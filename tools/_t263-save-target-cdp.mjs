#!/usr/bin/env node
// _t263-save-target-cdp.mjs — T-263 inception probe: Save-to-project target binding.
// Peer incident (AEF rail 225/228): a scratch COPY whose workflowMeta id still named
// the original was saved onto the ORIGINAL project; editing "the id input" with a
// synthetic value-set + input/change events did not rebind the target.
// Code facts (src/aef-workflow-designer.html): saveToProject() POSTs /api/save with
// id = state.workflowMeta.id, unconditionally (:7930/:7954); the ONLY UI that changes
// it is the props-panel "ID" field (renderProperties meta editor :5040), which commits
// via renameActiveWorkflow() on EVERY 'input' event (field() :5645); rename silently
// no-ops on library-key collision (:2588) and the field just reverts on blur.
// Probes (fresh served editor, isolated chromium, G-006):
//   leg1 synthetic  — set .value + dispatch Event('input') on the ID field → does
//                     state.workflowMeta.id rebind? (H1: peer's synthetic edit class)
//   leg2 real       — CDP Input.insertText (trusted input event) → rebind?
//   leg3 collision  — rename to an EXISTING library key → silent revert, no alert?
//   leg4 saveTarget — stub fetch + note modal, run saveToProject() → POST body id
//                     === state.workflowMeta.id (the incident mechanism itself)
//   leg5 focus      — after a successful rename re-render, does the field keep focus?
//                     (observation only, informs IW-3 UX ruling — not a pass/fail)
// Exit 0 = probes ran (findings in JSON); 1 = probe infrastructure failed; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof renderProperties==='function'&&typeof renameActiveWorkflow==='function'&&typeof saveToProject==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Locate the meta-editor ID input: no selection → renderProperties() shows the
// workflow panel; the ID field is the input whose value === state.workflowMeta.id.
const FIND_ID_INPUT = `(function(){
  selection = null; if (multiSelect) multiSelect.clear();
  renderProperties();
  var inputs = Array.prototype.slice.call(document.querySelectorAll('#properties .field-input'));
  var hit = inputs.findIndex(function(i){ return i.value === state.workflowMeta.id; });
  return { found: hit >= 0, index: hit, total: inputs.length, currentId: state.workflowMeta.id };
})()`;

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't263-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't263-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't263-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const legs = {};
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    // ── leg1: synthetic value-set + input event (the peer's edit class) ──
    legs.leg1_synthetic = await ev(cmd, `(function(){
      var loc = ${FIND_ID_INPUT};
      if (!loc.found) return { ran:false, why:'id input not found', loc:loc };
      var before = state.workflowMeta.id;
      var inp = document.querySelectorAll('#properties .field-input')[loc.index];
      inp.value = 't263-syn';
      inp.dispatchEvent(new Event('input', { bubbles: true }));
      inp.dispatchEvent(new Event('change', { bubbles: true }));
      return { ran:true, before: before, after: state.workflowMeta.id, rebound: state.workflowMeta.id === 't263-syn' };
    })()`);

    // ── leg2: REAL keystrokes via CDP Input.insertText (trusted input event) ──
    const loc2 = await ev(cmd, FIND_ID_INPUT);
    if (loc2.found) {
      await ev(cmd, `(function(){
        var inp = document.querySelectorAll('#properties .field-input')[${loc2.index}];
        inp.focus(); inp.select();
        window.__t263_focusInput = inp;
        return true;
      })()`);
      await cmd('Input.insertText', { text: 't263-real' });
      await sleep(150);
      legs.leg2_real = await ev(cmd, `(function(){
        var stillFocused = document.activeElement && document.activeElement.classList && document.activeElement.classList.contains('field-input');
        var sameEl = document.activeElement === window.__t263_focusInput;
        return { ran:true, before: ${JSON.stringify(loc2.currentId)}, after: state.workflowMeta.id,
                 rebound: state.workflowMeta.id === 't263-real',
                 focusKept: !!stillFocused, sameElementFocused: !!sameEl };
      })()`);
    } else {
      legs.leg2_real = { ran: false, why: 'id input not found post-leg1', loc: loc2 };
    }

    // ── leg3: collision with an existing library key → silent revert? ──
    legs.leg3_collision = await ev(cmd, `(function(){
      library.set('t263-other', { workflowMeta: { id: 't263-other' } });
      var alerts = 0; var _alert = window.alert; window.alert = function(){ alerts++; };
      var toasts = 0; var _toast = (typeof showToast === 'function') ? showToast : null;
      if (_toast) showToast = function(){ toasts++; };
      var loc = ${FIND_ID_INPUT};
      var before = state.workflowMeta.id;
      var inp = document.querySelectorAll('#properties .field-input')[loc.index];
      inp.value = 't263-other';
      inp.dispatchEvent(new Event('input', { bubbles: true }));
      var after = state.workflowMeta.id;
      var fieldShows = (function(){
        var l = ${FIND_ID_INPUT};
        return l.found ? document.querySelectorAll('#properties .field-input')[l.index].value : '<not-found>';
      })();
      window.alert = _alert; if (_toast) showToast = _toast;
      library.delete('t263-other');
      return { ran:true, before: before, attempted: 't263-other', after: after,
               silentNoop: after === before, alerts: alerts, toasts: toasts, fieldShowsAfterRerender: fieldShows };
    })()`);

    // ── leg4: what id does saveToProject actually POST? (incident mechanism) ──
    legs.leg4_saveTarget = await ev(cmd, `(async function(){
      _apiAvailable = true;
      var origPrompt = promptSaveNote; promptSaveNote = async function(){ return 't263 probe'; };
      var origThumb = captureThumbnail; captureThumbnail = async function(){ return null; };
      var origFetch = window.fetch; var captured = null;
      window.fetch = async function(url, opts){
        if (String(url).indexOf('/api/save') >= 0) {
          captured = { url: String(url), body: JSON.parse(opts.body) };
          return { ok: true, json: async function(){ return { ok: true, v: 99 }; } };
        }
        return origFetch.apply(this, arguments);
      };
      try { await saveToProject(); } finally {
        window.fetch = origFetch; promptSaveNote = origPrompt; captureThumbnail = origThumb;
      }
      return { ran: !!captured, postedId: captured && captured.body.id,
               metaIdAtSave: state.workflowMeta.id,
               targetIsMetaId: !!captured && captured.body.id === state.workflowMeta.id };
    })()`);

    const out = {
      ok: true,
      note: 'inception probe — findings, not pass/fail; see legs',
      legs,
      readings: {
        IW1: 'saveToProject POSTs id = state.workflowMeta.id unconditionally (leg4)',
        IW2_H1_syntheticWorks: legs.leg1_synthetic && legs.leg1_synthetic.rebound,
        IW2_realWorks: legs.leg2_real && legs.leg2_real.rebound,
        collisionIsSilent: legs.leg3_collision && legs.leg3_collision.silentNoop && legs.leg3_collision.alerts === 0 && legs.leg3_collision.toasts === 0,
        focusLostAfterRename: legs.leg2_real && legs.leg2_real.rebound && !legs.leg2_real.sameElementFocused,
      },
    };
    process.stdout.write(JSON.stringify(out, null, 2) + '\n');
    process.exitCode = 0;
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, error: String(e && e.stack || e), legs }, null, 2) + '\n');
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
