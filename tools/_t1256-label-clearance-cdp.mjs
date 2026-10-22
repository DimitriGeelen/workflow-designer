#!/usr/bin/env node
// _t1256-label-clearance-cdp.mjs — T-1256: gateway/event labels, id captions and flow labels clear of the drawn flows.
// Drives the REAL editor headless (gallery-serve.py + the interim lens file) and measures the RENDERED SVG: the
// screen box of every label text (getBBox through getScreenCTM) against the segments of every drawn flow path
// (the `d` of .edge-path, not the editor's own stash), and every label box against every other label box.
//   gwFlow  a gateway/event name line crossed by a flow segment      (text.node-label[data-nl])
//   idFlow  an id caption crossed by a flow segment                  (text.node-id-badge)
//   ll      two labels of different owners overlapping               (names, id captions, flow labels)
// Legs:
//   1. aef-task-lifecycle (v3 project map) at 1920, every lens (business/logical/technical/all) x id captions on/off:
//      gwFlow = idFlow = ll = 0;
//   2. every map in examples/aef-processes/rendered/, lens all, ids on and off: gwFlow+idFlow per map no higher than
//      the designer-v0.24.0 placement (built from `git show designer-v0.24.0:src/...`), and lower in total; flow labels
//      crossed by another flow no higher per map either (moving a name must not push a flow label onto a line);
//   3. bytes: buildBpmnXml output is identical before and after every render this harness makes, on every map;
//   6. nearness (T-1274): a flow label and a node/gateway/event name or id caption on one text row closer than three em
//      of the smaller font read as one run ("yes — status: issues issues encountered?"): 0 on aef-task-lifecycle in
//      leg 5's every run (lens x ids x 1440/1920); on the corpus (lens all, ids on/off, 1440 and 1920) no map more than
//      the designer-v0.25.0 placement, and the total not higher (T1256_NEAR_BASE_SRC substitutes that baseline);
//   7. lens-shot state (T-1277): every corpus map opened as tools/_t1241-lens-shots.py opens it, at 1024/1440/1920,
//      lens all, ids on: gwFlow + idFlow + head (a name or caption on an arrowhead) per map and in total no higher than
//      the 6d03c1b9 placement (T1256_SHOT_BASE_SRC substitutes it); bytes unchanged. Legs 1 and 5 count head too, and
//      leg 5 measures the lens-shot load at 1024 as well;
//   4. at 1024 the map opens with its node and gateway text at >= MIN_PX (stated in T-1256) rendered size, and
//      nothing is hidden: every node's shape is in the canvas's scrollable area.
// T1256_SRC substitutes another designer file (e.g. the 0.24.0 source: legs 1, 2 and 4 must go red).
// T1256_BASE_SRC substitutes the baseline file for leg 2. Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn, execFileSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1256_SRC || join(REPO, 'src/aef-workflow-designer.html');
const BASE_TAG = 'designer-v0.24.0';
const NEAR_TAG = 'designer-v0.25.0';
const SHOT_BASE = '6d03c1b9';      // T-1277: the leg-7 baseline (T-1241 round-3 amber was judged on it)   // T-1274: the nearness baseline (the release before the nearness pass)
const MIN_PX = 7;   // the stated minimum rendered size of node and gateway text at 1024 (T-1256)
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
// The engine T-1241's lens-shot script (Playwright) draws with: its text metrics differ from chrome's by a pixel here
// and there, and label places follow the metrics, so leg 5 measures in both.
function findShell() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium_headless_shell-')) for (const x of [join(cache, d, 'chrome-linux', 'headless_shell'), join(cache, d, 'chrome-headless-shell-linux64', 'chrome-headless-shell')]) c.push(x); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; return null; }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const LIFECYCLE = join(REPO, '.agentic-framework/.context/designer/projects/aef-task-lifecycle/v3.bpmn');
const CORPUS_DIR = join(REPO, 'examples/aef-processes/rendered');
const LENSFILE = join(REPO, 'lens-definition.interim.json');

