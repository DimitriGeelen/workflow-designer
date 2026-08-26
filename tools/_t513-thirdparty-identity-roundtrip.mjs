#!/usr/bin/env node
// _t513-thirdparty-identity-roundtrip.mjs — does identity survive a THIRD-PARTY import?
//
// AEF asked this at rail 11882, closing out the element-`id` question we raised at 11879:
//
//   "If you have a case where identity has to survive a third-party import (no aef:uid on
//    arrival), that is the one I would want to hear about — that is where derived-from-uid
//    stops being stable."
//
// It is precisely the case _t511 named in its own `does_not_cover` and excluded. So the
// party who would be harmed by a bad answer asked us for the one we said we had not taken.
//
// THIRD-PARTY, defined so the answer cannot be read wider than it was measured:
//   a BPMN document in which the string "aef:" does not appear at all — no aef namespace
//   declaration, no aef:uid, no aef:position — carrying geometry as BPMN DI dc:Bounds and
//   bpmn.io-shaped element ids. That is what bpmn.io and Camunda Modeler emit.
//
// The READ of the source says identity survives: parseBpmnXml derives a uid from the
// element id via FNV-1a when aef:uid is absent (T-364), and buildBpmnXml emits aef:uid
// unconditionally. This probe does not trust that read. _t511's first run proved that a
// confident, wrong answer about this exact area is one comparator mistake away.
//
// Usage:  node tools/_t513-thirdparty-identity-roundtrip.mjs
// Exit 0 = fixture was genuinely aef-free AND identity survived AND the control fired AND
// the anti-overfit leg stayed green; 1 = a real answer of NO, or a dead control; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = 'src/aef-workflow-designer.html';
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// ── the fixture ───────────────────────────────────────────────────────────────────────
// AUTHORED, not taken from our corpus, and that is the point: every .bpmn in
// examples/aef-processes/rendered is designer-produced and carries aef:uid, so none of them
// can stand in for a document that arrives without one. Stripping aef out of one of ours
// would leave OUR id shapes behind and quietly test a different population.
//
// bpmn.io/Camunda shape: bpmndi geometry, `Activity_`/`Gateway_`/`Event_`/`Flow_` ids with
// 7-hex suffixes, no aef namespace declared anywhere.
// EVERY element id the fixture defines, flows included. The boundary leg re-mints this
// whole set: a third-party editor re-exporting renames its flows too, and a first version
// that suffixed only the four node ids reported "3 edge uids survived" — an artifact of the
// three flow ids I had left alone, not a property of the designer. A partial re-mint models
// a re-export nobody performs.
const IDS = {
  start: 'StartEvent_1',
  task:  'Activity_1a2b3c4',
  gw:    'Gateway_0x9y8z7',
  end:   'Event_1q2w3e4',
  f1:    'Flow_0aaaaaa',
  f2:    'Flow_0bbbbbb',
  f3:    'Flow_0cccccc',
};
const FIXTURE = String.raw`<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
                  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
                  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
                  id="Definitions_t513" targetNamespace="http://bpmn.io/schema/bpmn">
  <bpmn:process id="Process_t513" isExecutable="false">
    <bpmn:startEvent id="StartEvent_1" name="Request received">
      <bpmn:outgoing>Flow_0aaaaaa</bpmn:outgoing>
    </bpmn:startEvent>
    <bpmn:task id="Activity_1a2b3c4" name="Review request">
      <bpmn:incoming>Flow_0aaaaaa</bpmn:incoming>
      <bpmn:outgoing>Flow_0bbbbbb</bpmn:outgoing>
    </bpmn:task>
    <bpmn:exclusiveGateway id="Gateway_0x9y8z7" name="Approved?">
      <bpmn:incoming>Flow_0bbbbbb</bpmn:incoming>
      <bpmn:outgoing>Flow_0cccccc</bpmn:outgoing>
    </bpmn:exclusiveGateway>
    <bpmn:endEvent id="Event_1q2w3e4" name="Done">
      <bpmn:incoming>Flow_0cccccc</bpmn:incoming>
    </bpmn:endEvent>
    <bpmn:sequenceFlow id="Flow_0aaaaaa" sourceRef="StartEvent_1" targetRef="Activity_1a2b3c4" />
    <bpmn:sequenceFlow id="Flow_0bbbbbb" sourceRef="Activity_1a2b3c4" targetRef="Gateway_0x9y8z7" />
    <bpmn:sequenceFlow id="Flow_0cccccc" sourceRef="Gateway_0x9y8z7" targetRef="Event_1q2w3e4" />
  </bpmn:process>
  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Process_t513">
      <bpmndi:BPMNShape id="StartEvent_1_di" bpmnElement="StartEvent_1">
        <dc:Bounds x="160" y="100" width="36" height="36" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_1a2b3c4_di" bpmnElement="Activity_1a2b3c4">
        <dc:Bounds x="270" y="80" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Gateway_0x9y8z7_di" bpmnElement="Gateway_0x9y8z7">
        <dc:Bounds x="440" y="95" width="50" height="50" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Event_1q2w3e4_di" bpmnElement="Event_1q2w3e4">
        <dc:Bounds x="570" y="102" width="36" height="36" />
      </bpmndi:BPMNShape>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</bpmn:definitions>
`;

