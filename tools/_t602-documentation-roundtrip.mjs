#!/usr/bin/env node
// _t602-documentation-roundtrip.mjs — does <bpmn:documentation> on a flow node survive
// open -> save, with its CONTENT intact?
//
// WHY NOT JUST REUSE _t347's CENSUS. That instrument COUNTS documentation elements.
// A count is satisfied by emitting empty <bpmn:documentation/> elements in the right
// number — which is exactly the failure mode this task could plausibly ship, since the
// field report that opened it (001-CashWeb, agent-chat-arc 531) was about eight elements
// whose VALUE was the per-node vendor API binding, auth shape and policy. The count was
// never the asset. So every leg here asserts content, not cardinality.
//
// Legs:
//   L1  documentation text survives byte-for-byte, including markup-ish characters
//   L2  the id attribute survives
//   L3  the textFormat attribute survives
//   L4  two documentation elements on one node survive in ORDER
//   L5  documentation is emitted BEFORE extensionElements (BPMN XSD tBaseElement order)
//   L6  a node with no documentation emits none — no byte drift for the existing corpus
//
// --self-test loads a copy with the emit block removed and requires L1-L5 to FAIL.
//
// Usage:  node tools/_t602-documentation-roundtrip.mjs [--self-test]
// Exit:   0 pass · 1 leg failed · 2 driver/integrity error
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve } from 'node:path';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const EDITOR = join(resolve(HERE, '..'), 'src', 'aef-workflow-designer.html');
const BPMN_NS = 'http://www.omg.org/spec/BPMN/20100524/MODEL';
const DOC_A = 'GET /get/index/{index} — CASH-API.V4.0 <read> & auth: Bearer';
const DOC_B = 'PD-003: never auto-create a product from an ERP feed';

