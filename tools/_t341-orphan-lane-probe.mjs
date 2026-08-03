#!/usr/bin/env node
// _t341-orphan-lane-probe.mjs — WHERE does an orphaned flow node land, and WHY?
//
// T-341 is filed as "an unresolvable flowNodeRef silently reassigns the orphaned
// node to the HUMAN (sovereignty) lane", and T-339 measured `framework→human` on 5
// of 24 corpus maps. But parseBpmnXml says
//
//     let laneId = lanes[0]?.id;
//
// which is POSITIONAL -- the first lane declared in the laneSet -- and `human` is
// first on only 13 of the 24 rendered maps (`agent` on 10, `working` on 1).
//
// Those are two different defects wearing the same measurement:
//
//   SEMANTIC  -- orphans go to the sovereignty lane. A stated, auditable policy
//                that happens to be the wrong one.
//   POSITIONAL-- orphans go to whichever lane is declared first. WHO owns the node
//                is then decided by declaration ORDER, which this project treats
//                elsewhere as adjustable presentation: the lane-geometry rule calls
//                reordering a laneSet a "zero-semantic repair".
//
// T-339's figure cannot separate them. Its mutation ghosts the FIRST
// <bpmn:flowNodeRef> in the document, which belongs to the first NON-EMPTY lane --
// so on a human-first map with an empty human lane it reads `framework→human`, and
// that reading is equally predicted by both hypotheses. A measurement consistent
// with both is evidence for neither.
//
// THE DISCRIMINATOR. Orphan a node that belongs to a lane OTHER than lanes[0], on
// maps whose first lane is NOT `human`. Then:
//
//     landed == firstLane  on every map, with firstLane VARYING  -> POSITIONAL
//     landed == 'human'    regardless of firstLane               -> SEMANTIC
//
// The variation is the whole experiment, so it is asserted: if every map in the
// population happens to be human-first, the probe cannot separate the hypotheses
// and says so instead of reporting a verdict it did not earn.
//
// Identity is carried by aef:uid, and the victim's uid is read from the ORIGINAL
// document -- never from the mutated one. T-341's own filing records that trap:
// baselining on the mutated input excludes the victim (its ref is the thing
// replaced), so the one node whose fate is the question is absent from the
// comparison set, and the probe reports 0 with confidence.
//
// Read-only: measures, decides nothing. The default-lane policy is an operator
// ruling (T-341 AC1).
//
// Usage: node tools/_t341-orphan-lane-probe.mjs [--json]
// Exit 0 = a verdict was earned; 1 = the population cannot discriminate; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = join(REPO, 'examples', 'aef-processes', 'rendered');
const SRC = process.env.T341_DESIGNER_SRC || join(REPO, 'src', 'aef-workflow-designer.html');
const JSON_OUT = process.argv.includes('--json');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const NODE_TAGS = 'serviceTask|userTask|scriptTask|startEvent|endEvent|exclusiveGateway'
  + '|parallelGateway|intermediateThrowEvent|intermediateCatchEvent|boundaryEvent|subProcess';

// [{ id, refs: [displayId, ...] }] in DECLARED order -- the order is the subject here.
function laneBlocks(xml) {
  const out = [];
  const re = /<bpmn:lane\b[^>]*\bid="([^"]*)"[\s\S]*?<\/bpmn:lane>/g;
  let g;
  while ((g = re.exec(xml))) out.push({ id: g[1], refs: [...g[0].matchAll(/<bpmn:flowNodeRef>([^<]*)<\/bpmn:flowNodeRef>/g)].map(m => m[1]) });
  return out;
}

// displayId -> uid, read off the node elements themselves.
function idToUid(xml) {
  const m = {};
  const re = new RegExp(`<bpmn:(${NODE_TAGS})\\b[^>]*\\bid="([^"]*)"[^>]*>([\\s\\S]*?)</bpmn:\\1>`, 'g');
  let g;
  while ((g = re.exec(xml))) { const u = g[3].match(/<aef:uid value="([^"]*)"/); if (u) m[g[2]] = u[1]; }
  return m;
}

// Which lane holds this uid, resolved through the display ids in each lane block.
function laneOfUid(xml, uid) {
  const map = idToUid(xml);
  for (const b of laneBlocks(xml)) for (const r of b.refs) if (map[r] === uid) return b.id;
  return null;
}

