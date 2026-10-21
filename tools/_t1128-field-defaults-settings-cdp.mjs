#!/usr/bin/env node
// _t1128-field-defaults-settings-cdp.mjs — T-1128: Settings → "Fields shown by default", per project and per map
// (map wins for the fields it mentions), saved through gallery-serve.py. Drives the REAL editor and Settings controls:
//   A  the section lists every field of the chosen type; the map scope is offered when the open map has a valid id
//   B  project scope: Hide horizon + Always show sideEffect → preview says so before Save; Save writes the project
//      file; after a reload the panel applies it (sideEffect drawn empty, horizon not offered)
//   C  map scope: Always show horizon (overrides the project's hide) + Hide endpoint → Save writes the map file; the
//      panel: horizon drawn, a FILLED endpoint drawn and tagged "hidden in this map", sideEffect still pinned
//      by the project (fall-through); Settings rows name the source of each state
//   D  a project file changed behind the designer's back → Save refused 409, message says so, file keeps the
//      outside change
//   E  Cancel discards a draft; the file is untouched
//   F  a map saved under a new id has no map settings: label shows the new id, status says so, panel = project only
//   G  export byte-identical with and without both profiles
//   H  standalone (file://): the section is read-only and says why
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const argv = process.argv.slice(2);
const DESIGNER = (argv.indexOf('--designer') >= 0 && argv[argv.indexOf('--designer') + 1]) || join(REPO, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); const errs = []; s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } else if (m.method === 'Runtime.exceptionThrown') errs.push(m.params.exceptionDetails.text + ' ' + ((m.params.exceptionDetails.exception || {}).description || '')); }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, errs, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const LOAD = xml => `(function(){ adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); renderAll(); return true; })()`;
const SYN = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" id="Defs_1" targetNamespace="https://example.invalid/t1128">
  <bpmn:process id="Process_t1128" isExecutable="false">
    <bpmn:laneSet id="LaneSet_1"><bpmn:lane id="lane_a" name="Agent"><bpmn:flowNodeRef>s1</bpmn:flowNodeRef><bpmn:flowNodeRef>s2</bpmn:flowNodeRef></bpmn:lane></bpmn:laneSet>
    <bpmn:serviceTask id="s1" name="Call the service"><bpmn:extensionElements><aef:meta endpoint="svc/call" tier="2"/></bpmn:extensionElements></bpmn:serviceTask>
    <bpmn:serviceTask id="s2" name="Other step"/>
    <bpmn:sequenceFlow id="f1" sourceRef="s1" targetRef="s2"/>
  </bpmn:process>
