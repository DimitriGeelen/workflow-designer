#!/usr/bin/env node
// _t1274-note-box-cdp.mjs — T-1274: the side-panel Note box shows its whole text (the T-1241 reviewer: it cut its third
// line, "until real ACs exist", in t1241-business-1920-panel and t1241-technical-1440-panel-bottom).
// Drives the REAL editor headless (gallery-serve.py + the interim lens file), aef-task-lifecycle (v3 project map).
// Legs:
//   1. at 1024, 1440 and 1920, in every lens (business/logical/technical/all), every node with a note selected: the
//      side panel's Note field shows its whole text: scrollHeight <= clientHeight; and the field is drawn in at least
//      one lens per width (the check is not vacuous);
//   2. the cap: a note of 60 lines makes the box no taller than the cap and it scrolls visibly (overflow-y auto,
//      scrollHeight > clientHeight); typing grows it, deleting shrinks it again;
//   3. bytes: buildBpmnXml output is identical before and after (sizing is display only).
// T1274_SRC substitutes another designer file (the 0.25.0 source: leg 1 must go red). Exit 0 = green; 1 = red; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1274_SRC || join(REPO, 'src/aef-workflow-designer.html');
const LIFECYCLE = join(REPO, '.agentic-framework/.context/designer/projects/aef-task-lifecycle/v3.bpmn');
const LENSFILE = join(REPO, 'lens-definition.interim.json');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// In-page. The Note field is the .field whose label reads "Note" in #properties.
const RUN = `(async function(args){
  var frame = function(){ return new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); }); };
  function noteBox(){ var fs = document.querySelectorAll('#properties .field'); for (var i = 0; i < fs.length; i++) {
    var l = fs[i].querySelector('.field-label'); if (l && l.firstChild && l.firstChild.textContent.trim() === 'Note') return fs[i].querySelector('textarea'); } return null; }
  var out = { cut: [], shown: {}, measured: 0, cap: null };
  adoptImportedXml(args.xml, { userImport: true }); renderAll();
  if (typeof openingZoom === 'function') openingZoom();
  var base = buildBpmnXml(state);
  var withNote = state.nodes.filter(function(n){ return n.aef && typeof n.aef.note === 'string' && n.aef.note.trim(); });
  out.withNote = withNote.length;
  for (var li = 0; li < args.lenses.length; li++) {
    var lens = args.lenses[li];
    if (typeof setLens === 'function') setLens(lens);
    out.shown[lens] = 0;
    for (var k = 0; k < withNote.length; k++) {
      var n = withNote[k];
      selection = { kind: 'node', id: n.id }; renderProperties(); await frame();
      // a lens switch may re-render the panel once more a moment later; measure the box a person then sees
      await new Promise(function(r){ setTimeout(r, 150); }); await frame();
      var ta = noteBox(); if (!ta) continue;
      out.shown[lens]++; out.measured++;
      if (ta.scrollHeight > ta.clientHeight) out.cut.push(lens + ' ' + n.id + ': scrollHeight ' + ta.scrollHeight + ' > clientHeight ' + ta.clientHeight + ' (' + n.aef.note.length + ' chars, height ' + ta.style.height + ', width ' + ta.clientWidth + ', classes ' + ta.className + ')');
    }
  }
  // leg 2 on the first node with a note, lens all
  if (typeof setLens === 'function') setLens('all');
  var n0 = withNote[0];
  if (n0) {
    selection = { kind: 'node', id: n0.id }; renderProperties(); await frame();
    var ta = noteBox();
    if (ta) {
      var orig = ta.value, h0 = ta.clientHeight, long = []; for (var i = 0; i < 60; i++) long.push('line ' + i);
      ta.value = long.join('\\n'); ta.dispatchEvent(new Event('input')); await frame();
      var cs = getComputedStyle(ta);
      out.cap = { before: h0, long: ta.clientHeight, offset: ta.offsetHeight, overflowY: cs.overflowY, scrolls: ta.scrollHeight > ta.clientHeight };
      ta.value = 'x'; ta.dispatchEvent(new Event('input')); await frame();
      out.cap.short = ta.clientHeight;
      // undo the edit: the field's own input handler writes the value back as it was
      ta.value = orig; ta.dispatchEvent(new Event('input'));
    }
  }
  out.bytesSame = buildBpmnXml(state) === base;
  return out;
})`;

async function session(width, height, fn) {
  const doc = mkdtempSync(join(tmpdir(), 't1274-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1274-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(LENSFILE, join(repo, 'lens-definition.interim.json'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1274-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', `--window-size=${width},${height}`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd);
    for (let i = 0; i < 50; i++) { if (await ev(cmd, `typeof _lensDef === 'undefined' || !!_lensDef`)) break; await sleep(100); }
    await sleep(200);
    return await fn(cmd);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}

async function main() {
  if (!existsSync(SRC) || !existsSync(LIFECYCLE) || !existsSync(LENSFILE)) { console.log(JSON.stringify({ ok: false, error: 'missing input' })); process.exitCode = 2; return; }
  const xml = readFileSync(LIFECYCLE, 'utf8');
  const errs = [], report = { src: SRC };
  try {
    for (const [w, h] of [[1024, 768], [1440, 900], [1920, 1080]]) {
      const r = await session(w, h, cmd => ev(cmd, `(${RUN})(${JSON.stringify({ xml, lenses: ['business', 'logical', 'technical', 'all'] })})`));
      report[w] = { withNote: r.withNote, measured: r.measured, shown: r.shown, cap: r.cap, cut: r.cut };
      for (const c of r.cut) errs.push(`leg1: at ${w}, ${c}`);
      if (!r.withNote || !r.measured) errs.push(`leg1: at ${w} no Note field was measured (${r.withNote} nodes with a note) — vacuous`);
      const c = r.cap;
      if (!c) errs.push(`leg2: at ${w} no Note box to try the cap on`);
      else {
        if (!(c.long > c.before)) errs.push(`leg2: at ${w} a 60-line note did not grow the box (${c.before} -> ${c.long})`);
        if (!(c.offset <= 240)) errs.push(`leg2: at ${w} a 60-line note made the box ${c.offset}px tall (cap 240)`);
        if (!(c.scrolls && c.overflowY === 'auto')) errs.push(`leg2: at ${w} past the cap the box does not scroll visibly (overflow-y ${c.overflowY}, scrolls ${c.scrolls})`);
        if (!(c.short < c.long)) errs.push(`leg2: at ${w} deleting the text did not shrink the box (${c.long} -> ${c.short})`);
      }
      if (!r.bytesSame) errs.push(`leg3: at ${w} buildBpmnXml changed`);
    }
  } catch (e) { errs.push('exception: ' + (e && e.stack || e)); }
  report.ok = !errs.length; report.errs = errs;
  console.log(JSON.stringify(report, null, 2));
  process.exitCode = errs.length ? 1 : 0;
}
main();
