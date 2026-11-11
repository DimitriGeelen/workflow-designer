#!/usr/bin/env node
// _t1366-plain-event-kinds-cdp.mjs — T-1366: a conditional or signal event from another tool's file is drawn and named as
// what it is. Before, a bpmn:intermediateCatchEvent with a conditionalEventDefinition opened as a link catch: a plain
// double ring with no marker, and a display id with "link" in it (greenfield's WT-01 "Lead status Qualified in
// Salesforce" read sal_link_lead). Drives the REAL editor runtime headless on a synthetic map (no client data) and asserts:
//   1. conditional catch, signal catch and signal throw each draw BPMN's kind marker ([data-kind-marker]);
//   2. their display ids name the kind (conditional / signal) and never "link";
//   3. the kinds the designer types (message, timer) and a definition-less catch are unchanged: no marker, and the
//      plain catch keeps its "link" word (out of scope: T-308's bare catch);
//   4. the side panel heads the conditional event "conditionalEvent";
//   5. the save keeps every native definition, a second save is byte-identical, and the export parses in expat.
// T1366_SRC substitutes another designer file (the BITE: run against the pre-T-1366 source, legs 1, 2 and 4 are red).
// Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn, spawnSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';   // T-1395: rejects on Chrome's death and after cmdMs, never waits for ever

const HERE = dirname(fileURLToPath(import.meta.url));
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1366_SRC || join(HERE, '..', 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&typeof buildBpmnXml==='function'&&typeof displayIdOf==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// One lane, a chain of intermediate events, one per native kind (conditional catch, signal catch, message catch, timer
// catch, a catch with no definition, signal throw), written as another tool writes them. The same file feeds
// tools/_t1366-shots.mjs.
const MAP = readFileSync(join(HERE, '..', 'tests/fixtures/t1366/plain-event-kinds.bpmn'), 'utf8');

const ASSERT = `(() => {
  var errs = [], info = {};
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  adoptImportedXml(window.__MAP__); renderAll();
  function node(name){ return state.nodes.filter(function(n){ return n.name === name; })[0]; }
  function marker(n){ var g = document.querySelector('g[data-id="' + n.id + '"]'); if (!g) return 'NO-GROUP'; var m = g.querySelector('[data-kind-marker]'); return m ? m.getAttribute('data-kind-marker') : null; }
  var want = [['Status Qualified', 'conditional'], ['Recall signal', 'signal'], ['Send recall', 'signal']];
  want.forEach(function(w){
    var n = node(w[0]); if (!n) { errs.push('setup: no node "' + w[0] + '"'); return; }
    var mk = marker(n), id = displayIdOf(n);
    info[w[0]] = { type: n.type, marker: mk, id: id };
    if (mk !== w[1]) errs.push('leg1: "' + w[0] + '" draws marker ' + JSON.stringify(mk) + ', want ' + w[1]);
    if (/link/.test(id) || id.indexOf(w[1]) < 0) errs.push('leg2: "' + w[0] + '" display id ' + id + ' does not name ' + w[1] + ' (or says link)');
  });
  [['Order received', 'eventMessage'], ['Two days', 'eventTimer']].forEach(function(w){
    var n = node(w[0]); info[w[0]] = n && { type: n.type, marker: marker(n), id: displayIdOf(n) };
    if (!n || n.type !== w[1]) errs.push('leg3: "' + w[0] + '" is ' + (n && n.type) + ', want ' + w[1]);
    else if (marker(n)) errs.push('leg3: "' + w[0] + '" got a plain-kind marker');
  });
  var pc = node('Plain catch'); info['Plain catch'] = pc && { type: pc.type, marker: marker(pc), id: displayIdOf(pc) };
  if (!pc || marker(pc)) errs.push('leg3: the definition-less catch got a marker');
  else if (!/link/.test(displayIdOf(pc))) errs.push('leg3: the definition-less catch changed its id word (' + displayIdOf(pc) + '), out of scope');
  var c = node('Status Qualified');
  if (c) { selection = { kind: 'node', id: c.uid }; renderProperties();
    var hn = document.querySelector('.props-type-name'); info.header = hn && hn.textContent;
    if (!hn || !/^(conditionalEvent|Conditional event)$/.test(hn.textContent)) errs.push('leg4: the panel heads it ' + JSON.stringify(hn && hn.textContent));
    var pt = document.getElementById('properties').textContent;
    info.panelSaysNoKind = /carries no kind/.test(pt);
    if (/carries no kind/.test(pt)) errs.push('leg4: the panel still says the conditional event carries no kind');
    if (pt.indexOf('status = Qualified') < 0) errs.push('leg4: the panel does not show the condition as written');
    if (/Make this a handoff/.test(pt)) errs.push('leg4: the panel offers to make the conditional event a handoff'); }
  var o1 = strip(buildBpmnXml(state)), o2 = strip(buildBpmnXml(state));
  if (o1 !== o2) errs.push('leg5: a second save differs from the first');
  [['conditionalEventDefinition', 1], ['signalEventDefinition', 2], ['messageEventDefinition', 1], ['timerEventDefinition', 1]].forEach(function(k){
    var n = (o1.match(new RegExp('<bpmn:' + k[0] + '\\\\b', 'g')) || []).length;
    if (n !== k[1]) errs.push('leg5: the save has ' + n + ' ' + k[0] + ', want ' + k[1]);
  });
  if (o1.indexOf('status = Qualified') < 0) errs.push('leg5: the condition expression is lost');
  return { ok: errs.length === 0, errs: errs, info: info, xml: o1 };
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1366-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1366-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1366-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__MAP__ = ${JSON.stringify(MAP)};`);
    const r = await ev(cmd, ASSERT);
    if (r && r.xml) {
      const p = spawnSync('python3', ['-I', '-c', 'import sys, xml.etree.ElementTree as E; E.fromstring(sys.stdin.buffer.read())'], { input: r.xml });
      if (p.status !== 0) { r.ok = false; r.errs.push('leg5 (expat): ' + String(p.stderr).trim().split('\n').pop()); }
      delete r.xml;
    }
    console.log(JSON.stringify({ ok: !!(r && r.ok), src: SRC, result: r }, null, 2));
    process.exitCode = r && r.ok ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e) }));
    process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill();
  }
}
main();
