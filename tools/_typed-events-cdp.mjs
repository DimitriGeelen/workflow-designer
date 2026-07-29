#!/usr/bin/env node
// _typed-events-cdp.mjs — T-204 Slice 1 correctness guard for typed intermediate
// events (error / timer / message). The round-trip harness
// (_roundtrip-serialization-cdp.mjs) proves parse→build is a SELF-CONSISTENT fixed
// point; it cannot prove CORRECTNESS (a consistently-wrong mapping — e.g. the
// typed event decoding back to linkEventCatch — would still be a fixed point).
// This harness asserts the actual, correct decode/encode IN THE REAL EDITOR:
//   * parseBpmnXml(typed-events.bpmn) yields node.type ∈ {eventError,eventTimer,
//     eventMessage} with the kind-specific binding field restored;
//   * buildBpmnXml re-emits the three <aef:eventDef kind=… binding=…/> markers;
//   * BITE: with <aef:eventDef> stripped, the same intermediateCatchEvent tag
//     decodes to linkEventCatch — proving the typing is DRIVEN BY the extension,
//     not the tag (the collision-disambiguation is real).
// Isolation mirrors the round-trip harness: temp docroot served by gallery-serve.py
// on a free port, driven in an isolated headless chromium (G-006). Exit 0 = correct
// + bites; 1 = a correctness/bite assertion failed; 2 = misconfig (no fixture/editor).
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXTURE = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 'typed-events.bpmn');
const BFIXTURE = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 'boundary-events.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const ASSERT_EXPR = `(function(){
  var text = window.__FIXTURE__;
  var want = {
    n_err: { type:'eventError',   field:'errorStatus', val:'status:issues' },
    n_tmr: { type:'eventTimer',   field:'timerSpec',   val:'0 9 * * *' },
    n_msg: { type:'eventMessage', field:'busTopic',    val:'bus:designer-events' }
  };
  var emitWant = [
    'kind="error" binding="status:issues"',
    'kind="timer" binding="0 9 * * *"',
    'kind="message" binding="bus:designer-events"'
  ];
  var errs = [];
  try {
    var m = parseBpmnXml(text);
    if(!m) return { ok:false, errs:['parse-null'] };
    var byUid = {}; m.nodes.forEach(function(n){ byUid[n.uid]=n; });
    for (var uid in want) {
      var n = byUid[uid];
      if(!n){ errs.push('missing node '+uid); continue; }
      if(n.type !== want[uid].type) errs.push(uid+' type '+n.type+' != '+want[uid].type);
      var got = (n.aef||{})[want[uid].field];
      if(got !== want[uid].val) errs.push(uid+' '+want[uid].field+'='+JSON.stringify(got)+' != '+JSON.stringify(want[uid].val));
    }
    state = m; refreshDisplayIds();
    // T-311: same class as the boundary block below — assert on structure, not on
    // the authored doc block that now legitimately rides along in the export.
    var emit = buildBpmnXml(state).replace(/<!--[\\s\\S]*?-->/g, '');
    emitWant.forEach(function(s){ if(emit.indexOf('<aef:eventDef '+s) < 0) errs.push('emit missing <aef:eventDef '+s+'/>'); });
    // BITE: strip the eventDef markers — the SAME intermediateCatchEvent tag must
    // now decode to linkEventCatch, proving the typing is driven by the extension.
    var stripped = text.replace(/<aef:eventDef[^>]*\\/>/g, '');
    var m2 = parseBpmnXml(stripped);
    var probe = (m2 ? m2.nodes.filter(function(n){return n.uid==='n_err';})[0] : null);
    var biteOk = !!probe && probe.type === 'linkEventCatch';
    if(!biteOk) errs.push('BITE FAIL: n_err without <aef:eventDef> decoded to '+(probe?probe.type:'<missing>')+', expected linkEventCatch');
    return { ok: errs.length===0, errs:errs, biteOk:biteOk };
  } catch(e) { return { ok:false, errs:['exception: '+(e&&e.message||e)] }; }
})()`;

// T-204 Slice 2 correctness guard for the BOUNDARY form. The round-trip harness proves
// a semantic fixed point but cannot prove the emitted TAG is literally bpmn:boundaryEvent
// (a wrong-but-consistent intermediateCatchEvent+attachedToRef would also be a fixed point
// once hostRef is projected). This asserts, IN THE REAL EDITOR:
//   * parse resolves attachedToRef → aef.hostRef (the host uid) + cancelActivity → interrupting;
//   * build re-emits <bpmn:boundaryEvent attachedToRef=<hostDisplayId> cancelActivity=…>,
//     the host itself stays a serviceTask, and both cancelActivity values appear;
//   * BITE: strip attachedToRef and the same node loses its hostRef — attachment is driven
//     by the native attribute, not by the boundaryEvent tag.
const BOUNDARY_ASSERT_EXPR = `(function(){
  var text = window.__BFIXTURE__;
  var errs = [];
  var wantB = {
    n_berr: { type:'eventError', interrupting:'true'  },
    n_btmr: { type:'eventTimer', interrupting:'false' }
  };
  try {
    var m = parseBpmnXml(text);
    if(!m) return { ok:false, errs:['parse-null'] };
    var byUid = {}; m.nodes.forEach(function(n){ byUid[n.uid]=n; });
    var host = byUid['n_host'];
    if(!host){ errs.push('missing host n_host'); return { ok:false, errs:errs }; }
    for (var uid in wantB) {
      var n = byUid[uid];
      if(!n){ errs.push('missing boundary node '+uid); continue; }
      var aef = n.aef||{};
      if(n.type !== wantB[uid].type) errs.push(uid+' type '+n.type+' != '+wantB[uid].type);
      if(aef.hostRef !== 'n_host') errs.push(uid+' hostRef='+JSON.stringify(aef.hostRef)+' != "n_host"');
      if(aef.interrupting !== wantB[uid].interrupting) errs.push(uid+' interrupting='+JSON.stringify(aef.interrupting)+' != '+wantB[uid].interrupting);
    }
    state = m; refreshDisplayIds();
    var hostDid = displayIdOf(host);
    // T-311: strip comments before asserting on structure. Authored doc blocks now
    // survive the round-trip, and this fixture's own block names <bpmn:boundaryEvent >
    // in prose — which inflated the count below from 2 to 3. The presence checks that
    // follow are the more dangerous half of the same class: a doc block quoting
    // cancelActivity="true" would make one pass with no such attribute emitted.
    var emit = buildBpmnXml(state).replace(/<!--[\\s\\S]*?-->/g, '');
    if(emit.indexOf('<bpmn:serviceTask id="'+hostDid+'"') < 0) errs.push('host not emitted as <bpmn:serviceTask id="'+hostDid+'">');
    var nb = (emit.match(/<bpmn:boundaryEvent /g)||[]).length;
    if(nb !== 2) errs.push('expected 2 <bpmn:boundaryEvent>, got '+nb);
    if(emit.indexOf('attachedToRef="'+hostDid+'"') < 0) errs.push('no boundary event attachedToRef the host displayId '+hostDid);
    if(emit.indexOf('cancelActivity="true"') < 0) errs.push('missing cancelActivity="true" (interrupting)');
    if(emit.indexOf('cancelActivity="false"') < 0) errs.push('missing cancelActivity="false" (non-interrupting)');
    // BITE: strip the native attachment → the same node must lose its hostRef.
    var stripped = text.replace(/ attachedToRef="[^"]*"/g, '').replace(/ cancelActivity="[^"]*"/g, '');
    var m2 = parseBpmnXml(stripped);
    var probe = m2 ? m2.nodes.filter(function(n){return n.uid==='n_berr';})[0] : null;
    var biteOk = !!probe && !((probe.aef||{}).hostRef);
    if(!biteOk) errs.push('BITE FAIL: n_berr without attachedToRef still had hostRef '+(probe&&probe.aef?probe.aef.hostRef:'<none>'));
    return { ok: errs.length===0, errs:errs, biteOk:biteOk };
  } catch(e) { return { ok:false, errs:['exception: '+(e&&e.message||e)] }; }
})()`;

// T-204 Slice 2 step 3 (T-168 ports) render-path guard. The boundary data-path and
// round-trip guards prove serialization; they say nothing about how a boundary event's
// OUTGOING edge is routed. This asserts, IN THE REAL EDITOR after a full render:
//   * each boundary-origin edge's SOURCE anchor sits at the host-edge outward port
//     (boundaryOutwardPort ≡ the perimeter normal, so the edge leaves the host); and
//   * the routed polyline never passes through the host-body interior — including the
//     hard case (n_btmr, a TOP-edge boundary whose handler is BELOW): it must exit
//     upward and route AROUND, not straight down through the host.
// Without this, a regression to centre-toward-target anchoring (edge crossing the host)
// would pass every other guard silently.
const PORT_ASSERT_EXPR = `(function(){
  var text = window.__BFIXTURE__;
  var errs = [];
  try {
    var m = parseBpmnXml(text);
    if(!m) return { ok:false, errs:['parse-null'] };
    state = m; refreshDisplayIds();
    if (typeof renderAll === 'function') renderAll(); else { renderNodes(); renderEdges(); }
    var host = findNode('n_host');
    if(!host){ errs.push('missing host n_host'); return { ok:false, errs:errs }; }
    var hd = NODE_DEFAULTS[host.type];
    var hr = { x: host.x, y: host.y, w: hd.w, h: hd.h };
    var checked = 0;
    for (var i=0;i<state.edges.length;i++){
      var e = state.edges[i];
      var src = findNode(e.source);
      if(!src || !boundaryHostOf(src)) continue;
      checked++;
      var poly = e._renderedPolyline;
      if(!poly || poly.length < 2){ errs.push(e.id+' no rendered polyline'); continue; }
      var port = boundaryOutwardPort(src, host);
      var anch = portPointAt(src, port);
      if (Math.hypot(anch.x-poly[0].x, anch.y-poly[0].y) > 0.5)
        errs.push(e.id+' source anchor not at outward port '+port+' (got '+JSON.stringify(poly[0])+', want '+JSON.stringify(anch)+')');
      var crosses = false, pad = 2;
      for (var s=0;s<poly.length-1 && !crosses;s++){
        for (var t=0;t<=1;t+=0.02){
          var x = poly[s].x + (poly[s+1].x-poly[s].x)*t;
          var y = poly[s].y + (poly[s+1].y-poly[s].y)*t;
          if (x>hr.x+pad && x<hr.x+hr.w-pad && y>hr.y+pad && y<hr.y+hr.h-pad){ crosses=true; break; }
        }
      }
      if(crosses) errs.push(e.id+' routed polyline crosses the host body');
    }
    if(checked !== 2) errs.push('expected 2 boundary-origin edges, checked '+checked);
    return { ok: errs.length===0, errs:errs, checked:checked };
  } catch(e) { return { ok:false, errs:['exception: '+(e&&e.message||e)] }; }
})()`;

async function main() {
  if (!existsSync(FIXTURE)) { process.stdout.write(JSON.stringify({ ok:false, error:'fixture missing: '+FIXTURE })+'\n'); process.exitCode = 2; return; }
  if (!existsSync(BFIXTURE)) { process.stdout.write(JSON.stringify({ ok:false, error:'fixture missing: '+BFIXTURE })+'\n'); process.exitCode = 2; return; }
  const text = readFileSync(FIXTURE, 'utf8');
  const btext = readFileSync(BFIXTURE, 'utf8');
  const doc = mkdtempSync(join(tmpdir(), 'te-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'te-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'te-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(text)};`);
    const r = await ev(cmd, ASSERT_EXPR);
    await ev(cmd, `window.__BFIXTURE__ = ${JSON.stringify(btext)};`);
    const rb = await ev(cmd, BOUNDARY_ASSERT_EXPR);
    const rp = await ev(cmd, PORT_ASSERT_EXPR);
    const out = { ok: !!(r && r.ok && rb && rb.ok && rp && rp.ok), typed: r, boundary: rb, ports: rp };
    process.stdout.write(JSON.stringify(out, null, 2) + '\n');
    process.exitCode = out.ok ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, error: String(e && e.stack || e) }, null, 2) + '\n');
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
