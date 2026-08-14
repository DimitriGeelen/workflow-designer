#!/usr/bin/env node
// _t355-foreign-tag-render-cdp.mjs — does the canvas DISCLOSE that a node is a foreign
// BPMN element, or does it draw one it is not?
//
// T-337 made the importer preserve an out-of-allowlist flow node (`foreignTag`, re-emitted
// verbatim). That is the subtraction half and it is done. This instrument covers the other
// half: a preserved element that renders as a serviceTask, complete with the blue service
// dot, is a lie told to the author at full confidence. Preservation without disclosure is
// how a callActivity becomes a serviceTask in someone's head.
//
// WHY A CONTROL NODE IS IN THE FIXTURE. Every leg below has a matching assertion on a
// REAL serviceTask in the same document. Without it, "the foreign node has no blue dot"
// would also pass if the blue dot had been deleted for every node in the editor — the
// disclosure would be indistinguishable from a regression that erased the distinction from
// the other side. The control is what makes the foreign legs mean "different", not "gone".
//
// EVERY LEG ASSERTS ITS OWN DENOMINATOR. Written after T-233, where three legs of a new
// guard reported PASS while rendering zero cards, because `every()` over an empty array is
// true. A leg that can be satisfied by an empty population is not a guard, it is a mood.
import { spawn } from 'node:child_process';
import { readFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve } from 'node:path';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = process.env.T355_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');

// Fixture: two foreign elements (one task-shaped, one *Gateway-shaped), one foreign tag
// long enough to exercise truncation, and TWO allowlisted nodes as controls.
const LONG_TAG = 'exceptionallyLongForeignElementName';   // 35 chars
const FIXTURE = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:aef="https://agentic-engineering.org/bpmn"
                  targetNamespace="urn:t355">
  <bpmn:process id="Process_t355" isExecutable="false">
    <bpmn:startEvent id="s1" name="start"/>
    <bpmn:serviceTask id="real1" name="a real service task"/>
    <bpmn:callActivity id="foreign1" name="call another process"/>
    <bpmn:inclusiveGateway id="foreign2" name="inclusive split"/>
    <bpmn:${LONG_TAG} id="foreign3" name="long tag"/>
    <bpmn:endEvent id="e1" name="done"/>
    <bpmn:sequenceFlow id="f1" sourceRef="s1" targetRef="real1"/>
    <bpmn:sequenceFlow id="f2" sourceRef="real1" targetRef="foreign1"/>
    <bpmn:sequenceFlow id="f3" sourceRef="foreign1" targetRef="foreign2"/>
    <bpmn:sequenceFlow id="f4" sourceRef="foreign2" targetRef="foreign3"/>
    <bpmn:sequenceFlow id="f5" sourceRef="foreign3" targetRef="e1"/>
  </bpmn:process>
