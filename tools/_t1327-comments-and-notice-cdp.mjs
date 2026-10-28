#!/usr/bin/env node
// _t1327-comments-and-notice-cdp.mjs — T-1327 (T-1322 GO slice 3): comments among a process's children are kept, and
// the import notice says what a save of the file will not keep. Drives the REAL editor runtime headless:
//   1. a comment before an element is written back immediately before that element (found by name, its id is
//      rewritten); a comment that ended the process is written at its end; a second save is byte-identical;
//   2. once the comment's element is deleted, the comment is written once, at the end of the process;
//   3. opening a file as a person does (adoptImportedXml, userImport) puts each new part in the notice when it applies:
//      kitchen-sink (subprocess contents moved up, layout redrawn, annotations/groups kept), the nested-lane fixture
//      (nested lanes flattened); a designer-written corpus map gets none of them;
//   4. no designer-written corpus map gains a `comments` key;
//   5. every export parses in Python's expat.
// T1327_SRC substitutes another designer file (the BITE: on the pre-T-1327 source, legs 1-3 are red).
// Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn, spawnSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1327_SRC || join(REPO, 'src/aef-workflow-designer.html');
const CORPUS = join(REPO, 'examples/aef-processes/rendered');
const NESTED = readFileSync(join(REPO, 'tests/fixtures/t1327/nested-lanes.bpmn'), 'utf8');
const KITCHEN = readFileSync(join(REPO, 'tests/fixtures/third-party/kitchen-sink.bpmn'), 'utf8');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// Phrases of the new notice parts; a designer-written map must show none of them.
const NEW_PARTS = ['subprocess nesting is NOT kept', 'lane nesting is NOT kept', 'layout is redrawn on save', 'kept unchanged and saved back, not shown yet'];

const ASSERT = `(async function(){
  var errs = [], exports = [], notices = {};
  var C1 = ' quote first, then the visit: the field team needs the price ', C2 = ' reviewed with the ops lead, 2026-10 ';
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function noticeText(){ var el = document.getElementById('lane-fix-notice'), m = document.getElementById('lane-fix-msg');
    return el && el.style.display !== 'none' && m ? m.textContent : ''; }
  async function openAsPerson(xml){ await adoptImportedXml(xml, { userImport: true }); await new Promise(function(r){ setTimeout(r, 150); }); return noticeText(); }
  try {
    load(window.__NESTED__);
    var out1 = buildBpmnXml(state); exports.push(['leg1', out1]);
    var i1 = out1.indexOf('<!--' + C1 + '-->'), iq = out1.indexOf('name="Prepare quote"'), ip = out1.indexOf('</bpmn:process>');
    if (i1 < 0) errs.push('leg1: the comment before the quote task is gone');
    else {
      var between = out1.slice(i1, iq);
      if (iq < i1 || (between.match(/<bpmn:/g) || []).length !== 1) errs.push('leg1: the comment is not immediately before the quote task');
    }
    var i2 = out1.indexOf('<!--' + C2 + '-->');
    if (i2 < 0) errs.push('leg1: the comment that ended the process is gone');
    else if (/<bpmn:(?!\\/)/.test(out1.slice(i2 + C2.length, ip).replace('</bpmn:process>', ''))) errs.push('leg1: the closing comment is not at the end of the process');
    load(out1);
    if (buildBpmnXml(state) !== out1) errs.push('leg1: second save differs from the first');
    load(window.__NESTED__);
    var q = state.nodes.filter(function(n){ return n.name === 'Prepare quote'; })[0];
    state.nodes = state.nodes.filter(function(n){ return n !== q; });
    state.edges = state.edges.filter(function(e){ return e.source !== q.id && e.target !== q.id; });
    var out2 = buildBpmnXml(state); exports.push(['leg2', out2]);
    var n1 = out2.split('<!--' + C1 + '-->').length - 1;
    if (n1 !== 1) errs.push('leg2: the orphaned comment is written ' + n1 + ' times (want 1)');
    else if (out2.indexOf('<!--' + C1 + '-->') < out2.lastIndexOf('<bpmn:sequenceFlow')) errs.push('leg2: the orphaned comment is not at the end of the process');
    notices.kitchen = await openAsPerson(window.__KITCHEN__);
    notices.nested = await openAsPerson(window.__NESTED__);
    notices.corpus = await openAsPerson(window.__CORPUS__[0][1]);
    function has(t, p){ return t.indexOf(p) > -1; }
    if (!has(notices.kitchen, 'subprocess nesting is NOT kept')) errs.push('leg3: kitchen-sink notice does not say the subprocess nesting is lost');
    if (!has(notices.kitchen, 'layout is redrawn on save')) errs.push('leg3: kitchen-sink notice does not say its layout is redrawn');
    if (!has(notices.kitchen, '1 annotation, 3 groups, 2 associations kept unchanged')) errs.push('leg3: kitchen-sink notice does not count the kept annotation, groups and associations');
    if (!has(notices.nested, '2 nested lanes')) errs.push('leg3: nested-lane notice does not count the 2 nested lanes: ' + notices.nested.slice(0, 200));
    ${JSON.stringify(NEW_PARTS)}.forEach(function(p){ if (has(notices.corpus, p)) errs.push('leg3: a designer-written map shows "' + p + '"'); });
    var grew = [];
    window.__CORPUS__.forEach(function(c){ load(c[1]); if (state.procKept && state.procKept.comments) grew.push(c[0]); });
    if (grew.length) errs.push('leg4: designer-written maps grew comments: ' + grew.join(', '));
    return { ok: errs.length === 0, errs: errs, exports: exports, notices: notices, corpus: window.__CORPUS__.length };
  } catch (err) { return { ok: false, errs: ['exception: ' + (err && err.message || err)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort().map(f => [f, readFileSync(join(CORPUS, f), 'utf8')]);
  const doc = mkdtempSync(join(tmpdir(), 't1327-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1327-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1327-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__NESTED__ = ${JSON.stringify(NESTED)}; window.__KITCHEN__ = ${JSON.stringify(KITCHEN)}; window.__CORPUS__ = ${JSON.stringify(corpus)};`);
    const r = await ev(cmd, ASSERT);
    for (const [tag, x] of (r && r.exports) || []) {
      const p = spawnSync('python3', ['-I', '-c', 'import sys, xml.etree.ElementTree as E; E.fromstring(sys.stdin.buffer.read())'], { input: x });
      if (p.status !== 0) { r.ok = false; r.errs.push(`${tag} (expat): ${String(p.stderr).trim().split('\n').pop()}`); }
    }
    if (r) delete r.exports;
    console.log(JSON.stringify({ ok: !!(r && r.ok), src: SRC, result: r }, null, 2));
    process.exitCode = r && r.ok ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e) }, null, 2));
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
