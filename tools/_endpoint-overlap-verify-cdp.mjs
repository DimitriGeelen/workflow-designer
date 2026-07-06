#!/usr/bin/env node
// _endpoint-overlap-verify-cdp.mjs — verify T-136: at a convergence point (two edges
// sharing a connection point) a click on the selected edge's endpoint grab-halo falls
// through to select the sibling line under the pointer, instead of being swallowed.
//
// Serves the editor from a TEMP docroot, drives it in ISOLATED headless chromium (own
// --user-data-dir; G-006). Fit-to-view viewBox keeps the whole map on-screen so real
// screen-coordinate mouse events (CDP Input.dispatchMouseEvent) land correctly.
//
// Steps:
//   1. Load arc-lifecycle, discover a pair of edges A/B sharing a SOURCE anchor point.
//   2. Select A -> its endpoint halos render at the shared point.
//   3. Unit: edgeHitTestAt(sharedClientPt, A) returns the sibling B (not A).
//   4. Integration: real mousedown+mouseup (no move) on A's src halo -> selection == B.
//   5. Regression: a real DRAG of A's endpoint (move > threshold) does NOT fall through
//      to sibling-select (it stays an endpoint drag; selection is not hijacked to B).
// Screenshot of the convergence for the READ step. Exit 0 = pass.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

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
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&typeof edgeHitTestAt==='function')`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready (needs edgeHitTestAt — is the T-136 build synced?)'); await sleep(150); } }
async function mouse(cmd, type, x, y, extra = {}) { await cmd('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1, buttons: type === 'mouseReleased' ? 0 : 1, ...extra }); }

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 'eo-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'eo-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'eo-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down');
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1200, height: 820, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(500);

    // Helpers injected in-page: map an SVG-user point to client (viewport CSS) px,
    // and find the closest point on a polyline to a point.
    await ev(cmd, `window.__svgToClient = function(x,y){ var m = svg.getScreenCTM(); return { x: m.a*x + m.c*y + m.e, y: m.b*x + m.d*y + m.f }; };`);

    // 1. Reproduce the operator's exact condition — "two or more arrow ends on the same
    //    connection point." Pick a fork (a source node with >=2 outgoing edges) and pin both
    //    outgoing edges to the SAME source port so their source endpoints coincide. Now the
    //    selected edge A's endpoint halo (r11) sits directly on sibling B's line, which
    //    emanates from the same point. Q = closest point on B's rendered polyline to A's
    //    anchor P (dist ~0). Render so _renderedPolyline exists.
    const pair = await ev(cmd, `(function(){
      var bySrc={}; state.edges.forEach(function(e){ (bySrc[e.source]=bySrc[e.source]||[]).push(e); });
      var forkSrc=null; for (var k in bySrc){ if (bySrc[k].length>=2){ forkSrc=k; break; } }
      if (!forkSrc) return null;
      var es=bySrc[forkSrc], A=es[0], B=es[1];
      A.sourcePort='E'; B.sourcePort='E'; A.waypoints=[]; B.waypoints=[];
      renderAll();
      function firstRef(e){ return (e.waypoints&&e.waypoints[0]) ? e.waypoints[0] : centerOf(findNode(e.target)); }
      var P = anchorPoint(findNode(A.source), A.sourcePort, firstRef(A));
      var poly = B._renderedPolyline || [];
      function closestOnPoly(poly, p){
        var best={d:Infinity,q:{x:p.x,y:p.y}};
        for (var i=0;i<poly.length-1;i++){
          var a=poly[i], b=poly[i+1], dx=b.x-a.x, dy=b.y-a.y, L=dx*dx+dy*dy;
          var t = L ? ((p.x-a.x)*dx + (p.y-a.y)*dy)/L : 0; t=Math.max(0,Math.min(1,t));
          var qx=a.x+t*dx, qy=a.y+t*dy, d=Math.hypot(qx-p.x, qy-p.y);
          if (d<best.d){ best={d:d, q:{x:qx,y:qy}}; }
        }
        return best;
      }
      var c = closestOnPoly(poly, P);
      // Nudge Q a few units along B away from P so we click on B's line just past the shared
      // endpoint (still well inside A's r11 halo) — the spot the operator can't select.
      var q = c.q;
      if (poly.length>=2){ var d0=poly[0], d1=poly[1], len=Math.hypot(d1.x-d0.x,d1.y-d0.y)||1; q={ x: P.x + (d1.x-d0.x)/len*4, y: P.y + (d1.y-d0.y)/len*4 }; }
      return { A:A.id, role:'src', B:B.id, P:{x:P.x,y:P.y}, Q:q, dist:c.d, forkSrc:forkSrc };
    })()`);
    push('found-halo-over-sibling', pair && pair.A && pair.B, pair);
    if (!pair) throw new Error('no fork (source with >=2 outgoing) in ' + MAP + ' — cannot exercise the convergence bug');
    const A = pair.A, B = pair.B, ROLE = pair.role;
    const dataRole = ROLE === 'src' ? 'src' : 'tgt';

    // 2. Select A -> its endpoint halos render (r11) at the anchors.
    await ev(cmd, `(function(){ selection = { kind:'edge', id:${JSON.stringify(A)} }; multiSelect = new Set(); renderAll(); renderProperties(); })()`);
    await sleep(150);
    const selA = await ev(cmd, `selection && selection.kind==='edge' ? selection.id : null`);
    push('edge-A-selected', selA === A, selA);

    // client coords of Q (point on B's line, under A's halo)
    const Qc = await ev(cmd, `(function(){ var c = window.__svgToClient(${pair.Q.x}, ${pair.Q.y}); return { x:c.x, y:c.y }; })()`);
    push('click-point-onscreen', Qc && Qc.x > 0 && Qc.x < 1200 && Qc.y > 0 && Qc.y < 820, Qc);
    if (!(Qc.x > 0 && Qc.x < 1200)) throw new Error('convergence point off-screen');
    const CX = Qc.x, CY = Qc.y;

    // Force the bug condition deterministically: raise A's <g> to the top of gEdges so its
    // endpoint halo is the topmost element at Q (paint order otherwise decides whether the
    // halo or B's line wins — the operator saw this "often", i.e. stacking-dependent). With
    // the halo on top, a naive click is swallowed; the fix must fall through to B.
    await ev(cmd, `(function(){ var g=document.querySelector('.edge.selected'); if(g && g.parentNode) g.parentNode.appendChild(g); })()`);
    await sleep(50);
    const topmost = await ev(cmd, `(function(){ var els=document.elementsFromPoint(${CX},${CY}); for(var i=0;i<els.length;i++){ if(els[i].classList){ if(els[i].classList.contains('edge-handle-endpoint-hit')) return 'halo'; if(els[i].classList.contains('edge-hit')) return 'edge-hit'; } } return 'other'; })()`);
    push('halo-is-topmost-at-Q', topmost === 'halo', { topmost, dataRole, dist: pair.dist });

    // 3. Unit: hit-test at Q prefers the sibling B (not A), skipping the halo.
    const hitId = await ev(cmd, `edgeHitTestAt(${CX}, ${CY}, ${JSON.stringify(A)})`);
    push('hittest-prefers-sibling', hitId === B, { hitId, expected: B, notA: A });

    // 4. Integration: real click (down+up, no move) at Q -> selection is no longer stuck on A.
    await mouse(cmd, 'mousePressed', CX, CY);
    await sleep(30);
    await mouse(cmd, 'mouseReleased', CX, CY);
    await sleep(150);
    const selAfterClick = await ev(cmd, `selection && selection.kind==='edge' ? selection.id : null`);
    push('click-selects-sibling', selAfterClick === B, { before: A, after: selAfterClick, expected: B });

    // 5. Regression: a real DRAG of A's endpoint is NOT hijacked into sibling-select.
    // Re-select A, raise to top, press on its halo, move well past threshold into open space, release.
    await ev(cmd, `(function(){ selection = { kind:'edge', id:${JSON.stringify(A)} }; multiSelect = new Set(); renderAll(); renderProperties(); var g=document.querySelector('.edge.selected'); if(g&&g.parentNode) g.parentNode.appendChild(g); })()`);
    await sleep(120);
    const halo2 = await ev(cmd, `(function(){ var h=document.querySelector('.edge.selected .edge-handle-endpoint-hit[data-role="${dataRole}"]'); if(!h) return null; var r=h.getBoundingClientRect(); return { cx:r.left+r.width/2, cy:r.top+r.height/2 }; })()`);
    await mouse(cmd, 'mousePressed', halo2.cx, halo2.cy);
    await mouse(cmd, 'mouseMoved', halo2.cx + 40, halo2.cy + 40, { buttons: 1 });
    await sleep(30);
    await mouse(cmd, 'mouseMoved', halo2.cx + 70, halo2.cy + 60, { buttons: 1 });
    await sleep(30);
    await mouse(cmd, 'mouseReleased', halo2.cx + 70, halo2.cy + 60);
    await sleep(150);
    const selAfterDrag = await ev(cmd, `selection && selection.kind==='edge' ? selection.id : null`);
    // A real drag (released in open space, no snap) must not select the sibling B.
    push('drag-not-hijacked-to-sibling', selAfterDrag !== B, { after: selAfterDrag, B });

    // screenshot the convergence for the READ step
    await ev(cmd, `(function(){ selection = { kind:'edge', id:${JSON.stringify(A)} }; multiSelect = new Set(); renderEdges(); })()`);
    await sleep(100);
    const shot = await cmd('Page.captureScreenshot', { format: 'png' });
    const shotPath = join(tmpdir(), 'endpoint-overlap-full.png');
    writeFileSync(shotPath, Buffer.from(shot.data, 'base64')); verdict.screenshotFull = shotPath;

    verdict.pair = { A, B };
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
