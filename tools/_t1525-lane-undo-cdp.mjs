// T-1525 — adding, deleting and resizing a lane are each one undo step. Before, addLane(), deleteLane() and the
// lane-resize gesture changed state.lanes without pushHistory(), so Ctrl+Z after a lane change restored the snapshot
// taken before the previous recorded action and undid that action as well (found in T-1513).
//
//   U1 Add Lane (a real click): undo removes only the lane, the phase row added before it stays; redo puts it back
//   U2 deleting a lane: undo brings it back, nothing before it lost; redo deletes it again
//   U3 a real drag of the last lane's resize handle: undo restores the height, nothing before it lost; redo
//   U4 a press on the handle without moving records no undo step
// Teeth: T1525_EDITOR=<dist 0.50.0> fails U1-U3.
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1525_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const READER = process.env.T1525_READER || join(ROOT, 'dist', 'aef-workflow-designer-0.49.0.html');
const FIXTURE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const strip = x => {
  const groups = [...x.matchAll(/<bpmn:group\b[^>]*\bid="([^"]+)"/g)].map(m => m[1]);
  let y = x.replace(/\s*<bpmn:category\b[\s\S]*?<\/bpmn:category>/g, '')
           .replace(/\s*<bpmn:group\b[^>]*?(?:\/>|>[\s\S]*?<\/bpmn:group>)/g, '');
  for (const g of groups) y = y.replace(new RegExp(`\\s*<bpmndi:BPMNShape\\b[^>]*\\bbpmnElement="${g}"[\\s\\S]*?</bpmndi:BPMNShape>`), '');
  return y;
};
const STRIPPED = strip(readFileSync(FIXTURE, 'utf8'));

