#!/usr/bin/env node
/**
 * _t406-doc-comment-provenance-cdp.mjs — does a PEER's leading rationale survive import?
 *
 * readDocComment used to return null for any leading comment opening with
 * DI_TRAILER_PREFIX, on the reasoning that a hand-edit may have hoisted our own
 * boilerplate to the top. A peer authoring to our mapping standard whose rationale
 * opens with those eight words therefore lost their doc block silently — AEF's T-347
 * loss shape from a mechanism we built (their rail 491, our T-406).
 *
 * No content test can separate the two cases: the DI comment in AEF's
 * draft-inception fixture is BYTE-IDENTICAL to the false trailer we shipped for two
 * months. So the discriminator is producer identity (T-399's `exporter`).
 *
 * Both directions in one run, because either alone is satisfiable by a broken fix:
 *
 *   PEER    no `exporter` of ours + leading comment opening with the prefix
 *           -> docComment PRESERVED   (the repair)
 *   OURS    our `exporter` + the same comment hoisted to the top
 *           -> docComment SUPPRESSED  (the property the guard exists for; losing it
 *                                      is the defect that poisoned AEF's corpus)
 *
 * CONTROL   a plainly-authored leading comment in a peer document must come back
 *           verbatim. Without it, "preserved" is equally consistent with a probe that
 *           never invoked the parser at all.
 *
 * Usage: node tools/_t406-doc-comment-provenance-cdp.mjs
 * Exit 0 = all three hold. 1 = a direction failed. 2 = harness error.
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');

// The exact string AEF's fixture carries, which is also the exact false trailer we
// shipped in 11 releases. Read from their fixture rather than retyped, so the day the
// two stop being identical this probe stops silently testing a straw man.
const PEER_FIXTURE = join(REPO, 'tests', 'fixtures', 'third-party',
                          'aef-draft-inception-readiness-v2.bpmn');
const COLLIDING = 'BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates';
const PLAIN = 'Rationale authored by the peer, nothing to do with layout.';

// NOTE ON FIXTURE PROVENANCE: the four `doc()`-built documents below are SYNTHETIC —
// minimal definitions elements built here, not bytes AEF published. The two below THAT
// are the real thing: AEF authored them at their commit 4f9a42926 and posted the bytes
// on the rail (504/505) after OBS-108 closed the file channel. Landed and sha256-verified
// by tools/_t413-land-fixtures.py; see the README beside them.
const FIX_DIR = join(REPO, 'tests', 'fixtures', 'aef-inbound');
const FIX_CLEAN = join(FIX_DIR, 't406-clean-leading-boilerplate.bpmn');
const FIX_INCIDENTAL = join(FIX_DIR, 't406-incidental-leading-boilerplate.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

function doc({ exporter, comment }) {
  const exp = exporter ? ` exporter="${exporter}"` : '';
  return `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:aef="http://anchorpoint.framework/aef/extensions"
                  id="Definitions_t406"${exp}
                  targetNamespace="https://aef.anchorpoint.dev/workflows">
  <!-- ${comment} -->
  <bpmn:collaboration id="Collaboration_t406">
    <bpmn:participant id="Pool_t406" name="t406" processRef="Process_t406"/>
  </bpmn:collaboration>
  <bpmn:process id="Process_t406" isExecutable="true">
    <bpmn:extensionElements>
      <aef:workflowMeta id="t406" version="1" schemaVersion="2"/>
    </bpmn:extensionElements>
    <bpmn:startEvent id="s1" name="start"/>
  </bpmn:process>
</bpmn:definitions>
`;
}

// Which arm of readDocComment's `someoneElsesDocument` test this document lands on.
// OURS = our own export; FOREIGN = positively names a different producer; UNSTAMPED =
// names nobody, which is the default arm — and the one every real AEF document takes.
const OURS = 'aef-workflow-designer';
function branchOf(xml) {
  const m = /\bexporter\s*=\s*"([^"]*)"/.exec(xml);
  if (!m) return 'UNSTAMPED (default)';
  return m[1] === OURS ? 'OURS' : `FOREIGN "${m[1]}"`;
}

async function main() {
  // Precondition: the colliding string must really be what the peer fixture carries.
  // If they diverge, this probe would be testing a string nobody actually writes.
  if (!existsSync(PEER_FIXTURE)) { console.log('  FAIL — peer fixture missing'); return 2; }
  if (!readFileSync(PEER_FIXTURE, 'utf8').includes(COLLIDING)) {
    console.log('  FAIL precondition — the peer fixture no longer carries the colliding string;');
    console.log('        this probe would be measuring a straw man. Re-derive it from the fixture.');
    return 2;
  }
  console.log('  precondition ok — colliding string is present verbatim in the peer fixture');

  // T-413 precondition: the two AEF-authored fixtures must be present AND must actually
  // LEAD with the colliding string. A fixture that drifted off the shape would turn its
  // leg into a straw man that passes for the wrong reason.
  for (const f of [FIX_CLEAN, FIX_INCIDENTAL]) {
    if (!existsSync(f)) {
      console.log(`  FAIL — AEF fixture missing: ${f}`);
      console.log('        Land it: python3 tools/_t413-land-fixtures.py <rail-state.json> tests/fixtures/aef-inbound');
      return 2;
    }
    const first = /<!--([\s\S]*?)-->/.exec(readFileSync(f, 'utf8'));
    if (!first || !first[1].trim().startsWith(COLLIDING)) {
      console.log(`  FAIL precondition — ${f} no longer leads with the colliding string`);
      return 2;
    }
  }
  console.log('  precondition ok — both AEF fixtures present and leading with the colliding string');

  const CASES = [
    // Proves the parser ran at all. A probe that never invoked it reports "preserved"
    // for the same reason a working one does.
    ['CONTROL  peer, plain rationale     ', { exporter: null, comment: PLAIN }, 'preserve'],
    // THE REPAIR: a peer who stamps their own identity keeps their rationale even when
    // it opens with our eight words.
    ['STAMPED  peer, colliding comment   ', { exporter: 'camunda modeler', comment: COLLIDING }, 'preserve'],
    // THE PROPERTY THE GUARD EXISTS FOR (T-311): our own boilerplate hand-hoisted to the
    // top must not be promoted to rationale. This is the direction that poisoned AEF's
    // corpus, and a fix satisfying only the line above would have removed it.
    ['OURS     boilerplate hoisted to top', { exporter: 'aef-workflow-designer', comment: COLLIDING }, 'suppress'],
    // THE RESIDUAL, pinned rather than left implicit: an UNIDENTIFIED document whose
    // comment is NOTHING BUT the trailer is suppressed, and correctly — nothing is lost.
    ['UNKNOWN  no producer identity      ', { exporter: null, comment: COLLIDING }, 'suppress'],

    // ── T-413: AEF's own fixtures, their commit 4f9a42926, delivered as payload_b64 on
    // the rail at offsets 504/505 because OBS-108 shuts the file channel. These are the
    // first legs in this probe running REAL PEER BYTES rather than documents we
    // synthesized to be convenient for ourselves.
    //
    // Both are UNSTAMPED — measured on the received bytes, 0 `exporter=` on either, and
    // 0 across all 37 .bpmn of their live corpus (their rail 506 §2). So both take the
    // default branch, and the default branch is the one that decides every real AEF
    // document.
    //
    // The four legs above are NOT blind to that branch — CONTROL and UNKNOWN both run
    // through it. What they never cross it with is the SHAPE of the comment. Above, the
    // leading comment is either nothing but the trailer or has no trailer at all; the
    // mixed shape — trailer, then real rationale, one block — appears on no leg at any
    // branch. Producer identity was the axis I chose, and the case that actually loses
    // content is discriminated by shape, which is why AEF's narrowing beats my gate here.
    ['AEF-CLEAN    trailer only, real bytes ', { file: FIX_CLEAN }, 'suppress'],
    // The expectation here is what SHOULD happen, not what does. The comment is our
    // eight words followed by seven lines of genuine `aef-task-lifecycle` rationale in
    // the same block; suppressing it destroys content no one can recover. Pinning the
    // observed behaviour instead would encode the defect as the specification.
    ['AEF-INCIDENTAL rationale after trailer', { file: FIX_INCIDENTAL }, 'preserve'],

    // T-414: the junk-line decision, pinned on OUR OWN documents too. Identity is not a
    // licence to delete: if one of our exports has real rationale under a hoisted trailer,
    // dropping it destroys a user's content exactly as it destroyed AEF's. This leg is what
    // stops a future "we know it's ours, just suppress it" simplification, and it is the
    // one case where the recovered comment deliberately KEEPS a visible junk first line.
    ['OURS+RATIONALE trailer then content ',
     { exporter: 'aef-workflow-designer', comment: COLLIDING + '\n       ' + PLAIN }, 'preserve'],
  ];

  // T-414: for legs that must PRESERVE a specific text, non-emptiness is not enough — a
  // recovery that truncated to the trailer line alone would satisfy `kept` and lose
  // everything the fix exists to save. These legs assert the content is actually there.
  const MUST_CONTAIN = {
    'AEF-INCIDENTAL rationale after trailer': 'designer-corpus D1 (arc-014, T-2555)',
    'OURS+RATIONALE trailer then content ': PLAIN,
  };

  const d = mkdtempSync(join(tmpdir(), 't406-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't406-repo-'));
  // T406_SRC overrides the subject so the legs can be MUTATION-TESTED: run against a copy
  // with the fix reverted and confirm they go red. Legs that have never failed are not
  // known to be capable of failing. Defaults to live src, so a plain run is unaffected.
  copyFileSync(process.env.T406_SRC || join(REPO, 'src/aef-workflow-designer.html'),
               join(d, 'designer.html'));
  mkdirSync(join(d, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', d, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', x => pyErr += x.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't406-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, results = [];
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    for (const [label, spec, want] of CASES) {
      const xml = spec.file ? readFileSync(spec.file, 'utf8') : doc(spec);
      await ev(cmd, `window.__IN__ = ${JSON.stringify(xml)};`);
      const got = await ev(cmd, `(function(){
        var m = parseBpmnXml(window.__IN__);
        if(!m) return {parsed:false};
        return {parsed:true, doc: m.docComment == null ? null : String(m.docComment)};
      })()`);
      results.push([label, want, got, branchOf(xml)]);
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const x of [d, repo, udd]) { try { rmSync(x, { recursive: true, force: true }); } catch (_) {} }
  }

  let fail = 0;
  for (const [label, want, got, branch] of results) {
    if (!got || !got.parsed) { console.log(`  FAIL ${label} parse returned null`); fail = 1; continue; }
    const kept = got.doc != null && String(got.doc).trim().length > 0;
    const need = MUST_CONTAIN[label];
    const hasText = !need || (kept && String(got.doc).includes(need));
    const ok = want === 'preserve' ? (kept && hasText) : !kept;
    if (want === 'preserve' && kept && !hasText) {
      console.log(`  FAIL ${label} [branch: ${branch}] preserved, but the recovered comment`);
      console.log(`       does not contain ${JSON.stringify(need)} — a truncated recovery`);
      console.log(`       passes a non-emptiness check and still loses the content.`);
      fail = 1;
      continue;
    }
    // The BRANCH is printed next to every verdict on purpose. A bare
    // suppressed/preserved cannot distinguish the identity gate working from the
    // default branch happening to be permissive — right answer, wrong mechanism, which
    // is the expensive kind of green because it retires the question (AEF, rail 506 §2a).
    console.log(`  ${ok ? 'ok  ' : 'FAIL'} ${label} [branch: ${branch}] want=${want} got=${kept ? 'preserved' : 'suppressed'}`);
    if (!ok) fail = 1;
  }

  console.log();
  if (fail) { console.log('FAIL — see above'); return 1; }
  console.log('PASS — a peer rationale survives; our own hoisted boilerplate is still suppressed');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
