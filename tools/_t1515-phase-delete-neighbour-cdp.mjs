// T-1515 (T-1491 walkthrough step 7) — deleting a phase gives its range to the neighbour it shares an edge with, so a
// row has no hole: the left neighbour widens to the deleted phase's end; else (a row's first phase, or no left one
// touching) the right one starts where it started. A phase that touches no neighbour is deleted as before. On
// Greenfield's sample (tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn: 'Fase' Group_f1..f5 share their edges;
// 'Fase in Salesforce' Group_s1..s6 are 6 px apart).
//
//   D1 delete 'Fase' phase 3 with the Delete key: phase 2 widens over its range; the rest stay; one undo restores it
//   D2 delete 'Fase' phase 1: phase 2 starts where it started; undo
//   D3 delete a 'Fase in Salesforce' phase: its neighbours stay; undo
//   D4 the save after D1 changes only the deleted phase's elements and the neighbour's Bounds; read back here and by the
//      released reader (T1515_READER, default dist 0.50.0) the same
// Teeth: T1515_EDITOR=<dist 0.50.0> fails D1, D2 (the stretch stays empty).
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
const EDITOR = process.env.T1515_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const READER = process.env.T1515_READER || join(ROOT, 'dist', 'aef-workflow-designer-0.50.0.html');
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

