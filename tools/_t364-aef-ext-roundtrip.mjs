#!/usr/bin/env node
/**
 * _t364-aef-ext-roundtrip.mjs — which of AEF's 12 `aef:*` extension kinds survive
 * an open->save through the designer?
 *
 * ANSWERS A DIRECT QUESTION FROM THE PEER (RAIL-432). Their corpus carries 12
 * distinct `aef:*` child kinds, 1,933 instances, and exactly one (`aef:uid`) is in
 * the seam contract. Their worry, in their words: if `parseBpmnXml` names only uid,
 * a round-trip strips their entire governance overlay — state, lane authority, event
 * typing, anchors — while node/flow/lane counts stay identical. Green because the
 * measure is about the wrong property.
 *
 * WHY THIS IS A ROUND-TRIP AND NOT A GREP. A `grep -o "byAef(el, '...')"` answers
 * "which kinds does the importer NAME", and I ran exactly that first. It reported 10
 * of 12, missing `aef:constituents`/`aef:constituent` because those go through a
 * separate list-of-dicts path (`structItemList`, emitter ~9369 / importer ~9924) and
 * never appear in a `byAef(el, <literal>)` call site. It would have been wrong by
 * precisely the two kinds the question was sharpest about.
 *
 * Naming is also not preserving: a kind can be read into a local that never reaches
 * the node object, or reach it and never be emitted. Only a round-trip answers the
 * question that was asked.
 *
 * METHOD. Build one document carrying every kind, in the shapes this build emits, at
 * the carrier each belongs on (process / lane / node / edge). Import it, export it,
 * and compare per kind:
 *
 *   PRESERVED  kind present after round-trip AND every attribute value survives
 *   ALTERED    kind present, at least one attribute value changed or vanished
 *   DROPPED    kind absent from the output
 *
 * A DROPPED row is the finding. An ALTERED row is nearly as interesting, because a
 * kind that survives with a hollowed-out body still passes any count-based check.
 *
 * The uid rows are the built-in positive control: `aef:uid` is ratified and
 * demonstrably survives, so a DROPPED on uid means the harness is broken and no other
 * row is interpretable. `aef:notAThing` is the negative control — a kind this build
 * has never heard of, which MUST come back DROPPED. If the unknown kind survived,
 * the probe would be measuring passthrough rather than naming, and every PRESERVED
 * would be worthless.
 *
 * Usage: node tools/_t364-aef-ext-roundtrip.mjs
 * Exit 0 = both controls behaved and the census is interpretable (findings and all).
 * Exit 1 = a control misbehaved; read nothing off the other rows.
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

// The 12 kinds AEF reported at RAIL-432, with instance counts, plus one control.
// `carrier` records where the kind legitimately sits — a kind put on the wrong
// carrier would come back DROPPED for a reason that has nothing to do with the seam.
const KINDS = [
  { kind: 'uid',           n: 889, carrier: 'node+edge', control: 'positive' },
  { kind: 'position',      n: 424, carrier: 'node' },
  { kind: 'meta',          n: 366, carrier: 'node' },
  { kind: 'anchors',       n: 92,  carrier: 'edge' },
  { kind: 'laneMeta',      n: 78,  carrier: 'lane' },
  { kind: 'workflowMeta',  n: 32,  carrier: 'process' },
  { kind: 'eventDef',      n: 20,  carrier: 'node' },
  { kind: 'link',          n: 12,  carrier: 'node' },
  { kind: 'routingHint',   n: 8,   carrier: 'edge' },
  { kind: 'loopDetour',    n: 8,   carrier: 'edge' },
  { kind: 'constituents',  n: 1,   carrier: 'node' },
  { kind: 'constituent',   n: 3,   carrier: 'node (child of constituents)' },
  { kind: 'notAThing',     n: 0,   carrier: 'node', control: 'negative' },
];

const NS = 'xmlns:aef="http://anchorpoint.framework/aef/extensions"';

// One document carrying every kind. Shapes taken from this build's own emitter so
// the fixture is what we would produce, not what I imagine AEF produces — the
// question is whether OUR importer keeps them, and a shape our emitter never writes
// would test the wrong thing.
const DOC = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
                  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
                  ${NS}
                  id="Definitions_ext" targetNamespace="http://bpmn.io/schema/bpmn">
  <bpmn:process id="Process_ext" isExecutable="false">
    <bpmn:extensionElements>
      <aef:workflowMeta id="ext-probe" version="3" schemaVersion="2" title="ext probe" tier_default="1"/>
    </bpmn:extensionElements>
    <bpmn:laneSet id="LaneSet_1">
      <bpmn:lane id="Lane_gov" name="Governance">
        <bpmn:extensionElements>
          <aef:laneMeta abbr="gov" authority="sovereignty" height="150"/>
        </bpmn:extensionElements>
        <bpmn:flowNodeRef>gov_1_start</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>gov_2_work</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>gov_3_done</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>gov_4_link</bpmn:flowNodeRef>
      </bpmn:lane>
    </bpmn:laneSet>
    <bpmn:startEvent id="gov_1_start" name="start">
      <bpmn:extensionElements>
        <aef:uid value="n_extprobe1"/>
        <aef:position x="220.0" y="60.0"/>
      </bpmn:extensionElements>
      <bpmn:outgoing>flow_1</bpmn:outgoing>
    </bpmn:startEvent>
    <bpmn:serviceTask id="gov_2_work" name="work">
      <bpmn:extensionElements>
        <aef:uid value="n_extprobe2"/>
        <aef:position x="380.0" y="60.0"/>
        <aef:meta tier="2" owner="framework" state="active"/>
        <aef:notAThing value="control"/>
        <aef:constituents>
          <aef:constituent id="c1" name="first" ref="R-1"/>
          <aef:constituent id="c2" name="second" ref="R-2"/>
          <aef:constituent id="c3" name="third" ref="R-3"/>
        </aef:constituents>
      </bpmn:extensionElements>
      <bpmn:incoming>flow_1</bpmn:incoming>
      <bpmn:outgoing>flow_2</bpmn:outgoing>
    </bpmn:serviceTask>
    <bpmn:intermediateThrowEvent id="gov_3_done" name="done">
      <bpmn:extensionElements>
        <aef:uid value="n_extprobe3"/>
        <aef:position x="540.0" y="60.0"/>
        <aef:eventDef kind="message" binding="bus.topic.x"/>
      </bpmn:extensionElements>
      <bpmn:incoming>flow_2</bpmn:incoming>
      <bpmn:outgoing>flow_3</bpmn:outgoing>
    </bpmn:intermediateThrowEvent>
    <!-- aef:link gets its OWN node, and the attribute shape the emitter actually
         writes. The first version of this fixture put aef:link beside aef:eventDef on
         one node and gave it a bare name="" — two defects that both produce a DROPPED
         for reasons having nothing to do with the seam. eventDef and link are
         mutually-exclusive typing extensions that adoptImportedXml disambiguates
         between, and name= is only emitted alongside workflowRef, so linkAttrs would
         have been empty even on a correct import. Reporting that DROPPED to AEF would
         have spent their attention on a fixture bug of mine. -->
    <bpmn:task id="gov_4_link" name="call other workflow">
      <bpmn:extensionElements>
        <aef:uid value="n_extprobe4"/>
        <aef:position x="700.0" y="60.0"/>
        <aef:link workflowRef="wf-target-1" name="lnk_a" linkId="L1"/>
      </bpmn:extensionElements>
      <bpmn:incoming>flow_3</bpmn:incoming>
    </bpmn:task>
    <bpmn:sequenceFlow id="flow_1" sourceRef="gov_1_start" targetRef="gov_2_work">
      <bpmn:extensionElements>
        <aef:uid value="e_extprobe1"/>
        <aef:anchors sourcePort="e" targetPort="w"/>
        <aef:routingHint role="branch" offset="24.0"/>
      </bpmn:extensionElements>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="flow_2" sourceRef="gov_2_work" targetRef="gov_3_done">
      <bpmn:extensionElements>
        <aef:uid value="e_extprobe2"/>
        <aef:loopDetour y="88.0"/>
      </bpmn:extensionElements>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="flow_3" sourceRef="gov_3_done" targetRef="gov_4_link">
      <bpmn:extensionElements>
        <aef:uid value="e_extprobe3"/>
      </bpmn:extensionElements>
    </bpmn:sequenceFlow>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="D_1"><bpmndi:BPMNPlane id="P_1" bpmnElement="Process_ext"/></bpmndi:BPMNDiagram>
</bpmn:definitions>
`;

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Every <aef:KIND .../> occurrence with its attribute map, keyed by kind.
function harvest(xml) {
  const out = new Map();
  const re = /<aef:([A-Za-z]+)\b([^>]*?)\/?>/g;
  let m;
  while ((m = re.exec(xml))) {
    const kind = m[1];
    const attrs = {};
    for (const a of m[2].matchAll(/([A-Za-z_][\w.-]*)="([^"]*)"/g)) attrs[a[1]] = a[2];
    if (!out.has(kind)) out.set(kind, []);
    out.get(kind).push(attrs);
  }
  return out;
}

function classify(before, after, kind) {
  const b = before.get(kind) || [], a = after.get(kind) || [];
  if (!b.length) return { verdict: 'NOT-IN-FIXTURE', detail: 'the probe never injected this kind' };
  if (!a.length) return { verdict: 'DROPPED', detail: `${b.length} in, 0 out` };
  // Attribute fidelity: every attribute value present on input must appear on some
  // output instance of the same kind. Deliberately order-insensitive — a reordered
  // emit is not a loss and flagging it would bury the real drops in noise.
  const outVals = new Set();
  for (const inst of a) for (const [k, v] of Object.entries(inst)) outVals.add(`${k}=${v}`);
  const lost = [];
  for (const inst of b) for (const [k, v] of Object.entries(inst)) if (!outVals.has(`${k}=${v}`)) lost.push(`${k}="${v}"`);
  if (lost.length) return { verdict: 'ALTERED', detail: `${b.length} in / ${a.length} out; lost ${lost.slice(0, 4).join(' ')}` };
  return { verdict: 'PRESERVED', detail: `${b.length} in / ${a.length} out, all attribute values survive` };
}

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't364-ext-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't364-ext-repo-'));
  writeFileSync(join(doc, 'designer.html'), readFileSync(join(REPO, 'src/aef-workflow-designer.html'), 'utf8'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't364-ext-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, outXml = null, err = null;
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__IN__ = ${JSON.stringify(DOC)};`);
    const r = await ev(cmd, `(function(){
      var prev = state; var m = parseBpmnXml(window.__IN__);
      if (!m) { state = prev; return { fatal: 'parseBpmnXml returned null' }; }
      state = m; refreshDisplayIds(); var x = buildBpmnXml(state); state = prev;
      return { xml: x, nodes: m.nodes.length, edges: m.edges.length, lanes: (m.lanes||[]).length };
    })()`);
    if (r.fatal) err = r.fatal; else { outXml = r.xml; console.log(`\nimported: ${r.nodes} nodes, ${r.edges} edges, ${r.lanes} lane(s)`); }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  if (err || !outXml) { console.error('HARNESS BROKEN: ' + (err || 'no output')); return 1; }

  const before = harvest(DOC), after = harvest(outXml);
  console.log('\nDo AEF\'s aef:* extension kinds survive an open->save through the designer?');
  console.log('(fixture carries every kind AEF reported at RAIL-432, in this build\'s own shapes)\n');

  const rows = KINDS.map(k => ({ ...k, ...classify(before, after, k.kind) }));
  const pad = (s, n) => String(s).padEnd(n);
  console.log(`  ${pad('kind', 16)}${pad('AEF n', 8)}${pad('carrier', 30)}${pad('verdict', 15)}detail`);
  console.log('  ' + '-'.repeat(104));
  for (const r of rows) {
    const tag = r.control ? ` [${r.control} control]` : '';
    console.log(`  ${pad('aef:' + r.kind, 16)}${pad(r.n || '-', 8)}${pad(r.carrier + tag, 30)}${pad(r.verdict, 15)}${r.detail}`);
  }

  const pos = rows.find(r => r.control === 'positive');
  const neg = rows.find(r => r.control === 'negative');
  console.log();
  let bad = 0;
  if (pos.verdict !== 'PRESERVED') {
    console.log(`  CONTROL FAILED — aef:uid came back ${pos.verdict}. uid is ratified and known to`);
    console.log('  survive, so this is a broken harness. No other row is interpretable.');
    bad++;
  }
  if (neg.verdict !== 'DROPPED') {
    console.log(`  CONTROL FAILED — aef:notAThing came back ${neg.verdict}. An unknown kind must NOT`);
    console.log('  survive. If it does, this probe is measuring blind passthrough rather than what');
    console.log('  the importer names, and every PRESERVED above is worthless.');
    bad++;
  }
  if (bad) return 1;

  const real = rows.filter(r => !r.control);
  const dropped = real.filter(r => r.verdict === 'DROPPED');
  const altered = real.filter(r => r.verdict === 'ALTERED');
  const missing = real.filter(r => r.verdict === 'NOT-IN-FIXTURE');
  console.log('  Both controls behaved: uid PRESERVED, unknown kind DROPPED. The census reads.');
  console.log();
  if (missing.length) {
    console.log(`  ${missing.length} kind(s) never made it into the fixture — NOT a result for them:`);
    for (const r of missing) console.log(`      aef:${r.kind}`);
  }
  const lost = dropped.reduce((s, r) => s + (r.n || 0), 0);
  const alt = altered.reduce((s, r) => s + (r.n || 0), 0);
  if (!dropped.length && !altered.length) {
    console.log(`  ALL ${real.length - missing.length} of AEF's kinds round-trip intact.`);
    console.log('  Their worst case — "if the answer is only uid, a round-trip strips the entire');
    console.log('  governance overlay" — does NOT hold for this build. The importer names each of');
    console.log('  these and the emitter writes them back with their attribute values.');
    console.log();
    console.log('  Scope, stated so this is not read wider than it is: measured on ONE synthetic');
    console.log('  document carrying the kinds in the shapes THIS build emits. It does not prove');
    console.log('  fidelity for attribute names we do not emit, for kinds absent from their census,');
    console.log('  or for nesting depths this fixture does not reach. A byte-identical fixture from');
    console.log('  their corpus would settle it for their bytes; this settles it for the kinds.');
  } else {
    if (dropped.length) {
      console.log(`  *** ${dropped.length} kind(s) DROPPED — ${lost} instances in their corpus:`);
      for (const r of dropped) console.log(`      aef:${r.kind}  (${r.n} instances)  ${r.detail}`);
    }
    if (altered.length) {
      console.log(`  *** ${altered.length} kind(s) ALTERED — ${alt} instances, survive with a changed body:`);
      for (const r of altered) console.log(`      aef:${r.kind}  (${r.n} instances)  ${r.detail}`);
    }
    console.log();
    console.log('  This is the RAIL-399 shape from the other end: node, flow and lane counts are');
    console.log('  unchanged, so every count-based instrument on both sides stays green while the');
    console.log('  governance overlay degrades. Report to AEF with the instance counts attached.');
  }
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
