#!/usr/bin/env node
// _t1131-dangling-refs-thirdparty-cdp.mjs — T-1131: every third-party fixture's EXPORT must reference only ids it
// contains. The byte-identity goldens (T-358) were recorded from the export, so a defect present when they were
// recorded passes them forever; this checks validity instead of bytes. Scans, in the real editor's output:
//   attributes sourceRef / targetRef / bpmnElement / dataObjectRef / processRef / attachedToRef / default, and the
//   text of <sourceRef>/<targetRef>/<incoming>/<outgoing>/<flowNodeRef> elements.
//   node tools/_t1131-dangling-refs-thirdparty-cdp.mjs [--designer PATH]
// Exit 0 = no dangling reference in any export; 1 = some; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXDIR = join(REPO, 'tests', 'fixtures', 'third-party');
const argv = process.argv.slice(2);
const DESIGNER = (argv.indexOf('--designer') >= 0 && argv[argv.indexOf('--designer') + 1]) || join(REPO, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const SCAN = `(function(xml){
  var d = new DOMParser().parseFromString(xml, 'application/xml');
  if (d.getElementsByTagName('parsererror').length) return { parse: false };
  var all = Array.prototype.slice.call(d.getElementsByTagName('*'));
  var ids = new Set(all.map(function(e){ return e.getAttribute('id'); }).filter(Boolean));
  var bad = [];
  // Only BPMN-model and BPMN-DI elements: a vendor element's attribute of the same name is not a reference
  // (caseagile:property default="FFFFFF" is a colour).
  var NS = { 'http://www.omg.org/spec/BPMN/20100524/MODEL': 1, 'http://www.omg.org/spec/BPMN/20100524/DI': 1 };
  all.forEach(function(e){
    if (!NS[e.namespaceURI]) return;
    ['sourceRef', 'targetRef', 'bpmnElement', 'dataObjectRef', 'processRef', 'attachedToRef', 'default'].forEach(function(a){ var v = e.getAttribute(a); if (v && !ids.has(v)) bad.push(e.localName + '@' + a + '=' + v); });
    if (/^(sourceRef|targetRef|incoming|outgoing|flowNodeRef)$/.test(e.localName) && !e.children.length) { var t = (e.textContent || '').trim(); if (t && !ids.has(t)) bad.push(e.parentNode.localName + '/' + e.localName + '=' + t); }
  });
  return { parse: true, bad: bad }; })`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const fixtures = readdirSync(FIXDIR).filter(f => f.endsWith('.bpmn')).sort();
  const doc = mkdtempSync(join(tmpdir(), 't1131-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1131-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1131-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const rows = []; let cl;
  try {
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) break; } catch (_) {} await sleep(100); }
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; };' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(300);
    for (const f of fixtures) {
      const xml = readFileSync(join(FIXDIR, f), 'utf8');
      const r = await ev(cmd, `(function(){ try { adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); renderAll(); return ${SCAN}(buildBpmnXml(state)); } catch (e) { return { error: String(e) }; } })()`);
      rows.push({ f, r });
    }
  } catch (e) {
    rows.push({ f: 'harness', r: { error: String(e && e.stack || e) } });
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  let bad = 0;
  for (const { f, r } of rows) {
    const ok = r && r.parse && r.bad && r.bad.length === 0;
    if (!ok) bad++;
    console.log(`${ok ? 'ok  ' : 'FAIL'} ${f}${ok ? '' : '  ' + JSON.stringify(r.error ? r.error : (r.parse === false ? 'export does not parse' : r.bad.slice(0, 5)))}`);
  }
  console.log(`T-1131: ${rows.length - bad}/${rows.length} third-party exports free of dangling references`);
  process.exitCode = bad ? 1 : 0;
}
main();
