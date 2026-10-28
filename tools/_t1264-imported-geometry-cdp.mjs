#!/usr/bin/env node
// _t1264-imported-geometry-cdp.mjs — T-1264 (job C F6): another tool's diagram geometry is kept until the person moves
// the element. Before, a save wrote NODE_DEFAULTS sizes, recomputed every route, dropped isMarkerVisible and labels, and
// renamed every DI id. Drives the REAL editor runtime (parseBpmnXml -> buildBpmnXml) headless and asserts:
//   1. unmoved: a gateway keeps width 50, isMarkerVisible and its DI id; a task keeps 100x80; a start event keeps its
//      BPMNLabel; a bent flow keeps its waypoints and DI id; each points at the element's CURRENT id;
//   2. moved: the moved gateway is redrawn (designer size and id) and the flows touching it are recomputed, while the
//      untouched task and the flow between untouched nodes keep theirs;
//   3. a second save is byte-identical;
//   4. designer-written maps record nothing (no diKept in state);
//   5. every export parses in Python's expat.
// T1264_SRC substitutes another designer file (the BITE: run against the pre-T-1264 source, leg 1 is red).
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
const SRC = process.env.T1264_SRC || join(REPO, 'src/aef-workflow-designer.html');
const CORPUS = join(REPO, 'examples/aef-processes/rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// One lane; every node centred inside the designer's first lane band, so lane reconciliation moves none of them.
const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" xmlns:omgdc="http://www.omg.org/spec/DD/20100524/DC" xmlns:omgdi="http://www.omg.org/spec/DD/20100524/DI" id="Defs_1" targetNamespace="http://example.com/t1264" exporter="Camunda Modeler" exporterVersion="5.0.0">
  <bpmn:process id="Proc_1" isExecutable="true">
    <bpmn:laneSet id="LS"><bpmn:lane id="L1" name="Team">
      <bpmn:flowNodeRef>S</bpmn:flowNodeRef><bpmn:flowNodeRef>T</bpmn:flowNodeRef><bpmn:flowNodeRef>G</bpmn:flowNodeRef><bpmn:flowNodeRef>E</bpmn:flowNodeRef>
      <bpmn:flowNodeRef>X</bpmn:flowNodeRef>
    </bpmn:lane><bpmn:lane id="L2" name="Other"><bpmn:flowNodeRef>Y</bpmn:flowNodeRef></bpmn:lane></bpmn:laneSet>
    <bpmn:startEvent id="S" name="Start"/>
    <bpmn:userTask id="T" name="Review"/>
    <bpmn:exclusiveGateway id="G" name="OK?"/>
    <bpmn:endEvent id="E" name="Done"/>
    <bpmn:task id="X" name="Misplaced"/>
    <bpmn:task id="Y" name="Elsewhere"/>
    <bpmn:sequenceFlow id="F4" sourceRef="T" targetRef="X"/>
    <bpmn:sequenceFlow id="F1" sourceRef="S" targetRef="T"/>
    <bpmn:sequenceFlow id="F2" sourceRef="T" targetRef="G"/>
    <bpmn:sequenceFlow id="F3" sourceRef="G" targetRef="E"/>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="D1"><bpmndi:BPMNPlane id="PL1" bpmnElement="Proc_1">
    <bpmndi:BPMNShape id="S_di" bpmnElement="S"><omgdc:Bounds x="120" y="77" width="36" height="36"/>
      <bpmndi:BPMNLabel><omgdc:Bounds x="125" y="120" width="26" height="14"/></bpmndi:BPMNLabel></bpmndi:BPMNShape>
    <bpmndi:BPMNShape id="T_di" bpmnElement="T"><omgdc:Bounds x="200" y="63" width="100" height="80"/></bpmndi:BPMNShape>
    <bpmndi:BPMNShape id="G_di" bpmnElement="G" isMarkerVisible="true"><omgdc:Bounds x="360" y="71" width="50" height="50"/></bpmndi:BPMNShape>
    <bpmndi:BPMNShape id="E_di" bpmnElement="E"><omgdc:Bounds x="470" y="77" width="36" height="36"/></bpmndi:BPMNShape>
    <bpmndi:BPMNEdge id="F1_di" bpmnElement="F1" sourceElement="S_di" targetElement="T_di"><omgdi:waypoint x="156" y="95"/><omgdi:waypoint x="178" y="95"/><omgdi:waypoint x="178" y="100"/><omgdi:waypoint x="200" y="100"/></bpmndi:BPMNEdge>
    <bpmndi:BPMNEdge id="F2_di" bpmnElement="F2"><omgdi:waypoint x="300" y="100"/><omgdi:waypoint x="330" y="100"/><omgdi:waypoint x="330" y="96"/><omgdi:waypoint x="360" y="96"/></bpmndi:BPMNEdge>
    <bpmndi:BPMNShape id="X_di" bpmnElement="X"><omgdc:Bounds x="250" y="190" width="100" height="80"/></bpmndi:BPMNShape>
    <bpmndi:BPMNShape id="Y_di" bpmnElement="Y"><omgdc:Bounds x="420" y="190" width="100" height="80"/></bpmndi:BPMNShape>
    <bpmndi:BPMNEdge id="F4_di" bpmnElement="F4"><omgdi:waypoint x="250" y="143"/><omgdi:waypoint x="250" y="166"/><omgdi:waypoint x="300" y="166"/><omgdi:waypoint x="300" y="190"/></bpmndi:BPMNEdge>
    <bpmndi:BPMNEdge id="F3_di" bpmnElement="F3"><omgdi:waypoint x="410" y="96"/><omgdi:waypoint x="470" y="95"/></bpmndi:BPMNEdge>
  </bpmndi:BPMNPlane></bpmndi:BPMNDiagram>
</bpmn:definitions>`;

const ASSERT = `(function(){
  var errs = [], exports = [], B = 'http://www.omg.org/spec/BPMN/20100524/MODEL', DI = 'http://www.omg.org/spec/BPMN/20100524/DI';
  var DC = 'http://www.omg.org/spec/DD/20100524/DC', DDI = 'http://www.omg.org/spec/DD/20100524/DI';
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function dom(xml, tag){ var d = new DOMParser().parseFromString(xml, 'application/xml');
    var pe = d.getElementsByTagName('parsererror'); if (pe.length) { errs.push(tag + ': not well-formed'); return null; } return d; }
  function idOf(d, local, name){ var e = Array.prototype.filter.call(d.getElementsByTagNameNS(B, local), function(x){ return x.getAttribute('name') === name; })[0]; return e && e.getAttribute('id'); }
  function flowId(d, from, to){ var f = Array.prototype.filter.call(d.getElementsByTagNameNS(B, 'sequenceFlow'), function(x){
    return x.getAttribute('sourceRef') === from && x.getAttribute('targetRef') === to; })[0]; return f && f.getAttribute('id'); }
  function di(d, local, ref){ return Array.prototype.filter.call(d.getElementsByTagNameNS(DI, local), function(x){ return x.getAttribute('bpmnElement') === ref; })[0]; }
  function bounds(sh){ return sh && Array.prototype.filter.call(sh.children, function(c){ return c.namespaceURI === DC && c.localName === 'Bounds'; })[0]; }
  function wps(ed){ return ed ? Array.prototype.filter.call(ed.children, function(c){ return c.namespaceURI === DDI && c.localName === 'waypoint'; })
    .map(function(p){ return (+p.getAttribute('x')) + ',' + (+p.getAttribute('y')); }).join(' ') : ''; }
  // every sourceElement/targetElement on a BPMNEdge names a BPMNShape id this export contains
  function refsResolve(tag, d){ if (!d) return; var ids = {};
    Array.prototype.forEach.call(d.getElementsByTagNameNS(DI, 'BPMNShape'), function(s){ ids[s.getAttribute('id')] = 1; });
    var n = 0; Array.prototype.forEach.call(d.getElementsByTagNameNS(DI, 'BPMNEdge'), function(e){ ['sourceElement', 'targetElement'].forEach(function(a){
      if (e.hasAttribute(a)) { n++; if (!ids[e.getAttribute(a)]) errs.push(tag + ': ' + a + '=' + e.getAttribute(a) + ' names no shape'); } }); });
    if (tag === 'leg1' && n < 2) errs.push('leg1: cannot bite, no sourceElement/targetElement written'); }
  try {
    load(window.__MAP__);
    var want = { Start: [120, 77], Review: [200, 63], 'OK?': [360, 71], Done: [470, 77] };
    var moved = state.nodes.filter(function(n){ var w = want[n.name]; return w && (n.x !== w[0] || n.y !== w[1]); });
    if (moved.length) errs.push('setup: the import moved ' + moved.map(function(n){ return n.name + '@' + n.x + ',' + n.y; }).join(' ') + ' (the test cannot bite)');
    var mis = state.nodes.filter(function(n){ return n.name === 'Misplaced'; })[0];
    if (!mis || mis.y === 190) errs.push('setup: the import did not move Misplaced back into its lane (the reconcile case cannot bite)');
    var o1 = strip(buildBpmnXml(state)); exports.push(['leg1', o1]);
    var d1 = dom(o1, 'leg1');
    if (d1) {
      var S = idOf(d1, 'startEvent', 'Start'), T = idOf(d1, 'userTask', 'Review'), G = idOf(d1, 'exclusiveGateway', 'OK?'), E = idOf(d1, 'endEvent', 'Done');
      if (G === 'G') errs.push('leg1: cannot bite, the gateway kept its source id');
      var g = di(d1, 'BPMNShape', G), gb = bounds(g);
      if (!g || g.getAttribute('id') !== 'G_di') errs.push('leg1: gateway DI id ' + (g && g.getAttribute('id')) + ' (want G_di)');
      if (!g || g.getAttribute('isMarkerVisible') !== 'true') errs.push('leg1: gateway isMarkerVisible lost');
      if (!gb || gb.getAttribute('width') !== '50' || gb.getAttribute('height') !== '50') errs.push('leg1: gateway size ' + (gb && gb.getAttribute('width') + 'x' + gb.getAttribute('height')) + ' (want 50x50)');
      var tb = bounds(di(d1, 'BPMNShape', T));
      if (!tb || tb.getAttribute('width') !== '100' || tb.getAttribute('height') !== '80') errs.push('leg1: task size ' + (tb && tb.getAttribute('width') + 'x' + tb.getAttribute('height')) + ' (want 100x80)');
      var s = di(d1, 'BPMNShape', S), lab = s && Array.prototype.filter.call(s.children, function(c){ return c.localName === 'BPMNLabel'; })[0];
      if (!lab || !bounds(lab) || bounds(lab).getAttribute('y') !== '120') errs.push('leg1: start event label lost');
      var f2 = di(d1, 'BPMNEdge', flowId(d1, T, G));
      if (!f2 || f2.getAttribute('id') !== 'F2_di') errs.push('leg1: flow T->G DI id ' + (f2 && f2.getAttribute('id')) + ' (want F2_di)');
      if (wps(f2) !== '300,100 330,100 330,96 360,96') errs.push('leg1: flow T->G waypoints ' + wps(f2));
      if (wps(di(d1, 'BPMNEdge', flowId(d1, S, T))) !== '156,95 178,95 178,100 200,100') errs.push('leg1: flow S->T waypoints ' + wps(di(d1, 'BPMNEdge', flowId(d1, S, T))));
      // a node the IMPORT moved (declared in L1, drawn in L2's band) is redrawn, and so is its flow
      var X = idOf(d1, 'task', 'Misplaced'), x = di(d1, 'BPMNShape', X), xb = bounds(x);
      if (!x || x.getAttribute('id') === 'X_di' || (xb && xb.getAttribute('width') === '100')) errs.push('leg1: a node the import moved kept its imported geometry (' + (x && x.getAttribute('id')) + ')');
      var f4 = di(d1, 'BPMNEdge', flowId(d1, T, X));
      if (!f4 || f4.getAttribute('id') === 'F4_di' || wps(f4) === '250,143 250,166 300,166 300,190') errs.push('leg1: the flow into a node the import moved kept its imported route');
      var yb = bounds(di(d1, 'BPMNShape', idOf(d1, 'task', 'Elsewhere')));
      if (!yb || yb.getAttribute('width') !== '100') errs.push('leg1: an unmoved node in the second lane lost its size');
    }
    [['leg1', d1]].forEach(function(p){ refsResolve(p[0], p[1]); });
    load(o1);
    if (strip(buildBpmnXml(state)) !== o1) errs.push('leg3: second save differs from the first');
    // leg 2: move the gateway
    load(window.__MAP__);
    state.nodes.filter(function(n){ return n.name === 'OK?'; })[0].x += 40;
    var o2 = strip(buildBpmnXml(state)); exports.push(['leg2', o2]);
    var d2 = dom(o2, 'leg2');
    if (d2) {
      var S2 = idOf(d2, 'startEvent', 'Start'), T2 = idOf(d2, 'userTask', 'Review'), G2 = idOf(d2, 'exclusiveGateway', 'OK?');
      var g2 = di(d2, 'BPMNShape', G2), gb2 = bounds(g2);
      if (!g2 || g2.getAttribute('id') === 'G_di' || (gb2 && gb2.getAttribute('width') === '50')) errs.push('leg2: the moved gateway kept its imported geometry');
      var f22 = di(d2, 'BPMNEdge', flowId(d2, T2, G2));
      if (!f22 || f22.getAttribute('id') === 'F2_di' || wps(f22) === '300,100 330,100 330,96 360,96') errs.push('leg2: the flow into the moved gateway kept its imported route');
      var tb2 = bounds(di(d2, 'BPMNShape', T2));
      if (!tb2 || tb2.getAttribute('width') !== '100') errs.push('leg2: the untouched task lost its size');
      if (wps(di(d2, 'BPMNEdge', flowId(d2, S2, T2))) !== '156,95 178,95 178,100 200,100') errs.push('leg2: the flow between untouched nodes lost its route');
      refsResolve('leg2', d2);
    }
    var grew = [];
    (window.__CORPUS__ || []).forEach(function(c){ load(c[1]);
      if (state.nodes.some(function(n){ return 'diKept' in n; }) || state.edges.some(function(e){ return 'diKept' in e; })) grew.push(c[0]); });
    if (!(window.__CORPUS__ || []).length) errs.push('leg4: no corpus maps loaded');
    if (grew.length) errs.push('leg4: designer-written maps recorded geometry: ' + grew.join(', '));
    return { ok: errs.length === 0, errs: errs, exports: exports, corpus: (window.__CORPUS__ || []).length };
  } catch (err) { return { ok: false, errs: ['exception: ' + (err && err.stack || err)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort().map(f => [f, readFileSync(join(CORPUS, f), 'utf8')]);
  const doc = mkdtempSync(join(tmpdir(), 't1264-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1264-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1264-udd-');
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
