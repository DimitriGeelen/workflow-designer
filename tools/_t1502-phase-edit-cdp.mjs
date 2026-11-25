// T-1502 (T-1491 GO, slice A) — select a phase or a phase row on the canvas and edit it in the panel, on Greenfield's
// sample (tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn; 'Fase' Group_f1..f5, 'Fase in Salesforce' Group_s1..s6).
//
//   A1 a real mouse click on the phase 'Order' selects it: panel "phase" with Name 'Order' and Row 'Fase'; a click on the
//      row label 'Fase in Salesforce' selects the row; a click on a step still selects the step
//   A2 selecting phases and rows without editing changes no saved byte
//   A3 rename 'Order' → 'Order & levering' through the panel's Name field; undo restores 'Order'; redo the rename
//   A4 write documentation on 'Order' through the panel; delete 'Productie & service' with Delete; delete the row
//      'Fase in Salesforce' from its panel
//   A5 the save: categoryValue CategoryValue_f4 value="Order &amp; levering"; Group_f4 carries the documentation; no
//      Group_f5, its shape or CategoryValue_f5; no Category_sf, no Group_s*, no shapes of them; every other line of the
//      save as before the edits
//   A6 the saved file read back by this designer and by the released reader (T1502_READER, default dist 0.48.1, the
//      first that draws phases from a designer-saved file, T-1510; 0.47.0/0.48.0 draw none from any such file): one row,
//      'Opportunity', 'Configuratie', 'Offerte & onderhandeling', 'Order & levering', at the same x ranges as before
// Teeth: T1502_EDITOR=<the 0.47.0 designer> fails A1.
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
const EDITOR = process.env.T1502_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const READER = process.env.T1502_READER || join(ROOT, 'dist', 'aef-workflow-designer-0.48.1.html');
const FIXTURE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
const DOC = 'Rule: an order is confirmed in writing\nOpen: who sends the confirmation?';
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1502-doc-'));
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
  const udd = makeProfileDir('t1502-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--disable-dev-shm-usage', '--no-sandbox', '--disable-gpu', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
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
  // a real click at the centre of the element matching sel (scrolled into view first)
  const click = async sel => {
    const r = await ev(`(function(){ var e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; e.scrollIntoView({ block: 'center', inline: 'center' });
      var b = e.getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top + b.height / 2 }; })()`);
    if (!r) return false;
    await frames();
    for (const type of ['mousePressed', 'mouseReleased']) await cl.cmd('Input.dispatchMouseEvent', { type, x: r.x, y: r.y, button: 'left', clickCount: 1 });
    await frames();
    return true;
  };
  const sel = () => ev(`selection ? JSON.stringify(selection) : 'none'`);
  // type into the panel field labelled `label` and commit (blur), as a person does
  const typeField = async (label, value) => ev(`(function(){
    var w = Array.from(document.querySelectorAll('#properties .field')).find(function(f){ var l = f.querySelector('.field-label'); return l && l.firstChild && l.firstChild.textContent.trim() === ${JSON.stringify(label)}; });
    if (!w) return false; var i = w.querySelector('input, textarea'); i.focus(); i.value = ${JSON.stringify(value)};
    i.dispatchEvent(new Event('input', { bubbles: true })); i.blur(); return true; })()`);
  const xml = readFileSync(FIXTURE, 'utf8');
  await open('designer.html');
  await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); if (typeof openingZoom === 'function') openingZoom(); return true; })(${JSON.stringify(xml)})`);
  await frames();
  const before = await ev(`buildBpmnXml(state)`);
  const phasesBefore = await ev(PHASES);
  // A1
  const okOrder = await click('#g-phases [data-phase-id="Group_f4"]');
  const s1 = await sel();
  const panel1 = await ev(`(function(){ var s = document.querySelector('[data-testid="props-phase"]'); if (!s) return null;
    var n = s.querySelector('input'); var r = s.querySelector('.field-static'); return { name: n ? n.value : null, row: r ? r.textContent : null }; })()`);
  const okRow = await click('#g-phases [data-phase-row-id="Category_sf"]');
  const s2 = await sel();
  const rowPanel = await ev(`!!document.querySelector('[data-testid="props-phase-row"]')`);
  const okStep = await click('#g-nodes [data-id]');
  const s3 = await sel();
  leg(okOrder && /"kind":"phase","id":"Group_f4"/.test(s1) && panel1 && panel1.name === 'Order' && panel1.row === 'Fase'
      && okRow && /"kind":"phaseRow","id":"Category_sf"/.test(s2) && rowPanel && /"kind":"node"/.test(s3),
    `A1 clicking 'Order' selects the phase (panel Name 'Order', Row 'Fase'); the row label selects the row; a step still selects`,
    JSON.stringify({ okOrder, s1, panel1, okRow, s2, rowPanel, s3 }).slice(0, 260));
  // A2
  const afterSelect = await ev(`buildBpmnXml(state)`);
  leg(before === afterSelect, `A2 selecting phases and rows changes no saved byte (${before.length} chars)`);
  // A3
  await click('#g-phases [data-phase-id="Group_f4"]');
  await typeField('Name', 'Order & levering');
  const renamed = await ev(`(phaseFind('Group_f4') || {}).phase ? phaseFind('Group_f4').phase.name : null`);
  await ev(`undo()`);
  const undone = await ev(`(phaseFind('Group_f4') || {}).phase ? phaseFind('Group_f4').phase.name : null`);
  await ev(`redo()`);
  const redone = await ev(`(phaseFind('Group_f4') || {}).phase ? phaseFind('Group_f4').phase.name : null`);
  leg(renamed === 'Order & levering' && undone === 'Order' && redone === 'Order & levering',
    `A3 rename through the panel, undo, redo`, JSON.stringify({ renamed, undone, redone }));
  // A4
  await ev(`(function(){ selection = { kind: 'phase', id: 'Group_f4' }; renderAll(); return true; })()`);
  await typeField('Documentation', DOC);
  await ev(`(function(){ selection = { kind: 'phase', id: 'Group_f5' }; renderAll(); return true; })()`);
  await cl.cmd('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Delete', code: 'Delete', windowsVirtualKeyCode: 46 });
  await cl.cmd('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Delete', code: 'Delete', windowsVirtualKeyCode: 46 });
  await ev(`(function(){ selection = { kind: 'phaseRow', id: 'Category_sf' }; renderAll(); var b = document.querySelector('#properties .props-delete'); if (b) b.click(); return !!b; })()`);
  const left = await ev(PHASES);
  leg(left.length === 4 && left.every(p => p.row === '0') && !left.some(p => p.id === 'Group_f5'),
    `A4 documentation written; 'Productie & service' deleted with Delete; the row 'Fase in Salesforce' deleted from its panel`, JSON.stringify(left.map(p => p.name)));
  // A5
  const after = await ev(`buildBpmnXml(state)`);
  const bad = [];
  if (!/<bpmn:categoryValue id="CategoryValue_f4" value="Order &amp; levering"\/>/.test(after)) bad.push('renamed value');
  const g4 = /<bpmn:group\b[^>]*\bid="Group_f4"[\s\S]*?(?:\/>|<\/bpmn:group>)/.exec(after);
  if (!g4 || !g4[0].includes('Rule: an order is confirmed in writing')) bad.push('documentation on Group_f4: ' + (g4 ? g4[0].slice(0, 120) : 'none'));
  for (const gone of ['"Group_f5"', 'CategoryValue_f5', 'Category_sf', 'Group_s1', 'Group_s6', 'CategoryValue_s1']) if (after.includes(gone)) bad.push('still there: ' + gone);
  const lines = s => s.split('\n');
  const B = lines(before), A = new Set(lines(after));
  const lost = B.filter(l => !A.has(l) && !/categor|[Gg]roup|documentation|BPMNShape|Bounds/.test(l));
  if (lost.length) bad.push(`${lost.length} other line(s) changed: ${lost[0].trim().slice(0, 100)}`);
  leg(!bad.length, `A5 the save carries exactly the edits; every other line as before`, bad.join('; '));
  // A6
  const back = await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); return ${PHASES}; })(${JSON.stringify(after)})`);
  const want = ['Opportunity', 'Configuratie', 'Offerte & onderhandeling', 'Order & levering'];
  const sameX = back.every(p => { const o = phasesBefore.find(q => q.id === p.id); return o && o.x1 === p.x1 && o.x2 === p.x2; });
  let reader = null;
  if (existsSync(join(doc, 'reader.html'))) {
    await open('reader.html');
    reader = await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); return ${PHASES}; })(${JSON.stringify(after)})`);
  }
  leg(JSON.stringify(back.map(p => p.name)) === JSON.stringify(want) && sameX && reader && JSON.stringify(reader.map(p => p.name)) === JSON.stringify(want),
    `A6 read back here and by the released 0.48.1: one row, the four phases with the new name, at the same x ranges`,
    JSON.stringify({ here: back.map(p => p.name), sameX, reader: reader && reader.map(p => p.name) }).slice(0, 240));
  if (process.env.T1502_SHOTS) {
    mkdirSync(process.env.T1502_SHOTS, { recursive: true });
    await open('designer.html');
    await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); if (typeof openingZoom === 'function') openingZoom(); return true; })(${JSON.stringify(after)})`);
    for (const W of [1024, 1440, 1920]) {
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
      await ev(`renderAll()`);
      await click('#g-phases [data-phase-id="Group_f4"]');
      await sleep(300);
      let s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1502_SHOTS, `phase-selected-${W}.png`), Buffer.from(s.data, 'base64'));
      await click('#g-phases [data-phase-row-id="Category_fase"]');
      await sleep(300);
      s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1502_SHOTS, `row-selected-${W}.png`), Buffer.from(s.data, 'base64'));
      // a lane selected the same way, for the side-by-side the reviewer asked for (first judgement, amber)
      await click('#g-lanes [data-lane-id="Lane_Salesforce"], #g-pool [data-lane="Lane_Salesforce"], text.lane-label');
      await ev(`(function(){ if (!selection || selection.kind !== 'lane') { selection = { kind: 'lane', id: 'Lane_Salesforce' }; renderAll(); } return true; })()`);
      await sleep(300);
      s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1502_SHOTS, `lane-selected-${W}.png`), Buffer.from(s.data, 'base64'));
    }
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
