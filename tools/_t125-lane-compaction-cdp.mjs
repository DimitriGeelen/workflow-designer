#!/usr/bin/env node
// _t125-lane-compaction-cdp.mjs — T-125 regression guard: vertical lane-compaction
// in cleanLayout (the dominant rule from the T-122 operator correction pairs 1–3).
// Drives the REAL editor (file://) in isolated headless chromium, adopts every
// rendered corpus map, and asserts PASS/FAIL (exit 0 only if all pass):
//   leg1 verticalOnly  — compactLanesFit() alone never changes any node.x (all maps)
//   leg2 convergence   — cleanLayout() loop reaches an exact fixpoint (moved==0)
//                        within 8 iterations on every map (the tidy↔compact
//                        feedback class measured during build: 16/24 2-cycled
//                        under a naive extent fit)
//   leg3 containment   — post-Clean, every node rect sits inside its lane band
//                        (baseline corpus had genuine overflows, e.g.
//                        audit-process framework; the fit must contain)
//   leg4 overlaps      — post-Clean node-pair intersections <= pre-Clean count
//   leg5 messiness     — post-Clean mapMessiness <= pre-Clean (Clean never
//                        makes a map messier)
//   leg6 undo          — one undoTidy() after Clean restores every node y/x and
//                        every lane height exactly (compaction rides the
//                        composite lastTidy)
//   leg7 pairHeights   — the three correction-pair maps come out under generous
//                        regression ceilings (task-lifecycle 480, promotion-
//                        pipeline 460, arc-lifecycle 500 vs 620/620/533 before
//                        the rule; measured 392/376/420 at build)
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve, basename } from 'node:path';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = join(ROOT, 'src', 'aef-workflow-designer.html');
const RENDERED = join(ROOT, 'examples', 'aef-processes', 'rendered');
const PAIR_CEILINGS = { 'task-lifecycle': 480, 'promotion-pipeline': 460, 'arc-lifecycle': 500 };
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

// Per-map probe, evaluated in-page. Returns raw measurements; assertions happen
// node-side so failures print the numbers.
const PROBE = text => `(function(){ try {
  adoptImportedXml(${JSON.stringify(text)});
  var snap = function(){ return state.nodes.map(function(n){ return { id:n.id, x:n.x, y:n.y }; }); };
  var overlaps = function(){
    var c = 0, ns = state.nodes;
    for (var i = 0; i < ns.length; i++) for (var j = i + 1; j < ns.length; j++)
      if (rectsIntersect(nodeRect(ns[i]), nodeRect(ns[j]))) c++;
    return c;
  };
  var contained = function(){
    var out = [];
    for (var k = 0; k < state.nodes.length; k++) {
      var n = state.nodes[k], r = nodeRect(n);
      var top = laneTop(n.lane), lane = findLane(n.lane);
      if (!lane || r.y < top - 0.5 || r.y + r.h > top + lane.height + 0.5)
        out.push(n.id + '@' + n.lane);
    }
    return out;
  };
  // leg1: compaction alone is vertical-only
  var xs0 = snap();
  compactLanesFit();
  var xs1 = snap();
  var xDrift = [];
  for (var i = 0; i < xs0.length; i++)
    if (Math.abs(xs0[i].x - xs1[i].x) > 0.01) xDrift.push(xs0[i].id);
  // fresh adopt for the full-Clean legs
  adoptImportedXml(${JSON.stringify(text)});
  var ovBefore = overlaps();
  var messBefore = (typeof mapMessiness === 'function') ? mapMessiness() : null;
  // leg6 material: pre-Clean state for undo comparison
  var preY = state.nodes.map(function(n){ return { id:n.id, x:n.x, y:n.y }; });
  var preH = state.lanes.map(function(l){ return { id:l.id, height:l.height }; });
  var first = cleanLayout();
  var undoOk = true;
  if (first > 0 || lastTidy) {
    undoTidy();
    for (var a = 0; a < preY.length; a++) {
      var n2 = findNode(preY[a].id);
      if (!n2 || Math.abs(n2.y - preY[a].y) > 0.01 || Math.abs(n2.x - preY[a].x) > 0.01) undoOk = false;
    }
    for (var b = 0; b < preH.length; b++) {
      var l2 = findLane(preH[b].id);
      if (!l2 || Math.abs(l2.height - preH[b].height) > 0.01) undoOk = false;
    }
    cleanLayout(); // redo for the remaining legs
  }
  // leg2: fixpoint within 8 iterations
  var last = 1, iters = 1;
  while (last > 0 && iters < 8) { last = cleanLayout(); iters++; }
  var ovAfter = overlaps();
  var messAfter = (typeof mapMessiness === 'function') ? mapMessiness() : null;
  var escapees = contained();
  var totalH = state.lanes.reduce(function(s, l){ return s + l.height; }, 0);
  return { ok:true, xDrift:xDrift, lastMoved:last, iters:iters, undoOk:undoOk,
           ovBefore:ovBefore, ovAfter:ovAfter, messBefore:messBefore, messAfter:messAfter,
           escapees:escapees, totalH:totalH };
} catch (e) { return { ok:false, error:String(e && e.stack || e) }; } })()`;

async function main() {
  const maps = readdirSync(RENDERED).filter(f => f.endsWith('.bpmn')).sort();
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't125-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const fails = [];
  const perMap = {};
  try {
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: 'file://' + EDITOR });
    const t0 = Date.now();
    for (;;) {
      const ok = await ev(cmd, `(typeof cleanLayout==='function'&&typeof compactLanesFit==='function'&&typeof adoptImportedXml==='function'&&!!state)`).catch(() => false);
      if (ok) break;
      if (Date.now() - t0 > 20000) throw new Error('editor not ready (compactLanesFit missing?)');
      await sleep(150);
    }
    await ev(cmd, `(window.alert=window.confirm=window.prompt=function(){return true;},true)`);
    for (const f of maps) {
      const name = basename(f, '.bpmn');
      const r = await ev(cmd, PROBE(readFileSync(join(RENDERED, f), 'utf8')));
      perMap[name] = r;
      if (!r.ok) { fails.push(`${name}: probe error ${r.error}`); continue; }
      if (r.xDrift.length) fails.push(`${name}: leg1 verticalOnly — compaction moved x of ${r.xDrift.join(',')}`);
      if (r.lastMoved > 0) fails.push(`${name}: leg2 convergence — still moving ${r.lastMoved} after ${r.iters} iters`);
      if (r.escapees.length) fails.push(`${name}: leg3 containment — outside lane band: ${r.escapees.join(',')}`);
      if (r.ovAfter > r.ovBefore) fails.push(`${name}: leg4 overlaps — ${r.ovBefore} -> ${r.ovAfter}`);
      if (r.messBefore != null && r.messAfter > r.messBefore) fails.push(`${name}: leg5 messiness — ${r.messBefore} -> ${r.messAfter}`);
      if (!r.undoOk) fails.push(`${name}: leg6 undo — undoTidy did not restore geometry exactly`);
      if (PAIR_CEILINGS[name] && r.totalH > PAIR_CEILINGS[name])
        fails.push(`${name}: leg7 pairHeights — total ${r.totalH} > ceiling ${PAIR_CEILINGS[name]}`);
    }
    const ok = fails.length === 0;
    const heights = Object.fromEntries(Object.entries(perMap).map(([k, v]) => [k, v.totalH]));
    process.stdout.write(JSON.stringify({ ok, maps: maps.length, fails, heights }, null, 2) + '\n');
    process.exitCode = ok ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, error: String(e && e.stack || e), fails }, null, 2) + '\n');
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