// Extract every aef:uid value and every element id from a document, IN the page, using the
// same DOM parser the designer itself uses.
const READ_EXPR = t => `(function(){
  var AEF = 'http://anchorpoint.framework/aef/extensions';
  var d = new DOMParser().parseFromString(${JSON.stringify(t)}, 'application/xml');
  var BPMN = 'http://www.omg.org/spec/BPMN/20100524/MODEL';
  var uids = [], ids = [], bpmnIds = [], nodeIdByUid = {};
  var u = d.getElementsByTagNameNS(AEF, 'uid');
  for (var i=0;i<u.length;i++){
    var v = u[i].getAttribute('value'); if (!v) continue;
    uids.push(v);
    // The element id of the node CARRYING this uid — lets a rename's effect on the
    // emitted id be measured per node rather than inferred from two sorted lists.
    var host = u[i].parentNode && u[i].parentNode.parentNode;
    if (host && host.getAttribute) { var hid = host.getAttribute('id'); if (hid) nodeIdByUid[v] = hid; }
  }
  var all = d.getElementsByTagName('*');
  for (var j=0;j<all.length;j++){
    var x = all[j].getAttribute && all[j].getAttribute('id'); if (!x) continue;
    ids.push(x);
    // Only BPMN-namespace ids are xsd:ID. Foreign elements inside bpmn:extensionElements
    // are admitted by <xsd:any namespace="##other" processContents="lax"/>, so with no AEF
    // schema present their @id is never validated as an ID and carries no uniqueness
    // constraint. Counting them together reported a "duplicate element id" that is not one.
    if (all[j].namespaceURI === BPMN) bpmnIds.push(x);
  }
  return { uids: uids, ids: ids, bpmnIds: bpmnIds, nodeIdByUid: nodeIdByUid };
})()`;

// One round-trip, exactly as the save path runs it.
const ROUNDTRIP = src => `(function(){ state = parseBpmnXml(${JSON.stringify(src)}); refreshDisplayIds(); return buildBpmnXml(state); })()`;

const sorted = a => a.slice().sort();
const sameSet = (a, b) => a.length === b.length && JSON.stringify(sorted(a)) === JSON.stringify(sorted(b));

