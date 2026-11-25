// T-1513 — a phase that spans the pool keeps spanning it when an edit makes the pool taller, so lanes can be added after
// phases: before, a step placed in a lane added below the phases put the saved file's step band (T-1510) below the
// groups, and after a save and reopen every phase vanished.
//
//   P1 the starter map: a phase row made with slice B (split twice), then a lane added below (a real click on Add Lane)
//      and a step in it; saved; reopened here and by the released reader (T1513_READER, default dist 0.50.0): the three
//      phases are drawn, at the same x ranges
//   P2 the same on Greenfield's sample (tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn, 'Fase' and 'Fase in
//      Salesforce'), two lanes and two steps: every phase drawn after the reopen, at the same x ranges
//   P3 a real drag of the last lane's resize handle makes the pool taller: the phases' shapes reach the new pool bottom
//      (only their Bounds height changed); undo puts the shapes back as they were
//   P4 a map nobody edits is not changed: Greenfield's sample and a reopened designer save with phases, rendered again and
//      at another window width, save exactly as when opened
// Teeth: T1513_EDITOR=<dist 0.50.0> fails P1 (the phases vanish after the reopen).
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
const EDITOR = process.env.T1513_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const READER = process.env.T1513_READER || join(ROOT, 'dist', 'aef-workflow-designer-0.50.0.html');
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

