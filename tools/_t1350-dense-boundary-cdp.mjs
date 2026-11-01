#!/usr/bin/env node
// _t1350-dense-boundary-cdp.mjs — T-1350: a host carrying more boundary events than its edges hold at its type's size is
// drawn at the file's size, so its events sit apart. Opens each fixture as a person does (adoptImportedXml, userImport) in
// the REAL editor, renders, and checks:
//   1. kitchen-sink's Activity_0pzvbay (12 events, 150x600 in the file) is drawn at least the file's size;
//   2. no two boundary circles on any host overlap (centres at least 36 px apart);
//   3. a host that fits at its type's size gets no size of its own (boundary-events.bpmn: every host);
//   4. the saved DI draws the dense host at the size it is drawn, the reparsed host keeps it (undo re-parses a save),
//      and a second save is byte-identical.
//   node tools/_t1350-dense-boundary-cdp.mjs        T1350_SRC=<designer.html> substitutes another source
// Exit 0 = all green; 1 = a check failed; 2 = misconfig.
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
const FIXDIR = join(REPO, 'tests', 'fixtures', 'third-party');
const DESIGNER = process.env.T1350_SRC || join(REPO, 'src', 'aef-workflow-designer.html');
const FIXTURES = ['kitchen-sink.bpmn', 'boundary-events.bpmn'];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// In the page: open, render, measure every host's boundary circles, then save twice.
const DENSE = { 'kitchen-sink.bpmn': { Activity_0pzvbay: { w: 150, h: 600 } }, 'boundary-events.bpmn': {} };
const CHECK = `(async function(xml, dense){
  await adoptImportedXml(xml, { userImport: true }); renderAll(); await new Promise(function(r){ setTimeout(r, 120); });
  var errs = [], byOrig = {}, hosts = {}, events = 0;
  function size(n){ return n.drawSize || NODE_DEFAULTS[n.type]; }
  state.nodes.forEach(function(n){ byOrig[n.originalId || n.id] = n; });
  state.nodes.forEach(function(n){ var h = boundaryHostOf(n); if (!h) return; events++;
    (hosts[h.originalId || h.id] = hosts[h.originalId || h.id] || []).push(n); });
  Object.keys(dense).forEach(function(id){ var h = byOrig[id];
    if (!h) { errs.push(id + ': not imported'); return; }
    var s = size(h); if (s.w < dense[id].w || s.h < dense[id].h) errs.push(id + ': drawn ' + s.w + 'x' + s.h + ', the file draws it ' + dense[id].w + 'x' + dense[id].h);
    if (!h.drawSize) errs.push(id + ': no size of its own'); });
  Object.keys(hosts).forEach(function(hk){ var h = byOrig[hk], evs = hosts[hk];
    if (h && h.drawSize && !dense[hk]) errs.push(hk + ': given a size of its own (' + h.drawSize.w + 'x' + h.drawSize.h + ') though its events fit');
    for (var i = 0; i < evs.length; i++) for (var j = i + 1; j < evs.length; j++) {
      var a = evs[i], b = evs[j], da = size(a), db = size(b),
          d = Math.hypot(a.x + da.w / 2 - b.x - db.w / 2, a.y + da.h / 2 - b.y - db.h / 2);
      if (d < 36) errs.push((a.originalId || a.id) + ' and ' + (b.originalId || b.id) + ' overlap (' + d.toFixed(1) + ' px apart) on ' + hk); } });
  var out1 = buildBpmnXml(state);
  Object.keys(dense).forEach(function(id){ var h = byOrig[id]; if (!h) return;
    var m = new RegExp('bpmnElement="' + displayIdOf(h) + '"[^>]*>\\\\s*<dc:Bounds [^>]*width="([^"]+)" height="([^"]+)"').exec(out1);
    if (!m) errs.push(id + ': no shape in the save');
    else if (+m[1] !== size(h).w || +m[2] !== size(h).h) errs.push(id + ': saved ' + m[1] + 'x' + m[2] + ', drawn ' + size(h).w + 'x' + size(h).h); });
  state = parseBpmnXml(out1); refreshDisplayIds();
  var again = {}; state.nodes.forEach(function(n){ again[n.originalId || n.id] = n; });
  Object.keys(dense).forEach(function(id){ var h = again[id];
    if (!h || !h.drawSize) errs.push(id + ': lost its size on reparse (undo would shrink it)'); });
  if (buildBpmnXml(state) !== out1) errs.push('second save differs');
  return { errs: errs, events: events };
})`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1350-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1350-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1350-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const rows = []; let cl;
  try {
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) break; } catch (_) {} await sleep(100); }
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; };' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(300);
    for (const f of FIXTURES) {
      const xml = readFileSync(join(FIXDIR, f), 'utf8');
      rows.push({ f, r: await ev(cmd, `${CHECK}(${JSON.stringify(xml)}, ${JSON.stringify(DENSE[f])}).catch(function(e){ return { errs: ['exception: ' + e] }; })`) });
    }
  } catch (e) {
    rows.push({ f: 'harness', r: { errs: [String(e && e.stack || e)] } });
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  let bad = 0, n = 0;
  for (const { f, r } of rows) {
    const errs = (r && r.errs) || ['no result'];
    if (r && r.events) n += r.events;
    if (errs.length) bad++;
    console.log(`${errs.length ? 'FAIL' : 'ok  '} ${f}${r && r.events != null ? `  (${r.events} boundary events drawn in the file)` : ''}`);
    for (const e of errs.slice(0, 10)) console.log(`       ${e}`);
    if (errs.length > 10) console.log(`       ... ${errs.length - 10} more`);
  }
  if (!n) { bad++; console.log('FAIL no boundary event with a drawn host in the fixtures: the check measured nothing'); }
  console.log(`T-1350: ${bad ? 'RED' : 'GREEN'} — ${FIXTURES.length} fixtures, ${n} boundary events checked`);
  process.exitCode = bad ? 1 : 0;
}
main();
