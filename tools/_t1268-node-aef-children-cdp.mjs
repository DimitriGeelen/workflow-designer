#!/usr/bin/env node
// _t1268-node-aef-children-cdp.mjs — T-1268: an aef element on a node that the designer does not read survives open and
// save. Import read only the aef children it names, so an element written by a newer AEF or bridge was gone after one
// save (ring20 cloud job C, F10; T-1243 had fixed the same for children of aef:input/aef:output). Drives the REAL editor
// runtime (parseBpmnXml -> buildBpmnXml) headless and asserts:
//   1. two unknown aef elements (one flat, one nested with text) are written back in source order, inside the node's
//      extensionElements, after the ones the designer writes, with no namespace declaration added;
//   2. a second save is byte-identical to the first;
//   3. renaming the node (as the panel does) keeps them;
//   4. a node without unknown aef elements exports exactly as before, and grows no aefKept key; an element the designer
//      reads (aef:meta) is written once, not kept twice;
//   5. the export is well-formed (DOMParser, and Python's expat outside the browser).
// T1268_SRC substitutes another designer file (the BITE: run against the pre-T-1268 source, leg 1 is red).
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
const SRC = process.env.T1268_SRC || join(REPO, 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

function map(taskExt) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" id="Defs_1" targetNamespace="http://example.com/t1268">
  <bpmn:process id="Proc_1" name="T-1268" isExecutable="false">
    <bpmn:startEvent id="Start_1" name="Start"/>
    <bpmn:serviceTask id="Task_1" name="Price order">
      <bpmn:extensionElements>
        <aef:uid value="t1268_task"/>
${taskExt}
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:endEvent id="End_1" name="End"/>
    <bpmn:sequenceFlow id="f1" sourceRef="Start_1" targetRef="Task_1"/>
    <bpmn:sequenceFlow id="f2" sourceRef="Task_1" targetRef="End_1"/>
  </bpmn:process>
</bpmn:definitions>`;
}
const WITH = map(`        <aef:customNote text="keep me too"/>
        <aef:meta tier="1"/>
        <aef:future level="2"><aef:part ref="x">t &amp; u</aef:part></aef:future>`);
const WITHOUT = map(`        <aef:meta tier="1"/>`);

const ASSERT = `(function(){
  var errs = [], exports = [];
  var AEF = 'http://anchorpoint.framework/aef/extensions', BPMN = 'http://www.omg.org/spec/BPMN/20100524/MODEL';
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function task(s){ return s.nodes.filter(function(n){ return n.uid === 't1268_task'; })[0]; }
  function count(s, sub){ return s.split(sub).length - 1; }
  function taskExt(xml){
    var d = new DOMParser().parseFromString(xml, 'application/xml');
    if (d.getElementsByTagName('parsererror').length) return { bad: d.getElementsByTagName('parsererror')[0].textContent.slice(0, 160) };
    var t = Array.prototype.filter.call(d.getElementsByTagNameNS(BPMN, 'serviceTask'), function(e){ return true; })[0];
    var ext = t && Array.prototype.filter.call(t.children, function(c){ return c.localName === 'extensionElements'; })[0];
    return ext ? { kids: Array.prototype.map.call(ext.children, function(c){ return (c.namespaceURI === AEF ? 'aef:' : '?:') + c.localName; }), ext: ext } : { missing: true };
  }
  try {
    load(window.__WITH__);
    var out1 = strip(buildBpmnXml(state)), x1 = taskExt(out1);
    exports.push(['leg1', out1]);
    if (x1.bad || x1.missing) errs.push('leg1: no readable extensionElements on the task ' + (x1.bad || ''));
    else {
      var a = x1.kids.indexOf('aef:customNote'), b = x1.kids.indexOf('aef:future');
      if (a < 0) errs.push('leg1: aef:customNote dropped (' + x1.kids.join(',') + ')');
      if (b < 0) errs.push('leg1: aef:future dropped (' + x1.kids.join(',') + ')');
      if (a > -1 && b > -1 && a > b) errs.push('leg1: out of source order (' + x1.kids.join(',') + ')');
      if (out1.indexOf('<aef:customNote text="keep me too"/>') < 0) errs.push('leg1: customNote not verbatim');
      if (out1.indexOf('<aef:future level="2"><aef:part ref="x">t &amp; u</aef:part></aef:future>') < 0) errs.push('leg1: future not verbatim');
      if (count(x1.kids.join(','), 'aef:meta') !== 1) errs.push('leg4: aef:meta written ' + count(x1.kids.join(','), 'aef:meta') + ' times');
    }
    if (count(out1, 'xmlns:aef=') !== 1) errs.push('leg1: xmlns:aef declared ' + count(out1, 'xmlns:aef=') + ' times (want 1, the root)');
    load(out1);
    if (strip(buildBpmnXml(state)) !== out1) errs.push('leg2: second save differs from the first');
    load(window.__WITH__);
    var t = task(state);
    if (!t) { errs.push('leg3: task t1268_task not found'); return { ok: false, errs: errs }; }
    t.name = 'Price the order';
    var out3 = strip(buildBpmnXml(state));
    if (out3.indexOf('name="Price the order"') < 0) errs.push('leg3: rename not written');
    if (out3.indexOf('<aef:customNote text="keep me too"/>') < 0 || out3.indexOf('<aef:future level="2">') < 0) errs.push('leg3: a renamed node lost its kept elements');
    exports.push(['leg3', out3]);
    load(window.__WITHOUT__);
    var plain = task(state);
    if (plain && 'aefKept' in plain) errs.push('leg4: a node without unknown aef elements grew aefKept');
    var x4 = taskExt(strip(buildBpmnXml(state)));
    if (x4.kids && x4.kids.join(',') !== 'aef:uid,aef:position,aef:meta') errs.push('leg4: plain node extension changed: ' + x4.kids.join(','));
    return { ok: errs.length === 0, errs: errs, exports: exports };
  } catch (err) { return { ok: false, errs: ['exception: ' + (err && err.message || err)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1268-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1268-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1268-udd-');
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
    await ev(cmd, `window.__WITH__ = ${JSON.stringify(WITH)}; window.__WITHOUT__ = ${JSON.stringify(WITHOUT)};`);
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
