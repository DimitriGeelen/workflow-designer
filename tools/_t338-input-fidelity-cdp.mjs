#!/usr/bin/env node
// _t338-input-fidelity-cdp.mjs — does a load->save round trip PRESERVE what it was
// given? Compares the EXPORTED document against the INPUT document.
//
// Prevention leg for G-016. The tree already has an export-safety instrument,
// tools/_t308-export-byte-identity-cdp.mjs, and it is differential: it runs
// buildBpmnXml(parseBpmnXml(map)) under the working tree AND under a git ref and
// compares the two outputs TO EACH OTHER, over the 24 well-formed corpus maps.
// Two blind spots follow from that shape, neither of which is a bug in that tool:
//
//   1. A defect present in BOTH versions is byte-identical, therefore green. The
//      instrument can see CHANGE; it cannot see WRONGNESS.
//   2. Its denominator is well-formed corpus maps, so a defect only malformed
//      input can express is outside the population entirely.
//
// T-337 lived in the intersection: parseBpmnXml enumerates flow nodes by iterating
// a hard-coded tag allowlist with no complement branch, so an unlisted tag is not
// rejected but never visited; export writes only from state.nodes, so the node is
// deleted on open->save. Both designer versions drop it (green), and no corpus map
// carries such a tag (never asked).
//
// This instrument supplies the missing direction -- output vs INPUT -- over a
// population that deliberately includes documents the corpus cannot express.
//
// THE LOSSY SET IS MEASURED, NOT DECLARED. A hand-written "known lossy tags" list
// would be a tolerance answerable only to itself: it could never fail for being
// wrong, only for being out of date, and nothing would say which. Instead every
// probe tag is exercised every run and the resulting SET is compared with EXPECTED.
// A tag joining the set fails. A tag LEAVING it also fails, and says so -- that is
// how this guard reports that T-337 landed, rather than quietly relaxing.
//
// Usage: node tools/_t338-input-fidelity-cdp.mjs [--json]
// Exit 0 = corpus lossless AND lossy set == expected; 1 = drift; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = join(REPO, 'examples', 'aef-processes', 'rendered');
const SRC = join(REPO, 'src', 'aef-workflow-designer.html');
const JSON_OUT = process.argv.includes('--json');
const sleep = ms => new Promise(r => setTimeout(r, ms));

// Standard BPMN flow-node tags this designer does not implement. Every one is a
// legitimate element a peer may author -- callActivity is already an open task
// here (T-282) and inclusiveGateway/businessRuleTask are plain BPMN. The point is
// not that these are exotic; it is that the vocabulary gap between BPMN and the
// importer's allowlist is where content silently disappears.
const PROBE_TAGS = [
  'callActivity', 'inclusiveGateway', 'businessRuleTask', 'sendTask',
  'receiveTask', 'manualTask', 'eventBasedGateway', 'complexGateway',
  'transaction', 'adHocSubProcess',
];

// Tags currently measured as lossy. NOT a permission list -- the set is recomputed
// every run and any difference in EITHER direction is a failure. Empty this after
// T-337 lands and the guard will tell you if you were wrong to.
const EXPECTED_LOSSY = new Set(PROBE_TAGS);

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Counts taken from the DOCUMENT, never from editor state -- state is the thing
// under test, so counting it would make the guard agree with the defect.
const NON_FLOWNODE = new Set(['sequenceFlow', 'laneSet', 'extensionElements', 'documentation']);
function census(xml) {
  const proc = xml.match(/<bpmn:process\b[\s\S]*?<\/bpmn:process>/);
  const body = proc ? proc[0] : xml;
  const flows = (body.match(/<bpmn:sequenceFlow\b/g) || []).length;
  const lanes = (body.match(/<bpmn:lane\b/g) || []).length;
  // Direct children of <bpmn:process> that are not sequenceFlow/laneSet/etc.
  const opens = [...body.matchAll(/<bpmn:([A-Za-z]+)\b/g)].map(m => m[1]);
  const nodes = opens.filter(t => !NON_FLOWNODE.has(t) && t !== 'process' && t !== 'lane'
    && t !== 'flowNodeRef' && t !== 'incoming' && t !== 'outgoing'
    && t !== 'conditionExpression').length;
  return { nodes, flows, lanes };
}

// Inject one element carrying `tag` into the process, wired into nothing, so the
// only thing that can remove it is the importer.
function inject(xml, tag) {
  const probeId = 'probe_' + tag;
  const el = `\n    <bpmn:${tag} id="${probeId}" name="Probe ${tag}">\n`
    + `      <bpmn:extensionElements><aef:uid value="${probeId}"/></bpmn:extensionElements>\n`
    + `    </bpmn:${tag}>\n`;
  const at = xml.indexOf('</bpmn:process>');
  if (at < 0) return null;
  return xml.slice(0, at) + el + xml.slice(at);
}

