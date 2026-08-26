#!/usr/bin/env node
// _t511-unwired-node-roundtrip.mjs — does a save round-trip drop unwired flow nodes?
//
// AEF asked this at rail 11833 Q2 and re-asked it at 11874 and 11876. It is answered here
// by RUNNING the round-trip, not by reading parseBpmnXml. PL-204 was filed the same day for
// exactly the opposite habit — inferring a mechanism from an experiment run differently
// than the caller runs it — and the designer's real caller is
// `buildBpmnXml(parseBpmnXml(text))` inside the loaded page, which is what this drives.
//
// UNWIRED, defined so the answer cannot be read more broadly than it was measured:
//   a flow node with no <bpmn:incoming>, no <bpmn:outgoing>, and appearing in no
//   sequenceFlow sourceRef/targetRef.
// Two sub-cases, because they can plausibly differ and a single-case answer would
// over-claim: one node listed in a lane's flowNodeRef, one listed in no lane at all.
//
// THE NEGATIVE CONTROL IS NOT OPTIONAL (AEF, rail 11876, the same morning). "No nodes were
// dropped" and "the comparison does not work" produce identical output. So the same
// comparator is run a second time against an output with a node deliberately cut out, and
// it must report the drop. A control that cannot fail is not a control.
//
// Usage:  node tools/_t511-unwired-node-roundtrip.mjs
// Exit 0 = every unwired node survived AND the control fired; 1 = a drop or a dead
// control; 2 = misconfig.
import { spawn, execFileSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, writeFileSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = process.env.T511_CORPUS || join(REPO, 'examples', 'aef-processes', 'rendered');
const SRC = 'src/aef-workflow-designer.html';
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// ── the fixture, BUILT from a real map rather than found ──────────────────────────────
// Built so it cannot go stale as the corpus changes, and so the two unwired nodes are the
// only difference between input and baseline.
const IN_LANE = 't511_unwired_in_lane';
const NO_LANE = 't511_unwired_no_lane';
const UID_LANE = 'n_t511_lane';
const UID_NOLANE = 'n_t511_nolane';

function buildFixture(src) {
  const nodes =
`
    <bpmn:scriptTask id="${IN_LANE}" name="T-511 unwired, listed in a lane">
      <bpmn:extensionElements>
        <aef:uid value="n_t511_lane"/>
        <aef:position x="80.0" y="80.0"/>
      </bpmn:extensionElements>
    </bpmn:scriptTask>

    <bpmn:exclusiveGateway id="${NO_LANE}" name="T-511 unwired, in no lane">
      <bpmn:extensionElements>
        <aef:uid value="n_t511_nolane"/>
        <aef:position x="200.0" y="80.0"/>
      </bpmn:extensionElements>
    </bpmn:exclusiveGateway>
`;
  // Insert the nodes as process children, immediately after the laneSet closes.
  const at = src.indexOf('</bpmn:laneSet>');
  if (at < 0) throw new Error('fixture: no </bpmn:laneSet> in source map');
  let out = src.slice(0, at + '</bpmn:laneSet>'.length) + nodes + src.slice(at + '</bpmn:laneSet>'.length);
  // One of them joins a lane; the other deliberately joins none.
  const lane = out.indexOf('</bpmn:lane>');
  if (lane < 0) throw new Error('fixture: no </bpmn:lane> in source map');
  out = out.slice(0, lane) + `  <bpmn:flowNodeRef>${IN_LANE}</bpmn:flowNodeRef>\n      ` + out.slice(lane);
  return out;
}

// IDENTITY: aef:uid, NOT the element id.
//
// The first version of this probe compared element `id` and reported both nodes DROPPED
// while ids_in and ids_out were both 38 and the negative control did not fire. Those three
// facts together say the comparator was wrong, not that the nodes vanished: the exporter
// MINTS the element id from the uid (see the T-364 note at parseBpmnXml — "the uid reaches
// the emitted element id, flowNodeRef, sourceRef/targetRef"), so comparing on `id`
// measures id stability and calls a rename a deletion. Had the control been absent, a
// false "YES, we drop unwired nodes" would have gone to AEF over the rail. Their 11876
// point, arriving the same morning, is the only reason it did not.
//
// aef:uid is the stable identity across a round-trip and is what the document actually
// carries through. Element ids are reported alongside as an observation.
const UIDS_EXPR = t => `(function(){
  var AEF = 'http://anchorpoint.framework/aef/extensions';
  var d = new DOMParser().parseFromString(${JSON.stringify(t)}, 'application/xml');
  var uids = [], ids = [];
  var u = d.getElementsByTagNameNS(AEF, 'uid');
  for (var i=0;i<u.length;i++){ var v = u[i].getAttribute('value'); if (v) uids.push(v); }
  var all = d.getElementsByTagName('*');
  for (var j=0;j<all.length;j++){ var x = all[j].getAttribute && all[j].getAttribute('id'); if (x) ids.push(x); }
  return { uids: uids, ids: ids };
})()`;

async function main() {
  if (!existsSync(CORPUS)) { console.log(JSON.stringify({ ok: false, error: 'no corpus at ' + CORPUS })); process.exitCode = 2; return; }
  const files = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!files.length) { console.log(JSON.stringify({ ok: false, error: 'corpus empty — a probe with no subject is not an answer' })); process.exitCode = 2; return; }
  const srcName = basename(files[0], '.bpmn');
  const fixture = buildFixture(readFileSync(join(CORPUS, files[0]), 'utf8'));

  const doc = mkdtempSync(join(tmpdir(), 't511-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't511-repo-'));
  copyFileSync(join(REPO, SRC), join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't511-udd-'));
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

    // The round-trip, exactly as the save path runs it.
    await ev(cmd, `window.__FIX__ = ${JSON.stringify(fixture)};`);
    const exported = await ev(cmd, `(function(){ state = parseBpmnXml(window.__FIX__); refreshDisplayIds(); return buildBpmnXml(state); })()`);
    if (typeof exported !== 'string') throw new Error('round-trip produced no string');

    const IN = await ev(cmd, UIDS_EXPR(fixture));
    const OUT = await ev(cmd, UIDS_EXPR(exported));

    // The comparator, used twice: once for real, once against a mutilated output.
    const survived = uid => OUT.uids.includes(uid);
    const verdict = {
      in_lane: { uid: UID_LANE, element_id_in: IN_LANE, kind: 'bpmn:scriptTask', present_in_input: IN.uids.includes(UID_LANE), survived: survived(UID_LANE) },
      no_lane: { uid: UID_NOLANE, element_id_in: NO_LANE, kind: 'bpmn:exclusiveGateway', present_in_input: IN.uids.includes(UID_NOLANE), survived: survived(UID_NOLANE) },
    };

    // ── negative control: cut the node out of the output and re-run the comparison ────
    // Cut on the UID, which is what the comparator reads — cutting on something it does
    // not consult would prove nothing about it.
    const cut = exported.replace(new RegExp(`<aef:uid value="${UID_LANE}"\\s*/>`), '');
    const CUT = await ev(cmd, UIDS_EXPR(cut));
    const controlFired = !CUT.uids.includes(UID_LANE) && cut.length < exported.length;

    const dropped = Object.values(verdict).filter(v => v.present_in_input && !v.survived);
    const fixtureOk = Object.values(verdict).every(v => v.present_in_input);
    const ok = fixtureOk && dropped.length === 0 && controlFired;

    console.log(JSON.stringify({
      ok,
      question: 'AEF rail 11833 Q2 — does a save round-trip drop unwired flow nodes?',
      answer: !fixtureOk ? 'INCONCLUSIVE — the fixture did not contain what it claims'
            : dropped.length === 0 ? 'NO — unwired flow nodes survive buildBpmnXml(parseBpmnXml(x)) intact'
            : 'YES — see dropped[]',
      definition_of_unwired: 'no bpmn:incoming, no bpmn:outgoing, and absent from every sequenceFlow sourceRef/targetRef',
      source_map: srcName,
      verdict, dropped,
      negative_control: {
        description: 'the same comparator run against an output with the in-lane node cut out; it MUST report the drop, else "nothing was dropped" is indistinguishable from a dead comparison (AEF, rail 11876)',
        fired: controlFired,
      },
      identity_compared_on: "aef:uid — NOT element id, which the exporter mints from the uid",
      counts: { uids_in: IN.uids.length, uids_out: OUT.uids.length, ids_in: IN.ids.length, ids_out: OUT.ids.length },
      element_ids_out_for_the_two: OUT.ids.filter(function(x){ return /t511/.test(x); }),
      does_not_cover: 'edges attached to nothing, nodes inside a subProcess, and third-party documents arriving without aef:uid. Measured on one designer-produced map with two injected node kinds (a task and a gateway); cite it for that and not for round-trip fidelity generally.',
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
