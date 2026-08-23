#!/usr/bin/env node
/**
 * _t423-additive-export-cdp.mjs — run the additive-export guard against REAL exports,
 * produced by the real designer in a real browser.
 *
 * WHY A BROWSER. The guard is a pure function over two directories, and its teeth prove it
 * discriminates — but the claim it certifies is about what `buildBpmnXml` does, and that
 * function only exists inside the page. A stand-in export written by this file would test
 * the stand-in. This is the same reason the carrier-agreement probe exists next door, and
 * the same answer to AEF's rail-11876 question: a real artefact, not a constructed one.
 *
 * WHAT IT PROVES, which is more than the two ACs it closes asked for. Every element outside
 * the DI namespaces is identical between each source map and its export — same tag, same
 * attributes, same document order. "aef:position still written, nothing removed or
 * reordered" and "the intent extensions untouched" both fall out of that one equality,
 * along with everything else in the document that neither AC thought to name.
 *
 * Rendering is deliberately not invoked, for the reason recorded in the carrier probe:
 * computeEdgeGeometry is a pure function of the model so that export does not depend on a
 * canvas having been painted. Requiring a render here would leave that property untested
 * and untrue for headless consumers.
 *
 * T423_EXPORT_OUT — write the exports to this directory and leave them there. The teeth
 * (tools/_t423-additive-export-teeth.py) damage a REAL export rather than a hand-written
 * one, so the suite runs this first and hands the directory over.
 *
 * Usage: node tools/_t423-additive-export-cdp.mjs
 * Exit 0 = every exported map is identical to its source outside DI.
 *      1 = a document diverged.
 *      2 = misconfig, export failure, or the guard refused (nothing compared).
 */

import { spawn, spawnSync } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
// Written repo-relative, not as join(HERE, '<name>'), and that is not a style preference.
// tools/_t451-unwired-guard-census.py decides reachability by textual reference to
// `tools/<name>` in an executable position, so a runtime-composed path makes a guard that is
// genuinely invoked here report as UNWIRED — its own LIMIT paragraph names this false
// positive and says it cannot be closed from outside. The sibling carrier probe composes its
// path that way and is currently counted wired only because a JSDoc COMMENT happens to spell
// the path out; T-495 strips Python and shell comments but not JS block comments, so that
// edge is prose. Filed as T-578. This line states the real dependency where the tool can see it.
const GUARD = join(REPO, 'tools/_t423-additive-export-guard.py');
// Overridable for the same reason T308_CORPUS is (T-364): a population whose size is part of
// the finding must be shown variable before its value means anything.
const CORPUS = process.env.T423_CORPUS || join(REPO, 'examples', 'aef-processes', 'rendered');
const KEEP = process.env.T423_EXPORT_OUT || '';

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const EXPORT_EXPR = `(function(){
  var out = {};
  var maps = window.__MAPS__;
  for (var i=0;i<maps.length;i++){
    try {
      var m = parseBpmnXml(maps[i].text);
      if(!m){ out[maps[i].name] = {err:'parse returned null'}; continue; }
      state = m; refreshDisplayIds();
      out[maps[i].name] = {xml: buildBpmnXml(state)};
    } catch(e) { out[maps[i].name] = {err: String(e && e.message || e)}; }
  }
  return out;
})()`;

async function main() {
  const files = existsSync(CORPUS) ? readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort() : [];
  if (!files.length) { console.log(`REFUSE — no .bpmn in ${CORPUS}`); return 2; }

  const doc = mkdtempSync(join(tmpdir(), 't423a-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't423a-repo-'));
  const outdir = KEEP || mkdtempSync(join(tmpdir(), 't423a-out-'));
  if (KEEP) { rmSync(KEEP, { recursive: true, force: true }); mkdirSync(KEEP, { recursive: true }); }
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't423a-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, exported = null;
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
    await cl.cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cl.cmd); await sleep(300);
    const maps = files.map(f => ({ name: f, text: readFileSync(join(CORPUS, f), 'utf8') }));
    await ev(cl.cmd, `window.__MAPS__ = ${JSON.stringify(maps)};`);
    exported = await ev(cl.cmd, EXPORT_EXPR);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  // An export that threw is NOT a document with nothing wrong in it. Fatal and named — a
  // silently shrinking population is how a guard's coverage evaporates with its verdict
  // unchanged, and the guard's own pair-set check would report the survivors as PASS.
  const failed = [];
  for (const f of files) {
    const r = exported && exported[f];
    if (!r || r.err || !r.xml) { failed.push(`${f}: ${r && r.err || 'no output'}`); continue; }
    writeFileSync(join(outdir, f), r.xml, 'utf8');
  }
  if (failed.length) {
    console.log(`REFUSE — ${failed.length} of ${files.length} map(s) did not export:`);
    for (const x of failed) console.log('  ' + x);
    if (!KEEP) rmSync(outdir, { recursive: true, force: true });
    return 2;
  }

  console.log(`  exported ${files.length} map(s) through a real browser -> ${outdir}`);
  const g = spawnSync('python3', [GUARD, CORPUS, outdir], { encoding: 'utf8' });
  process.stdout.write(g.stdout || '');
  process.stderr.write(g.stderr || '');
  if (!KEEP) rmSync(outdir, { recursive: true, force: true });

  if (g.status !== 0) { console.log(`\nFAIL — guard exited ${g.status} on REAL exported artefacts`); return g.status; }
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
