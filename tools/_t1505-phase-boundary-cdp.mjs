// T-1505 (T-1491 GO, slice C) — drag the boundary between two neighbouring phases left or right; it snaps to the gap
// between steps nearest the pointer, never into a step or past either phase's far end. On Greenfield's sample
// (tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn: row 1 'Fase' Group_f1..f5 share their edges; row 2's phases
// are 6 px apart, so they have no shared edge) and on a row made with slice B (T-1504) on the starter map.
//
//   C1 a handle on each shared edge: row 1 four, on the bracket band and along the divider through the lanes; row 2 none
//   C2 a real mouse drag of the Fase 2|3 handle (bracket band) moves the boundary to the step gap nearest the release;
//      the two phases change, every other phase stays; a preview line is drawn while dragging
//   C3 dragged far past the right phase's end (along the divider through the lanes) it stops at the last gap inside
//      the pair; never into a step (no step's x range contains the boundary)
//   C4 a press and release without moving changes no byte; a slice-B boundary dragged onto its own gap changes no byte
//   C5 undo puts the boundary back; redo moves it again
//   C6 the save rewrites only the moved groups' Bounds; read back here and by the released reader (T1505_READER, default
//      dist 0.49.0) the phases are at the new boundaries
// Teeth: T1505_EDITOR=<dist 0.49.0> fails C1 (no handles).
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';
import { clearShot } from './_cdp-clear-shot.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1505_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const READER = process.env.T1505_READER || join(ROOT, 'dist', 'aef-workflow-designer-0.49.0.html');
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

