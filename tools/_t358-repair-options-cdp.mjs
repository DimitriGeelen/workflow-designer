#!/usr/bin/env node
/**
 * _t358-repair-options-cdp.mjs — MEASURE the candidate repairs instead of describing
 * them, so the operator's T-341/T-358 ruling is a choice between observed outcomes.
 *
 * This does NOT repair anything. Each candidate is applied to a TEMP COPY of the
 * source (the real tree is never edited — same discipline as _t358-teeth.py) and the
 * result is round-tripped through the REAL importer and REAL emitter in headless
 * Chrome. What it reports per candidate:
 *
 *   fabricates?      does a lane-less input still gain the 3-lane Authority Model
 *   asserts?         does `authority="sovereignty"` reach the emitted bytes
 *   survives_save?   does the provenance signal still exist after one round-trip
 *                    (the F2 defect: today the answer is NO — our own output
 *                     re-imports as `authored`)
 *   emits_empty_ls?  do we emit `<bpmn:laneSet>` with zero lanes, i.e. the shape our
 *                    own partition classifies as third-party cause (ii)
 *   corpus_bytes     are the emitted bytes for an existing designer map UNCHANGED
 *                    vs the current build — AC5 in miniature, run per candidate
 *
 * The corpus regression is the one that disqualifies quietly, so it is measured for
 * every candidate rather than argued about for any.
 *
 * Usage: node tools/_t358-repair-options-cdp.mjs
 * Exit 0 = every candidate applied and was measured. Exit 2 = a candidate's anchor
 * was not found (the source moved) or the harness failed — never a silent skip.
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXDIR = join(REPO, 'tests', 'fixtures', 'lane-provenance');
const CORPUS = join(REPO, 'examples', 'aef-processes', 'rendered', 'audit-process.bpmn');

// ---- anchors in the current source. Missing anchor => exit 2, never a silent skip.
const A_IMPORT_FAB = "  if (!lanes.length) lanes.push(...defaultLanes());";
const A_EMIT_OPEN  = "  lines.push(`    <bpmn:laneSet id=\"LaneSet_1\">`);\n  const lanesToEmit = s.lanes || defaultLanes();";
const A_EMIT_CLOSE = "  lines.push(`    </bpmn:laneSet>`);";
const A_WM_EMIT    = "  lines.push(`      <aef:workflowMeta ${wmAttrs.join(' ')}/>`);";
const A_WM_READ    = "  const aefMetaEl = byAef(proc, 'workflowMeta')[0];";

/**
 * Candidate repairs. Each is a list of [anchor, replacement] pairs.
 *
 * A — DROP: stop fabricating, and stop emitting a laneSet we have no lanes for.
 *     Both halves are required: dropping only the importer half leaves `[]` flowing
 *     through the emitter's nullish guard and emits cause (ii). That is F1.
 *
 * B — MARK: keep fabricating, but write the provenance into the DOCUMENT and read it
 *     back, so the signal survives the save. Targets F2 specifically. Note this fixes
 *     the *legibility* of the fabrication, not the fabrication.
 *
 * C — NEUTRAL: keep a default so downstream lane consumers always have one, but stop
 *     asserting the Authority Model. One lane, authority 'unassigned'.
 *
 * AB — A plus B's marking, for the paths that still default (T-341 orphans).
 */
