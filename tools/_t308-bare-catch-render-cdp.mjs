#!/usr/bin/env node
// _t308-bare-catch-render-cdp.mjs — T-308 (T-244 GO, path b) regression guard for
// the neutral presentation of a BARE catch event.
//
// A <bpmn:intermediateCatchEvent> with no <aef:link> and no recognised
// <aef:eventDef> decodes to linkEventCatch through the REVERSE_TYPE fallback —
// there is no neutral landing type — and then wears the "← Handoff" glyph plus a
// link property schema whose target fields can never bind. AEF's operator read
// exactly that as a broken connector on a healthy map (T-244 exploration).
//
// This harness drives the REAL editor runtime against tests/fixtures/aef-bpmn/
// bare-catch-event.bpmn and asserts, in four layers:
//
//   MODEL   the bare node keeps type linkEventCatch (the fix is presentation
//           only — no type change, no schema surface) while isBareCatchEvent()
//           singles it out; bound (uuid + legacy slug) and typed-catch nodes are
//           NOT flagged, so the T-204/T-237 classification is untouched.
//   RENDER  the bare node draws the neutral double ring (2 circles, no chevron
//           path); a bound handoff still draws circle + chevron.
//   PANEL   the bare node's inspector shows the neutral 'intermediateEvent' badge
//           and the "Make this a handoff" affordance, and does NOT offer the dead
//           target fields; a bound handoff's panel is unchanged.
//   EXPORT  ZERO export surface. Exactly 2 <aef:link> survive (the two bound
//           nodes); the bare node's block emits none; build is a byte-exact fixed
//           point across a second save; and a palette-created handoff — unbound,
//           therefore byte-identical to a bare catch event — also emits none.
//
//   SESSION IW-3: authorial intent has no carrier in the dialect, so it lives in
//           session state. A palette-created linkEventCatch keeps the handoff UI
//           while live; clearing sessionAuthoredLinks (what a page reload does to
//           the Set) flips the same node to neutral.
//
//   BITE    giving the bare node a targetWorkflow must flip it back to the handoff
//           presentation — proving the branch reads node state rather than
//           echoing a constant.
//
// Isolation mirrors the t259 harness: temp docroot served by gallery-serve.py on a
// free port, isolated headless chromium (G-006).
// Exit 0 = neutral + bites; 1 = assertion failed; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXTURE = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 'bare-catch-event.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof renderAll==='function'&&typeof isBareCatchEvent==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const ASSERT_EXPR = `(function(){
  var text = window.__FIXTURE__;
  var errs = [];
  function shapeCounts(uid){
    var g = document.querySelector('g.node[data-id="'+uid+'"]');
    if(!g) return null;
    return { circles: g.querySelectorAll('circle').length, paths: g.querySelectorAll('path').length };
  }
  function panelText(uid){
    selection = { kind:'node', id: uid };
    renderProperties();
    // The inspector container is #properties. Do NOT fall back to document.body:
    // static markup elsewhere on the page (project modal, palette) carries the
    // same strings and would make every panel assertion vacuously true.
    var p = document.getElementById('properties');
    if(!p) throw new Error('#properties panel not found');
    return p.textContent || '';
  }
  function panelTypeName(){
    var el = document.querySelector('.props-type-name');
    return el ? (el.textContent||'').trim() : '<no props-type-name>';
  }
  try {
    // ---- MODEL ----------------------------------------------------------
    var m = parseBpmnXml(text);
    if(!m){ return { ok:false, errs:['parse returned null'] }; }
    var by = {}; m.nodes.forEach(function(n){ by[n.uid]=n; });
    ['n_bare','n_bound','n_slug','n_typed'].forEach(function(u){ if(!by[u]) errs.push('missing fixture node '+u); });
    if(errs.length) return { ok:false, errs:errs };
    if(by.n_bare.type !== 'linkEventCatch') errs.push('MODEL: n_bare type '+by.n_bare.type+' != linkEventCatch (T-308 must NOT change the node type — that would be path (a))');
    if(by.n_bound.type !== 'linkEventCatch') errs.push('MODEL: n_bound type '+by.n_bound.type+' != linkEventCatch');
    if(by.n_slug.type !== 'linkEventCatch') errs.push('MODEL: n_slug type '+by.n_slug.type+' != linkEventCatch');
    if(by.n_typed.type !== 'eventMessage') errs.push('MODEL: n_typed type '+by.n_typed.type+' != eventMessage (T-204 typed-catch override regressed)');
    if(isBareCatchEvent(by.n_bare) !== true) errs.push('MODEL: isBareCatchEvent(n_bare) is false — the bare node is not being singled out');
    if(isBareCatchEvent(by.n_bound) !== false) errs.push('MODEL: isBareCatchEvent(n_bound) is true — a uuid-bound handoff must not go neutral');
    if(isBareCatchEvent(by.n_slug) !== false) errs.push('MODEL: isBareCatchEvent(n_slug) is true — a legacy-slug handoff must not go neutral');
    if(isBareCatchEvent(by.n_typed) !== false) errs.push('MODEL: isBareCatchEvent(n_typed) is true — a typed catch is not a link event at all');

    // ---- RENDER ---------------------------------------------------------
    state = parseBpmnXml(text); refreshDisplayIds(); renderAll();
    var sBare = shapeCounts('n_bare'), sBound = shapeCounts('n_bound');
    if(!sBare) errs.push('RENDER: no <g class="node" data-id="n_bare">');
    else {
      if(sBare.paths !== 0) errs.push('RENDER: n_bare drew '+sBare.paths+' path(s) — the handoff chevron must be gone');
      if(sBare.circles !== 2) errs.push('RENDER: n_bare drew '+sBare.circles+' circle(s), expected 2 (neutral double ring)');
    }
    if(!sBound) errs.push('RENDER: no <g class="node" data-id="n_bound">');
    else {
      if(sBound.paths < 1) errs.push('RENDER: n_bound lost its chevron path — a bound handoff must be unaffected');
      if(sBound.circles !== 1) errs.push('RENDER: n_bound drew '+sBound.circles+' circle(s), expected 1 (unchanged handoff glyph)');
    }

    // ---- PANEL ----------------------------------------------------------
    var tBare = panelText('n_bare'); var badgeBare = panelTypeName();
    if(badgeBare !== 'intermediateEvent') errs.push('PANEL: n_bare type badge reads '+JSON.stringify(badgeBare)+' != "intermediateEvent"');
    if(tBare.indexOf('Make this a handoff') < 0) errs.push('PANEL: n_bare panel lacks the "Make this a handoff" affordance — binding would be unreachable');
    if(tBare.indexOf('Choose from project') >= 0) errs.push('PANEL: n_bare panel still offers the dead target picker');
    if(tBare.indexOf('Open target workflow') >= 0) errs.push('PANEL: n_bare panel still offers the dead jump button');
    var tBound = panelText('n_bound'); var badgeBound = panelTypeName();
    if(badgeBound !== 'linkEventCatch') errs.push('PANEL: n_bound type badge reads '+JSON.stringify(badgeBound)+' != "linkEventCatch"');
    if(tBound.indexOf('Choose from project') < 0) errs.push('PANEL: n_bound lost its target picker — a bound handoff must be unaffected');
    if(tBound.indexOf('Make this a handoff') >= 0) errs.push('PANEL: n_bound offered "Make this a handoff" — it already is one');

    // ---- EXPORT (zero surface) -----------------------------------------
    state = parseBpmnXml(text); refreshDisplayIds();
    var emit = buildBpmnXml(state);
    var nLinks = (emit.match(/<aef:link /g)||[]).length;
    if(nLinks !== 2) errs.push('EXPORT: expected exactly 2 <aef:link> (n_bound + n_slug), got '+nLinks);
    function blockFor(uid){
      var re = /<bpmn:intermediateCatchEvent [^>]*>[\\s\\S]*?<\\/bpmn:intermediateCatchEvent>/g;
      var b = emit.match(re)||[];
      for (var i=0;i<b.length;i++) if(b[i].indexOf('<aef:uid value="'+uid+'"') >= 0) return b[i];
      return null;
    }
    var bb = blockFor('n_bare');
    if(!bb) errs.push('EXPORT: n_bare is not inside a <bpmn:intermediateCatchEvent> block (host tag mutated?)');
    else if(bb.indexOf('<aef:link') >= 0) errs.push('EXPORT: n_bare acquired an <aef:link> — the bare node must stay bare');
    // second save is byte-identical (build is a fixed point over this fixture)
    state = parseBpmnXml(emit); refreshDisplayIds();
    var emit2 = buildBpmnXml(state);
    if(emit2 !== emit) errs.push('EXPORT: second save differs from the first — round-trip is no longer byte-clean');

    // ---- SESSION (IW-3) -------------------------------------------------
    state = parseBpmnXml(text); refreshDisplayIds(); renderAll();
    var before = state.nodes.length;
    createNodeAt('linkEventCatch', 300, 140);
    if(state.nodes.length !== before + 1) errs.push('SESSION: createNodeAt did not add a node');
    var fresh = state.nodes[state.nodes.length - 1];
    if(isBareCatchEvent(fresh) !== false) errs.push('SESSION: a palette-created handoff went neutral immediately — binding would be undiscoverable');
    renderAll();
    var sFresh = shapeCounts(fresh.uid);
    if(sFresh && sFresh.paths < 1) errs.push('SESSION: palette-created handoff drew no chevron while live in the session');
    // it is unbound, so it must still export no <aef:link> — intent is NOT persisted
    var emitFresh = buildBpmnXml(state);
    var nLinksFresh = (emitFresh.match(/<aef:link /g)||[]).length;
    if(nLinksFresh !== 2) errs.push('SESSION: palette-created unbound handoff emitted an <aef:link> ('+nLinksFresh+' total, expected 2) — that would be a persisted intent marker, i.e. path (a)');
    // a reload drops the session Set; the same node must then read neutral
    sessionAuthoredLinks.clear();
    if(isBareCatchEvent(fresh) !== true) errs.push('SESSION: after clearing session intent (reload proxy) the unbound node still presents as a handoff');
    renderAll();
    var sAfter = shapeCounts(fresh.uid);
    if(sAfter && sAfter.paths !== 0) errs.push('SESSION: after reload proxy the node still draws a chevron');

    // ---- BITE -----------------------------------------------------------
    // Give the bare node a target: the neutral branch MUST release it. Without
    // this the whole guard could pass on a hard-coded "always neutral".
    state = parseBpmnXml(text); refreshDisplayIds();
    var biteNode = state.nodes.filter(function(n){ return n.uid === 'n_bare'; })[0];
    var biteOk = true;
    if(!biteNode){ errs.push('BITE: n_bare absent'); biteOk = false; }
    else {
      biteNode.aef = biteNode.aef || {};
      biteNode.aef.targetWorkflow = 'review-map';
      if(isBareCatchEvent(biteNode) !== false){ errs.push('BITE FAIL: n_bare still reads bare after gaining a targetWorkflow'); biteOk = false; }
      renderAll();
      var sBite = shapeCounts('n_bare');
      if(sBite && sBite.paths < 1){ errs.push('BITE FAIL: n_bare drew no chevron after gaining a target — the branch is not reading node state'); biteOk = false; }
    }
    return { ok: errs.length===0, errs:errs, biteOk:biteOk };
  } catch(e) { return { ok:false, errs:['exception: '+(e&&e.message||e)] }; }
})()`;

async function main() {
  if (!existsSync(FIXTURE)) { process.stdout.write(JSON.stringify({ ok:false, error:'fixture missing: '+FIXTURE })+'\n'); process.exitCode = 2; return; }
  const text = readFileSync(FIXTURE, 'utf8');
  const doc = mkdtempSync(join(tmpdir(), 't308-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't308-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't308-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(text)};`);
    const r = await ev(cmd, ASSERT_EXPR);
    const out = { ok: !!(r && r.ok), bareCatch: r };
    process.stdout.write(JSON.stringify(out, null, 2) + '\n');
    process.exitCode = out.ok ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, error: String(e && e.stack || e) }, null, 2) + '\n');
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    try { rmSync(repo, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
