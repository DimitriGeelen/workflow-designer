#!/usr/bin/env node
// _t338-input-fidelity-cdp.mjs — does a load->save round trip PRESERVE what it was
// given? Compares the EXPORTED document against the INPUT document.
//
// Prevention leg for G-016. The tree already has an export-safety instrument,
// tools/_t308-export-byte-identity-cdp.mjs, and it is differential: it runs
// buildBpmnXml(parseBpmnXml(map)) under the working tree AND under a git ref and
// compares the two outputs TO EACH OTHER, over the 24 well-formed corpus maps.
// Two blind spots follow from that shape, neither of which is a bug in that tool:
//
//   1. A defect present in BOTH versions is byte-identical, therefore green. The
//      instrument can see CHANGE; it cannot see WRONGNESS.
//   2. Its denominator is well-formed corpus maps, so a defect only malformed
//      input can express is outside the population entirely.
//
// T-337 lived in the intersection: parseBpmnXml enumerates flow nodes by iterating
// a hard-coded tag allowlist with no complement branch, so an unlisted tag is not
// rejected but never visited; export writes only from state.nodes, so the node is
// deleted on open->save. Both designer versions drop it (green), and no corpus map
// carries such a tag (never asked).
//
// This instrument supplies the missing direction -- output vs INPUT -- over a
// population that deliberately includes documents the corpus cannot express.
//
// THE EXPECTED SET IS MEASURED, NOT DECLARED. A hand-written "known lossy" list
// would be a tolerance answerable only to itself: it could never fail for being
// wrong, only for being out of date, and nothing would say which. Instead every
// probe is exercised every run and the resulting VERDICT is compared with
// EXPECTED. A verdict that worsens fails. A verdict that IMPROVES also fails, and
// says so -- that is how this guard reports that a defect was fixed, rather than
// quietly relaxing into a permission list.
//
// ---------------------------------------------------------------------------
// T-339 WIDENING. G-016's decision_trigger names THREE populations: "malformed
// input, out-of-vocabulary tags, unresolvable refs". T-338 shipped one of them
// (out-of-vocabulary tags) and the prose reporting it did not say which. This
// file now covers all three, plus a fourth found while covering the third.
//
// THE TRAP THIS AVOIDS. For the corpus and for out-of-vocabulary tags the wanted
// property is LOSSLESSNESS and can be asserted directly. For MALFORMED input it
// is not: refusing to load a broken document is CORRECT, and a guard demanding
// preservation would go red exactly when the designer behaves well. The property
// actually wanted is
//
//     either refuse visibly, or preserve -- silent partial acceptance is the defect
//
// so the malformed leg is three-way (REFUSED / PRESERVED / SILENTLY-PARTIAL) and
// only the third fails. The same applies to unresolvable refs: dropping a
// dangling flowNodeRef may be a legitimate repair, while dropping the ELEMENT
// that carried it is loss -- those must not share a verdict.
//
// IDENTITY IS MEASURED BY uid, NOT BY STRING PRESENCE. Measuring "is this id
// still somewhere in the output" produced a false data-loss reading on 4 maps
// during T-339: a node orphaned from its lane is re-homed to the first lane,
// which RECOMPUTES its display id (frw_6_x -> hum_1_x) and renumbers its
// siblings. The uid was preserved throughout. On one map the string predicate
// even read TRUE because a different node had inherited the vacated name. Node
// counts and aef:uid sets are the discriminators; the id attribute is not.
//
// WHAT IS GATED AND WHAT IS ONLY REPORTED. Verdict SETS are gated. Per-map counts
// (e.g. "4 of 24 maps re-home a lane") are printed but not gated, because a count
// over the corpus moves whenever the corpus grows -- pinning it would rebuild the
// G-015 shape: a global always-moving property inside a per-change gate.
//
// Usage: node tools/_t338-input-fidelity-cdp.mjs [--json]
// Exit 0 = every measured verdict matches expectation; 1 = drift; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = join(REPO, 'examples', 'aef-processes', 'rendered');
// Teeth-only seam. Defaults to the real designer; the gating runner never sets
// this. It exists so a teeth run can mutate a COPY of the subject and prove that
// the SILENTLY-PARTIAL and UID-LOST verdicts are reachable at all — without it,
// "0 silent partial acceptances" would be a zero in a bucket never shown
// fillable, which is indistinguishable from a bucket that cannot fill.
const SRC = process.env.T338_DESIGNER_SRC || join(REPO, 'src', 'aef-workflow-designer.html');
const JSON_OUT = process.argv.includes('--json');
const sleep = ms => new Promise(r => setTimeout(r, ms));

// Standard BPMN flow-node tags this designer does not implement. Every one is a
// legitimate element a peer may author -- callActivity is already an open task
// here (T-282) and inclusiveGateway/businessRuleTask are plain BPMN. The point is
// not that these are exotic; it is that the vocabulary gap between BPMN and the
// importer's allowlist is where content silently disappears.
const PROBE_TAGS = [
  'callActivity', 'inclusiveGateway', 'businessRuleTask', 'sendTask',
  'receiveTask', 'manualTask', 'eventBasedGateway', 'complexGateway',
  'transaction', 'adHocSubProcess',
];

// Tags currently measured as lossy. NOT a permission list -- the set is recomputed
// every run and any difference in EITHER direction is a failure.
//
// EMPTIED 2026-08-03 BY T-337, which is the event this file was written to catch.
// Measured before: 10/10 lossy. Measured after: 0/10, with every other row in every
// other population byte-identical to the baseline run. parseBpmnXml grew a
// complement branch, so an out-of-allowlist flow node is now imported carrying its
// original tag and re-emitted with it.
//
// The population inverted with it: this used to be all-expected-to-DROP, and now it
// is all-expected-to-SURVIVE. Those two shapes fail differently. The old one could
// pass on an injection that never landed; the new one cannot, because the injection
// is asserted present in the mutated source (`<bpmn:TAG` matched before the round
// trip) and a tag that fails to inject lands in `notInjected`, which is gated. That
// assertion is now the whole control for this leg -- see the empty-population guard
// below, added with this change so the leg cannot pass by probing nothing.
const EXPECTED_LOSSY = new Set();

