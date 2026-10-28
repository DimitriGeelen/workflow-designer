#!/usr/bin/env node
// _t1325-element-passthrough-cdp.mjs — T-1325 (T-1322 GO slice 1; T-347 ruling (a)): a flow node or sequence flow keeps
// the attributes and children the designer does not read, and a save writes them back in place. Before, one unedited
// save of a third-party file dropped them (T-1322 §2: 383 items over 7 of 11 fixtures). Drives the REAL editor runtime
// (parseBpmnXml -> buildBpmnXml) headless and asserts:
//   1. unread attributes survive, standard (scriptFormat, isImmediate) and foreign (camunda:assignee, whose prefix only
//      the SOURCE root declares): the export is well-formed and the attribute keeps its namespace;
//   2. unread children survive (multiInstanceLoopCharacteristics + loopCardinality after the outgoing refs, a script's
//      text), and other tools' extensions stay inside extensionElements (camunda:formData on a task, camunda:properties
//      on a flow);
//   3. a gateway's default flow is written as that flow's CURRENT id, and is dropped once the flow is deleted;
//   4. a retype (userTask to serviceTask) drops the old tag's attributes and children, and keeps the extensions;
//   5. a second save is byte-identical; a map the designer wrote gains no `kept` key (every corpus map checked);
//   6. every export parses in Python's expat too (an unbound prefix is an error there).
// T1325_SRC substitutes another designer file (the BITE: run against the pre-T-1325 source, legs 1-3 are red).
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
const SRC = process.env.T1325_SRC || join(REPO, 'src/aef-workflow-designer.html');
const CORPUS = join(REPO, 'examples/aef-processes/rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const CAMUNDA = 'http://camunda.org/schema/1.0/bpmn';
const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:camunda="${CAMUNDA}" id="Defs_1" targetNamespace="http://example.com/t1325">
  <bpmn:process id="Proc_1" name="T-1325" isExecutable="true">
    <bpmn:startEvent id="S" name="Start"/>
    <bpmn:userTask id="U" name="Approve" camunda:assignee="\${initiator}">
      <bpmn:extensionElements>
        <camunda:formData><camunda:formField id="ok" type="boolean"/></camunda:formData>
      </bpmn:extensionElements>
      <bpmn:multiInstanceLoopCharacteristics isSequential="true"><bpmn:loopCardinality>3</bpmn:loopCardinality></bpmn:multiInstanceLoopCharacteristics>
    </bpmn:userTask>
    <bpmn:scriptTask id="SC" name="Compute" scriptFormat="groovy"><bpmn:script>x = 1 &lt; 2</bpmn:script></bpmn:scriptTask>
    <bpmn:exclusiveGateway id="G" name="OK?" default="F3"/>
    <bpmn:endEvent id="E1" name="Done"/>
    <bpmn:endEvent id="E2" name="Rejected"/>
    <bpmn:sequenceFlow id="F0" sourceRef="S" targetRef="U"/>
    <bpmn:sequenceFlow id="F1" sourceRef="U" targetRef="SC"/>
    <bpmn:sequenceFlow id="F2" sourceRef="SC" targetRef="G"/>
    <bpmn:sequenceFlow id="F3" name="yes" sourceRef="G" targetRef="E1"/>
    <bpmn:sequenceFlow id="F4" name="no" sourceRef="G" targetRef="E2" isImmediate="true">
      <bpmn:extensionElements><camunda:properties><camunda:property name="p" value="v"/></camunda:properties></bpmn:extensionElements>
      <bpmn:conditionExpression xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="bpmn:tFormalExpression">\${!ok}</bpmn:conditionExpression>
    </bpmn:sequenceFlow>
  </bpmn:process>
</bpmn:definitions>`;

const ASSERT = `(function(){
  var errs = [], exports = [];
  var B = 'http://www.omg.org/spec/BPMN/20100524/MODEL', C = ${JSON.stringify(CAMUNDA)};
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function dom(xml, tag){ var d = new DOMParser().parseFromString(xml, 'application/xml');
    var pe = d.getElementsByTagName('parsererror'); if (pe.length) { errs.push(tag + ': not well-formed: ' + pe[0].textContent.slice(0, 160)); return null; } return d; }
  function byName(d, local, name){ return Array.prototype.filter.call(d.getElementsByTagNameNS(B, local), function(e){ return e.getAttribute('name') === name; })[0]; }
  function kids(el){ return el ? Array.prototype.map.call(el.children, function(c){ return c.localName; }) : []; }
  function node(name){ return state.nodes.filter(function(n){ return n.name === name; })[0]; }
  try {
    load(window.__MAP__);
    var out1 = strip(buildBpmnXml(state)); exports.push(['leg1', out1]);
    var d = dom(out1, 'leg1');
    if (d) {
      var u = byName(d, 'userTask', 'Approve'), sc = byName(d, 'scriptTask', 'Compute'), f4 = byName(d, 'sequenceFlow', 'no');
      if (!u || u.getAttributeNS(C, 'assignee') !== '\${initiator}') errs.push('leg1: camunda:assignee lost or not in its namespace');
      if (!sc || sc.getAttribute('scriptFormat') !== 'groovy') errs.push('leg1: scriptFormat lost');
      if (!f4 || f4.getAttribute('isImmediate') !== 'true') errs.push('leg1: isImmediate on the flow lost');
      var mi = u && Array.prototype.filter.call(u.children, function(c){ return c.localName === 'multiInstanceLoopCharacteristics'; })[0];
      if (!mi || mi.getAttribute('isSequential') !== 'true' || (mi.textContent || '').trim() !== '3') errs.push('leg2: multiInstanceLoopCharacteristics lost (' + kids(u).join(',') + ')');
      var k = kids(u); if (mi && k.lastIndexOf('outgoing') > k.indexOf('multiInstanceLoopCharacteristics')) errs.push('leg2: loop characteristics before the outgoing refs (' + k.join(',') + ')');
      var script = sc && Array.prototype.filter.call(sc.children, function(c){ return c.localName === 'script'; })[0];
      if (!script || script.textContent !== 'x = 1 < 2') errs.push('leg2: script lost or altered: ' + (script && script.textContent));
      var ext = function(el){ return el && Array.prototype.filter.call(el.children, function(c){ return c.localName === 'extensionElements'; })[0]; };
      if (!ext(u) || !ext(u).getElementsByTagNameNS(C, 'formField').length) errs.push('leg2: camunda:formData not inside the task extensionElements');
      if (!ext(f4) || !ext(f4).getElementsByTagNameNS(C, 'property').length) errs.push('leg2: camunda:properties not inside the flow extensionElements');
      var g = byName(d, 'exclusiveGateway', 'OK?'), f3 = byName(d, 'sequenceFlow', 'yes');
      if (!g || !f3 || g.getAttribute('default') !== f3.getAttribute('id')) errs.push('leg3: default is ' + (g && g.getAttribute('default')) + ', the yes flow is ' + (f3 && f3.getAttribute('id')));
      if (f3 && f3.getAttribute('id') === 'F3') errs.push('leg3: the test cannot bite, the flow kept its source id');
    }
    load(out1);
    if (strip(buildBpmnXml(state)) !== out1) errs.push('leg5: second save differs from the first');
    load(window.__MAP__);
    var yes = state.edges.filter(function(e){ return e.name === 'yes'; })[0];
    state.edges = state.edges.filter(function(e){ return e !== yes; });
    var d3 = dom(strip(buildBpmnXml(state)), 'leg3');
    var g3 = d3 && byName(d3, 'exclusiveGateway', 'OK?');
    if (g3 && g3.hasAttribute('default')) errs.push('leg3: default still written after its flow was deleted: ' + g3.getAttribute('default'));
    load(window.__MAP__);
    node('Approve').type = 'serviceTask';
    var out4 = strip(buildBpmnXml(state)); exports.push(['leg4', out4]);
    var d4 = dom(out4, 'leg4'), t4 = d4 && byName(d4, 'serviceTask', 'Approve');
    if (!t4) errs.push('leg4: retyped task not found');
    else {
      if (t4.hasAttributeNS(C, 'assignee')) errs.push('leg4: a retyped task kept the userTask attribute camunda:assignee');
      if (kids(t4).indexOf('multiInstanceLoopCharacteristics') > -1) errs.push('leg4: a retyped task kept the old tag children');
      if (!t4.getElementsByTagNameNS(C, 'formField').length) errs.push('leg4: a retype dropped the extension');
    }
    var grew = [];
    (window.__CORPUS__ || []).forEach(function(c){
      load(c[1]);
      if (state.nodes.some(function(n){ return 'kept' in n; }) || state.edges.some(function(e){ return 'kept' in e; })) grew.push(c[0]);
    });
    if (!(window.__CORPUS__ || []).length) errs.push('leg5: no corpus maps loaded');
    if (grew.length) errs.push('leg5: designer-written maps grew a kept key: ' + grew.join(', '));
    return { ok: errs.length === 0, errs: errs, exports: exports, corpus: (window.__CORPUS__ || []).length };
  } catch (err) { return { ok: false, errs: ['exception: ' + (err && err.message || err)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort().map(f => [f, readFileSync(join(CORPUS, f), 'utf8')]);
  const doc = mkdtempSync(join(tmpdir(), 't1325-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1325-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1325-udd-');
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
