#!/usr/bin/env node
// _t1126-field-suggestions-cdp.mjs — T-1126 (T-1118 B3): "Suggest as a field" records a suggestion; only the operator's
// tools/field-suggestion.py turns it into a field. Drives the REAL editor, gallery-serve.py and the CLI:
//   A  server: POST records, a repeat merges (maps seen), a bad key is refused 400; GET lists
//   B  the panel: an unknown key under "Other extensions" shows its evidence ("on 2 of 3 userTask elements") and
//      "Suggest as a field"; a key derived from the diagram (gatewayKind) has no button
//   C  clicking records it (count 2/3, examples) and the button reads "Suggested ✓"; NOTHING became a field
//   D  CLI approve: the project profile gets fields.approvalLimit with approved_by/approved_at; the suggestion is
//      approved; a profile entry WITHOUT approval is refused whole (422)
//   E  after approval the key is an Extensions field labelled as approved, gone from "Other extensions", editable;
//      an unchanged map exports byte-identical to before; an edit lands in the export
//   F  CLI reject: the button reads "Rejected"
//   G  standalone (file://): the button is disabled with the reason
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn, execFileSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CLI = join(REPO, 'tools/field-suggestion.py');   // spelled out: the unwired-guard census reads tools/<name>
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
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" id="Defs_1" targetNamespace="https://example.invalid/t1126">
  <bpmn:process id="Process_t1126" isExecutable="false">
    <bpmn:extensionElements><aef:workflowMeta id="map-s" uuid="11111111-2222-3333-4444-555555555555" version="1" schemaVersion="2" title="map-s"/></bpmn:extensionElements>
    <bpmn:laneSet id="LaneSet_1"><bpmn:lane id="lane_h" name="Human"><bpmn:flowNodeRef>u1</bpmn:flowNodeRef><bpmn:flowNodeRef>u2</bpmn:flowNodeRef><bpmn:flowNodeRef>u3</bpmn:flowNodeRef><bpmn:flowNodeRef>g1</bpmn:flowNodeRef></bpmn:lane></bpmn:laneSet>
    <bpmn:userTask id="u1" name="Approve small"><bpmn:extensionElements><aef:meta approvalLimit="5000"/></bpmn:extensionElements></bpmn:userTask>
    <bpmn:userTask id="u2" name="Approve large"><bpmn:extensionElements><aef:meta approvalLimit="50000"/></bpmn:extensionElements></bpmn:userTask>
    <bpmn:userTask id="u3" name="Review"/>
    <bpmn:exclusiveGateway id="g1" name="Route"><bpmn:extensionElements><aef:meta gatewayKind="decision"/></bpmn:extensionElements></bpmn:exclusiveGateway>
    <bpmn:sequenceFlow id="f1" sourceRef="u1" targetRef="g1"/>
    <bpmn:sequenceFlow id="f2" sourceRef="g1" targetRef="u2"/>
    <bpmn:sequenceFlow id="f3" sourceRef="g1" targetRef="u3"/>
  </bpmn:process>
