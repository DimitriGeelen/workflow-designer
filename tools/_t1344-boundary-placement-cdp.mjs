#!/usr/bin/env node
// _t1344-boundary-placement-cdp.mjs — T-1344: another tool's boundary events sit where the file placed them on their host.
// Opens each fixture as a person does (adoptImportedXml, userImport) in the REAL editor, renders, and for every
// boundary event attached to a host that is drawn in the file:
//   1. the edge it sits on in the designer (top/right/bottom/left of its host) is the edge it sits on in the file;
//   2. events on one edge of one host keep the file's order along that edge;
//   3. no two events on one host sit on the same point (under 2 px apart) — the stacking T-1344 fixes. Overlap on a
//      dense host (kitchen-sink's 6 per edge) is T-1350's, measured by _t1350-dense-boundary-cdp.mjs;
//   4. a second save (reparse the first) is byte-identical.
//   node tools/_t1344-boundary-placement-cdp.mjs        T1344_SRC=<designer.html> substitutes another source
// Exit 0 = all green; 1 = a check failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';   // T-1395: rejects on Chrome's death and after cmdMs, never waits for ever

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXDIR = join(REPO, 'tests', 'fixtures', 'third-party');
const DESIGNER = process.env.T1344_SRC || join(REPO, 'src', 'aef-workflow-designer.html');
const FIXTURES = ['kitchen-sink.bpmn', 'boundary-events.bpmn'];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// In the page: open, render, compare each attached event's edge and order with the file, then save twice.
const CHECK = `(async function(xml){
  var MODEL = 'http://www.omg.org/spec/BPMN/20100524/MODEL', DI = 'http://www.omg.org/spec/BPMN/20100524/DI',
      DC = 'http://www.omg.org/spec/DD/20100524/DC';
  function edgeOf(cx, cy, b){ var d = [[Math.abs(cy - b.y), 'top', cx], [Math.abs(cx - (b.x + b.w)), 'right', cy],
    [Math.abs(cy - (b.y + b.h)), 'bottom', -cx], [Math.abs(cx - b.x), 'left', -cy]];
    var m = d.reduce(function(a, c){ return c[0] < a[0] ? c : a; }); return { edge: m[1], along: m[2] }; }
  var doc = new DOMParser().parseFromString(xml, 'application/xml'), bounds = {};
  Array.prototype.forEach.call(doc.getElementsByTagNameNS(DI, 'BPMNShape'), function(s){
    var b = s.getElementsByTagNameNS(DC, 'Bounds')[0]; if (!b) return;
    bounds[s.getAttribute('bpmnElement')] = { x: +b.getAttribute('x'), y: +b.getAttribute('y'), w: +b.getAttribute('width'), h: +b.getAttribute('height') }; });
  var file = {};
  Array.prototype.forEach.call(doc.getElementsByTagNameNS(MODEL, 'boundaryEvent'), function(e){
    var id = e.getAttribute('id'), host = e.getAttribute('attachedToRef'), eb = bounds[id], hb = bounds[host];
    if (!eb || !hb || !hb.w) return;
    file[id] = Object.assign({ host: host }, edgeOf(eb.x + eb.w / 2, eb.y + eb.h / 2, hb)); });
  await adoptImportedXml(xml, { userImport: true }); renderAll(); await new Promise(function(r){ setTimeout(r, 120); });
  var errs = [], got = {}, byOrig = {};
  state.nodes.forEach(function(n){ byOrig[n.originalId || n.id] = n; });
  Object.keys(file).forEach(function(id){
    var n = byOrig[id], h = n && byOrig[file[id].host];
    if (!n || !h) { errs.push(id + ': not imported with its host'); return; }
    var nd = NODE_DEFAULTS[n.type], hd = h.drawSize || NODE_DEFAULTS[h.type];   // T-1350: a dense host has its own size
    got[id] = Object.assign({ host: file[id].host, cx: n.x + nd.w / 2, cy: n.y + nd.h / 2 },
      edgeOf(n.x + nd.w / 2, n.y + nd.h / 2, { x: h.x, y: h.y, w: hd.w, h: hd.h }));
    if (got[id].edge !== file[id].edge) errs.push(id + ': on the ' + got[id].edge + ' edge, the file has it on the ' + file[id].edge);
  });
  var groups = {};
  Object.keys(got).forEach(function(id){ var k = got[id].host + '/' + got[id].edge; (groups[k] = groups[k] || []).push(id); });
  Object.keys(groups).forEach(function(k){
    var ids = groups[k], a = ids.slice().sort(function(p, q){ return file[p].along - file[q].along; }),
        b = ids.slice().sort(function(p, q){ return got[p].along - got[q].along; });
    if (a.join() !== b.join()) errs.push(k + ': order along the edge ' + b.join(',') + ', the file has ' + a.join(','));
  });
  var hosts = {};
  Object.keys(got).forEach(function(id){ (hosts[got[id].host] = hosts[got[id].host] || []).push(id); });
  Object.keys(hosts).forEach(function(hk){ var ids = hosts[hk];
    for (var i = 0; i < ids.length; i++) for (var j = i + 1; j < ids.length; j++) {
      var p = got[ids[i]], q = got[ids[j]], dist = Math.hypot(p.cx - q.cx, p.cy - q.cy);
      if (dist < 2) errs.push(ids[i] + ' and ' + ids[j] + ' sit on one point (' + dist.toFixed(1) + ' px apart) on ' + hk); } });
  var out1 = buildBpmnXml(state); state = parseBpmnXml(out1); refreshDisplayIds();
  if (buildBpmnXml(state) !== out1) errs.push('second save differs');
  return { errs: errs, events: Object.keys(file).length };
})`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1344-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1344-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1344-udd-');
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
      rows.push({ f, r: await ev(cmd, `${CHECK}(${JSON.stringify(xml)}).catch(function(e){ return { errs: ['exception: ' + e] }; })`) });
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
  console.log(`T-1344: ${bad ? 'RED' : 'GREEN'} — ${FIXTURES.length} fixtures, ${n} boundary events checked`);
  process.exitCode = bad ? 1 : 0;
}
main();
