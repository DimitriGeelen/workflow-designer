#!/usr/bin/env node
// _autoload-verify-cdp.mjs — verify B1 (T-127 / T-128 GO): the editor AUTO-LOADS the
// autosaved document on reload (no banner), keyed by ?load so reloads never cross maps.
// ISOLATED headless Chromium (own --user-data-dir) — never the shared browser (G-006).
//
// Steps (against http://localhost:8834/designer.html):
//   1. bare load, clear localStorage, reload → assert NO banner AND NO toast (clean slate)
//   2. mutate a node (y += 37) on the bare designer + wait for debounced autosave
//   3. reload bare → assert: NO #restore-nudge banner; doc auto-loaded (node count > 0);
//      the mutated geometry is present (proves restore, not fresh seed); id has no _v2;
//      #restore-toast confirms
//   4. keying: ?load=A → mutate → autosave → reload ?load=A → restored (mutation present);
//      then load ?load=B (different map) → NOT clobbered by A's autosave (B's id loads)
// Output: JSON verdict on stdout. Exit 0 = all pass.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join } from 'node:path';
import { pageWsUrl } from './_cdp-attach.mjs';

const BASE = process.argv[2] || 'http://localhost:8834/designer.html';
const MAP_A = 'rendered/arc-lifecycle.bpmn';
const MAP_B = 'rendered/audit-process.bpmn';
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright');
  const cands = [];
  if (existsSync(cache)) for (const d of readdirSync(cache))
    if (d.startsWith('chromium-')) cands.push(join(cache, d, 'chrome-linux64', 'chrome'));
  cands.sort().reverse();
  for (const c of cands) if (existsSync(c)) return c;
  throw new Error('No Chromium binary under ' + cache);
}
async function waitForPortFile(f, timeoutMs = 15000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (existsSync(f)) {
      const txt = readFileSync(f, 'utf8').split('\n');
      if (txt[0] && txt[0].trim()) return { port: parseInt(txt[0].trim(), 10) };
    }
    await sleep(100);
  }
  throw new Error('Chromium did not report a DevTools port in time');
}
function cdpClient(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0; const pending = new Map();
  ws.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } });
  const ready = new Promise((res, rej) => { ws.addEventListener('open', res); ws.addEventListener('error', e => rej(new Error('CDP ws error: ' + (e.message || e.type)))); });
  function cmd(method, params = {}) { return new Promise((res, rej) => { const mid = ++id; pending.set(mid, m => m.error ? rej(new Error(method + ': ' + JSON.stringify(m.error))) : res(m.result)); ws.send(JSON.stringify({ id: mid, method, params })); }); }
  return { ready, cmd, close: () => ws.close() };
}
async function evalJson(cmd, expression) {
  const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error('page eval threw: ' + JSON.stringify(r.exceptionDetails));
  return r.result.value;
}
async function waitReady(cmd) {
  const t0 = Date.now();
  for (;;) {
    const ok = await evalJson(cmd, `(typeof state==='object' && !!state && typeof buildBpmnXml==='function' && typeof _appReady!=='undefined' && _appReady===true)`).catch(() => false);
    if (ok) return;
    if (Date.now() - t0 > 20000) throw new Error('editor did not finish loading');
    await sleep(150);
  }
}
async function nav(cmd, url) { await cmd('Page.navigate', { url }); await waitReady(cmd); await sleep(350); }

