#!/usr/bin/env node
// _t251-visual-shots.mjs — T-251 visual-verification screenshots (throwaway).
// Hermetic (same isolation as the G-010 suite); writes element-level PNGs to
// .playwright-mcp/ for the CLAUDE.md "Visual Verification for UI Changes" rule.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const EDITOR = join(REPO, 'src', 'aef-workflow-designer.html');
const RENDERED = join(REPO, 'examples', 'aef-processes', 'rendered');
const OUT = join(REPO, '.playwright-mcp');
const MAP = 'arc-lifecycle.bpmn';
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

async function shot(cmd, sel, file, pad = 6) {
  const r = await ev(cmd, `(function(){ const el = document.querySelector(${JSON.stringify(sel)}); const b = el.getBoundingClientRect(); return { x: b.left, y: b.top, w: b.width, h: b.height }; })()`);
  const png = await cmd('Page.captureScreenshot', { clip: { x: Math.max(0, r.x - pad), y: Math.max(0, r.y - pad), width: r.w + 2 * pad, height: r.h + 2 * pad, scale: 1 }, format: 'png' });
  writeFileSync(join(OUT, file), Buffer.from(png.data, 'base64'));
  console.log('wrote', file, Math.round(r.w), 'x', Math.round(r.h));
}

async function main() {
  mkdirSync(OUT, { recursive: true });
  const doc = mkdtempSync(join(tmpdir(), 't251-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't251-repo-'));
  copyFileSync(EDITOR, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(RENDERED, MAP), join(doc, 'rendered', MAP));
  const rr = join(repo, 'examples', 'aef-processes', 'rendered');
  mkdirSync(rr, { recursive: true });
  copyFileSync(join(RENDERED, MAP), join(rr, MAP));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't251-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) break; } catch (_) {} await sleep(100); }
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: BASE + '/designer.html?load=' + encodeURIComponent('rendered/' + MAP) });
    { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof renderAll==='function'&&_appReady===true)`).catch(() => false); if (ok) break; if (Date.now() - t0 > 20000) throw new Error('not ready'); await sleep(150); } }
    await sleep(400);
    await ev(cmd, `state.nodes.forEach(function(n, i){ n.x = 80 + (i % 10) * 520; }); renderAll();`);

    // 1: header at fit — new zoom controls visible in context
    await shot(cmd, 'header .actions', 't251-header-fit.png');
    // 2: zoomed — readout %, scrollbars on the wrap
    await ev(cmd, `document.getElementById('btn-zoom-in').click(); document.getElementById('btn-zoom-in').click();`);
    await sleep(200);
    await shot(cmd, 'header .actions', 't251-header-zoomed.png');
    await ev(cmd, `canvasWrap.scrollLeft = 300; canvasWrap.scrollTop = 30; syncOverlayPin();`);
    await sleep(150);
    await shot(cmd, '.canvas-wrap', 't251-canvas-zoomed-scrolled.png');
    // 3: focus mode + zoom
    await ev(cmd, `document.getElementById('btn-focus-mode').click();`);
    await sleep(250);
    await shot(cmd, '.canvas-wrap', 't251-focus-zoomed.png');
    await ev(cmd, `document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));`);
    await sleep(200);
    // 4: fit restore
    await ev(cmd, `document.getElementById('btn-zoom-fit').click();`);
    await sleep(200);
    await shot(cmd, '.canvas-wrap', 't251-fit-restore.png');
    await shot(cmd, 'header .actions', 't251-header-fit-after.png');
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    try { rmSync(doc, { recursive: true, force: true }); rmSync(repo, { recursive: true, force: true }); rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
