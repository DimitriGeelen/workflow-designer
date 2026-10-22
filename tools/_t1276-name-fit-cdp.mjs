#!/usr/bin/env node
// _t1276-name-fit-cdp.mjs — T-1276: no task name is cut with "…" on a corpus map, and flow labels meet WCAG AA.
// The T-1241 codex review (judge-t-1241-r5-codex-094a2e6d84f5) read two lifecycle names ending in "…" (the T-087 fit
// ladder's floor) and called the flow labels low contrast. Drives the REAL editor headless (gallery-serve.py + the
// interim lens file), opening each map as T-1241's lens-shot script does (adopt, render, opening zoom, lens).
// Legs:
//   1. floor hits: on aef-task-lifecycle (v3 project map) and every map in examples/aef-processes/rendered/, in every
//      lens (business/logical/technical/all), at 1024, 1440 and 1920, default label size: every task/subprocess name
//      is drawn whole inside its rect (the rendered lines, joined, equal the name; no "…" the name does not carry):
//      0 floor hits. Also measured: every line fits the rect's inner width and the block stays inside the rect, and
//      no name renders below MIN_FS user px (the font size the ladder may go down to). Reported, not a leg: name lines
//      under the I/O or constituent badge drawn inside the rect (short names on the default step have run under the
//      badge since 0.25.0 and before; T1276_BADGE_MAX fails the run when the count exceeds it);
//   2. contrast: the flow-label fill against what is painted under it (its halo pad, else the canvas background),
//      composited with every ancestor's opacity, from computed styles: >= 4.5:1 in every theme the designer ships
//      (themes are found by the data-theme values the source styles; none means the one :root theme);
//   3. bytes: buildBpmnXml output is identical before and after every render this harness makes.
// T1276_SRC substitutes another designer file (the 0.25.0 source: leg 1 must go red, lifecycle >= 2).
// Exit 0 = green; 1 = red; 2 = misconfig.
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
const SRC = process.env.T1276_SRC || join(REPO, 'src/aef-workflow-designer.html');
const LIFECYCLE = join(REPO, '.agentic-framework/.context/designer/projects/aef-task-lifecycle/v3.bpmn');
const CORPUS_DIR = join(REPO, 'examples/aef-processes/rendered');
const LENSFILE = join(REPO, 'lens-definition.interim.json');
const LENSES = ['business', 'logical', 'technical', 'all'];
const MIN_FS = 8;     // no name below 8px at the default label size (T-1276)
const AA = 4.5;
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// In-page. Floor hits and fit per map and lens; flow-label contrast on the current theme.
const RUN = `(async function(args){
  var frame = function(){ return new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); }); };
  var norm = function(s){ return String(s || '').split(/\\s+/).filter(Boolean).join(' '); };
  var res = { lens: {}, bytesChanged: [], tasks: 0 };
  if (typeof labelPrefs === 'object') labelPrefs.size = 'm';
  adoptImportedXml(args.xml, { userImport: true }); renderAll();
  if (typeof openingZoom === 'function') openingZoom();
  var base = buildBpmnXml(state);
  for (var li = 0; li < args.lenses.length; li++) {
    var lens = args.lenses[li];
    if (typeof setLens === 'function') setLens(lens); else if (lens !== 'all') continue;
    renderAll(); await frame();
    var r = { floor: [], misfit: [], badge: [], minFs: Infinity, tasks: 0 };
    state.nodes.forEach(function(n){
      var ts = Array.prototype.slice.call(gNodes.querySelectorAll('text[data-fitn="' + n.uid + '"]'));
      if (!ts.length) return;
      r.tasks++;
      // whole = every non-space character of the name drawn, in order, and no "…" the name does not carry (a line may
      // break inside an over-wide token, after a / or |, so spaces are not compared)
      var drawn = norm(ts.map(function(t){ return t.textContent; }).join(' ')), bare = function(x){ return x.replace(/\\s+/g, ''); };
      if (bare(drawn) !== bare(n.name) || (drawn.indexOf('\\u2026') >= 0 && norm(n.name).indexOf('\\u2026') < 0)) r.floor.push(n.id + ': "' + drawn + '"');
      var def = NODE_DEFAULTS[n.type], maxW = def.w - 8;
      // the badges drawn inside the rect (I/O top-right, constituents bottom-left): a name line must not run under one
      var badges = Array.prototype.slice.call(ts[0].parentNode.querySelectorAll('text.node-io-badge')).map(function(b){ var x = b.getBBox(); return { t: b.textContent, x1: x.x - 4, y1: x.y - 1, x2: x.x + x.width + 4, y2: x.y + x.height + 1 }; });
      ts.forEach(function(t){
        var fs = parseFloat(getComputedStyle(t).fontSize); if (fs < r.minFs) r.minFs = fs;
        var b = t.getBBox(), w = t.getComputedTextLength();
        badges.forEach(function(q){ if (b.x < q.x2 && q.x1 < b.x + b.width && b.y + 1 < q.y2 && q.y1 < b.y + b.height - 1) r.badge.push(n.id + ' "' + t.textContent + '" x badge ' + q.t); });
        if (w > maxW + 0.01 || b.y < n.y + 1 || b.y + b.height > n.y + def.h - 1)
          r.misfit.push(n.id + ' "' + t.textContent + '" w ' + w.toFixed(1) + '/' + maxW + ' y ' + (b.y - n.y).toFixed(1) + '..' + (b.y + b.height - n.y).toFixed(1) + '/' + def.h);
      });
    });
    res.lens[lens] = r;
    if (buildBpmnXml(state) !== base) res.bytesChanged.push(lens);
  }
  if (typeof setLens === 'function') setLens('all');
  return res;
})`;

