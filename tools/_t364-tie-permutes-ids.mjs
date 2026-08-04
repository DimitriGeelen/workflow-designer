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
 * DO NOT WIRE THIS INTO P-011 VERIFICATION OR THE BRIDGE SUITE AS-IS.
 * It exits 0 when the DEFECT IS PRESENT. After repair (a) — derive the uid from the
 * element id — a stripped document would mint stable uids, the tied rows would stop
 * permuting, and this probe would report PREDICTION REFUTED and exit 1. That is a
 * gate which goes red exactly when the fix works, and someone would "fix" the probe.
 * It is an EXPERIMENT with a recorded result, not a regression gate. The gate that
 * survives the repair is _t358-export-determinism.mjs (stable = good, in both eras).
 *
 * Usage: node tools/_t364-tie-permutes-ids.mjs
 * Exit 0 = control stable AND the experiment behaved as the tie count predicts.
 * Exit 1 = a prediction failed (either direction — a stable strip is as interesting).
 * Exit 2 = harness broken.
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
  writeFileSync(join(doc, 'designer.html'), readFileSync(join(REPO, 'src/aef-workflow-designer.html'), 'utf8'));
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

      const ctl = await emitTwice(src);
      if (ctl.fatal) { rows.push({ name, tie, fatal: 'control: ' + ctl.fatal }); continue; }
      const exp = await emitTwice(stripped);
      if (exp.fatal) { rows.push({ name, tie, fatal: 'stripped: ' + exp.fatal }); continue; }

      const ctlIds = [flowIds(ctl.a), flowIds(ctl.b)];
      const expIds = [flowIds(exp.a), flowIds(exp.b)];
      rows.push({
        name, tie, removed,
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
  let broken = 0, confirmed = 0, refuted = 0, cleanNoTie = 0;
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
      if (r.tie.groups > 0) {
        console.log(`      *** PREDICTION REFUTED — this map HAS a tie and still emitted stable ids.`);
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
  if (!confirmed) { console.log('  No map exercised the mechanism — this run proves nothing. Pick maps with ties.'); return 1; }
  if (!cleanNoTie) {
    console.log('  NO TIE-FREE CONTROL HELD STILL. Every row permuted, so this run cannot tell');
    console.log('  "the tie causes it" from "any uid strip causes it" — it confirms without');
    console.log('  discriminating. Add a map the census reports as tie-free and re-run.');
    return 1;
  }
  console.log(`  CONFIRMED on ${confirmed} map(s); ${cleanNoTie} tie-free map(s) held still as a negative control.`);
  console.log('  The control is what makes this causal rather than correlational: strip the same');
  console.log('  aef:uid from a map with no same-lane x tie and the emitted ids do not move.');
  console.log();
  console.log('  A same-lane x tie plus a missing aef:uid permutes the EMITTED identity graph —');
  console.log('  flowNodeRef, and with it id=, sourceRef/targetRef, attachedToRef, incoming/outgoing.');
  console.log('  Consequences, stated where they bite:');
  console.log('   1. Repair option (b) "mint the uid but do not persist it" would produce exactly');
  console.log('      these documents. 19 of 24 corpus maps hold a tie and are stable ONLY because');
  console.log('      aef:uid is in their bytes. (b) does not fail to fix churn — it CREATES it.');
  console.log('   2. Any diff, review, merge or downstream consumer keyed on element id sees a');
  console.log('      whole-document change from a no-op open-and-save.');
  console.log('   3. tools/_t358-byteid-thirdparty.mjs normalises aef:uid ONLY. It is sound for');
  console.log('      today\'s third-party fixtures because the importer\'s fallback layout gives');
  console.log('      them strictly increasing x (a tie is unreachable) — NOT because ties are');
  console.log('      harmless. Adopt BPMN DI as geometry (T-357) and that protection is gone.');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
