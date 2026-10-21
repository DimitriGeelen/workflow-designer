#!/usr/bin/env node
// _t1220-io-extra-attrs-cdp.mjs — T-1220: attributes on <aef:input>/<aef:output> beyond name/type/required
// survive open and save. A consumer (aef-greenfield-test, T-276) generates aef:io from its ontology with
// ref / role / cardinality / dataType (AEF T-4415); before T-1220 the save kept only the named attributes.
// Drives the REAL editor runtime (parseBpmnXml -> buildBpmnXml) headless and asserts:
//   1. every extra attribute on an input and an output is written back, with its value, in its order;
//   2. a second save is byte-identical to the first (the preservation is a fixed point);
//   3. editing the input in state (rename, type change, as the panel does) keeps the extras;
//   4. deleting the input drops its extras with it;
//   5. a map with no extra attributes parses to state WITHOUT an `extra` key and emits only the named ones;
//   6. a value carrying quotes, an ampersand and angle brackets round-trips exactly (escaped, not raw).
// T1220_SRC substitutes another designer file (the BITE: run against the pre-T-1220 source, leg 1 is red).
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
const SRC = process.env.T1220_SRC || join(REPO, 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const AEF = 'http://anchorpoint.framework/aef/extensions';
function map(ioXml) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="${AEF}" id="Defs_1" targetNamespace="http://example.com/t1220">
  <bpmn:process id="Proc_1" name="T-1220" isExecutable="false">
    <bpmn:startEvent id="Start_1" name="Start"/>
    <bpmn:serviceTask id="Task_1" name="Assign owner">
      <bpmn:extensionElements>
        <aef:uid value="t1220_task"/>
        <aef:io>
${ioXml}
        </aef:io>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:endEvent id="End_1" name="End"/>
    <bpmn:sequenceFlow id="f1" sourceRef="Start_1" targetRef="Task_1"/>
    <bpmn:sequenceFlow id="f2" sourceRef="Task_1" targetRef="End_1"/>
  </bpmn:process>
</bpmn:definitions>`;
}
const WITH = map(`          <aef:input name="owner" type="string" required="true" ref="sfdc:Opportunity.OwnerId" role="read" cardinality="1" dataType="id" x-foo="bar"/>
          <aef:output name="assignment" type="ref" ref="sfdc:Opportunity.OwnerId" role="write" cardinality="0..1" dataType="reference"/>
          <aef:input name="note" type="string" label="He said &quot;a &amp; b &lt;c&gt;&quot;"/>`);
const WITHOUT = map(`          <aef:input name="owner" type="string" required="true"/>
          <aef:output name="assignment" type="ref"/>`);

const ASSERT = `(function(){
  var errs = [];
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function task(s){ return s.nodes.filter(function(n){ return n.uid === 't1220_task'; })[0]; }
  function line(out, tag, name){ var m = out.match(new RegExp('<aef:' + tag + ' name="' + name + '"[^>]*/>')); return m ? m[0] : ''; }
  try {
    load(window.__WITH__);
    var out1 = strip(buildBpmnXml(state));
    var li = line(out1, 'input', 'owner'), lo = line(out1, 'output', 'assignment');
    var wantIn = ' ref="sfdc:Opportunity.OwnerId" role="read" cardinality="1" dataType="id" x-foo="bar"';
    var wantOut = ' ref="sfdc:Opportunity.OwnerId" role="write" cardinality="0..1" dataType="reference"';
    if (li.indexOf(wantIn) < 0) errs.push('leg1: input extras missing or reordered: ' + (li || '<no aef:input owner>'));
    if (lo.indexOf(wantOut) < 0) errs.push('leg1: output extras missing or reordered: ' + (lo || '<no aef:output assignment>'));
    if (li.indexOf('required="true"') < 0) errs.push('leg1: required="true" lost: ' + li);
    load(out1);
    var out2 = strip(buildBpmnXml(state));
    if (out2 !== out1) errs.push('leg2: second save differs from the first');
    var t = task(state);
    if (!t) { errs.push('leg3: task node t1220_task not found'); return { ok: false, errs: errs }; }
    var inp = t.io.inputs.filter(function(i){ return i.name === 'owner'; })[0];
    inp.name = 'owner_id'; inp.type = 'ref';
    var out3 = strip(buildBpmnXml(state));
    var l3 = line(out3, 'input', 'owner_id');
    if (l3.indexOf('type="ref"') < 0 || l3.indexOf(wantIn) < 0) errs.push('leg3: an edited input lost its extras: ' + (l3 || '<none>'));
    t.io.inputs = t.io.inputs.filter(function(i){ return i.name !== 'owner_id'; });
    var out4 = strip(buildBpmnXml(state));
    if (out4.indexOf('dataType="id"') >= 0 || out4.indexOf('x-foo') >= 0) errs.push('leg4: a deleted input left its extras behind');
    load(window.__WITHOUT__);
    var plain = task(state);
    var hasExtra = plain && (plain.io.inputs.concat(plain.io.outputs)).some(function(i){ return 'extra' in i; });
    if (hasExtra) errs.push('leg5: a map without extras grew an extra key in state');
    var out5 = strip(buildBpmnXml(state));
    if (line(out5, 'input', 'owner') !== '<aef:input name="owner" type="string" required="true"/>') errs.push('leg5: plain input emitted as ' + line(out5, 'input', 'owner'));
    if (line(out5, 'output', 'assignment') !== '<aef:output name="assignment" type="ref"/>') errs.push('leg5: plain output emitted as ' + line(out5, 'output', 'assignment'));
    load(window.__WITH__);
    var note = task(state).io.inputs.filter(function(i){ return i.name === 'note'; })[0];
    var got = note && (note.extra || []).filter(function(kv){ return kv[0] === 'label'; })[0];
    if (!got || got[1] !== 'He said "a & b <c>"') errs.push('leg6: parsed label value is ' + JSON.stringify(got && got[1]));
    var l6 = line(strip(buildBpmnXml(state)), 'input', 'note');
    if (l6.indexOf('label="He said &quot;a &amp; b &lt;c&gt;&quot;"') < 0) errs.push('leg6: label not escaped on save: ' + l6);
    return { ok: errs.length === 0, errs: errs };
  } catch (e) { return { ok: false, errs: ['exception: ' + (e && e.message || e)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1220-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1220-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1220-udd-');
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
