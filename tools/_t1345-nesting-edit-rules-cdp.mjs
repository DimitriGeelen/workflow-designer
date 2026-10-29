#!/usr/bin/env node
// _t1345-nesting-edit-rules-cdp.mjs — T-1345 (T-1266 GO, slice 2): the edit rules for another tool's nested nodes, in
// the REAL editor (headless Chromium), on tests/fixtures/t1345/nested-two-lanes.bpmn opened as a person opens a file:
//   L1 drag: a nested task dragged (real mouse events) into the other lane changes lane and keeps its container; the
//      save writes it inside the subprocess;
//   L2 connect: clicking (real mouse events, connect mode) a nested task then a top-level task, and a task of S1 then a
//      task of S2, creates no flow, records no undo step and shows the refusal; two nodes of one container, and two
//      top-level nodes, are connected as before;
//   L3 re-anchor: dropping a flow's end on a node in another container (the real mouseup handler) leaves the flow as
//      it was and shows the refusal;
//   L4 delete S1: its 4 direct contents move to the process (S2 keeps its own task), the message says so; undo puts
//      them back inside S1;
//   L5 delete S2 alone: its task moves into S1 (depth 2 -> 1), the message names S1;
//   L6 multi-select delete of S1 and S2 (the real keydown handler): the contents of both reach the process, and undo
//      restores both (a multi-delete recorded no undo step before T-1345);
//   L7 a node added from the palette (createNodeAt) has no container.
//   node tools/_t1345-nesting-edit-rules-cdp.mjs        T1345_SRC=<designer.html> substitutes another source
// Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const DESIGNER = process.env.T1345_SRC || join(REPO, 'src', 'aef-workflow-designer.html');
const FIXTURE = readFileSync(join(REPO, 'tests', 'fixtures', 't1345', 'nested-two-lanes.bpmn'), 'utf8');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// Page helpers, installed once. H.parentInExport(name) reads the container from a fresh save, by x832:origin.
const HELPERS = `window.H = {
  node: function(name){ return state.nodes.find(function(n){ return n.name === name; }); },
  toast: function(){ var t = document.getElementById('app-toast'); return t ? t.textContent : ''; },
  clearToast: function(){ var t = document.getElementById('app-toast'); if (t) t.remove(); },
  center: function(name){ var n = H.node(name); var g = n && document.querySelector('g[data-id="' + n.uid + '"]');
    if (!g) return null; var r = g.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2,
    vis: r.top >= 0 && r.left >= 0 && r.bottom <= innerHeight && r.right <= innerWidth }; },
  parentInExport: function(name){
    var d = new DOMParser().parseFromString(buildBpmnXml(state), 'application/xml'), M = 'http://www.omg.org/spec/BPMN/20100524/MODEL';
    var el = Array.prototype.find.call(d.getElementsByTagNameNS(M, '*'), function(e){ return e.getAttribute('name') === name && e.localName !== 'participant'; });
    if (!el) return 'MISSING';
    for (var p = el.parentNode; p; p = p.parentNode) { if (p.namespaceURI !== M) continue;
      if (p.localName === 'process') return 'process'; if (/^(subProcess|transaction|adHocSubProcess)$/.test(p.localName)) return p.getAttribute('name'); }
    return '?'; },
  open: async function(xml){ await adoptImportedXml(xml, { userImport: true }); await new Promise(function(r){ setTimeout(r, 150); });
    setMode('select'); selection = null; multiSelect = new Set(); H.clearToast(); }
};`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1345-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1345-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1345-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1600,1000', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; let cl;
  const leg = (name, ok, detail) => legs.push({ name, ok: !!ok, detail: ok ? '' : detail });
  try {
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) break; } catch (_) {} await sleep(100); }
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; };' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(300);
    await ev(cmd, HELPERS);
    const X = JSON.stringify(FIXTURE);
    const open = () => ev(cmd, `H.open(${X})`);
    const mouse = (type, x, y) => cmd('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
    const click = async p => { await mouse('mouseMoved', p.x, p.y); await mouse('mousePressed', p.x, p.y); await mouse('mouseReleased', p.x, p.y); await sleep(120); };

    // Guard: the import must have nested the fixture, or every leg below measures nothing (T-1339 is the precondition).
    await open();
    const pre = await ev(cmd, `({ inner: H.parentInExport('Inner task'), deep: H.parentInExport('Deep task'), s2: H.parentInExport('Deep') })`);
    if (pre.inner !== 'Outer' || pre.deep !== 'Deep' || pre.s2 !== 'Outer') {
      console.log(JSON.stringify({ ok: false, error: 'CANNOT RUN: the fixture did not import nested (T-1339 precondition)', pre })); process.exitCode = 2; return;
    }

    // L1 drag into the other lane, real mouse events
    const from = await ev(cmd, `H.center('Inner task')`), toward = await ev(cmd, `H.center('Top task')`);
    if (!from || !toward || !from.vis || !toward.vis) { leg('L1 drag keeps the container', false, 'nodes not on screen: ' + JSON.stringify({ from, toward })); }
    else {
      const ty = toward.y, tx = from.x;
      await mouse('mouseMoved', from.x, from.y); await mouse('mousePressed', from.x, from.y);
      for (let i = 1; i <= 8; i++) { await mouse('mouseMoved', from.x + (tx - from.x) * i / 8, from.y + (ty - from.y) * i / 8); await sleep(30); }
      await mouse('mouseReleased', tx, ty); await sleep(200);
      const r = await ev(cmd, `(function(){ var n = H.node('Inner task'), s1 = H.node('Outer');
        return { lane: n.lane, parentIsS1: n.parent === s1.uid, saved: H.parentInExport('Inner task') }; })()`);
      leg('L1 drag into lane B keeps the container', r.lane === 'Lane_B' && r.parentIsS1 && r.saved === 'Outer', JSON.stringify(r));
    }

    // L2 connect gesture, real clicks
    const connect = async (a, b) => {
      await ev(cmd, `(H.clearToast(), setMode('connect'), selection = null, true)`);
      const pa = await ev(cmd, `H.center(${JSON.stringify(a)})`), pb = await ev(cmd, `H.center(${JSON.stringify(b)})`);
      if (!pa || !pb || !pa.vis || !pb.vis) return { error: 'not on screen', pa, pb };
      const before = await ev(cmd, `({ edges: state.edges.length, hist: _history.length })`);
      await click(pa); await click(pb);
      const after = await ev(cmd, `({ edges: state.edges.length, hist: _history.length, toast: H.toast() })`);
      await ev(cmd, `(setMode('select'), true)`);
      return { added: after.edges - before.edges, hist: after.hist - before.hist, toast: after.toast };
    };
    await open();
    const c1 = await connect('Inner task', 'Top task');
    leg('L2 nested -> top-level refused, no undo step, message', c1.added === 0 && c1.hist === 0 && /cannot cross a subprocess boundary/.test(c1.toast || ''), JSON.stringify(c1));
    const c2 = await connect('Inner task', 'Deep task');
    leg('L2 S1 -> S2 refused', c2.added === 0 && /cannot cross a subprocess boundary/.test(c2.toast || ''), JSON.stringify(c2));
    const c3 = await connect('In start', 'In end');
    leg('L2 within one container connects', c3.added === 1 && !/cannot cross/.test(c3.toast || ''), JSON.stringify(c3));
    const c4 = await connect('Begin', 'Done');
    leg('L2 two top-level nodes connect', c4.added === 1, JSON.stringify(c4));

    // L3 re-anchor an edge end into another container, through the real mouseup handler
    await open();
    const r3 = await ev(cmd, `(function(){
      var tgt = H.node('In end'), outside = H.node('Top task');
      var e = state.edges.find(function(x){ return x.target === tgt.uid; });
      edgeDrag = { kind: 'endpoint', edgeId: e.id, role: 'target', snapNodeId: outside.uid, snapPort: null };
      window.dispatchEvent(new MouseEvent('mouseup', { clientX: 0, clientY: 0 }));
      var after = state.edges.find(function(x){ return x.id === e.id; });
      return { stillTarget: after.target === tgt.uid, toast: H.toast() }; })()`);
    leg('L3 re-anchor across the boundary refused', r3.stillTarget && /cannot cross a subprocess boundary/.test(r3.toast), JSON.stringify(r3));

    // L4 delete S1: contents to the process, message, undo restores
    await open();
    const r4 = await ev(cmd, `(function(){ deleteNode(H.node('Outer').uid);
      var out = { inner: H.parentInExport('Inner task'), start: H.parentInExport('In start'), s2: H.parentInExport('Deep'),
        deep: H.parentInExport('Deep task'), toast: H.toast() };
      undo(); out.undoInner = H.parentInExport('Inner task'); out.undoDeep = H.parentInExport('Deep task'); return out; })()`);
    leg('L4 delete S1 moves its 4 contents to the process, says so; undo restores', r4.inner === 'process' && r4.start === 'process'
      && r4.s2 === 'process' && r4.deep === 'Deep' && /4 elements moved out of subprocess "Outer" into the process/.test(r4.toast)
      && r4.undoInner === 'Outer' && r4.undoDeep === 'Deep', JSON.stringify(r4));

    // L5 delete S2 alone: its task moves into S1
    await open();
    const r5 = await ev(cmd, `(function(){ deleteNode(H.node('Deep').uid); return { deep: H.parentInExport('Deep task'), toast: H.toast() }; })()`);
    leg('L5 delete S2 moves its task into S1, says so', r5.deep === 'Outer' && /1 element moved out of subprocess "Deep" into subprocess "Outer"/.test(r5.toast), JSON.stringify(r5));

    // L6 multi-select delete through the real keydown handler
    await open();
    const r6 = await ev(cmd, `(function(){ var s1 = H.node('Outer'), s2 = H.node('Deep');
      selection = { kind: 'node', id: s1.id }; multiSelect = new Set([s1.id, s2.id]);
      var h0 = _history.length;
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Delete', bubbles: true }));
      var out = { gone: !H.node('Outer') && !H.node('Deep'), inner: H.parentInExport('Inner task'), deep: H.parentInExport('Deep task'),
        hist: _history.length - h0, toast: H.toast() };
      undo(); out.undoInner = H.parentInExport('Inner task'); out.undoDeep = H.parentInExport('Deep task'); return out; })()`);
    leg('L6 multi-delete of S1+S2: contents to the process, undoable', r6.gone && r6.inner === 'process' && r6.deep === 'process'
      && r6.hist === 1 && /moved out of the deleted subprocesses/.test(r6.toast) && r6.undoInner === 'Outer' && r6.undoDeep === 'Deep', JSON.stringify(r6));

    // L7 palette add
    await open();
    const r7 = await ev(cmd, `(function(){ var before = new Set(state.nodes.map(function(n){ return n.uid; }));
      var s1 = H.node('Outer'); createNodeAt('serviceTask', s1.x + 10, s1.y + 10);
      var n = state.nodes.find(function(x){ return !before.has(x.uid); }); return { made: !!n, parent: n ? (n.parent || '') : null }; })()`);
    leg('L7 a palette node is never nested', r7.made && r7.parent === '', JSON.stringify(r7));
  } catch (e) {
    legs.push({ name: 'harness', ok: false, detail: String(e && e.stack || e) });
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  if (process.exitCode === 2) return;
  let bad = 0;
  for (const l of legs) { if (!l.ok) bad++; console.log(`${l.ok ? 'ok  ' : 'FAIL'} ${l.name}${l.ok ? '' : '\n       ' + l.detail}`); }
  console.log(`T-1345: ${bad ? 'RED' : 'GREEN'} — ${legs.length - bad}/${legs.length} legs`);
  process.exitCode = bad ? 1 : 0;
}
main();
