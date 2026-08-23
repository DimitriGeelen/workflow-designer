#!/usr/bin/env node
/**
 * _t565-workflowmeta-emission-census.mjs — the exit condition T-501 IW-0 named for itself,
 * measured on a population that can actually move.
 *
 * WHAT IW-0 ASKS. T-501 carved out one item from its GO: "should export always emit
 * <aef:workflowMeta>?" It is `disposition: deferred`, and the deferral wrote its own exit
 * (T-501:157-163): measure whether always emitting the element changes the bytes of any of
 * the 24 rendered corpus maps, then run the T-308/T-358 byte-identity gates against it.
 *
 * WHY THAT EXIT CANNOT BE EXECUTED AS WRITTEN, which is the first finding and the reason
 * this file measures more than it was asked to. All 24 of examples/aef-processes/rendered
 * already carry exactly one <aef:workflowMeta>. A change conditioned on "the document has
 * no such element" cannot move a population in which that condition occurs zero times. So
 * a clean result over the named 24 would be a no-op reported as a safety proof — the same
 * population-pin shape as T-423's aef:forceStraight (0 corpus instances, guard green
 * forever) and G-015. The 24 are measured anyway and reported as UNEXERCISED, deliberately
 * NOT as evidence.
 *
 * WHERE THE MOVERS ARE. T-501 IW-1 already located them: over the 60-document corpus
 * (rendered + tests/fixtures/{aef-bpmn,third-party,lane-provenance}) 14 documents carry no
 * <aef:workflowMeta> and reach the id fallback chain. Those 14 are the only documents an
 * always-emit rule can change, so they are the population the operator's ruling should be
 * made against.
 *
 * WHAT IS MEASURED, AND WHY IT IS THE ELEMENT AND NOT THE DOCUMENT. Each corpus document is
 * parsed and re-exported by the real designer in a real browser, and the census records
 * whether <aef:workflowMeta> is present in the INPUT and in the OUTPUT. The byte figure
 * reported is the emitted workflowMeta BLOCK, not the whole-document delta. That is not a
 * convenience: since T-423, DI is emitted unconditionally, so a whole-document diff is
 * dominated by 2012 added DI elements and would answer a question nobody asked. The block
 * is the byte cost attributable to this item alone, which is exactly what the carve-out was
 * carved out to preserve.
 *
 * WHY A BROWSER. buildBpmnXml only exists inside the page. Reading the emitter and stating
 * what it would do is the substitution this project has spent a week cataloguing — a stated
 * property standing in for a checked one. The emitter's behaviour here is the finding, so
 * it is executed, not quoted.
 *
 * GATE COVERAGE IS PART OF THE ANSWER. The deferral names T-308 and T-358 as the safety net.
 * Each of those gates reads a fixed corpus; this census reports, per moving document,
 * whether either gate would see it. A gate pointed at a population that cannot contain the
 * change is not a safety net for that change.
 *
 * IT IS A CENSUS THAT ALSO HOLDS ONE INVARIANT, and the invariant was added deliberately
 * after the first run. The census answers IW-0 by measuring that always-emit is ALREADY the
 * behaviour — every corpus document lacking the element gains one on export. That fact is
 * what the operator's ruling would rest on, so it needs something watching it: a leg that
 * reports a number and can never go red is not a guard, it is a log line. If emission ever
 * becomes conditional, the ruling's premise is gone and this goes red.
 *
 * Exit 0 = every document that lacks <aef:workflowMeta> gains one on export.
 *      1 = at least one did not — the premise IW-0's answer rests on is broken, named.
 *      2 = REFUSED. Corpus missing, a document failed to export (a silently shrinking
 *          population is how coverage evaporates with the verdict unchanged), or the
 *          moving population is EMPTY — a corpus in which no document lacks the element
 *          cannot exercise the invariant, and passing on it would be the exact
 *          population-pin this file was written to expose.
 *
 * Usage: node tools/_t565-workflowmeta-emission-census.mjs
 */

