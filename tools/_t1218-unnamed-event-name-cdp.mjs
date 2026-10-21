#!/usr/bin/env node
// _t1218-unnamed-event-name-cdp.mjs — T-1218: an unnamed start or end event stays unnamed through open and save.
// The import used the element id as the name when the name was absent or empty, so the canvas showed "Start_8" and
// the save wrote name="Start_8" back (aef-greenfield-test, 41 maps). Drives the REAL editor runtime headless and asserts:
//   1. a start event with no name, one with name="", and an end event with no name parse to name '' and save with
//      no name attribute;
//   2. their display ids are unchanged (lan_start_start, lan_start_start_2, lan_end_end): the slug still comes from the id;
//   3. named start/end events keep their names;
//   4. an unnamed task keeps its id as its label (deliberate: an empty task box cannot be found on the canvas);
//   5. a second save is byte-identical to the first;
//   6. a name cleared in state saves as no name attribute, not name="".
// T1218_SRC substitutes another designer file (the BITE: against the pre-T-1218 source, legs 1 and 6 are red).
// Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
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
const SRC = process.env.T1218_SRC || join(REPO, 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const AEF = 'http://anchorpoint.framework/aef/extensions';
const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="${AEF}" id="Defs_1" targetNamespace="http://example.com/t1218">
  <bpmn:process id="Proc_1" name="T-1218" isExecutable="false">
    <bpmn:startEvent id="Start_8"/>
    <bpmn:startEvent id="Start_9" name=""/>
    <bpmn:startEvent id="Start_10" name="Order received"/>
    <bpmn:task id="Task_1"/>
    <bpmn:endEvent id="End_10"/>
    <bpmn:endEvent id="End_11" name="Order closed"/>
    <bpmn:sequenceFlow id="f1" sourceRef="Start_8" targetRef="Task_1"/>
    <bpmn:sequenceFlow id="f2" sourceRef="Start_9" targetRef="Task_1"/>
    <bpmn:sequenceFlow id="f3" sourceRef="Start_10" targetRef="Task_1"/>
    <bpmn:sequenceFlow id="f4" sourceRef="Task_1" targetRef="End_10"/>
    <bpmn:sequenceFlow id="f5" sourceRef="Task_1" targetRef="End_11"/>
  </bpmn:process>
</bpmn:definitions>`;

const ASSERT = `(function(){
  var errs = [];
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function load(xml){ state = parseBpmnXml(xml); refreshDisplayIds(); return state; }
  function tagOf(out, tag, id){ var m = out.match(new RegExp('<bpmn:' + tag + ' id="' + id + '"[^>]*>')); return m ? m[0] : ''; }
  try {
    load(window.__MAP__);
    var byName = {}; state.nodes.forEach(function(n){ byName[n.type + ':' + displayIdOf(n)] = n; });
    var out1 = strip(buildBpmnXml(state));
    var unnamed = [['startEvent','lan_start_start'], ['startEvent','lan_start_start_2'], ['endEvent','lan_end_end']];
    unnamed.forEach(function(p){
      var t = tagOf(out1, p[0], p[1]);
      if (!t) errs.push('leg2: no <bpmn:' + p[0] + ' id="' + p[1] + '"> (display id changed?)');
      else if (t.indexOf(' name=') >= 0) errs.push('leg1: ' + p[1] + ' saved with a name: ' + t);
      var n = byName[p[0] + ':' + p[1]];
      if (n && n.name !== '') errs.push('leg1: ' + p[1] + ' parsed with name ' + JSON.stringify(n.name));
    });
    if (out1.indexOf('name="Order received"') < 0) errs.push('leg3: named start event lost its name');
    if (out1.indexOf('name="Order closed"') < 0) errs.push('leg3: named end event lost its name');
    if (out1.indexOf('name="Task_1"') < 0) errs.push('leg4: unnamed task no longer labelled with its id');
    load(out1);
    var out2 = strip(buildBpmnXml(state));
    if (out2 !== out1) errs.push('leg5: second save differs from the first');
    var named = state.nodes.filter(function(n){ return n.name === 'Order received'; })[0];
    if (!named) errs.push('leg6: named start not found after reload');
    else {
      var id6 = displayIdOf(named); named.name = '';
      var out6 = strip(buildBpmnXml(state));
      var t6 = tagOf(out6, 'startEvent', id6);
      if (!t6 || t6.indexOf(' name=') >= 0) errs.push('leg6: a cleared name saved as ' + (t6 || '<missing ' + id6 + '>'));
    }
    return { ok: errs.length === 0, errs: errs };
  } catch (e) { return { ok: false, errs: ['exception: ' + (e && e.message || e)] }; }
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1218-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1218-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1218-udd-');
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
