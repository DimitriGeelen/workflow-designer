#!/usr/bin/env node
/**
 * T-523 — what happens to an externally-assigned aef:uid on a node NESTED INSIDE a subProcess.
 *
 * Third of the four gaps _t515 names in its own does_not_cover, and the last one on our side of
 * the boundary: the fourth is AEF's reverse renderer, which cannot be exercised from here at all.
 *
 * WHY THIS IS NOT "DOES THE UID SURVIVE". A uid can survive while its CONTAINMENT does not, and
 * that is a third outcome, not a shade of the first. AEF keys records on uid; if a node comes
 * back with its uid intact but no longer inside the subProcess it was authored in, the record
 * survives and its scope silently changes parent. That is worse than losing it, because losing
 * it is at least detectable by counting. So every verdict here carries the ancestry, read by a
 * conforming parser (tools/_t523-xml-structure.py), never by the browser's own DOMParser —
 * T-520's lesson, learned the expensive way: the producer's parser agreed with the producer's
 * defect and reported a corrupted round-trip as byte-identical.
 *
 * TWO ARMS, BECAUSE ONE ARM CANNOT NAME A CAUSE. Arm NESTED injects a subProcess containing two
 * flow nodes and a sequence flow. Arm FLAT injects the SAME two nodes, with the same uids, as
 * direct children of <bpmn:process>. If the flat arm survives and the nested arm does not, the
 * variable is nesting and the probe has demonstrated that rather than asserted it. If BOTH
 * arms vanish, the finding is about injection or staging — emphatically not about subProcess —
 * and reporting it as a nesting defect would be a fabrication. A single-arm probe cannot tell
 * those apart, and would confidently report the wrong one.
 *
 * THERE IS A CLAIM IN THE SOURCE ALREADY, WHICH IS EXACTLY WHY IT NEEDS MEASURING.
 * parseBpmnXml's T-337 comment states "the whole interior of an accepted element is dropped
 * today". That is a comment: an assumption with an expiry date that nothing re-checks (the
 * T-509 class). It may be true, stale, or true-but-imprecise about which parts go. A comment
 * is not a measurement and cannot be cited to AEF.
 *
 * CHARACTERISATION, NOT A VERDICT (as T-518 and T-520). Nobody has ratified what SHOULD happen
 * to a nested node's uid. This pins what IS and goes red on a CHANGE, rather than legislating a
 * co-designed standard from a test file.
 *
 * Usage: node tools/_t523-subprocess-nesting.mjs
 *   rc 0  measured, and every observation matches its pin
 *   rc 1  behaviour changed — tell AEF before they find out from a broken record
 *   rc 2  REFUSE: could not measure (no corpus, staging failed, negative control dead, unpinned)
 */
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = process.env.T523_CORPUS || join(REPO, 'examples', 'aef-processes', 'rendered');
// Overridable so the teeth can point this at a MUTATED copy of the editor and prove the pin can
// move at all. Defaults to the real thing; a probe that can only ever be run against the tree
// that already satisfies it is not evidence (PL-206).
const SRC = process.env.T523_SRC || join(REPO, 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

// ── the injected fixture ──────────────────────────────────────────────────────────────────
// Deliberately conventional: uid + position in extensionElements, exactly as every corpus node
// is written. A fixture that is unusual in ways OTHER than the property under test cannot
// attribute its own result — if this were dropped for want of a position, the finding would
// read as "nesting loses nodes" and be wrong.
const SUB_UID = 'n_t523_sub';
const CHILD_A = 'n_t523_child_a';
const CHILD_B = 'n_t523_child_b';

const task = (id, uid, name, x, y) => `
    <bpmn:serviceTask id="${id}" name="${name}">
      <bpmn:extensionElements>
        <aef:uid value="${uid}"/>
        <aef:position x="${x}.0" y="${y}.0"/>
      </bpmn:extensionElements>
    </bpmn:serviceTask>`;

// Arm NESTED — a real subProcess with real flowElement children, the shape AEF would author.
const NESTED_BLOCK = `
    <bpmn:subProcess id="t523_sub" name="T523 scope">
      <bpmn:extensionElements>
        <aef:uid value="${SUB_UID}"/>
        <aef:position x="1200.0" y="120.0"/>
      </bpmn:extensionElements>${task('t523_a', CHILD_A, 'T523 nested A', 1220, 140)}${task('t523_b', CHILD_B, 'T523 nested B', 1340, 140)}
      <bpmn:sequenceFlow id="t523_flow" sourceRef="t523_a" targetRef="t523_b"/>
    </bpmn:subProcess>`;

// Arm FLAT — same two nodes, same uids, SAME connecting flow, no containment. The discriminator.
//
// The sequenceFlow is here because of a mistake worth leaving recorded: the first version of
// this arm had the two tasks and no flow, so the flat arm reported `edge: lost` — trivially,
// since no edge had been injected for it to keep. A control that differs from the treatment in
// MORE than the variable under test cannot attribute anything, and this one would have written
// a fixture artifact into the pin as though it were a measured property of flat nodes.
const FLAT_BLOCK = `${task('t523_a', CHILD_A, 'T523 flat A', 1220, 140)}${task('t523_b', CHILD_B, 'T523 flat B', 1340, 140)}
    <bpmn:sequenceFlow id="t523_flow" sourceRef="t523_a" targetRef="t523_b"/>`;

// Arm COLLAPSED — a subProcess with NO flowElement children at all, carrying only its
// extensionElements. Added for T-528 at AEF's request (rail 11926/11930) after they measured
// their own corpus and reported that this is not an edge case for them but their ENTIRE
// population: subProcess appears in three published maps and three drafts, and parsed rather
// than grepped, every one is childless — `children={'extensionElements': 1}`, zero contained
// flow nodes. They use subProcess as a TYPED MARKER, deliberately (commit 226fe8680, "G-3
// collapsed-subProcess dialect round-trips"), corroborated by no isExpanded on any DI shape.
//
// WHY THE OTHER TWO ARMS DO NOT COVER THIS, which is the part worth recording: both inject a
// subProcess WITH children, because the question they were built for was containment. Containment
// is answerable only when there is something contained. So the pair covers 100% of the question I
// asked and 0% of AEF's actual usage, and no amount of care about the arms I had would have
// surfaced that — it took their corpus. A probe's coverage gap is a fact about the population it
// was aimed at, not about the rigour of its controls.
//
// WHAT THIS ARM ASSERTS IS NOT WHAT THE OTHERS ASSERT. They ask whether children survive
// containment. This asks whether the ELEMENT TYPE survives at all: a round-trip that rewrites a
// childless subProcess into a task is a defensible cleanup — there is nothing to scope, so why
// carry a scope element — and it would silently degrade every collapsed node in three published
// maps to an untyped activity. "The uid came back" is the answer to a question AEF did not ask.
//
// Deliberately NO sequenceFlow and NO children: the arm must be childless or it is testing the
// nested arm again under a different name. The stimulus check below enforces that rather than
// trusting this string, because the fixture and the assertion are edited by different hands at
// different times, and the one that goes stale silently is the fixture.
const COLLAPSED_UID = 'n_t523_collapsed';
const COLLAPSED_BLOCK = `
    <bpmn:subProcess id="t523_collapsed" name="T523 collapsed">
      <bpmn:extensionElements>
        <aef:uid value="${COLLAPSED_UID}"/>
        <aef:position x="1200.0" y="300.0"/>
      </bpmn:extensionElements>
    </bpmn:subProcess>`;

// ── the pin ───────────────────────────────────────────────────────────────────────────────
// Set from the first MEASURED run, not from expectation, and not from the source comment that
// prompted the task. An unpinned observation REFUSES rather than passing.
//
// The pin lives in tools/_t523-nesting.pin.json so that a change to it shows up in review as a
// one-line diff of a data file rather than buried in a source edit — the movement is the whole
// signal, and T-520's pin moved four times, three of them because I was wrong rather than
// because the editor changed.
//
// Absent pin does NOT crash and does NOT pass: the run measures, then REFUSES and prints what
// it saw, so the pin can be written from a real measurement instead of from expectation. That
// ordering is deliberate — every time I have drafted a pin from what I believed the code did,
// the belief was wrong in at least one entry.
const PIN_FILE = process.env.T523_PIN || join(REPO, 'tools/_t523-nesting.pin.json');
const PIN = existsSync(PIN_FILE) ? JSON.parse(readFileSync(PIN_FILE, 'utf8')) : null;

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const ROUNDTRIP = src => `(function(){ state = parseBpmnXml(${JSON.stringify(src)}); refreshDisplayIds(); return buildBpmnXml(state); })()`;

const refuse = (msg, extra = {}) => { console.log(JSON.stringify({ ok: false, refusal: msg, ...extra }, null, 2)); process.exitCode = 2; };

// Every verdict comes from here. Path written as one repo-relative literal so T-451's census can
// see the edge — a runtime-composed path is invisible to it, which its own LIMIT section says.
const readStructure = text => new Promise((res, rej) => {
  const p = spawn('python3', [join(REPO, 'tools/_t523-xml-structure.py')], { stdio: ['pipe', 'pipe', 'pipe'] });
  let o = '', e = '';
  p.stdout.on('data', d => o += d); p.stderr.on('data', d => e += d);
  p.on('close', code => {
    if (code !== 0) return rej(new Error('structure reader exited ' + code + ': ' + e.slice(-300)));
    try { res(JSON.parse(o)); } catch (_) { rej(new Error('structure reader emitted non-JSON: ' + o.slice(0, 200))); }
  });
  p.stdin.end(Buffer.from(text, 'utf8'));
});

const find = (doc, value) => doc.uids.find(u => u.value === value) || null;

// Classify one injected uid into an OUTCOME. The three-way split is the whole point: present
// and nested, present but flattened, and gone are three different facts about the seam.
function classify(after, value, expectNested) {
  const u = find(after, value);
  if (!u) return { outcome: 'dropped' };
  if (expectNested && !u.in_sub) return { outcome: 'survived-flattened', owner: u.owner, path: u.path };
  if (!expectNested && u.in_sub) return { outcome: 'survived-reparented-into-sub', owner: u.owner, path: u.path };
  return { outcome: 'survived', owner: u.owner, path: u.path };
}

async function main() {
  if (!existsSync(CORPUS)) return refuse('no corpus at ' + CORPUS);
  const files = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!files.length) return refuse('corpus empty — a nesting probe with no subject is not a pass');
  const srcName = basename(files[0], '.bpmn');
  const ORIGINAL = readFileSync(join(CORPUS, files[0]), 'utf8');

  const doc = mkdtempSync(join(tmpdir(), 't523-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't523-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't523-udd-'));
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

    const base = await readStructure(ORIGINAL);
    if (!base.parsed) return refuse('the corpus fixture itself does not parse — no verdict here is about the editor', { error: base.error });
    const flatControl = base.uids.filter(u => u.value && u.value.startsWith('n_') && !u.in_sub)[0];
    if (!flatControl) return refuse(`corpus map ${srcName} carries no top-level node uid to use as a control`);

    const CLOSE = '</bpmn:process>';
    if (ORIGINAL.split(CLOSE).length - 1 !== 1) {
      return refuse('fixture does not have exactly one </bpmn:process> — injection would not be surgical');
    }

    const arms = [
      { key: 'nested', block: NESTED_BLOCK, expectNested: true },
      { key: 'flat', block: FLAT_BLOCK, expectNested: false },
      { key: 'collapsed', block: COLLAPSED_BLOCK, expectNested: null },
    ];
    const measured = {};

    for (const arm of arms) {
      const input = ORIGINAL.replace(CLOSE, arm.block + '\n  ' + CLOSE);

      // ── stimulus check (PL-206), BEFORE the round-trip ──────────────────────────────
      // Did the injection actually produce the structure this arm claims to test? A probe
      // whose stimulus never contained the property under test passes forever while
      // measuring nothing — the single most expensive mistake available here.
      const inp = await readStructure(input);
      if (!inp.parsed) return refuse(`arm ${arm.key}: injected document does not parse — the fixture is broken, not the editor`, { error: inp.error });
      const wanted = arm.key === 'nested' ? [SUB_UID, CHILD_A, CHILD_B]
        : arm.key === 'collapsed' ? [COLLAPSED_UID]
          : [CHILD_A, CHILD_B];
      for (const w of wanted) {
        const u = find(inp, w);
        if (!u) return refuse(`arm ${arm.key}: staged uid ${w} is not present in the INPUT — staging failed`);
      }
      if (arm.key === 'collapsed') {
        // Stimulus check for THIS arm's property (PL-206). Two things must hold in the INPUT or
        // the arm is not testing AEF's population: the uid must be owned by a subProcess, and
        // that subProcess must contain ZERO flow nodes. The second is the one that rots — a
        // later edit to COLLAPSED_BLOCK that adds a child would turn this into a second nested
        // arm, and every run would still be green while covering none of what it claims.
        const c = find(inp, COLLAPSED_UID);
        if (c.owner !== 'subProcess') {
          return refuse(`arm collapsed: the staged uid is owned by <${c.owner}>, not <subProcess> — the fixture does not contain the element under test`, { path: c.path });
        }
        const kids = inp.flow_children_by_parent[c.owner_id];
        if (kids) {
          return refuse(`arm collapsed: the staged subProcess contains ${kids} flow node(s) — this arm is only a statement about CHILDLESS subProcesses, which is AEF's entire population, and a fixture with children re-tests the nested arm under another name`, { owner_id: c.owner_id, children: kids });
        }
      } else {
        const childA = find(inp, CHILD_A);
        if (childA.in_sub !== arm.expectNested) {
          return refuse(`arm ${arm.key}: staged child nesting is ${childA.in_sub}, expected ${arm.expectNested} — this arm is not testing what it says it tests`, { path: childA.path });
        }
      }

      let out;
      try { out = await ev(cmd, ROUNDTRIP(input)); }
      catch (e) { measured[arm.key] = { editor_threw: String(e.message).slice(0, 200) }; continue; }
      const after = await readStructure(out);
      if (!after.parsed) { measured[arm.key] = { output_malformed: (after.error || '').split('\n')[0] }; continue; }

      // NEGATIVE CONTROL, per arm: an ordinary top-level uid from the untouched fixture must
      // come through. If it does not, this run measured a broken round-trip rather than a
      // property of nesting, and every verdict in it is worthless.
      if (!find(after, flatControl.value)) {
        return refuse(`arm ${arm.key}: the NEGATIVE CONTROL uid ${flatControl.value} did not survive an ordinary round-trip — nothing in this run is a statement about subProcess`, { control: flatControl.value });
      }

      // Did the flow that joined the two injected nodes come through with them? Resolved by
      // UID, never by element id — ids are re-minted from lane and x-order on every save
      // (T-513), so matching on the id we injected would report every flow as lost.
      if (arm.key === 'collapsed') {
        // The property AEF depends on, stated as its own three-way outcome rather than as a
        // boolean. "Survived" and "survived but is now a <task>" are the same fact about the uid
        // and opposite facts about their dialect, so collapsing them would answer the question
        // they did not ask and hide the one they did.
        const c = find(after, COLLAPSED_UID);
        const kidsAfter = c ? (after.flow_children_by_parent[c.owner_id] || 0) : null;
        measured.collapsed = {
          node: !c ? { outcome: 'dropped' }
            : c.owner !== 'subProcess' ? { outcome: 'survived-retyped', owner: c.owner, path: c.path }
              : { outcome: 'survived', owner: c.owner, path: c.path },
          // Recorded because the inverse defect is possible and would be just as silent: an
          // editor that "helpfully" gives an empty scope a placeholder child changes what the
          // map MEANS without dropping anything, and nothing else here would notice.
          children_after: kidsAfter,
        };
        continue;
      }

      const ua = find(after, CHILD_A), ub = find(after, CHILD_B);
      const joined = !!(ua && ub && after.flows.some(f =>
        (f.source === ua.owner_id && f.target === ub.owner_id) ||
        (f.source === ub.owner_id && f.target === ua.owner_id)));

      measured[arm.key] = {
        sub: arm.key === 'nested' ? classify(after, SUB_UID, false) : null,
        child_a: classify(after, CHILD_A, arm.expectNested),
        child_b: classify(after, CHILD_B, arm.expectNested),
        // Two surviving nodes that arrive DISCONNECTED is a quieter loss than two that do not
        // arrive at all — nothing counts down, and the workflow simply means something else.
        edge_between_children: joined ? 'preserved' : 'lost',
        containment: after.flow_children_by_parent,
      };
    }

    // ── the discriminator ─────────────────────────────────────────────────────────────
    // Stated as a computed fact rather than left for the reader to infer from two blobs.
    const nestedA = measured.nested && measured.nested.child_a ? measured.nested.child_a.outcome : null;
    const flatKept = measured.flat && measured.flat.child_a && measured.flat.child_a.outcome === 'survived';
    // Three outcomes, not two. "The uid survived" is the answer to a question nobody asked:
    // what AEF needs to know is whether the RECORD comes back attached to the same parent.
    const attribution =
      !flatKept ? 'injection-or-staging-is-the-cause — NOT a subProcess finding, and no verdict below is about nesting'
        : nestedA === 'dropped' ? 'nesting-loses-the-node-entirely'
          : nestedA === 'survived-flattened' ? 'uid-survives-containment-does-not — the node is HOISTED to process level and the subProcess is left empty'
            : nestedA === 'survived' ? 'nesting-round-trips-intact'
              : 'inconclusive';

    const observed = { arms: measured, attribution };
    const summary = {
      nested: summarise(measured.nested),
      flat: summarise(measured.flat),
      collapsed: summariseCollapsed(measured.collapsed),
      attribution,
    };

    if (!PIN) {
      return refuse(
        `no pin file at tools/_t523-nesting.pin.json — this run MEASURED but has no reference to compare against, which is an abstention, not a pass. Write the summary below to that file once you have read it and believe it.`,
        { observed, summary_to_pin: summary });
    }
    for (const k of ['nested', 'flat', 'collapsed', 'attribution']) {
      if (!(k in PIN)) return refuse(`no pin for ${k} — "I have no reference for this" must not be indistinguishable from "it matched"`, { observed, summary_to_pin: summary });
    }
    const drift = [];
    // `_`-prefixed keys are prose for the reader of the pin file — the finding it records and
    // why it is written the way it is. They are not observations and must not be compared, or
    // improving a comment turns the instrument red.
    for (const k of Object.keys(PIN).filter(k => !k.startsWith('_'))) {
      const a = JSON.stringify(PIN[k]);
      const b = JSON.stringify(summary[k]);
      if (a !== b) drift.push({ key: k, pinned: PIN[k], measured: summary[k] });
    }

    console.log(JSON.stringify({
      ok: drift.length === 0,
      fixture: srcName,
      control: flatControl.value,
      observed,
      drift,
      does_not_cover: 'the AEF-side reverse renderer, which is the fourth and last gap _t515 names and cannot be exercised from here at all: I can state what is IN a document but not what AEF should produce from it, because "correct" there is a fact about their data model. Proposed as a fixture-pair contract at rail 11911; their operator decides. Also not covered: whether the editor SHOULD preserve nesting, which is a co-design question and is deliberately not legislated by this file.',
    }, null, 2));
    process.exitCode = drift.length === 0 ? 0 : 1;
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

// The pin compares OUTCOMES, not the whole measurement. Element ids are re-minted on every save
// (T-513), and containment counts carry generated ids as keys, so pinning the raw object would
// go red on an id change that means nothing. Outcome plus owner is the part that is a claim.
function summarise(m) {
  if (!m) return null;
  if (m.editor_threw) return { editor_threw: true };
  if (m.output_malformed) return { output_malformed: true };
  const o = x => (x ? { outcome: x.outcome, owner: x.owner ?? null } : null);
  return { sub: o(m.sub), child_a: o(m.child_a), child_b: o(m.child_b), edge: m.edge_between_children ?? null };
}

// The collapsed arm pins OUTCOME + OWNER + child count. Owner is pinned rather than merely
// checked against the literal 'subProcess' so that a retype is recorded as WHAT it became: the
// remedy for "it is now a task" and "it is now a callActivity" are different conversations with
// AEF, and a boolean would start both of them the same way.
function summariseCollapsed(m) {
  if (!m) return null;
  if (m.editor_threw) return { editor_threw: true };
  if (m.output_malformed) return { output_malformed: true };
  return {
    node: m.node ? { outcome: m.node.outcome, owner: m.node.owner ?? null } : null,
    children_after: m.children_after ?? null,
  };
}

main();
