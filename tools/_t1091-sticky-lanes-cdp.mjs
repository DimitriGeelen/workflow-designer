#!/usr/bin/env node
// _t1091-sticky-lanes-cdp.mjs — verify T-1091: zoomed in and scrolled right, every lane's name stays at the canvas's
// left edge (a copy of each header in #g-sticky-lanes, above nodes and edges), aligned with its own lane; unscrolled
// nothing is drawn; a click on a pinned name selects the lane; Settings "Sticky lane labels" (default on, persisted in
// aefLabelPrefs) turns it off, as does "Show lane names" off; the BPMN export is the same either way and thumbnails
// carry no copies.
//
// Same harness as _t1177 (gallery-serve.py temp docroot, ISOLATED headless chromium); clicks are real CDP mouse input.
// Writes .playwright-mcp/t1091-<width>-{unscrolled,scrolled,scrolled-down,off}.png at 1024/1440/1920 for the visual
// review (CLAUDE.md, T-1174). T1091_DESIGNER=<file> runs it against another build (the control: the pre-T-1091 designer
// must fail the pinned-name legs).
// Exit 0 = pass. Exit 1 = a step failed. Exit 2 = harness could not run.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SHOTDIR = join(REPO, '.playwright-mcp');
const MAP = 'task-lifecycle';
const WIDTHS = [1024, 1440, 1920];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// In the page: geometry of the pinned copies against the wrap and the original headers.
const PROBE = `(function(){
  var g = document.getElementById('g-sticky-lanes');
  var wrap = document.querySelector('.canvas-wrap'), wr = wrap.getBoundingClientRect();
  var orig = Array.prototype.slice.call(document.querySelectorAll('#g-pool > .lane-header'));
  var pins = g ? Array.prototype.slice.call(g.children) : [];
  var rows = pins.map(function(p){
    var r = p.querySelector('rect').getBoundingClientRect();
    var o = orig.filter(function(h){ return h.getAttribute('data-lane-id') === p.getAttribute('data-lane-id'); })[0];
    var orr = o ? o.querySelector('rect').getBoundingClientRect() : null;
    var label = p.querySelector('.lane-label');
    // 60% across the strip: the palette's fold tab (T-1177) covers the canvas's left edge at mid-height, by design.
    var mx = r.left + r.width * 0.6, my = r.top + r.height / 2, hit = null;
    if (my > wr.top && my < wr.bottom) { var e = document.elementFromPoint(mx, my); hit = e ? !!e.closest('#g-sticky-lanes') : false; }
    return { lane: p.getAttribute('data-lane-id'), left: r.left, top: r.top, h: r.height,
             origTop: orr ? orr.top : null, origH: orr ? orr.height : null, label: label ? label.textContent : '', onTop: hit, mx: mx, my: my };
  });
  return { layer: !!g, pins: pins.length, lanes: orig.length, wrapLeft: wr.left + wrap.clientLeft, wrapTop: wr.top, wrapBottom: wr.bottom,
           scrollLeft: wrap.scrollLeft, scrollTop: wrap.scrollTop, maxLeft: wrap.scrollWidth - wrap.clientWidth,
           maxTop: wrap.scrollHeight - wrap.clientHeight, zoomed: zoomFactor != null, rows: rows };
})()`;

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't1091-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1091-repo-'));
  copyFileSync(process.env.T1091_DESIGNER || join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1091-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const steps = [], shots = [];
  const push = (n, p, g) => steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    const URL = `${BASE}/designer.html?load=rendered/${MAP}.bpmn`;
    const open = async (w, clear) => {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: 860, deviceScaleFactor: 1, mobile: false });
      if (clear) { await cmd('Page.navigate', { url: URL }); await sleep(300); await waitReady(cmd); await ev(cmd, `localStorage.removeItem('aefLabelPrefs'), localStorage.removeItem('aefViewPrefs'), 1`); }
      await cmd('Page.navigate', { url: URL });
      await sleep(300); await waitReady(cmd); await sleep(500);
      await ev(cmd, `document.fonts.ready.then(function(){ return new Promise(function(r){ setTimeout(r, 250); }); })`);
    };
    // Zoom so the diagram is at least twice the wrap's width, anchored at the wrap's top-left.
    const zoomIn = () => ev(cmd, `(function(){ var w = document.querySelector('.canvas-wrap'), r = w.getBoundingClientRect();
      var vb = svg.viewBox.baseVal; setZoom(Math.max(1.6, 2.2 * w.clientWidth / vb.width), r.left + 1, r.top + 1);
      w.scrollLeft = 0; w.scrollTop = 0; return new Promise(function(res){ setTimeout(function(){ res(zoomFactor); }, 200); }); })()`);
    const scrollTo = (x, y) => ev(cmd, `(function(){ var w = document.querySelector('.canvas-wrap');
      w.scrollLeft = ${x === 'max' ? 'w.scrollWidth' : x}; w.scrollTop = ${y === 'max' ? 'w.scrollHeight' : y};
      return new Promise(function(res){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ res(1); }); }); }); })()`);
    const probe = () => ev(cmd, PROBE);
    const shot = async name => {
      const { data } = await cmd('Page.captureScreenshot', { format: 'png' });
      mkdirSync(SHOTDIR, { recursive: true });
      const f = join(SHOTDIR, `t1091-${name}.png`); writeFileSync(f, Buffer.from(data, 'base64')); shots.push(f);
    };
    const aligned = p => p.rows.length === p.lanes && p.rows.every(r => Math.abs(r.left - p.wrapLeft) <= 2
      && r.origTop != null && Math.abs(r.top - r.origTop) <= 1 && Math.abs(r.h - r.origH) <= 1 && r.label.length > 0);

    for (const w of WIDTHS) {
      await open(w, true);
      let p = await probe();
      push(`${w} fit mode: layer present, nothing pinned`, p.layer && p.pins === 0 && !p.zoomed, { layer: p.layer, pins: p.pins, zoomed: p.zoomed });
      await zoomIn(); await scrollTo(0, 0);
      p = await probe();
      push(`${w} zoomed, scroll 0: nothing pinned (pool's left edge in view)`, p.zoomed && p.pins === 0 && p.maxLeft > 200, { pins: p.pins, maxLeft: p.maxLeft });
      await shot(`${w}-unscrolled`);
      await scrollTo(Math.round(p.maxLeft * 0.6), 0);
      p = await probe();
      push(`${w} scrolled right: every lane pinned at the left edge, at its own lane's height, named`, p.scrollLeft > 100 && aligned(p),
           { scrollLeft: p.scrollLeft, pins: p.pins, lanes: p.lanes, rows: p.rows.map(r => [r.lane, Math.round(r.left - p.wrapLeft), Math.round(r.top - r.origTop), r.label]) });
      const vis = p.rows.filter(r => r.onTop !== null);
      push(`${w} scrolled right: the pinned names are on top of the diagram`, vis.length > 0 && vis.every(r => r.onTop), vis.map(r => [r.lane, r.onTop]));
      await shot(`${w}-scrolled`);
      if (p.maxTop > 20) {
        await scrollTo(Math.round(p.maxLeft * 0.6), 'max');
        const q = await probe();
        push(`${w} scrolled right and down: still at the left edge and aligned with their lanes`, q.scrollTop > 10 && aligned(q), { scrollTop: q.scrollTop, rows: q.rows.map(r => [r.lane, Math.round(r.top - r.origTop)]) });
        await shot(`${w}-scrolled-down`);
        await scrollTo(Math.round(p.maxLeft * 0.6), 0);
        p = await probe();
      } else {
        push(`${w} scrolled right and down: map fits vertically, nothing to scroll (maxTop ${p.maxTop})`, true, { maxTop: p.maxTop });
      }
      // A real click on the first visible pinned name selects its lane.
      const tgt = p.rows.find(r => r.onTop);
      if (tgt) {
        for (const type of ['mouseMoved', 'mousePressed', 'mouseReleased'])
          await cmd('Input.dispatchMouseEvent', { type, x: tgt.mx, y: tgt.my, button: 'left', clickCount: 1 });
        await sleep(200);
        const sel = await ev(cmd, `selection ? { kind: selection.kind, id: selection.id } : null`);
        push(`${w} click on a pinned name selects that lane`, sel && sel.kind === 'lane' && sel.id === tgt.lane, { want: tgt.lane, got: sel });
        await ev(cmd, `(selection = null, renderAll(), 1)`); await sleep(150);
      } else push(`${w} click on a pinned name selects that lane`, false, 'no pinned name on screen');

      // Export: BPMN identical with the option on and off, while scrolled.
      const onXml = await ev(cmd, `buildBpmnXml(state)`);
      await ev(cmd, `(setLabelPref('stickyLanes', false), 1)`); await sleep(150);
      p = await probe();
      const offXml = await ev(cmd, `buildBpmnXml(state)`);
      push(`${w} option off: nothing pinned while scrolled`, p.pins === 0 && p.scrollLeft > 100, { pins: p.pins });
      push(`${w} BPMN export identical with the option on and off`, onXml === offXml && onXml.length > 1000, { len: onXml.length });
      await shot(`${w}-off`);
      await ev(cmd, `(setLabelPref('stickyLanes', true), 1)`); await sleep(150);
      p = await probe();
      push(`${w} option back on: pinned again`, p.pins === p.lanes && p.pins > 0, { pins: p.pins });
    }

    // Persistence: off survives a reload, the checkbox follows it; "Show lane names" off pins nothing.
    await open(1440, true);
    await ev(cmd, `(setLabelPref('stickyLanes', false), 1)`);
    await open(1440, false);
    await zoomIn(); { const p0 = await probe(); await scrollTo(Math.round(p0.maxLeft * 0.6), 0); }
    let p = await probe();
    const box = await ev(cmd, `({ checked: document.getElementById('set-sticky-lanes').checked, stored: JSON.parse(localStorage.getItem('aefLabelPrefs') || '{}').stickyLanes })`);
    push('option off survives a reload (stored, checkbox unchecked, nothing pinned)', box.stored === false && box.checked === false && p.pins === 0, { box, pins: p.pins });
    await ev(cmd, `(setLabelPref('stickyLanes', true), 1)`); await sleep(150);
    await ev(cmd, `(setLabelPref('showLane', false), 1)`); await sleep(150);
    p = await probe();
    push('"Show lane names" off: nothing pinned', p.pins === 0, { pins: p.pins });
    await ev(cmd, `(setLabelPref('showLane', true), 1)`); await sleep(150);
    p = await probe();
    push('default is on: a fresh profile pins while scrolled', p.pins === p.lanes && p.pins > 0, { pins: p.pins });

    // Thumbnail: the serialised clone carries an EMPTY sticky layer while the live one is populated.
    const th = await ev(cmd, `(function(){ var orig = XMLSerializer.prototype.serializeToString, seen = [];
      XMLSerializer.prototype.serializeToString = function(n){ var s = orig.call(this, n); seen.push(s); return s; };
      var live = document.getElementById('g-sticky-lanes').children.length;
      return captureThumbnail().then(function(){ XMLSerializer.prototype.serializeToString = orig;
        var x = seen.filter(function(s){ return s.indexOf('g-sticky-lanes') >= 0; })[0] || '';
        var m = x.match(/<g id="g-sticky-lanes"[^>]*?(\\/>|>([\\s\\S]*?)<\\/g>)/);   // an empty <g> serialises self-closing
        return { live: live, found: !!x, inner: m ? (m[1] === '/>' ? 0 : m[2].length) : -1 }; }); })()`);
    push('thumbnail carries no pinned copies (live layer populated, thumbnail layer empty)', th.found && th.live > 0 && th.inner === 0, th);
  } catch (e) {
    push('harness', false, String(e && e.stack || e)); process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    await sleep(300);
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
  for (const s of steps) console.log((s.pass ? 'ok    ' : 'FAIL  ') + s.step + (s.pass ? '' : '  got: ' + JSON.stringify(s.got)));
  const failed = steps.filter(s => !s.pass).length;
  console.log(`${failed ? 'FAIL' : 'PASS'}: ${steps.length - failed}/${steps.length}` + (shots.length ? `  (${shots.length} screenshots in .playwright-mcp/)` : ''));
  if (process.exitCode !== 2) process.exitCode = failed ? 1 : 0;
}
main();
