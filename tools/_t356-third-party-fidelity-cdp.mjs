#!/usr/bin/env node
// _t356-third-party-fidelity-cdp.mjs — run REAL third-party BPMN through today's
// importer and measure what survives.
//
// WHY THIS EXISTS SEPARATELY FROM _t338. That instrument's populations are all
// SYNTHESISED: it takes a corpus map we produced and injects a probe into it
// (injectDI, injectRoot, injectContent, inject). Injection answers "does the
// importer drop X when X is spliced into a document we wrote?" — a good question,
// and not the same question as "does a document a real tool wrote survive?".
//
// T-356 measured the gap: 126 .bpmn in this tree, 0 with an `exporter=` signature,
// 0 with `bpmndi:`. Every fidelity number this project has ever quoted was drawn
// from a population that our own exporter authored, which is why T-340's severity
// ("0 of N files carry DI") could never have filled. See tests/fixtures/third-party/
// PROVENANCE.md.
//
// THE DIRECTION IS STATED BEFORE THE RUN, so a clean result cannot be read as good
// news after the fact:
//
//   - Any fixture losing content  => the population is CAPABLE OF FAILING, which is
//                                    what T-356 AC2 requires. Losses are findings.
//   - Every fixture clean         => the FIXTURES ARE UNREPRESENTATIVE. It does NOT
//                                    mean the importer is sound. Get better fixtures.
//   - Positive control lossy      => the HARNESS is broken. Every other row in the
//                                    run is void; fix this before reading any of them.
//
// THE POSITIVE CONTROL IS INPUT-DERIVED, not hard-coded. It is a real corpus map,
// which the designer is known lossless over (_t338 leg 1 gates exactly that). If it
// reads lossy here, the difference is this harness, not the designer. A control
// that cannot fail is the recurring defect on this arc — see T-335 REPAIRED and
// T-336 VALUE — so this one is measured through the same code path as the subjects.
//
// This is a MEASURING instrument, not a gate: it pins no expectation and flips no
// verdict. T-356 AC4 forbids that deliberately — this task adds a population, it
// does not repair a defect.

import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T356_DESIGNER_SRC || join(REPO, 'src', 'aef-workflow-designer.html');
const THIRD = join(REPO, 'tests', 'fixtures', 'third-party');
const CORPUS = join(REPO, 'examples', 'aef-processes', 'rendered');
const JSON_OUT = process.argv.includes('--json');
const sleep = ms => new Promise(r => setTimeout(r, ms));

// ── the measurement ────────────────────────────────────────────────────────
// Counts only. Every property here is one a losing importer would visibly move,
// and none is derivable from another, so a single number cannot mask a change in
// a different one.
const NODE_TAGS = 'serviceTask|userTask|scriptTask|manualTask|task|sendTask|receiveTask'
  + '|businessRuleTask|callActivity|subProcess|startEvent|endEvent|intermediateCatchEvent'
  + '|intermediateThrowEvent|boundaryEvent|exclusiveGateway|parallelGateway'
  + '|inclusiveGateway|eventBasedGateway';

const count = (xml, re) => (xml.match(re) || []).length;

function census(xml) {
  return {
    nodes:       count(xml, new RegExp(`<(?:\\w+:)?(?:${NODE_TAGS})[ />]`, 'g')),
    flows:       count(xml, /<(?:\w+:)?sequenceFlow[ />]/g),
    lanes:       count(xml, /<(?:\w+:)?lane[ />]/g),
    participants:count(xml, /<(?:\w+:)?participant[ />]/g),
    messageFlows:count(xml, /<(?:\w+:)?messageFlow[ />]/g),
    processes:   count(xml, /<(?:\w+:)?process[ />]/g),
    diagrams:    count(xml, /<bpmndi:BPMNDiagram[ />]/g),
    diShapes:    count(xml, /<bpmndi:BPMNShape[ />]/g),
    diEdges:     count(xml, /<bpmndi:BPMNEdge[ />]/g),
    bounds:      count(xml, /<dc:Bounds[ />]/g),
    docs:        count(xml, /<(?:\w+:)?documentation[ />]/g),
    exporter:    /\sexporter=/.test(xml) ? 1 : 0,
  };
}

const KEYS = Object.keys(census('<x/>'));

// ── plumbing (same shape as _t338) ─────────────────────────────────────────
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

  // positive control: a real corpus map, input-derived, known lossless
  const corpusFiles = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!corpusFiles.length) throw new Error('no corpus map available for the positive control');
  const control = { name: basename(corpusFiles[0], '.bpmn'), kind: 'control', text: readFileSync(join(CORPUS, corpusFiles[0]), 'utf8') };

  const doc = mkdtempSync(join(tmpdir(), 't356-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't356-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't356-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl, rows = [];
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready;
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
      if (r.threw) { rows.push({ ...s, threw: r.threw }); continue; }
      const a = census(s.text), b = census(r.xml);
      const delta = {}; for (const k of KEYS) if (a[k] !== b[k]) delta[k] = [a[k], b[k]];
      rows.push({ name: s.name, kind: s.kind, input: a, output: b, delta, lossy: Object.keys(delta).length > 0 });
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGTERM'); } catch (_) {}
    try { py.kill('SIGTERM'); } catch (_) {}
  }

  if (JSON_OUT) { console.log(JSON.stringify({ rows }, null, 2)); return; }

  const ctl = rows.find(r => r.kind === 'control');
  const subs = rows.filter(r => r.kind === 'third-party');

  console.log('== T-356 third-party import fidelity ==\n');
  console.log(`positive control (designer-produced, must be clean): ${ctl.name}`);
  if (ctl.threw) console.log(`  HARNESS BROKEN — control threw: ${ctl.threw}`);
  else if (ctl.lossy) console.log(`  HARNESS BROKEN — control lost: ${JSON.stringify(ctl.delta)}`);
  else console.log('  clean — the round-trip path itself is sound, so subject losses are real\n');

  for (const r of subs) {
    if (r.threw) { console.log(`${r.name}\n  THREW: ${r.threw}`); continue; }
    console.log(`${r.name}  ${r.lossy ? 'LOSSY' : 'clean'}`);
    for (const [k, [i, o]] of Object.entries(r.delta)) console.log(`    ${k.padEnd(13)} in=${i}  out=${o}`);
    if (!r.lossy) console.log('    (no counted property moved — see the note below before reading this as good)');
  }

  const lossy = subs.filter(r => r.lossy || r.threw).length;
  console.log(`\n${lossy}/${subs.length} third-party fixtures lose content through today's importer.`);
  if (lossy === 0) console.log('ZERO IS NOT A PASS. Per T-356 AC2 the conclusion is that these fixtures are\nunrepresentative, NOT that the importer is sound. Get better fixtures.');
  else console.log('The population is CAPABLE OF FAILING — T-356 AC2 satisfied. Each loss is a\nfinding to file, not a pin to flip (AC4).');
})().catch(e => { console.error('ERROR: ' + (e && e.stack || e)); process.exit(1); });