// sRGB relative luminance and contrast (WCAG 2.x); colours composited over the backdrop with the effective opacity.
const CONTRAST = `(async function(){
  var frame = function(){ return new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); }); };
  function rgba(s){ var m = String(s).match(/rgba?\\(([^)]+)\\)/); if (!m) return null; var p = m[1].split(/[ ,\\/]+/).filter(Boolean).map(parseFloat); return { r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1 }; }
  function over(c, b, a){ return { r: c.r * a + b.r * (1 - a), g: c.g * a + b.g * (1 - a), b: c.b * a + b.b * (1 - a), a: 1 }; }
  function lum(c){ var f = function(v){ v /= 255; return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }; return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b); }
  function ratio(a, b){ var x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); }
  function opac(e){ var o = 1; for (; e && e.nodeType === 1; e = e.parentNode) o *= parseFloat(getComputedStyle(e).opacity); return o; }
  // the canvas background: the wrap's background colour (its dot grid is 4% white, ignored), over the body's
  var page = rgba(getComputedStyle(document.body).backgroundColor) || { r: 255, g: 255, b: 255, a: 1 };
  var wrap = rgba(getComputedStyle(canvasWrap).backgroundColor) || { a: 0 };
  var canvasBg = wrap.a > 0 ? over(wrap, page, wrap.a) : page;
  var themes = [], seen = {};
  Array.prototype.forEach.call(document.styleSheets, function(ss){ var rules; try { rules = ss.cssRules; } catch (_) { return; }
    Array.prototype.forEach.call(rules || [], function(r){ var m = (r.selectorText || '').match(/\\[data-theme=["']?([\\w-]+)/); if (m && !seen[m[1]]) { seen[m[1]] = 1; themes.push(m[1]); } }); });
  var out = { themes: {} }, list = [null].concat(themes);
  for (var i = 0; i < list.length; i++) {
    var th = list[i];
    if (th) document.documentElement.setAttribute('data-theme', th); else document.documentElement.removeAttribute('data-theme');
    renderAll(); await frame();
    page = rgba(getComputedStyle(document.body).backgroundColor) || page;
    wrap = rgba(getComputedStyle(canvasWrap).backgroundColor) || { a: 0 };
    canvasBg = wrap.a > 0 ? over(wrap, page, wrap.a) : page;
    var worst = null, n = 0;
    Array.prototype.forEach.call(gEdges.querySelectorAll('text.edge-label'), function(t){
      var cs = getComputedStyle(t), fill = rgba(cs.fill); if (!fill) return;
      var bg = canvasBg, h = gEdges.querySelector('rect[data-elr="' + t.getAttribute('data-el') + '"]');
      if (h) { var hf = rgba(getComputedStyle(h).fill); if (hf && hf.a > 0) bg = over(hf, bg, hf.a * opac(h)); }
      var fg = over(fill, bg, fill.a * opac(t)), r = ratio(fg, bg); n++;
      if (!worst || r < worst.ratio) worst = { ratio: +r.toFixed(2), text: t.textContent, fill: cs.fill, bg: 'rgb(' + [bg.r, bg.g, bg.b].map(Math.round).join(',') + ')' };
    });
    out.themes[th || ':root'] = { labels: n, worst: worst };
  }
  document.documentElement.removeAttribute('data-theme'); renderAll();
  return out;
})`;