// In-page: measure the rendered canvas. Everything in screen px, so text and flows compare in one space.
const MEASURE = `window.__t1256measure = function(){
  function pt(m, x, y){ return { x: m.a * x + m.c * y + m.e, y: m.b * x + m.d * y + m.f }; }
  function boxOf(t){ var b = t.getBBox(); if (!b.width || !b.height) return null; var m = t.getScreenCTM();
    var p = pt(m, b.x, b.y), q = pt(m, b.x + b.width, b.y + b.height);
    return { x1: Math.min(p.x, q.x), y1: Math.min(p.y, q.y), x2: Math.max(p.x, q.x), y2: Math.max(p.y, q.y) }; }
  // Liang-Barsky: does segment a-b enter the rectangle r?
  function segHits(a, b, r){ var t0 = 0, t1 = 1, dx = b.x - a.x, dy = b.y - a.y;
    var P = [-dx, dx, -dy, dy], Q = [a.x - r.x1, r.x2 - a.x, a.y - r.y1, r.y2 - a.y];
    for (var i = 0; i < 4; i++) { if (P[i] === 0) { if (Q[i] < 0) return false; continue; }
      var t = Q[i] / P[i]; if (P[i] < 0) { if (t > t1) return false; if (t > t0) t0 = t; } else { if (t < t0) return false; if (t < t1) t1 = t; } }
    return true; }
  var segs = [];
  Array.prototype.forEach.call(gEdges.querySelectorAll('g.edge > path.edge-path'), function(p){
    var m = p.getScreenCTM(), id = p.parentNode.getAttribute('data-id');
    var pts = polylineFromPath(p.getAttribute('d')).map(function(q){ return pt(m, q.x, q.y); });
    for (var i = 0; i < pts.length - 1; i++) segs.push({ a: pts[i], b: pts[i + 1], edge: id });
  });
  // T-1277: the arrowheads, which the segments above leave out: #arrow at the end (8 x the 1.5 stroke, tip 1/10 past
  // the path's end) and #arrow-source at the start (5 x 1.5, pointing into the flow), as boxes in screen px with one
  // unit of margin for the anti-aliased edge. agt_3_start and agt_6_completion stood against the end head of the flow
  // into their own task, touching its base: no segment crossed them, so legs 1 and 5 read 0.
  var heads = [];
  Array.prototype.forEach.call(gEdges.querySelectorAll('g.edge > path.edge-path'), function(p){
    var m = p.getScreenCTM(), id = p.parentNode.getAttribute('data-id'), pl = polylineFromPath(p.getAttribute('d')), SW = 1.5, M = 1;
    if (pl.length < 2) return;
    function head(tip, prev, back, fwd, half){ var dx = tip.x - prev.x, dy = tip.y - prev.y, L = Math.hypot(dx, dy); if (!L) return;
      var ux = dx / L, uy = dy / L, bx = tip.x - ux * back, by = tip.y - uy * back;
      var xs = [tip.x + ux * fwd, bx - uy * half, bx + uy * half], ys = [tip.y + uy * fwd, by + ux * half, by - ux * half];
      var a = pt(m, Math.min.apply(null, xs) - M, Math.min.apply(null, ys) - M), b = pt(m, Math.max.apply(null, xs) + M, Math.max.apply(null, ys) + M);
      heads.push({ edge: id, box: { x1: Math.min(a.x, b.x), y1: Math.min(a.y, b.y), x2: Math.max(a.x, b.x), y2: Math.max(a.y, b.y) } }); }
    if (p.getAttribute('marker-end')) head(pl[pl.length - 1], pl[pl.length - 2], 0.8 * SW * 9, 0.8 * SW, 0.8 * SW * 5);
    if (p.getAttribute('marker-start')) head(pl[0], pl[1], -0.5 * SW, -0.5 * SW * 9, 0.5 * SW * 5);
  });
  var labels = [];
  function add(kind, t, owner){ if (t.closest('#g-sticky-lanes')) return; var b = boxOf(t); if (!b) return;
    var s = 0.5; b = { x1: b.x1 + s, y1: b.y1 + s, x2: b.x2 - s, y2: b.y2 - s };   // touching is not crossing
    var raw = boxOf(t), fpx = parseFloat(getComputedStyle(t).fontSize) * Math.abs(t.getScreenCTM().a);
    labels.push({ kind: kind, owner: owner, text: t.textContent, box: b, raw: raw, em: fpx }); }
  Array.prototype.forEach.call(gNodes.querySelectorAll('text.node-label[data-nl]'), function(t){ add('gw', t, 'n:' + t.getAttribute('data-nl')); });
  // T-1274: names inside a shape count for nearness only (a flow label beside a task's name reads on with it too).
  var nameIn = [];
  Array.prototype.forEach.call(gNodes.querySelectorAll('text.node-label:not([data-nl])'), function(t){ var g = t.closest('g[data-id]');
    if (t.closest('#g-sticky-lanes')) return; var b = boxOf(t); if (!b) return;
    nameIn.push({ kind: 'nm', owner: 'n:' + (g ? g.getAttribute('data-id') : t.textContent), text: t.textContent, raw: b,
      em: parseFloat(getComputedStyle(t).fontSize) * Math.abs(t.getScreenCTM().a) }); });
  Array.prototype.forEach.call(svg.querySelectorAll('text.node-id-badge'), function(t){ var g = t.closest('g[data-id]');
    add('id', t, 'n:' + (t.getAttribute('data-nl') || (g ? g.getAttribute('data-id') : t.textContent))); });
  Array.prototype.forEach.call(gEdges.querySelectorAll('text.edge-label'), function(t){ add('el', t, 'e:' + t.getAttribute('data-el')); });
  var out = { gwFlow: 0, idFlow: 0, elFlow: 0, ll: 0, hits: [] };
  labels.forEach(function(L){
    var crossed = {};
    segs.forEach(function(s){ if (segHits(s.a, s.b, L.box)) crossed[s.edge] = 1; });
    var n = Object.keys(crossed).length;
    if (L.kind === 'el') { delete crossed[L.owner.slice(2)]; n = Object.keys(crossed).length; }
    if (!n) return;
    out[L.kind + 'Flow'] += n;
    out.hits.push(L.kind + ' "' + L.text + '" x flow ' + Object.keys(crossed).join(','));
  });
  function inter(a, b){ return a.x1 < b.x2 && b.x1 < a.x2 && a.y1 < b.y2 && b.y1 < a.y2; }
  // head (T-1277): a gateway/event name or id caption on an arrowhead (its raw box against the head's box + margin).
  out.head = 0;
  labels.forEach(function(L){ if (L.kind === 'el') return;
    heads.forEach(function(h){ if (!inter(L.raw, h.box)) return;
      out.head++; out.hits.push('head "' + L.text + '" x arrowhead of ' + h.edge); }); });
  for (var i = 0; i < labels.length; i++) for (var j = i + 1; j < labels.length; j++) {
    var A = labels[i], B = labels[j];
    if (A.owner === B.owner || !inter(A.box, B.box)) continue;
    out.ll++; out.hits.push('ll "' + A.text + '" x "' + B.text + '"');
  }
  // near (T-1274): a flow label and a node/gateway/event name or id caption on one text row (their boxes share at least
  // half the smaller height) with a horizontal gap under NEAR_EM em of the smaller font: they read as one run. Three em,
  // not one: the pair the T-1241 reviewer read as one run ("yes — status: issues" | "issues encountered?", 1920
  // technical/all) stands 10.7 px apart across a 1-px flow, where one em of the 10-px flow label is 7.6 px; at two em
  // the pass parked the label 20 px from the name on the same row, which still reads on (T-1274 crops).
  var NEAR_EM = 3;
  out.near = 0;
  var nodeTexts = labels.filter(function(L){ return L.kind !== 'el'; }).concat(nameIn);
  labels.forEach(function(A){ if (A.kind !== 'el') return;
    nodeTexts.forEach(function(B){
      var a = A.raw, b = B.raw, ov = Math.min(a.y2, b.y2) - Math.max(a.y1, b.y1);
      if (ov < 0.5 * Math.min(a.y2 - a.y1, b.y2 - b.y1)) return;
      var gap = Math.max(b.x1 - a.x2, a.x1 - b.x2), em = Math.min(A.em, B.em);
      if (gap < 0 || gap >= NEAR_EM * em) return;      // overlapping is ll's; a gap of NEAR_EM em or more is clear
      out.near++; out.hits.push('near "' + A.text + '" x "' + B.text + '" gap ' + gap.toFixed(1) + 'px < ' + (NEAR_EM * em).toFixed(1)); }); });
  // clip: a flow label's text under another flow's halo painted after it (the halo is the label's background pad,
  // so a later one cuts the earlier text: the "backloq" descender the T-1241 reviewer saw).
  out.clip = 0;
  var els = Array.prototype.slice.call(gEdges.querySelectorAll('text.edge-label'));
  var halos = Array.prototype.slice.call(gEdges.querySelectorAll('rect[data-elr]'));
  els.forEach(function(t){ var b = boxOf(t); if (!b) return;
    halos.forEach(function(h){ if (h.getAttribute('data-elr') === t.getAttribute('data-el')) return;
      if (!(t.compareDocumentPosition(h) & Node.DOCUMENT_POSITION_FOLLOWING)) return;
      var hb = boxOf(h); if (!hb || !inter(b, hb)) return;
      out.clip++; out.hits.push('clip "' + t.textContent + '" under the pad of ' + h.getAttribute('data-elr')); }); });
  if (window.__t1256dump) out.dump = els.map(function(t){ var h = gEdges.querySelector('rect[data-elr="' + t.getAttribute('data-el') + '"]');
    return [t.textContent, boxOf(t), h && boxOf(h)]; });
  out.labels = labels.length; out.segs = segs.length;
  return out;
};`;

