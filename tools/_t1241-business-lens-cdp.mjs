#!/usr/bin/env node
// _t1241-business-lens-cdp.mjs — T-1241 (T-281 slice 1): the business lens, on aef-task-lifecycle.
// Drives the REAL editor headless (gallery-serve.py + the interim lens file + a field profile that hides fields).
// Legs:
//   1. business lens, canvas: 0 technical badges (id, io, constituents, authority, finding), pool label without the workflow id;
//      the SAME map in the "all" lens does draw them (the check is not vacuous);
//   2. business lens, side panel AND details view, every node: sections only BPMN / Extensions, BPMN fields only Name / Lane,
//      every Extensions field inside the business set, 0 fields the field profile hides (the profile hides fields
//      that carry values on this map, so the value-never-hidden rule would otherwise show them);
//   3. logical and technical lenses are wider than business (data-driven: same file), 'all' draws every field again;
//   4. switching lenses (and opening details) changes 0 bytes of buildBpmnXml output;
//   5. no lens definition (404): the switch offers only All and every field shows, as before.
// T1241_SRC substitutes another designer file. Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1241_SRC || join(REPO, 'src/aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }


const FIXTURE = join(REPO, '.agentic-framework/.context/designer/projects/aef-task-lifecycle/v3.bpmn');
const LENSFILE = join(REPO, 'lens-definition.interim.json');
const PROFILE = { version: 1, types: { serviceTask: { hide: ['note', 'sideEffect'] }, userTask: { hide: ['note'] }, exclusiveGateway: { hide: ['decisionOwner'] } } };

const ASSERT = `(async function(){
  var errs = [], info = {};
  var BADGES = '.node-id-badge,.node-io-badge,.node-authority-badge,.node-authority-missing,.node-finding-badge,.node-finding-pill';
  function labelsOf(root){ return Array.prototype.map.call(root.querySelectorAll('.field-label'), function(l){ return (l.firstChild ? l.firstChild.textContent : '').trim(); }); }
  function sections(root){ return Array.prototype.map.call(root.querySelectorAll('.props-section-title'), function(t){ return (t.firstChild ? t.firstChild.textContent : '').trim(); }); }
  function pick(n){ selection = { kind: 'node', id: n.id }; renderProperties(); }
  function lensFields(){ var l = lensSpec(); return l ? l.fields : null; }
  try {
    var xml = window.__FIXTURE__;
    adoptImportedXml(xml, { userImport: true }); renderAll();
    var base = buildBpmnXml(state);
    var nodes = state.nodes.slice();
    info.nodes = nodes.length;
    // wait for the lens definition and the field profile
    for (var i = 0; i < 100 && !(_lensDef && _fieldProfileStatus === 'loaded'); i++) await new Promise(function(r){ setTimeout(r, 100); });
    if (!_lensDef) { errs.push('lens definition not loaded'); return { ok: false, errs: errs, info: info }; }
    if (_fieldProfileStatus !== 'loaded') { errs.push('field profile not loaded: ' + _fieldProfileStatus); return { ok: false, errs: errs, info: info }; }
    var opts = Array.prototype.map.call(document.querySelectorAll('#lens-select option'), function(o){ return o.value; });
    info.options = opts;
    if (opts.join() !== 'business,logical,technical,all') errs.push('leg3: toolbar options are ' + opts.join());

    // ---- all lens: the baseline that proves the checks are not vacuous
    setLens('all');
    var allBadges = document.querySelectorAll(BADGES).length;
    info.allBadges = allBadges;
    if (allBadges === 0) errs.push('leg1: the all lens draws no badges at all — the business check would be vacuous');
    var allPanelFields = 0, allProfileHiddenWithValue = 0;
    nodes.forEach(function(n){ pick(n); allPanelFields += labelsOf(document.getElementById('properties')).length;
      var plan = fieldPlanFor(n.type); plan.hidden.forEach(function(k){ if (n.aef && n.aef[k]) allProfileHiddenWithValue++; }); });
    info.allPanelFields = allPanelFields; info.profileHiddenWithValue = allProfileHiddenWithValue;
    if (!allProfileHiddenWithValue) errs.push('leg2: the profile hides no field that has a value on this map — the profile check would be vacuous');

    // ---- business lens
    setLens('business');
    var L = lensSpec();
    var allowed = {}; L.fields.forEach(function(k){ allowed[fieldMetaFor(k).label] = k; });
    allowed['Owner'] = 'owner';
    var left = document.querySelectorAll(BADGES).length;
    if (left) errs.push('leg1: business lens still draws ' + left + ' technical badge(s): ' + Array.prototype.map.call(document.querySelectorAll(BADGES), function(e){ return e.getAttribute('class'); }).slice(0, 5).join(','));
    var pool = document.querySelector('.pool-label');
    if (pool && /workflow:/.test(pool.textContent)) errs.push('leg1: pool label still carries the workflow id: ' + pool.textContent);
    var bizFields = 0;
    nodes.forEach(function(n){
      var plan = fieldPlanFor(n.type);
      var hiddenLabels = {}; plan.hidden.forEach(function(k){ hiddenLabels[fieldMetaFor(k).label] = k; });
      ['panel', 'details'].forEach(function(where){
        var root;
        if (where === 'panel') { pick(n); root = document.getElementById('properties'); }
        else { openDetails(n.id); root = document.getElementById('details-body'); }
        var secs = sections(root).filter(function(t){ return t !== 'Workflow'; });
        secs.forEach(function(t){ if (t !== 'BPMN' && t !== 'Extensions') errs.push('leg2: ' + where + ' ' + n.id + ' shows section "' + t + '"'); });
        var bpmn = root.querySelectorAll('.props-section')[0];
        if (bpmn && bpmn.querySelector('.props-section-title').firstChild.textContent.trim() === 'BPMN') labelsOf(bpmn).forEach(function(l){ if (l !== 'Name' && l !== 'Lane') errs.push('leg2: ' + where + ' ' + n.id + ' BPMN field "' + l + '"'); });
        var ext = Array.prototype.filter.call(root.querySelectorAll('.props-section'), function(s){ return s.querySelector('.props-section-title').firstChild.textContent.trim() === 'Extensions'; })[0];
        if (ext) labelsOf(ext).forEach(function(l){
          if (!(l in allowed)) errs.push('leg2: ' + where + ' ' + n.id + ' shows "' + l + '" outside the business set');
          if (l in hiddenLabels) errs.push('leg2: ' + where + ' ' + n.id + ' shows "' + l + '" which the field profile hides');
          bizFields++;
        });
        if (/\\bhidden in\\b/.test(root.textContent)) errs.push('leg2: ' + where + ' ' + n.id + ' carries a "hidden in" tag: the lens must not draw profile-hidden fields');
        if (where === 'details') closeDetails();
      });
    });
    info.businessFields = bizFields;
    if (!bizFields) errs.push('leg2: no business field was drawn anywhere — the check is vacuous');

    // ---- logical / technical are wider (same data file), all restores every field
    var counts = {};
    ['business', 'logical', 'technical', 'all'].forEach(function(name){
      setLens(name); var t = 0, b = document.querySelectorAll(BADGES).length;
      nodes.forEach(function(n){ pick(n); t += labelsOf(document.getElementById('properties')).length; });
      counts[name] = { fields: t, badges: b };
    });
    info.counts = counts;
    if (!(counts.business.fields < counts.logical.fields && counts.logical.fields < counts.technical.fields)) errs.push('leg3: field counts are not business < logical < technical: ' + JSON.stringify(counts));
    if (counts.all.fields < counts.technical.fields) errs.push('leg3: all shows fewer fields than technical: ' + JSON.stringify(counts));
    if (counts.all.badges !== allBadges) errs.push('leg3: returning to all draws ' + counts.all.badges + ' badges, not ' + allBadges);

    // ---- bytes
    ['business', 'logical', 'technical', 'all', 'business'].forEach(function(name){
      setLens(name); nodes.forEach(function(n){ pick(n); });
      openDetails(nodes[0].id); closeDetails();
      var out = buildBpmnXml(state);
      if (out !== base) errs.push('leg4: lens ' + name + ' changed the exported XML (' + base.length + ' -> ' + out.length + ' bytes)');
    });
    return { ok: errs.length === 0, errs: errs, info: info };
  } catch (e) { return { ok: false, errs: ['exception: ' + (e && e.stack || e)], info: info }; }
})()`;

