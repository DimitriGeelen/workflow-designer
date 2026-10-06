#!/usr/bin/env node
// _t1078-advisory-overlap-cdp.mjs — an advisory banner must never sit ON the diagram (T-1078).
//
// The independent reviewer's follow-up on T-310: on a malformed map both advisories fire (the
// lane-fix notice and the Clean layout nudge), and the stacked nudge covered agt_2_agent — the
// very top-lane node the lane-fix notice says was moved back. The lane-fix message was also
// nowrap, so at narrow widths it ran off the canvas on one line.
//
// Drives the REAL editor (served copy, headless Chromium) on T-310's fixture with both
// advisories visible, at 1280 and 1720 px, and MEASURES:
//   O1  no advisory box intersects any node shape or node label/badge (client rects)
//   O2  the lane-fix message fits inside the canvas (no horizontal overflow, box inside the wrap)
//   O3  setup control: both advisories really are visible (else O1/O2 assert nothing)
//   O4  dismissing both gives the canvas its space back (no permanent shrink)
//
// --self-test reruns on two poisoned copies, or the legs assert nothing (T-592):
//   A  the canvas padding write removed            -> O1 must FAIL
//   B  the message forced back to nowrap           -> O2 must FAIL
// --shots DIR writes the canvas top at both widths.
//
// Usage:  node tools/_t1078-advisory-overlap-cdp.mjs [--self-test] [--shots DIR]
// Exit:   0 pass · 1 leg failed · 2 setup broken
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
const FIXTURE = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 'lane-position-conflict.bpmn');
const EDITOR = join(REPO, 'src', 'aef-workflow-designer.html');
const WIDTHS = [1280, 1720];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Import the fixture so BOTH advisories show: the lane-fix notice comes from the reconciliation;
// the Clean nudge is shown the way the import path shows it (clean-on-import off).
const LOAD = `(function(){
  if (typeof viewPrefs === 'object') viewPrefs.cleanOnImport = false;
  adoptImportedXml(window.__FIX__, { userImport: true });
  var n = document.getElementById('clean-nudge'); if (n) n.style.display = '';
  // The worst case the reviewer named: the COMBINED lane-fix message (moves + grown bands +
  // a skipped process), which is long. Report contents as T-315/T-603 would produce them.
  _laneGrowReport = [{ name: 'Framework · Authority', grew: 140 }, { name: 'Agent · Initiative', grew: 60 }];
  _processSkipReport = [{ id: 'Process_secondary_intake', name: 'secondary intake', n: 7 }];
  if (typeof maybeShowLaneFixNotice === 'function') maybeShowLaneFixNotice();
  return 1; })()`;

const MEASURE = `(function(){
  function r(e){ var b = e.getBoundingClientRect(); return { x1: b.left, y1: b.top, x2: b.right, y2: b.bottom, w: b.width, h: b.height }; }
  function hit(a, b){ return a.x1 < b.x2 && b.x1 < a.x2 && a.y1 < b.y2 && b.y1 < a.y2; }
  var adv = ['lane-fix-notice', 'clean-nudge'].map(function(id){ return document.getElementById(id); })
    .filter(function(e){ return e && getComputedStyle(e).display !== 'none' && e.offsetHeight > 0; });
  var targets = [];
  state.nodes.forEach(function(n){
    // node groups are keyed by data-id = n.id in #g-nodes (a wrong attribute here once measured
    // only the below-labels and passed under the poison arm — the self-test caught it)
    var g = document.querySelector('#g-nodes [data-id="' + n.id + '"]');
    if (g) targets.push({ what: n.uid + ' shape', r: r(g) });
    document.querySelectorAll('text[data-nl="' + n.uid + '"]').forEach(function(t){
      var b = r(t); if (b.w > 0) targets.push({ what: n.uid + ' ' + (t.getAttribute('class') || 'text'), r: b }); });
  });
  var overlaps = [];
  adv.forEach(function(a){ var ar = r(a); targets.forEach(function(t){ if (hit(ar, t.r)) overlaps.push(a.id + ' over ' + t.what); }); });
  var wrap = document.querySelector('.canvas-wrap'), wr = r(wrap);
  var msg = document.getElementById('lane-fix-msg'), lf = document.getElementById('lane-fix-notice');
  var lr = lf ? r(lf) : null;
  return { visible: adv.map(function(a){ return a.id; }), overlaps: overlaps, targets: targets.length,
           nodes: state.nodes.length, shapes: targets.filter(function(t){ return / shape$/.test(t.what); }).length,
           msgOverflow: msg ? msg.scrollWidth - msg.clientWidth : null,
           lfInside: lr ? (lr.x1 >= wr.x1 - 0.5 && lr.x2 <= wr.x2 + 0.5) : null,
           lfBox: lr ? [Math.round(lr.x1), Math.round(lr.x2)] : null, wrapBox: [Math.round(wr.x1), Math.round(wr.x2)] };
})()`;

