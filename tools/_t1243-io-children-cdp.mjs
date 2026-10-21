#!/usr/bin/env node
// _t1243-io-children-cdp.mjs — T-1243: CHILD elements inside <aef:input>/<aef:output> survive open and save.
// T-1220 kept unknown attributes on aef:io; a producer's nested attribute tree, a schema reference or any extension
// child was still dropped. Asked by aef-greenfield-test and both external reviewers of T-1242 (preserving is not
// interpreting). Drives the REAL editor runtime (parseBpmnXml -> buildBpmnXml) headless and asserts:
//   1. a 3-level nested aef:attr tree, a foreign-namespace child and a child with text survive, in order;
//   2. the save adds no namespace declaration (exactly one xmlns:aef, the root's; the foreign child keeps its own);
//   3. a second save is byte-identical to the first;
//   4. editing the input in state (rename, as the panel does) keeps its children;
//   5. an io with no children still serialises self-closing, exactly as before.
// T1243_SRC substitutes another designer file (the BITE: run against the pre-T-1243 source, leg 1 is red).
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
const SRC = process.env.T1243_SRC || join(REPO, 'src/aef-workflow-designer.html');
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
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="${AEF}" id="Defs_1" targetNamespace="http://example.com/t1243">
  <bpmn:process id="Proc_1" name="T-1243" isExecutable="false">
    <bpmn:startEvent id="Start_1" name="Start"/>
    <bpmn:serviceTask id="Task_1" name="Price order">
      <bpmn:extensionElements>
        <aef:uid value="t1243_task"/>
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
const WITH = map(`          <aef:input name="order" type="object" required="true" typeRef="nid:Order">
            <aef:attr name="customer" type="object" required="true"><aef:attr name="email" type="string" required="true"/><aef:attr name="tier" type="string" values="free,paid"><aef:attr name="since" type="date"/></aef:attr></aef:attr>
            <x:schema xmlns:x="urn:example:x" href="schemas/order-v1.json"/>
            <aef:note>order shape v1</aef:note>
          </aef:input>
          <aef:output name="quote" type="object"><aef:attr name="total" type="number"/></aef:output>`);
const WITHOUT = map(`          <aef:input name="owner" type="string" required="true"/>
          <aef:output name="assignment" type="ref"/>`);

const ASSERT = `(function(){
  var errs = [];
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function task(s){ return s.nodes.filter(function(n){ return n.uid === 't1243_task'; })[0]; }
  function count(s, sub){ return s.split(sub).length - 1; }
  try {
    load(window.__WITH__);
    var out1 = strip(buildBpmnXml(state));
    var want = ['<aef:attr name="customer" type="object" required="true">', '<aef:attr name="email" type="string" required="true"/>',
                '<aef:attr name="tier" type="string" values="free,paid">', '<aef:attr name="since" type="date"/>',
                '<x:schema xmlns:x="urn:example:x" href="schemas/order-v1.json"/>', '<aef:note>order shape v1</aef:note>',
                '<aef:attr name="total" type="number"/>', 'typeRef="nid:Order"'];
    want.forEach(function(w){ if (out1.indexOf(w) < 0) errs.push('leg1: missing ' + w); });
    var a = out1.indexOf('name="customer"'), b = out1.indexOf('<x:schema'), c = out1.indexOf('<aef:note>');
    if (!(a > -1 && a < b && b < c)) errs.push('leg1: children out of order (' + [a, b, c].join(',') + ')');
    if (count(out1, 'xmlns:aef=') !== 1) errs.push('leg2: xmlns:aef declared ' + count(out1, 'xmlns:aef=') + ' times (want 1, the root)');
    load(out1);
    var out2 = strip(buildBpmnXml(state));
    if (out2 !== out1) errs.push('leg3: second save differs from the first');
    var t = task(state);
    if (!t) { errs.push('leg4: task node t1243_task not found'); return { ok: false, errs: errs }; }
    var inp = t.io.inputs.filter(function(i){ return i.name === 'order'; })[0];
    inp.name = 'order_in';
    var out3 = strip(buildBpmnXml(state));
    if (out3.indexOf('<aef:input name="order_in"') < 0 || out3.indexOf('name="since"') < 0) errs.push('leg4: an edited input lost its children');
    load(window.__WITHOUT__);
    var out5 = strip(buildBpmnXml(state));
    if (out5.indexOf('<aef:input name="owner" type="string" required="true"/>') < 0) errs.push('leg5: plain input not self-closing as before');
    if (out5.indexOf('<aef:output name="assignment" type="ref"/>') < 0) errs.push('leg5: plain output not self-closing as before');
    var plain = task(state);
    if (plain && plain.io.inputs.concat(plain.io.outputs).some(function(i){ return 'children' in i; })) errs.push('leg5: a map without children grew a children key');
    return { ok: errs.length === 0, errs: errs };
  } catch (e) { return { ok: false, errs: ['exception: ' + (e && e.message || e)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1243-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1243-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1243-udd-');
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
