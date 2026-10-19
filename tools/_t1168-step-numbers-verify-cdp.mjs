#!/usr/bin/env node
// _t1168-step-numbers-verify-cdp.mjs — verify T-1168 (T-1094 GO, option 2): the step number in a node id
// counts ACTIVITIES only; events and gateways carry a type word instead of a number.
//
// Serves the editor from a TEMP docroot (gallery-serve.py) and drives it in ISOLATED headless chromium,
// the same harness as _t911/_t1155. Every check reads the ids the EXPORT writes (displayIdOf on the live
// state, the same function buildBpmnXml uses) and the exported XML itself, not the source.
//
// WHAT IT ASSERTS, per map:
//   1. In every lane, the activities' numbers are exactly 1..n in x order (no gap, no repeat).
//   2. No event or gateway id carries a number; each carries its type word (start|end|gw|link|error|timer|
//      message|ev).
//   3. Every node id in the exported XML is unique, and every attachedToRef / sourceRef / targetRef names one.
//   4. Export -> parseBpmnXml -> export is byte-identical (the new ids round-trip).
// Maps: task-lifecycle (gateways between activities, start + end events), boundary-events (attached events),
// and an in-browser case with two same-named gateways in one lane (the de-duplication suffix). Pass
// T1168_EXTRA_MAP=<path to a .bpmn> to run the same checks on one more map (used once on Greenfield's
// after-owner-straightened.bpmn, which is not committed here).
//
// Exit 0 = pass. Exit 1 = a step failed. Exit 2 = harness could not run.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const MAPS = [
  ['task-lifecycle', join(REPO, 'examples/aef-processes/rendered/task-lifecycle.bpmn')],
  ['boundary-events', join(REPO, 'tests/fixtures/aef-bpmn/boundary-events.bpmn')],
];
if (process.env.T1168_EXTRA_MAP) MAPS.push(['extra-' + basename(process.env.T1168_EXTRA_MAP, '.bpmn'), process.env.T1168_EXTRA_MAP]);
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// One in-page check over the live state and its export. Returns per-lane findings.
const CHECK = `(function(){
  var WORDS = ['start','end','gw','link','error','timer','message','ev'];
  var ACT = function(n){ return isStepNumbered(n); };
  refreshDisplayIds();
  var lanes = {};
  state.nodes.forEach(function(n){ (lanes[n.lane] = lanes[n.lane] || []).push(n); });
  var problems = [], perLane = {};
  Object.keys(lanes).forEach(function(l){
    var ns = lanes[l].slice().sort(function(a,b){ return a.x - b.x || a.uid.localeCompare(b.uid); });
    var acts = ns.filter(ACT), nums = acts.map(function(n){ var m = displayIdOf(n).match(/^[^_]+_(\\d+)_/); return m ? +m[1] : null; });
    perLane[l] = ns.map(function(n){ return displayIdOf(n); });
    nums.forEach(function(v,i){ if (v !== i+1) problems.push('lane ' + l + ': activity ' + displayIdOf(acts[i]) + ' should be number ' + (i+1)); });
    ns.filter(function(n){ return !ACT(n); }).forEach(function(n){
      var m = displayIdOf(n).match(/^[^_]+_([a-z]+)_/);
      if (/^[^_]+_\\d+_/.test(displayIdOf(n))) problems.push('lane ' + l + ': ' + n.type + ' ' + displayIdOf(n) + ' carries a number');
      else if (!m || WORDS.indexOf(m[1]) < 0) problems.push('lane ' + l + ': ' + n.type + ' ' + displayIdOf(n) + ' has no type word');
    });
  });
  var xml = buildBpmnXml(state);
  var doc = new DOMParser().parseFromString(xml, 'application/xml');
  var ids = {}, dup = [];
  Array.prototype.forEach.call(doc.getElementsByTagName('*'), function(e){
    var id = e.getAttribute('id'); if (!id) return;
    if (ids[id]) dup.push(id); ids[id] = true;
  });
  var dangling = [];
  Array.prototype.forEach.call(doc.getElementsByTagName('*'), function(e){
    ['attachedToRef','sourceRef','targetRef'].forEach(function(a){ var v = e.getAttribute(a); if (v && !ids[v]) dangling.push(a + '=' + v); });
  });
  var again = buildBpmnXml(parseBpmnXml(xml));
  return { problems: problems, dup: dup, dangling: dangling, roundtrip: again === xml, lanes: perLane };
})()`;

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't1168-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1168-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  for (const [name, path] of MAPS) copyFileSync(path, join(doc, 'rendered', name + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1168-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1280,860', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    const hasFn = async () => ev(cmd, `typeof isStepNumbered === 'function'`);

    for (const [name] of MAPS) {
      await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${name}.bpmn` });
      await sleep(300); await waitReady(cmd); await sleep(400);
      if (!(await hasFn())) { push(`${name}: designer has isStepNumbered (the activity rule)`, false, 'missing'); continue; }
      const r = await ev(cmd, CHECK);
      push(`${name}: activities numbered 1..n per lane, events/gateways carry a type word`, r.problems.length === 0, r.problems.length ? r.problems : r.lanes);
      push(`${name}: exported ids unique, every ref resolves`, r.dup.length === 0 && r.dangling.length === 0, { dup: r.dup, dangling: r.dangling });
      push(`${name}: export -> import -> export is byte-identical`, r.roundtrip === true, r.roundtrip);
    }

    // Two same-named gateways in one lane: the type-word ids must still be unique (suffix).
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/task-lifecycle.bpmn` });
    await sleep(300); await waitReady(cmd); await sleep(400);
    const dupCase = await ev(cmd, `(function(){
      var g = state.nodes.filter(function(n){ return /Gateway$/.test(n.type); })[0];
      if (!g) return { ok:false, reason:'no gateway in task-lifecycle' };
      var c = JSON.parse(JSON.stringify(g)); c.uid = 'u-t1168-copy'; c.id = c.uid; c.x = g.x + 7;
      state.nodes.push(c); refreshDisplayIds();
      var a = displayIdOf(g), b = displayIdOf(c);
      state.nodes.pop(); refreshDisplayIds();
      return { ok:true, a:a, b:b };
    })()`);
    push('two same-named gateways in one lane get distinct type-word ids', dupCase.ok && dupCase.a !== dupCase.b
      && /_gw_/.test(dupCase.a) && /_gw_/.test(dupCase.b), dupCase);

    verdict.pass = verdict.steps.length > 0 && verdict.steps.every(s => s.pass);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), steps: verdict.steps }, null, 2) + '\n');
    process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