const doc = mkdtempSync(join(tmpdir(), 't1515-doc-'));
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
  const udd = makeProfileDir('t1515-'); profiles.push(udd);
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
  const save = () => ev(`buildBpmnXml(state)`);
  const ranges = a => Object.fromEntries(a.map(p => [p.id, [p.x1, p.x2]]));
  // select a phase as a person does (its panel), then the Delete key
  const del = async gid => {
    await ev(`(function(){ selection = { kind: 'phase', id: ${JSON.stringify(gid)} }; renderAll(); return true; })()`); await frames();
    await cl.cmd('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Delete', code: 'Delete', windowsVirtualKeyCode: 46 });
    await cl.cmd('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Delete', code: 'Delete', windowsVirtualKeyCode: 46 });
    await frames();
    return ranges(await ev(PHASES));
  };
  const xml = readFileSync(FIXTURE, 'utf8');
  await open('designer.html');
  await adopt(xml); await frames();
  const R0 = ranges(await ev(PHASES));
  const saved0 = await save();
  const same = (a, ids) => ids.every(k => a[k] && R0[k] && a[k][0] === R0[k][0] && a[k][1] === R0[k][1]);

  // D1 a middle phase: its left neighbour takes its range
  const d1 = await del('Group_f3');
  const savedD1 = await save();
  await ev(`undo()`); await frames();
  const u1 = ranges(await ev(PHASES));
  leg(!d1.Group_f3 && d1.Group_f2 && d1.Group_f2[0] === R0.Group_f2[0] && d1.Group_f2[1] === R0.Group_f3[1]
      && same(d1, ['Group_f1', 'Group_f4', 'Group_f5', 'Group_s1', 'Group_s6']) && JSON.stringify(u1) === JSON.stringify(R0),
    `D1 deleting 'Fase' phase 3 (Delete key): phase 2 widens over its range; the rest stay; one undo restores it`,
    JSON.stringify({ f2: d1.Group_f2, want: [R0.Group_f2[0], R0.Group_f3[1]], undone: JSON.stringify(u1) === JSON.stringify(R0) }));

  // D2 a row's first phase: the second starts where it started
  const d2 = await del('Group_f1');
  await ev(`undo()`); await frames();
  const u2 = ranges(await ev(PHASES));
  leg(!d2.Group_f1 && d2.Group_f2 && d2.Group_f2[0] === R0.Group_f1[0] && d2.Group_f2[1] === R0.Group_f2[1]
      && same(d2, ['Group_f3', 'Group_f4', 'Group_f5']) && JSON.stringify(u2) === JSON.stringify(R0),
    `D2 deleting 'Fase' phase 1: phase 2 starts where it started; one undo restores it`,
    JSON.stringify({ f2: d2.Group_f2, want: [R0.Group_f1[0], R0.Group_f2[1]] }));

  // D3 a phase that touches no neighbour ('Fase in Salesforce' phases are 6 px apart): the neighbours stay
  const d3 = await del('Group_s3');
  await ev(`undo()`); await frames();
  const u3 = ranges(await ev(PHASES));
  leg(!d3.Group_s3 && same(d3, ['Group_s2', 'Group_s4', 'Group_f1', 'Group_f2', 'Group_f3', 'Group_f4', 'Group_f5']) && JSON.stringify(u3) === JSON.stringify(R0),
    `D3 deleting a 'Fase in Salesforce' phase (no shared edge): its neighbours stay as they were; one undo restores it`,
    JSON.stringify({ s2: d3.Group_s2, s4: d3.Group_s4 }));

  // D4 the save after D1: only the deleted elements and Group_f2's Bounds changed; read back here and by the reader
  const B = saved0.split('\n'), A = new Set(savedD1.split('\n'));
  const gone = B.filter(l => !A.has(l));
  const allowed = l => /Group_f3|CategoryValue_f3/.test(l) || (/bpmnElement="Group_f2"/.test(l) || /<dc:Bounds/.test(l));
  const f2Bounds = savedD1.match(/bpmnElement="Group_f2"[^>]*>\s*<dc:Bounds[^>]*>/);
  await adopt(savedD1); await frames();
  const here = ranges(await ev(PHASES));
  let reader = null;
  if (existsSync(join(doc, 'reader.html'))) { await open('reader.html'); await adopt(savedD1); await frames(); reader = ranges(await ev(PHASES)); }
  leg(gone.length > 0 && gone.every(allowed) && !!f2Bounds && JSON.stringify(here) === JSON.stringify(d1) && reader && JSON.stringify(reader) === JSON.stringify(d1),
    `D4 the save changes only the deleted phase's elements and the neighbour's Bounds; read back here and by the released reader the same`,
    JSON.stringify({ changed: gone.length, stray: gone.filter(l => !allowed(l)).map(l => l.trim().slice(0, 80)), here: JSON.stringify(here) === JSON.stringify(d1), reader: reader && JSON.stringify(reader) === JSON.stringify(d1) }));
  if (process.env.T1515_SHOTS) {
    const D = process.env.T1515_SHOTS; mkdirSync(D, { recursive: true });
    for (const W of [1024, 1440, 1920]) {
      await open('designer.html');
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
      await adopt(xml); await frames();
      // the same view before and after: centred on 'Fase' phases 2-3, zoomed out only until both are in view
      for (let z = 0; z < 4; z++) {
        const fits = await ev(`(function(){ var sc = svg.parentElement, b = sc.getBoundingClientRect();
          var t2 = document.querySelector('#g-phases [data-phase="Group_f2"] path'), t4 = document.querySelector('#g-phases [data-phase="Group_f4"] path'), t3 = document.querySelector('#g-phases [data-phase="Group_f3"] path');
          var r3 = t3.getBoundingClientRect(), r2a = t2.getBoundingClientRect(); sc.scrollLeft += ((r2a.left + r3.right) / 2) - (b.left + b.width / 2); sc.scrollTop = 0; r3 = t3.getBoundingClientRect();
          var r2 = t2.getBoundingClientRect(), r4 = t4.getBoundingClientRect(); return r2.left >= b.left + 4 && r3.right <= b.right - 4; })()`);
        if (fits) break;
        await click('#btn-zoom-out'); await sleep(250);
      }
      const v = await ev(`(function(){ var sc = svg.parentElement; return [sc.scrollLeft, sc.scrollTop]; })()`);
      await ev(`(function(){ selection = { kind: 'phase', id: 'Group_f3' }; renderAll(); return true; })()`); await frames();
      await ev(`(function(v){ var sc = svg.parentElement; sc.scrollLeft = v[0]; sc.scrollTop = v[1]; return true; })(${JSON.stringify(v)})`); await frames(); await sleep(200);
      let s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(D, `before-delete-${W}.png`), Buffer.from(s.data, 'base64'));
      await cl.cmd('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Delete', code: 'Delete', windowsVirtualKeyCode: 46 });
      await cl.cmd('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Delete', code: 'Delete', windowsVirtualKeyCode: 46 });
      await frames();
      await ev(`(function(v){ var sc = svg.parentElement; sc.scrollLeft = v[0]; sc.scrollTop = v[1]; return true; })(${JSON.stringify(v)})`); await frames(); await sleep(200);
      s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(D, `after-delete-${W}.png`), Buffer.from(s.data, 'base64'));
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
