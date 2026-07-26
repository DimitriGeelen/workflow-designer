#!/usr/bin/env node
// _t255-visual-shots.mjs — T-255 visual-verification screenshots (throwaway).
// Hermetic (same isolation as the G-010 suite); writes element-level PNGs to
// .playwright-mcp/ for the CLAUDE.md "Visual Verification for UI Changes" rule.
// App is dark-only — single-mode verification.
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

async function shot(cmd, sel, file, pad = 10) {
  const r = await ev(cmd, `(function(){ const el = document.querySelector(${JSON.stringify(sel)}); const b = el.getBoundingClientRect(); return { x: b.left, y: b.top, w: b.width, h: b.height }; })()`);
  const png = await cmd('Page.captureScreenshot', { clip: { x: Math.max(0, r.x - pad), y: Math.max(0, r.y - pad), width: r.w + 2 * pad, height: r.h + 2 * pad, scale: 1 }, format: 'png' });
  writeFileSync(join(OUT, file), Buffer.from(png.data, 'base64'));
  console.log('wrote', file, Math.round(r.w), 'x', Math.round(r.h));
}
async function shotRegion(cmd, x, y, w, h, file) {
  const png = await cmd('Page.captureScreenshot', { clip: { x, y, width: w, height: h, scale: 1 }, format: 'png' });
  writeFileSync(join(OUT, file), Buffer.from(png.data, 'base64'));
  console.log('wrote', file, w, 'x', h);
}

async function main() {
  mkdirSync(OUT, { recursive: true });
  const doc = mkdtempSync(join(tmpdir(), 't255-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't255-repo-'));
  copyFileSync(EDITOR, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(RENDERED, MAP), join(doc, 'rendered', MAP));
  const rr = join(repo, 'examples', 'aef-processes', 'rendered');
  mkdirSync(rr, { recursive: true });
  copyFileSync(join(RENDERED, MAP), join(rr, MAP));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't255-udd-'));
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

    // 1: whole canvas at rest — baseline before widen
    await shot(cmd, '.canvas-wrap', 't255-canvas-before.png');
    // 2: right-edge region with the handle grip forced visible (hover state via .dragging class)
    const edge = await ev(cmd, `(function(){
      const r = document.querySelector('.pool-resize-handle .lane-resize-hit').getBoundingClientRect();
      return { x: Math.round(r.left), y: Math.round(r.top), h: Math.round(r.height) };
    })()`);
    await ev(cmd, `document.querySelector('.pool-resize-handle').classList.add('dragging')`);
    await sleep(150);
    const grip = await ev(cmd, `(function(){
      const r = document.querySelector('.pool-resize-handle .lane-resize-grip').getBoundingClientRect();
      return { cx: r.left + r.width / 2, cy: r.top + r.height / 2 };
    })()`);
    { const png = await cmd('Page.captureScreenshot', { clip: { x: grip.cx - 45, y: grip.cy - 45, width: 90, height: 90, scale: 4 }, format: 'png' });
      writeFileSync(join(OUT, 't255-handle-active.png'), Buffer.from(png.data, 'base64'));
      console.log('wrote t255-handle-active.png (4x zoom of grip)'); }
    await ev(cmd, `document.querySelector('.pool-resize-handle').classList.remove('dragging')`);
    // 3: widen via the real state path (authored floor), then canvas after
    await ev(cmd, `state.workflowMeta.pageWidth = (contentRightEdgeNatural() - POOL_X) + 900; renderAll();`);
    await sleep(250);
    await shot(cmd, '.canvas-wrap', 't255-canvas-widened.png');
    // 4: cleared back to auto-fit
    await ev(cmd, `state.workflowMeta.pageWidth = null; renderAll();`);
    await sleep(250);
    await shot(cmd, '.canvas-wrap', 't255-canvas-cleared.png');
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    try { rmSync(doc, { recursive: true, force: true }); rmSync(repo, { recursive: true, force: true }); rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
