#!/usr/bin/env node
// _t315-lane-grow-on-import-cdp — T-315: an under-declared lane band is GROWN on
// import, instead of the operator's nodes being moved into the band that was too
// small for them. Drives the REAL editor runtime in an isolated headless chromium.
//
// Two fixtures, and the pairing is the whole point:
//
//   lane-capacity-large-spill.bpmn  ORDERING-CLEAN, agent lane declares 260 while
//       its members span 567. A pure height solve exists, so the band grows to the
//       Clean fixpoint (591) and ZERO nodes move. On the pre-T-315 build three of
//       the four nodes are yanked to a lane centre — the authored layout destroyed
//       to repair a number.
//
//   lane-position-conflict.bpmn     ORDERING-DIRTY (a two-node swap). No set of
//       heights can repair it, so the grow pass stands down entirely and T-310's
//       reconcile behaves byte-identically. This fixture is what the operator is
//       asked to load for T-310's open [REVIEW] ACs, so "unchanged" is a governance
//       requirement, not a nicety. It is a sharp test: this lane WOULD grow if the
//       gate were missing (agent extent 254 vs declared 160), so the assertion
//       fails the moment the ordering precondition is dropped or inverted.
//
// Exit 0 = contract holds; 1 = violated (offending assertions named); 2 = misconfig.
//
// Teeth (PL-061): accepts an optional path to a different designer build.
//     node tools/_t315-lane-grow-on-import-cdp.mjs /path/to/older-designer.html
import { spawn } from 'node:child_process';
import { existsSync, readFileSync, copyFileSync, mkdtempSync, mkdirSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SPILL = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 'lane-capacity-large-spill.bpmn');
const SWAP = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 'lane-position-conflict.bpmn');
const SRC = process.argv[2] || join(REPO, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&typeof laneAtY==='function'&&typeof laneTop==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Read everything the assertions need out of the LIVE editor in one shot.
// Tolerant reads throughout: on a build predating T-315 neither _laneGrowReport
// nor the grow pass exists. Reporting [] rather than throwing makes the teeth run
// fail on the REAL assertions (nodes moved, bands never grown) instead of dying on
// a ReferenceError, which would prove nothing.
const PROBE = fixVar => `(function(){
  adoptImportedXml(window.${fixVar}, { userImport: true });
  var out = {
    reconciled: (typeof _laneReconcileCount === 'number' ? _laneReconcileCount : 0),
    grown: (typeof _laneGrowReport !== 'undefined' && _laneGrowReport) ? _laneGrowReport : [],
    lanes: [], nodes: []
  };
  getLanes().forEach(function(l){
    var t = laneTop(l.id);
    out.lanes.push({ id: l.id, height: l.height, top: t, bottom: t + l.height });
  });
  state.nodes.forEach(function(n){
    var def = NODE_DEFAULTS[n.type] || NODE_DEFAULTS.serviceTask;
    out.nodes.push({ uid: n.uid, lane: n.lane, y: n.y, cy: n.y + def.h / 2,
                     laneAtCentre: laneAtY(n.y + def.h / 2) });
  });
  var lf = document.getElementById('lane-fix-notice');
  out.notice = {
    visible: !!lf && lf.style.display !== 'none',
    text: (document.getElementById('lane-fix-msg') || {}).textContent || ''
  };
  out.exported = buildBpmnXml(state);
  return out;
})()`;

async function main() {
  for (const f of [SPILL, SWAP]) {
    if (!existsSync(f)) { console.log(JSON.stringify({ ok: false, error: 'fixture missing: ' + f })); process.exitCode = 2; return; }
  }
  const spill = readFileSync(SPILL, 'utf8');
  const swap = readFileSync(SWAP, 'utf8');

  const doc = mkdtempSync(join(tmpdir(), 't315-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't315-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't315-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const errs = [];
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(200);
    await ev(cmd, `window.__SPILL__ = ${JSON.stringify(spill)}; window.__SWAP__ = ${JSON.stringify(swap)};`);

    // ── Fixture A: ordering-clean, under-declared band ────────────────────────
    const a = await ev(cmd, PROBE('__SPILL__'));
    const aLane = Object.fromEntries(a.lanes.map(l => [l.id, l]));
    const aNode = Object.fromEntries(a.nodes.map(n => [n.uid, n]));

    // 1. the whole point: nothing moved
    if (a.reconciled !== 0) errs.push(`spill: ${a.reconciled} node(s) moved, expected 0 — an under-declared band must be grown, not have the operator's work relocated`);

    // 2. every authored y survived, exactly
    const AUTHORED = { n_start: 87, n_pick: 300, n_wait: 600, n_done: 700 };
    for (const [uid, y] of Object.entries(AUTHORED)) {
      const n = aNode[uid];
      if (!n) { errs.push(`spill: node ${uid} missing after import`); continue; }
      if (n.y !== y) errs.push(`spill: ${uid} y=${n.y}, authored ${y}`);
    }

    // 3. the band grew to the Clean fixpoint: extent 567 + 2*12
    if (!aLane.agent) errs.push('spill: agent lane missing');
    else if (aLane.agent.height !== 591) errs.push(`spill: agent height ${aLane.agent.height}, expected 591 (extent 567 + 2*12 fixpoint)`);

    // 4. the lane that already contained its content is untouched
    if (aLane.framework && aLane.framework.height !== 200) errs.push(`spill: framework height ${aLane.framework.height}, expected 200 untouched — it already contained its members`);

    // 5. and now every node really does sit inside the lane it claims
    for (const n of a.nodes) {
      if (n.laneAtCentre !== n.lane) errs.push(`spill: ${n.uid} claims ${n.lane} but its centre falls in ${n.laneAtCentre}`);
    }

    // 6. the grow is REPORTED — a silent geometry change on load is the failure mode
    if (a.grown.length !== 1) errs.push(`spill: grow report has ${a.grown.length} entries, expected 1`);
    if (!a.notice.visible) errs.push('spill: no import notice shown for a grown band');
    if (!/grown, no nodes moved/.test(a.notice.text)) errs.push(`spill: notice does not say the band grew and nothing moved: ${JSON.stringify(a.notice.text)}`);
    if (!/\+331px/.test(a.notice.text)) errs.push(`spill: notice does not carry the growth amount (+331px): ${JSON.stringify(a.notice.text)}`);

    // 7. round-trip: the grown height is a real edit to the document, not a
    //    render-time fudge that silently reverts on save
    if (!/height="591"/.test(a.exported)) errs.push('spill: export does not carry the grown height 591 — the grow is not reaching the document');
    if (/height="260"/.test(a.exported)) errs.push('spill: export still carries the old under-declared height 260');

    // ── Fixture B: ordering-dirty — T-310's open-review fixture, must not move ─
    const b = await ev(cmd, PROBE('__SWAP__'));
    const bLane = Object.fromEntries(b.lanes.map(l => [l.id, l]));
    const bNode = Object.fromEntries(b.nodes.map(n => [n.uid, n]));

    // 8. T-310's behaviour is byte-identical: both conflicting nodes still moved
    if (b.reconciled !== 2) errs.push(`swap: reconcile count ${b.reconciled}, expected 2 — T-310's behaviour must be unchanged on the fixture under operator review`);

    // 9. the grow pass stood down entirely. This is the sharp one: the agent lane
    //    WOULD grow here (extent 254 vs declared 160) if the ordering gate were
    //    dropped, so it fails the moment the precondition is removed or inverted.
    if (b.grown.length !== 0) errs.push(`swap: ${b.grown.length} lane(s) grown on an ordering-dirty map — no set of heights can repair a swap; this must stand down`);
    for (const id of ['agent', 'framework']) {
      if (bLane[id] && bLane[id].height !== 160) errs.push(`swap: ${id} height ${bLane[id].height}, expected 160 unchanged`);
    }

    // 10. and the operator still reads exactly the T-310 sentence, with no grow clause
    if (!/2 nodes were drawn outside their declared lane/.test(b.notice.text)) errs.push(`swap: T-310 notice wording changed: ${JSON.stringify(b.notice.text)}`);
    if (/grown/.test(b.notice.text)) errs.push(`swap: notice mentions growing on a map where nothing grew: ${JSON.stringify(b.notice.text)}`);

    // 11. the reconciled nodes are still the two that disagreed
    // keyed by aef:uid, not by BPMN element id — displayIds are derived and
    // regenerate on import, so they cannot be compared across a round-trip
    for (const [uid, lane] of Object.entries({ n_start: 'agent', n_check: 'framework', n_act: 'agent', n_done: 'framework' })) {
      const n = bNode[uid];
      if (!n) { errs.push(`swap: node ${uid} missing after import`); continue; }
      if (n.lane !== lane) errs.push(`swap: ${uid} lane ${n.lane}, declared ${lane}`);
    }

    console.log(JSON.stringify({ ok: errs.length === 0, errs, spill: { reconciled: a.reconciled, agentHeight: aLane.agent && aLane.agent.height, grown: a.grown }, swap: { reconciled: b.reconciled, grown: b.grown.length } }, null, 2));
    process.exitCode = errs.length ? 1 : 0;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.message || e) }));
    process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill(); } catch (_) {}
    try { py.kill(); } catch (_) {}
  }
}
main();
