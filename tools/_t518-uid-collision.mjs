#!/usr/bin/env node
// _t518-uid-collision.mjs — what happens when two things want the same aef:uid?
//
// Closes the first of four gaps _t515 names in its own does_not_cover, and the one I told AEF
// at rail 11891 I would take first: "uid collision between an externally-assigned value and one
// the editor would mint".
//
// WHY AEF CARES. Mapping standard §6.3 invites them to assign aef:uid externally, and their
// reverse renderer keys records on uid. Two nodes sharing one uid means a record-keyed consumer
// silently folds them into one — no error on their side, no error on ours, and a document that
// looks perfectly conformant.
//
// READING THE SOURCE FIRST CHANGED THE TEST. The two collision directions are NOT symmetric:
//
//   D1  external value == one the editor would mint for a DIFFERENT node.
//       Guarded. designer.html:9909 pre-seeds `usedUids` with every aef:uid in the document
//       BEFORE any derivation runs, and deriveUid (9925) salts deterministically in document
//       order while the value is taken. So the derived node moves out of the way.
//
//   D2  two nodes carry the SAME external uid.
//       Unguarded by construction. The call site (10090) is
//           uidEl?.getAttribute('value') || deriveUid('n', displayId)
//       so an authored uid short-circuits: deriveUid is never entered, `usedUids` is never
//       consulted and never updated. Nothing in that path can notice a duplicate.
//
// Had this probe tested only D1 — the direction the phrase in _t515 literally names — it would
// have gone green and I would have reported "collisions are handled". That is PL-206 exactly:
// a control fed a stimulus built so it cannot fire. So it measures both, and edges as well as
// nodes, since edges run a separate call site (10274) with the same shape.
//
// THIS IS A CHARACTERISATION PROBE, NOT A VERDICT. Nobody has yet agreed what SHOULD happen on
// D2 — the standard is silent, which is the actual finding. So the observed behaviour is pinned
// and a CHANGE goes red. Pinning a measurement is honest; asserting a preference nobody ratified
// would be me legislating a co-designed standard from a test file.
//
// Usage:  node tools/_t518-uid-collision.mjs
// Exit 0 = measured, controls fired, behaviour matches the pin; 1 = behaviour changed or a
// control is dead; 2 = REFUSAL (no corpus, no browser, or the fixture could not be made to
// collide — an unmeasurable run must never read as green).
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = process.env.T518_CORPUS || join(REPO, 'examples', 'aef-processes', 'rendered');
const SRC = 'src/aef-workflow-designer.html';
const sleep = ms => new Promise(r => setTimeout(r, ms));

// The pinned observation. Set from the first measured run, not from expectation.
// D2_DUPLICATE_SURVIVES=true means: hand the editor two nodes with the same authored uid and it
// hands both back unchanged, still colliding. If this ever flips, something in the import path
// grew a uniqueness guard and AEF must be told, because their reverse path would then see a
// uid it never assigned.
const PIN = { d1_derived_node_moves_aside: true, d2_duplicate_survives: true };

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Returns [{uid, owner, ownerTag}] — the uid AND which element carries it. _t515 read the uid
// SET, which is enough for "were they honoured" but cannot answer "did two nodes end up with
// one identity", the whole question here. Climbs to the nearest ancestor carrying an id, which
// is the flow node or sequence flow the extensionElements hangs off.
const READ_PAIRS = t => `(function(){
  var AEF='http://anchorpoint.framework/aef/extensions';
  var d=new DOMParser().parseFromString(${JSON.stringify(t)},'application/xml');
  var u=d.getElementsByTagNameNS(AEF,'uid'); var out=[];
  for(var i=0;i<u.length;i++){
    var v=u[i].getAttribute('value'); var p=u[i].parentNode;
    while(p && p.nodeType===1 && !(p.getAttribute && p.getAttribute('id'))) p=p.parentNode;
    out.push({uid:v, owner:(p&&p.getAttribute)?p.getAttribute('id'):null, ownerTag:(p&&p.localName)||null});
  }
  return out;
})()`;

const ROUNDTRIP = src => `(function(){ state = parseBpmnXml(${JSON.stringify(src)}); refreshDisplayIds(); return buildBpmnXml(state); })()`;

const refuse = (msg, extra = {}) => { console.log(JSON.stringify({ ok: false, refusal: msg, ...extra }, null, 2)); process.exitCode = 2; };