</bpmn:definitions>`;
const N_FOREIGN = 3, N_NATIVE = 3;   // start + serviceTask + end

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright');
  const cands = [];
  if (existsSync(cache)) for (const d of readdirSync(cache))
    if (d.startsWith('chromium-')) cands.push(join(cache, d, 'chrome-linux64', 'chrome'));
  cands.sort().reverse();
  for (const c of cands) if (existsSync(c)) return c;
  throw new Error('No Chromium under ' + cache);
}
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function waitForPortFile(f, timeoutMs = 15000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (existsSync(f)) {
      const txt = readFileSync(f, 'utf8').split('\n');
      if (txt[0] && txt[0].trim()) return { port: parseInt(txt[0].trim(), 10) };
    }
    await sleep(100);
  }
  throw new Error('Chromium did not report a DevTools port');
}
function cdpClient(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0; const pending = new Map();
  ws.addEventListener('message', ev => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  });
  const ready = new Promise((res, rej) => {
    ws.addEventListener('open', res);
    ws.addEventListener('error', () => rej(new Error('CDP websocket error')));
  });
  const cmd = (method, params = {}) => new Promise((res, rej) => {
    const mid = ++id;
    pending.set(mid, m => m.error ? rej(new Error(method + ': ' + JSON.stringify(m.error))) : res(m.result));
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  return { ready, cmd, close: () => ws.close() };
}
async function evalJson(cmd, expression) {
  const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error('page eval threw: ' + JSON.stringify(r.exceptionDetails).slice(0, 600));
  return r.result.value;
}

let failures = 0;
function leg(name, ok, detail) {
  console.log(`  [${ok ? 'PASS' : 'FAIL'}] ${name}${detail ? ' — ' + detail : ''}`);
  if (!ok) failures++;
}

async function main() {
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't355-leg-'));
  const proc = spawn(chrome, [
    '--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, '--window-size=1600,1000', 'about:blank',
  ], { stdio: ['ignore', 'ignore', 'pipe'] });
  try {
    const { port } = await waitForPortFile(join(udd, 'DevToolsActivePort'));
    const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    const page = targets.find(t => t.type === 'page');
    if (!page) throw new Error('no page target');
    const client = cdpClient(page.webSocketDebuggerUrl);
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1600, height: 1000, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: 'file://' + EDITOR });
    const t0 = Date.now();
    for (;;) {
      const ok = await evalJson(cmd, `(typeof adoptImportedXml==='function' && typeof state==='object' && !!state)`);
      if (ok) break;
      if (Date.now() - t0 > 20000) throw new Error('editor load timeout');
      await sleep(150);
    }
    await evalJson(cmd, `(window.alert=window.confirm=window.prompt=function(){return true;},true)`);
    await evalJson(cmd, `(adoptImportedXml(${JSON.stringify(FIXTURE)}), true)`);
    await sleep(400);

    const seen = await evalJson(cmd, `(function(){
      const out = { foreign: [], native: [] };
      for (const n of state.nodes) {
        const g = document.querySelector('#g-nodes g[data-id="' + n.id + '"]');
        if (!g) continue;
        const shape = g.querySelector('.node-shape');
        const tagText = g.querySelector('text.node-foreign-tag');
        const rec = {
          name: n.name,
          foreignTag: n.foreignTag || null,
          type: n.type,
          shapeTag: shape ? shape.tagName.toLowerCase() : null,
          dash: shape ? (shape.getAttribute('stroke-dasharray') || '') : null,
          stroke: shape ? (shape.getAttribute('stroke') || '') : null,
          circles: g.querySelectorAll('circle').length,
          // The exclusive X and the service dot are the two marks that assert a type.
          paths: g.querySelectorAll('path').length,
          tagLabel: tagText ? tagText.textContent : null,
          title: (g.querySelector('title') || {}).textContent || null,
          w: shape && shape.tagName.toLowerCase() === 'rect' ? parseFloat(shape.getAttribute('width')) : null,
        };
        (n.foreignTag ? out.foreign : out.native).push(rec);
      }
      return out;
    })()`);

    const F = seen.foreign, NAT = seen.native;
    const popF = F.length === N_FOREIGN, popN = NAT.length === N_NATIVE;

    leg(`population: ${N_FOREIGN} foreign + ${N_NATIVE} native nodes imported`,
      popF && popN, `foreign=${F.length} native=${NAT.length}`);

    leg('every foreign node is drawn dashed in the muted palette',
      popF && F.every(r => r.dash === '4 3' && r.stroke === 'var(--text-dim)'),
      popF ? JSON.stringify(F.map(r => [r.foreignTag, r.dash, r.stroke])) : 'population 0 — nothing measured');

    // The two type-asserting marks: serviceTask's blue dot is a <circle>, the exclusive
    // gateway's X is an extra <path> beside the diamond.
    const taskShaped = F.filter(r => r.shapeTag === 'rect');
    const gwShaped = F.filter(r => r.shapeTag === 'path');
    leg('no serviceTask dot on a task-shaped foreign node',
      taskShaped.length === 2 && taskShaped.every(r => r.circles === 0),
      `${taskShaped.length} task-shaped (expected 2), circles=${JSON.stringify(taskShaped.map(r => r.circles))}`);
    leg('no exclusive X on a gateway-shaped foreign node (diamond only)',
      gwShaped.length === 1 && gwShaped.every(r => r.paths === 1),
      `${gwShaped.length} gateway-shaped (expected 1), paths=${JSON.stringify(gwShaped.map(r => r.paths))}`);

    leg('every foreign node displays its real tag',
      popF && F.every(r => r.tagLabel && r.tagLabel.indexOf('⟨') === 0),
      popF ? JSON.stringify(F.map(r => r.tagLabel)) : 'population 0 — nothing measured');

    const exact = F.find(r => r.foreignTag === 'callActivity');
    leg('the tag is the document\'s, verbatim',
      !!exact && exact.tagLabel === '⟨callActivity⟩',
      exact ? `callActivity → ${exact.tagLabel}` : 'no callActivity node — nothing measured');

    // Width is compared against the REAL serviceTask in the same document, not against a
    // constant. The first version of this leg asserted `w === 120` and failed at 110 — I
    // had declared the node default instead of reading it, which is the wrong kind of
    // expectation for a leg whose claim is "the label changed nothing": the claim is
    // relative, so the measurement must be too. A hard-coded width would also have gone
    // red for a legitimate change to NODE_DEFAULTS that this task has no opinion about.
    const longRec = F.find(r => r.foreignTag === LONG_TAG);
    const nativeTaskW = (NAT.find(r => r.type === 'serviceTask') || {}).w;
    leg('a long tag is truncated, not wrapped, and does not resize the node',
      !!longRec && !!longRec.tagLabel && !!nativeTaskW && longRec.tagLabel.length === 20
        && longRec.tagLabel.endsWith('…⟩') && longRec.w === nativeTaskW,
      longRec ? `label=${longRec.tagLabel} (${longRec.tagLabel ? longRec.tagLabel.length : 0} chars) `
        + `width=${longRec.w} vs native serviceTask ${nativeTaskW}`
        : 'no long-tag node — nothing measured');

    leg('every foreign node carries a <title> stating it is preserved verbatim',
      popF && F.every(r => r.title && /preserved verbatim on export/.test(r.title)),
      popF ? '' : 'population 0 — nothing measured');

    // CONTROL: the real nodes in the same document must be untouched.
    const realTask = NAT.find(r => r.type === 'serviceTask');
    leg('CONTROL — the real serviceTask keeps its dot, its solid stroke and no tag label',
      !!realTask && realTask.circles === 1 && !realTask.dash && !realTask.tagLabel,
      realTask ? `circles=${realTask.circles} dash="${realTask.dash}" tagLabel=${realTask.tagLabel}`
        : 'no native serviceTask — nothing measured');

    // Round trip: disclosure must not have touched what export writes.
    const xml = await evalJson(cmd, `buildBpmnXml(state)`);
    const roundTrip = typeof xml === 'string'
      && xml.indexOf('<bpmn:callActivity') > -1
      && xml.indexOf('<bpmn:inclusiveGateway') > -1
      && xml.indexOf('<bpmn:' + LONG_TAG) > -1
      && xml.indexOf('node-foreign-tag') === -1;
    leg('export still re-emits all 3 foreign tags verbatim and leaks no render detail',
      roundTrip, roundTrip ? '' : 'export text missing a foreign tag or carrying render markup');

    client.close();
  } finally {
    proc.kill('SIGKILL');
  }
  console.log(failures === 0 ? '\nT-355 foreign-tag disclosure: all legs PASS' : `\nT-355 foreign-tag disclosure: ${failures} leg(s) FAILED`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch(e => { console.error('probe error:', e.message); process.exit(2); });
