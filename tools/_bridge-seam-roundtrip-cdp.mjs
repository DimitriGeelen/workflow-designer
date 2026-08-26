#!/usr/bin/env node
// _bridge-seam-roundtrip-cdp.mjs — close the SECOND half of G-002: the JS<->Python cross-seam.
//
// T-187 (tools/_roundtrip-serialization-cdp.mjs) guards the editor-INTERNAL round trip. This
// harness guards the drift that was G-002's original motivation: the Python bridge
// (tools/yaml-to-bpmn.py) and the editor (src/aef-workflow-designer.html) independently serialize
// the aef: namespace and can DISAGREE, silently dropping content on the bridge->editor import path.
// Both confirmed G-002 incidents were exactly this:
//   - T-042: editor import keyed off a different aef: namespace URI than the bridge emitted, so
//            byAef matched nothing and every aef:uid/position was silently dropped.
//   - T-053: editor read aef:decisionOutputs as an attribute while the bridge emits element text,
//            so the decision enum was lost on import.
//
// For every examples/aef-processes/*.workflow.yaml it:
//   1. runs the REAL bridge  (python3 tools/yaml-to-bpmn.py <yaml>)  -> B0 (BPMN+aef: text);
//   2. imports B0 into the REAL editor (parseBpmnXml) in isolated headless chromium;
//   3. asserts NO SILENT DROP: every aef:uid in the B0 text appears on a node/edge in the parsed
//      model, and every governance aef:meta key=value in B0 (restricted to the editor's OWN
//      metaKeys — the bridge emits a documented superset, editor metaKeys ⊆ bridge META_KEYS per
//      test_editor_bridge_meta_parity, so the extra bridge-only keys are out of scope) survives
//      into the editor's model;
//   4. asserts the editor round trip on bridge output is a semantic fixed point (buildBpmnXml ->
//      parseBpmnXml yields an equal uid-keyed projection).
//
// Self-test (preflight): mangles the aef namespace URI in a bridge emission and asserts the
// drop-detector reports missing uids — a faithful reproduction of the T-042 failure mode, proving
// the guard bites (a green that cannot go red is worthless). Empty workflow set => exit 1 (PL-022).
//
// Isolation: serves nothing (parses in-memory); drives an isolated headless chromium with its own
// --user-data-dir — never the shared browser (G-006). The editor is loaded from a temp docroot via
// gallery-serve.py only to obtain a live editor runtime; no fixture is served.
// Exit 0 = all workflows clean. Exit 1 = a drop/drift. Exit 2 = self-test failed (guard vacuous).
import { spawn, spawnSync } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const BRIDGE = join(HERE, 'yaml-to-bpmn.py');
const YAML_DIR = join(REPO, 'examples', 'aef-processes');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

