#!/usr/bin/env node
// _roundtrip-serialization-cdp.mjs — close G-002: prove the editor↔bridge aef: serialization
// seam is a SEMANTIC FIXED POINT, exercised through the REAL editor runtime (not a proxy).
//
// The 7 existing seam guards are static/text checks that each cover one aspect (meta-parity,
// field-coverage, structured-parity, extension-shape, namespace, mapping-conformance,
// forward-fixtures). None runs a true round trip. Only the editor JS can parse BPMN back into a
// re-emittable model (parseBpmnXml @ src/aef-workflow-designer.html:7959; buildBpmnXml @ :7830) —
// the Python bridge (tools/yaml-to-bpmn.py) is emit-only. So a genuine round trip is reachable
// only by driving the editor in a browser, which is what this harness does.
//
// For every tests/fixtures/aef-bpmn/*.bpmn it runs, IN THE REAL EDITOR:
//     m1    = parseBpmnXml(fixture)
//     emit1 = buildBpmnXml(state=m1)            // real import path: set state, refreshDisplayIds
//     m2    = parseBpmnXml(emit1)
//     emit2 = buildBpmnXml(state=m2)
// and asserts the SEMANTIC PROJECTION of m1 equals that of m2 — a fixed point on the
// governance-bearing content: aef:uid multiset (every flow node + every sequenceFlow), each
// node's aef:meta key→value map, node type + name, per-node lane authority, the edge
// source→target set (keyed by uid, so display-id churn is invisible), and workflowMeta.
// Presentational data (position, waypoints, routing hints — v1 §1 presentational class) is
// deliberately EXCLUDED: a diagram that differs only presentationally must round-trip identically
// in the semantic projection, which is exactly the property child-2's forward compile relies on.
//
// Gate (exit 0) requires, for every fixture:
//   - parse1 and parse2 both non-null;
//   - every node and every edge in m1 carries an aef:uid (identity hinge);
//   - buildBpmnXml is deterministic (emit(state)===emit(state));
//   - proj(m1) === proj(m2)  (the semantic fixed point).
// byteIdempotent (emit1===emit2, the stricter string-level fixed point) is REPORTED in the
// verdict but NOT gated — legitimate presentational churn can break bytes without semantic drift.
//
// Isolation: serves the editor from a TEMP docroot via gallery-serve.py on a free port, and
// drives it in an ISOLATED headless chromium with its own --user-data-dir — never the shared
// browser (G-006). Empty/missing fixtures dir ⇒ exit 1, not a vacuous pass (PL-022).
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
// T-591: aimable. Default is unchanged (`tests/fixtures/aef-bpmn`), so every existing caller
// and every gate that invokes this harness bare is byte-for-byte unaffected. The override
// exists so the EWCR Arc-0 pilot fixture — which lives outside the corpus, in
// docs/research/executable-workflow/fixtures/ — can be held to the SAME fixed-point bar as a
// corpus member without first being adopted into the corpus. Adoption is a contract decision;
// conformance is a measurement, and the measurement should not have to wait on the decision.
// A relative value resolves against the repo root, not the cwd, so the variable means the same
// thing from anywhere.
const _fxOverride = (process.env.ROUNDTRIP_FIXTURES_DIR || '').trim();
const FIXturesDir = _fxOverride
  ? (_fxOverride.startsWith('/') ? _fxOverride : join(REPO, _fxOverride))
  : join(REPO, 'tests', 'fixtures', 'aef-bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

// ── T-488: the SINGLE SOURCE for what the fixed point projects ────────────────────────────
//
// These lists used to be duplicated verbatim inside the two browser expressions below, and
// they had DIVERGED: the guard copy carried errorStatus/timerSpec/busTopic/hostRef/interrupting
// and the preflight copy did not, so the teeth-proof exercised a strict SUBSET of what the
// guard projected (OBS-045). Nothing detected that, because nothing compared the two copies —
// they were prose-coupled by a comment saying "keep in step with the copy below".
//
// Defined once here and interpolated into both expressions, so divergence is now structurally
// impossible rather than merely detectable. That is the T-484 distinction applied to our own
// instrument: a comment asking for agreement is a CLAIM, one definition is EVIDENCE.
//
// `shape` is the WIRE CARRIER, and it is here because the keys do not share one. A flat
// enumeration over heterogeneous shapes has nowhere to put the shape (PL-176), which is how
// the old self-test came to assume every key rides `key="..."`. Fourteen of these thirty-four
// do not, and were unreachable by that regex no matter how the loop was written:
//
//   metaattr    <aef:meta KEY="V"/>                   src:9278-9285   the twenty base keys
//   elemtext    <aef:KEY>V</aef:KEY>                  src:9286,9289-9290
//   elempaths   <aef:KEY paths="V"/>                  src:9287-9288
//   linkattr    <aef:link KEY="V"/>                   src:9296-9308
//   eventbind   <aef:eventDef binding="V"/>           src:9314-9317   ATTRIBUTE IS 'binding',
//                                                                     NOT the key name — which
//                                                                     is why `key="` never
//                                                                     matched these three
//   attachedref bpmn:boundaryEvent attachedToRef="V"  src:9327-9330   native BPMN attribute
//   cancelact   bpmn:boundaryEvent cancelActivity="V" src:9327-9330   native BPMN attribute
//
// The three `eventbind` keys are distinguished by NODE TYPE, not by attribute name
// (EVENT_BINDING_FIELD, src:9257), so the self-test attributes a binding mutation to whichever
// key actually moved in the projection rather than guessing which of the three it hit.
const KEYSPEC = [
  { k: 'tier',            shape: 'metaattr'    }, { k: 'agentType',      shape: 'metaattr' },
  { k: 'decisionOwner',   shape: 'metaattr'    }, { k: 'triggeredBy',    shape: 'metaattr' },
  { k: 'terminalKind',    shape: 'metaattr'    }, { k: 'state',          shape: 'metaattr' },
  { k: 'note',            shape: 'metaattr'    }, { k: 'softFail',       shape: 'metaattr' },
  { k: 'section',         shape: 'metaattr'    }, { k: 'guard',          shape: 'metaattr' },
  { k: 'external',        shape: 'metaattr'    }, { k: 'exitCode',       shape: 'metaattr' },
  { k: 'autoTrigger',     shape: 'metaattr'    }, { k: 'trigger',        shape: 'metaattr' },
  { k: 'gatewayKind',     shape: 'metaattr'    }, { k: 'gate',           shape: 'metaattr' },
  { k: 'scopeOf',         shape: 'metaattr'    }, { k: 'horizon',        shape: 'metaattr' },
  { k: 'workflowType',    shape: 'metaattr'    }, { k: 'owner',          shape: 'metaattr' },
  // T-889 (T-888 ruling clause 2): the element's authority. Same metaattr carrier as the rest
  // of <aef:meta>; it is here because the emitter now projects it, and this entry was added
  // AFTER the guard went red naming it (orphan: authority, exit 2) — the derivation caught it,
  // it was not remembered.
  { k: 'authority',       shape: 'metaattr'    },
  // T-204 typed-event binding fields. Ride <aef:eventDef binding="V"/>.
  { k: 'errorStatus',     shape: 'eventbind'   }, { k: 'timerSpec',      shape: 'eventbind' },
  { k: 'busTopic',        shape: 'eventbind'   },
  // T-480 (closed OBS-041): projected DESPITE the frozen standard listing aef:endpoint in its
  // PRESENTATIONAL class. That listing is wrong and is registered as OBS-039 — aef:endpoint
  // carries the executable command a task node runs. DO NOT REMOVE THIS KEY to make the harness
  // conform to the standard; following section 1 faithfully is exactly how it went unguarded.
  { k: 'endpoint',        shape: 'elemtext'    },
  // T-482 scalars carried by standalone aef elements. workflowRef is the off-page seam binding
  // (S2/T-225); losing it silently on a round trip would unbind a cross-workflow jump.
  { k: 'contextReads',    shape: 'elempaths'   }, { k: 'artifactsWrites', shape: 'elempaths' },
  { k: 'decisionInput',   shape: 'elemtext'    }, { k: 'decisionOutputs', shape: 'elemtext' },
  { k: 'workflowRef',     shape: 'linkattr'    }, { k: 'name',            shape: 'linkattr' },
  { k: 'targetWorkflow',  shape: 'linkattr'    }, { k: 'linkId',          shape: 'linkattr' },
  // T-204 Slice 2: boundary attachment. These ride NATIVE bpmn:boundaryEvent attributes, not any
  // aef element — boundaryPos is the only cosmetic fraction that needs one, and it is
  // deliberately not projected (presentational).
  { k: 'hostRef',         shape: 'attachedref' }, { k: 'interrupting',    shape: 'cancelact' },
  // T-490: the T-259 preservation passthrough (src:9318-9325). These two were not excluded from
  // this list — they were simply never in it, which is the distinction the whole task turns on.
  // An exclusion with a reason is a decision; an absence is a hole, and this one was wearing
  // "34/34" as if it were a total. eventDefBinding shares the eventbind carrier and is separated
  // from the trio the same way they are separated from each other: by which key actually moved.
  { k: 'eventDefKind',    shape: 'eventkind'   }, { k: 'eventDefBinding', shape: 'eventbind' },
];
const METAKEYS = KEYSPEC.map(s => s.k);
// T-483: the STRUCTURED semantic values. These must NEVER be added to METAKEYS. The scalar
// projection body is String(aef[k]), and for these that is actively worse than leaving them out:
// array-valued members comma-join ambiguously, and dict-valued members become the CONSTANT
// "[object Object]", which compares equal to itself for every possible mutation. Absent is a
// known gap; that is a gap that reports itself as closed.
const STRUCTKEYS = ['emits', 'compensates', 'aggregation', 'multiInstance', 'timer', 'constituents'];
// aef:io is deliberately in NEITHER list. It is built from the inputs/outputs ARRAYS
// (src:9337-9345) and there is no aef.io scalar, so listing it in METAKEYS would read as coverage
// while the projection body skipped it as undefined — a green that cannot go red. It is projected
// structurally by structOf() instead.

// ── T-886: the DOCUMENT-level seam, which was outside every denominator above ────────────────
//
// Everything above this line is about the NODE-level aef.* seam. checkDenominator() derives its
// keys from inside aefExtensionXml(), so the process-level <aef:workflowMeta .../> attributes were
// never in its denominator BY CONSTRUCTION — not omitted, structurally unreachable. The old
// document-level projection was a hand-typed list of FOUR (id, tier_default, version, title)
// while the emitter writes TEN, and nothing compared the two.
//
// Measured by mutation under T-885 (the census this task is the repair for): with the attribute
// suppressed in the writer, uuid, description and kind each left every guard green. uuid is the
// finding — T-224 connector-referenceable identity, what off-page links resolve against, and
// byte-pinned cross-agent by AEF in offpage-seam.bpmn and s4-exemplar.bpmn. Stop emitting it and
// link resolution breaks on both sides of the seam with no test in this repository saying so.
//
// So the same two-part discipline the node level already earned is applied here: the DENOMINATOR
// is derived from the emitter, and every derived attribute must be either compared or excluded
// with a reason. WMSPEC is still a list someone typed — what makes it honest is that
// checkWmDenominator() fails when it disagrees with the emitter, so the next attribute added to
// the writer (T-889's aef:meta authority work is the immediate one) cannot enter unnoticed.
const WMSPEC = ['id', 'version', 'schemaVersion', 'uuid', 'title', 'description', 'tier_default', 'pageWidth', 'kind'];
// EXCLUSIONS ARE DATA AND CARRY A REASON — same contract as EXCLUDED above.
const WM_EXCLUDED = {
  source: 'WRITE-ONLY (T-885 census): the emitter writes source="..." (src:10441) and no reader anywhere reads it back, so a round-trip comparison is not a weak check but a structurally impossible one — the value cannot survive a parse that never parses it. It is a latent silent-drop, harmless today only because no map in the corpus authors it. Whether to stop emitting it or to read it back is a product question about a seam AEF byte-pins, filed as T-898 rather than decided inside a test harness.',
};
// The emitter anchor. A line range would slide off its subject, which is the same failure this
// check exists to catch one level up; the wmAttrs array literal is the named thing.
const WM_EMITTER_ANCHOR = 'const wmAttrs = [';
const WM_TAG = '<aef:workflowMeta ';
const WM_SCAN_TO = '</bpmn:extensionElements>';

// ── T-910: the same gap one element over, and the generalisation that answers it ─────────────
//
// T-886 closed the aef:workflowMeta hole with a derived denominator. That guarantee stops at the
// ELEMENT boundary: checkWmDenominator() anchored on `const wmAttrs = [`, so aef:laneMeta's
// attributes were outside it BY CONSTRUCTION — exactly as workflowMeta's were outside
// checkDenominator(). Measured under T-890 by mutation: suppressing the editor's authoringDefault
// writer entirely still left this harness pass:true, exit 0, reporting
// "wm-denominator: 0 unclassified / 10 written". The 10 were workflowMeta's.
//
// Of the four laneMeta attributes, two (authority, abbr) were incidentally compared by a
// hand-typed lanes projection and two (height, authoringDefault) were droppable from the emitter
// in silence — and nothing in the harness distinguished the two cases, because there was no
// denominator to state it against. `authority` being on the lucky side of that split was an
// accident, not a guarantee: it is §3's authority-of-record and nothing asserted it.
//
// WHY THIS IS SHARED RATHER THAN COPIED: a second hand-written derivation is the T-322 defect
// (one module-scope vocabulary, never a second copy) and would rebuild the original omission one
// element over — a list checked only by its author re-reading the same source.
//
// WHY IT READS THE EMISSION RATHER THAN A REGION: the region that holds the lane emission also
// holds `<bpmn:lane id="${...}" name="${...}">`. Hoovering attribute-looking text out of it would
// put another element's attributes in this element's denominator — coverage theatre inside the
// check written to prevent coverage theatre. So this reads the ELEMENT'S OWN EMISSION, and for
// each `${...}` in it that is not itself an inline attribute value, RESOLVES the local supplying
// it and reads what that local accumulates before the emission. An interpolation it cannot
// resolve THROWS rather than being skipped: an attribute arriving through a carrier this function
// does not understand must stop the run, because the alternative is a denominator that is
// silently short — which is the whole defect being repaired.
const ATTR_RX = /([A-Za-z_][A-Za-z0-9_]*)="\$\{/g;
function deriveEmittedAttrs({ label, tag, scanFrom, scanTo }) {
  const srcAll = readFileSync(SRC_HTML, 'utf8');
  const a = srcAll.indexOf(scanFrom);
  if (a < 0) throw new Error(`${label}: "${scanFrom}" not found in ${SRC_HTML} — the anchor moved, fix the anchor rather than the expectation`);
  const z = srcAll.indexOf(scanTo, a);
  if (z < 0) throw new Error(`${label}: no "${scanTo}" after "${scanFrom}" — the carrier changed`);
  const region = srcAll.slice(a, z);
  const e = region.indexOf(tag);
  if (e < 0) throw new Error(`${label}: no ${tag} emission between the anchors — the carrier changed`);
  if (region.indexOf(tag, e + 1) >= 0) throw new Error(`${label}: more than one ${tag} emission between the anchors — this derivation reads exactly one and would silently cover only the first`);
  const eol = region.indexOf('\n', e);
  const emission = region.slice(e, eol < 0 ? region.length : eol);
  const attrs = [];
  const unresolved = [];
  for (const m of emission.matchAll(ATTR_RX)) attrs.push(m[1]);
  for (const m of emission.matchAll(/\$\{([^}]*)\}/g)) {
    // An inline attribute value — already counted above. Recognised by the `NAME="` immediately
    // preceding the interpolation rather than by guessing at the expression's shape.
    if (/[A-Za-z_][A-Za-z0-9_]*="$/.test(emission.slice(0, m.index))) continue;
    // Only two carrier shapes resolve: a bare local (`${_ad}`) and a joined accumulator
    // (`${wmAttrs.join(' ')}`). ANY other expression is unresolvable BY POLICY, not by accident.
    //
    // This used to take the leading identifier of whatever the interpolation was, which let
    // `${lane.extra ? ... : ...}` resolve its base to the `for (const lane of lanesToEmit)` LOOP
    // VARIABLE — and then scan from the loop head to the emission, hoovering `id` and `name` off
    // the sibling <bpmn:lane> element into aef:laneMeta's denominator. Measured: derivedTotal 6,
    // orphans id+name. It happened to go red, but only because those two were not in LMSPEC; the
    // same off-target resolution against a list that did contain them would have gone GREEN over
    // a denominator describing the wrong element. Caught by case 8 of _t910-lanemeta-teeth.sh.
    const expr = m[1].trim();
    const base = /^[A-Za-z_][A-Za-z0-9_]*$/.test(expr)
      ? expr
      : (expr.match(/^([A-Za-z_][A-Za-z0-9_]*)\.join\([^()]*\)$/) || [])[1];
    // And it must resolve to a real ASSIGNMENT. `for (const x of ...)` binds x without assigning
    // a fragment to it, so accepting it is what let the loop variable through above.
    const decl = base ? region.search(new RegExp(`(?:^|[;{\\n])\\s*(?:const|let|var)\\s+${base}\\s*=`)) : -1;
    if (decl < 0 || decl > e) { unresolved.push(expr); continue; }
    for (const a2 of region.slice(decl, e).matchAll(ATTR_RX)) attrs.push(a2[1]);
  }
  if (unresolved.length) throw new Error(`${label}: ${unresolved.length} interpolation(s) in the ${tag} emission this derivation cannot resolve to a local declared before it: ${unresolved.join(' | ')} — an attribute arriving through an unrecognised carrier stops the run rather than going missing from the denominator`);
  return [...new Set(attrs)];
}
// The contract every element-level denominator holds: derived-from-the-emitter, and every derived
// attribute either compared or excluded WITH A REASON. Shared so the two levels cannot drift, and
// so a third arrives by adding data rather than by writing a third checker.
function checkElementDenominator({ label, elementName, tag, scanFrom, scanTo, spec, excluded }) {
  const derived = deriveEmittedAttrs({ label, tag, scanFrom, scanTo });
  const compared = new Set(spec);
  const problems = [];
  for (const [name, reason] of Object.entries(excluded))
    if (!reason || !reason.trim()) problems.push(`${label} exclusion "${name}" has no reason — an exclusion without a reason is an absence wearing a decision's clothes`);
  for (const name of Object.keys(excluded))
    if (compared.has(name)) problems.push(`"${name}" is both compared and excluded in ${label} — one of the two is wrong`);
  const orphans = derived.filter(k => !compared.has(k) && !(k in excluded)).sort();
  if (orphans.length) problems.push(`${orphans.length} emitter-written ${elementName} attribute(s) NEITHER compared NOR excluded: ${orphans.join(', ')} — add it to the compared list, or to the exclusion map with a reason`);
  // Dead coverage reads as real coverage: a compared entry the emitter does not write can never
  // go red, so it inflates the fraction while guarding nothing.
  const specNotWritten = spec.filter(k => !derived.includes(k)).sort();
  if (specNotWritten.length) problems.push(`${label} compares ${elementName} attribute(s) the emitter does not write: ${specNotWritten.join(', ')} — dead coverage reads as real coverage`);
  return { problems, derived: derived.sort(), derivedTotal: derived.length, compared: [...compared].sort(), excluded: Object.keys(excluded).sort(), orphans };
}
function checkWmDenominator() {
  return checkElementDenominator({
    label: 'wm-denominator', elementName: 'aef:workflowMeta',
    tag: WM_TAG, scanFrom: WM_EMITTER_ANCHOR, scanTo: WM_SCAN_TO,
    spec: WMSPEC, excluded: WM_EXCLUDED,
  });
}

// ── T-910: aef:laneMeta, the LANE-level seam ─────────────────────────────────────────────────
// Emitted at src:10495 inside the lane loop. authoringDefault (T-890) arrives through the local
// `_ad` rather than inline, which is precisely the carrier shape deriveEmittedAttrs() resolves —
// and precisely the one a naive line-scan of the emission alone would miss.
const LMSPEC = ['abbr', 'authority', 'authoringDefault', 'height'];
// EXCLUSIONS ARE DATA AND CARRY A REASON — same contract as WM_EXCLUDED and EXCLUDED above.
// Empty today: all four laneMeta attributes are read back by the parser (src:10875-10884), so all
// four are round-trip comparable and none has an honest reason to sit outside the comparison.
const LM_EXCLUDED = {};
const LM_EMITTER_ANCHOR = 'const lanesToEmit =';
const LM_TAG = '<aef:laneMeta ';
const LM_SCAN_TO = '</bpmn:laneSet>';
function checkLmDenominator() {
  return checkElementDenominator({
    label: 'lm-denominator', elementName: 'aef:laneMeta',
    tag: LM_TAG, scanFrom: LM_EMITTER_ANCHOR, scanTo: LM_SCAN_TO,
    spec: LMSPEC, excluded: LM_EXCLUDED,
  });
}

// ── T-490: the denominator is DERIVED, not asserted ─────────────────────────────────────────
// KEYSPEC above is a list I typed by reading the emitter. So was AEF's `_KNOWN_EXT`; so were the
// two METAKEYS copies T-488 found already divergent by five keys (OBS-045). A hand-typed list can
// only ever be checked by the person who typed it re-reading the same source, which is the one
// check guaranteed to reproduce the original omission. `proven_fraction: 34/34` was true of the
// 34 and silent about whether 34 was the total; eventDefKind/eventDefBinding were outside it.
//
// This derives the emitter's projected-scalar set FROM THE EMITTER and fails on any identifier
// that is in neither KEYSPEC nor a documented exclusion. Anchored on the function NAME
// (aefExtensionXml, src:9259) rather than a line range, because a range that silently slides off
// its subject is the same failure one level up: a check that scans the wrong region reports clean.
//
// EXCLUSIONS ARE DATA AND CARRY A REASON. A bare name with an empty reason fails the check — the
// point is that removing a key from coverage has to cost a sentence, so it stays a decision
// instead of decaying into an absence.
const SRC_HTML = join(REPO, 'src', 'aef-workflow-designer.html');
const PROJECTION_FN = 'aefExtensionXml';
const EXCLUDED = {
  emits:         'STRUCTURED (T-483): array/dict-valued, String() gives "[object Object]" which compares equal to itself for every mutation — covered structurally by structOf(), not as a scalar',
  compensates:   'STRUCTURED (T-483): as emits',
  aggregation:   'STRUCTURED (T-483): as emits',
  multiInstance: 'STRUCTURED (T-483): as emits',
  timer:         'STRUCTURED (T-483): as emits',
  constituents:  'STRUCTURED (T-483): as emits',
  boundaryPos:   'PRESENTATIONAL (v1 §1, like aef:position): the cosmetic perimeter fraction, deliberately outside the semantic projection this guard is a fixed point over',
};
// Computed accesses — aef[<var>] — cannot be read as literal keys. Each must name the source it
// iterates, so a new computed access cannot enter the emitter unnoticed by reading as a variable.
//
// T-905: THE DECLARATION IS VERIFIED, NOT TRUSTED. Until T-905 this table was `k: 'metaKeys',
// key: 'metaKeys', bindField: 'EVENT_BINDING_FIELD'` and checkDenominator() only asked whether an
// entry EXISTED for each computed variable. Measured under T-904: `key` never iterates metaKeys —
// it walks STRUCT_LIST_KEYS, an inline array and structItemList — and `k` ranges over the node's whole
// key bag (Object.keys(aef) / aefKeys / carriedKeys), of which metaKeys is one filtered slice. A
// misdeclaration was indistinguishable from a correct one, which is the false-green shape this
// guard exists to remove. Now deriveBindingSources() reads, from the stripped body, every site
// that BINDS the variable (for-of/in, .filter/.map callbacks, const =) and the declaration below
// must match that set exactly, and every declared source must exist where it says it lives.
//
// Source kinds, because they contribute to the projection differently:
//   literal — an array literal in the body whose string elements are projected keys (metaKeys)
//   object  — an object literal in the body whose KEYS are projected keys (STRUCT_LIST_KEYS, structItemList)
//   inline  — an inline array literal iterated directly; its elements are projected keys
//   bag     — the node's own key bag: an OPEN set that comes from the document (T-570 carriage).
//             It cannot be enumerated from the emitter; it is REPORTED as open rather than implied
//             enumerated, which is the honest form of "derived FROM the emitter" for that range.
//   module  — a module-scope literal above the function (EVENT_BINDING_FIELD), handled by bindFields
//   moduleObject — T-573: a module-scope OBJECT whose KEYS are projected keys
//             (STRUCT_LIST_KEYS). `object` resolves inside the emitter body only, so a shared
//             vocabulary hoisted OUT of the body reads as "does not exist in the emitter" — which
//             is what happened, correctly, when T-573 moved STRUCT_LIST_KEYS to module scope so the
//             properties panel could read it instead of becoming a third copy (T-322).
//             Still DERIVED FROM CODE, which is this guard's whole point: the keys are read out of
//             the constant the emitter names, never from a hand-maintained list. A new kind rather
//             than widening `object` to search module scope: `object` asserts body-locality, and
//             silently relaxing it would let a genuinely absent literal resolve against any
//             same-named thing elsewhere in a 12k-line file.
const COMPUTED_SOURCES = {
  k: [
    { bag: 'Object.keys(aef)' },   // aefKeys = Object.keys(aef).filter(k => ...)
    { bag: 'aefKeys' },            // carriedKeys = aefKeys.filter(k => ...)
    { literal: 'metaKeys' },       // metaKeys.filter(k => aefKeys.includes(k))
    { bag: 'carriedKeys' },        // [...metaKeys.filter(...), ...carriedKeys].map(k => ...)
  ],
  key: [
    // T-573: was `structList`, an object literal inside the emitter. The triple it held was
    // written out twice in the editor and the properties panel needed a third reader, so it
    // was hoisted to one module-scope STRUCT_LIST_KEYS (T-322). This declaration is updated
    // rather than the code being reverted: T-905 built this check precisely so a rename could
    // not slip past, and it did not — the guard refused with "declares object source
    // 'structList' which does not exist in the emitter" before this line changed.
    { moduleObject: 'STRUCT_LIST_KEYS' },                       // for (const key in STRUCT_LIST_KEYS)
    { inline: "['aggregation', 'multiInstance', 'timer']" },   // for (const key of [...])
    { object: 'structItemList' },                              // for (const key in structItemList)
  ],
  bindField: [
    { module: 'EVENT_BINDING_FIELD' },                         // const bindField = EVENT_BINDING_FIELD[node.type]
  ],
};
const SOURCE_KINDS = ['literal', 'object', 'inline', 'bag', 'module', 'moduleObject'];
function sourceName(decl) { const kind = SOURCE_KINDS.find(k => k in decl); return kind ? { kind, name: decl[kind] } : null; }

// Walk backwards from index i (just before a `.filter(`/`.map(` dot) over one balanced receiver
// expression: an identifier chain, optionally ending in a balanced (...) / [...] group.
function receiverBefore(body, i) {
  let j = i - 1;
  while (j >= 0 && /\s/.test(body[j])) j--;   // a chained .map( may start on the next line
  const closeOf = { ')': '(', ']': '[' };
  while (j >= 0) {
    const c = body[j];
    if (c === ')' || c === ']') {           // balanced group — skip to its opener
      let depth = 0;
      for (; j >= 0; j--) {
        if (body[j] === c) depth++;
        else if (body[j] === closeOf[c]) { depth--; if (depth === 0) break; }
      }
      j--; continue;
    }
    if (/[A-Za-z0-9_.$]/.test(c)) { j--; continue; }
    break;
  }
  return body.slice(j + 1, i).trim().replace(/^\.\.\./, '');   // a spread element's head, not the dots
}
// Reduce a binding expression to the source NAMES it draws from, in the vocabulary of the table.
function sourceNamesOf(expr) {
  expr = expr.trim();
  if (expr.startsWith('[') && expr.includes('...')) {       // spread array: each element's head
    const inner = expr.slice(1, -1);
    const parts = []; let depth = 0, cur = '';
    for (const c of inner) {
      if (c === ',' && depth === 0) { parts.push(cur); cur = ''; continue; }
      if ('([{'.includes(c)) depth++; if (')]}'.includes(c)) depth--;
      cur += c;
    }
    parts.push(cur);
    return parts.flatMap(p => sourceNamesOf(p.trim().replace(/^\.\.\./, '')));
  }
  if (expr.startsWith('[')) return [expr.replace(/\s+/g, ' ')];   // inline literal, verbatim
  if (/^Object\.keys\(aef\)/.test(expr)) return ['Object.keys(aef)'];
  const head = /^([A-Za-z_$][\w$]*)/.exec(expr);
  return head ? [head[1]] : [expr];
}
function deriveBindingSources(body, v) {
  const found = new Set();
  const esc = v.replace(/[$]/g, '\\$&');
  for (const m of body.matchAll(new RegExp(`for\\s*\\(\\s*(?:const|let|var)\\s+${esc}\\s+(?:of|in)\\s+([^)]+)\\)`, 'g')))
    for (const n of sourceNamesOf(m[1])) found.add(n);
  for (const m of body.matchAll(new RegExp(`\\.(?:filter|map|forEach|some|every|find|flatMap)\\(\\s*${esc}\\s*=>`, 'g')))
    for (const n of sourceNamesOf(receiverBefore(body, m.index))) found.add(n);
  for (const m of body.matchAll(new RegExp(`(?:const|let|var)\\s+${esc}\\s*=\\s*([^;\\n]+)`, 'g')))
    for (const n of sourceNamesOf(m[1])) found.add(n);
  return found;
}
// Keys an OBJECT or INLINE source contributes to the projection: object-literal keys, or array elements.
function keysOfSource(body, srcAll, decl) {
  const { kind, name } = sourceName(decl);
  if (kind === 'object' || kind === 'moduleObject') {
    // T-573: `object` looks in the emitter body; `moduleObject` looks at the whole module.
    const where = kind === 'moduleObject' ? srcAll : body;
    const m = new RegExp(`const\\s+${name}\\s*=\\s*\\{([\\s\\S]*?)\\};`).exec(where);
    if (!m) return null;
    return [...m[1].matchAll(/(?:^|[,{\s])([A-Za-z_][A-Za-z0-9_]*)\s*:/g)].map(x => x[1]);
  }
  if (kind === 'inline') return [...name.matchAll(/'([A-Za-z_][A-Za-z0-9_]*)'/g)].map(x => x[1]);
  return [];
}
// Existence: where each declared source must be found, verbatim.
function sourceExists(body, srcAll, decl) {
  const { kind, name } = sourceName(decl);
  if (kind === 'bag') return name === 'Object.keys(aef)' ? body.includes('Object.keys(aef)') : new RegExp(`const\\s+${name}\\s*=`).test(body);
  if (kind === 'literal' || kind === 'object') return new RegExp(`const\\s+${name}\\s*=`).test(body);
  if (kind === 'inline') return body.replace(/\s+/g, ' ').includes(name);
  if (kind === 'module' || kind === 'moduleObject') return new RegExp(`const\\s+${name}\\s*=`).test(srcAll);
  return false;
}
function checkComputedSources(body, srcAll, computed) {
  const problems = [], report = {};
  for (const v of computed) {
    const decls = COMPUTED_SOURCES[v];
    if (!decls) { problems.push(`aef[${v}] is a computed access with no declared source — add it to COMPUTED_SOURCES naming the list it iterates`); continue; }
    const declared = [], open = [], contributed = [];
    for (const d of decls) {
      const sn = sourceName(d);
      if (!sn) { problems.push(`COMPUTED_SOURCES.${v}: a declaration has no recognised kind (${SOURCE_KINDS.join('|')})`); continue; }
      declared.push(sn.name);
      if (!sourceExists(body, srcAll, d)) { problems.push(`COMPUTED_SOURCES.${v} declares ${sn.kind} source "${sn.name}" which does not exist in the emitter — the declaration names something that is not there`); continue; }
      if (sn.kind === 'bag') open.push(sn.name);
      const ks = keysOfSource(body, srcAll, d);
      if (ks === null) problems.push(`COMPUTED_SOURCES.${v}: ${sn.kind} source "${sn.name}" exists but its literal did not parse`);
      else contributed.push(...ks);
    }
    const actual = deriveBindingSources(body, v);
    const undeclared = [...actual].filter(n => !declared.includes(n)).sort();
    const notBound = declared.filter(n => !actual.has(n)).sort();
    if (undeclared.length) problems.push(`aef[${v}] is bound from ${undeclared.join(', ')} which COMPUTED_SOURCES.${v} does not declare — the declaration is narrower than the code`);
    if (notBound.length) problems.push(`COMPUTED_SOURCES.${v} declares ${notBound.join(', ')} but the emitter never binds ${v} from it — the declaration names a source it does not iterate`);
    report[v] = { declared, actual: [...actual].sort(), open, contributed };
  }
  for (const v of Object.keys(COMPUTED_SOURCES)) if (!computed.has(v)) problems.push(`COMPUTED_SOURCES.${v} is declared but aef[${v}] no longer appears in the emitter — dead declaration`);
  return { problems, report };
}
// T-904: THE DERIVATION MATCHES CODE, NOT PROSE. Every regex below runs over comment-stripped
// text. Before this, deriveProjectedKeys() regexed the RAW function body, so a comment naming
// `node.aef.foo` entered the projected set exactly as an executable access would. Measured in
// T-889: deleting `authority` from metaKeys left this guard GREEN because a prose comment three
// lines above mentioned the accessor; deleting only that comment text — changing nothing the
// engine runs — turned the identical mutant RED. Both directions were live: FALSE GREEN for a
// key deleted from the emitter but still named in a comment, FALSE RED for a key only ever
// mentioned. The whole point of deriving FROM the emitter (T-886) is that the list cannot drift
// from the code; a derivation movable by text the engine never executes does not have that
// property. Quote-aware rather than a bare /\/\/.*$/ strip: today no string literal in the body
// contains "//" (measured, 0 occurrences), so a naive strip would be ACCIDENTALLY correct and
// would silently truncate real code the first time someone writes a URL in a string.
function stripJsComments(src) {
  let out = '', i = 0, q = null;         // q = the open quote char, or null outside a string
  while (i < src.length) {
    const c = src[i], d = src[i + 1];
    if (q) {
      if (c === '\\') { out += c + (d ?? ''); i += 2; continue; }   // escape: copy the pair whole
      if (c === q) q = null;
      out += c; i++; continue;
    }
    if (c === '"' || c === "'" || c === '`') { q = c; out += c; i++; continue; }
    if (c === '/' && d === '/') { while (i < src.length && src[i] !== '\n') i++; continue; }
    if (c === '/' && d === '*') {
      i += 2;
      while (i < src.length && !(src[i] === '*' && src[i + 1] === '/')) i++;
      i += 2; continue;
    }
    out += c; i++;
  }
  return out;
}
function deriveProjectedKeys() {
  const html = readFileSync(SRC_HTML, 'utf8').split('\n');
  const start = html.findIndex(l => l.startsWith(`function ${PROJECTION_FN}(`));
  if (start < 0) throw new Error(`denominator: ${PROJECTION_FN} not found in ${SRC_HTML} — the anchor moved, fix the anchor rather than the expectation`);
  let end = -1;
  for (let i = start + 1; i < html.length; i++) if (html[i] === '}') { end = i; break; }
  if (end < 0) throw new Error(`denominator: no column-0 close for ${PROJECTION_FN}`);
  // The anchor and the column-0 close are located on RAW lines (a comment cannot fake either),
  // then the slice is stripped once and every match below runs on the stripped text.
  const body = stripJsComments(html.slice(start, end + 1).join('\n'));

  const dot = new Set([...body.matchAll(/aef\.([A-Za-z_][A-Za-z0-9_]*)/g)].map(m => m[1]));
  const computed = new Set([...body.matchAll(/aef\[([A-Za-z_][A-Za-z0-9_]*)\]/g)].map(m => m[1]));

  // The metaKeys array literal, read from the emitter rather than re-typed.
  const mk = /const metaKeys\s*=\s*\[([\s\S]*?)\]/.exec(body);
  if (!mk) throw new Error('denominator: metaKeys literal not found inside ' + PROJECTION_FN);
  const metaKeys = [...mk[1].matchAll(/'([A-Za-z_][A-Za-z0-9_]*)'/g)].map(m => m[1]);

  // EVENT_BINDING_FIELD lives just above the function; its VALUES are projected keys.
  // Stripped too — a commented-out EVENT_BINDING_FIELD literal must not read as the live one,
  // which is the same defect one declaration over. But stripped PER LINE, not whole-file.
  // T-904 measured why: SRC_HTML is an HTML document, and stripJsComments is a JS stripper.
  // Running it over the whole file took it from 1,013,174 to 393,293 bytes — it ate 61% of the
  // document, because CSS `/* */` blocks and apostrophes in prose desync a JS quote scanner.
  // The bindFields happened to survive that, which is luck, not correctness. This declaration is
  // a single-line literal, so stripping candidate lines individually is both sufficient and
  // safe. Requiring exactly ONE surviving declaration is the real check: a commented-out copy
  // strips to nothing and drops out, and anything ambiguous (zero, or a second live one, or the
  // literal going multi-line) fails loud instead of silently picking the first match.
  const ebfLines = readFileSync(SRC_HTML, 'utf8').split('\n')
    .map(l => stripJsComments(l))
    .filter(l => /const EVENT_BINDING_FIELD\s*=/.test(l));
  if (ebfLines.length !== 1) throw new Error(`denominator: expected exactly 1 live EVENT_BINDING_FIELD declaration, found ${ebfLines.length} — if the literal went multi-line, widen this read deliberately rather than loosening the count`);
  const ebf = /const EVENT_BINDING_FIELD\s*=\s*\{([^}]*)\}/.exec(ebfLines[0]);
  if (!ebf) throw new Error('denominator: EVENT_BINDING_FIELD found but its object literal did not parse');
  const bindFields = [...ebf[1].matchAll(/:\s*'([A-Za-z_][A-Za-z0-9_]*)'/g)].map(m => m[1]);

  return { dot, computed, metaKeys, bindFields, body };
}
// hostRef / interrupting are NOT aef.* accesses — they ride native bpmn:boundaryEvent attributes
// emitted in buildBpmnXml (src:9643). Assert the mechanism still exists, so if the emitter stops
// writing them the denominator notices instead of the pair quietly becoming NEVER-PRESENT.
const NATIVE_KEYS = { hostRef: 'attachedToRef="', interrupting: 'cancelActivity="' };
function checkDenominator() {
  const { dot, computed, metaKeys, bindFields, body } = deriveProjectedKeys();
  const covered = new Set(METAKEYS);
  const problems = [];
  const srcAllForCs = readFileSync(SRC_HTML, 'utf8');
  // T-905: verified computed-source declarations; their object/inline sources join the projection.
  const cs = checkComputedSources(body, srcAllForCs, computed);
  problems.push(...cs.problems);

  for (const [name, reason] of Object.entries(EXCLUDED))
    if (!reason || !reason.trim()) problems.push(`exclusion "${name}" has no reason — an exclusion without a reason is an absence wearing a decision's clothes`);
  for (const name of Object.keys(EXCLUDED))
    if (covered.has(name)) problems.push(`"${name}" is both in KEYSPEC and in EXCLUDED — one of the two is wrong`);

  const projected = new Set([...dot, ...metaKeys, ...bindFields]);
  for (const r of Object.values(cs.report)) for (const k of r.contributed) projected.add(k);
  for (const v of computed) projected.delete(v); // the variable itself is not a key
  for (const v of Object.keys(COMPUTED_SOURCES)) projected.delete(v);

  const orphans = [...projected].filter(k => !covered.has(k) && !(k in EXCLUDED)).sort();
  if (orphans.length) problems.push(`${orphans.length} emitter-projected key(s) in NEITHER KEYSPEC nor EXCLUDED: ${orphans.join(', ')}`);

  const srcAll = readFileSync(SRC_HTML, 'utf8');
  for (const [k, needle] of Object.entries(NATIVE_KEYS)) {
    if (!covered.has(k)) problems.push(`native key "${k}" missing from KEYSPEC`);
    if (!srcAll.includes(needle)) problems.push(`native key "${k}": emitter no longer writes ${needle} — carrier changed, KEYSPEC shape is stale`);
  }
  // Total = everything the emitter projects, minus reasoned exclusions, plus the native pair.
  const total = new Set([...projected].filter(k => !(k in EXCLUDED)));
  for (const k of Object.keys(NATIVE_KEYS)) total.add(k);
  const missingFromSpec = [...total].filter(k => !covered.has(k)).sort();
  const specNotProjected = [...covered].filter(k => !total.has(k)).sort();
  if (specNotProjected.length) problems.push(`KEYSPEC contains key(s) the emitter does not project: ${specNotProjected.join(', ')} — dead coverage reads as real coverage`);

  const openSources = Object.entries(cs.report).flatMap(([v, r]) => r.open.map(n => `${v} <- ${n}`));
  return { problems, derivedTotal: total.size, missingFromSpec, orphans, specSize: covered.size, computedSources: cs.report, openSources };
}

// Self-test: perturb EVERY projected key in its own wire form and confirm the projection
// comparison detects each drift. Proves the guard bites per key — a green that cannot go red is
// worthless (PL-022 stance; mirrors test_forward_fixtures.py::_selftest).
//
// It used to `break` on the first key that matched, and `tier` is both first in the list and
// present in every document, so it reported hit:'tier' on EVERY run and proved the mechanism for
// exactly one key. Every key added afterwards had teeth only from one-shot task probes
// (tools/_t482-*, tools/_t483-*), which are completion-gate artifacts, not standing guards —
// PL-161. This folds that per-key knowledge into the gate that actually runs.
const PREFLIGHT_EXPR = `(function(){
  var text = window.__FIXTURE__;
  var KEYSPEC = ${JSON.stringify(KEYSPEC)};
  var METAKEYS = ${JSON.stringify(METAKEYS)};
  var STRUCTKEYS = ${JSON.stringify(STRUCTKEYS)};
  function canon(v){
    if(v===null || typeof v!=='object') return v;
    if(Object.prototype.toString.call(v)==='[object Array]') return v.map(canon);
    var o={}; Object.keys(v).sort().forEach(function(k){ o[k]=canon(v[k]); });
    return o;
  }
  function structOf(n){
    var aef=n.aef||{}, s={};
    STRUCTKEYS.forEach(function(k){ if(aef[k]!=null) s[k]=canon(aef[k]); });
    var io=n.io||{};
    var ins=io.inputs||[], outs=io.outputs||[];
    if(ins.length||outs.length) s.io={ inputs:canon(ins), outputs:canon(outs) };
    return s;
  }
  function proj(m){
    if(!m) return null;
    var uidOf={}; m.nodes.forEach(function(n){ uidOf[n.id]=n.uid; });
    var nodes=m.nodes.map(function(n){ var aef=n.aef||{},meta={};
      METAKEYS.forEach(function(k){ if(aef[k]!=null&&aef[k]!=='') meta[k]=String(aef[k]); });
      return {uid:n.uid,meta:meta,struct:structOf(n)}; }).sort(function(a,b){return a.uid<b.uid?-1:a.uid>b.uid?1:0;});
    return JSON.stringify(nodes);
  }
  // Per-key projected value, so a mutation can be attributed to the key it was aimed at rather
  // than merely to "something moved". This is what makes the eventbind trio separable: all three
  // ride the same binding= attribute and are told apart by node type, so the only honest way to
  // say WHICH key a binding mutation exercised is to read which key's value actually changed.
  function valuesOf(m,k){
    if(!m) return null;
    var out=[];
    m.nodes.forEach(function(n){ var a=n.aef||{}; if(a[k]!=null&&a[k]!=='') out.push(n.uid+'='+String(a[k])); });
    return out.sort().join('|');
  }
  // Mutate ONE key in its own wire carrier. Returns the mutated XML, or null when the key's
  // carrier is not present in this document (which is NOT-PRESENT, not a pass).
  var MARK='__DRIFT__';
  // Replace attr= INSIDE a named element only. An unanchored /k="/ is wrong for at least two
  // keys and silently so: a bare name= matches the first bpmn node or process name in the
  // document, and workflowType= matches the PROCESS-level aef:workflowMeta. Both mutate
  // something real, neither is the key under test, and because proj() covers nodes only,
  // neither moves the projection — so the key reports BLIND. A too-loose regex does not fail
  // loudly here, it manufactures a finding AGAINST THE GUARD. Measured: name read BLIND in
  // 18 of 18 fixtures on this probe's first run, and the guard was innocent.
  //
  // (No backticks in this comment. It lives inside a JS template literal, where a backtick
  //  ends the literal and the harness dies before evaluating anything. That is now the THIRD
  //  time this file has been broken this way — T-480, T-483, and again writing this note.
  //  Reading the warning two lines up is not the same as being protected by it.)
  function inElement(xml,elem,attr){
    var rx=new RegExp('<aef:'+elem+'\\\\s[^>]*>','g'),m;
    while((m=rx.exec(xml))!==null){
      var re=new RegExp('(\\\\s'+attr+'=")([^"]*)(")');
      if(re.test(m[0])) return xml.slice(0,m.index)+m[0].replace(re,'$1'+MARK+'$3')+xml.slice(m.index+m[0].length);
    }
    return null;
  }
  function mutate(xml,spec){
    var k=spec.k, re, m;
    if(spec.shape==='metaattr') return inElement(xml,'meta',k);
    if(spec.shape==='linkattr') return inElement(xml,'link',k);
    if(spec.shape==='elempaths'){
      re=new RegExp('(<aef:'+k+'\\\\s+paths=")([^"]*)(")');
      return re.test(xml) ? xml.replace(re,'$1'+MARK+'$3') : null;
    }
    if(spec.shape==='elemtext'){
      re=new RegExp('(<aef:'+k+'>)([^<]*)(</aef:'+k+'>)');
      return re.test(xml) ? xml.replace(re,'$1'+MARK+'$3') : null;
    }
    if(spec.shape==='eventbind'){
      // errorStatus / timerSpec / busTopic all ride the SAME binding= attribute and are told
      // apart by the node's type (EVENT_BINDING_FIELD, src:9257). So there is no regex that
      // targets one of them. Return every eventDef occurrence as a separate candidate and let
      // the caller keep the one that moved the key under test; mutating only the first reports
      // DRIFT-ELSEWHERE whenever the document's first typed event is not the wanted kind.
      var out=[],rx=/<aef:eventDef\\s[^>]*binding="[^"]*"[^>]*\\/>/g,g;
      while((g=rx.exec(xml))!==null){
        var one=g[0].replace(/(binding=")([^"]*)(")/,'$1'+MARK+'$3');
        if(one!==g[0]) out.push(xml.slice(0,g.index)+one+xml.slice(g.index+g[0].length));
      }
      return out.length?out:null;
    }
    if(spec.shape==='attachedref'){
      // Re-point the boundary event at a DIFFERENT existing flow node. A sentinel would be an
      // unresolvable ref, which exercises the T-341 rehome path rather than the projection.
      m=/<bpmn:boundaryEvent\\s[^>]*attachedToRef="([^"]*)"/.exec(xml);
      if(!m) return null;
      var ids=[],rx=/<bpmn:(?:serviceTask|task|userTask|scriptTask|businessRuleTask|manualTask|sendTask|receiveTask|subProcess)\\s[^>]*id="([^"]*)"/g,g;
      while((g=rx.exec(xml))!==null) if(g[1]!==m[1]) ids.push(g[1]);
      // The carrier IS here; there is just no second activity to re-point at. Reporting that as
      // NOT-PRESENT would file it beside keys genuinely missing from the corpus and send the
      // reader to write the wrong fixture. Distinct state, distinct remedy: this one needs a
      // document with TWO attachable hosts, not a document with boundary events.
      if(!ids.length) return {unexercisable:'boundaryEvent present but no alternative host activity to re-point at'};
      return xml.slice(0,m.index)+m[0].replace('attachedToRef="'+m[1]+'"','attachedToRef="'+ids[0]+'"')+xml.slice(m.index+m[0].length);
    }
    if(spec.shape==='eventkind'){
      // kind= on aef:eventDef. Sentinel rather than another VALID kind, deliberately: an
      // error->timer swap keeps the eventDef CONSUMED by the typed-catch override (src:9994), so
      // the value lands in errorStatus/timerSpec and this key never moves — DRIFT-ELSEWHERE, and
      // a reader would wrongly conclude kind= is not load-bearing. An unmappable sentinel leaves
      // the eventDef unconsumed, which is exactly the passthrough branch these two keys exist
      // for. Note what that means for the verdict: this proves kind= is load-bearing across the
      // round trip, which is the guard's job, NOT that a genuinely-unconsumed eventDef survives
      // faithfully. The corpus has no start/throw carrier to ask that second question of.
      var out=[],rx=/<aef:eventDef\\s[^>]*kind="[^"]*"[^>]*\\/>/g,g;
      while((g=rx.exec(xml))!==null){
        var one=g[0].replace(/(kind=")([^"]*)(")/,'$1'+MARK+'$3');
        if(one!==g[0]) out.push(xml.slice(0,g.index)+one+xml.slice(g.index+g[0].length));
      }
      return out.length?out:null;
    }
    if(spec.shape==='cancelact'){
      // Boolean carrier: a sentinel string would not be a legal value, so FLIP it.
      m=/(<bpmn:boundaryEvent\\s[^>]*cancelActivity=")(true|false)(")/.exec(xml);
      if(!m) return null;
      return xml.replace(m[0], m[1]+(m[2]==='true'?'false':'true')+m[3]);
    }
    return null;
  }
  try{
    var m1=parseBpmnXml(text); if(!m1) return {perturbable:false,reason:'parse-null'};
    state=m1; refreshDisplayIds();
    var emit1=buildBpmnXml(state);
    var p1=proj(m1);
    var results=[];
    for(var i=0;i<KEYSPEC.length;i++){
      var spec=KEYSPEC[i];
      var cands=mutate(emit1,spec);
      if(cands===null){ results.push({key:spec.k,shape:spec.shape,verdict:'NOT-PRESENT'}); continue; }
      if(cands&&cands.unexercisable){ results.push({key:spec.k,shape:spec.shape,verdict:'NOT-EXERCISABLE',reason:cands.unexercisable}); continue; }
      if(typeof cands==='string') cands=[cands];
      cands=cands.filter(function(c){ return c!==emit1; });
      if(!cands.length){ results.push({key:spec.k,shape:spec.shape,verdict:'NOT-PRESENT'}); continue; }
      // Best verdict across candidates: LIVE beats DRIFT-ELSEWHERE beats BLIND. Only the
      // eventbind shape yields more than one candidate, and there the wanted key is reachable
      // through exactly one of them.
      var best=null,bestMoved=null;
      for(var c=0;c<cands.length;c++){
        var m2=parseBpmnXml(cands[c]);
        if(!m2){ best='LIVE'; bestMoved=['<parse broke>']; break; }
        if(p1===proj(m2)){ if(best===null) best='BLIND'; continue; }
        var moved=[];
        for(var j=0;j<METAKEYS.length;j++) if(valuesOf(m1,METAKEYS[j])!==valuesOf(m2,METAKEYS[j])) moved.push(METAKEYS[j]);
        if(moved.indexOf(spec.k)>=0){ best='LIVE'; bestMoved=moved; break; }
        if(best!=='LIVE'){ best='DRIFT-ELSEWHERE'; bestMoved=moved; }
      }
      results.push({key:spec.k,shape:spec.shape,verdict:best,moved:bestMoved,candidates:cands.length});
    }
    // Restore the page's state so the per-fixture round trip that follows is unaffected.
    state=m1; refreshDisplayIds();
    return { perturbable:true, results:results };
  }catch(e){ return {perturbable:false,reason:'exception: '+(e&&e.message||e)}; }
})()`;

// T-886: the DOCUMENT-level self-test. Same question as the node-level one above, asked of the
// aef:workflowMeta attributes: with this attribute perturbed in its own wire carrier, does the
// projection move? A key in WMSPEC is a CLAIM of coverage; only a value that varies is EVIDENCE
// (PL-175), and T-885 proved the difference the expensive way — it predicted tier_default BARE
// and uuid COVERED, and both were backwards. Reading the projection is not a substitute for
// mutating it.
//
// Mutation is anchored INSIDE the aef:workflowMeta element, never document-wide. id=, version=
// and title= all match a bpmn: element long before they match this one, and an off-target
// mutation that lands somewhere real reports BLIND while the guard is innocent — measured on the
// node-level probe, 18 of 18 fixtures. (No backticks in this comment: it lives inside a JS
// template literal and a backtick kills the harness before it evaluates. Broken that way three
// times already.)
const WM_PREFLIGHT_EXPR = `(function(){
  var text = window.__FIXTURE__;
  var WMSPEC = ${JSON.stringify(WMSPEC)};
  var MARK='__DRIFT__';
  function wmProj(m){
    if(!m) return null;
    var o={}, s=m.workflowMeta||{};
    WMSPEC.forEach(function(k){ var v=s[k]; o[k]=(v==null||v==='')?null:String(v); });
    return JSON.stringify(o);
  }
  function wmValue(m,k){
    if(!m) return null;
    var v=(m.workflowMeta||{})[k];
    return (v==null||v==='')?null:String(v);
  }
  // Replace attr=" inside the aef:workflowMeta element only, returning null when this document
  // does not carry the attribute at all. Absent is NOT-PRESENT and is not a pass.
  function inWorkflowMeta(xml,attr){
    var rx=new RegExp('<aef:workflowMeta\\\\s[^>]*>','g'),m;
    while((m=rx.exec(xml))!==null){
      var re=new RegExp('(\\\\s'+attr+'=")([^"]*)(")');
      if(re.test(m[0])) return xml.slice(0,m.index)+m[0].replace(re,'$1'+MARK+'$3')+xml.slice(m.index+m[0].length);
    }
    return null;
  }
  try{
    var m1=parseBpmnXml(text);
    if(!m1) return {perturbable:false,reason:'parse1-null'};
    var p1=wmProj(m1);
    var results=[];
    for(var i=0;i<WMSPEC.length;i++){
      var k=WMSPEC[i];
      var mut=inWorkflowMeta(text,k);
      if(mut===null){ results.push({key:k,verdict:'NOT-PRESENT'}); continue; }
      if(mut===text){ results.push({key:k,verdict:'NOT-PRESENT'}); continue; }
      var m2=parseBpmnXml(mut);
      if(!m2){ results.push({key:k,verdict:'LIVE',moved:['<parse broke>']}); continue; }
      if(wmProj(m2)===p1){ results.push({key:k,verdict:'BLIND'}); continue; }
      // Attribute the movement to the key it was aimed at. A mutation that moves SOME other
      // attribute is DRIFT-ELSEWHERE, not coverage of this one — the same distinction the
      // node-level probe needs for the eventbind trio.
      var moved=[];
      for(var j=0;j<WMSPEC.length;j++) if(wmValue(m1,WMSPEC[j])!==wmValue(m2,WMSPEC[j])) moved.push(WMSPEC[j]);
      results.push({key:k,verdict:(moved.indexOf(k)>=0?'LIVE':'DRIFT-ELSEWHERE'),moved:moved});
    }
    return {perturbable:true,results:results};
  }catch(e){ return {perturbable:false,reason:'exception: '+(e&&e.message||e)}; }
})()`;
// ── T-910: the LANE-level self-test ──────────────────────────────────────────────────────────
// Same question the document-level one asks, of aef:laneMeta: with this attribute perturbed in
// its own wire carrier, does the lane projection move? A key in LMSPEC is a CLAIM of coverage;
// only a value that varies is EVIDENCE (PL-175).
//
// Mutation is anchored INSIDE the aef:laneMeta element, never document-wide. height= and abbr=
// match other elements in a full BPMN document long before they match this one, and an off-target
// mutation that lands somewhere real reports BLIND while the guard is innocent — measured on the
// node-level probe, 18 of 18 fixtures.
//
// CONTROLS RUN BEFORE ANY VERDICT IS SCORED. This corpus has twice scored an unapplied mutation
// as a survival: a mutant that never applied and a mutant that survived are byte-identical in
// their result, and only an assertion that the mark actually landed tells them apart. So each
// mutation is checked for the mark before its result counts, and the pair of controls below runs
// first — if the mutator cannot distinguish an attribute that is present from one that is not,
// every kill and every survival below is noise and the honest output is MUTATION SETUP BROKEN,
// not a score.
// (No backticks in this comment: it lives inside a JS template literal and a backtick kills the
// harness before it evaluates.)
const LM_PREFLIGHT_EXPR = `(function(){
  var text = window.__FIXTURE__;
  var LMSPEC = ${JSON.stringify(LMSPEC)};
  var MARK='__DRIFT__';
  function lmProj(m){
    if(!m) return null;
    return JSON.stringify((m.lanes||[]).map(function(l){
      var o={id:l.id};
      LMSPEC.forEach(function(k){ var v=l[k]; o[k]=(v==null||v==='')?null:String(v); });
      return o;
    }).sort(function(a,b){ return a.id<b.id?-1:a.id>b.id?1:0; }));
  }
  // Per-attribute across ALL lanes, so movement can be attributed to the attribute it was aimed
  // at rather than to the document having changed somehow.
  function lmValue(m,k){
    if(!m) return null;
    return JSON.stringify((m.lanes||[]).map(function(l){
      var v=l[k]; return [l.id,(v==null||v==='')?null:String(v)];
    }).sort(function(a,b){ return a[0]<b[0]?-1:a[0]>b[0]?1:0; }));
  }
  // Returns the mutated document AND what the wire authored, plus the lane it belongs to, so the
  // caller can check the parser actually reads the attribute through before scoring a survival.
  function inLaneMeta(xml,attr){
    var rx=new RegExp('<aef:laneMeta\\\\s[^>]*>','g'),m;
    while((m=rx.exec(xml))!==null){
      var re=new RegExp('(\\\\s'+attr+'=")([^"]*)(")');
      if(re.test(m[0])){
        var authored=m[0].match(re)[2];
        // The enclosing lane is the last <bpmn:lane ...> opened before this laneMeta.
        var before=xml.slice(0,m.index);
        var li=before.lastIndexOf('<bpmn:lane ');
        var laneId=null;
        if(li>=0){ var idm=before.slice(li).match(/id="([^"]*)"/); if(idm) laneId=idm[1]; }
        return { xml: xml.slice(0,m.index)+m[0].replace(re,'$1'+MARK+'$3')+xml.slice(m.index+m[0].length),
                 authored: authored, laneId: laneId };
      }
    }
    return null;
  }
  try{
    var m1=parseBpmnXml(text);
    if(!m1) return {perturbable:false,reason:'parse1-null'};
    if(!(m1.lanes||[]).length) return {perturbable:false,reason:'no-lanes'};
    // CONTROL SET, before any scoring.
    // negative: an attribute no laneMeta carries must come back null. If it comes back mutated,
    //           inLaneMeta is matching something it was not aimed at.
    // positive: a known-present attribute must come back carrying the mark. If it does not, the
    //           mutator is a no-op and every SURVIVED below would be a no-op misread as evidence.
    var ctlNeg=inLaneMeta(text,'__t910_absent__');
    var ctlPos=inLaneMeta(text,'authority');
    var controls={
      negative_absent_attr_expected_NULL: (ctlNeg===null)?'NULL':'MUTATED',
      positive_authority_expected_MARKED: (ctlPos!==null && ctlPos.xml!==text && ctlPos.xml.indexOf(MARK)>=0)?'MARKED':'NOT-MARKED'
    };
    controls.held = controls.negative_absent_attr_expected_NULL==='NULL'
                 && controls.positive_authority_expected_MARKED==='MARKED';
    if(!controls.held) return {perturbable:false,reason:'MUTATION SETUP BROKEN',controls:controls};
    var p1=lmProj(m1);
    var results=[];
    for(var i=0;i<LMSPEC.length;i++){
      var k=LMSPEC[i];
      var hit=inLaneMeta(text,k);
      if(hit===null){ results.push({key:k,verdict:'NOT-PRESENT'}); continue; }
      // ASSERT THE MUTATION APPLIED before scoring it. An unapplied mutation reads identically
      // to a survival; without this line the two are indistinguishable.
      if(hit.xml===text || hit.xml.indexOf(MARK)<0){ results.push({key:k,verdict:'MUTATION-NOT-APPLIED'}); continue; }
      // NOT-EXERCISABLE, distinct from BLIND. If the parser already does not carry the AUTHORED
      // value through to the model, then perturbing the wire cannot move the projection and a
      // survival says nothing about the guard. parseBpmnXml runs deliberate repairs on import —
      // growUnderDeclaredLanes() rewrites an under-declared lane height (src:11350ish), so
      // lane-capacity-large-spill.bpmn authors height="260" and parses as 591. Scoring that as
      // BLIND blames the guard for a repair working exactly as designed, and sends the reader to
      // fix a projection that is innocent. Derived by COMPARING authored against parsed rather
      // than by naming the repair, so the next transform on import classifies itself.
      var lane1=(m1.lanes||[]).filter(function(l){ return l.id===hit.laneId; })[0];
      var parsedNow=lane1?((lane1[k]==null||lane1[k]==='')?null:String(lane1[k])):null;
      if(lane1 && parsedNow!==String(hit.authored)){
        results.push({key:k,verdict:'NOT-EXERCISABLE',lane:hit.laneId,authored:hit.authored,parsed:parsedNow,
          reason:'the parser does not carry the authored value through — it is transformed on import, so mutating the wire cannot move the projection and a survival would be meaningless'});
        continue;
      }
      var m2=parseBpmnXml(hit.xml);
      if(!m2){ results.push({key:k,verdict:'LIVE',moved:['<parse broke>']}); continue; }
      // A BLIND verdict carries the before/after the parser actually saw. Without it the reader
      // has to re-derive by hand what the projection failed to notice, which is how a real
      // finding gets written off as harness noise.
      if(lmProj(m2)===p1){ results.push({key:k,verdict:'BLIND',value_before:lmValue(m1,k),value_after:lmValue(m2,k)}); continue; }
      var moved=[];
      for(var j=0;j<LMSPEC.length;j++) if(lmValue(m1,LMSPEC[j])!==lmValue(m2,LMSPEC[j])) moved.push(LMSPEC[j]);
      results.push({key:k,verdict:(moved.indexOf(k)>=0?'LIVE':'DRIFT-ELSEWHERE'),moved:moved});
    }
    return {perturbable:true,controls:controls,results:results};
  }catch(e){ return {perturbable:false,reason:'exception: '+(e&&e.message||e)}; }
})()`;

async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// The round-trip, executed inside the editor for one fixture (text pre-set as window.__FIXTURE__).
const ROUNDTRIP_EXPR = `(function(){
  var text = window.__FIXTURE__;
  // T-488: interpolated from the single KEYSPEC above — see the long note there for the
  // seven wire carriers these thirty-four keys ride, and for why the two hand-maintained
  // copies this replaces had already diverged by five keys without anything noticing.
  var METAKEYS = ${JSON.stringify(METAKEYS)};
  var STRUCTKEYS = ${JSON.stringify(STRUCTKEYS)};
  // T-886: the document-level set, interpolated from the same WMSPEC that checkWmDenominator()
  // checks against the emitter. This replaced a hand-typed four-key object literal.
  var WMSPEC = ${JSON.stringify(WMSPEC)};
  // T-910: the lane-level set, on the same contract via checkLmDenominator().
  var LMSPEC = ${JSON.stringify(LMSPEC)};
  // Key-order-independent. projEqual compares JSON.stringify output, so without canon() a
  // pure attribute-order difference would read as semantic drift.
  function canon(v){
    if(v===null || typeof v!=='object') return v;
    if(Object.prototype.toString.call(v)==='[object Array]') return v.map(canon);
    var o={}; Object.keys(v).sort().forEach(function(k){ o[k]=canon(v[k]); });
    return o;
  }
  // io is a SIBLING of aef on the node (node.io), not an aef key at all — a third shape
  // beyond scalar and structured-aef. Parsed at src:10029-10044, emitted at src:9337-9345.
  //
  // Deliberately NOT mirroring the emitter's name-filter (src:9263-9264) here.
  // Filtering both sides to what the emitter keeps would restrict the comparison to what
  // already survives, which is exactly the trap PL-031 names: the guard stops being able
  // to see a class of loss because it adopted the lossy step's own definition of content.
  // If a nameless io entry exists in the corpus it SHOULD surface as drift and get a task.
  function structOf(n){
    var aef=n.aef||{}, s={};
    STRUCTKEYS.forEach(function(k){ if(aef[k]!=null) s[k]=canon(aef[k]); });
    var io=n.io||{};
    var ins=io.inputs||[], outs=io.outputs||[];
    if(ins.length||outs.length) s.io={ inputs:canon(ins), outputs:canon(outs) };
    return s;
  }
  function proj(m){
    if(!m) return null;
    var laneAuth = {}; (m.lanes||[]).forEach(function(l){ laneAuth[l.id]=l.authority; });
    var uidOf = {}; m.nodes.forEach(function(n){ uidOf[n.id]=n.uid; });
    var nodes = m.nodes.map(function(n){
      var aef=n.aef||{}, meta={};
      METAKEYS.forEach(function(k){ if(aef[k]!=null && aef[k]!=='') meta[k]=String(aef[k]); });
      return { uid:n.uid, type:n.type, name:(n.name==null?'':n.name), lane:laneAuth[n.lane]||null,
               meta:meta, struct:structOf(n) };
    }).sort(function(a,b){ return a.uid<b.uid?-1:a.uid>b.uid?1:0; });
    var edges = m.edges.map(function(e){
      return { uid:(e.uid==null?'':e.uid), src:uidOf[e.source]||e.source, tgt:uidOf[e.target]||e.target,
               name:(e.name||null), condition:(e.condition||null) };
    }).sort(function(a,b){ return a.uid<b.uid?-1:a.uid>b.uid?1:0; });
    // T-910: LMSPEC-driven, so an aef:laneMeta attribute cannot be in the emitter and absent from
    // the comparison without checkLmDenominator() failing first. This was a hand-typed
    // {id, authority, abbr}: height and authoringDefault were outside it, so suppressing either
    // in the writer left the whole harness pass:true — measured under T-890 for authoringDefault.
    // Absent and empty-string both normalise to null, matching the wm rule: the emitter omits
    // authoringDefault when falsy, so "" and missing are the same wire state.
    var lanes = (m.lanes||[]).map(function(l){
      var o={id:l.id};
      LMSPEC.forEach(function(k){ var v=l[k]; o[k]=(v==null||v==='')?null:String(v); });
      return o;
    }).sort(function(a,b){ return a.id<b.id?-1:a.id>b.id?1:0; });
    // T-886: WMSPEC-driven, so an attribute cannot be in the emitter and absent from the
    // comparison without checkWmDenominator() failing first. Absent and empty-string both
    // normalise to null: the emitter only writes these when truthy, so "" and missing are the
    // same wire state and must not compare unequal to each other.
    var wm = {}; var wmSrc = m.workflowMeta || {};
    WMSPEC.forEach(function(k){ var v = wmSrc[k]; wm[k] = (v==null || v==='') ? null : String(v); });
    return { nodes:nodes, edges:edges, lanes:lanes, wm:wm };
  }
  try{
    var m1 = parseBpmnXml(text);
    if(!m1) return { ok:false, reason:'parse1-null' };
    state = m1; refreshDisplayIds();
    var emit1a = buildBpmnXml(state);
    var emit1b = buildBpmnXml(state);
    var m2 = parseBpmnXml(emit1a);
    if(!m2) return { ok:false, reason:'parse2-null' };
    state = m2; refreshDisplayIds();
    var emit2 = buildBpmnXml(state);
    var p1 = proj(m1), p2 = proj(m2);
    // T-591: these two count uids on the PARSED model, and parseBpmnXml MINTS an identity for
    // any node or edge that arrives without one (src/aef-workflow-designer.html:10284 — a
    // deliberate affordance so third-party BPMN can be imported at all). So m1 is always fully
    // populated and both counters are zero BY CONSTRUCTION: the missingNodeUid===0 clause in
    // the gate below has never been capable of being false. Proven, not inferred — deleting one
    // of the pilot fixture's nine aef:uid elements still yielded missingNodeUid 0 and ok:true.
    // They are kept because they are honest about the parsed model and cost nothing; the leg
    // with teeth is declaredUid* below, which reads the SOURCE.
    var missingNodeUid = m1.nodes.filter(function(n){return !n.uid;}).length;
    var missingEdgeUid = m1.edges.filter(function(e){return !e.uid;}).length;
    // The question the header comment meant to ask: does the FIXTURE declare its own
    // identities, or did the editor have to invent them? A corpus member that silently relies
    // on minting is not carrying a stable identity across the seam — the uid it round-trips is
    // one this run created, and the next run creates a different one.
    // NO REGEX ESCAPES HERE. This whole expression is a JS template literal, so a backslash is
    // eaten before the browser ever sees it: /<aef:uid\s+value="/ arrives as /<aef:uid s+value="/
    // and matches nothing. The first version of this leg reported declaredUids 0 on a fixture
    // carrying nine of them — an instrument that could not see its subject, reporting the same
    // number it would report for a fixture that genuinely had none. Split on a literal instead.
    // T-1017: count over the source WITHOUT XML comments. A comment is not a declaration:
    // plain-task-default-ns.bpmn's header prose mentions "<aef:uid value=…/>", which made this
    // count 6 against 5 real elements (red since T-970), and the same blindness would PASS a
    // fixture whose only "declaration" sat inside a comment. indexOf, not a regex (see above).
    var uncommented = '', ci = 0;
    while (true) {
      var ca = text.indexOf('<!--', ci);
      if (ca < 0) { uncommented += text.slice(ci); break; }
      uncommented += text.slice(ci, ca);
      var cb = text.indexOf('-->', ca + 4);
      if (cb < 0) break;              // unterminated comment: nothing after it is markup
      ci = cb + 3;
    }
    var declaredUids = uncommented.split('<aef:uid ').length - 1;
    var expectedUids = m1.nodes.length + m1.edges.length;
    var undeclaredUid = expectedUids - declaredUids;
    var deterministic = (emit1a===emit1b);
    var projEqual = (JSON.stringify(p1)===JSON.stringify(p2));
    // localise the first semantic drift, if any, for diagnosis
    var drift = null;
    if(!projEqual){
      var s1=JSON.stringify(p1,null,0), s2=JSON.stringify(p2,null,0);
      var i=0; while(i<s1.length && i<s2.length && s1[i]===s2[i]) i++;
      drift = { at:i, a:s1.slice(Math.max(0,i-40), i+40), b:s2.slice(Math.max(0,i-40), i+40) };
    }
    return {
      // T-591: undeclaredUid===0 is the leg with teeth. Gating it is safe because it was
      // MEASURED across all 19 corpus fixtures first and every one declares every identity
      // (undeclared 0), so this turns nothing red today — it can only go red on a fixture
      // that starts relying on the parser to invent identities for it.
      ok: projEqual && deterministic && missingNodeUid===0 && missingEdgeUid===0 && undeclaredUid===0,
      nodes:m1.nodes.length, edges:m1.edges.length, lanes:(m1.lanes||[]).length,
      missingNodeUid:missingNodeUid, missingEdgeUid:missingEdgeUid,
      declaredUids:declaredUids, expectedUids:expectedUids, undeclaredUid:undeclaredUid,
      deterministic:deterministic, projEqual:projEqual,
      byteIdempotent:(emit1a===emit2), len1:emit1a.length, len2:emit2.length,
      drift:drift
    };
  }catch(e){ return { ok:false, reason:'exception: '+(e&&e.message||e) }; }
})()`;

async function main() {
  // Fixture corpus is the subject of the test — absence/emptiness is a FAILURE (PL-022).
  if (!existsSync(FIXturesDir)) { process.stdout.write(JSON.stringify({ pass: false, error: 'fixtures dir missing: ' + FIXturesDir }) + '\n'); process.exitCode = 1; return; }
  const fixtures = readdirSync(FIXturesDir).filter(f => f.endsWith('.bpmn')).sort();
  if (!fixtures.length) { process.stdout.write(JSON.stringify({ pass: false, error: 'no *.bpmn fixtures in ' + FIXturesDir }) + '\n'); process.exitCode = 1; return; }

  // T-490: derive the denominator BEFORE spending a browser on the self-test. This is a pure
  // static check against the emitter, and it answers the question the self-test cannot ask of
  // itself — whether the list it exercises is the whole list. Failing here rather than after a
  // green run matters: a coverage number published alongside a known-incomplete denominator is
  // worse than no number, because it is the number a reader will quote.
  let DENOM;
  try { DENOM = checkDenominator(); }
  catch (e) { process.stdout.write(JSON.stringify({ pass: false, denominator_failed: true, error: 'denominator derivation threw: ' + (e && e.message || e) }, null, 2) + '\n'); process.exitCode = 2; return; }
  if (DENOM.problems.length) {
    process.stdout.write(JSON.stringify({
      pass: false, denominator_failed: true,
      error: 'the emitter projects keys this guard does not cover — "N/N" would be a claim about the list, not about the seam',
      denominator: DENOM,
    }, null, 2) + '\n');
    process.exitCode = 2; return;
  }
  // T-886: the same check for the DOCUMENT level, and for the same reason — a coverage number
  // published next to an incomplete denominator is worse than none, because it is the number a
  // reader quotes. Static, so it costs no browser and fails before one is spent.
  let WMDENOM;
  try { WMDENOM = checkWmDenominator(); }
  catch (e) { process.stdout.write(JSON.stringify({ pass: false, wm_denominator_failed: true, error: 'wm-denominator derivation threw: ' + (e && e.message || e) }, null, 2) + '\n'); process.exitCode = 2; return; }
  if (WMDENOM.problems.length) {
    process.stdout.write(JSON.stringify({
      pass: false, wm_denominator_failed: true,
      error: 'the emitter writes aef:workflowMeta attribute(s) this guard neither compares nor excludes — the T-885 census defect, reappearing',
      wm_denominator: WMDENOM,
      wm_summary: `wm-denominator: ${WMDENOM.orphans.length} unclassified`,
    }, null, 2) + '\n');
    process.exitCode = 2; return;
  }
  // T-910: and the LANE level. Same reason, one element over.
  let LMDENOM;
  try { LMDENOM = checkLmDenominator(); }
  catch (e) { process.stdout.write(JSON.stringify({ pass: false, lm_denominator_failed: true, error: 'lm-denominator derivation threw: ' + (e && e.message || e) }, null, 2) + '\n'); process.exitCode = 2; return; }
  if (LMDENOM.problems.length) {
    process.stdout.write(JSON.stringify({
      pass: false, lm_denominator_failed: true,
      error: 'the emitter writes aef:laneMeta attribute(s) this guard neither compares nor excludes — the T-885 census defect, reappearing one element over',
      lm_denominator: LMDENOM,
      lm_summary: `lm-denominator: ${LMDENOM.orphans.length} unclassified`,
    }, null, 2) + '\n');
    process.exitCode = 2; return;
  }

  // T-910: the three denominators are pure static reads of the emitter and cost no browser.
  // --denominators-only runs just them, so the derived-denominator contract is checkable in a
  // second rather than behind a headless Chrome the caller may not be able to spend. The full run
  // is unchanged and still runs all three first.
  if (process.argv.includes('--denominators-only')) {
    process.stdout.write(JSON.stringify({
      pass: true, denominators_only: true,
      denominator: { derivedTotal: DENOM.derivedTotal, orphans: DENOM.orphans, computedSources: DENOM.computedSources, openSources: DENOM.openSources },
      wm_denominator: { derivedTotal: WMDENOM.derivedTotal, derived: WMDENOM.derived, orphans: WMDENOM.orphans },
      lm_denominator: { derivedTotal: LMDENOM.derivedTotal, derived: LMDENOM.derived, orphans: LMDENOM.orphans },
      summary: `node ${DENOM.derivedTotal} / workflowMeta ${WMDENOM.derivedTotal} / laneMeta ${LMDENOM.derivedTotal} attributes derived, 0 unclassified; computed sources ${Object.keys(DENOM.computedSources).length} verified, ${DENOM.openSources.length} open`,
    }, null, 2) + '\n');
    process.exitCode = 0; return;
  }

  const doc = mkdtempSync(join(tmpdir(), 'rt-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'rt-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'rt-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { fixtures: [] };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    // Preflight self-test (T-488): prove the projection guard detects an injected drift FOR EVERY
    // PROJECTED KEY, in that key's own wire carrier, aggregated over the WHOLE corpus.
    //
    // It used to break on the first perturbable fixture AND the first matching key, so it ran one
    // mutation on one document and reported hit:'tier' forever. Aggregating over the corpus is not
    // thoroughness for its own sake: a key absent from one fixture may be the only live one in
    // another, and a per-document verdict cannot tell "this document has no boundary events" from
    // "this key is unguarded".
    const perKey = new Map(KEYSPEC.map(s => [s.k, { key: s.k, shape: s.shape, LIVE: 0, BLIND: 0, ELSEWHERE: 0, absent: 0, unexercisable: 0, unexercisable_reason: null, witnesses: [] }]));
    const selftest = { fixtures_exercised: 0, unperturbable: [] };
    for (const name of fixtures) {
      const text = readFileSync(join(FIXturesDir, name), 'utf8');
      await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(text)};`);
      const r = await ev(cmd, PREFLIGHT_EXPR);
      if (!r || !r.perturbable) { selftest.unperturbable.push({ fixture: name, reason: r && r.reason }); continue; }
      selftest.fixtures_exercised++;
      for (const res of r.results) {
        const agg = perKey.get(res.key); if (!agg) continue;
        if (res.verdict === 'LIVE') { agg.LIVE++; if (agg.witnesses.length < 2) agg.witnesses.push(name); }
        else if (res.verdict === 'BLIND') { agg.BLIND++; if (agg.witnesses.length < 2) agg.witnesses.push(name); }
        else if (res.verdict === 'DRIFT-ELSEWHERE') { agg.ELSEWHERE++; if (agg.witnesses.length < 2) agg.witnesses.push(name); }
        else if (res.verdict === 'NOT-EXERCISABLE') { agg.unexercisable++; agg.unexercisable_reason = res.reason; if (agg.witnesses.length < 2) agg.witnesses.push(name); }
        else agg.absent++;
      }
    }
    const keys = [...perKey.values()];
    // A key is LIVE if it went live in ANY document; BLIND anywhere is a finding even if it is
    // live elsewhere, because it means some carrier shape reaches the emission without reaching
    // the projection.
    selftest.keys_total = keys.length;
    selftest.live = keys.filter(k => k.LIVE > 0).map(k => k.key);
    selftest.blind = keys.filter(k => k.BLIND > 0).map(k => ({ key: k.key, shape: k.shape, docs: k.BLIND, witnesses: k.witnesses }));
    selftest.drift_elsewhere = keys.filter(k => k.ELSEWHERE > 0).map(k => ({ key: k.key, shape: k.shape, docs: k.ELSEWHERE }));
    // Three distinct unproven states, kept apart because they have three different remedies:
    //   NEVER-PRESENT    no fixture carries the key          -> author a fixture that sets it
    //   NOT-EXERCISABLE  carrier present, no legal mutation  -> enrich an existing fixture
    //   BLIND            mutated and the projection did not move -> the GUARD is at fault
    // Collapsing the first two sends the reader to write the wrong fixture; collapsing any of
    // them into a single "unproven" count loses which of the three is a defect in the guard.
    selftest.not_exercisable = keys.filter(k => k.LIVE === 0 && k.BLIND === 0 && k.ELSEWHERE === 0 && k.unexercisable > 0)
      .map(k => ({ key: k.key, shape: k.shape, docs: k.unexercisable, reason: k.unexercisable_reason }));
    selftest.never_present = keys.filter(k => k.LIVE === 0 && k.BLIND === 0 && k.ELSEWHERE === 0 && k.unexercisable === 0).map(k => ({ key: k.key, shape: k.shape }));
    // Controls (T-485): a probe that cannot tell the two states apart proves nothing by finding
    // nothing. `tier` is known live in every corpus document; a synthetic key is in no list and
    // must never be exercised. If either control fails, refuse to publish a verdict.
    selftest.controls = {
      positive_tier_expected_LIVE: selftest.live.includes('tier') ? 'LIVE' : 'NOT-LIVE',
      negative_synthetic_expected_ABSENT: perKey.has('__t488_synthetic__') ? 'PRESENT' : 'ABSENT',
    };
    selftest.controls.held = selftest.controls.positive_tier_expected_LIVE === 'LIVE'
      && selftest.controls.negative_synthetic_expected_ABSENT === 'ABSENT';
    selftest.summary = `${selftest.keys_total} keys / ${selftest.live.length} LIVE / ${selftest.blind.length} BLIND / ${selftest.drift_elsewhere.length} DRIFT-ELSEWHERE / ${selftest.not_exercisable.length} NOT-EXERCISABLE / ${selftest.never_present.length} NEVER-PRESENT over ${selftest.fixtures_exercised} fixtures`;
    // T-490: the fraction's DENOMINATOR is the emitter's derived total, not KEYSPEC's length.
    // Reporting live/keys_total made the number self-referential — it could only ever describe
    // the list it was computed from, so a key missing from that list was invisible to the very
    // ratio meant to express coverage. If the two disagree, the derived total is the honest one
    // and the disagreement is itself the finding.
    selftest.denominator = DENOM;
    selftest.proven_fraction = `${selftest.live.length}/${selftest.denominator.derivedTotal ?? selftest.keys_total}`;
    verdict.selftest = selftest;
    // PL-084: a clean result over an empty population is vacuity, not safety. Zero LIVE keys
    // means the self-test proved nothing at all, however green everything downstream looks.
    if (!selftest.controls.held || selftest.blind.length || selftest.live.length === 0) {
      process.stdout.write(JSON.stringify({
        pass: false, selftest_failed: true,
        error: !selftest.controls.held ? 'self-test controls did not hold — any verdict would be vacuous'
          : selftest.blind.length ? 'a projected key survived mutation of its own wire carrier without moving the projection — that key is unguarded'
          : 'no projected key could be exercised — the self-test proved nothing',
        selftest,
      }, null, 2) + '\n');
      process.exitCode = 2; return;
    }

    // ── T-886: document-level self-test, aggregated over the corpus ───────────────────────────
    // Per-fixture would be dishonest here for the same reason it was at the node level: uuid is
    // carried by exactly 1 of 20 fixtures and kind by 1, so a per-document verdict cannot tell
    // "this document does not set uuid" from "uuid is unguarded".
    const wmPerKey = new Map(WMSPEC.map(k => [k, { key: k, LIVE: 0, BLIND: 0, ELSEWHERE: 0, absent: 0, witnesses: [] }]));
    const wmTest = { fixtures_exercised: 0, unperturbable: [] };
    for (const name of fixtures) {
      const text = readFileSync(join(FIXturesDir, name), 'utf8');
      await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(text)};`);
      const r = await ev(cmd, WM_PREFLIGHT_EXPR);
      if (!r || !r.perturbable) { wmTest.unperturbable.push({ fixture: name, reason: r && r.reason }); continue; }
      wmTest.fixtures_exercised++;
      for (const res of r.results) {
        const agg = wmPerKey.get(res.key); if (!agg) continue;
        if (res.verdict === 'LIVE') { agg.LIVE++; if (agg.witnesses.length < 2) agg.witnesses.push(name); }
        else if (res.verdict === 'BLIND') { agg.BLIND++; if (agg.witnesses.length < 2) agg.witnesses.push(name); }
        else if (res.verdict === 'DRIFT-ELSEWHERE') { agg.ELSEWHERE++; if (agg.witnesses.length < 2) agg.witnesses.push(name); }
        else agg.absent++;
      }
    }
    const wmKeys = [...wmPerKey.values()];
    wmTest.live = wmKeys.filter(k => k.LIVE > 0).map(k => k.key);
    wmTest.blind = wmKeys.filter(k => k.BLIND > 0).map(k => ({ key: k.key, docs: k.BLIND, witnesses: k.witnesses }));
    wmTest.drift_elsewhere = wmKeys.filter(k => k.ELSEWHERE > 0).map(k => ({ key: k.key, docs: k.ELSEWHERE }));
    // NEVER-PRESENT is reported and is NOT counted as covered. pageWidth is the known case: no
    // fixture authors it, so nothing about it was measured. Per T-3105 that is not a pass, and
    // this project's grammar is that NOT EVALUATED is not PASSED.
    wmTest.never_present = wmKeys.filter(k => k.LIVE === 0 && k.BLIND === 0 && k.ELSEWHERE === 0).map(k => k.key);
    wmTest.excluded = WMDENOM.excluded.map(k => ({ key: k, reason: WM_EXCLUDED[k] }));
    wmTest.wm_denominator = WMDENOM;
    wmTest.exercised_fraction = `${wmTest.live.length}/${WMDENOM.derivedTotal}`;
    wmTest.summary = `wm-denominator: ${WMDENOM.orphans.length} unclassified / ${WMDENOM.derivedTotal} written / ${wmTest.live.length} LIVE / ${wmTest.blind.length} BLIND / ${wmTest.never_present.length} NEVER-PRESENT / ${wmTest.excluded.length} EXCLUDED over ${wmTest.fixtures_exercised} fixtures`;
    verdict.wm_selftest = wmTest;
    // A compared attribute that survives mutation of its own carrier is unguarded — the exact
    // T-885 finding, and the state this task exists to make reachable instead of invisible.
    if (wmTest.blind.length || wmTest.live.length === 0) {
      process.stdout.write(JSON.stringify({
        pass: false, wm_selftest_failed: true,
        error: wmTest.blind.length
          ? 'an aef:workflowMeta attribute survived mutation of its own carrier without moving the projection — that attribute is unguarded (the T-885 census defect)'
          : 'no aef:workflowMeta attribute could be exercised — the document-level self-test proved nothing',
        wm_selftest: wmTest,
      }, null, 2) + '\n');
      process.exitCode = 2; return;
    }

    // ── T-910: lane-level self-test, aggregated over the corpus ───────────────────────────────
    // Per-fixture would be dishonest for the same reason it is at the two levels above:
    // authoringDefault is carried by very few fixtures, so a per-document verdict cannot tell
    // "this document sets no authoring default" from "authoringDefault is unguarded".
    // T-910: witnesses are kept PER VERDICT, not pooled. The wm and node levels share one
    // `witnesses` list across every verdict, so a BLIND finding is reported alongside fixture
    // names that were LIVE — which sends the reader to open the wrong document. Hit on the first
    // run of this leg: height came back BLIND on 1 of 20 and the two names printed next to it
    // were both fixtures where it was live. Filed for the other two levels rather than changed
    // here, so this task does not quietly rewrite guards it is not about.
    const lmPerKey = new Map(LMSPEC.map(k => [k, { key: k, LIVE: 0, BLIND: 0, ELSEWHERE: 0, absent: 0, not_applied: 0, unexercisable: 0, unexercisable_detail: null, w: { LIVE: [], BLIND: [], ELSEWHERE: [], NOT_APPLIED: [], NOT_EXERCISABLE: [] } }]));
    const lmTest = { fixtures_exercised: 0, unperturbable: [], setup_broken: [] };
    for (const name of fixtures) {
      const text = readFileSync(join(FIXturesDir, name), 'utf8');
      await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(text)};`);
      const r = await ev(cmd, LM_PREFLIGHT_EXPR);
      // The control set is the first thing scored, and a broken mutator is reported as broken
      // rather than being allowed to contribute survivals to a coverage number.
      if (r && r.reason === 'MUTATION SETUP BROKEN') { lmTest.setup_broken.push({ fixture: name, controls: r.controls }); continue; }
      if (!r || !r.perturbable) { lmTest.unperturbable.push({ fixture: name, reason: r && r.reason }); continue; }
      lmTest.fixtures_exercised++;
      for (const res of r.results) {
        const agg = lmPerKey.get(res.key); if (!agg) continue;
        if (res.verdict === 'LIVE') { agg.LIVE++; if (agg.w.LIVE.length < 3) agg.w.LIVE.push(name); }
        else if (res.verdict === 'BLIND') { agg.BLIND++; if (agg.w.BLIND.length < 3) agg.w.BLIND.push({ fixture: name, value_before: res.value_before, value_after: res.value_after }); }
        else if (res.verdict === 'DRIFT-ELSEWHERE') { agg.ELSEWHERE++; if (agg.w.ELSEWHERE.length < 3) agg.w.ELSEWHERE.push(name); }
        else if (res.verdict === 'MUTATION-NOT-APPLIED') { agg.not_applied++; if (agg.w.NOT_APPLIED.length < 3) agg.w.NOT_APPLIED.push(name); }
        else if (res.verdict === 'NOT-EXERCISABLE') { agg.unexercisable++; agg.unexercisable_detail = agg.unexercisable_detail || { reason: res.reason, lane: res.lane, authored: res.authored, parsed: res.parsed }; if (agg.w.NOT_EXERCISABLE.length < 3) agg.w.NOT_EXERCISABLE.push(name); }
        else agg.absent++;
      }
    }
    const lmKeys = [...lmPerKey.values()];
    lmTest.live = lmKeys.filter(k => k.LIVE > 0).map(k => k.key);
    lmTest.blind = lmKeys.filter(k => k.BLIND > 0).map(k => ({ key: k.key, docs: k.BLIND, blind_in: k.w.BLIND, also_live_in: k.w.LIVE }));
    lmTest.drift_elsewhere = lmKeys.filter(k => k.ELSEWHERE > 0).map(k => ({ key: k.key, docs: k.ELSEWHERE }));
    // A mutation that never applied is NOT a survival and NOT an absence — it is a broken probe,
    // and it is kept as its own state so it can never be read as either.
    lmTest.mutation_not_applied = lmKeys.filter(k => k.not_applied > 0).map(k => ({ key: k.key, docs: k.not_applied, not_applied_in: k.w.NOT_APPLIED }));
    // NEVER-PRESENT is reported and is NOT counted as covered — per T-3105, NOT EVALUATED is not
    // PASSED.
    // Four distinct unproven states, kept apart because they have four different remedies:
    //   NEVER-PRESENT    no fixture carries the attribute        -> author a fixture that sets it
    //   NOT-EXERCISABLE  carried, but transformed on import      -> the probe cannot reach it; say so
    //   NOT-APPLIED      the mutation never landed               -> the HARNESS is broken
    //   BLIND            mutated, read through, did not move     -> the GUARD is at fault
    // Collapsing any pair sends the reader to the wrong repair. The first version of this leg
    // collapsed the middle two into BLIND and accused an innocent projection.
    lmTest.not_exercisable = lmKeys.filter(k => k.LIVE === 0 && k.BLIND === 0 && k.ELSEWHERE === 0 && k.not_applied === 0 && k.unexercisable > 0)
      .map(k => ({ key: k.key, docs: k.unexercisable, in_fixtures: k.w.NOT_EXERCISABLE, detail: k.unexercisable_detail }));
    // An attribute LIVE somewhere and merely unexercisable elsewhere is proven; it is the ones
    // proven NOWHERE that are reported unproven.
    lmTest.partially_exercisable = lmKeys.filter(k => k.LIVE > 0 && k.unexercisable > 0)
      .map(k => ({ key: k.key, live_docs: k.LIVE, unexercisable_docs: k.unexercisable, in_fixtures: k.w.NOT_EXERCISABLE, detail: k.unexercisable_detail }));
    lmTest.never_present = lmKeys.filter(k => k.LIVE === 0 && k.BLIND === 0 && k.ELSEWHERE === 0 && k.not_applied === 0 && k.unexercisable === 0).map(k => k.key);
    lmTest.excluded = LMDENOM.excluded.map(k => ({ key: k, reason: LM_EXCLUDED[k] }));
    lmTest.lm_denominator = LMDENOM;
    lmTest.exercised_fraction = `${lmTest.live.length}/${LMDENOM.derivedTotal}`;
    // T-910 AC4: authority is called out separately WHATEVER IT SHOWS. It is the
    // authority-of-record under §3 of docs/standards/aef-bpmn-mapping-v1.md, so its state is a
    // seam-integrity fact a reader must be able to see without decoding a fraction — and it sat
    // on the lucky side of a hand-typed projection by accident, not by guarantee.
    {
      const a = lmPerKey.get('authority');
      lmTest.authority = {
        attribute: 'aef:laneMeta/@authority',
        state: a.BLIND > 0 ? 'BLIND' : a.not_applied > 0 ? 'MUTATION-NOT-APPLIED' : a.LIVE > 0 ? 'LIVE' : a.ELSEWHERE > 0 ? 'DRIFT-ELSEWHERE' : a.unexercisable > 0 ? 'NOT-EXERCISABLE' : 'NEVER-PRESENT',
        live_docs: a.LIVE, blind_docs: a.BLIND, elsewhere_docs: a.ELSEWHERE, not_applied_docs: a.not_applied,
        why_reported_separately: 'v1 §3 authority-of-record. Silent loss here is a seam-integrity defect, not a cosmetic one, so it is stated outright rather than averaged into a coverage fraction.',
      };
    }
    lmTest.summary = `lm-denominator: ${LMDENOM.orphans.length} unclassified / ${LMDENOM.derivedTotal} written / ${lmTest.live.length} LIVE / ${lmTest.blind.length} BLIND / ${lmTest.mutation_not_applied.length} NOT-APPLIED / ${lmTest.not_exercisable.length} NOT-EXERCISABLE / ${lmTest.never_present.length} NEVER-PRESENT / ${lmTest.excluded.length} EXCLUDED over ${lmTest.fixtures_exercised} fixtures; authority=${lmTest.authority.state}`;
    verdict.lm_selftest = lmTest;
    if (lmTest.setup_broken.length || lmTest.mutation_not_applied.length || lmTest.blind.length || lmTest.live.length === 0) {
      process.stdout.write(JSON.stringify({
        pass: false, lm_selftest_failed: true,
        error: lmTest.setup_broken.length
          ? `MUTATION SETUP BROKEN — the lane-level mutator failed its own controls on ${lmTest.setup_broken.length} fixture(s); no kill or survival below is evidence of anything`
          : lmTest.mutation_not_applied.length
          ? 'MUTATION SETUP BROKEN — a lane-level mutation did not apply, and an unapplied mutation is indistinguishable from a survival'
          : lmTest.blind.length
          ? 'an aef:laneMeta attribute survived mutation of its own carrier without moving the projection — that attribute is unguarded (the T-885 census defect, one element over)'
          : 'no aef:laneMeta attribute could be exercised — the lane-level self-test proved nothing',
        lm_selftest: lmTest,
      }, null, 2) + '\n');
      process.exitCode = 2; return;
    }

    for (const name of fixtures) {
      const text = readFileSync(join(FIXturesDir, name), 'utf8');
      await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(text)};`);
      const r = await ev(cmd, ROUNDTRIP_EXPR);
      verdict.fixtures.push({ fixture: name, ...r });
    }

    verdict.pass = verdict.fixtures.length > 0 && verdict.fixtures.every(f => f.ok === true);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), fixtures: verdict.fixtures }, null, 2) + '\n');
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    try { rmSync(repo, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
