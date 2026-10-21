#!/usr/bin/env node
// _t1217-native-link-definition-cdp.mjs — T-1217: a link event marked the standard way keeps that marking.
// A third-party map pairs a link throw with its catch by <bpmn:linkEventDefinition name>. The designer encodes link
// events as <aef:link> (T-190 IW-1) and dropped the native element on save, losing the pairing entirely
// (aef-greenfield-test, 25 maps). Drives the REAL editor runtime headless and asserts:
//   1. a throw and a catch carrying <bpmn:linkEventDefinition id name> save it back, id and name intact;
//   2. its name seeds the node's linkId when no aef:link names one;
//   3. the definition is written after incoming/outgoing (BPMN tThrowEvent/tCatchEvent order);
//   4. a second save is byte-identical to the first;
//   5. changing the linkId renames the native definition with it, so throw and catch stay paired;
//   6. a link event authored without a native definition still emits none (our own maps are unchanged).
// T1217_SRC substitutes another designer file (the BITE: against the pre-T-1217 source, legs 1-2 are red).
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
const SRC = process.env.T1217_SRC || join(REPO, 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const AEF = 'http://anchorpoint.framework/aef/extensions';
const NATIVE = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="${AEF}" id="Defs_1" targetNamespace="http://example.com/t1217">
  <bpmn:process id="Proc_1" name="T-1217" isExecutable="false">
    <bpmn:startEvent id="Start_1" name="Order in"/>
    <bpmn:intermediateThrowEvent id="Throw_1" name="Hand over to Purchasing"><bpmn:linkEventDefinition id="link_a" name="Purchasing"/></bpmn:intermediateThrowEvent>
    <bpmn:intermediateCatchEvent id="Catch_1" name="From Sales"><bpmn:linkEventDefinition id="link_b" name="Purchasing"/></bpmn:intermediateCatchEvent>
    <bpmn:endEvent id="End_1" name="Ordered"/>
    <bpmn:sequenceFlow id="f1" sourceRef="Start_1" targetRef="Throw_1"/>
    <bpmn:sequenceFlow id="f2" sourceRef="Catch_1" targetRef="End_1"/>
  </bpmn:process>
</bpmn:definitions>`;
const OURS = NATIVE.replace('<bpmn:linkEventDefinition id="link_a" name="Purchasing"/>', '<bpmn:extensionElements><aef:link linkId="Purchasing"/></bpmn:extensionElements>')
                   .replace('<bpmn:linkEventDefinition id="link_b" name="Purchasing"/>', '<bpmn:extensionElements><aef:link linkId="Purchasing"/></bpmn:extensionElements>');

const ASSERT = `(function(){
  var errs = [];
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function block(out, tag){ var m = out.match(new RegExp('<bpmn:' + tag + ' [^>]*>[\\\\s\\\\S]*?<\\\\/bpmn:' + tag + '>')); return m ? m[0] : ''; }
  try {
    load(window.__NATIVE__);
    var out1 = strip(buildBpmnXml(state));
    var tb = block(out1, 'intermediateThrowEvent'), cb = block(out1, 'intermediateCatchEvent');
    if (tb.indexOf('<bpmn:linkEventDefinition id="link_a" name="Purchasing"/>') < 0) errs.push('leg1: throw lost its native definition: ' + tb.slice(0, 300));
    if (cb.indexOf('<bpmn:linkEventDefinition id="link_b" name="Purchasing"/>') < 0) errs.push('leg1: catch lost its native definition: ' + cb.slice(0, 300));
    var links = state.nodes.filter(function(n){ return n.type === 'linkEventThrow' || n.type === 'linkEventCatch'; });
    if (links.length !== 2 || links.some(function(n){ return (n.aef || {}).linkId !== 'Purchasing'; }))
      errs.push('leg2: linkId not seeded from the native name: ' + JSON.stringify(links.map(function(n){ return (n.aef || {}).linkId; })));
    var io = tb.lastIndexOf('<bpmn:incoming>'), ld = tb.indexOf('<bpmn:linkEventDefinition');
    if (io < 0 || ld < io) errs.push('leg3: native definition not after incoming in the throw block');
    load(out1);
    var out2 = strip(buildBpmnXml(state));
    if (out2 !== out1) errs.push('leg4: second save differs from the first');
    state.nodes.forEach(function(n){ if (n.type === 'linkEventThrow' || n.type === 'linkEventCatch') n.aef.linkId = 'Purchasing2'; });
    var out5 = strip(buildBpmnXml(state));
    if ((out5.match(/<bpmn:linkEventDefinition [^>]*name="Purchasing2"\\/>/g) || []).length !== 2) errs.push('leg5: renamed linkId did not rename both native definitions');
    load(window.__OURS__);
    var out6 = strip(buildBpmnXml(state));
    if (out6.indexOf('linkEventDefinition') >= 0) errs.push('leg6: a link event without a native definition now emits one');
    return { ok: errs.length === 0, errs: errs };
  } catch (e) { return { ok: false, errs: ['exception: ' + (e && e.message || e)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1217-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1217-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1217-udd-');
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
    await ev(cmd, `window.__NATIVE__ = ${JSON.stringify(NATIVE)}; window.__OURS__ = ${JSON.stringify(OURS)};`);
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
