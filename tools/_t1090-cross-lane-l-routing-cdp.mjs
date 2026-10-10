#!/usr/bin/env node
// _t1090-cross-lane-l-routing-cdp.mjs — T-1090: auto-routed cross-lane flows take ONE bend (an L).
//
// aef-greenfield-test (T-172 #1): the owner straightened a generated map by hand. Every cross-lane
// flow the router had drawn as a Z (leave E, enter W, two bends) became an L: leave on the side
// facing the target lane and enter W, or leave E and enter on the side facing the source lane.
// Bends 46 -> 24. The router chose each auto end's side independently, which cannot make an L.
//
// Synthetic map (3 lanes x 130px; Greenfield's map is their client's process, not committed):
//   e1 A->B, e2 B->A, e3 A->C (two lanes), e5 C->A   cross-lane, corners free  -> L, exit N/S, enter W
//     (the old router drew these as a 4-bend S->N staircase at this box aspect, or as an E->W Z)
//   e4 C->C, e6 A->A                                   same lane                 -> straight (0 bends)
//   e7 A->B, a box below the source                    first L blocked           -> L, exit E, enter N
//   e9 A->B, boxes below the source AND above target   both L blocked            -> Z kept, no box cut
// Also: no flow cuts a node box; total bends with crossLane 'L' < with 'Z' (the Settings toggle);
// the exported BPMN DI for e1 has the same one-bend shape as the canvas.
//
//   node tools/_t1090-cross-lane-l-routing-cdp.mjs [--designer PATH] [--bpmn PATH]
//   --designer: run against another copy (the unfixed designer must FAIL)
//   --bpmn: only REPORT bends/crossings on another file (Greenfield's map; not committed);
//           exits 0 iff total bends <= --max-bends (default 24) and no flow cuts a box.
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const argv = process.argv.slice(2);
const opt = k => { const i = argv.indexOf(k); return i >= 0 ? argv[i + 1] : null; };
const DESIGNER = opt('--designer') || join(REPO, 'src', 'aef-workflow-designer.html');
const OTHER = opt('--bpmn');
const MAX_BENDS = parseInt(opt('--max-bends') || '24', 10);
const sleep = ms => new Promise(r => setTimeout(r, ms));

const task = (id, name) => `    <bpmn:serviceTask id="${id}" name="${name}"><bpmn:extensionElements><aef:uid value="u_${id}"/></bpmn:extensionElements></bpmn:serviceTask>`;
const flow = (id, s, t) => `    <bpmn:sequenceFlow id="${id}" sourceRef="${s}" targetRef="${t}"><bpmn:extensionElements><aef:uid value="u_${id}"/></bpmn:extensionElements></bpmn:sequenceFlow>`;
const LANES = { A: ['n1', 'n3', 'n6', 'n7', 'n10', 'n13'], B: ['n2', 'n8', 'n9', 'n11', 'n12'], C: ['n4', 'n5'] };
const X = { n1: 100, n2: 320, n3: 540, n4: 760, n5: 980, n6: 1200, n7: 1420, n8: 1640, n9: 1420, n10: 1860, n11: 2080, n12: 1860, n13: 2080 };
const FLOWS = [['e1', 'n1', 'n2'], ['e2', 'n2', 'n3'], ['e3', 'n3', 'n4'], ['e4', 'n4', 'n5'], ['e5', 'n5', 'n6'], ['e6', 'n6', 'n7'], ['e7', 'n7', 'n8'], ['e9', 'n10', 'n11']];
const FIXTURE = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" id="Defs_t1090" targetNamespace="https://example.invalid/t1090">
  <bpmn:process id="Process_t1090" isExecutable="false">
    <bpmn:extensionElements><aef:workflowMeta id="t1090-cross-lane" version="1" schemaVersion="2" title="T-1090 cross-lane routing"/></bpmn:extensionElements>
    <bpmn:laneSet id="LaneSet_1">
