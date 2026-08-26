#!/usr/bin/env node
// _saveproject-verify-cdp.mjs — verify B3 (T-130): the editor "Save to project" button
// captures a thumbnail and POSTs to the B2 sidecar. Runs a sidecar on a free port against
// a TEMP repo+docroot (never the real repo), drives the editor in ISOLATED headless
// chromium (own --user-data-dir; never the shared browser, G-006), clicks Save, asserts a
// version with a thumbnail was written and the "✓ Saved v1" feedback shows. Screenshots.
// Exit 0 = pass.
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

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright');
  const c = [];
  if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome'));
  c.sort().reverse();
  for (const x of c) if (existsSync(x)) return x;
  throw new Error('no chromium');
}
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', e => rej(e)); }); const cmd = (method, params = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(method + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method, params })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&!!document.getElementById('btn-save-project'))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  const repo = mkdtempSync(join(tmpdir(), 'sp-repo-'));
  const doc = mkdtempSync(join(tmpdir(), 'sp-doc-'));
  // assemble docroot: designer.html (B3) + rendered/<map>.bpmn
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;

  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'sp-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [], pass: false };
  const push = (name, pass, got) => verdict.steps.push({ step: name, pass: !!pass, got });
  try {
    // wait server health
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    push('sidecar-up', up); if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));

    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1200, height: 820, deviceScaleFactor: 1, mobile: false });

    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(600);

    // button revealed by detectSaveApi
    const btn = await ev(cmd, `(function(){var b=document.getElementById('btn-save-project');return {shown:!!b&&b.style.display!=='none', api:_apiAvailable};})()`);
    push('save-button-visible', btn.shown === true && btn.api === true, btn);

    // click Save to project
    await ev(cmd, `document.getElementById('btn-save-project').click()`);
    // wait for the POST to complete + feedback
    let fb = null;
    for (let i = 0; i < 40; i++) { fb = await ev(cmd, `document.getElementById('btn-save-project').textContent`); if (/Saved v/.test(fb)) break; await sleep(150); }
    push('save-feedback', /Saved v1/.test(fb || ''), fb);

    // server side: version written with thumbnail
    const vs = await (await fetch(`${BASE}/api/versions?id=${MAP}`)).json();
    push('version-written', Array.isArray(vs) && vs.length === 1 && vs[0].v === 1, vs);
    push('thumbnail-written', existsSync(join(repo, '.editor-versions', MAP, 'v1.png')), vs[0] && vs[0].thumb);
    // round-trip: GET version returns bpmn
    const gv = await fetch(`${BASE}/api/version?id=${MAP}&v=1`);
    const gvt = await gv.text();
    push('version-roundtrip', gv.status === 200 && gvt.includes('<') && gvt.length > 200, { status: gv.status, len: gvt.length });

    // screenshot
    const shot = await cmd('Page.captureScreenshot', { format: 'png' });
    const out = join(tmpdir(), 'saveproject-shot.png');
    writeFileSync(out, Buffer.from(shot.data, 'base64'));
    verdict.screenshot = out;

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