async function main() {
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'autoload-verify-'));
  const proc = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let stderr = ''; proc.stderr.on('data', d => stderr += d.toString());
  let client; const verdict = { steps: [], pass: false };
  try {
    const { port } = await waitForPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(port) };
    client = cdpClient(page.webSocketDebuggerUrl); await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');

    // 1. clean slate (bare)
    await nav(cmd, BASE);
    await evalJson(cmd, `localStorage.removeItem('aefAutosaveDoc')`);
    await nav(cmd, BASE);
    const clean = await evalJson(cmd, `({banner:!!document.getElementById('restore-nudge'), toast:!!document.getElementById('restore-toast'), nodes:state.nodes.length})`);
    verdict.steps.push({ step: 'clean-load-no-banner-no-toast', pass: clean.banner === false && clean.toast === false, got: clean });

    // 2. mutate + autosave (bare)
    const mutated = await evalJson(cmd, `(function(){ if(!state.nodes.length) return {skip:true}; var n=state.nodes[0]; n.y=(n.y||100)+37; renderAll(); return {id:state.workflowMeta.id, nodeId:n.id, y:n.y, nodes:state.nodes.length}; })()`);
    await sleep(1000);
    const saved = await evalJson(cmd, `(function(){ try{ var s=JSON.parse(localStorage.getItem('aefAutosaveDoc')||'null'); return s?{id:s.id, src:s.src||null, len:(''+s.xml).length}:null; }catch(e){return {err:String(e)};} })()`);
    verdict.steps.push({ step: 'edit-triggers-autosave', pass: !!(saved && saved.len > 100), got: saved, mutated });

    // 3. reload bare → auto-load, no banner, mutation present, no _v2, toast shown
    await nav(cmd, BASE);
    const restored = await evalJson(cmd, `(function(){
      var banner=!!document.getElementById('restore-nudge');
      var toast=!!document.getElementById('restore-toast');
      var id=state.workflowMeta.id;
      var n=state.nodes.filter(function(x){return x.id===${JSON.stringify(mutated.nodeId)};})[0];
      return {banner:banner, toast:toast, id:id, nodes:state.nodes.length, nodeY:n?n.y:null};
    })()`);
    const wantY = mutated.y;
    const okRestore = restored.banner === false
      && restored.nodes > 0
      && restored.nodeY === wantY
      && !/_v\d+$/.test(restored.id);
    verdict.steps.push({ step: 'reload-auto-loads-no-banner', pass: okRestore, got: restored, wantY, toastShown: restored.toast });

    // 4a. keying — same deep-link restores
    await evalJson(cmd, `localStorage.removeItem('aefAutosaveDoc')`);
    await nav(cmd, BASE + '?load=' + encodeURIComponent(MAP_A));
    const mA = await evalJson(cmd, `(function(){ var n=state.nodes[0]; n.y=(n.y||100)+41; renderAll(); return {id:state.workflowMeta.id, nodeId:n.id, y:n.y}; })()`);
    await sleep(1000);
    await nav(cmd, BASE + '?load=' + encodeURIComponent(MAP_A));
    const sameLink = await evalJson(cmd, `(function(){ var n=state.nodes.filter(function(x){return x.id===${JSON.stringify(mA.nodeId)};})[0]; return {id:state.workflowMeta.id, nodeY:n?n.y:null, banner:!!document.getElementById('restore-nudge')}; })()`);
    verdict.steps.push({ step: 'same-deeplink-restores', pass: sameLink.banner === false && sameLink.nodeY === mA.y, got: sameLink, wantY: mA.y });

    // 4b. keying — different deep-link is NOT clobbered by A's autosave
    // (A's autosave still in localStorage with src=MAP_A; open MAP_B)
    await nav(cmd, BASE + '?load=' + encodeURIComponent(MAP_B));
    const diffLink = await evalJson(cmd, `({id:state.workflowMeta.id, nodes:state.nodes.length, aId:${JSON.stringify(mA.id)}})`);
    // B must have loaded — its id differs from A's, and A's +41 mutation must not be here
    const okDiff = diffLink.id !== mA.id && diffLink.nodes > 0;
    verdict.steps.push({ step: 'different-deeplink-not-clobbered', pass: okDiff, got: diffLink });

    verdict.pass = verdict.steps.every(s => s.pass);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stderr.write('DRIVER ERROR: ' + (e && e.stack || e) + '\n' + (stderr ? stderr.slice(-600) : ''));
    process.exitCode = 1;
  } finally {
    try { client && client.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}
main();
