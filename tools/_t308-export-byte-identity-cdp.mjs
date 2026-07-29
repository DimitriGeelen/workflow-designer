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

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = join(REPO, 'examples', 'aef-processes', 'rendered');
const REF = process.argv[2] || 'HEAD';
const SRC = 'src/aef-workflow-designer.html';
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
const EXPORT_EXPR = `(function(){
  var out = {};
  var maps = window.__MAPS__;
  for (var i=0;i<maps.length;i++){
    try {
      state = parseBpmnXml(maps[i].text);
      refreshDisplayIds();
      out[maps[i].name] = buildBpmnXml(state);
    } catch(e) { out[maps[i].name] = 'ERROR: ' + (e && e.message || e); }
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
  try { oldHtml = execFileSync('git', ['show', `${REF}:${SRC}`], { cwd: REPO, maxBuffer: 64 * 1024 * 1024 }).toString(); }
  catch (e) { console.log(JSON.stringify({ ok: false, error: `cannot read ${REF}:${SRC} — ${e.message}` })); process.exitCode = 2; return; }

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
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');

    const before = await exportAll(cmd, `${BASE}/designer-old.html`, maps);
    const after = await exportAll(cmd, `${BASE}/designer-new.html`, maps);

    const drift = [], errors = [], rows = [];
    for (const m of maps) {
      const b = before[m.name], a = after[m.name];
      if (typeof b !== 'string' || b.startsWith('ERROR:')) errors.push(`${m.name} (${REF}): ${b}`);
      if (typeof a !== 'string' || a.startsWith('ERROR:')) errors.push(`${m.name} (working tree): ${a}`);
      if (typeof b === 'string' && typeof a === 'string') {
        if (b !== a) drift.push({ map: m.name, refSha: sha(b), treeSha: sha(a), refBytes: b.length, treeBytes: a.length });
        else rows.push({ map: m.name, sha: sha(a), bytes: a.length });
      }
    }
    const ok = drift.length === 0 && errors.length === 0;
    console.log(JSON.stringify({
      ok, ref: REF, maps: maps.length,
      identical: rows.length, drifted: drift.length,
      drift, errors, sample: rows.slice(0, 3),
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
