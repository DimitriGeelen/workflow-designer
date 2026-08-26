#!/usr/bin/env node
// _t483-structured-projection-falsify.mjs — do the STRUCTURED semantic values have teeth in
// the round-trip fixed point, and is the obvious patch actually blind?
//
// T-482 projected the eight SCALAR aef keys. It deliberately excluded aef:io, because io is
// not an aef.X scalar. Measuring that exclusion properly turned up six more structured
// values in the same blind spot: emits, compensates (string arrays), aggregation,
// multiInstance, timer (dicts), constituents (array of dicts). Seven in total with io.
//
// THE POINT OF THIS PROBE IS THE THIRD COLUMN.
// The obvious way to "close" the gap is to append these names to METAKEYS, whose projection
// body is String(aef[k]). For a dict that yields the CONSTANT "[object Object]" — a value
// that compares equal to itself for every possible mutation. The key would appear in the
// projection, the list would read as complete, and the guard would be exactly as blind as
// before. That is worse than the gap: an absent key is a known hole, a constant-valued key
// is a hole that reports itself closed.
//
// So for each value this measures THREE projections against the same mutated emission:
//
//   none    key excluded entirely           expect EQUAL     (the pre-fix blindness)
//   string  key projected via String()      dicts: EQUAL     (the naive patch, blind)
//   struct  key projected via canon()       expect DIFFERENT (the actual fix, catching)
//
// PRE and POST differ by one variable — how the key is projected. Same parse, same emission,
// no code reverted, no exit code consulted (T-480 RCA / rail 595 §3, adopted by AEF 597 §4).
//
// DENOMINATOR (PL-084): each value's corpus population is counted and printed. A value with
// population zero is reported UNFALSIFIABLE, never counted as a pass.
//
// Exit 0 iff every value with a non-zero population is blind under 'none' and catching under
// 'struct'. The 'string' column is REPORTED, not gated — it is evidence for the design
// choice, and a dict that somehow became detectable through String() would be a finding
// worth reading rather than a failure worth blocking.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const sleep = ms => new Promise(r => setTimeout(r, ms));

// value -> how to mutate ONE occurrence of it in the emitted XML.
// kind 'childattr': <aef:WRAP><aef:ITEM ATTR="v"/></aef:WRAP>
// kind 'selfattr' : <aef:WRAP ATTR="v"/>          (first attribute carries the payload)
// kind 'io'       : <aef:io><aef:input name=".." type="v"/>...
const VALUES = [
  { key: 'emits',         kind: 'childattr', item: 'emit',        attr: 'value', dict: false },
  { key: 'compensates',   kind: 'childattr', item: 'compensate',  attr: 'ref',   dict: false },
  { key: 'constituents',  kind: 'childattr', item: 'constituent', attr: 'name',  dict: false },
  { key: 'aggregation',   kind: 'selfattr',                                      dict: true  },
  { key: 'multiInstance', kind: 'selfattr',                                      dict: true  },
  { key: 'timer',         kind: 'selfattr',                                      dict: true  },
  { key: 'io',            kind: 'io',                                            dict: true  },
];

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// NOTE: every string below is built with ordinary concatenation, never a template literal.
// The comments inside these page expressions killed this harness twice (T-480, and again in
// T-483 while writing this file) because a backtick or a dollar-brace inside a comment that
// lives in a template literal terminates the literal. Concatenation removes the hazard.
const HELPERS =
  " function canon(v){ if(v===null||typeof v!=='object') return v;" +
  "   if(Object.prototype.toString.call(v)==='[object Array]') return v.map(canon);" +
  "   var o={}; Object.keys(v).sort().forEach(function(k){ o[k]=canon(v[k]); }); return o; }" +
  " function valOf(n,k){ return k==='io' ? (n.io||null) : ((n.aef||{})[k]); }" +
  " function projMode(m,mode,key){" +
  "   if(!m) return null;" +
  "   return JSON.stringify(m.nodes.map(function(n){" +
  "     var cell=null; var v=valOf(n,key);" +
  "     if(mode==='string'){ cell = (v==null? null : String(v)); }" +
  "     else if(mode==='struct'){ cell = (v==null? null : canon(v)); }" +
  "     return { uid:n.uid, cell:cell };" +
  "   }).sort(function(a,b){ return a.uid<b.uid?-1:a.uid>b.uid?1:0; })); }";

const CENSUS_EXPR = keys =>
  "(function(){ try{" + HELPERS +
  "  var m1=parseBpmnXml(window.__DOC__); if(!m1) return {ok:false,reason:'parse-null'};" +
  "  state=m1; refreshDisplayIds(); var emit1=buildBpmnXml(state);" +
  "  var pop={}; " + JSON.stringify(keys) + ".forEach(function(k){ var c=0;" +
  "    m1.nodes.forEach(function(n){ var v=valOf(n,k);" +
  "      if(v==null) return;" +
  "      if(k==='io'){ if(((v.inputs||[]).length)||((v.outputs||[]).length)) c++; return; }" +
  "      if(Object.prototype.toString.call(v)==='[object Array]'){ if(v.length) c++; return; }" +
  "      if(typeof v==='object'){ if(Object.keys(v).length) c++; return; }" +
  "      c++; });" +
  "    if(c) pop[k]=c; });" +
  "  return {ok:true,pop:pop,emit:emit1};" +
  "}catch(e){ return {ok:false,reason:'exception: '+(e&&e.message||e)}; } })()";

