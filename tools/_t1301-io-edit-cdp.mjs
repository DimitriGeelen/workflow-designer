#!/usr/bin/env node
// _t1301-io-edit-cdp.mjs — T-1301 (slice 2 of T-1242, arc-006): the io attributes are EDITABLE in the properties panel, and
// a save writes exactly the edit. Drives the REAL editor runtime headless (parseBpmnXml, renderProperties, DOM events on the
// editor's own controls, buildBpmnXml):
//   a. model: an attribute added to an io item in RAW layout (its source attribute order differs from the canonical one)
//      is written on save. Before T-1301 the raw path wrote only the source's order list, so the new attribute was dropped;
//   b. UI: each attribute (ref, fieldRef, typeRef, schemaRef, conceptRef, role, operation, cardinality, sourceSystem /
//      targetSystem, dataType) is set through its control; the saved item gains exactly that attribute, everything else in
//      the item and every other step is unchanged;
//   c. UI: clearing a control removes exactly that attribute;
//   d. editing a greenfield style-A item (raw one-line layout) changes only the edited attribute; untouched steps byte-exact;
//   e. no silent upgrade: setting v1.1 attributes adds no mappingVersion and no aef:prefixes;
//   f. a CURIE whose prefix the map does not declare shows a hint; a declared one does not;
//   g. the ref field offers the ref values already in the map (datalist);
//   h. every io row has an edit toggle, closed by default (the released read-only summary unchanged); opening it shows
//      the controls; open + select + save with no edit is unchanged.
// T1301_SRC substitutes another designer file (e.g. the pre-T-1301 source: leg a must go red, b-h report no editor).
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
const SRC = process.env.T1301_SRC || join(REPO, 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const AEF = 'http://anchorpoint.framework/aef/extensions';
// Two steps: a style-A step written the way greenfield writes it (its io on one line, RAW attribute order: type before
// name on the first item), and a v1 step. PFX_META declares one prefix (sfdc, kind field).
const MAP = (meta) => `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="${AEF}" id="Definitions_t1301" targetNamespace="https://aef.anchorpoint.dev/workflows">
  <bpmn:process id="Process_t1301" isExecutable="true">
    <bpmn:extensionElements>
      <aef:workflowMeta id="t1301-io-edit" version="1" schemaVersion="2" title="io edit" tier_default="1"/>
${meta}    </bpmn:extensionElements>
    <bpmn:startEvent id="Start_1" name="Start"/>
    <bpmn:serviceTask id="Task_a" name="Configure quote">
      <bpmn:extensionElements>
        <aef:uid value="t1301_a"/>
        <aef:io><aef:input type="object" name="sfdc:Opportunity.Id" ref="nid:attr-opportunity-id" role="read" dataType="id"/><aef:output name="tacton:Account.companyName" type="object" ref="nid:attr-account-company" role="write"/></aef:io>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:serviceTask id="Task_v1" name="Assign owner">
      <bpmn:extensionElements>
        <aef:uid value="t1301_v1"/>
        <aef:io>
          <aef:input name="owner" type="string" required="true"/>
          <aef:output name="assignment" type="ref"/>
        </aef:io>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:endEvent id="End_1" name="End"/>
    <bpmn:sequenceFlow id="f1" sourceRef="Start_1" targetRef="Task_a"/>
    <bpmn:sequenceFlow id="f2" sourceRef="Task_a" targetRef="Task_v1"/>
    <bpmn:sequenceFlow id="f3" sourceRef="Task_v1" targetRef="End_1"/>
  </bpmn:process>
</bpmn:definitions>
`;
const NO_META = MAP('');
const PFX_META = MAP('      <aef:meta>\n        <aef:prefixes>\n          <aef:prefix name="sfdc" iri="https://example.org/sfdc#" kind="field"/>\n        </aef:prefixes>\n      </aef:meta>\n');

const PAGE = `(function(){
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function stepIo(x, uid){   // the <aef:io> block of the step whose aef:uid is uid
    var parts = strip(x).split('<bpmn:extensionElements>');
    for (var i = 1; i < parts.length; i++) {
      var body = parts[i].split('</bpmn:extensionElements>')[0];
      if (body.indexOf('<aef:uid value="' + uid + '"') < 0) continue;
      var m = body.match(/<aef:io>[\\s\\S]*?<\\/aef:io>|<aef:io\\/>/); return m ? m[0] : null;
    }
    return null;
  }
  function items(block){   // [{tag, attrs:{k:v}, order:[k]}] of the io items in a block
    var out = [], re = /<aef:(input|output)\\b([^>]*?)\\/?>/g, m;
    while ((m = re.exec(block || ''))) {
      var a = {}, order = [], ar = /([^\\s=]+)="([^"]*)"/g, n;
      while ((n = ar.exec(m[2]))) { a[n[1]] = n[2]; order.push(n[1]); }
      out.push({ tag: m[1], attrs: a, order: order });
    }
    return out;
  }
  function block(kind){
    var p = document.getElementById('properties');
    return Array.from(p.querySelectorAll('.io-block')).filter(function(x){ var l = x.querySelector('.field-label'); return l && l.textContent.indexOf(kind) === 0; })[0];
  }
  window.__t1301 = { stepIo: stepIo, items: items };
  window.__open = function(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return buildBpmnXml(state); };
  window.__select = function(uid){
    var n = state.nodes.filter(function(x){ return x.uid === uid; })[0];
    selection = { kind: 'node', id: n.id }; multiSelect = new Set([n.id]); renderProperties();
    return !!n;
  };
  // the editor controls of io row #idx ('inputs'|'outputs'), keyed by attribute name; opens the editor if asked
  window.__controls = function(kind, idx, open){
    var b = block(kind);
    if (!b) return { found: false };
    var rows = Array.from(b.querySelectorAll('.io-attrs-toggle'));
    var t = rows[idx];
    var ed = t ? t.nextElementSibling : null;
    if (ed && !ed.classList.contains('io-attrs')) ed = null;
    if (open && t && !ed) { t.click(); return window.__controls(kind, idx, false); }
    var r = { found: true, toggles: rows.length, open: !!ed, keys: [], hints: [] };
    if (ed) {
      ed.querySelectorAll('[data-attr]').forEach(function(c){ if (c.matches('input,select,textarea')) r.keys.push(c.dataset.attr); });
      ed.querySelectorAll('.io-attr-hint').forEach(function(h){ if (h.textContent.trim()) r.hints.push(h.dataset.attr + ': ' + h.textContent.trim()); });
      var pk = ed.querySelector('select[data-pick="ref"]');
      r.refList = pk ? Array.from(pk.options).map(function(o){ return o.value; }).filter(Boolean) : null;
      // a text value must be shown whole: a wrapping field as tall as its content (T-1301 review: clipped refs)
      r.clipped = Array.from(ed.querySelectorAll('textarea')).filter(function(t){ return t.value && t.scrollHeight > t.clientHeight + 1; }).map(function(t){ return t.dataset.attr; });
    }
    return r;
  };
  window.__set = function(kind, idx, attr, value){   // through the control, as a person would
    window.__controls(kind, idx, true);
    var b = block(kind), t = b.querySelectorAll('.io-attrs-toggle')[idx], ed = t && t.nextElementSibling;
    var c = !ed ? null : attr === 'ref:pick' ? ed.querySelector('select[data-pick="ref"]')
      : ed.querySelector('input[data-attr="' + attr + '"], select[data-attr="' + attr + '"], textarea[data-attr="' + attr + '"]');
    if (!c) return 'no control for ' + attr;
    c.value = value;
    if (c.tagName !== 'SELECT') c.dispatchEvent(new Event('input', { bubbles: true }));
    c.dispatchEvent(new Event('change', { bubbles: true }));
    return 'ok';
  };
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1301-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1301-repo-'));
  writeFileSync(join(doc, 'designer.html'), readFileSync(SRC, 'utf8'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1301-udd-');
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
    const E = (js) => ev(cmd, js);
    const items = (xml, uid) => E(`window.__t1301.items(window.__t1301.stepIo(${JSON.stringify(xml)}, ${JSON.stringify(uid)}))`);
    const io = (xml, uid) => E(`window.__t1301.stepIo(${JSON.stringify(xml)}, ${JSON.stringify(uid)})`);
    const save = () => E('buildBpmnXml(state)');
    const fresh = async (xml, uid) => { await E(`window.__open(${JSON.stringify(xml)})`); await E(`window.__select(${JSON.stringify(uid)})`); };

    // a. model: add an attribute to the raw-layout item (type before name), save
    await E(`window.__open(${JSON.stringify(NO_META)})`);
    const aOut = await E(`(function(){ var n = state.nodes.filter(function(x){ return x.uid === 't1301_a'; })[0];
      var it = n.io.inputs[0]; it.extra = (it.extra || []).concat([['operation', 'read']]); return buildBpmnXml(state); })()`);
    const aItem = (await items(aOut, 't1301_a'))[0] || { attrs: {}, order: [] };
    legs.a = { order: aItem.order, operation: aItem.attrs.operation || null };
    if (aItem.attrs.operation !== 'read') errs.push('a: an attribute added to a raw-layout io item is not written on save');
    if (aItem.order.slice(0, 5).join(',') !== 'type,name,ref,role,dataType') errs.push('a: the raw item lost its own attribute order: ' + aItem.order.join(','));

    // b/c. UI: set, then clear, each attribute through its control (input 0 of the style-A step)
    const base = await E(`window.__open(${JSON.stringify(NO_META)})`);
    const baseA = await items(base, 't1301_a'), baseV1 = await io(base, 't1301_v1');
    await E(`window.__select('t1301_a')`);
    const c0 = await E(`window.__controls('inputs', 0, true)`);
    const want = ['ref', 'fieldRef', 'typeRef', 'schemaRef', 'conceptRef', 'role', 'operation', 'cardinality', 'sourceSystem', 'dataType'];
    legs.b = { controls: c0.keys || [], set: {}, cleared: {} };
    const missingCtl = want.filter(k => (c0.keys || []).indexOf(k) < 0);
    if (!c0.found || missingCtl.length) errs.push('b: io editor lacks controls for ' + (missingCtl.join(', ') || '(no editor)'));
    if ((c0.keys || []).indexOf('targetSystem') >= 0) errs.push('b: an INPUT offers targetSystem');
    const VAL = { ref: 'nid:attr-x', fieldRef: 'sfdc:Opportunity.Id', typeRef: 'sfdc:Opportunity', schemaRef: 'https://example.org/s.json',
                  conceptRef: 'biz:Deal', role: 'match', operation: 'upsert', cardinality: 'many', sourceSystem: 'sys:crm', dataType: 'reference' };
    for (const k of want) {
      if ((c0.keys || []).indexOf(k) < 0) continue;
      await fresh(NO_META, 't1301_a');
      const r = await E(`window.__set('inputs', 0, ${JSON.stringify(k)}, ${JSON.stringify(VAL[k])})`);
      const out = await save(), its = await items(out, 't1301_a'), it = its[0];
      const before = baseA[0].attrs, changed = Object.keys(Object.assign({}, before, it.attrs)).filter(x => before[x] !== it.attrs[x]);
      legs.b.set[k] = changed.join(',');
      if (r !== 'ok' || it.attrs[k] !== VAL[k] || changed.length !== 1 || changed[0] !== k) errs.push(`b: setting ${k} changed [${changed}] (want exactly ${k}=${VAL[k]})`);
      if (JSON.stringify(its[1]) !== JSON.stringify(baseA[1])) errs.push(`b: setting ${k} on input 0 changed output 0`);
      if ((await io(out, 't1301_v1')) !== baseV1) errs.push(`b: setting ${k} changed the untouched v1 step's io bytes`);
      // c. clear the control: the attribute goes, nothing else moves
      await E(`window.__set('inputs', 0, ${JSON.stringify(k)}, '')`);
      const it2 = (await items(await save(), 't1301_a'))[0];
      legs.b.cleared[k] = it2.attrs[k] === undefined;
      if (it2.attrs[k] !== undefined) errs.push(`c: clearing ${k} left ${k}="${it2.attrs[k]}"`);
      if (Object.keys(before).filter(x => x !== k).some(x => it2.attrs[x] !== before[x])) errs.push(`c: clearing ${k} changed another attribute`);
    }
    // outputs offer targetSystem, not sourceSystem
    await fresh(NO_META, 't1301_a');
    const co = await E(`window.__controls('outputs', 0, true)`);
    legs.b.outputControls = co.keys || [];
    if ((co.keys || []).indexOf('targetSystem') < 0 || (co.keys || []).indexOf('sourceSystem') >= 0) errs.push('b: an OUTPUT must offer targetSystem and not sourceSystem');

    // d. style A edited: role read -> match on input 0; only that attribute moves, raw order kept, other step byte-exact
    await fresh(NO_META, 't1301_a');
    await E(`window.__set('inputs', 0, 'role', 'match')`);
    const dOut = await save(), dIt = (await items(dOut, 't1301_a'))[0];
    legs.d = { order: dIt.order, role: dIt.attrs.role };
    if (dIt.attrs.role !== 'match' || dIt.order.join(',') !== baseA[0].order.join(',')) errs.push('d: editing role on a raw style-A item moved its attributes: ' + dIt.order.join(','));
    if ((await io(dOut, 't1301_v1')) !== baseV1) errs.push('d: the untouched v1 step changed');

    // e. no silent upgrade
    await fresh(NO_META, 't1301_a');
    await E(`window.__set('inputs', 0, 'typeRef', 'sfdc:Opportunity')`);
    await E(`window.__set('inputs', 0, 'operation', 'update')`);
    const eOut = await save();
    legs.e = { mappingVersion: /mappingVersion=/.test(eOut), prefixes: /<aef:prefixes/.test(eOut) };
    if (legs.e.mappingVersion || legs.e.prefixes) errs.push('e: setting v1.1 attributes added mappingVersion or aef:prefixes');

    // f. undeclared prefix hint (typeRef zz:Thing) vs declared (sfdc in PFX_META)
    await fresh(NO_META, 't1301_a');
    await E(`window.__set('inputs', 0, 'typeRef', 'zz:Thing')`);
    const fU = await E(`window.__controls('inputs', 0, true)`);
    await fresh(PFX_META, 't1301_a');
    await E(`window.__set('inputs', 0, 'fieldRef', 'sfdc:Opportunity.Id')`);
    const fD = await E(`window.__controls('inputs', 0, true)`);
    legs.f = { undeclared: fU.hints || [], declared: fD.hints || [] };
    if (!(fU.hints || []).some(h => h.indexOf('typeRef') === 0 && h.indexOf('zz') >= 0)) errs.push('f: no hint for the undeclared prefix zz on typeRef');
    if ((fD.hints || []).some(h => h.indexOf('fieldRef') === 0)) errs.push('f: a hint on fieldRef although sfdc is declared');

    // g. ref suggestions: the OTHER refs already in the map are offered, and picking one sets ref; long values shown whole
    await fresh(NO_META, 't1301_a');
    const g = await E(`window.__controls('inputs', 0, true)`);
    const gSet = await E(`window.__set('inputs', 0, 'ref:pick', 'nid:attr-account-company')`);
    const gIt = (await items(await save(), 't1301_a'))[0];
    await fresh(NO_META, 't1301_a');
    await E(`window.__set('inputs', 0, 'ref', 'nid:attr-a-very-long-producer-attribute-identifier-that-cannot-fit')`);
    const gLong = await E(`window.__controls('inputs', 0, true)`);
    legs.g = { refList: g.refList, picked: gIt.attrs.ref, clipped: gLong.clipped };
    if (!g.refList || g.refList.indexOf('nid:attr-account-company') < 0 || g.refList.indexOf('nid:attr-opportunity-id') >= 0)
      errs.push('g: the ref picker should offer the map\'s other refs (not the current one): ' + JSON.stringify(g.refList));
    if (gSet !== 'ok' || gIt.attrs.ref !== 'nid:attr-account-company') errs.push('g: picking a ref from the map did not set it');
    if (!gLong.clipped || gLong.clipped.length) errs.push('g: a long value is clipped in its field: ' + JSON.stringify(gLong.clipped));

    // h. a closed toggle on every io (v1 and style A); opening shows controls; open + select + save with no edit changes nothing
    await fresh(NO_META, 't1301_v1');
    const hV1 = await E(`window.__controls('inputs', 0, false)`);
    await E(`window.__select('t1301_a')`);
    const hA = await E(`window.__controls('inputs', 0, false)`);
    const hAo = await E(`window.__controls('inputs', 0, true)`);
    const hOut = await save();
    legs.h = { v1Open: hV1.open, v1Toggles: hV1.toggles, styleAOpen: hA.open, styleAToggles: hA.toggles, openedKeys: (hAo.keys || []).length };
    if (hV1.open || !hV1.toggles) errs.push('h: a v1 io should show a closed edit toggle');
    if (hA.open || hA.toggles !== 1) errs.push('h: a style-A input should show one closed edit toggle (the released summary unchanged)');
    if (!hAo.open || !(hAo.keys || []).length) errs.push('h: opening the toggle shows no controls');
    if ((await io(hOut, 't1301_v1')) !== baseV1 || JSON.stringify(await items(hOut, 't1301_a')) !== JSON.stringify(baseA)) errs.push('h: open + select + save with no edit changed io');

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
