#!/usr/bin/env node
// _t1366-shots.mjs — T-1366 visual evidence: tests/fixtures/t1366/plain-event-kinds.bpmn opened in the real editor.
// Writes to OUT (default docs/reports/T-1366-evidence/):
//   events-<W>.png           the whole window at W = 1024, 1440, 1920 (opening state);
//   events-<W>-zoom.png      the row of events, 3x, so each marker can be read;
//   panel-<W>.png            the window with the conditional event selected (the side panel heads it);
//   events-1920-zoom-before.png  the same row on T1366_BEFORE (the pre-T-1366 source), when given.
// Exit 0 = every shot written; 1 = a shot failed.
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, mkdirSync, existsSync, readFileSync, readdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const OUT = process.argv[2] || join(REPO, 'docs/reports/T-1366-evidence');
const SRC = join(REPO, 'src/aef-workflow-designer.html');
const BEFORE = process.env.T1366_BEFORE || '';
const MAP = readFileSync(join(REPO, 'tests/fixtures/t1366/plain-event-kinds.bpmn'), 'utf8');
const SERVER = join(HERE, 'gallery-serve.py');
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; }

// Bounding box (viewport px) of every event group plus its labels.
const ROW = `(() => { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
  for (const n of state.nodes) for (const el of document.querySelectorAll('g[data-id="' + n.id + '"], text[data-nl="' + n.uid + '"]')) {
    const b = el.getBoundingClientRect(); if (!b.width) continue;
    x0 = Math.min(x0, b.x); y0 = Math.min(y0, b.y); x1 = Math.max(x1, b.right); y1 = Math.max(y1, b.bottom); }
  return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 }; })()`;

async function shoot(src, W, H, base, shots) {
  const doc = mkdtempSync(join(tmpdir(), 't1366s-doc-')); const repo = mkdtempSync(join(tmpdir(), 't1366s-repo-'));
  copyFileSync(src, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: 'ignore' });
  const udd = makeProfileDir('t1366s-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', `--window-size=${W},${H}`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  const BASE = `http://127.0.0.1:${port}`;
  try {
    for (let i = 0; i < 100; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
    const cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    for (let t0 = Date.now(); Date.now() - t0 < 20000; await sleep(150)) if (await ev(cmd, `typeof adoptImportedXml==='function'&&_appReady===true`).catch(() => false)) break;
    await ev(cmd, `adoptImportedXml(${JSON.stringify(MAP)}); renderAll(); true`); await sleep(900);
    const save = async (name, clip) => { const s = await cmd('Page.captureScreenshot', clip ? { format: 'png', clip } : { format: 'png' }); writeFileSync(join(OUT, name), Buffer.from(s.data, 'base64')); shots.push(name); };
    if (base === 'events') await save(`events-${W}.png`);
    const r = await ev(cmd, ROW);
    const pad = 24, x = Math.max(0, r.x - pad), y = Math.max(0, r.y - pad);
    await save(base === 'events' ? `events-${W}-zoom.png` : `events-${W}-zoom-before.png`,
               { x, y, width: Math.min(W - x, r.w + 2 * pad), height: Math.min(H - y, r.h + 2 * pad), scale: 3 });
    if (base === 'events') {
      await ev(cmd, `(() => { const c = state.nodes.find(n => n.name === 'Status Qualified'); selection = { kind: 'node', id: c.uid }; renderAll(); renderProperties(); return true; })()`);
      await sleep(400);
      await save(`panel-${W}.png`);
    }
    cl.close();
  } finally { br.kill('SIGKILL'); py.kill(); }
}

async function main() {
  mkdirSync(OUT, { recursive: true });
  const shots = [];
  for (const [W, H] of [[1024, 768], [1440, 900], [1920, 1080]]) await shoot(SRC, W, H, 'events', shots);
  if (BEFORE) await shoot(BEFORE, 1920, 1080, 'before', shots);
  console.log(JSON.stringify({ ok: true, out: OUT, shots }, null, 1));
}
main().catch(e => { console.error(e); process.exit(1); });