const doc = mkdtempSync(join(tmpdir(), 't1525-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
if (existsSync(READER)) copyFileSync(READER, join(doc, 'reader.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const PHASES = `(function(){ return Array.from(document.querySelectorAll('#g-phases g[data-phase]')).map(function(g){
  var p = g.querySelector('path').getBBox(), t = g.querySelector('title'), n = g.querySelector('text');
  return { id: g.getAttribute('data-phase'), row: g.getAttribute('data-phase-row'), name: t ? t.textContent : n.textContent,
           x1: Math.round(p.x), x2: Math.round(p.x + p.width) }; }); })()`;
const profiles = [];
const dialogs = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1525-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  // a dialog (alert/confirm) blocks the page, and every later command waits on it: record its text, dismiss it, and
  // report it (pool runs at c1800044a and 8618e0661 hung 60 s in B5, a page call and then a mouse event)
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000, onEvent: m => {
    if (m.method === 'Page.javascriptDialogOpening') {
      dialogs.push(`${m.params.type}: ${String(m.params.message).slice(0, 200)}`);
      cl.cmd('Page.handleJavaScriptDialog', { accept: true }).catch(() => {});
    }
    if (m.method === 'Inspector.targetCrashed') dialogs.push('CRASH: the page crashed');
  } }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable'); await cl.cmd('Inspector.enable').catch(() => {});
  await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  const open = async page => {
    // Leave the current page first (about:blank), so it can neither autosave into storage after the clear nor answer a
    // ready check meant for the next page; then clear the origin's storage (designer and reader share it); then load.
    // Before: clear-then-reload raced both (pool run at c1800044a: CDP TIMEOUT in B5's first open after B4's reader;
    // with 1.5 s navigation latency locally: the starter and the sample saved as *_v2, a library entry written after
    // the clear).
    const origin = `http://127.0.0.1:${port}`;
    await cl.cmd('Page.navigate', { url: 'about:blank' });
    for (let k = 0; k < 100; k++) { if (await ev(`location.href === 'about:blank'`).catch(() => false)) break; await sleep(100); }
    await cl.cmd('Storage.clearDataForOrigin', { origin, storageTypes: 'local_storage,session_storage,indexeddb,cache_storage' });
    await cl.cmd('Page.navigate', { url: `${origin}/${page}` });
    for (let k = 0; k < 200; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
    await ev(`document.fonts.ready`);
  };
  const frames = () => ev(`new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); })`);
  const press = async (x, y) => { for (const type of ['mousePressed', 'mouseReleased']) await cl.cmd('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 }); await frames(); };
  const click = async sel => {
    const r = await ev(`(function(){ var e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; e.scrollIntoView({ block: 'center', inline: 'center' });
      var b = e.getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top + b.height / 2 }; })()`);
    if (!r) return false;
    await frames(); await press(r.x, r.y); return true;
  };
  // a real click on the map at map coordinates (x, y), the view panned first so the point is on screen
  const clickMap = async (x, y) => {
    // the map scrolls inside its container (wider than the screen's canvas area): scroll the point into the middle first,
    // then check that it is the map, not a panel, under the pointer
    const r = await ev(`(function(){ var sc = svg.parentElement;
      var at = function(){ var m = svg.getScreenCTM(); return { x: m.a * ${x} + m.c * ${y} + m.e, y: m.b * ${x} + m.d * ${y} + m.f }; };
      var p = at(), b = sc.getBoundingClientRect();
      sc.scrollLeft += p.x - (b.left + b.width / 2); sc.scrollTop += p.y - (b.top + b.height / 2);
      p = at(); b = sc.getBoundingClientRect();
      var e = document.elementFromPoint(p.x, p.y);
      return { x: p.x, y: p.y, in: p.x > b.left + 2 && p.x < b.right - 2 && p.y > b.top + 2 && p.y < b.bottom - 2 && !!e && svg.contains(e) }; })()`);
    if (!r.in) return false;
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    await press(r.x, r.y); return true;
  };
  // the map as it matters here: lanes (id, height), phases (row count), node count — and the undo depth
  const shape = () => ev(`JSON.stringify({ lanes: (state.lanes || []).map(function(l){ return [l.id, Math.round(l.height)]; })   /* a drag leaves a fractional height; the saved map (undo/redo snapshots) keeps it rounded */,
    phases: ((state.procKept && state.procKept.categories) || []).length, nodes: state.nodes.length })`);
  const depth = () => ev(`_history.length`);
  // a recorded action first (a phase row), so an undo that reaches past the lane change shows: the row would go too
  await open('designer.html');
  await ev(`(function(){ phaseRowAdd(); return true; })()`); await frames();
  const s0 = await shape();

  // U1 add a lane with a real click on Add Lane; undo; redo
  const okAdd = await click('#btn-add-lane');
  const s1 = await shape();
  await ev(`undo()`); await frames();
  const s1u = await shape();
  await ev(`redo()`); await frames();
  const s1r = await shape();
  leg(okAdd && JSON.parse(s1).lanes.length === JSON.parse(s0).lanes.length + 1 && s1u === s0 && s1r === s1,
    `U1 Add Lane (a real click) is one undo step: undo removes only the lane (the phase row before it stays), redo puts it back`,
    JSON.stringify({ s0, s1, s1u, s1r }).slice(0, 400));

  // U2 delete a lane; undo; redo
  const lastId = await ev(`state.lanes[state.lanes.length - 1].id`);
  await ev(`(function(){ deleteLane(${JSON.stringify(lastId)}); return true; })()`); await frames();
  const s2 = await shape();
  await ev(`undo()`); await frames();
  const s2u = await shape();
  await ev(`redo()`); await frames();
  const s2r = await shape();
  leg(JSON.parse(s2).lanes.length === JSON.parse(s1).lanes.length - 1 && s2u === s1 && s2r === s2,
    `U2 deleting a lane is one undo step: undo brings the lane back (nothing before it lost), redo deletes it again`,
    JSON.stringify({ s2, s2u, s2r }).slice(0, 300));

  // U3 a real drag of the last lane's resize handle; undo; redo
  await click('#btn-zoom-out'); await sleep(200); await click('#btn-zoom-out'); await sleep(200);
  const handle = () => ev(`(function(){ var hs = document.querySelectorAll('.lane-resize-handle .lane-resize-hit'); var h = hs[hs.length - 1]; if (!h) return null;
    h.scrollIntoView({ block: 'nearest', inline: 'nearest' }); var r = h.getBoundingClientRect(), c = svg.parentElement.getBoundingClientRect();
    /* 2 px inside the 8 px handle: the pool border's stroke lies on its centreline */
    var x = Math.max(r.left, c.left) + 40, y = r.top + 2, e = document.elementFromPoint(x, y);
    return { x: x, y: y, bottom: c.bottom, hit: !!e && e.classList.contains('lane-resize-hit') }; })()`);
  const s3a = await shape(), d3a = await depth();
  const h = await handle();
  let s3 = null, s3u = null, s3r = null;
  if (h && h.hit) {
    const room = Math.min(120, h.bottom - 30 - h.y);
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: h.x, y: h.y });
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x: h.x, y: h.y, button: 'left', clickCount: 1 });
    for (let i = 1; i <= 8; i++) await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: h.x, y: h.y + room * i / 8, button: 'left', buttons: 1 });
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x: h.x, y: h.y + room, button: 'left', clickCount: 1 });
    await frames();
    s3 = await shape();
    await ev(`undo()`); await frames();
    s3u = await shape();
    await ev(`redo()`); await frames();
    s3r = await shape();
  }
  leg(!!h && h.hit && s3 !== s3a && s3u === s3a && s3r === s3,
    `U3 a real drag of a lane's resize handle is one undo step: undo restores the height (nothing before it lost), redo resizes again`,
    JSON.stringify({ hit: h && h.hit, heights: [s3a, s3, s3u, s3r].map(x => x && JSON.parse(x).lanes.map(l => l[1]).join('/') + ' p' + JSON.parse(x).phases + ' n' + JSON.parse(x).nodes) }));

  // U4 a press on the handle without moving records no undo step
  const d4a = await depth();
  const h4 = await handle();
  if (h4 && h4.hit) {
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: h4.x, y: h4.y });
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x: h4.x, y: h4.y, button: 'left', clickCount: 1 });
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x: h4.x, y: h4.y, button: 'left', clickCount: 1 });
    await frames();
  }
  const d4b = await depth();
  leg(!!h4 && h4.hit && d4b === d4a, `U4 a press on a lane's resize handle without moving records no undo step`, JSON.stringify({ hit: h4 && h4.hit, d4a, d4b }));
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300) + (dialogs.length ? '  dialogs: ' + JSON.stringify(dialogs) : ''));
} finally {
  if (dialogs.length) leg(false, 'no dialog opened during the run', JSON.stringify(dialogs).slice(0, 400));
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
