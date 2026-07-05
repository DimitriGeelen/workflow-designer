#!/usr/bin/env node
// _label-overlap-probe.mjs — headless edge-label overlap census (T-105 investigation).
//
// Loads the REAL editor, imports one or more .bpmn (or two git blobs of the same map
// for a pre/post comparison), runs the full render (which includes
// adjustEdgeLabelPlacements — the collision-avoidance post-pass), then reads back the
// MEASURED getBBox of every rendered edge-label text and counts:
//   - label∩label overlapping pairs (the readability defect)
//   - label∩gateway-glyph overlaps (label sitting on a diamond)
// Reports per-map counts + the offending pairs, so we can confirm WHERE the collision
// comes from and whether pre-bake vs post-bake geometry differs.
//
// Usage:
//   node tools/_label-overlap-probe.mjs <file.bpmn> [file2.bpmn ...]
//   node tools/_label-overlap-probe.mjs --stdin < map.bpmn   (label:"stdin")
// Reuses the CDP boilerplate from tools/_node-cuts-cdp.mjs (PL-005: editor's own render).
import { spawn } from 'node:child_process';
import { readFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve, basename } from 'node:path';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = join(ROOT, 'src', 'aef-workflow-designer.html');

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright');
  const cands = [];
  if (existsSync(cache)) for (const d of readdirSync(cache))
    if (d.startsWith('chromium-')) cands.push(join(cache, d, 'chrome-linux64', 'chrome'));
  cands.sort().reverse();
  for (const c of cands) if (existsSync(c)) return c;
  throw new Error('No Chromium under ' + cache);
}
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function waitForPortFile(f, timeoutMs = 15000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (existsSync(f)) {
      const txt = readFileSync(f, 'utf8').split('\n');
      if (txt[0] && txt[0].trim()) return { port: parseInt(txt[0].trim(), 10) };
    }
    await sleep(100);
  }
  throw new Error('Chromium DevTools port timeout');
}
function cdpClient(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0; const pending = new Map();
  ws.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } });
  const ready = new Promise((res, rej) => { ws.addEventListener('open', res); ws.addEventListener('error', e => rej(new Error('CDP ws error'))); });
  function cmd(method, params = {}) {
    return new Promise((res, rej) => { const mid = ++id; pending.set(mid, m => m.error ? rej(new Error(method + ': ' + JSON.stringify(m.error))) : res(m.result)); ws.send(JSON.stringify({ id: mid, method, params })); });
  }
  return { ready, cmd, close: () => ws.close() };
}
async function evalJson(cmd, expression) {
  const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error('eval threw: ' + JSON.stringify(r.exceptionDetails));
  return r.result.value;
}

// Import text, render, then measure edge-label bboxes and gateway-glyph rects.
function probeExpr(text) {
  return `(function(){ try{
    adoptImportedXml(${JSON.stringify(text)}, {userImport:true});
    // gather measured label boxes
    var labels=[];
    var texts=document.querySelectorAll('#gEdges text.edge-label, text.edge-label');
    for (var i=0;i<texts.length;i++){
      var t=texts[i]; var b=t.getBBox();
      if(!b.width) continue;
      labels.push({el:t.getAttribute('data-el'), name:t.textContent,
                   x1:b.x, y1:b.y, x2:b.x+b.width, y2:b.y+b.height});
    }
    // gateway glyph rects (nodes of gateway type) from state geometry
    var gws=[];
    for (var j=0;j<state.nodes.length;j++){
      var n=state.nodes[j]; var d=NODE_DEFAULTS[n.type];
      if(String(n.type).toLowerCase().indexOf('gateway')>=0)
        gws.push({id:n.id, x1:n.x, y1:n.y, x2:n.x+d.w, y2:n.y+d.h});
    }
    var inter=function(a,b){ return !(a.x2<b.x1||a.x1>b.x2||a.y2<b.y1||a.y1>b.y2); };
    var overlapArea=function(a,b){ var w=Math.min(a.x2,b.x2)-Math.max(a.x1,b.x1); var h=Math.min(a.y2,b.y2)-Math.max(a.y1,b.y1); return (w>0&&h>0)?Math.round(w*h):0; };
    var pairs=[];
    for(var p=0;p<labels.length;p++) for(var q=p+1;q<labels.length;q++)
      if(inter(labels[p],labels[q])) pairs.push({a:labels[p].el,an:labels[p].name,b:labels[q].el,bn:labels[q].name,area:overlapArea(labels[p],labels[q])});
    var onGw=[];
    for(var p2=0;p2<labels.length;p2++) for(var g=0;g<gws.length;g++)
      if(inter(labels[p2],gws[g])) onGw.push({label:labels[p2].el,name:labels[p2].name,gw:gws[g].id,area:overlapArea(labels[p2],gws[g])});
    return {ok:true, nLabels:labels.length, labelPairs:pairs.length, onGateway:onGw.length,
            pairs:pairs, onGw:onGw};
  }catch(e){ return {ok:false, error:String(e&&e.stack||e)}; } })()`;
}

async function main() {
  const argv = process.argv.slice(2);
  let jobs = []; // {label, text}
  if (argv[0] === '--stdin') {
    jobs.push({ label: 'stdin', text: readFileSync(0, 'utf8') });
  } else {
    for (const a of argv) {
      // support git-blob syntax  rev:path  via env? keep simple: plain files
      jobs.push({ label: basename(a), text: readFileSync(a, 'utf8') });
    }
  }
  if (!jobs.length) { console.error('usage: _label-overlap-probe.mjs <file.bpmn> ...'); process.exit(2); }

  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'labelovl-chrome-'));
  const proc = spawn(chrome, ['--headless=new','--no-sandbox','--disable-gpu','--disable-dev-shm-usage','--remote-debugging-port=0',`--user-data-dir=${udd}`,'about:blank'], { stdio: ['ignore','ignore','pipe'] });
  let stderr = ''; proc.stderr.on('data', d => stderr += d.toString());
  let client;
  try {
    const { port } = await waitForPortFile(join(udd, 'DevToolsActivePort'));
    const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    const page = targets.find(t => t.type === 'page');
    client = cdpClient(page.webSocketDebuggerUrl);
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: 'file://' + EDITOR });
    const t0 = Date.now();
    for (;;) {
      const ok = await evalJson(cmd, `(typeof adoptImportedXml==='function' && typeof state==='object' && !!state)`);
      if (ok) break;
      if (Date.now() - t0 > 20000) throw new Error('editor load timeout');
      await sleep(150);
    }
    await evalJson(cmd, `(window.alert=window.confirm=window.prompt=function(){return true;},true)`);
    const out = {};
    for (const j of jobs) out[j.label] = await evalJson(cmd, probeExpr(j.text));
    process.stdout.write(JSON.stringify(out, null, 2) + '\n');
  } catch (e) {
    process.stderr.write('DRIVER ERROR: ' + (e && e.stack || e) + '\n' + (stderr ? stderr.slice(-600) : ''));
    process.exitCode = 1;
  } finally {
    try { client && client.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}
main();
