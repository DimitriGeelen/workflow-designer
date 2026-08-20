#!/usr/bin/env node
// _t566-note-field-cdp.mjs — `note` is authorable, and nothing the document carries is invisible.
//
// THE DEFECT. The Extensions panel iterates AEF_FIELDS[n.type] (src:5669) and renders one
// control per listed key. Anything the whitelist does not name is dropped silently — no
// readout, no count. `note` is in the export metaKeys set (src:9424), so the editor stores
// and re-emits it faithfully and shows it nowhere. Reported independently by 999-AEF
// (T-2974 defect 1) and 001-CashWeb (their T-064: 27 nodes of API references, auth rules,
// call lines and pseudo code). Measured over 91 bpmn files / 714 aef:meta values: 305
// (42.7%) sit outside AEF_FIELDS across 14 distinct keys; `note` is 92 of them.
//
// WHY CDP AND NOT SOURCE-READING (PL-148). Every leg here could have been written as a grep
// over AEF_FIELDS, and every one of those greps would assert that the fix is in the FILE.
// Leg 2 is the only kind of evidence that separates "the table lists note" from "an author
// can type into it and the bytes change": it drives the real input event on the real panel
// and then reads the exported XML. The probe loads the editor from a temp docroot; it never
// touches the registry or the running gallery.
//
// LEG 6 IS THE ONE THAT WOULD HAVE BEEN MISSED. `note` rides an XML ATTRIBUTE, and attribute
// -value normalisation collapses a literal newline to a space — so "multi-line note" is a
// claim about escAttr, not about the panel. escAttr already emits &#10; (src:9437). That is
// load-bearing for the reporter's actual content and is asserted rather than assumed.
//
// --src <path> runs against an alternate editor build so the teeth harness can mutate a copy
// in a tmpdir. Exit 0 = all legs pass, 1 = a leg failed, 2 = misconfigured (NOT a pass).
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const argi = process.argv.indexOf('--src');
const EDITOR = argi > -1 ? process.argv[argi + 1] : join(REPO, 'src', 'aef-workflow-designer.html');

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 20000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof renderProperties==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 25000) throw new Error('editor not ready'); await sleep(150); } }

// The note the reporter actually has: multi-line, with an API path, a quote and an ampersand.
const NOTE = 'GET /api/v1/orders/{id}\nAuth: bearer, scope="orders:read"\nRetry 3x & backoff';
// An unlisted key on the SAME node. `terminalKind` and `state` are both real corpus keys
// (60 and 56 occurrences) and neither is in AEF_FIELDS for any type.
const FIXTURE = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:aef="http://anchorpoint.framework/aef/extensions" id="d1" targetNamespace="http://x">
  <bpmn:process id="Process_t566" isExecutable="false">
    <bpmn:serviceTask id="T1" name="Fetch orders">
      <bpmn:extensionElements>
        <aef:uid value="u-t566-1"/>
        <aef:position x="200.0" y="140.0"/>
        <aef:meta tier="2" note="${NOTE.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/\n/g, '&#10;')}" terminalKind="ok" state="active"/>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="Di_1"><bpmndi:BPMNPlane id="Pl_1" bpmnElement="Process_t566">
    <bpmndi:BPMNShape id="S_T1" bpmnElement="T1"><dc:Bounds x="200" y="140" width="120" height="64"/></bpmndi:BPMNShape>
  </bpmndi:BPMNPlane></bpmndi:BPMNDiagram>
