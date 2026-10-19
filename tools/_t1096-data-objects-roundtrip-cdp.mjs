#!/usr/bin/env node
// _t1096-data-objects-roundtrip-cdp.mjs — T-1096: process-level DATA survives a save. Imports
// tests/fixtures/aef-bpmn/t1096-data-objects.bpmn (a data object passed between two tasks, a data store written to) into
// the REAL editor, exports, and checks the exported document, element by element:
//   dataObject, dataObjectReference (with dataObjectRef), dataStoreReference, the dataOutputAssociation /
//   dataInputAssociation on the tasks (+ the property an input association targets), and their DI shapes/edges;
//   every *Ref in the export resolves to an id present in it (nothing dangling).
//   node tools/_t1096-data-objects-roundtrip-cdp.mjs [--designer PATH]
// Exit 0 = pass; 1 = something was dropped or dangles; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIX = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 't1096-data-objects.bpmn');
const argv = process.argv.slice(2);
const DESIGNER = (argv.indexOf('--designer') >= 0 && argv[argv.indexOf('--designer') + 1]) || join(REPO, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// What the export must still carry: [label, CSS-ish test run in the page on the exported DOM].
const CHECKS = [
  ['dataObject', `!!byId('DataObject_quote') && byId('DataObject_quote').localName === 'dataObject'`],
  ['dataObjectReference (dataObjectRef kept)', `!!byId('DOR_quote') && byId('DOR_quote').getAttribute('dataObjectRef') === 'DataObject_quote' && byId('DOR_quote').getAttribute('name') === 'Quote'`],
  ['dataStoreReference', `!!byId('DSR_crm') && byId('DSR_crm').getAttribute('name') === 'CRM'`],
  ['dataOutputAssociation on "Draft quote" -> Quote', `inTask('Draft quote', 'dataOutputAssociation', 'DOR_quote')`],
  ['dataInputAssociation on "Send quote" <- Quote (+ its property)', `inTask('Send quote', 'dataInputAssociation', 'DOR_quote') && !!byId('Prop_send')`],
  ['dataOutputAssociation on "Send quote" -> CRM', `inTask('Send quote', 'dataOutputAssociation', 'DSR_crm')`],
  ['DI shapes for the data object and store', `!!diFor('DOR_quote') && !!diFor('DSR_crm')`],
  ['DI edges for the three associations', `!!diFor('DOA_draft') && !!diFor('DIA_send') && !!diFor('DOA_crm')`],
  ['every reference resolves (nothing dangling)', `dangling().length === 0`],
];

async function main() {
  if (!existsSync(DESIGNER) || !existsSync(FIX)) { console.log(JSON.stringify({ ok: false, error: 'missing designer or fixture' })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1096-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1096-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1096-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  try {
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) break; } catch (_) {} await sleep(100); }
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; };' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(300);
    const xml = readFileSync(FIX, 'utf8');
    await ev(cmd, `(function(){ adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); renderAll(); return true; })()`); await sleep(200);
    const res = await ev(cmd, `(function(){
      var out = buildBpmnXml(state); window.__t1096 = out;
      var d = new DOMParser().parseFromString(out, 'application/xml');
      function byId(id){ return Array.prototype.find.call(d.getElementsByTagName('*'), function(e){ return e.getAttribute('id') === id; }) || null; }
      function task(name){ return Array.prototype.find.call(d.getElementsByTagName('*'), function(e){ return /^(task|userTask|serviceTask|scriptTask)$/.test(e.localName) && e.getAttribute('name') === name; }) || null; }
      function inTask(name, assoc, ref){ var t = task(name); if (!t) return false; return Array.prototype.some.call(t.children, function(c){ return c.localName === assoc && Array.prototype.some.call(c.children, function(r){ return (r.localName === 'targetRef' || r.localName === 'sourceRef') && r.textContent.trim() === ref; }); }); }
      function diFor(id){ return Array.prototype.find.call(d.getElementsByTagName('*'), function(e){ return (e.localName === 'BPMNShape' || e.localName === 'BPMNEdge') && e.getAttribute('bpmnElement') === id; }) || null; }
      function dangling(){ var ids = new Set(Array.prototype.map.call(d.getElementsByTagName('*'), function(e){ return e.getAttribute('id'); }).filter(Boolean)); var bad = [];
        Array.prototype.forEach.call(d.getElementsByTagName('*'), function(e){
          ['dataObjectRef', 'bpmnElement', 'sourceRef', 'targetRef', 'processRef'].forEach(function(a){ var v = e.getAttribute(a); if (v && !ids.has(v)) bad.push(e.localName + '@' + a + '=' + v); });
          if ((e.localName === 'sourceRef' || e.localName === 'targetRef') && e.children.length === 0) { var v = e.textContent.trim(); if (v && !ids.has(v)) bad.push(e.parentNode.localName + '/' + e.localName + '=' + v); } });
        return bad; }
      var checks = ${JSON.stringify(CHECKS)};
      return { parseError: !!d.getElementsByTagName('parsererror').length, results: checks.map(function(c){ var ok = false; try { ok = !!eval(c[1]); } catch (e) { ok = false; } return [c[0], ok]; }), dangling: dangling() }; })()`);
    leg(!res.parseError, 'export parses', res);
    // the import notice says the data is kept but not drawn
    const notice = await ev(cmd, `(function(){ var m = Array.prototype.slice.call(document.querySelectorAll('*')).find(function(e){ return e.children.length === 0 && /data object\\/store element/.test(e.textContent || ''); }); return m ? m.textContent : null; })()`);
    leg(notice && /3 data object\/store elements and 3 data associations kept unchanged and saved back, not shown yet/.test(notice), 'import notice: data kept and saved back, not shown yet', notice);
    for (const [name, ok] of res.results) leg(ok, name, name.startsWith('every') ? res.dangling : '');

    // a second save of our own export is identical (idempotent)
    // (The whole document cannot be compared: re-importing a map whose id is already open renames it "_v2" —
    // library behaviour, not data. The DATA content is compared instead, element by element.)
    const again = await ev(cmd, `(function(){ var x = window.__t1096; adoptImportedXml(x, { userImport: true }); renderAll(); var y = buildBpmnXml(state);
      var IDS = ['DataObject_quote', 'DOR_quote', 'DSR_crm', 'DOA_draft', 'DIA_send', 'DOA_crm', 'Prop_send'];
      function pick(xml){ var d = new DOMParser().parseFromString(xml, 'application/xml'); var s = new XMLSerializer();
        return Array.prototype.filter.call(d.getElementsByTagName('*'), function(e){ return IDS.indexOf(e.getAttribute('id')) >= 0 || IDS.indexOf(e.getAttribute('bpmnElement')) >= 0; })
          .map(function(e){ return s.serializeToString(e); }).sort().join('\\n'); }
      var a = pick(x), b = pick(y);
      return { same: a === b && a.length > 0, n: a.split('\\n').length }; })()`);
    leg(again.same, 'second save keeps the data content identical (import our export, export again)', again);

    // delete "Send quote": its two associations, its property and their DI edges go; the data object and store
    // stay; nothing dangles
    const del = await ev(cmd, `(function(){ var n = state.nodes.find(function(x){ return x.name === 'Send quote'; }); deleteNode(n.id);
      var out = buildBpmnXml(state); var d = new DOMParser().parseFromString(out, 'application/xml');
      var all = Array.prototype.slice.call(d.getElementsByTagName('*'));
      var ids = new Set(all.map(function(e){ return e.getAttribute('id'); }).filter(Boolean));
      var dangling = []; all.forEach(function(e){ ['bpmnElement', 'dataObjectRef', 'sourceRef', 'targetRef'].forEach(function(a){ var v = e.getAttribute(a); if (v && !ids.has(v)) dangling.push(a + '=' + v); });
        if ((e.localName === 'sourceRef' || e.localName === 'targetRef') && !e.children.length && !ids.has(e.textContent.trim())) dangling.push(e.localName + '=' + e.textContent.trim()); });
      return { gone: !ids.has('DIA_send') && !ids.has('DOA_crm') && !ids.has('Prop_send'), kept: ids.has('DOR_quote') && ids.has('DSR_crm') && ids.has('DOA_draft'), dangling: dangling }; })()`);
    leg(del.gone && del.kept && del.dangling.length === 0, 'delete a task: its associations and their DI go, data objects stay, nothing dangles', del);
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  const ok = legs.length > 0 && legs.every(l => l.ok);
  for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'} ${l.name}${l.ok ? '' : '  ' + JSON.stringify(l.detail).slice(0, 400)}`);
  console.log(`T-1096: ${legs.filter(l => l.ok).length}/${legs.length}`);
  process.exitCode = ok ? 0 : 1;
}
main();