const CANDIDATES = {
  'current (no repair)': [],

  'A · drop (importer + emitter)': [
    [A_IMPORT_FAB, "  /* T-358 candidate A: no fabrication */"],
    [A_EMIT_OPEN,
      "  const lanesToEmit = s.lanes || defaultLanes();\n" +
      "  if (lanesToEmit.length) lines.push(`    <bpmn:laneSet id=\"LaneSet_1\">`);"],
    [A_EMIT_CLOSE, "  if (lanesToEmit.length) lines.push(`    </bpmn:laneSet>`);"],
  ],

  'B · mark (provenance into the doc)': [
    [A_WM_EMIT,
      "  if (s.laneProvenance && s.laneProvenance !== 'authored') wmAttrs.push(`laneProvenance=\"${escAttr(s.laneProvenance)}\"`);\n" +
      A_WM_EMIT],
    // read it back, so provenance becomes a property of the document, not of the parse
    [A_WM_READ,
      A_WM_READ + "\n  const _carriedProv = aefMetaEl && aefMetaEl.getAttribute('laneProvenance');"],
    ["    laneProvenance,", "    laneProvenance: _carriedProv || laneProvenance,"],
  ],

  'C · neutral default (no Authority Model)': [
    [A_IMPORT_FAB,
      "  if (!lanes.length) lanes.push({ id: 'unassigned', name: 'Unassigned', abbr: 'una', authority: 'unassigned', height: 130 });"],
  ],

  'AB · drop + mark': [
    [A_IMPORT_FAB, "  /* T-358 candidate AB: no fabrication */"],
    [A_EMIT_OPEN,
      "  const lanesToEmit = s.lanes || defaultLanes();\n" +
      "  if (lanesToEmit.length) lines.push(`    <bpmn:laneSet id=\"LaneSet_1\">`);"],
    [A_EMIT_CLOSE, "  if (lanesToEmit.length) lines.push(`    </bpmn:laneSet>`);"],
    [A_WM_EMIT,
      "  if (s.laneProvenance && s.laneProvenance !== 'authored') wmAttrs.push(`laneProvenance=\"${escAttr(s.laneProvenance)}\"`);\n" +
      A_WM_EMIT],
    [A_WM_READ,
      A_WM_READ + "\n  const _carriedProv = aefMetaEl && aefMetaEl.getAttribute('laneProvenance');"],
    ["    laneProvenance,", "    laneProvenance: _carriedProv || laneProvenance,"],
  ],
};

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Round-trip one document and report everything the ruling needs from it.
const PROBE = `(function(){
  var out = {};
  try {
    var m = parseBpmnXml(window.__IN__);
    if (!m) return { fatal: 'parse returned null' };
    out.prov = m.laneProvenance;
    out.lanes = (m.lanes||[]).length;
    var prev = state; state = m;
    try {
      var xml = buildBpmnXml(state);
      out.sha = xml.length + ':' + (function(s){var h=0;for(var i=0;i<s.length;i++){h=((h<<5)-h+s.charCodeAt(i))|0;}return h;})(xml);
      out.laneSetOpen = (xml.match(/<bpmn:laneSet\\b/g)||[]).length;
      out.laneEls     = (xml.match(/<bpmn:lane\\b/g)||[]).length;
      out.sovereignty = /authority="sovereignty"/.test(xml);
      var m2 = parseBpmnXml(xml);
      out.reProv = m2 ? m2.laneProvenance : 'reparse-failed';
    } catch (e) { out.emitError = String(e && e.message || e); }
    try { if (typeof renderAll === 'function') { renderAll(); out.render = 'ok'; } else out.render = 'PROBE-BROKEN'; }
    catch (e) { out.render = 'THREW: ' + String(e && e.message || e); }
    state = prev;
  } catch (e) { out.fatal = String(e && e.message || e); }
  return out;
})()`;

