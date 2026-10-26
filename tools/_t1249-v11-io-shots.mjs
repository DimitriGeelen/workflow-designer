#!/usr/bin/env node
// _t1249-v11-io-shots.mjs — T-1249: screenshots of the read-only mapping v1.1 io display, for the visual review.
// States: v11-step (a v1.1 step with fields, expectations, an example, explicit and derived systems), v1-step (a plain
// v1 io), empty-step (a step with no io), workflow (the workflow panel's Mapping section). Each at 1024x768, 1440x900
// and 1920x1080: the full viewport (toolbar reach) and the properties panel scrolled to the section (-panel), plus a
// second panel shot scrolled to the end when the section is taller than the panel (-panel-end).
// Fixtures: AEF's mapping v1.1 section-11 examples and its FULL case only (never client material).
// Usage: node tools/_t1249-v11-io-shots.mjs [outdir]   (default docs/reports/T-1249-evidence)
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, writeFileSync, rmSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1249_SRC || join(REPO, 'src/aef-workflow-designer.html');
const OUT = process.argv[2] || join(REPO, 'docs/reports/T-1249-evidence');
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const AEF = 'http://anchorpoint.framework/aef/extensions';
const io = lines => lines.map(l => '          ' + l).join('\n');
const task = (id, name, uid, body) => `    <bpmn:serviceTask id="${id}" name="${name}">
      <bpmn:extensionElements>
        <aef:uid value="${uid}"/>
${body}      </bpmn:extensionElements>
    </bpmn:serviceTask>`;
const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="${AEF}" id="Definitions_t1249" targetNamespace="https://aef.anchorpoint.dev/workflows">
  <bpmn:process id="Process_t1249" isExecutable="true">
    <bpmn:extensionElements>
      <aef:workflowMeta id="t1249-v11-io" version="1" schemaVersion="2" title="Mapping v1.1 io (section 11 examples)" tier_default="1"/>
      <aef:meta mappingVersion="1.1">
        <aef:prefixes>
          <aef:prefix name="sfdc" iri="https://example.org/sfdc#" system="sys:salesforce" kind="field"/>
          <aef:prefix name="tacton" iri="https://example.org/tacton#" kind="type"/>
        </aef:prefixes>
      </aef:meta>
    </bpmn:extensionElements>
    <bpmn:startEvent id="Start_1" name="Start"/>
${task('Task_v11', 'Sync opportunity', 't1249_v11', `        <aef:meta sourceSystem="sys:crm-default"/>
        <aef:io>
${io(['<aef:input name="opp" typeRef="sf:Opportunity" sourceSystem="sys:crm" required="true" cardinality="one" conceptRef="biz:Deal" ref="nid:x" dataType="id">',
  '  <aef:field path="LineItems[]" cardinality="many"><aef:when path="Kind" const="TradeIn"/></aef:field>',
  '  <aef:expect path="Status"><aef:value>Won</aef:value><aef:value>Closed Won</aef:value></aef:expect>',
  '  <aef:expect path="Amount" minimum="10000" exclusiveMaximum="1e9" pattern="^[0-9]+$"/>',
  '  <aef:example path="Amount" value="12500"/>',
  '</aef:input>',
  '<aef:input fieldRef="sfdc:Opportunity.Id" role="read" type="ref"/>',
  '<aef:output typeRef="tacton:Opportunity" operation="upsert">',
  '  <aef:field fieldRef="tacton:Opportunity.crmOppExtId" role="match"/>',
  '  <aef:field fieldRef="tacton:Opportunity.name" role="write"/>',
  '  <aef:field fieldRef="tacton:Opportunity.accountId" role="create"/>',
  '</aef:output>',
  '<aef:output typeRef="sfdc:Opportunity" operation="update">',
  '  <aef:field fieldRef="sfdc:Opportunity.Id" role="match"/>',
  '  <aef:expect path="StageName" const="Closed Won"/>',
  '</aef:output>',
  '<aef:output typeRef="sfdc:Account" targetSystem="sys:salesforce" operation="create">',
  '  <aef:field fieldRef="sfdc:Account.Name" role="write"/>',
  '  <aef:field path="Phone" role="write"/>',
  '  <aef:field path="OwnerId" role="write" required="true"/>',
  '</aef:output>'])}
        </aef:io>
`)}
${task('Task_v1', 'Assign owner', 't1249_v1', `        <aef:io>
${io(['<aef:input name="owner" type="string" required="true"/>', '<aef:input name="team" type="list"/>', '<aef:output name="assignment" type="ref"/>'])}
        </aef:io>
`)}
${task('Task_stylea', 'Configure quote', 't1249_stylea', `        <aef:io>
${io(['<aef:input name="sfdc:Opportunity.Id" type="object" ref="nid:attr-opportunity-id" role="read" dataType="id"/>',
  '<aef:input name="sfdc:Opportunity.OwnerId" type="object" ref="nid:attr-opportunity-owner" role="read" dataType="reference"/>',
  '<aef:output name="tacton:Account.companyName" type="object" ref="nid:attr-account-company" role="write" dataType="string"/>'])}
        </aef:io>
`)}
${task('Task_empty', 'Notify', 't1249_empty', '')}
    <bpmn:endEvent id="End_1" name="End"/>
    <bpmn:sequenceFlow id="f1" sourceRef="Start_1" targetRef="Task_v11"/>
    <bpmn:sequenceFlow id="f2" sourceRef="Task_v11" targetRef="Task_v1"/>
    <bpmn:sequenceFlow id="f3" sourceRef="Task_v1" targetRef="Task_stylea"/>
    <bpmn:sequenceFlow id="f3b" sourceRef="Task_stylea" targetRef="Task_empty"/>
    <bpmn:sequenceFlow id="f4" sourceRef="Task_empty" targetRef="End_1"/>
  </bpmn:process>
