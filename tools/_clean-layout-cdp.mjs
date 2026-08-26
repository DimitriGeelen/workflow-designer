#!/usr/bin/env node
// _clean-layout-cdp.mjs — headless browser driver for the Clean-layout bake (T-101).
//
// Loads the REAL editor (src/aef-workflow-designer.html) in headless Chromium and,
// for each examples/aef-processes/rendered/*.bpmn, runs the editor's own
// cleanLayout() then reads back the resulting geometry. This reuses the editor's
// exact Clean logic (tidy row-snap + T-093 branch pitch + T-094 align-rows) rather
// than reimplementing it in Python (PL-005: editor/bridge drift on shared logic).
//
// Dependency-free: drives Chromium over the DevTools Protocol using Node's native
// WebSocket + fetch (Node >= 22). Chromium is the cached Playwright build.
//
// Output: JSON on stdout, keyed by map basename:
//   { "<map>": { ok, moved, messinessBefore, messinessAfter,
//                nodes:[{id,x,y,lane}], lanes:[{id,height}] }, ... }
//
// Usage:  node tools/_clean-layout-cdp.mjs [map1 map2 ...]
//         (no args → all rendered/*.bpmn). Called by tools/bake-clean-layout.py.
import { spawn } from 'node:child_process';
import { readFileSync, readdirSync, mkdtempSync, existsSync, readFile } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve, basename } from 'node:path';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = join(ROOT, 'src', 'aef-workflow-designer.html');
const RENDERED = join(ROOT, 'examples', 'aef-processes', 'rendered');

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright');
  const cands = [];
  if (existsSync(cache)) {
    for (const d of readdirSync(cache)) {
      if (d.startsWith('chromium-')) cands.push(join(cache, d, 'chrome-linux64', 'chrome'));
    }
  }
  // Newest build dir last-ish; just pick the first that exists.
  cands.sort().reverse();
  for (const c of cands) if (existsSync(c)) return c;
  throw new Error('No Chromium binary found under ' + cache + ' (expected chromium-*/chrome-linux64/chrome)');
}

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function waitForPortFile(f, timeoutMs = 15000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (existsSync(f)) {
      const txt = readFileSync(f, 'utf8').split('\n');
      if (txt[0] && txt[0].trim()) return { port: parseInt(txt[0].trim(), 10), wsPath: (txt[1] || '').trim() };
    }
    await sleep(100);
  }
  throw new Error('Chromium did not report a DevTools port in time');
}

function cdpClient(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0;
  const pending = new Map();
  ws.addEventListener('message', ev => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  });
  const ready = new Promise((res, rej) => {
    ws.addEventListener('open', res);
    ws.addEventListener('error', e => rej(new Error('CDP websocket error: ' + (e.message || e.type))));
  });
  function cmd(method, params = {}) {
    return new Promise((res, rej) => {
      const mid = ++id;
      pending.set(mid, m => m.error ? rej(new Error(method + ': ' + JSON.stringify(m.error))) : res(m.result));
      ws.send(JSON.stringify({ id: mid, method, params }));
    });
  }
  return { ready, cmd, close: () => ws.close() };
}

async function evalJson(cmd, expression) {
  const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error('page eval threw: ' + JSON.stringify(r.exceptionDetails));
  return r.result.value;
}