import { spawn } from 'node:child_process';
import { readdirSync, existsSync, readFileSync, mkdtempSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');

// The four directories T-501's census of 60 named, in its order. Written out rather than
// discovered by a find, because the corpus this ruling is made against must be the same one
// the earlier measurement used — a population that silently grows between two measurements
// makes the two numbers incomparable, and this file exists to be compared with T-501's.
const CORPUS_DIRS = [
  ['rendered',        join(REPO, 'examples', 'aef-processes', 'rendered')],
  ['aef-bpmn',        join(REPO, 'tests', 'fixtures', 'aef-bpmn')],
  ['third-party',     join(REPO, 'tests', 'fixtures', 'third-party')],
  ['lane-provenance', join(REPO, 'tests', 'fixtures', 'lane-provenance')],
];

// What each named gate actually reads, taken from the gates themselves rather than from
// their names. _t308-export-byte-identity-cdp.mjs:31 defaults CORPUS to the rendered maps;
// _t358-byteid-thirdparty.mjs:46 defaults FIXDIR to tests/fixtures/third-party.
const GATE_SCOPE = {
  'rendered':    ['_t308-export-byte-identity-cdp.mjs'],
  'third-party': ['_t358-byteid-thirdparty.mjs'],
};

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const EXPORT_EXPR = `(function(){
  var out = {};
  var maps = window.__MAPS__;
  for (var i=0;i<maps.length;i++){
    try {
      var m = parseBpmnXml(maps[i].text);
      if(!m){ out[maps[i].name] = {err:'parse returned null'}; continue; }
      state = m; refreshDisplayIds();
      out[maps[i].name] = {xml: buildBpmnXml(state)};
    } catch(e) { out[maps[i].name] = {err: String(e && e.message || e)}; }
  }
  return out;
})()`;

// The emitted element, verbatim, so the byte figure is the bytes and not a description of
// them. Returns null when absent — which is the case this census exists to detect, so the
// distinction between "absent" and "unreadable" is kept rather than collapsed to falsy.
function metaBlock(xml) {
  const m = /^[ \t]*<aef:workflowMeta\b[^>]*\/?>/m.exec(xml);
  return m ? m[0] : null;
}

function main2(docs, exported) {
  const rows = [];
  for (const d of docs) {
    const r = exported[d.key];
    rows.push({
      ...d,
      inMeta: metaBlock(d.text),
      outMeta: metaBlock(r.xml),
    });
  }

  console.log('== <aef:workflowMeta> emission census (T-565 / T-501 IW-0) ==\n');

  // ── 1. The population the deferral named ─────────────────────────────────────────────
  const rendered = rows.filter(r => r.group === 'rendered');
  const rLack = rendered.filter(r => !r.inMeta);
  console.log(`THE POPULATION IW-0's EXIT CONDITION NAMED: ${rendered.length} rendered map(s).`);
  console.log(`  carry <aef:workflowMeta> on input:   ${rendered.length - rLack.length}`);
  console.log(`  do NOT carry it on input:            ${rLack.length}`);
  if (!rLack.length) {
    console.log('\n  UNEXERCISED. Every map in the named population already carries the element,');
    console.log('  so an always-emit rule cannot change one byte of any of them. This is NOT');
    console.log('  reported as "always-emit is safe": a no-op over a population containing none');
    console.log('  of the condition is not evidence about the condition. Same shape as T-423');
    console.log('  aef:forceStraight (0 instances) and G-015 population-pinning.');
  }

  // ── 2. The population that CAN move ──────────────────────────────────────────────────
  const movers = rows.filter(r => !r.inMeta);
  console.log(`\nTHE POPULATION THAT CAN MOVE, over the full ${rows.length}-document corpus:`);
  for (const [name] of CORPUS_DIRS) {
    const g = rows.filter(r => r.group === name);
    const l = g.filter(r => !r.inMeta);
    console.log(`  ${name.padEnd(16)} ${String(g.length).padStart(3)} document(s), ${String(l.length).padStart(3)} lacking <aef:workflowMeta>`);
  }
  console.log(`  ${'TOTAL'.padEnd(16)} ${String(rows.length).padStart(3)} document(s), ${String(movers.length).padStart(3)} can be changed by an always-emit rule`);

  // ── 3. What the exporter ACTUALLY does to them ───────────────────────────────────────
  const gained = movers.filter(r => r.outMeta);
  const stillAbsent = movers.filter(r => !r.outMeta);
  console.log(`\nWHAT THE CURRENT EXPORTER ALREADY DOES TO THOSE ${movers.length}, measured by round-tripping`);
  console.log('each through the real designer rather than by reading buildBpmnXml:');
  console.log(`  input lacked it, output CARRIES it:  ${gained.length}`);
  console.log(`  input lacked it, output still lacks: ${stillAbsent.length}`);
  if (movers.length && gained.length === movers.length) {
    console.log('\n  ALWAYS-EMIT IS ALREADY THE BEHAVIOUR. Every document that lacks the element');
    console.log('  gains one on export today, unconditionally. IW-0 asks whether export SHOULD');
    console.log('  always emit; the exporter already does. So the item is not a proposed byte');
    console.log('  change to weigh — it is a description of current behaviour, and the bytes it');
    console.log('  would supposedly add are bytes the tree already writes.');
  }

  // ── 4. Per-document bytes, and whether any named gate watches it ─────────────────────
  if (movers.length) {
    console.log('\nPER-DOCUMENT, the block emitted and the gate that would see it:');
    for (const r of movers) {
      const gates = GATE_SCOPE[r.group] || [];
      const blk = r.outMeta || '(none emitted)';
      console.log(`\n  ${r.group}/${r.name}`);
      console.log(`      emitted block  ${Buffer.byteLength(blk, 'utf8')} byte(s): ${blk.trim()}`);
      console.log(`      watched by     ${gates.length ? gates.join(', ') : 'NO NAMED GATE'}`);
    }
  }

  // ── 5. The gate-coverage answer the deferral asked for ───────────────────────────────
  const unwatched = movers.filter(r => !(GATE_SCOPE[r.group] || []).length);
  console.log('\n== Gate coverage of the moving population ==');
  console.log(`  documents that can move:                 ${movers.length}`);
  console.log(`  of those, inside a named gate's corpus:  ${movers.length - unwatched.length}`);
  console.log(`  of those, watched by NO named gate:      ${unwatched.length}`);
  console.log('  T-308 reads examples/aef-processes/rendered; T-358 reads tests/fixtures/third-party.');
  console.log('  Neither gate is a safety net for a document outside the directory it reads, and');
  console.log('  the deferral named both as though they covered the item.');

  console.log('\nREAD THIS AS A CENSUS, NOT A RULING. Whether export should always emit the element');
  console.log('is the operator\'s call. What this measures is that the question, as written, names a');
  console.log('population that cannot answer it, and that the behaviour it proposes is already shipped.');

  // ── The one invariant this file holds ────────────────────────────────────────────────
  if (!movers.length) {
    console.log('\nREFUSE — the moving population is EMPTY. No corpus document lacks');
    console.log('<aef:workflowMeta>, so nothing here can exercise the invariant and a PASS would');
    console.log('mean only that there was nothing to check. Reported as a refusal rather than a');
    console.log('pass for the same reason T-423 prints UNEXERCISED instead of counting coverage.');
    return 2;
  }
  if (stillAbsent.length) {
    console.log(`\nFAIL — ${stillAbsent.length} document(s) lacked <aef:workflowMeta> on input and STILL lack`);
    console.log('it on export. Always-emit is no longer unconditional, which is the premise any');
    console.log('answer to IW-0 rests on:');
    for (const r of stillAbsent) console.log(`    ${r.group}/${r.name}`);
    return 1;
  }
  console.log(`\nPASS — all ${movers.length} document(s) that lack the element gain one on export.`);
  return 0;
}

async function main() {
  const docs = [];
  for (const [group, dir] of CORPUS_DIRS) {
    if (!existsSync(dir)) { console.log(`REFUSE — corpus directory missing: ${dir}`); return 2; }
    for (const f of readdirSync(dir).filter(x => x.endsWith('.bpmn')).sort()) {
      docs.push({ group, name: f, key: `${group}/${f}`, text: readFileSync(join(dir, f), 'utf8') });
    }
  }
  if (!docs.length) { console.log('REFUSE — no .bpmn documents in the four corpus directories'); return 2; }

  const doc = mkdtempSync(join(tmpdir(), 't565-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't565-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't565-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, exported = null;
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
    await cl.cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cl.cmd); await sleep(300);
    const maps = docs.map(d => ({ name: d.key, text: d.text }));
    await ev(cl.cmd, `window.__MAPS__ = ${JSON.stringify(maps)};`);
    exported = await ev(cl.cmd, EXPORT_EXPR);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  // A document that failed to export is not a document with nothing to report. Named and
  // fatal: dropping it would shrink the denominator of every ratio printed below while the
  // verdict stayed the same, which is the failure mode this census is about.
  const failed = [];
  for (const d of docs) {
    const r = exported && exported[d.key];
    if (!r || r.err || !r.xml) failed.push(`${d.key}: ${(r && r.err) || 'no output'}`);
  }
  if (failed.length) {
    console.log(`REFUSE — ${failed.length} of ${docs.length} document(s) did not export:`);
    for (const x of failed) console.log('  ' + x);
    return 2;
  }

  return main2(docs, exported);
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
