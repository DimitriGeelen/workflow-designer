#!/usr/bin/env node
// _t1125-field-profile-cdp.mjs — T-1125 (T-1118 B2): a project field profile (field-profile.json at the gallery
// repo root, GET /api/field-profile) decides which Extensions fields the panel shows. Drives the REAL editor
// against gallery-serve.py:
//   A  endpoint: absent → 404; valid → 200 + profile; bad JSON → 422; show∩hide → 422; unknown key → 422
//   B  hide + show: a hidden EMPTY field is not drawn and not offered under "+ N"; a hidden field WITH a value is
//      drawn, tagged "hidden in this project"; a pinned (show) field is drawn while empty; the fold count excludes both
//   C  "+ N empty fields" opened: hidden fields still not drawn
//   D  "Show all fields": every field drawn, no hidden tag
//   E  a profile key the type does not offer is ignored (no error, same panel)
//   F  a refused (malformed) profile → designer default, Settings readout says "refused"
//   G  export byte-identical with and without a profile across examples/
//   H  standalone (no API): status 'standalone', panel = designer default, no page error
//   node tools/_t1125-field-profile-cdp.mjs [--designer PATH]
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, writeFileSync, rmSync } from 'node:fs';
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
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const LOAD = xml => `(function(){ adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); renderAll(); return true; })()`;
const SYN = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" id="Defs_1" targetNamespace="https://example.invalid/t1125">
  <bpmn:process id="Process_t1125" isExecutable="false">
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
  var tagged = Array.prototype.slice.call(s.querySelectorAll('.field-hidden-tag')).map(function(t){ return t.closest('.field').querySelector('.field-label').firstChild.textContent.trim(); });
  var row = s.querySelector('.props-empty-fields');
  return { fields: fields, tagged: tagged, row: row ? row.textContent : null }; })()`;
const SELECT = uid => `(function(){ var n = state.nodes.find(function(x){ return x.uid === ${JSON.stringify(uid)}; }); if (!n) return false; selection = { kind: 'node', id: n.uid }; renderProperties(); return true; })()`;
const BYNAME = name => `(state.nodes.find(function(x){ return x.name === ${JSON.stringify(name)}; }) || {}).uid`;
const PROFILE = { version: 1, types: { serviceTask: { show: ['sideEffect', 'bogusKey'], hide: ['endpoint', 'horizon', 'tier'] } } };

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const corpus = [];
  const walk = d => { for (const e of readdirSync(d, { withFileTypes: true })) { const p = join(d, e.name); if (e.isDirectory()) walk(p); else if (e.name.endsWith('.bpmn')) corpus.push(p); } };
  walk(join(REPO, 'examples'));
  const doc = mkdtempSync(join(tmpdir(), 't1125-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1125-repo-'));
  const PF = join(repo, 'field-profile.json');
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1125-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--allow-file-access-from-files', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));

    // A — endpoint
    const get = async () => { const r = await fetch(BASE + '/api/field-profile'); return { code: r.status, body: await r.json().catch(() => null) }; };
    const a1 = await get();
    writeFileSync(PF, JSON.stringify(PROFILE)); const a2 = await get();
    writeFileSync(PF, '{not json'); const a3 = await get();
    writeFileSync(PF, JSON.stringify({ version: 1, types: { serviceTask: { show: ['tier'], hide: ['tier'] } } })); const a4 = await get();
    writeFileSync(PF, JSON.stringify({ version: 1, types: {}, extra: true })); const a5 = await get();
    leg(a1.code === 404 && a2.code === 200 && a2.body.ok && a2.body.profile.types.serviceTask && a3.code === 422 && a4.code === 422 && a5.code === 422,
      'A endpoint: 404 absent, 200 valid, 422 bad JSON / show∩hide / unknown key', [a1.code, a2.code, a3.code, a4.code, a5.code]);

    writeFileSync(PF, JSON.stringify(PROFILE));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; }; try { localStorage.clear(); } catch (_) {}' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(400);
    const reload = async () => { await ev(cmd, `loadFieldProfile().then(function(){ return _fieldProfileStatus; })`); };
    await reload();
    const status = await ev(cmd, `_fieldProfileStatus`);
    await ev(cmd, LOAD(SYN)); await sleep(150);
    const S1 = await ev(cmd, BYNAME('Call the service')), S2 = await ev(cmd, BYNAME('Other step'));
    const total = await ev(cmd, `AEF_FIELDS.serviceTask.length`);

    // B — s1 has endpoint + tier (both hidden by the profile, both with a value)
    await ev(cmd, SELECT(S1));
    let p = await ev(cmd, PANEL);
    leg(status === 'loaded' && p && p.fields.includes('Tier') && p.fields.includes('Endpoint') && p.fields.includes('Side effect')
        && JSON.stringify(p.tagged.sort()) === JSON.stringify(['Endpoint', 'Tier']) && !p.fields.includes('Horizon')
        && p.row === `+ ${total - 4} empty fields`,
      'B hidden-with-value drawn + tagged; pinned empty drawn; hidden empty neither drawn nor folded', { status, p, want: total - 4 });
    if (process.env.T1125_SHOTS) {   // the panel with two tagged fields and a pinned empty one
      mkdirSync(process.env.T1125_SHOTS, { recursive: true });
      const r = await ev(cmd, `(function(){ var b = document.getElementById('properties').getBoundingClientRect(); return { x: b.x, y: b.y, w: b.width, h: Math.min(b.height, 900) }; })()`);
      const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: r.x, y: r.y, width: r.w, height: r.h, scale: 1 } });
      writeFileSync(join(process.env.T1125_SHOTS, 't1125-profile.png'), Buffer.from(s.data, 'base64'));
    }
    await ev(cmd, SELECT(S2));
    p = await ev(cmd, PANEL);
    leg(p && !p.fields.includes('Endpoint') && !p.fields.includes('Tier') && p.fields.includes('Side effect') && p.tagged.length === 0
        && p.row === `+ ${total - 4} empty fields`, 'B empty node: hidden fields absent, pinned present', p);

    // C — open the fold: hidden still absent
    await ev(cmd, `document.querySelector('#properties .props-empty-fields').click(); true`);
    p = await ev(cmd, PANEL);
    leg(p && p.row === null && !p.fields.includes('Endpoint') && !p.fields.includes('Horizon') && p.fields.length === total - 3 + 1,
      'C opened fold: every field but the 3 hidden (+ Owner)', p);

    // D — Show all fields
    await ev(cmd, `(setViewPref('showAllFields', true), true)`); await ev(cmd, SELECT(S1));
    p = await ev(cmd, PANEL);
    leg(p && p.fields.length === total + 1 && p.tagged.length === 0 && p.row === null, 'D "Show all fields": all drawn, no hidden tag', p);
    await ev(cmd, `(setViewPref('showAllFields', false), true)`);

    // E — the unknown profile key (bogusKey) changed nothing and raised nothing
    leg(cl.errs.length === 0, 'E unknown profile key ignored, no page error', cl.errs.slice(0, 3));

    // F — a refused profile: designer default, readout says so
    writeFileSync(PF, '{not json'); await reload();
    const fStatus = await ev(cmd, `_fieldProfileStatus`);
    await ev(cmd, SELECT(S2)); p = await ev(cmd, PANEL);
    const readout = await ev(cmd, `(syncSettingsUI(), document.getElementById('set-field-profile-status').textContent)`);
    leg(/^refused/.test(fStatus) && /refused/.test(readout) && p && p.row === `+ ${total} empty fields`, 'F refused profile → designer default, readout says refused', { fStatus, readout, p });

    // G — export parity across examples/
    const diffs = [];
    for (const f of corpus) {
      await ev(cmd, LOAD(readFileSync(f, 'utf8'))); await sleep(40);
      writeFileSync(PF, '{"version":1,"types":{}}'); rmSync(PF); await reload();
      const without = await ev(cmd, `buildBpmnXml(state)`);
      writeFileSync(PF, JSON.stringify(PROFILE)); await reload();
      const withP = await ev(cmd, `buildBpmnXml(state)`);
      if (without !== withP) diffs.push(f.replace(REPO + '/', ''));
    }
    leg(diffs.length === 0, `G export unchanged by a profile across ${corpus.length} files`, diffs);

    // H — standalone: file:// (no API)
    await cmd('Page.navigate', { url: pathToFileURL(join(doc, 'designer.html')).href });
    const t0 = Date.now(); while (Date.now() - t0 < 15000) { const ok = await ev(cmd, `typeof _appReady !== 'undefined' && _appReady === true`).catch(() => false); if (ok) break; await sleep(150); }
    await sleep(500);
    const hStatus = await ev(cmd, `_fieldProfileStatus`);
    await ev(cmd, LOAD(SYN)); const H2 = await ev(cmd, BYNAME('Other step')); await ev(cmd, SELECT(H2));
    p = await ev(cmd, PANEL);
    leg(hStatus === 'standalone' && p && p.row === `+ ${total} empty fields`, 'H standalone: designer default, no profile request', { hStatus, p });
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  const ok = legs.length > 0 && legs.every(l => l.ok);
  for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'} ${l.name}${l.ok ? '' : '  ' + JSON.stringify(l.detail).slice(0, 700)}`);
  console.log(`T-1125: ${legs.filter(l => l.ok).length}/${legs.length}`);
  process.exitCode = ok ? 0 : 1;
}
main();
