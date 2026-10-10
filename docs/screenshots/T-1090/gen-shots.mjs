#!/usr/bin/env node
// docs/screenshots/T-1090/gen-shots.mjs — T-1090 visual verification: the same corpus map rendered with cross-lane
// routing 'Z' (the old route) and 'L' (one bend), as element screenshots of the canvas.
//   node docs/screenshots/T-1090/gen-shots.mjs [map-id ...]   (default: task-lifecycle)
// Writes docs/screenshots/T-1090/<map>-{Z,L}.png. Exit 0 = written; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from '../../../tools/_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..', '..', '..');
const SERVER = join(REPO, 'tools', 'gallery-serve.py');
const OUT = join(REPO, 'docs', 'screenshots', 'T-1090');
const MAPS = process.argv.slice(2).length ? process.argv.slice(2) : ['task-lifecycle'];
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

async function main() {
  mkdirSync(OUT, { recursive: true });
  const doc = mkdtempSync(join(tmpdir(), 't1090s-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1090s-repo-'));
  copyFileSync(join(REPO, 'src', 'aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'ignore'] });
  const udd = mkdtempSync(join(tmpdir(), 't1090s-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=2400,1100', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'ignore'] });
  let cl;
  try {
    for (let i = 0; i < 60; i++) { try { if ((await fetch(`http://127.0.0.1:${port}/api/health`)).ok) break; } catch (_) {} await sleep(100); }
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
    for (let i = 0; i < 200; i++) { if (await ev(cmd, `typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(100); }
    await sleep(400);
    for (const map of MAPS) {
      const xml = readFileSync(join(REPO, 'build', 'gallery', 'rendered', map + '.bpmn'), 'utf8');
      for (const mode of ['Z', 'L', 'H']) {   // T-1110: H = the mirror L (leave E, enter N/S)
        const rect = await ev(cmd, `(function(){ adoptImportedXml(${JSON.stringify(xml)}, { replace: true });
          routingPrefs.crossLane = '${mode === 'H' ? 'L' : mode}'; routingPrefs.crossLaneFirst = '${mode === 'H' ? 'horizontal' : 'vertical'}';
          _edgeGroupCache = null; renderAll();
          var svg = document.querySelector('#canvas svg') || document.querySelector('svg#canvas') || document.querySelector('svg');
          var r = svg.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height }; })()`);
        await sleep(300);
        const shot = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: rect.x, y: rect.y, width: Math.min(rect.w, 2400), height: Math.min(rect.h, 1100), scale: 1 } });
        const f = join(OUT, `${map}-${mode}.png`);
        writeFileSync(f, Buffer.from(shot.data, 'base64'));
        console.log('wrote', f.replace(REPO + '/', ''));
      }
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main().catch(e => { console.error(e); process.exitCode = 2; });