async function run(editorPath, shotDir, tag) {
  const fixture = readFileSync(FIXTURE, 'utf8');
  const doc = mkdtempSync(join(tmpdir(), 't1078-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1078-repo-'));
  copyFileSync(editorPath, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1078-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const out = {};
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const rr = await fetch(BASE + '/api/health'); if (rr.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down');
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    for (const w of WIDTHS) {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: 820, deviceScaleFactor: 1, mobile: false });
      await cmd('Page.navigate', { url: `${BASE}/designer.html` });
      await waitReady(cmd); await sleep(200);
      await ev(cmd, `window.__FIX__ = ${JSON.stringify(fixture)};`);
      await ev(cmd, LOAD);
      await sleep(400);
      out[w] = await ev(cmd, MEASURE);
      // O4: dismissing both advisories gives the canvas its space back (no permanent shrink).
      out[w].padShown = await ev(cmd, `document.querySelector('.canvas-wrap').style.paddingTop`);
      await ev(cmd, `(function(){ document.getElementById('lane-fix-dismiss').click(); document.getElementById('clean-nudge-dismiss').click(); return 1; })()`);
      await sleep(200);
      out[w].padAfter = await ev(cmd, `document.querySelector('.canvas-wrap').style.paddingTop`);
      if (shotDir) {
        const box = await ev(cmd, `(function(){ var b = document.querySelector('.canvas-wrap').getBoundingClientRect(); return { x: b.left, y: b.top, w: b.width, h: Math.min(b.height, 360) }; })()`);
        const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: box.x, y: box.y, width: box.w, height: box.h, scale: 1 } });
        writeFileSync(join(shotDir, `t1078-${tag}-${w}.png`), Buffer.from(s.data, 'base64'));
      }
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
  }
  return out;
}

function legs(res) {
  const L = [];
  for (const w of WIDTHS) {
    const m = res[w];
    L.push({ id: `O3@${w}`, ok: m.visible.length === 2 && m.shapes === m.nodes && m.nodes > 0,
             detail: `visible: ${m.visible.join(', ') || 'none'}; ${m.shapes}/${m.nodes} node shapes found, ${m.targets} rects` });
    L.push({ id: `O1@${w}`, ok: m.overlaps.length === 0, detail: m.overlaps.length ? m.overlaps.slice(0, 4).join('; ') : 'no advisory over any node shape or label' });
    L.push({ id: `O2@${w}`, ok: m.msgOverflow !== null && m.msgOverflow <= 1 && m.lfInside === true,
             detail: `message overflow ${m.msgOverflow}px; notice x ${m.lfBox} inside wrap x ${m.wrapBox}: ${m.lfInside}` });
    L.push({ id: `O4@${w}`, ok: m.padAfter === '',
             detail: `canvas top padding ${m.padShown || '(none)'} while shown, '${m.padAfter}' after both dismissed` });
  }
  return L;
}
const report = L => { for (const l of L) console.log(`  ${l.ok ? 'PASS' : 'FAIL'}  ${l.id}  ${l.detail}`); };

async function main() {
  const selfTest = process.argv.includes('--self-test');
  const si = process.argv.indexOf('--shots');
  const shotDir = si > 0 ? process.argv[si + 1] : null;
  if (shotDir) mkdirSync(shotDir, { recursive: true });
  if (!existsSync(FIXTURE)) { console.log('SETUP BROKEN: fixture missing ' + FIXTURE); process.exit(2); }
  console.log('T-1078 advisories never cover the diagram — measured at ' + WIDTHS.join(' and ') + ' px');
  const live = legs(await run(EDITOR, shotDir, 'after'));
  report(live);
  const failed = live.filter(l => !l.ok);
  if (!selfTest) { console.log(failed.length ? `FAIL — ${failed.length} leg(s)` : `PASS — ${live.length} legs`); process.exit(failed.length ? 1 : 0); }
  const src = readFileSync(EDITOR, 'utf8');
  const PAD = '  if (wrap.style.paddingTop !== pad) wrap.style.paddingTop = pad;\n';
  const WRAP = '  .clean-nudge .clean-nudge-msg { white-space: normal; }\n';
  if (!src.includes(PAD) || !src.includes(WRAP)) { console.log('SELF-TEST INTEGRITY FAIL — a poison target is missing from the editor source'); process.exit(2); }
  const arms = [
    { name: 'A — canvas padding not written', must: 'O1', patched: src.replace(PAD, '') },
    { name: 'B — message back to nowrap', must: 'O2', patched: src.replace(WRAP, '  .clean-nudge .clean-nudge-msg { white-space: nowrap; }\n').replace('  .clean-nudge { max-width: calc(100% - 24px); }\n', '') },
  ];
  const dir = mkdtempSync(join(tmpdir(), 't1078-poison-'));
  for (const [i, arm] of arms.entries()) {
    const f = join(dir, `poison-${i}.html`); writeFileSync(f, arm.patched);
    console.log(`\npoison arm ${arm.name} — ${arm.must} must FAIL at some width`);
    const pl = legs(await run(f, shotDir, `poison-${'AB'[i]}`)); report(pl);
    if (failed.length) { console.log(`\nFAIL — ${failed.length} live leg(s)`); process.exit(1); }
    if (!pl.some(l => l.id.startsWith(arm.must) && !l.ok)) { console.log(`\nSELF-TEST FAIL — ${arm.must} passed under poison; it asserts nothing`); process.exit(2); }
    if (pl.some(l => l.id.startsWith('O3') && !l.ok)) { console.log('\nSELF-TEST FAIL — the setup control broke under poison'); process.exit(2); }
  }
  console.log(`\nPASS — ${live.length} live legs; O1 and O2 proven failable`);
}
main().catch(e => { console.error('DRIVER ERROR: ' + (e && e.stack || e)); process.exit(2); });
