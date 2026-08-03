#!/usr/bin/env node
// _t347-accepted-element-content-cdp.mjs — does content INSIDE an element the
// importer accepts survive the round trip?
//
// WHY THIS EXISTS SEPARATELY FROM _t356. That instrument asks "does a third-party
// document survive?" and counts structure — nodes, flows, lanes, DI. T-347 asks a
// narrower question: when the importer ACCEPTS an element, does it keep what is
// inside it? An importer can score perfectly on _t356's census while silently
// discarding every <documentation> in the file, because documentation is not a node.
//
// WHY THE T-356 FIXTURES COULD NOT ANSWER IT. Censusing those five against these
// shapes returned ALL ZEROS: documentation 0, foreign extensionElements children 0,
// property 0, loop characteristics 0. T-356 made this project capable of answering
// ONE question and cast a halo over its neighbours. Capability is per-QUESTION, not
// per-population — so T-347 needed its own hunt, under the same criterion.
//
// THE DIRECTION IS STATED BEFORE THE RUN:
//
//   - A shape present in input and absent from output => the defect is REAL for that
//                                                        shape, with a named witness.
//   - A shape present in input and present in output  => that shape SURVIVES. This is
//                                                        a real negative, and T-347's
//                                                        severity must come down for it.
//   - A shape ABSENT from input                       => this file CANNOT ANSWER. It is
//                                                        not agreement. See below.
//   - Positive control lossy                          => harness broken; every row void.
//
// THE THREE-STATE REPORTING IS THE POINT. A two-state instrument (lossy/clean) would
// score a fixture carrying no <documentation> as "documentation fine", and ten such
// fixtures would read as strong evidence for a claim nothing measured. So every shape
// reports kept / LOST / n-a separately, and each shape's denominator is the number of
// files that ACTUALLY CARRY IT — not the number of files run.
//
// This is a MEASURING instrument. It pins no expectation and gates nothing.

import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T347_DESIGNER_SRC || join(REPO, 'src', 'aef-workflow-designer.html');
const THIRD = join(REPO, 'tests', 'fixtures', 'third-party');
const CORPUS = join(REPO, 'examples', 'aef-processes', 'rendered');
const JSON_OUT = process.argv.includes('--json');
const sleep = ms => new Promise(r => setTimeout(r, ms));

// ── the measurement ────────────────────────────────────────────────────────
// Spec-reserved prefixes. Anything else namespaced is a foreign vocabulary, which
// is what "foreign extensionElements child" and "unknown attribute" mean here.
const SPEC_PREFIX = /^(bpmn|bpmn2|bpmndi|dc|di|semantic|xsi|xsd|xml|xmlns)$/;

const count = (xml, re) => (xml.match(re) || []).length;

// PER-PREFIX, AND THE REASON MATTERS. A first cut of this instrument summed every
// non-spec prefix into one number and compared input to output. kitchen-sink then
// read `extChildren kept 1->162`: its ONE <zeebe:calledElement> was deleted, and our
// exporter's own <aef:position> — one per node — pushed the total far past the input,
// so the comparison called a deletion "kept". A total cannot tell PRESERVATION from
// SUBSTITUTION, and it fails toward the reassuring answer. Counting per prefix, and
// only over the prefixes the INPUT actually had, is substitution-proof: content we
// emit ourselves can never repay a debt in someone else's vocabulary.
function prefixTally(xml, re, slice) {
  const out = {};
  for (const t of xml.match(re) || []) {
    const p = slice(t);
    if (!SPEC_PREFIX.test(p)) out[p] = (out[p] || 0) + 1;
  }
  return out;
}
const foreignEls   = xml => prefixTally(xml, /<([a-zA-Z][\w.-]*):([a-zA-Z][\w.-]*)/g, t => t.slice(1).split(':')[0]);
const foreignAttrs = xml => prefixTally(xml, /\s([a-zA-Z][\w.-]*):([a-zA-Z][\w.-]*)=/g, t => t.trim().split(':')[0]);

// Sum a tally, restricted to a set of prefixes (the input's) when one is given.
const tallySum = (t, only) => Object.entries(t)
  .filter(([p]) => !only || only.has(p))
  .reduce((n, [, v]) => n + v, 0);

// T-347's five shapes, each counted independently — none derivable from another.
// `only` carries the input's foreign prefixes when censusing an output.
function census(xml, only) {
  return {
    documentation: count(xml, /<(?:[\w.-]+:)?documentation[ />]/g),
    extChildren:   tallySum(foreignEls(xml), only && only.els),
    property:      count(xml, /<(?:[\w.-]+:)?property[ />]/g),
    loopChars:     count(xml, /<(?:[\w.-]+:)?[a-zA-Z]*LoopCharacteristics[ />]/g),
    unknownAttrs:  tallySum(foreignAttrs(xml), only && only.attrs),
  };
}
const prefixesOf = xml => ({
  els:   new Set(Object.keys(foreignEls(xml))),
  attrs: new Set(Object.keys(foreignAttrs(xml))),
});
const KEYS = Object.keys(census('<x/>'));

