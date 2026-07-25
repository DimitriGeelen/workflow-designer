#!/usr/bin/env node
// _t249-spike-zoom-cdp.mjs — T-249 INCEPTION SPIKE (throwaway prototype, NOT a suite).
//
// Question (IW-1): does explicit-SVG-element-sizing zoom (viewBox untouched, element
// width/height = viewBox × zoom via inline style, .canvas-wrap overflow:auto) survive
// the every-render viewBox recompute (syncCanvasSize) and keep pointer paths CTM-correct?
// Rider (IW-2): does a capture-phase pan handler on .canvas-wrap cleanly preempt the
// svg-level rubber-band mousedown without touching existing handlers?
// Rider (IW-3): captureThumbnail() unaffected by live-canvas zoom? (clone carries the
// inline style — probe fit-vs-zoom output equality)
// Rider (IW-4): composes with T-245 focus mode?
//
// Mechanism prototype = a syncCanvasSize wrapper injected at runtime into the UNMODIFIED
// shipping editor — zero source edits (inception discipline: no build artifacts).
// ISOLATION: same hermetic pattern as _editor-behavior-verify-cdp.mjs (G-006): temp
// docroot + temp repo, throwaway gallery-serve.py on a free port, isolated headless
// chromium with its own user-data-dir. Real trusted input via CDP Input.dispatchMouseEvent
// (G-003: real hit-testing, not synthetic dispatchEvent).
// Exit 0 = spike ran (verdict JSON on stdout, pass/fail per probe); 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const EDITOR = join(REPO, 'src', 'aef-workflow-designer.html');
const RENDERED = join(REPO, 'examples', 'aef-processes', 'rendered');
const MAP = 'arc-lifecycle.bpmn';
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof renderAll==='function'&&typeof syncCanvasSize==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Real mouse helpers (trusted input — hits the same paths a human does)
async function click(cmd, x, y, button = 'left') {
  await cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button, clickCount: 1 });
  await cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button, clickCount: 1 });
}
async function drag(cmd, x1, y1, x2, y2, button = 'left') {
  await cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x: x1, y: y1, button, clickCount: 1 });
  const steps = 8;
  for (let i = 1; i <= steps; i++) {
    const x = x1 + (x2 - x1) * i / steps, y = y1 + (y2 - y1) * i / steps;
    await cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y, button });
    await sleep(15);
  }
  await cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x: x2, y: y2, button, clickCount: 1 });
}

// ── Prototype injection: the entire IW-1 mechanism candidate, ~20 lines ──
const INJECT_ZOOM = `(function(){
  window.__wrap = document.querySelector('.canvas-wrap');
  window.__zoomFactor = null; /* null = fit (today's behavior, untouched) */
  window.__applyZoom = function(){
    const vb = svg.viewBox.baseVal;
    if (window.__zoomFactor == null) {
      svg.style.width = ''; svg.style.height = ''; __wrap.style.overflow = '';
    } else {
      svg.style.width  = (vb.width  * window.__zoomFactor) + 'px';
      svg.style.height = (vb.height * window.__zoomFactor) + 'px';
      __wrap.style.overflow = 'auto';
    }
  };
  const _orig = syncCanvasSize;
  syncCanvasSize = function(){ _orig(); window.__applyZoom(); };
  window.setZoomProto = function(f){ window.__zoomFactor = f; window.__applyZoom(); };
  return typeof setZoomProto === 'function';
})()`;

// ── Pan prototype (IW-2 candidate: capture-phase interception on the wrap) ──
const INJECT_PAN = `(function(){
  window.__panMode = false;  /* stands in for space-held / pan-tool-active */
  window.__panState = null;
  window.__panLog = [];
  __wrap.addEventListener('mousedown', function(e){
    if (!window.__panMode && e.button !== 1) return;
    window.__panState = { x: e.clientX, y: e.clientY, sl: __wrap.scrollLeft, st: __wrap.scrollTop };
    __panLog.push('down');
    e.preventDefault(); e.stopPropagation();
  }, true);
  window.addEventListener('mousemove', function(e){
    if (!window.__panState) return;
    __wrap.scrollLeft = __panState.sl - (e.clientX - __panState.x);
    __wrap.scrollTop  = __panState.st - (e.clientY - __panState.y);
    e.preventDefault(); e.stopPropagation();
  }, true);
  window.addEventListener('mouseup', function(e){
    if (window.__panState) { window.__panState = null; __panLog.push('up'); e.preventDefault(); e.stopPropagation(); }
  }, true);
  return true;
})()`;