async function main() {
  const argv = process.argv.slice(2);
  const maps = argv.length
    ? argv.map(a => a.endsWith('.bpmn') ? a : join(RENDERED, a + '.bpmn'))
    : readdirSync(RENDERED).filter(f => f.endsWith('.bpmn')).sort().map(f => join(RENDERED, f));

  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'bake-chrome-'));
  const proc = spawn(chrome, [
    '--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank',
  ], { stdio: ['ignore', 'ignore', 'pipe'] });
  let stderr = '';
  proc.stderr.on('data', d => { stderr += d.toString(); });

  let client;
  try {
    const { port } = await waitForPortFile(join(udd, 'DevToolsActivePort'));
    let page = { webSocketDebuggerUrl: await pageWsUrl(port) };
    client = cdpClient(page.webSocketDebuggerUrl);
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable');
    await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: 'file://' + EDITOR });

    // Wait until the editor's functions are defined.
    const t0 = Date.now();
    for (;;) {
      const ok = await evalJson(cmd,
        `(typeof cleanLayout==='function' && typeof adoptImportedXml==='function' && typeof state==='object' && !!state)`);
      if (ok) break;
      if (Date.now() - t0 > 20000) throw new Error('Editor did not finish loading (cleanLayout undefined)');
      await sleep(150);
    }
    // Neutralise blocking dialogs (adoptImportedXml alert() on parse failure).
    await evalJson(cmd, `(window.alert=window.confirm=window.prompt=function(){return true;},true)`);

    const out = {};
    for (const f of maps) {
      const name = basename(f, '.bpmn');
      const text = readFileSync(f, 'utf8');
      // Iterate cleanLayout() to a fixpoint. One Clean pass isn't idempotent:
      // align-rows snapping can merge clusters (nodes that were >14px apart become
      // <=14px), so a second pass settles them a few px further. We bake the
      // fixpoint (the maximally-tidy result), so a later re-bake moves 0 nodes.
      const expr = `(async function(){ try{
        adoptImportedXml(${JSON.stringify(text)});
        var mb=(typeof mapMessiness==='function')?mapMessiness():null;
        // Snapshot pre-Clean geometry: the fixpoint criterion is NET displacement
        // (T-300): Clean can 2-cycle on some topologies (transient moved>0) while
        // landing exactly where it started — that IS a bake fixpoint (bytes stable).
        var init={}; state.nodes.forEach(function(n){ init[n.id]=[n.x,n.y]; });
        var initH={}; state.lanes.forEach(function(l){ initH[l.id]=l.height; });
        var moved=0,last=0,iter=0;
        do { last=cleanLayout(); moved+=last; iter++; } while(last>0 && iter<12);
        var netMoved=0;
        state.nodes.forEach(function(n){ var p=init[n.id]; if(!p||Math.abs(n.x-p[0])>0.01||Math.abs(n.y-p[1])>0.01) netMoved++; });
        state.lanes.forEach(function(l){ if(Math.abs(l.height-(initH[l.id]!=null?initH[l.id]:l.height))>0.01) netMoved++; });
        var ma=(typeof mapMessiness==='function')?mapMessiness():null;
        // T-300 (G-012): return the editor's OWN serialization so the bake can
        // write it back verbatim — the committed corpus is editor-saved dialect
        // (T-288); regenerating via yaml-to-bpmn.py clobbers ids/DI/meta notes.
        var xml=(typeof buildBpmnXml==='function')?buildBpmnXml(state):null;
        // Thumbnail for the T-145 store append (bake mints a new .editor-versions
        // entry when bytes change; an honest post-Clean thumb, not a stale copy).
        var thumb=null; try{ if(typeof captureThumbnail==='function') thumb=await captureThumbnail(); }catch(e){}
        return {ok:true,moved:moved,netMoved:netMoved,lastMoved:last,iters:iter,messinessBefore:mb,messinessAfter:ma,xml:xml,thumb:thumb,
          nodes:state.nodes.map(function(n){return {id:n.id,x:n.x,y:n.y,lane:n.lane};}),
          lanes:state.lanes.map(function(l){return {id:l.id,height:l.height};})};
      }catch(e){ return {ok:false,error:String(e&&e.stack||e)}; } })()`;
      out[name] = await evalJson(cmd, expr);
    }
    process.stdout.write(JSON.stringify(out, null, 2) + '\n');
  } catch (e) {
    process.stderr.write('DRIVER ERROR: ' + (e && e.stack || e) + '\n' + (stderr ? 'chrome stderr tail:\n' + stderr.slice(-800) + '\n' : ''));
    process.exitCode = 1;
  } finally {
    try { client && client.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}

main();
