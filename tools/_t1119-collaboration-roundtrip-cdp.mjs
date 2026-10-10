#!/usr/bin/env node
// _t1119-collaboration-roundtrip-cdp.mjs — T-1119 (P1): open + save keeps every pool, process and message flow.
//
// Before T-1119 the importer opened one process, read only participant[0] and ignored messageFlow, so a
// collaboration lost its other pools and every message flow on the first save (T-348: ROOT-DROPPED 24/24;
// aef-greenfield-test lost "Tacton CPQ" and both flows). Drives the REAL editor (adoptImportedXml +
// buildBpmnXml) on four collaborations — a synthetic Sales + black-box Tacton CPQ (CPQ listed FIRST) and
// three third-party files — and checks the saved XML:
//   A  participants and messageFlows: same count after save as before (per file)
//   B  every messageFlow sourceRef/targetRef and every participant processRef resolves in the saved file
//   C  every messageFlow joins two DIFFERENT pools (BPMN 2.0.2)
//   D  the saved file is well-formed XML
//   E  our pool is the one whose processRef is the opened process (synthetic: "Sales", although CPQ comes first)
//   F  no "not shown yet" notice for pools (T-1120 draws them; P1 had the notice)
//   node tools/_t1119-collaboration-roundtrip-cdp.mjs [--designer PATH]   (0.16.0 must FAIL A)
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
const DESIGNER = (argv.indexOf('--designer') >= 0 && argv[argv.indexOf('--designer') + 1]) || join(REPO, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));
const FILES = [
  join(REPO, 'tests', 'fixtures', 'aef-bpmn', 't1119-sales-cpq-collaboration.bpmn'),
  join(REPO, 'tests', 'fixtures', 'third-party', 'collaboration-message-flows.bpmn'),
  join(REPO, 'tests', 'fixtures', 'third-party', 'kitchen-sink.bpmn'),
  join(REPO, 'tests', 'fixtures', 'third-party', 'bizagi-nested-ns.bpmn'),
];

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// In-page: facts about one BPMN document (counts, unresolved refs, flows within one pool).
const FACTS = `function(xml){
  var d = new DOMParser().parseFromString(xml, 'application/xml');
  if (d.getElementsByTagName('parsererror').length) return { wellFormed: false, unresolved: ['parsererror'], samePool: [] };
  var M = 'http://www.omg.org/spec/BPMN/20100524/MODEL';
  var all = function(t){ return Array.prototype.slice.call(d.getElementsByTagNameNS(M, t)); };
  var ids = {}; Array.prototype.slice.call(d.getElementsByTagName('*')).forEach(function(e){ if (e.getAttribute && e.getAttribute('id')) ids[e.getAttribute('id')] = e; });
  var parts = all('participant'), flows = all('messageFlow');
  var poolOf = function(id){ var e = ids[id]; if (!e) return null;
    if (e.localName === 'participant') return id;
    var p = e; while (p && p.localName !== 'process') p = p.parentNode;
    if (!p) return null; var pid = p.getAttribute('id');
    var owner = parts.filter(function(x){ return x.getAttribute('processRef') === pid; })[0];
    return owner ? owner.getAttribute('id') : 'process:' + pid; };
  var unresolved = [], samePool = [];
  flows.forEach(function(f){ var s = f.getAttribute('sourceRef'), t = f.getAttribute('targetRef');
    if (!ids[s]) unresolved.push(f.getAttribute('id') + '.sourceRef=' + s);
    if (!ids[t]) unresolved.push(f.getAttribute('id') + '.targetRef=' + t);
    if (ids[s] && ids[t] && poolOf(s) === poolOf(t)) samePool.push(f.getAttribute('id')); });
  parts.forEach(function(p){ var r = p.getAttribute('processRef'); if (r && !ids[r]) unresolved.push(p.getAttribute('id') + '.processRef=' + r); });
  return { wellFormed: true, participants: parts.length, messageFlows: flows.length, unresolved: unresolved, samePool: samePool };
}`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1119-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1119-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1119-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; };' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    const res = [];
    for (const f of FILES) {
      const xml = readFileSync(f, 'utf8');
      const r = await ev(cmd, `(function(){ var facts = ${FACTS}; var before = facts(${JSON.stringify(xml)});
        adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); renderAll();
        var out = buildBpmnXml(state); var after = facts(out);
        var n = document.getElementById('lane-fix-msg');
        return { before: before, after: after, pool: state.pool.name, notice: n ? n.textContent : '' }; })()`);
      res.push({ file: f.split('/').slice(-2).join('/'), ...r });
    }
    for (const r of res) {
      leg(r.after.participants === r.before.participants && r.after.messageFlows === r.before.messageFlows,
          `A ${r.file}: pools ${r.before.participants}->${r.after.participants}, message flows ${r.before.messageFlows}->${r.after.messageFlows}`);
      leg(r.after.wellFormed && r.after.unresolved.length === 0, `B ${r.file}: every ref resolves after save`, JSON.stringify(r.after.unresolved));
      leg(r.after.wellFormed && r.after.samePool.length === 0, `C ${r.file}: message flows only between different pools`, JSON.stringify(r.after.samePool));
      leg(r.after.wellFormed, `D ${r.file}: saved file is well-formed XML`);
    }
    const syn = res[0];
    leg(syn.pool === 'Sales', 'E synthetic: our pool is "Sales" (by processRef), although "Tacton CPQ" is listed first', 'pool=' + syn.pool);
    // T-1120 draws the kept pools, so P1's "kept, not shown yet" notice must be gone for them (no claim of hidden pools)
    leg(!/not shown yet/.test(syn.notice), 'F synthetic: no "not shown yet" notice for pools (T-1120 draws them)', JSON.stringify(syn.notice));
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
  for (const l of legs) console.log(`${l.ok ? 'PASS' : 'FAIL'}  ${l.name}${l.detail ? ' — ' + l.detail : ''}`);
  const want = FILES.length * 4 + 2;
  const ok = legs.length === want && legs.every(l => l.ok);
  console.log(ok ? `${legs.length}/${want} legs passed` : `FAILED (${legs.filter(l => !l.ok).length} of ${legs.length})`);
  process.exitCode = ok ? 0 : 1;
}
main();
