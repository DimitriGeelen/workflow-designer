#!/usr/bin/env node
// _t1124-hide-empty-fields-cdp.mjs — T-1124 (T-1118 B1): the properties panel folds empty Extensions fields
// into one "+ N empty fields" row; a field with a value is never hidden; Settings "Show all fields" restores
// the old panel; nothing changes in what is saved. Drives the REAL editor:
//   A  a service task with 2 filled fields: those 2 + Owner drawn, one "+ 11 empty fields" row, no empty field
//   B  clicking the row draws all 13 in AEF_FIELDS order; a value typed into one survives a re-render;
//      selecting another node and coming back folds the (still empty) others again, keeps the filled one
//   C  "Show all fields" on: 13 fields + Owner, no row; Reset turns it off
//   D  value-never-hidden: on every service task in examples/, every field with a value is drawn
//   E  corpus median of Extensions rows drawn by default over examples/ service tasks <= 4 (hypothesis of T-1118)
//   F  export byte-identical with the setting on and off, across examples/
//   node tools/_t1124-hide-empty-fields-cdp.mjs [--designer PATH]   (the 0.17.0 designer must FAIL A)
//   T1124_SHOTS=<dir> also writes panel screenshots (light, dark; folded and opened).
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
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
const argv = process.argv.slice(2);
const DESIGNER = (argv.indexOf('--designer') >= 0 && argv[argv.indexOf('--designer') + 1]) || join(REPO, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const LOAD = xml => `(function(){ adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); renderAll(); return true; })()`;
// One synthetic service task with exactly 2 filled fields (endpoint, tier) — the corpus median.
const SYN = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" id="Defs_1" targetNamespace="https://example.invalid/t1124">
  <bpmn:process id="Process_t1124" isExecutable="false">
    <bpmn:laneSet id="LaneSet_1"><bpmn:lane id="lane_a" name="Agent"><bpmn:flowNodeRef>s1</bpmn:flowNodeRef><bpmn:flowNodeRef>s2</bpmn:flowNodeRef></bpmn:lane></bpmn:laneSet>
    <bpmn:serviceTask id="s1" name="Call the service"><bpmn:extensionElements><aef:meta endpoint="svc/call" tier="2"/></bpmn:extensionElements></bpmn:serviceTask>
    <bpmn:serviceTask id="s2" name="Other step"/>
    <bpmn:sequenceFlow id="f1" sourceRef="s1" targetRef="s2"/>
  </bpmn:process>
</bpmn:definitions>`;
// The Extensions section of the panel, as drawn: field labels, Owner, the fold row.
const PANEL = `(function(){
  var secs = Array.prototype.slice.call(document.querySelectorAll('#properties .props-section'));
  var s = secs.find(function(x){ var t = x.querySelector('.props-section-title'); return t && /^Extensions/.test(t.textContent); });
  if (!s) return null;
  var fields = Array.prototype.slice.call(s.querySelectorAll(':scope > .field')).map(function(f){ var l = f.querySelector('.field-label'); return l ? l.firstChild.textContent.trim() : ''; });
  var row = s.querySelector('.props-empty-fields');
  return { fields: fields, row: row ? row.textContent : null, rows: fields.length + (row ? 1 : 0) }; })()`;
// Select by uid (findNode matches uid); BYNAME resolves the synthetic tasks by their name.
const SELECT = uid => `(function(){ var n = state.nodes.find(function(x){ return x.uid === ${JSON.stringify(uid)}; }); if (!n) return false; selection = { kind: 'node', id: n.uid }; renderProperties(); return true; })()`;
const BYNAME = name => `(state.nodes.find(function(x){ return x.name === ${JSON.stringify(name)}; }) || {}).uid`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const corpus = [];
  const walk = d => { for (const e of readdirSync(d, { withFileTypes: true })) { const p = join(d, e.name); if (e.isDirectory()) walk(p); else if (e.name.endsWith('.bpmn')) corpus.push(p); } };
  walk(join(REPO, 'examples'));
  const doc = mkdtempSync(join(tmpdir(), 't1124-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1124-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1124-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; }; try { localStorage.clear(); } catch (_) {}' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    const hasPref = await ev(cmd, `typeof viewPrefs === 'object' && 'showAllFields' in viewPrefs && typeof setViewPref === 'function'`);
    const setAll = on => ev(cmd, hasPref ? `(setViewPref('showAllFields', ${on}), true)` : 'true');
    const shot = async name => { if (!process.env.T1124_SHOTS) return; mkdirSync(process.env.T1124_SHOTS, { recursive: true });
      const r = await ev(cmd, `(function(){ var b = document.getElementById('properties').getBoundingClientRect(); return { x: b.x, y: b.y, w: b.width, h: Math.min(b.height, 900) }; })()`);
      const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: r.x, y: r.y, width: r.w, height: r.h, scale: 1 } });
      writeFileSync(join(process.env.T1124_SHOTS, name), Buffer.from(s.data, 'base64')); };

    // A — folded by default
    await setAll(false);
    await ev(cmd, LOAD(SYN)); await sleep(200);
    const S1 = await ev(cmd, BYNAME('Call the service')), S2 = await ev(cmd, BYNAME('Other step'));
    await ev(cmd, SELECT(S1));
    let p = await ev(cmd, PANEL);
    const total = await ev(cmd, `AEF_FIELDS.serviceTask.length`);
    leg(p && p.fields.includes('Endpoint') && p.fields.includes('Tier') && p.fields.includes('Owner') && p.fields.length === 3
        && p.row === `+ ${total - 2} empty fields`, 'A folded: 2 filled + Owner + one fold row', p);
    await shot('t1124-folded.png');

    // B — open in place, order, typed value survives, re-select folds
    await ev(cmd, `document.querySelector('#properties .props-empty-fields').click(); true`);
    p = await ev(cmd, PANEL);
    const order = await ev(cmd, `AEF_FIELDS.serviceTask.map(function(f){ return FIELD_META[f].special === 'tier' ? 'Tier' : FIELD_META[f].label; })`);
    leg(p && p.row === null && JSON.stringify(p.fields.filter(f => f !== 'Owner')) === JSON.stringify(order), 'B opened: all fields in AEF_FIELDS order, no row', { got: p && p.fields, want: order });
    await shot('t1124-opened.png');
    await ev(cmd, `(function(){ var n = state.nodes.find(function(x){ return x.uid === ${JSON.stringify(S1)}; }); n.aef.note = 'typed'; renderProperties(); return true; })()`);
    p = await ev(cmd, PANEL);
    leg(p && p.fields.includes('Note') && p.row === null, 'B typed value survives a re-render while open', p);
    await ev(cmd, SELECT(S2)); await ev(cmd, SELECT(S1));
    p = await ev(cmd, PANEL);
    leg(p && p.fields.includes('Note') && p.fields.length === 4 && p.row === `+ ${total - 3} empty fields`, 'B re-select folds the empty ones, keeps the filled', p);

    // C — Show all fields, then Reset
    await setAll(true); await ev(cmd, SELECT(S1));
    p = await ev(cmd, PANEL);
    leg(p && p.row === null && p.fields.length === total + 1, 'C "Show all fields": every field + Owner, no row', p);
    const reset = await ev(cmd, `(function(){ document.getElementById('btn-settings-reset').click(); return viewPrefs.showAllFields; })()`).catch(e => 'err ' + e.message);
    leg(reset === false, 'C Settings → Reset turns "Show all fields" off', reset);

    // G — a handoff's target picker is never folded, even with no target yet (T-163/T-308)
    await ev(cmd, LOAD(SYN.replace('<bpmn:serviceTask id="s2" name="Other step"/>',
      '<bpmn:serviceTask id="s2" name="Other step"/><bpmn:intermediateCatchEvent id="h1" name="Handoff in"><bpmn:linkEventDefinition id="led1" name="h"/></bpmn:intermediateCatchEvent>'))); await sleep(150);
    const H1 = await ev(cmd, BYNAME('Handoff in'));
    await ev(cmd, `(function(){ var n = state.nodes.find(function(x){ return x.uid === ${JSON.stringify(H1)}; }); if (n && n.type !== 'linkEventCatch') { n.type = 'linkEventCatch'; } if (typeof sessionAuthoredLinks !== 'undefined' && n) sessionAuthoredLinks.add(n.uid); return true; })()`);
    await ev(cmd, SELECT(H1));
    const gText = await ev(cmd, `document.getElementById('properties').textContent`);
    leg(/Choose from project/.test(gText), 'G handoff target picker drawn while empty', gText.slice(0, 200));

    // D, E, F — the corpus
    const rows = []; const hidden = []; const diffs = []; let svc = 0;
    for (const f of corpus) {
      const xml = readFileSync(f, 'utf8');
      await setAll(false); await ev(cmd, LOAD(xml)); await sleep(60);
      const ids = await ev(cmd, `state.nodes.filter(function(n){ return n.type === 'serviceTask'; }).map(function(n){ return n.uid; })`);
      for (const id of ids) {
        svc++;
        await ev(cmd, SELECT(id));
        const q = await ev(cmd, PANEL);
        rows.push(q ? q.rows : 99);
        const filled = await ev(cmd, `(function(){ var n = state.nodes.find(function(x){ return x.uid === ${JSON.stringify(id)}; });
          return AEF_FIELDS.serviceTask.filter(function(k){ return aefFieldHasValue(n, k, FIELD_META[k]); }).map(function(k){ return FIELD_META[k].special === 'tier' ? 'Tier' : FIELD_META[k].label; }); })()`).catch(() => null);
        if (!filled) { hidden.push({ f, id, err: 'no aefFieldHasValue' }); continue; }
        const miss = filled.filter(l => !(q && q.fields.includes(l)));
        if (miss.length) hidden.push({ f: f.replace(REPO + '/', ''), id, miss });
      }
      const off = await ev(cmd, `buildBpmnXml(state)`);
      await setAll(true);
      const on = await ev(cmd, `buildBpmnXml(state)`);
      if (off !== on) diffs.push(f.replace(REPO + '/', ''));
    }
    await setAll(false);
    const sorted = rows.slice().sort((a, b) => a - b);
    const median = sorted.length ? sorted[Math.floor(sorted.length / 2)] : null;
    leg(svc > 0 && hidden.length === 0, `D value-never-hidden on ${svc} service tasks in ${corpus.length} files`, hidden.slice(0, 5));
    leg(median !== null && median <= 4, `E corpus median Extensions rows drawn by default = ${median} (target <= 4; was ${total + 1})`, { svc, rows: sorted });
    leg(diffs.length === 0, `F export unchanged by the setting across ${corpus.length} files`, diffs);

    if (process.env.T1124_SHOTS) {   // dark mode of the folded panel
      await ev(cmd, LOAD(SYN)); await ev(cmd, SELECT(S1));
      await cmd('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-color-scheme', value: 'dark' }] });
      await ev(cmd, `(function(){ if (typeof setTheme === 'function') setTheme('dark'); else document.documentElement.setAttribute('data-theme', 'dark'); renderProperties(); return true; })()`); await sleep(200);
      await shot('t1124-folded-dark.png');
      await ev(cmd, `document.querySelector('#properties .props-empty-fields').click(); true`); await sleep(100);
      await shot('t1124-opened-dark.png');
    }
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  const ok = legs.length > 0 && legs.every(l => l.ok);
  for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'} ${l.name}${l.ok ? '' : '  ' + JSON.stringify(l.detail).slice(0, 600)}`);
  console.log(`T-1124: ${legs.filter(l => l.ok).length}/${legs.length}`);
  process.exitCode = ok ? 0 : 1;
}
main();
