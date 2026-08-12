#!/usr/bin/env node
// _t482-scalar-projection-falsify.mjs — does projecting the eight scalar semantic keys
// actually give the round-trip fixed point teeth on each of them?
//
// WHY a separate probe rather than the harness's own self-test: the preflight self-test in
// _roundtrip-serialization-cdp.mjs perturbs the FIRST key whose attribute regex matches and
// then breaks. It reports hit:"tier" and stops. It therefore proves the MECHANISM detects
// drift; it proves nothing about any individual key added after 'tier'. A key can sit in
// METAKEYS, be skipped by the projection body as undefined, and the self-test stays green —
// which is exactly the failure mode this task rejected for aef:io.
//
// THE FALSIFICATION DESIGN, and why it is shaped this way (T-480 RCA):
// T-480's counterfactual mutated emit1a AFTER emit1b was computed, which broke the run's
// determinism flag, so the PRE-change mutant EXITED RED for a reason unrelated to the
// change. On exit status alone the reading was "your fix is redundant" and a correct fix
// would have been reverted. The rule taken from that (rail 595 §3, adopted by AEF at 597 §4):
// a counterfactual must be judged on the SPECIFIC SIGNAL the change was about, not on the
// run's exit status.
//
// So this probe does not revert code and does not touch determinism at all. For each key K:
//
//     emit1  = buildBpmnXml(parseBpmnXml(doc))      faithful emission
//     emitM  = <emit1 with K's VALUE mutated>       simulated serializer regression
//     m2     = parseBpmnXml(emitM)
//     WITHOUT K : proj(m1, KEYS minus K) === proj(m2, KEYS minus K)   must be TRUE  (blind)
//     WITH    K : proj(m1, KEYS)         === proj(m2, KEYS)           must be FALSE (caught)
//
// PRE and POST differ ONLY by the presence of K in the projection list. Same run, same
// parse, same emission, one variable. There is no exit code to misread and no second signal
// the mutation could contaminate.
//
// DENOMINATOR (PL-084): a key absent from the whole corpus cannot be falsified, and reporting
// it as "projected" would be vacuity dressed as coverage. Every key's corpus population is
// counted and reported. A key with population 0 is reported as UNFALSIFIABLE, not as a pass.
//
// Exit 0 iff every key with a non-zero population is blind WITHOUT it and catching WITH it.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const sleep = ms => new Promise(r => setTimeout(r, ms));

// The eight keys T-482 added. Their presence in BOTH copies of the harness list is pinned
// structurally by a P-011 leg, so this probe may name them without re-deriving the list.
const KEYS = ['contextReads', 'artifactsWrites', 'decisionInput', 'decisionOutputs',
              'workflowRef', 'name', 'targetWorkflow', 'linkId'];

// How each key appears on the wire, so the mutation hits the value and nothing else.
// element  : <aef:K>value</aef:K>
// ownattr  : <aef:K paths="value"/>            (its own element, value in an attribute)
// linkattr : <aef:link ... K="value" .../>     (an attribute of the shared aef:link element)
const WIRE = {
  contextReads:    { kind: 'ownattr',  attr: 'paths' },
  artifactsWrites: { kind: 'ownattr',  attr: 'paths' },
  decisionInput:   { kind: 'element' },
  decisionOutputs: { kind: 'element' },
  workflowRef:     { kind: 'linkattr' },
  name:            { kind: 'linkattr' },
  targetWorkflow:  { kind: 'linkattr' },
  linkId:          { kind: 'linkattr' },
};

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Parameterised projection. Deliberately mirrors proj() in the harness for the meta axis
// only: this probe asks one question — does meta register a change in aef[k] — so node
// identity plus the meta bag is the whole comparison surface.
const PROJ_FN = `
  function projWith(m, keys){
    if(!m) return null;
    return JSON.stringify(m.nodes.map(function(n){
      var aef = n.aef || {}, meta = {};
      keys.forEach(function(k){ if(aef[k]!=null && aef[k]!=='') meta[k]=String(aef[k]); });
      return { uid:n.uid, type:n.type, meta:meta };
    }).sort(function(a,b){ return a.uid<b.uid?-1:a.uid>b.uid?1:0; }));
  }`;

const CENSUS_EXPR = keys => `(function(){
  try{
    ${PROJ_FN}
    var m1 = parseBpmnXml(window.__DOC__);
    if(!m1) return { ok:false, reason:'parse-null' };
    state = m1; refreshDisplayIds();
    var emit1 = buildBpmnXml(state);
    var pop = {};
    ${JSON.stringify(keys)}.forEach(function(k){
      var c = 0;
      m1.nodes.forEach(function(n){ var a = n.aef||{}; if(a[k]!=null && a[k]!=='') c++; });
      if(c) pop[k] = c;
    });
    return { ok:true, pop:pop, emit:emit1, nodes:m1.nodes.length };
  }catch(e){ return { ok:false, reason:'exception: '+(e&&e.message||e) }; }
})()`;

