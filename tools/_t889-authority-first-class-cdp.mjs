#!/usr/bin/env node
// T-889 AC 1 — `authority` is a FIRST-CLASS editor meta-key, not T-570 carriage.
//
// WHY A SEPARATE SCRIPT. The two static halves of AC 1 (metaKeys 20->21, and the panel
// offering the writer via AEF_FIELDS) are already checked by _t889-authority-on-the-element-teeth.sh
// legs C5/C6. They are NOT what the AC asks for. Subset-parity with the bridge, and any check
// that reads the emitter source, pass identically under carriage — carriage can re-emit a key
// the SOURCE DOCUMENT already carried. The only outcome carriage cannot produce is an export
// that carries `aef:meta authority=` for a node whose source document carried none. That
// requires driving the editor: load an authority-free document, set the value THROUGH THE PANEL,
// export, and look.
//
// Rounds 2 and 3 left this AC open citing the round-trip harness's `SRC_HTML` not being
// overridable. That blocker is real for REUSING that harness, whose guard legs read the source
// file. It is not a blocker on the proof: the harness itself serves a COPY of the designer out of
// a temp docroot (_roundtrip-serialization-cdp.mjs:740), so a standalone driver needs to override
// nothing. This script is that driver, built on the same sidecar + CDP plumbing.
//
// THE PROOF IS A DIFFERENTIAL, not a green. L2 and L3 parse the SAME document with the SAME code
// path and differ only in whether the panel interaction happened. A bare "export contains
// authority" would be satisfied by a document that already carried one, by a lane default
// bleeding onto the element, or by an emitter that stamps every node — so each of those is
// excluded by its own leg rather than by argument:
//
//   L1  SOURCE PRECONDITION  fixture has 0 element-level `aef:meta ... authority=`.
//                            (It has 3 LANE-level ones; those must not count, and L4 uses them.)
//   L2  CARRIAGE CONTROL     parse -> emit with NO interaction  => still 0 element-level.
//                            This is what carriage alone yields. Without it L3 proves nothing.
//   L3  THE AC               parse -> select node -> set panel Authority -> emit => the node's
//                            own element carries authority.
//   L4  NOT LANE INHERITANCE the value set is `external`, which NO lane in this document carries
//                            (lanes are sovereignty/authority/initiative) and is not the `none`
//                            import default. So the exported value cannot be explained by
//                            inheritance or by a default.
//   L5  SETUP CONTROL        the panel must actually have rendered an Authority <select> for the
//                            selected node, and the write must have gone through its `change`
//                            listener. If the select is absent we report SETUP BROKEN rather
//                            than reading a model poke as a panel proof (T-866 pattern).
//
// Exit 0 = all legs pass. Exit 2 = a leg failed or setup broke.

