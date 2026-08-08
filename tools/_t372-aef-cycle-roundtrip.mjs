#!/usr/bin/env node
/**
 * _t372-aef-cycle-roundtrip.mjs — does AEF's three-lane inception cycle survive an
 * open->save through the designer?
 *
 * ANSWERS RAIL-445 Q2. AEF asked us to probe `draft-inception-readiness` v2 for
 * importer damage before they promote a v3. The shape they care about is a cycle:
 * a Framework-lane gateway with three outbound edges, two of which are RETURN edges,
 * one of those re-entering a COLLAPSED subProcess in a different lane, the other
 * going to a Human-lane user task that itself returns to that same subProcess.
 *
 * THE IDS THEY GAVE DO NOT EXIST (T-372, reported at RAIL-448). `fw_6_readiness` and
 * `hum_7_dialogue` appear nowhere in the document — not as ids, not as names. The
 * topology they described is real and correct; only the identifiers were quoted from
 * memory. The mapping, measured from their own bytes:
 *
 *     fw_6_readiness  ->  fw_2_proposed    (framework lane, exclusiveGateway)
 *     hum_7_dialogue  ->  hum_1_operator   (human lane, userTask)
 *
 * A probe keyed on the ids as given would have reported "the cycle you describe is
 * not present" — true, confident, and worse than useless. This one is keyed on the
 * real ids, and asserts up front that the topology IS there in the input, because a
 * "survived" verdict over a population that never contained the shape is vacuous.
 *
 * WHY THE MUTATION PASS IS NOT OPTIONAL. Every claim below is checked twice: once
 * against the real output, and once against the output with a targeted mutation that
 * SHOULD break exactly that claim. A claim that stays green under its own mutation
 * is not measuring what its name says, and its clean verdict on the real output means
 * nothing. Exit 1 if any claim fails to go red on its mutation.
 *
 * Usage: node tools/_t372-aef-cycle-roundtrip.mjs
 * Exit 0 = teeth proven and the verdicts read (findings and all).
 * Exit 1 = a claim has no teeth, or the harness broke; read nothing off the verdicts.
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXTURE = join(REPO, 'tests/fixtures/third-party/aef-draft-inception-readiness-v2.bpmn');

// Identity AEF published on the rail. Measuring unverified bytes measures an unknown
// document, so this is asserted before anything else runs.
const EXP_BYTES = 18472;
const EXP_SHA = 'fe3a520ddd51523e3cdd55da0aea428368a07b05e481246c837c6330d9c4a846';

// The cycle participants, under their REAL ids.
const GATEWAY = 'fw_2_proposed';   // AEF called this fw_6_readiness
const SUBPROC = 'agt_4_explore';
const OPERATOR = 'hum_1_operator'; // AEF called this hum_7_dialogue
const FORWARD = 'fw_3_put';

// AEF's trailer comment, verbatim — reused by the advice control below.
const DI_TRAILER_TEXT = '<!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->';

// ---------------------------------------------------------------------------
// EXPECTED LOSS — declared before measuring, per T-372 AC4.
//
// Stating this after seeing output would let the result be retro-fitted to whatever
// came out: anything that dropped would become "expected". So it is fixed here, it
// is short, and it is exhaustive. ANYTHING ELSE THAT DROPS IS A FINDING.
// ---------------------------------------------------------------------------
const EXPECTED_LOSS = [
  {
    what: 'the XML comment "<!-- BPMN DI (visual layout) omitted in this demo ... -->"',
    why: 'our T-311 — comments are not retained through parse->emit. AEF explicitly asked '
       + 'that this not be reported as a finding; it is known, filed, and theirs to expect.',
  },
];

// ---------------------------------------------------------------------------
// CLAIMS — each with the mutation that must break it.
//
// `plausible` marks claims our exporter could realistically break, so a clean run is
// not read as "we tested things that could never fail". The subProcess claims carry
// it on evidence: tests/fixtures/third-party/PROVENANCE.md already records that this
// importer flattens nested subProcesses.
// ---------------------------------------------------------------------------
const CLAIMS = [
  {
    id: 'C1',
    text: `${GATEWAY} retains exactly THREE outbound edges`,
    plausible: true,
    check: g => {
      const out = g.flows.filter(f => f.src === GATEWAY);
      return out.length === 3
        ? { ok: true, detail: `3 outbound: ${out.map(f => f.tgt).sort().join(', ')}` }
        : { ok: false, detail: `${out.length} outbound (expected 3): ${out.map(f => f.tgt).join(', ') || 'none'}` };
    },
    // Drop one outbound edge.
    mutate: x => x.replace(/<bpmn:sequenceFlow[^>]*sourceRef="fw_2_proposed"[^>]*targetRef="fw_3_put"[^>]*(\/>|>[\s\S]*?<\/bpmn:sequenceFlow>)/, ''),
  },
  {
    id: 'C2',
    text: `return edge ${GATEWAY} -> ${SUBPROC} survives (cross-lane, framework -> agent)`,
    plausible: true,
    check: g => hasEdge(g, GATEWAY, SUBPROC),
    mutate: x => x.replace(/(<bpmn:sequenceFlow[^>]*sourceRef="fw_2_proposed"[^>]*)targetRef="agt_4_explore"/, '$1targetRef="fw_3_put"'),
  },
  {
    id: 'C3',
    text: `return edge ${OPERATOR} -> ${SUBPROC} survives (cross-lane, human -> agent)`,
    plausible: true,
    check: g => hasEdge(g, OPERATOR, SUBPROC),
    mutate: x => x.replace(/(<bpmn:sequenceFlow[^>]*sourceRef="hum_1_operator"[^>]*)targetRef="agt_4_explore"/, '$1targetRef="fw_3_put"'),
  },
  {
    id: 'C4',
    text: `forward edge ${GATEWAY} -> ${FORWARD} survives`,
    plausible: false,
    check: g => hasEdge(g, GATEWAY, FORWARD),
    mutate: x => x.replace(/(<bpmn:sequenceFlow[^>]*sourceRef="fw_2_proposed"[^>]*)targetRef="fw_3_put"/, '$1targetRef="hum_1_operator"'),
  },
  {
    id: 'C5',
    text: `${SUBPROC} is still a subProcess and is still COLLAPSED (no children introduced)`,
    plausible: true,
    check: g => {
      const n = g.nodes.get(SUBPROC);
      if (!n) return { ok: false, detail: `${SUBPROC} absent from output entirely` };
      if (n.tag !== 'subProcess') return { ok: false, detail: `re-typed to bpmn:${n.tag} — flattened or downgraded` };
      return n.childFlowElements === 0
        ? { ok: true, detail: 'bpmn:subProcess, 0 child flow elements (collapsed)' }
        : { ok: false, detail: `bpmn:subProcess but gained ${n.childFlowElements} child flow element(s) — expanded` };
    },
    // Re-type it, which is exactly what a flattening importer would produce.
    mutate: x => x.replace(/<bpmn:subProcess (id="agt_4_explore")/, '<bpmn:serviceTask $1')
                  .replace(/<\/bpmn:subProcess>/, '</bpmn:serviceTask>'),
  },
  {
    id: 'C6',
    text: 'lane membership of every cycle participant is unchanged',
    plausible: true,
    check: g => {
      const want = { [GATEWAY]: 'framework', [SUBPROC]: 'agent', [OPERATOR]: 'human', [FORWARD]: 'framework' };
      const wrong = [];
      for (const [node, lane] of Object.entries(want)) {
        const got = g.laneOf.get(node);
        if (got !== lane) wrong.push(`${node}: ${got === undefined ? 'NO LANE' : got} (expected ${lane})`);
      }
      return wrong.length
        ? { ok: false, detail: wrong.join('; ') }
        : { ok: true, detail: 'framework/agent/human assignments all intact across 3 lanes' };
    },
    // T-341's shape: an orphaned node reassigned to the human lane.
    mutate: x => x.replace(/<bpmn:flowNodeRef>fw_2_proposed<\/bpmn:flowNodeRef>/, ''),
  },
  {
    id: 'C7',
    text: `${SUBPROC} retains all THREE inbound edges (re-parenting would strand them)`,
    plausible: true,
    check: g => {
      const inc = g.flows.filter(f => f.tgt === SUBPROC);
      return inc.length === 3
        ? { ok: true, detail: `3 inbound from: ${inc.map(f => f.src).sort().join(', ')}` }
        : { ok: false, detail: `${inc.length} inbound (expected 3): ${inc.map(f => f.src).join(', ') || 'none'}` };
    },
    mutate: x => x.replace(/<bpmn:sequenceFlow[^>]*targetRef="agt_4_explore"[^>]*(\/>|>[\s\S]*?<\/bpmn:sequenceFlow>)/, ''),
  },
];

function hasEdge(g, src, tgt) {
  const f = g.flows.find(x => x.src === src && x.tgt === tgt);
  return f ? { ok: true, detail: `present as ${f.id}` } : { ok: false, detail: `ABSENT: no flow ${src} -> ${tgt}` };
}

// ---------------------------------------------------------------------------
// Structural read. Deliberately the same routine for input and output, so a
// difference is a difference in the documents and not in how they were parsed.
// ---------------------------------------------------------------------------
const NODE_TAGS = ['task', 'userTask', 'serviceTask', 'scriptTask', 'manualTask', 'sendTask', 'receiveTask',
                   'businessRuleTask', 'callActivity', 'subProcess', 'exclusiveGateway', 'parallelGateway',
                   'inclusiveGateway', 'eventBasedGateway', 'startEvent', 'endEvent',
                   'intermediateThrowEvent', 'intermediateCatchEvent', 'boundaryEvent'];

function readGraph(xml) {
  const flows = [];
  for (const m of xml.matchAll(/<bpmn:sequenceFlow\b([^>]*)>/g)) {
    const a = attrs(m[1]);
    if (a.id && a.sourceRef && a.targetRef) flows.push({ id: a.id, src: a.sourceRef, tgt: a.targetRef });
  }
  const nodes = new Map();
  for (const tag of NODE_TAGS) {
    const re = new RegExp(`<bpmn:${tag}\\b([^>]*?)(/)?>`, 'g');
    for (const m of xml.matchAll(re)) {
      const a = attrs(m[1]);
      if (!a.id) continue;
      let childFlowElements = 0;
      if (tag === 'subProcess' && !m[2]) {
        const block = new RegExp(`<bpmn:subProcess\\b[^>]*\\bid="${a.id}"[\\s\\S]*?</bpmn:subProcess>`).exec(xml);
        if (block) for (const t of NODE_TAGS) childFlowElements += (block[0].match(new RegExp(`<bpmn:${t}\\b`, 'g')) || []).length;
        if (block) childFlowElements -= 1; // the subProcess open tag itself
      }
      nodes.set(a.id, { tag, name: a.name || '', childFlowElements });
    }
  }
  const laneOf = new Map();
  for (const m of xml.matchAll(/<bpmn:lane\b([^>]*)>([\s\S]*?)<\/bpmn:lane>/g)) {
    const a = attrs(m[1]);
    for (const r of m[2].matchAll(/<bpmn:flowNodeRef>([^<]+)<\/bpmn:flowNodeRef>/g)) laneOf.set(r[1].trim(), a.id);
  }
  return { flows, nodes, laneOf };
}
function attrs(s) { const o = {}; for (const a of s.matchAll(/([A-Za-z_:][\w.:-]*)="([^"]*)"/g)) o[a[1]] = a[2]; return o; }

// ---------------------------------------------------------------------------
// CDP plumbing (same mechanism as _t364-aef-ext-roundtrip.mjs)
// ---------------------------------------------------------------------------
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  // --- fixture identity, before anything else ------------------------------
  const raw = readFileSync(FIXTURE);
  const sha = createHash('sha256').update(raw).digest('hex');
  if (raw.length !== EXP_BYTES || sha !== EXP_SHA) {
    console.error(`FIXTURE IDENTITY FAILED: ${raw.length} B sha ${sha.slice(0, 12)}`);
    console.error(`  expected ${EXP_BYTES} B sha ${EXP_SHA.slice(0, 12)} (AEF's published values)`);
    return 1;
  }
  const IN = raw.toString('utf8');
  console.log(`fixture identity OK — ${raw.length} B, sha256 ${sha.slice(0, 12)}… (matches AEF's published values)`);

  // --- the topology must EXIST in the input, or every verdict below is vacuous
  const gIn = readGraph(IN);
  const inFails = CLAIMS.map(c => ({ c, r: c.check(gIn) })).filter(x => !x.r.ok);
  if (inFails.length) {
    console.error('\nINPUT DOES NOT CARRY THE SHAPE — the population cannot contain the defect:');
    for (const { c, r } of inFails) console.error(`  ${c.id}: ${r.detail}`);
    return 1;
  }
  console.log(`input carries the full cycle: all ${CLAIMS.length} claims hold BEFORE import\n`);

  // --- round-trip -----------------------------------------------------------
  const doc = mkdtempSync(join(tmpdir(), 't372-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't372-repo-'));
  writeFileSync(join(doc, 'designer.html'), readFileSync(join(REPO, 'src/aef-workflow-designer.html'), 'utf8'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't372-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, out = null, err = null, advice = null;
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    const roundTrip = async xml => {
      await ev(cmd, `window.__IN__ = ${JSON.stringify(xml)};`);
      return ev(cmd, `(function(){
        var prev = state; var m = parseBpmnXml(window.__IN__);
        if (!m) { state = prev; return { fatal: 'parseBpmnXml returned null' }; }
        state = m; refreshDisplayIds(); var x = buildBpmnXml(state); state = prev;
        return { xml: x, nodes: m.nodes.length, edges: m.edges.length, lanes: (m.lanes||[]).length };
      })()`);
    };
    const r = await roundTrip(IN);
    if (r.fatal) err = r.fatal;
    else { out = r; console.log(`imported: ${r.nodes} nodes, ${r.edges} edges, ${r.lanes} lane(s)`); }

    // ADVICE CONTROL. Before telling AEF "move rationale to leading position and it
    // survives", measure it — on their document, with their text. T-311 point 5 says a
    // HOISTED trailer is refused by content, not just position, so the obvious advice
    // may be wrong for this exact string. Two variants, opposite predictions:
    if (!err) {
      const AUTHORED = '<!-- Rationale: the not-ready edges route back into whichever mode is owed. -->';
      const hoisted = IN.replace(/\s*<!--[\s\S]*?-->\s*(<\/bpmn:definitions>)/, '\n$1')
                        .replace(/(<bpmn:definitions[^>]*>)/, `$1\n  ${DI_TRAILER_TEXT}`);
      const authored = IN.replace(/(<bpmn:definitions[^>]*>)/, `$1\n  ${AUTHORED}`);
      const rh = await roundTrip(hoisted), ra = await roundTrip(authored);
      advice = {
        hoisted: rh.fatal ? 'PARSE FAILED' : (rh.xml.includes('AEF generates it from node coordinates') ? 'KEPT' : 'REFUSED'),
        authored: ra.fatal ? 'PARSE FAILED' : (ra.xml.includes('the not-ready edges route back into whichever mode is owed') ? 'KEPT' : 'REFUSED'),
      };
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
  if (err || !out) { console.error('HARNESS BROKEN: ' + (err || 'no output')); return 1; }
  const OUT = out.xml;

  // --- id survival, diagnosed separately ------------------------------------
  // If the ids were rewritten, every claim below would go red for one reason and
  // report as six. Distinguish that here rather than let it masquerade as damage.
  const gOut = readGraph(OUT);
  const missing = [GATEWAY, SUBPROC, OPERATOR, FORWARD].filter(id => !gOut.nodes.has(id));
  if (missing.length === 4) {
    console.error('\nALL FOUR CYCLE IDS ABSENT FROM OUTPUT — this is an id-rewrite, not edge damage.');
    console.error('  The claims below would all go red for a single cause. Diagnose the id mapping first.');
    return 1;
  }
  if (missing.length) console.log(`\nNOTE: ${missing.length} of 4 cycle ids absent from output: ${missing.join(', ')}`);

  // --- verdicts -------------------------------------------------------------
  console.log('\nRAIL-445 Q2 — per-claim verdicts (ids corrected per RAIL-448):\n');
  const results = CLAIMS.map(c => ({ c, r: c.check(gOut) }));
  for (const { c, r } of results) {
    console.log(`  ${r.ok ? 'PASS' : 'FAIL'}  ${c.id}  ${c.text}`);
    console.log(`        ${r.detail}`);
  }

  // --- expected loss, declared before measuring ------------------------------
  console.log('\n  Expected loss (fixed before the run, not after):');
  for (const e of EXPECTED_LOSS) console.log(`    - ${e.what}\n      ${e.why}`);
  // Compare comment TEXT, not comment COUNT. "1 in, 1 out" cannot tell a surviving
  // comment from a different one our emitter wrote in its place — a total is blind to
  // substitution, and this one would have read as preservation either way.
  const norm = x => (x.match(/<!--[\s\S]*?-->/g) || []).map(c => c.replace(/\s+/g, ' ').trim());
  const cIn = norm(IN), cOut = norm(OUT);
  const kept = cIn.filter(c => cOut.includes(c));
  const lost = cIn.filter(c => !cOut.includes(c));
  const added = cOut.filter(c => !cIn.includes(c));
  console.log(`    observed: ${cIn.length} comment(s) in / ${cOut.length} out — ${kept.length} kept, ${lost.length} lost, ${added.length} new`);
  for (const c of lost) console.log(`      LOST : ${c.slice(0, 88)}`);
  for (const c of added) console.log(`      NEW  : ${c.slice(0, 88)}`);
  for (const c of kept) console.log(`      KEPT : ${c.slice(0, 88)}`);
  // POST-RUN REFINEMENT, marked as such. The declaration above is left exactly as it
  // was written before the run — revising it now is the retro-fit AC4 exists to stop.
  // The PREDICTION (this comment will not survive) was right. The REASON given
  // ("comments are not retained") was wrong, and the run is what corrected it:
  //
  //   T-311 retains the LEADING comment child of <bpmn:definitions> — the authored doc
  //   block, ahead of <bpmn:collaboration>. AEF's comment is not that. It sits at char
  //   18290 of 18403, after </bpmn:process>, immediately before </bpmn:definitions>:
  //   a TRAILER. T-311 contract points 4 and 5 refuse trailers deliberately, including
  //   hoisted ones, because promoting our own DI trailer to rationale is the defect
  //   that poisoned 5 of AEF's 11 maps.
  //
  // So this is the contract working, not importer damage — and the substitution is the
  // part worth telling them: they do not get a REMOVED line in a diff, they get a
  // CHANGED one carrying text they did not write.
  if (lost.length && added.length) {
    console.log('    -> not damage: the lost comment is a TRAILER (after </bpmn:process>), and T-311');
    console.log('       deliberately refuses trailers. Our emitter writes its own in that slot, so a');
    console.log('       diff shows a CHANGED line, not a removed one. Rationale meant to survive must');
    console.log('       be the LEADING comment child of <bpmn:definitions>, ahead of <bpmn:collaboration>.');
  } else if (!lost.length && kept.length) {
    console.log('    -> the declared expected loss DID NOT OCCUR: the comment survived verbatim.');
  }
  if (advice) {
    console.log('\n  Advice control — measured before advising AEF where to put rationale:');
    console.log(`    their trailer text HOISTED to leading position : ${advice.hoisted}`);
    console.log(`    a distinct authored rationale, leading position : ${advice.authored}`);
    if (advice.hoisted === 'REFUSED' && advice.authored === 'KEPT') {
      console.log('    -> position alone is NOT enough. The guard reads content: DI-boilerplate is');
      console.log('       refused even when hand-moved to the leading slot (T-311 point 5). Authored');
      console.log('       rationale in that slot is kept. Advising "just move it up" would have been');
      console.log('       wrong for this exact string.');
    } else if (advice.hoisted === 'KEPT') {
      console.log('    -> the boilerplate guard did NOT refuse the hoisted trailer. T-311 point 5 says');
      console.log('       it should. That is a finding against our own contract, not against AEF.');
    }
  }

  // --- teeth: every claim must go red under its own mutation ----------------
  console.log('\n  Teeth — each claim re-checked against output mutated to break exactly it:');
  let toothless = 0;
  for (const { c } of results) {
    const mutated = c.mutate(OUT);
    if (mutated === OUT) { console.log(`    NO-OP  ${c.id}  mutation changed nothing — cannot prove teeth`); toothless++; continue; }
    const mr = c.check(readGraph(mutated));
    if (mr.ok) { console.log(`    NO TEETH  ${c.id}  still PASSES when broken — this claim measures nothing`); toothless++; }
    else console.log(`    red  ${c.id}  ${mr.detail}`);
  }
  if (toothless) {
    console.error(`\n  ${toothless} claim(s) without teeth. Read nothing off the verdicts above.`);
    return 1;
  }

  const failed = results.filter(x => !x.r.ok);
  console.log();
  if (!failed.length) {
    console.log(`  ALL ${results.length} CLAIMS SURVIVE. AEF's cycle round-trips intact: the gateway keeps`);
    console.log('  its three outbound edges, both return edges survive including the cross-lane');
    console.log('  re-entry, the subProcess stays collapsed, and lane membership is unchanged');
    console.log('  across all three lanes.');
    console.log();
    console.log('  Scope: ONE document, the cycle region only. It does not clear the rest of the');
    console.log('  fixture, and it is not a statement about documents this one does not resemble.');
  } else {
    console.log(`  *** ${failed.length} CLAIM(S) FAIL — importer damage in the region AEF asked about:`);
    for (const { c, r } of failed) console.log(`      ${c.id}  ${c.text}\n           ${r.detail}`);
    console.log('\n  None of these is on the expected-loss list, so each is a finding.');
  }
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.stack || e)); process.exit(2); });
