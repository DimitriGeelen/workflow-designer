// T-1456 — routing: a flow between two steps of one lane stays in that lane, and an incoming end does not sit on top of
// an outgoing start (Greenfield item 6). Measured on the DRAWN paths (g.edge[data-id] > path.edge-path), headless
// Chromium over CDP.
//
//   F1 [Greenfield fixture, 1024/1440/1920] the 'wel' flow (gateway Redesign -> Opportunity/Solution, both in Tacton)
//      has every point inside lane Tacton
//   F2 [same] its arrowhead end on Opportunity/Solution is on another side than that step's outgoing starts, or >= 12 px
//      from each of them
//   F3 [same] T-1457 (Greenfield 7): at Productieorder the incoming and outgoing ends are on different sides or >= 12 px
//      apart, and the incoming flow (straight down from Verkooporder compleet) stays one straight segment
//   C1 [24 corpus maps + the fixture, 1440] L = automatically routed same-lane flows outside their lane although a bar
//      inside it cuts no step; S = incoming ends within 8 px of an outgoing start on the same side of one step: both
//      0. Flows that leave for a reason (a route the author set; a lane where every bar cuts a step) are listed.
// Teeth: T1456_EDITOR=<the 0.44.0 designer> fails F1/F2 (and C1 where the corpus had the faults).
import { readFileSync, mkdirSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1456_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const RENDERED = join(ROOT, 'examples', 'aef-processes', 'rendered');
const FIXTURE = join(ROOT, 'tests', 'fixtures', 'greenfield', 'nooteboom-offerte-tot-order-with-notes.bpmn');
const CORPUS = process.env.T1456_MAPS ? process.env.T1456_MAPS.split(',') : readdirSync(RENDERED).filter(f => f.endsWith('.bpmn')).sort();
const REPORT = !!process.env.T1456_REPORT;
// Known faults of ANOTHER class, each with its own task: listed by the leg, not counted. Remove an entry when its task
// lands (the leg then counts it again). 'map|flow name' -> task.
const KNOWN = { 'upgrade-process|dry-run': 'T-1459 (a flow into the far side of its target drawn as a loop, through the target box)' };
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1456-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
for (const m of CORPUS) copyFileSync(join(RENDERED, m), join(doc, 'rendered', m));
copyFileSync(FIXTURE, join(doc, 'rendered', 'greenfield.bpmn'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1456-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl;
// In the page: every flow's drawn polyline, its ends' sides, lane bounds; the two counts and the 'wel' details.
const MEASURE = `(function(){
  const laneOf = id => state.lanes.find(l => l.id === id);
  const bounds = l => ({ top: laneTop(l.id), bot: laneTop(l.id) + l.height });
  const node = id => state.nodes.find(n => n.id === id);
  const sideOf = (n, p) => { const d = dims(n), t = 2.5;
    if (Math.abs(p.x - n.x) <= t) return 'left'; if (Math.abs(p.x - (n.x + d.w)) <= t) return 'right';
    if (Math.abs(p.y - n.y) <= t) return 'top'; if (Math.abs(p.y - (n.y + d.h)) <= t) return 'bottom';
    const cx = n.x + d.w / 2, cy = n.y + d.h / 2; const dx = (p.x - cx) / d.w, dy = (p.y - cy) / d.h;   // diamonds, circles
    return Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 'right' : 'left') : (dy > 0 ? 'bottom' : 'top'); };
  const flows = [];
  for (const g of document.querySelectorAll('#g-edges g.edge[data-id]')) {
    const e = state.edges.find(x => x.id === g.dataset.id), p = g.querySelector('path.edge-path');
    if (!e || !p) continue;
    const s = node(e.source), t = node(e.target); if (!s || !t) continue;
    const pl = polylineFromPath(p.getAttribute('d')); if (pl.length < 2) continue;
    flows.push({ id: e.id, name: e.name || '', s, t, pl, a: pl[0], b: pl[pl.length - 1], sa: sideOf(s, pl[0]), sb: sideOf(t, pl[pl.length - 1]) });
  }
  // L counts a flow that leaves its lane although it need not: it is routed automatically (no route of the author's:
  // waypoints, routing hints or a detour height) and some bar height inside the lane cuts no step (the router's own
  // loopPathCrossings over the lane's heights, 4 px apart). Excused cases are listed, never hidden.
  const L = [], excused = [];
  for (const f of flows) {
    if (f.s.lane && f.s.lane === f.t.lane && laneOf(f.s.lane)) {
      const b = bounds(laneOf(f.s.lane));
      const out = f.pl.filter(q => q.y < b.top - 1 || q.y > b.bot + 1);
      if (!out.length) continue;
      const e = state.edges.find(x => x.id === f.id);
      const what = f.id + ' ' + (f.name || f.s.name + '->' + f.t.name).slice(0, 40) + ' y ' + out.map(q => Math.round(q.y)).join(',') + ' lane ' + Math.round(b.top) + '-' + Math.round(b.bot);
      const authored = (e.waypoints && e.waypoints.length) || (e.routingHints && Object.keys(e.routingHints).length) || typeof e.detourY === 'number';
      if (authored) { excused.push(what + ' (route set by the author)'); continue; }
      let clear = false;
      if (f.pl.length >= 4) for (let y = b.top + 4; y <= b.bot - 4 && !clear; y += 4) clear = loopPathCrossings(f.pl[1], f.pl[f.pl.length - 2], y, f.s, f.t) === 0;
      if (!clear) { excused.push(what + ' (every bar inside the lane cuts a step)'); continue; }
      L.push({ what, name: f.name || '' });
    }
  }
  const S = [];
  for (const f of flows) for (const o of flows) {
    if (o === f || o.s.id !== f.t.id || o.sa !== f.sb) continue;   // f ends where o starts, same side
    const d = Math.hypot(f.b.x - o.a.x, f.b.y - o.a.y);
    if (d < 8) S.push(f.t.name.slice(0, 30) + ' ' + f.sb + ': in ' + (f.name || f.id) + ' / out ' + (o.name || o.id) + ' ' + d.toFixed(1) + ' px');
  }
  const wel = flows.find(f => f.name === 'wel');
  let welInfo = null;
  if (wel) {
    const b = bounds(laneOf(wel.t.lane));
    const outs = flows.filter(o => o.s.id === wel.t.id);
    welInfo = { lane: laneOf(wel.t.lane).name, top: Math.round(b.top), bot: Math.round(b.bot), ys: wel.pl.map(q => Math.round(q.y)),
      inside: wel.pl.every(q => q.y >= b.top - 1 && q.y <= b.bot + 1), end: [Math.round(wel.b.x), Math.round(wel.b.y), wel.sb],
      outs: outs.map(o => ({ side: o.sa, at: [Math.round(o.a.x), Math.round(o.a.y)], d: Math.round(Math.hypot(wel.b.x - o.a.x, wel.b.y - o.a.y) * 10) / 10 })) };
  }
  // T-1457: Productieorder (lane NAV): its incoming and outgoing ends, and whether the incoming flow is straight
  const prodNode = state.nodes.find(n => /^Productieorder/.test(n.name || ''));
  let prod = null;
  if (prodNode) {
    const ins = flows.filter(f => f.t.id === prodNode.id), outs = flows.filter(f => f.s.id === prodNode.id);
    prod = { ins: ins.map(f => ({ side: f.sb, at: [Math.round(f.b.x), Math.round(f.b.y)], pts: f.pl.length })),
             outs: outs.map(f => ({ side: f.sa, at: [Math.round(f.a.x), Math.round(f.a.y)] })),
             minGap: Math.min(Infinity, ...ins.flatMap(i => outs.filter(o => o.sa === i.sb).map(o => Math.hypot(i.b.x - o.a.x, i.b.y - o.a.y)))) };
  }
  return { L, S, excused, wel: welInfo, prod, flows: flows.length };
})()`;
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  await cmd('Page.enable'); await cmd('Runtime.enable');
  const open = async (map, W) => {
    await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: 'about:blank' }); await sleep(100);
    await cmd('Storage.clearDataForOrigin', { origin: `http://127.0.0.1:${port}`, storageTypes: 'all' });
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${map}` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
    await sleep(500);
    return ev(MEASURE);
  };
  for (const W of [1024, 1440, 1920]) {
    const m = await open('greenfield.bpmn', W);
    const w = m.wel;
    leg(!!w && w.inside, `F1 [greenfield @${W}] the 'wel' loop stays inside lane ${w ? w.lane : '?'} (${w ? w.top + '-' + w.bot : '?'})`, w ? `ys ${w.ys.join(',')}` : 'no flow named wel');
    const clear = !!w && w.outs.every(o => o.side !== w.end[2] || o.d >= 12);
    leg(clear, `F2 [greenfield @${W}] its arrowhead on Opportunity/Solution is on another side than the step's outgoing starts, or >= 12 px from them`,
        w ? `end ${w.end.join(' ')}; outgoing ${w.outs.map(o => o.side + ' ' + o.at.join(',') + ' (' + o.d + ' px)').join('; ')}` : '');
    const p = m.prod;   // T-1457 (Greenfield 7)
    leg(!!p && p.ins.length > 0 && p.outs.length > 0 && p.minGap >= 12 && p.ins.every(i => i.pts === 2),
        `F3 [greenfield @${W}] at Productieorder the incoming and outgoing ends are on different sides or >= 12 px apart, and the incoming flow stays straight (T-1457)`,
        p ? `in ${p.ins.map(i => i.side + ' ' + i.at.join(',') + ' (' + i.pts + ' points)').join('; ')}; out ${p.outs.map(o => o.side + ' ' + o.at.join(',')).join('; ')}; nearest same-side gap ${Number.isFinite(p.minGap) ? p.minGap.toFixed(1) + ' px' : 'none (different sides)'}` : 'no step Productieorder');
  }
  let Lsum = 0, Ssum = 0; const per = [], exc = [];
  for (const map of [...CORPUS, 'greenfield.bpmn']) {
    const m = await open(map, 1440);
    const tag = map.replace('.bpmn', '');
    const known = m.L.filter(x => KNOWN[tag + '|' + x.name]);
    m.L = m.L.filter(x => !KNOWN[tag + '|' + x.name]).map(x => x.what);
    for (const x of known) exc.push(tag + ': ' + x.what + ' (known: ' + KNOWN[tag + '|' + x.name] + ')');
    Lsum += m.L.length; Ssum += m.S.length; for (const x of m.excused) exc.push(tag + ': ' + x);
    if (m.L.length || m.S.length) per.push(`${map.replace('.bpmn', '')} L${m.L.length} S${m.S.length}`);
    if (REPORT) for (const x of [...m.L.map(v => 'L ' + v), ...m.S.map(v => 'S ' + v)]) console.log(`      ${map}: ${x}`);
  }
  leg(Lsum === 0 && Ssum === 0, `C1 [${CORPUS.length} corpus maps + the fixture @1440] no same-lane flow leaves its lane (L), no incoming end within 8 px of an outgoing start on one side (S)`,
      `L ${Lsum}, S ${Ssum}${per.length ? ': ' + per.join('; ') : ''}; leaving the lane excused: ${exc.length ? exc.join(' | ') : 'none'}`);
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL');
  for (const d of [doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
