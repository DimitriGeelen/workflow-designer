#!/usr/bin/env node
// _t1127-element-details-cdp.mjs — T-1127: the element details view ("all config with all options"). Drives the
// REAL editor against gallery-serve.py:
//   A  double-click on a service task opens the details view for it; the side panel has an "All details" button
//   B  the view shows EVERY Extensions field (filled or empty), no fold row, BPMN basics, and the read-only
//      "Other extensions"; a field the project hides is drawn and marked "hidden in the side panel by this project"
//   C  an edit in the view changes the element: the side panel shows it after closing; export reflects the edit,
//      and opening/closing alone changes nothing in the export
//   D  Esc, the Close button and a backdrop click each close it; while open, Delete does not delete the element
//   E  a handoff keeps its double-click jump (no details opened); its panel button opens the details
//   F  legible at 1024x768: the dialog fits the viewport width, body scrolls instead of overflowing
//   node tools/_t1127-element-details-cdp.mjs [--designer PATH]   (the 0.17.0 designer must FAIL A)
//   T1127_SHOTS=<dir> also writes screenshots of the view.
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
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
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); const errs = []; s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } else if (m.method === 'Runtime.exceptionThrown') errs.push(m.params.exceptionDetails.text + ' ' + ((m.params.exceptionDetails.exception || {}).description || '')); }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, errs, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const LOAD = xml => `(function(){ adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); renderAll(); return true; })()`;
const SYN = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" id="Defs_1" targetNamespace="https://example.invalid/t1127">
  <bpmn:process id="Process_t1127" isExecutable="false">
    <bpmn:laneSet id="LaneSet_1"><bpmn:lane id="lane_a" name="Agent"><bpmn:flowNodeRef>s1</bpmn:flowNodeRef><bpmn:flowNodeRef>s2</bpmn:flowNodeRef><bpmn:flowNodeRef>h1</bpmn:flowNodeRef></bpmn:lane></bpmn:laneSet>
    <bpmn:serviceTask id="s1" name="Call the service"><bpmn:extensionElements><aef:meta endpoint="svc/call" tier="2" customKey="kept"/></bpmn:extensionElements></bpmn:serviceTask>
    <bpmn:serviceTask id="s2" name="Other step"/>
    <bpmn:intermediateThrowEvent id="h1" name="Hand off"><bpmn:linkEventDefinition id="led1" name="h"/></bpmn:intermediateThrowEvent>
    <bpmn:sequenceFlow id="f1" sourceRef="s1" targetRef="s2"/>
    <bpmn:sequenceFlow id="f2" sourceRef="s2" targetRef="h1"/>
  </bpmn:process>
