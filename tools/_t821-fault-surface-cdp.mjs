#!/usr/bin/env node
// _t821-fault-surface-cdp.mjs — does the fault surface actually record, show, survive and
// stay harmless?
//
// T-821 (F-05). Four claims, each of which can fail independently:
//
//   RECORDS   a fault reaches the ring with code, detail, time and build.
//   SHOWS     the indicator is ABSENT with zero faults and PRESENT with some. Absence is
//             the load-bearing half: a badge that is always there is chrome, and the whole
//             value of this one is the moment it appears.
//   SURVIVES  the ring is restored across a reload — the conditions worth reading (quota,
//             a seam that stopped answering) are exactly the ones an operator reloads to
//             escape, so a surface that forgets on reload never shows them.
//   HARMLESS  aefRecordFault cannot throw. Every caller is inside a `catch` whose contract
//             is "never break the editor"; a recorder that throws turns a swallowed failure
//             into a broken editor, which is strictly worse than the silence it replaced.
//
// And one end-to-end leg: break navigator.clipboard, press Copy, and require a
// `clipboard-write` fault to appear. Testing aefRecordFault directly proves the recorder;
// only this proves the WIRING, which is where T-818 found both probes had rotted.
//
// Exit 0 = pass.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const MAP = 'arc-lifecycle';
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&typeof aefRecordFault==='function')`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready (needs aefRecordFault — is the T-821 build synced?)'); await sleep(150); } }

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 'fs-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'fs-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 'fs-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down');
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1200, height: 820, deviceScaleFactor: 1, mobile: false });
    const NAV = `${BASE}/designer.html?load=rendered/${MAP}.bpmn`;
    await cmd('Page.navigate', { url: NAV });
    await waitReady(cmd); await sleep(400);

    // --- SHOWS (absence half). Nothing has failed, so there must be no badge at all.
    const clean = await ev(cmd, `(function(){ var b=document.getElementById('brand-fault'); return { exists: !!b, hidden: !!(b&&b.hidden), faults: aefFaults().length }; })()`);
    push('indicator-absent-when-clean', clean.exists === true && clean.hidden === true && clean.faults === 0, clean);

    // --- HARMLESS. Hostile inputs, from inside the contract the callers rely on. If any of
    // these throws, the call sites it was written for become editor-breaking.
    const harmless = await ev(cmd, `(function(){
      var circular = {}; circular.self = circular;
      var thrower = { get message(){ throw new Error('detail getter exploded'); } };
      var cases = [
        function(){ aefRecordFault(); },
        function(){ aefRecordFault(null, null); },
        function(){ aefRecordFault('circular', circular); },
        function(){ aefRecordFault('thrower', thrower); },
        function(){ aefRecordFault({toString:function(){ throw new Error('code exploded'); }}, 'x'); }
      ];
      var threw = [];
      for (var i=0;i<cases.length;i++){ try { cases[i](); } catch(e){ threw.push(i + ':' + e.message); } }
      return { threw: threw, alive: (typeof state==='object' && !!state) };
    })()`);
    push('recorder-never-throws', harmless.threw.length === 0 && harmless.alive === true, harmless);

    // --- reset to a clean ring before the real-path leg, so its count is unambiguous.
    await ev(cmd, `aefClearFaults()`);
    await sleep(80);

    // --- END TO END. Break the clipboard and press the real Copy button. This is the leg
    // that tests the WIRING; everything above tests the recorder.
    await ev(cmd, `(function(){
      Object.defineProperty(navigator, 'clipboard', {
        configurable: true,
        get: function(){ return { writeText: function(){ return Promise.reject(new Error('T-821 control: clipboard denied')); } }; }
      });
    })()`);
    await ev(cmd, `document.getElementById('btn-copy-xml').click()`);
    let wired = null;
    for (let i = 0; i < 30; i++) { wired = await ev(cmd, `aefFaults()`); if (wired.length) break; await sleep(100); }
    push('real-failure-is-recorded', wired.length === 1 && wired[0].code === 'clipboard-write' && /denied/.test(wired[0].detail || ''), wired);

    // --- SHOWS (presence half), and the badge reports the count.
    await sleep(150);
    const shown = await ev(cmd, `(function(){ var b=document.getElementById('brand-fault'); return { hidden: !!b.hidden, text: b.textContent }; })()`);
    push('indicator-appears-with-count', shown.hidden === false && /1/.test(shown.text), shown);

    // --- the panel opens on a REAL click of the badge and names the condition.
    const box = await ev(cmd, `(function(){ var r=document.getElementById('brand-fault').getBoundingClientRect(); return { x:r.left+r.width/2, y:r.top+r.height/2 }; })()`);
    await cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x: box.x, y: box.y, button: 'left', clickCount: 1, buttons: 1 });
    await cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x: box.x, y: box.y, button: 'left', clickCount: 1, buttons: 0 });
    await sleep(250);
    const panel = await ev(cmd, `(function(){ var p=document.getElementById('fault-panel'); return { open: !!p, text: p ? p.innerText.slice(0,400) : null }; })()`);
    push('panel-opens-and-names-it', panel.open === true && /clipboard-write/.test(panel.text || ''), panel && { open: panel.open, hasCode: /clipboard-write/.test(panel.text || '') });

    // --- SURVIVES a reload. Restore runs at init from localStorage.
    await ev(cmd, `(function(){ var p=document.getElementById('fault-panel'); if(p) p.remove(); })()`);
    await cmd('Page.navigate', { url: NAV });
    await waitReady(cmd); await sleep(500);
    const after = await ev(cmd, `(function(){ var b=document.getElementById('brand-fault'); return { faults: aefFaults().length, code: (aefFaults()[0]||{}).code, hidden: !!(b&&b.hidden) }; })()`);
    push('survives-reload', after.faults === 1 && after.code === 'clipboard-write' && after.hidden === false, after);

    // --- clearing returns the editor to the absent state, or the badge is a one-way door.
    await ev(cmd, `aefClearFaults()`);
    await sleep(120);
    const cleared = await ev(cmd, `(function(){ var b=document.getElementById('brand-fault'); return { hidden: !!b.hidden, faults: aefFaults().length, stored: localStorage.getItem('aefFaults') }; })()`);
    push('clear-restores-absence', cleared.hidden === true && cleared.faults === 0 && cleared.stored === null, cleared);

    verdict.pass = verdict.steps.every(s => s.pass);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), steps: verdict.steps }, null, 2) + '\n');
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
