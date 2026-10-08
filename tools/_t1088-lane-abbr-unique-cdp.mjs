#!/usr/bin/env node
// _t1088-lane-abbr-unique-cdp.mjs — T-1088: lane abbreviations are unique after BPMN import.
//
// aef-greenfield-test (T-172 item 2) loaded a map whose lanes "Tacton CPQ" and "TactonConnector"
// both became 'tac': the importer derived each lane's abbreviation on its own and never ran the
// uniqueness step that rename and addLane use. Node ids are `<abbr>_<rank>_<slug>`, so two lanes
// sharing a prefix make ids ambiguous, and identical ones as soon as two such lanes hold a
// same-named step at the same rank — duplicate XML ids, an invalid file.
//
// Drives the REAL editor runtime against tests/fixtures/aef-bpmn/t1088-lane-abbr-clash.bpmn
// (three lanes deriving 'tac', two lanes with the same explicit laneMeta abbr 'sal', one
// "Check order" step each) and asserts:
//   IMPORT  every lane abbreviation is distinct; the first lane of each clash keeps its abbr
//   IDS     every node displayId is distinct
//   SAVE    buildBpmnXml emits no duplicate id attribute, and re-import keeps the abbrs (fixed point)
//
//   node tools/_t1088-lane-abbr-unique-cdp.mjs [--designer PATH] [--bpmn PATH]
//   --designer runs against another copy (to show the test fails on the unfixed code);
//   --bpmn checks only IMPORT on another file (Greenfield's maps; not committed).
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const argv = process.argv.slice(2);
const opt = k => { const i = argv.indexOf(k); return i >= 0 ? argv[i + 1] : null; };
const DESIGNER = opt('--designer') || join(REPO, 'src', 'aef-workflow-designer.html');
const OTHER = opt('--bpmn');
const FIXTURE = OTHER || join(REPO, 'tests', 'fixtures', 'aef-bpmn', 't1088-lane-abbr-clash.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const ASSERT_EXPR = (onlyImport) => `(function(){
  var errs = [];
  function dups(a){ var seen = {}, d = []; a.forEach(function(x){ if(seen[x] && d.indexOf(x) < 0) d.push(x); seen[x] = 1; }); return d; }
  try {
    state = parseBpmnXml(window.__FIXTURE__); refreshDisplayIds();
    var abbrs = state.lanes.map(function(l){ return l.abbr; });
    var dA = dups(abbrs);
    if (dA.length) errs.push('IMPORT: lanes share abbreviation(s) ' + dA.join(',') + ' — all: ' + abbrs.join(','));
    var byName = {}; state.lanes.forEach(function(l){ byName[l.name] = l.abbr; });
    var out = { abbrs: state.lanes.map(function(l){ return l.name + '=' + l.abbr; }) };
    if (!${onlyImport}) {
      if (byName['Tacton CPQ'] !== 'tac') errs.push('IMPORT: first clashing lane did not keep tac (got ' + byName['Tacton CPQ'] + ')');
      if (byName['Sales A'] !== 'sal') errs.push('IMPORT: first explicit-abbr lane did not keep sal (got ' + byName['Sales A'] + ')');
      var ids = state.nodes.map(function(n){ return displayIdOf(n); });
      var dI = dups(ids);
      if (dI.length) errs.push('IDS: duplicate node ids ' + dI.join(','));
      out.ids = ids;
      var xml = buildBpmnXml(state).replace(/<!--[\\s\\S]*?-->/g, '');
      var xmlIds = (xml.match(/\\sid="[^"]+"/g) || []).map(function(s){ return s.trim(); });
      var dX = dups(xmlIds);
      if (dX.length) errs.push('SAVE: saved XML has duplicate ' + dX.join(' '));
      state = parseBpmnXml(xml); refreshDisplayIds();
      var again = state.lanes.map(function(l){ return l.abbr; });
      if (again.join(',') !== abbrs.join(',')) errs.push('SAVE: re-import changed the abbrs ' + abbrs.join(',') + ' -> ' + again.join(','));
    }
    out.ok = errs.length === 0; out.errs = errs;
    return out;
  } catch (e) { return { ok: false, errs: ['exception: ' + (e && e.message || e)] }; }
})()`;

async function main() {
  if (!existsSync(FIXTURE) || !existsSync(DESIGNER)) { process.stdout.write(JSON.stringify({ ok: false, error: 'missing: ' + (existsSync(FIXTURE) ? DESIGNER : FIXTURE) }) + '\n'); process.exitCode = 2; return; }
  const text = readFileSync(FIXTURE, 'utf8');
  const doc = mkdtempSync(join(tmpdir(), 't1088-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1088-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1088-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(text)};`);
    const r = await ev(cmd, ASSERT_EXPR(!!OTHER));
    process.stdout.write(JSON.stringify({ fixture: FIXTURE.replace(REPO + '/', ''), ...r }, null, 2) + '\n');
    process.exitCode = r && r.ok ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, error: String(e && e.stack || e) }, null, 2) + '\n');
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
