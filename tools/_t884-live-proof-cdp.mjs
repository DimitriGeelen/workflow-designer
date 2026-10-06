#!/usr/bin/env node
// T-884 live proof (AC 9, not in P-011 — PL-285): the REAL corpus through the REAL server.
// Usage: node tools/_t884-live-proof-cdp.mjs <base-url> <T-XXX> <expected-current> <expected-refused-node> <expected-rule>
// Navigates an isolated headless Chromium to <base>/designer.html?load=rendered/task-lifecycle.bpmn&instance=<T-XXX>
// (the base must be a gallery-serve.py instance, so /api/instances is live), asserts the overlay
// and writes docs/reports/t884-shots/live-<T-XXX>-m.png (element) and live-<T-XXX>-map.png (canvas).
import { readFileSync, existsSync, readdirSync, mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { pageWsUrl } from './_cdp-attach.mjs';
const HERE = dirname(fileURLToPath(import.meta.url));
const OUT = join(HERE, '..', 'docs', 'reports', 't884-shots');
const [BASE, TASK, WANT_CUR, WANT_REF_NODE, WANT_RULE] = process.argv.slice(2);
if (!BASE || !TASK) { console.error('usage: <base-url> <T-XXX> <current> <refused-node> <rule>'); process.exit(2); }
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
(async () => {
  const udd = mkdtempSync(join(tmpdir(), 't884-live-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1600,1000', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let rc = 0;
  try {
    const cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/task-lifecycle.bpmn&instance=${encodeURIComponent(TASK)}` });
    const t0 = Date.now();
    for (;;) { const ok = await ev(cmd, `(typeof instanceOverlayState==='function' && _appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null) && state && (state.nodes||[]).length>0 && instanceView.available!==null)`).catch(() => false); if (ok) break; if (Date.now() - t0 > 30000) throw new Error('editor/overlay not ready'); await sleep(150); }
    await ev(cmd, 'labelPrefs.size = "m"; renderAll(); true'); await sleep(150);
    const r = await ev(cmd, `(() => { const s = document.getElementById('instancePicker'); const g = document.querySelector('g.node[data-instance="current"]'); const rf = document.querySelector('g.node[data-instance="refused"]') || (g && g.querySelector('[data-instance-badge="refused"]') ? g : null); const rb = document.querySelector('[data-instance-badge="refused"]'); return { available: instanceView.available, selected: instanceView.selected, picker: s.options[s.selectedIndex].textContent, nInstances: instanceView.instances.length, current: g ? displayIdOf(findNode(g.getAttribute('data-id'))) : null, done: Array.from(document.querySelectorAll('g.node[data-instance="done"]')).map(x => displayIdOf(findNode(x.getAttribute('data-id')))), refusedNode: rf ? displayIdOf(findNode(rf.getAttribute('data-id'))) : null, refusedBadge: rb ? rb.textContent : null, overlay: instanceView.overlay }; })()`);
    console.log(JSON.stringify(r, null, 1));
    const ok = r.available === true && r.selected === TASK && r.current === WANT_CUR && r.refusedNode === WANT_REF_NODE && r.refusedBadge === '⛔ ' + WANT_RULE;
    console.log(`LIVE ${ok ? 'PASS' : 'FAIL'}  ${TASK}: current=${r.current} refused=${r.refusedNode} badge=${JSON.stringify(r.refusedBadge)} picker=${JSON.stringify(r.picker)}`);
    mkdirSync(OUT, { recursive: true });
    const shot = async (sel, file, pad) => { const box = await ev(cmd, `(() => { const g = document.querySelector(${JSON.stringify(sel)}); if (!g) return null; const b = g.getBoundingClientRect(); return { x: b.x, y: b.y, w: b.width, h: b.height }; })()`); if (!box) return; const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: Math.max(0, box.x - pad), y: Math.max(0, box.y - pad - 6), width: box.w + 2 * pad, height: box.h + 2 * pad + 6, scale: 2 } }); writeFileSync(join(OUT, file), Buffer.from(s.data, 'base64')); };
    await shot('g.node[data-instance="current"]', `live-${TASK}-current-m.png`, 30);
    if (r.refusedNode && r.refusedNode !== r.current) await shot('g.node[data-instance="refused"]', `live-${TASK}-refused-m.png`, 30);
    const full = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: 1600, height: 1000, scale: 1 } });
    writeFileSync(join(OUT, `live-${TASK}-map.png`), Buffer.from(full.data, 'base64'));
    rc = ok ? 0 : 2;
  } catch (e) { console.error('DRIVER ERROR', e && e.message); rc = 2; }
  finally { try { br.kill(); } catch (_) {} }
  process.exit(rc);
})();