const doc = mkdtempSync(join(tmpdir(), 't1505-doc-'));
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
  const udd = makeProfileDir('t1505-'); profiles.push(udd);
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
  const handles = () => ev(`Array.from(document.querySelectorAll('#g-phases .phase-boundary')).map(function(h){
    return { l: h.getAttribute('data-phase-left'), r: h.getAttribute('data-phase-right'), row: h.getAttribute('data-boundary-row'),
             tall: +h.getAttribute('height') > 40 }; })`);
  // map x -> screen x (and a screen point on a handle), after scrolling the map so map x is in the middle
  const toScreen = async (x, y) => ev(`(function(){ var sc = svg.parentElement, m = svg.getScreenCTM(), b = sc.getBoundingClientRect();
    sc.scrollLeft += (m.a * ${x} + m.e) - (b.left + b.width / 2); m = svg.getScreenCTM();
    return { x: m.a * ${x} + m.e, y: m.d * ${y} + m.f, mx: m.a }; })()`);
  // a real drag: press on the handle (l|r, the bracket one or the tall divider one), move in steps to map x, release
  const drag = async (l, r, tall, toX, opts = {}) => {
    const h = await ev(`(function(){ var hs = Array.from(document.querySelectorAll('#g-phases .phase-boundary')).filter(function(h){
        return h.getAttribute('data-phase-left') === ${JSON.stringify(l)} && h.getAttribute('data-phase-right') === ${JSON.stringify(r)}
          && (+h.getAttribute('height') > 40) === ${tall}; }); if (!hs.length) return null;
      var h = hs[0]; return { x: +h.getAttribute('x') + 3, y: +h.getAttribute('y') + Math.min(+h.getAttribute('height') / 2, 60) }; })()`);
    if (!h) return { ok: false, why: 'no handle' };
    const a = await toScreen(h.x, h.y);
    const hit = await ev(`(function(){ var e = document.elementFromPoint(${a.x}, ${a.y}); return !!e && e.classList.contains('phase-boundary'); })()`);
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: a.x, y: a.y });
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x: a.x, y: a.y, button: 'left', clickCount: 1 });
    let preview = null;
    if (!opts.still) {
      const steps = 8, dx = (toX - h.x) * a.mx;
      for (let i = 1; i <= steps; i++) {
        await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: a.x + dx * i / steps, y: a.y, button: 'left', buttons: 1 });
        if (i === steps - 1) preview = await ev(`(function(){ var l = document.querySelector('[data-phase-boundary-preview]'); return l ? Math.round(+l.getAttribute('x1')) : null; })()`);
      }
    }
    const endX = opts.still ? a.x : a.x + (toX - h.x) * a.mx;
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x: endX, y: a.y, button: 'left', clickCount: 1 });
    await frames();
    return { ok: true, hit, preview };
  };
  const nearestInside = (gaps, lo, hi, x) => { const ins = gaps.filter(g => g > lo + 12 && g < hi - 12); return ins.length ? ins.reduce((p, q) => Math.abs(q - x) < Math.abs(p - x) ? q : p) : null; };
  const save = () => ev(`buildBpmnXml(state)`);

  // ── Greenfield's sample ──
  const xml = readFileSync(FIXTURE, 'utf8');
  await open('designer.html');
  await adopt(xml); await frames();
  const H = await handles();
  const row1 = H.filter(h => h.row === 'Category_fase'), row2 = H.filter(h => h.row !== 'Category_fase');
  const pairs = [['Group_f1', 'Group_f2'], ['Group_f2', 'Group_f3'], ['Group_f3', 'Group_f4'], ['Group_f4', 'Group_f5']];
  // the cursor a person sees on the handle (a screenshot never shows the pointer; T-1505 review asked for it)
  const cursor = await ev(`(function(){ var h = document.querySelector('#g-phases .phase-boundary'); return h ? getComputedStyle(h).cursor : null; })()`);
  const c1 = pairs.every(([l, r]) => row1.some(h => h.l === l && h.r === r && !h.tall) && row1.some(h => h.l === l && h.r === r && h.tall))
    && row1.length === 8 && row2.length === 0 && cursor === 'col-resize';
  leg(c1, `C1 a handle on each shared edge: row 1 four (bracket band and divider), row 2 none (its phases are 6 px apart); its cursor is col-resize`,
    JSON.stringify({ row1: row1.length, row2: row2.length, cursor }));

  // C2
  const gaps = await ev(`phaseStepGaps(state)`);
  const before = await ev(PHASES), saved0 = await save();
  const f2 = before.find(p => p.id === 'Group_f2'), f3 = before.find(p => p.id === 'Group_f3');
  const want2 = nearestInside(gaps, f2.x1 - 2, f3.x2 + 2, 1168 + 150);
  const d2 = await drag('Group_f2', 'Group_f3', false, 1168 + 150);
  const after2 = await ev(PHASES);
  const g2 = after2.find(p => p.id === 'Group_f2'), g3 = after2.find(p => p.id === 'Group_f3');
  const others2 = after2.filter(p => !['Group_f2', 'Group_f3'].includes(p.id));
  const same2 = others2.every(p => { const o = before.find(q => q.id === p.id); return o && o.x1 === p.x1 && o.x2 === p.x2; });
  const divider2 = await ev(`(function(){ var l = document.querySelector('#g-phases [data-phase-divider="Group_f3"]'); return l ? Math.round(+l.getAttribute('x1')) : null; })()`);
  leg(d2.ok && d2.hit && want2 != null && g2.x2 === Math.round(want2) - 2 && g3.x1 === Math.round(want2) + 2 && same2
      && d2.preview === Math.round(want2) && divider2 === Math.round(want2),
    `C2 a real drag of the Fase 2|3 handle moves the boundary to the step gap nearest the release (${want2}); the other phases stay; previewed`,
    JSON.stringify({ d2, want2, f2: [g2.x1, g2.x2], f3: [g3.x1, g3.x2], same2, divider2 }));

  // C3
  const f4 = after2.find(p => p.id === 'Group_f4');
  const want3 = nearestInside(gaps, g3.x1 - 2, f4.x2 + 2, 99999);
  const d3 = await drag('Group_f3', 'Group_f4', true, f4.x2 + 600);
  const after3 = await ev(PHASES);
  const h3 = after3.find(p => p.id === 'Group_f3'), h4 = after3.find(p => p.id === 'Group_f4');
  const steps = await ev(`state.nodes.map(function(n){ var d = dims(n); return [n.x, n.x + d.w]; })`);
  const inStep = b => steps.some(([a, z]) => b > a + 0.5 && b < z - 0.5);
  leg(d3.ok && d3.hit && want3 != null && h4.x1 === Math.round(want3) + 2 && h4.x2 === f4.x2 && !inStep(want3) && !inStep(want2),
    `C3 dragged along the divider far past Fase 4's end, the boundary stops at the last gap inside the pair (${want3}); no boundary inside a step`,
    JSON.stringify({ d3, want3, f3: [h3.x1, h3.x2], f4: [h4.x1, h4.x2] }));

  // C5
  await ev(`undo()`);
  const undone = await ev(PHASES);
  await ev(`redo()`);
  const redone = await ev(PHASES);
  leg(sig(undone) === sig(after2) && sig(redone) === sig(after3), `C5 undo puts the Fase 3|4 boundary back, redo moves it again`,
    JSON.stringify({ undone: sig(undone).slice(0, 120), redone: sig(redone).slice(0, 120) }));

  // C6
  const saved = await save();
  const B = saved0.split('\n'), A = new Set(saved.split('\n'));
  const changed = B.filter(l => !A.has(l));
  const onlyBounds = changed.length > 0 && changed.every(l => /bpmnElement="Group_f[234]"/.test(l) || /<dc:Bounds/.test(l));
  const movedGroups = new Set(changed.map(l => (/Group_f\d/.exec(l) || [])[0]).filter(Boolean));
  await adopt(saved); await frames();
  const here = await ev(PHASES);
  let reader = null;
  if (existsSync(join(doc, 'reader.html'))) { await open('reader.html'); await adopt(saved); await frames(); reader = await ev(PHASES); }
  const r1 = a => sig(a.filter(p => p.row === '0'));
  leg(onlyBounds && [...movedGroups].every(g => ['Group_f2', 'Group_f3', 'Group_f4'].includes(g)) && r1(here) === r1(after3) && reader && r1(reader) === r1(after3),
    `C6 the save rewrites only the moved groups' Bounds; read back here and by the released reader at the new boundaries`,
    JSON.stringify({ changed: changed.length, movedGroups: [...movedGroups], here: r1(here) === r1(after3), reader: reader && r1(reader) === r1(after3) }));

  // C4
  await open('designer.html');
  await adopt(xml); await frames();
  const s0 = await save();
  const d4 = await drag('Group_f1', 'Group_f2', false, 0, { still: true });
  const s1 = await save();
  await open('designer.html');   // the starter map: a slice-B row split once at a gap, its boundary dragged onto its own gap
  await ev(`(function(){ phaseRowAdd(); var g = phaseStepGaps(state); var P = gPool.querySelector('.pool-border'); phaseSplitAt(g[Math.floor(g.length / 2)], +P.getAttribute('y') + 60); return true; })()`);
  await frames();
  const sb = await ev(PHASES), sb0 = await save();
  const d4b = await drag(sb[0].id, sb[1].id, false, sb[1].x1 - 2 + 5);
  const sb1 = await save();
  leg(d4.ok && d4.hit && s0 === s1 && sb.length === 2 && d4b.ok && d4b.hit && sb0 === sb1,
    `C4 a press and release without moving changes no byte; a slice-B boundary dragged onto its own gap changes no byte`,
    JSON.stringify({ d4, still: s0 === s1, sb: sb.length, d4b, ownGap: sb0 === sb1 }));

  if (process.env.T1505_SHOTS) {
    const D = process.env.T1505_SHOTS; mkdirSync(D, { recursive: true });
    for (const W of [1024, 1440, 1920]) {
      await open('designer.html');
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
      await adopt(xml); await frames();
      // hover the Fase 2|3 handle (its highlight), then mid-drag (the preview line), then after the release
      const h = await ev(`(function(){ var h = Array.from(document.querySelectorAll('#g-phases .phase-boundary')).find(function(h){ return h.getAttribute('data-phase-left') === 'Group_f2' && +h.getAttribute('height') < 40; }); return { x: +h.getAttribute('x') + 3, y: +h.getAttribute('y') + 10 }; })()`);
      const a = await toScreen(h.x, h.y);
      // the same place with the pointer away: the baseline for the hover shots (T-1505 review)
      await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: a.x - 200, y: a.y + 200 }); await frames(); await sleep(150);
      // close-ups through clearShot (T-1429): it refuses unless the handle itself is what is painted at its centre
      const HSEL = '#g-phases .phase-boundary[data-phase-left="Group_f2"]';
      const shotOf = () => clearShot((m, p) => cl.cmd(m, p), (c, e) => ev(e), HSEL, { pad: 150, padTop: 60, widen: false, scale: 2 });
      writeFileSync(join(D, `handle-idle-closeup-${W}.png`), await shotOf());
      // away first, then onto the handle, then wait until the page reports the hover (after the drag legs a move to the
      // same point may not re-evaluate :hover)
      await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: a.x - 200, y: a.y + 200 }); await frames();
      await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: a.x, y: a.y });
      for (let k = 0; k < 20 && !(await ev(`!!document.querySelector('#g-phases .phase-boundary:hover')`)); k++) await sleep(100);
      await sleep(150);
      let s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(D, `handle-hover-${W}.png`), Buffer.from(s.data, 'base64'));
      // a close-up of the hovered handle: in the full shot it is a few pixels wide
      writeFileSync(join(D, `handle-hover-closeup-${W}.png`), await shotOf());
      await cl.cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x: a.x, y: a.y, button: 'left', clickCount: 1 });
      for (let i = 1; i <= 6; i++) await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: a.x + 25 * a.mx * i, y: a.y, button: 'left', buttons: 1 });
      await sleep(200);
      s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(D, `dragging-${W}.png`), Buffer.from(s.data, 'base64'));
      await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x: a.x + 150 * a.mx, y: a.y, button: 'left', clickCount: 1 });
      await sleep(300);
      // the result as a whole: both phase names beside the moved edge in view (T-1505 review: at 1024 they were not) —
      // centre on the boundary, zoom out a step at a time until both names fit inside the canvas
      for (let z = 0; z < 4; z++) {
        const fits = await ev(`(function(){ var sc = svg.parentElement, b = sc.getBoundingClientRect();
          var g2 = document.querySelector('#g-phases [data-phase="Group_f2"] text'), g3 = document.querySelector('#g-phases [data-phase="Group_f3"] text');
          var d = document.querySelector('#g-phases [data-phase-divider="Group_f3"]'); if (!g2 || !g3 || !d) return true;
          var m = svg.getScreenCTM(), dx = m.a * +d.getAttribute('x1') + m.e; sc.scrollLeft += dx - (b.left + b.width / 2);
          var r2 = g2.getBoundingClientRect(), r3 = g3.getBoundingClientRect();
          return r2.left >= b.left + 4 && r3.right <= b.right - 4; })()`);
        if (fits) break;
        await click('#btn-zoom-out'); await sleep(250);
      }
      await frames();
      // before and after in the SAME view, so the move reads by comparison (T-1505 review: moved-1920 alone could not be
      // read with confidence): undo, capture 'before', redo, capture 'moved'; the scroll and zoom are kept, and checked
      const view = () => ev(`(function(){ var sc = svg.parentElement; return [sc.scrollLeft, sc.scrollTop, document.getElementById('zoom-level').textContent]; })()`);
      const v1 = await view();
      await ev(`undo()`); await frames();
      await ev(`(function(v){ var sc = svg.parentElement; sc.scrollLeft = v[0]; sc.scrollTop = v[1]; return true; })(${JSON.stringify(v1)})`); await frames(); await sleep(200);
      s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(D, `before-${W}.png`), Buffer.from(s.data, 'base64'));
      await ev(`redo()`); await frames();
      await ev(`(function(v){ var sc = svg.parentElement; sc.scrollLeft = v[0]; sc.scrollTop = v[1]; return true; })(${JSON.stringify(v1)})`); await frames(); await sleep(200);
      const v2 = await view();
      if (JSON.stringify(v1) !== JSON.stringify(v2)) console.log(`NOTE shots ${W}: view moved ${JSON.stringify(v1)} -> ${JSON.stringify(v2)}`);
      s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(D, `moved-${W}.png`), Buffer.from(s.data, 'base64'));
    }
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  }
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
