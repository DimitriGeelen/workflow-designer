#!/usr/bin/env node
// _t1339-subprocess-nesting-roundtrip-cdp.mjs — T-1339 (T-1266 GO, slice 1): a third-party file opened and saved
// unedited keeps every node and sequence flow in the container the file declared it in (subProcess, transaction,
// adHocSubProcess, or the process). Drives the REAL editor headless, as a person opens a file (adoptImportedXml,
// userImport), then:
//   1. for every flow node and sequenceFlow in the file, its container in the export (matched by id, or by the
//      x832:origin originalId the designer writes when it renames one, T-1261) is the file's container;
//   2. the totals of nested nodes and nested flows across the 4 nesting fixtures are 23 and 6 (T-1266 F1);
//   3. a second save (open the first export, save) is byte-identical to the first.
//   node tools/_t1339-subprocess-nesting-roundtrip-cdp.mjs
// T1339_DUMP=<dir> writes both saves of a failing fixture there.
// T1339_SRC substitutes another designer file (the BITE: on the pre-T-1339 source every nested element is moved up).
// Exit 0 = all green; 1 = a check failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXDIR = join(REPO, 'tests', 'fixtures', 'third-party');
const DESIGNER = process.env.T1339_SRC || join(REPO, 'src', 'aef-workflow-designer.html');
const FIXTURES = ['simple.bpmn', 'boundary-events.bpmn', 'nested-subprocesses.bpmn', 'kitchen-sink.bpmn'];
const WANT = { nodes: 23, flows: 6 };
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// In the page: open, save, compare each element's container; open the save, save again, compare bytes.
const CHECK = `(async function(xml){
  var MODEL = 'http://www.omg.org/spec/BPMN/20100524/MODEL', ORIGIN = 'urn:832-workflow-designer:origin:1';
  var KINDS = { subProcess: 1, transaction: 1, adHocSubProcess: 1 };
  var NODE = /(Event|Task|task|Gateway|subProcess|SubProcess|transaction|callActivity)$/;
  function parse(x){ return new DOMParser().parseFromString(x, 'application/xml'); }
  function homeOf(el, key){ for (var p = el.parentNode; p; p = p.parentNode) { if (p.namespaceURI !== MODEL) continue;
    if (p.localName === 'process') return 'process'; if (KINDS[p.localName]) return key(p); } return '?'; }
  function elems(d){ return Array.prototype.filter.call(d.getElementsByTagNameNS(MODEL, '*'), function(e){
    return e.getAttribute('id') && (e.localName === 'sequenceFlow' || NODE.test(e.localName)) && homeOf(e, function(){ return 1; }) !== '?'; }); }
  function origOf(e){ var o = e.getElementsByTagNameNS(ORIGIN, 'origin')[0];
    return o && o.parentNode && o.parentNode.parentNode === e ? o.getAttribute('originalId') : e.getAttribute('id'); }
  async function save(x){ await adoptImportedXml(x, { userImport: true }); await new Promise(function(r){ setTimeout(r, 100); }); return buildBpmnXml(state); }
  var src = parse(xml), out1 = await save(xml), dst = parse(out1), errs = [], nested = { nodes: 0, flows: 0 };
  var dstByOrig = {}; elems(dst).forEach(function(e){ dstByOrig[origOf(e)] = e; });
  elems(src).forEach(function(e){
    var id = e.getAttribute('id'), want = homeOf(e, function(p){ return p.getAttribute('id'); });
    if (want !== 'process') nested[e.localName === 'sequenceFlow' ? 'flows' : 'nodes']++;
    var d = dstByOrig[id];
    if (!d) { errs.push(id + ': not in the export'); return; }
    var got = homeOf(d, origOf);
    if (got !== want) errs.push(id + ': in ' + got + ', file has it in ' + want);
  });
  // The second save reparses the first directly: opening it as a person would again renames the workflow (a library
  // clash, _v2, _v3 ...), which is the import's rule, not a round-trip difference.
  state = parseBpmnXml(out1); refreshDisplayIds();
  var out2 = buildBpmnXml(state);
  if (out2 !== out1) { var i = 0; while (i < out1.length && out1[i] === out2[i]) i++;
    errs.push('second save differs at byte ' + i + ': ' + JSON.stringify(out1.slice(Math.max(0, i - 60), i + 60))); }
  return { errs: errs, nested: nested, saves: errs.length ? [out1, out2] : null };
})`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1339-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1339-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1339-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const rows = []; let cl;
  try {
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) break; } catch (_) {} await sleep(100); }
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; };' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(300);
    for (const f of FIXTURES) {
      const xml = readFileSync(join(FIXDIR, f), 'utf8');
      rows.push({ f, r: await ev(cmd, `${CHECK}(${JSON.stringify(xml)}).catch(function(e){ return { errs: ['exception: ' + e] }; })`) });
    }
  } catch (e) {
    rows.push({ f: 'harness', r: { errs: [String(e && e.stack || e)] } });
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  let bad = 0; const tot = { nodes: 0, flows: 0 };
  for (const { f, r } of rows) {
    const errs = (r && r.errs) || ['no result'];
    if (r && r.nested) { tot.nodes += r.nested.nodes; tot.flows += r.nested.flows; }
    if (errs.length) bad++;
    if (errs.length && r.saves && process.env.T1339_DUMP) r.saves.forEach((x, i) => writeFileSync(join(process.env.T1339_DUMP, `${f}.save${i + 1}.bpmn`), x));
    console.log(`${errs.length ? 'FAIL' : 'ok  '} ${f}${r && r.nested ? `  (nested: ${r.nested.nodes} nodes, ${r.nested.flows} flows)` : ''}`);
    for (const e of errs.slice(0, 8)) console.log(`       ${e}`);
    if (errs.length > 8) console.log(`       ... ${errs.length - 8} more`);
  }
  if (tot.nodes !== WANT.nodes || tot.flows !== WANT.flows) {
    bad++; console.log(`FAIL totals: ${tot.nodes} nested nodes, ${tot.flows} nested flows; T-1266 measured ${WANT.nodes} and ${WANT.flows}`);
  }
  console.log(`T-1339: ${bad ? 'RED' : 'GREEN'} — ${FIXTURES.length} fixtures, ${tot.nodes} nested nodes and ${tot.flows} nested flows checked`);
  process.exitCode = bad ? 1 : 0;
}
main();
