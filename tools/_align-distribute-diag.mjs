#!/usr/bin/env node
// _align-distribute-diag.mjs — DIAGNOSTIC (not a gate). Loads the editor in isolated headless,
// captures console errors + uncaught exceptions, then invokes each layout action and reports
// whether it moved nodes or threw. Prints a JSON report. Used to reproduce the "distribute /
// align broken" field report (T-134).
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const MAP = process.argv[2] || 'arc-lifecycle';
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); const evs = []; s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } else if (m.method) evs.push(m); }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, evs, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) return { __throw: JSON.stringify(r.exceptionDetails).slice(0, 500) }; return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true)`).catch(() => false); if (ok === true) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 'ad-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'ad-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'ad-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const report = { map: MAP, actions: {}, consoleErrors: [], exceptions: [] };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down');
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    // collect console errors + exceptions
    cmd('Runtime.enable');
    const collect = () => { for (const m of cl.evs) { if (m.method === 'Runtime.consoleAPICalled' && (m.params.type === 'error' || m.params.type === 'warning')) report.consoleErrors.push(m.params.args.map(a => a.value || a.description || a.type).join(' ')); if (m.method === 'Runtime.exceptionThrown') report.exceptions.push((m.params.exceptionDetails.exception && (m.params.exceptionDetails.exception.description || m.params.exceptionDetails.exception.value)) || m.params.exceptionDetails.text); } cl.evs.length = 0; };
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(500); collect();

    // helper: snapshot all node positions
    const snap = () => ev(cmd, `JSON.stringify(state.nodes.map(function(n){return {id:n.id,x:Math.round(n.x),y:Math.round(n.y)};}))`);
    const countMoved = (a, b) => { const A = JSON.parse(a), B = JSON.parse(b); let m = 0; for (let i = 0; i < A.length; i++) if (A[i].x !== B[i].x || A[i].y !== B[i].y) m++; return m; };

    // fns exist?
    report.fnsPresent = await ev(cmd, `({alignColumns:typeof alignColumns,distributeEvenly:typeof distributeEvenly,alignRowsLane:typeof alignRowsLane,alignColumnsMoves:typeof alignColumnsMoves,tidyLane:typeof tidyLane})`);

    // ACTION: Align columns (toolbar) — call the button onclick
    let before = await snap();
    let ret = await ev(cmd, `(function(){ try { return {moved: alignColumns()}; } catch(e){ return {err:String(e && e.stack || e)}; } })()`);
    let after = await snap(); collect();
    report.actions.alignColumns = { ret, domMoved: countMoved(before, after) };

    // ACTION: Distribute evenly
    before = await snap();
    ret = await ev(cmd, `(function(){ try { return {moved: distributeEvenly()}; } catch(e){ return {err:String(e && e.stack || e)}; } })()`);
    after = await snap(); collect();
    report.actions.distributeEvenly = { ret, domMoved: countMoved(before, after) };

    // ACTION: Align rows (lane-scoped) — run on every lane
    before = await snap();
    ret = await ev(cmd, `(function(){ try { var t=0; for (var i=0;i<state.lanes.length;i++){ t += (alignRowsLane(state.lanes[i].id)||0); } return {moved:t}; } catch(e){ return {err:String(e && e.stack || e)}; } })()`);
    after = await snap(); collect();
    report.actions.alignRowsLane = { ret, domMoved: countMoved(before, after) };

    // ACTION: click the actual toolbar buttons (exercise the real handlers incl. B5 history)
    before = await snap();
    await ev(cmd, `document.getElementById('btn-distribute').click()`); await sleep(120);
    after = await snap(); collect();
    report.actions.btnDistributeClick = { text: await ev(cmd, `document.getElementById('btn-distribute').textContent`), domMoved: countMoved(before, after) };

    before = await snap();
    await ev(cmd, `document.getElementById('btn-align-cols').click()`); await sleep(120);
    after = await snap(); collect();
    report.actions.btnAlignColsClick = { text: await ev(cmd, `document.getElementById('btn-align-cols').textContent`), domMoved: countMoved(before, after) };

    process.stdout.write(JSON.stringify(report, null, 2) + '\n');
  } catch (e) {
    process.stdout.write(JSON.stringify({ error: String(e && e.stack || e), report }, null, 2) + '\n');
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