</bpmn:definitions>`;

// Selects the fixture node and renders the panel, then reports what the panel actually shows.
// Anchored on the FIELD LABEL, not on the node name: the node's name appears in the header
// too, and a window anchored there can slice past the field under test (the trap that cost
// T-569 a control run).
const PANEL = `(function(){
  var n = state.nodes.find(function(x){ return x.id === 'T1' || x.uid === 'u-t566-1' || x.name === 'Fetch orders'; });
  if (!n) return { err: 'fixture node absent; ids present = ' + JSON.stringify(state.nodes.map(function(x){ return { id: x.id, name: x.name, aef: x.aef }; })) };
  window.__t566id = n.id;
  selection = { kind: 'node', id: n.id };
  renderProperties();
  var props = document.getElementById('properties');
  var labels = Array.prototype.slice.call(props.querySelectorAll('.field-label'));
  function rowFor(text){
    for (var i=0;i<labels.length;i++){
      // textContent includes the hint span; match on the leading label word only.
      if (labels[i].childNodes[0] && String(labels[i].childNodes[0].nodeValue||'').trim() === text) return labels[i].parentNode;
    }
    return null;
  }
  var noteRow = rowFor('Note');
  var noteEl = noteRow ? noteRow.querySelector('textarea, input') : null;
  // The disclosure section: find a section whose heading starts with 'Other extensions'.
  var heads = Array.prototype.slice.call(props.querySelectorAll('*'));
  var otherSec = null;
  for (var j=0;j<heads.length;j++){
    var t = heads[j].childNodes[0] && heads[j].childNodes[0].nodeValue;
    if (t && String(t).indexOf('Other extensions') === 0) { otherSec = heads[j].closest('.section') || heads[j].parentNode; break; }
  }
  var disclosed = {};
  var editable = 0;
  if (otherSec) {
    var rows = Array.prototype.slice.call(otherSec.querySelectorAll('.field'));
    rows.forEach(function(r){
      var l = r.querySelector('.field-label'), v = r.querySelector('.field-input');
      // Read .value when the row carries a control and .textContent when it is a readout.
      // Without this the "is it editable?" leg and the "is it disclosed?" leg would both
      // redden for an editable disclosure, and the two mutants would be indistinguishable.
      if (l && v) disclosed[String(l.textContent).trim()] = (v.value !== undefined && v.value !== '') ? String(v.value) : String(v.textContent);
    });
    editable = otherSec.querySelectorAll('input, textarea, select').length;
  }
  return {
    noteFound: !!noteEl,
    noteTag: noteEl ? noteEl.tagName.toLowerCase() : null,
    noteValue: noteEl ? noteEl.value : null,
    aefNote: n.aef ? n.aef.note : null,
    otherFound: !!otherSec,
    disclosed: disclosed,
    editableInOther: editable
  };
})()`;

async function main() {
  const out = [];
  let npass = 0, nfail = 0;
  const report = (ok, name, detail) => { ok ? npass++ : nfail++; out.push(`${ok ? 'PASS' : 'FAIL'}  ${name} — ${detail}`); };

  if (!existsSync(EDITOR)) { console.log('CANNOT RUN: editor missing: ' + EDITOR); return 2; }
  if (!existsSync(SERVER)) { console.log('CANNOT RUN: server missing: ' + SERVER); return 2; }

  const doc = mkdtempSync(join(tmpdir(), 't566-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't566-repo-'));
  const udd = mkdtempSync(join(tmpdir(), 't566-udd-'));
  copyFileSync(EDITOR, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  writeFileSync(join(doc, 'rendered', 't566.bpmn'), FIXTURE);
  mkdirSync(join(repo, 'examples', 'aef-processes', 'rendered'), { recursive: true });
  writeFileSync(join(repo, 'examples', 'aef-processes', 'rendered', 't566.bpmn'), FIXTURE);

  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  let chrome; try { chrome = findChrome(); } catch (e) { console.log('CANNOT RUN: ' + e.message); py.kill(); return 2; }
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false;
    for (let i = 0; i < 80; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    // OBS-304: a single /json query races Chromium's page-target registration under load.
    let page = null;
    for (let i = 0; i < 40 && !page; i++) {
      try { page = (await (await fetch(`http://127.0.0.1:${dp}/json`)).json()).find(t => t.type === 'page'); } catch (_) {}
      if (!page) await sleep(150);
    }
    if (!page) throw new Error('no page target after retries');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: BASE + '/designer.html?load=' + encodeURIComponent('rendered/t566.bpmn') });
    await waitReady(cmd); await sleep(500);

    const p = await ev(cmd, PANEL);
    if (p.err) throw new Error(p.err);

    // ── Leg 1: the Note control exists and is a textarea (multi-line by construction) ──
    report(p.noteFound && p.noteTag === 'textarea', 'note-field',
      p.noteFound ? `rendered as <${p.noteTag}>` : 'NO Note control in the Extensions panel');

    // ── Leg 2: it shows the document's value, not an empty box ──
    report(p.noteValue === NOTE, 'note-reads',
      p.noteValue === NOTE ? 'panel shows the stored note verbatim'
        : `panel value !== document value (got ${JSON.stringify(String(p.noteValue).slice(0, 60))})`);

    // ── Leg 3: WRITE-THROUGH. Drive the real input event, then export and read the bytes.
    // This is the leg that separates "the table lists note" from "an author can author it".
    const NEW = 'Rewritten by probe\nsecond line & "quoted"';
    const w = await ev(cmd, `(function(){
      var props = document.getElementById('properties');
      var labels = Array.prototype.slice.call(props.querySelectorAll('.field-label'));
      var row = null;
      for (var i=0;i<labels.length;i++){ if (labels[i].childNodes[0] && String(labels[i].childNodes[0].nodeValue||'').trim()==='Note') { row = labels[i].parentNode; break; } }
      // A missing control is a LEG FAILURE, not a broken probe: if this threw, a mutant that
      // removes the field would abort the run with CANNOT RUN, and "the probe crashed" would
      // be indistinguishable from "the probe found the defect".
      var el = row ? row.querySelector('textarea, input') : null;
      if (!el) return { absent: true };
      el.value = ${JSON.stringify(NEW)};
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      var n = state.nodes.find(function(x){ return x.id===window.__t566id; });
      return { aef: n.aef.note, xml: buildBpmnXml(state) };
    })()`);
    const wroteModel = !w.absent && w.aef === NEW;
    const wroteXml = !w.absent && typeof w.xml === 'string' && w.xml.indexOf('Rewritten by probe&#10;second line &amp; &quot;quoted&quot;') > -1;
    report(wroteModel && wroteXml, 'note-writes',
      w.absent ? 'no Note control to write into'
        : `model ${wroteModel ? 'ok' : 'NOT updated'}, exported xml ${wroteXml ? 'carries the new note' : 'DOES NOT carry it'}`);

    // ── Leg 4: DISCLOSURE. The unlisted keys the node carries are shown, not dropped. ──
    const gotTK = p.disclosed && p.disclosed.terminalKind === 'ok';
    const gotSt = p.disclosed && p.disclosed.state === 'active';
    report(p.otherFound && gotTK && gotSt, 'disclosure',
      p.otherFound ? `disclosed ${JSON.stringify(Object.keys(p.disclosed))}` : 'NO "Other extensions" section — unlisted keys are still invisible');

    // ── Leg 5: the disclosure is READ-ONLY (T-197: derived/structural keys are not authored here) ──
    report(p.otherFound && p.editableInOther === 0, 'disclosure-readonly',
      p.otherFound ? `${p.editableInOther} editable control(s) in the disclosure (want 0)` : 'no section to judge');

    // ── Leg 6: MULTI-LINE SURVIVES THE ATTRIBUTE. Round-trip through parse→build. ──
    // A literal newline in an XML attribute normalises to a space on parse; escAttr emits
    // &#10; instead (src:9437). Without that, "multi-line note" is false however the panel
    // renders — which is why this is asserted on the BYTES and after a re-parse.
    // Set the value on the MODEL rather than reusing whatever leg 3 left behind: this leg is
    // an assertion about escAttr and the parser, and it must stay green when a mutant removes
    // the panel field. Independent legs, independent causes.
    const rt = await ev(cmd, `(function(){
      var n0 = state.nodes.find(function(x){ return x.id===window.__t566id; });
      n0.aef = n0.aef || {}; n0.aef.note = ${JSON.stringify(NEW)};
      var xml = buildBpmnXml(state);
      var st2 = parseBpmnXml(xml);
      var list = (st2 && st2.nodes) ? st2.nodes : [];
      var n2 = list.find(function(x){ return x.id===window.__t566id || x.uid==='u-t566-1'; });
      return { back: n2 && n2.aef ? n2.aef.note : null, hasEnt: xml.indexOf('&#10;') > -1 };
    })()`);
    report(rt.back === NEW && rt.hasEnt, 'multiline-roundtrip',
      rt.back === NEW ? 'newlines survive parse→build→parse via &#10;'
        : `note came back changed: ${JSON.stringify(String(rt.back).slice(0, 60))}`);

  } catch (e) {
    console.log('CANNOT RUN: ' + e.message);
    try { cl && cl.close(); } catch (_) {}
    br.kill(); py.kill();
    await sleep(400);
    for (const d of [doc, repo, udd]) rmSync(d, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });
    return 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill(); py.kill();
  }
  // Chromium keeps writing to the user-data-dir for a beat after SIGTERM; an ENOTEMPTY
  // here would crash the probe AFTER its verdict, turning a real result into a stack trace.
  await sleep(400);
  for (const d of [doc, repo, udd]) rmSync(d, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });

  console.log(out.join('\n'));
  console.log(`\n${npass} passed, ${nfail} failed`);
  if (nfail === 0) console.log(`${npass}/${npass} T-566 legs passed`);
  return nfail === 0 ? 0 : 1;
}

main().then(c => { process.exitCode = c; });