const doc = mkdtempSync(join(tmpdir(), 't1513-doc-'));
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
  const udd = makeProfileDir('t1513-'); profiles.push(udd);
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
  const adopt = x => ev(`(function(x){ adoptImportedXml(x, { userImport: true }); if (typeof openingZoom === 'function') openingZoom(); return true; })(${JSON.stringify(x)})`);
  const sig = a => JSON.stringify(a.map(p => [p.id, p.x1, p.x2]));
  const save = () => ev(`buildBpmnXml(state)`);
  const groupBounds = () => ev(`(function(){ var pk = state.procKept || {}; return (pk.di || []).filter(function(d){ return /Group/.test(d.ref); }).map(function(d){
      var m = /<(?:[\\w.-]+:)?Bounds\\b[^>]*>/.exec(d.xml); return [d.ref, m ? m[0].replace(/\\s+xmlns:\\w+="[^"]*"/g, '') : null]; }); })()`);
  const poolBottom = () => ev(`(function(){ var P = gPool.querySelector('.pool-border'); return +P.getAttribute('y') + +P.getAttribute('height'); })()`);
  // add a lane below with a real click on Add Lane, then a step in it (the step is what moves the saved step band)
  const laneAndStep = async () => {
    const lanes0 = await ev(`state.lanes.length`);
    const ok = await click('#btn-add-lane');
    const at = await ev(`(function(){ var L = state.lanes[state.lanes.length - 1]; var bgs = Array.from(document.querySelectorAll('#g-pool .lane-bg'));
      var bg = bgs[bgs.length - 1]; if (!bg) return null; var x = +bg.getAttribute('x') + +bg.getAttribute('width') / 2, y = +bg.getAttribute('y') + +bg.getAttribute('height') / 2;
      createNodeAt('serviceTask', x, y); renderAll(); return { lane: L.id, x: Math.round(x), y: Math.round(y),
        inLane: state.nodes.some(function(n){ return n.lane === L.id; }) }; })()`);
    await frames();
    return { ok, lanes: [lanes0, await ev(`state.lanes.length`)], at };
  };

  // ── P1: the starter map ──
  await open('designer.html');
  await ev(`(function(){ phaseRowAdd(); var g = phaseStepGaps(state), P = gPool.querySelector('.pool-border'), y = +P.getAttribute('y') + 60;
    phaseSplitAt(g[Math.floor(g.length / 3)], y); phaseSplitAt(g[Math.floor(2 * g.length / 3)], y); return true; })()`);
  await frames();
  const p1want = await ev(PHASES);
  const p1la = await laneAndStep();
  const p1saved = await save();
  await adopt(p1saved); await frames();
  const p1here = await ev(PHASES);
  let p1reader = null;
  if (existsSync(join(doc, 'reader.html'))) { await open('reader.html'); await adopt(p1saved); await frames(); p1reader = await ev(PHASES); }
  leg(p1want.length === 3 && p1la.ok && p1la.lanes[1] === p1la.lanes[0] + 1 && p1la.at && p1la.at.inLane
      && sig(p1here) === sig(p1want) && p1reader && sig(p1reader) === sig(p1want),
    `P1 starter map: phases, then a lane added below and a step in it; saved and reopened here and by the reader: the three phases drawn, same x ranges`,
    JSON.stringify({ want: sig(p1want), la: p1la, here: sig(p1here), reader: p1reader && sig(p1reader) }).slice(0, 400));

  // ── P2: Greenfield's sample ──
  const gxml = readFileSync(FIXTURE, 'utf8');
  await open('designer.html');
  await adopt(gxml); await frames();
  const p2want = await ev(PHASES);
  const p2la = await laneAndStep();
  const p2lb = await laneAndStep();   // a second lane and step further down, so the step band reaches below the file's groups
  const p2saved = await save();
  await adopt(p2saved); await frames();
  const p2here = await ev(PHASES);
  let p2reader = null;
  if (existsSync(join(doc, 'reader.html'))) { await open('reader.html'); await adopt(p2saved); await frames(); p2reader = await ev(PHASES); }
  leg(p2want.length === 11 && p2la.at && p2la.at.inLane && p2lb.at && p2lb.at.inLane && sig(p2here) === sig(p2want) && p2reader && sig(p2reader) === sig(p2want),
    `P2 Greenfield's sample: two lanes added below, a step in each; saved and reopened here and by the reader: all eleven phases drawn, same x ranges`,
    JSON.stringify({ n: p2want.length, steps: [p2la.at, p2lb.at], here: p2here.length, reader: p2reader && p2reader.length, same: sig(p2here) === sig(p2want) }).slice(0, 300));

  // ── P3: a real lane-resize drag; undo ──
  await open('designer.html');
  await ev(`(function(){ phaseRowAdd(); var g = phaseStepGaps(state), P = gPool.querySelector('.pool-border'); phaseSplitAt(g[Math.floor(g.length / 2)], +P.getAttribute('y') + 60); return true; })()`);
  await frames();
  const b0 = await groupBounds();
  const pb0 = await poolBottom();
  // zoomed out, so the last lane's bottom edge sits well inside the canvas: the resize listens on the map itself, and a
  // drag that leaves it (onto the status bar) stops resizing
  await click('#btn-zoom-out'); await sleep(200); await click('#btn-zoom-out'); await sleep(200);
  const hnd = await ev(`(function(){ var hs = document.querySelectorAll('.lane-resize-handle .lane-resize-hit');   /* not the pool's right-edge handle, which shares the class */ var h = hs[hs.length - 1]; if (!h) return null; h.scrollIntoView({ block: 'nearest', inline: 'nearest' });
    var r = h.getBoundingClientRect(); var c = svg.parentElement.getBoundingClientRect();
    /* 2 px inside the 8 px handle: the pool border's stroke lies on its centreline and is drawn above it */
    var x = Math.max(r.left, c.left) + 40, y = r.top + 2, e = document.elementFromPoint(x, y);
    return { x: x, y: y, bottom: c.bottom, hit: !!e && e.classList.contains('lane-resize-hit') }; })()`);
  if (hnd) {
    await frames();
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: hnd.x, y: hnd.y });
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x: hnd.x, y: hnd.y, button: 'left', clickCount: 1 });
    const room = Math.min(120, hnd.bottom - 30 - hnd.y);
    for (let i = 1; i <= 8; i++) await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: hnd.x, y: hnd.y + room * i / 8, button: 'left', buttons: 1 });
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x: hnd.x, y: hnd.y + room, button: 'left', clickCount: 1 });
    await frames();
  }
  const pb1 = await poolBottom();
  const b1 = await groupBounds();
  const num = (t, k) => +((new RegExp(`\\s${k}="([^"]+)"`)).exec(t) || [])[1];
  const reach = b1.length > 0 && b1.every(([, t]) => Math.abs(num(t, 'y') + num(t, 'height') - pb1) <= 1);
  const onlyH = b0.length === b1.length && b0.every(([r, t], i) => b1[i][0] === r && t.replace(/\sheight="[^"]*"/, '') === b1[i][1].replace(/\sheight="[^"]*"/, ''));
  await ev(`undo()`); await frames();
  const b2 = await groupBounds();
  // compared by value: an undo re-reads the map from its saved XML, which re-serialises a kept shape (' />' -> '/>')
  const nums = b => JSON.stringify(b.map(([r, t]) => [r, ...['x', 'y', 'width', 'height'].map(k => Math.round(num(t, k) * 10) / 10)]));
  leg(!!hnd && hnd.hit && pb1 > pb0 + 50 && reach && onlyH && nums(b2) === nums(b0),
    `P3 a real drag of the last lane's resize handle makes the pool taller: the phases' shapes reach the new bottom (only their height changed); undo puts them back`,
    JSON.stringify({ hit: hnd && hnd.hit, pb0, pb1, reach, onlyH, undone: nums(b2) === nums(b0), b0: nums(b0), b2: nums(b2) }).slice(0, 300));

  // ── P4: no edit, no change ──
  const rerender = async W => { await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 850, deviceScaleFactor: 1, mobile: false }); await ev(`renderAll()`); await frames(); await sleep(150); };
  await open('designer.html');
  await adopt(gxml); await frames();
  const g0 = await save();
  await rerender(1024); await rerender(1920); await rerender(1440);
  const g1 = await save();
  await adopt(p1saved); await frames();
  const s0 = await save();
  await rerender(1024); await rerender(1920); await rerender(1440);
  const s1 = await save();
  leg(g0 === g1 && s0 === s1, `P4 a map nobody edits is not changed: Greenfield's sample and a reopened designer save with phases, re-rendered at other widths, save as opened`,
    JSON.stringify({ greenfield: g0 === g1, designerSave: s0 === s1 }));
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
