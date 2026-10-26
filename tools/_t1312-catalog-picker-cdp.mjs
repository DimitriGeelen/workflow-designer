#!/usr/bin/env node
// _t1312-catalog-picker-cdp.mjs — T-1312 (arc-006): the ref field of the io editor offers a searchable picker over the
// project's field catalog (GET /api/field-catalog, greenfield's nid-attributes.json, format v1). Drives the REAL editor
// headless against the REAL reference server (tools/gallery-serve.py), whose repo holds the catalog or not:
//   a. no catalog (the server answers 404): no picker anywhere; the "use a ref from this map…" picker and the free-text ref
//      field are exactly as before;
//   b. a catalog: the open editor's ref row shows one search field; nothing is listed until something is typed;
//   c. typing matches every word against notation, label and ref; at most 8 hits; each shows notation and label;
//   d. picking a hit on a v1 io (no dataType) writes ref AND prefills dataType from the row; nothing else in the item moves;
//   e. picking a hit on a style-A io that has its own dataType writes ref only: the producer's dataType is kept;
//   f. every other step keeps its io bytes;
//   g. the search field and its hits lie inside the editor and are on top where a person clicks, at 1024 and 1440.
// T1312_SRC substitutes another designer file (e.g. the 0.29.0 source: b-g must go red, a stays green).
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
const SRC = process.env.T1312_SRC || join(REPO, 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const AEF = 'http://anchorpoint.framework/aef/extensions';
// A style-A step (greenfield's form: ref + role + dataType, one line) and a v1 step with no ref and no dataType.
const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="${AEF}" id="Definitions_t1312" targetNamespace="https://aef.anchorpoint.dev/workflows">
  <bpmn:process id="Process_t1312" isExecutable="true">
    <bpmn:extensionElements>
      <aef:workflowMeta id="t1312-catalog" version="1" schemaVersion="2" title="catalog picker" tier_default="1"/>
    </bpmn:extensionElements>
    <bpmn:startEvent id="Start_1" name="Start"/>
    <bpmn:serviceTask id="Task_a" name="Configure quote">
      <bpmn:extensionElements>
        <aef:uid value="t1312_a"/>
        <aef:io><aef:input type="object" name="sfdc:Opportunity.Id" ref="nid:attr-opportunity-id" role="read" dataType="id"/></aef:io>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:serviceTask id="Task_v1" name="Assign owner">
      <bpmn:extensionElements>
        <aef:uid value="t1312_v1"/>
        <aef:io>
          <aef:input name="owner" type="string" required="true"/>
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
// v1 catalog rows (the shape of greenfield's docs/views/nid-attributes.json; synthetic values). 12 rows so the 8-hit cap
// is reachable: "Account" matches 10 of them.
const ROWS = [
  { ref: 'nid:attr-salesforce-opportunity-owner', notation: 'sfdc:Opportunity.OwnerId', label: 'OwnerId (Salesforce Opportunity)', system: 'nid:app-salesforce', systemLabel: 'Salesforce', entity: 'nid:de-opportunity', dataType: 'reference', keyRole: '', sources: 1 },
  { ref: 'nid:attr-salesforce-opportunity-name', notation: 'sfdc:Opportunity.Name', label: 'Name (Salesforce Opportunity)', system: 'nid:app-salesforce', systemLabel: 'Salesforce', entity: 'nid:de-opportunity', dataType: 'string', keyRole: '', sources: 1 },
];
for (let i = 0; i < 10; i++) ROWS.push({ ref: 'nid:attr-tacton-account-f' + i, notation: '', label: 'field' + i + ' (Tacton Account)', system: 'nid:app-tacton', systemLabel: 'Tacton', entity: 'nid:de-account', dataType: '', keyRole: '', sources: 1 });
const CATALOG = { version: 1, generatedBy: 't1312 fixture', count: ROWS.length, attributes: ROWS };

const PAGE = `(function(){
  function stepIo(xml, uid){
    var parts = xml.split('<bpmn:extensionElements>');
    for (var i = 1; i < parts.length; i++) {
      var body = parts[i].split('</bpmn:extensionElements>')[0];
      if (body.indexOf('<aef:uid value="' + uid + '"') < 0) continue;
      var m = body.match(/<aef:io>[\\s\\S]*?<\\/aef:io>|<aef:io\\/>/); return m ? m[0] : null;
    }
    return null;
  }
  function editor(){   // open the editor of input 0 of the selected step, return it
    var p = document.getElementById('properties');
    var t = p.querySelector('.io-attrs-toggle');
    if (!t) return null;
    var ed = t.nextElementSibling;
    if (!ed || !ed.classList.contains('io-attrs')) { t.click(); t = p.querySelector('.io-attrs-toggle'); ed = t && t.nextElementSibling; }
    return ed && ed.classList.contains('io-attrs') ? ed : null;
  }
  window.__t1312 = { stepIo: stepIo };
  window.__open = function(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return buildBpmnXml(state); };
  window.__select = function(uid){
    var n = state.nodes.filter(function(x){ return x.uid === uid; })[0];
    selection = { kind: 'node', id: n.id }; multiSelect = new Set([n.id]); renderProperties();
    return !!n;
  };
  window.__picker = function(){
    var ed = editor(); if (!ed) return { editor: false };
    var s = ed.querySelectorAll('[data-pick="catalog"]');
    var refRow = ed.querySelector('[data-attr="ref"]'); refRow = refRow && refRow.closest('.io-attr');
    return { editor: true, searches: s.length, inRefRow: !!(s[0] && refRow && refRow.contains(s[0])),
             mapPick: !!ed.querySelector('select[data-pick="ref"]'), refField: !!ed.querySelector('textarea[data-attr="ref"]'),
             hits: Array.from(ed.querySelectorAll('.io-cat-hit')).map(function(h){ return { ref: h.dataset.ref, text: h.textContent }; }) };
  };
  window.__search = function(q){
    var ed = editor(); var s = ed && ed.querySelector('[data-pick="catalog"]'); if (!s) return 'no search field';
    s.value = q; s.dispatchEvent(new Event('input', { bubbles: true })); return 'ok';
  };
  window.__pick = function(ref){
    var ed = editor(); var h = ed && Array.from(ed.querySelectorAll('.io-cat-hit')).filter(function(x){ return x.dataset.ref === ref; })[0];
    if (!h) return 'no hit ' + ref; h.click(); return 'ok';
  };
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1312-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1312-repo-'));
  writeFileSync(join(doc, 'designer.html'), readFileSync(SRC, 'utf8'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1312-udd-');
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
    const load = async () => { await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(500); await E(PAGE); };
    const save = () => E('buildBpmnXml(state)');
    const io = (xml, uid) => E(`window.__t1312.stepIo(${JSON.stringify(xml)}, ${JSON.stringify(uid)})`);
    const fresh = async (uid) => { const x = await E(`window.__open(${JSON.stringify(MAP)})`); await E(`window.__select(${JSON.stringify(uid)})`); return x; };

    // a. no catalog: the server answers 404; the editor is exactly as before
    const r404 = await fetch(BASE + '/api/field-catalog');
    await load();
    await fresh('t1312_a');
    const a = await E('window.__picker()');
    legs.a = { status: r404.status, picker: a };
    if (r404.status !== 404) errs.push('a: the fixture server should answer 404 without a catalog, got ' + r404.status);
    if (!a.editor || a.searches !== 0 || !a.refField) errs.push('a: without a catalog the ref row changed: ' + JSON.stringify(a));

    // b. a catalog: one search field in the ref row, no hits before typing
    writeFileSync(join(repo, 'field-catalog.json'), JSON.stringify(CATALOG));
    await load();
    const base = await fresh('t1312_v1');
    const b = await E('window.__picker()');
    legs.b = b;
    if (b.searches !== 1 || !b.inRefRow || b.hits.length) errs.push('b: expected one catalog search field in the ref row and no hits yet: ' + JSON.stringify(b));

    // c. matching: every word, against notation, label and ref; at most 8
    await E(`window.__search('opportunity owner')`);
    const c1 = await E('window.__picker()');
    await E(`window.__search('account')`);
    const c2 = await E('window.__picker()');
    legs.c = { owner: c1.hits, account: c2.hits.length };
    if (c1.hits.length !== 1 || c1.hits[0].ref !== ROWS[0].ref || c1.hits[0].text.indexOf('sfdc:Opportunity.OwnerId') < 0 || c1.hits[0].text.indexOf('OwnerId (Salesforce Opportunity)') < 0)
      errs.push('c: "opportunity owner" should list exactly the OwnerId row with its notation and label: ' + JSON.stringify(c1.hits));
    if (c2.hits.length !== 8) errs.push('c: "account" matches 10 rows; at most 8 are listed, got ' + c2.hits.length);
    // h. a re-render (a startup loader settling, any edit) keeps what was typed and its hits
    await E('renderProperties()');
    const h1 = await E(`(function(){ var s = document.querySelector('#properties [data-pick="catalog"]'); return { value: s && s.value, hits: document.querySelectorAll('#properties .io-cat-hit').length }; })()`);
    legs.h = h1;
    if (!h1.value || h1.value !== 'account' || h1.hits !== 8) errs.push('h: a re-render lost the catalog search or its hits: ' + JSON.stringify(h1));

    // d. v1 io (no dataType): ref AND dataType from the row
    await E(`window.__search('opportunity owner')`);
    const dp1 = await E(`window.__pick(${JSON.stringify(ROWS[0].ref)})`);
    const dOut = await save();
    const dIo = await io(dOut, 't1312_v1');
    legs.d = { pick: dp1, io: dIo };
    if (!/^<aef:io>\s*<aef:input name="owner" type="string" required="true" ref="nid:attr-salesforce-opportunity-owner" dataType="reference"\/>\s*<\/aef:io>$/.test(dIo || ''))
      errs.push('d: picking on a v1 io should add ref and dataType, nothing else: ' + dIo);
    // f. the other step is byte-exact
    if ((await io(dOut, 't1312_a')) !== (await io(base, 't1312_a'))) errs.push('f: picking on one step changed another step\'s io');

    // e. style-A io with its own dataType: ref only, the producer's dataType kept
    await fresh('t1312_a');
    await E(`window.__search('opportunity name')`);
    const ep = await E(`window.__pick(${JSON.stringify(ROWS[1].ref)})`);
    const eIo = await io(await save(), 't1312_a');
    legs.e = { pick: ep, io: eIo };
    // an edited step's io block is written one item per line (the 0.28.0 rule); the ITEM must be exact, attribute order kept
    if (!/^<aef:io>\s*<aef:input type="object" name="sfdc:Opportunity\.Id" ref="nid:attr-salesforce-opportunity-name" role="read" dataType="id"\/>\s*<\/aef:io>$/.test(eIo || ''))
      errs.push('e: picking on a style-A io should change ref only and keep its dataType "id": ' + eIo);

    // g. geometry: the search field and its hits inside the editor, on top where a person clicks
    const geo = [];
    for (const [w, h] of [[1024, 768], [1440, 900]]) {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
      await fresh('t1312_v1'); await E(`window.__search('account')`);
      geo.push(await E(`(function(){
        var out = [], ed = document.querySelector('#properties .io-attrs'); if (!ed) return { w: ${w}, outside: ['no editor'] };
        var er = ed.getBoundingClientRect(), cs = ed.querySelectorAll('[data-pick="catalog"], .io-cat-hit');
        if (cs.length < 2) out.push('no catalog search field with hits to measure (' + cs.length + ')');   // never vacuous
        cs.forEach(function(c){
          c.scrollIntoView({ block: 'center' });
          var r = c.getBoundingClientRect();
          if (r.width < 1 || r.right > er.right + 0.5 || r.left < er.left - 0.5) out.push((c.className || c.tagName) + ' x ' + Math.round(r.left) + '..' + Math.round(r.right) + ' vs ' + Math.round(er.left) + '..' + Math.round(er.right));
          var hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
          if (!hit || (hit !== c && !c.contains(hit))) out.push((c.className || c.tagName) + ' not on top: ' + (hit ? (hit.className || hit.tagName) : 'nothing'));
        });
        return { w: ${w}, outside: out };
      })()`));
    }
    await cmd('Emulation.clearDeviceMetricsOverride');
    legs.g = geo;
    for (const g of geo) if (g.outside.length) errs.push(`g: at ${g.w} px: ` + g.outside.slice(0, 3).join(' | '));

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
