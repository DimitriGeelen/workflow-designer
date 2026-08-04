#!/usr/bin/env node
/**
 * _t358-empty-lanes-blast-radius.mjs — measure what the DOWNSTREAM consumers do when
 * the importer stops fabricating lanes. This is AC4 evidence, NOT the repair.
 *
 * The question this exists to answer: T-358's repair would leave `state.lanes = []`
 * for a lane-less input. Is that safe, or does it reverse into the opposite defect?
 *
 * Reading the source suggests it is NOT safe, for a reason worth measuring: the
 * fabrication sites are guarded by DIFFERENT PREDICATES.
 *
 *   importer  ~9705  `if (!lanes.length) lanes.push(...defaultLanes())`  -- emptiness
 *   emitter   ~9511  `const lanesToEmit = s.lanes || defaultLanes()`     -- nullishness
 *   getLanes  ~2087  `(state && state.lanes) ? state.lanes : ...`        -- nullishness
 *   addLane   ~8068  `if (!state.lanes) state.lanes = defaultLanes()`    -- nullishness
 *
 * `[]` is truthy. So an empty lane array flows through every downstream guard
 * untouched -- their defaults never fire -- and reaches an emitter that opens
 * `<bpmn:laneSet id="LaneSet_1">` unconditionally. If that is what happens, the
 * repaired importer would EMIT the empty-laneSet shape that our own partition
 * classifies as third-party cause (ii). We would produce the defect we detect.
 *
 * Method: mutate a TEMP COPY of src to neutralise the importer fabrication (the real
 * tree is never edited -- same discipline as _t358-teeth.py), then round-trip a
 * lane-less third-party fixture through the REAL importer and REAL emitter in
 * headless Chrome and read the actual bytes back.
 *
 * This prints a measurement and always exits 0 on a successful run. It is deliberately
 * NOT a pass/fail gate: no repair has been chosen yet, so there is no correct answer
 * to gate on. Exit 2 means the measurement itself failed to run.
 *
 * Usage: node tools/_t358-empty-lanes-blast-radius.mjs
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXDIR = join(REPO, 'tests', 'fixtures', 'lane-provenance');

// The exact fabrication site, anchored on its text (line numbers drift -- T-340's
// filed anchor already did).
const FABRICATION = "  if (!lanes.length) lanes.push(...defaultLanes());";
const NEUTRALISED = "  /* T-358 blast-radius probe: fabrication suppressed */";

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  const src = readFileSync(join(REPO, 'src/aef-workflow-designer.html'), 'utf8');
  if (!src.includes(FABRICATION)) {
    console.error('ERROR: fabrication anchor not found -- the site moved or was already repaired.');
    console.error('  wanted: ' + JSON.stringify(FABRICATION));
    return 2;
  }

  const doc = mkdtempSync(join(tmpdir(), 't358-br-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't358-br-repo-'));
  // Two builds served side by side: the tree as it stands, and the tree with the
  // fabrication suppressed. Comparing them is the whole measurement.
  writeFileSync(join(doc, 'current.html'), src);
  writeFileSync(join(doc, 'norepair.html'), src.replace(FABRICATION, NEUTRALISED));
  mkdirSync(join(doc, 'rendered'), { recursive: true });

  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't358-br-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl; const rows = [];
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');

    for (const build of ['current', 'norepair']) {
      await cmd('Page.navigate', { url: `${BASE}/${build}.html` });
      await waitReady(cmd); await sleep(300);

      for (const fx of ['no-laneset.bpmn', 'authored-lanes.bpmn']) {
        const xml = readFileSync(join(FIXDIR, fx), 'utf8');
        await ev(cmd, `window.__IN__ = ${JSON.stringify(xml)};`);
        // Round-trip through the REAL importer and the REAL emitter, then read the
        // emitted bytes back. Rendering is exercised too: a consumer that throws on
        // an empty lane array is exactly the "opposite defect" this probe looks for.
        const r = await ev(cmd, `(function(){
          var out = { render: 'not-attempted', renderError: null };
          try {
            var m = parseBpmnXml(window.__IN__);
            if (!m) return { fatal: 'parse returned null' };
            out.prov = m.laneProvenance;
            out.lanesIn = (m.lanes||[]).length;
            out.nodeCount = (m.nodes||[]).length;
            out.nodesWithNoLane = (m.nodes||[]).filter(function(n){ return !n.lane; }).length;
            var prev = state;
            state = m;
            try {
              var xml = buildBpmnXml(state);
              out.emittedLaneSetOpen = (xml.match(/<bpmn:laneSet\\b/g)||[]).length;
              out.emittedLaneEls    = (xml.match(/<bpmn:lane\\b/g)||[]).length;
              out.emittedFlowNodeRefs = (xml.match(/<bpmn:flowNodeRef>/g)||[]).length;
              out.emitsSovereignty  = /authority="sovereignty"/.test(xml);
              // Does our own importer read our own output back the same way?
              var m2 = parseBpmnXml(xml);
              out.reimportProv  = m2 ? m2.laneProvenance : 'reparse-failed';
              out.reimportLanes = m2 ? (m2.lanes||[]).length : -1;
            } catch (e) { out.emitError = String(e && e.message || e); }
            // The entrypoint is renderAll(), not render(). Named explicitly and
            // asserted present: an earlier version of this probe tested
            // \`typeof render === 'function'\`, which is always false here, so the
            // render leg reported 'not-attempted' on every row -- a check that
            // cannot fire is a constant, and a constant measures nothing.
            if (typeof renderAll !== 'function') { out.render = 'PROBE-BROKEN: renderAll absent'; }
            else {
              try { renderAll(); out.render = 'ok'; }
              catch (e) { out.render = 'THREW'; out.renderError = String(e && e.message || e); }
            }
            state = prev;
          } catch (e) { out.fatal = String(e && e.message || e); }
          return out;
        })()`);
        rows.push({ build, fx, ...r });
      }
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  console.log('\nT-358 AC4 — what the consumers do when the importer stops fabricating');
  console.log('(measurement only; no repair is chosen here)\n');
  for (const r of rows) {
    console.log(`  ${r.build.padEnd(9)} ${r.fx.padEnd(22)}`);
    if (r.fatal) { console.log(`      FATAL: ${r.fatal}`); continue; }
    console.log(`      provenance=${r.prov}  lanes_in_state=${r.lanesIn}  nodes=${r.nodeCount}  nodes_with_no_lane=${r.nodesWithNoLane}`);
    console.log(`      emitted: laneSet=${r.emittedLaneSetOpen}  lane=${r.emittedLaneEls}  flowNodeRef=${r.emittedFlowNodeRefs}  asserts_sovereignty=${r.emitsSovereignty}`);
    console.log(`      re-import of our own output: provenance=${r.reimportProv}  lanes=${r.reimportLanes}`);
    if (r.emitError) console.log(`      EMIT THREW: ${r.emitError}`);
    console.log(`      render=${r.render}${r.renderError ? ' -- ' + r.renderError : ''}`);
  }

  // The finding, stated as a derived claim so it cannot be read off vibes.
  const nr = rows.find(r => r.build === 'norepair' && r.fx === 'no-laneset.bpmn');
  console.log('\n  --- derived ---');
  if (nr && !nr.fatal) {
    const emptyLaneSet = nr.emittedLaneSetOpen > 0 && nr.emittedLaneEls === 0;
    console.log(`  suppressing the importer default leaves lanes=[] in state: ${nr.lanesIn === 0}`);
    console.log(`  ...and the emitter still opens a laneSet with zero lane children: ${emptyLaneSet}`);
    if (emptyLaneSet) {
      console.log('  => WE WOULD EMIT cause (ii) "empty laneSet" -- the exact shape our own');
      console.log('     partition classifies as a third-party defect. AC4 fires: the naive');
      console.log('     repair reverses into the opposite defect.');
    }
    console.log(`  round-trip stability: our own output re-imports as ${nr.reimportProv}`);
  }

  // The finding this probe was NOT written to look for, which is why it is stated
  // as its own derived claim rather than left for a reader to notice.
  const cur = rows.find(r => r.build === 'current' && r.fx === 'no-laneset.bpmn');
  if (cur && !cur.fatal) {
    const laundered = String(cur.prov).startsWith('defaulted:') && cur.reimportProv === 'authored';
    console.log(`\n  laundering: import says ${cur.prov}; our own emitted output re-imports as ${cur.reimportProv}`);
    if (laundered) {
      console.log('  => THE FABRICATION LAUNDERS ITSELF IN ONE ROUND-TRIP. laneProvenance is a');
      console.log('     PARSE-time property, not a DOCUMENT property. Open a third-party file,');
      console.log('     save it, reopen it: the second open reports `authored`, with');
      console.log(`     authority="sovereignty" in the bytes (emitted this run: ${cur.emitsSovereignty}).`);
      console.log('     Saving is exactly what makes the assertion the document, so the signal');
      console.log('     dies at the moment it would matter. Any repair must therefore act at or');
      console.log('     before the FIRST save -- a report-only remedy cannot reach the corpus.');
    }
  }
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
