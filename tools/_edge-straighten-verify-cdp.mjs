#!/usr/bin/env node
// _edge-straighten-verify-cdp.mjs — verify T-137: the "Straighten" edge action.
// Serves the editor from a TEMP docroot, drives it in ISOLATED headless chromium (own
// --user-data-dir; G-006). Loads task-gate, whose edge e_09 (gateway g_ready → n_allow)
// carries a persisted aef:loopDetour and renders as an up-and-over loop even though a direct
// route is clean. Proves:
//   1. e_09 starts as a loop (detourY set, >4 vertices).
//   2. "Reset routing" alone does NOT straighten it (backward-flow re-loops) — the reason a
//      dedicated Straighten is needed.
//   3. Clicking the "Straighten" button collapses e_09 to a direct route (fewer vertices,
//      detourY gone, forceStraight set) and does NOT increase node crossings.
//   4. It persists: serialize→parse round-trip keeps the edge straight (no aef:loopDetour,
//      forceStraight retained).
//   5. Guard: an edge whose direct route WOULD cross a node is NOT forced straight.
//   6. One undo() restores the prior loop routing.
// Screenshots the straightened map for the READ step. Exit 0 = pass.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const MAP = 'task-gate';
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&typeof renderProperties==='function')`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Find e_09 (gateway→allow) robustly; select it; return a compact routing snapshot.
const SNAP = `(function(){
  var e = state.edges.find(function(x){return x.id==='e_09'||x.uid==='e_09';});
  if(!e){ var g=state.nodes.find(function(n){return /Started-work/.test(n.name||'');}); var a=state.nodes.find(function(n){return /Allow/.test(n.name||'');}); if(g&&a) e=state.edges.find(function(x){return x.source===g.id&&x.target===a.id;}); }
  if(!e) return {error:'no e_09'};
  window.__eid = e.id;
  var pl=(e._renderedPolyline||[]);
  var src=findNode(e.source), tgt=findNode(e.target);
  return { id:e.id, detourY:e.detourY, forceStraight:!!e.forceStraight, vtx:pl.length,
           loopY:e._loopDetourY, sameY: src&&tgt ? Math.abs(centerOf(src).y-centerOf(tgt).y)<1 : null };
})()`;
// Select the edge and render the properties panel, then click a routing button by label.
const clickBtn = label => `(function(){
  var e = state.edges.find(function(x){return x.id===window.__eid;});
  selection = { kind:'edge', id: e.id }; multiSelect=new Set(); renderProperties();
  var b=[].slice.call(document.querySelectorAll('#properties button')).filter(function(x){return x.textContent.trim()===${JSON.stringify(label)};})[0];
  if(!b) return { clicked:false, buttons:[].slice.call(document.querySelectorAll('#properties button')).map(function(x){return x.textContent.trim();}) };
  b.click(); return { clicked:true };
})()`;

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 'es-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'es-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'es-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down');
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1400, height: 900, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(500);

    const before = await ev(cmd, SNAP);
    push('e09-starts-as-loop', before && typeof before.detourY === 'number' && before.vtx > 4 && before.sameY === true, before);

    // A helper: node-crossing count for the edge's current rendered polyline.
    const crossings = `(function(){ var e=state.edges.find(function(x){return x.id===window.__eid;}); var src=findNode(e.source),tgt=findNode(e.target); return countNodeCrossings(e._renderedPolyline||[], src, tgt); })()`;
    const beforeCross = await ev(cmd, crossings);

    // Step 2: Reset routing alone does NOT straighten (control) — clear then observe re-loop.
    const rr = await ev(cmd, clickBtn('Reset routing'));
    const afterReset = await ev(cmd, SNAP);
    push('reset-alone-reloops', rr.clicked && afterReset.vtx > 4, { clicked: rr.clicked, vtx: afterReset.vtx });
    // reload map to restore the pristine detourY for the real test
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(400); await ev(cmd, SNAP);

    // Step 3: Straighten collapses the loop, no extra crossings.
    const sc = await ev(cmd, clickBtn('Straighten'));
    const afterStraight = await ev(cmd, SNAP);
    const afterCross = await ev(cmd, crossings);
    push('straighten-button-present', sc.clicked, sc);
    push('straighten-collapses-loop',
      afterStraight.forceStraight === true && typeof afterStraight.detourY !== 'number' && afterStraight.vtx < before.vtx,
      { before: before.vtx, after: afterStraight.vtx, detourY: afterStraight.detourY, forceStraight: afterStraight.forceStraight });
    push('straighten-adds-no-crossings', afterCross <= beforeCross, { before: beforeCross, after: afterCross });

    // Step 4: persistence — serialize then parse and confirm it stays straight.
    const roundtrip = await ev(cmd, `(function(){
      var xml = buildBpmnXml(state);
      var hasLoop = /aef:loopDetour[^>]*id?|<aef:loopDetour/.test(xml) && /flow_9/.test(xml);
      var loaded = parseBpmnXml(xml);
      var e = loaded.edges.find(function(x){return x.id===window.__eid;});
      // is aef:forceStraight present in the serialized XML for this edge?
      var hasForce = /<aef:forceStraight value="true"\\/>/.test(xml);
      return { forceStraightAfterParse: !!(e&&e.forceStraight), detourYAfterParse: e?e.detourY:undefined, xmlHasForceStraight: hasForce };
    })()`);
    push('persists-through-roundtrip',
      roundtrip.forceStraightAfterParse === true && typeof roundtrip.detourYAfterParse !== 'number' && roundtrip.xmlHasForceStraight,
      roundtrip);

    // Step 6: one undo restores the loop.
    const undone = await ev(cmd, `(function(){ var ok=undo(); var s=${SNAP}; return { ok:ok, vtx:s.vtx, detourY:s.detourY, forceStraight:s.forceStraight }; })()`);
    push('undo-restores-loop', undone.ok && undone.vtx > 4 && typeof undone.detourY === 'number', undone);

    // Step 5: guard — force a node ONTO e_09's straight path, then Straighten must be REFUSED
    // (the edge stays a loop, never a straight line through the obstacle). Reload first for a
    // pristine e_09.
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(400); await ev(cmd, SNAP);
    const guard = await ev(cmd, `(function(){
      var e = state.edges.find(function(x){return x.id===window.__eid;});
      var src=findNode(e.source), tgt=findNode(e.target);
      var y = centerOf(src).y;               // e_09 endpoints share this y (~400)
      var xL = Math.min(centerOf(src).x, centerOf(tgt).x), xR = Math.max(centerOf(src).x, centerOf(tgt).x);
      // relocate an unrelated node to straddle the midpoint of the straight line
      var obstacle = state.nodes.find(function(n){ return n.id!==e.source && n.id!==e.target; });
      var d = NODE_DEFAULTS[obstacle.type];
      obstacle.x = (xL+xR)/2 - d.w/2; obstacle.y = y - d.h/2;   // centred on the line
      renderAll();
      var directCrosses = polylineCrossesNodes([centerOf(src), centerOf(tgt)], src, tgt);
      e.forceStraight = true; renderAll();
      var pl = e._renderedPolyline||[];
      var stayedLooped = pl.length > 2;      // refused → still a multi-segment (loop) route
      var noNewCut = countNodeCrossings(pl, src, tgt) === 0;
      return { directCrosses: directCrosses, vtxAfterForce: pl.length, stayedLooped: stayedLooped, noNewCut: noNewCut };
    })()`);
    // A real guard: the obstacle makes the direct line cross, so forceStraight must be ignored.
    push('guard-refuses-when-direct-crosses', guard.directCrosses && guard.stayedLooped && guard.noNewCut, guard);

    // Screenshot the straightened map for the READ step.
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(400); await ev(cmd, SNAP);
    await ev(cmd, clickBtn('Straighten')); await sleep(150);
    const shot = await cmd('Page.captureScreenshot', { format: 'png' });
    writeFileSync(join(tmpdir(), 'edge-straighten-full.png'), Buffer.from(shot.data, 'base64'));
    verdict.screenshotFull = join(tmpdir(), 'edge-straighten-full.png');

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
