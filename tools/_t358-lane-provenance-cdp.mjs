#!/usr/bin/env node
/**
 * _t358-lane-provenance-cdp.mjs — prove the lane-origin partition is TOTAL and that
 * its four branches are actually DISTINGUISHABLE on real documents.
 *
 * The defect this exists for: three separate causes reached `!lanes.length` in
 * `parseBpmnXml` and produced byte-identical output. "The input had no lanes" and
 * "the input had lanes we failed to read" are a property of the author and a defect
 * of ours respectively, and they were the same observation. No repair to either
 * could be verified, and no report could name which had happened.
 *
 * What is on trial here is the PROBE as much as the code. A probe that reads
 * `laneProvenance` back from the same parse that set it would agree with itself on
 * every document — so each fixture is an independently authored XML shape, and the
 * run FAILS unless all four branches are observed and no two fixtures collide.
 *
 * The negative control is load-bearing. Counting lanes in the OUTPUT reads 3 for a
 * designer map and 3 for a fabricated one, discriminating nothing; `authored-lanes`
 * must come back input-derived (2 lanes in, 2 lanes out, provenance `authored`).
 *
 * Usage: node tools/_t358-lane-provenance-cdp.mjs
 * Exit 0 = all four branches observed, distinct, and lane counts match expectation.
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXDIR = join(REPO, 'tests', 'fixtures', 'lane-provenance');

// Expectation table. `lanesOut` is what state should hold AFTER parse:
// the control keeps its own 2; every defaulted case gets our 3-lane skeleton.
const CASES = [
  { file: 'authored-lanes.bpmn',         provenance: 'authored',                         lanesOut: 2, note: 'NEGATIVE CONTROL — input-derived, no fabrication' },
  { file: 'no-laneset.bpmn',             provenance: 'defaulted:no-laneset',             lanesOut: 3, note: 'property of the input' },
  { file: 'empty-laneset.bpmn',          provenance: 'defaulted:empty-laneset',          lanesOut: 3, note: 'laneSet present, zero lane children' },
  { file: 'later-laneset-ignored.bpmn',  provenance: 'defaulted:later-laneset-ignored',  lanesOut: 3, note: 'OUR defect — T-348 first-only read discarded real lanes' },
];

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  for (const c of CASES) if (!existsSync(join(FIXDIR, c.file))) throw new Error('fixture missing: ' + c.file);

  const doc = mkdtempSync(join(tmpdir(), 't358-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't358-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't358-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl; const observed = [];
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    for (const c of CASES) {
      const xml = readFileSync(join(FIXDIR, c.file), 'utf8');
      await ev(cmd, `window.__IN__ = ${JSON.stringify(xml)};`);
      const r = await ev(cmd, `(function(){
        var m = parseBpmnXml(window.__IN__);
        if(!m) return null;
        return { prov: m.laneProvenance, lanes: (m.lanes||[]).length,
                 laneNames: (m.lanes||[]).map(function(l){return l.name;}),
                 firstAuthority: (m.lanes && m.lanes[0]) ? m.lanes[0].authority : null };
      })()`);
      observed.push({ ...c, got: r });
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  const fails = [];
  for (const o of observed) {
    if (!o.got) { fails.push(`${o.file}: parse returned null`); continue; }
    console.log(`  ${o.file.padEnd(30)} provenance=${String(o.got.prov).padEnd(34)} lanes=${o.got.lanes}  [${o.note}]`);
    if (o.got.prov !== o.provenance) fails.push(`${o.file}: provenance ${JSON.stringify(o.got.prov)} != expected ${JSON.stringify(o.provenance)}`);
    if (o.got.lanes !== o.lanesOut) fails.push(`${o.file}: lanes ${o.got.lanes} != expected ${o.lanesOut}`);
  }

  // The partition must be TOTAL and its branches DISJOINT on real documents.
  // Four fixtures collapsing onto three values would mean two causes still share
  // one verdict — the exact condition this task exists to end.
  // NOTE (found by tools/_t358-teeth.py, case 3): `seen` was built with
  // `.filter(Boolean)` and the totality check below then looked for undefined in it.
  // `.filter(Boolean)` strips exactly the values that check exists to find, so it
  // could never fire — an unreachable check is a constant, and a constant
  // discriminates nothing. Totality is now tested BEFORE anything is filtered.
  const seen = observed.map(o => (o.got ? o.got.prov : undefined));
  const missing = seen.filter(v => v === undefined || v === null).length;
  if (missing) {
    fails.push(`${missing} document(s) produced NO provenance — the partition is not total`);
  }
  const distinct = new Set(seen.filter(Boolean));
  if (distinct.size !== CASES.length) {
    fails.push(`branches are NOT separable: ${CASES.length} fixtures produced ${distinct.size} distinct verdict(s) [${[...distinct].join(', ')}]`);
  }

  // Negative control, stated as its own check so it cannot pass by accident:
  // the control must be the ONLY case that is not defaulted.
  const ctl = observed.find(o => o.file === 'authored-lanes.bpmn');
  if (ctl && ctl.got) {
    if (String(ctl.got.prov).startsWith('defaulted:')) fails.push('negative control was DEFAULTED — the probe cannot report "no fabrication"');
    if (JSON.stringify(ctl.got.laneNames) !== JSON.stringify(['Operations', 'Finance'])) {
      fails.push(`negative control lanes are not input-derived: ${JSON.stringify(ctl.got.laneNames)}`);
    }
  }
  const defaulted = observed.filter(o => o.got && String(o.got.prov).startsWith('defaulted:'));
  if (defaulted.length !== 3) fails.push(`expected exactly 3 defaulted cases, saw ${defaulted.length}`);
  // And the fabrication this task names: every defaulted document is asserted
  // human-sovereign. Pinned so a silent change to defaultLanes() cannot pass unseen.
  for (const d of defaulted) {
    if (d.got.firstAuthority !== 'sovereignty') fails.push(`${d.file}: first lane authority ${JSON.stringify(d.got.firstAuthority)} != 'sovereignty' (the fabricated assertion this task names)`);
  }

  if (fails.length) { for (const f of fails) console.log('  FAIL ' + f); console.log('\nFAIL'); return 1; }
  console.log('\nPASS — 4 lane origins, 4 distinct verdicts; partition total; control input-derived (2 in, 2 out)');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