async function main() {
  // ── anti-vacuity, BEFORE anything is spawned ────────────────────────────────────────
  // A "third-party import" answer measured on a document that already carries aef:uid is
  // not a weak answer, it is a different question wearing this one's name.
  if (/aef:/.test(FIXTURE) || /anchorpoint\.framework/.test(FIXTURE)) {
    console.log(JSON.stringify({ ok: false, error: 'fixture is not third-party — it mentions aef. A document that already carries our identity attribute cannot answer what happens to one that does not.' }, null, 2));
    process.exitCode = 2; return;
  }

  const doc = mkdtempSync(join(tmpdir(), 't513-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't513-repo-'));
  copyFileSync(join(REPO, SRC), join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't513-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(200);

    const IN = await ev(cmd, READ_EXPR(FIXTURE));
    if (IN.uids.length !== 0) throw new Error('fixture parsed with ' + IN.uids.length + ' aef:uid — it is not third-party');

    // ── half (a): is an identity MINTED on the way out? ────────────────────────────────
    const export1 = await ev(cmd, ROUNDTRIP(FIXTURE));
    if (typeof export1 !== 'string') throw new Error('round-trip 1 produced no string');
    const OUT1 = await ev(cmd, READ_EXPR(export1));

    // ── half (b): does that identity SURVIVE a second import? ─────────────────────────
    // This is the half that actually answers AEF. Minting a uid on save is worthless if
    // re-opening the saved file mints a different one.
    const export2 = await ev(cmd, ROUNDTRIP(export1));
    const OUT2 = await ev(cmd, READ_EXPR(export2));
    const identitySurvives = OUT1.uids.length > 0 && sameSet(OUT1.uids, OUT2.uids);

    // ── stability across two opens of the SAME bytes (T-364's claim, re-checked) ───────
    const export1b = await ev(cmd, ROUNDTRIP(FIXTURE));
    const OUT1B = await ev(cmd, READ_EXPR(export1b));
    const stableAcrossOpens = sameSet(OUT1.uids, OUT1B.uids);

    // ── NEGATIVE CONTROL CUTS ON aef:uid ──────────────────────────────────────────────
    // The comparator reads aef:uid, so the control deletes an aef:uid. Cutting on anything
    // it does not consult would certify nothing (PL-205). "Identity survived" and "the
    // comparison is dead" are byte-identical outputs without this.
    const victim = OUT1.uids[0];
    const cut = export1.replace(new RegExp(`<aef:uid value="${victim}"\\s*/>`), '');
    const CUT = await ev(cmd, READ_EXPR(cut));
    const controlFired = cut.length < export1.length && !sameSet(OUT1.uids, CUT.uids) && !CUT.uids.includes(victim);

    // ── anti-overfit: a benign edit must NOT move the verdict ─────────────────────────
    // A probe that goes red on any change is measuring "did anything happen", not identity.
    // The rename is SUBSTANTIVE — a different first word, not a suffix. The first version
    // appended "(renamed)" and reported `id_survived_a_rename: true`, which was true and
    // meaningless: the emitted id slug is built from the leading word, so "Review request"
    // and "Review request (renamed)" both slug to `review` and the leg passed without ever
    // exercising what it claims to measure. Same shape as a control that cannot fail.
    const renamed = FIXTURE.replace('name="Review request"', 'name="Escalate to legal"');
    if (renamed === FIXTURE) throw new Error('anti-overfit leg did not actually edit the fixture');
    const exportR = await ev(cmd, ROUNDTRIP(renamed));
    // Ask the page which uid the renamed node ended up with, rather than deriving it here —
    // re-implementing the uid derivation in this file would make the probe agree with itself
    // instead of with the designer. Read immediately, while `state` is still that parse.
    const RENAMED_UID = await ev(cmd, `(function(){ var n = state.nodes.find(function(x){ return x.name === 'Escalate to legal'; }); return n ? n.uid : null; })()`);
    const OUTR = await ev(cmd, READ_EXPR(exportR));
    if (!RENAMED_UID) throw new Error('anti-overfit leg: the renamed node was not found in state — the rename did not reach the parser');
    const benignEditIsQuiet = sameSet(OUT1.uids, OUTR.uids);

    // ── the boundary, MEASURED and reported as a number, not asserted as a claim ───────
    // A third-party editor re-mints its own element ids on re-export. Since the uid is
    // DERIVED from that id, this is where derived-from-uid stops being stable — AEF's
    // exact phrase. Expected to be a boundary of the design, not a defect; reported either
    // way so they can judge it themselves.
    let remint = FIXTURE;
    for (const id of Object.values(IDS)) remint = remint.split(id).join(id + 'z');
    const exportM = await ev(cmd, ROUNDTRIP(remint));
    const OUTM = await ev(cmd, READ_EXPR(exportM));
    const overlap = OUT1.uids.filter(u => OUTM.uids.includes(u));

    // Duplicate element ids, counted rather than eyeballed — and counted over BPMN-namespace
    // elements ONLY.
    //
    // The first version of this counter ran over every element in the document and reported
    // `Process_t513` twice, which reads as a schema violation because BPMN's @id is xsd:ID.
    // It is not one: the two carriers are `bpmn:participant/@id` and `aef:workflowMeta/@id`,
    // and the second is a foreign element inside bpmn:extensionElements, admitted by
    // <xsd:any namespace="##other" processContents="lax"/>. With no AEF schema available, lax
    // means it is not validated at all, so that attribute is never typed as xsd:ID. Had this
    // gone out unchecked, AEF would have received a fabricated defect report from us.
    // Reported, NOT gated on: this probe answers the identity question, and widening it into
    // a validity gate would make one green mean two things.
    const seen = new Set(), dupes = new Set();
    for (const i of OUT1.bpmnIds) { if (seen.has(i)) dupes.add(i); else seen.add(i); }
    // The same string used as an @id by a BPMN element and by a foreign one. Legal, but it
    // is what made the naive counter cry wolf, so it is named rather than left to be
    // rediscovered.
    const bpmnCount = new Map();
    for (const i of OUT1.bpmnIds) bpmnCount.set(i, (bpmnCount.get(i) || 0) + 1);
    const allCount = new Map();
    for (const i of OUT1.ids) allCount.set(i, (allCount.get(i) || 0) + 1);
    const crossNs = [...bpmnCount.keys()].filter(i => allCount.get(i) > bpmnCount.get(i));

    // Env-gated dump, so the next person investigating an oddity in the output does not
    // have to re-write the harness to see the bytes it is describing.
    if (process.env.T513_DUMP) process.stderr.write(export1);

    const ok = identitySurvives && stableAcrossOpens && controlFired && benignEditIsQuiet;

    console.log(JSON.stringify({
      ok,
      question: 'AEF rail 11882 — does identity survive a third-party import arriving with no aef:uid?',
      answer: !ok && !controlFired ? 'INCONCLUSIVE — the negative control did not fire, so this run certifies nothing'
            : identitySurvives ? 'YES — an aef:uid is minted on first save and the SAME uid comes back on re-import'
            : 'NO — see uids_first_save vs uids_second_save',
      definition_of_third_party: 'the string "aef:" does not appear in the document at all; geometry arrives as BPMN DI dc:Bounds; bpmn.io-shaped element ids',
      halves: {
        a_identity_minted_on_save: { uids_out: OUT1.uids.length, uids_in: IN.uids.length, minted: OUT1.uids.length > 0 },
        b_identity_survives_reimport: { survives: identitySurvives, uids_first_save: sorted(OUT1.uids), uids_second_save: sorted(OUT2.uids) },
      },
      stable_across_two_opens_of_same_bytes: stableAcrossOpens,
      element_id_churn: {
        note: 'reported as an observation, not a pass/fail — the exporter mints element ids from the uid by design (T-364)',
        ids_in: sorted(IN.ids),
        ids_out_first_save: sorted(OUT1.ids),
        original_ids_that_survived: Object.values(IDS).filter(i => OUT1.ids.includes(i)),
        duplicate_element_ids_in_output: [...dupes],
        counted_over: 'BPMN-namespace elements only — @id is xsd:ID there; foreign elements inside extensionElements are lax-processed and untyped',
        same_string_used_as_id_by_both_a_bpmn_and_a_foreign_element: crossNs,
      },
      negative_control: {
        description: 'one aef:uid deleted from the saved document; the comparator MUST notice. Cut on aef:uid because that is what the comparator reads (PL-205).',
        victim, fired: controlFired,
      },
      anti_overfit: {
        description: 'renaming a node\'s name attribute must leave the uid set unchanged',
        quiet: benignEditIsQuiet,
      },
      element_id_churns_on_ordinary_editing: {
        // The sharper form of the id warning we sent AEF at 11879. We told them the id is
        // "re-minted on import". Measured, it is worse than that: the emitted id is a
        // function of lane + x-order + the node's NAME, so it moves when someone renames or
        // drags a node — during ordinary authoring, with no import involved. Anything
        // keying on it breaks on a rename, not just on a round-trip.
        description: 'the SAME uid before and after a pure rename; does its emitted element id stay put?',
        renamed_node_uid: RENAMED_UID,
        element_id_before: RENAMED_UID ? (OUT1.nodeIdByUid[RENAMED_UID] || null) : null,
        element_id_after: RENAMED_UID ? (OUTR.nodeIdByUid[RENAMED_UID] || null) : null,
        id_survived_a_rename: RENAMED_UID ? OUT1.nodeIdByUid[RENAMED_UID] === OUTR.nodeIdByUid[RENAMED_UID] : null,
      },
      boundary_third_party_remints_its_own_ids: {
        description: 'every element id in the fixture suffixed, as a third-party editor re-exporting would do. The uid is DERIVED from the element id, so it is expected to change — this is the limit of "identity survives", stated as a measurement.',
        uids_before: sorted(OUT1.uids), uids_after: sorted(OUTM.uids), overlap,
        identity_carries_across_a_third_party_remint: overlap.length === OUT1.uids.length,
      },
      does_not_cover: 'one authored 4-node document (startEvent, task, exclusiveGateway, endEvent) with no lanes, no subProcess, no boundary events and no pools. It does not cover whether a third-party editor PRESERVES our aef:uid when it re-opens our output — that is a property of their tool, not ours, and cannot be measured from here.',
    }, null, 2));
    process.exitCode = ok ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e) }, null, 2));
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