async function main() {
  if (!existsSync(CORPUS)) { console.log('FAIL: no corpus at ' + CORPUS); process.exitCode = 2; return; }
  const files = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!files.length) { console.log('FAIL: corpus empty'); process.exitCode = 2; return; }
  const maps = files.map(f => ({ name: basename(f, '.bpmn'), text: readFileSync(join(CORPUS, f), 'utf8') }));

  const doc = mkdtempSync(join(tmpdir(), 't338-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't338-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't338-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
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

    // -- leg 1: the corpus must be lossless -------------------------------
    const corpusLoss = [];
    for (const m of maps) {
      const r = await roundTrip(m.text);
      if (r.threw) { corpusLoss.push({ map: m.name, threw: r.threw }); continue; }
      const a = census(m.text), b = census(r.xml);
      if (a.nodes !== b.nodes || a.flows !== b.flows || a.lanes !== b.lanes) {
        corpusLoss.push({ map: m.name, input: a, output: b });
      }
    }

    // -- leg 2: which out-of-vocabulary tags lose content? ----------------
    // Measured, every run. The tag is present in the input by construction
    // (asserted), so a missing tag in the output is a loss and nothing else.
    const observedLossy = new Set();
    const probeRows = [];
    const notInjected = [];
    for (const tag of PROBE_TAGS) {
      const src = inject(maps[0].text, tag);
      if (src === null) { notInjected.push(tag); continue; }
      if (!new RegExp(`<bpmn:${tag}\\b`).test(src)) { notInjected.push(tag); continue; }
      const r = await roundTrip(src);
      if (r.threw) { probeRows.push({ tag, threw: r.threw }); observedLossy.add(tag); continue; }
      const kept = new RegExp(`<bpmn:${tag}\\b`).test(r.xml);
      if (!kept) observedLossy.add(tag);
      probeRows.push({ tag, kept });
    }

    // -- population assertions: the guard must not pass by testing nothing --
    const problems = [];
    if (maps.length === 0) problems.push('corpus population is empty');
    if (probeRows.length === 0) problems.push('out-of-vocabulary population is empty — nothing was probed');
    if (notInjected.length) problems.push(`could not inject ${notInjected.length} probe tag(s): ${notInjected.join(', ')}`);

    // -- verdict ----------------------------------------------------------
    const appeared = [...observedLossy].filter(t => !EXPECTED_LOSSY.has(t)).sort();
    const closed = [...EXPECTED_LOSSY].filter(t => !observedLossy.has(t)).sort();

    const ok = corpusLoss.length === 0 && appeared.length === 0 && closed.length === 0 && problems.length === 0;
    if (JSON_OUT) {
      console.log(JSON.stringify({ ok, corpus: maps.length, corpusLoss, probed: probeRows.length, lossy: [...observedLossy].sort(), appeared, closed, problems }, null, 2));
    } else {
      console.log(`input fidelity: ${maps.length} corpus maps round-tripped, ${probeRows.length} out-of-vocabulary tags probed (population the corpus does not contain).`);
      console.log(`  corpus loss:  ${corpusLoss.length === 0 ? 'none — every map preserves node/flow/lane counts' : corpusLoss.length + ' map(s) LOST content'}`);
      console.log(`  lossy tags:   ${observedLossy.size}/${probeRows.length} — ${[...observedLossy].sort().join(', ') || '(none)'}`);
      for (const p of problems) console.log(`  POPULATION:   ${p}`);
      for (const c of corpusLoss) console.log(`  LOSS ${c.map}: ${c.threw ? 'threw ' + c.threw : `in ${JSON.stringify(c.input)} out ${JSON.stringify(c.output)}`}`);
      if (appeared.length) console.log(`  FAIL: a NEW vocabulary gap appeared — ${appeared.join(', ')} now lose content on a load→save round trip. A tag the importer does not know is not rejected, it is invisible, and export writes only what state holds (T-337).`);
      if (closed.length) console.log(`  FAIL: a vocabulary gap CLOSED — ${closed.join(', ')} now survive the round trip. This is good news the guard cannot silently absorb: remove them from EXPECTED_LOSSY in this file and re-run, so the improvement is recorded rather than assumed.`);
      console.log(ok ? 'OK: the corpus round-trips losslessly, and the set of tags that lose content is exactly what was expected'
                     : 'FAIL: input fidelity moved — see above');
    }
    process.exitCode = ok ? 0 : 1;
  } catch (e) {
    console.log('FAIL: ' + String(e && e.stack || e));
    process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
