#!/usr/bin/env node
// _t515-external-uid-conformance.mjs — does the editor honour uids it did not mint?
//
// `docs/standards/aef-bpmn-mapping-v1.md` §6 conformance requirement 3:
//   "It carries a stable, externally-assignable aef:uid on every node and edge (§5)."
// and §5, the clause AEF's reverse path is built on:
//   "aef:uid is externally assignable — the reference editor's import path honors arbitrary
//    aef:uid values, so a reverse renderer needs no editor change for identity."
//
// That is a claim about OUR editor, written into a co-designed standard, which licenses AEF
// to build a reverse renderer without asking us for anything. T-182 built
// tests/test_mapping_standard_conformance.py, but it guards §2 only — the frozen governance
// meta-key list. Requirement 3 had no machine check on either side.
//
// T-513 measured the ABSENT case (a uid gets minted, deterministically, from the element id).
// This measures the PRESENT-AND-NOT-OURS case, which is a different branch: absent takes the
// FNV-1a derivation path, present takes the honour-what-you-were-given path, and only the
// second is what §5 promises.
//
// Three properties, because they fail independently:
//   1. every externally-assigned uid survives a round-trip byte-identical, on nodes AND edges
//      (§6.3 says "every node and edge", and they are emitted by two different code paths);
//   2. a second round-trip is byte-identical to the first — §5 promises re-rendering is
//      byte-stable, and an editor that honours a uid once but perturbs the file on every save
//      breaks the reverse path just as surely as one that rewrites the uid;
//   3. the comparator is alive (negative control) and not merely allergic to change
//      (anti-overfit).
//
// Usage:  node tools/_t515-external-uid-conformance.mjs
// Exit 0 = conformant and the controls fired; 1 = a real failure or a dead control;
// 2 = misconfig or the fixture stopped being externally-shaped.
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
const CORPUS = process.env.T515_CORPUS || join(REPO, 'examples', 'aef-processes', 'rendered');
const SRC = 'src/aef-workflow-designer.html';
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// ── externalising the identity of a real map ─────────────────────────────────────────────
// Built from a live corpus document rather than authored, so the structure around the uids
// is one the editor actually round-trips today and the ONLY difference from a normal save is
// whose identity the file carries. Node uids become AEF task ids, edge uids become the
// "deterministic hash for edges" §5 allows — both obviously not editor-minted, which is the
// entire point: the question is whether the editor honours values it could NOT have produced.
const NODE_UID = i => `T-${4200 + i}`;
const EDGE_UID = i => `AEF-DEP-${String(1000 + i).padStart(4, '0')}`;

function externalise(src) {
  let n = 0, e = 0;
  const map = new Map();
  const out = src.replace(/<aef:uid value="([^"]+)"\s*\/>/g, (whole, val) => {
    // n_/e_ is the editor's own prefix convention — that is how node and edge uids are told
    // apart here. A uid in neither shape is left alone rather than guessed at.
    let next;
    if (val.startsWith('n_')) next = NODE_UID(n++);
    else if (val.startsWith('e_')) next = EDGE_UID(e++);
    else return whole;
    map.set(val, next);
    return `<aef:uid value="${next}"/>`;
  });
  return { xml: out, map, nodes: n, edges: e };
}

const READ_EXPR = t => `(function(){
  var AEF = 'http://anchorpoint.framework/aef/extensions';
  var d = new DOMParser().parseFromString(${JSON.stringify(t)}, 'application/xml');
  var uids = [];
  var u = d.getElementsByTagNameNS(AEF, 'uid');
  for (var i=0;i<u.length;i++){ var v = u[i].getAttribute('value'); if (v) uids.push(v); }
  return uids;
})()`;

const ROUNDTRIP = src => `(function(){ state = parseBpmnXml(${JSON.stringify(src)}); refreshDisplayIds(); return buildBpmnXml(state); })()`;

