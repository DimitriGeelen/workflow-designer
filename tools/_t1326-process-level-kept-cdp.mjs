#!/usr/bin/env node
// _t1326-process-level-kept-cdp.mjs — T-1326 (T-1322 GO slice 2): what a save dropped at process, collaboration and
// root level is kept: artifacts (text annotation, association, group) with their DI and the root categories a group
// names; documentation, unread attributes and other tools' extensions on the process, the collaboration, our pool and
// the definitions root; a flow's documentation. Drives the REAL editor runtime (parseBpmnXml -> buildBpmnXml) headless:
//   1. the annotation (with its text), both associations, the group in the collaboration and its category survive, with
//      the annotation's BPMNShape and the association's BPMNEdge;
//   2. an association names its node / flow end by that element's CURRENT id; deleting the node drops the association
//      and its DI edge, and names it in processLevelKeptOut(state).dropped;
//   3. process documentation comes first, before extensionElements; camunda:versionTag on the process and
//      modeler:executionPlatform + typeLanguage on the root keep their namespace; the process, collaboration and
//      participant extensions and documentation survive;
//   4. a flow's documentation is its first child;
//   5. a second save is byte-identical; no corpus map gains a procKept or keptDocs key; every export parses in expat.
// T1326_SRC substitutes another designer file (the BITE: on the pre-T-1326 source, legs 1-4 are red).
// Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn, spawnSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1326_SRC || join(REPO, 'src/aef-workflow-designer.html');
const CORPUS = join(REPO, 'examples/aef-processes/rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const CAMUNDA = 'http://camunda.org/schema/1.0/bpmn', MODELER = 'http://camunda.org/schema/modeler/1.0';
const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" xmlns:di="http://www.omg.org/spec/DD/20100524/DI" xmlns:camunda="${CAMUNDA}" xmlns:modeler="${MODELER}" id="Defs_1" targetNamespace="http://example.com/t1326" typeLanguage="http://www.w3.org/2001/XMLSchema" modeler:executionPlatform="Camunda Platform">
  <bpmn:category id="Cat_1"><bpmn:categoryValue id="CatV_1" value="Billing"/></bpmn:category>
  <bpmn:collaboration id="Collab_1">
    <bpmn:documentation>Collab doc</bpmn:documentation>
    <bpmn:extensionElements><camunda:properties><camunda:property name="c" value="1"/></camunda:properties></bpmn:extensionElements>
    <bpmn:participant id="Pool_1" name="Orders" processRef="Proc_1">
      <bpmn:documentation>Pool doc</bpmn:documentation>
      <bpmn:extensionElements><camunda:properties><camunda:property name="p" value="2"/></camunda:properties></bpmn:extensionElements>
    </bpmn:participant>
    <bpmn:group id="Grp_1" categoryValueRef="CatV_1"/>
  </bpmn:collaboration>
  <bpmn:process id="Proc_1" name="Orders" isExecutable="true" camunda:versionTag="v7">
    <bpmn:documentation>Process doc</bpmn:documentation>
    <bpmn:extensionElements><camunda:executionListener event="start" class="x.Y"/></bpmn:extensionElements>
    <bpmn:startEvent id="S" name="Start"/>
    <bpmn:task id="A" name="Check order"/>
    <bpmn:endEvent id="E" name="End"/>
    <bpmn:sequenceFlow id="F1" name="go" sourceRef="S" targetRef="A"><bpmn:documentation>Flow doc</bpmn:documentation></bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="F2" sourceRef="A" targetRef="E"/>
    <bpmn:textAnnotation id="T1"><bpmn:text>Note: ünïcødé</bpmn:text></bpmn:textAnnotation>
    <bpmn:association id="As1" sourceRef="A" targetRef="T1" associationDirection="None"/>
    <bpmn:association id="As2" sourceRef="F1" targetRef="T1"/>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="D1">
    <bpmndi:BPMNPlane id="P1" bpmnElement="Collab_1">
      <bpmndi:BPMNShape id="T1_di" bpmnElement="T1"><dc:Bounds x="300" y="40" width="100" height="40"/></bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="As1_di" bpmnElement="As1"><di:waypoint x="280" y="120"/><di:waypoint x="320" y="80"/></bpmndi:BPMNEdge>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</bpmn:definitions>`;

const ASSERT = `(function(){
  var errs = [], exports = [];
  var B = 'http://www.omg.org/spec/BPMN/20100524/MODEL', DI = 'http://www.omg.org/spec/BPMN/20100524/DI';
  var C = ${JSON.stringify(CAMUNDA)}, M = ${JSON.stringify(MODELER)};
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function dom(xml, tag){ var d = new DOMParser().parseFromString(xml, 'application/xml');
    var pe = d.getElementsByTagName('parsererror'); if (pe.length) { errs.push(tag + ': not well-formed: ' + pe[0].textContent.slice(0, 160)); return null; } return d; }
  function all(d, ns, local){ return Array.prototype.slice.call(d.getElementsByTagNameNS(ns, local)); }
  function byId(d, local, id){ return all(d, B, local).filter(function(e){ return e.getAttribute('id') === id; })[0]; }
  function named(d, local, name){ return all(d, B, local).filter(function(e){ return e.getAttribute('name') === name; })[0]; }
  function di(d, ref){ return all(d, DI, 'BPMNShape').concat(all(d, DI, 'BPMNEdge')).filter(function(e){ return e.getAttribute('bpmnElement') === ref; })[0]; }
  function first(el){ return el && el.children[0] ? el.children[0].localName : null; }
  try {
    load(window.__MAP__);
    var out1 = strip(buildBpmnXml(state)); exports.push(['leg1', out1]);
    var d = dom(out1, 'leg1');
    if (d) {
      var t1 = byId(d, 'textAnnotation', 'T1');
      if (!t1 || t1.textContent.trim() !== 'Note: ünïcødé') errs.push('leg1: text annotation lost or its text changed');
      if (!di(d, 'T1')) errs.push('leg1: the annotation lost its BPMNShape');
      if (!di(d, 'As1')) errs.push('leg1: the association lost its BPMNEdge');
      var g = byId(d, 'group', 'Grp_1');
      if (!g || g.parentNode.localName !== 'collaboration') errs.push('leg1: the group is gone or not in the collaboration');
      if (!byId(d, 'categoryValue', 'CatV_1')) errs.push('leg1: the root category the group names is gone');
      var a = named(d, 'task', 'Check order'), f1 = named(d, 'sequenceFlow', 'go');
      var as1 = byId(d, 'association', 'As1'), as2 = byId(d, 'association', 'As2');
      if (!as1 || !a || as1.getAttribute('sourceRef') !== a.getAttribute('id')) errs.push('leg2: As1 sourceRef ' + (as1 && as1.getAttribute('sourceRef')) + ' is not the task id ' + (a && a.getAttribute('id')));
      if (a && a.getAttribute('id') === 'A') errs.push('leg2: cannot bite, the task kept its source id');
      if (!as2 || !f1 || as2.getAttribute('sourceRef') !== f1.getAttribute('id')) errs.push('leg2: As2 sourceRef ' + (as2 && as2.getAttribute('sourceRef')) + ' is not the flow id ' + (f1 && f1.getAttribute('id')));
      if (as1 && as1.getAttribute('targetRef') !== 'T1') errs.push('leg2: an annotation end changed: ' + as1.getAttribute('targetRef'));
      if (as1 && as1.getAttribute('associationDirection') !== 'None') errs.push('leg2: associationDirection lost');
      var p = all(d, B, 'process')[0];
      if (first(p) !== 'documentation' || p.children[0].textContent !== 'Process doc') errs.push('leg3: process documentation not first (' + first(p) + ')');
      if (!p || p.getAttributeNS(C, 'versionTag') !== 'v7') errs.push('leg3: camunda:versionTag lost on the process');
      if (!p || !p.getElementsByTagNameNS(C, 'executionListener').length) errs.push('leg3: the process extension lost');
      var root = d.documentElement;
      if (root.getAttributeNS(M, 'executionPlatform') !== 'Camunda Platform') errs.push('leg3: modeler:executionPlatform lost on the root');
      if (root.getAttribute('typeLanguage') !== 'http://www.w3.org/2001/XMLSchema') errs.push('leg3: typeLanguage lost on the root');
      var co = all(d, B, 'collaboration')[0], pa = all(d, B, 'participant')[0];
      if (first(co) !== 'documentation' || co.children[0].textContent !== 'Collab doc') errs.push('leg3: collaboration documentation lost or not first');
      if (!co || !Array.prototype.some.call(co.getElementsByTagNameNS(C, 'property'), function(x){ return x.getAttribute('name') === 'c'; })) errs.push('leg3: collaboration extension lost');
      if (first(pa) !== 'documentation' || pa.children[0].textContent !== 'Pool doc') errs.push('leg3: participant documentation lost or not first');
      if (!pa || !Array.prototype.some.call(pa.getElementsByTagNameNS(C, 'property'), function(x){ return x.getAttribute('name') === 'p'; })) errs.push('leg3: participant extension lost');
      if (first(f1) !== 'documentation' || f1.children[0].textContent !== 'Flow doc') errs.push('leg4: flow documentation lost or not first (' + first(f1) + ')');
    }
    load(out1);
    if (strip(buildBpmnXml(state)) !== out1) errs.push('leg5: second save differs from the first');
    load(window.__MAP__);
    var task = state.nodes.filter(function(n){ return n.name === 'Check order'; })[0];
    state.nodes = state.nodes.filter(function(n){ return n !== task; });
    state.edges = state.edges.filter(function(e){ return e.source !== task.id && e.target !== task.id; });
    var out2 = strip(buildBpmnXml(state)); exports.push(['leg2-deleted', out2]);
    var d2 = dom(out2, 'leg2');
    if (d2 && byId(d2, 'association', 'As1')) errs.push('leg2: an association to a deleted task is still written');
    if (d2 && di(d2, 'As1')) errs.push('leg2: the deleted association kept its DI edge');
    if (d2 && !byId(d2, 'textAnnotation', 'T1')) errs.push('leg2: the annotation went with the task');
    var dr = (typeof processLevelKeptOut === 'function') ? processLevelKeptOut(state).dropped : [];
    if (dr.indexOf('As1') < 0) errs.push('leg2: the dropped association is not named for the notice (' + JSON.stringify(dr) + ')');
    var grew = [];
    (window.__CORPUS__ || []).forEach(function(c){
      load(c[1]);
      if ('procKept' in state || state.edges.some(function(e){ return 'keptDocs' in e; })) grew.push(c[0]);
    });
    if (!(window.__CORPUS__ || []).length) errs.push('leg5: no corpus maps loaded');
    if (grew.length) errs.push('leg5: designer-written maps grew a key: ' + grew.join(', '));
    return { ok: errs.length === 0, errs: errs, exports: exports, corpus: (window.__CORPUS__ || []).length };
  } catch (err) { return { ok: false, errs: ['exception: ' + (err && err.message || err)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort().map(f => [f, readFileSync(join(CORPUS, f), 'utf8')]);
  const doc = mkdtempSync(join(tmpdir(), 't1326-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1326-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1326-udd-');
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
    for (const [tag, x] of (r && r.exports) || []) {
      const p = spawnSync('python3', ['-I', '-c', 'import sys, xml.etree.ElementTree as E; E.fromstring(sys.stdin.buffer.read())'], { input: x });
      if (p.status !== 0) { r.ok = false; r.errs.push(`${tag} (expat): ${String(p.stderr).trim().split('\n').pop()}`); }
    }
    if (r) delete r.exports;
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
