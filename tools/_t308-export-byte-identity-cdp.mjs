#!/usr/bin/env node
// _t308-export-byte-identity-cdp.mjs — prove a designer change has ZERO export
// surface: for every corpus map, buildBpmnXml(parseBpmnXml(map)) must be
// byte-identical between the working-tree designer and the designer at a given
// git ref.
//
// Written for T-308 (T-244 GO, path b), whose load-bearing claim is that neutral
// rendering of bare catch events changes what the reader SEES and not one
// exported byte — no schema change, no dialect change, nothing for AEF to ratify.
// Kept as a general utility: any presentation-only change can be held to the same
// standard by pointing it at the ref before the change.
//
// Usage:  node tools/_t308-export-byte-identity-cdp.mjs [git-ref]     (default HEAD)
// Exit 0 = byte-identical for every map; 1 = drift (the drifting maps are named);
// 2 = misconfig.
import { spawn, execFileSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, writeFileSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
// T-364: overridable so the `unusable` path can be exercised against a temp corpus
// (tools/_t364-t308-teeth.py) without mutating the real one. A bucket whose count is
// the finding has to be shown fillable before its emptiness means anything.
const CORPUS = process.env.T308_CORPUS || join(REPO, 'examples', 'aef-processes', 'rendered');
const REF = process.argv[2] || 'HEAD';
const SRC = 'src/aef-workflow-designer.html';
// T-663: overridable OLD-side build, same purpose and same shape as T308_CORPUS above.
// The `unusable` bucket can only be shown fillable by feeding this gate something that
// is not byte-stable with itself, and after T-364 no real DOCUMENT is: the parse->build
// path has no remaining nondeterminism, so the instability has to come from a build.
// (The one live mint, workflowMeta uuid at adoptImportedXml, is on the open wrapper this
// gate does not call — see the teeth docstring.)
//
// A result produced with this override is NOT a gate result, so it declares itself in
// the JSON (`srcOverride`) rather than looking like one. That is G-023's own rule turned
// on this tool: report what you ranged over in the same breath as the verdict.
const OLD_SRC = process.env.T308_OLD_SRC || null;
// One label for the old side, used by BOTH the verdict and the per-map `unstableIn`
// attribution. Reporting "unstable in HEAD" while the build actually came from an
// override would misname which build carries the defect — the exact confusion this
// gate exists to prevent, reintroduced in its own output.
const OLD_LABEL = OLD_SRC ? `T308_OLD_SRC:${OLD_SRC}` : REF;
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }
const sha = s => createHash('sha256').update(s, 'utf8').digest('hex').slice(0, 16);

// Export each corpus map through the loaded designer, returning uid→sha of the
// emitted bytes. Rendering is deliberately NOT invoked: this measures the
// serialization path only, which is exactly the surface that must not move.
// G-023 / T-364: each map is exported TWICE in the same build. A cross-build byte
// comparison is only evidence where a build is byte-stable WITH ITSELF, and this
// gate had no way to know it wasn't. `aef:uid` is minted per parse for any node that
// arrives without one, so third-party documents are not stable and can never be
// compared this way — they are absent from the corpus rather than failing in it, and
// the absence read as coverage for the whole arc. Self-stability is now measured, and
// an unstable document is reported `unusable`: never counted identical, never silent.
const EXPORT_EXPR = `(function(){
  var out = {};
  var maps = window.__MAPS__;
  function once(t){ state = parseBpmnXml(t); refreshDisplayIds(); return buildBpmnXml(state); }
  for (var i=0;i<maps.length;i++){
    try {
      var a = once(maps[i].text);
      var b = once(maps[i].text);
      out[maps[i].name] = { xml: a, selfStable: a === b };
    } catch(e) { out[maps[i].name] = { xml: 'ERROR: ' + (e && e.message || e), selfStable: false }; }
  }
  return out;
})()`;

async function exportAll(cmd, url, maps) {
  await cmd('Page.navigate', { url });
  await waitReady(cmd); await sleep(200);
  await ev(cmd, `window.__MAPS__ = ${JSON.stringify(maps)};`);
  return await ev(cmd, EXPORT_EXPR);
}

