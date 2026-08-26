#!/usr/bin/env node
// _t570-meta-carriage-cdp.mjs — the editor does not destroy <aef:meta> keys it does not name.
//
// THE DEFECT. Import reads EVERY attribute of <aef:meta> into node.aef (src:10255,
// unconditional loop). Export emitted only the 20 keys on the metaKeys whitelist. The two
// lists are asymmetric, so a key present in a source document and absent from metaKeys was
// loaded, rendered nowhere, and DESTROYED on the next save. Not invisibility — that was
// T-566, and it round-tripped faithfully. This is loss.
//
// MEASURED, NOT READ. Of the 4 keys our 91-file corpus carries outside metaKeys, three do
// not survive parse→build→parse: `determinism` (16 values), `sideEffect` (2), `emits` (1).
// The fourth, `endpoint` (10), survives because it has its own element emitter — which is
// exactly the distinction a census over the two whitelists cannot make, and the reason
// leg 2 drives a real round trip in the page instead of grepping the source.
//
// LEG 1 IS THE CONTROL ARM AND IT IS NOT OPTIONAL. "the key is present after the fix" is
// also what a probe that asserts nothing produces. Leg 1 reproduces the PRE-fix rule inside
// the page — the literal metaKeys.filter(...) one-liner this task replaced — and requires it
// to LOSE the keys that leg 2 requires to survive. Without it, a corpus that happened to
// carry no unlisted keys would report the same green (T-560).
//
// --src <path> runs against an alternate editor build so the teeth harness can mutate a copy
// in a tmpdir. Exit 0 = all legs pass, 1 = a leg failed, 2 = misconfigured (NOT a pass).
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

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
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 25000) throw new Error('editor not ready'); await sleep(150); } }

// A carried value with every character class an XML attribute can mangle. Newline is the one
// that matters most: attribute-value normalisation collapses a literal \n to a space, so
// "the value survives" is an assertion about escAttr, not about the carriage filter.
const HARD = 'a & b < c "quoted"\nsecond line';
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;').replace(/\n/g, '&#10;');

// T1 carries three unlisted keys plus one (endpoint) that HAS its own emitter — the pair is
// what separates "carry everything" from "carry what nothing else emits".
// `provenance` is deliberately NOT in our corpus: a fix that widens metaKeys by the keys the
// census happened to find passes on determinism/sideEffect and fails here, which is the
// difference between repairing the mechanism and repairing the sample (mutant D).
// T2 carries nothing unlisted — it is the arm that catches a fix which UNIONS keys globally.
// E1 carries a SCALAR emits, the shape both investigate.bpmn and the editor's own seed
// template (src:2083) use, and the shape the structured exporter's Array.isArray silently
// skips.
const FIXTURE = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:aef="http://anchorpoint.framework/aef/extensions" id="d1" targetNamespace="http://x">
  <bpmn:process id="Process_t570" isExecutable="false">
    <bpmn:serviceTask id="T1" name="Carrier">
      <bpmn:extensionElements>
        <aef:uid value="u-t570-1"/>
        <aef:position x="200.0" y="140.0"/>
        <aef:meta tier="2" note="keepme" determinism="deterministic" sideEffect="${esc(HARD)}" provenance="cashweb/2026" endpoint="POST /orders"/>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:serviceTask id="T2" name="Plain">
      <bpmn:extensionElements>
        <aef:uid value="u-t570-2"/>
        <aef:position x="400.0" y="140.0"/>
        <aef:meta tier="1"/>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:endEvent id="E1" name="Done">
      <bpmn:extensionElements>
        <aef:uid value="u-t570-3"/>
        <aef:position x="600.0" y="140.0"/>
        <aef:meta emits="event:probe.ready"/>
      </bpmn:extensionElements>
    </bpmn:endEvent>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="Di_1"><bpmndi:BPMNPlane id="Pl_1" bpmnElement="Process_t570">
    <bpmndi:BPMNShape id="S_T1" bpmnElement="T1"><dc:Bounds x="200" y="140" width="120" height="64"/></bpmndi:BPMNShape>
    <bpmndi:BPMNShape id="S_T2" bpmnElement="T2"><dc:Bounds x="400" y="140" width="120" height="64"/></bpmndi:BPMNShape>
    <bpmndi:BPMNShape id="S_E1" bpmnElement="E1"><dc:Bounds x="600" y="140" width="36" height="36"/></bpmndi:BPMNShape>
  </bpmndi:BPMNPlane></bpmndi:BPMNDiagram>
