#!/usr/bin/env node
// _t1102-unique-display-ids-cdp.mjs — T-1102: every node's display id is unique within its map. The display id IS the
// saved element id, so two nodes sharing one make the export invalid BPMN (kitchen-sink: two endEvents saved as
// `lan_end_event`, 2026-10-08 and again 2026-10-28). Drives the REAL editor runtime (parseBpmnXml -> buildBpmnXml)
// headless and asserts:
//   1. a minimal map with two same-word, same-slug events in two DIFFERENT unresolved lanes gets two distinct ids;
//   2. every third-party fixture and every corpus map saves with no repeated `id` value in the whole document;
//   3. a designer-written map whose ids were already unique keeps exactly the ids it had (corpus: ids in = ids out);
//   4. a second save is byte-identical.
// On failure it prints each duplicate with its nodes' lane values (the diagnosis, not just the count).
// T1102_SRC substitutes another designer file (the BITE: run against the pre-T-1102 source, legs 1 and 2 are red).
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
const SRC = process.env.T1102_SRC || join(REPO, 'src/aef-workflow-designer.html');
const CORPUS = join(REPO, 'examples/aef-processes/rendered');
const THIRD = join(REPO, 'tests/fixtures/third-party');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// Declared order: start, task, gateway, foreign task, task, end. Grouping by kind would put the end event second.

// Minimal case, the shape the kitchen-sink diagnosis named: a real lane whose abbreviation is `lan`, the same as the
// no-lane fallback (here a lane called "Lane"; in kitchen-sink it is Lane_1cofr07), holding a start event "Begin", and a
// subprocess whose start event "Begin" is in no lane.
const MIN = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" id="Defs_1" targetNamespace="http://example.com/t1102">
  <bpmn:process id="Proc_1" isExecutable="false">
    <bpmn:laneSet id="LS"><bpmn:lane id="L1" name="Lane">
      <bpmn:flowNodeRef>S1</bpmn:flowNodeRef><bpmn:flowNodeRef>SP</bpmn:flowNodeRef><bpmn:flowNodeRef>E1</bpmn:flowNodeRef>
    </bpmn:lane></bpmn:laneSet>
    <bpmn:startEvent id="S1" name="Begin"/>
    <bpmn:subProcess id="SP" name="Inner">
      <bpmn:startEvent id="S2" name="Begin"/>
      <bpmn:endEvent id="E2" name="Finish"/>
      <bpmn:sequenceFlow id="F2" sourceRef="S2" targetRef="E2"/>
    </bpmn:subProcess>
    <bpmn:endEvent id="E1" name="Finish"/>
    <bpmn:sequenceFlow id="F1" sourceRef="S1" targetRef="SP"/>
    <bpmn:sequenceFlow id="F3" sourceRef="SP" targetRef="E1"/>
  </bpmn:process>
</bpmn:definitions>`;

const ASSERT = `(function(){
  var errs = [], diag = [];
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  // ids on BPMN model and BPMN DI elements only: another tool's extension content is kept verbatim, its own ids and all
  // (caseagile repeats <caseagile:principal id="User"> in its source)
  var NS = { 'http://www.omg.org/spec/BPMN/20100524/MODEL': 1, 'http://www.omg.org/spec/BPMN/20100524/DI': 1 };
  function dupIds(xml){ var d = new DOMParser().parseFromString(xml, 'application/xml'), seen = {}, dup = {};
    Array.prototype.forEach.call(d.getElementsByTagName('*'), function(e){ var i = e.getAttribute('id'); if (!i || !NS[e.namespaceURI]) return;
      if (seen[i]) dup[i] = 1; seen[i] = 1; });
    return Object.keys(dup); }
  function nodeDups(){ var by = {};
    state.nodes.forEach(function(n){ var id = displayIdOf(n); (by[id] = by[id] || []).push(n); });
    return Object.keys(by).filter(function(k){ return by[k].length > 1; }).map(function(k){
      return k + ' <- ' + by[k].map(function(n){ return n.type + ' "' + (n.name || '') + '" lane=' + JSON.stringify(n.lane)
        + (findLane(n.lane) ? '' : ' (UNRESOLVED)') + ' uid=' + n.uid; }).join(' | '); }); }
  try {
    if (window.__MIN__) {
      load(window.__MIN__);
      var nd = nodeDups(); if (nd.length) errs.push('leg1: minimal map: ' + nd.join('; '));
    }
    (window.__THIRD__ || []).concat(window.__CORPUS__ || []).forEach(function(c){
      load(c[1]);
      var nd = nodeDups();
      if (nd.length) { errs.push('leg2: ' + c[0] + ': ' + nd.length + ' duplicate node id(s)'); diag.push(c[0] + ': ' + nd.join('; ')); }
      var out = strip(buildBpmnXml(state)), dd = dupIds(out);
      if (dd.length) errs.push('leg2: ' + c[0] + ' saves with repeated ids: ' + dd.slice(0, 6).join(', '));
      load(out);
      if (strip(buildBpmnXml(state)) !== out) errs.push('leg4: ' + c[0] + ': second save differs');
    });
    // leg 3: a designer-written map whose ids are unique keeps them
    var moved = [];
    (window.__CORPUS__ || []).forEach(function(c){
      var din = new DOMParser().parseFromString(c[1], 'application/xml');
      var ids = function(d){ return Array.prototype.map.call(d.getElementsByTagNameNS('http://www.omg.org/spec/BPMN/20100524/MODEL', '*'), function(e){ return e.getAttribute('id'); }).filter(Boolean).sort().join('|'); };
      if (dupIds(c[1]).length) return;
      load(c[1]);
      var dout = new DOMParser().parseFromString(strip(buildBpmnXml(state)), 'application/xml');
      if (ids(din) !== ids(dout)) moved.push(c[0]);
    });
    if (moved.length) errs.push('leg3: designer-written maps changed their ids: ' + moved.join(', '));
    return { ok: errs.length === 0, errs: errs, diag: diag, third: (window.__THIRD__ || []).length, corpus: (window.__CORPUS__ || []).length };
  } catch (err) { return { ok: false, errs: ['exception: ' + (err && err.stack || err)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const third = readdirSync(THIRD).filter(f => f.endsWith('.bpmn')).sort().map(f => [f, readFileSync(join(THIRD, f), 'utf8')]);
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort().map(f => [f, readFileSync(join(CORPUS, f), 'utf8')]);
  const doc = mkdtempSync(join(tmpdir(), 't1102-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1102-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1102-udd-');
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
    await ev(cmd, `window.__MIN__ = ${JSON.stringify(MIN)}; window.__THIRD__ = ${JSON.stringify(third)}; window.__CORPUS__ = ${JSON.stringify(corpus)};`);
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
