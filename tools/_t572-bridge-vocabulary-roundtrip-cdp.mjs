#!/usr/bin/env node
// _t572-bridge-vocabulary-roundtrip-cdp.mjs — every key our BRIDGE can emit survives an
// editor load→save round trip. Measured in the page, against the editor's behaviour.
//
// WHAT THIS REPLACES, AND WHY A SET COMPARISON COULD NOT DO IT.
// tests/test_editor_bridge_meta_parity.py asserts editor_metaKeys ⊆ bridge_META_KEYS. Its
// docstring does not merely omit the other direction — it ARGUES the other direction is safe:
//   "the bridge legitimately emits more keys than the editor authors, e.g. determinism/
//    endpoint/sideEffect; those flow bridge→editor via the generic absorption, so the reverse
//    direction is not a data-loss risk."
// "Not a data-loss risk" is a claim about a ROUND TRIP, and it was checked against the READ
// side alone. Import is generic (src:10255) — that half is true and visible in the source.
// Export was not: it filtered through a 20-key whitelist, so a key was absorbed on load and
// DESTROYED on save. The docstring named three of the nine casualties as its reassurance.
// The guard returned [] the whole time (PL-034: a guard checking internal self-consistency
// cannot detect a broken promise).
//
// T-570 made the claim true by giving export generic carriage. NOTHING HOLDS IT THAT WAY.
// Revert the carriage and the ⊆ test goes green again while nine keys die on every save.
// That is precisely the condition mutant A reproduces, and this probe is what reddens under it.
//
// THE FIXTURE IS DERIVED, NOT WRITTEN. Keys come from the bridge's own META_KEYS at run time,
// through the parity test's extractor (one extractor, not a second regex that can drift from
// it). A hand-written fixture pins today's 29 keys and is silent on the 30th — the T-570
// lesson exactly: a census over what the corpus happens to carry measures the SAMPLE, while
// the producer's vocabulary is the POPULATION. Mutant B is the tooth for this: it adds a key
// to META_KEYS that appears nowhere in this file, and the probe must cover it with no edit.
//
// EVERY NODE TYPE, NOT ONE. A key with a dedicated emitter on some type is skipped from
// <aef:meta> for that type (src:9550 scalarHandled), so carriage proven on a serviceTask is
// not carriage proven on a gateway or an end event. The fixture instantiates one node per
// BPMN element type the editor accepts and judges each independently.
//
// MEASURED AT node.aef AFTER RE-PARSE, NOT AT THE ATTRIBUTE. `endpoint` round-trips as
// <aef:endpoint> rather than as a meta attribute and is not lost — asserting "comes back as a
// meta attribute" would report a defect that is not there. The property is survival of the
// VALUE, and the channel is the editor's business.
//
// EXEMPT is empty and that is asserted (leg 6). Measured over all 29 keys × 12 distinct editor
// types: zero losses, zero value changes. A future key that legitimately cannot round-trip must
// be written into EXEMPT with its reason — a silent exclusion is the shape this guard removes.
//
// --src <path> / --bridge <path> run against alternate builds so the teeth harness can mutate
// copies in a tmpdir. Exit 0 = all legs pass, 1 = a leg failed, 2 = misconfigured (NOT a pass).
import { spawn, execFileSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const arg = (flag, dflt) => { const i = process.argv.indexOf(flag); return i > -1 ? process.argv[i + 1] : dflt; };
const EDITOR = arg('--src', join(REPO, 'src', 'aef-workflow-designer.html'));
const BRIDGE = arg('--bridge', join(REPO, 'tools', 'yaml-to-bpmn.py'));
const PARITY = join(REPO, 'tests', 'test_editor_bridge_meta_parity.py');

const sleep = ms => new Promise(r => setTimeout(r, ms));
let npass = 0, nfail = 0;
const leg = (ok, name, detail) => { ok ? npass++ : nfail++; console.log(`${ok ? 'PASS' : 'FAIL'}  ${name} — ${detail}`); };
const die = m => { console.log('CANNOT RUN: ' + m); process.exit(2); };

// ── the vocabulary, from the producer, via the parity test's own extractor ──────────────────
// Importing the extractor rather than re-implementing it means the two guards cannot disagree
// about what the bridge's vocabulary IS while disagreeing about whether it survives.
let KEYS;
try {
  KEYS = JSON.parse(execFileSync('python3', ['-c',
    'import importlib.util,json,sys\n' +
    'sp=importlib.util.spec_from_file_location("p",sys.argv[1])\n' +
    'm=importlib.util.module_from_spec(sp); sp.loader.exec_module(m)\n' +
    'print(json.dumps(m.bridge_meta_keys(open(sys.argv[2],encoding="utf-8").read())))',
    PARITY, BRIDGE], { encoding: 'utf8' }).trim());
} catch (e) { die('could not extract META_KEYS from ' + BRIDGE + ': ' + e.message); }
if (!Array.isArray(KEYS) || KEYS.length < 20) die('extracted ' + JSON.stringify(KEYS) + ' from META_KEYS — refusing to run on a vocabulary that small');

// Keys that legitimately do NOT round-trip verbatim, each with the reason it is exempt.
// EMPTY, and leg 6 asserts it stays that way: an exemption has to be written down.
const EXEMPT = {};

// The 20 keys the editor's own metaKeys whitelist named before T-570. Hard-coded ON PURPOSE:
// leg 2 reproduces the PRE-fix export rule in the page and needs the historical list, not
// today's. Sourcing it from src/ would make the control arm track the code it is controlling.
const PRE_T570_METAKEYS = ['tier', 'agentType', 'decisionOwner', 'triggeredBy', 'terminalKind',
  'state', 'note', 'softFail', 'section', 'guard', 'external', 'exitCode', 'autoTrigger',
  'trigger', 'gatewayKind', 'gate', 'scopeOf', 'horizon', 'workflowType', 'owner'];

// Newline is the character that matters most: XML attribute-value normalisation collapses a
// literal \n to a space, so a byte-identical newline proves escAttr ran, not just that the
// key was copied.
const HARD = 'a & b < c "quoted"\nsecond line';
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;').replace(/\n/g, '&#10;');
const VAL = {};
for (const k of KEYS) VAL[k] = 'v-' + k;
// The hostile value rides the first key that is NOT on the historical metaKeys whitelist, so
// leg 5 exercises the CARRIAGE path rather than the path that already worked before T-570.
// Not KEYS[0]: that is whichever key happens to sit first in the bridge's tuple, and a mutant
// which adds a key to the front of META_KEYS would silently move the hostile value onto the
// key it is about to destroy — measured, by a teeth run that reddened this leg for that reason
// and not for the one it claimed. Order still decides among the carried keys, but every
// candidate is a carried key, which is the property leg 5 is about.
const HARD_KEY = KEYS.find(k => !PRE_T570_METAKEYS.includes(k));
if (!HARD_KEY) die('no bridge key outside the pre-T-570 whitelist — nothing for leg 5 to exercise');
VAL[HARD_KEY] = HARD;
const attrs = KEYS.map(k => `${k}="${esc(VAL[k])}"`).join(' ');

// One node per BPMN element type the editor accepts. Several collapse onto the same internal
// type (manualTask→serviceTask, inclusiveGateway→exclusiveGateway, callActivity→serviceTask);
// that is the editor's business and the probe judges whatever types come back.
const TYPES = ['startEvent', 'userTask', 'serviceTask', 'scriptTask', 'manualTask', 'businessRuleTask',
  'exclusiveGateway', 'parallelGateway', 'inclusiveGateway', 'eventBasedGateway',
  'intermediateCatchEvent', 'intermediateThrowEvent', 'endEvent', 'subProcess', 'callActivity'];

const FIXTURE = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:aef="http://anchorpoint.framework/aef/extensions" id="d1" targetNamespace="http://x">
  <bpmn:process id="Process_t572" isExecutable="false">
${TYPES.map((t, i) => `    <bpmn:${t} id="N${i}" name="Node${i}">
      <bpmn:extensionElements>
        <aef:uid value="u-t572-${i}"/>
        <aef:position x="${200 + i * 160}.0" y="140.0"/>
        <aef:meta ${attrs}/>
      </bpmn:extensionElements>
    </bpmn:${t}>`).join('\n')}
  </bpmn:process>
  <bpmndi:BPMNDiagram id="Di_1"><bpmndi:BPMNPlane id="Pl_1" bpmnElement="Process_t572">
${TYPES.map((t, i) => `    <bpmndi:BPMNShape id="S_N${i}" bpmnElement="N${i}"><dc:Bounds x="${200 + i * 160}" y="140" width="120" height="64"/></bpmndi:BPMNShape>`).join('\n')}
  </bpmndi:BPMNPlane></bpmndi:BPMNDiagram>
</bpmn:definitions>`;

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 20000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

if (!existsSync(EDITOR)) die('missing editor ' + EDITOR);
if (!existsSync(SERVER)) die('missing server ' + SERVER);

const doc = mkdtempSync(join(tmpdir(), 'd572-')), repoDir = mkdtempSync(join(tmpdir(), 'r572-')), udd = mkdtempSync(join(tmpdir(), 'u572-'));
let py = null, br = null, cl = null;
try {
  copyFileSync(EDITOR, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  writeFileSync(join(doc, 'rendered', 't.bpmn'), FIXTURE);
  mkdirSync(join(repoDir, 'examples', 'aef-processes', 'rendered'), { recursive: true });

  const port = await freePort();
  py = spawn('python3', [SERVER, String(port), '--repo', repoDir, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let up = false;
  for (let i = 0; i < 80 && !up; i++) { try { up = (await fetch(BASE + '/api/health')).ok; } catch (_) { } if (!up) await sleep(100); }
  if (!up) die('gallery-serve did not come up on ' + BASE);
  const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
  // OBS-304: the page target is not listed the instant DevTools answers; poll rather than
  // index [0] into a list that is still empty.
  let page = null;
  for (let i = 0; i < 40 && !page; i++) { try { page = (await (await fetch(`http://127.0.0.1:${dp}/json`)).json()).find(t => t.type === 'page'); } catch (_) { } if (!page) await sleep(150); }
  if (!page) die('no CDP page target after 40 attempts');
  cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
  const { cmd } = cl;
  await cmd('Page.enable'); await cmd('Runtime.enable');
  await cmd('Page.navigate', { url: BASE + '/designer.html?load=' + encodeURIComponent('rendered/t.bpmn') });
  const t0 = Date.now();
  for (; ;) {
    const ok = await ev(cmd, `(typeof buildBpmnXml==='function'&&typeof parseBpmnXml==='function'&&_appReady===true)`).catch(() => false);
    if (ok) break;
    if (Date.now() - t0 > 25000) die('editor never became ready');
    await sleep(150);
  }
  await sleep(400);

  // One snapshot for every leg, so no leg can observe state a previous leg mutated.
  const snap = await ev(cmd, `(function(){
    function byUid(l,u){ return (l||[]).find(function(x){ return x.uid===u; }); }
    var n0 = byUid(state.nodes, 'u-t572-0');
    if (!n0) return { err: 'fixture absent; uids = ' + JSON.stringify((state.nodes||[]).map(function(x){return x.uid;})) };
    var xml = buildBpmnXml(state);
    var st2 = parseBpmnXml(xml);
    var rows = [];
    for (var i = 0; i < ${TYPES.length}; i++) {
      var u = 'u-t572-' + i, a = byUid(state.nodes, u), b = byUid(st2.nodes, u);
      rows.push({ uid: u, type: a ? a.type : null, present: !!a,
                  imported: a ? JSON.parse(JSON.stringify(a.aef || {})) : null,
                  after: b ? JSON.parse(JSON.stringify(b.aef || {})) : null });
    }
    // The PRE-T-570 export rule, reproduced verbatim on the first node. Control arm: it must
    // LOSE what the shipped path keeps, or the fixture never reached the defect at all.
    var pre = ${JSON.stringify(PRE_T570_METAKEYS)};
    var impKeys = Object.keys(n0.aef || {}).filter(function(k){ return n0.aef[k] !== '' && n0.aef[k] != null; });
    var oldRule = pre.filter(function(k){ return impKeys.indexOf(k) > -1; });
    return { rows: rows, oldRule: oldRule, importedKeys: impKeys, nodeCount: (state.nodes||[]).length };
  })()`);
  if (snap.err) die(snap.err);

  const primary = snap.rows.find(r => r.uid === 'u-t572-0');
  const survives = (row, k) => row.after && Object.prototype.hasOwnProperty.call(row.after, k) && row.after[k] === VAL[k];

  // ── leg 1: the fixture is the producer's whole vocabulary, not a sample of it ─────────────
  // Positive form on purpose (T-560): "no hard-coded key list here" is an absence assertion
  // that passes just as readily when mis-written. This asserts the derived keys ARRIVED —
  // every key the extractor returned was carried into the document the editor actually loaded.
  {
    const missing = KEYS.filter(k => !Object.prototype.hasOwnProperty.call(primary.imported || {}, k));
    leg(missing.length === 0 && KEYS.length >= 20,
      'vocabulary-derived',
      `${KEYS.length} keys read from the bridge's META_KEYS reached node.aef on import` +
      (missing.length ? `; MISSING ${JSON.stringify(missing)}` : ''));
  }

  // ── leg 2: control arm — the pre-fix rule loses the keys the shipped path keeps ───────────
  {
    const lostByOld = KEYS.filter(k => snap.importedKeys.includes(k) && !snap.oldRule.includes(k));
    leg(lostByOld.length > 0,
      'reproduce-drop',
      `pre-T-570 metaKeys filter drops ${lostByOld.length} of the bridge's keys ` +
      `${JSON.stringify(lostByOld.slice(0, 9))} — the fixture reaches the defect`);
  }

  // ── leg 3: every key survives on the primary node ─────────────────────────────────────────
  {
    const lost = KEYS.filter(k => !survives(primary, k) && !(k in EXEMPT));
    leg(lost.length === 0, 'roundtrip-every-key',
      `${KEYS.length - lost.length}/${KEYS.length} bridge keys survive parse→build→parse` +
      (lost.length ? `; LOST ${JSON.stringify(lost)}` : ''));
  }

  // ── leg 4: and on every node type, not just the one that was convenient ───────────────────
  {
    const bad = [];
    for (const r of snap.rows) {
      if (!r.present) { bad.push([r.uid, 'node absent after import']); continue; }
      const lost = KEYS.filter(k => !survives(r, k) && !(k in EXEMPT));
      if (lost.length) bad.push([r.type, lost]);
    }
    const types = [...new Set(snap.rows.map(r => r.type))];
    leg(bad.length === 0 && snap.rows.length === TYPES.length,
      'roundtrip-every-type',
      `${snap.rows.length} nodes → ${types.length} distinct editor types, all keys intact` +
      (bad.length ? `; PROBLEMS ${JSON.stringify(bad)}` : ''));
  }

  // ── leg 5: the value, not merely the key ─────────────────────────────────────────────────
  {
    const got = primary.after ? primary.after[HARD_KEY] : undefined;
    leg(got === HARD, 'hostile-value',
      `${HARD_KEY}: ampersand, angle, quote and newline round-trip ` +
      (got === HARD ? 'byte-identical' : `MANGLED — got ${JSON.stringify(got)}`));
  }

  // ── leg 6: exemptions are declared, never silent ──────────────────────────────────────────
  // The old guard's failure was an undeclared gap that read as coverage. If a key ever earns
  // an exemption it must appear in EXEMPT with a reason, and this leg makes that visible in
  // the run output rather than buried in a filter expression.
  {
    const names = Object.keys(EXEMPT);
    const undocumented = names.filter(k => !EXEMPT[k] || String(EXEMPT[k]).length < 20);
    leg(undocumented.length === 0, 'no-silent-exemptions',
      names.length === 0
        ? 'EXEMPT is empty — every one of the bridge\'s keys is held to the round trip'
        : `${names.length} exempt, each with a reason: ${JSON.stringify(names)}` +
          (undocumented.length ? `; UNDOCUMENTED ${JSON.stringify(undocumented)}` : ''));
  }

  console.log(`\n${npass} passed, ${nfail} failed`);
} finally {
  try { cl && cl.close(); } catch (_) { }
  try { br && br.kill(); } catch (_) { }
  try { py && py.kill(); } catch (_) { }
  await sleep(400);
  for (const d of [doc, repoDir, udd]) { try { rmSync(d, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 }); } catch (_) { } }
}
process.exit(nfail === 0 ? 0 : 1);