async function main() {
  if (!existsSync(CORPUS)) { console.log('FAIL: no corpus at ' + CORPUS); process.exitCode = 2; return; }
  const files = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!files.length) { console.log('FAIL: corpus empty'); process.exitCode = 2; return; }

  const doc = mkdtempSync(join(tmpdir(), 't341-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't341-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't341-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
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

    const roundTrip = async text => {
      await ev(cmd, `window.__X__ = ${JSON.stringify(text)};`);
      return await ev(cmd, `(function(){ try {
        state = parseBpmnXml(window.__X__); refreshDisplayIds();
        return { xml: buildBpmnXml(state) };
      } catch(e) { return { threw: String(e && e.message || e) }; } })()`);
    };

    const rows = [], skipped = [];
    for (const f of files) {
      const name = basename(f, '.bpmn');
      const text = readFileSync(join(CORPUS, f), 'utf8');
      const blocks = laneBlocks(text);
      if (blocks.length < 2) { skipped.push({ name, why: 'fewer than 2 lanes — no non-first lane to orphan from' }); continue; }
      const firstLane = blocks[0].id;

      // Victim must live in a lane OTHER than lanes[0]: orphaning a node already in
      // the first lane makes the fallback a no-op and the map says nothing.
      const donor = blocks.slice(1).find(b => b.refs.length);
      if (!donor) { skipped.push({ name, why: 'every non-first lane is empty' }); continue; }
      const victimDisplayId = donor.refs[0];

      // uid read from the ORIGINAL document (see header note on T-341 trap 2).
      const victimUid = idToUid(text)[victimDisplayId];
      if (!victimUid) { skipped.push({ name, why: `victim ${victimDisplayId} has no aef:uid — identity not resolvable` }); continue; }

      const mutated = text.replace(`<bpmn:flowNodeRef>${victimDisplayId}</bpmn:flowNodeRef>`,
                                   `<bpmn:flowNodeRef>__ghost__</bpmn:flowNodeRef>`);
      if (mutated === text) { skipped.push({ name, why: 'mutation did not land' }); continue; }

      const r = await roundTrip(mutated);
      if (r.threw) { skipped.push({ name, why: 'refused: ' + r.threw }); continue; }
      const landed = laneOfUid(r.xml, victimUid);
      rows.push({ map: name, firstLane, fromLane: donor.id, landed,
                  matchesFirst: landed === firstLane, matchesHuman: landed === 'human' });
    }

    // -- discrimination check, BEFORE any verdict --------------------------
    const firstLanes = [...new Set(rows.map(r => r.firstLane))].sort();
    const problems = [];
    if (rows.length === 0) problems.push('population is empty — nothing was probed');
    if (firstLanes.length < 2) problems.push(
      `every probed map declares '${firstLanes[0]}' first, so POSITIONAL and SEMANTIC predict the same result on all of them — this population cannot separate the hypotheses`);
    if (rows.some(r => r.landed === null)) problems.push('a victim uid was not found in any output lane — identity unresolvable, verdict withheld');

    const allFirst = rows.every(r => r.matchesFirst);
    const allHuman = rows.every(r => r.matchesHuman);
    const verdict = problems.length ? 'INDETERMINATE' : (allFirst && !allHuman) ? 'POSITIONAL'
                  : (allHuman && !allFirst) ? 'SEMANTIC' : allFirst && allHuman ? 'INDETERMINATE' : 'MIXED';

    if (JSON_OUT) { console.log(JSON.stringify({ verdict, rows, skipped, firstLanes, problems }, null, 2)); }
    else {
      console.log(`orphan-lane probe: ${rows.length} maps probed, ${skipped.length} skipped; first-lane values seen: ${firstLanes.join(', ') || '(none)'}`);
      for (const r of rows) console.log(`  ${r.map.padEnd(28)} first=${String(r.firstLane).padEnd(10)} orphaned-from=${String(r.fromLane).padEnd(10)} landed=${String(r.landed).padEnd(10)}${r.matchesFirst ? '  = first' : '  ≠ FIRST'}`);
      for (const s of skipped) console.log(`  SKIP ${s.name.padEnd(27)} ${s.why}`);
      console.log(`  landed in the FIRST declared lane: ${rows.filter(r => r.matchesFirst).length}/${rows.length}`);
      console.log(`  landed in the HUMAN lane:          ${rows.filter(r => r.matchesHuman).length}/${rows.length}`);
      for (const p of problems) console.log(`  PROBLEM: ${p}`);
      console.log(`VERDICT: ${verdict}`);
      if (verdict === 'POSITIONAL') console.log(
        '  The orphan destination is DECLARATION ORDER, not sovereignty. WHO owns an orphaned\n'
        + '  node is therefore decided by laneSet ordering — which W-XML-LANE-GEOMETRY calls a\n'
        + '  "zero-semantic repair". Those two beliefs cannot both be true. Operator ruling (T-341 AC1).');
    }
    process.exitCode = problems.length ? 1 : 0;
  } catch (e) {
    console.log('FAIL: ' + (e && e.message || e)); process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
  }
}
main();