</bpmn:definitions>`;
const PANEL = `(function(){
  var secs = Array.prototype.slice.call(document.querySelectorAll('#properties .props-section'));
  var s = secs.find(function(x){ var t = x.querySelector('.props-section-title'); return t && /^Extensions/.test(t.textContent); });
  if (!s) return null;
  var fields = Array.prototype.slice.call(s.querySelectorAll(':scope > .field')).map(function(f){ var l = f.querySelector('.field-label'); return l ? l.firstChild.textContent.trim() : ''; });
  var tags = Array.prototype.slice.call(s.querySelectorAll('.field-hidden-tag')).map(function(t){ return t.closest('.field').querySelector('.field-label').firstChild.textContent.trim() + ': ' + t.textContent; });
  var row = s.querySelector('.props-empty-fields');
  return { fields: fields, tags: tags, row: row ? row.textContent : null }; })()`;
const SELECT = uid => `(function(){ var n = state.nodes.find(function(x){ return x.uid === ${JSON.stringify(uid)}; }); if (!n) return false; selection = { kind: 'node', id: n.uid }; renderProperties(); return true; })()`;
const BYNAME = name => `(state.nodes.find(function(x){ return x.name === ${JSON.stringify(name)}; }) || {}).uid`;
// Settings driving: open, choose type + scope, set a row, read rows/status, Save, Cancel.
const OPEN = `(openSettings(), true)`;
const SCOPE = s => `(function(){ var r = document.querySelector('input[name="set-fd-scope"][value="${s}"]'); r.checked = true; r.dispatchEvent(new Event('change')); return !r.disabled; })()`;
const TYPE = t => `(function(){ var s = document.getElementById('set-fd-type'); s.value = ${JSON.stringify(t)}; s.dispatchEvent(new Event('change')); return s.value; })()`;
const SETROW = (k, v) => `(function(){ var s = document.querySelector('#set-fd-rows select[data-key="${k}"]'); if (!s) return false; s.value = ${JSON.stringify(v)}; s.dispatchEvent(new Event('change')); return true; })()`;
const ROWS = `(function(){ var o = {}; document.querySelectorAll('#set-fd-rows .fd-eff').forEach(function(e){ o[e.dataset.key] = e.textContent; }); return { eff: o, n: document.querySelectorAll('#set-fd-rows select').length, disabled: Array.prototype.every.call(document.querySelectorAll('#set-fd-rows select'), function(s){ return s.disabled; }), status: document.getElementById('set-fd-status').textContent, mapLabel: document.getElementById('set-fd-map-label').textContent, mapDisabled: document.querySelector('input[name="set-fd-scope"][value="map"]').disabled }; })()`;
const SAVE = `(saveFieldDefaults().then(function(){ return document.getElementById('set-fd-status').textContent; }))`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const corpus = [];
  const walk = d => { for (const e of readdirSync(d, { withFileTypes: true })) { const p = join(d, e.name); if (e.isDirectory()) walk(p); else if (e.name.endsWith('.bpmn')) corpus.push(p); } };
  walk(join(REPO, 'examples'));
  const doc = mkdtempSync(join(tmpdir(), 't1128-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1128-repo-'));
  const PF = join(repo, 'field-profile.json');
  const MF = join(repo, '.editor-versions', 'map-a', 'field-profile.json');
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1128-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,1000', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  const shot = async (cmd, name, sel) => { if (!process.env.T1128_SHOTS) return; mkdirSync(process.env.T1128_SHOTS, { recursive: true });
    const r = await ev(cmd, `(function(){ var b = document.querySelector(${JSON.stringify(sel)}).getBoundingClientRect(); return { x: b.x, y: b.y, w: b.width, h: b.height }; })()`);
    const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: r.x, y: r.y, width: r.w, height: Math.min(r.h, 1000), scale: 1 }, captureBeyondViewport: true });
    writeFileSync(join(process.env.T1128_SHOTS, name), Buffer.from(s.data, 'base64')); };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; };' });
    const boot = async () => {
      await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(400);
      await ev(cmd, `loadFieldProfile().then(function(){ return true; })`);
      await ev(cmd, LOAD(SYN)); await sleep(150);
      await ev(cmd, `(state.workflowMeta.id = 'map-a', loadMapFieldProfile('map-a', true).then(function(){ return true; }))`);
    };
    await boot();
    const S1 = await ev(cmd, BYNAME('Call the service')), S2 = await ev(cmd, BYNAME('Other step'));
    const total = await ev(cmd, `AEF_FIELDS.serviceTask.length`);

    // A
    await ev(cmd, OPEN); await ev(cmd, TYPE('serviceTask')); await ev(cmd, SCOPE('project'));
    let r = await ev(cmd, ROWS);
    leg(r.n === total && !r.mapDisabled && /map-a/.test(r.mapLabel), 'A rows for every field; map scope offered for map-a', r);

    // B — project
    await ev(cmd, SETROW('horizon', 'hide')); await ev(cmd, SETROW('sideEffect', 'show'));
    r = await ev(cmd, ROWS);
    const preview = /hidden · project/.test(r.eff.horizon) && /always shown · project/.test(r.eff.sideEffect) && /Unsaved/.test(r.status);
    await shot(cmd, 't1128-settings-project.png', '#set-fd-section');
    const bMsg = await ev(cmd, SAVE);
    const pf = existsSync(PF) ? JSON.parse(readFileSync(PF, 'utf8')) : null;
    await boot();
    await ev(cmd, SELECT(S2)); let p = await ev(cmd, PANEL);
    leg(preview && /Saved/.test(bMsg) && pf && JSON.stringify(pf.types.serviceTask) === JSON.stringify({ hide: ['horizon'], show: ['sideEffect'] })
        && p && p.fields.includes('Side effect') && !p.fields.includes('Horizon') && p.row === `+ ${total - 2} empty fields`,
      'B project: preview, Save writes the file, reload applies it', { preview, bMsg, pf, p });

    // C — map
    await ev(cmd, OPEN); await ev(cmd, TYPE('serviceTask')); await ev(cmd, SCOPE('map'));
    await sleep(200);
    await ev(cmd, SETROW('horizon', 'show')); await ev(cmd, SETROW('endpoint', 'hide'));
    r = await ev(cmd, ROWS);
    await shot(cmd, 't1128-settings-map.png', '#set-fd-section');
    const cMsg = await ev(cmd, SAVE);
    const mf = existsSync(MF) ? JSON.parse(readFileSync(MF, 'utf8')) : null;
    r = await ev(cmd, ROWS);
    await ev(cmd, SELECT(S1)); p = await ev(cmd, PANEL);
    leg(/Saved/.test(cMsg) && mf && JSON.stringify(mf.types.serviceTask) === JSON.stringify({ hide: ['endpoint'], show: ['horizon'] })
        && /always shown · map/.test(r.eff.horizon) && /hidden · map/.test(r.eff.endpoint) && /always shown · project/.test(r.eff.sideEffect)
        && /shown when filled · designer default/.test(r.eff.note)
        && p && p.fields.includes('Horizon') && p.fields.includes('Endpoint') && p.fields.includes('Side effect')
        && p.tags.some(t => /^Endpoint: hidden in this map/.test(t)),
      'C map wins for its fields, falls through for the rest; provenance in rows and panel tag', { cMsg, mf, eff: r.eff, p });

    // D — 409
    const outside = { version: 1, types: { serviceTask: { hide: ['tier'] } } };
    writeFileSync(PF, JSON.stringify(outside));
    await ev(cmd, SCOPE('project')); await ev(cmd, SETROW('agentType', 'hide'));
    const dMsg = await ev(cmd, SAVE);
    const after = JSON.parse(readFileSync(PF, 'utf8'));
    leg(/changed elsewhere/.test(dMsg) && JSON.stringify(after) === JSON.stringify(outside)
        && (await ev(cmd, `JSON.stringify(_fieldProfile)`)) === JSON.stringify(outside),
      'D changed behind our back: 409, said so, outside change kept and reloaded', { dMsg, after });

    // E — Cancel
    const beforeE = readFileSync(PF, 'utf8');
    await ev(cmd, SETROW('note', 'hide'));
    const dirty = (await ev(cmd, ROWS)).status;
    await ev(cmd, `(document.getElementById('btn-fd-cancel').click(), true)`);
    const rE = await ev(cmd, ROWS);
    leg(/Unsaved/.test(dirty) && !/Unsaved/.test(rE.status) && readFileSync(PF, 'utf8') === beforeE && !/hidden · project/.test(rE.eff.note),
      'E Cancel discards the draft, file untouched', { dirty, rE });

    // F — copy under a new id
    await ev(cmd, `(state.workflowMeta.id = 'map-b', true)`);
    await ev(cmd, SCOPE('map')); await sleep(300);
    r = await ev(cmd, ROWS);
    await ev(cmd, SELECT(S1)); p = await ev(cmd, PANEL);
    leg(/map-b/.test(r.mapLabel) && /no settings of its own/.test(r.status) && p && !p.fields.includes('Horizon'),
      'F new id: no map settings, project only, Settings says so', { r, p });

    // G — export parity
    const diffs = [];
    for (const f of corpus) {
      await ev(cmd, LOAD(readFileSync(f, 'utf8'))); await sleep(30);
      const withP = await ev(cmd, `buildBpmnXml(state)`);
      const without = await ev(cmd, `(function(){ var a = _fieldProfile; _fieldProfile = null; var x = buildBpmnXml(state); _fieldProfile = a; return x; })()`);
      if (withP !== without) diffs.push(f.replace(REPO + '/', ''));
    }
    leg(diffs.length === 0, `G export unchanged by profiles across ${corpus.length} files`, diffs);

    // H — standalone
    await cmd('Page.navigate', { url: pathToFileURL(join(doc, 'designer.html')).href });
    const t0 = Date.now(); while (Date.now() - t0 < 15000) { const ok = await ev(cmd, `typeof _appReady !== 'undefined' && _appReady === true`).catch(() => false); if (ok) break; await sleep(150); }
    await sleep(400);
    await ev(cmd, OPEN); r = await ev(cmd, ROWS);
    leg(r.disabled && /Needs the project server/.test(r.status) && r.mapDisabled, 'H standalone: read-only with the reason', r);
    leg(cl.errs.length === 0, 'no page errors', cl.errs.slice(0, 3));
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  const ok = legs.length > 0 && legs.every(l => l.ok);
  for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'} ${l.name}${l.ok ? '' : '  ' + JSON.stringify(l.detail).slice(0, 900)}`);
  console.log(`T-1128: ${legs.filter(l => l.ok).length}/${legs.length}`);
  process.exitCode = ok ? 0 : 1;
}
main();
