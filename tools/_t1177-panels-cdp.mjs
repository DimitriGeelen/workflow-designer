#!/usr/bin/env node
// _t1177-panels-cdp.mjs — verify T-1177: each side panel folds away to a notch at the window edge and unfolds from it,
// its width is set by dragging its inner edge (palette 160-480px, properties 240-640px, the canvas keeps at least
// 320px), a double-click on the edge restores the default, and fold state and widths persist in aefViewPrefs.
//
// Same harness as _t1176 (gallery-serve.py temp docroot, ISOLATED headless chromium). All clicks and drags are real
// CDP mouse input, so the pointer events the designer listens to are the browser's own.
// Writes .playwright-mcp/t1177-<width>-{open,palette-folded,props-folded,resized}.png at 1024/1440/1920 for the
// visual review (CLAUDE.md, T-1174).
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
const MAP = 'audit-process';
const WIDTHS = [1024, 1200, 1280, 1440, 1920];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't1177-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1177-repo-'));
  const src = process.env.T1177_DESIGNER || join(REPO, 'src/aef-workflow-designer.html');
  copyFileSync(src, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1177-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [], shots: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    const URL = `${BASE}/designer.html?load=rendered/${MAP}.bpmn`;
    const open = async (w, clear) => {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: 860, deviceScaleFactor: 1, mobile: false });
      if (clear) { await cmd('Page.navigate', { url: URL }); await sleep(300); await waitReady(cmd); await ev(cmd, `localStorage.removeItem('aefViewPrefs'), 1`); }
      await cmd('Page.navigate', { url: URL });
      await sleep(300); await waitReady(cmd); await sleep(600);
      await ev(cmd, `document.fonts.ready.then(function(){ return new Promise(function(r){ setTimeout(r, 300); }); })`);
    };
    const mouse = (type, x, y, extra = {}) => cmd('Input.dispatchMouseEvent', { type, x, y, button: 'left', buttons: type === 'mouseReleased' ? 0 : 1, clickCount: 1, ...extra });
    // A drag edge is grabbed 120px below its top: the fold tab sits over the middle of the edge.
    const centre = async sel => ev(cmd, `(function(){ var e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; var r = e.getBoundingClientRect();
      var edge = e.classList.contains('panel-resizer'); var x = r.left + r.width / 2, y = edge ? r.top + 120 : r.top + r.height / 2;
      if (edge && document.elementFromPoint(x, y) !== e) return null;
      return { x: x, y: y, w: r.width, h: r.height }; })()`);
    const click = async sel => { const c = await centre(sel); if (!c) throw new Error('no ' + sel); await mouse('mouseMoved', c.x, c.y, { buttons: 0 }); await mouse('mousePressed', c.x, c.y); await mouse('mouseReleased', c.x, c.y); await sleep(250); };
    const dblclick = async sel => { const c = await centre(sel); await mouse('mousePressed', c.x, c.y); await mouse('mouseReleased', c.x, c.y); await mouse('mousePressed', c.x, c.y, { clickCount: 2 }); await mouse('mouseReleased', c.x, c.y, { clickCount: 2 }); await sleep(250); };
    const drag = async (sel, toX) => { const c = await centre(sel); if (!c) throw new Error('drag edge ' + sel + ' not grabbable'); await mouse('mouseMoved', c.x, c.y, { buttons: 0 }); await mouse('mousePressed', c.x, c.y);
      for (let i = 1; i <= 8; i++) { await mouse('mouseMoved', c.x + (toX - c.x) * i / 8, c.y); await sleep(20); } await mouse('mouseReleased', toX, c.y); await sleep(300); };
    const STATE = `(function(){
      var q = function(s){ var e = document.querySelector(s); if (!e) return null; var cs = getComputedStyle(e), r = e.getBoundingClientRect();
        return { shown: cs.display !== 'none' && r.width > 0, left: Math.round(r.left), right: Math.round(r.right), w: Math.round(r.width) }; };
      var p = {}; try { p = JSON.parse(localStorage.getItem('aefViewPrefs') || '{}'); } catch (e) {}
      var hitTab = function(id){ var e = document.getElementById(id); if (!e) return false; var r = e.getBoundingClientRect(); var h = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2); return h === e; };
      return { pal: q('.palette'), props: q('.properties'), canvas: q('#canvas-wrap') || q('.canvas-wrap'), tabPal: q('#tab-palette'), tabProps: q('#tab-props'),
        rzPal: q('#resize-palette'), rzProps: q('#resize-props'), drawer: (function(){ var d = document.getElementById('findings-drawer'); if (!d) return null; var cs = getComputedStyle(d); return { left: parseFloat(cs.left), right: parseFloat(cs.right) }; })(),
        tabPalHit: hitTab('tab-palette'), tabPropsHit: hitTab('tab-props'),
        tabPalText: (document.getElementById('tab-palette') || {}).textContent, tabPropsText: (document.getElementById('tab-props') || {}).textContent,
        noPal: document.body.classList.contains('vc-no-palette'), noProps: document.body.classList.contains('vc-no-props'), stored: p, width: innerWidth };
    })()`;
    const st = () => ev(cmd, STATE);
    const shot = async name => { const s = await cmd('Page.captureScreenshot', { format: 'png' }); mkdirSync(SHOTDIR, { recursive: true });
      const f = join(SHOTDIR, `t1177-${name}.png`); writeFileSync(f, Buffer.from(s.data, 'base64')); verdict.shots.push(f); };
    const near = (a, b, tol = 2) => Math.abs(a - b) <= tol;

    // ---- behaviour, at 1440 ----
    await open(1440, true);
    let s = await st();
    push('defaults: palette 220px, properties 320px, both tabs on the inner edges and clickable', s.tabPal && s.tabProps && near(s.pal.w, 220) && near(s.props.w, 320) && s.tabPalHit && s.tabPropsHit
      && near(s.tabPal.left, s.pal.right, 1) && near(s.tabProps.right, s.props.left, 1), s);
    await click('#tab-palette'); s = await st();
    push('the palette tab folds the palette to a notch at the window edge; the canvas takes the space', s.noPal && !s.pal.shown && s.tabPal.left === 0 && s.tabPalHit && s.canvas.left >= 15 && s.canvas.left <= 17 && s.stored.paletteHidden === true && s.tabPalText === '▸', s);
    await click('#tab-palette'); s = await st();
    push('the notch unfolds the palette again', !s.noPal && s.pal.shown && near(s.pal.w, 220) && s.stored.paletteHidden === false && s.tabPalText === '◂', s);
    await click('#tab-props'); s = await st();
    push('the properties tab folds the panel to a notch at the right edge', s.noProps && !s.props.shown && s.tabProps.right === s.width && s.tabPropsHit && s.width - s.canvas.right >= 15 && s.width - s.canvas.right <= 17 && s.stored.propsHidden === true, s);
    await click('#tab-props'); s = await st();
    push('the notch unfolds the properties panel again', !s.noProps && s.props.shown && near(s.props.w, 320), s);
    await click('#btn-toggle-palette'); s = await st();
    push('the toolbar ◧ folds the same state (notch shown)', s.noPal && s.tabPal.left === 0 && s.stored.paletteHidden === true, s);
    await click('#btn-toggle-palette');
    await drag('#resize-palette', 350); s = await st();
    push('dragging the palette edge to x=350 makes it 350px wide and stores it', near(s.pal.w, 350) && s.stored.palW === s.pal.w && near(s.tabPal.left, s.pal.right, 1), s);
    await drag('#resize-palette', 50); s = await st();
    push('dragging it below the minimum stops at 160px', near(s.pal.w, 160) && s.stored.palW === 160, s);
    await drag('#resize-palette', 900); s = await st();
    push('dragging it past the maximum stops at 480px', near(s.pal.w, 480) && s.stored.palW === 480, s);
    await drag('#resize-props', 100); s = await st();
    push('the properties edge stops where the canvas keeps 320px (both panels wide)', s.canvas.w >= 319 && s.props.w <= 640 && s.stored.propsW === s.props.w, s);
    push('the findings drawer follows the panel widths', near(s.drawer.left, s.pal.right, 1) && near(s.drawer.right, s.width - s.props.left, 1), s.drawer);
    await dblclick('#resize-palette'); await dblclick('#resize-props'); s = await st();
    push('double-clicking an edge restores the default (220 / 320)', near(s.pal.w, 220) && near(s.props.w, 320) && s.stored.palW === 220 && s.stored.propsW === 320, s);
    await drag('#resize-palette', 300); await drag('#resize-props', 1440 - 400); await click('#tab-palette');
    await open(1440, false); s = await st();
    push('fold state and both widths survive a reload', s.noPal && s.stored.palW === 300 && near(s.props.w, 400) && s.tabPal.left === 0, s);
    await ev(cmd, `localStorage.setItem('aefViewPrefs', JSON.stringify({ palW: 9999, propsW: 'wide', paletteHidden: false })), 1`);
    await open(1440, false); s = await st();
    push('out-of-range or invalid stored widths fall back to the defaults', near(s.pal.w, 220) && near(s.props.w, 320), s);
    await click('#btn-focus-mode'); await sleep(200);
    const focus = await ev(cmd, `[document.getElementById('tab-palette'), document.getElementById('tab-props'), document.getElementById('resize-palette'), document.getElementById('resize-props')].map(function(e){ return getComputedStyle(e).display; })`);
    push('focus mode hides the tabs and the drag edges too', focus.every(d => d === 'none'), focus);
    await ev(cmd, `document.getElementById('vc-exit').click(), 1`);

    // ---- screenshots for the visual review (CLAUDE.md, T-1174) ----
    for (const w of [1024, 1440, 1920]) {
      await open(w, true); await shot(`${w}-open`);
      await click('#tab-palette'); await shot(`${w}-palette-folded`); await click('#tab-palette');
      await click('#tab-props'); await shot(`${w}-props-folded`); await click('#tab-props');
      await drag('#resize-palette', 330); await drag('#resize-props', w - 460); s = await st();
      push(`${w}px: both resized, the canvas keeps at least 320px`, s.canvas.w >= 319, { pal: s.pal.w, props: s.props.w, canvas: s.canvas.w });
      await shot(`${w}-resized`);
    }
    await ev(cmd, `localStorage.removeItem('aefViewPrefs'), 1`);
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