const ASSERT_NO_LENS = `(async function(){
  var errs = [];
  try {
    for (var i = 0; i < 30; i++) await new Promise(function(r){ setTimeout(r, 100); });
    var opts = Array.prototype.map.call(document.querySelectorAll('#lens-select option'), function(o){ return o.value; });
    if (opts.join() !== 'all') errs.push('leg5: without a definition the switch offers ' + opts.join());
    if (_lensDef) errs.push('leg5: a definition loaded');
    localStorage.setItem('aefLens', 'business');
    if (lensSpec()) { _lensName = 'business'; if (lensSpec()) errs.push('leg5: a lens is in force without a definition'); }
    return { ok: errs.length === 0, errs: errs };
  } catch (e) { return { ok: false, errs: ['exception: ' + (e && e.stack || e)] }; }
})()`;

async function session(withLens) {
  const doc = mkdtempSync(join(tmpdir(), 't1241-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1241-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  if (withLens) copyFileSync(LENSFILE, join(repo, 'lens-definition.interim.json'));
  writeFileSync(join(repo, 'field-profile.json'), JSON.stringify(PROFILE));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1241-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(readFileSync(FIXTURE, 'utf8'))};`);
    return await ev(cmd, withLens ? ASSERT : ASSERT_NO_LENS);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}

async function main() {
  if (!existsSync(SRC) || !existsSync(FIXTURE) || !existsSync(LENSFILE)) { console.log(JSON.stringify({ ok: false, error: 'missing: ' + [SRC, FIXTURE, LENSFILE].filter(f => !existsSync(f)).join(' ') })); process.exitCode = 2; return; }
  try {
    const a = await session(true), b = await session(false);
    console.log(JSON.stringify({ ok: !!(a && a.ok && b && b.ok), src: SRC, lens: a, noLens: b }, null, 2));
    process.exitCode = a && a.ok && b && b.ok ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e) }, null, 2));
    process.exitCode = 1;
  }
}
main();