import { readFileSync, existsSync, readdirSync, mkdtempSync, copyFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXTURE = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 's4-exemplar.bpmn');
const SET_VALUE = 'external';
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&typeof renderProperties==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Count ELEMENT-level authority only. `aef:laneMeta ... authority=` must not be counted: the
// fixture carries 3 of them and they are the control in L4, not the subject.
function countElementAuthority(xml) {
  const m = xml.match(/<aef:meta\b[^>]*\bauthority="[^"]*"/g) || [];
  return m.length;
}
function elementAuthorityValues(xml) {
  return (xml.match(/<aef:meta\b[^>]*\bauthority="([^"]*)"/g) || [])
    .map(s => (s.match(/\bauthority="([^"]*)"/) || [])[1]);
}
function laneAuthorityValues(xml) {
  return (xml.match(/<aef:laneMeta\b[^>]*\bauthority="([^"]*)"/g) || [])
    .map(s => (s.match(/\bauthority="([^"]*)"/) || [])[1]);
}

const legs = [];
function leg(id, name, ok, detail) { legs.push({ id, name, ok, detail }); }

// Driven entirely in the page. Returns the model facts plus both exports so every leg is
// decided on OBSERVED bytes rather than on the page's own opinion of success.
const DRIVE_EXPR = `(() => {
  const out = { ok: false };
  try {
    // ---- L2: carriage control. Import and emit with NO interaction whatsoever. ----
    const m1 = parseBpmnXml(window.__FIXTURE__);
    if (!m1) return { ok: false, reason: 'parse1-null' };
    state = m1; refreshDisplayIds();
    out.exportUntouched = buildBpmnXml(state);

    // ---- pick a task-like node: the types AEF_FIELDS offers 'authority' on ----
    const TASKLIKE = ['serviceTask', 'userTask', 'scriptTask'];
    const n = (state.nodes || []).find(x => TASKLIKE.indexOf(x.type) >= 0);
    if (!n) return { ok: false, reason: 'no-tasklike-node' };
    // The emitter writes id="displayIdOf(n)" (src:10521/10526), NOT n.id. Measured the hard way:
    // confining the leg by n.id matched NOTHING, and an empty block counts 0 authority — a FALSE
    // FAIL that reads exactly like the feature being absent. Ask the emitter for the id it uses.
    out.node = { id: n.id, uid: n.uid, type: n.type, lane: n.lane, displayId: displayIdOf(n) };
    // the node's OWN authority before we touch anything — must be absent for the AC to mean
    // what it says.
    out.authorityBefore = (n.aef && n.aef.authority) || null;
    // the lane this node sits in, and that lane's authority: L4's inheritance control.
    const ln = (state.lanes || []).find(l => l.id === n.lane);
    out.laneAuthority = ln ? ((ln.authority !== undefined) ? ln.authority : null) : null;

    // ---- L5 + L3: drive the REAL panel ----
    selection = { kind: 'node', id: n.id };
    renderProperties();
    const fields = Array.from(document.querySelectorAll('#properties .field'));
    const wrap = fields.find(w => {
      const l = w.querySelector('.field-label');
      return l && l.textContent.trim().toLowerCase().indexOf('authority') === 0;
    });
    if (!wrap) return { ok: false, reason: 'SETUP-BROKEN: no Authority field rendered in panel for ' + n.type };
    const sel = wrap.querySelector('select');
    if (!sel) return { ok: false, reason: 'SETUP-BROKEN: Authority field is not a <select>' };
    out.optionsOffered = Array.from(sel.options).map(o => o.value);
    if (out.optionsOffered.indexOf(${JSON.stringify(SET_VALUE)}) < 0) {
      return { ok: false, reason: 'SETUP-BROKEN: panel does not offer ' + ${JSON.stringify(SET_VALUE)} };
    }
    out.selectValueBefore = sel.value;
    // Write through the panel's own change listener — NOT by assigning n.aef.authority.
    sel.value = ${JSON.stringify(SET_VALUE)};
    sel.dispatchEvent(new Event('change', { bubbles: true }));
    out.modelAfter = (state.nodes.find(x => x.id === n.id).aef || {}).authority || null;

    out.exportAfter = buildBpmnXml(state);
    out.ok = true;
    return out;
  } catch (e) { return { ok: false, reason: 'threw: ' + (e && e.message) }; }
})()`;

(async () => {
  if (!existsSync(FIXTURE)) { console.error(`fixture missing: ${FIXTURE}`); process.exit(2); }
  const src = readFileSync(FIXTURE, 'utf8');

  // L1 is decided on the FIXTURE FILE, before any browser exists.
  const srcElem = countElementAuthority(src);
  const srcLane = laneAuthorityValues(src);
  leg('L1', 'source document carries NO element-level authority',
      srcElem === 0,
      `element-level=${srcElem} (want 0); lane-level=${srcLane.length} [${srcLane.join(',')}] (not counted)`);
  if (srcElem !== 0) {
    console.error('L1 failed — the fixture already carries element-level authority, so nothing below can distinguish carriage from a first-class key.');
    report(); process.exit(2);
  }

  const doc = mkdtempSync(join(tmpdir(), 't889-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't889-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't889-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(src)};`);
    const r = await ev(cmd, DRIVE_EXPR);
    if (!r || !r.ok) {
      console.error(`DRIVE FAILED: ${r && r.reason}`);
      leg('L3', 'panel-driven set + export', false, String(r && r.reason));
      report(); process.exit(2);
    }

    // ---- L5: setup control ----
    leg('L5', 'panel rendered an Authority <select> and the write went through its change listener',
        r.modelAfter === SET_VALUE,
        `node=${r.node.id} (${r.node.type}); options=[${(r.optionsOffered || []).join(',')}]; select before="${r.selectValueBefore}"; model after change="${r.modelAfter}"`);

    // ---- L2: carriage control ----
    const untouched = countElementAuthority(r.exportUntouched);
    leg('L2', 'CARRIAGE CONTROL: import+export with no interaction yields NO element authority',
        untouched === 0,
        `element-level in untouched export=${untouched} (want 0)`);

    // ---- L3: the AC ----
    const afterVals = elementAuthorityValues(r.exportAfter);
    const afterCount = afterVals.length;
    // Confine to the node we actually edited: the attribute must sit inside THAT element.
    const nodeElemRe = new RegExp(`<(?:bpmn:)?${r.node.type}\\b[^>]*\\bid="${r.node.displayId}"[\\s\\S]*?</(?:bpmn:)?${r.node.type}>`);
    const nodeBlock = (r.exportAfter.match(nodeElemRe) || [])[0] || '';
    // CONTROL ON THE CONTROL: an empty block counts 0 and is indistinguishable from the feature
    // being absent. Require the block to have actually matched before reading a count off it.
    if (!nodeBlock) {
      leg('L3', 'THE AC: export carries aef:meta authority= on the edited node, from a source that had none',
          false, `SETUP BROKEN: no <${r.node.type} id="${r.node.displayId}"> block found in the export — the leg cannot be decided, it did not fail`);
    }
    const onOurNode = countElementAuthority(nodeBlock);
    if (nodeBlock) leg('L3', 'THE AC: export carries aef:meta authority= on the edited node, from a source that had none',
        onOurNode === 1 && afterCount === 1,
        `on edited node <${r.node.type} id="${r.node.displayId}">=${onOurNode} (want 1); document-wide element-level=${afterCount} (want 1 — only the node we edited)`);

    // ---- L4: not lane inheritance, not a default ----
    const exportedVal = elementAuthorityValues(nodeBlock)[0] || null;
    const laneVals = laneAuthorityValues(r.exportAfter);
    const notInherited = exportedVal === SET_VALUE && laneVals.indexOf(SET_VALUE) < 0;
    leg('L4', `NOT LANE INHERITANCE: exported value is the one set ("${SET_VALUE}"), which no lane carries`,
        notInherited,
        `exported="${exportedVal}"; node's own lane ${r.node.lane} authority="${r.laneAuthority}"; lanes in export=[${laneVals.join(',')}]; node authority before edit=${JSON.stringify(r.authorityBefore)}`);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill(); } catch (_) {}
    try { py.kill(); } catch (_) {}
  }
  report();
  process.exit(legs.every(l => l.ok) ? 0 : 2);
})().catch(e => { console.error('HARNESS ERROR: ' + (e && e.stack || e)); report(); process.exit(2); });

function report() {
  console.log('\n── T-889 AC 1: authority is a first-class editor meta-key (panel-driven) ──');
  for (const l of legs) console.log(`  ${l.ok ? 'PASS' : 'FAIL'}  ${l.id}  ${l.name}\n        ${l.detail}`);
  const pass = legs.filter(l => l.ok).length;
  console.log(`\n  ${pass}/${legs.length} legs passed`);
  if (legs.length && legs.every(l => l.ok)) {
    console.log('  DIFFERENTIAL: L2 (no interaction) = 0 element-level authority; L3 (panel interaction) = 1.');
    console.log('  Same document, same emitter, same code path. Carriage cannot produce that delta.');
  }
}
