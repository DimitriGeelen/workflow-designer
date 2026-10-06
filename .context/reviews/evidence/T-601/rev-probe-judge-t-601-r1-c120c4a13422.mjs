// Independent reviewer probe for T-601 AC1. Loads every corpus map into an editor build,
// measures every event/gateway label block against the lane furniture READ FROM THE DOM
// (g.lane-header rect = header strip + lane band), and reports header/divider/pool violations.
// usage: node probe.mjs <editor.html> <mode:orig|long> [shotDir]
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join } from 'node:path';
import { pageWsUrl } from '/opt/832-Workflow-designer/tools/_cdp-attach.mjs';

const [editor, mode, shotDir] = process.argv.slice(2);
const LONG = 'run halted because the operator pressed the kill switch during settlement';
const MAPDIR = '/opt/832-Workflow-designer/examples/aef-processes/rendered';
const maps = readdirSync(MAPDIR).filter(f => f.endsWith('.bpmn')).sort();
const sleep = ms => new Promise(r => setTimeout(r, ms));
function chrome() {
  const c = join(homedir(), '.cache', 'ms-playwright');
  return readdirSync(c).filter(d => d.startsWith('chromium-')).sort().reverse()
    .map(d => join(c, d, 'chrome-linux64', 'chrome')).find(existsSync);
}
const udd = mkdtempSync(join(tmpdir(), 'rev601-'));
const proc = spawn(chrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
  '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let port;
for (let i = 0; i < 400 && !port; i++) {
  const f = join(udd, 'DevToolsActivePort');
  if (existsSync(f)) port = +readFileSync(f, 'utf8').split('\n')[0] || undefined;
  await sleep(100);
}
const ws = new WebSocket(await pageWsUrl(port));
let id = 0; const pend = new Map();
ws.addEventListener('message', ev => { const m = JSON.parse(ev.data);
  if (m.id && pend.has(m.id)) { pend.get(m.id)(m); pend.delete(m.id); }
  if (m.method === 'Page.javascriptDialogOpening') cmd('Page.handleJavaScriptDialog', { accept: true }); });
await new Promise(r => ws.addEventListener('open', r));
function cmd(method, params = {}) { return new Promise((res, rej) => { const k = ++id;
  pend.set(k, m => m.error ? rej(new Error(method + JSON.stringify(m.error))) : res(m.result));
  ws.send(JSON.stringify({ id: k, method, params })); }); }
async function ev(expression) { const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 500)); return r.result.value; }
await cmd('Page.enable'); await cmd('Runtime.enable');
await cmd('Emulation.setDeviceMetricsOverride', { width: 1600, height: 1000, deviceScaleFactor: 2, mobile: false });

const measure = (long) => `(function(){
  labelPrefs.wrapNames = true;
  var isB=function(n){ return n.type==='startEvent'||n.type==='endEvent'||/Gateway$/.test(n.type)||/^linkEvent/.test(n.type)||/^event/.test(n.type); };
  if (${long}) state.nodes.filter(isB).filter(function(n){ return !${JSON.stringify(process.env.ONLY||"")} || n.uid===${JSON.stringify(process.env.ONLY||"")}; }).forEach(function(n){ n.name=${JSON.stringify(LONG)}; });
  renderAll();
  var hdr=Array.prototype.slice.call(document.querySelectorAll('g.lane-header > rect')).map(function(r){
    return {x1:+r.getAttribute('x'), x2:+r.getAttribute('x')+(+r.getAttribute('width')), y1:+r.getAttribute('y'), y2:+r.getAttribute('y')+(+r.getAttribute('height'))}; });
  if(!hdr.length) return {lanes:0, out:[]};
  var hx2=hdr[0].x2, poolX=hdr[0].x1, top=hdr[0].y1, bot=hdr[hdr.length-1].y2;
  var segs=[]; state.edges.forEach(function(e){ var p=e._renderedPolyline; if(!p) return; for(var i=0;i<p.length-1;i++) segs.push(p[i],p[i+1]); });
  var out=[], total=0;
  state.nodes.filter(isB).forEach(function(n){
    var d=NODE_DEFAULTS[n.type], cy=n.y+d.h/2;
    var own=hdr.find(function(b){return cy>=b.y1&&cy<b.y2;});
    var rs=Array.prototype.slice.call(document.querySelectorAll('text[data-nl="'+n.uid+'"]')).map(function(t){var b=t.getBBox();return b;}).filter(function(b){return b.width>0;});
    if(!rs.length) return; total++;
    var x1=Math.min.apply(null,rs.map(function(b){return b.x;})), x2=Math.max.apply(null,rs.map(function(b){return b.x+b.width;}));
    var y1=Math.min.apply(null,rs.map(function(b){return b.y;})), y2=Math.max.apply(null,rs.map(function(b){return b.y+b.height;}));
    var side = x1 > n.x+d.w ? 'right' : (x2 < n.x ? 'left' : 'below');
    var v=[];
    if (x1 < hx2 && y2 > top && y1 < bot) v.push('HEADER('+(hx2-x1).toFixed(1)+'px)');
    if (own && (y1 < own.y1-1 || y2 > own.y2+1)) v.push('LANE(y '+y1.toFixed(0)+'-'+y2.toFixed(0)+' vs '+own.y1+'-'+own.y2+')');
    if (x1 < poolX || y2 > bot+1) v.push('POOL');
    var cross=0; rs.forEach(function(b){ for(var i=0;i<segs.length;i+=2){ var a=segs[i],c=segs[i+1];
      if(Math.max(a.x,c.x)<b.x||Math.min(a.x,c.x)>b.x+b.width||Math.max(a.y,c.y)<b.y||Math.min(a.y,c.y)>b.y+b.height) continue; cross++; } });
    var nb=0; state.nodes.forEach(function(m){ if(m===n) return; var dm=NODE_DEFAULTS[m.type];
      rs.forEach(function(b){ if(b.x+b.width>m.x+1&&b.x<m.x+dm.w-1&&b.y+b.height>m.y+1&&b.y<m.y+dm.h-1){ nb++; } }); });
    if(nb) v.push('UNDER_NODE('+nb+')');
    out.push({uid:n.uid,name:n.name.slice(0,40),side:side,v:v,cross:cross,x1:x1,y1:y1,x2:x2,y2:y2});
  });
  return {lanes:hdr.length,total:total,out:out};
})()`;

