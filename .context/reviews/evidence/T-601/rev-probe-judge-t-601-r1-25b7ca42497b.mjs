import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join } from 'node:path';
const ROOT='/opt/832-Workflow-designer';
const { pageWsUrl } = await import(ROOT+'/tools/_cdp-attach.mjs');
const EDITOR=join(ROOT,'src','aef-workflow-designer.html');
const OUT=process.argv[2];
function findChrome(){const c=join(homedir(),'.cache','ms-playwright');const a=[];for(const d of readdirSync(c))if(d.startsWith('chromium-'))a.push(join(c,d,'chrome-linux64','chrome'));a.sort().reverse();return a.find(existsSync);}
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const udd=mkdtempSync(join(tmpdir(),'rev601-'));
const proc=spawn(findChrome(),['--headless=new','--no-sandbox','--disable-gpu','--remote-debugging-port=0',`--user-data-dir=${udd}`,'about:blank'],{stdio:'ignore'});
let port;for(let i=0;i<400;i++){const f=join(udd,'DevToolsActivePort');if(existsSync(f)){const t=readFileSync(f,'utf8').split('\n')[0];if(t.trim()){port=+t;break;}}await sleep(100);}
const ws=new WebSocket(await pageWsUrl(port));let id=0;const pend=new Map();
ws.addEventListener('message',ev=>{const m=JSON.parse(ev.data);if(m.id&&pend.has(m.id)){pend.get(m.id)(m);pend.delete(m.id);}});
await new Promise(r=>ws.addEventListener('open',r));
const cmd=(method,params={})=>new Promise((res,rej)=>{const k=++id;pend.set(k,m=>m.error?rej(new Error(JSON.stringify(m.error))):res(m.result));ws.send(JSON.stringify({id:k,method,params}));});
const ev=async e=>{const r=await cmd('Runtime.evaluate',{expression:e,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw new Error(JSON.stringify(r.exceptionDetails).slice(0,500));return r.result.value;};
await cmd('Page.enable');await cmd('Runtime.enable');
await cmd('Emulation.setDeviceMetricsOverride',{width:1400,height:900,deviceScaleFactor:2,mobile:false});
await cmd('Page.navigate',{url:'file://'+EDITOR});
for(let t0=Date.now();;){if(await ev(`typeof renderAll==='function'&&!!(window.state&&state.nodes)||(typeof state==='object'&&!!state&&!!state.nodes)`))break;if(Date.now()-t0>40000)throw 'timeout';await sleep(150);}
await sleep(500);
// audit: every label-below node, every label line, vs header strip & own band
const AUDIT=`(function(){
 var isB=function(n){return n.type==='startEvent'||n.type==='endEvent'||/Gateway$/.test(n.type)||/^linkEvent/.test(n.type)||/^event/.test(n.type);};
 var bands=[],y=POOL_Y+POOL_HEADER;getLanes().forEach(function(l){bands.push({y1:y,y2:y+l.height,name:l.name||l.id});y+=l.height;});
 var hx=POOL_X+LANE_HEADER, out=[];
 state.nodes.filter(isB).forEach(function(n){var d=NODE_DEFAULTS[n.type];var cy=n.y+d.h/2;
  var bi=bands.findIndex(function(b){return cy>=b.y1&&cy<b.y2;});
  Array.prototype.slice.call(document.querySelectorAll('text[data-nl="'+n.uid+'"]')).forEach(function(t){var b=t.getBBox();if(!b.width)return;
   var probs=[];if(b.x<hx-1)probs.push('header');
   if(bi>=0){var B=bands[bi];if(b.y<B.y1-1||b.y+b.height>B.y2+1)probs.push('outside-own-lane');}
   if(probs.length)out.push({node:n.uid,name:n.name,lane:bi>=0?bands[bi].name:null,text:t.textContent,probs:probs,bb:[b.x,b.y,b.width,b.height].map(Math.round)});});});
 return {nodes:state.nodes.filter(isB).length,bands:bands,issues:out};})()`;
console.log('DEFAULT MAP audit:',JSON.stringify(await ev(`labelPrefs.wrapNames=true;renderAll();`+AUDIT)));
// scenario: node at bottom of lane 1 with long name, lane1 node, keep edges
const r=await ev(`(function(){var isB=function(n){return n.type==='startEvent'||n.type==='endEvent'||/Gateway$/.test(n.type)||/^linkEvent/.test(n.type)||/^event/.test(n.type);};
 var n=state.nodes.filter(isB)[0];var d=NODE_DEFAULTS[n.type];n.name='run halted because the operator pressed the kill switch during settlement';
 var b0y=POOL_Y+POOL_HEADER, h=getLanes()[0].height; n.x=POOL_X+LANE_HEADER+240; n.y=b0y+h-d.h-6; renderAll(); window._probeUid=n.uid; return {uid:n.uid,x:n.x,y:n.y};})()`+';'+'');
console.log('scenario lane-bottom node', JSON.stringify(r));
console.log('AUDIT after lane-bottom:',JSON.stringify(await ev(AUDIT)));
const box=await ev(`(function(){var p=[];document.querySelectorAll('text[data-nl="'+window._probeUid+'"]').forEach(function(t){p.push(t.getBoundingClientRect());});var g=document.querySelector('[data-node-id="'+window._probeUid+'"]');if(g)p.push(g.getBoundingClientRect());var lh=document.querySelector('g.lane-header rect');if(lh)p.push(lh.getBoundingClientRect());
 var x1=Math.min.apply(null,p.map(function(r){return r.left}));var x2=Math.max.apply(null,p.map(function(r){return r.right}));var y1=Math.min.apply(null,p.map(function(r){return r.top}));var y2=Math.max.apply(null,p.map(function(r){return r.bottom}));return {x:x1-20,y:y1-20,w:x2-x1+40,h:y2-y1+40};})()`);
const shot=await cmd('Page.captureScreenshot',{format:'png',captureBeyondViewport:true,clip:{x:Math.max(0,box.x),y:Math.max(0,box.y),width:box.w,height:box.h,scale:1}});
writeFileSync(OUT,Buffer.from(shot.data,'base64'));console.log('wrote',OUT);
ws.close();proc.kill('SIGKILL');process.exit(0);