// One map: adopt it, then measure each config. bytes: buildBpmnXml before and after every render.
const RUN = `(async function(args){
  var res = { cfg: {}, bytesChanged: [] };
  adoptImportedXml(args.xml, { userImport: true }); renderAll();
  var base = buildBpmnXml(state);
  for (var i = 0; i < args.cfgs.length; i++) {
    var c = args.cfgs[i];
    if (typeof setLens === 'function') setLens(c.lens); else if (c.lens !== 'all') continue;
    labelPrefs.showIds = c.ids; renderAll();
    await new Promise(function(r){ requestAnimationFrame(function(){ r(); }); });
    res.cfg[c.lens + (c.ids ? '+ids' : '-ids')] = window.__t1256measure();
    if (buildBpmnXml(state) !== base) res.bytesChanged.push(c.lens + (c.ids ? '+ids' : '-ids'));
  }
  labelPrefs.showIds = true; if (typeof setLens === 'function') setLens('all'); renderAll();
  return res;
})`;

// Leg 5 (flow labels, T-1241 reviewer amber 2026-10-21): the map opened by ?load= as a person opens it, at the
// opening zoom, a service task selected as in the T-1241 lens shots; each lens x ids on/off is measured as drawn.
const OPEN_CFGS = `(async function(args){
  var res = {};
  for (var i = 0; i < args.cfgs.length; i++) {
    var c = args.cfgs[i];
    window.__t1256dump = args.dump;
    if (typeof setLens === 'function') setLens(c.lens); else if (c.lens !== 'all') continue;
    labelPrefs.showIds = c.ids;
    if (args.xml) {   // as T-1241's lens-shot script opens it: adopt, render, opening zoom, lens
      adoptImportedXml(args.xml, { userImport: true }); renderAll();
      if (typeof openingZoom === 'function') openingZoom();
      if (typeof setLens === 'function') setLens(c.lens);
    }
    var n = state.nodes.find(function(x){ return x.uid === args.pick; });
    if (n) selection = { kind: 'node', id: n.id };
    if (!args.xml) renderAll();
    if (typeof renderProperties === 'function') renderProperties();
    await new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); });
    res[c.lens + (c.ids ? '+ids' : '-ids')] = window.__t1256measure();
  }
  return res;
})`;