const FALSIFY_EXPR = key =>
  "(function(){ try{" + HELPERS +
  "  var K=" + JSON.stringify(key) + ";" +
  "  var m1=parseBpmnXml(window.__DOC__), m2=parseBpmnXml(window.__EMITM__);" +
  "  if(!m1||!m2) return {ok:false,reason:'parse-null'};" +
  "  return { ok:true," +
  "    none:   projMode(m1,'none',K)   === projMode(m2,'none',K)," +
  "    string: projMode(m1,'string',K) === projMode(m2,'string',K)," +
  "    struct: projMode(m1,'struct',K) === projMode(m2,'struct',K) };" +
  "}catch(e){ return {ok:false,reason:'exception: '+(e&&e.message||e)}; } })()";

const D = '__T483_DRIFT__';

// Mutate exactly one occurrence. Returns null when the value is not on the wire here.
function mutate(xml, v) {
  if (v.kind === 'childattr') {
    const re = new RegExp('(<aef:' + v.item + '\\s[^>]*?' + v.attr + '=")([^"]*)(")');
    if (!re.test(xml)) return null;
    return xml.replace(re, '$1' + D + '$3');
  }
  if (v.kind === 'selfattr') {
    // first attribute value inside the element's own tag
    const re = new RegExp('(<aef:' + v.key + '\\s+[a-zA-Z:_-]+=")([^"]*)(")');
    if (!re.test(xml)) return null;
    return xml.replace(re, '$1' + D + '$3');
  }
  // io: mutate an input/output type, which is pure payload
  const re = new RegExp('(<aef:(?:input|output)\\s[^>]*?type=")([^"]*)(")');
  if (!re.test(xml)) return null;
  return xml.replace(re, '$1' + D + '$3');
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
  const KEYS = VALUES.map(v => v.key);

  const doc = mkdtempSync(join(tmpdir(), 't483-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't483-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't483-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl;
  const verdict = { corpus: docs.length, population: {}, values: {}, unfalsifiable: [], naivePatchBlind: [], failures: [] };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) { } await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    const site = {};
    for (const p of docs) {
      const rel = p.replace(REPO + '/', '');
      await ev(cmd, `window.__DOC__ = ${JSON.stringify(readFileSync(p, 'utf8'))};`);
      const r = await ev(cmd, CENSUS_EXPR(KEYS));
      if (!r || !r.ok) { verdict.failures.push({ doc: rel, error: (r && r.reason) || 'no result' }); continue; }
      for (const k of Object.keys(r.pop)) {
        verdict.population[k] = (verdict.population[k] || 0) + r.pop[k];
        const v = VALUES.find(x => x.key === k);
        if (!site[k] && mutate(r.emit, v)) site[k] = { doc: rel, emit: r.emit };
      }
    }

    for (const v of VALUES) {
      const pop = verdict.population[v.key] || 0;
      if (!pop || !site[v.key]) {
        verdict.unfalsifiable.push({ key: v.key, population: pop, reason: pop ? 'present but not mutable on the wire' : 'absent from corpus' });
        continue;
      }
      const emitM = mutate(site[v.key].emit, v);
      await ev(cmd, `window.__DOC__ = ${JSON.stringify(site[v.key].emit)};`);
      await ev(cmd, `window.__EMITM__ = ${JSON.stringify(emitM)};`);
      const r = await ev(cmd, FALSIFY_EXPR(v.key));
      if (!r || !r.ok) { verdict.failures.push({ key: v.key, error: (r && r.reason) || 'no result' }); continue; }
      const good = r.none === true && r.struct === false;
      verdict.values[v.key] = {
        population: pop, site: site[v.key].doc, dictValued: v.dict,
        blindWhenExcluded: r.none,
        blindUnderStringPatch: r.string,
        caughtByStructural: r.struct === false,
        verdict: good ? 'FALSIFIED-BOTH-WAYS' : 'INCONCLUSIVE',
      };
      if (r.string === true) verdict.naivePatchBlind.push(v.key);
      if (!good) verdict.failures.push({ key: v.key, none: r.none, struct: r.struct });
    }

    verdict.pass = verdict.failures.length === 0 && Object.keys(verdict.values).length > 0;
    verdict.summary = `${docs.length} docs; ${Object.keys(verdict.values).length}/${VALUES.length} values falsified both ways; ` +
      `${verdict.naivePatchBlind.length} would stay BLIND under the String() patch (${verdict.naivePatchBlind.join(',') || 'none'}); ` +
      `${verdict.unfalsifiable.length} unfalsifiable`;
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