const sorted = a => a.slice().sort();
const sameSet = (a, b) => a.length === b.length && JSON.stringify(sorted(a)) === JSON.stringify(sorted(b));

async function main() {
  if (!existsSync(CORPUS)) { console.log(JSON.stringify({ ok: false, error: 'no corpus at ' + CORPUS })); process.exitCode = 2; return; }
  const files = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!files.length) { console.log(JSON.stringify({ ok: false, error: 'corpus empty — a conformance probe with no subject is not a pass' })); process.exitCode = 2; return; }
  const srcName = basename(files[0], '.bpmn');
  const FIX = externalise(readFileSync(join(CORPUS, files[0]), 'utf8'));

  // ── anti-vacuity ───────────────────────────────────────────────────────────────────────
  // If the fixture's uids are editor-shaped, a pass proves nothing: the editor would be
  // being tested against values it could have minted itself, which is the one case §5 does
  // NOT promise anything about.
  if (FIX.nodes === 0 || FIX.edges === 0) {
    console.log(JSON.stringify({ ok: false, error: `fixture carries ${FIX.nodes} node uids and ${FIX.edges} edge uids — §6.3 is about "every node AND edge", and a corpus map missing either cannot test it` }, null, 2));
    process.exitCode = 2; return;
  }
  if (/aef:uid value="[ne]_[0-9a-f]{8}"/.test(FIX.xml)) {
    console.log(JSON.stringify({ ok: false, error: 'fixture still contains editor-shaped uids after externalising — the replacement did not take, and the probe would be measuring the editor against its own minting' }, null, 2));
    process.exitCode = 2; return;
  }
  const EXPECTED = [...FIX.map.values()];

  const doc = mkdtempSync(join(tmpdir(), 't515-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't515-repo-'));
  copyFileSync(join(REPO, SRC), join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't515-udd-'));
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

    // ── property 1: are the uids honoured? ────────────────────────────────────────────────
    const export1 = await ev(cmd, ROUNDTRIP(FIX.xml));
    if (typeof export1 !== 'string') throw new Error('round-trip 1 produced no string');
    const OUT1 = await ev(cmd, READ_EXPR(export1));
    const missing = EXPECTED.filter(u => !OUT1.includes(u));
    const honoured = missing.length === 0;
    // Anything in the output that we did not put in is a uid the editor minted for itself —
    // reported separately, because "honoured all of ours" and "minted none of its own" are
    // different claims and §6.3 needs both.
    const unexpected = OUT1.filter(u => !EXPECTED.includes(u));

    // ── property 2: is re-rendering byte-stable? ──────────────────────────────────────────
    const export2 = await ev(cmd, ROUNDTRIP(export1));
    const idempotent = export1 === export2;

    // ── NEGATIVE CONTROL CUTS ON aef:uid ─────────────────────────────────────────────────
    // Alters the value of one externally-assigned uid in the output — the exact field the
    // comparator reads. PL-206: it is not enough that the control CAN fire; the stimulus has
    // to differ in the compared field, so the alteration is asserted to have changed the
    // parsed uid list and not merely some bytes elsewhere in the file.
    const victim = EXPECTED[0];
    const cut = export1.replace(`<aef:uid value="${victim}"/>`, `<aef:uid value="${victim}-MUTATED"/>`);
    const CUT = await ev(cmd, READ_EXPR(cut));
    const stimulusReallyDiffers = cut !== export1 && !CUT.includes(victim);
    const controlFired = stimulusReallyDiffers && EXPECTED.filter(u => !CUT.includes(u)).length > 0;

    // ── anti-overfit: a benign edit must not move the verdict ─────────────────────────────
    // Node POSITIONS are presentational — §6.4 says presentational-only edits are task-graph
    // no-ops — so nudging one must leave identity untouched.
    const nudged = FIX.xml.replace(/<aef:position x="([\d.]+)" y="([\d.]+)"\/>/, (w, x, y) => `<aef:position x="${(parseFloat(x) + 7).toFixed(1)}" y="${y}"/>`);
    if (nudged === FIX.xml) throw new Error('anti-overfit leg did not actually edit the fixture — no aef:position found to nudge');
    const exportN = await ev(cmd, ROUNDTRIP(nudged));
    const OUTN = await ev(cmd, READ_EXPR(exportN));
    const benignEditIsQuiet = sameSet(OUT1, OUTN);

    const ok = honoured && unexpected.length === 0 && idempotent && controlFired && benignEditIsQuiet;

    console.log(JSON.stringify({
      ok,
      question: 'mapping-standard §6.3 / §5 — does the editor honour aef:uid values it did not mint, on every node and edge?',
      answer: !controlFired ? 'INCONCLUSIVE — the negative control did not fire, so this run certifies nothing'
            : ok ? 'YES — every externally-assigned uid survives unchanged on nodes and edges, and re-rendering is byte-stable'
            : 'NO — see missing[] / unexpected[] / idempotent',
      source_map: srcName,
      externally_assigned: { nodes: FIX.nodes, edges: FIX.edges, total: EXPECTED.length,
        shape: 'nodes: T-42NN (AEF task ids). edges: AEF-DEP-NNNN (the "deterministic hash for edges" §5 allows). Neither is a shape this editor can mint.' },
      property_1_uids_honoured: { honoured, missing, unexpected },
      property_2_rerender_byte_stable: { idempotent, bytes_first: export1.length, bytes_second: export2.length },
      negative_control: {
        description: 'one externally-assigned uid altered in the saved document; the comparator MUST report it. Cut on aef:uid because that is the field compared (PL-205), and the stimulus is asserted to differ in that field rather than merely somewhere in the file (PL-206).',
        victim, stimulus_really_differs: stimulusReallyDiffers, fired: controlFired,
      },
      anti_overfit: { description: 'nudging one aef:position — a presentational-only edit per §6.4 — must leave the uid set unchanged', quiet: benignEditIsQuiet },
      does_not_cover: 'one corpus map. Does not cover subProcess-nested nodes, nor the REVERSE RENDERER, which is AEF-side and cannot be exercised from here — only the editor-side promise §5 makes on its behalf. THREE of the four gaps named here when this was written are now measured elsewhere. UID COLLISION -> tools/_t518-uid-collision.mjs: a derived uid colliding with an authored one is guarded, but TWO AUTHORED uids with the same value both survive a round-trip, on nodes and edges; §6.3 states no uniqueness requirement and the editor enforces none. NOT-XML-ATTRIBUTE-SAFE VALUES -> tools/_t520-uid-xml-safety.mjs: escaping is correct (& < > " and non-ASCII all survive byte-identical), but a uid containing a newline or tab is emitted RAW into the attribute and XML attribute-value normalisation turns it into a space for any conforming parser, so AEF reads a different uid than we wrote, silently. That one was nearly missed because reading the result back with the browser DOMParser — the same lenient parser that produced it — reported the value intact; verdicts there come from expat instead. SUBPROCESS-NESTED NODES -> tools/_t523-subprocess-nesting.mjs: nothing is lost and the scope is. A node authored inside a <bpmn:subProcess> comes back with its uid byte-identical, and so does the sequenceFlow joining two of them, but the node is HOISTED to <bpmn:process> level and the subProcess returns EMPTY. The record survives and silently changes parent, which is worse than losing it because losing it is at least countable — and it is why no count-based instrument here has ever gone red on it. The source comment in parseBpmnXml asserted the opposite (that the whole interior is dropped); that was a claim nobody re-checked and T-523 corrected it in place. ONE GAP REMAINS and it is not ours: the AEF-side reverse renderer. I can state exactly what is IN a document and have no way to know what AEF should produce from it, because correct there means the records they would have produced from a natively-authored workflow — a fact about their data model, not about the document. Proposed as a fixture-pair contract at rail 11911; their operator decides, and until then this gap stays open by agreement rather than by neglect.',
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
