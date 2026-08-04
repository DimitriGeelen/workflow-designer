#!/usr/bin/env node
/**
 * _t364-tie-permutes-ids.mjs — does a same-lane x tie actually permute EMITTED ids?
 *
 * The claim under test, stated so it can fail:
 *
 *   computeDisplayId ranks by (x, uid.localeCompare) and displayIdOf is the emitted
 *   BPMN element id. So two nodes tied on x, in one lane, WITHOUT aef:uid in the
 *   bytes, will swap emitted ids between two parses of identical input.
 *
 * Everything so far is a reading of sort code. This runs it.
 *
 * The census (tools/_t364-x-tie-census.py) found 19 of 24 corpus maps hold a
 * same-lane x collision — ties are ordinary, not exotic. They are harmless today
 * only because those maps carry aef:uid, which pins the tie-break across parses.
 *
 * That makes this probe a direct measurement of repair option (b) "mint the uid but
 * do not PERSIST it": stripping aef:uid from a real corpus map is exactly the
 * document (b) would produce on the next save. If ids permute here, (b) does not
 * merely fail to fix identity churn — it introduces churn into 19/24 maps that are
 * stable today.
 *
 * Design note — the control is the load-bearing half. Each map runs TWICE:
 *   with-uid     unmodified            -> expect STABLE (proves the harness is sound)
 *   without-uid  aef:uid stripped      -> expect PERMUTED (the finding)
 * A permutation reported without a stable control would be indistinguishable from a
 * flaky harness, and a stable control on a map with NO tie proves nothing either, so
 * the tie count is read out of the input and printed with every row.
 *
 * ---- POLARITY CHANGED WHEN REPAIR (a) LANDED. Read this before interpreting a run. ----
 *
 * This file was written as an EXPERIMENT against the pre-repair build, and in that era it
 * exited 0 when the DEFECT WAS PRESENT — it was explicitly not a gate, because it would
 * have gone red exactly when the fix worked and someone would then have "fixed" the probe.
 *
 * Repair (a) has landed (deriveUid in parseBpmnXml — uid derives from the BPMN element
 * id). The experiment's question is answered and its recorded result lives in the T-364
 * task: 4 tied maps PERMUTED, 2 tie-free controls held still. So the polarity is now
 * inverted ON PURPOSE and the file is a regression guard:
 *
 *   exit 0 = the repair holds — tied maps still have their ties, mint is stable, ids still
 *   exit 1 = REGRESSION (a map permuted), or the guard lost its subject (no map has a tie),
 *            or the mechanism reading is contradicted (permutation-free WITH a random mint)
 *   exit 2 = harness broken / a row is uninterpretable
 *
 * Which side of the repair the build is on is MEASURED per run (parse the uid-less bytes
 * twice, compare the uid vector) rather than assumed, so the verdict text cannot tell a
 * reader "your understanding of computeDisplayId is wrong" when the truth is "the code was
 * fixed underneath you".
 *
 * One caveat that outlives the repair: under a stable mint the tie-free control is INERT.
 * Nothing permutes any more, so a tie-free map holding still is guaranteed and discriminates
 * nothing. The quantities that still carry the run are the per-build mint measurement and
 * the tie counts. The verdict prints this rather than quietly counting an inert control as
 * corroboration.
 *
 * Usage: node tools/_t364-tie-permutes-ids.mjs
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = join(REPO, 'examples', 'aef-processes', 'rendered');

// Four maps the census named as holding same-lane x collisions, and TWO it named as
// tie-free. The tie-free rows are the discriminating half: if stripping aef:uid
// permuted ids there too, the cause would not be the tie and the whole reading would
// be wrong. The first version of this list had no genuine tie-free entry —
// context-memory was picked as one and turns out to hold a tie — so the run
// confirmed four times and separated nothing. Ties are common (19 of 24), which is
// exactly why a negative control has to be chosen from a census rather than assumed.
const TIED = ['audit-process', 'harvest-pipeline', 'arc-lifecycle', 'context-memory'];
const TIE_FREE = ['healing-loop', 'verification-gate'];
const PICKS = [...TIED, ...TIE_FREE];

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Remove every <aef:uid .../> element. This is what a (b)-style "mint but do not
// persist" save would leave behind, applied to a document that is stable today.
function stripUids(xml) {
  let n = 0;
  const out = xml.replace(/[ \t]*<aef:uid\b[^>]*\/>\s*\n?/g, () => { n++; return ''; });
  return [out, n];
}

// Count same-lane x collisions on the PARSED STATE, not on the bytes.
//
// The first version of this counted ties with a regex over the source XML and
// returned 0 for every map, while the XML-parsing census (_t364-x-tie-census.py)
// found ties in 19 of 24. Two instruments disagreeing meant the run was
// uninterpretable and the probe's own guard said so.
//
// Counting on state.nodes is not merely the working version, it is the correct
// subject: computeDisplayId sorts `state.nodes` by `n.x` within `n.lane`, so the
// tie that matters is a tie in THAT array — after import has resolved lane
// membership and filled any missing coordinate. A tie in the bytes is a proxy for
// it; this is the thing itself.
const TIE_EXPR = `(function(){
  var prev = state; var m = parseBpmnXml(window.__IN__);
  if (!m) { state = prev; return { fatal: 'parse returned null' }; }
  state = m;
  var buckets = {};
  for (var i=0;i<state.nodes.length;i++){
    var n = state.nodes[i];
    var k = String(n.lane) + '@' + String(n.x);
    (buckets[k] = buckets[k] || []).push(n.uid);
  }
  state = prev;
  var groups = 0, nodes = 0, widest = 0;
  for (var k in buckets) if (buckets[k].length > 1) {
    groups++; nodes += buckets[k].length;
    if (buckets[k].length > widest) widest = buckets[k].length;
  }
  return { groups: groups, nodes: nodes, widest: widest };
})()`;

// Emitted-id extraction: only the ids the DOCUMENT uses to identify flow nodes.
// aef:uid lines are deliberately excluded — this probe must not be able to report
// "permuted" on the churn we already know about.
function flowIds(xml) {
  return [...xml.matchAll(/<bpmn:flowNodeRef>([^<]*)<\/bpmn:flowNodeRef>/g)].map(m => m[1].trim());
}

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't364-tie-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't364-tie-repo-'));
  // T364_SRC: overridable so the REGRESSION branch can be exercised against a mutated
  // copy (tools/_t364-tie-guard-teeth.py) without ever touching the real source. Same
  // pattern as T358_FIXDIR in _t358-byteid-thirdparty.mjs.
  const SRC = process.env.T364_SRC || join(REPO, 'src/aef-workflow-designer.html');
  writeFileSync(join(doc, 'designer.html'), readFileSync(SRC, 'utf8'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't364-tie-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl; const rows = [];
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

    // Which side of the T-364 repair is this build on? Measured, not assumed: parse the
    // same uid-less bytes twice and compare the uid vector. Random minting => differs;
    // derived-from-element-id => identical. Without this the probe cannot tell "the tie
    // mechanism is wrong" from "the tie mechanism was fixed", and those two readings send
    // the reader to opposite places.
    const uidsMintedStably = async (text) => {
      await ev(cmd, `window.__IN__ = ${JSON.stringify(text)};`);
      return await ev(cmd, `(function(){
        function sig(){ var prev=state; var m=parseBpmnXml(window.__IN__); if(!m){ state=prev; return null; }
          var s = m.nodes.map(function(n){return n.uid;}).join(',') + '|' +
                  m.edges.map(function(e){return e.uid;}).join(',');
          state=prev; return s; }
        var a = sig(), b = sig();
        if (a===null||b===null) return null;
        return a === b;
      })()`);
    };

    const emitTwice = async (text) => {
      await ev(cmd, `window.__IN__ = ${JSON.stringify(text)};`);
      return await ev(cmd, `(function(){
        function once(){ var prev=state; var m=parseBpmnXml(window.__IN__); if(!m) return null;
          state=m; refreshDisplayIds(); var x=buildBpmnXml(state); state=prev; return x; }
        var a = once(), b = once();
        if (a===null||b===null) return { fatal:'parse returned null' };
        return { a:a, b:b };
      })()`);
    };

    for (const name of PICKS) {
      const path = join(CORPUS, name + '.bpmn');
      if (!existsSync(path)) { rows.push({ name, skip: 'missing' }); continue; }
      const src = readFileSync(path, 'utf8');
      const [stripped, removed] = stripUids(src);
      // Measure the tie on the STRIPPED document — that is the one whose ids are
      // under test, and stripping could in principle change lane resolution.
      await ev(cmd, `window.__IN__ = ${JSON.stringify(stripped)};`);
      const tie = await ev(cmd, TIE_EXPR);
      if (tie.fatal) { rows.push({ name, tie: { groups: 0, nodes: 0 }, fatal: 'tie count: ' + tie.fatal }); continue; }

      const stableMint = await uidsMintedStably(stripped);

      const ctl = await emitTwice(src);
      if (ctl.fatal) { rows.push({ name, tie, fatal: 'control: ' + ctl.fatal }); continue; }
      const exp = await emitTwice(stripped);
      if (exp.fatal) { rows.push({ name, tie, fatal: 'stripped: ' + exp.fatal }); continue; }

      const ctlIds = [flowIds(ctl.a), flowIds(ctl.b)];
      const expIds = [flowIds(exp.a), flowIds(exp.b)];
      rows.push({
        name, tie, removed, stableMint,
        controlStable: ctl.a === ctl.b,
        controlIdsSame: JSON.stringify(ctlIds[0]) === JSON.stringify(ctlIds[1]),
        strippedIdsSame: JSON.stringify(expIds[0]) === JSON.stringify(expIds[1]),
        idCount: expIds[0].length,
        sample: expIds[0].map((v, i) => [v, expIds[1][i]]).filter(([p, q]) => p !== q).slice(0, 3),
      });
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  console.log('\nDoes a same-lane x tie permute EMITTED element ids when aef:uid is absent?');
  console.log('(control = the map as it ships; stripped = the same map with aef:uid removed)\n');
  let broken = 0, confirmed = 0, refuted = 0, cleanNoTie = 0, repairHeld = 0;
  for (const r of rows) {
    if (r.skip) { console.log(`  ${r.name.padEnd(22)} SKIP (${r.skip})`); continue; }
    if (r.fatal) { console.log(`  ${r.name.padEnd(22)} FATAL ${r.fatal}`); broken++; continue; }
    const t = `${r.tie.groups} tie group(s)/${r.tie.nodes} node(s)`;
    console.log(`  ${r.name.padEnd(22)} ${t.padEnd(28)} uids stripped: ${r.removed}`);
    if (!r.controlStable || !r.controlIdsSame) {
      console.log(`      CONTROL UNSTABLE — the shipped map does not emit the same ids twice.`);
      console.log(`      Nothing below this line is interpretable for this map.`);
      broken++; continue;
    }
    console.log(`      control  : ids identical across two parses  (as expected — aef:uid pins the tie-break)`);
    if (r.strippedIdsSame) {
      console.log(`      stripped : ids identical too  (${r.idCount} flowNodeRefs)`);
      if (r.tie.groups > 0 && r.stableMint === null) {
        console.log(`      UNINTERPRETABLE — could not measure whether this build mints uids stably.`);
        broken++;
      } else if (r.tie.groups > 0 && r.stableMint) {
        console.log(`      *** REPAIR HOLDS — this map HAS a tie and still emitted stable ids, and`);
        console.log(`          this build mints uids STABLY (two parses of the uid-less bytes produce`);
        console.log(`          the same uid vector). That is T-364 repair (a) working, not a refuted`);
        console.log(`          mechanism: the tie is still there and no longer decides anything.`);
        repairHeld++;
      } else if (r.tie.groups > 0) {
        console.log(`      *** PREDICTION REFUTED — this map HAS a tie, this build mints uids`);
        console.log(`          NONDETERMINISTICALLY, and the ids still held still.`);
        console.log(`          The (x, uid) sort is not the whole story; find what else orders them`);
        console.log(`          before citing this mechanism anywhere.`);
        refuted++;
      } else {
        console.log(`      (no tie in this map, so stability here is the correct negative control)`);
        cleanNoTie++;
      }
    } else {
      console.log(`      stripped : ids PERMUTED across two parses of identical bytes`);
      for (const [p, q] of r.sample) console.log(`          parse 1: ${p}   parse 2: ${q}`);
      if (r.tie.groups === 0) {
        console.log(`      *** UNEXPLAINED — permuted with NO same-lane x tie detected. The hazard`);
        console.log(`          is wider than the tie mechanism; do not close this on the tie story.`);
        broken++;
      } else confirmed++;
    }
  }

  console.log();
  if (broken) { console.log(`  ${broken} row(s) uninterpretable — fix the harness before reading anything.`); return 2; }
  if (refuted) { console.log(`  ${refuted} row(s) refuted the mechanism. The reading of computeDisplayId is wrong.`); return 1; }
  // ---- verdict, post-repair semantics ----
  // This file began as a one-shot experiment whose exit 0 meant "the defect is present".
  // Repair (a) landed, so that reading is retired: a build that still permutes is now a
  // REGRESSION, and the exit code says exactly one thing — the repair is in place, or it
  // is not. The original demonstration (4 maps PERMUTED, 2 tie-free controls held still,
  // against the pre-repair build) is recorded in the T-364 task; it is not re-runnable
  // here because the mechanism needs a nondeterministic mint to bite and this build has
  // none.
  if (confirmed) {
    console.log(`  *** REGRESSION — ${confirmed} map(s) permuted their emitted element ids across two`);
    console.log('  parses of identical bytes. That is the T-364 defect back: some node is getting a');
    console.log('  uid that is not derived from its element id, and uid is the tie-breaker in');
    console.log('  computeDisplayId while displayIdOf IS the emitted id. A no-op open-and-save now');
    console.log('  rewrites flowNodeRef, id=, sourceRef/targetRef, attachedToRef and incoming/outgoing.');
    console.log('  Look first at the two mint fallbacks in parseBpmnXml (deriveUid, T-364 repair (a)).');
    return 1;
  }
  if (!repairHeld) {
    console.log('  NO TIED MAP EXERCISED ANYTHING — every picked map reported zero same-lane x ties,');
    console.log('  so this run cannot tell "the repair holds" from "the subject is gone". The TIED');
    console.log('  list was chosen from tools/_t364-x-tie-census.py; re-run the census and re-pick.');
    return 1;
  }
  console.log(`  REPAIR HOLDS on ${repairHeld} tied map(s) (${cleanNoTie} tie-free map(s) also held still).`);
  console.log('  Every tied map still HAS its tie and the ids no longer move: the tie stopped');
  console.log('  deciding anything because aef:uid now derives from the element id.');
  console.log();
  console.log('  Read the two numbers differently — the tie-free control has gone INERT.');
  console.log('  Before the repair it discriminated: it told "the tie causes the permutation" from');
  console.log('  "any uid strip causes it". Under a stable mint NOTHING permutes, so a tie-free map');
  console.log('  holding still is now guaranteed and confirms nothing. What carries this run is the');
  console.log('  per-build mint measurement (two parses of the uid-less bytes, same uid vector) —');
  console.log('  that is the quantity which flips if the defect returns, and the tie counts, which');
  console.log('  prove the hazard population still exists to be protected.');
  console.log();
  console.log('  Still true, and not addressed by this repair:');
  console.log('   1. Repair option (b) "mint the uid but do not persist it" would have produced');
  console.log('      exactly the permuting documents. 19 of 24 corpus maps hold a tie and were');
  console.log('      stable ONLY because aef:uid is in their bytes. That is why (b) was rejected.');
  console.log('   2. tools/_t358-byteid-thirdparty.mjs normalises aef:uid ONLY. Its soundness for');
  console.log('      today\'s third-party fixtures rests on the importer\'s fallback layout giving');
  console.log('      them strictly increasing x — NOT on ties being harmless. Adopting BPMN DI as');
  console.log('      geometry (T-357) removes that, and THEN this repair is what stands between a');
  console.log('      real colliding x and a permuted identity graph.');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
