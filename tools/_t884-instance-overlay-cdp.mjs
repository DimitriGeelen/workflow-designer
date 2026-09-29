#!/usr/bin/env node
// T-884 (arc-005 S4) — the instance overlay, driven in an isolated headless Chromium (own
// --user-data-dir; never the shared MCP browser — G-006) against a static server that serves
// the designer, the REAL task-lifecycle artefact, and a fixture snapshot at api/instances
// (python http.server ignores the query string, so the file answers /api/instances?template=…).
// Legs:
//   L1  picker lists the fixture instance; ?instance= pre-selects it; the option text names task · node · status
//   L2  four states drawn, nothing else: exactly one current (badge "● T-9991"), |done| done, one refused
//       ("⛔ template-flow"), one refused-target; every other node carries no data-instance
//   L3  WRITES NOTHING: buildBpmnXml and every node's aef bag byte-identical before / with / after
//   L4  deselect -> zero [data-instance]; select an unknown id -> "instance not found" option, zero overlay
//   L5  refusal on the current node keeps data-instance="current" AND draws the refused badge (second fixture instance)
//   L6  endpoint absent (second doc root without api/instances) -> picker reads "instances: unavailable",
//       zero overlay, g.node count == state.nodes.length
// Screenshots (element-level, scale 2): docs/reports/t884-shots/<state>-<s|m|l>.png (12) + picker.png.
// Exit 0 = all legs pass; 2 otherwise.
import { readFileSync, existsSync, readdirSync, mkdtempSync, copyFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';
const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const OUT = join(REPO, 'docs', 'reports', 't884-shots');
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof instanceOverlayState==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }
async function waitOverlayLoaded(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(state && (state.nodes||[]).length > 0 && instanceView.available !== null)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('overlay never loaded'); await sleep(150); } }

// The fixture snapshot: T-9991 stands on agt_2_perform (so done = frw_1_task, frw_2_build, frw_3_start),
// with an out-of-order refusal fired on frw_7_all toward frw_10_finalize (four DISTINCT states);
// T-9992 stands on frw_6_run with a refusal fired on frw_6_run itself (L5: both badges on one node).
const SNAPSHOT = {
  template: 'task-lifecycle', generated: '2026-09-29T00:00:00Z', state: 'INSTANCES', examined: 3,
  instances: [
    { task: 'T-9991', state: 'NODE', node: 'agt_2_perform', status: 'started-work', owner: 'agent' },
    { task: 'T-9992', state: 'NODE', node: 'frw_6_run', status: 'started-work', owner: 'human' },
    { task: 'T-9993', state: 'NO-POSITION', node: '', status: 'captured', owner: 'agent' },
  ],
  refusals: [
    { ts: '2026-09-29T00:00:01Z', task: 'T-9991', case: 'unmet-input-contract', rule: 'P-010', kind: 'REFUSED-BY-GATE', node: 'frw_7_all', target: '', template: 'task-lifecycle', detail: 'earlier', actor: 'framework' },
    { ts: '2026-09-29T00:00:02Z', task: 'T-9991', case: 'out-of-order-advance', rule: 'template-flow', kind: 'REFUSED-TRANSITION', node: 'frw_7_all', target: 'frw_10_finalize', template: 'examples/aef-processes/rendered/task-lifecycle.bpmn', detail: 'latest', actor: 'cli' },
    { ts: '2026-09-29T00:00:03Z', task: 'T-9992', case: 'skipped-human-gateway', rule: 'R-033', kind: 'REFUSED-BY-GATE', node: 'frw_6_run', target: '', template: 'task-lifecycle', detail: 'on the current node', actor: 'framework' },
  ],
};
const legs = []; const leg = (id, name, ok, detail) => { legs.push({ id, name, ok, detail }); console.log(`${id} ${ok ? 'PASS' : 'FAIL'}  ${name}\n      ${detail}`); };

function makeDoc(withApi) {
  const doc = mkdtempSync(join(tmpdir(), 't884-doc-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/task-lifecycle.bpmn'), join(doc, 'rendered', 'task-lifecycle.bpmn'));
  if (withApi) { mkdirSync(join(doc, 'api'), { recursive: true }); writeFileSync(join(doc, 'api', 'instances'), JSON.stringify(SNAPSHOT)); }
  return doc;
}
async function serve(doc) {
  const port = await freePort();
  const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: ['ignore', 'ignore', 'ignore'] });
  const BASE = `http://127.0.0.1:${port}`;
  let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/designer.html'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
  if (!up) throw new Error('static server down');
  return { py, BASE };
}
const COUNTS = `({ current: document.querySelectorAll('g.node[data-instance="current"]').length, done: document.querySelectorAll('g.node[data-instance="done"]').length, refused: document.querySelectorAll('g.node[data-instance="refused"]').length, target: document.querySelectorAll('g.node[data-instance="refused-target"]').length, any: document.querySelectorAll('g.node[data-instance]').length, nodes: document.querySelectorAll('g.node').length, stateNodes: (state.nodes||[]).length })`;

