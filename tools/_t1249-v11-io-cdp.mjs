#!/usr/bin/env node
// _t1249-v11-io-cdp.mjs — T-1249 (slice 1 of T-1242): the designer SHOWS every mapping v1.1 io construct, read-only,
// and saves it byte-exactly. Standard: AEF's aef-bpmn-mapping-v1.1-io.md (T-4548); fixtures are its section-11 worked
// examples plus AEF's FULL case (test_t4549_aef_io_v11_roundtrip.py), wrapped in a minimal map in the designer's own
// layout. Drives the REAL editor runtime (parseBpmnXml -> buildBpmnXml, renderProperties) headless:
//   a. each v1.1 example map opens and saves with every <aef:io> block, and the process-level <aef:meta>
//      (mappingVersion, aef:prefixes), byte-identical; a second save equals the first;
//   b. every tracked .bpmn that carries aef:input/aef:output: io bytes unchanged after open + save;
//   c. greenfield's VZN-T1 v29 (client material, read in place, never printed): io bytes unchanged. Absent = not measured;
//   d. the io panel shows each construct of a v1.1 step, and the workflow panel mappingVersion and the prefixes
//      (asserted on DOM text), with no new input/select inside the v1.1 display (read-only);
//   e. a v1 io shows no v1.1 section, and its row is exactly the editable row it was before.
// T1249_SRC substitutes another designer file (e.g. the pre-T-1249 source). T1249_BITE=display runs a temp copy whose
// display function returns nothing: leg d must go red. Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn, execFileSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1249_SRC || join(REPO, 'src/aef-workflow-designer.html');
const BITE = process.env.T1249_BITE || '';
const VZN = process.env.T1249_VZN || join(REPO, '.context/working/intake-t4415/greenfield/VZN-T1-v29-nodoc.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// ── fixtures: the section-11 worked examples and AEF's FULL case, verbatim, one io per line block ──
const AEF = 'http://anchorpoint.framework/aef/extensions';
const V11_META = [
  '<aef:meta mappingVersion="1.1">',
  '  <aef:prefixes>',
  '    <aef:prefix name="sfdc" iri="https://example.org/sfdc#" system="sys:salesforce" kind="field"/>',
  '    <aef:prefix name="tacton" iri="https://example.org/tacton#" kind="type"/>',
  '  </aef:prefixes>',
  '</aef:meta>'];
const EX = {
  h042: ['<aef:output typeRef="tacton:Opportunity" operation="upsert">',
    '  <aef:field fieldRef="tacton:Opportunity.crmOppExtId" role="match"/>',
    '  <aef:field fieldRef="tacton:Opportunity.name" role="write"/>',
    '  <aef:field fieldRef="tacton:Opportunity.accountId" role="create"/>',
    '</aef:output>'],
  account: ['<aef:output typeRef="sfdc:Account" targetSystem="sys:salesforce" operation="create">',
    '  <aef:field fieldRef="sfdc:Account.Name" role="write"/>',
    '  <aef:field path="Phone" role="write"/>',
    '  <aef:field path="OwnerId" role="write" required="true"/>',
    '</aef:output>'],
  styleB: ['<aef:output typeRef="sfdc:Opportunity" operation="update">',
    '  <aef:field fieldRef="sfdc:Opportunity.Id" role="match"/>',
    '  <aef:expect path="StageName" const="Closed Won"/>',
    '</aef:output>'],
  deletes: ['<aef:output typeRef="sfdc:Contact" operation="update">',
    '  <aef:field fieldRef="sfdc:Contact.Id" role="match"/>',
    '  <aef:expect path="Status" const="archived"/>',
    '</aef:output>',
    '<aef:output typeRef="sfdc:Contact" operation="delete">',
    '  <aef:field fieldRef="sfdc:Contact.Id" role="match"/>',
    '  <aef:expect fieldRef="sfdc:Contact.Id" absent="true"/>',
    '</aef:output>'],
  full: ['<aef:input name="opp" typeRef="sf:Opportunity" sourceSystem="sys:crm" required="true" cardinality="one" conceptRef="biz:Deal" ref="nid:x" dataType="id">',
    '  <aef:field path="LineItems[]" cardinality="many"><aef:when path="Kind" const="TradeIn"/></aef:field>',
    '  <aef:expect path="Status"><aef:value>Won</aef:value><aef:value>Closed Won</aef:value></aef:expect>',
    '  <aef:expect path="Amount" minimum="10000" exclusiveMaximum="1e9" pattern="^[0-9]+$"/>',
    '  <aef:expect path="Notes" description="free text" ruleRef="rules:notes" ruleLanguage="shacl" present="true"/>',
    '  <aef:example path="Amount" value="12500"/>',
    '</aef:input>',
    '<aef:input fieldRef="sfdc:Opportunity.Id" role="read" type="ref"/>',
    '<aef:output schemaRef="https://example.org/s.json" operation="read" targetSystem="sys:erp"/>'],
};
const ind = (lines, n) => lines.map(l => ' '.repeat(n) + l).join('\n');
// A minimal map in the designer's own layout (process ext at 6, node ext at 8, io items at 10, io children at 12), so a
// byte comparison measures the io, not the designer's indentation. stepMeta: an optional step-level aef:meta line.
function v11Map(key, ioLines, opts = {}) {
  const meta = opts.noMeta ? '' : ind(V11_META, 6) + '\n';
  const stepMeta = opts.stepMeta ? `        ${opts.stepMeta}\n` : '';
  return `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="${AEF}" id="Definitions_${key}" targetNamespace="https://aef.anchorpoint.dev/workflows">
  <bpmn:process id="Process_${key}" isExecutable="true">
    <bpmn:extensionElements>
      <aef:workflowMeta id="${key}" version="1" schemaVersion="2" title="${key}" tier_default="1"/>
${meta}    </bpmn:extensionElements>
    <bpmn:startEvent id="Start_1" name="Start"/>
    <bpmn:serviceTask id="Task_1" name="Sync ${key}">
      <bpmn:extensionElements>
        <aef:uid value="t1249_${key}"/>
${stepMeta}        <aef:io>
${ind(ioLines, 10)}
        </aef:io>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:endEvent id="End_1" name="End"/>
    <bpmn:sequenceFlow id="f1" sourceRef="Start_1" targetRef="Task_1"/>
    <bpmn:sequenceFlow id="f2" sourceRef="Task_1" targetRef="End_1"/>
  </bpmn:process>
</bpmn:definitions>
`;
}
const FIXTURES = Object.entries(EX).map(([k, v]) => ({ key: k, xml: v11Map(k, v) }));
// leg d: a step with a step default (sourceSystem on the step's aef:meta) and an io whose system comes from a prefix
const DISPLAY = v11Map('display', [...EX.full, ...EX.h042, ...EX.styleB, ...EX.account.slice(0, 2), '</aef:output>',
  '<aef:input name="acct" fieldRef="sfdc:Account.Id" role="match"/>'], { stepMeta: '<aef:meta sourceSystem="sys:crm-default"/>' });
const V1 = v11Map('v1', ['<aef:input name="owner" type="string" required="true"/>', '<aef:output name="assignment" type="ref" ref="nid:x"/>'], { noMeta: true });

function trackedMaps() {
  const files = execFileSync('git', ['ls-files', '*.bpmn'], { cwd: REPO, encoding: 'utf8' }).split('\n').filter(Boolean);
  const seen = new Set(), out = [];
  for (const f of files) {
    const t = readFileSync(join(REPO, f), 'utf8');
    if (!/<aef:(input|output)\b/.test(t)) continue;
    const h = createHash('sha256').update(t).digest('hex');
    if (seen.has(h)) continue;
    seen.add(h); out.push({ key: f, xml: t });
  }
  return out;
}

const PAGE = `(function(){
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  var IO = /<aef:io>[\\s\\S]*?<\\/aef:io>|<aef:io\\/>/g;
  var PMETA = /<bpmn:process\\b[\\s\\S]*?<bpmn:extensionElements>([\\s\\S]*?)<\\/bpmn:extensionElements>/;
  function procMeta(x){ var m = strip(x).match(PMETA); return m ? (m[1].match(/<aef:meta\\b[\\s\\S]*?(?:\\/>|<\\/aef:meta>)/g) || []) : []; }
  function ioByStep(x){
    var o = {}, parts = strip(x).split('<bpmn:extensionElements>');
    for (var i = 1; i < parts.length; i++) {
      var body = parts[i].split('</bpmn:extensionElements>')[0], io = body.match(IO);
      if (!io) continue;
      // the step: the id of the BPMN element that owns this extensionElements, else its aef:uid
      var uid = body.match(/<aef:uid value="([^"]*)"/), owner = parts[i - 1].match(/<bpmn:\w+\b[^>]*?\sid="([^"]*)"[^>]*>\s*$/);
      var k = owner ? 'id:' + owner[1] : uid ? uid[1] : '#' + i;
      while (o[k] !== undefined) k += "'";
      o[k] = io.join('');
    }
    return o;
  }
  // a content-free description of how two io blocks differ (VZN-T1 is client material: never print its bytes)
  function kind(p, q){
    if (q === undefined) return 'dropped';
    if (p.replace(/>\\s+</g, '><') === q.replace(/>\\s+</g, '><')) return 'whitespace-between-elements';
    var tags = function(x){ return (x.match(/<aef:(input|output)\\b/g) || []).join(','); };
    if (tags(p) !== tags(q)) return 'io item order or count';
    var norm = function(x){ return x.replace(/<([^\\s>\\/]+)((?:\\s+[^\\s=>]+="[^"]*")*)\\s*(\\/?)>/g, function(m, t, at, sl){ return '<' + t + ' ' + (at.match(/[^\\s=]+="[^"]*"/g) || []).sort().join(' ') + sl + '>'; }).replace(/>\\s+</g, '><'); };
    if (norm(p) === norm(q)) return 'attribute order';
    return 'value or element (len ' + p.length + ' -> ' + q.length + ')';
  }
  window.__round = function(xml, withMeta){
    var r = { io: 0, ioDiff: [], meta: 0, metaDiff: false, second: true };
    state = parseBpmnXml(xml); refreshDisplayIds();
    // how much of the new state a map needs (a map the designer wrote should need none of it)
    r.kept = state.nodes.filter(function(n){ return n.io && n.io.kept; }).length;
    r.raw = state.nodes.reduce(function(c, n){ return c + ((n.io && n.io.inputs) || []).concat((n.io && n.io.outputs) || []).filter(function(i){ return i.raw; }).length; }, 0);
    r.procMeta = (state.procMetaKept || []).length;
    var out = buildBpmnXml(state);
    // io blocks keyed by their step's aef:uid (the designer may emit the steps in another order; that is not io bytes)
    var a = ioByStep(xml), b = ioByStep(out), ka = Object.keys(a);
    r.io = ka.length; r.outIo = Object.keys(b).length; r.sameKeys = ka.filter(function(k){ return k in b; }).length;
    if (ka.length !== Object.keys(b).length) r.ioDiff.push('count ' + ka.length + ' -> ' + Object.keys(b).length);
    if (r.sameKeys === ka.length) ka.forEach(function(k){ if (a[k] !== b[k]) r.ioDiff.push(kind(a[k], b[k])); });
    else {   // the designer re-identified the steps (a map with no aef:uid): compare the blocks as a sorted multiset
      var sa = ka.map(function(k){ return a[k]; }).sort(), sb = Object.keys(b).map(function(k){ return b[k]; }).sort();
      sa.forEach(function(x, i){ if (x !== sb[i]) r.ioDiff.push(kind(x, sb[i])); });
      r.pairing = 'multiset';
    }
    if (withMeta) { var ma = procMeta(xml), mb = procMeta(out); r.meta = ma.length; r.metaDiff = ma.join('') !== mb.join(''); }
    state = parseBpmnXml(out); refreshDisplayIds();
    r.second = strip(buildBpmnXml(state)) === strip(out);
    return r;
  };
  window.__show = function(xml, uid){
    state = parseBpmnXml(xml); refreshDisplayIds();
    var n = state.nodes.filter(function(x){ return x.uid === uid; })[0];
    selection = { kind: 'node', id: n.id }; multiSelect = new Set([n.id]); renderProperties();
    var p = document.getElementById('properties');
    var v11 = Array.from(p.querySelectorAll('.io-v11'));
    var r = { text: p.innerText, v11: v11.length, v11Text: v11.map(function(e){ return e.innerText; }).join('\\n'),
              v11Inputs: v11.reduce(function(s, e){ return s + e.querySelectorAll('input,select,textarea,[contenteditable="true"]').length; }, 0),
              rows: Array.from(p.querySelectorAll('.io-row')).map(function(r){ return r.querySelectorAll('input,select').length; }) };
    selection = null; multiSelect = new Set(); renderProperties();
    r.wfText = p.innerText; r.wfV11 = p.querySelectorAll('.wf-v11').length;
    return r;
  };
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1249-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1249-repo-'));
  let html = readFileSync(SRC, 'utf8');
  if (BITE === 'display') {
    const before = html;
    html = html.replace(/function ioV11Block\(([^)]*)\) \{/, 'function ioV11Block($1) { return null;');
    html = html.replace(/function wfV11Section\(([^)]*)\) \{/, 'function wfV11Section($1) { return null;');
    if (html === before) { console.log(JSON.stringify({ ok: false, error: 'bite: display functions not found' })); process.exitCode = 2; return; }
  }
  writeFileSync(join(doc, 'designer.html'), html);
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1249-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const legs = {}, errs = [];
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, PAGE);
    const round = (xml, withMeta) => ev(cmd, `window.__round(${JSON.stringify(xml)}, ${!!withMeta})`);

    // a. section-11 examples + FULL
    legs.a = { maps: 0, io: 0, failed: [] };
    for (const f of FIXTURES) {
      const r = await round(f.xml, true);
      legs.a.maps++; legs.a.io += r.io;
      if (r.ioDiff.length || r.metaDiff || r.meta !== 1 || !r.second) legs.a.failed.push({ key: f.key, ioDiff: r.ioDiff, metaKept: r.meta === 1 && !r.metaDiff, second: r.second });
    }
    if (legs.a.failed.length) errs.push('a: ' + legs.a.failed.length + ' v1.1 example map(s) changed io or process aef:meta bytes');

    // b. tracked maps
    legs.b = { maps: 0, io: 0, failed: [] };
    for (const f of trackedMaps()) {
      const r = await round(f.xml, false);
      legs.b.maps++; legs.b.io += r.io;
      if (r.kept || r.raw || r.procMeta) legs.b.usesNewState = (legs.b.usesNewState || []).concat([{ key: f.key, keptBlocks: r.kept, rawItems: r.raw, procMeta: r.procMeta }]);
      if (r.ioDiff.length) legs.b.failed.push({ key: f.key, ioDiff: r.ioDiff.slice(0, 5) });
    }
    if (!legs.b.maps) errs.push('b: no tracked map with io found');
    if (legs.b.failed.length) errs.push('b: ' + legs.b.failed.length + ' tracked map(s) changed io bytes');

    // c. VZN-T1 (client material: counts only, nothing from the file is printed)
    if (existsSync(VZN)) {
      const r = await round(readFileSync(VZN, 'utf8'), false);
      legs.c = { measured: true, ioBlocks: r.io, keptBlocks: r.kept, rawItems: r.raw, changedBlocks: r.ioDiff.length, how: Array.from(new Set(r.ioDiff)), outIo: r.outIo, pairing: r.pairing || 'by step', second: r.second };
      if (r.ioDiff.length || !r.io) errs.push('c: VZN-T1 io bytes changed (' + r.ioDiff.length + ' block(s))');
    } else legs.c = { measured: false, note: 'VZN-T1 not present: not measured' };

    // d. display
    const d = await ev(cmd, `window.__show(${JSON.stringify(DISPLAY)}, 't1249_display')`);
    const want = [
      'typeRef', 'sf:Opportunity', 'sourceSystem', 'sys:crm', 'cardinality', 'one', 'conceptRef', 'biz:Deal',
      'fieldRef', 'sfdc:Opportunity.Id', 'role', 'read', 'schemaRef', 'https://example.org/s.json', 'operation', 'upsert',
      'targetSystem', 'sys:erp', 'sys:salesforce', 'derived', 'sys:crm-default', 'step default',
      'LineItems[]', 'when Kind const TradeIn', 'tacton:Opportunity.crmOppExtId', 'match', 'create',
      'StageName', 'Status', 'enum Won, Closed Won', 'minimum 10000', 'exclusiveMaximum 1e9', 'pattern ^[0-9]+$',
      'present true', 'ruleRef rules:notes', 'example', 'Amount', '12500', 'field', 'expect'];
    const miss = want.filter(w => d.v11Text.indexOf(w) < 0);
    const wfWant = ['mappingVersion', '1.1', 'sfdc', 'https://example.org/sfdc#', 'sys:salesforce', 'field', 'tacton', 'https://example.org/tacton#', 'type'];
    const wfMiss = wfWant.filter(w => d.wfText.indexOf(w) < 0);
    legs.d = { v11Blocks: d.v11, missing: miss, wfMissing: wfMiss, editableInV11: d.v11Inputs, wfV11: d.wfV11 };
    if (d.v11 < 5) errs.push('d: expected a v1.1 display on each of the 5+ v1.1 io, saw ' + d.v11);
    if (miss.length) errs.push('d: io panel does not show ' + miss.join(' | '));
    if (!d.wfV11 || wfMiss.length) errs.push('d: workflow panel does not show mappingVersion/prefixes (' + wfMiss.join(' | ') + ')');
    if (d.v11Inputs) errs.push('d: the v1.1 display contains ' + d.v11Inputs + ' editable control(s)');

    // e. v1 io: no v1.1 section, rows unchanged (name input + type select (+ req checkbox))
    const e = await ev(cmd, `window.__show(${JSON.stringify(V1)}, 't1249_v1')`);
    legs.e = { v11Blocks: e.v11, rows: e.rows, wfV11: e.wfV11 };
    if (e.v11 || e.wfV11) errs.push('e: a v1 map shows a v1.1 section');
    if (JSON.stringify(e.rows) !== JSON.stringify([3, 2])) errs.push('e: v1 io rows changed shape ' + JSON.stringify(e.rows));

    const ok = errs.length === 0;
    console.log(JSON.stringify({ ok, src: SRC, bite: BITE || null, errs, legs }, null, 2));
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
