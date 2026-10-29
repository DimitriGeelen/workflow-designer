#!/usr/bin/env node
// _t1345-message-shots.mjs — T-1345 screenshots: the two messages the nesting edit rules show, at the three review widths
// (CLAUDE.md, operator 2026-10-14), after opening tests/fixtures/t1345/nested-two-lanes.bpmn as a person does:
//   refused  — a flow from a nested task to a top-level task is refused (addEdge, the connect gesture's commit);
//   deleted  — subprocess "Outer" is deleted and its 4 contents move to the process (deleteNode).
// Each writes a full-window shot and an element shot of the toast, and MEASURES what the shot shows: the toast lies
// inside the viewport, its text is not clipped (no overflow), and it covers no toolbar button.
// Usage: node tools/_t1345-message-shots.mjs [outdir]   (default docs/reports/T-1345-evidence)
// Exit 0 = every measure holds; 1 = one failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1345_SRC || join(REPO, 'src/aef-workflow-designer.html');
const OUT = process.argv[2] || join(REPO, 'docs/reports/T-1345-evidence');
const FIXTURE = readFileSync(join(REPO, 'tests/fixtures/t1345/nested-two-lanes.bpmn'), 'utf8');
const WIDTHS = [[1024, 768], [1440, 900], [1920, 1080]];
const STATES = [
  ['refused', `addEdge(state.nodes.find(function(n){ return n.name === 'Inner task'; }).uid, state.nodes.find(function(n){ return n.name === 'Top task'; }).uid)`, /cannot cross a subprocess boundary/],
  ['deleted', `deleteNode(state.nodes.find(function(n){ return n.name === 'Outer'; }).uid)`, /4 elements moved out of subprocess "Outer" into the process/],
];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

const MEASURE = `(function(){
  var t = document.getElementById('app-toast'); if (!t) return { shown: false };
  var r = t.getBoundingClientRect(), m = t.querySelector('span');
  var inView = r.left >= 0 && r.top >= 0 && r.right <= innerWidth && r.bottom <= innerHeight;
  var clipped = m ? m.scrollWidth > m.clientWidth + 1 || t.scrollWidth > t.clientWidth + 1 : true;
  var covers = Array.prototype.filter.call(document.querySelectorAll('header button, .toolbar button, .topbar button'), function(b){
    var q = b.getBoundingClientRect(); return q.width && !(q.right <= r.left || q.left >= r.right || q.bottom <= r.top || q.top >= r.bottom); })
    .map(function(b){ return b.textContent.trim(); });
  return { shown: true, text: t.textContent, rect: [Math.round(r.left), Math.round(r.top), Math.round(r.right), Math.round(r.bottom)], inView: inView, clipped: clipped, covers: covers };
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  mkdirSync(OUT, { recursive: true });
  const doc = mkdtempSync(join(tmpdir(), 't1345s-doc-')), repo = mkdtempSync(join(tmpdir(), 't1345s-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html')); mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort(), BASE = `http://127.0.0.1:${port}`;
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const udd = makeProfileDir('t1345s-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1920,1080', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const rows = []; let cl, bad = 0;
  try {
    for (let i = 0; i < 100; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; };' });
    for (const [w, h] of WIDTHS) {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
      for (const [name, action, want] of STATES) {
        await cmd('Storage.clearDataForOrigin', { origin: BASE, storageTypes: 'local_storage,indexeddb,session_storage' }).catch(() => {});
        await cmd('Page.navigate', { url: `${BASE}/designer.html` });
        for (let i = 0; i < 200; i++) { if (await ev(cmd, `typeof _appReady!=='undefined'&&_appReady===true&&typeof adoptImportedXml==='function'`).catch(() => false)) break; await sleep(100); }
        await ev(cmd, `adoptImportedXml(${JSON.stringify(FIXTURE)}, { userImport: true })`); await sleep(300);
        await ev(cmd, `(function(){ var n = document.getElementById('lane-fix-notice'); if (n) n.style.display = 'none'; var t = document.getElementById('app-toast'); if (t) t.remove(); return true; })()`);
        await ev(cmd, `(${action}, true)`); await sleep(500);
        const m = await ev(cmd, MEASURE);
        const ok = m.shown && want.test(m.text) && m.inView && !m.clipped && m.covers.length === 0;
        if (!ok) bad++;
        rows.push({ name, w, ok, ...m });
        const file = `${name}-${w}.png`;
        writeFileSync(join(OUT, file), Buffer.from((await cmd('Page.captureScreenshot', { format: 'png' })).data, 'base64'));
        if (m.shown) {
          const [x, y, x2, y2] = m.rect, pad = 8;
          const clip = { x: Math.max(0, x - pad), y: Math.max(0, y - pad), width: Math.min(w, x2 + pad) - Math.max(0, x - pad), height: Math.min(h, y2 + pad) - Math.max(0, y - pad), scale: 1 };
          writeFileSync(join(OUT, `${name}-${w}-toast.png`), Buffer.from((await cmd('Page.captureScreenshot', { format: 'png', clip })).data, 'base64'));
        }
        console.log(`${ok ? 'ok  ' : 'FAIL'} ${name} @${w}: ${m.shown ? `toast [${m.rect}]${m.clipped ? ' CLIPPED' : ''}${m.inView ? '' : ' OUT OF VIEW'}${m.covers.length ? ' covers ' + m.covers.join(',') : ''}` : 'no toast'}`);
      }
    }
  } catch (e) {
    console.log('harness: ' + (e && e.stack || e)); process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  writeFileSync(join(OUT, 'measures.json'), JSON.stringify(rows, null, 2) + '\n');
  if (process.exitCode !== 2) process.exitCode = bad ? 1 : 0;
}
main();
