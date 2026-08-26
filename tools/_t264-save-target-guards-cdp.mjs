#!/usr/bin/env node
// _t264-save-target-guards-cdp.mjs — T-264 regression guard: the save-target guard set
// built from the T-263 GO (rail-225 scratch-copy overwrite incident).
// Guards under test (src/aef-workflow-designer.html):
//   G1 collision feedback — props-panel ID rename onto an existing library key renders
//      a one-shot `.id-rename-notice` naming the id; state stays unchanged.
//   G2 commit-on-blur/Enter — the ID field (field() opts.deferred) commits once on
//      blur or Enter; per-keystroke input events do NOT commit, so focus survives the
//      whole edit. Other meta fields (Title) keep live commit.
//   G3 load-source mismatch confirm — saveToProject asks one confirm when the document
//      came in via ?load (state: _loadSrcKey === activeKey) and the load-source stem
//      differs from workflowMeta.id; decline aborts the POST and restores the button.
// Legs (fresh served editor, isolated chromium, G-006 — PASS/FAIL, exit 0 only if all pass):
//   leg1 inputNoCommit   — synthetic input event on ID field → id UNCHANGED
//   leg2 blurCommits     — value + blur → renamed (normalized)
//   leg3 enterCommits    — value + keydown Enter → renamed
//   leg4 focusKept       — CDP Input.insertText (trusted, mid-typing) → focus kept,
//                          no commit yet; blur then commits the typed value
//   leg5 collisionNotice — rename onto existing key + blur → notice rendered naming
//                          the id, state unchanged, notice one-shot (gone next render)
//   leg6 mismatchConfirm — ?load=rendered/other-map.bpmn + _loadSrcKey=activeKey:
//                          confirm false → no POST + label restored; true → POST
//   leg7 mismatchBITE    — guard reads STATE, not strings: same-stem ?load → no
//                          confirm; _loadSrcKey=null (no deep-link) → no confirm
//   leg8 titleStillLive  — Title field commits per input event (live), unchanged
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
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof renderProperties==='function'&&typeof renameActiveWorkflow==='function'&&typeof saveToProject==='function'&&typeof _loadSrcStem==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Locate a meta-editor field input by its label text (no selection → workflow panel).
const FIND_FIELD = `function __find(label){
  selection = null; if (multiSelect) multiSelect.clear();
  renderProperties();
  var fields = Array.prototype.slice.call(document.querySelectorAll('#properties .field'));
  for (var i = 0; i < fields.length; i++) {
    var l = fields[i].querySelector('.field-label');
    var inp = fields[i].querySelector('.field-input, .field-textarea');
    if (l && inp && l.childNodes[0] && l.childNodes[0].textContent.trim() === label) return inp;
  }
  return null;
}`;

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't264-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't264-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't264-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const legs = {};
  const fails = [];
  const assert = (name, cond, detail) => { legs[name] = { pass: !!cond, ...detail }; if (!cond) fails.push(name); };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    // ── leg1: input event alone does NOT commit ──
    const r1 = await ev(cmd, `(function(){ ${FIND_FIELD}
      var inp = __find('ID'); if (!inp) return { ran:false };
      var before = state.workflowMeta.id;
      inp.value = 't264-nocommit';
      inp.dispatchEvent(new Event('input', { bubbles: true }));
      return { ran:true, before: before, after: state.workflowMeta.id, stillFocusable: !!inp.isConnected };
    })()`);
    assert('leg1_inputNoCommit', r1.ran && r1.after === r1.before, r1);

    // ── leg2: blur commits (value normalized by the callback) ──
    const r2 = await ev(cmd, `(function(){ ${FIND_FIELD}
      var inp = __find('ID'); if (!inp) return { ran:false };
      var before = state.workflowMeta.id;
      inp.value = 'T264 Blur';
      inp.dispatchEvent(new Event('blur'));
      return { ran:true, before: before, after: state.workflowMeta.id, inLibrary: library.has('t264-blur'), key: activeKey };
    })()`);
    assert('leg2_blurCommits', r2.ran && r2.after === 't264-blur' && r2.inLibrary && r2.key === 't264-blur', r2);

    // ── leg3: Enter commits ──
    const r3 = await ev(cmd, `(function(){ ${FIND_FIELD}
      var inp = __find('ID'); if (!inp) return { ran:false };
      inp.value = 't264-enter';
      inp.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
      return { ran:true, after: state.workflowMeta.id, key: activeKey };
    })()`);
    assert('leg3_enterCommits', r3.ran && r3.after === 't264-enter' && r3.key === 't264-enter', r3);

    // ── leg4: REAL mid-typing keystrokes keep focus; blur then commits ──
    const loc4 = await ev(cmd, `(function(){ ${FIND_FIELD}
      var inp = __find('ID'); if (!inp) return { found:false };
      inp.focus(); inp.select(); window.__t264_inp = inp;
      return { found:true };
    })()`);
    if (loc4.found) {
      await cmd('Input.insertText', { text: 't264' });
      await sleep(100);
      await cmd('Input.insertText', { text: '-typed' });
      await sleep(100);
      const r4a = await ev(cmd, `(function(){
        return { midValue: window.__t264_inp.value,
                 focusKept: document.activeElement === window.__t264_inp,
                 idUnchangedMidType: state.workflowMeta.id === 't264-enter' };
      })()`);
      const r4b = await ev(cmd, `(function(){
        window.__t264_inp.blur();
        return { after: state.workflowMeta.id };
      })()`);
      assert('leg4_focusKept', r4a.focusKept && r4a.idUnchangedMidType && r4a.midValue === 't264-typed' && r4b.after === 't264-typed', { ...r4a, ...r4b });
    } else {
      assert('leg4_focusKept', false, { ran: false, why: 'id input not found' });
    }

    // ── leg5: collision renders the one-shot notice, state unchanged ──
    const r5 = await ev(cmd, `(function(){ ${FIND_FIELD}
      library.set('t264-taken', { workflowMeta: { id: 't264-taken' } });
      var inp = __find('ID');
      var before = state.workflowMeta.id;
      inp.value = 't264-taken';
      inp.dispatchEvent(new Event('blur'));
      var notice = document.querySelector('#properties .id-rename-notice');
      var noticeText = notice ? notice.textContent : null;
      var fieldAfter = __find('ID');   // re-render happened in the commit path
      var reverted = fieldAfter ? fieldAfter.value : '<none>';
      var noticeGoneNextRender = !document.querySelector('#properties .id-rename-notice');
      library.delete('t264-taken');
      return { ran:true, before: before, after: state.workflowMeta.id, noticeText: noticeText,
               fieldReverted: reverted, noticeGoneNextRender: noticeGoneNextRender };
    })()`);
    assert('leg5_collisionNotice',
      r5.ran && r5.after === r5.before && r5.noticeText && r5.noticeText.indexOf('t264-taken') >= 0
        && r5.fieldReverted === r5.before && r5.noticeGoneNextRender, r5);

    // ── leg6: load-source mismatch confirm gates the POST ──
    const r6 = await ev(cmd, `(async function(){
      _apiAvailable = true;
      history.replaceState(null, '', '?load=rendered/other-map.bpmn');
      _loadSrcKey = activeKey;
      var origPrompt = promptSaveNote; promptSaveNote = async function(){ return 't264 harness'; };
      var origThumb = captureThumbnail; captureThumbnail = async function(){ return null; };
      var origFetch = window.fetch; var posts = [];
      window.fetch = async function(url, opts){
        if (String(url).indexOf('/api/save') >= 0) {
          posts.push(JSON.parse(opts.body));
          return { ok: true, json: async function(){ return { ok: true, v: 99 }; } };
        }
        return origFetch.apply(this, arguments);
      };
      var confirms = []; var answer = false;
      var origConfirm = window.confirm;
      window.confirm = function(msg){ confirms.push(String(msg)); return answer; };
      var btn = document.getElementById('btn-save-project');
      var out = {};
      try {
        answer = false;
        await saveToProject();
        out.declined = { confirms: confirms.slice(), posts: posts.length,
                         btnLabel: btn ? btn.textContent : null };
        confirms.length = 0;
        answer = true;
        await saveToProject();
        out.accepted = { confirms: confirms.slice(), posts: posts.length,
                         postedId: posts.length ? posts[posts.length-1].id : null };
      } finally {
        window.fetch = origFetch; window.confirm = origConfirm;
        promptSaveNote = origPrompt; captureThumbnail = origThumb;
      }
      out.metaId = state.workflowMeta.id;
      return out;
    })()`);
    const d6 = r6.declined || {}, a6 = r6.accepted || {};
    const declinedOk = d6.posts === 0 && d6.confirms && d6.confirms.length === 1
      && d6.confirms[0].indexOf('rendered/other-map.bpmn') >= 0 && d6.confirms[0].indexOf(r6.metaId) >= 0
      && d6.btnLabel && d6.btnLabel.indexOf('Saving') < 0;
    const acceptedOk = a6.posts === 1 && a6.confirms.length === 1 && a6.postedId === r6.metaId;
    assert('leg6_mismatchConfirm', declinedOk && acceptedOk, r6);

    // ── leg7 BITE: guard driven by state, not string echo ──
    const r7 = await ev(cmd, `(async function(){
      _apiAvailable = true;
      var origPrompt = promptSaveNote; promptSaveNote = async function(){ return 't264 harness'; };
      var origThumb = captureThumbnail; captureThumbnail = async function(){ return null; };
      var origFetch = window.fetch; var posts = 0;
      window.fetch = async function(url, opts){
        if (String(url).indexOf('/api/save') >= 0) { posts++; return { ok: true, json: async function(){ return { ok: true, v: 99 }; } }; }
        return origFetch.apply(this, arguments);
      };
      var confirms = []; var origConfirm = window.confirm;
      window.confirm = function(msg){ confirms.push(String(msg)); return true; };
      var out = {};
      try {
        // 7a same-stem: ?load names the SAME map as the id → no mismatch confirm
        history.replaceState(null, '', '?load=rendered/' + state.workflowMeta.id + '.bpmn');
        _loadSrcKey = activeKey;
        await saveToProject();
        out.sameStem = { confirms: confirms.slice(), posts: posts };
        confirms.length = 0;
        // 7b no deep-link state: same URL still set, but _loadSrcKey=null → no confirm
        history.replaceState(null, '', '?load=rendered/other-map.bpmn');
        _loadSrcKey = null;
        await saveToProject();
        out.noDeepLink = { confirms: confirms.slice(), posts: posts };
      } finally {
        window.fetch = origFetch; window.confirm = origConfirm;
        promptSaveNote = origPrompt; captureThumbnail = origThumb;
        history.replaceState(null, '', location.pathname);
      }
      return out;
    })()`);
    const noMismatch = arr => arr.every(c => c.indexOf('Loaded from') < 0);
    assert('leg7_mismatchBITE',
      r7.sameStem && r7.sameStem.posts === 1 && noMismatch(r7.sameStem.confirms)
        && r7.noDeepLink && r7.noDeepLink.posts === 2 && noMismatch(r7.noDeepLink.confirms), r7);

    // ── leg8: Title field still live-commits per input event ──
    const r8 = await ev(cmd, `(function(){ ${FIND_FIELD}
      var inp = __find('Title'); if (!inp) return { ran:false };
      inp.value = 'T264 Live Title';
      inp.dispatchEvent(new Event('input', { bubbles: true }));
      return { ran:true, titleNow: state.workflowMeta.title };
    })()`);
    assert('leg8_titleStillLive', r8.ran && r8.titleNow === 'T264 Live Title', r8);

    const ok = fails.length === 0;
    process.stdout.write(JSON.stringify({ ok, pass: ok ? 'ALL 8 LEGS PASS' : undefined, fails, legs }, null, 2) + '\n');
    process.exitCode = ok ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, error: String(e && e.stack || e), fails, legs }, null, 2) + '\n');
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