async function main() {
  if (!existsSync(CORPUS)) return refuse('no corpus at ' + CORPUS);
  const files = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!files.length) return refuse('corpus empty — a collision probe with no subject is not a pass');
  const srcName = basename(files[0], '.bpmn');
  const ORIGINAL = readFileSync(join(CORPUS, files[0]), 'utf8');

  const doc = mkdtempSync(join(tmpdir(), 't518-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't518-repo-'));
  copyFileSync(join(REPO, SRC), join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't518-udd-'));
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

    // ── how this measurement is keyed, and why not by element id ─────────────────────────
    // The first version of this probe tracked each carrier across the round-trip by its owning
    // element's `id` and produced pure artifacts — one lookup returned null, another returned a
    // different element's uid. The reason is T-513's own finding, which I filed and then walked
    // straight into: the element `id` is a function of lane + x-order + node NAME, so it is
    // RE-MINTED on every save. Keying a before/after comparison on it is keying on something
    // the operation under test rewrites.
    //
    // So nothing here is keyed on identity that the round-trip controls. Every verdict is a
    // COUNT of a specific uid value in the output, or a set difference. A count needs no stable
    // handle on "which element was this", and the question — do two carriers end up sharing one
    // identity — is a question about counts anyway.
    const uidsOf = t => ev(cmd, READ_PAIRS(t)).then(ps => ps.map(p => p.uid).filter(Boolean));
    const countOf = (list, v) => list.filter(u => u === v).length;

    const baseUids = await uidsOf(ORIGINAL);
    const nodeUids = baseUids.filter(u => u.startsWith('n_'));
    const edgeUids = baseUids.filter(u => u.startsWith('e_'));
    if (nodeUids.length < 2) return refuse(`corpus map ${srcName} carries ${nodeUids.length} node uid(s) — a collision needs two carriers, so this cannot be tested here`, { candidates: baseUids.length });
    const Auid = nodeUids[0], Buid = nodeUids[1];

    // ── D1: what WOULD the editor mint for A? ────────────────────────────────────────────
    // Two-phase and unavoidably so: the colliding value is whatever the editor derives, and
    // reimplementing FNV-1a here would test this probe's copy rather than the editor's. The
    // minted value is recovered by SET DIFFERENCE — strip A's uid, round-trip, and the one uid
    // present that was not there before is what A was given.
    const stripA = ORIGINAL.replace(`<aef:uid value="${Auid}"/>`, '');
    if (stripA === ORIGINAL) return refuse(`could not strip A's uid (${Auid}) — the fixture is not the shape this probe assumes`);
    const afterStrip = await uidsOf(await ev(cmd, ROUNDTRIP(stripA)));
    const survivors = new Set(baseUids.filter(u => u !== Auid));
    const fresh = afterStrip.filter(u => !survivors.has(u));
    if (fresh.length !== 1) return refuse(`stripping A's uid produced ${fresh.length} new uid(s), expected exactly 1 — cannot identify what the editor minted`, { fresh, Auid });
    const mintedForA = fresh[0];

    // Hand that exact value to B as an authored uid, leaving A to derive it again.
    const d1 = stripA.replace(`<aef:uid value="${Buid}"/>`, `<aef:uid value="${mintedForA}"/>`);
    // STIMULUS CHECK (PL-206): the fixture must really stage the collision — B carrying the
    // minted value exactly once, and A carrying no uid at all. Otherwise whatever comes back
    // says nothing about collisions and green would be an artifact.
    if (countOf(d1.split('\n').join('\n').match(/<aef:uid value="[^"]*"\/>/g) || [], `<aef:uid value="${mintedForA}"/>`) !== 1
        || d1.includes(`<aef:uid value="${Auid}"/>`)) {
      return refuse('D1 fixture does not stage the collision', { mintedForA, Auid, Buid });
    }
    const d1Out = await uidsOf(await ev(cmd, ROUNDTRIP(d1)));
    const d1MintedCount = countOf(d1Out, mintedForA);
    // 1 => the derived node salted away and both carriers kept a distinct identity.
    // 2 => the collision survived: two elements share one uid.
    const d1MovedAside = d1MintedCount === 1;

    // ── D2: two carriers, one authored value ─────────────────────────────────────────────
    const DUP = 'AEF-DUP-0001';
    let d2 = ORIGINAL.replace(`<aef:uid value="${Auid}"/>`, `<aef:uid value="${DUP}"/>`);
    d2 = d2.replace(`<aef:uid value="${Buid}"/>`, `<aef:uid value="${DUP}"/>`);
    const dupStaged = (d2.match(new RegExp(`<aef:uid value="${DUP}"/>`, 'g')) || []).length;
    if (dupStaged !== 2) return refuse(`D2 fixture carries the duplicate ${dupStaged} time(s), not 2 — the collision was never staged`, { DUP });
    const d2Out = await uidsOf(await ev(cmd, ROUNDTRIP(d2)));
    const d2DupCount = countOf(d2Out, DUP);
    const d2Survives = d2DupCount === 2;
    const d2DistinctAfter = new Set(d2Out).size;
    // A carrier vanishing entirely is a different and worse outcome than a surviving duplicate,
    // so total carrier count is reported rather than inferred from the duplicate count alone.
    const d2CarriersBefore = baseUids.length, d2CarriersAfter = d2Out.length;

    // ── D2 for edges — a separate call site (10274) with the same shape ──────────────────
    let edgeResult = { tested: false, why: `corpus map carries ${edgeUids.length} edge uid(s); two are needed` };
    if (edgeUids.length >= 2) {
      const EDUP = 'AEF-DUP-EDGE-1';
      let de = ORIGINAL.replace(`<aef:uid value="${edgeUids[0]}"/>`, `<aef:uid value="${EDUP}"/>`);
      de = de.replace(`<aef:uid value="${edgeUids[1]}"/>`, `<aef:uid value="${EDUP}"/>`);
      if ((de.match(new RegExp(`<aef:uid value="${EDUP}"/>`, 'g')) || []).length === 2) {
        const deOut = await uidsOf(await ev(cmd, ROUNDTRIP(de)));
        edgeResult = { tested: true, duplicate_count_after: countOf(deOut, EDUP), duplicate_survives: countOf(deOut, EDUP) === 2 };
      }
    }

    // ── NEGATIVE CONTROL ─────────────────────────────────────────────────────────────────
    // "The two nodes still collide" and "the comparator cannot see uids at all" would print
    // identically. So alter one uid in a saved document and require the reader to notice, in
    // the exact field compared (PL-205 / PL-206).
    const clean = await ev(cmd, ROUNDTRIP(ORIGINAL));
    const cleanUids = await uidsOf(clean);
    const victim = cleanUids.find(u => u.startsWith('n_'));
    const mutated = clean.replace(`<aef:uid value="${victim}"/>`, `<aef:uid value="${victim}-MUTATED"/>`);
    const mutUids = await uidsOf(mutated);
    const stimulusReallyDiffers = mutated !== clean;
    const controlFired = stimulusReallyDiffers && !mutUids.includes(victim);

    const matchesPin = d1MovedAside === PIN.d1_derived_node_moves_aside && d2Survives === PIN.d2_duplicate_survives;
    const ok = controlFired && matchesPin;

    console.log(JSON.stringify({
      ok,
      question: 'aef:uid collision — what does the editor do when two carriers want one identity? (_t515 does_not_cover gap 1, AEF rail 11891)',
      answer: !controlFired
        ? 'INCONCLUSIVE — the negative control did not fire, so this run certifies nothing'
        : !matchesPin
          ? 'CHANGED — collision behaviour no longer matches the pinned observation; AEF must be told'
          : 'MEASURED — D1 (derived vs authored) is guarded; D2 (two authored, same value) is NOT, and the duplicate survives a full round-trip',
      source_map: srcName,
      d1_external_equals_what_editor_would_mint: {
        mechanism: 'designer.html:9909 pre-seeds usedUids with every authored aef:uid before derivation; deriveUid (9925) then salts deterministically while the value is taken',
        minted_for_A_when_alone: mintedForA,
        occurrences_of_that_value_after_collision: d1MintedCount,
        derived_node_moved_aside: d1MovedAside,
        verdict: d1MovedAside
          ? 'GUARDED — the authored value occurs exactly once afterwards, so the derived node salted away and both carriers kept a distinct identity'
          : 'UNGUARDED — the authored value occurs twice afterwards',
      },
      d2_two_authored_uids_with_the_same_value: {
        mechanism: 'call site 10090 is `uidEl?.getAttribute(value) || deriveUid(...)` — an authored uid short-circuits, so deriveUid is never entered, usedUids is never consulted and never updated. Nothing on that path can observe a duplicate.',
        value_used: DUP,
        occurrences_after_roundtrip: d2DupCount,
        duplicate_survives_roundtrip: d2Survives,
        distinct_uids_in_document_after: d2DistinctAfter,
        uid_carriers_before: d2CarriersBefore, uid_carriers_after: d2CarriersAfter,
        verdict: d2Survives
          ? 'UNGUARDED — two elements leave the editor sharing one identity, silently'
          : d2DupCount === 1 ? 'one carrier lost the value — check uid_carriers_after for whether an element was dropped'
          : 'neither carrier kept the value',
      },
      d2_edges: edgeResult,
      negative_control: {
        description: 'one uid altered in a saved document; the reader MUST stop finding the original. Cut on aef:uid because that is the compared field.',
        victim, stimulus_really_differs: stimulusReallyDiffers, fired: controlFired,
      },
      pinned_expectation: PIN,
      what_this_means_for_aef: d2Survives
        ? 'Mapping standard §6.3 invites external uid assignment but states no UNIQUENESS requirement, and the editor enforces none for authored values. A reverse renderer keying records on uid will silently fold two nodes into one. The constraint is real and currently lives nowhere — that is the finding, not the editor behaviour itself.'
        : 'the editor rejects or rewrites duplicate authored uids — see d2 block',
      does_not_cover: 'one corpus map, top-level nodes and edges only. Does not cover subProcess-nested elements, uid values that are not XML-attribute-safe, collisions introduced by INTERACTIVE authoring rather than by import, or the AEF-side reverse renderer, which cannot be exercised from here.',
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