</bpmn:definitions>`;

// Everything the legs need, gathered in ONE page evaluation so no leg can observe a state a
// previous leg mutated. Each leg then judges its own slice of this snapshot.
const SNAP = `(function(){
  function byUid(list, u){ return (list||[]).find(function(x){ return x.uid===u; }); }
  var n1 = byUid(state.nodes, 'u-t570-1');
  if (!n1) return { err: 'fixture absent; uids = ' + JSON.stringify((state.nodes||[]).map(function(x){return x.uid;})) };

  var imported1 = JSON.parse(JSON.stringify(n1.aef || {}));
  var xml  = buildBpmnXml(state);
  var xml2 = buildBpmnXml(state);
  var st2  = parseBpmnXml(xml);
  var b1 = byUid(st2.nodes, 'u-t570-1'), b2 = byUid(st2.nodes, 'u-t570-2'), b3 = byUid(st2.nodes, 'u-t570-3');

  // The PRE-fix export rule, reproduced verbatim. This is the control arm: it must LOSE what
  // the shipped path keeps, otherwise the fixture never reached the defect at all.
  var metaKeys = ['tier','agentType','decisionOwner','triggeredBy','terminalKind','state','note',
    'softFail','section','guard','external','exitCode','autoTrigger','trigger','gatewayKind',
    'gate','scopeOf','horizon','workflowType','owner'];
  var aefKeys = Object.keys(imported1).filter(function(k){ return imported1[k] !== '' && imported1[k] != null; });
  var oldRule = metaKeys.filter(function(k){ return aefKeys.indexOf(k) > -1; });

  // ONE node's extensionElements block, so "how many times does endpoint appear" is a
  // question about that node rather than about the whole document.
  // Anchored on the aef:uid, NOT on the bpmn id: export REGENERATES display ids from lane,
  // index and name (id="T1" comes back as id="hum_1_carrier"), so an id-anchored window
  // silently matches nothing and every leg reading it reports a defect that isn't there.
  // The uid is the identifier export is contractually obliged to preserve (src:9487).
  function blockFor(x, uid){
    var re = /<bpmn:extensionElements>[\\s\\S]*?<\\/bpmn:extensionElements>/g, mm;
    while ((mm = re.exec(x))) { if (mm[0].indexOf(uid) > -1) return mm[0]; }
    return '';
  }
  var t1block = blockFor(xml, 'u-t570-1');
  var metaM = t1block.match(/<aef:meta ([^>]*?)\\/>/);
  var metaAttrOrder = metaM ? (metaM[1].match(/([A-Za-z_][\\w.\\-]*)=/g) || []).map(function(s){ return s.slice(0,-1); }) : [];

  // Structured emits: an ARRAY value must keep its own <aef:emits> channel and must NOT also
  // be flattened into the meta bag. Mutated on a CLONE of state so nothing above is disturbed.
  var n3 = byUid(state.nodes, 'u-t570-3');
  var savedEmits = n3 ? n3.aef.emits : undefined;
  if (n3) n3.aef.emits = ['event:a', 'event:b'];
  var xmlArr = buildBpmnXml(state);
  if (n3) n3.aef.emits = savedEmits;
  var e1arr = blockFor(xmlArr, 'u-t570-3');

  return {
    imported1: imported1,
    oldRule: oldRule,
    back1: b1 ? b1.aef : null,
    back2: b2 ? b2.aef : null,
    back3: b3 ? b3.aef : null,
    stable: xml === xml2,
    t1block: t1block,
    metaAttrOrder: metaAttrOrder,
    e1arr: e1arr
  };
})()`;

async function main() {
  const out = [];
  let npass = 0, nfail = 0;
  const report = (ok, name, detail) => { ok ? npass++ : nfail++; out.push(`${ok ? 'PASS' : 'FAIL'}  ${name} — ${detail}`); };

  if (!existsSync(EDITOR)) { console.log('CANNOT RUN: editor missing: ' + EDITOR); return 2; }
  if (!existsSync(SERVER)) { console.log('CANNOT RUN: server missing: ' + SERVER); return 2; }

  const doc = mkdtempSync(join(tmpdir(), 't570-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't570-repo-'));
  const udd = mkdtempSync(join(tmpdir(), 't570-udd-'));
  copyFileSync(EDITOR, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  writeFileSync(join(doc, 'rendered', 't570.bpmn'), FIXTURE);
  mkdirSync(join(repo, 'examples', 'aef-processes', 'rendered'), { recursive: true });

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
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: BASE + '/designer.html?load=' + encodeURIComponent('rendered/t570.bpmn') });
    await waitReady(cmd); await sleep(500);

    const s = await ev(cmd, SNAP);
    if (s.err) throw new Error(s.err);

    const LOST = ['determinism', 'sideEffect', 'provenance'];

    // ── Leg 1: CONTROL ARM. The pre-fix rule must lose exactly what leg 2 requires to survive.
    const oldLost = LOST.filter(k => s.oldRule.indexOf(k) === -1);
    report(oldLost.length === LOST.length, 'reproduce-drop',
      oldLost.length === LOST.length
        ? `pre-fix metaKeys filter drops ${JSON.stringify(LOST)} — the fixture reaches the defect`
        : `pre-fix rule already kept ${JSON.stringify(LOST.filter(k => s.oldRule.indexOf(k) > -1))}; this fixture cannot evidence a repair`);

    // ── Leg 2: CARRIAGE. Every attribute the document carried comes back after a real
    // import → export → re-parse, byte-identical. Compared against what IMPORT produced,
    // not against a hand-written list, so the leg cannot drift from the fixture.
    const back1 = s.back1 || {};
    const missing = Object.keys(s.imported1).filter(k => back1[k] !== s.imported1[k]);
    report(missing.length === 0, 'carriage-roundtrip',
      missing.length === 0
        ? `all ${Object.keys(s.imported1).length} carried keys survive parse→build→parse`
        : `lost or altered on re-export: ${JSON.stringify(missing.map(k => k + ': ' + JSON.stringify(back1[k])))}`);

    // ── Leg 3: the hard value survives the ATTRIBUTE, not just the filter. & < " and a
    // newline all pass through escAttr and back. A carriage fix that forgot escaping would
    // pass leg 2 on the plain keys and silently mangle this one.
    report(back1.sideEffect === HARD, 'carried-escaping',
      back1.sideEffect === HARD ? 'ampersand, angle, quote and newline round-trip intact'
        : `value came back changed: ${JSON.stringify(String(back1.sideEffect).slice(0, 70))}`);

    // ── Leg 4: NO ACQUISITION. A node that carried nothing unlisted gains nothing. This is
    // the arm that catches a fix which unions unknown keys across the document.
    const gained = Object.keys(s.back2 || {}).filter(k => LOST.indexOf(k) > -1);
    report(gained.length === 0, 'no-acquisition',
      gained.length === 0 ? 'the plain node carries only its own keys'
        : `plain node acquired ${JSON.stringify(gained)} from a sibling`);

    // ── Leg 5: NO DOUBLE EMIT. `endpoint` has its own element emitter; carrying it in the
    // meta bag as well would give one value two carriers that can then disagree.
    const epAttr = (s.t1block.match(/<aef:meta[^>]*\bendpoint=/) || []).length;
    const epEl = (s.t1block.match(/<aef:endpoint>/g) || []).length;
    report(epAttr === 0 && epEl === 1, 'no-double-emit',
      `endpoint: ${epAttr} meta attribute(s) + ${epEl} element(s) (want 0 + 1)`);

    // ── Leg 6: STRUCTURED VALUES KEEP THEIR OWN CHANNEL. An ARRAY emits still becomes
    // <aef:emits><aef:emit …/></aef:emits> and is NOT also flattened into the meta bag.
    const hasStruct = /<aef:emits>[\s\S]*<aef:emit value="event:a"/.test(s.e1arr);
    const flattened = /<aef:meta[^>]*\bemits=/.test(s.e1arr);
    report(hasStruct && !flattened, 'structured-untouched',
      `array emits: structured element ${hasStruct ? 'present' : 'MISSING'}, meta attribute ${flattened ? 'ALSO present (flattened an array into an attribute)' : 'absent'}`);

    // ── Leg 7: the SCALAR emits reaches the file. The panel's Emits box (FIELD_META, plain
    // text field) writes a string, and the structured exporter's Array.isArray skipped it —
    // so this value was destroyed on save whether it came from a document or from an author.
    report((s.back3 || {}).emits === 'event:probe.ready', 'scalar-emits-survives',
      (s.back3 || {}).emits === 'event:probe.ready' ? 'a scalar emits round-trips instead of being dropped'
        : `scalar emits came back as ${JSON.stringify((s.back3 || {}).emits)}`);

    // ── Leg 8: DETERMINISTIC BYTES AND ORDER. Two exports of an unchanged state are
    // identical, and known keys precede carried keys so a diff of two saves stays readable.
    const known = ['tier', 'note'];
    const idxKnown = known.map(k => s.metaAttrOrder.indexOf(k));
    const idxCarried = LOST.map(k => s.metaAttrOrder.indexOf(k));
    const ordered = idxKnown.every(i => i > -1) && idxCarried.every(i => i > -1)
      && Math.max(...idxKnown) < Math.min(...idxCarried);
    report(s.stable && ordered, 'deterministic-order',
      `two exports ${s.stable ? 'byte-identical' : 'DIFFER'}; attribute order ${JSON.stringify(s.metaAttrOrder)}${ordered ? '' : ' (known keys must precede carried keys)'}`);

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
  // Chromium keeps writing to the user-data-dir for a beat after SIGTERM; an ENOTEMPTY here
  // would crash the probe AFTER its verdict, turning a real result into a stack trace.
  await sleep(400);
  for (const d of [doc, repo, udd]) rmSync(d, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });

  console.log(out.join('\n'));
  console.log(`\n${npass} passed, ${nfail} failed`);
  if (nfail === 0) console.log(`${npass}/${npass} T-570 legs passed`);
  return nfail === 0 ? 0 : 1;
}

main().then(c => { process.exitCode = c; });
