#!/usr/bin/env node
// _roundtrip-serialization-cdp.mjs — close G-002: prove the editor↔bridge aef: serialization
// seam is a SEMANTIC FIXED POINT, exercised through the REAL editor runtime (not a proxy).
//
// The 7 existing seam guards are static/text checks that each cover one aspect (meta-parity,
// field-coverage, structured-parity, extension-shape, namespace, mapping-conformance,
// forward-fixtures). None runs a true round trip. Only the editor JS can parse BPMN back into a
// re-emittable model (parseBpmnXml @ src/aef-workflow-designer.html:7959; buildBpmnXml @ :7830) —
// the Python bridge (tools/yaml-to-bpmn.py) is emit-only. So a genuine round trip is reachable
// only by driving the editor in a browser, which is what this harness does.
//
// For every tests/fixtures/aef-bpmn/*.bpmn it runs, IN THE REAL EDITOR:
//     m1    = parseBpmnXml(fixture)
//     emit1 = buildBpmnXml(state=m1)            // real import path: set state, refreshDisplayIds
//     m2    = parseBpmnXml(emit1)
//     emit2 = buildBpmnXml(state=m2)
// and asserts the SEMANTIC PROJECTION of m1 equals that of m2 — a fixed point on the
// governance-bearing content: aef:uid multiset (every flow node + every sequenceFlow), each
// node's aef:meta key→value map, node type + name, per-node lane authority, the edge
// source→target set (keyed by uid, so display-id churn is invisible), and workflowMeta.
// Presentational data (position, waypoints, routing hints — v1 §1 presentational class) is
// deliberately EXCLUDED: a diagram that differs only presentationally must round-trip identically
// in the semantic projection, which is exactly the property child-2's forward compile relies on.
//
// Gate (exit 0) requires, for every fixture:
//   - parse1 and parse2 both non-null;
//   - every node and every edge in m1 carries an aef:uid (identity hinge);
//   - buildBpmnXml is deterministic (emit(state)===emit(state));
//   - proj(m1) === proj(m2)  (the semantic fixed point).
// byteIdempotent (emit1===emit2, the stricter string-level fixed point) is REPORTED in the
// verdict but NOT gated — legitimate presentational churn can break bytes without semantic drift.
//
// Isolation: serves the editor from a TEMP docroot via gallery-serve.py on a free port, and
// drives it in an ISOLATED headless chromium with its own --user-data-dir — never the shared
// browser (G-006). Empty/missing fixtures dir ⇒ exit 1, not a vacuous pass (PL-022).
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXturesDir = join(REPO, 'tests', 'fixtures', 'aef-bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

// Self-test: perturb ONE governance attribute in the emission and confirm the projection
// comparison detects the drift. Proves the guard bites — a green that cannot go red is worthless
// (PL-022 stance; mirrors test_forward_fixtures.py::_selftest). Returns {perturbable, detectsDrift}.
const PREFLIGHT_EXPR = `(function(){
  var text = window.__FIXTURE__;
  var METAKEYS = ['tier','agentType','decisionOwner','triggeredBy','terminalKind','state','note',
    'softFail','section','guard','external','exitCode','autoTrigger','trigger','gatewayKind',
    'gate','scopeOf','horizon','workflowType','owner',
    // T-480: 'endpoint' must appear in BOTH copies of this list. If the preflight
    // self-test does not project it, the guard below asserts a property its own
    // teeth-proof never exercises. See the note at the second copy for why endpoint
    // is projected at all.
    'endpoint',
    // T-482: keep in step with the guard copy below. Same eight scalar keys; see the
    // long note there for why aef:io is deliberately absent from both.
    'contextReads','artifactsWrites','decisionInput','decisionOutputs',
    'workflowRef','name','targetWorkflow','linkId'];
  function proj(m){
    if(!m) return null;
    var uidOf={}; m.nodes.forEach(function(n){ uidOf[n.id]=n.uid; });
    var nodes=m.nodes.map(function(n){ var aef=n.aef||{},meta={};
      METAKEYS.forEach(function(k){ if(aef[k]!=null&&aef[k]!=='') meta[k]=String(aef[k]); });
      return {uid:n.uid,meta:meta}; }).sort(function(a,b){return a.uid<b.uid?-1:a.uid>b.uid?1:0;});
    return JSON.stringify(nodes);
  }
  try{
    var m1=parseBpmnXml(text); if(!m1) return {perturbable:false,reason:'parse-null'};
    state=m1; refreshDisplayIds();
    var emit1=buildBpmnXml(state);
    // Flip the first governance attr we can find to a sentinel value.
    var mutated=emit1, hit=null;
    for(var i=0;i<METAKEYS.length;i++){
      var re=new RegExp('('+METAKEYS[i]+'=")([^"]*)(")');
      if(re.test(emit1)){ mutated=emit1.replace(re,'$1__DRIFT__$3'); hit=METAKEYS[i]; break; }
    }
    if(hit===null) return {perturbable:false,reason:'no governance attr in emission'};
    var m2=parseBpmnXml(mutated); if(!m2) return {perturbable:true,detectsDrift:true,note:'mutation broke parse (also a detection)'};
    state=m2; refreshDisplayIds();
    return { perturbable:true, hit:hit, detectsDrift: proj(m1)!==proj(m2) };
  }catch(e){ return {perturbable:false,reason:'exception: '+(e&&e.message||e)}; }
})()`;
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// The round-trip, executed inside the editor for one fixture (text pre-set as window.__FIXTURE__).
const ROUNDTRIP_EXPR = `(function(){
  var text = window.__FIXTURE__;
  // aef scalar keys projected per node. The first group are <aef:meta> attributes
  // (buildBpmnXml metaKeys); the T-204 trailing group are the typed-event binding
  // fields (which ride <aef:eventDef binding=…>, not <aef:meta>) — included here so
  // the semantic fixed point has teeth on the binding value, not just node.type.
  var METAKEYS = ['tier','agentType','decisionOwner','triggeredBy','terminalKind','state','note',
    'softFail','section','guard','external','exitCode','autoTrigger','trigger','gatewayKind',
    'gate','scopeOf','horizon','workflowType','owner',
    'errorStatus','timerSpec','busTopic',
    // T-480 (closes OBS-041): 'endpoint' is projected DESPITE the frozen standard
    // listing aef:endpoint in its PRESENTATIONAL class. That listing is wrong and is
    // registered as OBS-039: aef:endpoint carries the executable command a task node
    // runs (e.g. "fw context build --task <task_id> --depth 2"), emitted beside
    // aef:contextReads / aef:artifactsWrites, and the bridge lists it in META_KEYS.
    //
    // (This comment lives INSIDE a JS template literal: no backticks, no dollar-brace.
    //  The first form used both and the harness died before evaluating anything —
    //  the same class as the P-011 leg eval-expansion caught an hour earlier.)
    //
    // DO NOT REMOVE THIS KEY to make the harness conform to the standard. That is
    // exactly how it went missing: the projection excludes presentational content by
    // design, so following §1 faithfully left the executable command unguarded on this
    // axis. T-479 measured no loss today (155 endpoints / 30 docs / 0 lossy) — this
    // keeps a future drop from being silent. If a v1.2 reclassifies aef:endpoint as
    // semantic, this comment becomes redundant, not wrong.
    //
    // NOTE: endpoint rides a STANDALONE <aef:endpoint> element, not an <aef:meta>
    // attribute — it is in this list because proj() reads n.aef[k] off the parsed
    // model, where parseBpmnXml puts it (src:9957-9958), not because it is meta.
    'endpoint',
    // T-482: the remaining SCALAR semantic keys carried by standalone aef elements.
    // Parsed at src:9959-9979, emitted at src:9287-9308. Same reason as endpoint:
    // proj() reads n.aef[k], so what matters is that parseBpmnXml lands the value on
    // the model, not whether the wire form is an aef:meta attribute.
    //
    // The first four ride their own elements (aef:contextReads, aef:artifactsWrites,
    // aef:decisionInput, aef:decisionOutputs). The last four are the aef:link binding
    // attributes, which parse into four SEPARATE scalar keys — there is no aef.link.
    // workflowRef is the off-page seam binding (S2/T-225); losing it silently on a
    // round trip would unbind a cross-workflow jump with no error anywhere.
    //
    // NOT projected here, deliberately: aef:io. It is built from the inputs/outputs
    // ARRAYS (src:9337-9345) and there is no aef.io scalar, so listing it would read
    // as coverage while the projection body skipped it as undefined — a green that
    // cannot go red. It needs a structured projection, filed as its own task.
    'contextReads','artifactsWrites','decisionInput','decisionOutputs',
    'workflowRef','name','targetWorkflow','linkId',
    // T-204 Slice 2: boundary attachment is governance-bearing — hostRef (the resolved
    // host uid) and interrupting (cancelActivity) must survive the fixed point. boundaryPos
    // is presentational (like position/waypoints) and is deliberately NOT projected.
    'hostRef','interrupting'];
  function proj(m){
    if(!m) return null;
    var laneAuth = {}; (m.lanes||[]).forEach(function(l){ laneAuth[l.id]=l.authority; });
    var uidOf = {}; m.nodes.forEach(function(n){ uidOf[n.id]=n.uid; });
    var nodes = m.nodes.map(function(n){
      var aef=n.aef||{}, meta={};
      METAKEYS.forEach(function(k){ if(aef[k]!=null && aef[k]!=='') meta[k]=String(aef[k]); });
      return { uid:n.uid, type:n.type, name:(n.name==null?'':n.name), lane:laneAuth[n.lane]||null, meta:meta };
    }).sort(function(a,b){ return a.uid<b.uid?-1:a.uid>b.uid?1:0; });
    var edges = m.edges.map(function(e){
      return { uid:(e.uid==null?'':e.uid), src:uidOf[e.source]||e.source, tgt:uidOf[e.target]||e.target,
               name:(e.name||null), condition:(e.condition||null) };
    }).sort(function(a,b){ return a.uid<b.uid?-1:a.uid>b.uid?1:0; });
    var lanes = (m.lanes||[]).map(function(l){ return { id:l.id, authority:l.authority, abbr:(l.abbr||null) }; })
      .sort(function(a,b){ return a.id<b.id?-1:a.id>b.id?1:0; });
    return { nodes:nodes, edges:edges, lanes:lanes,
             wm:{ id:m.workflowMeta.id, tier_default:(m.workflowMeta.tier_default||null),
                  version:(m.workflowMeta.version||null), title:(m.workflowMeta.title||null) } };
  }
  try{
    var m1 = parseBpmnXml(text);
    if(!m1) return { ok:false, reason:'parse1-null' };
    state = m1; refreshDisplayIds();
    var emit1a = buildBpmnXml(state);
    var emit1b = buildBpmnXml(state);
    var m2 = parseBpmnXml(emit1a);
    if(!m2) return { ok:false, reason:'parse2-null' };
    state = m2; refreshDisplayIds();
    var emit2 = buildBpmnXml(state);
    var p1 = proj(m1), p2 = proj(m2);
    var missingNodeUid = m1.nodes.filter(function(n){return !n.uid;}).length;
    var missingEdgeUid = m1.edges.filter(function(e){return !e.uid;}).length;
    var deterministic = (emit1a===emit1b);
    var projEqual = (JSON.stringify(p1)===JSON.stringify(p2));
    // localise the first semantic drift, if any, for diagnosis
    var drift = null;
    if(!projEqual){
      var s1=JSON.stringify(p1,null,0), s2=JSON.stringify(p2,null,0);
      var i=0; while(i<s1.length && i<s2.length && s1[i]===s2[i]) i++;
      drift = { at:i, a:s1.slice(Math.max(0,i-40), i+40), b:s2.slice(Math.max(0,i-40), i+40) };
    }
    return {
      ok: projEqual && deterministic && missingNodeUid===0 && missingEdgeUid===0,
      nodes:m1.nodes.length, edges:m1.edges.length, lanes:(m1.lanes||[]).length,
      missingNodeUid:missingNodeUid, missingEdgeUid:missingEdgeUid,
      deterministic:deterministic, projEqual:projEqual,
      byteIdempotent:(emit1a===emit2), len1:emit1a.length, len2:emit2.length,
      drift:drift
    };
  }catch(e){ return { ok:false, reason:'exception: '+(e&&e.message||e) }; }
})()`;

async function main() {
  // Fixture corpus is the subject of the test — absence/emptiness is a FAILURE (PL-022).
  if (!existsSync(FIXturesDir)) { process.stdout.write(JSON.stringify({ pass: false, error: 'fixtures dir missing: ' + FIXturesDir }) + '\n'); process.exitCode = 1; return; }
  const fixtures = readdirSync(FIXturesDir).filter(f => f.endsWith('.bpmn')).sort();
  if (!fixtures.length) { process.stdout.write(JSON.stringify({ pass: false, error: 'no *.bpmn fixtures in ' + FIXturesDir }) + '\n'); process.exitCode = 1; return; }

  const doc = mkdtempSync(join(tmpdir(), 'rt-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'rt-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'rt-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { fixtures: [] };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    // Preflight self-test: prove the projection guard detects an injected governance drift.
    let proven = false, preflight = null;
    for (const name of fixtures) {
      const text = readFileSync(join(FIXturesDir, name), 'utf8');
      await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(text)};`);
      const r = await ev(cmd, PREFLIGHT_EXPR);
      if (r && r.perturbable) { preflight = { fixture: name, ...r }; if (r.detectsDrift) proven = true; break; }
    }
    verdict.selftest = preflight;
    if (!proven) {
      process.stdout.write(JSON.stringify({ pass: false, selftest_failed: true, error: 'guard did not detect an injected governance drift — vacuous', selftest: preflight }, null, 2) + '\n');
      process.exitCode = 2; return;
    }

    for (const name of fixtures) {
      const text = readFileSync(join(FIXturesDir, name), 'utf8');
      await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(text)};`);
      const r = await ev(cmd, ROUNDTRIP_EXPR);
      verdict.fixtures.push({ fixture: name, ...r });
    }

    verdict.pass = verdict.fixtures.length > 0 && verdict.fixtures.every(f => f.ok === true);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), fixtures: verdict.fixtures }, null, 2) + '\n');
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    try { rmSync(repo, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
