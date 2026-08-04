#!/usr/bin/env node
/**
 * _t366-uid-shape-agnostic.mjs — does anything on our side validate aef:uid SHAPE?
 *
 * ANSWERS A DIRECT QUESTION FROM THE PEER (RAIL-441). Their corpus is 1081 uid
 * elements and only 31 are our `n_8hex` mint shape; theirs are SEMANTIC SLUGS
 * (`ac_cron_fire`, `tl_work`, `ac_done_triaged`). Their worry: anything downstream of
 * us that validates uid shape — a regex, a schema, an assertion that uid matches
 * ^n_[0-9a-f]{8}$ — rejects 1050 of their 1081, and it is invisible from their side.
 *
 * WHY THIS IS A ROUND-TRIP AND NOT A GREP. A static scan of 34 uid-touching code
 * files found zero shape operations, and that is worth exactly what "I did not find
 * one" is worth. A shape constraint can be spelled `startsWith`, a length test, a
 * `slice(2)`, a schema pattern, or a prefix comparison — and AEF's own report in the
 * same message is a grep that returned 0 of 1081 because it assumed attribute syntax
 * for an element-syntax field. A regex hunting a shape reports confidently about a
 * population it cannot see. Only running the document answers the question.
 *
 * THE WITHIN-FIXTURE CONTROL IS THE LOAD-BEARING PART. The fixture carries AEF-form
 * slugs AND one mint-shaped `n_1a2b3c4d`. If a shape coercion existed, the mint-shaped
 * uid would survive while the slugs were rewritten — a SPLIT result, which names the
 * defect. A single boolean "all preserved" could not tell "no constraint exists" from
 * "the probe cannot see constraints"; the split can.
 *
 * T366_SRC overrides the designer source so tools/_t366-uid-shape-teeth.py can drive
 * a mutated copy carrying a deliberate shape validator. The real source is never
 * touched.
 *
 * Usage: node tools/_t366-uid-shape-agnostic.mjs
 * Exit 0 = every uid value survives verbatim, whatever its shape.
 * Exit 1 = at least one uid was rewritten or dropped (the shape hazard is real).
 * Exit 2 = harness broken.
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T366_SRC || join(REPO, 'src/aef-workflow-designer.html');

// The uid values under test. AEF's real reported forms, plus controls.
//   aef-slug   : the shape 1050 of their 1081 uids actually take
//   mint       : our own generateUid/deriveUid shape — the WITHIN-FIXTURE CONTROL.
//                A shape coercion preserves this one and rewrites the others.
//   exotic     : neither — proves the answer is "shape-agnostic", not "two shapes"
const UIDS = [
  { v: 'ac_cron_fire',   kind: 'aef-slug', on: 'node' },
  { v: 'ac_done_triaged', kind: 'aef-slug', on: 'node' },
  { v: 'tl_work',        kind: 'aef-slug', on: 'node' },
  { v: 'n_1a2b3c4d',     kind: 'mint',     on: 'node' },
  { v: 'T-2584',         kind: 'exotic',   on: 'node' },
  { v: 'e_trigger_fork', kind: 'aef-slug', on: 'edge' },
  { v: 'e_0001',         kind: 'exotic',   on: 'edge' },
  { v: 'e_deadbeef',     kind: 'mint',     on: 'edge' },
];

const DOC = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
                  xmlns:aef="http://anchorpoint.framework/aef/extensions"
                  id="Definitions_uidshape" targetNamespace="http://bpmn.io/schema/bpmn">
  <bpmn:process id="Process_uidshape" name="uid shape probe" isExecutable="false">
    <bpmn:laneSet id="LaneSet_1">
      <bpmn:lane id="Lane_1" name="Agent">
        <bpmn:extensionElements>
          <aef:laneMeta abbr="agt" authority="initiative" height="150"/>
        </bpmn:extensionElements>
        <bpmn:flowNodeRef>agt_1_start</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>agt_2_work</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>agt_3_check</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>agt_4_mint</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>agt_5_done</bpmn:flowNodeRef>
      </bpmn:lane>
    </bpmn:laneSet>
    <bpmn:startEvent id="agt_1_start" name="cron fires">
      <bpmn:extensionElements>
        <aef:uid value="ac_cron_fire"/>
        <aef:position x="220.0" y="60.0"/>
      </bpmn:extensionElements>
      <bpmn:outgoing>flow_1</bpmn:outgoing>
    </bpmn:startEvent>
    <bpmn:serviceTask id="agt_2_work" name="work">
      <bpmn:extensionElements>
        <aef:uid value="tl_work"/>
        <aef:position x="380.0" y="60.0"/>
      </bpmn:extensionElements>
      <bpmn:incoming>flow_1</bpmn:incoming>
      <bpmn:outgoing>flow_2</bpmn:outgoing>
    </bpmn:serviceTask>
    <bpmn:serviceTask id="agt_3_check" name="triaged">
      <bpmn:extensionElements>
        <aef:uid value="ac_done_triaged"/>
        <aef:position x="540.0" y="60.0"/>
      </bpmn:extensionElements>
      <bpmn:incoming>flow_2</bpmn:incoming>
      <bpmn:outgoing>flow_3</bpmn:outgoing>
    </bpmn:serviceTask>
    <bpmn:serviceTask id="agt_4_mint" name="mint-shaped control">
      <bpmn:extensionElements>
        <aef:uid value="n_1a2b3c4d"/>
        <aef:position x="700.0" y="60.0"/>
      </bpmn:extensionElements>
      <bpmn:incoming>flow_3</bpmn:incoming>
      <bpmn:outgoing>flow_4</bpmn:outgoing>
    </bpmn:serviceTask>
    <bpmn:endEvent id="agt_5_done" name="done">
      <bpmn:extensionElements>
        <aef:uid value="T-2584"/>
        <aef:position x="860.0" y="60.0"/>
      </bpmn:extensionElements>
      <bpmn:incoming>flow_4</bpmn:incoming>
    </bpmn:endEvent>
    <bpmn:sequenceFlow id="flow_1" sourceRef="agt_1_start" targetRef="agt_2_work">
      <bpmn:extensionElements><aef:uid value="e_trigger_fork"/></bpmn:extensionElements>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="flow_2" sourceRef="agt_2_work" targetRef="agt_3_check">
      <bpmn:extensionElements><aef:uid value="e_0001"/></bpmn:extensionElements>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="flow_3" sourceRef="agt_3_check" targetRef="agt_4_mint">
      <bpmn:extensionElements><aef:uid value="e_deadbeef"/></bpmn:extensionElements>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="flow_4" sourceRef="agt_4_mint" targetRef="agt_5_done">
      <bpmn:extensionElements><aef:uid value="e_last_flow"/></bpmn:extensionElements>
    </bpmn:sequenceFlow>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="D_1"><bpmndi:BPMNPlane id="P_1" bpmnElement="Process_uidshape"/></bpmndi:BPMNDiagram>
</bpmn:definitions>
`;

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 45000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('chrome did not write DevToolsActivePort within 45s'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const uidValues = xml => [...xml.matchAll(/<aef:uid value="([^"]*)"/g)].map(m => m[1]);

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't366-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't366-repo-'));
  writeFileSync(join(doc, 'designer.html'), readFileSync(SRC, 'utf8'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't366-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, outXml = null, err = null, counts = null;
  try {
    // 300 x 100ms = 30s, where the 38 sibling CDP probes all use 6s. Raised as cheap
    // headroom, NOT as a fix — read the next paragraph before repeating this elsewhere.
    //
    // This probe returned exit 2 ("harness broken") once inside the P-011 gate and
    // passed every standalone re-run. I hypothesised the 6s sidecar wait was marginal
    // under gate load and was about to file a 38-file sweep for it. Then I measured:
    // gallery-serve.py answers /api/health in 0.13s, three runs, a 46x margin. THE
    // HYPOTHESIS IS DISPROVED and the timeout is not the known cause.
    //
    // The cause is still unknown, because the verification line that caught it wrote
    // `> /dev/null 2>&1` and the gate prints head -5 of a failed command's output — I
    // suppressed the only diagnostic there was. Both halves are fixed (that line no
    // longer redirects; the throws below now name which wait expired), so the next
    // occurrence will say what it was instead of inviting another guess.
    //
    // Remaining unguarded race, named as a suspect and NOT as a finding: the chrome
    // target list below is read once with no retry, so `tg.find(t => t.type === 'page')`
    // can be undefined if DevToolsActivePort lands before the page target registers.
    let up = false;
    for (let i = 0; i < 300; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar did not answer /api/health within 30s:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__IN__ = ${JSON.stringify(DOC)};`);
    const r = await ev(cmd, `(function(){
      var prev = state; var m = parseBpmnXml(window.__IN__);
      if (!m) { state = prev; return { fatal: 'parseBpmnXml returned null' }; }
      state = m; refreshDisplayIds(); var x = buildBpmnXml(state);
      var inMem = { nodes: m.nodes.map(function(n){return n.uid;}),
                    edges: m.edges.map(function(e){return e.uid;}) };
      state = prev;
      return { xml: x, nodes: m.nodes.length, edges: m.edges.length, inMem: inMem };
    })()`);
    if (r.fatal) err = r.fatal; else { outXml = r.xml; counts = r; }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  if (err || !outXml) { console.error('HARNESS BROKEN: ' + (err || 'no output')); return 2; }

  const before = uidValues(DOC), after = new Set(uidValues(outXml));
  const inMem = new Set([...(counts.inMem.nodes || []), ...(counts.inMem.edges || [])]);

  console.log('\nDoes anything on the 832 side validate aef:uid SHAPE?');
  console.log(`(one document, ${before.length} uid values across four shape families; imported`);
  console.log(` ${counts.nodes} nodes / ${counts.edges} edges)\n`);

  const shapeOf = v => (UIDS.find(u => u.v === v) || {}).kind || 'aef-slug';
  const pad = (s, n) => String(s).padEnd(n);
  console.log(`  ${pad('uid value', 20)}${pad('shape', 12)}${pad('in memory', 12)}${pad('in bytes', 12)}verdict`);
  console.log('  ' + '-'.repeat(70));

  const rewritten = [];
  for (const v of before) {
    const mem = inMem.has(v), byt = after.has(v);
    const verdict = (mem && byt) ? 'PRESERVED' : (!mem && !byt) ? 'REWRITTEN (both)' : !mem ? 'REWRITTEN in memory' : 'DROPPED from bytes';
    if (!(mem && byt)) rewritten.push({ v, shape: shapeOf(v), verdict });
    console.log(`  ${pad(v, 20)}${pad(shapeOf(v), 12)}${pad(mem ? 'kept' : 'LOST', 12)}${pad(byt ? 'kept' : 'LOST', 12)}${verdict}`);
  }

  console.log();
  if (rewritten.length) {
    console.log(`  *** SHAPE CONSTRAINT FOUND — ${rewritten.length} of ${before.length} uid value(s) did not survive.`);
    const byShape = {};
    for (const r of rewritten) byShape[r.shape] = (byShape[r.shape] || 0) + 1;
    for (const [k, n] of Object.entries(byShape)) console.log(`      ${k}: ${n} lost`);
    const mintLost = rewritten.some(r => r.shape === 'mint');
    if (!mintLost) {
      console.log('  The mint-shaped control SURVIVED while other shapes did not. That split is the');
      console.log('  signature of a shape validator, not of a general uid bug — look for a regex,');
      console.log('  prefix test or length check on the import path.');
    } else {
      console.log('  The mint-shaped control was lost too, so this is NOT shape-selective — something');
      console.log('  is dropping uids generally. Different defect; do not report it as a shape constraint.');
    }
    return 1;
  }

  console.log(`  NO SHAPE CONSTRAINT — all ${before.length} uid values survived verbatim, in memory and in`);
  console.log('  the emitted bytes, across all four shape families (AEF semantic slugs, our mint');
  console.log('  shape, a bare task id, a zero-padded sequence).');
  console.log();
  console.log('  The mint-shaped control is what makes this discriminating: had a validator existed,');
  console.log('  n_1a2b3c4d and e_deadbeef would have survived while the slugs were rewritten, and');
  console.log('  the table above would show that split rather than a uniform PRESERVED column.');
  console.log('  tools/_t366-uid-shape-teeth.py proves this probe DOES report that split when a');
  console.log('  shape validator is present — without it, this green means "found nothing", which');
  console.log('  is not the same claim.');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