let agg = { under: 0, labels: 0, header: 0, lane: 0, pool: 0, cross: 0, side: 0 };
const rows = [];
for (const m of maps) {
  const xml = readFileSync(join(MAPDIR, m), 'utf8');
  await cmd('Page.navigate', { url: 'file://' + editor });
  for (let t0 = Date.now(); ; ) { if (await ev(`typeof renderAll==='function'&&!!(window.state||typeof state!=='undefined')&&window._deepLinkSettled!==null`).catch(() => false)) break;
    if (Date.now() - t0 > 40000) throw new Error('load timeout'); await sleep(150); }
  await ev(`(function(){ try{ localStorage.clear(); }catch(e){} adoptImportedXml(${JSON.stringify(xml)}, {userImport:true}); return 1; })()`);
  const r = await ev(measure(mode === 'long'));
  for (const o of r.out) {
    agg.labels++; agg.cross += o.cross; if (o.side !== 'below') agg.side++;
    if (o.v.some(s => s.startsWith('HEADER'))) agg.header++;
    if (o.v.some(s => s.startsWith('LANE'))) agg.lane++;
    if (o.v.includes('POOL')) agg.pool++;
    if (o.v.some(s => s.startsWith('UNDER'))) agg.under++;
    if (o.v.length || (process.env.DUMP && o.uid===process.env.DUMP)) rows.push(`${m}  ${o.uid}  [${o.side}] "${o.name}"  ${o.v.join(' ')}  cross=${o.cross} rect=[${o.x1.toFixed(0)},${o.y1.toFixed(0)},${o.x2.toFixed(0)},${o.y2.toFixed(0)}]`);
  }
  if (shotDir && r.out.some(o => o.v.length || o.side !== 'below')) {
    // clip each moved/violating label with its shape and the lane header
    for (const o of r.out.filter(o => o.v.length || o.side !== 'below').slice(0, 3)) {
      const box = await ev(`(function(){ var s=document.querySelector('svg#canvas, svg'); var parts=[];
        document.querySelectorAll('text[data-nl="${o.uid}"]').forEach(function(t){parts.push(t.getBoundingClientRect());});
        var g=document.querySelector('[data-node-id="${o.uid}"]'); if(g) parts.push(g.getBoundingClientRect());
        var lh=document.querySelector('g.lane-header rect'); if(lh){var r=lh.getBoundingClientRect(); parts.push({left:r.left,right:r.right,top:parts[0].top,bottom:parts[0].bottom});}
        var x1=Math.min.apply(null,parts.map(function(r){return r.left;})),x2=Math.max.apply(null,parts.map(function(r){return r.right;}));
        var y1=Math.min.apply(null,parts.map(function(r){return r.top;})),y2=Math.max.apply(null,parts.map(function(r){return r.bottom;}));
        return {x:Math.max(0,x1-40),y:Math.max(0,y1-60),w:(x2-x1)+80,h:(y2-y1)+120}; })()`);
      const shot = await cmd('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true, clip: { x: box.x, y: box.y, width: box.w, height: box.h, scale: 1 } });
      writeFileSync(join(shotDir, `${m.replace('.bpmn', '')}-${o.uid}-${mode}.png`), Buffer.from(shot.data, 'base64'));
    }
  }
}
console.log(`editor=${editor} mode=${mode} maps=${maps.length}`);
console.log(JSON.stringify(agg));
rows.forEach(r => console.log('  ' + r));
ws.close(); proc.kill('SIGKILL');
