#!/usr/bin/env node
// _t601-lane-boundary.mjs — does the label placement pass respect the pool and
// the lane bands, or does it score a label sitting on the lane header as clean?
//
// THE DEFECT. adjustLabelPlacements() scored candidates with bboxScore(), which
// counted rendered edge segments and other nodes' shape boxes and nothing else.
// The pool outline, the pool header band and the per-lane header strip are drawn
// by renderPool() and were invisible to it, so a placement lying on top of the
// lane header — or reaching over a divider into the next lane — scored a clean 0
// and was kept. The operator reported exactly this on 2026-08-26. T-600 wrapped
// the text, which NARROWS the overrun; only a containment term can clamp it.
//
// WHY THE DIVIDER LEG IS NOT COSMETIC. A lane encodes WHO acts. A label drawn
// over the neighbouring lane attributes the step to the wrong actor, which is a
// claim about what the diagram MEANS.
//
// LEGS ASSERT GEOMETRY, NOT MOVEMENT. "n labels moved" would pass on a pass that
// moved them somewhere equally wrong. Every leg below compares a MEASURED label
// rect against MEASURED furniture read out of the same live document.
//
// Legs:
//   L1  no label rect overlaps the lane header strip        (scenario: left edge)
//   L2  no label rect straddles a lane divider              (scenario: lane bottom)
//   L3  no label rect leaves the pool interior              (scenario: left edge)
//   L4  an uncontested label KEEPS its default below placement, still centred on
//       its shape — the T-105 contract, and the reason the corpus does not reflow
//   L5  integrity: the document really has >= 2 lanes and a positive pool width,
//       otherwise hasPool is false and L1-L3 assert nothing at all
//
// --self-test restores the pre-T-601 sum (no pool term) and requires L1-L3 to FAIL.
//
// Usage:  node tools/_t601-lane-boundary.mjs [--self-test]
// Exit:   0 pass · 1 leg failed · 2 driver/integrity error
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = join(ROOT, 'src', 'aef-workflow-designer.html');
const LONG = 'run halted because the operator pressed the kill switch during settlement';
const SHORT = 'ok';

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
function cdpClient(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0; const pending = new Map();
  ws.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } });
  const ready = new Promise((res, rej) => { ws.addEventListener('open', res); ws.addEventListener('error', () => rej(new Error('CDP ws error'))); });
  const cmd = (method, params = {}) => new Promise((res, rej) => {
    const mid = ++id;
    pending.set(mid, m => m.error ? rej(new Error(method + ': ' + JSON.stringify(m.error))) : res(m.result));
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  return { ready, cmd, close: () => ws.close() };
}
async function evalJson(cmd, expression) {
  const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error('eval threw: ' + JSON.stringify(r.exceptionDetails).slice(0, 400));
  return r.result.value;
}

// Place the first label-below node per `where`, rename it, re-render through the
// REAL pipeline (renderAll calls adjustLabelPlacements at :3255), then read back
// measured label rects AND the measured furniture from the same document.
const probeExpr = (name, where) => `(function(){ try{
  labelPrefs.wrapNames = true;
  var isBelow=function(n){ return n.type==='startEvent'||n.type==='endEvent'||
    /Gateway$/.test(n.type)||/^linkEvent/.test(n.type)||/^event/.test(n.type); };
  var n=state.nodes.filter(isBelow)[0];
  if(!n) return {ok:false,error:'no label-below node in the default document'};
  n.name=${JSON.stringify(name)};
  var d=NODE_DEFAULTS[n.type];
  var bandsPre=[], yPre=POOL_Y+POOL_HEADER;
  getLanes().forEach(function(l){ bandsPre.push({y1:yPre,y2:yPre+l.height}); yPre+=l.height; });
  if(!bandsPre.length) return {ok:false,error:'document has no lanes'};
  var b0=bandsPre[0];
  if(${JSON.stringify(where)}==='left'){
    n.x = POOL_X + LANE_HEADER + 4;              // hard against the lane header
    n.y = b0.y1 + Math.max(8,(b0.y2-b0.y1-d.h)/2);
  } else if(${JSON.stringify(where)}==='poolbottom'){
    // Bottom of the LAST lane: the default below-label falls past the pool floor,
    // and a side placement clamped into that band is inside it. This is the case
    // the containment clause exists for AND one the pass can actually satisfy.
    var lastB=bandsPre[bandsPre.length-1];
    n.x = POOL_X + LANE_HEADER + 300;
    n.y = lastB.y2 - d.h - 6;
  } else if(${JSON.stringify(where)}==='bottom'){
    n.x = POOL_X + LANE_HEADER + 240;            // clear of the header, low in the band
    n.y = b0.y2 - d.h - 6;
  } else {                                        // 'clean' — genuinely uncontested
    // Empty space in the tallest band AND no edges at all. Without dropping the
    // edges the node's own connectors run under its label, the placement is
    // legitimately contested, and the leg would be asserting the opposite of
    // what it claims. Runs last, so the earlier probes keep their edges.
    var last=bandsPre[bandsPre.length-1];
    state.edges = [];
    state.nodes = [n];
    n.x = POOL_X + LANE_HEADER + 300;
    n.y = last.y1 + (last.y2-last.y1)/2 - 40;
  }
  renderAll();
  var px=POOL_X, py=POOL_Y, pw=contentRightEdge()-POOL_X, ph=poolHeight();
  var bandTop=py+POOL_HEADER, bands=[], y=bandTop;
  getLanes().forEach(function(l){ bands.push({y1:y,y2:y+l.height}); y+=l.height; });
  var els=Array.prototype.slice.call(document.querySelectorAll('text[data-nl="'+n.uid+'"]'));
  var rects=els.map(function(t){ var b=t.getBBox();
    return {x1:b.x,x2:b.x+b.width,y1:b.y,y2:b.y+b.height,cls:t.getAttribute('class'),
            anchor:t.getAttribute('text-anchor')}; });
  return {ok:true, uid:n.uid, shape:{x1:n.x,x2:n.x+d.w,y1:n.y,y2:n.y+d.h},
          furniture:{px:px,py:py,pw:pw,ph:ph,bandTop:bandTop,laneHeader:LANE_HEADER,bands:bands},
          rects:rects};
}catch(e){ return {ok:false,error:String(e&&e.stack||e)}; } })()`;

// Element-level capture of the left-edge scenario — the operator's reported case.
// DOM rects prove geometry; only a rendered image proves it LOOKS right, so the
// same harness that measures also photographs, against the same build.
async function shoot(editorPath, outFile) {
  const udd = mkdtempSync(join(tmpdir(), 't601-shot-'));
  const proc = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let client;
  try {
    let port;
    for (let i = 0; i < 400; i++) {
      const f = join(udd, 'DevToolsActivePort');
      if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n')[0]; if (t.trim()) { port = +t.trim(); break; } }
      await sleep(100);
    }
    if (!port) throw new Error('Chromium DevTools port timeout');
    const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    client = cdpClient(await pageWsUrl(port));
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1400, height: 900, deviceScaleFactor: 3, mobile: false });
    await cmd('Page.navigate', { url: 'file://' + editorPath });
    const t0 = Date.now();
    for (;;) {
      if (await evalJson(cmd, `(typeof renderAll==='function' && typeof state==='object' && !!state && !!state.nodes)`)) break;
      if (Date.now() - t0 > 40000) throw new Error('editor load timeout');
      await sleep(150);
    }
    await evalJson(cmd, probeExpr(LONG, 'left'));
    // Clip in CSS pixels over the pool's top-left corner: lane header strip,
    // the first band's divider, and the node whose label used to cross both.
    // Clip from REAL client rects — the union of the lane header strip and the
    // node's own label lines. viewBox arithmetic got this wrong once (it captured
    // the palette), and a screenshot of the wrong region is worse than none: it
    // looks like evidence.
    const box = await evalJson(cmd, `(function(){
      var parts=[];
      var lh=document.querySelector('g.lane-header rect');
      if(lh) parts.push(lh.getBoundingClientRect());
      var isBelow=function(n){ return n.type==='startEvent'||n.type==='endEvent'||
        /Gateway$/.test(n.type)||/^linkEvent/.test(n.type)||/^event/.test(n.type); };
      var n=state.nodes.filter(isBelow)[0];
      document.querySelectorAll('text[data-nl="'+n.uid+'"]').forEach(function(t){ parts.push(t.getBoundingClientRect()); });
      var g=document.querySelector('[data-node-id="'+n.uid+'"]') || document.querySelector('g.node');
      if(g) parts.push(g.getBoundingClientRect());
      if(!parts.length) return null;
      var x1=Math.min.apply(null,parts.map(function(r){return r.left;}));
      var x2=Math.max.apply(null,parts.map(function(r){return r.right;}));
      var y1=Math.min.apply(null,parts.map(function(r){return r.top;}));
      var y2=Math.max.apply(null,parts.map(function(r){return r.bottom;}));
      return {x:x1-14,y:y1-14,w:(x2-x1)+28,h:(y2-y1)+28};
    })()`);
    if (!box) throw new Error('could not compute a clip region');
    const shot = await cmd('Page.captureScreenshot', {
      format: 'png', captureBeyondViewport: true,
      clip: { x: Math.max(0, box.x), y: Math.max(0, box.y), width: box.w, height: box.h, scale: 1.4 } });
    writeFileSync(outFile, Buffer.from(shot.data, 'base64'));
    console.log(`wrote ${outFile}`);
  } finally {
    try { client && client.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}

async function probe(editorPath) {
  const udd = mkdtempSync(join(tmpdir(), 't601-chrome-'));
  const proc = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let client;
  try {
    let port;
    for (let i = 0; i < 400; i++) {
      const f = join(udd, 'DevToolsActivePort');
      if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n')[0]; if (t.trim()) { port = +t.trim(); break; } }
      await sleep(100);
    }
    if (!port) throw new Error('Chromium DevTools port timeout');
    const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    client = cdpClient(await pageWsUrl(port));
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: 'file://' + editorPath });
    const t0 = Date.now();
    for (;;) {
      if (await evalJson(cmd, `(typeof renderAll==='function' && typeof state==='object' && !!state && !!state.nodes)`)) break;
      if (Date.now() - t0 > 40000) throw new Error('editor load timeout');
      await sleep(150);
    }
    return {
      left: await evalJson(cmd, probeExpr(LONG, 'left')),
      poolbottom: await evalJson(cmd, probeExpr(LONG, 'poolbottom')),
      bottom: await evalJson(cmd, probeExpr(LONG, 'bottom')),
      clean: await evalJson(cmd, probeExpr(SHORT, 'clean')),
    };
  } finally {
    try { client && client.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}

const EPS = 1;   // the scorer pads rects by 1px; do not fail on the pad itself
const bandsTouched = (r, bands) => bands.filter(b => r.y2 > b.y1 + EPS && r.y1 < b.y2 - EPS).length;

function legs(res) {
  for (const [k, v] of Object.entries(res || {}))
    if (!v || !v.ok) return [{ id: 'probe:' + k, ok: false, detail: (v && v.error) || 'probe returned nothing' }];
  const L = [], left = res.left, bottom = res.bottom, clean = res.clean;
  const f = left.furniture;
  const headerEdge = f.px + f.laneHeader;

  const minX1 = Math.min(...left.rects.map(r => r.x1));
  L.push({ id: 'L1', ok: minX1 >= headerEdge - EPS,
           detail: `left-edge node: leftmost label x=${minX1.toFixed(1)} vs lane-header edge ${headerEdge}` });

  const worst = Math.max(...bottom.rects.map(r => bandsTouched(r, bottom.furniture.bands)));
  L.push({ id: 'L2', ok: worst <= 1,
           detail: `lane-bottom node: worst label spans ${worst} lane band(s) of ${bottom.furniture.bands.length}` });

  const rf = res.poolbottom.furniture;
  const out = res.poolbottom.rects.filter(r =>
    r.x1 < rf.px - EPS || r.x2 > rf.px + rf.pw + EPS || r.y1 < rf.bandTop - EPS || r.y2 > rf.py + rf.ph + EPS);
  L.push({ id: 'L3', ok: out.length === 0,
           detail: `pool-floor node: ${out.length} label rect(s) outside pool [${rf.px},${(rf.px + rf.pw).toFixed(0)}]x[${rf.bandTop},${(rf.py + rf.ph).toFixed(0)}]` });

  const nameRects = clean.rects.filter(r => r.cls === 'node-label');
  const shapeMid = (clean.shape.x1 + clean.shape.x2) / 2;
  const centred = nameRects.length > 0 && nameRects.every(r => Math.abs((r.x1 + r.x2) / 2 - shapeMid) <= 6);
  const below = nameRects.every(r => r.y1 >= clean.shape.y2 - EPS);
  L.push({ id: 'L4', ok: centred && below,
           detail: `uncontested label centred on shape: ${centred}, below shape: ${below} (${nameRects.length} name line(s))` });

  L.push({ id: 'L5', ok: f.bands.length >= 2 && f.pw > 0,
           detail: `furniture: ${f.bands.length} lane band(s), pool width ${f.pw.toFixed(0)}` });
  return L;
}

async function main() {
  const selfTest = process.argv.includes('--self-test');
  const report = ls => { for (const l of ls) console.log(`  ${l.ok ? 'PASS' : 'FAIL'}  ${l.id}  ${l.detail}`); };
  console.log('T-601 pool and lane boundary awareness — geometry legs');
  if (process.argv.includes('--shots')) {
    const dir = process.argv[process.argv.indexOf('--shots') + 1];
    const src = readFileSync(EDITOR, 'utf8');
    const A = 'sc += segCrossings(r) + nodeOverlaps(r, self) + poolPenalty(r);';
    const B = `      if (band) {
        const lo = band.y1 + ASC, hi = band.y2 - DESC - (total - 1) * LH;
        if (hi >= lo) b0 = Math.max(lo, Math.min(b0, hi));   // slide into the lane, never squash
      }\n`;
    const C = `    if (scLeft < scDefault && scLeft < scRight) continue;             // already placed left
    if (scRight < scDefault && scRight <= scLeft) { RIGHT(); continue; }\n`;
    const p = join(mkdtempSync(join(tmpdir(), 't601-shotpoison-')), 'pre-t601.html');
    writeFileSync(p, src.replace(A, 'sc += segCrossings(r) + nodeOverlaps(r, self);').replace(B, '').replace(C, ''));
    await shoot(p, join(dir, 't601-before.png'));
    await shoot(EDITOR, join(dir, 't601-after.png'));
    process.exit(0);
  }
  if (process.argv.includes('--dump')) {
    const r = await probe(EDITOR);
    console.log(JSON.stringify(r));
    process.exit(0);
  }
  const live = legs(await probe(EDITOR));
  report(live);
  const failed = live.filter(l => !l.ok);
  if (!selfTest) {
    console.log(failed.length ? `FAIL — ${failed.length} leg(s)` : `PASS — ${live.length} leg(s)`);
    process.exit(failed.length ? 1 : 0);
  }
  const src = readFileSync(EDITOR, 'utf8');
  // FAITHFUL to pre-T-601: the sum had no pool term at all. Disabling one clause
  // inside poolPenalty would leave the other two live and the legs would still
  // pass on "broken" code — T-603 shipped exactly that mistake and the self-test
  // caught it only because the poison was made faithful.
  // The fix has THREE parts and all three must go, or the arm proves nothing
  // about the parts it leaves behind:
  //   A  the pool term in the score          B  the in-band clamp in place()
  //   C  the keep-the-best-candidate fallback
  const A = 'sc += segCrossings(r) + nodeOverlaps(r, self) + poolPenalty(r);';
  const B = `      if (band) {
        const lo = band.y1 + ASC, hi = band.y2 - DESC - (total - 1) * LH;
        if (hi >= lo) b0 = Math.max(lo, Math.min(b0, hi));   // slide into the lane, never squash
      }\n`;
  const C = `    if (scLeft < scDefault && scLeft < scRight) continue;             // already placed left
    if (scRight < scDefault && scRight <= scLeft) { RIGHT(); continue; }\n`;
  for (const [nm, t] of [['A', A], ['B', B], ['C', C]])
    if (!src.includes(t)) { console.log(`SELF-TEST INTEGRITY FAIL — poison target ${nm} missing`); process.exit(2); }
  const f = join(mkdtempSync(join(tmpdir(), 't601-poison-')), 'poisoned-editor.html');
  writeFileSync(f, src.replace(A, 'sc += segCrossings(r) + nodeOverlaps(r, self);')
                      .replace(B, '').replace(C, ''));
  console.log('\npoison arm — pre-T-601 scorer restored (no pool term); L1-L3 must FAIL');
  const pl = legs(await probe(f));
  report(pl);
  const mustFail = ['L1', 'L2', 'L3'];
  const survivors = pl.filter(l => mustFail.includes(l.id) && l.ok).map(l => l.id);
  const control = pl.filter(l => ['L4', 'L5'].includes(l.id) && !l.ok).map(l => l.id);
  if (failed.length) { console.log(`\nFAIL — ${failed.length} live leg(s)`); process.exit(1); }
  if (survivors.length) { console.log(`\nSELF-TEST FAIL — ${survivors.join(',')} passed without the pool term; they assert nothing`); process.exit(2); }
  if (control.length) { console.log(`\nSELF-TEST FAIL — control leg(s) ${control.join(',')} broke under poison; not independent`); process.exit(2); }
  console.log(`\nPASS — ${live.length} live leg(s); ${mustFail.length} proven failable`);
}
main().catch(e => { console.error('DRIVER ERROR: ' + (e && e.stack || e)); process.exit(2); });