${Object.entries(LANES).map(([l, ns]) => `      <bpmn:lane id="lane_${l}" name="Lane ${l}"><bpmn:extensionElements><aef:laneMeta abbr="l${l.toLowerCase()}x" authority="none" height="130"/></bpmn:extensionElements>${ns.map(n => `<bpmn:flowNodeRef>${n}</bpmn:flowNodeRef>`).join('')}</bpmn:lane>`).join('\n')}
    </bpmn:laneSet>
${Object.keys(X).map(n => task(n, 'Step ' + n)).join('\n')}
${FLOWS.map(([id, s, t]) => flow(id, s, t)).join('\n')}
  </bpmn:process>
</bpmn:definitions>`;

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof computeEdgeGeometry==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// In-page measurement: for each flow, its routed polyline, bends, first/last segment
// orientation and whether it cuts a node box. `mode` sets routingPrefs.crossLane.
const MEASURE = (placeSynthetic, mode, first) => `(function(){
  function bends(poly){ var s=[]; for(var i=0;i<poly.length-1;i++){ var dx=poly[i+1].x-poly[i].x, dy=poly[i+1].y-poly[i].y; if(Math.abs(dx)<0.5&&Math.abs(dy)<0.5) continue; s.push(Math.abs(dx)>=Math.abs(dy)?'H':'V'); } var n=0; for(var j=1;j<s.length;j++) if(s[j]!==s[j-1]) n++; return {n:n, first:s[0], last:s[s.length-1]}; }
  state = parseBpmnXml(window.__XML__);
  if (${placeSynthetic}) {
    var X = ${JSON.stringify(X)};
    state.nodes.forEach(function(n){ var key = n.uid.replace(/^u_/,''); if (X[key] !== undefined) { var d = NODE_DEFAULTS[n.type]; var L = findLane(n.lane); n.x = X[key]; n.y = laneTop(n.lane) + (L.height - d.h) / 2; } });
  }
  if (typeof routingPrefs.crossLane !== 'undefined' || '${mode}' === 'Z') routingPrefs.crossLane = '${mode}';
  routingPrefs.crossLaneFirst = '${first || 'vertical'}';   // T-1110
  _edgeGroupCache = null; refreshDisplayIds();
  var out = {}, total = 0, cut = 0;
  state.edges.forEach(function(e){
    var src = findNode(e.source), tgt = findNode(e.target); if (!src || !tgt) return;
    var poly = computeEdgeGeometry(e, src, tgt).polyline;
    var b = bends(poly), c = polylineCrossesNodes(poly, src, tgt);
    total += b.n; if (c) cut++;
    out[e.uid.replace(/^u_/,'')] = { bends: b.n, first: b.first, last: b.last, cuts: c, cross: src.lane !== tgt.lane };
  });
  var e1di = null;
  if (${placeSynthetic}) {
    var xml = buildBpmnXml(state);
    var m = xml.match(/<bpmndi:BPMNEdge[^>]*bpmnElement="[^"]*"[^>]*>([\\s\\S]*?)<\\/bpmndi:BPMNEdge>/g) || [];
    var e1id = displayIdOf(state.edges.filter(function(e){ return e.uid === 'u_e1'; })[0]);
    m.forEach(function(block){ if (block.indexOf('"' + e1id + '"') >= 0) { var pts = []; block.replace(/x="([-\\d.]+)" y="([-\\d.]+)"/g, function(_, x, y){ pts.push({x:+x, y:+y}); }); e1di = bends(pts).n; } });
  }
  var dbg = state.nodes.filter(function(n){return /n[12]$/.test(n.uid);}).map(function(n){return [n.uid,n.lane,n.x,n.y,n.type];});
  var e1 = state.edges.filter(function(e){return e.uid==='u_e1';})[0];
  dbg.push(e1 ? computeEdgeGeometry(e1, findNode(e1.source), findNode(e1.target)).polyline : 'no e1');
  return { flows: out, total: total, cut: cut, e1di: e1di, dbg: window.__DBG__ ? dbg : undefined };
})()`;

async function main() {
  if (!existsSync(DESIGNER) || (OTHER && !existsSync(OTHER))) { console.log(JSON.stringify({ ok: false, error: 'missing input' })); process.exitCode = 2; return; }
  const xml = OTHER ? readFileSync(OTHER, 'utf8') : FIXTURE;
  const doc = mkdtempSync(join(tmpdir(), 't1090-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1090-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1090-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__XML__ = ${JSON.stringify(xml)}; true`);
    await ev(cmd, 'window.__DBG__ = !!' + JSON.stringify(!!process.env.T1090_DBG)); const L = await ev(cmd, MEASURE(!OTHER, 'L')); if (process.env.T1090_DBG) console.log(JSON.stringify(L.dbg));
    const Z = await ev(cmd, MEASURE(!OTHER, 'Z'));
    const H = await ev(cmd, MEASURE(!OTHER, 'L', 'horizontal'));   // T-1110: the mirror L
    if (OTHER) {
      const crossMulti = Object.values(L.flows).filter(f => f.cross && f.bends > 1).length;
      console.log(JSON.stringify({ file: OTHER, L: { totalBends: L.total, cutsBox: L.cut, crossLaneOver1Bend: crossMulti }, Z: { totalBends: Z.total, cutsBox: Z.cut } }));
      leg(L.total <= MAX_BENDS && L.cut === 0, `file: total bends ${L.total} <= ${MAX_BENDS} and no flow cuts a box`, `cut=${L.cut}`);
    } else {
      const f = L.flows;
      for (const id of ['e1', 'e2', 'e3', 'e5'])
        leg(f[id] && f[id].bends === 1 && f[id].first === 'V' && f[id].last === 'H', `${id} cross-lane, corners free -> L leaving N/S, entering W`, JSON.stringify(f[id]));
      for (const id of ['e4', 'e6']) leg(f[id] && f[id].bends === 0, `${id} same lane -> straight`, JSON.stringify(f[id]));
      leg(f.e7 && f.e7.bends === 1 && f.e7.first === 'H' && f.e7.last === 'V', 'e7 first L blocked -> fallback L leaving E, entering N', JSON.stringify(f.e7));
      leg(f.e9 && f.e9.bends >= 2 && !f.e9.cuts, 'e9 both L blocked -> Z kept, cuts no box', JSON.stringify(f.e9));
      leg(L.cut === 0, 'no flow cuts a node box (L mode)', 'cut=' + L.cut);
      leg(L.total < Z.total, `total bends L ${L.total} < Z ${Z.total} (Settings toggle restores the Z)`);
      leg(Z.flows.e1 && Z.flows.e1.bends > 1, 'toggle off: e1 is routed the old way again (more than one bend)', JSON.stringify(Z.flows.e1));
      leg(L.e1di === 1, 'exported BPMN DI for e1 has the same single bend as the canvas', 'di bends=' + L.e1di);
      // T-1110: the mirror preference — the same flows take the OTHER L where it is free; blocked cases keep their fallback
      const h = H.flows;
      leg(['e1', 'e2', 'e3', 'e5'].every(id => h[id] && h[id].bends === 1 && h[id].first === 'H' && h[id].last === 'V'),
          'T-1110 mirror: e1/e2/e3/e5 leave E and enter N/S, still one bend', JSON.stringify(['e1', 'e2', 'e3', 'e5'].map(id => h[id])));
      leg(h.e7 && h.e7.bends === 1 && h.e7.first === 'H' && h.e9 && h.e9.bends >= 2 && !h.e9.cuts && H.cut === 0,
          'T-1110 mirror: e7 still one bend, e9 (both blocked) still a Z, no flow cuts a box', JSON.stringify({ e7: h.e7, e9: h.e9, cut: H.cut }));
    }
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
  for (const l of legs) console.log(`${l.ok ? 'PASS' : 'FAIL'}  ${l.name}${l.detail ? ' — ' + l.detail : ''}`);
  const want = OTHER ? 1 : 14;
  const ok = legs.length === want && legs.every(l => l.ok);
  console.log(ok ? `${legs.length}/${want} legs passed` : `FAILED (${legs.filter(l => !l.ok).length} of ${legs.length})`);
  process.exitCode = ok ? 0 : 1;
}
main();
