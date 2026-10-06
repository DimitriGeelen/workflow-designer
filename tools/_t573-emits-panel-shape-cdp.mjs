#!/usr/bin/env node
// _t573-emits-panel-shape-cdp.mjs — the Emits panel field authors the RATIFIED shape.
//
// THE DEFECT. FIELD_META.emits had no special handler, so the inspector's Emits box wrote a
// STRING into n.aef.emits. buildBpmnXml's structured exporter fires on
// Array.isArray(aef.emits), so an authored value fell through it silently and
// <aef:emits><aef:emit value="…"/></aef:emits> — the form tools/yaml-to-bpmn.py and
// tests/test_editor_bridge_structured_parity.py agree on — was UNREACHABLE FROM THE PANEL.
// T-570 made the string survive (as <aef:meta emits="…"/>), so the DATA was safe and the
// SHAPE was still wrong. That smaller, different defect is what this closes.
//
// WHY IT DRIVES THE REAL INPUT ELEMENT. The AC says "proven in the page, reading the
// exported XML — not by reading the handler". Calling the callback directly would pass on a
// build where the panel never renders the field at all, which is the F-11 defect (an
// authored value nobody can reach) one level up. So every mutating leg finds the input by
// its rendered LABEL, sets .value, and dispatches a real 'input' event.
//
// LEG 2 IS THE CONTROL ARM AND IT IS NOT OPTIONAL. "the structured element is present after
// the fix" is also what a probe asserting nothing produces. Leg 2 reproduces the PRE-fix
// write inside the page — the literal `n.aef[f] = v` this task replaced — and requires it to
// produce NO structured element. Without it a fixture that happened to arrive structured
// would report the same green (T-560's lesson).
//
// Each mutating leg RELOADS the page, so no leg observes state a previous leg mutated.
//
// --src <path> runs against an alternate editor build. Exit 0 = all legs pass, 1 = a leg
// failed, 2 = misconfigured (NOT a pass).
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const argi = process.argv.indexOf('--src');
const EDITOR = argi > -1 ? process.argv[argi + 1] : join(REPO, 'src', 'aef-workflow-designer.html');

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; for (const x of ['/usr/bin/chromium', '/usr/bin/google-chrome']) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 20000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
// T-1060: 'ready' includes the ?load= map having been ADOPTED (_loadSrcKey set). _appReady flips at
// the end of Init, but the deep-link fetch is async and lands later; a fixed sleep after it lost that
// race on a busy host ('fixture node absent', counted as a failed guard).
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true&&(!new URLSearchParams(location.search).get('load')||_loadSrcKey!=null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 25000) throw new Error('editor not ready'); await sleep(150); } }

// E1 carries a SCALAR emits — the shape tests/fixtures/valid/investigate.bpmn and the
// editor's own seed template use, and the shape Array.isArray silently skips.
// S1 carries the STRUCTURED form already, so the clear leg has something real to clear and
// the "two channels stay disjoint" claim has both arms present in one document.
const FIXTURE = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:aef="http://anchorpoint.framework/aef/extensions" id="d1" targetNamespace="http://x">
  <bpmn:process id="Process_t573" isExecutable="false">
    <bpmn:endEvent id="E1" name="ScalarDone">
      <bpmn:extensionElements>
        <aef:uid value="u-t573-scalar"/>
        <aef:position x="200.0" y="140.0"/>
        <aef:meta emits="event:probe.ready"/>
      </bpmn:extensionElements>
    </bpmn:endEvent>
    <bpmn:endEvent id="S1" name="StructDone">
      <bpmn:extensionElements>
        <aef:uid value="u-t573-struct"/>
        <aef:position x="400.0" y="140.0"/>
        <aef:meta tier="2"/>
        <aef:emits><aef:emit value="event:one"/><aef:emit value="event:two"/></aef:emits>
      </bpmn:extensionElements>
    </bpmn:endEvent>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="Di_1"><bpmndi:BPMNPlane id="Pl_1" bpmnElement="Process_t573">
    <bpmndi:BPMNShape id="S_E1" bpmnElement="E1"><dc:Bounds x="200" y="140" width="36" height="36"/></bpmndi:BPMNShape>
    <bpmndi:BPMNShape id="S_S1" bpmnElement="S1"><dc:Bounds x="400" y="140" width="36" height="36"/></bpmndi:BPMNShape>
  </bpmndi:BPMNPlane></bpmndi:BPMNDiagram>
