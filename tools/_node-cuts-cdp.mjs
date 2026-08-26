#!/usr/bin/env node
// _node-cuts-cdp.mjs — headless node-cut census over the rendered corpus (T-113).
//
// A "node-cut" is an edge whose rendered orthogonal polyline passes through the
// bounding box of a node it does not connect to — a pure legibility defect. This
// driver loads the REAL editor (src/aef-workflow-designer.html) in headless
// Chromium and, for each examples/aef-processes/rendered/*.bpmn, reads back the
// editor's own routed geometry and counts cuts using the editor's own
// polylineCrossesNodes — NOT a Python re-implementation (PL-005: editor logic must
// not be re-derived; a divergent metric manufactures phantom findings, cf. T-110).
//
// Dependency-free: drives Chromium over the DevTools Protocol using Node's native
// WebSocket + fetch (Node >= 22). Chromium is the cached Playwright build. This is
// a deliberate sibling of tools/_clean-layout-cdp.mjs (same CDP boilerplate); the
// duplication is intentional — perturbing the bake driver risks the corpus bake.
//
// Output: JSON on stdout, keyed by map basename:
//   { "<map>": { ok, cutEdges, incidences, edges, nodes,
//                cuts:[{edge, nodes:[id,...]}] }, ... }
//
// Usage:  node tools/_node-cuts-cdp.mjs [map1 map2 ...]
//         (no args → all rendered/*.bpmn). Consumed by tests/check-corpus-node-cuts.sh.
import { spawn } from 'node:child_process';
import { readFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
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

// The census, expressed as page JS. Uses the editor's own polylineCrossesNodes for
// the boolean "is this edge a cut", and an inline distinct-node count at the SAME
// margin (4) the editor uses, over the editor's own _renderedPolyline. No geometry
// is re-derived — we only read what the editor already computed at render time.
function censusExpr(text) {
  return `(function(){ try{
    adoptImportedXml(${JSON.stringify(text)}, {userImport:true});
    var cutEdges=0, incidences=0, cuts=[];
    for (var k=0;k<state.edges.length;k++){
      var e=state.edges[k];
      var src=findNode(e.source), tgt=findNode(e.target);
      if(!src||!tgt) continue;
      var poly=e._renderedPolyline;
      if(!poly||poly.length<2) continue;
      if(polylineCrossesNodes(poly, src, tgt)) cutEdges++;
      var crossed={}; var margin=4;
      for(var i=0;i<poly.length-1;i++){
        var a=poly[i], b=poly[i+1];
        var x1=Math.min(a.x,b.x), x2=Math.max(a.x,b.x);
        var y1=Math.min(a.y,b.y), y2=Math.max(a.y,b.y);
        for(var j=0;j<state.nodes.length;j++){
          var n=state.nodes[j];
          if(n.id===src.id||n.id===tgt.id) continue;
          var d=NODE_DEFAULTS[n.type];
          if(x2<n.x-margin||x1>n.x+d.w+margin) continue;
          if(y2<n.y-margin||y1>n.y+d.h+margin) continue;
          crossed[n.id]=1;
        }
      }
      var ids=Object.keys(crossed);
      incidences+=ids.length;
      if(ids.length) cuts.push({edge:e.id, nodes:ids});
    }
    return {ok:true, cutEdges:cutEdges, incidences:incidences,
            edges:state.edges.length, nodes:state.nodes.length, cuts:cuts};
  }catch(e){ return {ok:false, error:String(e&&e.stack||e)}; } })()`;
}

async function main() {
  const argv = process.argv.slice(2);
  const maps = argv.length
    ? argv.map(a => a.endsWith('.bpmn') ? a : join(RENDERED, a + '.bpmn'))
    : readdirSync(RENDERED).filter(f => f.endsWith('.bpmn')).sort().map(f => join(RENDERED, f));

  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'nodecuts-chrome-'));
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

    const t0 = Date.now();
    for (;;) {
      const ok = await evalJson(cmd,
        `(typeof adoptImportedXml==='function' && typeof polylineCrossesNodes==='function' && typeof findNode==='function' && typeof state==='object' && !!state)`);
      if (ok) break;
      if (Date.now() - t0 > 20000) throw new Error('Editor did not finish loading (polylineCrossesNodes undefined)');
      await sleep(150);
    }
    await evalJson(cmd, `(window.alert=window.confirm=window.prompt=function(){return true;},true)`);

    const out = {};
    for (const f of maps) {
      const name = basename(f, '.bpmn');
      const text = readFileSync(f, 'utf8');
      out[name] = await evalJson(cmd, censusExpr(text));
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