// ── plumbing (same shape as _t356) ─────────────────────────────────────────
function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright'); const c = [];
  if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome'));
  c.sort().reverse();
  for (const x of c) if (existsSync(x)) return x;
  throw new Error('no chromium');
}
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) {
  const s = new WebSocket(ws); let id = 0; const p = new Map();
  s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } });
  const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); });
  const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); });
  return { ready, cmd, close: () => s.close() };
}
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// ── run ────────────────────────────────────────────────────────────────────
(async () => {
  const subjects = readdirSync(THIRD).filter(f => f.endsWith('.bpmn')).sort()
    .map(f => ({ name: basename(f, '.bpmn'), kind: 'third-party', text: readFileSync(join(THIRD, f), 'utf8') }));
  if (!subjects.length) throw new Error(`no fixtures in ${THIRD}`);

  const corpusFiles = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!corpusFiles.length) throw new Error('no corpus map available for the positive control');
  const control = { name: basename(corpusFiles[0], '.bpmn'), kind: 'control', text: readFileSync(join(CORPUS, corpusFiles[0]), 'utf8') };

  const doc = mkdtempSync(join(tmpdir(), 't347-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't347-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't347-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl, rows = [];
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
    await waitReady(cmd); await sleep(200);

    const roundTrip = async text => {
      await ev(cmd, `window.__X__ = ${JSON.stringify(text)};`);
      return await ev(cmd, `(function(){ try {
        state = parseBpmnXml(window.__X__); refreshDisplayIds();
        return { xml: buildBpmnXml(state) };
      } catch(e) { return { threw: String(e && e.message || e) }; } })()`);
    };

    for (const s of [control, ...subjects]) {
      const r = await roundTrip(s.text);
      if (r.threw) { rows.push({ name: s.name, kind: s.kind, threw: r.threw }); continue; }
      const only = prefixesOf(s.text);
      const a = census(s.text), b = census(r.xml, only);
      const verdict = {};
      for (const k of KEYS) verdict[k] = a[k] === 0 ? 'n-a' : (b[k] >= a[k] ? 'kept' : 'LOST');
      rows.push({ name: s.name, kind: s.kind, input: a, output: b, verdict });
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGTERM'); } catch (_) {}
    try { py.kill('SIGTERM'); } catch (_) {}
  }

  if (JSON_OUT) { console.log(JSON.stringify({ rows }, null, 2)); return; }

  const ctl = rows.find(r => r.kind === 'control');
  const subs = rows.filter(r => r.kind === 'third-party');

  console.log('== T-347 content-inside-an-accepted-element ==\n');
  console.log(`positive control (designer-produced): ${ctl.name}`);
  if (ctl.threw) console.log(`  HARNESS BROKEN — control threw: ${ctl.threw}`);
  else if (Object.values(ctl.verdict).includes('LOST')) console.log(`  control lost: ${JSON.stringify(ctl.verdict)}`);
  else console.log('  no shape lost — round-trip path sound, subject results are real\n');

  const w = Math.max(...subs.map(r => r.name.length), 12);
  console.log('file'.padEnd(w) + '  ' + KEYS.map(k => k.padEnd(14)).join(''));
  console.log('-'.repeat(w + 2 + KEYS.length * 14));
  for (const r of subs) {
    if (r.threw) { console.log(r.name.padEnd(w) + '  THREW: ' + r.threw); continue; }
    console.log(r.name.padEnd(w) + '  ' + KEYS.map(k =>
      (r.verdict[k] === 'n-a' ? 'n/a' : `${r.verdict[k]} ${r.input[k]}->${r.output[k]}`).padEnd(14)).join(''));
  }

  // Per-shape denominators. The denominator is the count of files that CARRY the
  // shape — files that do not carry it are reported as unable to answer, never
  // folded in as agreement.
  console.log('\nPER-SHAPE VERDICT (denominator = files that actually carry the shape)\n');
  for (const k of KEYS) {
    const carriers = subs.filter(r => !r.threw && r.verdict[k] !== 'n-a');
    const lost = carriers.filter(r => r.verdict[k] === 'LOST');
    const na = subs.length - carriers.length;
    if (!carriers.length) {
      console.log(`  ${k.padEnd(14)} NO CARRIER — 0/${subs.length} files carry this shape.`);
      console.log(`  ${''.padEnd(14)} UNANSWERED: this run says nothing about it either way.`);
    } else {
      console.log(`  ${k.padEnd(14)} ${lost.length}/${carriers.length} carriers LOSE it` +
        `  (${na} file(s) cannot answer)`);
      if (lost.length) console.log(`  ${''.padEnd(14)} witnesses: ${lost.map(r => r.name).join(', ')}`);
      else console.log(`  ${''.padEnd(14)} SURVIVES on every carrier — T-347 severity must come down for this shape.`);
    }
  }
})().catch(e => { console.error('ERROR: ' + (e && e.stack || e)); process.exit(1); });
