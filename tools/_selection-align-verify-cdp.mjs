#!/usr/bin/env node
// _selection-align-verify-cdp.mjs — verify T-134: selection-scoped Align / Distribute.
// Serves the editor from a TEMP docroot, drives it in ISOLATED headless chromium (own
// --user-data-dir; G-006). Multi-selects 3 nodes, asserts the Align/Distribute panel renders,
// then for each op perturbs the 3 nodes to distinct coords, clicks the button, and asserts the
// selection aligned/distributed (regardless of distance) + one undo restores. Screenshots the
// panel for the READ step. Exit 0 = pass.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const MAP = 'arc-lifecycle';
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&typeof renderMultiSelectProps==='function')`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 'sa-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'sa-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'sa-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down');
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1200, height: 820, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(500);

    // multi-select the first 3 nodes
    await ev(cmd, `(function(){ var ids = state.nodes.slice(0,3).map(function(n){return n.id;}); multiSelect = new Set(ids); selection = { kind:'node', id: ids[0] }; renderProperties(); window.__ids = ids; })()`);
    await sleep(150);

    // panel renders the bar
    const btns = await ev(cmd, `[].slice.call(document.querySelectorAll('#properties button')).map(function(b){return b.textContent.trim();})`);
    const hasBar = ['Left', 'Centre', 'Right', 'Top', 'Middle', 'Bottom', 'Horizontal', 'Vertical'].every(k => btns.some(t => t.includes(k)));
    push('multi-select-bar-renders', hasBar, btns);

    // helper: perturb the 3 selected to distinct coords
    // re-establish the multi-selection each time (undo() clears it via _restoreSnapshot) + perturb
    const perturb = () => ev(cmd, `(function(){ multiSelect = new Set(window.__ids); selection = { kind:'node', id: window.__ids[0] }; var ns=window.__ids.map(findNode); ns[0].x=90;ns[0].y=110; ns[1].x=180;ns[1].y=200; ns[2].x=300;ns[2].y=330; renderAll(); renderProperties(); })()`);
    const click = label => ev(cmd, `(function(){ var b=[].slice.call(document.querySelectorAll('#properties button')).filter(function(x){return x.textContent.indexOf(${JSON.stringify(label)})>=0;})[0]; if(b){b.click();return true;} return false; })()`);
    const coords = () => ev(cmd, `window.__ids.map(function(id){var n=findNode(id);var d=NODE_DEFAULTS[n.type];return {x:n.x,y:n.y,w:d.w,h:d.h,cx:n.x+d.w/2,cy:n.y+d.h/2,r:n.x+d.w,b:n.y+d.h};})`);
    const near = (a, b, t = 0.6) => Math.abs(a - b) <= t;
    const allEq = (arr, t = 0.6) => arr.every(v => near(v, arr[0], t));

    // Left → all x equal (min)
    await perturb(); await click('Left'); await sleep(80);
    let c = await coords();
    push('align-left', allEq(c.map(n => n.x)) && near(Math.min(...c.map(n => n.x)), 90), c.map(n => Math.round(n.x)));
    // undo restores
    await ev(cmd, `undo()`); const cu = await coords();
    push('align-left-undo', !allEq(cu.map(n => n.x)) && near(cu[0].x, 90) && near(cu[2].x, 300), cu.map(n => Math.round(n.x)));

    // Centre → all cx equal
    await perturb(); await click('Centre'); await sleep(80);
    c = await coords(); push('align-centre-x', allEq(c.map(n => n.cx)), c.map(n => Math.round(n.cx)));

    // Right → all right edge equal
    await perturb(); await click('Right'); await sleep(80);
    c = await coords(); push('align-right', allEq(c.map(n => n.r)), c.map(n => Math.round(n.r)));

    // Top → all y equal
    await perturb(); await click('Top'); await sleep(80);
    c = await coords(); push('align-top', allEq(c.map(n => n.y)) && near(Math.min(...c.map(n => n.y)), 110), c.map(n => Math.round(n.y)));

    // Middle → all cy equal
    await perturb(); await click('Middle'); await sleep(80);
    c = await coords(); push('align-middle-y', allEq(c.map(n => n.cy)), c.map(n => Math.round(n.cy)));

    // Bottom → all bottom edge equal
    await perturb(); await click('Bottom'); await sleep(80);
    c = await coords(); push('align-bottom', allEq(c.map(n => n.b)), c.map(n => Math.round(n.b)));

    // Distribute Horizontal → equal consecutive centre-x deltas
    await perturb(); await click('Horizontal'); await sleep(80);
    c = await coords(); { const cx = c.map(n => n.cx).sort((a, b) => a - b); const d1 = cx[1] - cx[0], d2 = cx[2] - cx[1]; push('distribute-horizontal', near(d1, d2, 0.6) && d1 > 1, { cx: cx.map(Math.round), d1: Math.round(d1), d2: Math.round(d2) }); }

    // Distribute Vertical → equal consecutive centre-y deltas
    await perturb(); await click('Vertical'); await sleep(80);
    c = await coords(); { const cy = c.map(n => n.cy).sort((a, b) => a - b); const d1 = cy[1] - cy[0], d2 = cy[2] - cy[1]; push('distribute-vertical', near(d1, d2, 0.6) && d1 > 1, { cy: cy.map(Math.round), d1: Math.round(d1), d2: Math.round(d2) }); }

    // screenshots for the READ step (aligned state + panel)
    await perturb(); await click('Middle'); await sleep(100);
    const shot = await cmd('Page.captureScreenshot', { format: 'png' });
    writeFileSync(join(tmpdir(), 'selection-align-full.png'), Buffer.from(shot.data, 'base64')); verdict.screenshotFull = join(tmpdir(), 'selection-align-full.png');
    const panelClip = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: 878, y: 55, width: 322, height: 340, scale: 2 } });
    writeFileSync(join(tmpdir(), 'selection-align-panel.png'), Buffer.from(panelClip.data, 'base64')); verdict.screenshotPanel = join(tmpdir(), 'selection-align-panel.png');

    verdict.pass = verdict.steps.every(s => s.pass);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), steps: verdict.steps }, null, 2) + '\n');
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    try { rmSync(repo, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
