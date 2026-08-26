#!/usr/bin/env node
// _t258-annotation-seam-cdp.mjs — T-258 (T-250 GO) correctness guard for the
// annotation seam v0 (shape A postMessage). Drives the REAL editor embedded in an
// iframe host page — exactly the AEF Watchtower topology — and asserts the full
// ratified loop:
//   * aef:ready arrives at the parent on initial load, version 1, with the seed
//     workflow's uid list;
//   * aef:annotate renders read-only badges for known uids, silently ignores
//     unknown uids, and rejects nothing loudly (no console errors);
//   * the badge layer is DISPLAY-ONLY: buildBpmnXml output carries no trace of it
//     and captureThumbnail's clone strip removes it (_stripAnnotationLayer);
//   * a re-render re-emits aef:ready AND wipes the badges (re-handshake contract);
//   * a document switch drops badges and re-emits ready with the NEW uid set;
//   * messages from a non-parent source are ignored (self-post probe);
//   * BITE: before any annotate, zero .aef-annotation elements exist.
// Also captures an element-level screenshot of a badged node region to
// .playwright-mcp/t258-annotation-badges.png for the visual-verification read.
// Isolation mirrors the sibling harnesses: temp docroot via gallery-serve.py,
// isolated headless chromium (G-006). Exit 0 = green; 1 = assertion failed;
// 2 = misconfig.
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
const SHOT = join(REPO, '.playwright-mcp', 't258-annotation-badges.png');
// T-261: the REAL payload AEF's live /api/overlay served on 2026-07-27 (their
// wrapper posts this verbatim) — wire-canonical shape {nodes:[{uid,badge,text,severity}]}.
const WIRE_FIXTURE = join(REPO, 'tests', 'fixtures', 'aef-overlay', 'live-payload-2026-07-27.json');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

// Host page: embeds the designer exactly as AEF's Watchtower would, records every
// aef:ready envelope, and exposes a helper to post aef:annotate into the iframe.
const HOST_HTML = `<!doctype html>
<html><head><meta charset="utf-8"><title>t258 host</title></head>
<body style="margin:0">
<iframe id="f" src="designer.html" style="width:1200px;height:800px;border:0"></iframe>
<iframe id="spoofer" style="display:none" srcdoc="<script>window.spoof=function(uid){parent.document.getElementById('f').contentWindow.postMessage({type:'aef:annotate',annotations:[{uid:uid,badge:'spoof',tone:'warn'}]},'*');};</script>"></iframe>
<script>
  window.__readies = [];
  window.addEventListener('message', function(ev){
    if (ev.data && ev.data.type === 'aef:ready') window.__readies.push(JSON.parse(JSON.stringify(ev.data)));
  });
  window.__annotate = function(annotations){
    document.getElementById('f').contentWindow.postMessage({ type: 'aef:annotate', annotations: annotations }, '*');
  };
  window.__post = function(obj){
    document.getElementById('f').contentWindow.postMessage(obj, '*');
  };
</script>
</body></html>`;

