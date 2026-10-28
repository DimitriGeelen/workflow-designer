#!/usr/bin/env node
// _t1265-condition-language-cdp.mjs — T-1265: a sequence flow's <bpmn:conditionExpression> keeps its language and id
// attributes on open and save. Import kept only the text and export wrote a fixed element, so language="javascript" was
// dropped and the engine evaluated the script in its default language (JUEL in Camunda; ring20 cloud job C, F7).
// Drives the REAL editor runtime (parseBpmnXml -> buildBpmnXml) headless and asserts:
//   1. language and id survive, on the expression, with the same text;
//   2. a second save is byte-identical to the first;
//   3. editing the condition text in state (as the panel does) keeps the language;
//   4. a condition without language or id exports exactly as before: no new attribute;
//   5. a language with `"` and `&` is escaped, the export is well-formed (DOMParser, and Python's expat outside the
//      browser), and it re-reads equal.
// T1265_SRC substitutes another designer file (the BITE: run against the pre-T-1265 source, leg 1 is red).
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
const SRC = process.env.T1265_SRC || join(REPO, 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const XSI = 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"';
function map(condAttrs, text) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" ${XSI} id="Defs_1" targetNamespace="http://example.com/t1265">
  <bpmn:process id="Proc_1" name="T-1265" isExecutable="false">
    <bpmn:startEvent id="Start_1" name="Start"/>
    <bpmn:exclusiveGateway id="Gw_1" name="Cheap?"/>
    <bpmn:endEvent id="End_1" name="Yes"/>
    <bpmn:endEvent id="End_2" name="No"/>
    <bpmn:sequenceFlow id="f1" sourceRef="Start_1" targetRef="Gw_1"/>
    <bpmn:sequenceFlow id="f2" name="yes" sourceRef="Gw_1" targetRef="End_1">
      <bpmn:extensionElements><aef:uid value="t1265_cond"/></bpmn:extensionElements>
      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression"${condAttrs}>${text}</bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="f3" name="no" sourceRef="Gw_1" targetRef="End_2"/>
  </bpmn:process>
</bpmn:definitions>`;
}
const WITH = map(' language="javascript" id="Cond_1"', 'a &lt; b');
const WITHOUT = map('', 'ok == true');
const ODD = map(' language="x&quot;&amp;y"', 'a');

const ASSERT = `(function(){
  var errs = [], exports = [];
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function cond(s){ return s.edges.filter(function(e){ return e.uid === 't1265_cond'; })[0]; }
  function expr(xml){
    var d = new DOMParser().parseFromString(xml, 'application/xml');
    if (d.getElementsByTagName('parsererror').length) return { bad: d.getElementsByTagName('parsererror')[0].textContent.slice(0, 160) };
    var c = d.getElementsByTagNameNS('http://www.omg.org/spec/BPMN/20100524/MODEL', 'conditionExpression')[0];
    return c ? { lang: c.getAttribute('language'), id: c.getAttribute('id'), text: c.textContent, el: c } : { missing: true };
  }
  try {
    load(window.__WITH__);
    var out1 = strip(buildBpmnXml(state)), x1 = expr(out1);
    if (x1.bad || x1.missing) errs.push('leg1: export has no readable conditionExpression ' + (x1.bad || ''));
    else {
      if (x1.lang !== 'javascript') errs.push('leg1: language is ' + JSON.stringify(x1.lang) + ', want "javascript"');
      if (x1.id !== 'Cond_1') errs.push('leg1: id is ' + JSON.stringify(x1.id) + ', want "Cond_1"');
      if (x1.text !== 'a < b') errs.push('leg1: text is ' + JSON.stringify(x1.text));
    }
    exports.push(['leg1', out1]);
    load(out1);
    if (strip(buildBpmnXml(state)) !== out1) errs.push('leg2: second save differs from the first');
    load(window.__WITH__);
    var e = cond(state);
    if (!e) { errs.push('leg3: flow t1265_cond not found'); return { ok: false, errs: errs }; }
    e.condition = 'a <= b';
    var x3 = expr(strip(buildBpmnXml(state)));
    if (x3.lang !== 'javascript' || x3.text !== 'a <= b') errs.push('leg3: after a text edit: ' + JSON.stringify({ lang: x3.lang, text: x3.text }));
    load(window.__WITHOUT__);
    var out4 = strip(buildBpmnXml(state));
    var line = (out4.match(/<bpmn:conditionExpression[^>]*>/) || [''])[0];
    var want = '<bpmn:conditionExpression xsi:type="bpmn:tFormalExpression" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
    if (line !== want) errs.push('leg4: plain condition changed: ' + line);
    var e4 = cond(state);
    if (e4 && ('conditionLanguage' in e4 || 'conditionId' in e4)) errs.push('leg4: a plain condition grew conditionLanguage/conditionId');
    load(window.__ODD__);
    var out5 = strip(buildBpmnXml(state)), x5 = expr(out5);
    if (x5.bad) errs.push('leg5: export not well-formed: ' + x5.bad);
    else if (x5.lang !== 'x"&y') errs.push('leg5: language re-read as ' + JSON.stringify(x5.lang));
    exports.push(['leg5', out5]);
    load(out5);
    if (strip(buildBpmnXml(state)) !== out5) errs.push('leg5: second save differs from the first');
    return { ok: errs.length === 0, errs: errs, exports: exports };
  } catch (err) { return { ok: false, errs: ['exception: ' + (err && err.message || err)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1265-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1265-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1265-udd-');
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
    await ev(cmd, `window.__WITH__ = ${JSON.stringify(WITH)}; window.__WITHOUT__ = ${JSON.stringify(WITHOUT)}; window.__ODD__ = ${JSON.stringify(ODD)};`);
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