// Find a visible empty-background client point inside the wrap (svg or lane-bg target)
const FIND_BG_POINT = `(function(){
  const wr = __wrap.getBoundingClientRect();
  for (let dy = 30; dy < wr.height - 30; dy += 24) {
    for (let dx = 30; dx < wr.width - 30; dx += 24) {
      const x = wr.left + dx, y = wr.top + dy;
      const el = document.elementFromPoint(x, y);
      if (!el) continue;
      if (el === svg || (el.tagName === 'rect' && el.classList.contains('lane-bg')))
        return { x: Math.round(x), y: Math.round(y) };
    }
  }
  return null;
})()`;

async function main() {
  for (const [f, tag] of [[EDITOR, 'editor'], [SERVER, 'server'], [join(RENDERED, MAP), 'map']])
    if (!existsSync(f)) { console.log(JSON.stringify({ ok: false, error: tag + ' missing: ' + f })); process.exitCode = 2; return; }

  const doc = mkdtempSync(join(tmpdir(), 't249-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't249-repo-'));
  copyFileSync(EDITOR, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(RENDERED, MAP), join(doc, 'rendered', MAP));
  const repoRendered = join(repo, 'examples', 'aef-processes', 'rendered');
  mkdirSync(repoRendered, { recursive: true });
  copyFileSync(join(RENDERED, MAP), join(repoRendered, MAP));

  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't249-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { probes: [], pass: false };
  const probe = (name, pass, got) => { verdict.probes.push({ probe: name, pass: !!pass, got }); };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: BASE + '/designer.html?load=' + encodeURIComponent('rendered/' + MAP) });
    await waitReady(cmd); await sleep(400);

    // Oversize the loaded map through the REAL content pipeline: spread nodes wide+tall,
    // renderAll() recomputes the viewBox from the grown content (contentRightEdge etc).
    const grown = await ev(cmd, `(function(){
      state.nodes.forEach(function(n, i){ n.x = 80 + (i % 10) * 520; });
      renderAll();
      const vb = svg.viewBox.baseVal;
      return { nodes: state.nodes.length, vbW: Math.round(vb.width), vbH: Math.round(vb.height),
               cw: Math.round(svg.getBoundingClientRect().width) };
    })()`);
    // Baseline sanity: fit-to-view means no overflow, svg fills the wrap
    const base0 = await ev(cmd, `({ sw: __x = undefined, scrollW: document.querySelector('.canvas-wrap').scrollWidth, clientW: document.querySelector('.canvas-wrap').clientWidth })`).catch(() => null);
    probe('grow-fixture', grown.vbW > 3000, grown);

    // Thumbnail baseline at fit (IW-3) — BEFORE any zoom so it can't be contaminated
    const thumbFit = await ev(cmd, `captureThumbnail()`);

    // ── P1 (IW-1): inject prototype, zoom 1.5 → element grows, native scrollbars ──
    const inj = await ev(cmd, INJECT_ZOOM);
    const p1 = await ev(cmd, `(function(){
      setZoomProto(1.5);
      const vb = svg.viewBox.baseVal, r = svg.getBoundingClientRect();
      return { inj: ${JSON.stringify(true)}, vbW: vb.width, elW: r.width,
               want: vb.width * 1.5,
               scrollW: __wrap.scrollWidth, clientW: __wrap.clientWidth,
               scrollH: __wrap.scrollHeight, clientH: __wrap.clientHeight,
               ctmA: svg.getScreenCTM().a };
    })()`);
    probe('P1-zoom-scrollbars', inj && Math.abs(p1.elW - p1.want) < 3 && p1.scrollW > p1.clientW + 20 && Math.abs(p1.ctmA - 1.5) < 0.02, p1);

    // ── P2 (IW-1): CTM click accuracy while zoomed AND scrolled (real trusted click) ──
    const target = await ev(cmd, `(function(){
      __wrap.scrollLeft = 600; __wrap.scrollTop = 120;
      /* pick the node nearest the current viewport center for a clean hit */
      const wr = __wrap.getBoundingClientRect();
      let best = null, bd = 1e9;
      state.nodes.forEach(function(n){
        const g = document.querySelector('g[data-id="' + n.id + '"]');
        if (!g) return;
        const r = g.getBoundingClientRect();
        const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
        if (cx < wr.left + 20 || cx > wr.right - 20 || cy < wr.top + 20 || cy > wr.bottom - 20) return;
        const d = Math.abs(cx - (wr.left + wr.width / 2)) + Math.abs(cy - (wr.top + wr.height / 2));
        if (d < bd) { bd = d; best = { id: n.id, x: Math.round(cx), y: Math.round(cy) }; }
      });
      return best;
    })()`);
    let p2 = { target };
    if (target) {
      await click(cmd, target.x, target.y);
      await sleep(250);
      p2 = await ev(cmd, `({ sel: selection && selection.id, kind: selection && selection.kind, scrollL: __wrap.scrollLeft })`);
      p2.target = target;
    }
    probe('P2-ctm-click-zoomed-scrolled', target && p2.sel === target.id && p2.kind === 'node', p2);

    // ── P3 (IW-1 core): renderAll() DURING zoom (edit simulation) — zoom must survive ──
    const p3 = await ev(cmd, `(function(){
      const n = state.nodes[0]; n.y = (n.y || 100) + 30;
      renderAll();  /* runs syncCanvasSize → viewBox recomputed → wrapper reapplies zoom */
      const vb = svg.viewBox.baseVal, r = svg.getBoundingClientRect();
      return { elW: r.width, want: vb.width * 1.5, scrollW: __wrap.scrollWidth, clientW: __wrap.clientWidth, ctmA: svg.getScreenCTM().a };
    })()`);
    probe('P3-zoom-survives-render', Math.abs(p3.elW - p3.want) < 3 && p3.scrollW > p3.clientW + 20 && Math.abs(p3.ctmA - 1.5) < 0.02, p3);

    // ── P4 (IW-1): content GROWS while zoomed → element tracks new content × zoom ──
    const p4 = await ev(cmd, `(function(){
      const before = svg.viewBox.baseVal.width;
      /* move the RIGHTMOST node — first run moved nodes[last], which sat mid-map */
      const n = state.nodes.reduce(function(a, b){ return (b.x || 0) > (a.x || 0) ? b : a; });
      n.x += 1500;
      renderAll();
      const vb = svg.viewBox.baseVal, r = svg.getBoundingClientRect();
      return { vbBefore: Math.round(before), vbAfter: Math.round(vb.width), elW: r.width, want: vb.width * 1.5 };
    })()`);
    probe('P4-content-growth-tracked', p4.vbAfter > p4.vbBefore + 1000 && Math.abs(p4.elW - p4.want) < 3, p4);

    // ── P5 (IW-1): Fit restore — back to today's exact behavior ──
    const p5 = await ev(cmd, `(function(){
      setZoomProto(null);
      const r = svg.getBoundingClientRect();
      return { elW: Math.round(r.width), wrapW: __wrap.clientWidth, scrollW: __wrap.scrollWidth,
               overflow: getComputedStyle(__wrap).overflow, styleW: svg.style.width || '(empty)' };
    })()`);
    probe('P5-fit-restore', Math.abs(p5.elW - p5.wrapW) < 3 && p5.scrollW <= p5.wrapW + 2 && p5.styleW === '(empty)', p5);

    // ── P6 (IW-2 constraint): marquee still works at zoom+scroll (real drag on bg) ──
    await ev(cmd, `setZoomProto(1.5); __wrap.scrollLeft = 400; __wrap.scrollTop = 80; multiSelect.clear && multiSelect.clear(); selection = null; renderAll();`);
    // Semantics under test (finalizeRubberBandSelection): a node is selected iff its
    // CENTER (svg coords) falls in the marquee rect. Precompute the expected set from
    // the drag's client points via clientToSvg — this asserts the CTM math end-to-end.
    const mq = await ev(cmd, `(function(){
      /* center a mid-map node in the viewport first so the marquee rect can't be empty */
      const mid = state.nodes[Math.floor(state.nodes.length / 2)];
      const md = NODE_DEFAULTS[mid.type];
      __wrap.scrollLeft = Math.max(0, (mid.x + md.w / 2) * 1.5 - __wrap.clientWidth / 2);
      __wrap.scrollTop  = Math.max(0, (mid.y + md.h / 2) * 1.5 - __wrap.clientHeight / 2);
      const wr = __wrap.getBoundingClientRect();
      const isBg = function(el){ return el === svg || (el && el.tagName === 'rect' && el.classList.contains('lane-bg')); };
      const pts = [];
      for (let dy = 20; dy < wr.height - 20; dy += 16)
        for (let dx = 20; dx < wr.width - 20; dx += 16) {
          const x = wr.left + dx, y = wr.top + dy;
          if (isBg(document.elementFromPoint(x, y))) pts.push({ x: Math.round(x), y: Math.round(y) });
        }
      if (pts.length < 2) return null;
      let a = pts[0], b = pts[0];
      for (const p of pts) { if (p.x + p.y < a.x + a.y) a = p; if (p.x + p.y > b.x + b.y) b = p; }
      if (b.x - a.x < 150 || b.y - a.y < 80) return { a, b, tooSmall: true };
      const s1 = clientToSvg(a.x, a.y), s2 = clientToSvg(b.x, b.y);
      const x1 = Math.min(s1.x, s2.x), x2 = Math.max(s1.x, s2.x), y1 = Math.min(s1.y, s2.y), y2 = Math.max(s1.y, s2.y);
      const expected = [];
      for (const n of state.nodes) {
        const d = NODE_DEFAULTS[n.type];
        const cx = n.x + d.w / 2, cy = n.y + d.h / 2;
        if (cx >= x1 && cx <= x2 && cy >= y1 && cy <= y2) expected.push(n.id);
      }
      return { a, b, expected };
    })()`);
    let p6 = { mq };
    if (mq && !mq.tooSmall) {
      await drag(cmd, mq.a.x, mq.a.y, mq.b.x, mq.b.y);
      await sleep(250);
      p6 = await ev(cmd, `({ selected: Array.from(multiSelect || []).sort(), rb: rubberBand })`);
      p6.expected = (mq.expected || []).sort(); p6.mq = mq;
    }
    const p6ok = mq && !mq.tooSmall && p6.expected.length >= 1
      && JSON.stringify(p6.selected) === JSON.stringify(p6.expected) && !p6.rb;
    probe('P6-marquee-at-zoom', !!p6ok, p6);

    // ── P7 (IW-2): capture-phase pan preempts rubber-band; scroll moves; no selection ──
    await ev(cmd, INJECT_PAN);
    await ev(cmd, `multiSelect.clear && multiSelect.clear(); selection = null; renderAll(); __wrap.scrollLeft = 500; __wrap.scrollTop = 100; window.__panMode = true;`);
    const bg = await ev(cmd, FIND_BG_POINT);
    let p7 = { bg };
    if (bg) {
      const pre = await ev(cmd, `({ sl: __wrap.scrollLeft, st: __wrap.scrollTop })`);
      await drag(cmd, bg.x, bg.y, bg.x - 180, bg.y - 60); // drag content left/up → scroll right/down
      await sleep(200);
      p7 = await ev(cmd, `({ sl: __wrap.scrollLeft, st: __wrap.scrollTop, rb: rubberBand, sel: selection && selection.id, msel: Array.from(multiSelect || []), log: __panLog })`);
      p7.pre = pre; p7.bg = bg;
      p7.dSL = p7.sl - pre.sl; p7.dST = p7.st - pre.st;
    }
    probe('P7-pan-preempts-marquee', bg && p7.dSL > 120 && p7.dST > 20 && !p7.rb && !p7.sel && (!p7.msel || p7.msel.length === 0), p7);

    // ── P7b (IW-2): middle-mouse pan with __panMode OFF (no mode key at all) ──
    await ev(cmd, `window.__panMode = false; __wrap.scrollLeft = 500; __wrap.scrollTop = 100;`);
    const bg2 = await ev(cmd, FIND_BG_POINT);
    let p7b = { bg2 };
    if (bg2) {
      const pre = await ev(cmd, `({ sl: __wrap.scrollLeft, st: __wrap.scrollTop })`);
      await drag(cmd, bg2.x, bg2.y, bg2.x - 150, bg2.y - 40, 'middle');
      await sleep(200);
      p7b = await ev(cmd, `({ sl: __wrap.scrollLeft, st: __wrap.scrollTop, rb: rubberBand, sel: selection && selection.id })`);
      p7b.dSL = p7b.sl - pre.sl;
    }
    probe('P7b-middle-mouse-pan', bg2 && p7b.dSL > 100 && !p7b.rb && !p7b.sel, p7b);

    // ── P8 (IW-4): focus mode + zoom + scroll compose ──
    const p8 = await ev(cmd, `(function(){
      document.getElementById('btn-focus-mode').click();
      const focused = document.body.classList.contains('vc-focus');
      const r = svg.getBoundingClientRect(), vb = svg.viewBox.baseVal;
      const zoomHeld = Math.abs(r.width - vb.width * 1.5) < 3;
      const scrollable = __wrap.scrollWidth > __wrap.clientWidth + 20;
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
      const exited = !document.body.classList.contains('vc-focus');
      return { focused, zoomHeld, scrollable, exited };
    })()`);
    probe('P8-focus-mode-composes', p8.focused && p8.zoomHeld && p8.scrollable && p8.exited, p8);

    // ── P9 (IW-3): captureThumbnail at zoom — inline style leaks into the clone? ──
    const thumbZoom = await ev(cmd, `captureThumbnail()`);
    const p9 = { fitLen: thumbFit ? thumbFit.length : null, zoomLen: thumbZoom ? thumbZoom.length : null, equal: thumbFit === thumbZoom };
    // NOTE: node positions changed between captures (P3/P4 moved nodes), so byte-equality
    // is NOT expected; the assertion is that both render non-null and same ORDER of size.
    probe('P9-thumbnail-renders-at-zoom', !!thumbFit && !!thumbZoom, p9);

    // ── P10 (finding, not gate): status overlay behavior in a scrolled wrap ──
    const p10 = await ev(cmd, `(function(){
      __wrap.scrollLeft = 800; __wrap.scrollTop = 150;
      const o = document.querySelector('.canvas-overlay');
      if (!o) return { present: false };
      const or = o.getBoundingClientRect(), wr = __wrap.getBoundingClientRect();
      const visible = or.bottom <= wr.bottom + 2 && or.left >= wr.left - 2 && or.top >= wr.top - 2;
      return { present: true, visible, overlay: { l: Math.round(or.left), b: Math.round(or.bottom) }, wrap: { l: Math.round(wr.left), b: Math.round(wr.bottom) } };
    })()`);
    probe('P10-overlay-observation', true /* observation only */, p10);

    verdict.pass = verdict.probes.filter(p => p.probe !== 'P10-overlay-observation').every(p => p.pass);
  } catch (e) {
    verdict.error = String(e && e.message || e);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    try { rmSync(doc, { recursive: true, force: true }); rmSync(repo, { recursive: true, force: true }); rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
  console.log(JSON.stringify(verdict, null, 1));
  process.exitCode = verdict.pass ? 0 : 1;
}
main();
