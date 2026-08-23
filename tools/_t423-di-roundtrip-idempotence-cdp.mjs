#!/usr/bin/env node
/**
 * _t423-di-roundtrip-idempotence-cdp.mjs — export -> re-import -> export must be
 * byte-identical, on every corpus map.
 *
 * T-423's AC states the reason and it is an authoring-tool reason, not a purity one:
 * "a DI emitter that is not idempotent makes every save a spurious diff." Open a document,
 * change nothing, save: if the second export differs from the first, every save the author
 * makes carries noise they did not write, and review of those files stops being possible.
 *
 * WHY THIS IS NOT THE SAME MEASUREMENT AS _t308-export-byte-identity-cdp.mjs, which also
 * says "identical" a lot. That gate compares the working tree's export of a map against a
 * PINNED GIT REF's export of the SAME INPUT — it answers "did my change move the bytes?"
 * and its input is always the original corpus file. This one never leaves the current
 * build and feeds the exporter its OWN OUTPUT. A designer can be perfectly stable against
 * a git ref while being unstable against itself; the two gates cannot substitute for each
 * other and the corpus is the only thing they share.
 *
 * WHY IT IS NOT _t308's SELF-STABILITY LEG EITHER (G-023/T-364), which exports the same map
 * twice and compares. That proves the exporter is deterministic given one parse. It says
 * nothing about whether the PARSER can read back what the exporter just wrote. The defect
 * this probe is built to catch lives exactly in that gap: the emitter writes a construct the
 * importer absorbs into a different model field, and the second export renders it somewhere
 * else. Both exports are individually deterministic and the round trip still drifts.
 *
 * WHAT MAKES IT LOAD-BEARING NOW. Yesterday DI became unconditional, so every export carries
 * bpmndi:BPMNShape/dc:Bounds and bpmndi:BPMNEdge/di:waypoint — constructs the corpus inputs
 * do NOT carry. So this is the first slice in which the exporter's output is meaningfully
 * different in shape from its input, and idempotence stopped being inherited from "the
 * output looks like the input" and became a property that has to be measured.
 *
 * Usage: node tools/_t423-di-roundtrip-idempotence-cdp.mjs
 * Exit 0 = E1 === E2 on every map, with at least one map actually measured.
 *      1 = drift (each drifting map named, with the first differing line on both sides).
 *      2 = misconfig, a map that would not parse or re-parse, or nothing to measure.
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = process.env.T423_CORPUS || join(REPO, 'examples', 'aef-processes', 'rendered');
// Overridable so the teeth can point this at a DELIBERATELY non-idempotent designer. A gate
// whose green has never been watched turning red is a gate nobody has any grounds to trust,
// and this one came back 24/24 on its very first run — the least informative kind of pass
// there is. Without this override the only way to make it fail would be to break the real
// source in the working tree, which is how a "temporary" mutation gets committed.
const SRC = process.env.T423_SRC || join(REPO, 'src/aef-workflow-designer.html');

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// The round trip, in the browser. E1 = export(parse(original)); E2 = export(parse(E1)).
// A THIRD generation is taken deliberately. If E1 != E2 the interesting question is
// immediately "does it converge or does it keep moving?" — a one-shot absorption that
// settles (E2 === E3) is a different defect from an emitter that drifts on every save, and
// they want different fixes. Measuring it here costs one extra parse and saves a whole
// diagnostic round trip later.
const ROUND_EXPR = `(function(){
  var out = {};
  var maps = window.__MAPS__;
  // Each generation is attempted SEPARATELY so a failure names WHICH one broke. The first
  // draft wrapped all three in one try, and its teeth caught the cost: when the exporter was
  // mutated to emit malformed XML, the thrown parse error was reported verbatim and read
  // exactly like a corpus map that was bad on arrival. "The input is broken" and "WE broke
  // our own output" are opposite findings and they were printing the same line.
  function once(t, gen){
    var m;
    try { m = parseBpmnXml(t); }
    catch(e) { throw new Error(gen + ' would not parse: ' + String(e && e.message || e)); }
    if(!m) throw new Error(gen + ' would not parse (parser returned null)');
    state = m; refreshDisplayIds(); return buildBpmnXml(state);
  }
  for (var i=0;i<maps.length;i++){
    var n = maps[i].name;
    try {
      var e1 = once(maps[i].text, 'the original corpus map');
      var e2 = once(e1, 'OUR OWN EXPORT');
      var e3 = once(e2, 'the second-generation export');
      out[n] = {e1: e1, e2: e2, stable23: e2 === e3, len1: e1.length, len2: e2.length};
    } catch(e) { out[n] = {err: String(e && e.message || e)}; }
  }
  return out;
})()`;

function firstDiff(a, b) {
  const A = a.split('\n'), B = b.split('\n');
  for (let i = 0; i < Math.max(A.length, B.length); i++) {
    if (A[i] !== B[i]) {
      return { line: i + 1,
               e1: A[i] === undefined ? '(absent — export 1 is shorter)' : A[i].trim().slice(0, 150),
               e2: B[i] === undefined ? '(absent — export 2 is shorter)' : B[i].trim().slice(0, 150) };
    }
  }
  return null;
}

async function main() {
  const files = existsSync(CORPUS) ? readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort() : [];
  if (!files.length) { console.log(`REFUSE — no .bpmn in ${CORPUS}`); return 2; }

  const doc = mkdtempSync(join(tmpdir(), 't423rt-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't423rt-repo-'));
  if (!existsSync(SRC)) { console.log(`REFUSE — designer source missing: ${SRC}`); return 2; }
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't423rt-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, res = null;
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    const maps = files.map(f => ({ name: f, text: readFileSync(join(CORPUS, f), 'utf8') }));
    await ev(cmd, `window.__MAPS__ = ${JSON.stringify(maps)};`);
    res = await ev(cmd, ROUND_EXPR);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  const broken = [], drifted = [];
  let identical = 0, converging = 0;
  for (const f of files) {
    const r = res && res[f];
    // A map that could not be measured is NOT a map that round-tripped. Named, counted,
    // and fatal — an error bucket that quietly shrinks the population is how a gate's
    // coverage evaporates while its verdict stays green (T-364's lesson on this harness
    // family).
    if (!r || r.err) { broken.push(`${f}: ${r && r.err || 'no output'}`); continue; }
    if (r.e1 === r.e2) { identical++; continue; }
    const d = firstDiff(r.e1, r.e2);
    drifted.push({ f, d, stable23: r.stable23, len1: r.len1, len2: r.len2 });
    if (r.stable23) converging++;
  }

  console.log(`  maps: ${files.length}   identical: ${identical}   drifted: ${drifted.length}   unmeasurable: ${broken.length}`);
  if (broken.length) {
    console.log('\nREFUSE — map(s) could not complete the round trip:');
    for (const b of broken) console.log('  ' + b);
    return 2;
  }
  if (identical === 0 && drifted.length === 0) {
    console.log('\nREFUSE — nothing was measured; an empty comparison is not a clean one');
    return 2;
  }
  if (drifted.length) {
    console.log(`\nFAIL — ${drifted.length} map(s) are not idempotent under export -> re-import -> export`);
    console.log(`  of those, ${converging} CONVERGE by generation 3 (one-shot absorption) and ` +
                `${drifted.length - converging} keep moving (every save drifts)`);
    for (const x of drifted.slice(0, 6)) {
      console.log(`\n  ${x.f}  (${x.len1} -> ${x.len2} bytes, converges: ${x.stable23})`);
      if (x.d) {
        console.log(`    first difference at line ${x.d.line}`);
        console.log(`      export 1: ${x.d.e1}`);
        console.log(`      export 2: ${x.d.e2}`);
      }
    }
    if (drifted.length > 6) console.log(`\n  … and ${drifted.length - 6} more`);
    return 1;
  }
  console.log(`\nPASS — export -> re-import -> export is byte-identical on all ${identical} map(s)`);
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
