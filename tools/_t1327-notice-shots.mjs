#!/usr/bin/env node
// _t1327-notice-shots.mjs — T-1327 screenshots: the import notice after opening a file as a person does, at the three
// review widths (CLAUDE.md, operator 2026-10-14). States: kitchen-sink (subprocess contents moved up, layout redrawn,
// kept annotations/groups, plus the older parts), nested-lanes (lane nesting), and a designer-written corpus map
// (plain: no notice). Each width writes a full-page shot and an element shot of the notice, and MEASURES what the shot
// shows: the notice lies inside the viewport, its text is not clipped (no overflow), it covers no drawn node (the
// T-1078 dock), every header button is inside the viewport, and the plain map shows no notice.
// Usage: node tools/_t1327-notice-shots.mjs [outdir]   (default docs/reports/T-1327-evidence)
// Exit 0 = every measure holds; 1 = one failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1327_SRC || join(REPO, 'src/aef-workflow-designer.html');
const OUT = process.argv[2] || join(REPO, 'docs/reports/T-1327-evidence');
const WIDTHS = [[1024, 768], [1440, 900], [1920, 1080]];
const STATES = [
  ['kitchen-sink', readFileSync(join(REPO, 'tests/fixtures/third-party/kitchen-sink.bpmn'), 'utf8'), true],
  ['nested-lanes', readFileSync(join(REPO, 'tests/fixtures/t1327/nested-lanes.bpmn'), 'utf8'), true],
  ['plain-designer-map', readFileSync(join(REPO, 'examples/aef-processes/rendered/arc-lifecycle.bpmn'), 'utf8'), false],
];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

const MEASURE = `(function(){
  var vw = innerWidth, vh = innerHeight, el = document.getElementById('lane-fix-notice'), msg = document.getElementById('lane-fix-msg');
  var shown = !!(el && el.style.display !== 'none' && el.getBoundingClientRect().width > 0);
  var out = { shown: shown, text: shown ? msg.textContent : '', problems: [] };
  if (shown) {
    var r = el.getBoundingClientRect(); out.rect = [Math.round(r.left), Math.round(r.top), Math.round(r.width), Math.round(r.height)];
    if (r.left < 0 || r.top < 0 || r.right > vw || r.bottom > vh) out.problems.push('notice outside the viewport ' + JSON.stringify(out.rect));
    if (msg.scrollWidth > msg.clientWidth + 1 || msg.scrollHeight > msg.clientHeight + 1) out.problems.push('notice text clipped');
    var hits = Array.prototype.filter.call(document.querySelectorAll('g.node'), function(g){
      var b = g.getBoundingClientRect(); return b.width > 0 && !(b.right <= r.left || b.left >= r.right || b.bottom <= r.top || b.top >= r.bottom); });
    if (hits.length) out.problems.push(hits.length + ' node(s) under the notice');
  }
  var off = Array.prototype.filter.call(document.querySelectorAll('header button'), function(b){
    var s = getComputedStyle(b); if (s.display === 'none' || s.visibility === 'hidden') return false;
    var q = b.getBoundingClientRect(); return q.width > 0 && (q.right > vw || q.left < 0); }).map(function(b){ return b.id || b.textContent.trim(); });
  if (off.length) out.problems.push('header button(s) off-screen: ' + off.join(', '));
  return out;
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log('designer missing: ' + SRC); process.exitCode = 2; return; }
  mkdirSync(OUT, { recursive: true });
  const doc = mkdtempSync(join(tmpdir(), 't1327s-doc-')), repo = mkdtempSync(join(tmpdir(), 't1327s-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1327s-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--hide-scrollbars', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl, failed = 0;
  const report = [];
  try {
    for (let i = 0; i < 100; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    for (const [w, h] of WIDTHS) {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
      for (const [name, xml, expectShown] of STATES) {
        // a fresh page each time: stored work from the previous state would add a "Restored your unsaved work" toast
        await cmd('Storage.clearDataForOrigin', { origin: BASE, storageTypes: 'local_storage,indexeddb,session_storage' }).catch(() => {});
        await cmd('Page.navigate', { url: `${BASE}/designer.html` });
        for (let i = 0; i < 200; i++) { if (await ev(cmd, `typeof _appReady!=='undefined'&&_appReady===true&&typeof adoptImportedXml==='function'`).catch(() => false)) break; await sleep(100); }
        await ev(cmd, `Promise.resolve(adoptImportedXml(${JSON.stringify(xml)}, { userImport: true })).then(function(){ return true; })`);
        await sleep(700);
        const m = await ev(cmd, MEASURE);
        if (m.shown !== expectShown) m.problems.push(expectShown ? 'no notice shown' : 'a notice is shown on a designer-written map');
        const shot = await cmd('Page.captureScreenshot', { format: 'png' });
        const file = `${name}-${w}.png`;
        writeFileSync(join(OUT, file), Buffer.from(shot.data, 'base64'));
        if (m.rect) {
          const [x, y, cw, ch] = m.rect;
          const es = await cmd('Page.captureScreenshot', { format: 'png', clip: { x, y, width: cw, height: ch, scale: 1 } });
          writeFileSync(join(OUT, `${name}-${w}-notice.png`), Buffer.from(es.data, 'base64'));
        }
        if (m.problems.length) failed++;
        report.push({ state: name, width: w, shot: file, ...m });
        console.log(`${m.problems.length ? 'FAIL' : 'ok  '} ${name} @${w}: ${m.shown ? 'notice ' + JSON.stringify(m.rect) : 'no notice'}${m.problems.length ? ' — ' + m.problems.join('; ') : ''}`);
      }
    }
    writeFileSync(join(OUT, 'measures.json'), JSON.stringify(report, null, 1) + '\n');
    process.exitCode = failed ? 1 : 0;
  } catch (e) { console.log('ERROR ' + (e && e.stack || e)); process.exitCode = 2; }
  finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
