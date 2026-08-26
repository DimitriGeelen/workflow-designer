#!/usr/bin/env node
// _t603-multiprocess-import.mjs — does a document with more than one <bpmn:process>
// lose its content on open, and is the loss REPORTED?
//
// THE DEFECT. parseBpmnXml took processes[0] unconditionally. A file whose first process
// is a stub loses everything: bizagi-nested-ns imported ZERO nodes and saved an empty
// process back over a full diagram. Nothing counted DOWN from any baseline the corpus
// holds, so no instrument in this repository ever reported it — the one census that
// touched the file attributed the total loss to "documentation", the only shape it counts.
//
// WHY TWO KINDS OF LEG. Choosing a better process is a heuristic; a document with real
// content in two processes still loses one. So selecting well is only half the fix, and
// the half that can go quiet again. The reporting legs are the other half, and they are
// what makes the residual loss survivable.
//
// Legs:
//   L1  the content-bearing process is the one imported (bizagi: nodes > 0)
//   L2  its flow content is complete (3 nodes — the second process's full membership)
//   L3  the skipped process is REPORTED, not dropped in silence
//   L4  the report names the skipped element's id, so the operator can go look
//   L5  a single-process document reports nothing (no false alarm on the whole corpus)
//   L6  ties keep the earliest process — a document whose first process is richest
//       behaves exactly as before, so the corpus moves no bytes
//
// --self-test restores processes[0] and requires L1-L4 to FAIL.
//
// Usage:  node tools/_t603-multiprocess-import.mjs [--self-test]
// Exit:   0 pass · 1 leg failed · 2 driver/integrity error
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = join(ROOT, 'src', 'aef-workflow-designer.html');
const BIZAGI = join(ROOT, 'tests', 'fixtures', 'third-party', 'bizagi-nested-ns.bpmn');
const SIMPLE = join(ROOT, 'tests', 'fixtures', 'third-party', 'simple.bpmn');
const NS = 'http://www.omg.org/spec/BPMN/20100524/MODEL';
const SKIPPED_ID = 'Id_f2afc6ec-e5fc-4205-837c-4f637bf95ba6';   // bizagi's stub process

// Two processes, the RICHEST FIRST — the ordering control for L6.
const FIRST_RICHEST = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="${NS}" id="Defs_t603" targetNamespace="http://t603">
  <bpmn:process id="Proc_rich" isExecutable="false">
    <bpmn:serviceTask id="A" name="Alpha"/>
    <bpmn:serviceTask id="B" name="Beta"/>
    <bpmn:sequenceFlow id="F1" sourceRef="A" targetRef="B"/>
  </bpmn:process>
  <bpmn:process id="Proc_thin"><bpmn:serviceTask id="C" name="Gamma"/></bpmn:process>
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
const importExpr = text => `(function(){ try{
  adoptImportedXml(${JSON.stringify(text)}, {userImport:true});
  maybeShowLaneFixNotice();
  var msg = document.getElementById('lane-fix-msg');
  var banner = document.getElementById('lane-fix-notice');
  return {ok:true, nodes: state.nodes.length,
          names: state.nodes.map(function(n){return n.name;}),
          notice: (banner && banner.style.display !== 'none' && msg) ? msg.textContent : '',
          skipped: (typeof _processSkipReport !== 'undefined') ? _processSkipReport : null};
}catch(e){ return {ok:false, error:String(e && e.stack || e)}; } })()`;

