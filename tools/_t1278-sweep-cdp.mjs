#!/usr/bin/env node
// _t1278-sweep-cdp.mjs — T-1278: the codex advisory sweep of the 48 T-1241 lens shots at 2015e17e
// (.context/reviews/advisory/T-1241-codex-sweep-2015e17e.md, items 1-11).
// Drives the REAL editor headless (gallery-serve.py + the interim lens file). Every map is opened the way
// tools/_t1241-lens-shots.py opens it: adopt, renderAll, openingZoom, setLens, the task `tl_create` selected.
// Legs:
//   1. readable opening (items 6-7): on aef-task-lifecycle at 1024/1440/1920, in every lens, the smallest drawn node
//      name, flow label, id caption (technical/all) and lane caption is >= 9 px; Fit still shows the whole map;
//   2. reachability (items 1-3, 5): with the side panel open, at 1024 and 1440, every drawn text and node shape is
//      brought fully into the visible canvas by scrolling it and nothing outside the map covers it, and at the
//      furthest scroll the pool's right and bottom edges are inside the visible canvas; the left palette scrolls to
//      its last control (the LANES item) and every palette control can be scrolled into view, at 1024/1440/1920;
//   3. Name field (item 4): on every corpus map (examples/aef-processes/rendered, 24) and aef-task-lifecycle at 1440,
//      and on aef-task-lifecycle at 1024 and 1920, every named node's side-panel Name box shows its whole value
//      (scrollWidth <= clientWidth and scrollHeight <= clientHeight); real keystrokes (CDP) type into it without
//      losing focus, a pasted line break becomes a space, Enter ends the edit, and no newline is stored;
//   4. business-lens palette (item 10): in the business lens no palette subtitle names a BPMN type or an execution
//      term; in every other lens each subtitle is the one written in the palette's HTML;
//   5. helper-text contrast (item 11): every drawn .field-hint in the side panel and in the details view has a
//      contrast ratio >= 4.5:1 against the background it is drawn on;
//   6. bytes: buildBpmnXml is identical before and after every leg on every map (all of it is display only).
// T1278_SRC substitutes another designer file (2015e17e: legs 1, 3, 4, 5 must go red). T1278_ONLY=leg1,leg3 runs a
// subset. Exit 0 = green; 1 = red; 2 = misconfig.
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
const SRC = process.env.T1278_SRC || join(REPO, 'src/aef-workflow-designer.html');
const LIFECYCLE = join(REPO, '.agentic-framework/.context/designer/projects/aef-task-lifecycle/v3.bpmn');
const CORPUS_DIR = join(REPO, 'examples/aef-processes/rendered');
const LENSFILE = join(REPO, 'lens-definition.interim.json');
const ONLY = (process.env.T1278_ONLY || '').split(',').filter(Boolean);
const run = leg => !ONLY.length || ONLY.includes(leg);
const MIN_PX = 9, MIN_CONTRAST = 4.5;
const WIDTHS = [[1024, 768], [1440, 900], [1920, 1080]];
const LENSES = ['business', 'logical', 'technical', 'all'];
// item 10: words a business reader should not meet in a palette subtitle
const TECH_WORDS = /startEvent|endEvent|Event\b|Task\b|Gateway|status:|cron|horizon|bus topic|composite|fork|join|\bfw\b/;
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }
async function key(cmd, k) {
  if (k === 'Enter') {
    await cmd('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13, text: '\r' });
    await cmd('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 });
  } else await cmd('Input.insertText', { text: k });
  await sleep(60);
}

// In-page helpers, defined once per page. open() is the lens-shot load; nameBox() the side panel's Name field.
const HELPERS = `(function(){
  window.__t1278 = {
    frame: function(){ return new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); }); },
    open: async function(xml, lens, uid){
      adoptImportedXml(xml, { userImport: true }); renderAll();
      var base = buildBpmnXml(state);
      if (typeof openingZoom === 'function') openingZoom();
      if (typeof setLens === 'function') setLens(lens);
      var n = (uid && state.nodes.find(function(x){ return x.uid === uid; })) || state.nodes.find(function(x){ return /Task$/.test(x.type); });
      if (n) { selection = { kind: 'node', id: n.id }; renderProperties(); }
      await new Promise(function(r){ setTimeout(r, 150); }); await __t1278.frame();
      return base;
    },
    nameBox: function(){ var fs = document.querySelectorAll('#properties .field'); for (var i = 0; i < fs.length; i++) {
      var l = fs[i].querySelector('.field-label'); if (l && l.firstChild && l.firstChild.textContent.trim() === 'Name') return fs[i].querySelector('input, textarea'); } return null; }
  };
  return true;
})()`;

// Leg 1: drawn text sizes per class, and Fit.
const LEG1 = `(async function(args){
  var out = {};
  for (var li = 0; li < args.lenses.length; li++) {
    var lens = args.lenses[li];
    var base = await __t1278.open(args.xml, lens, 'tl_create');
    var ctm = svg.getScreenCTM().a, min = {};
    [['name', 'text.node-label'], ['flow', 'text.edge-label'], ['id', 'text.node-id-badge'], ['lane', 'text.lane-label']].forEach(function(c){
      Array.prototype.forEach.call(svg.querySelectorAll(c[1]), function(t){ if (!t.getBoundingClientRect().width) return;
        var px = parseFloat(getComputedStyle(t).fontSize) * ctm; if (!(c[0] in min) || px < min[c[0]].px) min[c[0]] = { px: +px.toFixed(2), text: t.textContent.slice(0, 40) }; });
    });
    var z0 = zoomFactor; document.getElementById('btn-zoom-fit').click(); await __t1278.frame();
    var fit = { fitStill: zoomFactor === null, fits: canvasWrap.scrollWidth <= canvasWrap.clientWidth + 1 && canvasWrap.scrollHeight <= canvasWrap.clientHeight + 1 };
    out[lens] = { zoom: z0, min: min, fit: fit, bytesSame: buildBpmnXml(state) === base };
  }
  return out;
})`;

// Leg 2a: every drawn text and node shape on the canvas can be scrolled fully into view, uncovered; the pool's far edges.
const LEG2_CANVAS = `(async function(args){
  var out = {};
  for (var li = 0; li < args.lenses.length; li++) {
    var lens = args.lenses[li];
    var base = await __t1278.open(args.xml, lens, 'tl_create');
    var cw = canvasWrap, wr = cw.getBoundingClientRect();
    var vis = { l: wr.left + cw.clientLeft, t: wr.top + cw.clientTop }; vis.r = vis.l + cw.clientWidth; vis.b = vis.t + cw.clientHeight;
    var targets = Array.prototype.slice.call(svg.querySelectorAll('text')).concat(Array.prototype.slice.call(gNodes.querySelectorAll('.node > rect, .node > circle, .node > path, .node > polygon')))
      .filter(function(e){ var r = e.getBoundingClientRect(); var cs = getComputedStyle(e); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none'; });
    var bad = [], checked = 0;
    for (var i = 0; i < targets.length; i++) {
      var e = targets[i], r = e.getBoundingClientRect();
      cw.scrollLeft += (r.left + r.right) / 2 - (vis.l + vis.r) / 2;
      cw.scrollTop += (r.top + r.bottom) / 2 - (vis.t + vis.b) / 2;
      await __t1278.frame();
      r = e.getBoundingClientRect(); checked++;
      var inside = r.left >= vis.l - 0.5 && r.right <= vis.r + 0.5 && r.top >= vis.t - 0.5 && r.bottom <= vis.b + 0.5;
      var my = (r.top + r.bottom) / 2;
      var cov = [[(r.left + r.right) / 2, my], [r.left + 1, my], [r.right - 1, my]].map(function(p){ return document.elementFromPoint(p[0], p[1]); })
        .filter(function(h){ return h && !svg.contains(h); });
      if (!inside || cov.length) bad.push((e.textContent || e.tagName).slice(0, 40) + (inside ? '' : ' outside [' + [r.left, r.right, r.top, r.bottom].map(Math.round) + '] visible [' + [vis.l, vis.r, vis.t, vis.b].map(Math.round) + ']') + (cov.length ? ' covered by ' + cov.map(function(h){ return h.id || String(h.className); }).join('|') : ''));
    }
    var pool = svg.querySelector('.pool-border');
    cw.scrollLeft = cw.scrollWidth; cw.scrollTop = cw.scrollHeight; await __t1278.frame();
    var pr = pool ? pool.getBoundingClientRect() : null;
    out[lens] = { zoom: zoomFactor, panelOpen: document.getElementById('properties').getBoundingClientRect().width > 100, checked: checked, bad: bad,
                  pool: pr ? { right: Math.round(pr.right), bottom: Math.round(pr.bottom), visR: Math.round(vis.r), visB: Math.round(vis.b), inside: pr.right <= vis.r + 0.5 && pr.bottom <= vis.b + 0.5 } : null,
                  bytesSame: buildBpmnXml(state) === base };
  }
  return out;
})`;

// Leg 2b: the left palette: every control scrolls into view uncovered; at the end the LANES item is inside.
const LEG2_PALETTE = `(async function(args){
  var out = {};
  for (var li = 0; li < args.lenses.length; li++) {
    var lens = args.lenses[li];
    await __t1278.open(args.xml, lens, 'tl_create');
    var p = document.querySelector('.palette'), pr = p.getBoundingClientRect(), top = pr.top + p.clientTop, bottom = top + p.clientHeight;
    var ctl = Array.prototype.filter.call(p.querySelectorAll('.palette-item, .palette-tool, .palette-label'), function(e){ return e.getBoundingClientRect().height > 0; });
    var bad = [];
    for (var i = 0; i < ctl.length; i++) {
      ctl[i].scrollIntoView({ block: 'nearest' }); await __t1278.frame();
      var r = ctl[i].getBoundingClientRect(), hit = document.elementFromPoint((r.left + r.right) / 2, (r.top + r.bottom) / 2);
      if (r.top < top - 0.5 || r.bottom > bottom + 0.5 || !(hit && ctl[i].contains(hit))) bad.push(ctl[i].textContent.trim().replace(/\\s+/g, ' ').slice(0, 30));
    }
    p.scrollTop = p.scrollHeight; await __t1278.frame();
    var lanes = Array.prototype.find.call(p.querySelectorAll('.palette-label'), function(l){ return /lanes/i.test(l.textContent); });
    var last = lanes ? Array.prototype.filter.call(lanes.parentElement.querySelectorAll('.palette-item, [data-create], button'), function(e){ return e.getBoundingClientRect().height > 0; }).pop() : null;
    var lr = last ? last.getBoundingClientRect() : null;
    out[lens] = { controls: ctl.length, bad: bad, scrolls: p.scrollHeight > p.clientHeight ? getComputedStyle(p).overflowY : 'fits',
                  last: last ? last.textContent.trim().replace(/\\s+/g, ' ').slice(0, 40) : null, lastInside: !!lr && lr.top >= top - 0.5 && lr.bottom <= bottom + 0.5 };
    p.scrollTop = 0;
  }
  return out;
})`;

// Leg 3a: every named node's Name box shows its whole value, in the lens-shot state of the given lens.
const LEG3_CUT = `(async function(args){
  var base = await __t1278.open(args.xml, args.lens, 'tl_create');
  var cut = [], measured = 0;
  var named = state.nodes.filter(function(n){ return n.name && n.name.trim(); });
  for (var k = 0; k < named.length; k++) {
    selection = { kind: 'node', id: named[k].id }; renderProperties(); await __t1278.frame();
    var b = __t1278.nameBox(); if (!b) continue; measured++;
    if (b.scrollWidth > b.clientWidth + 1 || b.scrollHeight > b.clientHeight + 1) cut.push(named[k].id + ' "' + named[k].name.slice(0, 40) + '" ' + b.tagName + ' scroll ' + b.scrollWidth + 'x' + b.scrollHeight + ' > client ' + b.clientWidth + 'x' + b.clientHeight);
  }
  selection = null; renderProperties();
  return { named: named.length, measured: measured, cut: cut, bytesSame: buildBpmnXml(state) === base };
})`;
// Leg 3b: focus the Name box of tl_create (keystrokes come from CDP between FOCUS and AFTER).
const LEG3_FOCUS = `(async function(args){
  window.__t1278base = await __t1278.open(args.xml, 'all', 'tl_create');
  window.__t1278name0 = state.nodes.find(function(x){ return x.uid === 'tl_create'; }).name;
  var b = __t1278.nameBox(); b.focus(); b.setSelectionRange(b.value.length, b.value.length);
  return document.activeElement === b;
})`;
const LEG3_AFTER = `(function(){
  var n = state.nodes.find(function(x){ return x.uid === 'tl_create'; }), a = document.activeElement, b = __t1278.nameBox();
  return { name: n.name, focused: !!b && a === b, activeTag: a && a.tagName, box: b ? b.value : null };
})()`;
const LEG3_UNDO = `(function(){
  var n = state.nodes.find(function(x){ return x.uid === 'tl_create'; });
  n.name = __t1278name0; n.slug = deriveUniqueSlug(n, n.name); refreshDisplayIds(); renderAll(); selection = null; renderProperties();
  return buildBpmnXml(state) === __t1278base;
})()`;

// Leg 4: the palette subtitles per lens.
const LEG4 = `(async function(args){
  var out = {};
  for (var li = 0; li < args.lenses.length; li++) {
    await __t1278.open(args.xml, args.lenses[li], 'tl_create');
    out[args.lenses[li]] = Array.prototype.map.call(document.querySelectorAll('.palette-item[data-create]'), function(it){
      var m = it.querySelector('.palette-meta'); return [it.dataset.create, m ? m.textContent.trim() : null]; });
  }
  return out;
})`;

// Leg 5: contrast of every drawn .field-hint, side panel and details view, tl_create, every lens.
const LEG5 = `(async function(args){
  function rgb(s){ var m = s.match(/[\\d.]+/g).map(Number); return { c: m.slice(0, 3), a: m.length > 3 ? m[3] : 1 }; }
  function lum(c){ var v = c.map(function(x){ x /= 255; return x <= 0.03928 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4); }); return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2]; }
  function bgOf(e){ while (e) { var c = rgb(getComputedStyle(e).backgroundColor); if (c.a > 0.99) return c.c; e = e.parentElement; } return [0, 0, 0]; }
  var out = { measured: 0, low: [], min: null };
  for (var li = 0; li < args.lenses.length; li++) {
    var n = state.nodes; await __t1278.open(args.xml, args.lenses[li], 'tl_create');
    openDetails(state.nodes.find(function(x){ return x.uid === 'tl_create'; }).id); await new Promise(function(r){ setTimeout(r, 200); });
    Array.prototype.forEach.call(document.querySelectorAll('.field-hint'), function(h){
      if (!h.getBoundingClientRect().height || !h.textContent.trim()) return;
      var fg = rgb(getComputedStyle(h).color).c, bg = bgOf(h), l1 = lum(fg), l2 = lum(bg);
      var cr = (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05); out.measured++;
      if (out.min === null || cr < out.min) out.min = +cr.toFixed(2);
      if (cr < args.min) out.low.push(args.lenses[li] + ' "' + h.textContent.trim().slice(0, 30) + '" ' + cr.toFixed(2) + ':1 (' + fg + ' on ' + bg + ')');
    });
    if (typeof closeDetails === 'function') closeDetails();
  }
  return out;
})`;

async function session(width, height, fn) {
  const doc = mkdtempSync(join(tmpdir(), 't1278-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1278-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(LENSFILE, join(repo, 'lens-definition.interim.json'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1278-udd-');
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
    await ev(cmd, HELPERS);
    return await fn(cmd);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}

const call = (cmd, fn, args) => ev(cmd, `(${fn})(${JSON.stringify(args)})`);

async function main() {
  const corpus = existsSync(CORPUS_DIR) ? readdirSync(CORPUS_DIR).filter(f => f.endsWith('.bpmn')).sort() : [];
  if (!existsSync(SRC) || !existsSync(LIFECYCLE) || !existsSync(LENSFILE) || !corpus.length) { console.log(JSON.stringify({ ok: false, error: 'missing input' })); process.exitCode = 2; return; }
  const xml = readFileSync(LIFECYCLE, 'utf8');
  // the subtitles written in the palette's HTML, per data-create (leg 4: every non-business lens shows these)
  const html = readFileSync(SRC, 'utf8'), written = {};
  for (const m of html.matchAll(/data-create="([^"]+)"[\s\S]*?<div class="palette-meta">([^<]*)<\/div>/g)) if (!(m[1] in written)) written[m[1]] = m[2].replace(/&amp;/g, '&').trim();
  const errs = [], report = { src: SRC };
  try {
    for (const [w, h] of WIDTHS) {
      const r = await session(w, h, async cmd => {
        const o = {};
        if (run('leg1')) o.leg1 = await call(cmd, LEG1, { xml, lenses: LENSES });
        if (run('leg2')) { if (w < 1920) o.leg2c = await call(cmd, LEG2_CANVAS, { xml, lenses: LENSES }); o.leg2p = await call(cmd, LEG2_PALETTE, { xml, lenses: LENSES }); }
        if (run('leg3')) {
          o.leg3 = { lifecycle: await call(cmd, LEG3_CUT, { xml, lens: 'all' }) };
          if (w === 1440) for (const f of corpus) o.leg3[f] = await call(cmd, LEG3_CUT, { xml: readFileSync(join(CORPUS_DIR, f), 'utf8'), lens: 'all' });
          const focused = await call(cmd, LEG3_FOCUS, { xml });
          const name0 = await ev(cmd, `__t1278name0`);
          for (const k of ['a', 'b', 'c']) await key(cmd, k);
          const typed = await ev(cmd, LEG3_AFTER);
          await key(cmd, 'x\ny');
          const pasted = await ev(cmd, LEG3_AFTER);
          await key(cmd, 'Enter');
          const entered = await ev(cmd, LEG3_AFTER);
          o.leg3keys = { focused, name0, typed, pasted, entered, bytesBack: await ev(cmd, LEG3_UNDO) };
        }
        if (run('leg4') && w === 1440) o.leg4 = await call(cmd, LEG4, { xml, lenses: LENSES });
        if (run('leg5')) o.leg5 = await call(cmd, LEG5, { xml, lenses: LENSES, min: MIN_CONTRAST });
        return o;
      });
      report[w] = r;
      if (r.leg1) for (const lens of LENSES) {
        const x = r.leg1[lens];
        for (const c of ['name', 'flow', 'lane'].concat(lens === 'technical' || lens === 'all' ? ['id'] : [])) {
          if (!x.min[c]) errs.push(`leg1: at ${w} ${lens} no ${c} text drawn — vacuous`);
          else if (!(x.min[c].px >= MIN_PX - 0.01)) errs.push(`leg1: at ${w} ${lens} the smallest ${c} text "${x.min[c].text}" is drawn at ${x.min[c].px}px (< ${MIN_PX})`);
        }
        if (!x.fit.fitStill || !x.fit.fits) errs.push(`leg1: at ${w} ${lens} Fit does not show the whole map (${JSON.stringify(x.fit)})`);
        if (!x.bytesSame) errs.push(`leg1: at ${w} ${lens} buildBpmnXml changed`);
      }
      if (r.leg2c) for (const lens of LENSES) {
        const x = r.leg2c[lens];
        if (!x.panelOpen) errs.push(`leg2: at ${w} ${lens} the side panel is not open — vacuous`);
        if (x.checked < 20) errs.push(`leg2: at ${w} ${lens} only ${x.checked} canvas targets — vacuous`);
        for (const b of x.bad) errs.push(`leg2: at ${w} ${lens} not reachable: ${b}`);
        if (!x.pool || !x.pool.inside) errs.push(`leg2: at ${w} ${lens} the pool's far edge is not reachable (${JSON.stringify(x.pool)})`);
        if (!x.bytesSame) errs.push(`leg2: at ${w} ${lens} buildBpmnXml changed`);
      }
      if (r.leg2p) for (const lens of LENSES) {
        const x = r.leg2p[lens];
        for (const b of x.bad) errs.push(`leg2: at ${w} ${lens} palette control not reachable: ${b}`);
        if (!x.lastInside || !/lane/i.test(x.last || '')) errs.push(`leg2: at ${w} ${lens} the palette does not scroll to its LANES item (last ${x.last}, inside ${x.lastInside})`);
      }
      if (r.leg3) {
        for (const [m, x] of Object.entries(r.leg3)) {
          if (!x.measured) errs.push(`leg3: at ${w} ${m} no Name box measured — vacuous`);
          for (const c of x.cut) errs.push(`leg3: at ${w} ${m} Name cut: ${c}`);
          if (!x.bytesSame) errs.push(`leg3: at ${w} ${m} buildBpmnXml changed`);
        }
        const k = r.leg3keys;
        if (!k.focused) errs.push(`leg3: at ${w} the Name box did not take focus`);
        if (k.typed.name !== k.name0 + 'abc' || !k.typed.focused) errs.push(`leg3: at ${w} typing "abc" stored ${JSON.stringify(k.typed.name.slice(-8))}, focus ${k.typed.focused ? 'kept' : 'lost to ' + k.typed.activeTag}`);
        if (k.pasted.name !== k.name0 + 'abcx y') errs.push(`leg3: at ${w} a pasted line break stored ${JSON.stringify(k.pasted.name.slice(-8))} (want "abcx y")`);
        if (/[\r\n]/.test(k.entered.name) || k.entered.name !== k.pasted.name || k.entered.focused) errs.push(`leg3: at ${w} Enter: name ${JSON.stringify(k.entered.name.slice(-8))}, still focused ${k.entered.focused} (want the edit ended, no newline)`);
        if (!k.bytesBack) errs.push(`leg3: at ${w} restoring the name did not give the same bytes`);
      }
      if (r.leg4) for (const lens of LENSES) for (const [t, meta] of r.leg4[lens]) {
        if (lens === 'business') { if (TECH_WORDS.test(meta || '')) errs.push(`leg4: business palette subtitle of ${t} is "${meta}"`); }
        else if (meta !== written[t]) errs.push(`leg4: ${lens} palette subtitle of ${t} is "${meta}", the palette writes "${written[t]}"`);
      }
      if (r.leg5) {
        if (r.leg5.measured < 10) errs.push(`leg5: at ${w} only ${r.leg5.measured} helper texts measured — vacuous`);
        for (const l of r.leg5.low) errs.push(`leg5: at ${w} ${l} (< ${MIN_CONTRAST}:1)`);
      }
    }
  } catch (e) { errs.push('exception: ' + (e && e.stack || e)); }
  report.ok = !errs.length; report.errs = errs;
  console.log(JSON.stringify(report, (k, v) => (k === 'leg3' && v && typeof v === 'object') ? Object.fromEntries(Object.entries(v).map(([m, x]) => [m, { named: x.named, measured: x.measured, cut: x.cut.length }])) : v, 2));
  process.exitCode = errs.length ? 1 : 0;
}
main();