async function main() {
  const src = readFileSync(join(REPO, 'src/aef-workflow-designer.html'), 'utf8');
  if (!existsSync(CORPUS)) { console.error('ERROR: corpus regression map missing: ' + CORPUS); return 2; }

  const doc = mkdtempSync(join(tmpdir(), 't358-ro-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't358-ro-repo-'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });

  const names = Object.keys(CANDIDATES);
  const slug = n => 'b' + names.indexOf(n);
  for (const n of names) {
    let s = src;
    for (const [anchor, repl] of CANDIDATES[n]) {
      if (!s.includes(anchor)) {
        console.error(`ERROR: candidate ${JSON.stringify(n)} — anchor not found in source:`);
        console.error('  ' + JSON.stringify(anchor.slice(0, 90)));
        return 2;
      }
      s = s.replace(anchor, repl);
    }
    writeFileSync(join(doc, slug(n) + '.html'), s);
  }

  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't358-ro-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  const DOCS = [
    ['lane-less (the defect)', readFileSync(join(FIXDIR, 'no-laneset.bpmn'), 'utf8')],
    ['authored (control)',     readFileSync(join(FIXDIR, 'authored-lanes.bpmn'), 'utf8')],
    ['corpus map (regression)', readFileSync(CORPUS, 'utf8')],
  ];

  let cl; const table = {};
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');

    for (const n of names) {
      await cmd('Page.navigate', { url: `${BASE}/${slug(n)}.html` });
      await waitReady(cmd); await sleep(250);
      table[n] = {};
      for (const [label, xml] of DOCS) {
        await ev(cmd, `window.__IN__ = ${JSON.stringify(xml)};`);
        table[n][label] = await ev(cmd, PROBE);
        // Instrument self-check: emit the SAME document twice in the SAME build. A
        // cross-build byte comparison is meaningless unless a build is byte-stable
        // with itself, and the first version of this probe reported four spurious
        // "output changed" notes because it never asked.
        const again = await ev(cmd, PROBE);
        table[n][label].selfStable = again.sha === table[n][label].sha;
      }
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  const base = table[names[0]];
  console.log('\nT-358 — candidate repairs, MEASURED (no repair is applied to the tree)\n');
  const hdr = ['candidate', 'fabricates', 'asserts_sov', 'survives_save', 'emits_empty_ls', 'corpus_bytes', 'render'];
  console.log('  ' + hdr[0].padEnd(38) + hdr.slice(1).map(h => h.padEnd(15)).join(''));
  console.log('  ' + '-'.repeat(38 + 15 * 6));
  for (const n of names) {
    const d = table[n]['lane-less (the defect)'];
    const c = table[n]['corpus map (regression)'];
    const ctl = table[n]['authored (control)'];
    if (d.fatal || c.fatal) { console.log(`  ${n.padEnd(38)}FATAL ${d.fatal || c.fatal}`); continue; }
    const fabricates   = d.lanes > 0;
    const survives     = String(d.prov).startsWith('defaulted:') ? (String(d.reProv).startsWith('defaulted:') ? 'YES' : 'no') : 'n/a';
    const emptyLs      = d.laneSetOpen > 0 && d.laneEls === 0;
    // A byte comparison is only evidence where the build is byte-stable with itself.
    // Where it is not, say so — do not print a verdict the instrument cannot support.
    const corpusSame = !c.selfStable || !base['corpus map (regression)'].selfStable
      ? 'unstable' : (c.sha === base['corpus map (regression)'].sha ? 'identical' : 'CHANGED');
    const ctlSame = !ctl.selfStable || !base['authored (control)'].selfStable
      ? null : (ctl.sha === base['authored (control)'].sha);
    console.log('  ' + n.padEnd(38)
      + String(fabricates ? `yes (${d.lanes})` : 'no').padEnd(15)
      + String(d.sovereignty).padEnd(15)
      + survives.padEnd(15)
      + String(emptyLs ? 'YES' : 'no').padEnd(15)
      + corpusSame.padEnd(15)
      + String(d.render));
    if (ctlSame === false) console.log(`      ^ NOTE: this candidate also changed the AUTHORED control's output — it is not confined to the defaulted path`);
    if (ctlSame === null)  console.log(`      ^ control byte-comparison VOID: the build is not byte-stable with itself on this document`);
  }

  console.log('\n  legend');
  console.log('   fabricates      lanes present in state for an input that had none');
  console.log('   asserts_sov     authority="sovereignty" reaches the emitted bytes');
  console.log('   survives_save   provenance still says "defaulted:*" after one round-trip (F2)');
  console.log('   emits_empty_ls  we emit <bpmn:laneSet> with zero lanes = our own cause (ii) (F1)');
  console.log('   corpus_bytes    emitted bytes for an existing designer map vs the current build');
  console.log('\n  No candidate is selected here. Default choice is the operator\'s (T-341).');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
