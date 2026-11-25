// T-1504 (T-1491 GO, slice B) — add phases from the left panel's Phases section, on a map without phases: the starter
// map and Greenfield's sample with its phases stripped (tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn minus its
// categories, groups and their shapes, as the T-1491 walkthrough did).
//
//   B1 the Phases section is there; a real click on "Add phase row" adds one row with one phase across the pool, selected
//   B2 a real click on "Add phase", then on the map between two step columns, splits the phase there: the new boundary is
//      a gap between steps, the new phase is selected; four splits make five phases; undo takes the last one away, redo
//      puts it back; Esc leaves Add phase without a change
//   B3 rename one phase through the panel; the save writes standard BPMN (a root category with five values, five groups
//      with categoryValueRef, five shapes spanning the pool's full height, nothing aef: in them)
//   B4 the save read back by this designer and by the released reader (T1504_READER, default dist 0.49.0): one row, the
//      same five names at the same x ranges
//   B5 the same on Greenfield's sample stripped of its phases: row added, split at four gaps, read back here and by the
//      reader with the same phases
//   B6 a map nobody adds phases to saves exactly as the released reader saves it (the stripped sample, the starter map)
// Teeth: T1504_EDITOR=<dist 0.49.0> fails B1 (no Phases section).
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
const EDITOR = process.env.T1504_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const READER = process.env.T1504_READER || join(ROOT, 'dist', 'aef-workflow-designer-0.49.0.html');
const FIXTURE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

// Greenfield's sample without its phases: no root category, no group, no shape of a group
const strip = x => {
  const groups = [...x.matchAll(/<bpmn:group\b[^>]*\bid="([^"]+)"/g)].map(m => m[1]);
  let y = x.replace(/\s*<bpmn:category\b[\s\S]*?<\/bpmn:category>/g, '')
           .replace(/\s*<bpmn:group\b[^>]*?(?:\/>|>[\s\S]*?<\/bpmn:group>)/g, '');
  for (const g of groups) y = y.replace(new RegExp(`\\s*<bpmndi:BPMNShape\\b[^>]*\\bbpmnElement="${g}"[\\s\\S]*?</bpmndi:BPMNShape>`), '');
  return y;
};
const STRIPPED = strip(readFileSync(FIXTURE, 'utf8'));

