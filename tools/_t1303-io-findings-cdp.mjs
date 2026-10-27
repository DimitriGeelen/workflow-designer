#!/usr/bin/env node
// _t1303-io-findings-cdp.mjs — T-1303 (arc-006, slice 4): after Check, a mapping v1.1 lint finding whose location names
// an io (`node '<id>' output[i] "<name>"`) shows under that io's row in the properties panel. Drives the REAL editor
// headless against the REAL reference server (tools/gallery-serve.py), whose POST /api/validate runs the validator:
//   a. Check: step A's output 0 (update, no match field) shows E-XML-IO-MATCH-MISSING, ERROR, under ITS row; output 1
//      (a clean io on the same step) shows none;
//   b. step B: input 0 (undeclared prefix) shows E-XML-IO-PREFIX-UNDECLARED under the input row, output 0 (a match
//      field naming nothing) W-XML-IO-MATCH-UNRESOLVED, WARN, under the output row; nothing crosses between them;
//   c. a step with no finding: its panel is byte-identical before and after Check;
//   d. the drawer still lists all three and the canvas marks steps A and B (this repeats a finding, it moves none);
//   e. an io renamed since the Check shows no finding (never its neighbour's); closing the drawer clears them all;
//   f. geometry: every finding line lies inside the panel and is on top where a person reads it, at 1024 and 1440.
// T1303_SRC substitutes another designer file (e.g. the 0.30.0 source: a, b and f go red, c stays green).
// Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1303_SRC || join(REPO, 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const AEF = 'http://anchorpoint.framework/aef/extensions';
// Step A: output 0 updates with no match field (R1), output 1 is clean. Step B: input 0 names an undeclared prefix (R2),
// output 0 has a match field with neither fieldRef nor path (R3). Step C: a clean v1 io.
const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="${AEF}" id="Definitions_t1303" targetNamespace="https://aef.anchorpoint.dev/workflows">
  <bpmn:process id="Process_t1303" isExecutable="true">
    <bpmn:extensionElements>
      <aef:workflowMeta id="t1303-io-findings" version="1" schemaVersion="2" title="io findings" tier_default="1"/>
      <aef:meta mappingVersion="1.1">
        <aef:prefixes>
          <aef:prefix name="sfdc" iri="https://example.org/sfdc#" system="sys:salesforce" kind="field"/>
        </aef:prefixes>
      </aef:meta>
    </bpmn:extensionElements>
    <bpmn:laneSet id="LaneSet_1"><bpmn:lane id="Lane_ops" name="Operations">
      <bpmn:extensionElements><aef:laneMeta authority="initiative"/></bpmn:extensionElements>
      <bpmn:flowNodeRef>Start_1</bpmn:flowNodeRef><bpmn:flowNodeRef>Task_A</bpmn:flowNodeRef><bpmn:flowNodeRef>Task_B</bpmn:flowNodeRef>
      <bpmn:flowNodeRef>Task_C</bpmn:flowNodeRef><bpmn:flowNodeRef>End_1</bpmn:flowNodeRef>
    </bpmn:lane></bpmn:laneSet>
    <bpmn:startEvent id="Start_1" name="Start"/>
    <bpmn:serviceTask id="Task_A" name="Update opportunity">
      <bpmn:extensionElements>
        <aef:uid value="t1303_a"/>
        <aef:io>
          <aef:output name="opp" typeRef="sfdc:Opportunity" operation="update">
            <aef:field fieldRef="sfdc:Opportunity.StageName" role="write"/>
          </aef:output>
          <aef:output name="note" type="string"/>
        </aef:io>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:serviceTask id="Task_B" name="Sync contact">
      <bpmn:extensionElements>
        <aef:uid value="t1303_b"/>
        <aef:io>
          <aef:input name="contact" typeRef="crm:Contact"/>
          <aef:output name="ct" typeRef="sfdc:Contact" operation="upsert">
            <aef:field role="match"/>
          </aef:output>
        </aef:io>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:serviceTask id="Task_C" name="Notify owner">
      <bpmn:extensionElements>
        <aef:uid value="t1303_c"/>
        <aef:io><aef:input name="owner" type="string" required="true"/></aef:io>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:endEvent id="End_1" name="End"/>
    <bpmn:sequenceFlow id="f1" sourceRef="Start_1" targetRef="Task_A"/>
    <bpmn:sequenceFlow id="f2" sourceRef="Task_A" targetRef="Task_B"/>
    <bpmn:sequenceFlow id="f3" sourceRef="Task_B" targetRef="Task_C"/>
    <bpmn:sequenceFlow id="f4" sourceRef="Task_C" targetRef="End_1"/>
  </bpmn:process>
