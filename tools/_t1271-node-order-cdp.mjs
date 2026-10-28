#!/usr/bin/env node
// _t1271-node-order-cdp.mjs — T-1271 (job C F13): a save keeps the nodes in the order the file declares them. Before,
// import collected nodes one tag at a time, so the first save of a third-party file regrouped them by kind (start and
// end events first, then tasks, then gateways) in the process and in each lane's flowNodeRef list. Drives the REAL
// editor runtime (parseBpmnXml -> buildBpmnXml) headless and asserts:
//   1. a third-party map declaring start, task, gateway, task, end (with one foreign tag) saves its flow nodes in that
//      order, and its lane's flowNodeRefs in that order;
//   2. a second save is byte-identical;
//   3. every designer-written corpus map saves its flow nodes in the order its file declares them.
// T1271_SRC substitutes another designer file (the BITE: run against the pre-T-1271 source, leg 1 is red; leg 3 is
// green there too, since a designer-written file is already in the grouped order, and it guards that it stays so).
// Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1271_SRC || join(REPO, 'src/aef-workflow-designer.html');
const CORPUS = join(REPO, 'examples/aef-processes/rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// Declared order: start, task, gateway, foreign task, task, end. Grouping by kind would put the end event second.
const ORDER = ['Start', 'Check', 'OK?', 'Archive', 'Approve', 'Done'];
const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" id="Defs_1" targetNamespace="http://example.com/t1271">
  <bpmn:process id="Proc_1" isExecutable="false">
    <bpmn:laneSet id="LS"><bpmn:lane id="L1" name="Team">
      <bpmn:flowNodeRef>S</bpmn:flowNodeRef><bpmn:flowNodeRef>C</bpmn:flowNodeRef><bpmn:flowNodeRef>G</bpmn:flowNodeRef>
      <bpmn:flowNodeRef>AR</bpmn:flowNodeRef><bpmn:flowNodeRef>A</bpmn:flowNodeRef><bpmn:flowNodeRef>E</bpmn:flowNodeRef>
    </bpmn:lane></bpmn:laneSet>
    <bpmn:startEvent id="S" name="Start"/>
    <bpmn:serviceTask id="C" name="Check"/>
    <bpmn:exclusiveGateway id="G" name="OK?"/>
    <bpmn:task id="AR" name="Archive"/>
    <bpmn:userTask id="A" name="Approve"/>
    <bpmn:endEvent id="E" name="Done"/>
    <bpmn:sequenceFlow id="F1" sourceRef="S" targetRef="C"/>
    <bpmn:sequenceFlow id="F2" sourceRef="C" targetRef="G"/>
    <bpmn:sequenceFlow id="F3" sourceRef="G" targetRef="AR"/>
    <bpmn:sequenceFlow id="F4" sourceRef="G" targetRef="A"/>
    <bpmn:sequenceFlow id="F5" sourceRef="A" targetRef="E"/>
  </bpmn:process>
</bpmn:definitions>`;

const ASSERT = `(function(){
  var errs = [], B = 'http://www.omg.org/spec/BPMN/20100524/MODEL';
  var SKIP = { laneSet:1, sequenceFlow:1, documentation:1, extensionElements:1, textAnnotation:1, association:1, group:1,
    dataObject:1, dataObjectReference:1, dataStoreReference:1 };
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function proc(xml){ var d = new DOMParser().parseFromString(xml, 'application/xml'); return d.getElementsByTagNameNS(B, 'process')[0]; }
  // flow nodes in declared order: the process's direct BPMN children that are not lanes, flows or artifacts
  function nodeIds(p){ return p ? Array.prototype.filter.call(p.children, function(c){ return c.namespaceURI === B && !SKIP[c.localName]; })
    .map(function(c){ return c.getAttribute('id'); }) : []; }
  function namesOf(p, ids){ var by = {}; Array.prototype.forEach.call(p.children, function(c){ by[c.getAttribute('id')] = c.getAttribute('name'); });
    return ids.map(function(i){ return by[i]; }); }
  try {
    load(window.__MAP__);
    var out1 = strip(buildBpmnXml(state)), p1 = proc(out1);
    var got = namesOf(p1, nodeIds(p1)), want = ${JSON.stringify(ORDER)};
    if (got.join('|') !== want.join('|')) errs.push('leg1: flow nodes saved as ' + got.join(', ') + ' (declared ' + want.join(', ') + ')');
    var refs = Array.prototype.map.call(p1.getElementsByTagNameNS(B, 'flowNodeRef'), function(r){ return r.textContent.trim(); });
    if (namesOf(p1, refs).join('|') !== want.join('|')) errs.push('leg1: flowNodeRefs saved as ' + namesOf(p1, refs).join(', '));
    load(out1);
    if (strip(buildBpmnXml(state)) !== out1) errs.push('leg2: second save differs from the first');
    var moved = [];
    (window.__CORPUS__ || []).forEach(function(c){
      var pin = proc(c[1]); load(c[1]);
      var pout = proc(strip(buildBpmnXml(state)));
      if (nodeIds(pin).join('|') !== nodeIds(pout).join('|')) moved.push(c[0]);
    });
    if (!(window.__CORPUS__ || []).length) errs.push('leg3: no corpus maps loaded');
    if (moved.length) errs.push('leg3: designer-written maps saved their nodes in another order: ' + moved.join(', '));
    return { ok: errs.length === 0, errs: errs, corpus: (window.__CORPUS__ || []).length };
  } catch (err) { return { ok: false, errs: ['exception: ' + (err && err.message || err)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort().map(f => [f, readFileSync(join(CORPUS, f), 'utf8')]);
  const doc = mkdtempSync(join(tmpdir(), 't1271-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1271-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1271-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__MAP__ = ${JSON.stringify(MAP)}; window.__CORPUS__ = ${JSON.stringify(corpus)};`);
    const r = await ev(cmd, ASSERT);
    console.log(JSON.stringify({ ok: !!(r && r.ok), src: SRC, result: r }, null, 2));
    process.exitCode = r && r.ok ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e) }, null, 2));
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