const doc = mkdtempSync(join(tmpdir(), 't1504-doc-'));
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
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1504-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  const open = async page => {
    for (const pass of [0, 1]) {
      await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/${page}` });
      for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
      if (!pass) await ev(`(function(){ try { localStorage.clear(); sessionStorage.clear(); } catch (e) {} return true; })()`);
    }
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
  const sel = () => ev(`selection ? JSON.stringify(selection) : 'none'`);
  const typeField = async (label, value) => ev(`(function(){
    var w = Array.from(document.querySelectorAll('#properties .field')).find(function(f){ var l = f.querySelector('.field-label'); return l && l.firstChild && l.firstChild.textContent.trim() === ${JSON.stringify(label)}; });
    if (!w) return false; var i = w.querySelector('input, textarea'); i.focus(); i.value = ${JSON.stringify(value)};
    i.dispatchEvent(new Event('input', { bubbles: true })); i.blur(); return true; })()`);
  const adopt = x => ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); if (typeof openingZoom === 'function') openingZoom(); return true; })(${JSON.stringify(x)})`);
  const poolSpan = () => ev(`(function(){ var b = document.querySelector('#g-pool > .pool-border'); return { left: +b.getAttribute('x') + LANE_HEADER, right: +b.getAttribute('x') + +b.getAttribute('width'), y: +b.getAttribute('y'), h: +b.getAttribute('height') }; })()`);
  // splits the row at the gaps nearest four evenly spread points; returns the phases after each split and what was hit
  const splitFour = async () => {
    const gaps = await ev(`phaseStepGaps(state)`);
    const P = await poolSpan();
    const picks = [];
    for (const f of [0.2, 0.4, 0.6, 0.8]) { const want = gaps[Math.floor(f * gaps.length)]; if (want != null && !picks.includes(want)) picks.push(want); }
    const out = [];
    for (const g of picks) {
      await click('#palette-add-phase');
      const m = await ev(`mode`);
      const hit = await clickMap(g + 3, P.y + 70);
      out.push({ g, m, hit, sel: await sel(), mode: await ev(`mode`), n: (await ev(PHASES)).length });
    }
    return { gaps, picks, out };
  };

  // ── the starter map ──
  await open('designer.html');
  const starterSave0 = await ev(`buildBpmnXml(state)`);
  const hasSection = await ev(`!!document.getElementById('palette-add-phase-row') && !!document.getElementById('palette-add-phase')`);
  const okRow = hasSection && await click('#palette-add-phase-row');
  const P = await poolSpan();
  const ph1 = await ev(PHASES);
  const s1 = await sel();
  leg(hasSection && okRow && ph1.length === 1 && Math.abs(ph1[0].x1 - (P.left + 2)) <= 2 && Math.abs(ph1[0].x2 - (P.right - 2)) <= 2
      && /"kind":"phase"/.test(s1) && s1.includes(ph1[0].id),
    `B1 the Phases section adds a row with one phase across the pool, selected`, JSON.stringify({ hasSection, okRow, ph1, P, s1 }).slice(0, 300));

  // B2
  const sp = await splitFour();
  const ph5 = await ev(PHASES);
  const gapsHit = ph5.slice(1).every(p => sp.gaps.some(g => Math.abs(g - p.x1 + 2) <= 1.5));
  const lastSel = sp.out.length ? sp.out[sp.out.length - 1].sel : '';
  const newest = ph5.find(p => lastSel.includes(`"${p.id}"`));
  await ev(`undo()`);
  const afterUndo = (await ev(PHASES)).length;
  await ev(`redo()`);
  const afterRedo = (await ev(PHASES)).length;
  const saveBeforeEsc = await ev(`buildBpmnXml(state)`);
  await click('#palette-add-phase');
  const inMode = await ev(`mode`);
  // hovering a gap draws the dashed line where the split would be (cleared again by Esc)
  { const gs = await ev(`phaseStepGaps(state)`), Pq = await poolSpan(); const g = gs[1];
    const r = await ev(`(function(){ var sc = svg.parentElement, m = svg.getScreenCTM(), b = sc.getBoundingClientRect();
      sc.scrollLeft += (m.a * ${g + 3} + m.e) - (b.left + b.width / 2); m = svg.getScreenCTM(); return { x: m.a * ${g + 3} + m.e, y: m.d * ${Pq.y + 70} + m.f }; })()`);
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y }); await frames(); }
  const preview = await ev(`(function(){ var l = document.querySelector('[data-phase-split-preview]'); return l ? Math.round(+l.getAttribute('x1')) : null; })()`);
  await cl.cmd('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
  await cl.cmd('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
  const escMode = await ev(`mode`);
  const saveAfterEsc = await ev(`buildBpmnXml(state)`);
  leg(ph5.length === 5 && sp.out.every(o => o.m === 'phase-split' && o.hit && o.mode === 'select') && gapsHit && !!newest
      && afterUndo === 4 && afterRedo === 5 && inMode === 'phase-split' && preview != null && escMode === 'select' && !(await ev(`!!document.querySelector('[data-phase-split-preview]')`)) && saveBeforeEsc === saveAfterEsc,
    `B2 Add phase + a click splits at the nearest step gap (4 splits → 5 phases), the new one selected; undo/redo; Esc changes nothing`,
    JSON.stringify({ n: ph5.length, out: sp.out, gapsHit, newest: !!newest, afterUndo, afterRedo, inMode, preview, escMode, escSame: saveBeforeEsc === saveAfterEsc }).slice(0, 400));

  // B3
  const target = (await ev(PHASES))[2];
  await click(`#g-phases [data-phase-id="${target.id}"]`);
  await typeField('Name', 'Fulfilment');
  const saved = await ev(`buildBpmnXml(state)`);
  const cats = [...saved.matchAll(/<bpmn:category\b[\s\S]*?<\/bpmn:category>/g)].map(m => m[0]);
  const vals = cats.length === 1 ? [...cats[0].matchAll(/<bpmn:categoryValue\b[^>]*\bid="([^"]+)"[^>]*\bvalue="([^"]*)"/g)] : [];
  const groups = [...saved.matchAll(/<bpmn:group\b[^>]*\bid="([^"]+)"[^>]*\bcategoryValueRef="([^"]+)"/g)];
  const shapes = groups.map(g => new RegExp(`<bpmndi:BPMNShape\\b[^>]*bpmnElement="${g[1]}"[^>]*>\\s*<dc:Bounds\\b[^>]*?\\sx="([^"]+)" y="([^"]+)" width="([^"]+)" height="([^"]+)"`).exec(saved));
  const Pn = await poolSpan();
  const full = shapes.every(s => s && +s[2] <= Pn.y + 1 && +s[2] + +s[4] >= Pn.y + Pn.h - 1);
  const noAef = cats.every(c => !/aef:/.test(c)) && groups.every(g => !/aef:/.test(g[0]));
  const refsOk = groups.every(g => vals.some(v => v[1] === g[2]));
  leg(cats.length === 1 && vals.length === 5 && groups.length === 5 && refsOk && full && noAef && vals.some(v => v[2] === 'Fulfilment'),
    `B3 renamed through the panel; the save is standard BPMN: one root category with five values, five groups, five full-height shapes, no aef:`,
    JSON.stringify({ cats: cats.length, vals: vals.map(v => v[2]), groups: groups.length, refsOk, full, noAef }).slice(0, 300));

  // B4
  const want = await ev(PHASES);
  const sig = a => JSON.stringify(a.map(p => [p.name, p.x1, p.x2]));
  await adopt(saved);
  const here = await ev(PHASES);
  let reader = null, readerStarter0 = null;
  if (existsSync(join(doc, 'reader.html'))) {
    await open('reader.html');
    readerStarter0 = await ev(`buildBpmnXml(state)`);
    await adopt(saved);
    reader = await ev(PHASES);
  }
  leg(sig(here) === sig(want) && reader && sig(reader) === sig(want),
    `B4 read back here and by the released reader: the same five phases at the same x ranges`,
    JSON.stringify({ want: sig(want), here: sig(here), reader: reader && sig(reader) }).slice(0, 400));

  // ── Greenfield's sample, stripped of its phases ──
  let readerStripped0 = null;
  if (existsSync(join(doc, 'reader.html'))) { await adopt(STRIPPED); readerStripped0 = await ev(`buildBpmnXml(state)`); }
  await open('designer.html');
  await adopt(STRIPPED);
  await frames();
  const strippedSave0 = await ev(`buildBpmnXml(state)`);
  const noneAtFirst = (await ev(PHASES)).length === 0;
  await click('#palette-add-phase-row');
  const g1 = (await ev(PHASES)).length;
  const gsp = await splitFour();
  const gWant = await ev(PHASES);
  const gSaved = await ev(`buildBpmnXml(state)`);
  await adopt(gSaved);
  const gHere = await ev(PHASES);
  let gReader = null;
  if (existsSync(join(doc, 'reader.html'))) { await open('reader.html'); await adopt(gSaved); gReader = await ev(PHASES); }
  leg(noneAtFirst && g1 === 1 && gWant.length === 5 && sig(gHere) === sig(gWant) && gReader && sig(gReader) === sig(gWant),
    `B5 Greenfield's sample without phases: a row added and split four times at step gaps; read back here and by the reader the same`,
    JSON.stringify({ noneAtFirst, g1, n: gWant.length, out: gsp.out.map(o => o.hit), want: sig(gWant), here: sig(gHere), reader: gReader && sig(gReader) }).slice(0, 400));

  if (process.env.T1504_DUMP) { const D = process.env.T1504_DUMP; mkdirSync(D, { recursive: true });
    for (const [k, v] of Object.entries({ saved, gSaved, starterSave0, readerStarter0, strippedSave0, readerStripped0 })) if (v != null) writeFileSync(join(D, k + '.bpmn'), v); }
  // B6
  // the workflowMeta uuid is minted at each open of a map that has none (both versions), so it is left out of the compare
  const nu = x => x == null ? null : x.replace(/\buuid="[0-9a-f-]{36}"/g, 'uuid="*"');
  leg(readerStarter0 != null && nu(starterSave0) === nu(readerStarter0) && readerStripped0 != null && nu(strippedSave0) === nu(readerStripped0),
    `B6 a map nobody adds phases to saves exactly as the released reader saves it (starter, stripped sample)`,
    JSON.stringify({ starter: nu(starterSave0) === nu(readerStarter0), stripped: nu(strippedSave0) === nu(readerStripped0) }));

  if (process.env.T1504_SHOTS) {
    const D = process.env.T1504_SHOTS; mkdirSync(D, { recursive: true });
    for (const W of [1024, 1440, 1920]) {
      await open('designer.html');
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
      await adopt(STRIPPED); await frames();
      let s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(D, `palette-${W}.png`), Buffer.from(s.data, 'base64'));
      await click('#palette-add-phase-row'); await sleep(300);
      s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(D, `row-added-${W}.png`), Buffer.from(s.data, 'base64'));
      const gaps = await ev(`phaseStepGaps(state)`); const Q = await poolSpan();
      await click('#palette-add-phase');
      const g = gaps[Math.floor(gaps.length / 2)];
      const r = await ev(`(function(){ var m = svg.getScreenCTM(); return { x: m.a * ${g + 3} + m.e, y: m.d * ${Q.y + 70} + m.f }; })()`);
      await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y }); await sleep(200);
      s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(D, `split-preview-${W}.png`), Buffer.from(s.data, 'base64'));
      await cl.cmd('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
      await cl.cmd('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
      await splitFour(); await sleep(300);
      s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(D, `five-phases-${W}.png`), Buffer.from(s.data, 'base64'));
    }
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  }
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
