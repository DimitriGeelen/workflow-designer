#!/usr/bin/env node
/**
 * _t423-carrier-agreement-cdp.mjs — run the two-carrier agreement guard against REAL
 * exported artefacts, produced by the real designer in a real browser.
 *
 * WHY THIS EXISTS SEPARATELY FROM THE GUARD. The guard
 * (tools/_t423-carrier-agreement-guard.py) is a pure function over XML, and its teeth
 * prove it discriminates — but every document the teeth build is one I wrote to be
 * checked. AEF's question at rail 11876, transferred into this task's AC verbatim, is
 * *"has anyone watched it go red, against a real artefact, with a real competitor?"*
 * Synthetic input answers the first half of that and not the second. The corpus exported
 * through the actual `buildBpmnXml` is the real artefact; `dc:Bounds` written by the
 * emitter that landed at 389133c8 is the real competitor to `aef:position`.
 *
 * The rendered corpus on disk cannot serve: those documents carry `aef:position` and no
 * DI at all, because DI has only ever been an EXPORT product. Run the guard over them and
 * it refuses (0 pairs) — correctly, and uselessly for this purpose. The two carriers only
 * coexist downstream of an export, so an export is what has to be produced.
 *
 * ALSO WRITES ONE WITNESS, to tests/fixtures/exported/t423-carrier-witness.bpmn, for the
 * same reason t361 writes one: the teeth need a REAL document to mutate, and requiring a
 * browser to run the teeth would mean the teeth stop being run. The witness is the map
 * with the most nodes, so the population it gives the teeth is the largest available.
 *
 * Usage: node tools/_t423-carrier-agreement-cdp.mjs
 * Exit 0 = every exported map carries both carriers, covering the same nodes, agreeing.
 *      1 = the guard found a disagreement or a coverage hole.
 *      2 = misconfig, export failure, or the guard refused (nothing to compare).
 */

import { spawn, spawnSync } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const GUARD = join(HERE, '_t423-carrier-agreement-guard.py');
// Overridable for the same reason T308_CORPUS is (T-364): a bucket whose count is the
// finding has to be shown fillable against a temp corpus before its emptiness means
// anything.
const CORPUS = process.env.T423_CORPUS || join(REPO, 'examples', 'aef-processes', 'rendered');
const WITNESS = join(REPO, 'tests', 'fixtures', 'exported', 't423-carrier-witness.bpmn');

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Rendering is deliberately not invoked. computeEdgeGeometry is a pure function of the
// model precisely so that export does not depend on a canvas having been painted; if this
// probe had to render first, that property would be untested here and untrue in headless
// consumers. The node bounds this guard compares do not touch the canvas at all.
const EXPORT_EXPR = `(function(){
  var out = {};
  var maps = window.__MAPS__;
  for (var i=0;i<maps.length;i++){
    try {
      var m = parseBpmnXml(maps[i].text);
      if(!m){ out[maps[i].name] = {err:'parse returned null'}; continue; }
      state = m; refreshDisplayIds();
      out[maps[i].name] = {xml: buildBpmnXml(state), nodes: state.nodes.length};
    } catch(e) { out[maps[i].name] = {err: String(e && e.message || e)}; }
  }
  return out;
})()`;

async function main() {
  const files = existsSync(CORPUS) ? readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort() : [];
  if (!files.length) { console.log(`REFUSE — no .bpmn in ${CORPUS}`); return 2; }

  const doc = mkdtempSync(join(tmpdir(), 't423-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't423-repo-'));
  const outdir = mkdtempSync(join(tmpdir(), 't423-out-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't423-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, exported = null;
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

    const maps = files.map(f => ({ name: f, text: readFileSync(join(CORPUS, f), 'utf8') }));
    await ev(cmd, `window.__MAPS__ = ${JSON.stringify(maps)};`);
    exported = await ev(cmd, EXPORT_EXPR);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  // An export that threw is NOT a map with nothing wrong in it. Named and counted, and
  // fatal — a silently shrinking population is how a guard's coverage evaporates without
  // its verdict ever changing.
  const failed = [];
  let best = null;
  for (const f of files) {
    const r = exported && exported[f];
    if (!r || r.err || !r.xml) { failed.push(`${f}: ${r && r.err || 'no output'}`); continue; }
    writeFileSync(join(outdir, f), r.xml, 'utf8');
    if (!best || r.nodes > best.nodes) best = { name: f, xml: r.xml, nodes: r.nodes };
  }
  if (failed.length) {
    console.log(`REFUSE — ${failed.length} of ${files.length} map(s) did not export:`);
    for (const x of failed) console.log('  ' + x);
    rmSync(outdir, { recursive: true, force: true });
    return 2;
  }

  console.log(`  exported ${files.length} map(s) through a real browser -> ${outdir}`);
  const g = spawnSync('python3', [GUARD, outdir], { encoding: 'utf8' });
  process.stdout.write(g.stdout || '');
  process.stderr.write(g.stderr || '');

  if (g.status === 0 && best) {
    mkdirSync(dirname(WITNESS), { recursive: true });
    writeFileSync(WITNESS, best.xml, 'utf8');
    console.log(`  witness: ${WITNESS.replace(REPO + '/', '')} (from ${best.name}, ${best.nodes} nodes, ${best.xml.length} bytes)`);
  }
  rmSync(outdir, { recursive: true, force: true });

  if (g.status !== 0) { console.log(`\nFAIL — guard exited ${g.status} on REAL exported artefacts`); return g.status; }
  console.log('\nPASS — both carriers agree on every node of every exported corpus map');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
