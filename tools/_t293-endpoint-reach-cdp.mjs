// _t293-endpoint-reach-cdp.mjs — standing endpoint-reconnect reachability leg
// (T-293, G-003 class: pointer-interaction paths need trusted-input coverage).
//
// Drives the REAL editor (src/aef-workflow-designer.html) in an isolated
// headless chromium with real Input.dispatchMouseEvent input — no synthetic
// dispatchEvent, so hit-testing and paint order are exercised exactly as a
// user's mouse would.
//
// Field symptom (T-293): endpoint reconnect drag ("the hand") often failed to
// start, worst at frw_11_harvest — the selected edge's grab halos rendered in
// #g-edges, below #g-nodes, while T-168 anchors endpoints ON the node border,
// so the node body (or an active-port indicator dot) shadowed the handle and
// mousedown started a node drag (or nothing) instead.
//
// Legs:
//   1. layer-order — #g-badges < #g-edges < #g-nodes < #g-badges-top <
//      #g-handles < #g-preview under svg#canvas (T-286 + T-293 combined).
//   2. reach — for BOTH edges of frw_11_harvest (e_16, e_22), both endpoint
//      handle centres hit the handle itself (elementFromPoint) AND a real
//      mouse press+move starts edgeDrag kind 'endpoint' with no node drag.
//   3. reconnect-e2e — a full Input-driven drag of e_16's target endpoint onto
//      n_join actually rewires state (edge.target changes).
//
// TEETH: against the pre-T-293 editor, legs 2 and 3 fail with the exact field
// symptoms (3/4 centres resolve to node-shape, 1/4 to a port dot; the e2e drag
// leaves edge.target unchanged).
import { spawn } from 'node:child_process';
import { readFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = process.env.T293_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const MAP = join(ROOT, 'examples', 'aef-processes', 'rendered', 'harvest-pipeline.bpmn');

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
  throw new Error('Chromium did not report a DevTools port');
}
function cdpClient(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0; const pending = new Map();
  ws.addEventListener('message', ev => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  });
  const ready = new Promise((res, rej) => {
    ws.addEventListener('open', res);
    ws.addEventListener('error', () => rej(new Error('CDP websocket error')));
  });
  const cmd = (method, params = {}) => new Promise((res, rej) => {
    const mid = ++id;
    pending.set(mid, m => m.error ? rej(new Error(method + ': ' + JSON.stringify(m.error))) : res(m.result));
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  return { ready, cmd, close: () => ws.close() };
}
async function evalJson(cmd, expression) {
  const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error('page eval threw: ' + JSON.stringify(r.exceptionDetails).slice(0, 500));
  return r.result.value;
}
const mouse = (cmd, type, x, y) =>
  cmd('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });

let failures = 0;
function leg(name, ok, detail) {
  console.log(`  [${ok ? 'PASS' : 'FAIL'}] ${name}${detail ? ' — ' + detail : ''}`);
  if (!ok) failures++;
}

async function main() {
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't293-leg-'));
  const proc = spawn(chrome, [
    '--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, '--window-size=1600,1000', 'about:blank',
  ], { stdio: ['ignore', 'ignore', 'pipe'] });
  try {
    const { port } = await waitForPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(port) };
    const client = cdpClient(page.webSocketDebuggerUrl);
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1600, height: 1000, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: 'file://' + EDITOR });
    const t0 = Date.now();
    for (;;) {
      const ok = await evalJson(cmd, `(typeof adoptImportedXml==='function' && typeof state==='object' && !!state)`);
      if (ok) break;
      if (Date.now() - t0 > 20000) throw new Error('editor load timeout');
      await sleep(150);
    }
    await evalJson(cmd, `(window.alert=window.confirm=window.prompt=function(){return true;},true)`);
    await evalJson(cmd, `(adoptImportedXml(${JSON.stringify(readFileSync(MAP, 'utf8'))}), true)`);
    await sleep(300);

    // Leg 1: layer order.
    const order = await evalJson(cmd, `(function(){
      const ids = ['g-badges','g-edges','g-nodes','g-badges-top','g-handles','g-preview'];
      const els = ids.map(i => document.getElementById(i));
      if (els.some(e => !e)) return { ok:false, err:'missing layer group' };
      for (let i=0;i<els.length-1;i++) {
        if (!(els[i].compareDocumentPosition(els[i+1]) & Node.DOCUMENT_POSITION_FOLLOWING))
          return { ok:false, err: ids[i]+' not before '+ids[i+1] };
      }
      return { ok: els.every(e => e.parentNode === document.getElementById('canvas')) };
    })()`);
    leg('layer-order (T-286+T-293 canvas layers)', order.ok, order.err || '');

    // Leg 2: reach — both handles of both frw_11_harvest edges.
    for (const uid of ['e_16', 'e_22']) {
      const probe = await evalJson(cmd, `(function(){
        selection = { kind:'edge', id:${JSON.stringify(uid)} }; multiSelect.clear();
        renderEdges(); renderNodes();
        const out = [];
        for (const h of gHandles.querySelectorAll('.edge-handle-endpoint-hit')) {
          const r = h.getBoundingClientRect();
          const cx = r.x + r.width/2, cy = r.y + r.height/2;
          out.push({ role: h.getAttribute('data-role'), cx, cy,
                     isHandle: document.elementFromPoint(cx, cy) === h });
        }
        return out;
      })()`);
      leg(`${uid} handle count`, probe.length === 2, `got ${probe.length}`);
      for (const h of probe) {
        leg(`${uid}:${h.role} centre hit-tests to the handle`, !!h.isHandle);
        await mouse(cmd, 'mousePressed', h.cx, h.cy);
        await sleep(50);
        await mouse(cmd, 'mouseMoved', h.cx + 40, h.cy + 25);
        await sleep(50);
        const st = await evalJson(cmd, `({
          edgeDrag: (typeof edgeDrag!=='undefined' && edgeDrag) ? edgeDrag.kind : null,
          nodeDrag: (typeof drag!=='undefined' && !!drag),
        })`);
        await mouse(cmd, 'mouseReleased', h.cx + 40, h.cy + 25);
        await sleep(50);
        await evalJson(cmd, `(typeof undo==='function' ? (undo(),true) : true)`);
        leg(`${uid}:${h.role} press+move starts endpoint drag`,
            st.edgeDrag === 'endpoint' && !st.nodeDrag,
            `edgeDrag=${st.edgeDrag} nodeDrag=${st.nodeDrag}`);
      }
    }

    // Leg 3: full reconnect e2e — e_16 target from n_h_claude onto n_join.
    const e2e = await evalJson(cmd, `(function(){
      selection = { kind:'edge', id:'e_16' }; multiSelect.clear();
      renderEdges(); renderNodes();
      const h = gHandles.querySelector('.edge-handle-endpoint-hit[data-role="tgt"]');
      const r = h.getBoundingClientRect();
      // Aim at the node's SHAPE, not its <g>. The group's bounding box is the union of
      // the shape and its text label, so the group centre is only on the node while the
      // label happens to sit under it. T-601 legitimately repositioned labels and the
      // centre drifted 22.4px past n_join's right edge — 0.4px outside SNAP_RADIUS (22),
      // so the drop landed in open space, nothing snapped, and this leg went red while
      // the editor was behaving correctly. Verified: pressing the same handle and
      // releasing on the shape centre rewires n_h_claude -> n_join at the same commit.
      // PL-098: a pass-before/fail-after predicate aggregates EVERY cause of the change;
      // this one silently aggregated label geometry into a reconnect assertion.
      const dg = gNodes.querySelector('g[data-id="n_join"]');
      const d = (dg.querySelector('rect,ellipse,circle,polygon,path') || dg).getBoundingClientRect();
      return { hx: r.x+r.width/2, hy: r.y+r.height/2, dx: d.x+d.width/2, dy: d.y+d.height/2,
               before: state.edges.find(e=>e.uid==='e_16').target };
    })()`);
    await mouse(cmd, 'mousePressed', e2e.hx, e2e.hy);
    await sleep(50);
    for (let i = 1; i <= 5; i++) {
      await mouse(cmd, 'mouseMoved', e2e.hx + (e2e.dx - e2e.hx) * i / 5, e2e.hy + (e2e.dy - e2e.hy) * i / 5);
      await sleep(40);
    }
    await mouse(cmd, 'mouseReleased', e2e.dx, e2e.dy);
    await sleep(150);
    const after = await evalJson(cmd, `state.edges.find(e=>e.uid==='e_16').target`);
    await evalJson(cmd, `(typeof undo==='function' ? (undo(),true) : true)`);
    leg('reconnect e2e rewires edge.target', e2e.before === 'n_h_claude' && after === 'n_join',
        `before=${e2e.before} after=${after}`);

    client.close();
  } finally {
    proc.kill('SIGKILL');
  }
  console.log(failures === 0 ? 'endpoint-reach: ALL LEGS PASS' : `endpoint-reach: ${failures} leg(s) FAILED`);
  process.exit(failures === 0 ? 0 : 1);
}
main().catch(e => { console.error('FATAL', e.message); process.exit(1); });
