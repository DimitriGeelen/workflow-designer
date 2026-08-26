#!/usr/bin/env node
// _versions-verify-cdp.mjs — verify B4 (T-131): version history modal with thumbnails + revert.
// Sidecar on a free port against a TEMP repo+docroot; editor driven in ISOLATED headless
// chromium (own --user-data-dir; G-006). Saves v1 + v2, opens the modal, asserts 2 rows with
// loaded thumbnails, reverts to v1, asserts the editor holds v1 geometry. Screenshots. Exit 0=pass.
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
const MAP = 'arc-lifecycle';
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&!!document.getElementById('btn-versions'))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  const repo = mkdtempSync(join(tmpdir(), 'vr-repo-'));
  const doc = mkdtempSync(join(tmpdir(), 'vr-doc-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'vr-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    push('sidecar-up', up); if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1200, height: 820, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(600);

    // capture v1 geometry, save v1
    const g = await ev(cmd, `(function(){var n=state.nodes[0];return {id:n.id,y:n.y};})()`);
    await ev(cmd, `saveToProject()`); await sleep(300);
    // mutate + save v2
    await ev(cmd, `(function(){var n=state.nodes[0];n.y=(n.y||100)+50;renderAll();})()`);
    await ev(cmd, `saveToProject()`); await sleep(300);

    // open modal
    await ev(cmd, `openVersionsModal()`); await sleep(400);
    const rows = await ev(cmd, `document.querySelectorAll('#versions-modal img').length`);
    push('modal-two-rows', rows === 2, rows);
    // thumbnails load
    let imgw = 0; for (let i = 0; i < 40; i++) { imgw = await ev(cmd, `(function(){var im=document.querySelectorAll('#versions-modal img');return [].every.call(im,function(x){return x.naturalWidth>0;})&&im.length>0;})()`); if (imgw) break; await sleep(150); }
    push('thumbnails-load', imgw === true, imgw);

    // screenshot the modal
    const shot = await cmd('Page.captureScreenshot', { format: 'png' });
    const out = join(tmpdir(), 'versions-modal-shot.png');
    writeFileSync(out, Buffer.from(shot.data, 'base64')); verdict.screenshot = out;

    // click Revert on v1 (robust: button carries data-v)
    const clicked = await ev(cmd, `(function(){ var b=document.querySelector('#versions-modal button[data-v="1"]'); if(b){ b.click(); return true; } return false; })()`);
    push('revert-clicked', clicked === true, clicked);
    // wait for revert to load v1 geometry
    let reverted = null; for (let i = 0; i < 40; i++) { reverted = await ev(cmd, `(function(){var n=state.nodes.filter(function(x){return x.id===${JSON.stringify(g.id)};})[0];return n?n.y:null;})()`); if (reverted === g.y) break; await sleep(150); }
    push('revert-loads-v1', reverted === g.y, { got: reverted, wantY: g.y });

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