// --- population 2: malformed input ----------------------------------------
// Verdict per case is REFUSED (threw -- acceptable), PRESERVED (acceptable), or
// SILENTLY-PARTIAL (accepted without complaint and lost content -- the defect).
const MALFORMED = [
  { id: 'not-wellformed-unclosed',  fn: x => x.replace('</bpmn:process>', '') },
  { id: 'not-wellformed-badentity', fn: x => x.replace('<bpmn:process', '<bpmn:process foo="a & b"') },
  { id: 'not-wellformed-mismatch',  fn: x => x.replace('</bpmn:definitions>', '</bpmn:definitionsX>') },
  { id: 'no-process-element',       fn: x => x.replace(/<bpmn:process\b/, '<bpmn:processX').replace('</bpmn:process>', '</bpmn:processX>') },
  { id: 'node-without-id',          fn: x => x.replace(/(<bpmn:serviceTask\s+)id="[^"]*"/, '$1') },
  { id: 'wrong-root',               fn: x => x.replace('<bpmn:definitions', '<bpmn:definitionsWRONG').replace('</bpmn:definitions>', '</bpmn:definitionsWRONG>') },
  { id: 'empty-document',           fn: () => '' },
  { id: 'truncated-midway',         fn: x => x.slice(0, Math.floor(x.length / 2)) },
];

// Measured 2026-08-02 over all 24 rendered corpus maps. Every entry is the SET of
// verdicts that case produced, sorted and joined -- so a case that behaves
// differently on different maps is visible rather than averaged away.
const EXPECTED_MALFORMED = {
  'not-wellformed-unclosed':  'REFUSED',
  'not-wellformed-badentity': 'REFUSED',
  'not-wellformed-mismatch':  'REFUSED',
  'no-process-element':       'REFUSED',
  'node-without-id':          'PRESERVED',
  'wrong-root':               'PRESERVED',
  'empty-document':           'REFUSED',
  'truncated-midway':         'REFUSED',
};

// --- population 3: unresolvable refs ---------------------------------------
// Each mutation points one reference at a node that does not exist. The question
// is what happens to the ELEMENT that carried the bad reference, and to the
// identities (aef:uid) of everything in the document.
const REF_CASES = [
  { id: 'flow-sourceRef-dangling',
    fn: x => x.replace(/(<bpmn:sequenceFlow\b[^>]*\bsourceRef=")[^"]*(")/, '$1__ghost__$2') },
  { id: 'flow-targetRef-dangling',
    fn: x => x.replace(/(<bpmn:sequenceFlow\b[^>]*\btargetRef=")[^"]*(")/, '$1__ghost__$2') },
  { id: 'flowNodeRef-dangling',
    fn: x => x.replace(/(<bpmn:flowNodeRef>)[^<]*(<\/bpmn:flowNodeRef>)/, '$1__ghost__$2') },
  // The corpus contains zero boundaryEvents, so this case BUILDS its carrier
  // rather than mutating an absent one -- otherwise it would silently skip and a
  // population of zero would read as a pass. boundaryEvent IS in the importer's
  // allowlist, so this asks a real question: what happens to a boundary event
  // whose host task does not exist?
  { id: 'attachedToRef-dangling',
    fn: x => {
      const at = x.indexOf('</bpmn:process>');
      if (at < 0) return x;
      const el = `\n    <bpmn:boundaryEvent id="probe_boundary" name="Probe boundary" attachedToRef="__ghost__">\n`
        + `      <bpmn:extensionElements><aef:uid value="probe_boundary_uid"/></bpmn:extensionElements>\n`
        + `    </bpmn:boundaryEvent>\n`;
      return x.slice(0, at) + el + x.slice(at);
    } },
];

// Verdict vocabulary: UID-LOST (an aef:uid present in the input is absent from
// the output -- identity destroyed, data loss), UID-KEPT (every identity
// survives), LANE-REHOMED (some node's lane assignment changed).
//
// LANE-REHOMED is gated even though it is not loss. Lane is not decoration in
// this project -- it is WHO (IW-9: "Lane = who"), and an unresolvable
// flowNodeRef silently reassigns the orphaned node to the `human` lane, i.e. to
// sovereignty. Measured 2026-08-02: framework→human on every corpus map whose
// mutated node was not already there. Gating the VERDICT rather than the count
// keeps this corpus-size independent.
const EXPECTED_REFS = {
  'flow-sourceRef-dangling': 'UID-KEPT',
  'flow-targetRef-dangling': 'UID-KEPT',
  'flowNodeRef-dangling':    'LANE-REHOMED+UID-KEPT',
  'attachedToRef-dangling':  'UID-KEPT',
};

// --- population 4: unknown SUB-TREE (found while covering population 3) -----
// The corpus contains zero <bpmndi:BPMNDiagram> (0 of 175 local .bpmn files), so
// the whole standard BPMN DI sub-tree is a vocabulary gap one granularity ABOVE
// T-337's: not an unknown flow-node tag but an entire unknown branch. Every
// mainstream BPMN modeller emits DI, so this is the shape a real third-party file
// would arrive in. Filed as its own task; measured here because it is the same
// class the instrument exists to watch.
const EXPECTED_DI = 'DI-DROPPED';

// --- population 5: CONTENT of an ACCEPTED element (T-346) -------------------
// Populations 1-4 all ask whether the importer accepts a THING. This one asks
// what happens INSIDE a thing it already accepts. `parseBpmnXml` reaches into each
// allowlisted element for ~10 named children and 2 attributes; everything else in
// that element is not rejected, it is simply never read — and export writes only
// from `state`. Identical mechanism to T-337, one level further in.
//
// Not hypothetical: T-259 is exactly this defect and it shipped — an unconsumed
// <aef:eventDef> child destroyed by a layout-only open→save (the rail-201 field
// defect). That fix resolved ONE child. This measures the rest.
//
// The corpus leg cannot see this class: it compares node/flow/lane COUNTS, and an
// element that survives with its content stripped keeps all three identical. Same
// blind spot as T-341 — green because the measure was about the wrong property.
const MARK = 'T346MARK';
const CONTENT_CASES = [
  { id: 'documentation',      carrier: 'serviceTask',
    frag: `<bpmn:documentation>${MARK}</bpmn:documentation>` },
  // The T-259 shape itself: a foreign child inside an extensionElements block the
  // importer DOES read — it takes the aef:* children it knows and ignores the rest.
  { id: 'ext-foreign-child',  carrier: 'serviceTask', into: 'extensionElements',
    ns: ['zeebe', 'http://camunda.org/schema/zeebe/1.0'],
    frag: `<zeebe:taskDefinition type="${MARK}"/>` },
  { id: 'property',           carrier: 'serviceTask',
    frag: `<bpmn:property id="${MARK}" name="p"/>` },
  { id: 'multiInstanceLoop',  carrier: 'serviceTask',
    frag: `<bpmn:multiInstanceLoopCharacteristics isSequential="true">`
        + `<bpmn:loopCardinality>${MARK}</bpmn:loopCardinality>`
        + `</bpmn:multiInstanceLoopCharacteristics>` },
  { id: 'unknown-attribute',  carrier: 'serviceTask',
    ns: ['camunda', 'http://camunda.org/schema/1.0/bpmn'],
    attr: `camunda:asyncBefore="${MARK}"` },
  // Deliberately included as a case where dropping is CORRECT: incoming/outgoing
  // are derivable from the sequenceFlows and re-emitting them from state would be
  // duplication. Expected DROPPED and flagged benign, so the population is not
  // "everything we inject disappears" — a result that would say nothing.
  { id: 'incoming-ref',       carrier: 'serviceTask', benign: true,
    frag: `<bpmn:incoming>${MARK}</bpmn:incoming>` },
  // POSITIVE CONTROL. conditionExpression is read (src:9855) and re-emitted
  // (src:9540) unconditionally. If this one does not come back PRESERVED, the
  // probe is broken rather than the designer — a leg that goes red when the
  // subject is right, which is the failure this instrument has hit three times.
  { id: 'conditionExpression', carrier: 'sequenceFlow',
    frag: `<bpmn:conditionExpression xsi:type="bpmn:tFormalExpression" `
        + `xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">${MARK}</bpmn:conditionExpression>` },
];
const EXPECTED_CONTENT = {
  'documentation':       'CONTENT-DROPPED',
  'ext-foreign-child':   'CONTENT-DROPPED',
  'property':            'CONTENT-DROPPED',
  'multiInstanceLoop':   'CONTENT-DROPPED',
  'unknown-attribute':   'CONTENT-DROPPED',
  'incoming-ref':        'CONTENT-DROPPED',
  'conditionExpression': 'CONTENT-PRESERVED',
};

// Locate the element carrying a given uid. Identity is aef:uid, never the display
// id — display ids are recomputed from lane+ordinal+name by the change under test
// (T-341), so a display-id lookup measures renumbering.
// ---------------------------------------------------------------------------
// Population 6 (T-348) — ROOT-LEVEL SIBLINGS OF THE PROCESS.
//
// Populations 1-5 all ask about one bpmn:process and what lives inside it.
// parseBpmnXml takes processes[0], participant[0] and laneSets[0] — first-only,
// no complement branch — so definitions' OTHER children are a granularity above
// anything measured so far.
//
// The reason this is not just "T-347 with bigger elements": these root elements
// are REFERENCED by things the designer does emit. If a referent is dropped but
// its reference kept, the output is INVALID BPMN rather than merely poorer BPMN.
// That verdict is read off the emitted document by resolving every *Ref/*ref
// attribute against the ids present in it — never predicted from reading
// buildBpmnXml, which is how T-335 nearly shipped a predicate that could not
// be false.
// ---------------------------------------------------------------------------
const RMARK = 'T348MARK';

const ROOT_CASES = [
  // POSITIVE CONTROL. Pool identity is input-derived (partEl?.name || procName ->
  // state.pool.name) and re-emitted on bpmn:participant. It MUST come back. If it
  // reads dropped, the probe is injecting into a document the editor never saw and
  // every other row in this population is meaningless.
  { id: 'pool-identity', control: true, kind: 'identity' },

  // A whole second process — T-337's class at the largest granularity available.
  { id: 'second-process', kind: 'definitions-child',
    frag: `<bpmn:process id="${RMARK}_p2" isExecutable="false">`
        + `<bpmn:task id="${RMARK}_t2" name="${RMARK}"/></bpmn:process>` },

  { id: 'root-message', kind: 'definitions-child',
    frag: `<bpmn:message id="${RMARK}_msg" name="${RMARK}"/>` },
  { id: 'root-signal', kind: 'definitions-child',
    frag: `<bpmn:signal id="${RMARK}_sig" name="${RMARK}"/>` },
  { id: 'root-error', kind: 'definitions-child',
    frag: `<bpmn:error id="${RMARK}_err" name="${RMARK}" errorCode="${RMARK}"/>` },
  { id: 'root-datastore', kind: 'definitions-child',
    frag: `<bpmn:dataStore id="${RMARK}_ds" name="${RMARK}"/>` },

  // Inside the collaboration the editor itself emits: a SECOND pool, and a
  // message flow between pools. This is the shape every mainstream modeller
  // produces for a multi-pool diagram.
  { id: 'second-participant', kind: 'collaboration-child',
    frag: `<bpmn:participant id="${RMARK}_part" name="${RMARK}" processRef="${RMARK}_p2"/>` },
  { id: 'message-flow', kind: 'collaboration-child',
    frag: `<bpmn:messageFlow id="${RMARK}_mf" name="${RMARK}" `
        + `sourceRef="${RMARK}_part" targetRef="${RMARK}_part"/>` },
];

const EXPECTED_ROOT = {
  'pool-identity':      'ROOT-PRESERVED',
  'second-process':     'ROOT-DROPPED',
  'root-message':       'ROOT-DROPPED',
  'root-signal':        'ROOT-DROPPED',
  'root-error':         'ROOT-DROPPED',
  'root-datastore':     'ROOT-DROPPED',
  'second-participant': 'ROOT-DROPPED',
  'message-flow':       'ROOT-DROPPED',
};

// --- population 7: do we GENERATE a competing carrier? (T-419) --------------
// Populations 1-6 all ask what the importer LOSES. This one asks the opposite
// question, and it is the one PL-114 turns on: for a fact the input already
// carries in standard form, does our EXPORTER emit a second, rival representation
// of the same fact?
//
// That single bit decides four import rulings:
//
//   granularity                        rival carrier?   ruling
//   foreign flow-node tag (T-337)      no               (a) preserve   -- shipped
//   content in an accepted el (T-347)  no               (a) preserve   -- recommended
//   bpmndi geometry       (T-340)      YES aef:position (b) consume    -- recommended
//
// Preserving is right where nothing competes and wrong where something does: DI
// preserved beside a generated aef:position is two contradictory geometries in one
// document, with no user action. That is the whole argument for T-340 departing
// from its own precedent — and until now every cell of that table lived in prose in
// docs/reports/T-397-import-repair-semantics-brief.md and was measured nowhere.
//
// Not hypothetical. T-357 proposes retiring `aef:position` outright. If it ships,
// the DI row's premise is gone and nothing anywhere goes red — the brief keeps
// reading as true and the ruling keeps citing it.
//
// DERIVED, NOT DECLARED. The verdict is the set of markers in OUR namespace that
// appear in the output and not in the input, read out of the diff. No carrier is
// named in the logic: naming `aef:position` here would make the check agree with
// today's answer by construction, which is the close-the-member-in-hand move
// (T-418). The carrier's NAME is recorded in EXPECTED_CARRIER, so a different
// carrier appearing is drift rather than a silent pass.
const CARRIER_CASES = [
  // Geometry. The input must be a foreign document to pose the question at all:
  // standard DI present, `aef:position` absent. Stripping ours is what makes an
  // emitted aef:position GENERATED rather than merely preserved — leave it in and
  // the row measures nothing while looking identical.
  { id: 'geometry', fact: 'node position',
    prepare(xml) {
      const anchor = Object.keys(laneOfNode(xml))[0];
      if (!anchor) return null;
      const withDI = injectDI(xml, anchor);
      if (!withDI || !/<bpmndi:BPMNShape\b/.test(withDI)) return null;
      const foreign = withDI.replace(/[ \t]*<aef:position\b[^>]*\/>\r?\n?/g, '');
      if (foreign === withDI) return null;      // nothing stripped -> not a foreign doc
      return foreign;
    } },
  // Foreign flow-node tag: T-337's granularity. The tag's own bytes are the only
  // description of it we hold, so there is nothing for us to generate.
  { id: 'foreign-flownode', fact: 'an out-of-vocabulary flow node',
    prepare: xml => inject(xml, 'businessRuleTask') },
  // Content inside an element we accept: T-347's granularity. `documentation` is
  // author prose; we model no rival field for it.
  { id: 'element-content', fact: 'author documentation on a task',
    prepare(xml) {
      const inj = injectContent(xml, { carrier: 'serviceTask',
        frag: `<bpmn:documentation>${MARK}</bpmn:documentation>` });
      return inj ? inj.xml : null;
    } },
];

// The measured table. `CARRIER-GENERATED:<names>` names the rival carrier as
// DERIVED from the round trip, so both directions of drift fail: a carrier
// vanishing (T-357 retiring aef:position) and a carrier appearing where the brief
// says none (which would silently invert T-337's and T-347's rulings).
const EXPECTED_CARRIER = {
  'geometry':         'CARRIER-GENERATED:aef:position',
  'foreign-flownode': 'CARRIER-NONE',
  'element-content':  'CARRIER-NONE',
};

// Insert a root-level fragment. `definitions-child` goes before </bpmn:definitions>
// (DOM parsing does not enforce schema child order, and putting it last keeps the
// injected process from becoming processes[0] — which would measure a different
// and much louder defect than the one this row is about).
function injectRoot(xml, c) {
  if (c.kind === 'identity') {
    // Mark the carrier the editor actually reads for pool identity: the first
    // participant's name if there is one, else the process's name.
    const part = xml.match(/<bpmn:participant\b[^>]*\/>/);
    if (part && /\bname="/.test(part[0])) {
      return { xml: xml.replace(part[0], part[0].replace(/\bname="([^"]*)"/, `name="$1 ${RMARK}"`)), carrier: 'participant' };
    }
    const proc = xml.match(/<bpmn:process\b[^>]*>/);
    if (proc && /\bname="/.test(proc[0])) {
      return { xml: xml.replace(proc[0], proc[0].replace(/\bname="([^"]*)"/, `name="$1 ${RMARK}"`)), carrier: 'process' };
    }
    return null;
  }
  if (c.kind === 'collaboration-child') {
    const close = '</bpmn:collaboration>';
    if (!xml.includes(close)) return null;
    return { xml: xml.replace(close, c.frag + close), carrier: 'collaboration' };
  }
  const close = '</bpmn:definitions>';
  if (!xml.includes(close)) return null;
  return { xml: xml.replace(close, c.frag + close), carrier: 'definitions' };
}

// The BPMN attributes that are genuinely IDREFs into the same document.
//
// This list is explicit on purpose. The first version of this check matched any
// attribute whose name ended in "ref", which swept up AEF's OWN semantic `ref="…"`
// attribute — `ref="G-019"`, `ref="P-010 [--skip-acceptance-criteria]"`,
// `ref="docs/reports/*.md"` — and reported 21 "pre-existing dangling references"
// in every corpus export. Those are prose payloads, not element references, and
// the finding would have been entirely an artefact of the instrument. Naming the
// attributes is what stops the checker inventing its subject.
const IDREF_ATTRS = new Set([
  'sourceRef', 'targetRef', 'processRef', 'attachedToRef', 'bpmnElement',
  'messageRef', 'signalRef', 'errorRef', 'escalationRef', 'dataStoreRef',
  'categoryValueRef', 'dataObjectRef', 'default',
]);

// Every IDREF attribute value in the document that does not resolve to an id
// declared in the same document. Answers the dangling-reference question from
// the ARTIFACT rather than from a reading of the emitter.
function danglingRefs(xml) {
  const ids = new Set([...xml.matchAll(/\bid="([^"]*)"/g)].map(m => m[1]));
  const out = [];
  for (const m of xml.matchAll(/\b([A-Za-z]+)="([^"]*)"/g)) {
    const [, attr, val] = m;
    if (!IDREF_ATTRS.has(attr) || !val) continue;
    if (!ids.has(val)) out.push(`${attr}=${val}`);
  }
  // bpmn:incoming/outgoing and flowNodeRef carry ids as TEXT, not attributes
  for (const m of xml.matchAll(/<bpmn:(incoming|outgoing|flowNodeRef)>([^<]*)<\//g)) {
    if (!ids.has(m[2])) out.push(`${m[1]}=${m[2]}`);
  }
  return [...new Set(out)].sort();
}

function elementByUid(xml, tag, uid) {
  const re = new RegExp(`<bpmn:${tag}\\b[^>]*>[\\s\\S]*?</bpmn:${tag}>`, 'g');
  for (const m of xml.matchAll(re)) {
    if (m[0].includes(`<aef:uid value="${uid}"`)) return m[0];
  }
  return null;
}

// Inject a content fragment into the FIRST carrier element that is identifiable by
// uid, and hand back that uid so the verdict can be read off the same element
// after the round trip rather than off the document as a whole.
function injectContent(xml, c) {
  const re = new RegExp(`<bpmn:${c.carrier}\\b[^>]*>[\\s\\S]*?</bpmn:${c.carrier}>`);
  let head = xml;
  if (c.ns && !new RegExp(`xmlns:${c.ns[0]}=`).test(head)) {
    head = head.replace(/(<bpmn:definitions\b)/, `$1 xmlns:${c.ns[0]}="${c.ns[1]}"`);
  }
  const m = head.match(re);
  if (!m) return null;
  const um = m[0].match(/<aef:uid value="([^"]*)"/);
  if (!um) return null;                       // victim must be uid-identifiable
  let mutated;
  if (c.attr) {
    mutated = m[0].replace(new RegExp(`^<bpmn:${c.carrier}\\b`), `<bpmn:${c.carrier} ${c.attr}`);
  } else if (c.into) {
    const close = `</bpmn:${c.into}>`;
    if (!m[0].includes(close)) return null;   // no host block on this carrier
    mutated = m[0].replace(close, c.frag + close);
  } else {
    mutated = m[0].replace(new RegExp(`</bpmn:${c.carrier}>$`), c.frag + `</bpmn:${c.carrier}>`);
  }
  if (mutated === m[0]) return null;
  return { xml: head.replace(m[0], () => mutated), uid: um[1], tag: c.carrier };
}

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Counts taken from the DOCUMENT, never from editor state -- state is the thing
// under test, so counting it would make the guard agree with the defect.
const NON_FLOWNODE = new Set(['sequenceFlow', 'laneSet', 'extensionElements', 'documentation']);
function census(xml) {
  const proc = xml.match(/<bpmn:process\b[\s\S]*?<\/bpmn:process>/);
  const body = proc ? proc[0] : xml;
  const flows = (body.match(/<bpmn:sequenceFlow\b/g) || []).length;
  const lanes = (body.match(/<bpmn:lane\b/g) || []).length;
  // Direct children of <bpmn:process> that are not sequenceFlow/laneSet/etc.
  const opens = [...body.matchAll(/<bpmn:([A-Za-z]+)\b/g)].map(m => m[1]);
  const nodes = opens.filter(t => !NON_FLOWNODE.has(t) && t !== 'process' && t !== 'lane'
    && t !== 'flowNodeRef' && t !== 'incoming' && t !== 'outgoing'
    && t !== 'conditionExpression').length;
  return { nodes, flows, lanes };
}

// Identity, not string presence. See the header note on the T-339 false reading.
const uidsOf = x => [...x.matchAll(/<aef:uid value="([^"]*)"/g)].map(m => m[1]);

const NODE_TAGS = 'serviceTask|userTask|scriptTask|startEvent|endEvent|exclusiveGateway'
  + '|parallelGateway|intermediateThrowEvent|intermediateCatchEvent|boundaryEvent|subProcess';

// Lane membership keyed by DISPLAY id — used only to pick a mutation target.
function laneOfNode(xml) {
  const m = {};
  const re = /<bpmn:lane\b[^>]*\bid="([^"]*)"[\s\S]*?<\/bpmn:lane>/g;
  let g;
  while ((g = re.exec(xml))) for (const r of g[0].matchAll(/<bpmn:flowNodeRef>([^<]*)<\/bpmn:flowNodeRef>/g)) m[r[1]] = g[1];
  return m;
}

// Lane membership keyed by UID. A <bpmn:flowNodeRef> names a node by its DISPLAY
// id, and the display id is computed from lane + ordinal + name — so it changes
// whenever a node is re-homed, and re-numbers that node's siblings besides.
// Comparing lane membership keyed by display id therefore measures renumbering,
// not re-homing: the first version of this figure read 2 where the true answer
// is 4. Resolve through aef:uid, which is the stable identity, and refuse to
// report the figure at all if any reference cannot be resolved.
function laneByUid(xml) {
  const idToUid = {};
  const re = new RegExp(`<bpmn:(${NODE_TAGS})\\b[^>]*\\bid="([^"]*)"[^>]*>([\\s\\S]*?)</bpmn:\\1>`, 'g');
  let g;
  while ((g = re.exec(xml))) {
    const u = g[3].match(/<aef:uid value="([^"]*)"/);
    idToUid[g[2]] = u ? u[1] : g[2];
  }
  const out = {}; const unmappable = [];
  const laneRe = /<bpmn:lane\b[^>]*\bid="([^"]*)"[\s\S]*?<\/bpmn:lane>/g;
  let l;
  while ((l = laneRe.exec(xml))) {
    for (const r of l[0].matchAll(/<bpmn:flowNodeRef>([^<]*)<\/bpmn:flowNodeRef>/g)) {
      const ref = r[1];
      if (ref === '__ghost__') continue;              // dangling by construction
      if (!(ref in idToUid)) { unmappable.push(ref); continue; }
      out[idToUid[ref]] = l[1];
    }
  }
  return { lanes: out, unmappable };
}

// Inject one element carrying `tag` into the process, wired into nothing, so the
// only thing that can remove it is the importer.
function inject(xml, tag) {
  const probeId = 'probe_' + tag;
  const el = `\n    <bpmn:${tag} id="${probeId}" name="Probe ${tag}">\n`
    + `      <bpmn:extensionElements><aef:uid value="${probeId}"/></bpmn:extensionElements>\n`
    + `    </bpmn:${tag}>\n`;
  const at = xml.indexOf('</bpmn:process>');
  if (at < 0) return null;
  return xml.slice(0, at) + el + xml.slice(at);
}

// A minimal, standards-correct BPMN DI block. The corpus has none, so this probe
// BUILDS its carrier rather than mutating an absent one -- otherwise the case
// would silently skip and a population of zero would read as a pass.
function injectDI(xml, realNodeId) {
  const di = `
  <bpmndi:BPMNDiagram id="DIProbe">
    <bpmndi:BPMNPlane id="PlaneProbe" bpmnElement="Process_1">
      <bpmndi:BPMNShape id="Shape_real" bpmnElement="${realNodeId}">
        <dc:Bounds x="100" y="100" width="100" height="80"/>
      </bpmndi:BPMNShape>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
`;
  let head = xml;
  if (!/xmlns:bpmndi=/.test(head)) {
    head = head.replace(/(<bpmn:definitions\b)/,
      '$1 xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"');
  }
  const at = head.indexOf('</bpmn:definitions>');
  if (at < 0) return null;
  return head.slice(0, at) + di + head.slice(at);
}

const setStr = s => [...s].sort().join('+');

// Every marker in a namespace WE own that appears anywhere in a document, as
// element names and as attribute names. Used only as a DIFF between input and
// output, so the answer to "did we generate a carrier" is read out of the data
// rather than compared against a list of carriers someone remembered to maintain.
function ownMarkers(xml) {
  const out = new Set();
  for (const m of xml.matchAll(/<(aef:[\w.-]+)/g)) out.add(m[1]);
  for (const m of xml.matchAll(/\s(aef:[\w.-]+)\s*=/g)) out.add('@' + m[1]);
  return out;
}

async function main() {
  if (!existsSync(CORPUS)) { console.log('FAIL: no corpus at ' + CORPUS); process.exitCode = 2; return; }
  const files = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!files.length) { console.log('FAIL: corpus empty'); process.exitCode = 2; return; }
  const maps = files.map(f => ({ name: basename(f, '.bpmn'), text: readFileSync(join(CORPUS, f), 'utf8') }));

  const doc = mkdtempSync(join(tmpdir(), 't338-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't338-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't338-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(200);

    const roundTrip = async text => {
      await ev(cmd, `window.__X__ = ${JSON.stringify(text)};`);
      return await ev(cmd, `(function(){ try {
        state = parseBpmnXml(window.__X__); refreshDisplayIds();
        return { xml: buildBpmnXml(state) };
      } catch(e) { return { threw: String(e && e.message || e) }; } })()`);
    };

    const problems = [];

    // -- leg 1: the corpus must be lossless -------------------------------
    const corpusLoss = [];
    for (const m of maps) {
      const r = await roundTrip(m.text);
      if (r.threw) { corpusLoss.push({ map: m.name, threw: r.threw }); continue; }
      const a = census(m.text), b = census(r.xml);
      if (a.nodes !== b.nodes || a.flows !== b.flows || a.lanes !== b.lanes) {
        corpusLoss.push({ map: m.name, input: a, output: b });
      }
    }

    // -- leg 2: which out-of-vocabulary tags lose content? ----------------
    // Measured, every run. The tag is present in the input by construction
    // (asserted), so a missing tag in the output is a loss and nothing else.
    const observedLossy = new Set();
    const probeRows = [];
    const notInjected = [];
    for (const tag of PROBE_TAGS) {
      const src = inject(maps[0].text, tag);
      if (src === null) { notInjected.push(tag); continue; }
      if (!new RegExp(`<bpmn:${tag}\\b`).test(src)) { notInjected.push(tag); continue; }
      const r = await roundTrip(src);
      if (r.threw) { probeRows.push({ tag, threw: r.threw }); observedLossy.add(tag); continue; }
      const kept = new RegExp(`<bpmn:${tag}\\b`).test(r.xml);
      if (!kept) observedLossy.add(tag);
      probeRows.push({ tag, kept });
    }

    // -- leg 3: malformed input (G-016 clause 1) --------------------------
    // Three-way. Only SILENTLY-PARTIAL is a defect: refusing a broken document
    // is correct behaviour and must not be able to turn this guard red.
    const malformedRows = [];
    for (const c of MALFORMED) {
      const verdicts = new Set();
      let applied = 0, partial = 0;
      for (const m of maps) {
        const src = c.fn(m.text);
        if (src === m.text) continue;           // mutation did not apply to this map
        applied++;
        const r = await roundTrip(src);
        if (r.threw) { verdicts.add('REFUSED'); continue; }
        const a = census(src), b = census(r.xml);
        const same = a.nodes === b.nodes && a.flows === b.flows && a.lanes === b.lanes;
        if (same) verdicts.add('PRESERVED');
        else { verdicts.add('SILENTLY-PARTIAL'); partial++; }
      }
      if (applied === 0) problems.push(`malformed case '${c.id}' applied to 0 of ${maps.length} maps — nothing was measured`);
      malformedRows.push({ id: c.id, applied, partial, verdict: setStr(verdicts) });
    }

    // -- leg 4: unresolvable refs (G-016 clause 3) ------------------------
    // Identity is the axis. Lane re-homing is counted and printed, not gated.
    const refRows = [];
    for (const c of REF_CASES) {
      const verdicts = new Set();
      let applied = 0, rehomed = 0, lost = 0;
      const rehomedTo = new Set();
      for (const m of maps) {
        const src = c.fn(m.text);
        if (src === m.text) continue;
        applied++;
        const r = await roundTrip(src);
        if (r.threw) { verdicts.add('REFUSED'); continue; }
        const uIn = new Set(uidsOf(src)), uOut = new Set(uidsOf(r.xml));
        const missing = [...uIn].filter(u => !uOut.has(u));
        if (missing.length) { verdicts.add('UID-LOST'); lost++; }
        else verdicts.add('UID-KEPT');

        // Lane comparison is baselined on the ORIGINAL document, never on the
        // mutated one. The mutation replaces the victim's flowNodeRef with a
        // ghost, so a before/after keyed on the mutated input EXCLUDES the very
        // node whose fate is the question — it can only ever report collateral
        // movement, and duly reported zero while the answer was four.
        const O = laneByUid(m.text), B = laneByUid(r.xml);
        if (O.unmappable.length || B.unmappable.length) {
          problems.push(`ref case '${c.id}' on map '${m.name}': ${O.unmappable.length + B.unmappable.length} `
            + `flowNodeRef(s) could not be resolved to a uid — the lane figure would be unsound, so it is not reported`);
          continue;
        }
        let movedHere = false;
        for (const u of Object.keys(O.lanes)) {
          const to = B.lanes[u] ?? '(none)';
          if (to !== O.lanes[u]) { movedHere = true; rehomedTo.add(`${O.lanes[u]}→${to}`); }
        }
        if (movedHere) { rehomed++; verdicts.add('LANE-REHOMED'); }
      }
      if (applied === 0) problems.push(`ref case '${c.id}' applied to 0 of ${maps.length} maps — nothing was measured`);
      refRows.push({ id: c.id, applied, rehomed, lost, moves: [...rehomedTo].sort(), verdict: setStr(verdicts) });
    }

    // -- leg 5: an unknown SUB-TREE (standard BPMN DI) --------------------
    let diApplied = 0, diKept = 0;
    for (const m of maps) {
      const anchor = Object.keys(laneOfNode(m.text))[0];
      if (!anchor) continue;
      const src = injectDI(m.text, anchor);
      if (!src || !/<bpmndi:BPMNShape\b/.test(src)) continue;   // carrier not built
      diApplied++;
      const r = await roundTrip(src);
      if (r.threw) continue;
      if (/<bpmndi:BPMNShape\b/.test(r.xml)) diKept++;
    }
    if (diApplied === 0) problems.push('DI probe carrier could not be built on any map — nothing was measured');
    const diVerdict = diKept === 0 ? 'DI-DROPPED' : (diKept === diApplied ? 'DI-PRESERVED' : 'DI-MIXED');

    // -- leg 6: CONTENT of an accepted element (T-346) ---------------------
    // The verdict is read off the element bearing the victim's uid, not off the
    // document: content that survives but is relocated onto a different element is
    // a different outcome from content that survives in place, and a whole-document
    // search cannot tell them apart.
    const contentRows = [];
    for (const c of CONTENT_CASES) {
      const verdicts = new Set();
      let applied = 0;
      for (const m of maps) {
        const inj = injectContent(m.text, c);
        if (!inj) continue;                        // carrier absent on this map
        if (!inj.xml.includes(MARK)) {
          problems.push(`content case '${c.id}' on map '${m.name}': injection reported success but the marker is not in the input — the probe would have measured nothing`);
          continue;
        }
        applied++;
        const r = await roundTrip(inj.xml);
        if (r.threw) { verdicts.add('REFUSED'); continue; }
        const el = elementByUid(r.xml, inj.tag, inj.uid);
        if (!el) { verdicts.add('CARRIER-LOST'); continue; }
        if (el.includes(MARK)) verdicts.add('CONTENT-PRESERVED');
        else if (r.xml.includes(MARK)) verdicts.add('CONTENT-MOVED');
        else verdicts.add('CONTENT-DROPPED');
      }
      if (applied === 0) problems.push(`content case '${c.id}' applied to 0 of ${maps.length} maps — nothing was measured`);
      contentRows.push({ id: c.id, applied, benign: !!c.benign, verdict: setStr(verdicts) });
    }

    // ---- population 6 (T-348): root-level siblings of the process -----------
    // The dangling-reference checker gets its own controls before it is used on
    // anything. A narrowed predicate that no longer fires is worth less than the
    // wide one it replaced, and the narrowing above was substantial.
    {
      const pos = danglingRefs('<a id="x"/><b sourceRef="missing"/>');
      const neg = danglingRefs('<a id="x"/><b sourceRef="x"/>');
      const ignored = danglingRefs('<a id="x"/><b ref="G-019"/>');
      if (pos.length === 0) problems.push('danglingRefs FAILED its positive control — an unresolvable sourceRef was not reported, so "no dangling references" below would mean nothing');
      if (neg.length !== 0) problems.push('danglingRefs FAILED its negative control — a resolvable sourceRef was reported as dangling');
      if (ignored.length !== 0) problems.push("danglingRefs FAILED its exclusion control — AEF's semantic ref=\"…\" attribute is being read as an IDREF again");
    }

    const rootRows = [];
    let baselineDangling = null;
    for (const c of ROOT_CASES) {
      const verdicts = new Set();
      const danglingSeen = new Set();
      let applied = 0;
      for (const m of maps) {
        const inj = injectRoot(m.text, c);
        if (!inj) continue;                        // carrier absent on this map
        if (!inj.xml.includes(RMARK)) {
          problems.push(`root case '${c.id}' on map '${m.name}': injection reported success but the marker is not in the input — the probe would have measured nothing`);
          continue;
        }
        applied++;
        const r = await roundTrip(inj.xml);
        if (r.threw) { verdicts.add('REFUSED'); continue; }
        verdicts.add(r.xml.includes(RMARK) ? 'ROOT-PRESERVED' : 'ROOT-DROPPED');
        for (const d of danglingRefs(r.xml)) danglingSeen.add(d);
      }
      if (applied === 0) problems.push(`root case '${c.id}' applied to 0 of ${maps.length} maps — nothing was measured`);
      rootRows.push({
        id: c.id, applied, control: !!c.control,
        verdict: setStr(verdicts),
        dangling: [...danglingSeen].sort(),
      });
    }

    // The dangling question needs a baseline: if the UNMUTATED corpus already
    // emits unresolvable refs, then finding them after an injection says nothing
    // about the injection. Measured, not assumed.
    {
      const seen = new Set();
      for (const m of maps) {
        const r = await roundTrip(m.text);
        if (!r.threw) for (const d of danglingRefs(r.xml)) seen.add(d);
      }
      baselineDangling = [...seen].sort();
    }

    // -- leg 8: does the exporter GENERATE a competing carrier? (T-419) -----
    // The verdict per case is the set of our-namespace markers the OUTPUT carries
    // and the INPUT did not. Read off the whole document rather than one element:
    // a carrier that appears on a different element than the fact it duplicates is
    // still a rival carrier, and a per-element read would miss exactly that.
    const carrierRows = [];
    for (const c of CARRIER_CASES) {
      const verdicts = new Set();
      const generated = new Set();
      let applied = 0;
      for (const m of maps) {
        const src = c.prepare(m.text);
        if (!src) continue;                        // shape not buildable on this map
        applied++;
        const r = await roundTrip(src);
        if (r.threw) { verdicts.add('REFUSED'); continue; }
        const before = ownMarkers(src), after = ownMarkers(r.xml);
        const fresh = [...after].filter(k => !before.has(k)).sort();
        for (const k of fresh) generated.add(k);
        verdicts.add(fresh.length ? 'CARRIER-GENERATED:' + fresh.join(',') : 'CARRIER-NONE');
      }
      if (applied === 0) problems.push(`carrier case '${c.id}' applied to 0 of ${maps.length} maps — nothing was measured`);
      carrierRows.push({ id: c.id, fact: c.fact, applied,
        generated: [...generated].sort(), verdict: setStr(verdicts) });
    }

    // -- population assertions: the guard must not pass by testing nothing --
    if (maps.length === 0) problems.push('corpus population is empty');
    if (probeRows.length === 0) problems.push('out-of-vocabulary population is empty — nothing was probed');
    if (notInjected.length) problems.push(`could not inject ${notInjected.length} probe tag(s): ${notInjected.join(', ')}`);
    // T-337: the other four populations each had this guard; population 1 did not,
    // because while EXPECTED_LOSSY held every tag an empty run failed anyway (10
    // entries would show as CLOSED). With the set emptied that protection is gone —
    // an empty PROBE_TAGS would now score a silent, vacuous pass.
    if (probeRows.length === 0) problems.push('out-of-vocabulary population is empty — nothing was probed');
    if (malformedRows.length === 0) problems.push('malformed population is empty — nothing was probed');
    if (refRows.length === 0) problems.push('unresolvable-ref population is empty — nothing was probed');
    if (contentRows.length === 0) problems.push('accepted-element content population is empty — nothing was probed');
    if (rootRows.length === 0) problems.push('root-sibling population is empty — nothing was probed');
    if (!rootRows.some(r => r.control)) problems.push('root-sibling population has no positive control — a population of only-expected-to-drop rows cannot tell loss from an injection that never landed');
    if (carrierRows.length === 0) problems.push('competing-carrier population is empty — nothing was probed');
    // Two of the three rows assert an ABSENCE, and an absence is also what a broken
    // detector reports. The geometry row is the positive control: it is the one case
    // where a carrier is known to be generated, so if IT reads CARRIER-NONE the other
    // two rows' CARRIER-NONE means nothing (G-022 — absence must not render as a
    // clean bill). Asserted structurally so the control cannot be dropped.
    if (!carrierRows.some(r => r.verdict.startsWith('CARRIER-GENERATED')))
      problems.push('competing-carrier population reports no generated carrier on ANY row — the detector cannot be shown capable of finding one, so every CARRIER-NONE in it is uninterpretable');

    // -- verdict ----------------------------------------------------------
    const appeared = [...observedLossy].filter(t => !EXPECTED_LOSSY.has(t)).sort();
    const closed = [...EXPECTED_LOSSY].filter(t => !observedLossy.has(t)).sort();

    const malformedDrift = malformedRows.filter(r => r.verdict !== EXPECTED_MALFORMED[r.id]);
    const refDrift = refRows.filter(r => r.verdict !== EXPECTED_REFS[r.id]);
    const diDrift = diVerdict !== EXPECTED_DI;
    const contentDrift = contentRows.filter(r => r.verdict !== EXPECTED_CONTENT[r.id]);
    // Content the designer drops that it is NOT correct to drop. `incoming-ref` is
    // marked benign because incoming/outgoing are derivable from the sequenceFlows;
    // everything else in this list is author-supplied content with no other carrier.
    const contentLost = contentRows.filter(r => !r.benign && r.verdict === 'CONTENT-DROPPED');
    const silentlyPartial = malformedRows.filter(r => r.partial > 0);
    const uidLost = refRows.filter(r => r.lost > 0);

    const rootDrift = rootRows.filter(r => r.verdict !== EXPECTED_ROOT[r.id]);
    const rootLost = rootRows.filter(r => !r.control && r.verdict === 'ROOT-DROPPED');
    // A reference that dangles in the OUTPUT but not in the untouched baseline is
    // caused by the injection — i.e. the designer kept a reference whose referent it
    // discarded. That is invalid BPMN, a strictly worse outcome than lossy BPMN.
    const newDangling = rootRows
      .map(r => ({ id: r.id, refs: r.dangling.filter(d => !baselineDangling.includes(d)) }))
      .filter(r => r.refs.length);

    const carrierDrift = carrierRows.filter(r => r.verdict !== EXPECTED_CARRIER[r.id]);

    const ok = corpusLoss.length === 0 && appeared.length === 0 && closed.length === 0
      && problems.length === 0 && malformedDrift.length === 0 && refDrift.length === 0 && !diDrift
      && contentDrift.length === 0 && rootDrift.length === 0 && carrierDrift.length === 0;

    if (JSON_OUT) {
      console.log(JSON.stringify({ ok, corpus: maps.length, corpusLoss, probed: probeRows.length,
        lossy: [...observedLossy].sort(), appeared, closed,
        malformed: malformedRows, refs: refRows, di: { verdict: diVerdict, applied: diApplied, kept: diKept },
        content: contentRows,
        root: rootRows, baselineDangling, newDangling,
        carrier: carrierRows,
        problems }, null, 2));
    } else {
      console.log(`input fidelity: ${maps.length} corpus maps round-tripped; ${probeRows.length} out-of-vocabulary tags, `
        + `${malformedRows.length} malformed shapes, ${refRows.length} unresolvable-ref shapes, 1 unknown sub-tree, `
        + `${contentRows.length} accepted-element content shapes, ${carrierRows.length} competing-carrier questions probed.`);
      console.log(`  corpus loss:  ${corpusLoss.length === 0 ? 'none — every map preserves node/flow/lane counts' : corpusLoss.length + ' map(s) LOST content'}`);
      console.log(`  lossy tags:   ${observedLossy.size}/${probeRows.length} — ${[...observedLossy].sort().join(', ') || '(none)'}`);
      console.log(`  malformed:    ${silentlyPartial.length === 0 ? 'no silent partial acceptance — every case refuses visibly or preserves' : silentlyPartial.length + ' case(s) SILENTLY ACCEPTED a broken document and lost content'}`);
      for (const r of malformedRows) console.log(`      ${r.id.padEnd(26)} ${r.verdict.padEnd(18)} (applied to ${r.applied}/${maps.length})`);
      console.log(`  refs:         ${uidLost.length === 0 ? 'no identity lost — every aef:uid survives an unresolvable reference' : uidLost.length + ' case(s) DESTROYED an identity'}`);
      for (const r of refRows) console.log(`      ${r.id.padEnd(26)} ${r.verdict.padEnd(22)} (applied ${r.applied}/${maps.length}; lane re-homed on ${r.rehomed}${r.moves.length ? ' — ' + r.moves.join(', ') : ''})`);
      console.log(`  sub-tree:     ${diVerdict} — standard BPMN DI injected on ${diApplied}/${maps.length} maps, survived on ${diKept}`);
      console.log(`  content:      ${contentLost.length === 0 ? 'no non-derivable content lost from accepted elements' : contentLost.length + ' shape(s) SILENTLY DROPPED from elements the importer accepted'}`);
      for (const r of contentRows) console.log(`      ${r.id.padEnd(22)} ${r.verdict.padEnd(19)} (applied ${r.applied}/${maps.length})${r.benign ? '  [derivable — dropping is correct]' : ''}`);
      console.log(`  root siblings:${rootLost.length === 0 ? ' no root-level sibling of the process is lost' : ' ' + rootLost.length + ' shape(s) SILENTLY DROPPED from definitions/collaboration'}`);
      for (const r of rootRows) console.log(`      ${r.id.padEnd(22)} ${r.verdict.padEnd(19)} (applied ${r.applied}/${maps.length})${r.control ? '  [POSITIVE CONTROL — must survive]' : ''}`);
      console.log(`  dangling refs:${newDangling.length === 0
        ? ` none introduced — output stays SELF-CONSISTENT (baseline ${baselineDangling.length === 0 ? 'clean' : baselineDangling.length + ' pre-existing'}); the loss is lossy-but-valid, not invalid`
        : ' ' + newDangling.length + ' case(s) left a reference whose referent was discarded — the output is INVALID BPMN: ' + newDangling.map(d => d.id + ' [' + d.refs.join(' ') + ']').join(', ')}`);
      console.log(`  carriers:     ${carrierDrift.length === 0 ? 'the competing-carrier table still describes the code — PL-114 holds as measured' : carrierDrift.length + ' row(s) MOVED — a ruling premise changed'}`);
      for (const r of carrierRows) console.log(`      ${r.id.padEnd(22)} ${r.verdict.padEnd(32)} (applied ${r.applied}/${maps.length}; ${r.fact})`);
      for (const p of problems) console.log(`  POPULATION:   ${p}`);
      for (const c of corpusLoss) console.log(`  LOSS ${c.map}: ${c.threw ? 'threw ' + c.threw : `in ${JSON.stringify(c.input)} out ${JSON.stringify(c.output)}`}`);
      if (appeared.length) console.log(`  FAIL: a NEW vocabulary gap appeared — ${appeared.join(', ')} now lose content on a load→save round trip. A tag the importer does not know is not rejected, it is invisible, and export writes only what state holds (T-337).`);
      if (closed.length) console.log(`  FAIL: a vocabulary gap CLOSED — ${closed.join(', ')} now survive the round trip. This is good news the guard cannot silently absorb: remove them from EXPECTED_LOSSY in this file and re-run, so the improvement is recorded rather than assumed.`);
      for (const r of malformedDrift) console.log(`  FAIL: malformed-input behaviour changed for '${r.id}' — expected ${EXPECTED_MALFORMED[r.id]}, measured ${r.verdict}. SILENTLY-PARTIAL means a broken document was accepted without complaint and content was dropped; any other change means the refuse/preserve behaviour moved and EXPECTED_MALFORMED must be updated deliberately.`);
      for (const r of refDrift) console.log(`  FAIL: unresolvable-ref behaviour changed for '${r.id}' — expected ${EXPECTED_REFS[r.id]}, measured ${r.verdict}. UID-LOST means an aef:uid present in the input is absent from the output: a dangling reference destroyed an identity, which is data loss and not a repair.`);
      for (const r of contentDrift) console.log(`  FAIL: accepted-element content behaviour changed for '${r.id}' — expected ${EXPECTED_CONTENT[r.id]}, measured ${r.verdict}. CONTENT-DROPPED means the importer accepted the element and silently discarded part of its body: the tag was in the allowlist, so no vocabulary check fires and node/flow/lane counts are unchanged (T-259 shipped this way once). CONTENT-PRESERVED where DROPPED was expected is good news the guard must not absorb — update EXPECTED_CONTENT deliberately. CONTENT-MOVED means the content survived on a DIFFERENT element than the one that carried it.`);
      for (const r of rootDrift) console.log(`  FAIL: root-sibling behaviour changed for '${r.id}' — expected ${EXPECTED_ROOT[r.id]}, measured ${r.verdict}. parseBpmnXml takes processes[0]/participant[0]/laneSets[0] with no complement branch, so definitions' other children never enter state and export writes only from state. ROOT-DROPPED on the POSITIVE CONTROL has TWO possible causes and the control cannot separate them: either the probe is no longer landing, or the identity round-trip itself regressed. Both invalidate every other row in this population — resolve which one it is before reading any of them. ROOT-PRESERVED where DROPPED was expected is good news that must be recorded in EXPECTED_ROOT deliberately, not absorbed.`);
      if (diDrift) console.log(`  FAIL: unknown sub-tree behaviour changed — expected ${EXPECTED_DI}, measured ${diVerdict}. DI-PRESERVED is good news that must be recorded in EXPECTED_DI rather than absorbed; DI-MIXED means the outcome now depends on the map.`);
      for (const r of carrierDrift) console.log(`  FAIL: competing-carrier answer changed for '${r.id}' (${r.fact}) — expected ${EXPECTED_CARRIER[r.id]}, measured ${r.verdict}. This is the premise PL-114 rests on, and four import rulings cite it (T-337 preserve, T-347 preserve, T-340 consume). GENERATED→NONE means we stopped emitting a rival carrier for a fact the input already carries — the reason T-340 departs from the T-337 precedent is gone, and the ruling must be re-argued, not re-expected (T-357 retiring aef:position would land exactly here). NONE→GENERATED means we started competing with content we currently preserve, which inverts that row's ruling the other way. Update EXPECTED_CARRIER only alongside the ruling it changes, and fix docs/reports/T-397-import-repair-semantics-brief.md in the same commit — the brief's table is the thing this row keeps honest.`);
      console.log(ok ? 'OK: every measured fidelity verdict matches expectation — corpus lossless, vocabulary gap set unchanged, no silent partial acceptance, no identity destroyed'
                     : 'FAIL: input fidelity moved — see above');
    }
    process.exitCode = ok ? 0 : 1;
  } catch (e) {
    console.log('FAIL: ' + String(e && e.stack || e));
    process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