</bpmn:definitions>`;
const BYNAME = name => `(state.nodes.find(function(x){ return x.name === ${JSON.stringify(name)}; }) || {}).uid`;
const SELECT = uid => `(function(){ selection = { kind: 'node', id: ${JSON.stringify(uid)} }; multiSelect = new Set([${JSON.stringify(uid)}]); renderProperties(); return true; })()`;
const PANEL = `(function(){
  var secs = Array.prototype.slice.call(document.querySelectorAll('#properties .props-section'));
  function sec(re){ return secs.find(function(x){ var t = x.querySelector('.props-section-title'); return t && re.test(t.textContent); }); }
  var ext = sec(/^Extensions/), oth = sec(/^Other extensions/);
  function labels(s){ return s ? Array.prototype.slice.call(s.querySelectorAll(':scope > .field')).map(function(f){ var l = f.querySelector('.field-label'); return l ? l.firstChild.textContent.trim() : ''; }) : []; }
  var btns = oth ? Array.prototype.slice.call(oth.querySelectorAll('[data-testid="suggest-field"]')).map(function(b){ return { key: b.dataset.key, text: b.textContent, disabled: b.disabled, title: b.title }; }) : [];
  var evid = oth ? Array.prototype.slice.call(oth.querySelectorAll('.suggest-row .field-hint')).map(function(e){ return e.textContent; }) : [];
  return { ext: labels(ext), other: labels(oth), btns: btns, evid: evid }; })()`;
const cli = (repo, ...a) => { try { return { rc: 0, out: execFileSync('python3', [CLI, '--repo', repo, ...a]).toString() }; } catch (e) { return { rc: e.status, out: String(e.stdout || '') + String(e.stderr || '') }; } };

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1126-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1126-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1126-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1900,1000', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  const post = async b => { const r = await fetch(BASE + '/api/field-suggestions', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(b) }); return { code: r.status, body: await r.json().catch(() => null) }; };
  const list = async () => (await (await fetch(BASE + '/api/field-suggestions')).json()).suggestions;
  const shot = async (cmd, name) => { if (!process.env.T1126_SHOTS) return; mkdirSync(process.env.T1126_SHOTS, { recursive: true });
    const r = await ev(cmd, `(function(){ var b = document.getElementById('properties').getBoundingClientRect(); return { x: b.x, y: b.y, w: b.width, h: Math.min(b.height, 1000) }; })()`);
    const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: r.x, y: r.y, width: r.w, height: r.h, scale: 1 }, captureBeyondViewport: true });
    writeFileSync(join(process.env.T1126_SHOTS, name), Buffer.from(s.data, 'base64')); };
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));

    // A — server
    const a1 = await post({ type: 'serviceTask', key: 'costCentre', count: 1, total: 4, examples: ['CC-1'], map: 'other-map' });
    const a2 = await post({ type: 'serviceTask', key: 'costCentre', count: 2, total: 4, examples: ['CC-1', 'CC-2'], map: 'map-s' });
    const a3 = await post({ type: 'serviceTask', key: '../x', count: 1, total: 1 });
    const l1 = await list();
    const cc = l1.find(s => s.key === 'costCentre');
    leg(a1.code === 200 && a2.code === 200 && a3.code === 400 && l1.length === 1 && cc.count === 2 && cc.maps.length === 2 && cc.status === 'pending',
      'A records, merges a repeat, refuses a bad key; GET lists', { a1: a1.code, a2: a2.code, a3: a3.code, cc });

    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; }; try { localStorage.clear(); } catch (_) {}' });
    const boot = async () => {
      await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(400);
      await ev(cmd, `loadFieldProfile().then(function(){ return true; })`);
      await ev(cmd, LOAD(SYN)); await sleep(150);
      await ev(cmd, `(_fieldSuggestions = null, loadFieldSuggestions().then(function(){ return true; }))`);
    };
    await boot();
    const U1 = await ev(cmd, BYNAME('Approve small')), G1 = await ev(cmd, BYNAME('Route'));
    const exportBefore = await ev(cmd, `buildBpmnXml(state)`);

    // B — evidence + button; derived key has none
    await ev(cmd, SELECT(U1)); let p = await ev(cmd, PANEL);
    const bB = p.btns.find(b => b.key === 'approvalLimit');
    await ev(cmd, SELECT(G1)); const pg = await ev(cmd, PANEL);
    leg(p.other.includes('approvalLimit') && bB && !bB.disabled && /Suggest as a field/.test(bB.text)
        && p.evid.some(e => /approvalLimit · on 2 of 3 userTask elements/.test(e))
        && pg.other.includes('gatewayKind') && !pg.btns.some(b => b.key === 'gatewayKind'),
      'B evidence + button on an unknown key; none on a derived key', { p, pg });

    // C — click records; nothing became a field
    await ev(cmd, SELECT(U1));
    await ev(cmd, `(function(){ var b = document.querySelector('#properties [data-testid="suggest-field"][data-key="approvalLimit"]'); b.click(); return true; })()`);
    await sleep(500);
    p = await ev(cmd, PANEL);
    await ev(cmd, `(document.getElementById('properties').scrollTop = 1e6, true)`); await shot(cmd, 't1126-suggested.png');
    const sug = (await list()).find(s => s.key === 'approvalLimit');
    leg(sug && sug.status === 'pending' && sug.type === 'userTask' && sug.count === 2 && sug.total === 3 && sug.examples.length === 2
        && p.btns.some(b => b.key === 'approvalLimit' && /Suggested/.test(b.text) && b.disabled) && !p.ext.includes('Approval limit'),
      'C click records (2/3, examples), button says Suggested, no field yet', { sug, p });

    // D — CLI approve; a profile entry without approval is refused
    const d1 = cli(repo, 'approve', '--type', 'userTask', '--key', 'approvalLimit', '--label', 'Approval limit', '--hint', 'amount in EUR', '--by', 'operator-test');
    const prof = JSON.parse(readFileSync(join(repo, 'field-profile.json'), 'utf8'));
    const st = (await list()).find(s => s.key === 'approvalLimit').status;
    const cur = await (await fetch(BASE + '/api/field-profile')).json();
    const bad = JSON.parse(JSON.stringify(prof)); delete bad.fields.approvalLimit.approved_by;
    const put = await fetch(BASE + '/api/field-profile', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ profile: bad, base: cur.base }) });
    leg(d1.rc === 0 && prof.fields && prof.fields.approvalLimit && prof.fields.approvalLimit.approved_by === 'operator-test' && prof.fields.approvalLimit.approved_at
        && JSON.stringify(prof.fields.approvalLimit.types) === '["userTask"]' && st === 'approved' && put.status === 422,
      'D approve writes fields.approvalLimit with approval and marks it approved; an unapproved entry is refused (422)', { d1, fields: prof.fields, st, put: put.status });

    // E — the field, after approval
    await boot();
    const U1b = await ev(cmd, BYNAME('Approve small'));
    const exportAfter = await ev(cmd, `buildBpmnXml(state)`);
    await ev(cmd, SELECT(U1b)); p = await ev(cmd, PANEL); await shot(cmd, 't1126-approved.png');
    const hint = await ev(cmd, `(function(){ var f = Array.prototype.slice.call(document.querySelectorAll('#properties .field')).find(function(x){ var l = x.querySelector('.field-label'); return l && l.firstChild.textContent.trim() === 'Approval limit'; }); return f ? f.querySelector('.field-label').textContent : null; })()`);
    await ev(cmd, `(function(){ var f = Array.prototype.slice.call(document.querySelectorAll('#properties .field')).find(function(x){ var l = x.querySelector('.field-label'); return l && l.firstChild.textContent.trim() === 'Approval limit'; });
      var i = f.querySelector('textarea, input'); i.focus(); i.value = '7500'; i.dispatchEvent(new Event('input', { bubbles: true })); i.dispatchEvent(new Event('change', { bubbles: true })); i.blur(); return true; })()`);
    const edited = await ev(cmd, `buildBpmnXml(state)`);
    leg(p.ext.includes('Approval limit') && !p.other.includes('approvalLimit') && /approved field/.test(hint || '')
        && exportAfter === exportBefore && /approvalLimit="7500"/.test(edited),
      'E approved key is an Extensions field (marked approved), gone from Other; unchanged export identical; edit exported',
      { ext: p.ext, other: p.other, hint, same: exportAfter === exportBefore, edited: /approvalLimit="7500"/.test(edited) });

    // F — reject
    await post({ type: 'userTask', key: 'riskScore', count: 1, total: 3, examples: ['high'], map: 'map-s' });
    const f1 = cli(repo, 'reject', '--type', 'userTask', '--key', 'riskScore', '--reason', 'covered by tier', '--by', 'operator-test');
    await ev(cmd, `(state.nodes.find(function(x){ return x.name === 'Review'; }).aef = { riskScore: 'high' }, _fieldSuggestions = null, loadFieldSuggestions().then(function(){ return true; }))`);
    const U3 = await ev(cmd, BYNAME('Review'));
    await ev(cmd, SELECT(U3)); p = await ev(cmd, PANEL);
    const rb = p.btns.find(b => b.key === 'riskScore');
    leg(f1.rc === 0 && rb && /Rejected/.test(rb.text) && rb.disabled && /covered by tier/.test(rb.title), 'F rejected: the button reads Rejected, with the reason', { f1, rb });
    leg(cl.errs.length === 0, 'no page errors', cl.errs.slice(0, 3));

    // G — standalone
    await cmd('Page.navigate', { url: pathToFileURL(join(doc, 'designer.html')).href });
    const t0 = Date.now(); while (Date.now() - t0 < 15000) { const ok = await ev(cmd, `typeof _appReady !== 'undefined' && _appReady === true`).catch(() => false); if (ok) break; await sleep(150); }
    await sleep(400);
    await ev(cmd, LOAD(SYN)); const U1c = await ev(cmd, BYNAME('Approve small'));
    await ev(cmd, SELECT(U1c)); p = await ev(cmd, PANEL);
    const gb = p.btns.find(b => b.key === 'approvalLimit');
    leg(gb && gb.disabled && /project server/.test(gb.title), 'G standalone: disabled, says it needs the project server', gb);
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  const ok = legs.length > 0 && legs.every(l => l.ok);
  for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'} ${l.name}${l.ok ? '' : '  ' + JSON.stringify(l.detail).slice(0, 900)}`);
  console.log(`T-1126: ${legs.filter(l => l.ok).length}/${legs.length}`);
  process.exitCode = ok ? 0 : 1;
}
main();