async function probe(editorPath) {
  const udd = mkdtempSync(join(tmpdir(), 't603-chrome-'));
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
    client = cdpClient(await pageWsUrl(port));
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: 'file://' + editorPath });
    const t0 = Date.now();
    for (;;) {
      const r = await cmd('Runtime.evaluate', { expression: `(typeof adoptImportedXml==='function' && !!state)`, returnByValue: true });
      if (r.result.value) break;
      if (Date.now() - t0 > 25000) throw new Error('editor load timeout');
      await sleep(150);
    }
    await cmd('Runtime.evaluate', { expression: `(window.alert=window.confirm=window.prompt=function(){return true;},true)`, returnByValue: true });
    const run = async text => {
      const r = await cmd('Runtime.evaluate', { expression: importExpr(text), returnByValue: true, awaitPromise: true });
      if (r.exceptionDetails) throw new Error('probe threw: ' + JSON.stringify(r.exceptionDetails).slice(0, 300));
      return r.result.value;
    };
    return {
      bizagi: await run(readFileSync(BIZAGI, 'utf8')),
      simple: await run(readFileSync(SIMPLE, 'utf8')),
      firstRichest: await run(FIRST_RICHEST),
    };
  } finally {
    try { client && client.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}

function legs(r) {
  for (const [k, v] of Object.entries(r || {}))
    if (!v || !v.ok) return [{ id: 'probe:' + k, ok: false, detail: (v && v.error) || 'probe returned nothing' }];
  const b = r.bizagi, s = r.simple, f = r.firstRichest;
  const sk = b.skipped || [];
  return [
    { id: 'L1', ok: b.nodes > 0, detail: `bizagi imported ${b.nodes} node(s)` },
    { id: 'L2', ok: b.nodes === 3, detail: `bizagi nodes [${b.names.join(', ')}]` },
    { id: 'L3', ok: sk.length === 1 && /process/i.test(b.notice), detail: `${sk.length} skip record(s), notice ${JSON.stringify(b.notice.slice(0, 70))}` },
    { id: 'L4', ok: b.notice.includes(SKIPPED_ID), detail: `notice names the skipped id: ${b.notice.includes(SKIPPED_ID)}` },
    { id: 'L5', ok: (s.skipped || []).length === 0 && !/process/i.test(s.notice), detail: `simple.bpmn notice ${JSON.stringify(s.notice.slice(0, 50))}` },
    { id: 'L6', ok: f.nodes === 2 && f.names.includes('Alpha'), detail: `first-richest imported [${f.names.join(', ')}]` },
  ];
}

async function main() {
  const selfTest = process.argv.includes('--self-test');
  const report = ls => { for (const l of ls) console.log(`  ${l.ok ? 'PASS' : 'FAIL'}  ${l.id}  ${l.detail}`); };
  console.log('T-603 multi-process import — selection and reporting legs');
  const live = legs(await probe(EDITOR));
  report(live);
  const failed = live.filter(l => !l.ok);
  if (!selfTest) {
    console.log(failed.length ? `FAIL — ${failed.length} leg(s)` : `PASS — ${live.length} leg(s)`);
    process.exit(failed.length ? 1 : 0);
  }
  const src = readFileSync(EDITOR, 'utf8');
  // The poison must be FAITHFUL to pre-T-603, which had no report at all. Neutering
  // only the selection leaves the report in place naming the wrong process, and L3
  // ("a skip was reported") then passes on broken code — it asserted nothing until
  // both halves were removed. Found by this self-test, which is the point of it.
  const PICK = '  const proc = best.pr;';
  const REPORT = '  _processSkipReport = procCounts';
  if (!src.includes(PICK) || !src.includes(REPORT)) { console.log('SELF-TEST INTEGRITY FAIL — a poison target is missing'); process.exit(2); }
  const f = join(mkdtempSync(join(tmpdir(), 't603-poison-')), 'poisoned-editor.html');
  writeFileSync(f, src.replace(PICK, '  const proc = processes[0];')
                     .replace(REPORT, '  _processSkipReport = []; const _t603Poison = procCounts'));
  console.log('\npoison arm — pre-T-603 processes[0] restored; L1-L4 must FAIL');
  const pl = legs(await probe(f));
  report(pl);
  const mustFail = ['L1', 'L2', 'L3', 'L4'];
  const survivors = pl.filter(l => mustFail.includes(l.id) && l.ok).map(l => l.id);
  const control = pl.filter(l => ['L5', 'L6'].includes(l.id) && !l.ok).map(l => l.id);
  if (failed.length) { console.log(`\nFAIL — ${failed.length} live leg(s)`); process.exit(1); }
  if (survivors.length) { console.log(`\nSELF-TEST FAIL — ${survivors.join(',')} passed on processes[0]; they assert nothing`); process.exit(2); }
  if (control.length) { console.log(`\nSELF-TEST FAIL — control leg(s) ${control.join(',')} broke under poison; not independent`); process.exit(2); }
  console.log(`\nPASS — ${live.length} live leg(s); ${mustFail.length} proven failable`);
}
main().catch(e => { console.error('DRIVER ERROR: ' + (e && e.stack || e)); process.exit(2); });
