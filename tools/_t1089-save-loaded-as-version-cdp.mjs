#!/usr/bin/env node
// _t1089-save-loaded-as-version-cdp.mjs — T-1089: Save of a map opened from a project lands as that
// project's next version.
//
// aef-greenfield-test (T-172 item 5): the owner opened project tobe-walkthrough-verkoop v1 — a file
// with no aef:workflowMeta — edited it and saved. The importer had derived the workflow id from the
// process id (Process_x -> process_x), so the Save created a NEW project process_x v1 and the owner
// "only saw version 1". Fix: the project load paths pass the project id; a file that declares no id
// takes it; a DECLARED id is kept (T-263) and Save asks before writing elsewhere.
//
// Drives the REAL editor runtime (openVersionInPlace / saveToProject / adoptImportedXml) against
// gallery-serve.py with a temp project store. Legs:
//   A  file WITHOUT workflowMeta saved as project P v1, opened through the project path:
//      editor id = P, no confirm, Save writes P v2, no process_* project appears
//   B  negative control — the same file as a USER import (no project): id derived from the file
//   C  file DECLARING another id, stored under project Q: id kept, Save asks first naming Q;
//      declining writes nothing anywhere
//   node tools/_t1089-save-loaded-as-version-cdp.mjs [--designer PATH]
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

// Shape of the reported file: a generator's BPMN with lanes and tasks but no aef:workflowMeta.
const NO_META = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" id="Defs_1" targetNamespace="https://example.invalid/t1089">
  <bpmn:process id="Process_walkthrough-sales" name="Walkthrough sales" isExecutable="false">
    <bpmn:laneSet id="LaneSet_1">
      <bpmn:lane id="lane_seller" name="Seller"><bpmn:flowNodeRef>t_lead</bpmn:flowNodeRef><bpmn:flowNodeRef>t_quote</bpmn:flowNodeRef></bpmn:lane>
    </bpmn:laneSet>
    <bpmn:task id="t_lead" name="Qualify lead"/>
    <bpmn:task id="t_quote" name="Send quote"/>
    <bpmn:sequenceFlow id="f1" sourceRef="t_lead" targetRef="t_quote"/>
  </bpmn:process>
</bpmn:definitions>`;
const DECLARED = NO_META.replace('isExecutable="false">',
  'isExecutable="false">\n    <bpmn:extensionElements><aef:workflowMeta xmlns:aef="http://anchorpoint.framework/aef/extensions" id="declared-other" version="1" schemaVersion="2" title="declared"/></bpmn:extensionElements>')
  .replace('<bpmn:definitions ', '<bpmn:definitions xmlns:aef="http://anchorpoint.framework/aef/extensions" ');

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof openVersionInPlace==='function'&&typeof saveToProject==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1089-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1089-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1089-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const seed = async (id, bpmn) => { const r = await fetch(BASE + '/api/save', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ id, bpmn, note: 'seed' }) }); const d = await r.json(); if (!d.ok) throw new Error('seed ' + id + ': ' + JSON.stringify(d)); };
    const versions = async id => { const r = await fetch(`${BASE}/api/versions?id=${encodeURIComponent(id)}`); if (!r.ok) return []; const d = await r.json(); return Array.isArray(d) ? d : (d.versions || []); };
    await seed('walkthrough-sales', NO_META);
    await seed('project-q', DECLARED);

    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    // Stubs: no modal note, no thumbnail render, confirm() recorded and answered by window.__ANSWER__.
    await ev(cmd, `window.__CONFIRMS__ = []; window.__ANSWER__ = true;
      promptSaveNote = async () => ''; captureThumbnail = async () => null;
      window.confirm = m => { window.__CONFIRMS__.push(String(m)); return window.__ANSWER__; }; true`);

    // A — project load of a file without workflowMeta
    await ev(cmd, `openVersionInPlace('walkthrough-sales', 1).then(() => true)`);
    const idA = await ev(cmd, `state.workflowMeta.id`);
    leg(idA === 'walkthrough-sales', 'A1 opened from project P: editor workflow id = P', 'id=' + idA);
    await ev(cmd, `window.__CONFIRMS__ = []; saveToProject().then(() => true)`);
    const vA = await versions('walkthrough-sales');
    const confA = await ev(cmd, `window.__CONFIRMS__`);
    leg(vA.length === 2 && confA.length === 0, 'A2 Save writes P v2 without a confirm', `versions=${vA.length} confirms=${JSON.stringify(confA)}`);
    const stray = await versions('process_walkthrough-sales');
    leg(stray.length === 0, 'A3 no stray process_* project was created', 'process_walkthrough-sales versions=' + stray.length);

    // B — negative control: a user import of the same file keeps the file-derived id
    const idB = await ev(cmd, `(adoptImportedXml(${JSON.stringify(NO_META)}, { userImport: true }), state.workflowMeta.id)`);
    leg(idB === 'process_walkthrough-sales', 'B user import (no project) keeps the id derived from the file', 'id=' + idB);

    // C — declared id differs from the project: kept, and Save asks first; declining writes nothing
    await ev(cmd, `openVersionInPlace('project-q', 1).then(() => true)`);
    const idC = await ev(cmd, `state.workflowMeta.id`);
    leg(idC === 'declared-other', 'C1 a DECLARED workflowMeta id is kept (T-263)', 'id=' + idC);
    await ev(cmd, `window.__CONFIRMS__ = []; window.__ANSWER__ = false; saveToProject().then(() => true)`);
    const confC = await ev(cmd, `window.__CONFIRMS__`);
    leg(confC.some(m => m.includes('project "project-q"') && m.includes('"declared-other"')), 'C2 Save asks first, naming the project and the target id', JSON.stringify(confC));
    const vQ = await versions('project-q'), vD = await versions('declared-other');
    leg(vQ.length === 1 && vD.length === 0, 'C3 declining writes nothing anywhere', `project-q=${vQ.length} declared-other=${vD.length}`);
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
  for (const l of legs) console.log(`${l.ok ? 'PASS' : 'FAIL'}  ${l.name}${l.detail ? ' — ' + l.detail : ''}`);
  const ok = legs.length === 7 && legs.every(l => l.ok);
  console.log(ok ? `${legs.length}/7 legs passed` : `FAILED (${legs.filter(l => !l.ok).length} of ${legs.length})`);
  process.exitCode = ok ? 0 : 1;
}
main();
