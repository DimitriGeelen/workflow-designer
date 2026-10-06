#!/usr/bin/env node
// _t911-kind-badge-verify-cdp.mjs — verify T-911: aef:workflowMeta/@kind is SETTABLE from the
// document-properties panel and VISIBLE on the canvas without opening a panel.
//
// T-875 shipped the closed enum, the validator rules in both forms, the round-trip guarantee and a
// conformance case — and no way to set or see the marker, which made `kind` the only document-level
// attribute the editor read and wrote but could not author. arc-005's headline_mechanic opens with
// "an operator opens task-lifecycle in the designer, SEES IT MARKED as a template rather than an
// actionable work-plan", so the badge is not decoration: it is the arc's closing condition.
//
// Serves the editor from a TEMP docroot (gallery-serve.py) and drives it in ISOLATED headless
// chromium (own --user-data-dir; G-006).
//
// WHAT IT ASSERTS, and why each one is here rather than being taken on trust:
//   1. The panel offers a Kind select whose options are EXACTLY ['', documentation, work-plan],
//      read off the rendered <option> elements — not off the source literal, which would be the
//      check reading its own input.
//   2. Choosing a value through the REAL select (dispatching 'change', not calling the callback)
//      sets state and shows the badge. A callback invoked directly would pass with the control
//      unwired.
//   3. UNSET is reachable BACK from a set value, and returning to unset restores byte-identical
//      export. T-213 IW-3 kept the marker an explicit author decision; a control that cannot
//      return to unset silently reclassifies every map an operator merely glanced at.
//   4. The exported BYTES carry kind="..." — read off buildBpmnXml output, not off the in-memory
//      model. An attribute present in state and absent from the wire is the drop-on-save defect.
//   5. SCREENSHOTS for the READ step, in the modes that actually exist in this product.
//
// ON THE MODE LIST: this designer has ONE theme (a single :root token block, zero
// prefers-color-scheme, zero data-theme), no font modes ("serif" appears only inside fallback
// stacks) and no UI density ("density" here is a snap-THRESHOLD multiplier whose own comment says
// it never re-spaced rows nor grew lanes). So the general mono/sans/serif × light/dark/contrast ×
// compact/normal/cozy matrix would be nine identical renders — coverage theatre. The modes that
// change this pixel: the three badge states, and narrow vs wide (the overlay is absolutely
// positioned, so a long badge can collide).
//
// Exit 0 = pass. Exit 1 = a step failed. Exit 2 = harness could not run.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SHOTDIR = join(REPO, '.playwright-mcp');
const MAP = 'task-lifecycle';          // the map arc-005's headline mechanic names
const EXPECTED_OPTIONS = ['', 'documentation', 'work-plan'];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null)&&!!document.getElementById('status-kind'))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Drive the REAL <select>: set .value and dispatch a change event, exactly as a user's choice
// arrives. Calling the onInput callback directly would pass with the control unwired to the DOM.
const CHOOSE = v => `(function(){
  var sels = Array.prototype.slice.call(document.querySelectorAll('#properties .field select.field-select'));
  var target = null;
  for (var i=0;i<sels.length;i++){
    var lbl = sels[i].parentElement.querySelector('.field-label');
    if (lbl && lbl.textContent.indexOf('Kind') === 0) { target = sels[i]; break; }
  }
  if (!target) return { ok:false, reason:'no Kind select in the properties panel' };
  target.value = ${JSON.stringify(v)};
  target.dispatchEvent(new Event('change', { bubbles:true }));
  return { ok:true };
})()`;

const BADGE = `(function(){
  var el = document.getElementById('status-kind');
  if (!el) return { present:false };
  var cs = getComputedStyle(el);
  var r = el.getBoundingClientRect();
  return { present:true, hidden:el.hidden, text:el.textContent, dataKind:el.getAttribute('data-kind'),
           color:cs.color, visible: r.width > 0 && r.height > 0,
           right: Math.round(r.right), vw: window.innerWidth };
})()`;