// Runs ONE key's falsification inside the page. emitM is supplied already mutated, so the
// page does parse+project only — the mutation itself is done in node, in plain sight.
const FALSIFY_EXPR = (allKeys, k) => `(function(){
  try{
    ${PROJ_FN}
    var ALL = ${JSON.stringify(allKeys)};
    var WITHOUT = ALL.filter(function(x){ return x !== ${JSON.stringify(k)}; });
    var m1 = parseBpmnXml(window.__DOC__);
    var m2 = parseBpmnXml(window.__EMITM__);
    if(!m1 || !m2) return { ok:false, reason:'parse-null' };
    return {
      ok: true,
      withoutKey: projWith(m1, WITHOUT) === projWith(m2, WITHOUT),
      withKey:    projWith(m1, ALL)     === projWith(m2, ALL)
    };
  }catch(e){ return { ok:false, reason:'exception: '+(e&&e.message||e) }; }
})()`;

// Mutate exactly one occurrence of key K's value in the emitted XML. Returns null when the
// key is not on the wire in this document — a null is reported, never silently skipped.
function mutate(xml, k) {
  const w = WIRE[k];
  if (w.kind === 'element') {
    const re = new RegExp('(<aef:' + k + '>)([\\s\\S]*?)(</aef:' + k + '>)');
    if (!re.test(xml)) return null;
    return xml.replace(re, '$1__T482_DRIFT__$3');
  }
  if (w.kind === 'ownattr') {
    const re = new RegExp('(<aef:' + k + '\\s[^>]*?' + w.attr + '=")([^"]*)(")');
    if (!re.test(xml)) return null;
    return xml.replace(re, '$1__T482_DRIFT__$3');
  }
  // linkattr: constrain the match to inside a single <aef:link .../> element so a
  // same-named attribute elsewhere in the document cannot be the thing we mutate.
  const re = new RegExp('(<aef:link\\s[^>]*?\\b' + k + '=")([^"]*)(")');
  if (!re.test(xml)) return null;
  return xml.replace(re, '$1__T482_DRIFT__$3');
}

function collectDocs() {
  const roots = [join(REPO, 'examples'), join(REPO, 'tests', 'fixtures', 'aef-bpmn')];
  const found = [];
  const walk = d => { if (!existsSync(d)) return; for (const e of readdirSync(d, { withFileTypes: true })) { const p = join(d, e.name); if (e.isDirectory()) walk(p); else if (e.name.endsWith('.bpmn')) found.push(p); } };
  roots.forEach(walk);
  return found.sort();
}

async function main() {
  const docs = collectDocs();
  if (!docs.length) { console.log(JSON.stringify({ pass: false, error: 'no corpus documents — verdict would be vacuous' })); process.exitCode = 1; return; }

  const doc = mkdtempSync(join(tmpdir(), 't482-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't482-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't482-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl;
  const verdict = { corpus: docs.length, population: {}, keys: {}, unfalsifiable: [], failures: [] };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) { } await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    // Pass 1 — census. Which keys exist in the corpus at all, and where can each be falsified?
    const site = {};   // key -> { doc, emit }
    for (const p of docs) {
      const rel = p.replace(REPO + '/', '');
      const text = readFileSync(p, 'utf8');
      await ev(cmd, `window.__DOC__ = ${JSON.stringify(text)};`);
      const r = await ev(cmd, CENSUS_EXPR(KEYS));
      if (!r || !r.ok) { verdict.failures.push({ doc: rel, error: (r && r.reason) || 'no result' }); continue; }
      for (const k of Object.keys(r.pop)) {
        verdict.population[k] = (verdict.population[k] || 0) + r.pop[k];
        if (!site[k] && mutate(r.emit, k)) site[k] = { doc: rel, text, emit: r.emit };
      }
    }

    // Pass 2 — falsify each key that has a site, on the specific signal.
    for (const k of KEYS) {
      const pop = verdict.population[k] || 0;
      if (!pop || !site[k]) {
        verdict.unfalsifiable.push({ key: k, population: pop, reason: pop ? 'present but not mutable on the wire' : 'absent from corpus' });
        continue;
      }
      const emitM = mutate(site[k].emit, k);
      await ev(cmd, `window.__DOC__ = ${JSON.stringify(site[k].emit)};`);
      await ev(cmd, `window.__EMITM__ = ${JSON.stringify(emitM)};`);
      const r = await ev(cmd, FALSIFY_EXPR(KEYS, k));
      if (!r || !r.ok) { verdict.keys[k] = { error: (r && r.reason) || 'no result' }; verdict.failures.push({ key: k, error: (r && r.reason) || 'no result' }); continue; }
      const good = r.withoutKey === true && r.withKey === false;
      verdict.keys[k] = { population: pop, site: site[k].doc, blindWithout: r.withoutKey, caughtWith: r.withKey === false, verdict: good ? 'FALSIFIED-BOTH-WAYS' : 'INCONCLUSIVE' };
      if (!good) verdict.failures.push({ key: k, withoutKey: r.withoutKey, withKey: r.withKey });
    }

    verdict.pass = verdict.failures.length === 0 && Object.keys(verdict.keys).length > 0;
    verdict.summary = `${docs.length} docs; ${Object.keys(verdict.keys).length}/${KEYS.length} keys falsified both ways; ${verdict.unfalsifiable.length} unfalsifiable`;
    console.log(JSON.stringify(verdict, null, 2));
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ pass: false, error: String(e && e.message || e) }, null, 2));
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) { }
    try { br.kill(); } catch (_) { }
    try { py.kill(); } catch (_) { }
  }
}
main();