const INPUT = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="${BPMN_NS}" id="Defs_t602" targetNamespace="http://t602">
  <bpmn:process id="Proc_t602" isExecutable="false">
    <bpmn:serviceTask id="Task_documented" name="Read stock from Cash">
      <bpmn:documentation id="Doc_1" textFormat="text/plain">${DOC_A.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</bpmn:documentation>
      <bpmn:documentation id="Doc_2">${DOC_B}</bpmn:documentation>
    </bpmn:serviceTask>
    <bpmn:serviceTask id="Task_bare" name="Write to Ecwid"/>
    <bpmn:sequenceFlow id="Flow_1" sourceRef="Task_documented" targetRef="Task_bare"/>
  </bpmn:process>
</bpmn:definitions>`;

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright');
  const cands = [];
  if (existsSync(cache)) for (const d of readdirSync(cache))
    if (d.startsWith('chromium-')) cands.push(join(cache, d, 'chrome-linux64', 'chrome'));
  cands.sort().reverse();
  for (const c of cands) if (existsSync(c)) return c;
  throw new Error('No Chromium under ' + cache);
}
const sleep = ms => new Promise(r => setTimeout(r, ms));
function cdpClient(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0; const pending = new Map();
  ws.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } });
  const ready = new Promise((res, rej) => { ws.addEventListener('open', res); ws.addEventListener('error', () => rej(new Error('CDP ws error'))); });
  const cmd = (method, params = {}) => new Promise((res, rej) => {
    const mid = ++id;
    pending.set(mid, m => m.error ? rej(new Error(method + ': ' + JSON.stringify(m.error))) : res(m.result));
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  return { ready, cmd, close: () => ws.close() };
}

const PROBE = `(function(){ try{
  adoptImportedXml(${JSON.stringify(INPUT)}, {userImport:true});
  var out = buildBpmnXml(state);
  var d = new DOMParser().parseFromString(out, 'text/xml');
  var NS = ${JSON.stringify(BPMN_NS)};
  var byName = {};
  var tasks = d.getElementsByTagNameNS(NS, 'serviceTask');
  for (var i=0;i<tasks.length;i++){
    var t = tasks[i];
    var docs = [], order = [];
    for (var c = t.firstElementChild; c; c = c.nextElementSibling) {
      if (c.namespaceURI === NS && c.localName === 'documentation')
        docs.push({text: c.textContent, id: c.getAttribute('id'), fmt: c.getAttribute('textFormat')});
      order.push(c.localName);
    }
    byName[t.getAttribute('name')] = {docs: docs, order: order};
  }
  return {ok:true, tasks: byName, xml: out.length};
}catch(e){ return {ok:false, error:String(e && e.stack || e)}; } })()`;

async function probe(editorPath) {
  const udd = mkdtempSync(join(tmpdir(), 't602-chrome-'));
  const proc = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let client;
  try {
    let port;
    for (let i = 0; i < 250; i++) {
      const f = join(udd, 'DevToolsActivePort');
      if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n')[0]; if (t.trim()) { port = +t.trim(); break; } }
      await sleep(100);
    }
    if (!port) throw new Error('Chromium DevTools port timeout');
    const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    client = cdpClient(targets.find(t => t.type === 'page').webSocketDebuggerUrl);
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: 'file://' + editorPath });
    const t0 = Date.now();
    for (;;) {
      const r = await cmd('Runtime.evaluate', { expression: `(typeof adoptImportedXml==='function' && typeof buildBpmnXml==='function' && !!state)`, returnByValue: true });
      if (r.result.value) break;
      if (Date.now() - t0 > 25000) throw new Error('editor load timeout');
      await sleep(150);
    }
    await cmd('Runtime.evaluate', { expression: `(window.alert=window.confirm=window.prompt=function(){return true;},true)`, returnByValue: true });
    const r = await cmd('Runtime.evaluate', { expression: PROBE, returnByValue: true, awaitPromise: true });
    if (r.exceptionDetails) throw new Error('probe threw: ' + JSON.stringify(r.exceptionDetails).slice(0, 300));
    return r.result.value;
  } finally {
    try { client && client.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}

function legs(res) {
  if (!res || !res.ok) return [{ id: 'probe', ok: false, detail: (res && res.error) || 'probe returned nothing' }];
  const doc = res.tasks['Read stock from Cash'];
  const bare = res.tasks['Write to Ecwid'];
  if (!doc || !bare) return [{ id: 'probe', ok: false, detail: 'expected task not found in output: ' + Object.keys(res.tasks).join('|') }];
  const d0 = doc.docs[0] || {}, d1 = doc.docs[1] || {};
  const iDoc = doc.order.indexOf('documentation'), iExt = doc.order.indexOf('extensionElements');
  return [
    { id: 'L1', ok: d0.text === DOC_A, detail: `text ${JSON.stringify((d0.text || '').slice(0, 48))} vs expected ${JSON.stringify(DOC_A.slice(0, 48))}` },
    { id: 'L2', ok: d0.id === 'Doc_1', detail: `id ${JSON.stringify(d0.id)}` },
    { id: 'L3', ok: d0.fmt === 'text/plain', detail: `textFormat ${JSON.stringify(d0.fmt)}` },
    { id: 'L4', ok: doc.docs.length === 2 && d1.text === DOC_B, detail: `${doc.docs.length} element(s), second ${JSON.stringify((d1.text || '').slice(0, 40))}` },
    { id: 'L5', ok: iDoc === 0 && (iExt === -1 || iDoc < iExt), detail: `child order [${doc.order.join(', ')}]` },
    { id: 'L6', ok: bare.docs.length === 0, detail: `bare task carries ${bare.docs.length} documentation element(s)` },
  ];
}

async function main() {
  const selfTest = process.argv.includes('--self-test');
  const report = ls => { for (const l of ls) console.log(`  ${l.ok ? 'PASS' : 'FAIL'}  ${l.id}  ${l.detail}`); };
  console.log('T-602 bpmn:documentation round-trip — content legs');
  const live = legs(await probe(EDITOR));
  report(live);
  const failed = live.filter(l => !l.ok);
  if (!selfTest) {
    console.log(failed.length ? `FAIL — ${failed.length} leg(s)` : `PASS — ${live.length} leg(s)`);
    process.exit(failed.length ? 1 : 0);
  }
  const src = readFileSync(EDITOR, 'utf8');
  const EMIT = 'for (const d of (n.documentation || [])) {';
  if (!src.includes(EMIT)) { console.log('SELF-TEST INTEGRITY FAIL — emit block not found'); process.exit(2); }
  const f = join(mkdtempSync(join(tmpdir(), 't602-poison-')), 'poisoned-editor.html');
  writeFileSync(f, src.replace(EMIT, 'for (const d of []) {'));
  console.log('\npoison arm — emit block disabled; L1-L5 must FAIL');
  const pl = legs(await probe(f));
  report(pl);
  const mustFail = ['L1', 'L2', 'L3', 'L4', 'L5'];
  const survivors = pl.filter(l => mustFail.includes(l.id) && l.ok).map(l => l.id);
  const control = pl.filter(l => l.id === 'L6' && !l.ok).map(l => l.id);
  if (failed.length) { console.log(`\nFAIL — ${failed.length} live leg(s)`); process.exit(1); }
  if (survivors.length) { console.log(`\nSELF-TEST FAIL — ${survivors.join(',')} passed with the emit disabled; they assert nothing`); process.exit(2); }
  if (control.length) { console.log(`\nSELF-TEST FAIL — control leg L6 broke under poison; it is not independent`); process.exit(2); }
  console.log(`\nPASS — ${live.length} live leg(s); ${mustFail.length} proven failable`);
}
main().catch(e => { console.error('DRIVER ERROR: ' + (e && e.stack || e)); process.exit(2); });
