#!/usr/bin/env node
// _undo-verify-cdp.mjs — verify B5 (T-132): general undo/redo history stack.
// Serves the editor from a TEMP docroot via gallery-serve.py on a free port; drives it in
// ISOLATED headless chromium (own --user-data-dir; never the shared browser, G-006). Exercises
// every wired mutation site through its real entry point and asserts undo restores / redo re-applies:
//   1. functions present (partial-not-broken smoke test: typeof undo/redo/pushHistory/commitHistory)
//   2. real mouse drag of a node = exactly ONE undo entry (geometry restored in one Ctrl+Z)
//   3. delete node → undo restores it (+ incident edges) → redo removes it again
//   4. add node → undo removes it
//   5. button op (Clean layout) → undo restores → redo re-applies
//   6. multi-step: two drags, undo×2 back to origin, redo×2 forward
// Screenshot written for the READ step. Exit 0 = pass.
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
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&typeof undo==='function')`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Screen-center of a node (via getScreenCTM) so a real mouse drag can be dispatched at it.
const CENTER_EXPR = id => `(function(){
  var n = state.nodes.filter(function(x){return x.id===${JSON.stringify(id)};})[0];
  var svg = document.getElementById('canvas');
  var ctm = svg.getScreenCTM();
  var d = NODE_DEFAULTS[n.type];
  var pt = svg.createSVGPoint(); pt.x = n.x + d.w/2; pt.y = n.y + d.h/2;
  var sp = pt.matrixTransform(ctm);
  return { sx: sp.x, sy: sp.y, x: n.x, y: n.y };
})()`;

async function realDrag(cmd, sx, sy, ddx, ddy) {
  await cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x: sx, y: sy, button: 'left', buttons: 1, clickCount: 1 });
  await sleep(30);
  await cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: sx + ddx / 2, y: sy + ddy / 2, button: 'left', buttons: 1 });
  await sleep(30);
  await cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: sx + ddx, y: sy + ddy, button: 'left', buttons: 1 });
  await sleep(30);
  await cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x: sx + ddx, y: sy + ddy, button: 'left', buttons: 1, clickCount: 1 });
  await sleep(80);
}

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 'undo-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'undo-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'undo-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1200, height: 820, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(600);

    // 1. smoke: the partial is not syntactically broken — all history fns present
    const fns = await ev(cmd, `[typeof undo,typeof redo,typeof pushHistory,typeof commitHistory,typeof snapshotState,typeof _restoreSnapshot].join(',')`);
    push('history-fns-present', fns === 'function,function,function,function,function,function', fns);

    // pick a draggable task node (rect, not start/end/gateway) for a clean hit-test
    const target = await ev(cmd, `(function(){var n=state.nodes.filter(function(x){return /Task/.test(x.type);})[0]||state.nodes[0];return n.id;})()`);

    // 2. real mouse drag = exactly ONE undo entry
    let c = await ev(cmd, CENTER_EXPR(target));
    const y0 = c.y;
    await realDrag(cmd, c.sx, c.sy, 0, 90);           // drag straight down
    const yMoved = await ev(cmd, `(function(){return state.nodes.filter(function(x){return x.id===${JSON.stringify(target)};})[0].y;})()`);
    push('drag-moved', Math.abs(yMoved - y0) > 20, { y0, yMoved });
    const undone = await ev(cmd, `undo()`);
    const yBack = await ev(cmd, `(function(){return state.nodes.filter(function(x){return x.id===${JSON.stringify(target)};})[0].y;})()`);
    push('drag-one-undo-restores', undone === true && Math.abs(yBack - y0) < 0.5, { undone, y0, yBack });
    const yRedo = await ev(cmd, `(function(){var ok=redo();return {ok:ok,y:state.nodes.filter(function(x){return x.id===${JSON.stringify(target)};})[0].y};})()`);
    push('drag-redo-reapplies', yRedo.ok === true && Math.abs(yRedo.y - yMoved) < 0.5, yRedo);
    await ev(cmd, `undo()`);                            // back to origin for clean slate

    // 3. delete → undo restores node+edges → redo removes again
    const before = await ev(cmd, `({n:state.nodes.length,e:state.edges.length})`);
    await ev(cmd, `deleteNode(${JSON.stringify(target)})`);
    const afterDel = await ev(cmd, `({n:state.nodes.length,e:state.edges.length})`);
    push('delete-removed', afterDel.n === before.n - 1 && afterDel.e < before.e, { before, afterDel });
    await ev(cmd, `undo()`);
    const afterUndo = await ev(cmd, `({n:state.nodes.length,e:state.edges.length,has:!!state.nodes.filter(function(x){return x.id===${JSON.stringify(target)};})[0]})`);
    push('delete-undo-restores', afterUndo.n === before.n && afterUndo.e === before.e && afterUndo.has === true, afterUndo);
    await ev(cmd, `redo()`);
    const afterRedo = await ev(cmd, `state.nodes.length`);
    push('delete-redo-removes', afterRedo === before.n - 1, afterRedo);
    await ev(cmd, `undo()`);                            // restore

    // 4. add node → undo removes it
    const n1 = await ev(cmd, `state.nodes.length`);
    await ev(cmd, `createNodeAt('serviceTask', 300, 300)`);
    const n2 = await ev(cmd, `state.nodes.length`);
    await ev(cmd, `undo()`);
    const n3 = await ev(cmd, `state.nodes.length`);
    push('add-then-undo', n2 === n1 + 1 && n3 === n1, { n1, n2, n3 });

    // 5. button op (Clean layout): nudge a node off-grid, click Clean, undo restores
    await ev(cmd, `(function(){var n=state.nodes[0];n.y=n.y+37;renderAll();})()`);
    const yDirty = await ev(cmd, `state.nodes[0].y`);
    await ev(cmd, `document.getElementById('btn-clean').click()`); await sleep(200);
    const yClean = await ev(cmd, `state.nodes[0].y`);
    const cleanMoved = Math.abs(yClean - yDirty) > 0.5;
    let btnUndo = null;
    if (cleanMoved) { await ev(cmd, `undo()`); btnUndo = await ev(cmd, `state.nodes[0].y`); }
    push('button-op-undo', cleanMoved && Math.abs(btnUndo - yDirty) < 0.5, { yDirty, yClean, btnUndo, cleanMoved });

    // 6. multi-step: two drags, undo×2 to origin, redo×2 forward
    c = await ev(cmd, CENTER_EXPR(target));
    const my0 = c.y;
    await realDrag(cmd, c.sx, c.sy, 0, 60);
    const my1 = await ev(cmd, `state.nodes.filter(function(x){return x.id===${JSON.stringify(target)};})[0].y`);
    c = await ev(cmd, CENTER_EXPR(target));
    await realDrag(cmd, c.sx, c.sy, 0, 60);
    const my2 = await ev(cmd, `state.nodes.filter(function(x){return x.id===${JSON.stringify(target)};})[0].y`);
    await ev(cmd, `undo()`); await ev(cmd, `undo()`);
    const myBack = await ev(cmd, `state.nodes.filter(function(x){return x.id===${JSON.stringify(target)};})[0].y`);
    await ev(cmd, `redo()`); await ev(cmd, `redo()`);
    const myFwd = await ev(cmd, `state.nodes.filter(function(x){return x.id===${JSON.stringify(target)};})[0].y`);
    push('multistep-undo-redo', Math.abs(myBack - my0) < 0.5 && Math.abs(myFwd - my2) < 0.5 && my1 !== my0 && my2 !== my1, { my0, my1, my2, myBack, myFwd });

    // screenshot for the READ step
    await ev(cmd, `undo();undo();`);                    // settle
    const shot = await cmd('Page.captureScreenshot', { format: 'png' });
    const out = join(tmpdir(), 'undo-verify-shot.png');
    writeFileSync(out, Buffer.from(shot.data, 'base64')); verdict.screenshot = out;

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
