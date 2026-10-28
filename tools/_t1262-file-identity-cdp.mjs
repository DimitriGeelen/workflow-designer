#!/usr/bin/env node
// _t1262-file-identity-cdp.mjs — T-1262 (job C F4, with T-1270 / F12): a save keeps a file's own identity. Before, the
// designer wrote Definitions_<id>, its own targetNamespace, Collaboration_<id>, Process_<id> and isExecutable="true"
// whatever the file said, so a Camunda process lost its deployment key and callers' calledElement broke. Drives the
// REAL editor runtime (adoptImportedXml / parseBpmnXml -> buildBpmnXml) headless and asserts:
//   1. a file with a collaboration keeps its definitions id, targetNamespace, collaboration id, process id and
//      isExecutable="false"; the participant's processRef, a message flow naming our process, and the DI plane follow;
//   2. a file with no collaboration and no isExecutable keeps its process id, gets no isExecutable, and its invented
//      participant does not take the process id (every id in the export is unique);
//   3. (T-1270) the same file opened a second time: the designer's own workflowMeta id takes _v2, the saved ids do not;
//   4. designer-written maps record nothing (no fileIds) and a rename still renames Process_/Definitions_/Collaboration_;
//   5. a second save is byte-identical; every export parses in Python's expat.
// T1262_SRC substitutes another designer file (the BITE: run against the pre-T-1262 source, legs 1-3 are red).
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
const SRC = process.env.T1262_SRC || join(REPO, 'src/aef-workflow-designer.html');
const CORPUS = join(REPO, 'examples/aef-processes/rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof adoptImportedXml==='function'&&typeof renameActiveWorkflow==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const COLLAB = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" id="Defs_F" targetNamespace="http://example.com/f">
  <bpmn:collaboration id="Collab_F">
    <bpmn:participant id="P_F" name="Orders" processRef="Proc_F"/>
    <bpmn:participant id="P_X" name="Customer"/>
    <bpmn:messageFlow id="M1" sourceRef="P_X" targetRef="Proc_F"/>
  </bpmn:collaboration>
  <bpmn:process id="Proc_F" isExecutable="false">
    <bpmn:startEvent id="S" name="Start"/>
    <bpmn:task id="T" name="Handle"/>
    <bpmn:endEvent id="E" name="End"/>
    <bpmn:sequenceFlow id="F1" sourceRef="S" targetRef="T"/>
    <bpmn:sequenceFlow id="F2" sourceRef="T" targetRef="E"/>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="D1"><bpmndi:BPMNPlane id="PL1" bpmnElement="Collab_F">
    <bpmndi:BPMNShape id="S_di" bpmnElement="S"><dc:Bounds x="100" y="100" width="36" height="36"/></bpmndi:BPMNShape>
  </bpmndi:BPMNPlane></bpmndi:BPMNDiagram>
</bpmn:definitions>`;

const BARE = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" id="Defs_N" targetNamespace="http://example.com/n">
  <bpmn:process id="Proc_N">
    <bpmn:startEvent id="S" name="Start"/>
    <bpmn:endEvent id="E" name="End"/>
    <bpmn:sequenceFlow id="F1" sourceRef="S" targetRef="E"/>
  </bpmn:process>
</bpmn:definitions>`;

const ASSERT = `(function(){
  var errs = [], exports = [], B = 'http://www.omg.org/spec/BPMN/20100524/MODEL', DI = 'http://www.omg.org/spec/BPMN/20100524/DI';
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function dom(xml, tag){ var d = new DOMParser().parseFromString(xml, 'application/xml');
    var pe = d.getElementsByTagName('parsererror'); if (pe.length) { errs.push(tag + ': not well-formed'); return null; } return d; }
  function one(d, ns, local){ return d.getElementsByTagNameNS(ns, local)[0]; }
  function dupIds(d){ var seen = {}, dup = []; Array.prototype.forEach.call(d.getElementsByTagName('*'), function(e){
    var i = e.getAttribute('id'); if (!i) return; if (seen[i]) dup.push(i); seen[i] = 1; }); return dup; }
  function save(tag){ var x = strip(buildBpmnXml(state)); exports.push([tag, x]); return x; }
  function eq(tag, got, want){ if (got !== want) errs.push(tag + ': ' + got + ' (want ' + want + ')'); }
  try {
    // leg 1
    state = parseBpmnXml(window.__COLLAB__); refreshDisplayIds();
    var o1 = save('leg1'), d1 = dom(o1, 'leg1');
    if (d1) {
      var root = d1.documentElement, pr = one(d1, B, 'process'), co = one(d1, B, 'collaboration');
      eq('leg1 definitions id', root.getAttribute('id'), 'Defs_F');
      eq('leg1 targetNamespace', root.getAttribute('targetNamespace'), 'http://example.com/f');
      eq('leg1 collaboration id', co && co.getAttribute('id'), 'Collab_F');
      eq('leg1 process id', pr && pr.getAttribute('id'), 'Proc_F');
      eq('leg1 isExecutable', pr && pr.getAttribute('isExecutable'), 'false');
      var ours = Array.prototype.filter.call(d1.getElementsByTagNameNS(B, 'participant'), function(p){ return p.getAttribute('name') === 'Orders'; })[0];
      eq('leg1 participant processRef', ours && ours.getAttribute('processRef'), 'Proc_F');
      var mf = one(d1, B, 'messageFlow'); eq('leg1 message flow target', mf && mf.getAttribute('targetRef'), 'Proc_F');
      var pl = one(d1, DI, 'BPMNPlane'); eq('leg1 DI plane', pl && pl.getAttribute('bpmnElement'), 'Collab_F');
      var dup = dupIds(d1); if (dup.length) errs.push('leg1: duplicate ids ' + dup.join(', '));
    }
    state = parseBpmnXml(o1); refreshDisplayIds();
    if (strip(buildBpmnXml(state)) !== o1) errs.push('leg5: second save of leg 1 differs');
    // leg 2
    state = parseBpmnXml(window.__BARE__); refreshDisplayIds();
    var o2 = save('leg2'), d2 = dom(o2, 'leg2');
    if (d2) {
      var p2 = one(d2, B, 'process');
      eq('leg2 process id', p2 && p2.getAttribute('id'), 'Proc_N');
      if (p2 && p2.hasAttribute('isExecutable')) errs.push('leg2: isExecutable written where the file had none: ' + p2.getAttribute('isExecutable'));
      eq('leg2 definitions id', d2.documentElement.getAttribute('id'), 'Defs_N');
      var dup2 = dupIds(d2); if (dup2.length) errs.push('leg2: duplicate ids ' + dup2.join(', '));
    }
    state = parseBpmnXml(o2); refreshDisplayIds();
    if (strip(buildBpmnXml(state)) !== o2) errs.push('leg5: second save of leg 2 differs');
    // leg 3 (T-1270): the same file twice
    adoptImportedXml(window.__COLLAB__, {});
    var firstKey = activeKey;
    adoptImportedXml(window.__COLLAB__, {});
    if (activeKey === firstKey) errs.push('leg3: the second open did not get its own library entry (' + activeKey + ')');
    if (!/_v\\d+$/.test(state.workflowMeta.id)) errs.push('leg3: workflowMeta id of the second open is ' + state.workflowMeta.id + ', expected a _v suffix');
    var d3 = dom(save('leg3'), 'leg3');
    if (d3) {
      eq('leg3 process id', one(d3, B, 'process').getAttribute('id'), 'Proc_F');
      eq('leg3 definitions id', d3.documentElement.getAttribute('id'), 'Defs_F');
      eq('leg3 collaboration id', one(d3, B, 'collaboration').getAttribute('id'), 'Collab_F');
    }
    // leg 4: designer-written maps
    var recorded = [];
    (window.__CORPUS__ || []).forEach(function(c){ var st = parseBpmnXml(c[1]); if (st.fileIds) recorded.push(c[0] + ' ' + JSON.stringify(st.fileIds)); });
    if (!(window.__CORPUS__ || []).length) errs.push('leg4: no corpus maps loaded');
    if (recorded.length) errs.push('leg4: designer-written maps recorded file ids: ' + recorded.slice(0, 3).join('; '));
    if ((window.__CORPUS__ || []).length) {
      adoptImportedXml(window.__CORPUS__[0][1], {});
      if (!renameActiveWorkflow('t1262_renamed')) errs.push('leg4: rename refused');
      var d4 = dom(save('leg4'), 'leg4');
      if (d4) {
        eq('leg4 renamed process id', one(d4, B, 'process').getAttribute('id'), 'Process_t1262_renamed');
        eq('leg4 renamed definitions id', d4.documentElement.getAttribute('id'), 'Definitions_t1262_renamed');
        eq('leg4 renamed collaboration id', one(d4, B, 'collaboration').getAttribute('id'), 'Collaboration_t1262_renamed');
      }
    }
    return { ok: errs.length === 0, errs: errs, exports: exports, corpus: (window.__CORPUS__ || []).length };
  } catch (err) { return { ok: false, errs: ['exception: ' + (err && err.stack || err)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort().map(f => [f, readFileSync(join(CORPUS, f), 'utf8')]);
  const doc = mkdtempSync(join(tmpdir(), 't1262-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1262-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1262-udd-');
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
    await ev(cmd, `window.__COLLAB__ = ${JSON.stringify(COLLAB)}; window.__BARE__ = ${JSON.stringify(BARE)}; window.__CORPUS__ = ${JSON.stringify(corpus)};`);
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
