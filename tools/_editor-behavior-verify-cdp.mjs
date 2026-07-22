#!/usr/bin/env node
// _editor-behavior-verify-cdp.mjs — G-010 standing editor BEHAVIOR suite (T-238).
//
// WHY: T-234 (jump-autosave poisoning) and T-237 (eventDef/linkEventCatch collision)
// were both field-found by the AEF peer — the editor's load/persistence behavior paths
// and import classification paths had no standing tests (gap G-010, concerns.yaml).
// This suite encodes the two blockers' verification matrices as a repeatable harness:
//
//   T-234 legs (live editor, hermetic sidecar server):
//     1. jump-no-poison — open ?load=X, jumpToWorkflow(Y) (in-place map switch),
//        autosave fires ⇒ record carries src:null (NOT X's deep-link src);
//        revisiting ?load=X renders X. The pre-fix editor rendered Y here.
//     2. same-map-edit-restore — ?load=X, mutate, reload ?load=X ⇒ mutation
//        restored via the suppressed re-fetch path (the legitimate branch the
//        T-234 fix had to keep working — _loadSrcKey is re-adopted).
//
//   T-237 legs (in-page parseBpmnXml → buildBpmnXml, uid-keyed):
//     3. throw+eventDef — intermediateThrowEvent carrying <aef:eventDef> must NOT
//        mutate to a catch tag on re-export (pre-fix: unscoped override rewrote it);
//        the eventDef payload is DROPPED on re-export (recorded T-237 decision:
//        invalid hybrid, tag preservation wins) — asserted to lock the decision in.
//     4. link-wins — catch + aef:link workflowRef + eventDef ⇒ linkEventCatch with
//        the ref preserved (jump affordance must not hide).
//     5. bare-catch — no extensions ⇒ linkEventCatch (ratified default, 832's call).
//     6. typed-catch — catch + eventDef kind=message, no link target ⇒ eventMessage
//        with busTopic binding, re-export carries <aef:eventDef kind="message">.
//
// ISOLATION (G-006 + read-only-by-construction): the editor is served from a temp
// docroot by a throwaway gallery-serve.py on a free port with a temp --repo, in an
// isolated headless chromium. The suite cannot touch the real registry, versions
// store, or shared browser. localStorage is cleared between legs (T-237 verify
// lesson: autosave restore masks fresh-fetch behavior otherwise).
// Exit 0 = all legs pass; 1 = a leg failed; 2 = misconfig (missing editor/server).
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
// argv[2]: optional editor override — used by the teeth check (run against a pre-fix
// editor build and assert the suite FAILS; see T-238 Verification).
const EDITOR = process.argv[2] || join(REPO, 'src', 'aef-workflow-designer.html');
const RENDERED = join(REPO, 'examples', 'aef-processes', 'rendered');
const MAP_X = 'arc-lifecycle.bpmn';    // deep-link map (the "X" of the T-234 repro)
const MAP_Y = 'audit-process';         // jump target (resolved via /api/list)
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof jumpToWorkflow==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// T-237 classification fixture — one map, four probe nodes, uid-keyed. The XML shape
// mirrors the saved-map dialect (claim-smoke lineage): aef namespace + laneMeta + aef:uid.
const T237_FIXTURE = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:aef="http://anchorpoint.framework/aef/extensions"
                  id="Definitions_t237-probe"
                  targetNamespace="https://aef.anchorpoint.dev/workflows">
  <bpmn:collaboration id="Collaboration_t237-probe">
    <bpmn:participant id="Pool_t237-probe" name="t237-probe" processRef="Process_t237-probe"/>
  </bpmn:collaboration>
  <bpmn:process id="Process_t237-probe" isExecutable="true">
    <bpmn:extensionElements>
      <aef:workflowMeta id="t237-probe" version="1" schemaVersion="2" title="t237-probe" tier_default="2"/>
    </bpmn:extensionElements>
    <bpmn:laneSet id="LaneSet_1">
      <bpmn:lane id="framework" name="Framework · Authority">
        <bpmn:extensionElements>
          <aef:laneMeta abbr="frw" authority="authority" height="200"/>
        </bpmn:extensionElements>
        <bpmn:flowNodeRef>frw_1_thr</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>frw_2_cl</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>frw_3_bare</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>frw_4_typed</bpmn:flowNodeRef>
      </bpmn:lane>
    </bpmn:laneSet>
    <bpmn:intermediateThrowEvent id="frw_1_thr" name="throw with eventDef">
      <bpmn:extensionElements>
        <aef:uid value="n_thr"/>
        <aef:position x="100" y="80"/>
        <aef:eventDef kind="message" binding="bus:throw-probe"/>
      </bpmn:extensionElements>
    </bpmn:intermediateThrowEvent>
    <bpmn:intermediateCatchEvent id="frw_2_cl" name="catch with link and eventDef">
      <bpmn:extensionElements>
        <aef:uid value="n_cl"/>
        <aef:position x="220" y="80"/>
        <aef:link workflowRef="1f9b5f0c-0be4-4cfe-9158-d9e6f0c1d4c7" name="aef-task-lifecycle"/>
        <aef:eventDef kind="message" binding="bus:link-probe"/>
      </bpmn:extensionElements>
    </bpmn:intermediateCatchEvent>
    <bpmn:intermediateCatchEvent id="frw_3_bare" name="bare catch">
      <bpmn:extensionElements>
        <aef:uid value="n_bare"/>
        <aef:position x="340" y="80"/>
      </bpmn:extensionElements>
    </bpmn:intermediateCatchEvent>
    <bpmn:intermediateCatchEvent id="frw_4_typed" name="typed message catch">
      <bpmn:extensionElements>
        <aef:uid value="n_typed"/>
        <aef:position x="460" y="80"/>
        <aef:eventDef kind="message" binding="bus:typed-probe"/>
      </bpmn:extensionElements>
    </bpmn:intermediateCatchEvent>
  </bpmn:process>