(async () => {
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't884-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1600,1000', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl, rc = 0; const servers = [];
  const shot = async (cmd, sel, file, pad) => {
    const box = await ev(cmd, `(() => { const g = document.querySelector(${JSON.stringify(sel)}); if (!g) return null; const r = g.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height }; })()`);
    if (!box) throw new Error('no element for ' + sel);
    const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: Math.max(0, box.x - pad), y: Math.max(0, box.y - pad - 6), width: box.w + 2 * pad, height: box.h + 2 * pad + 6, scale: 2 } });
    mkdirSync(OUT, { recursive: true }); writeFileSync(join(OUT, file), Buffer.from(s.data, 'base64'));
  };
  try {
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');

    // ---- doc A: with the endpoint ----
    const A = await serve(makeDoc(true)); servers.push(A.py);
    await cmd('Page.navigate', { url: `${A.BASE}/designer.html?load=rendered/task-lifecycle.bpmn&instance=T-9991` });
    await waitReady(cmd); await waitOverlayLoaded(cmd);
    await ev(cmd, 'labelPrefs.size = "m"; renderAll(); true');
    const p = await ev(cmd, `(() => { const s = document.getElementById('instancePicker'); return { available: instanceView.available, selected: instanceView.selected, value: s.value, options: Array.from(s.options).map(o => o.textContent), disabled: s.disabled }; })()`);
    leg('L1', 'picker lists the instances, ?instance= pre-selects, option text is task · node · status',
        p.available === true && p.selected === 'T-9991' && p.value === 'T-9991' && p.options.includes('T-9991 · agt_2_perform · started-work') && p.options.includes('T-9993 · NO-POSITION · captured') && !p.disabled,
        JSON.stringify(p));
    const before = await ev(cmd, `({ xml: buildBpmnXml(state), aef: JSON.stringify(state.nodes.map(n => n.aef)) })`);
    const c = await ev(cmd, COUNTS);
    const badges = await ev(cmd, `(() => { const o = {}; for (const t of document.querySelectorAll('[data-instance-badge]')) { const g = t.closest('g.node'); o[t.getAttribute('data-instance-badge')] = { text: t.textContent, node: displayIdOf(findNode(g.getAttribute('data-id'))) }; } return o; })()`);
    const ids = await ev(cmd, `(() => { const o = {}; for (const g of document.querySelectorAll('g.node[data-instance]')) { const k = g.getAttribute('data-instance'); (o[k] = o[k] || []).push(displayIdOf(findNode(g.getAttribute('data-id')))); } return o; })()`);
    leg('L2', 'four states drawn, nothing else: 1 current (● T-9991), 3 done, 1 refused (⛔ template-flow), 1 refused-target',
        c.current === 1 && c.done === 3 && c.refused === 1 && c.target === 1 && c.any === 6 && c.nodes === c.stateNodes
          && ids.current[0] === 'agt_2_perform' && JSON.stringify([...ids.done].sort()) === JSON.stringify(['frw_1_task', 'frw_2_build', 'frw_3_start'])
          && ids.refused[0] === 'frw_7_all' && ids['refused-target'][0] === 'frw_10_finalize'
          && badges.current.text === '● T-9991' && badges.refused.text === '⛔ template-flow' && badges['refused-target'].text === '✗ refused target' && badges.done.text === '✓',
        JSON.stringify({ c, ids, badges }));
    // screenshots at every label size, one node per state
    const nodeSel = async did => `g.node[data-id="${await ev(cmd, `(state.nodes.find(n => displayIdOf(n) === '${did}') || {}).id`)}"]`;
    const targets = { current: 'agt_2_perform', done: 'frw_3_start', refused: 'frw_7_all', 'refused-target': 'frw_10_finalize' };
    for (const size of ['s', 'm', 'l']) {
      await ev(cmd, `labelPrefs.size = "${size}"; renderAll(); true`); await sleep(120);
      for (const [st, did] of Object.entries(targets)) await shot(cmd, await nodeSel(did), `${st}-${size}.png`, 30);
    }
    await ev(cmd, 'labelPrefs.size = "m"; renderAll(); true'); await sleep(100);
    await shot(cmd, '#instancePicker', 'picker.png', 10);

    // ---- L3 / L4 ----
    await ev(cmd, `selectInstance(null); true`);
    const c0 = await ev(cmd, COUNTS);
    const mid = await ev(cmd, `({ xml: buildBpmnXml(state), aef: JSON.stringify(state.nodes.map(n => n.aef)), first: document.getElementById('instancePicker').options[0].textContent })`);
    await ev(cmd, `selectInstance('T-0'); true`);
    const cU = await ev(cmd, COUNTS);
    const pU = await ev(cmd, `(() => { const s = document.getElementById('instancePicker'); return { value: s.value, text: s.options[s.selectedIndex].textContent, notFound: instanceView.notFound }; })()`);
    await ev(cmd, `selectInstance('T-9991'); true`);
    const after = await ev(cmd, `({ xml: buildBpmnXml(state), aef: JSON.stringify(state.nodes.map(n => n.aef)) })`);
    const cB = await ev(cmd, COUNTS);
    leg('L3', 'WRITES NOTHING: export and aef bags byte-identical with the overlay, without it, and with it again',
        before.xml === mid.xml && mid.xml === after.xml && before.aef === mid.aef && mid.aef === after.aef && cB.any === 6,
        `xml equal=${before.xml === mid.xml && mid.xml === after.xml} aef equal=${before.aef === mid.aef && mid.aef === after.aef} re-selected any=${cB.any}`);
    leg('L4', 'deselect -> zero overlay; unknown id -> "instance not found" option and zero overlay',
        c0.any === 0 && mid.first.startsWith('instance: none (3 on task-lifecycle)') && cU.any === 0 && pU.notFound === true && pU.text === 'instance not found: T-0' && pU.value === 'T-0',
        JSON.stringify({ c0: c0.any, first: mid.first, cU: cU.any, pU }));

    // ---- L5: refusal on the current node ----
    await ev(cmd, `selectInstance('T-9992'); true`);
    const c5 = await ev(cmd, COUNTS);
    const b5 = await ev(cmd, `(() => { const g = document.querySelector('g.node[data-instance="current"]'); return { node: displayIdOf(findNode(g.getAttribute('data-id'))), badges: Array.from(g.querySelectorAll('[data-instance-badge]')).map(t => t.getAttribute('data-instance-badge') + ':' + t.textContent) }; })()`);
    leg('L5', 'a refusal fired on the current node: data-instance stays current and BOTH badges draw',
        c5.current === 1 && c5.refused === 0 && b5.node === 'frw_6_run' && b5.badges.includes('current:● T-9992') && b5.badges.includes('refused:⛔ R-033'),
        JSON.stringify({ c5, b5 }));
    await shot(cmd, await nodeSel('frw_6_run'), 'current-and-refused-m.png', 30);

    // ---- doc B: endpoint absent ----
    const B = await serve(makeDoc(false)); servers.push(B.py);
    await cmd('Page.navigate', { url: `${B.BASE}/designer.html?load=rendered/task-lifecycle.bpmn&instance=T-9991` });
    await waitReady(cmd); await waitOverlayLoaded(cmd);
    const c6 = await ev(cmd, COUNTS);
    const p6 = await ev(cmd, `(() => { const s = document.getElementById('instancePicker'); return { available: instanceView.available, text: s.options[s.selectedIndex].textContent, n: s.options.length, notFound: instanceView.notFound }; })()`);
    leg('L6', 'endpoint absent: picker reads "instances: unavailable", zero overlay, every node still drawn',
        p6.available === false && p6.text === 'instances: unavailable' && c6.any === 0 && c6.nodes === c6.stateNodes && c6.nodes > 0,
        JSON.stringify({ c6, p6 }));

    rc = legs.every(l => l.ok) ? 0 : 2;
    console.log(`${legs.filter(l => l.ok).length}/${legs.length} legs passed; screenshots: ${readdirSync(OUT).filter(f => f.endsWith('.png')).sort().join(', ')}`);
  } catch (e) { console.error('DRIVER ERROR', e && e.message); rc = 2; }
  finally { try { br.kill(); } catch (_) {} for (const s of servers) { try { s.kill(); } catch (_) {} } }
  process.exit(rc);
})();