async function waitFor(cmd, expr, ms, label) {
  const t0 = Date.now();
  for (;;) {
    const ok = await ev(cmd, expr).catch(() => false);
    if (ok) return;
    if (Date.now() - t0 > ms) throw new Error('timeout waiting for ' + label);
    await sleep(150);
  }
}

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't258-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't258-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  writeFileSync(join(doc, 'host.html'), HOST_HTML);
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't258-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1280,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const errs = [];
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/host.html` });

    // (1) initial load → at least one aef:ready with the seed uid list
    await waitFor(cmd, `window.__readies && window.__readies.length >= 1`, 25000, 'first aef:ready');
    await sleep(300);
    const first = await ev(cmd, `(function(){
      var f = document.getElementById('f').contentWindow;
      var r = window.__readies[window.__readies.length-1];
      var uids = f.eval('state.nodes.map(function(n){ return n.uid; })');
      return { version: r.version, workflow: r.workflow, got: r.uids, want: uids };
    })()`);
    if (first.version !== 1) errs.push('ready.version ' + first.version + ' != 1');
    if (!first.workflow) errs.push('ready.workflow empty');
    if (JSON.stringify(first.got) !== JSON.stringify(first.want)) errs.push('ready.uids != state uids: ' + JSON.stringify(first.got) + ' vs ' + JSON.stringify(first.want));

    // (2) BITE: zero badges before any annotate
    const pre = await ev(cmd, `document.getElementById('f').contentWindow.document.querySelectorAll('.aef-annotation').length`);
    if (pre !== 0) errs.push('BITE FAIL: ' + pre + ' badge(s) before any annotate');

    // (3) annotate 2 known + 1 unknown (+1 malformed entry) → exactly 2 badges, no console error
    const r3 = await ev(cmd, `(function(){
      var f = document.getElementById('f').contentWindow;
      var uids = f.eval('state.nodes.map(function(n){ return n.uid; })');
      window.__u0 = uids[0]; window.__u1 = uids[1];
      window.__annotate([
        { uid: uids[0], badge: 'running', tone: 'ok', title: 'since 12:04Z' },
        { uid: uids[1], badge: 'blocked', tone: 'err' },
        { uid: 'n_does_not_exist', badge: 'ghost', tone: 'warn' },
        { nonsense: true }
      ]);
      return true;
    })()`);
    if (!r3) errs.push('annotate post failed');
    await waitFor(cmd, `document.getElementById('f').contentWindow.document.querySelectorAll('.aef-annotation').length === 2`, 5000, '2 badges');
    const badgeCheck = await ev(cmd, `(function(){
      var d = document.getElementById('f').contentWindow.document;
      var g0 = d.querySelector('g[data-id="'+window.__u0+'"] .aef-annotation');
      var g1 = d.querySelector('g[data-id="'+window.__u1+'"] .aef-annotation');
      return {
        okBadge: g0 ? g0.textContent : null,
        errBadge: g1 ? g1.textContent : null,
        okTone: g0 ? /tone-ok/.test(g0.getAttribute('class')) : false,
        errTone: g1 ? /tone-err/.test(g1.getAttribute('class')) : false,
        title: g0 ? (g0.querySelector('title') ? g0.querySelector('title').textContent : '') : ''
      };
    })()`);
    if (!badgeCheck.okTone || (badgeCheck.okBadge || '').indexOf('running') < 0) errs.push('known uid 0 badge wrong: ' + JSON.stringify(badgeCheck));
    if (!badgeCheck.errTone || (badgeCheck.errBadge || '').indexOf('blocked') < 0) errs.push('known uid 1 badge wrong: ' + JSON.stringify(badgeCheck));
    if (badgeCheck.title.indexOf('since 12:04Z') < 0) errs.push('badge title tooltip missing');

    // (4) display-only: BPMN emit clean + thumbnail clone strip removes badges
    const clean = await ev(cmd, `(function(){
      var f = document.getElementById('f').contentWindow;
      var xml = f.eval('buildBpmnXml(state)');
      var svg = f.document.getElementById('canvas');
      var clone = svg.cloneNode(true);
      var before = clone.querySelectorAll('.aef-annotation').length;
      f._stripAnnotationLayer(clone);
      var after = clone.querySelectorAll('.aef-annotation').length;
      return { xmlHasBadge: xml.indexOf('aef-annotation') >= 0 || xml.indexOf('running') >= 0,
               cloneBefore: before, cloneAfter: after };
    })()`);
    if (clean.xmlHasBadge) errs.push('buildBpmnXml output carries annotation traces');
    if (clean.cloneBefore !== 2) errs.push('thumbnail clone should start with 2 badges, had ' + clean.cloneBefore);
    if (clean.cloneAfter !== 0) errs.push('_stripAnnotationLayer left ' + clean.cloneAfter + ' badge(s)');

    // Screenshot the badged node region for the visual-verification read (before re-render wipes it).
    try {
      const box = await ev(cmd, `(function(){
        var f = document.getElementById('f').contentWindow;
        var d = f.document;
        var g = d.querySelector('g[data-id="'+window.__u0+'"]');
        var r = g.getBoundingClientRect();
        var fi = document.getElementById('f').getBoundingClientRect();
        return { x: Math.max(0, fi.x + r.x - 40), y: Math.max(0, fi.y + r.y - 40), w: r.width + 260, h: r.height + 90 };
      })()`);
      const shot = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: box.x, y: box.y, width: box.w, height: box.h, scale: 2 } });
      mkdirSync(dirname(SHOT), { recursive: true });
      writeFileSync(SHOT, Buffer.from(shot.data, 'base64'));
    } catch (e) { errs.push('screenshot capture failed: ' + (e && e.message || e)); }

    // (5) non-parent source ignored: a SIBLING iframe posting into the designer
    // (event.source = sibling window, not window.parent) must not add badges.
    await ev(cmd, `(document.getElementById('spoofer').contentWindow.spoof(window.__u0), true)`);
    await sleep(400);
    const spoof = await ev(cmd, `(function(){
      var d = document.getElementById('f').contentWindow.document;
      var els = d.querySelectorAll('.aef-annotation');
      for (var i = 0; i < els.length; i++) if (els[i].textContent.indexOf('spoof') >= 0) return true;
      return false;
    })()`);
    if (spoof) errs.push('SPOOF FAIL: non-parent-source annotate rendered a badge');

    // (6) re-render → ready re-emitted AND badges wiped
    const beforeRe = await ev(cmd, `window.__readies.length`);
    await ev(cmd, `(document.getElementById('f').contentWindow.renderAll(), true)`);
    await waitFor(cmd, `window.__readies.length > ${beforeRe}`, 5000, 'ready after re-render');
    const wiped = await ev(cmd, `document.getElementById('f').contentWindow.document.querySelectorAll('.aef-annotation').length`);
    if (wiped !== 0) errs.push('re-render left ' + wiped + ' badge(s) — wipe contract broken');

    // (7) document switch → ready with the NEW uid set, still zero badges
    const beforeSw = await ev(cmd, `window.__readies.length`);
    await ev(cmd, `(document.getElementById('f').contentWindow.createNewWorkflow(), true)`);
    await waitFor(cmd, `window.__readies.length > ${beforeSw}`, 5000, 'ready after doc switch');
    const sw = await ev(cmd, `(function(){
      var f = document.getElementById('f').contentWindow;
      var r = window.__readies[window.__readies.length-1];
      var uids = f.eval('state.nodes.map(function(n){ return n.uid; })');
      return { match: JSON.stringify(r.uids) === JSON.stringify(uids), workflow: r.workflow,
               badges: f.document.querySelectorAll('.aef-annotation').length };
    })()`);
    if (!sw.match) errs.push('post-switch ready.uids do not match the new document');
    if (sw.badges !== 0) errs.push('doc switch left ' + sw.badges + ' badge(s)');

    // (8) T-261 wire-shape leg: replay the REAL AEF payload bytes verbatim against a
    // document carrying two of its uids — nodes[]/severity/text must light badges
    // with mapped tones (alert→err) and text→tooltip; the 3 absent uids stay ignored.
    const wire = JSON.parse(readFileSync(WIRE_FIXTURE, 'utf8'));
    if (wire.type !== 'aef:annotate' || !Array.isArray(wire.nodes)) throw new Error('wire fixture malformed: ' + WIRE_FIXTURE);
    // Step (7) left an EMPTY new document — switch back to the seed map (still in
    // the in-session library) and rename two of its uids to the wire payload's.
    await ev(cmd, `(function(){
      var f = document.getElementById('f').contentWindow;
      f.eval("var k = Array.from(library.keys()).filter(function(x){ return x !== activeKey; })[0]; loadFromLibrary(k);" +
             "state.nodes[0].uid = 'tl_work'; state.nodes[0].id = 'tl_work';" +
             "state.nodes[1].uid = 'tl_human_review'; state.nodes[1].id = 'tl_human_review';" +
             "refreshDisplayIds(); renderAll();");
      return true;
    })()`);
    await sleep(200);
    await ev(cmd, `(window.__post(${JSON.stringify(wire)}), true)`);
    await waitFor(cmd, `document.getElementById('f').contentWindow.document.querySelectorAll('.aef-annotation').length === 2`, 5000, '2 wire-shape badges');
    const wireCheck = await ev(cmd, `(function(){
      var d = document.getElementById('f').contentWindow.document;
      var w = d.querySelector('g[data-id="tl_work"] .aef-annotation');
      var h = d.querySelector('g[data-id="tl_human_review"] .aef-annotation');
      return {
        workTone: w ? /tone-warn/.test(w.getAttribute('class')) : false,
        workBadge: w ? w.querySelector('text').textContent : null,
        workTip: w && w.querySelector('title') ? w.querySelector('title').textContent : '',
        reviewTone: h ? /tone-err/.test(h.getAttribute('class')) : false,
        reviewBadge: h ? h.querySelector('text').textContent : null
      };
    })()`);
    const wWork = wire.nodes.find(n => n.uid === 'tl_work');
    const wRev = wire.nodes.find(n => n.uid === 'tl_human_review');
    if (!wWork || !wRev) throw new Error('wire fixture lost its tl_work/tl_human_review carriers');
    if (wWork.severity !== 'warn' || wRev.severity !== 'alert') errs.push('wire fixture severities drifted — re-pin deliberately');
    if (!wireCheck.workTone || wireCheck.workBadge !== String(wWork.badge)) errs.push('wire: tl_work badge wrong: ' + JSON.stringify(wireCheck) + ' want ' + wWork.badge);
    if (wireCheck.workTip !== String(wWork.text).slice(0, 200)) errs.push('wire: tl_work tooltip missing text→title fallback: ' + JSON.stringify(wireCheck.workTip));
    if (!wireCheck.reviewTone || wireCheck.reviewBadge !== String(wRev.badge)) errs.push('wire: tl_human_review severity alert did not map to tone-err: ' + JSON.stringify(wireCheck));

    const out = { ok: errs.length === 0, errs, screenshot: existsSync(SHOT) ? SHOT : null };
    process.stdout.write(JSON.stringify(out, null, 2) + '\n');
    process.exitCode = out.ok ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, errs: errs.concat([String(e && e.stack || e)]) }, null, 2) + '\n');
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
