#!/usr/bin/env node
// _t1261-original-id-cdp.mjs — T-1261 (job C F3): the first open of a third-party file records each node's and flow's
// ORIGINAL id, which the save otherwise replaces with the designer's display id (aef:uid is a one-way hash of it).
// Carrier, chosen with AEF and an independent read: <x832:origin originalId="…"/>, attribute-only, in the element's
// extensionElements, namespace urn:832-workflow-designer:origin:1. Drives the REAL editor runtime headless and asserts:
//   1. a task and a flow without aef:uid save with their original ids in that carrier, matched by namespace URI, as an
//      attribute (no text content), and no element of ours there is named `uid` beyond aef:uid;
//   2. a second save is byte-identical, and each element carries exactly one origin after it;
//   3. the first value is never replaced: an element that already carries an origin keeps it on open, and a node whose
//      display id changes (lane renamed) keeps its origin;
//   4. designer-written maps record nothing (no originalId in state, the namespace absent from every export);
//   5. every export parses in Python's expat.
// T1261_SRC substitutes another designer file (the BITE: run against the pre-T-1261 source, legs 1 and 3 are red).
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
const SRC = process.env.T1261_SRC || join(REPO, 'src/aef-workflow-designer.html');
const CORPUS = join(REPO, 'examples/aef-processes/rendered');
const ORIGIN_NS = 'urn:832-workflow-designer:origin:1';
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:o="${ORIGIN_NS}" id="Defs_1" targetNamespace="http://example.com/t1261">
  <bpmn:process id="Proc_1" isExecutable="true">
    <bpmn:laneSet id="LS"><bpmn:lane id="L1" name="Approvers">
      <bpmn:flowNodeRef>Start_1</bpmn:flowNodeRef><bpmn:flowNodeRef>Task_Approve</bpmn:flowNodeRef><bpmn:flowNodeRef>End_1</bpmn:flowNodeRef>
    </bpmn:lane></bpmn:laneSet>
    <bpmn:startEvent id="Start_1" name="Start"/>
    <bpmn:userTask id="Task_Approve" name="Approve"/>
    <bpmn:endEvent id="End_1" name="Done">
      <bpmn:extensionElements><o:origin originalId="Legacy_End"/></bpmn:extensionElements>
    </bpmn:endEvent>
    <bpmn:sequenceFlow id="Flow_1" sourceRef="Start_1" targetRef="Task_Approve"/>
    <bpmn:sequenceFlow id="Flow_2" sourceRef="Task_Approve" targetRef="End_1"/>
  </bpmn:process>
</bpmn:definitions>`;

const ASSERT = `(function(){
  var errs = [], exports = [], B = 'http://www.omg.org/spec/BPMN/20100524/MODEL', O = ${JSON.stringify(ORIGIN_NS)};
  var AEF = 'http://anchorpoint.framework/aef/extensions';
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function dom(xml, tag){ var d = new DOMParser().parseFromString(xml, 'application/xml');
    var pe = d.getElementsByTagName('parsererror'); if (pe.length) { errs.push(tag + ': not well-formed'); return null; } return d; }
  function byName(d, local, name){ return Array.prototype.filter.call(d.getElementsByTagNameNS(B, local), function(e){ return e.getAttribute('name') === name; })[0]; }
  function origins(el){ var ext = el && Array.prototype.filter.call(el.children, function(c){ return c.namespaceURI === B && c.localName === 'extensionElements'; })[0];
    return ext ? Array.prototype.filter.call(ext.children, function(c){ return c.namespaceURI === O && c.localName === 'origin'; }) : []; }
  function flowTo(d, targetName){ var t = byName(d, 'endEvent', targetName) || byName(d, 'userTask', targetName);
    return t && Array.prototype.filter.call(d.getElementsByTagNameNS(B, 'sequenceFlow'), function(f){ return f.getAttribute('targetRef') === t.getAttribute('id'); })[0]; }
  function check(d, tag){
    var want = [['userTask', 'Approve', 'Task_Approve'], ['startEvent', 'Start', 'Start_1'], ['endEvent', 'Done', 'Legacy_End']];
    want.forEach(function(w){ var el = byName(d, w[0], w[1]), os = origins(el);
      if (os.length !== 1) errs.push(tag + ': ' + w[1] + ' carries ' + os.length + ' origin(s)');
      else { if (os[0].getAttribute('originalId') !== w[2]) errs.push(tag + ': ' + w[1] + ' origin is ' + os[0].getAttribute('originalId') + ' (want ' + w[2] + ')');
        if (os[0].textContent !== '' || os[0].children.length) errs.push(tag + ': origin has content (must be attribute-only)'); } });
    var f = flowTo(d, 'Approve'), fo = origins(f);
    if (fo.length !== 1 || fo[0].getAttribute('originalId') !== 'Flow_1') errs.push(tag + ': flow into Approve origin ' + (fo[0] ? fo[0].getAttribute('originalId') : 'missing') + ' (want Flow_1)');
    var uids = Array.prototype.filter.call(d.getElementsByTagName('*'), function(e){ return e.localName === 'uid' && e.namespaceURI !== AEF; });
    if (uids.length) errs.push(tag + ': an element named uid outside aef: (' + uids.length + ')');
  }
  try {
    load(window.__MAP__);
    var o1 = strip(buildBpmnXml(state)); exports.push(['leg1', o1]);
    var d1 = dom(o1, 'leg1'); if (d1) check(d1, 'leg1');
    var ta = byName(d1, 'userTask', 'Approve'); if (ta && ta.getAttribute('id') === 'Task_Approve') errs.push('leg1: cannot bite, the task kept its source id');
    load(o1);
    var o2 = strip(buildBpmnXml(state)); exports.push(['leg2', o2]);
    if (o2 !== o1) errs.push('leg2: second save differs from the first');
    var d2 = dom(o2, 'leg2'); if (d2) check(d2, 'leg2');
    // leg 3: the display id changes (lane renamed), the origin does not
    state.lanes[0].name = 'Reviewers'; state.lanes[0].abbr = ''; refreshDisplayIds();
    var o3 = strip(buildBpmnXml(state)); exports.push(['leg3', o3]);
    var d3 = dom(o3, 'leg3');
    if (d3) { check(d3, 'leg3'); var t3 = byName(d3, 'userTask', 'Approve'), t1 = byName(d1, 'userTask', 'Approve');
      if (t3 && t1 && t3.getAttribute('id') === t1.getAttribute('id')) errs.push('leg3: cannot bite, the display id did not change'); }
    // leg 4: designer-written maps
    var grew = [];
    (window.__CORPUS__ || []).forEach(function(c){
      load(c[1]);
      var has = state.nodes.some(function(n){ return 'originalId' in n; }) || state.edges.some(function(e){ return 'originalId' in e; });
      if (has || strip(buildBpmnXml(state)).indexOf(O) > -1) grew.push(c[0]);
    });
    if (!(window.__CORPUS__ || []).length) errs.push('leg4: no corpus maps loaded');
    if (grew.length) errs.push('leg4: designer-written maps gained an origin: ' + grew.join(', '));
    return { ok: errs.length === 0, errs: errs, exports: exports, corpus: (window.__CORPUS__ || []).length };
  } catch (err) { return { ok: false, errs: ['exception: ' + (err && err.stack || err)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort().map(f => [f, readFileSync(join(CORPUS, f), 'utf8')]);
  const doc = mkdtempSync(join(tmpdir(), 't1261-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1261-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1261-udd-');
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
