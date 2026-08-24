#!/usr/bin/env node
/**
 * _t358-byteid-thirdparty.mjs — byte-identity over the population `_t308` CANNOT
 * reach: third-party documents.
 *
 * Why this exists (G-023). `_t308` reports "24/24 identical, 0 drifted" and that is
 * true — of designer-produced corpus maps. Those are the documents that carry
 * `aef:uid`. Every third-party document does not, and the emitter mints a fresh uid
 * per parse (T-364), so third-party emissions are not byte-stable even against
 * themselves. A gate built on raw equality therefore cannot be run on them at all,
 * and its silence has been reading as coverage.
 *
 * The fix is not to widen the claim, it is to normalise the ONE field that is
 * legitimately nondeterministic and then demand exact equality of everything else:
 *
 *   - `aef:uid` values are replaced with u1, u2, ... in document order, before the
 *     bytes are compared or recorded — so the golden on disk is already normalised
 *     and the uid count is implicit in it: a run that normalised a different number
 *     of uids cannot match, without needing a separate count check.
 *   - the SUBSTITUTION IS COUNTED and reported. A normaliser that silently matched
 *     nothing would turn this into a raw comparison wearing a normalised label.
 *   - nothing else is touched.
 *
 * BASELINE: RECORDED BYTES, NOT A BUILD (T-581). This tool used to read a second copy
 * of the source out of git at a hand-picked ref — `3bf37909~1`, which nobody ratified;
 * it is simply where the file sat on 2026-08-04. Measured 2026-08-24 it reported
 * 0 identical / 11 drifted / PRECONDITION VIOLATED, while the same run against `HEAD`
 * reported 11 identical / PRECONDITION HOLDS. The whole red was the baseline's age.
 * Re-pinning by hand reproduces that on the same clock, so the baseline is now the
 * uid-normalised emission itself, one golden per fixture under tests/goldens/third-party/.
 *
 * Three consequences worth stating, because each removes a class rather than an instance:
 *
 *   - THE CROSS-BUILD UID HAZARD CANNOT EXIST. The old precondition refused whenever a
 *     same-lane x tie coexisted with uid values that differed between the two builds —
 *     unavoidable while the baseline predated T-364's uid repair. With one build there is
 *     no second uid vector to disagree with. What survives is the WITHIN-build determinism
 *     check, which is the one that can still be false, and it is a REFUSAL: if this build
 *     mints uids nondeterministically then no golden of it means anything.
 *
 *   - AN ACCEPTED CHANGE IS A REVIEWED DIFF. Re-recording is `--record` and nothing else.
 *     A gate that refreshes its own baseline whenever it passes ratchets forward silently
 *     and can never report drift that accumulated one green run at a time; the suite's call
 *     therefore does not pass --record, and that is asserted positively by the teeth.
 *
 *   - It builds the editor ONCE instead of twice.
 *
 * Usage: node tools/_t358-byteid-thirdparty.mjs [--record]
 * Exit 0 = every fixture matches its golden modulo uid. Exit 1 = a real difference, or a
 * golden is missing. Exit 2 = harness failure, a normaliser that did not fire, or a build
 * whose uid minting is not deterministic within itself.
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
// T-364: overridable so the precondition's hazard path can be exercised against a temp
// fixture set (tools/_t364-byteid-precondition-teeth.py) without touching the real one.
// A precondition that reports HOLDS and has never been shown able to report otherwise
// is a constant wearing a verdict.
const FIXDIR = process.env.T358_FIXDIR || join(REPO, 'tests', 'fixtures', 'third-party');
// T-581: the baseline. Overridable for the teeth, which need to mutate a golden without
// touching the real corpus — the same reason T358_FIXDIR exists.
const GOLDEN_DIR = process.env.T358_GOLDENDIR || join(REPO, 'tests', 'goldens', 'third-party');
// Writing goldens is an explicit act. Default is compare-and-refuse; there is deliberately
// no env var for this, because an env var is exactly how a suite acquires it by accident.
const RECORD = process.argv.includes('--record');

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

/** Replace aef:uid values with u1,u2,... in document order. Returns [text, count]. */
function normaliseUids(xml) {
  let n = 0;
  const out = xml.replace(/(<aef:uid\s+value=")([^"]*)(")/g, (_m, a, _v, c) => `${a}u${++n}${c}`);
  return [out, n];
}

async function main() {
  const currentSrc = readFileSync(join(REPO, 'src/aef-workflow-designer.html'), 'utf8');
  const fixtures = readdirSync(FIXDIR).filter(f => f.endsWith('.bpmn')).sort();
  if (!fixtures.length) { console.error('ERROR: no third-party fixtures'); return 2; }
  if (RECORD) mkdirSync(GOLDEN_DIR, { recursive: true });
  else if (!existsSync(GOLDEN_DIR)) {
    console.error(`ERROR: no golden corpus at ${GOLDEN_DIR}. Record it deliberately:`);
    console.error('       node tools/_t358-byteid-thirdparty.mjs --record');
    return 1;
  }

  const doc = mkdtempSync(join(tmpdir(), 't358-bid-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't358-bid-repo-'));
  writeFileSync(join(doc, 'current.html'), currentSrc);
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't358-bid-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl; const emitted = {};
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');

    {
      await cmd('Page.navigate', { url: `${BASE}/current.html` });
      await waitReady(cmd); await sleep(250);
      for (const f of fixtures) {
        await ev(cmd, `window.__IN__ = ${JSON.stringify(readFileSync(join(FIXDIR, f), 'utf8'))};`);
        emitted[f] = await ev(cmd, `(function(){
          var prev = state; var m = parseBpmnXml(window.__IN__);
          if (!m) { return null; }
          // T-364 PRECONDITION, part 1: is this build's uid minting stable WITHIN itself?
          // Measured, not assumed — parse the same bytes again and compare the uid vector.
          // Before the T-364 repair the second vector differed (random mint); after it,
          // uids derive from the element id and the vectors match.
          var uidSig = function (mm) {
            return mm.nodes.map(function (n) { return n.uid; }).join(',') + '|' +
                   mm.edges.map(function (e) { return e.uid; }).join(',');
          };
          var sig1 = uidSig(m);
          var m2 = parseBpmnXml(window.__IN__);
          var uidNondet = !m2 || uidSig(m2) !== sig1;
          state = m; var x = buildBpmnXml(state);
          // T-364 PRECONDITION. This tool normalises aef:uid and nothing else, which is
          // sound only while a uid can't influence any OTHER emitted byte. It can:
          // computeDisplayId breaks a same-lane x tie with uid.localeCompare, and
          // displayIdOf IS the emitted element id. Measure the tie on state.nodes — the
          // array the sort actually consumes — and carry it out with the bytes.
          var buckets = {};
          for (var i=0;i<state.nodes.length;i++){
            var n = state.nodes[i];
            var k = String(n.lane) + '@' + String(n.x);
            buckets[k] = (buckets[k] || 0) + 1;
          }
          var tieGroups = 0, tieNodes = 0;
          for (var k in buckets) if (buckets[k] > 1) { tieGroups++; tieNodes += buckets[k]; }
          var nodeCount = state.nodes.length;
          state = prev;
          // uids present in the SOURCE, not post-parse: after parse every node has one.
          var srcUids = (window.__IN__.match(/<aef:uid\\b/g) || []).length;
          return { xml: x, tieGroups: tieGroups, tieNodes: tieNodes,
                   nodeCount: nodeCount, srcUids: srcUids,
                   uidNondet: uidNondet, uidSig: sig1 };
        })()`);
      }
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  console.log(`\nByte-identity over THIRD-PARTY documents — current build vs recorded goldens`);
  console.log(`(${GOLDEN_DIR})`);
  console.log('(uid values normalised in document order; nothing else touched)\n');
  let identical = 0, drifted = 0, unusable = 0, normaliserSilent = 0, recorded = 0, missing = 0;
  const nondet = [], ties = [];
  for (const f of fixtures) {
    const rb = emitted[f];
    if (rb == null) { console.log(`  ${f.padEnd(36)} UNUSABLE (parse returned null)`); unusable++; continue; }
    // PRECONDITION, T-581. What the cross-build form used to test cannot arise here.
    //
    // The old predicate was "THE UID THAT BREAKS THIS TIE IS NOT THE SAME VALUE ON BOTH
    // SIDES OF THE COMPARISON" — sound, and unfalsifiable-in-practice, because one side
    // was a build read out of git at a fixed ref. Once that ref predated T-364's uid
    // repair the term was permanently true and the tool permanently refused. Deleting a
    // second build deletes the term: there is no other uid vector to disagree with.
    //
    // WHAT SURVIVES IS THE HALF THAT CAN STILL BE FALSE. If THIS build mints uids
    // nondeterministically, then the golden recorded from it was one draw of a die and
    // every future run compares against a coin flip. That is a refusal (rc 2), not a
    // drift: the corpus is not wrong, the instrument is.
    if (rb.uidNondet) nondet.push(f);
    // Ties are reported, not refused. A same-lane x tie among uid-less nodes means uid
    // ORDER reaches the emitted element id, so a future change to uid derivation permutes
    // ids here. Against a recorded golden that surfaces as a loud DRIFTED needing review —
    // the failure direction is red, not a flattering identical, which is the whole reason
    // the cross-build form had to refuse and this one does not.
    if (rb.tieGroups > 0 && rb.srcUids < rb.nodeCount) {
      ties.push({ f, groups: rb.tieGroups, nodes: rb.tieNodes, srcUids: rb.srcUids, nodeCount: rb.nodeCount });
    }

    const [nb, cb] = normaliseUids(rb.xml);
    if (cb === 0) normaliserSilent++;
    const gpath = join(GOLDEN_DIR, f + '.golden');
    if (RECORD) { writeFileSync(gpath, nb); recorded++; console.log(`  ${f.padEnd(36)} recorded    (${nb.length} bytes, ${cb} uid(s) normalised)`); continue; }
    if (!existsSync(gpath)) { console.log(`  ${f.padEnd(36)} NO GOLDEN — nothing to compare against`); missing++; continue; }
    const na = readFileSync(gpath, 'utf8');
    if (na === nb) { console.log(`  ${f.padEnd(36)} identical  (${nb.length} bytes, ${cb} uid(s) normalised)`); identical++; continue; }
    drifted++;
    const la = na.split('\n'), lb = nb.split('\n');
    let i = 0; while (i < la.length && i < lb.length && la[i] === lb[i]) i++;
    console.log(`  ${f.padEnd(36)} DRIFTED — first diff line ${i + 1}`);
    console.log(`      golden : ${(la[i] === undefined ? '<end of golden>' : la[i].trim().slice(0, 130))}`);
    console.log(`      current: ${(lb[i] === undefined ? '<end of current>' : lb[i].trim().slice(0, 130))}`);
  }

  if (RECORD) {
    console.log(`\n  ${recorded} golden(s) written to ${GOLDEN_DIR}, over ${fixtures.length} third-party fixture(s)`);
    console.log('  These bytes are now the baseline. Read the diff before committing them —');
    console.log('  that review is the only thing standing between an accepted change and a');
    console.log('  silently ratified regression.');
  } else {
    console.log(`\n  ${identical} identical, ${drifted} drifted, ${missing} without a golden, ${unusable} unusable, over ${fixtures.length} third-party fixture(s)`);
  }
  // A normaliser that never fires turns this into the raw comparison it replaced.
  if (normaliserSilent === fixtures.length) {
    console.log('\n  ERROR: the uid normaliser matched NOTHING on any fixture. This run is a raw');
    console.log('  byte comparison wearing a normalised label — it proves nothing about T-364.');
    return 2;
  }
  // REFUSAL, not a drift: a golden of a nondeterministic build is one draw of a die.
  if (nondet.length) {
    console.log('\n  *** REFUSING — this build does not mint uids deterministically.');
    for (const f of nondet) console.log(`      ${f}: parsing the same bytes twice gave two different uid vectors.`);
    console.log('      Every golden recorded from this build is one sample of a random variable,');
    console.log('      so neither a match nor a mismatch below carries information. Fix the mint');
    console.log('      (T-364) before recording or citing anything here.');
    return 2;
  }
  // The tie measurement is printed whichever way it goes: a silent precondition is one
  // nobody re-checks when the world changes, and T-357 (adopting BPMN DI as geometry) is a
  // scheduled change that would populate this list.
  if (ties.length) {
    console.log('\n  NOTE — uid ORDER reaches the emitted element id on these fixtures:');
    for (const h of ties) {
      console.log(`      ${h.f}: ${h.groups} same-lane x tie group(s), ${h.nodes} node(s); source carries ${h.srcUids} uid(s) for ${h.nodeCount} node(s).`);
    }
    console.log('      uid is the tie-breaker in computeDisplayId and displayIdOf IS the emitted id,');
    console.log('      so a future change to uid derivation permutes flowNodeRef / id= / sourceRef /');
    console.log('      targetRef here. Against a recorded golden that shows up as DRIFTED and gets');
    console.log('      read; it cannot show up as a flattering identical. Not a refusal.');
  } else {
    console.log('\n  No fixture has a same-lane x tie among uid-less nodes, so uid values cannot');
    console.log('  reach any other emitted byte. Note this is a property of these fixtures — none');
    console.log('  carries aef:position, so the importer lays them out strictly increasing per lane');
    console.log('  and a tie is unreachable. Adopting BPMN DI as geometry (T-357) removes that.');
  }
  if (RECORD) return 0;
  if (missing) {
    console.log(`\n  FAIL — ${missing} fixture(s) have no golden. Record them deliberately and commit`);
    console.log('  the bytes:  node tools/_t358-byteid-thirdparty.mjs --record');
    return 1;
  }
  if (drifted || unusable) return 1;
  console.log('\n  PASS — the population _t308 cannot reach matches its recorded bytes.');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
