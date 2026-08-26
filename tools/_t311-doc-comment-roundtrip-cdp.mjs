#!/usr/bin/env node
// _t311-doc-comment-roundtrip-cdp.mjs — drive the real editor against a map carrying
// an authored doc block (the leading comment child of <bpmn:definitions>, which AEF's
// corpus_spec treats as SEMANTIC) and prove the T-311 contract:
//
//   1. the doc block is CAPTURED at import (it used to be dropped — there was no
//      COMMENT_NODE handling anywhere in the file)
//   2. it is re-emitted VERBATIM and LEADING, ahead of <bpmn:collaboration>, which is
//      the position AEF's reader keys on
//   3. the round-trip is idempotent — export, re-import, still byte-identical
//   4. a map with no doc block gains none, and our own DI trailer is never promoted
//      to rationale (the exact defect that poisoned 5 of AEF's 11 maps, 2 promoted)
//   5. even a HOISTED trailer — boilerplate hand-moved to leading position — is
//      refused, so the guard is not merely positional
//   6. the doc survives undo, whose snapshots serialise through buildBpmnXml and
//      restore through parseBpmnXml; a drop there would be silent
//   7. a doc that would produce invalid XML (`--`, trailing `-`) still exports to a
//      parseable document rather than corrupting it
//
// Why a real browser rather than a unit test: parse, export and the history path are
// three separate sites in the assembled editor, and the defect was that none of them
// knew about comments. Same harness shape as T-308/T-310.
//
// Usage:  node tools/_t311-doc-comment-roundtrip-cdp.mjs [path/to/designer.html]
// Exit 0 = contract holds; 1 = violated (offending assertions named); 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXTURE = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 'doc-comment.bpmn');
// argv[2] optionally points at a different designer build — used to prove the harness
// has teeth by running it against the pre-fix source (PL-061: a check that cannot go
// red is not evidence).
const SRC = process.argv[2] || join(REPO, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&typeof buildBpmnXml==='function'&&typeof parseBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Pull the leading comment out of a document the same way a reader would: immediately
// after the <bpmn:definitions ...> open tag, with nothing but whitespace in between.
// Anchored with ^\s* rather than bounded by "the next <bpmn: element", because a doc
// block legitimately QUOTES element names — this fixture's own text mentions
// <bpmn:definitions>, which a lazy bound stops inside of.
function leadingComment(xml) {
  const open = /<bpmn:definitions[^>]*>/.exec(xml);
  if (!open) return null;
  const m = /^\s*<!--([\s\S]*?)-->/.exec(xml.slice(open.index + open[0].length));
  return m ? m[1] : null;
}

// Everything the assertions need, read out of the LIVE editor in one shot.
// Tolerant reads throughout: on a build predating T-311 `docComment` simply does not
// exist, and reporting null rather than throwing makes the teeth-test fail on the REAL
// assertions (doc absent from state, absent from the export) instead of dying on a
// ReferenceError, which would prove nothing.
const PROBE = `(function(){
  var out = {};
  adoptImportedXml(window.__FIX__, { userImport: true });
  out.captured = (state && typeof state.docComment !== 'undefined') ? state.docComment : null;
  out.exported = buildBpmnXml(state);

  // --- undo must not eat the doc: history serialises through buildBpmnXml and
  // restores through parseBpmnXml, so a gap at either end drops it silently.
  var before = snapshotState();
  var n = state.nodes[0];
  n.x = n.x + 40;                       // a real geometry edit
  commitHistory(before);
  undo();
  out.afterUndo = (state && typeof state.docComment !== 'undefined') ? state.docComment : null;

  // --- a map with NO doc block must gain none, and our own trailer must never be
  // promoted to rationale on a re-import of our own output.
  adoptImportedXml(window.__NODOC__, { userImport: true });
  out.noDocCaptured = (state && typeof state.docComment !== 'undefined') ? state.docComment : null;
  out.noDocExport = buildBpmnXml(state);

  // --- a HOISTED trailer (boilerplate hand-moved to leading position) must still be
  // refused: position alone would accept it.
  adoptImportedXml(window.__HOISTED__, { userImport: true });
  out.hoistedCaptured = (state && typeof state.docComment !== 'undefined') ? state.docComment : null;

  // --- a programmatically-set doc containing sequences XML forbids inside a comment
  // must still export to something parseable.
  adoptImportedXml(window.__FIX__, { userImport: true });
  try {
    state.docComment = ' danger -- double hyphen and a trailing dash -';
    var nasty = buildBpmnXml(state);
    out.nastyExport = nasty;
    var pd = new DOMParser().parseFromString(nasty, 'application/xml');
    out.nastyParses = pd.getElementsByTagName('parsererror').length === 0;
  } catch (e) { out.nastyParses = false; out.nastyError = String(e); }
  return out;
})()`;

async function main() {
  if (!existsSync(FIXTURE)) { console.log(JSON.stringify({ ok: false, error: 'fixture missing: ' + FIXTURE })); process.exitCode = 2; return; }
  const fixture = readFileSync(FIXTURE, 'utf8');
  const origComment = leadingComment(fixture);
  if (origComment == null) { console.log(JSON.stringify({ ok: false, error: 'fixture carries no leading comment — it cannot test anything' })); process.exitCode = 2; return; }

  // Same map with the doc block surgically removed, and a variant where our own DI
  // trailer has been hoisted into the leading slot.
  const noDoc = fixture.replace(/\n\s*<!--[\s\S]*?-->\n/, '\n');
  const hoisted = fixture.replace(/<!--[\s\S]*?-->/,
    '<!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->');

  const doc = mkdtempSync(join(tmpdir(), 't311-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't311-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't311-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const errs = [];
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(200);
    await ev(cmd, `window.__FIX__ = ${JSON.stringify(fixture)}; window.__NODOC__ = ${JSON.stringify(noDoc)}; window.__HOISTED__ = ${JSON.stringify(hoisted)};`);
    const r = await ev(cmd, PROBE);

    // 1. captured at import, verbatim
    if (r.captured == null) errs.push('doc comment not captured at import (state.docComment is null/absent)');
    else if (r.captured !== origComment) errs.push(`captured doc differs from source (len ${r.captured.length} vs ${origComment.length})`);

    // 2. re-emitted, and LEADING — ahead of the collaboration element
    const exportedComment = leadingComment(r.exported);
    if (exportedComment == null) errs.push('export carries no leading doc comment');
    else if (exportedComment !== origComment) errs.push('exported doc comment is not byte-identical to the source');
    const iCom = r.exported.indexOf('<!--');
    const iCol = r.exported.indexOf('<bpmn:collaboration');
    if (iCom === -1 || iCol === -1 || iCom > iCol) errs.push('doc comment does not lead the document (must precede <bpmn:collaboration>)');

    // 3. idempotent round-trip
    await ev(cmd, `window.__RT__ = ${JSON.stringify(r.exported)};`);
    // `replace: true` so the re-import overwrites the same library entry. Without it
    // adoptImportedXml's collision path renames the map to <id>_v2, and every id in
    // the document shifts with it — a harness artefact that has nothing to do with
    // the doc block being tested.
    const rt = await ev(cmd, `(function(){ adoptImportedXml(window.__RT__, { userImport: true, replace: true }); return { d: (state && typeof state.docComment !== 'undefined') ? state.docComment : null, x: buildBpmnXml(state) }; })()`);
    if (rt.d !== origComment) errs.push('re-import of the export lost or altered the doc comment');
    if (rt.x !== r.exported) {
      let i = 0; while (i < rt.x.length && i < r.exported.length && rt.x[i] === r.exported[i]) i++;
      errs.push(`second export differs from the first at offset ${i}: ${JSON.stringify(r.exported.slice(i, i + 70))} -> ${JSON.stringify(rt.x.slice(i, i + 70))}`);
    }

    // 4. no doc in, no doc out; and our trailer is never adopted
    if (r.noDocCaptured != null) errs.push(`map without a doc block captured one: ${JSON.stringify(String(r.noDocCaptured).slice(0, 60))}`);
    if (leadingComment(r.noDocExport) != null) errs.push('map without a doc block gained a leading comment on export');
    if (/BPMN DI \(visual layout\) omitted/.test(String(r.noDocCaptured || ''))) errs.push('our DI trailer was adopted as the rationale');

    // 5. a hoisted trailer is refused even though it IS in leading position
    if (r.hoistedCaptured != null) errs.push('hoisted DI trailer was accepted as a doc block — prefix guard not holding');

    // 6. undo does not eat it
    if (r.afterUndo !== origComment) errs.push('doc comment did not survive an edit -> undo cycle');

    // 7. an unemittable doc still yields a parseable document
    if (r.nastyParses !== true) errs.push(`doc containing "--" / trailing "-" produced an unparseable document (${r.nastyError || 'parsererror'})`);

    const ok = errs.length === 0;
    console.log(JSON.stringify({
      ok,
      capturedLen: r.captured == null ? null : r.captured.length,
      sourceLen: origComment.length,
      verbatim: r.captured === origComment,
      leadsDocument: iCom !== -1 && iCol !== -1 && iCom < iCol,
      roundTripStable: rt.x === r.exported,
      survivesUndo: r.afterUndo === origComment,
      noDocStaysEmpty: r.noDocCaptured == null,
      hoistedTrailerRefused: r.hoistedCaptured == null,
      nastyParses: r.nastyParses,
      errs,
    }, null, 2));
    process.exitCode = ok ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e), errs }, null, 2));
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
