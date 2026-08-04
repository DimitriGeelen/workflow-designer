#!/usr/bin/env node
/**
 * _t358-byteid-thirdparty.mjs — byte-identity over the population `_t308` CANNOT
 * reach: third-party documents.
 *
 * Why this exists (G-023). `_t308` reports "24/24 identical, 0 drifted" and that is
 * true — of designer-produced corpus maps. Those are the documents that carry
 * `aef:uid`. Every third-party document does not, and the emitter mints a fresh uid
 * per parse (T-364), so third-party emissions are not byte-stable even against
 * themselves. A gate built on raw equality therefore cannot be run on them at all,
 * and its silence has been reading as coverage.
 *
 * The fix is not to widen the claim, it is to normalise the ONE field that is
 * legitimately nondeterministic and then demand exact equality of everything else:
 *
 *   - `aef:uid` values are replaced with u1, u2, ... in document order, in both
 *     emissions, before comparison.
 *   - the SUBSTITUTION IS COUNTED and reported. A normaliser that silently matched
 *     nothing would turn this into a raw comparison wearing a normalised label, and
 *     an unequal count between the two sides is itself a difference.
 *   - nothing else is touched.
 *
 * Compares the CURRENT build against a BASELINE build read from git (default: the
 * commit before T-358's source change), so the question it answers is exactly the one
 * I put on the rail: did that change move any byte for a third-party document?
 *
 * Usage: node tools/_t358-byteid-thirdparty.mjs [baseline-git-ref]
 * Exit 0 = every fixture identical modulo uid. Exit 1 = a real difference. Exit 2 =
 * harness failure or a normaliser that did not fire.
 */

import { spawn, execFileSync } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXDIR = join(REPO, 'tests', 'fixtures', 'third-party');
// 3bf37909 is T-358's source change; its parent is the last build without it.
const BASELINE_REF = process.argv[2] || '3bf37909~1';

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

/** Replace aef:uid values with u1,u2,... in document order. Returns [text, count]. */
function normaliseUids(xml) {
  let n = 0;
  const out = xml.replace(/(<aef:uid\s+value=")([^"]*)(")/g, (_m, a, _v, c) => `${a}u${++n}${c}`);
  return [out, n];
}

async function main() {
  let baselineSrc;
  try {
    baselineSrc = execFileSync('git', ['-C', REPO, 'show', `${BASELINE_REF}:src/aef-workflow-designer.html`], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  } catch (e) {
    console.error(`ERROR: cannot read baseline ${BASELINE_REF}:src/aef-workflow-designer.html — ${e.message}`);
    return 2;
  }
  const currentSrc = readFileSync(join(REPO, 'src/aef-workflow-designer.html'), 'utf8');
  const fixtures = readdirSync(FIXDIR).filter(f => f.endsWith('.bpmn')).sort();
  if (!fixtures.length) { console.error('ERROR: no third-party fixtures'); return 2; }

  const doc = mkdtempSync(join(tmpdir(), 't358-bid-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't358-bid-repo-'));
  writeFileSync(join(doc, 'baseline.html'), baselineSrc);
  writeFileSync(join(doc, 'current.html'), currentSrc);
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't358-bid-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl; const emitted = { baseline: {}, current: {} };
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');

    for (const build of ['baseline', 'current']) {
      await cmd('Page.navigate', { url: `${BASE}/${build}.html` });
      await waitReady(cmd); await sleep(250);
      for (const f of fixtures) {
        await ev(cmd, `window.__IN__ = ${JSON.stringify(readFileSync(join(FIXDIR, f), 'utf8'))};`);
        emitted[build][f] = await ev(cmd, `(function(){
          var prev = state; var m = parseBpmnXml(window.__IN__);
          if (!m) { return null; }
          state = m; var x = buildBpmnXml(state); state = prev; return x;
        })()`);
      }
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  console.log(`\nByte-identity over THIRD-PARTY documents — current vs ${BASELINE_REF}`);
  console.log('(uid values normalised in document order; nothing else touched)\n');
  let identical = 0, drifted = 0, unusable = 0, normaliserSilent = 0;
  for (const f of fixtures) {
    const a = emitted.baseline[f], b = emitted.current[f];
    if (a == null || b == null) { console.log(`  ${f.padEnd(36)} UNUSABLE (parse returned null)`); unusable++; continue; }
    const [na, ca] = normaliseUids(a);
    const [nb, cb] = normaliseUids(b);
    if (ca === 0 && cb === 0) normaliserSilent++;
    if (ca !== cb) { console.log(`  ${f.padEnd(36)} DRIFTED — uid count differs (${ca} vs ${cb})`); drifted++; continue; }
    if (na === nb) { console.log(`  ${f.padEnd(36)} identical  (${na.length} bytes, ${ca} uid(s) normalised)`); identical++; continue; }
    drifted++;
    const la = na.split('\n'), lb = nb.split('\n');
    let i = 0; while (i < la.length && i < lb.length && la[i] === lb[i]) i++;
    console.log(`  ${f.padEnd(36)} DRIFTED — first diff line ${i + 1}`);
    console.log(`      baseline: ${(la[i] || '').trim().slice(0, 130)}`);
    console.log(`      current : ${(lb[i] || '').trim().slice(0, 130)}`);
  }

  console.log(`\n  ${identical} identical, ${drifted} drifted, ${unusable} unusable, over ${fixtures.length} third-party fixture(s)`);
  // A normaliser that never fires turns this into the raw comparison it replaced.
  if (normaliserSilent === fixtures.length) {
    console.log('\n  ERROR: the uid normaliser matched NOTHING on any fixture. This run is a raw');
    console.log('  byte comparison wearing a normalised label — it proves nothing about T-364.');
    return 2;
  }
  if (drifted || unusable) return 1;
  console.log('\n  PASS — the population _t308 cannot reach is unchanged by the current build.');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