function bridgeEmit(yamlPath) {
  const r = spawnSync('python3', [BRIDGE, yamlPath], { encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
  if (r.status !== 0) throw new Error('bridge failed on ' + yamlPath + ': ' + (r.stderr || '').slice(-300));
  return r.stdout;
}

// Cross-seam check for one bridge emission (B0 pre-set as window.__B0__).
const SEAM_EXPR = `(function(){
  var text = window.__B0__;
  var METAKEYS = ['tier','agentType','decisionOwner','triggeredBy','terminalKind','state','note',
    'softFail','section','guard','external','exitCode','autoTrigger','trigger','gatewayKind',
    'gate','scopeOf','horizon','workflowType','owner'];
  function unesc(s){ return s.replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"')
    .replace(/&#39;/g,"'").replace(/&apos;/g,"'").replace(/&amp;/g,'&'); }
  function extract(t){
    var uids=[], m, re=/<aef:uid value="([^"]*)"/g;
    while((m=re.exec(t))) uids.push(m[1]);
    var pairs=[], mm, mre=/<aef:meta ([^>]*)\\/>/g;
    while((mm=mre.exec(t))){ var attrs=mm[1], a, ar=/(\\w+)="([^"]*)"/g;
      while((a=ar.exec(attrs))){ if(METAKEYS.indexOf(a[1])>=0) pairs.push(a[1]+'='+unesc(a[2])); } }
    return { uids:uids, pairs:pairs };
  }
  function modelUidSet(m){ var s={}; m.nodes.forEach(function(n){if(n.uid)s[n.uid]=1;}); m.edges.forEach(function(e){if(e.uid)s[e.uid]=1;}); return s; }
  function modelMetaSet(m){ var s={}; m.nodes.forEach(function(n){var aef=n.aef||{}; METAKEYS.forEach(function(k){ if(aef[k]!=null&&aef[k]!=='') s[k+'='+String(aef[k])]=1; }); }); return s; }
  function proj(m){
    if(!m) return null;
    var laneAuth={}; (m.lanes||[]).forEach(function(l){laneAuth[l.id]=l.authority;});
    var uidOf={}; m.nodes.forEach(function(n){uidOf[n.id]=n.uid;});
    var nodes=m.nodes.map(function(n){var aef=n.aef||{},meta={};
      METAKEYS.forEach(function(k){ if(aef[k]!=null&&aef[k]!=='') meta[k]=String(aef[k]); });
      return {uid:n.uid,type:n.type,name:(n.name==null?'':n.name),lane:laneAuth[n.lane]||null,meta:meta};
    }).sort(function(a,b){return a.uid<b.uid?-1:a.uid>b.uid?1:0;});
    var edges=m.edges.map(function(e){return {uid:(e.uid==null?'':e.uid),src:uidOf[e.source]||e.source,tgt:uidOf[e.target]||e.target};})
      .sort(function(a,b){return a.uid<b.uid?-1:a.uid>b.uid?1:0;});
    return JSON.stringify({nodes:nodes,edges:edges});
  }
  try{
    var sig = extract(text);
    var m0 = parseBpmnXml(text);
    if(!m0) return { ok:false, reason:'parse-null' };
    state = m0; refreshDisplayIds();
    var mu = modelUidSet(m0), mm = modelMetaSet(m0);
    var missingUids = sig.uids.filter(function(u){ return !mu[u]; });
    var missingMeta = sig.pairs.filter(function(p){ return !mm[p]; });
    var emit1 = buildBpmnXml(state);
    var m1 = parseBpmnXml(emit1);
    if(!m1) return { ok:false, reason:'reparse-null' };
    state = m1; refreshDisplayIds();
    var fixed = proj(m0)===proj(m1);
    return {
      ok: missingUids.length===0 && missingMeta.length===0 && fixed,
      uidsB0: sig.uids.length, metaB0: sig.pairs.length,
      nodes: m0.nodes.length, edges: m0.edges.length,
      missingUids: missingUids, missingMeta: missingMeta, fixedPoint: fixed
    };
  }catch(e){ return { ok:false, reason:'exception: '+(e&&e.message||e) }; }
})()`;

// Self-test: mangle the aef namespace URI (reproduces T-042) and assert the drop-detector fires.
const SELFTEST_EXPR = `(function(){
  var text = window.__B0__;
  var uidRe=/<aef:uid value="([^"]*)"/g, m, uidsB0=[]; while((m=uidRe.exec(text))) uidsB0.push(m[1]);
  if(!uidsB0.length) return { perturbable:false, reason:'no uids in emission' };
  var bad = text.replace(/http:\\/\\/anchorpoint\\.framework\\/aef\\/extensions/g, 'http://wrong.example/aef/v0');
  if(bad===text) return { perturbable:false, reason:'namespace not found to mangle' };
  try{
    var mb = parseBpmnXml(bad);
    var mu = {}; if(mb){ mb.nodes.forEach(function(n){if(n.uid)mu[n.uid]=1;}); mb.edges.forEach(function(e){if(e.uid)mu[e.uid]=1;}); }
    var missing = uidsB0.filter(function(u){ return !mu[u]; });
    // With a wrong namespace, the editor's aef extraction must match nothing -> uids dropped.
    return { perturbable:true, detectsDrop: (mb===null) || missing.length>0, missingCount: missing.length, total: uidsB0.length };
  }catch(e){ return { perturbable:true, detectsDrop:true, note:'mangled parse threw (also a detection)' }; }
})()`;

async function main() {
  if (!existsSync(YAML_DIR)) { process.stdout.write(JSON.stringify({ pass: false, error: 'workflow dir missing: ' + YAML_DIR }) + '\n'); process.exitCode = 1; return; }
  const yamls = readdirSync(YAML_DIR).filter(f => f.endsWith('.workflow.yaml')).sort();
  if (!yamls.length) { process.stdout.write(JSON.stringify({ pass: false, error: 'no *.workflow.yaml in ' + YAML_DIR }) + '\n'); process.exitCode = 1; return; }

  // Emit all bridge BPMN up front (fail loud if the bridge itself breaks).
  const emissions = [];
  for (const y of yamls) {
    try { emissions.push({ yaml: y, b0: bridgeEmit(join(YAML_DIR, y)) }); }
    catch (e) { process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.message || e) }) + '\n'); process.exitCode = 1; return; }
  }

  const doc = mkdtempSync(join(tmpdir(), 'seam-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'seam-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'seam-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { workflows: [] };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    // Preflight self-test: prove the drop-detector catches a mangled-namespace import (T-042 class).
    await ev(cmd, `window.__B0__ = ${JSON.stringify(emissions[0].b0)};`);
    const st = await ev(cmd, SELFTEST_EXPR);
    verdict.selftest = { yaml: emissions[0].yaml, ...st };
    if (!(st && st.perturbable && st.detectsDrop)) {
      process.stdout.write(JSON.stringify({ pass: false, selftest_failed: true, error: 'drop-detector did not catch a mangled-namespace import — vacuous', selftest: verdict.selftest }, null, 2) + '\n');
      process.exitCode = 2; return;
    }

    for (const e of emissions) {
      await ev(cmd, `window.__B0__ = ${JSON.stringify(e.b0)};`);
      const r = await ev(cmd, SEAM_EXPR);
      verdict.workflows.push({ yaml: e.yaml, ...r });
    }

    verdict.pass = verdict.workflows.length > 0 && verdict.workflows.every(w => w.ok === true);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), workflows: verdict.workflows }, null, 2) + '\n');
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