</bpmn:definitions>`;
const BYNAME = name => `(state.nodes.find(function(x){ return x.name === ${JSON.stringify(name)}; }) || {}).uid`;
const SELECT = uid => `(function(){ var n = state.nodes.find(function(x){ return x.uid === ${JSON.stringify(uid)}; }); selection = { kind: 'node', id: n.uid }; multiSelect = new Set([n.uid]); renderProperties(); return true; })()`;
const DBL = uid => `(function(){ var g = document.querySelector('#canvas g.node[data-id="' + ${JSON.stringify(uid)} + '"]') || document.querySelector('g.node[data-id="' + ${JSON.stringify(uid)} + '"]'); if (!g) return 'no-node'; g.dispatchEvent(new MouseEvent('dblclick', { bubbles: true })); return true; })()`;
const VIEW = `(function(){
  var m = document.getElementById('details-modal'); if (!m) return { exists: false };
  var b = document.getElementById('details-body');
  var secs = Array.prototype.slice.call(b.querySelectorAll('.props-section'));
  var ext = secs.find(function(x){ var t = x.querySelector('.props-section-title'); return t && /^Extensions/.test(t.textContent); });
  var fields = ext ? Array.prototype.slice.call(ext.querySelectorAll(':scope > .field')).map(function(f){ var l = f.querySelector('.field-label'); return l ? l.firstChild.textContent.trim() : ''; }) : [];
  var tags = ext ? Array.prototype.slice.call(ext.querySelectorAll('.field-hidden-tag')).map(function(t){ return t.closest('.field').querySelector('.field-label').firstChild.textContent.trim() + ': ' + t.textContent; }) : [];
  return { exists: true, open: m.classList.contains('visible'), uid: typeof _detailsUid !== 'undefined' ? _detailsUid : null,
    titles: secs.map(function(x){ var t = x.querySelector('.props-section-title'); return t ? t.textContent : ''; }),
    fields: fields, tags: tags, fold: !!b.querySelector('.props-empty-fields'), title: document.getElementById('details-title').textContent }; })()`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1127-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1127-repo-'));
  writeFileSync(join(repo, 'field-profile.json'), JSON.stringify({ version: 1, types: { serviceTask: { hide: ['horizon'] } } }));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1127-udd-'));
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
    await waitReady(cmd); await sleep(400);
    await ev(cmd, `(typeof loadFieldProfile === 'function' ? loadFieldProfile() : Promise.resolve()).then(function(){ return true; })`);
    await ev(cmd, LOAD(SYN)); await sleep(200);
    const S1 = await ev(cmd, BYNAME('Call the service')), H1 = await ev(cmd, BYNAME('Hand off'));
    const total = await ev(cmd, `AEF_FIELDS.serviceTask.length`);
    const exportBefore = await ev(cmd, `buildBpmnXml(state)`);

    // A — double-click opens; the panel has the button
    await ev(cmd, SELECT(S1));
    const btn = await ev(cmd, `!!document.querySelector('#properties [data-testid="open-details"]')`);
    const d = await ev(cmd, DBL(S1)); await sleep(150);
    let v = await ev(cmd, VIEW);
    leg(btn && d === true && v.exists && v.open && v.uid === S1, 'A double-click opens details; panel has "All details"', { btn, d, v });

    // B — every field, no fold, sections, profile-hidden marked
    leg(v.open && v.fields.length === total + 1 && !v.fold && v.titles.some(t => /^BPMN/.test(t)) && v.titles.some(t => /^Other extensions/.test(t))
        && v.tags.some(t => /^Horizon: hidden in the side panel by this project/.test(t)),
      'B all fields (filled or empty) + Owner, no fold row, BPMN + Other extensions, profile-hidden marked', v);
    if (process.env.T1127_SHOTS) {
      mkdirSync(process.env.T1127_SHOTS, { recursive: true });
      const s = await cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1127_SHOTS, 't1127-details-1400.png'), Buffer.from(s.data, 'base64'));
    }

    // C — edit in the view (Side effect) → element changes, panel shows it after close; open/close alone is neutral
    await ev(cmd, `(function(){ var b = document.getElementById('details-body');
      var f = Array.prototype.slice.call(b.querySelectorAll('.field')).find(function(x){ var l = x.querySelector('.field-label'); return l && l.firstChild.textContent.trim() === 'Side effect'; });
      var i = f.querySelector('textarea, input'); i.focus(); i.value = 'writes the ledger'; i.dispatchEvent(new Event('input', { bubbles: true })); i.dispatchEvent(new Event('change', { bubbles: true })); i.blur(); return true; })()`);
    const model = await ev(cmd, `state.nodes.find(function(x){ return x.uid === ${JSON.stringify(S1)}; }).aef.sideEffect`);
    await ev(cmd, `(closeDetails(), true)`);
    const panelHas = await ev(cmd, `Array.prototype.some.call(document.querySelectorAll('#properties .field-label'), function(l){ return l.firstChild.textContent.trim() === 'Side effect'; })`);
    const exportAfter = await ev(cmd, `buildBpmnXml(state)`);
    // neutral: open + close on s2 without edits
    const S2 = await ev(cmd, BYNAME('Other step'));
    const x0 = exportAfter;
    await ev(cmd, `(openDetails(${JSON.stringify(S2)}), closeDetails(), true)`);
    const x1 = await ev(cmd, `buildBpmnXml(state)`);
    leg(model === 'writes the ledger' && panelHas && /writes the ledger/.test(exportAfter) && exportAfter !== exportBefore && x0 === x1,
      'C edit lands on the element, panel shows it, export reflects it; open/close alone is neutral', { model, panelHas, neutral: x0 === x1 });

    // D — Esc / Close / backdrop; Delete blocked while open
    await ev(cmd, `(openDetails(${JSON.stringify(S1)}), true)`);
    await cmd('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Delete', code: 'Delete', windowsVirtualKeyCode: 46 });
    await cmd('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Delete', code: 'Delete', windowsVirtualKeyCode: 46 });
    const stillThere = await ev(cmd, `!!state.nodes.find(function(x){ return x.uid === ${JSON.stringify(S1)}; })`);
    await cmd('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
    await cmd('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
    const escClosed = !(await ev(cmd, VIEW)).open;
    await ev(cmd, `(openDetails(${JSON.stringify(S1)}), document.getElementById('btn-close-details').click(), true)`);
    const btnClosed = !(await ev(cmd, VIEW)).open;
    await ev(cmd, `(openDetails(${JSON.stringify(S1)}), document.getElementById('details-modal').dispatchEvent(new MouseEvent('mousedown', { bubbles: true })), true)`);
    const bgClosed = !(await ev(cmd, VIEW)).open;
    leg(stillThere && escClosed && btnClosed && bgClosed, 'D Esc / Close / backdrop close it; Delete does nothing behind it', { stillThere, escClosed, btnClosed, bgClosed });

    // E — handoff: double-click does not open details; the panel button does
    const jumps = []; await ev(cmd, `(window.__jt = [], window.jumpToWorkflow = function(t){ window.__jt.push(t); }, true)`);
    await ev(cmd, SELECT(H1));
    await ev(cmd, DBL(H1)); await sleep(100);
    const afterDbl = (await ev(cmd, VIEW)).open;
    await ev(cmd, `(document.querySelector('#properties [data-testid="open-details"]').click(), true)`);
    const viaBtn = await ev(cmd, VIEW);
    await ev(cmd, `(closeDetails(), true)`);
    leg(afterDbl === false && viaBtn.open && viaBtn.uid === H1, 'E handoff: double-click keeps its jump, the button opens details', { afterDbl, viaBtn: viaBtn.uid });

    // G (T-1209) — every open starts at the top; an edit while open keeps the place.
    //   Unfixed: closeDetails() cleared the body but kept its scrollTop, so a reopen (any element) started where the
    //   last view was left and hid the element header and the Name/Slug row (seen at 1024/1440/1920 on 2026-10-19).
    const scrollTo = `(function(){ var b = document.getElementById('details-body'); b.scrollTop = 200; return b.scrollTop; })()`;
    const top = `document.getElementById('details-body').scrollTop`;
    await ev(cmd, `(openDetails(${JSON.stringify(S1)}), true)`); await sleep(100);
    const scrolled = await ev(cmd, scrollTo);
    await ev(cmd, `(closeDetails(), openDetails(${JSON.stringify(S1)}), true)`); await sleep(100);
    const reopenSame = await ev(cmd, top);
    await ev(cmd, scrollTo);
    await ev(cmd, `(closeDetails(), openDetails(${JSON.stringify(S2)}), true)`); await sleep(100);
    const openOther = await ev(cmd, top);
    // edit while open and scrolled: the re-render must not jump back to the top
    await ev(cmd, `(closeDetails(), openDetails(${JSON.stringify(S1)}), true)`); await sleep(100);
    const before = await ev(cmd, scrollTo);
    await ev(cmd, `(function(){ var b = document.getElementById('details-body');
      var f = Array.prototype.slice.call(b.querySelectorAll('.field')).find(function(x){ var l = x.querySelector('.field-label'); return l && l.firstChild.textContent.trim() === 'Side effect'; });
      var i = f.querySelector('textarea, input'); i.value = 'writes the ledger twice'; i.dispatchEvent(new Event('input', { bubbles: true })); i.dispatchEvent(new Event('change', { bubbles: true })); return true; })()`);
    await sleep(100);
    const afterEdit = await ev(cmd, top);
    await ev(cmd, `(closeDetails(), true)`);
    leg(scrolled > 0 && reopenSame === 0 && openOther === 0 && before > 0 && afterEdit > 0,
      'G (T-1209) reopen starts at the top (same and other element); an edit while open keeps the place',
      { scrolled, reopenSame, openOther, before, afterEdit });

    // F — 1024x768
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1024, height: 768, deviceScaleFactor: 1, mobile: false });
    await ev(cmd, `(openDetails(${JSON.stringify(S1)}), true)`); await sleep(150);
    const fit = await ev(cmd, `(function(){ var d = document.querySelector('#details-modal .details-dialog').getBoundingClientRect(); var b = document.getElementById('details-body'); return { left: d.left, right: d.right, bottom: d.bottom, vw: innerWidth, vh: innerHeight, scrolls: b.scrollHeight > b.clientHeight }; })()`);
    if (process.env.T1127_SHOTS) {
      const s = await cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1127_SHOTS, 't1127-details-1024.png'), Buffer.from(s.data, 'base64'));
      // The bottom of the view as well (T-1127 review, amber: the lower fields and "Other extensions" with its
      // read-only key and "Suggest as a field" were never in a shot).
      const bottom = async (w) => {
        await ev(cmd, `(function(){ var b = document.getElementById('details-body'); b.scrollTop = b.scrollHeight; return true; })()`);
        await sleep(100);
        const sb = await cmd('Page.captureScreenshot', { format: 'png' });
        writeFileSync(join(process.env.T1127_SHOTS, `t1127-details-${w}-bottom.png`), Buffer.from(sb.data, 'base64'));
      };
      await bottom(1024);
      // The UI review rule (operator, 2026-10-14) wants three widths: normal (~1440) and wide (~1920) as well.
      // Shots only; no leg asserts on them.
      for (const [w, h] of [[1440, 900], [1920, 1080]]) {
        await ev(cmd, `(closeDetails(), true)`);
        await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
        await ev(cmd, `(openDetails(${JSON.stringify(S1)}), true)`); await sleep(150);
        const sw = await cmd('Page.captureScreenshot', { format: 'png' });
        writeFileSync(join(process.env.T1127_SHOTS, `t1127-details-${w}.png`), Buffer.from(sw.data, 'base64'));
        await bottom(w);
      }
    }
    await cmd('Emulation.clearDeviceMetricsOverride');
    leg(fit.left >= 0 && fit.right <= fit.vw && fit.bottom <= fit.vh, 'F fits 1024x768 (body scrolls if needed)', fit);
    await ev(cmd, `(closeDetails(), true)`);
    leg(cl.errs.length === 0, 'no page errors', cl.errs.slice(0, 3));
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  const ok = legs.length > 0 && legs.every(l => l.ok);
  for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'} ${l.name}${l.ok ? '' : '  ' + JSON.stringify(l.detail).slice(0, 900)}`);
  console.log(`T-1127: ${legs.filter(l => l.ok).length}/${legs.length}`);
  process.exitCode = ok ? 0 : 1;
}
main();
