#!/usr/bin/env node
/**
 * _t563-fallback-id-derivation-cdp.mjs — what workflow id does the REAL designer derive
 * for a document that carries no <aef:workflowMeta>, and can that id still be a display
 * name?
 *
 * THE DEFECT (T-501 §Decision item 1). The import chain was
 *   aefMetaEl?.getAttribute('id') || procName || 'imported'
 * and `procName` is `proc.getAttribute('name')` falling back to procId minus a `Pool_`
 * prefix — a human-readable LABEL standing in for machine identity. Every document with
 * no <aef:workflowMeta> reaches it. That is 14 of the 58 corpus documents: 10 in
 * tests/fixtures/third-party, 4 in tests/fixtures/lane-provenance.
 *
 * WHY A BROWSER. `parseBpmnXml` only exists in the page, and the whole question is what
 * the SHIPPED import produces — not what a re-implementation of the chain would produce.
 * The week's lesson (T-565, T-578) is that a property asserted about a file is not the
 * same property asserted about the thing that runs.
 *
 * THE LEG THAT KEEPS THIS HONEST IS 5, NOT 2. "All 14 ids are valid" is also what a
 * corpus that never reaches the fallback reports, and it is what a chain that returned
 * the constant 'imported' fourteen times would report. Leg 5 reproduces the OLD chain
 * in-page and requires it to be INVALID where the new one is valid, so the corpus is
 * shown to exercise the change rather than assumed to. Leg 3 pins the other edge:
 * `deriveSlug` — a summariser, first word longer than one character truncated to 16 —
 * collapses these same 14 documents onto 4 ids that ALL pass the validator. A loud
 * save-time rejection turned into a silent cross-document collision. Leg 2 alone would
 * wave that through; leg 3 is what makes the substitution impossible to land quietly.
 *
 * Leg 4 guards the opposite mistake. The authored id is deliberately NOT sanitized: it
 * is already machine identity, it already round-trips, and passing it through the
 * sanitizer would move bytes on the 44 documents that carry it — the exact surface
 * _t308 and _t358 watch. Leg 4 goes red on an over-eager sanitize.
 *
 * Usage: node tools/_t563-fallback-id-derivation-cdp.mjs [--src <designer.html>]
 *   --src points the probe at a mutated copy (teeth). Default is the tree's source.
 * Exit 0 = all legs pass. Exit 2 = the probe could not establish its own preconditions
 *   (no corpus, no fallback documents) — a REFUSAL, never a pass.
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');

const srcFlag = process.argv.indexOf('--src');
const SRC = srcFlag > -1 && process.argv[srcFlag + 1]
  ? process.argv[srcFlag + 1]
  : join(REPO, 'src/aef-workflow-designer.html');

// The whole corpus, not only the fallback population — leg 4 needs the documents that
// DO carry the element, and the split is measured here rather than hard-coded so the
// probe reports the truth if the corpus moves.
const CORPUS_DIRS = [
  join(REPO, 'examples', 'aef-processes', 'rendered'),
  join(REPO, 'tests', 'fixtures', 'aef-bpmn'),
  join(REPO, 'tests', 'fixtures', 'third-party'),
  join(REPO, 'tests', 'fixtures', 'lane-provenance'),
];

// Floor on DISTINCT ids across the fallback population. MEASURED, not aspirational: 10
// over 14 documents, and it is 10 both before and after T-563 — because five
// third-party fixtures each declare `<bpmn:process id="Process_1">` and therefore share
// an identifier at the source. The chain loses nothing; the documents collide.
//
// I wrote 14 here first, on the assumption that fourteen documents yield fourteen ids.
// The measurement said 10 and the reason was in the corpus, not in the code.
//
// This is a floor, not an equality, and it exists to catch COLLAPSE: `deriveSlug` in
// the same slot scores 7 over this set and every one of those 7 passes the validator,
// so leg 2 would wave the substitution through and only this number catches it.
// Raising the floor when the corpus grows is correct. Lowering it to make a run green
// is precisely what it exists to prevent.
//
// Note for whoever reads sanitizeWorkflowId's docstring at src/…:1670 — it states
// deriveSlug yields "4 ids (`process` ×8, `proc` ×4, `id`, a hash)". Re-measured here
// through the real page: 7 distinct, `process` ×6, no `proc` bucket at all, because
// deriveSlug is applied to procNAME and the lane-provenance documents carry real names
// ("Authored lanes" -> `authored`). Same direction, different number. Corrected in
// that docstring under this task.
const DISTINCT_FLOOR = 10;

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const legs = [];
function leg(name, pass, detail) { legs.push({ name, pass: !!pass, detail }); }

// Evaluated once in the page; every per-document measurement calls it. Reproducing the
// OLD chain and the deriveSlug SUBSTITUTION in here — rather than in node — matters:
// they have to run against the same DOM the shipped chain reads, or the comparison is
// between two different parsers rather than between two rules.
const PROBE_FN = `
window.__t563 = function (xml) {
  var BPMN_NS = 'http://www.omg.org/spec/BPMN/20100524/MODEL';
  var AEF_NS  = 'http://anchorpoint.framework/aef/extensions';
  var d = new DOMParser().parseFromString(xml, 'application/xml');
  var procs = d.getElementsByTagNameNS(BPMN_NS, 'process');
  if (!procs.length) return { ok: false, err: 'no bpmn:process' };
  var p = procs[0];
  var procId = p.getAttribute('id') || 'imported';
  var procName = p.getAttribute('name') || procId.replace(/^Pool_/, '');
  var metaEl = p.getElementsByTagNameNS(AEF_NS, 'workflowMeta')[0];
  var authored = metaEl ? metaEl.getAttribute('id') : null;
  var shipped;
  try { shipped = parseBpmnXml(xml).workflowMeta.id; }
  catch (e) { return { ok: false, err: String(e && e.message || e) }; }
  return {
    ok: true,
    hasMeta: !!metaEl,
    authored: authored,
    procId: procId,
    procName: procName,
    shipped: shipped,
    shippedValid: isValidWorkflowId(shipped),
    // the chain as it stood before this task
    old: authored || procName || 'imported',
    oldValid: isValidWorkflowId(authored || procName || 'imported'),
    // the substitution T-501 names and rejects: a summariser in the identity slot
    slug: authored || deriveSlug(procName) || 'imported'
  };
};
true`;

function listBpmn(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir).filter(f => f.endsWith('.bpmn')).sort().map(f => join(dir, f));
}

async function main() {
  if (!existsSync(SRC)) throw new Error('source missing: ' + SRC);

  const files = CORPUS_DIRS.flatMap(listBpmn);
  if (!files.length) {
    console.log('REFUSE — no .bpmn documents found under any corpus directory. The probe');
    console.log('  cannot establish the population it is meant to measure, and reporting');
    console.log('  PASS on an empty set is the failure mode this project keeps hitting.');
    return 2;
  }

  const doc = mkdtempSync(join(tmpdir(), 't563-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't563-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't563-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl;
  const rows = [];
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    // ── leg 1: the three functions this probe reasons about exist in the page ──────
    const shapes = await ev(cmd, `({ parse: typeof parseBpmnXml, san: typeof sanitizeWorkflowId,
                                     val: typeof isValidWorkflowId, slug: typeof deriveSlug })`);
    const shapesOk = shapes.parse === 'function' && shapes.san === 'function'
                     && shapes.val === 'function' && shapes.slug === 'function';
    leg('1 parseBpmnXml + id helpers defined in page', shapesOk,
        `parseBpmnXml=${shapes.parse} sanitizeWorkflowId=${shapes.san} isValidWorkflowId=${shapes.val} deriveSlug=${shapes.slug}`);
    if (!shapesOk) return 1;

    await ev(cmd, PROBE_FN);

    for (const f of files) {
      const xml = readFileSync(f, 'utf8');
      const r = await ev(cmd, `window.__t563(${JSON.stringify(xml)})`);
      rows.push({ file: basename(f), dir: basename(dirname(f)), ...r });
    }

    const broke = rows.filter(r => !r.ok);
    if (broke.length) {
      leg('0 every corpus document imports', false,
          `${broke.length} failed to parse: ${broke.slice(0, 3).map(b => b.file + ' (' + b.err + ')').join('; ')}`);
      return 1;
    }

    const fallback = rows.filter(r => !r.hasMeta);
    const authoredRows = rows.filter(r => r.hasMeta);

    if (!fallback.length) {
      console.log(`REFUSE — ${rows.length} documents read, NONE of them lacks <aef:workflowMeta>.`);
      console.log('  This probe measures the fallback chain; over a population that never');
      console.log('  reaches it, every leg below would be green while proving nothing. That');
      console.log('  is the UNEXERCISED shape (T-423 aef:forceStraight, T-501 IW-0), and it');
      console.log('  is reported as a refusal rather than a pass.');
      return 2;
    }

    // ── leg 2: no derived id in the fallback population is an invalid identity ─────
    const invalid = fallback.filter(r => !r.shippedValid);
    leg('2 every fallback id satisfies isValidWorkflowId', invalid.length === 0,
        `${fallback.length} document(s) with no <aef:workflowMeta>; ${invalid.length} invalid`
        + (invalid.length ? ' — ' + invalid.slice(0, 6).map(r => `${r.file}=${JSON.stringify(r.shipped)}`).join(', ') : ''));

    // ── leg 3: the population is not COLLAPSED — floor, with the summariser as scale ─
    const distinct = new Set(fallback.map(r => r.shipped));
    const slugDistinct = new Set(fallback.map(r => r.slug));
    const slugAllValid = fallback.every(r => r.slug && r.shippedValid !== undefined);
    leg('3 distinct fallback ids at or above floor (deriveSlug would collapse)',
        distinct.size >= DISTINCT_FLOOR,
        `${distinct.size} distinct over ${fallback.length} documents (floor ${DISTINCT_FLOOR}); `
        + `deriveSlug in the same slot yields ${slugDistinct.size} — `
        + `${JSON.stringify([...slugDistinct].slice(0, 6))}`);

    // ── leg 4: an AUTHORED id is returned RAW, byte-for-byte ───────────────────────
    const mangled = authoredRows.filter(r => r.shipped !== r.authored);
    leg('4 authored <aef:workflowMeta id> passes through unchanged', mangled.length === 0,
        `${authoredRows.length} document(s) carry the element; ${mangled.length} altered`
        + (mangled.length ? ' — ' + mangled.slice(0, 6).map(r => `${r.file}: ${JSON.stringify(r.authored)} -> ${JSON.stringify(r.shipped)}`).join(', ') : ''));

    // ── leg 5: the corpus EXERCISES the change — old chain shown failing ───────────
    // Without this, leg 2 is satisfiable by a corpus that never reaches the fallback
    // and by a chain that returns one constant. This requires the old rule to be
    // invalid somewhere the new rule is valid, on these exact documents.
    const exercised = fallback.filter(r => !r.oldValid && r.shippedValid);
    const changed = fallback.filter(r => r.old !== r.shipped);
    leg('5 old chain demonstrably invalid where the new one is valid', exercised.length > 0,
        `${changed.length}/${fallback.length} document(s) derive a different id than before; `
        + `${exercised.length} were INVALID under the old chain and are valid now`
        + (exercised.length ? ' — e.g. ' + exercised.slice(0, 3).map(r => `${r.file}: ${JSON.stringify(r.old)} -> ${JSON.stringify(r.shipped)}`).join(', ') : ''));

    // Per-document table. The probe's job is to report a measurement, so it prints one
    // even when every leg is green — a run that says only "5/5" cannot be audited.
    console.log(`\nFallback population (${fallback.length} documents, no <aef:workflowMeta>):`);
    for (const r of fallback) {
      console.log(`  ${r.dir}/${r.file}`);
      console.log(`      procId=${JSON.stringify(r.procId)} procName=${JSON.stringify(r.procName)}`);
      console.log(`      old=${JSON.stringify(r.old)}${r.oldValid ? '' : ' (INVALID)'}  ->  now=${JSON.stringify(r.shipped)}${r.shippedValid ? '' : ' (INVALID)'}   [deriveSlug would give ${JSON.stringify(r.slug)}]`);
    }
    console.log(`\nAuthored population: ${authoredRows.length} document(s) carry <aef:workflowMeta id>, all returned raw.`);

  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  return legs.every(l => l.pass) && legs.length === 5 ? 0 : 1;
}

main().then(rc => {
  for (const l of legs) console.log(`${l.pass ? 'PASS' : 'FAIL'}  ${l.name} — ${l.detail}`);
  if (legs.length) {
    const passed = legs.filter(l => l.pass).length;
    console.log(`\n${passed}/${legs.length} legs passed`);
  }
  process.exit(rc);
}).catch(e => {
  for (const l of legs) console.log(`${l.pass ? 'PASS' : 'FAIL'}  ${l.name} — ${l.detail}`);
  console.error('ERROR: ' + (e && e.message ? e.message : e));
  process.exit(2);
});
