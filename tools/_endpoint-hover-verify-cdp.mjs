#!/usr/bin/env node
// _endpoint-hover-verify-cdp.mjs — verify T-133: edge endpoint handles have an enlarged,
// transparent grab/hover halo. Serves the editor from a TEMP docroot (gallery-serve.py) and
// drives it in ISOLATED headless chromium (own --user-data-dir; G-006). Selects an edge,
// asserts halo(r11)+dot(r6, pointer-events:none) structure, then does a REAL hover at a point
// outside the visible dot but inside the halo and asserts the dot highlights (proving the
// enlarged zone drives feedback). Screenshots the endpoint region for the READ step. Exit 0=pass.
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
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&Array.isArray(state.edges)&&state.edges.length>0)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 'ep-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'ep-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'ep-udd-'));
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
    await waitReady(cmd); await sleep(500);

    // select an edge so the endpoint handles render
    await ev(cmd, `(function(){ selection = { kind:'edge', id: state.edges[0].id }; renderAll(); })()`);
    await sleep(200);

    // structure: 2 halos (r11) + 2 dots (r6, pointer-events none)
    const struct = await ev(cmd, `(function(){
      var hits = [].slice.call(document.querySelectorAll('.edge-handle-endpoint-hit'));
      var dots = [].slice.call(document.querySelectorAll('.edge-handle-endpoint'));
      var hitR = hits.map(function(h){return parseFloat(h.getAttribute('r'));});
      var dotR = dots.map(function(d){return parseFloat(d.getAttribute('r'));});
      var pe = dots.length ? getComputedStyle(dots[0]).pointerEvents : null;
      return { nHits: hits.length, nDots: dots.length, hitR: hitR, dotR: dotR, dotPE: pe };
    })()`);
    push('two-halos-r11', struct.nHits === 2 && struct.hitR.every(r => r === 11), struct);
    push('two-dots-r6-noevents', struct.nDots === 2 && struct.dotR.every(r => r === 6) && struct.dotPE === 'none', struct);

    // grab-target roughly doubled vs old r6
    push('grab-radius-enlarged', struct.hitR[0] >= 10, struct.hitR[0]);

    // screen coords of the first halo + scale
    const loc = await ev(cmd, `(function(){
      var hit = document.querySelectorAll('.edge-handle-endpoint-hit')[0];
      var svg = document.getElementById('canvas'); var ctm = svg.getScreenCTM();
      var pt = svg.createSVGPoint(); pt.x = parseFloat(hit.getAttribute('cx')); pt.y = parseFloat(hit.getAttribute('cy'));
      var sp = pt.matrixTransform(ctm);
      return { sx: sp.x, sy: sp.y, scale: ctm.a };
    })()`);
    const dotFill = () => ev(cmd, `getComputedStyle(document.querySelectorAll('.edge-handle-endpoint')[0]).fill`);
    const dotRad = () => ev(cmd, `getComputedStyle(document.querySelectorAll('.edge-handle-endpoint')[0]).r`);

    // baseline: cursor parked far away → dot at rest (accent, not lime)
    await cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 5, y: 5 }); await sleep(120);
    const restFill = await dotFill();

    // hover at a RING point: ~8.5 user-units from centre → outside dot(r6), inside halo(r11)
    const off = 8.5 * loc.scale;
    await cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: loc.sx + off, y: loc.sy }); await sleep(150);
    const ringFill = await dotFill();
    const ringR = await dotRad();
    // #d8ff7d = rgb(216, 255, 125)
    const isLime = f => /216,\s*255,\s*125/.test(f) || /d8ff7d/i.test(f);
    push('rest-not-lime', !isLime(restFill), restFill);
    push('halo-ring-hover-highlights-dot', isLime(ringFill), { ringFill, restFill });
    push('halo-ring-hover-grows-dot', parseFloat(ringR) >= 7.5, ringR);

    // element-level screenshot around the endpoint (clip), for the READ step
    const clip = { x: Math.max(0, loc.sx - 60), y: Math.max(0, loc.sy - 45), width: 120, height: 90, scale: 3 };
    const shot = await cmd('Page.captureScreenshot', { format: 'png', clip });
    const out = join(tmpdir(), 'endpoint-hover-shot.png');
    writeFileSync(out, Buffer.from(shot.data, 'base64')); verdict.screenshot = out;
    // also a wider shot for context
    const shot2 = await cmd('Page.captureScreenshot', { format: 'png' });
    const out2 = join(tmpdir(), 'endpoint-hover-full.png');
    writeFileSync(out2, Buffer.from(shot2.data, 'base64')); verdict.screenshotFull = out2;

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