// Leg 7: one corpus map opened as tools/_t1241-lens-shots.py opens a map (adopt, render, opening zoom, lens, a task
// selected), lens all with ids on, measured as drawn; bytes compared before and after.
const SHOT_MAP = `(async function(args){
  labelPrefs.showIds = true;
  adoptImportedXml(args.xml, { userImport: true }); renderAll();
  var base = buildBpmnXml(state);
  if (typeof openingZoom === 'function') openingZoom();
  if (typeof setLens === 'function') setLens('all');
  var n = state.nodes.find(function(x){ return /Task$/.test(x.type); });
  if (n) { selection = { kind: 'node', id: n.id }; if (typeof renderProperties === 'function') renderProperties(); }
  await new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); });
  var m = window.__t1256measure();
  selection = null;
  return { gwFlow: m.gwFlow, idFlow: m.idFlow, head: m.head, hits: m.hits, bytesChanged: buildBpmnXml(state) !== base };
})`;

// Leg 4: at the opening view, the rendered size of node and gateway text, and whether every node is reachable.
// The map is opened the way a person opens it (?load= deep link), not by calling the editor's functions.
const OPEN_VIEW = `(async function(){
  await new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); });
  var sizes = [];
  Array.prototype.forEach.call(gNodes.querySelectorAll('text.node-label'), function(t){
    var fs = parseFloat(getComputedStyle(t).fontSize); var m = t.getScreenCTM(); sizes.push(fs * Math.abs(m.a)); });
  var wr = canvasWrap.getBoundingClientRect(), sr = svg.getBoundingClientRect();
  var unreachable = [];
  state.nodes.forEach(function(n){ var g = gNodes.querySelector('g[data-id="' + n.id + '"]'); if (!g) { unreachable.push(n.id + ':undrawn'); return; }
    var b = g.getBoundingClientRect(); if (b.width === 0 && b.height === 0) unreachable.push(n.id + ':empty');
    if (b.left < sr.left - 1 || b.right > sr.right + 1 || b.top < sr.top - 1 || b.bottom > sr.bottom + 1) unreachable.push(n.id + ':outside'); });
  var hidden = Array.prototype.filter.call(gNodes.querySelectorAll('g[data-id]'), function(g){ var cs = getComputedStyle(g); return cs.display === 'none' || cs.visibility === 'hidden'; }).length;
  var z0 = zoomFactor; document.getElementById('btn-zoom-fit').click(); var fitStill = zoomFactor === null; setZoom(z0);
  return { fitStill: fitStill, adopted: window._deepLinkSettled === 'adopted' && state.nodes.length > 10, minPx: Math.min.apply(null, sizes), zoom: typeof zoomFactor === 'undefined' ? null : zoomFactor,
           scrollable: canvasWrap.scrollWidth > canvasWrap.clientWidth || canvasWrap.scrollHeight > canvasWrap.clientHeight,
           wrapW: wr.width, unreachable: unreachable, hidden: hidden };
})`;