</bpmn:definitions>
`;

const PAGE = `(function(){
  window.__open = function(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); renderAll(); return true; };
  window.__select = function(uid){
    var n = state.nodes.filter(function(x){ return x.uid === uid; })[0];
    selection = { kind: 'node', id: n.id }; multiSelect = new Set([n.id]); renderProperties();
    return !!n;
  };
  // The findings shown under each io row of the selected step: { inputs: [[rule, sev, text]...], outputs: [...] }
  window.__ioFindings = function(){
    var out = { inputs: [], outputs: [] };
    document.querySelectorAll('#properties .io-block').forEach(function(b){
      var label = (b.querySelector('.field-label') || {}).textContent || '';
      var key = label.indexOf('inputs') === 0 ? 'inputs' : label.indexOf('outputs') === 0 ? 'outputs' : null;
      if (!key) return;
      var list = b.querySelector('.io-list'); if (!list) return;
      var cur = -1;
      Array.from(list.children).forEach(function(c){
        if (c.classList.contains('io-row')) { cur++; out[key][cur] = []; }
        else if (c.classList.contains('io-findings') && cur >= 0)
          c.querySelectorAll('.io-finding').forEach(function(f){ out[key][cur].push([f.dataset.rule, f.dataset.sev, f.textContent]); });
      });
    });
    return out;
  };
  // The panel's markup, after two frames, without inline style: the name field's auto-grow sets its height
  // asynchronously (style="height: …"), so with style in, two captures of an unchanged panel differ by timing alone.
  window.__panel = function(){
    return new Promise(function(res){ requestAnimationFrame(function(){ requestAnimationFrame(function(){
      res(document.getElementById('properties').innerHTML.replace(/ style="[^"]*"/g, ''));
    }); }); });
  };
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1303-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1303-repo-'));
  writeFileSync(join(doc, 'designer.html'), readFileSync(SRC, 'utf8'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1303-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const legs = {}, errs = [];
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('server down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    const E = (js) => ev(cmd, js);
    await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(500); await E(PAGE);
    const sel = (uid) => E(`window.__select(${JSON.stringify(uid)})`);
    const shown = () => E('window.__ioFindings()');
    const rules = (list) => (list || []).map(f => f[0] + '/' + f[1]);

    await E(`window.__open(${JSON.stringify(MAP)})`);
    await sel('t1303_c'); const cBefore = await E('window.__panel()');
    await sel('t1303_a'); const aBefore = await shown();
    await E('runCheck()');
    const view = await E(`({ state: findingsView.state, rows: findingsView.rows.map(function(r){ return [r.rule, r.location]; }),
      marked: Array.from(findingsView.byNode.keys()).map(function(id){ var n = state.nodes.filter(function(x){ return x.id === id; })[0]; return n && n.uid; }) })`);
    legs.check = view;
    if (view.state !== 'checked') errs.push('check: the Check did not complete against the server: ' + JSON.stringify(view));

    // a. step A
    await sel('t1303_a'); const a = await shown();
    legs.a = { before: aBefore, after: a };
    if (JSON.stringify(rules(a.outputs[0])) !== JSON.stringify(['E-XML-IO-MATCH-MISSING/ERROR']))
      errs.push('a: output 0 of step A should show exactly E-XML-IO-MATCH-MISSING (ERROR): ' + JSON.stringify(a.outputs[0]));
    if ((a.outputs[1] || []).length) errs.push('a: output 1 of step A is clean and shows: ' + JSON.stringify(a.outputs[1]));
    if (a.outputs[0] && a.outputs[0][0] && a.outputs[0][0][2].indexOf('operation="update"') < 0)
      errs.push('a: the line should carry the validator\'s message: ' + a.outputs[0][0][2]);
    if ((aBefore.outputs[0] || []).length) errs.push('a: before Check nothing should be shown: ' + JSON.stringify(aBefore));

    // b. step B: one under the input row, one under the output row
    await sel('t1303_b'); const b = await shown();
    legs.b = b;
    if (JSON.stringify(rules(b.inputs[0])) !== JSON.stringify(['E-XML-IO-PREFIX-UNDECLARED/ERROR']))
      errs.push('b: input 0 of step B should show exactly E-XML-IO-PREFIX-UNDECLARED: ' + JSON.stringify(b.inputs[0]));
    if (JSON.stringify(rules(b.outputs[0])) !== JSON.stringify(['W-XML-IO-MATCH-UNRESOLVED/WARN']))
      errs.push('b: output 0 of step B should show exactly W-XML-IO-MATCH-UNRESOLVED (WARN): ' + JSON.stringify(b.outputs[0]));

    // c. a step with no finding: the panel exactly as before
    await sel('t1303_c'); const cAfter = await E('window.__panel()');
    let at = 0; while (at < cBefore.length && cBefore[at] === cAfter[at]) at++;
    legs.c = { same: cBefore === cAfter, len: cAfter.length, firstDiff: cBefore === cAfter ? null
      : { before: cBefore.slice(Math.max(0, at - 120), at + 120), after: cAfter.slice(Math.max(0, at - 120), at + 120) } };
    if (cBefore !== cAfter) errs.push('c: Check changed the panel of a step that has no finding');

    // d. the drawer and the canvas keep every finding
    const ioRows = view.rows.filter(r => /^(E-XML-IO-|W-XML-IO-)/.test(r[0]));
    const drawer = await E(`document.querySelectorAll('#findings-list .finding-row').length`);
    legs.d = { ioRows: ioRows.length, drawerRows: drawer, marked: view.marked };
    if (ioRows.length !== 3) errs.push('d: the validator should report 3 io findings, got ' + JSON.stringify(ioRows));
    if (drawer < 3) errs.push('d: the drawer lists ' + drawer + ' rows, fewer than the io findings');
    if (!view.marked.includes('t1303_a') || !view.marked.includes('t1303_b')) errs.push('d: the canvas should mark steps A and B: ' + JSON.stringify(view.marked));

    // f. geometry (before e, which clears the findings)
    const geo = [];
    for (const [w, h] of [[1024, 768], [1440, 900]]) {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
      await sel('t1303_b');
      geo.push(await E(`(function(){
        var out = [], p = document.getElementById('properties'), pr = p.getBoundingClientRect();
        var fs = p.querySelectorAll('.io-finding');
        if (fs.length < 2) out.push('only ' + fs.length + ' finding line(s) to measure');   // never vacuous
        fs.forEach(function(f){
          f.scrollIntoView({ block: 'center' });
          var r = f.getBoundingClientRect(), pr2 = p.getBoundingClientRect();
          if (r.width < 1 || r.right > pr2.right + 0.5 || r.left < pr2.left - 0.5) out.push(f.dataset.rule + ' x ' + Math.round(r.left) + '..' + Math.round(r.right) + ' vs panel ' + Math.round(pr2.left) + '..' + Math.round(pr2.right));
          if (f.scrollWidth > f.clientWidth + 1) out.push(f.dataset.rule + ' overflows its line');
          var hit = document.elementFromPoint(r.left + Math.min(20, r.width / 2), r.top + Math.min(6, r.height / 2));
          if (!hit || (hit !== f && !f.contains(hit))) out.push(f.dataset.rule + ' not on top: ' + (hit ? (hit.className || hit.tagName) : 'nothing'));
        });
        return { w: ${w}, outside: out };
      })()`));
    }
    await cmd('Emulation.clearDeviceMetricsOverride');
    legs.f = geo;
    for (const g of geo) if (g.outside.length) errs.push(`f: at ${g.w} px: ` + g.outside.slice(0, 3).join(' | '));

    // e. a renamed io shows nothing; closing the drawer clears everything
    await sel('t1303_a');
    await E(`(function(){ var n = state.nodes.filter(function(x){ return x.uid === 't1303_a'; })[0]; n.io.outputs[0].name = 'opp2'; renderProperties(); })()`);
    const eRen = await shown();
    await E(`document.getElementById('findings-close').click()`);
    await sel('t1303_b'); const eClosed = await shown();
    legs.e = { renamed: eRen, closed: eClosed };
    if ((eRen.outputs[0] || []).length || (eRen.outputs[1] || []).length) errs.push('e: after renaming output 0 its finding should not show anywhere: ' + JSON.stringify(eRen));
    if ([].concat(eClosed.inputs, eClosed.outputs).some(l => (l || []).length)) errs.push('e: closing the drawer should clear the io findings: ' + JSON.stringify(eClosed));

    const ok = errs.length === 0;
    console.log(JSON.stringify({ ok, src: SRC, errs, legs }, null, 2));
    process.exitCode = ok ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e), legs }, null, 2));
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
