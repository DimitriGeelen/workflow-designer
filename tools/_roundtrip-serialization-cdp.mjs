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
const COMPUTED_SOURCES = {
  k:         'metaKeys',            // metaAttrs .map over the metaKeys literal
  key:       'metaKeys',
  bindField: 'EVENT_BINDING_FIELD', // typed-event binding field, chosen by node type
};
function deriveProjectedKeys() {
  const html = readFileSync(SRC_HTML, 'utf8').split('\n');
  const start = html.findIndex(l => l.startsWith(`function ${PROJECTION_FN}(`));
  if (start < 0) throw new Error(`denominator: ${PROJECTION_FN} not found in ${SRC_HTML} — the anchor moved, fix the anchor rather than the expectation`);
  let end = -1;
  for (let i = start + 1; i < html.length; i++) if (html[i] === '}') { end = i; break; }
  if (end < 0) throw new Error(`denominator: no column-0 close for ${PROJECTION_FN}`);
  const body = html.slice(start, end + 1).join('\n');

  const dot = new Set([...body.matchAll(/aef\.([A-Za-z_][A-Za-z0-9_]*)/g)].map(m => m[1]));
  const computed = new Set([...body.matchAll(/aef\[([A-Za-z_][A-Za-z0-9_]*)\]/g)].map(m => m[1]));

  // The metaKeys array literal, read from the emitter rather than re-typed.
  const mk = /const metaKeys\s*=\s*\[([\s\S]*?)\]/.exec(body);
  if (!mk) throw new Error('denominator: metaKeys literal not found inside ' + PROJECTION_FN);
  const metaKeys = [...mk[1].matchAll(/'([A-Za-z_][A-Za-z0-9_]*)'/g)].map(m => m[1]);

  // EVENT_BINDING_FIELD lives just above the function; its VALUES are projected keys.
  const ebf = /const EVENT_BINDING_FIELD\s*=\s*\{([^}]*)\}/.exec(readFileSync(SRC_HTML, 'utf8'));
  if (!ebf) throw new Error('denominator: EVENT_BINDING_FIELD not found');
  const bindFields = [...ebf[1].matchAll(/:\s*'([A-Za-z_][A-Za-z0-9_]*)'/g)].map(m => m[1]);

  return { dot, computed, metaKeys, bindFields };
}
// hostRef / interrupting are NOT aef.* accesses — they ride native bpmn:boundaryEvent attributes
// emitted in buildBpmnXml (src:9643). Assert the mechanism still exists, so if the emitter stops
// writing them the denominator notices instead of the pair quietly becoming NEVER-PRESENT.
const NATIVE_KEYS = { hostRef: 'attachedToRef="', interrupting: 'cancelActivity="' };
function checkDenominator() {
  const { dot, computed, metaKeys, bindFields } = deriveProjectedKeys();
  const covered = new Set(METAKEYS);
  const problems = [];

  for (const [name, reason] of Object.entries(EXCLUDED))
    if (!reason || !reason.trim()) problems.push(`exclusion "${name}" has no reason — an exclusion without a reason is an absence wearing a decision's clothes`);
  for (const name of Object.keys(EXCLUDED))
    if (covered.has(name)) problems.push(`"${name}" is both in KEYSPEC and in EXCLUDED — one of the two is wrong`);

  const projected = new Set([...dot, ...metaKeys, ...bindFields]);
  for (const v of computed) {
    if (!COMPUTED_SOURCES[v]) { problems.push(`aef[${v}] is a computed access with no declared source — add it to COMPUTED_SOURCES naming the list it iterates`); continue; }
    projected.delete(v); // the variable itself is not a key
  }
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

  return { problems, derivedTotal: total.size, missingFromSpec, orphans, specSize: covered.size };
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
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// The round-trip, executed inside the editor for one fixture (text pre-set as window.__FIXTURE__).
const ROUNDTRIP_EXPR = `(function(){
  var text = window.__FIXTURE__;
  // T-488: interpolated from the single KEYSPEC above — see the long note there for the
  // seven wire carriers these thirty-four keys ride, and for why the two hand-maintained
  // copies this replaces had already diverged by five keys without anything noticing.
  var METAKEYS = ${JSON.stringify(METAKEYS)};
  var STRUCTKEYS = ${JSON.stringify(STRUCTKEYS)};
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
    var lanes = (m.lanes||[]).map(function(l){ return { id:l.id, authority:l.authority, abbr:(l.abbr||null) }; })
      .sort(function(a,b){ return a.id<b.id?-1:a.id>b.id?1:0; });
    return { nodes:nodes, edges:edges, lanes:lanes,
             wm:{ id:m.workflowMeta.id, tier_default:(m.workflowMeta.tier_default||null),
                  version:(m.workflowMeta.version||null), title:(m.workflowMeta.title||null) } };
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
    var declaredUids = text.split('<aef:uid ').length - 1;
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
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
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