async function session(width, height, fn) {
  const doc = mkdtempSync(join(tmpdir(), 't1276-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1276-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(LENSFILE, join(repo, 'lens-definition.interim.json'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1276-udd-');
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
  const corpus = readdirSync(CORPUS_DIR).filter(f => f.endsWith('.bpmn')).sort();
  if (!existsSync(SRC) || !existsSync(LIFECYCLE) || !existsSync(LENSFILE) || !corpus.length) { console.log(JSON.stringify({ ok: false, error: 'missing input' })); process.exitCode = 2; return; }
  const maps = [['aef-task-lifecycle', readFileSync(LIFECYCLE, 'utf8')]].concat(corpus.map(f => [f, readFileSync(join(CORPUS_DIR, f), 'utf8')]));
  const errs = [], report = { src: SRC, floor: {}, floorTotal: 0, misfit: 0, minFs: Infinity, tasks: 0 };
  try {
    for (const [w, h] of [[1024, 768], [1440, 900], [1920, 1080]]) {
      await session(w, h, async cmd => {
        for (const [name, xml] of maps) {
          const r = await ev(cmd, `(${RUN})(${JSON.stringify({ xml, lenses: LENSES })})`);
          let hits = 0;
          for (const [lens, m] of Object.entries(r.lens)) {
            hits += m.floor.length; report.tasks += m.tasks;
            report.minFs = Math.min(report.minFs, m.minFs);
            for (const f of m.floor) errs.push(`leg1: ${name} at ${w}, ${lens}: floor hit ${f}`);
            for (const f of m.misfit) errs.push(`leg1: ${name} at ${w}, ${lens}: name outside its rect ${f}`);
            report.misfit += m.misfit.length;
            for (const f of m.badge) (report.badgeHits = report.badgeHits || []).push(`${name} at ${w}, ${lens}: ${f}`);
            report.badge = (report.badge || 0) + m.badge.length;
          }
          if (Object.keys(r.lens).length !== LENSES.length) errs.push(`leg1: ${name} at ${w}: measured ${Object.keys(r.lens).length} of 4 lenses`);
          report.floor[name] = (report.floor[name] || '') + (report.floor[name] ? ' ' : '') + w + ':' + hits;
          report.floorTotal += hits;
          if (r.bytesChanged.length) errs.push(`leg3: ${name} at ${w}: buildBpmnXml changed after rendering ${r.bytesChanged.join(',')}`);
        }
        if (w === 1920) {
          await ev(cmd, `(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); if (typeof openingZoom === 'function') openingZoom(); })(${JSON.stringify(maps[0][1])})`);
          report.contrast = await ev(cmd, `(${CONTRAST})()`);
        }
      });
    }
    if (process.env.T1276_BADGE_MAX && report.badge > +process.env.T1276_BADGE_MAX) errs.push(`leg1: ${report.badge} name lines under a badge (> T1276_BADGE_MAX ${process.env.T1276_BADGE_MAX})`);
    if (report.minFs < MIN_FS) errs.push(`leg1: a name renders at ${report.minFs}px (< ${MIN_FS})`);
    if (report.tasks < 100) errs.push(`leg1: only ${report.tasks} task names measured — vacuous`);
    for (const [th, c] of Object.entries(report.contrast.themes)) {
      if (!c.labels || !c.worst) errs.push(`leg2: theme ${th}: no flow label measured`);
      else if (c.worst.ratio < AA) errs.push(`leg2: theme ${th}: flow label "${c.worst.text}" ${c.worst.fill} on ${c.worst.bg} is ${c.worst.ratio}:1 (< ${AA})`);
    }
  } catch (e) { errs.push('exception: ' + (e && e.stack || e)); }
  report.ok = !errs.length; report.errs = errs;
  console.log(JSON.stringify(report, null, 2));
  process.exitCode = errs.length ? 1 : 0;
}
main();