</bpmn:definitions>`;

// Select a node by uid, render the panel, and TYPE into the field whose rendered label is
// `label`. Returns what the export looks like afterwards, plus enough state to tell a
// missing field from an unwritten one — "no structured element" and "no Emits box at all"
// are different failures and must not read the same.
const drive = (uid, label, text, preFix) => `(function(){
  var n = (state.nodes||[]).find(function(x){ return x.uid===${JSON.stringify(uid)}; });
  if (!n) return { err: 'fixture node absent: ' + ${JSON.stringify(uid)} };
  selection = n; renderProperties();
  var inp = null;
  var fields = document.querySelectorAll('#properties .field');
  for (var i=0;i<fields.length;i++){
    var lb = fields[i].querySelector('.field-label');
    if (lb && lb.textContent.indexOf(${JSON.stringify(label)}) === 0) {
      inp = fields[i].querySelector('input, textarea'); break;
    }
  }
  if (!inp) return { err: 'no rendered field labelled ' + ${JSON.stringify(label)} + ' (F-11: the value is unreachable in the panel)' };
  var before = buildBpmnXml(state);
  ${preFix ? `
  // THE PRE-FIX WRITE, reproduced verbatim: the plain field() path assigned the raw string.
  n.aef.emits = ${JSON.stringify(text)};
  ` : `
  inp.value = ${JSON.stringify(text)};
  inp.dispatchEvent(new Event('input', { bubbles: true }));
  `}
  var after = buildBpmnXml(state);
  var stored = n.aef.emits;
  return {
    before: before, after: after, unchanged: before === after,
    storedIsArray: Array.isArray(stored),
    stored: stored === undefined ? '<<absent>>' : JSON.stringify(stored),
    hint: (function(){ var lb=null; for (var i=0;i<fields.length;i++){ var l=fields[i].querySelector('.field-label'); if (l && l.textContent.indexOf(${JSON.stringify(label)})===0) lb=l; } return lb ? lb.textContent : ''; })(),
    shownValue: inp.value
  };
})()`;

// Does THIS node's serialised form carry emits, and through which channel? Scoped to the
// node's own element span so a sibling's structured element cannot answer for it.
//
// SCOPED BY aef:uid, NOT BY THE BPMN id. The first version of this helper looked for
// id="E1" and found nothing, failing four legs whose implementation was already correct —
// the export writes the DISPLAY id (displayIdOf), which the editor re-derives, so the
// fixture's own ids do not survive into the bytes. uid is the identity that does (T-224).
// Recorded rather than quietly fixed: a probe that cannot find its subject reports the same
// shape as a broken feature, which is the costlier of the two confusions.
function channels(xml, uid) {
  const parts = xml.split(/(?=<bpmn:(?:endEvent|startEvent|serviceTask|userTask|scriptTask|task|subProcess|exclusiveGateway|parallelGateway|intermediateCatchEvent|intermediateThrowEvent)\b)/);
  const span = parts.find(p => p.includes(`value="${uid}"`));
  if (!span) return { err: `node ${uid} absent from export` };
  const items = [...span.matchAll(/<aef:emit value="([^"]*)"\/>/g)].map(m => m[1]);
  return {
    structured: span.includes('<aef:emits>'),
    items,
    metaAttr: /<aef:meta[^>]*\semits="/.test(span),
  };
}

async function main() {
  const out = [];
  let npass = 0, nfail = 0;
  const report = (ok, name, detail) => { ok ? npass++ : nfail++; out.push(`${ok ? 'PASS' : 'FAIL'}  ${name} — ${detail}`); };

  if (!existsSync(EDITOR)) { console.log('CANNOT RUN: editor missing: ' + EDITOR); return 2; }
  if (!existsSync(SERVER)) { console.log('CANNOT RUN: server missing: ' + SERVER); return 2; }

  const doc = mkdtempSync(join(tmpdir(), 't573-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't573-repo-'));
  const udd = mkdtempSync(join(tmpdir(), 't573-udd-'));
  copyFileSync(EDITOR, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  writeFileSync(join(doc, 'rendered', 't573.bpmn'), FIXTURE);
  mkdirSync(join(repo, 'examples', 'aef-processes', 'rendered'), { recursive: true });

  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  let chrome; try { chrome = findChrome(); } catch (e) { console.log('CANNOT RUN: ' + e.message); py.kill(); return 2; }
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false;
    for (let i = 0; i < 80; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    const URL0 = BASE + '/designer.html?load=' + encodeURIComponent('rendered/t573.bpmn');
    const reload = async () => { await cmd('Page.navigate', { url: URL0 }); await waitReady(cmd); await sleep(400); };

    // ── Leg 1: the ratified shape is REACHABLE from the panel.
    await reload();
    let r = await ev(cmd, drive('u-t573-scalar', 'Emits', 'event:a, event:b', false));
    if (r.err) throw new Error(r.err);
    let ch = channels(r.after, 'u-t573-scalar');
    report(ch.structured && ch.items.length === 2 && ch.items[0] === 'event:a' && ch.items[1] === 'event:b' && !ch.metaAttr && r.storedIsArray,
      'panel-authors-structured',
      ch.structured
        ? `typed two events -> <aef:emits> with ${JSON.stringify(ch.items)}, meta attribute ${ch.metaAttr ? 'STILL PRESENT (both channels — they must stay disjoint)' : 'absent'}; stored ${r.stored}`
        : `typed two events and NO <aef:emits> was emitted; stored ${r.stored} (isArray=${r.storedIsArray})`);

    // ── Leg 2: CONTROL ARM. The pre-fix write must produce no structured element.
    await reload();
    let rc = await ev(cmd, drive('u-t573-scalar', 'Emits', 'event:a, event:b', true));
    if (rc.err) throw new Error(rc.err);
    let cc = channels(rc.after, 'u-t573-scalar');
    report(!cc.structured && !rc.storedIsArray, 'reproduce-string-write',
      !cc.structured
        ? `the pre-fix assignment leaves NO <aef:emits> (stored ${rc.stored}) — the fixture reaches the defect, so leg 1 is not a vacuous green`
        : `the pre-fix assignment ALREADY produced <aef:emits>; this fixture cannot evidence a repair`);

    // ── Leg 3: a single value with no separator still reaches the ratified shape.
    await reload();
    let r1 = await ev(cmd, drive('u-t573-scalar', 'Emits', 'event:solo', false));
    if (r1.err) throw new Error(r1.err);
    let c1 = channels(r1.after, 'u-t573-scalar');
    report(c1.structured && c1.items.length === 1 && c1.items[0] === 'event:solo' && !c1.metaAttr,
      'single-value-promotes',
      c1.structured
        ? `one event, no comma -> <aef:emits> with ${JSON.stringify(c1.items)} — the ratified form is not reserved for lists`
        : `one event with no comma stayed a scalar; stored ${r1.stored}`);

    // ── Leg 4: a CONTENT-EQUAL edit writes nothing. T-242's no-silent-migration guard.
    await reload();
    let r2 = await ev(cmd, drive('u-t573-scalar', 'Emits', 'event:probe.ready', false));
    if (r2.err) throw new Error(r2.err);
    let c2 = channels(r2.after, 'u-t573-scalar');
    report(r2.unchanged && c2.metaAttr && !c2.structured && !r2.storedIsArray,
      'noop-edit-moves-no-bytes',
      r2.unchanged
        ? `retyping the identical scalar left the export byte-identical and the shape a scalar (stored ${r2.stored})`
        : `retyping the identical value CHANGED the export — a stray keystroke now migrates a document-supplied shape (stored ${r2.stored}, structured=${c2.structured})`);

    // ── Leg 5: clearing removes the key from BOTH channels rather than storing empty.
    await reload();
    let r3 = await ev(cmd, drive('u-t573-struct', 'Emits', '', false));
    if (r3.err) throw new Error(r3.err);
    let c3 = channels(r3.after, 'u-t573-struct');
    report(!c3.structured && !c3.metaAttr && r3.stored === '<<absent>>',
      'clear-deletes-key',
      (!c3.structured && !c3.metaAttr)
        ? `cleared a structured field -> no <aef:emits> and no meta attribute; the key is ${r3.stored}`
        : `clearing left emits behind (structured=${c3.structured} metaAttr=${c3.metaAttr} stored ${r3.stored})`);

    // ── Leg 6: the structured value the DOCUMENT supplied is displayed joined, so the author
    // can see and edit it at all. An array rendered as "[object Object]" or "" would be F-11
    // again with the shape fixed.
    await reload();
    let r4 = await ev(cmd, drive('u-t573-struct', 'Emits', 'event:one, event:two', false));
    if (r4.err) throw new Error(r4.err);
    report(r4.shownValue === 'event:one, event:two' && r4.unchanged, 'array-displays-joined',
      `a document-supplied array renders as ${JSON.stringify(r4.shownValue)}${r4.unchanged ? ' and retyping it moves no bytes' : ' but retyping it CHANGED the export'}`);

    // ── Leg 7: the hint names the separator. The separator is load-bearing — it is what
    // produces the list — so an author who cannot see it cannot author a second event.
    report(/comma-separated/.test(r4.hint || ''), 'hint-names-the-separator',
      `rendered label+hint is ${JSON.stringify(r4.hint)}`);

    // ── Leg 8: the UNTOUCHED document round-trips both channels as it arrived. This is the
    // disjointness claim with nothing driven at all.
    await reload();
    let r5 = await ev(cmd, `(function(){ var x = buildBpmnXml(state); return { xml: x, stable: x === buildBpmnXml(state) }; })()`);
    const u1 = channels(r5.xml, 'u-t573-scalar'), u2 = channels(r5.xml, 'u-t573-struct');
    report(u1.metaAttr && !u1.structured && u2.structured && !u2.metaAttr && r5.stable,
      'untouched-channels-stay-disjoint',
      `scalar node: meta=${u1.metaAttr} structured=${u1.structured}; structured node: meta=${u2.metaAttr} structured=${u2.structured}; two exports ${r5.stable ? 'byte-identical' : 'DIFFER'}`);

  } catch (e) {
    console.log('CANNOT RUN: ' + e.message);
    try { cl && cl.close(); } catch (_) {}
    br.kill(); py.kill();
    await sleep(400);
    for (const d of [doc, repo, udd]) rmSync(d, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });
    return 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill(); py.kill();
  }
  await sleep(400);
  for (const d of [doc, repo, udd]) rmSync(d, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });

  console.log(out.join('\n'));
  console.log(`\n${npass} passed, ${nfail} failed`);
  if (nfail === 0) console.log(`${npass}/${npass} T-573 legs passed`);
  return nfail === 0 ? 0 : 1;
}

main().then(c => { process.exitCode = c; });