async function session(src, width, height, fn, load, engine) {
  const doc = mkdtempSync(join(tmpdir(), 't1256-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1256-repo-'));
  copyFileSync(src, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  if (load) writeFileSync(join(doc, 'rendered', 't1256-open.bpmn'), load);
  copyFileSync(LENSFILE, join(repo, 'lens-definition.interim.json'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1256-udd-');
  const br = spawn(engine || findChrome(), [...(engine ? [] : ['--headless=new']), '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', `--window-size=${width},${height}`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` + (load ? '?load=rendered/t1256-open.bpmn' : '') });
    await waitReady(cmd);
    // the lens definition loads after ready; wait for it where the source has lenses
    for (let i = 0; i < 50; i++) { if (await ev(cmd, `typeof _lensDef === 'undefined' || !!_lensDef`)) break; await sleep(100); }
    await sleep(200);
    await ev(cmd, MEASURE);
    return await fn(cmd);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}

const LENSES = ['business', 'logical', 'technical', 'all'];
const runMap = (cmd, xml, cfgs) => ev(cmd, `(${RUN})(${JSON.stringify({ xml, cfgs })})`);
const flowSum = r => Object.values(r.cfg).reduce((s, m) => s + m.gwFlow + m.idFlow, 0);

async function main() {
  const corpus = readdirSync(CORPUS_DIR).filter(f => f.endsWith('.bpmn')).sort();
  if (!existsSync(SRC) || !existsSync(LIFECYCLE) || !existsSync(LENSFILE) || !corpus.length) { console.log(JSON.stringify({ ok: false, error: 'missing input' })); process.exitCode = 2; return; }
  let baseSrc = process.env.T1256_BASE_SRC, baseTmp = null, nearTmp = null, shotTmp = null;
  if (!baseSrc) {
    baseTmp = mkdtempSync(join(tmpdir(), 't1256-base-'));
    baseSrc = join(baseTmp, 'designer.html');
    writeFileSync(baseSrc, execFileSync('git', ['-C', REPO, 'show', `${BASE_TAG}:src/aef-workflow-designer.html`], { maxBuffer: 64 << 20 }));
  }
  const errs = [], report = { ok: false, src: SRC, base: BASE_TAG, minPx: MIN_PX };
  try {
    const lcXml = readFileSync(LIFECYCLE, 'utf8');
    // leg 5
    report.flowLabels = {};
    const lcCfgs = LENSES.flatMap(lens => [{ lens, ids: true }, { lens, ids: false }]);
    const shell = findShell();
    if (!shell) errs.push('leg5: no Playwright headless shell found (the engine the T-1241 lens shots draw with)');
    const runs = [[1440, 900, 'link'], [1920, 1080, 'link'], [1024, 768, 'shot'], [1440, 900, 'shot'], [1920, 1080, 'shot']];
    if (shell) runs.push([1440, 900, 'shell'], [1920, 1080, 'shell']);
    for (const [w, h, how] of runs) {
      const args = { cfgs: lcCfgs, pick: 'tl_create', dump: !!process.env.T1256_DUMP, xml: how === 'link' ? null : lcXml };
      const cfg = await session(SRC, w, h, cmd => ev(cmd, `(${OPEN_CFGS})(${JSON.stringify(args)})`), how === 'link' ? lcXml : null, how === 'shell' ? shell : null);
      for (const [k0, m] of Object.entries(cfg)) {
        const k = how + ' ' + k0;
        const bad = m.hits.filter(x => x.startsWith('el') || x.startsWith('clip') || x.startsWith('ll') || x.startsWith('near') || x.startsWith('head') || x.startsWith('id') || x.startsWith('gw'));
        if (m.dump) report.dump = (report.dump || {}), report.dump[w + ' ' + k] = m.dump;
        report.flowLabels[w + ' ' + k] = `elFlow ${m.elFlow}, ll ${m.ll}, clip ${m.clip}, near ${m.near}, gwFlow ${m.gwFlow}, idFlow ${m.idFlow}, head ${m.head}` + (bad.length ? ': ' + bad.join('; ') : '');
        if (m.near) errs.push(`leg6: aef-task-lifecycle opened at ${w}, ${k}: ${m.hits.filter(x => x.startsWith('near')).join('; ')}`);
        if (m.elFlow || m.ll || m.clip || m.gwFlow || m.idFlow || m.head) errs.push(`leg5: aef-task-lifecycle opened at ${w}, ${k}: ${m.hits.join('; ')}`);
      }
      if (Object.keys(cfg).length !== 8) errs.push(`leg5: ${how} at ${w} measured ${Object.keys(cfg).length} of 8 lens/id configurations`);
    }
    // leg 7 (T-1277): every corpus map opened in the lens-shot state at 1024/1440/1920, lens all, ids on: gateway/event
    // names and id captions crossed by a flow segment or on an arrowhead, no map higher and no higher in total than the
    // placement at SHOT_BASE (the source the T-1241 reviewer's round-3 amber was on); the saved bytes unchanged.
    if (process.env.T1256_ONLY !== 'leg5') {
      let shotBase = process.env.T1256_SHOT_BASE_SRC;
      if (!shotBase) {
        shotTmp = mkdtempSync(join(tmpdir(), 't1256-shot-'));
        shotBase = join(shotTmp, 'designer.html');
        writeFileSync(shotBase, execFileSync('git', ['-C', REPO, 'show', `${SHOT_BASE}:src/aef-workflow-designer.html`], { maxBuffer: 64 << 20 }));
      }
      const shotAt = (src, w, h) => session(src, w, h, async cmd => {
        const maps = {};
        for (const f of corpus) maps[f] = await ev(cmd, `(${SHOT_MAP})(${JSON.stringify({ xml: readFileSync(join(CORPUS_DIR, f), 'utf8') })})`);
        return maps;
      });
      report.corpusShot = {}; const st = [0, 0];
      for (const [w, h] of [[1024, 768], [1440, 900], [1920, 1080]]) {
        const a = await shotAt(shotBase, w, h), b = await shotAt(SRC, w, h);
        for (const f of corpus) {
          const n0 = a[f].gwFlow + a[f].idFlow + a[f].head, n1 = b[f].gwFlow + b[f].idFlow + b[f].head;
          st[0] += n0; st[1] += n1;
          if (n0 || n1) report.corpusShot[w + ' ' + f] = `${n0}->${n1}` + (n1 ? ': ' + b[f].hits.filter(x => /^(gw|id|head) /.test(x)).join('; ') : '');
          if (n1 > n0) errs.push(`leg7: ${f} at ${w} in the lens-shot state: name/caption crossings rose ${n0} -> ${n1}`);
          if (b[f].bytesChanged) errs.push(`leg7: ${f} at ${w}: buildBpmnXml changed after the lens-shot render`);
        }
      }
      report.corpusShotTotal = `${st[0]}->${st[1]}`;
      if (st[1] > st[0]) errs.push(`leg7: corpus total in the lens-shot state rose ${st[0]} -> ${st[1]}`);
    }
    if (process.env.T1256_ONLY === 'leg5') throw new Error('T1256_ONLY=leg5: the other legs were not run');
    const corpusCfgs = [{ lens: 'all', ids: true }, { lens: 'all', ids: false }];
    const now = await session(SRC, 1920, 1080, async cmd => {
      const lc = await runMap(cmd, lcXml, LENSES.flatMap(lens => [{ lens, ids: true }, { lens, ids: false }]));
      const maps = {};
      for (const f of corpus) maps[f] = await runMap(cmd, readFileSync(join(CORPUS_DIR, f), 'utf8'), corpusCfgs);
      return { lc, maps };
    });
    const base = await session(baseSrc, 1920, 1080, async cmd => {
      const maps = {};
      for (const f of corpus) maps[f] = await runMap(cmd, readFileSync(join(CORPUS_DIR, f), 'utf8'), corpusCfgs);
      return { maps };
    });
    // Flow labels at 1440 too (leg 2b): label places follow the text metrics, which followed the zoom before T-1256.
    const corpusAt = src => session(src, 1440, 900, async cmd => {
      const maps = {};
      for (const f of corpus) maps[f] = await runMap(cmd, readFileSync(join(CORPUS_DIR, f), 'utf8'), corpusCfgs);
      return maps;
    });
    const now1440 = await corpusAt(SRC), base1440 = await corpusAt(baseSrc);
    // leg 6 (corpus): nearness against the 0.25.0 placement at 1920 and 1440
    let nearSrc = process.env.T1256_NEAR_BASE_SRC;
    if (!nearSrc) {
      nearTmp = mkdtempSync(join(tmpdir(), 't1256-near-'));
      nearSrc = join(nearTmp, 'designer.html');
      writeFileSync(nearSrc, execFileSync('git', ['-C', REPO, 'show', `${NEAR_TAG}:src/aef-workflow-designer.html`], { maxBuffer: 64 << 20 }));
    }
    const nearAt = (src, w, h) => session(src, w, h, async cmd => {
      const maps = {};
      for (const f of corpus) maps[f] = await runMap(cmd, readFileSync(join(CORPUS_DIR, f), 'utf8'), corpusCfgs);
      return maps;
    });
    const nb1920 = await nearAt(nearSrc, 1920, 1080), nb1440 = await nearAt(nearSrc, 1440, 900);
    const nearOf = maps => Object.values(maps.cfg).reduce((s, m) => s + m.near, 0);
    report.corpusNear = {}; const nt = [0, 0];
    for (const f of corpus) {
      const a = nearOf(nb1920[f]) + nearOf(nb1440[f]), b = nearOf(now.maps[f]) + nearOf(now1440[f]);
      report.corpusNear[f] = `${a}->${b}`;
      nt[0] += a; nt[1] += b;
      if (b > a) errs.push(`leg6: ${f} near pairs rose ${a} -> ${b}: ${Object.values(now.maps[f].cfg).concat(Object.values(now1440[f].cfg)).flatMap(m => m.hits.filter(h => h.startsWith('near'))).join('; ')}`);
    }
    report.corpusNearTotal = `${nt[0]}->${nt[1]}`;
    if (nt[1] > nt[0]) errs.push(`leg6: corpus near pairs rose in total ${nt[0]} -> ${nt[1]}`);
    // leg 1
    report.lifecycle = {};
    for (const [k, m] of Object.entries(now.lc.cfg)) {
      report.lifecycle[k] = { gwFlow: m.gwFlow, idFlow: m.idFlow, head: m.head, ll: m.ll, elFlow: m.elFlow, el: m.hits.filter(h => h.startsWith('el')) };
      if (m.gwFlow || m.idFlow || m.head || m.ll) errs.push(`leg1: aef-task-lifecycle ${k}: ${m.hits.join('; ')}`);
    }
    if (Object.keys(now.lc.cfg).length !== 8) errs.push(`leg1: measured ${Object.keys(now.lc.cfg).length} of 8 lens/id configurations (the source has no lenses?)`);
    if (!Object.values(now.lc.cfg).some(m => m.labels > 20 && m.segs > 20)) errs.push('leg1: almost nothing measured — the check would be vacuous');
    // leg 2
    report.corpus = {};
    let tNow = 0, tBase = 0;
    const elTot = [0, 0], llTot = [0, 0];
    for (const f of corpus) {
      const a = flowSum(base.maps[f]), b = flowSum(now.maps[f]);
      const llA = Object.values(base.maps[f].cfg).reduce((s, m) => s + m.ll, 0), llB = Object.values(now.maps[f].cfg).reduce((s, m) => s + m.ll, 0);
      const elA = Object.values(base.maps[f].cfg).reduce((s, m) => s + m.elFlow, 0), elB = Object.values(now.maps[f].cfg).reduce((s, m) => s + m.elFlow, 0);
      report.corpus[f] = `${a}->${b} (ll ${llA}->${llB}, flow labels crossed ${elA}->${elB})`;
      if (elB > elA) errs.push(`leg2: ${f} flow labels crossed by another flow rose ${elA} -> ${elB}: ${Object.values(now.maps[f].cfg).flatMap(m => m.hits.filter(h => h.startsWith('el'))).join('; ')}`);
      elTot[0] += elA; elTot[1] += elB; llTot[0] += llA; llTot[1] += llB;
      tNow += b; tBase += a;
      if (b > a) errs.push(`leg2: ${f} label/caption-flow crossings rose ${a} -> ${b}: ${Object.values(now.maps[f].cfg).flatMap(m => m.hits.filter(h => !h.startsWith('ll') && !h.startsWith('el'))).join('; ')}`);
    }
    // leg 2b: flow labels crossed by another flow, or cut by another label's pad, at 1920 and 1440: no map worse
    // than the 0.24.0 placement, and fewer in total.
    report.corpusFlowLabels = {};
    const elSum = cfg => Object.values(cfg).reduce((s, m) => s + m.elFlow + m.clip, 0);
    let fl = [0, 0];
    for (const f of corpus) {
      const a = elSum(base.maps[f].cfg) + elSum(base1440[f].cfg), b = elSum(now.maps[f].cfg) + elSum(now1440[f].cfg);
      report.corpusFlowLabels[f] = `${a}->${b}` + (b ? ': ' + Object.entries(now.maps[f].cfg).map(([k, m]) => ['1920 ' + k, m]).concat(Object.entries(now1440[f].cfg).map(([k, m]) => ['1440 ' + k, m]))
        .flatMap(([k, m]) => m.hits.filter(h => h.startsWith('el') || h.startsWith('clip')).map(h => k + ' ' + h)).join('; ') : '');
      fl[0] += a; fl[1] += b;
      if (b > a) errs.push(`leg2b: ${f} flow labels crossed or clipped rose ${a} -> ${b}: ${Object.values(now.maps[f].cfg).concat(Object.values(now1440[f].cfg)).flatMap(m => m.hits.filter(h => h.startsWith('el') || h.startsWith('clip'))).join('; ')}`);
    }
    report.corpusFlowLabelsTotal = `${fl[0]}->${fl[1]}`;
    if (!(fl[1] < fl[0])) errs.push(`leg2b: corpus flow labels crossed or clipped not lower than ${BASE_TAG}: ${fl[0]} -> ${fl[1]}`);
    report.corpusTotal = `${tBase}->${tNow}`;
    report.corpusInfo = `label/label ${llTot[0]}->${llTot[1]}, flow labels crossed by another flow ${elTot[0]}->${elTot[1]} `;
    if (!(tNow < tBase)) errs.push(`leg2: corpus total not lower than ${BASE_TAG}: ${tBase} -> ${tNow}`);
    // leg 3
    const changed = [['aef-task-lifecycle', now.lc]].concat(corpus.map(f => [f, now.maps[f]])).filter(([, r]) => r.bytesChanged.length);
    for (const [f, r] of changed) errs.push(`leg3: ${f}: buildBpmnXml changed after rendering ${r.bytesChanged.join(',')}`);
    report.bytesMaps = 1 + corpus.length - changed.length + '/' + (1 + corpus.length) + ' unchanged';
    // leg 4
    const open = await session(SRC, 1024, 768, cmd => ev(cmd, `(${OPEN_VIEW})()`), lcXml);
    if (!open.adopted) errs.push('leg4: the deep link did not open the map: ' + open.adopted);
    report.open1024 = open;
    // evidence for the decision (not a leg): the fitted size at the other widths
    report.openOther = {};
    for (const [w, h] of [[1440, 900], [1920, 1080]]) report.openOther[w] = await session(SRC, w, h, cmd => ev(cmd, `(${OPEN_VIEW})()`), lcXml);
    if (!(open.minPx >= MIN_PX - 0.01)) errs.push(`leg4: at 1024 the smallest node/gateway text renders at ${open.minPx.toFixed(2)}px (< ${MIN_PX})`);
    if (open.unreachable.length || open.hidden) errs.push(`leg4: at 1024 not every element is reachable: ${open.unreachable.join(',')} hidden=${open.hidden}`);
    if (!open.fitStill) errs.push('leg4: the Fit button no longer fits the whole map');
    if (open.minPx >= MIN_PX - 0.01 && open.zoom != null && !open.scrollable) errs.push('leg4: zoomed in at 1024 but the canvas does not scroll');
  } catch (e) {
    errs.push('exception: ' + (e && e.stack || e));
  } finally {
    if (baseTmp) rmSync(baseTmp, { recursive: true, force: true });
    if (nearTmp) rmSync(nearTmp, { recursive: true, force: true });
    if (shotTmp) rmSync(shotTmp, { recursive: true, force: true });
  }
  report.ok = errs.length === 0; report.errs = errs;
  console.log(JSON.stringify(report, null, 2));
  process.exitCode = errs.length ? 1 : 0;
}
main();
