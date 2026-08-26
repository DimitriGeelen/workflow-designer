#!/usr/bin/env node
// _t479-endpoint-roundtrip-cdp.mjs — does <aef:endpoint> survive the editor round trip?
//
// WHY this probe exists rather than a reading of the code: T-477 found the frozen two-party
// standard files `aef:endpoint` under the PRESENTATIONAL class ("derived, never authoritative";
// "a change alone MUST be a no-op for the task graph") while it actually carries the executable
// command a task node runs. That is an ENTITLEMENT to discard. Whether anything DOES discard it
// is a separate, measurable question, and it decides whether the v1.2 correction is urgent
// (commands being lost today) or latent (a trap for a future conformant implementer).
//
// The existing round-trip guard (_roundtrip-serialization-cdp.mjs) CANNOT answer it: its semantic
// projection is a fixed METAKEYS list, `endpoint` appears nowhere in that harness, and presentational
// content is excluded by design. So the standard's misclassification has already propagated into
// our verification — the guard that would catch endpoint loss is configured not to look.
//
// For every corpus/example document carrying >=1 <aef:endpoint>, IN THE REAL EDITOR:
//     m1    = parseBpmnXml(doc);  state = m1; refreshDisplayIds()
//     emit1 = buildBpmnXml(state)
// and compares the MULTISET of endpoint values in the input against the output — presence AND
// value, so a preserved-but-mangled endpoint is a failure, not a pass.
//
// Positive control (PL-095): one input has an endpoint deliberately stripped before the round trip.
// The comparison MUST report that as loss. A probe that cannot report loss proves nothing about
// its absence. Exit 2 if the control does not fire.
//
// Reports; the gate is the caller's. Exit 0 = no loss found AND control fired.
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

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Extract the multiset of <aef:endpoint> values from XML, DECODED.
//
// The first form of this function compared raw serialized text and reported
// offpage-seam.bpmn as lossy: its endpoint contains `->`, which the input carries
// unescaped (legal in XML text) and the editor's escText() re-emits as `-&gt;`.
// Semantically identical; textually different. That false positive was one step from
// being reported to AEF as data loss in a fixture THEY PIN. A serialization comparison
// that does not decode is comparing encodings, not values.
function decodeEntities(s) {
  return s.replace(/&lt;/g, '<').replace(/&gt;/g, '>')
          .replace(/&quot;/g, '"').replace(/&apos;/g, "'")
          .replace(/&amp;/g, '&');   // last: an unescaped & must not double-decode
}
function endpointsOf(text) {
  const out = []; const re = /<aef:endpoint>([\s\S]*?)<\/aef:endpoint>/g; let m;
  while ((m = re.exec(text)) !== null) out.push(decodeEntities(m[1]).trim());
  return out.sort();
}

const RT_EXPR = `(function(){
  try{
    var text = window.__DOC__;
    var m1 = parseBpmnXml(text);
    if(!m1) return { ok:false, reason:'parse-null' };
    state = m1; refreshDisplayIds();
    var emit1 = buildBpmnXml(state);
    return { ok:true, emit:emit1, nodes:m1.nodes.length };
  }catch(e){ return { ok:false, reason:'exception: '+(e&&e.message||e) }; }
})()`;

function collectDocs() {
  const roots = [join(REPO, 'examples'), join(REPO, 'tests', 'fixtures', 'aef-bpmn')];
  const found = [];
  const walk = d => { if (!existsSync(d)) return; for (const e of readdirSync(d, { withFileTypes: true })) { const p = join(d, e.name); if (e.isDirectory()) walk(p); else if (e.name.endsWith('.bpmn')) found.push(p); } };
  roots.forEach(walk);
  return found.filter(p => endpointsOf(readFileSync(p, 'utf8')).length > 0).sort();
}

async function main() {
  const docs = collectDocs();
  // PL-084/PL-022: an empty population is not a clean result — it is no result.
  if (!docs.length) { console.log(JSON.stringify({ pass: false, error: 'no document carries <aef:endpoint> — verdict would be vacuous' })); process.exitCode = 1; return; }

  const doc = mkdtempSync(join(tmpdir(), 't479-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't479-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't479-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl; const verdict = { population: docs.length, docs: [], totalIn: 0, totalOut: 0, lossy: [] };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) { } await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    const runOne = async (label, text) => {
      const before = endpointsOf(text);
      await ev(cmd, `window.__DOC__ = ${JSON.stringify(text)};`);
      const r = await ev(cmd, RT_EXPR);
      if (!r || !r.ok) return { label, error: (r && r.reason) || 'no result', before: before.length };
      const after = endpointsOf(r.emit);
      const lost = before.filter(v => !after.includes(v));
      const changed = before.length === after.length && JSON.stringify(before) !== JSON.stringify(after);
      return { label, before: before.length, after: after.length, lost, changed, nodes: r.nodes };
    };

    // --- positive control: strip ONE endpoint from a real document; loss MUST be reported ---
    const ctlSrc = readFileSync(docs[0], 'utf8');
    const ctlText = ctlSrc.replace(/<aef:endpoint>[\s\S]*?<\/aef:endpoint>/, '');
    const ctl = await runOne('POSITIVE-CONTROL(' + docs[0].replace(REPO + '/', '') + ')', ctlText);
    const ctlBase = endpointsOf(ctlSrc);
    const ctlFired = ctl.before === ctlBase.length - 1;
    verdict.control = { ...ctl, originalEndpoints: ctlBase.length, fired: ctlFired };
    if (!ctlFired) {
      console.log(JSON.stringify({ pass: false, control_failed: true, error: 'probe could not detect a removed endpoint — a clean verdict would be vacuous', control: verdict.control }, null, 2));
      process.exitCode = 2; return;
    }

    for (const p of docs) {
      const rel = p.replace(REPO + '/', '');
      const res = await runOne(rel, readFileSync(p, 'utf8'));
      verdict.docs.push(res);
      verdict.totalIn += res.before || 0; verdict.totalOut += res.after || 0;
      if (res.error || (res.lost && res.lost.length) || res.changed) verdict.lossy.push(res);
    }
    verdict.pass = verdict.lossy.length === 0;
    verdict.summary = `${verdict.population} documents, ${verdict.totalIn} endpoints in, ${verdict.totalOut} out, ${verdict.lossy.length} lossy`;
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