</bpmn:definitions>`;

const T237_ASSERT = `(function(){
  var errs = [];
  try {
    var m = parseBpmnXml(window.__T237__);
    if (!m) return { ok:false, errs:['parse-null'] };
    var by = {}; m.nodes.forEach(function(n){ by[n.uid] = n; });
    // (3) throw+eventDef: tag must NOT mutate to catch — parses as linkEventThrow
    if (!by.n_thr) errs.push('n_thr missing');
    else if (by.n_thr.type !== 'linkEventThrow') errs.push('n_thr type '+by.n_thr.type+' != linkEventThrow (throw->catch mutation?)');
    // (4) link wins over eventDef when the link has a target
    if (!by.n_cl) errs.push('n_cl missing');
    else {
      if (by.n_cl.type !== 'linkEventCatch') errs.push('n_cl type '+by.n_cl.type+' != linkEventCatch (link must win)');
      if ((by.n_cl.aef||{}).workflowRef !== '1f9b5f0c-0be4-4cfe-9158-d9e6f0c1d4c7') errs.push('n_cl workflowRef lost: '+JSON.stringify((by.n_cl.aef||{}).workflowRef));
    }
    // (5) bare catch = linkEventCatch (ratified default)
    if (!by.n_bare) errs.push('n_bare missing');
    else if (by.n_bare.type !== 'linkEventCatch') errs.push('n_bare type '+by.n_bare.type+' != linkEventCatch');
    // (6) typed catch: eventDef with no link target drives the type + binding
    if (!by.n_typed) errs.push('n_typed missing');
    else {
      if (by.n_typed.type !== 'eventMessage') errs.push('n_typed type '+by.n_typed.type+' != eventMessage');
      if ((by.n_typed.aef||{}).busTopic !== 'bus:typed-probe') errs.push('n_typed busTopic '+JSON.stringify((by.n_typed.aef||{}).busTopic)+' != bus:typed-probe');
    }
    // Re-export assertions on the emitted XML
    state = m; refreshDisplayIds();
    var emit = buildBpmnXml(state);
    var throws = (emit.match(/<bpmn:intermediateThrowEvent /g) || []).length;
    if (throws !== 1) errs.push('emit has '+throws+' intermediateThrowEvent tags, want exactly 1 (n_thr must stay a throw)');
    // recorded T-237 decision: throw+eventDef is an invalid hybrid — payload drops on re-export
    if (emit.indexOf('bus:throw-probe') >= 0) errs.push('emit still carries the throw-side eventDef payload (decision: dropped)');
    if (emit.indexOf('<aef:eventDef kind="message" binding="bus:typed-probe"/>') < 0) errs.push('emit lost the typed-catch <aef:eventDef>');
    if (emit.indexOf('workflowRef="1f9b5f0c-0be4-4cfe-9158-d9e6f0c1d4c7"') < 0) errs.push('emit lost the link workflowRef');
    return { ok: errs.length===0, errs: errs };
  } catch (e) { return { ok:false, errs:['exception: '+(e&&e.message||e)] }; }
})()`;

async function main() {
  if (!existsSync(EDITOR)) { process.stdout.write(JSON.stringify({ ok: false, error: 'editor missing: ' + EDITOR }) + '\n'); process.exitCode = 2; return; }
  if (!existsSync(SERVER)) { process.stdout.write(JSON.stringify({ ok: false, error: 'server missing: ' + SERVER }) + '\n'); process.exitCode = 2; return; }
  for (const f of [MAP_X, MAP_Y + '.bpmn']) if (!existsSync(join(RENDERED, f))) { process.stdout.write(JSON.stringify({ ok: false, error: 'rendered map missing: ' + f }) + '\n'); process.exitCode = 2; return; }

  const doc = mkdtempSync(join(tmpdir(), 'ebv-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'ebv-repo-'));
  copyFileSync(EDITOR, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(RENDERED, MAP_X), join(doc, 'rendered', MAP_X));
  copyFileSync(join(RENDERED, MAP_Y + '.bpmn'), join(doc, 'rendered', MAP_Y + '.bpmn'));
  // the sidecar lists maps from <repo>/examples/aef-processes/rendered — mirror them there
  const repoRendered = join(repo, 'examples', 'aef-processes', 'rendered');
  mkdirSync(repoRendered, { recursive: true });
  copyFileSync(join(RENDERED, MAP_X), join(repoRendered, MAP_X));
  copyFileSync(join(RENDERED, MAP_Y + '.bpmn'), join(repoRendered, MAP_Y + '.bpmn'));

  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'ebv-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { legs: [], pass: false };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    const nav = async url => { await cmd('Page.navigate', { url }); await waitReady(cmd); await sleep(350); };
    const LOAD_X = BASE + '/designer.html?load=' + encodeURIComponent('rendered/' + MAP_X);

    // ── Leg 1: jump-no-poison (the T-234 repro, post-fix expectations) ──
    await nav(BASE + '/designer.html');
    await ev(cmd, `localStorage.clear()`);
    await nav(LOAD_X);
    const atX = await ev(cmd, `({id: state.workflowMeta.id, nodes: state.nodes.length})`);
    await ev(cmd, `jumpToWorkflow(${JSON.stringify(MAP_Y)})`);
    await sleep(400);
    const atY = await ev(cmd, `({id: state.workflowMeta.id, nodes: state.nodes.length})`);
    // mutate on Y so the debounced autosave fires with Y as the active document
    await ev(cmd, `(function(){ var n=state.nodes[0]; n.y=(n.y||100)+37; renderAll(); return n.id; })()`);
    await sleep(1100);
    const rec = await ev(cmd, `(function(){ try { var s=JSON.parse(localStorage.getItem('aefAutosaveDoc')||'null'); return s?{id:s.id, src:('src' in s)?s.src:'<absent>'}:null; } catch(e){ return {err:String(e)}; } })()`);
    await nav(LOAD_X);
    const backAtX = await ev(cmd, `({id: state.workflowMeta.id, nodes: state.nodes.length})`);
    const leg1 = atX.id === 'arc-lifecycle' && atX.nodes > 0
      && atY.id === MAP_Y && atY.nodes > 0
      && !!rec && rec.id === MAP_Y && (rec.src === null || rec.src === undefined)
      && backAtX.id === 'arc-lifecycle' && backAtX.nodes === atX.nodes;
    verdict.legs.push({ leg: 'jump-no-poison', pass: leg1, got: { atX, atY, autosave: rec, backAtX } });

    // ── Leg 2: same-map edit-restore (the legitimate branch the fix must keep) ──
    await ev(cmd, `localStorage.clear()`);
    await nav(LOAD_X);
    const mut = await ev(cmd, `(function(){ var n=state.nodes[0]; n.y=(n.y||100)+41; renderAll(); return {nodeId:n.id, y:n.y}; })()`);
    await sleep(1100);
    await nav(LOAD_X);
    const rest = await ev(cmd, `(function(){ var n=state.nodes.filter(function(x){return x.id===${JSON.stringify(mut.nodeId)};})[0]; return {id: state.workflowMeta.id, y: n?n.y:null}; })()`);
    const leg2 = rest.id === 'arc-lifecycle' && rest.y === mut.y;
    verdict.legs.push({ leg: 'same-map-edit-restore', pass: leg2, got: { mut, rest } });

    // ── Legs 3-6: T-237 classification contract (in-page parse → build) ──
    await ev(cmd, `localStorage.clear()`);
    await nav(BASE + '/designer.html');
    await ev(cmd, `window.__T237__ = ${JSON.stringify(T237_FIXTURE)};`);
    const t237 = await ev(cmd, T237_ASSERT);
    verdict.legs.push({ leg: 't237-classification', pass: !!(t237 && t237.ok), got: t237 });

    verdict.pass = verdict.legs.every(l => l.pass);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, error: String(e && e.stack || e), legs: verdict.legs }, null, 2) + '\n');
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
