#!/usr/bin/env node
/**
 * _t367-aef-injection-footprint.mjs — what is the FULL `aef:` layer we write into a
 * document we did not author, when all the user did was open it and save?
 *
 * THE QUESTION AND WHY IT IS NOT ABOUT uid. AEF proposed at RAIL-441 that uid
 * persistence follow *authorship, not observation*: derive it in memory, persist it
 * only on documents we author or the user edits. After T-364 made uid derivable, the
 * reason persistence was load-bearing is gone, so the rule is sound on its own terms.
 *
 * What stopped me agreeing on the spot is that their rule names ONE element, and
 * nobody had ever measured what else we write. If `aef:uid` is a small minority of the
 * layer we inject, then their rule is correct and its SCOPE is wrong: the rule they
 * actually want is "we do not add an `aef:` layer to a document we did not author",
 * of which uid is one line. Implementing the uid-only version would make the diff
 * shorter while leaving open-and-save a non-no-op — the exact property they want back.
 *
 * So this measures the whole layer and states uid as a FRACTION. It does not pre-judge
 * which way that lands.
 *
 * POPULATION. `tests/fixtures/third-party/*.bpmn` — 10 documents from other tools
 * (Camunda, Bizagi, Zeebe, CaseAgile, bpmn.io). They carry no `aef:` layer at all,
 * which makes them the only population where "what do we ADD" is answerable: on our
 * own maps every kind is already present and an injection is indistinguishable from a
 * passthrough.
 *
 * THE INPUT COUNT IS MEASURED, NOT ASSUMED. Every kind's input count is harvested and
 * printed. The expectation is 0 across the board and a grep says it is, but a fixture
 * that already carried an `aef:` element would silently turn an injection into a
 * passthrough and deflate the very number this probe exists to produce. So the run
 * confirms it rather than the author asserting it.
 *
 * SEMANTIC vs PRESENTATIONAL, and the third bucket. Frozen standard §1 declares a
 * NORMATIVE two-class partition and says "Every `aef:` datum is exactly one of two
 * classes". A footprint that is 90% presentational is a completely different argument
 * from one that is 90% semantic — presentational data is explicitly "derived, never
 * authoritative", and a change to it alone MUST be a task-graph no-op. Reporting one
 * total would hide exactly the distinction the question turns on.
 *
 * But §1 declares the partition total while ENUMERATING only some kinds, and this
 * build emits kinds in neither list. Forcing those into "presentational" because they
 * are not in the semantic enumeration would be inventing a ruling and reporting it as
 * a measurement — an absence carrying a decision it cannot carry. They get their own
 * bucket, and that bucket being non-empty is itself a result for AEF.
 *
 * CONTROLS. Three, because the failure modes are different:
 *
 *   (1) POSITIVE — `aef:uid` must be injected. We know it is (T-364 derives it for
 *       every node and edge). A zero here means the save never ran and every other
 *       row is a harness artefact, not a finding.
 *
 *   (2) NEGATIVE — at least one kind this build CAN emit must come back absent. A
 *       probe reporting "we inject everything" is indistinguishable from a harvester
 *       matching too broadly. This is the T-364 failure that produced 21 invented
 *       dangling refs by matching any attribute ending in `ref`.
 *
 *   (3) HARVESTER CAPABILITY — the negative control is worth nothing if the harvester
 *       simply cannot see the kind it reports absent; a missing witness and an
 *       impossible one look identical. So `harvest()` is run against a document
 *       carrying every kind, and must find every one, BEFORE any zero is interpreted
 *       as "not injected".
 *
 * A fixture that fails to import is reported as such and excluded from the totals.
 * Counting it as zero injection would deflate the average with a number that means
 * "we never got there", not "we add nothing".
 *
 * Usage: node tools/_t367-aef-injection-footprint.mjs
 *        T367_SRC=/path/to/designer.html node tools/_t367-aef-injection-footprint.mjs
 * Exit 0 = all three controls behaved; the footprint census is interpretable.
 * Exit 1 = a control failed. Read nothing off the census.
 * Exit 2 = harness broken (no browser, sidecar down, every fixture failed to import).
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T367_SRC || join(REPO, 'src/aef-workflow-designer.html');
const FIXDIR = join(REPO, 'tests/fixtures/third-party');

// Frozen standard §1, quoted. SEMANTIC and PRESENTATIONAL are the standard's own
// enumerations, copied verbatim — not my reading of what each kind is for. Anything
// this build emits that appears in neither list lands in UNCLASSIFIED, which is a
// finding about the standard, not a default.
const SEMANTIC = new Set([
  'artifactsWrites', 'contextReads', 'decisionInput', 'decisionOutputs',
  'io', 'input', 'output', 'constituents', 'link', 'uid', 'meta',
]);
const PRESENTATIONAL = new Set([
  'position', 'anchors', 'endpoint', 'waypoint', 'routing', 'routingHint',
  'forceStraight', 'loopDetour', 'extensionElements',
]);
const classOf = k => SEMANTIC.has(k) ? 'SEMANTIC' : PRESENTATIONAL.has(k) ? 'PRESENTATIONAL' : 'UNCLASSIFIED';

// Every kind this build's emitter can write, harvested from the emission sites in
// buildBpmnXml. The negative control is drawn from THIS list: a kind that comes back
// 0 is only evidence of "not injected" if the emitter could have written it.
const EMITTABLE = [
  'uid', 'position', 'meta', 'endpoint', 'contextReads', 'artifactsWrites',
  'decisionInput', 'decisionOutputs', 'link', 'eventDef', 'boundaryPos', 'io',
  'input', 'output', 'constituents', 'constituent', 'workflowMeta', 'laneMeta',
  'anchors', 'loopDetour', 'forceStraight', 'routingHint', 'routing', 'waypoint',
];

// Control (3)'s subject: a document carrying every kind above, so the harvester's
// ability to SEE each one is proven before any absence is read as a finding.
const ALL_KINDS_DOC = EMITTABLE.map(k => `  <aef:${k} probe="1"/>`).join('\n');

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Count every `<aef:KIND ...>` occurrence by kind. Opening tags only — `</aef:x>` does
// not match because the character after `<` is `/`, so a container kind is counted once
// rather than twice.
function harvest(xml) {
  const out = new Map();
  const re = /<aef:([A-Za-z]+)\b/g;
  let m;
  while ((m = re.exec(xml))) out.set(m[1], (out.get(m[1]) || 0) + 1);
  return out;
}

// Strip XML comments. The `aef:` harvester matches inside comments (proven by the
// over-match guard below), so any count taken over raw bytes includes commented-out
// prose. The fixtures carry no comments at all, which makes the exposure inert HERE —
// but "inert on today's corpus" is a property of the corpus, not of the instrument,
// so the strip is applied and the difference reported rather than argued away.
const decomment = xml => xml.replace(/<!--[\s\S]*?-->/g, '');

// Core-BPMN structural census, namespace-prefix agnostic. `bizagi-nested-ns` and
// `caseagile-local-ns` exist precisely because prefixes vary, so matching `bpmn:lane`
// would undercount on the two fixtures named after that hazard.
//
// WHY THIS IS HERE AT ALL. The task asked for the `aef:` layer and that is what the
// census above measures. But 8 of these 10 documents contain no lane, and all 10 come
// back with lanes — the importer SYNTHESISES a lane structure, and a `<bpmn:lane>` is
// not an `aef:` extension. It is core BPMN that every other tool will render. A report
// saying "we inject 307 aef: elements" while silently omitting an invented laneSet
// would be a careful number answering a narrower question than the reader's.
const STRUCTURAL = ['laneSet', 'lane', 'process', 'participant', 'collaboration'];
function structure(xml) {
  const out = new Map();
  for (const k of STRUCTURAL) {
    const re = new RegExp(`<(?:[A-Za-z_][\\w.-]*:)?${k}\\b`, 'g');
    out.set(k, (decomment(xml).match(re) || []).length);
  }
  return out;
}

function main2(results) {
  const pad = (s, n) => String(s).padEnd(n);
  const rpad = (s, n) => String(s).padStart(n);

  const ok = results.filter(r => r.ok);
  const failed = results.filter(r => !r.ok);

  console.log('\n=== T-367: the aef: layer we inject into documents we did not author ===\n');
  console.log(`population: ${results.length} third-party fixtures, ${ok.length} imported, ${failed.length} failed\n`);

  console.log(`  ${pad('fixture', 34)}${rpad('aef in', 8)}${rpad('aef out', 9)}${rpad('injected', 10)}  nodes/edges/lanes`);
  console.log('  ' + '-'.repeat(88));
  for (const r of results) {
    if (!r.ok) { console.log(`  ${pad(r.name, 34)}${rpad('-', 8)}${rpad('-', 9)}${rpad('IMPORT FAILED', 10)}  ${r.err}`); continue; }
    console.log(`  ${pad(r.name, 34)}${rpad(r.inTotal, 8)}${rpad(r.outTotal, 9)}${rpad(r.outTotal - r.inTotal, 10)}  ${r.nodes}/${r.edges}/${r.lanes}`);
  }

  // ---- controls, before any interpretation ----
  const agg = new Map();     // kind -> {in, out}
  for (const r of ok) {
    for (const [k, n] of r.inMap) { const e = agg.get(k) || { in: 0, out: 0 }; e.in += n; agg.set(k, e); }
    for (const [k, n] of r.outMap) { const e = agg.get(k) || { in: 0, out: 0 }; e.out += n; agg.set(k, e); }
  }

  console.log('\n--- controls ---\n');
  let bad = 0;

  // (3) harvester capability — run first: it licenses reading any zero below.
  const seen = harvest(ALL_KINDS_DOC);
  const blind = EMITTABLE.filter(k => !seen.has(k));
  if (blind.length) {
    console.log(`  (3) HARVESTER CAPABILITY  FAILED — harvest() cannot see ${blind.length} kind(s) it is`);
    console.log(`      asked to report on: ${blind.join(', ')}`);
    console.log('      A zero for those means "invisible", not "not injected". Nothing below reads.');
    bad++;
  } else {
    console.log(`  (3) HARVESTER CAPABILITY  PASS — harvest() finds all ${EMITTABLE.length} emittable kinds in a`);
    console.log('      document carrying every one. An absence below is therefore an absence.');
  }

  // (3b) OVER-MATCH — the harvester must not manufacture kinds out of prose. A decoy
  // with exactly one live element and two dead mentions: one commented out, one
  // entity-escaped inside documentation text. Only the live one may be counted, and
  // the count is taken the way the census takes it (comments stripped first).
  const decoy = `<!-- <aef:ghost value="x"/> --><bpmn:documentation>see &lt;aef:ghost/&gt;</bpmn:documentation><aef:ghost live="1"/>`;
  const ghostsRaw = harvest(decoy).get('ghost') || 0;
  const ghostsStripped = harvest(decomment(decoy)).get('ghost') || 0;
  if (ghostsStripped !== 1) {
    console.log(`  (3b) OVER-MATCH GUARD     FAILED — decoy has exactly 1 live aef:ghost, harvester`);
    console.log(`      counts ${ghostsStripped} after stripping comments. The census over-counts prose as data.`);
    bad++;
  } else {
    console.log(`  (3b) OVER-MATCH GUARD     PASS — 1 live element counted once; the entity-escaped`);
    console.log(`      mention is invisible and the commented one is stripped (raw bytes would say ${ghostsRaw}).`);
  }
  const contaminated = ok.filter(r => r.commentBorne > 0);
  if (contaminated.length) {
    console.log(`      NOTE: ${contaminated.length} fixture(s) emit aef: mentions inside comments —`);
    console.log(`      ${contaminated.map(r => `${r.name}(+${r.commentBorne})`).join(', ')}. Excluded from every count.`);
  }

  // (1) positive
  const uidOut = (agg.get('uid') || { out: 0 }).out;
  if (uidOut === 0) {
    console.log('\n  (1) POSITIVE CONTROL      FAILED — aef:uid injected 0 times. T-364 derives a uid for');
    console.log('      every node and edge, so a zero means the save never ran. Census is a harness');
    console.log('      artefact, not a finding.');
    bad++;
  } else {
    console.log(`\n  (1) POSITIVE CONTROL      PASS — aef:uid injected ${uidOut}×, so the open->save ran.`);
  }

  // (2) negative — drawn from EMITTABLE so the bucket was reachable
  const absent = EMITTABLE.filter(k => !(agg.get(k) || { out: 0 }).out);
  if (!absent.length) {
    console.log('\n  (2) NEGATIVE CONTROL      FAILED — every kind this build can emit appears in the');
    console.log('      output. "We inject everything" and "the harvester matches too broadly" are');
    console.log('      the same reading, and this probe cannot tell them apart.');
    bad++;
  } else {
    console.log(`\n  (2) NEGATIVE CONTROL      PASS — ${absent.length} of ${EMITTABLE.length} emittable kinds are NOT injected:`);
    console.log(`      ${absent.join(', ')}`);
    console.log('      The census discriminates: it reports what we add, not everything it can name.');
  }

  if (bad) { console.log('\nCONTROLS FAILED — census suppressed.'); return 1; }

  if (!ok.length) { console.log('\nNo fixture imported. Nothing to measure.'); return 2; }

  // ---- the census ----
  console.log('\n--- what we inject, per kind (summed over the ' + ok.length + ' fixtures that imported) ---\n');
  console.log(`  ${pad('kind', 20)}${pad('§1 class', 17)}${rpad('in', 5)}${rpad('out', 7)}${rpad('injected', 11)}${rpad('share', 8)}`);
  console.log('  ' + '-'.repeat(70));

  const injected = [...agg.entries()]
    .map(([k, v]) => ({ kind: k, in: v.in, out: v.out, add: v.out - v.in, cls: classOf(k) }))
    .filter(r => r.add > 0)
    .sort((a, b) => b.add - a.add);
  const total = injected.reduce((s, r) => s + r.add, 0);

  for (const r of injected) {
    const pct = (100 * r.add / total).toFixed(1) + '%';
    console.log(`  ${pad('aef:' + r.kind, 20)}${pad(r.cls, 17)}${rpad(r.in, 5)}${rpad(r.out, 7)}${rpad(r.add, 11)}${rpad(pct, 8)}`);
  }
  console.log('  ' + '-'.repeat(70));
  console.log(`  ${pad('TOTAL', 37)}${rpad(injected.reduce((s, r) => s + r.in, 0), 5)}${rpad(injected.reduce((s, r) => s + r.out, 0), 7)}${rpad(total, 11)}`);

  const nonZeroIn = injected.filter(r => r.in > 0);
  console.log();
  if (nonZeroIn.length) {
    console.log(`  *** ${nonZeroIn.length} kind(s) were ALREADY PRESENT on input — for these the number above is`);
    console.log('      a net delta, not an injection: ' + nonZeroIn.map(r => `aef:${r.kind}(${r.in})`).join(', '));
  } else {
    console.log('  Input carried ZERO aef: elements across every fixture — confirmed by measurement,');
    console.log('  not assumed. Every count above is a pure injection into a foreign document.');
  }

  // ---- the fraction the question turns on ----
  const uidAdd = (injected.find(r => r.kind === 'uid') || { add: 0 }).add;
  const byClass = { SEMANTIC: 0, PRESENTATIONAL: 0, UNCLASSIFIED: 0 };
  for (const r of injected) byClass[r.cls] += r.add;

  console.log('\n--- the fraction ---\n');
  console.log(`  aef:uid          ${uidAdd} of ${total} injected elements = ${(100 * uidAdd / total).toFixed(1)}%`);
  console.log(`  everything else  ${total - uidAdd} of ${total} = ${(100 * (total - uidAdd) / total).toFixed(1)}%`);
  console.log();
  console.log('  by frozen-standard §1 class:');
  for (const [c, n] of Object.entries(byClass)) {
    if (!n && c === 'UNCLASSIFIED') continue;
    console.log(`    ${pad(c, 17)}${rpad(n, 5)}  ${(100 * n / total).toFixed(1)}%`);
  }
  const unclassified = injected.filter(r => r.cls === 'UNCLASSIFIED');
  if (unclassified.length) {
    console.log();
    console.log(`  ${unclassified.length} injected kind(s) are in NEITHER §1 list, though §1 says the partition is total`);
    console.log(`  ("Every aef: datum is exactly one of two classes"):`);
    for (const r of unclassified) console.log(`      aef:${r.kind}  (${r.add}×)`);
    console.log('  Not silently folded into PRESENTATIONAL — that would be a ruling wearing the');
    console.log('  costume of a measurement. It is a gap in the enumeration and AEF owns the fence.');
  }

  // ---- the structural injection the aef: census cannot see ----
  console.log('\n--- and the part that is not an aef: element at all ---\n');
  console.log(`  ${pad('fixture', 34)}${pad('lanes', 12)}${pad('participants', 15)}${pad('nodes/edges', 13)}laneProvenance (T-358)`);
  console.log('  ' + '-'.repeat(104));
  let synthLanes = 0, withNoLanes = 0, synthPart = 0, withNoPart = 0;
  const emptied = [], lostPart = [];
  for (const r of ok) {
    const li = r.structIn.get('lane'), lo = r.structOut.get('lane');
    const pi = r.structIn.get('participant'), po = r.structOut.get('participant');
    if (li === 0 && lo > 0) { synthLanes += lo; withNoLanes++; }
    if (pi === 0 && po > 0) { synthPart += po; withNoPart++; }
    if (pi > po) lostPart.push(`${r.name} (${pi}->${po})`);
    if (r.nodes === 0) emptied.push(r.name);
    console.log(`  ${pad(r.name, 34)}${pad(`${li} -> ${lo}`, 12)}${pad(`${pi} -> ${po}`, 15)}${pad(`${r.nodes}/${r.edges}`, 13)}${r.prov}`);
  }
  console.log();
  if (withNoLanes) {
    console.log(`  *** ${withNoLanes} of ${ok.length} fixtures contain NO lane and come back carrying lanes:`);
    console.log(`      ${synthLanes} <bpmn:lane> elements invented, plus the enclosing <bpmn:laneSet>.`);
    console.log(`      ${withNoPart} of ${ok.length} gain a <bpmn:participant> the input never had (${synthPart} total).`);
    if (lostPart.length) {
      console.log(`      And participants move in BOTH directions — ${lostPart.length} fixture(s) LOSE one:`);
      console.log(`      ${lostPart.join(', ')}. That is the two-pool-saves-as-one-pool collapse`);
      console.log('      (RAIL-400), not fabrication. A net participant count would have cancelled');
      console.log('      these against the 6 fabricated and reported a tidy near-zero.');
    }
    console.log('      These are CORE BPMN, not an aef: extension — every other tool renders them,');
    console.log('      and no aef:-scoped rule (RAIL-441 included) would remove a single one. The');
    console.log('      aef:laneMeta count above is downstream of this: most of it annotates lanes');
    console.log('      that did not exist in the source document.');
    console.log();
    console.log(`      SCOPE CORRECTION for T-358, whose title says EVERY third-party document gains`);
    console.log(`      3 lanes and 1 participant: measured on 5 fixtures, true of all 5. On these ${ok.length}`);
    console.log(`      it is ${withNoLanes}/${ok.length} — the two carrying their own lanes keep them and fabricate nothing.`);
    console.log('      The defect is real and its universal quantifier was never measured.');
  }
  if (emptied.length) {
    console.log();
    console.log(`  *** ${emptied.length} fixture(s) import as ZERO flow nodes and save as a document containing`);
    console.log('      NONE of the author\'s content — only our invented lane skeleton and aef: layer:');
    for (const n of emptied) console.log(`      ${n}`);
    console.log('      This is not annotation, it is SUBSTITUTION, and it reports as a clean import:');
    console.log('      parseBpmnXml returns a map rather than null, so no gate on this side fires.');
    console.log('      Cause is known and already filed — T-348 (parseBpmnXml reads processes[0]');
    console.log('      only) meeting T-358 path (iii). What is new here is the CONSEQUENCE: when the');
    console.log('      first process is an empty stub, the surviving document is entirely ours.');
  }

  console.log('\n--- what this says about RAIL-441 ---\n');
  const uidPct = 100 * uidAdd / total;
  console.log(`  uid is ${uidPct.toFixed(1)}% of the aef: layer. The number matters less than what is left:`);
  console.log(`  implementing RAIL-441 as written removes ${uidAdd} of ${total} injected aef: elements and`);
  console.log(`  leaves ${total - uidAdd}, plus ${synthLanes} invented lanes it does not scope over at all.`);
  console.log('  Open-and-save stays a non-no-op on a foreign document; the diff gets shorter.');
  console.log();
  console.log('  This conclusion does NOT hinge on uid being a minority — it would hold at 80%,');
  console.log('  because the property AEF wants back is binary. Any residue defeats it.');
  console.log();
  console.log('  So the rule is right and its SCOPE is the thing to fix. Not "uid persistence');
  console.log('  follows authorship" but "we do not modify a document we did not author", of');
  console.log('  which uid is one line and the synthesised lane structure is the largest.');
  console.log();
  console.log('  SCOPE. Measured on 10 third-party fixtures via open->save with no edit. It does');
  console.log('  not measure what an actual EDIT adds (strictly more), nor documents whose shapes');
  console.log('  these 10 do not reach. A per-document footprint scales with node and edge count,');
  console.log('  so the percentages are the portable result and the absolute counts are not.');
  return 0;
}

async function main() {
  const names = readdirSync(FIXDIR).filter(f => f.endsWith('.bpmn')).sort();
  if (!names.length) { console.error('no fixtures in ' + FIXDIR); return 2; }

  const doc = mkdtempSync(join(tmpdir(), 't367-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't367-repo-'));
  writeFileSync(join(doc, 'designer.html'), readFileSync(SRC, 'utf8'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't367-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl; const results = [];
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    for (const name of names) {
      const xml = readFileSync(join(FIXDIR, name), 'utf8');
      await ev(cmd, `window.__IN__ = ${JSON.stringify(xml)};`);
      const r = await ev(cmd, `(function(){
        var prev = state;
        try {
          var m = parseBpmnXml(window.__IN__);
          if (!m) { state = prev; return { fatal: 'parseBpmnXml returned null' }; }
          state = m; refreshDisplayIds(); var x = buildBpmnXml(state); state = prev;
          return { xml: x, nodes: m.nodes.length, edges: m.edges.length, lanes: (m.lanes||[]).length,
                   prov: m.laneProvenance || '(none)' };
        } catch (e) { state = prev; return { fatal: String(e && e.message || e) }; }
      })()`);
      if (r.fatal) { results.push({ name, ok: false, err: r.fatal }); continue; }
      if (process.env.T367_DUMP && name.includes(process.env.T367_DUMP)) {
        console.log(`\n===== T367_DUMP: emitted bytes for ${name} =====\n${r.xml}\n===== end dump =====\n`);
      }
      const inMap = harvest(decomment(xml)), outMap = harvest(decomment(r.xml));
      const sum = m => [...m.values()].reduce((a, b) => a + b, 0);
      // Comment contamination: how much would a raw-bytes count have over-reported?
      const commentBorne = sum(harvest(r.xml)) - sum(outMap);
      results.push({
        name, ok: true, inMap, outMap, inTotal: sum(inMap), outTotal: sum(outMap),
        nodes: r.nodes, edges: r.edges, lanes: r.lanes, commentBorne, prov: r.prov,
        structIn: structure(xml), structOut: structure(r.xml),
        bytesIn: Buffer.byteLength(xml), bytesOut: Buffer.byteLength(r.xml),
      });
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  return main2(results);
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