async function main() {
  if (!existsSync(CORPUS)) { console.log(JSON.stringify({ ok: false, error: 'no corpus at ' + CORPUS })); process.exitCode = 2; return; }
  const files = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!files.length) { console.log(JSON.stringify({ ok: false, error: 'corpus empty' })); process.exitCode = 2; return; }
  const maps = files.map(f => ({ name: basename(f, '.bpmn'), text: readFileSync(join(CORPUS, f), 'utf8') }));

  let oldHtml;
  if (OLD_SRC) {
    if (!existsSync(OLD_SRC)) { console.log(JSON.stringify({ ok: false, error: `T308_OLD_SRC does not exist: ${OLD_SRC}` })); process.exitCode = 2; return; }
    oldHtml = readFileSync(OLD_SRC, 'utf8');
  } else {
    try { oldHtml = execFileSync('git', ['show', `${REF}:${SRC}`], { cwd: REPO, maxBuffer: 64 * 1024 * 1024 }).toString(); }
    catch (e) { console.log(JSON.stringify({ ok: false, error: `cannot read ${REF}:${SRC} — ${e.message}` })); process.exitCode = 2; return; }
  }

  const doc = mkdtempSync(join(tmpdir(), 't308-bi-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't308-bi-repo-'));
  writeFileSync(join(doc, 'designer-old.html'), oldHtml);
  copyFileSync(join(REPO, SRC), join(doc, 'designer-new.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't308-bi-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');

    const before = await exportAll(cmd, `${BASE}/designer-old.html`, maps);
    const after = await exportAll(cmd, `${BASE}/designer-new.html`, maps);

    const drift = [], errors = [], rows = [], unusable = [];
    for (const m of maps) {
      const B = before[m.name] || {}, A = after[m.name] || {};
      const b = B.xml, a = A.xml;
      if (typeof b !== 'string' || b.startsWith('ERROR:')) errors.push(`${m.name} (${OLD_LABEL}): ${b}`);
      if (typeof a !== 'string' || a.startsWith('ERROR:')) errors.push(`${m.name} (working tree): ${a}`);
      if (typeof b === 'string' && typeof a === 'string' && !b.startsWith('ERROR:') && !a.startsWith('ERROR:')) {
        // Void before verdict: an unstable document cannot be compared across builds,
        // so it is neither identical nor drifted. Counting it either way would be a
        // number that does not mean what it says.
        if (B.selfStable === false || A.selfStable === false) {
          unusable.push({ map: m.name, unstableIn: [B.selfStable === false ? OLD_LABEL : null, A.selfStable === false ? 'working tree' : null].filter(Boolean) });
          continue;
        }
        if (b !== a) drift.push({ map: m.name, refSha: sha(b), treeSha: sha(a), refBytes: b.length, treeBytes: a.length });
        else rows.push({ map: m.name, sha: sha(a), bytes: a.length });
      }
    }
    // An unusable map fails the run. The gate exists to answer "did any byte move?";
    // for a document it cannot compare it has no answer, and a green with a silent
    // hole is exactly the failure G-023 records.
    const ok = drift.length === 0 && errors.length === 0 && unusable.length === 0;
    console.log(JSON.stringify({
      ok, ref: OLD_LABEL,
      srcOverride: OLD_SRC || null, maps: maps.length,
      identical: rows.length, drifted: drift.length, unusable: unusable.length,
      population: {
        source: 'examples/aef-processes/rendered',
        description: 'designer-produced corpus maps — they carry aef:uid in their bytes, which is what makes them byte-comparable at all',
        does_not_cover: 'third-party documents (they arrive with no aef:uid, so the values this gate compares byte-for-byte are ones WE mint for them rather than anything the author wrote). Until T-364 they were also not byte-stable with themselves — a fresh random uid per parse — which is why the unusable bucket exists; repair (a) fixed that (uid now derives from the element id) and the exclusion still stands on the first reason alone. Cite this result for the corpus, never for third-party fidelity; use tools/_t358-byteid-thirdparty.mjs for that population.',
      },
      drift, errors, unusableMaps: unusable, sample: rows.slice(0, 3),
    }, null, 2));
    process.exitCode = ok ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e) }, null, 2));
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
