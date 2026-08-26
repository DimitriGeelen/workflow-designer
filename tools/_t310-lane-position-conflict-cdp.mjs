#!/usr/bin/env node
// _t310-lane-position-conflict-cdp.mjs — drive the real editor against a map whose
// declared lane membership disagrees with its own <aef:position> geometry, and prove
// the T-310 contract:
//
//   1. conflicts are reconciled in favour of the DECLARED lane (membership is the
//      `who`, T-189; position is view-layer)
//   2. agreements are left completely alone (no gratuitous geometry rewriting)
//   3. the move is REPORTED, not silent
//   4. laneAtY no longer adopts a below-all-bands node into the top lane
//   5. nothing about the reconciliation leaks into the exported document
//   6. the result is idempotent — re-importing the export reconciles zero
//
// Why a real browser rather than a unit test: the defect lived in the interaction
// between parse, the lane-band geometry and the drag handler. Only the assembled
// editor exercises all three (the same reason T-308 used this harness shape).
//
// Usage:  node tools/_t310-lane-position-conflict-cdp.mjs
// Exit 0 = contract holds; 1 = violated (offending assertions named); 2 = misconfig.
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
const FIXTURE = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 'lane-position-conflict.bpmn');
// argv[2] optionally points at a different designer build — used to prove the
// harness has teeth by running it against the pre-fix source (PL-061: a check that
// cannot go red is not evidence).
const SRC = process.argv[2] || join(REPO, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&typeof laneAtY==='function'&&typeof laneTop==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Everything the assertions need, read out of the LIVE editor in one shot.
const PROBE = `(function(){
  adoptImportedXml(window.__FIX__, { userImport: true });
  function band(id){ var l = findLane(id); if(!l) return null; var t = laneTop(id); return { top: t, bottom: t + l.height }; }
  // Tolerant read: on a build predating T-310 the counter does not exist. Reporting
  // 0 rather than throwing makes the teeth-test fail on the REAL assertions (nodes
  // drawn in the wrong lane, no notice, void adopted by lane[0]) instead of dying
  // on a ReferenceError, which would prove nothing.
  var out = { reconciled: (typeof _laneReconcileCount === 'number' ? _laneReconcileCount : 0), nodes: [], bands: {} };
  ['agent','framework'].forEach(function(id){ out.bands[id] = band(id); });
  state.nodes.forEach(function(n){
    var def = NODE_DEFAULTS[n.type] || NODE_DEFAULTS.serviceTask;
    var cy = n.y + def.h / 2;
    out.nodes.push({ uid: n.uid, lane: n.lane, y: n.y, cy: cy, laneAtCentre: laneAtY(cy) });
  });
  var lf = document.getElementById('lane-fix-notice');
  var nudge = document.getElementById('clean-nudge');
  out.notice = {
    visible: !!lf && lf.style.display !== 'none',
    text: (document.getElementById('lane-fix-msg') || {}).textContent || '',
    nudgeStacked: !!nudge && nudge.classList.contains('stacked'),
  };
  // orphan adoption: a y far below every band must be "no lane", not lane[0]
  var below = 0; getLanes().forEach(function(l){ below += l.height; });
  out.laneAtVoid = laneAtY(30 + 32 + below + 500);
  out.exported = buildBpmnXml(state);
  return out;
})()`;

async function main() {
  if (!existsSync(FIXTURE)) { console.log(JSON.stringify({ ok: false, error: 'fixture missing: ' + FIXTURE })); process.exitCode = 2; return; }
  const fixture = readFileSync(FIXTURE, 'utf8');

  const doc = mkdtempSync(join(tmpdir(), 't310-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't310-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't310-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const errs = [];
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(200);
    await ev(cmd, `window.__FIX__ = ${JSON.stringify(fixture)};`);
    const r = await ev(cmd, PROBE);

    const byUid = Object.fromEntries(r.nodes.map(n => [n.uid, n]));
    const EXPECT = {
      n_start: { lane: 'agent',     moved: false, y: 110 },
      n_check: { lane: 'framework', moved: true },
      n_act:   { lane: 'agent',     moved: true },
      n_done:  { lane: 'framework', moved: false, y: 310 },
    };

    // 1. exactly the two conflicting nodes were reconciled
    if (r.reconciled !== 2) errs.push(`reconcile count ${r.reconciled}, expected 2`);

    for (const [uid, exp] of Object.entries(EXPECT)) {
      const n = byUid[uid];
      if (!n) { errs.push(`node ${uid} missing after import`); continue; }
      // 2. declared membership survived — the whole point
      if (n.lane !== exp.lane) errs.push(`${uid}: lane ${n.lane}, declared ${exp.lane}`);
      // 3. it is now DRAWN inside the lane it claims to be in
      if (n.laneAtCentre !== exp.lane) errs.push(`${uid}: centre falls in ${n.laneAtCentre}, declared ${exp.lane}`);
      // 4. agreeing nodes must not be touched at all
      if (exp.moved === false && n.y !== exp.y) errs.push(`${uid}: y moved ${exp.y} -> ${n.y} but it already agreed`);
    }

    // 5. the move is announced
    if (!r.notice.visible) errs.push('lane-fix notice not shown despite 2 reconciled');
    if (!/2 nodes were drawn outside their declared lane/.test(r.notice.text)) errs.push(`notice text unexpected: ${JSON.stringify(r.notice.text)}`);

    // 6. below every band is "no lane", not silent adoption by lane[0]
    if (r.laneAtVoid !== null) errs.push(`laneAtY(below all bands) = ${r.laneAtVoid}, expected null`);

    // 7. nothing about the reconciliation leaks into the document.
    // T-311: assert against structure, not prose — authored doc blocks now survive
    // the round-trip, so a fixture whose rationale discusses the reconciliation
    // would otherwise trip the leak check (false red) or seed the uid table below
    // with quoted element names (false green). Neither is a real export surface.
    const exportedS = r.exported.replace(/<!--[\s\S]*?-->/g, '');
    if (/laneReconcile|_laneReconcileCount|laneFix/i.test(exportedS)) errs.push('reconciliation state leaked into exported bytes');
    // displayIds are DERIVED (lane abbr + ordinal + slug) and are regenerated on
    // import, so they cannot be hardcoded here — resolve each flowNodeRef back to
    // its stable aef:uid before comparing membership.
    const dispToUid = {};
    // Anchored on flow-node tags only: a bare <bpmn:\w+ id="..."> also matches
    // <bpmn:lane>, which sits BEFORE the nodes and would swallow the first node's
    // uid — mapping lane ids into the table and shifting every lookup by one.
    const FLOW_TAGS = 'startEvent|endEvent|serviceTask|userTask|scriptTask|exclusiveGateway|parallelGateway|intermediateCatchEvent|intermediateThrowEvent|subProcess';
    for (const m of exportedS.matchAll(new RegExp(`<bpmn:(?:${FLOW_TAGS}) id="([^"]+)"[\\s\\S]*?<aef:uid value="([^"]+)"`, 'g'))) dispToUid[m[1]] = m[2];
    const exportedLaneOf = {};
    for (const m of exportedS.matchAll(/<bpmn:lane id="([^"]+)"([\s\S]*?)<\/bpmn:lane>/g)) {
      for (const f of m[2].matchAll(/<bpmn:flowNodeRef>([^<]+)<\/bpmn:flowNodeRef>/g)) {
        exportedLaneOf[dispToUid[f[1]] || ('?' + f[1])] = m[1];
      }
    }
    for (const [uid, exp] of Object.entries(EXPECT)) {
      if (exportedLaneOf[uid] !== exp.lane) {
        errs.push(`export: ${uid} listed under lane ${exportedLaneOf[uid]}, declared ${exp.lane}`);
      }
    }

    // 8. idempotent — the repaired map has no conflict left to repair
    await ev(cmd, `window.__FIX2__ = ${JSON.stringify(r.exported)};`);
    const again = await ev(cmd, `(function(){ adoptImportedXml(window.__FIX2__, { userImport: true }); return (typeof _laneReconcileCount === 'number' ? _laneReconcileCount : 0); })()`);
    if (again !== 0) errs.push(`re-import of the export reconciled ${again}, expected 0 (not idempotent)`);

    const ok = errs.length === 0;
    console.log(JSON.stringify({ ok, reconciled: r.reconciled, laneAtVoid: r.laneAtVoid, reimportReconciled: again, notice: r.notice, bands: r.bands, nodes: r.nodes, errs }, null, 2));
    process.exitCode = ok ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e), errs }, null, 2));
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
