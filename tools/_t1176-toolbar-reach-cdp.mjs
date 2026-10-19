#!/usr/bin/env node
// _t1176-toolbar-reach-cdp.mjs — verify T-1176: at every width, every header control the designer shows can be seen
// and clicked. The header was one flex row in a fixed 48px grid row, so below ~1450px Check, Versions, Save to project
// and Save were pushed past the edge (operator 2026-10-14: "the menu buttons drop off. I cannot access them anymore").
//
// Serves the editor from a TEMP docroot (gallery-serve.py, so the server-gated buttons are shown) and drives it in
// ISOLATED headless chromium, the same harness as _t1155. Per width (1024, 1200 ~ the inline frame in Watchtower,
// 1280, 1440, 1920):
//   1. every VISIBLE control in <header> lies fully inside the window (left >= 0, right <= innerWidth), and the
//      element at its centre is the control itself (nothing covers it: it can be clicked);
//   2. the panels (palette, canvas, properties) start at or below the header's bottom edge (no overlap);
//   3. at 1920 the header is still one 48px row (nothing changes where everything fitted).
// Writes .playwright-mcp/t1176-header-<width>.png per width for the visual review (CLAUDE.md, T-1174).
// Exit 0 = pass. Exit 1 = a step failed. Exit 2 = harness could not run.
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
const MAP = 'audit-process';
const WIDTHS = [1024, 1200, 1280, 1440, 1920];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const MEASURE = `(function(){
  var h = document.querySelector('header');
  var hr = h.getBoundingClientRect();
  var ctrls = Array.prototype.slice.call(h.querySelectorAll('button, select, a, input'));
  var shown = ctrls.filter(function(c){ var cs = getComputedStyle(c), r = c.getBoundingClientRect();
    return cs.display !== 'none' && cs.visibility !== 'hidden' && !c.hidden && r.width > 0 && r.height > 0; });
  var bad = [];
  shown.forEach(function(c){
    var r = c.getBoundingClientRect();
    var name = (c.id || c.textContent.trim().slice(0, 20) || c.tagName);
    if (r.left < 0 || r.right > innerWidth + 0.5 || r.top < 0 || r.bottom > innerHeight) { bad.push(name + ' outside the window (' + Math.round(r.left) + '..' + Math.round(r.right) + ' of ' + innerWidth + ')'); return; }
    var hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
    if (!hit || !(hit === c || c.contains(hit))) bad.push(name + ' covered by ' + (hit ? (hit.id || hit.className || hit.tagName) : 'nothing'));
  });
  var below = ['palette', 'canvas-wrap', 'properties'].map(function(id){ var e = document.getElementById(id) || document.querySelector('.' + id);
    return e ? { id: id, top: Math.round(e.getBoundingClientRect().top) } : null; }).filter(Boolean);
  var overlap = below.filter(function(b){ return b.top < Math.round(hr.bottom) - 1; });
  // The zoom (− fit + ⤢) and view (◧ ◨ ⛶) controls must each stay on ONE row (reviewer on T-1176: ⛶ split off at 1024).
  var groups = [['btn-zoom-out', 'zoom-level', 'btn-zoom-in', 'btn-zoom-fit'], ['btn-toggle-palette', 'btn-toggle-props', 'btn-focus-mode']];
  var split = groups.filter(function(g){ var tops = g.map(function(id){ return Math.round(document.getElementById(id).getBoundingClientRect().top); });
    return Math.max.apply(null, tops) - Math.min.apply(null, tops) > 4; }).map(function(g){ return g.join(' '); });
  return { width: innerWidth, headerH: Math.round(hr.height), shown: shown.length, bad: bad, overlap: overlap, below: below, split: split };
})()`;

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't1176-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1176-repo-'));
  const src = process.env.T1176_DESIGNER || join(REPO, 'src/aef-workflow-designer.html');
  copyFileSync(src, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1176-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [], shots: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    for (const w of WIDTHS) {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: 860, deviceScaleFactor: 1, mobile: false });
      await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
      await sleep(300); await waitReady(cmd); await sleep(900);   // server-gated buttons appear after /api/health
      // Measure the layout the user SEES: web fonts are wider than the fallback, and a measurement taken before they
      // load passed a one-row header that wrapped once they arrived (found reviewing the inline 1920 screenshot).
      await ev(cmd, `document.fonts.ready.then(function(){ return new Promise(function(r){ setTimeout(r, 300); }); })`);
      const m = await ev(cmd, MEASURE);
      push(`${w}px: all ${m.shown} visible header controls inside the window and clickable`, m.bad.length === 0 && m.shown >= 15, m.bad.length ? m.bad : { shown: m.shown, headerH: m.headerH });
      push(`${w}px: the panels start below the header (no overlap)`, m.overlap.length === 0 && m.below.length >= 2, m.overlap.length ? m.overlap : m.below);
      push(`${w}px: the zoom group and the view group each stay on one row`, m.split.length === 0, m.split);
      if (w === 1920) push('1920px: the header is still one 48px row', m.headerH === 48, m.headerH);
      // The XML panel is an overlay placed below the header; with a 2-row header a fixed 48px would cover row 2.
      const xp = await ev(cmd, `(function(){ document.getElementById('btn-xml').click();
        var p = document.getElementById('xml-panel').getBoundingClientRect(), h = document.querySelector('header').getBoundingClientRect();
        var r = { panelTop: Math.round(p.top), headerBottom: Math.round(h.bottom) };
        var c = document.getElementById('btn-close-xml'); if (c) c.click();
        return r; })()`);
      push(`${w}px: the XML panel opens below the header, not over it`, xp.panelTop >= xp.headerBottom - 1, xp);
      const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: w, height: Math.min(220, 860), scale: 1 } });
      mkdirSync(SHOTDIR, { recursive: true });
      const f = join(SHOTDIR, `t1176-header-${w}.png`);
      writeFileSync(f, Buffer.from(s.data, 'base64'));
      verdict.shots.push(f);
    }
    verdict.pass = verdict.steps.every(s => s.pass);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), steps: verdict.steps }, null, 2) + '\n');
    process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