async function shoot(cmd, name, sel, pad = 10) {
  const box = await ev(cmd, `(function(){ var e=document.querySelector(${JSON.stringify(sel)}); if(!e) return null;
    var r=e.getBoundingClientRect();
    return { x:Math.max(0,r.x-${pad}), y:Math.max(0,r.y-${pad}), w:r.width+${pad * 2}, h:r.height+${pad * 2} }; })()`);
  if (!box || box.w < 2 || box.h < 2) return { shot: name, captured: false, reason: 'no box for ' + sel };
  const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { ...box, width: box.w, height: box.h, scale: 2 } });
  mkdirSync(SHOTDIR, { recursive: true });
  const f = join(SHOTDIR, name);
  writeFileSync(f, Buffer.from(s.data, 'base64'));
  return { shot: name, captured: true, path: f, bytes: Buffer.from(s.data, 'base64').length };
}

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't911-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't911-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't911-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1280,860', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [], shots: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1280, height: 860, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(600);

    // ── CONTROL, FIRST ────────────────────────────────────────────────────────────────────────
    // task-lifecycle carries NO kind today (T-876 is the backfill). So the opening state must be
    // UNSET with the badge hidden. If it were already set, every "badge appeared" result below
    // would be measuring a page that already looked right — the control that makes the rest mean
    // something.
    const start = await ev(cmd, `({ kind: (state.workflowMeta||{}).kind || null, badge: ${BADGE} })`);
    push('control: map opens with kind UNSET and the badge hidden',
      start.kind === null && start.badge.present === true && start.badge.hidden === true, start);

    // ── 1. the panel offers the closed enum, read off the DOM ─────────────────────────────────
    const opts = await ev(cmd, `(function(){
      var sels = Array.prototype.slice.call(document.querySelectorAll('#properties .field select.field-select'));
      for (var i=0;i<sels.length;i++){
        var lbl = sels[i].parentElement.querySelector('.field-label');
        if (lbl && lbl.textContent.indexOf('Kind') === 0)
          return Array.prototype.map.call(sels[i].options, function(o){ return o.value; });
      }
      return null;
    })()`);
    push('panel offers a Kind select with exactly ' + JSON.stringify(EXPECTED_OPTIONS),
      Array.isArray(opts) && JSON.stringify(opts) === JSON.stringify(EXPECTED_OPTIONS), opts);
    verdict.shots.push(await shoot(cmd, 't911-panel-kind-select.png', '#properties', 0));

    // ── 2. choosing documentation through the real control ────────────────────────────────────
    push('choose documentation (real change event)', (await ev(cmd, CHOOSE('documentation'))).ok, null);
    await sleep(250);
    const doc1 = await ev(cmd, `({ kind:(state.workflowMeta||{}).kind||null, badge: ${BADGE} })`);
    push('documentation: state set, badge visible and glossed',
      doc1.kind === 'documentation' && doc1.badge.hidden === false && doc1.badge.visible === true
      && /documentation/.test(doc1.badge.text) && /illustrative/.test(doc1.badge.text), doc1);
    verdict.shots.push(await shoot(cmd, 't911-badge-documentation.png', '#status'));

    // ── 3. work-plan, which has its own colour rule ────────────────────────────────────────────
    push('choose work-plan (real change event)', (await ev(cmd, CHOOSE('work-plan'))).ok, null);
    await sleep(250);
    const wp = await ev(cmd, `({ kind:(state.workflowMeta||{}).kind||null, badge: ${BADGE} })`);
    push('work-plan: state set, badge glossed actionable, colour DIFFERS from documentation',
      wp.kind === 'work-plan' && wp.badge.hidden === false && /actionable/.test(wp.badge.text)
      && wp.badge.color !== doc1.badge.color, { workPlan: wp.badge, documentationColor: doc1.badge.color });
    verdict.shots.push(await shoot(cmd, 't911-badge-work-plan.png', '#status'));

    // ── 4. the export BYTES carry it ──────────────────────────────────────────────────────────
    const xml = await ev(cmd, `buildBpmnXml(state)`);
    push('exported bytes carry kind="work-plan" on aef:workflowMeta',
      /<aef:workflowMeta[^>]*\skind="work-plan"/.test(xml),
      (xml.match(/<aef:workflowMeta[^>]*>/) || ['<none>'])[0]);

    // ── 5. UNSET is reachable BACK, and restores the original bytes ────────────────────────────
    // The load-bearing one for T-213 IW-3. Compared against the bytes the map exported BEFORE any
    // kind was chosen, so this is a round trip to the real starting state rather than to a
    // remembered claim about it.
    // PRECONDITION. These two legs assert an ABSENCE — kind is null, no kind= on the wire — and on
    // the first run of this instrument they both PASSED while every set leg failed, because the
    // absence they assert was already true: nothing had ever been set. An absence assertion whose
    // subject was never present is NOT EVALUATED, and per T-3105 that is not a PASS. So the
    // round trip is only scored when the set it reverses is proven to have happened.
    const setHeld = (await ev(cmd, `((state.workflowMeta||{}).kind === 'work-plan')`)) === true;
    const before = await ev(cmd, `(function(){ var k=(state.workflowMeta||{}).kind; state.workflowMeta.kind=null; var x=buildBpmnXml(state); state.workflowMeta.kind=k; return x; })()`);
    push('choose UNSET (real change event)', (await ev(cmd, CHOOSE(''))).ok, null);
    await sleep(250);
    const un = await ev(cmd, `({ kind:(state.workflowMeta||{}).kind, badge: ${BADGE}, xml: buildBpmnXml(state) })`);
    push('UNSET: kind is null (not ""), badge hidden again',
      setHeld && un.kind === null && un.badge.hidden === true,
      setHeld ? { kind: un.kind, badge: un.badge }
              : 'NOT EVALUATED — kind was not set to work-plan beforehand, so reverting it proves nothing (T-3105)');
    push('UNSET exports byte-identically to a map that never had a kind',
      setHeld && un.xml === before && !/\skind="/.test(un.xml),
      setHeld ? { identical: un.xml === before, hasKindAttr: /\skind="/.test(un.xml) }
              : 'NOT EVALUATED — no prior set to revert (T-3105)');
    verdict.shots.push(await shoot(cmd, 't911-badge-unset.png', '#status'));

    // ── 6. narrow viewport: the absolutely-positioned overlay must not run off ─────────────────
    await ev(cmd, CHOOSE('work-plan')); await sleep(200);
    await cmd('Emulation.setDeviceMetricsOverride', { width: 640, height: 860, deviceScaleFactor: 1, mobile: false });
    await sleep(400);
    const narrow = await ev(cmd, BADGE);
    push('narrow (640px): badge still visible and inside the viewport',
      narrow.visible === true && narrow.right <= narrow.vw, narrow);
    verdict.shots.push(await shoot(cmd, 't911-badge-narrow-640.png', '#status'));

    verdict.pass = verdict.steps.every(s => s.pass) && verdict.shots.every(s => s.captured);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), steps: verdict.steps }, null, 2) + '\n');
    process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
