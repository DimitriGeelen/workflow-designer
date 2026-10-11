#!/usr/bin/env node
// _t1129-optional-select-empty-cdp.mjs — T-1129: an optional select must offer an empty choice, or an unset field
// DISPLAYS its first option (and writes it on any change). Drives the REAL editor:
//   A  guard: every FIELD_META entry with special 'select' starts with '' (the next optional select cannot repeat it)
//   B  live DOM: an unset Agent type (service task) and an unset Decision owner (gateway) read '' in the details view
//   C  choosing a value writes it to the model and the export; choosing '' again removes it from the export
//   D  an element that HAS a value still shows it
//   E  export of every examples/ file byte-identical to the 0.17.0 release's (no value changed by the fix)
//   node tools/_t1129-optional-select-empty-cdp.mjs [--designer PATH]   (the 0.17.0 designer must FAIL A and B)
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
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
const argv = process.argv.slice(2);
const DESIGNER = (argv.indexOf('--designer') >= 0 && argv[argv.indexOf('--designer') + 1]) || join(REPO, 'src', 'aef-workflow-designer.html');
const BASELINE = join(REPO, 'dist', 'aef-workflow-designer-0.17.0.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const LOAD = xml => `(function(){ adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); renderAll(); return true; })()`;
const SYN = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" id="Defs_1" targetNamespace="https://example.invalid/t1129">
  <bpmn:process id="Process_t1129" isExecutable="false">
    <bpmn:laneSet id="LaneSet_1"><bpmn:lane id="lane_a" name="Agent"><bpmn:flowNodeRef>s1</bpmn:flowNodeRef><bpmn:flowNodeRef>s2</bpmn:flowNodeRef><bpmn:flowNodeRef>g1</bpmn:flowNodeRef></bpmn:lane></bpmn:laneSet>
    <bpmn:serviceTask id="s1" name="Unset agent"><bpmn:extensionElements><aef:meta endpoint="svc/call"/></bpmn:extensionElements></bpmn:serviceTask>
    <bpmn:serviceTask id="s2" name="Set agent"><bpmn:extensionElements><aef:meta agentType="human"/></bpmn:extensionElements></bpmn:serviceTask>
    <bpmn:exclusiveGateway id="g1" name="Decide"/>
    <bpmn:sequenceFlow id="f1" sourceRef="s1" targetRef="g1"/>
    <bpmn:sequenceFlow id="f2" sourceRef="g1" targetRef="s2"/>
  </bpmn:process>
</bpmn:definitions>`;
const BYNAME = name => `(state.nodes.find(function(x){ return x.name === ${JSON.stringify(name)}; }) || {}).uid`;
// The select for a field label, in the side panel with every field shown (Show all fields on).
const SELVAL = (uid, label) => `(function(){ setViewPref('showAllFields', true); selection = { kind: 'node', id: ${JSON.stringify(uid)} }; multiSelect = new Set([${JSON.stringify(uid)}]); renderProperties();
  var f = Array.prototype.slice.call(document.querySelectorAll('#properties .field')).find(function(x){ var l = x.querySelector('.field-label'); return l && l.firstChild.textContent.trim() === ${JSON.stringify(label)}; });
  var s = f && f.querySelector('select'); return s ? { value: s.value, options: Array.prototype.map.call(s.options, function(o){ return o.value; }) } : null; })()`;
const CHOOSE = (uid, label, v) => `(function(){ selection = { kind: 'node', id: ${JSON.stringify(uid)} }; renderProperties();
  var f = Array.prototype.slice.call(document.querySelectorAll('#properties .field')).find(function(x){ var l = x.querySelector('.field-label'); return l && l.firstChild.textContent.trim() === ${JSON.stringify(label)}; });
  var s = f.querySelector('select'); s.value = ${JSON.stringify(v)}; s.dispatchEvent(new Event('change', { bubbles: true })); s.dispatchEvent(new Event('input', { bubbles: true }));
  return state.nodes.find(function(x){ return x.uid === ${JSON.stringify(uid)}; }).aef.agentType; })()`;

async function exportsOf(cmd, BASE, page, corpus) {
  await cmd('Page.navigate', { url: `${BASE}/${page}` }); await waitReady(cmd); await sleep(300);
  const out = {};
  for (const f of corpus) { await ev(cmd, LOAD(readFileSync(f, 'utf8'))); await sleep(30); out[f] = await ev(cmd, `buildBpmnXml(state)`); }
  return out;
}

async function main() {
  if (!existsSync(DESIGNER) || !existsSync(BASELINE)) { console.log(JSON.stringify({ ok: false, error: 'missing designer or baseline' })); process.exitCode = 2; return; }
  const corpus = [];
  const walk = d => { for (const e of readdirSync(d, { withFileTypes: true })) { const p = join(d, e.name); if (e.isDirectory()) walk(p); else if (e.name.endsWith('.bpmn')) corpus.push(p); } };
  walk(join(REPO, 'examples'));
  const doc = mkdtempSync(join(tmpdir(), 't1129-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1129-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  copyFileSync(BASELINE, join(doc, 'baseline.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1129-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  try {
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) break; } catch (_) {} await sleep(100); }
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; }; try { localStorage.clear(); } catch (_) {}' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(300);

    // A — guard over every select
    const bad = await ev(cmd, `Object.keys(FIELD_META).filter(function(k){ var m = FIELD_META[k]; return m.special === 'select' && (!Array.isArray(m.options) || m.options[0] !== ''); })`);
    leg(bad.length === 0, 'A every optional select in FIELD_META starts with an empty choice', bad);

    // B — live DOM, unset
    await ev(cmd, LOAD(SYN)); await sleep(150);
    const U = await ev(cmd, BYNAME('Unset agent')), S = await ev(cmd, BYNAME('Set agent')), G = await ev(cmd, BYNAME('Decide'));
    const a = await ev(cmd, SELVAL(U, 'Agent type'));
    const gTypes = await ev(cmd, `Object.keys(AEF_FIELDS).filter(function(t){ return (AEF_FIELDS[t] || []).indexOf('decisionOwner') >= 0; })`);
    const g = gTypes.includes('exclusiveGateway') ? await ev(cmd, SELVAL(G, 'Decision owner')) : { value: '', options: [''], note: 'decisionOwner not offered on exclusiveGateway: ' + gTypes.join(',') };
    leg(a && a.value === '' && g && g.value === '', 'B unset Agent type and Decision owner display the empty choice', { a, g, gTypes });

    // C — choose, then clear
    const set = await ev(cmd, CHOOSE(U, 'Agent type', 'termlink-worker'));
    const x1 = await ev(cmd, `buildBpmnXml(state)`);
    await ev(cmd, CHOOSE(U, 'Agent type', ''));
    const x2 = await ev(cmd, `buildBpmnXml(state)`);
    const has = x => /agentType="termlink-worker"/.test(x);
    leg(set === 'termlink-worker' && has(x1) && !has(x2) && !/agentType=""/.test(x2), 'C choose writes it; the empty choice removes it from the export', { set, x1: has(x1), x2: has(x2) });

    // D — a set value still shows
    const d = await ev(cmd, SELVAL(S, 'Agent type'));
    leg(d && d.value === 'human', 'D a set value still shows', d);
    await ev(cmd, `(setViewPref('showAllFields', false), true)`);

    // E — export parity with 0.17.0
    const now = await exportsOf(cmd, BASE, 'designer.html', corpus);
    const was = await exportsOf(cmd, BASE, 'baseline.html', corpus);
    const firstDiff = (a, b) => { const A = a.split('\n'), B = b.split('\n'); for (let i = 0; i < Math.max(A.length, B.length); i++) if (A[i] !== B[i]) return { line: i + 1, now: (A[i] || '').trim().slice(0, 200), was: (B[i] || '').trim().slice(0, 200) }; return null; };
    // A map whose file has no workflowMeta uuid gets a FRESH one minted on every load (by design, T-226), so two
    // loads always differ there; compare without it for those files only.
    const norm = (f, x) => /<aef:workflowMeta[^>]*\suuid="/.test(readFileSync(f, 'utf8')) ? x : x.replace(/(<aef:workflowMeta[^>]*?)\suuid="[^"]*"/, '$1');
    const diffs = corpus.filter(f => norm(f, now[f]) !== norm(f, was[f])).map(f => ({ file: f.replace(REPO + '/', ''), at: firstDiff(norm(f, now[f]), norm(f, was[f])) }));
    leg(diffs.length === 0, `E export of ${corpus.length} examples identical to 0.17.0`, diffs);
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  const ok = legs.length > 0 && legs.every(l => l.ok);
  for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'} ${l.name}${l.ok ? '' : '  ' + JSON.stringify(l.detail).slice(0, 700)}`);
  console.log(`T-1129: ${legs.filter(l => l.ok).length}/${legs.length}`);
  process.exitCode = ok ? 0 : 1;
}
main();