</bpmn:definitions>
`;
// T-1304: stylea-step, greenfield's style A (v1 ref, role, dataType; synthetic values, nid: prefix undeclared)
// T-1301: stylea-edit / v1-edit open the io attributes editor (4th field: the edit toggles to click, in panel order);
// last, because an open editor stays open for the rest of that width.
const STATES = [['v11-step', 't1249_v11', 'I/O contract'], ['v1-step', 't1249_v1', 'I/O contract'], ['stylea-step', 't1249_stylea', 'I/O contract'], ['empty-step', 't1249_empty', 'I/O contract'], ['workflow', null, 'Mapping'],
  ['stylea-edit', 't1249_stylea', 'I/O contract', [0, 2]], ['v1-edit', 't1249_v1', 'I/O contract', [0]],
  // T-1301 review: the undeclared-prefix hint, typed into typeRef of the v1 step's first input (zz is not declared)
  ['hint-edit', 't1249_v1', 'I/O contract', { open: [0], set: { typeRef: 'zz:Thing' } }],
  // T-1305: a name longer than the panel is wide, so the wrap itself is visible (typed into the first name, not saved)
  ['longname', 't1249_v1', 'I/O contract', { name: [0, 'salesforce:OpportunityLineItem.QuoteLineItem.TradeInVehicle.RegistrationNumber'] }],
  // T-1302: the fields of an io in its editor (the v1.1 step's first output: three fields), and adding one (style A)
  ['fields-edit', 't1249_v11', 'I/O contract', { open: [2] }],
  ['field-add', 't1249_stylea', 'I/O contract', { open: [0], addField: true }]];
const WIDTHS = [[1024, 768], [1440, 900], [1920, 1080]];

async function main() {
  mkdirSync(OUT, { recursive: true });
  const doc = mkdtempSync(join(tmpdir(), 't1249s-doc-')), repo = mkdtempSync(join(tmpdir(), 't1249s-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html')); mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1249s-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const written = [];
  try {
    for (let i = 0; i < 100; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    for (const [w, h] of WIDTHS) {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
      await cmd('Page.navigate', { url: `${BASE}/designer.html` });
      await waitReady(cmd); await sleep(400);
      await ev(cmd, `adoptImportedXml(${JSON.stringify(MAP)}); typeof fitView==='function' && fitView(); true`);
      await sleep(300);
      for (const [name, uid, title, opens] of STATES) {
        const rect = await ev(cmd, `(function(){
          if (${JSON.stringify(uid)}) { var n = state.nodes.filter(function(x){ return x.uid === ${JSON.stringify(uid)}; })[0];
            selection = { kind: 'node', id: n.id }; multiSelect = new Set([n.id]); }
          else { selection = null; multiSelect = new Set(); }
          renderAll(); renderProperties();
          var spec = ${JSON.stringify(opens || [])}, op = Array.isArray(spec) ? spec : (spec.open || []);
          op.forEach(function(i){ var t = document.querySelectorAll('#properties .io-attrs-toggle')[i]; if (t && !t.classList.contains('open')) t.click(); });
          if (spec.addField) { var a = document.querySelector('#properties .io-attrs .io-field-add'); if (a) a.click(); }
          if (spec.name) {   // [row index, value]: type it into that io name, then re-render as an edit would
            var f = document.querySelectorAll('#properties .io-row .io-name')[spec.name[0]];
            if (f) { f.value = spec.name[1]; f.dispatchEvent(new Event('input', { bubbles: true })); renderProperties(); }
          }
          Object.keys(spec.set || {}).forEach(function(k){
            var c = document.querySelector('#properties .io-attrs [data-attr="' + k + '"]');
            if (c) { c.value = spec.set[k]; c.dispatchEvent(new Event('change', { bubbles: true })); }
          });
          var p = document.getElementById('properties');
          var sec = Array.from(p.querySelectorAll('.props-section')).filter(function(s){ var t = s.querySelector('.props-section-title'); return t && t.textContent.indexOf(${JSON.stringify(title)}) === 0; })[0];
          p.scrollTop = 0;
          if (sec) p.scrollTop = Math.max(0, sec.offsetTop - p.offsetTop - 8);
          var r = p.getBoundingClientRect();
          return { x: r.x, y: r.y, w: r.width, h: r.height, more: p.scrollTop + p.clientHeight < p.scrollHeight - 1, found: !!sec };
        })()`);
        await sleep(200);
        const shot = async (file, clip) => { const r = await cmd('Page.captureScreenshot', { format: 'png', ...(clip ? { clip: { ...clip, scale: 1 } } : {}) }); writeFileSync(join(OUT, file), Buffer.from(r.data, 'base64')); written.push(file); };
        await shot(`${name}-${w}.png`);
        await shot(`${name}-${w}-panel.png`, { x: rect.x, y: rect.y, width: rect.w, height: rect.h });
        if (rect.more) {
          await ev(cmd, `(function(){ var p = document.getElementById('properties'); p.scrollTop = p.scrollHeight; })()`); await sleep(150);
          await shot(`${name}-${w}-panel-end.png`, { x: rect.x, y: rect.y, width: rect.w, height: rect.h });
        }
        if (!rect.found && name !== 'empty-step') console.error(`warn: ${name}@${w}: section "${title}" not found`);
      }
    }
    console.log(JSON.stringify({ ok: true, out: OUT, files: written.length }));
  } catch (e) { console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e) })); process.exitCode = 1; }
  finally {
    try { cl && cl.close(); } catch (_) {} try { br.kill('SIGKILL'); } catch (_) {} try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
