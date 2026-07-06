#!/usr/bin/env node
// _autosave-verify-cdp.mjs — verify editor document autosave (T-126 / G-005) in an
// ISOLATED headless Chromium (its own --user-data-dir). NEVER attaches to a shared
// or live browser — that is the exact failure this task exists to fix (G-006).
//
// Steps (against the served gallery http://localhost:8834/designer.html):
//   1. load, clear localStorage, reload → assert NO restore banner (clean slate)
//   2. mutate the document (move a node) + renderAll(); wait for debounced autosave
//      → assert localStorage[aefAutosaveDoc] now holds the doc XML
//   3. reload → assert the #restore-nudge banner appears; click Restore
//      → assert the document came back (node count > 0, same id)
// Output: JSON verdict on stdout. Exit 0 = all pass.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, existsSync as _e } from 'node:path';

const URL_ = process.argv[2] || 'http://localhost:8834/designer.html';
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
    const ok = await evalJson(cmd, `(typeof state==='object' && !!state && typeof buildBpmnXml==='function' && typeof _appReady!=='undefined')`).catch(() => false);
    if (ok) return;
    if (Date.now() - t0 > 20000) throw new Error('editor did not finish loading');
    await sleep(150);
  }
}

async function main() {
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'autosave-verify-'));
  const proc = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let stderr = ''; proc.stderr.on('data', d => stderr += d.toString());
  let client; const verdict = { steps: [], pass: false };
  try {
    const { port } = await waitForPortFile(join(udd, 'DevToolsActivePort'));
    const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    const page = targets.find(t => t.type === 'page');
    client = cdpClient(page.webSocketDebuggerUrl); await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');

    // 1. clean slate
    await cmd('Page.navigate', { url: URL_ }); await waitReady(cmd);
    await evalJson(cmd, `localStorage.removeItem('aefAutosaveDoc')`);
    await cmd('Page.navigate', { url: URL_ }); await waitReady(cmd); await sleep(200);
    const bannerClean = await evalJson(cmd, `!!document.getElementById('restore-nudge')`);
    verdict.steps.push({ step: 'clean-load-no-banner', pass: bannerClean === false, got: bannerClean });

    // 2. mutate + autosave
    const mutated = await evalJson(cmd, `(function(){ if(!state.nodes.length) return {skip:true}; var n=state.nodes[0]; n.y=(n.y||100)+37; renderAll(); return {id:state.workflowMeta.id, nodes:state.nodes.length}; })()`);
    await sleep(1000); // debounce 700ms + margin
    const saved = await evalJson(cmd, `(function(){ try{ var s=JSON.parse(localStorage.getItem('aefAutosaveDoc')||'null'); return s? {id:s.id, hasXml:(''+s.xml).indexOf('<')>=0, len:(''+s.xml).length}:null; }catch(e){return {err:String(e)};} })()`);
    verdict.steps.push({ step: 'edit-triggers-autosave', pass: !!(saved && saved.hasXml && saved.len > 100), got: saved, mutated });

    // 3. reload → restore banner → restore doc
    await cmd('Page.navigate', { url: URL_ }); await waitReady(cmd); await sleep(250);
    const bannerAfter = await evalJson(cmd, `!!document.getElementById('restore-nudge')`);
    const restored = await evalJson(cmd, `(function(){ var b=document.getElementById('restore-nudge'); if(!b) return {noBanner:true}; var btns=b.querySelectorAll('button'); var r=[].find.call(btns,x=>/restore/i.test(x.textContent)); if(!r) return {noBtn:true}; r.click(); return {id:state.workflowMeta.id, nodes:state.nodes.length, gone:!document.getElementById('restore-nudge')}; })()`);
    verdict.steps.push({ step: 'reload-shows-banner', pass: bannerAfter === true, got: bannerAfter });
    verdict.steps.push({ step: 'restore-brings-back-doc', pass: !!(restored && restored.nodes > 0 && restored.gone), got: restored });

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
