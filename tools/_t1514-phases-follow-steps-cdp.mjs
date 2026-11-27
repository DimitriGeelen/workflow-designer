// T-1514 (T-1491 IW-2) — phase boundaries follow the steps when steps move. On Greenfield's sample
// (tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn: 'Fase' Group_f1..f5 share their edges, off-centre in their gaps;
// 'Fase in Salesforce' Group_s1..s6 are 6 px apart):
//   F1 drag the last step of 'Fase' phase 2 right, inside its phase: it stays in phase 2; the f2|f3 edge keeps its
//      relative place in the new gap; every other edge of the row stays; one undo restores steps and phases
//   F2 drag the first step of 'Fase' phase 3 left, dropped in phase 2: it joins phase 2; every step is under its phase;
//      the shared edges sit in their gaps; one undo restores
//   F3 Clean layout: every step keeps its phase in both rows; each shared edge sits in its gap; each non-shared edge
//      ('Fase in Salesforce') keeps its distance to its nearest step; one undo restores
//   F4 no edit (open, re-render, zoom) changes nothing: the save is byte-identical to the released designer's
//      (T1514_READER, default dist 0.52.0); the F2 save changes only group Bounds x/width and the moved step's lines,
//      and reads back the same here and by the released reader
//   F5 nothing is guessed: steps out of phase order leave the row as it was; a phase with no steps keeps its edges
// Teeth: T1514_EDITOR=<dist 0.52.0> fails F1 and F2. F3 also holds on 0.52.0: on this sample Clean's x moves are column
// snaps of a few px that never take a step out from under its phase, so F3 guards the rule rather than the change.
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
const EDITOR = process.env.T1514_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const READER = process.env.T1514_READER || join(ROOT, 'dist', 'aef-workflow-designer-0.52.0.html');
const FIXTURE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1514-doc-'));
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
  const udd = makeProfileDir('t1514-'); profiles.push(udd);
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
  const PH = `(function(){ return phasesParse(phaseKept()).map(function(r){ return { id: r.id, phases: r.phases.map(function(p){ return { id: p.id, x: p.x, r: p.x + p.w }; }) }; }); })()`;
  const NODES = `(function(){ return state.nodes.filter(function(n){ return typeof n.x === 'number'; }).map(function(n){ var d = dims(n); return { id: n.id, x: n.x, r: n.x + d.w, y: n.y, h: d.h }; }); })()`;
  const snap = async () => ({ rows: await ev(PH), nodes: await ev(NODES) });
  // which phase of a row holds a node's centre (by the given rows' bounds)
  const phaseOf = (rows, rid, n) => { const r = rows.find(r => r.id === rid); const c = (n.x + n.r) / 2; const p = r && r.phases.find(p => c >= p.x && c <= p.r); return p ? p.id : null; };
  const members = (s, ref) => Object.fromEntries(s.rows.map(r => [r.id, Object.fromEntries(s.nodes.map(n => [n.id, phaseOf(ref.rows, r.id, n)]))]));
  // a real drag of a step: press on its centre, move in steps, release
  const dragNode = async (id, dx, dy = 0) => {
    const p = await ev(`(function(){ var n = findNode(${JSON.stringify(id)}), d = dims(n), sc = svg.parentElement;
      var cx = n.x + d.w / 2, cy = n.y + d.h / 2;
      var at = function(){ var m = svg.getScreenCTM(); return { x: m.a * cx + m.c * cy + m.e, y: m.b * cx + m.d * cy + m.f, s: m.a }; };
      var q = at(), b = sc.getBoundingClientRect(); sc.scrollLeft += q.x - (b.left + b.width / 2); sc.scrollTop += q.y - (b.top + b.height / 2);
      return at(); })()`);
    await frames();
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: p.x, y: p.y });
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x: p.x, y: p.y, button: 'left', clickCount: 1 });
    const steps = 8;
    for (let k = 1; k <= steps; k++) await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: p.x + dx * p.s * k / steps, y: p.y + dy * p.s * k / steps, button: 'left', buttons: 1 });
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x: p.x + dx * p.s, y: p.y + dy * p.s, button: 'left', clickCount: 1 });
    await frames();
  };
  const E = (a, b) => Math.abs(a - b) < 0.6;
  // every shared edge strictly inside the gap between its phases' steps (by membership m over nodes s)
  const sharedOk = (s, m) => s.rows.every(r => r.phases.every((p, i) => {
    if (i === 0) return true;
    const a = r.phases[i - 1]; if (Math.abs(a.r - p.x) > 2) return true;
    const A = s.nodes.filter(n => m[r.id][n.id] === a.id), B = s.nodes.filter(n => m[r.id][n.id] === p.id);
    if (!A.length || !B.length) return true;
    return Math.max(...A.map(n => n.r)) <= p.x + 0.6 && p.x <= Math.min(...B.map(n => n.x)) + 0.6;
  }));
  const under = (s, m) => s.rows.every(r => s.nodes.every(n => m[r.id][n.id] == null || phaseOf(s.rows, r.id, n) === m[r.id][n.id]));
  const edges = s => Object.fromEntries(s.rows.flatMap(r => r.phases.map(p => [p.id, [p.x, p.r]])));

  // F4 (first half): no edit changes nothing
  let readerSave = null;
  if (existsSync(join(doc, 'reader.html'))) { await open('reader.html'); await adopt(xml); await frames(); readerSave = await save(); }
  await open('designer.html'); await adopt(xml); await frames();
  const S0 = await snap(), save0 = await save();
  await ev(`(function(){ renderAll(); renderAll(); return true; })()`); await click('#btn-zoom-out'); await click('#btn-zoom-in'); await frames();
  const save0b = await save();
  const M0 = members(S0, S0);

  // F1 last step of f2 (n_60040b05) 30 px right, still in f2
  await dragNode('n_60040b05', 30);
  const S1 = await snap();
  const e0 = edges(S0), e1 = edges(S1);
  const n1 = S1.nodes.find(n => n.id === 'n_60040b05');
  const oldR = 1137, oldL3 = Math.min(...S0.nodes.filter(n => M0.Category_fase[n.id] === 'Group_f3').map(n => n.x));
  const t = (e0.Group_f3[0] - oldR) / (oldL3 - oldR);
  const want = n1.r + t * (oldL3 - n1.r);
  const others = Object.keys(e0).filter(k => !['Group_f2', 'Group_f3'].includes(k)).every(k => E(e0[k][0], e1[k][0]) && E(e0[k][1], e1[k][1]));
  const moved1 = n1.x > 1027 + 10;
  await ev(`undo()`); await frames();
  const u1 = await save();
  leg(moved1 && phaseOf(S1.rows, 'Category_fase', n1) === 'Group_f2' && E(e1.Group_f3[0], want) && E(e1.Group_f2[1], want) && others && u1 === save0,
    `F1 dragging phase 2's last step right inside phase 2: the f2|f3 edge keeps its place in the gap; the rest of the row stays; one undo restores`,
    JSON.stringify({ stepX: n1.x, edge: e1.Group_f3[0], want: Math.round(want * 10) / 10, before: e0.Group_f3[0], others, undone: u1 === save0 }));

  // F2 first step of f3 (n_2d825dab) dropped inside f2 (centre left of the old f2|f3 edge)
  const d2 = e0.Group_f3[0] - 1234 - 40;   // its centre is at 1234; land 40 px left of the edge
  await dragNode('n_2d825dab', d2);
  const S2 = await snap(), save2 = await save();
  const n2 = S2.nodes.find(n => n.id === 'n_2d825dab');
  const M2 = JSON.parse(JSON.stringify(M0)); M2.Category_fase.n_2d825dab = phaseOf(S0.rows, 'Category_fase', n2);
  M2.Category_sf.n_2d825dab = phaseOf(S0.rows, 'Category_sf', n2);
  await ev(`undo()`); await frames();
  const u2 = await save();
  leg(M2.Category_fase.n_2d825dab === 'Group_f2' && under(S2, M2) && sharedOk(S2, M2) && u2 === save0,
    `F2 dropping phase 3's first step inside phase 2: it joins phase 2; every step is under its phase; the shared edges sit in their gaps; one undo restores`,
    JSON.stringify({ joined: M2.Category_fase.n_2d825dab, under: under(S2, M2), shared: sharedOk(S2, M2), f3: edges(S2).Group_f3, undone: u2 === save0 }));

  // F3 Clean layout. The sample is already tidy in x, so first knock a few steps off their columns (inside their phases,
  // the way a person's rough drags leave them: 9-17 px), as a state change with no phase involved; then Clean
  await ev(`(function(){ ['n_13dcbea2', 'n_abea8e2d', 'n_2c2d3cd9', 'n_5c0e19d4', 'n_79029ee7', 'n_70d537f7'].forEach(function(id, i){ findNode(id).x += 9 + i; }); renderAll(); return true; })()`);
  await frames();
  const S3a = await snap(), save3a = await save();
  await click('#btn-clean'); await frames();
  const S3 = await snap();
  const movedAny = S3.nodes.some(n => { const o = S3a.nodes.find(q => q.id === n.id); return !E(o.x, n.x); });
  // non-shared edges keep their distance to their nearest step (Salesforce row)
  const sf0 = S3a.rows.find(r => r.id === 'Category_sf'), sf3 = S3.rows.find(r => r.id === 'Category_sf');   // before Clean = the knocked state
  const dist = (s, r, m, p, side) => { const ns = s.nodes.filter(n => m[r][n.id] === p.id); if (!ns.length) return null; return side === 'L' ? Math.min(...ns.map(n => n.x)) - p.x : p.r - Math.max(...ns.map(n => n.r)); };
  const keep = sf0.phases.every((p, i) => {
    const q = sf3.phases[i]; const okL = (i > 0 && Math.abs(sf0.phases[i - 1].r - p.x) <= 2) || p.x <= 92 || E(dist(S3a, 'Category_sf', M0, p, 'L'), dist(S3, 'Category_sf', M0, q, 'L'));
    const okR = (i < sf0.phases.length - 1 && Math.abs(p.r - sf0.phases[i + 1].x) <= 2) || E(dist(S3a, 'Category_sf', M0, p, 'R'), dist(S3, 'Category_sf', M0, q, 'R'));
    return okL && okR; });
  await ev(`undo()`); await frames();
  const u3 = await save();
  leg(movedAny && under(S3, M0) && sharedOk(S3, M0) && keep && u3 === save3a,
    `F3 Clean layout: every step keeps its phase in both rows; shared edges sit in their gaps; 'Fase in Salesforce' edges keep their distance to their steps; one undo restores`,
    JSON.stringify({ movedAny, under: under(S3, M0), shared: sharedOk(S3, M0), keep, undone: u3 === save3a, f: edges(S3).Group_f2, s2: edges(S3).Group_s2 }));

  // F4: the F2 save changes only group Bounds x/width and the moved step (its shape, its flows' routes, its position)
  // the sample declares no aef:workflowMeta, so every open mints a uuid: set it aside when comparing two opens
  const nu = x => x.replace(/(<aef:workflowMeta\b[^>]*\suuid=")[^"]*"/, '$1U"');
  const part = (x, a) => { const k = x.indexOf('<bpmndi:BPMNDiagram'); return a ? x.slice(0, k) : x.slice(k); };
  const lines = x => x.split('\n');
  const semGone = lines(part(save0, true)).filter(l => !new Set(lines(part(save2, true))).has(l));
  const semOk = semGone.every(l => /aef:position|n_2d825dab/.test(l));
  const groupB = x => Object.fromEntries([...x.matchAll(/bpmnElement="(Group_[^"]+)"[^>]*>\s*<dc:Bounds([^>]*)>/g)].map(m => [m[1], Object.fromEntries([...m[2].matchAll(/(\w+)="([^"]*)"/g)].map(a => [a[1], +a[2]]))]));
  const g0 = groupB(save0), g2 = groupB(save2);
  const gOk = Object.keys(g0).length === Object.keys(g2).length && Object.keys(g0).every(k => g2[k] && g0[k].y === g2[k].y && g0[k].height === g2[k].height);
  await adopt(save2); await frames();
  const here = edges(await snap());
  let rd = null;
  if (existsSync(join(doc, 'reader.html'))) { await open('reader.html'); await adopt(save2); await frames(); rd = edges(await snap()); }
  const e2 = edges(S2);
  const sameE = (a, b) => a && Object.keys(e2).every(k => a[k] && E(a[k][0], e2[k][0]) && E(a[k][1], e2[k][1]));
  leg(save0 === save0b && !!readerSave && nu(readerSave) === nu(save0) && semOk && gOk && sameE(here) && sameE(rd),
    `F4 no edit changes nothing (byte-identical to the released designer); the F2 save changes only the moved step and the groups' x/width; read back the same here and by the released reader`,
    JSON.stringify({ noEdit: save0 === save0b, asReader: !!readerSave && nu(readerSave) === nu(save0), semStray: semGone.filter(l => !/aef:position|n_2d825dab/.test(l)).map(l => l.trim().slice(0, 90)).slice(0, 3), groupsYH: gOk, here: sameE(here), reader: sameE(rd) }));
  // F5 nothing is guessed: (a) a move that puts a phase's steps out of order leaves the row as it was; (b) a phase that
  // holds no steps keeps its edges, and so does the edge it shares (the follow rule called directly, as the edits do)
  await open('designer.html'); await adopt(xml); await frames();
  const f5 = await ev(`(function(){
    var E = function(){ return JSON.stringify(phasesParse(phaseKept()).map(function(r){ return r.phases.map(function(p){ return [p.id, p.x, p.w]; }); })); };
    var e0 = E();
    var b = phaseMembership(); var n = findNode('n_33e2dcb8'), x0 = n.x;
    n.x = 1500;   // phase 2's first step beyond phase 3's first: out of order in both rows
    var ca = _phasesFollowSteps(b, null), ea = E(); n.x = x0;
    var b2 = phaseMembership(); var m = b2.byRow.get('Category_fase');
    ['n_7d3db646', 'n_13dcbea2', 'n_6a5f74bf'].forEach(function(id){ m.delete(id); });   // phase 1 holds nothing
    findNode('n_33e2dcb8').x += 20;   // phase 2's first step moves right: its left edge is shared with phase 1
    var cb = _phasesFollowSteps(b2, null), r = phasesParse(phaseKept())[0].phases;
    var f1 = r.find(function(p){ return p.id === 'Group_f1'; }), f2 = r.find(function(p){ return p.id === 'Group_f2'; });
    return { outOfOrder: { changed: ca, same: ea === e0 }, empty: { f1: [f1.x, f1.w], f2x: f2.x } }; })()`);
  leg(!f5.outOfOrder.changed && f5.outOfOrder.same && f5.empty.f1[0] === 50 && f5.empty.f1[1] === 510 && f5.empty.f2x === 560,
    'F5 nothing is guessed: steps moved out of phase order leave the row as it was; a phase with no steps keeps its edges and the edge it shares',
    JSON.stringify(f5));
  if (process.env.T1514_SHOTS) {
    const D = process.env.T1514_SHOTS; mkdirSync(D, { recursive: true });
    for (const W of [1024, 1440, 1920]) {
      await open('designer.html');
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
      await adopt(xml); await frames();
      await click('#btn-toggle-palette'); await click('#btn-toggle-props'); await sleep(300);
      // the whole pool, from its phase-row labels to its right edge (T-1514 review 2: no heading or id cut; on this sample
      // no vertical line right of 'Offerte & onderhandeling' is free of an id label or a phase bracket, so a narrower crop
      // always cuts one). The 2x capture keeps the text readable.
      const edgesX = await ev(`(function(){ var m = svg.getScreenCTM().inverse(), pt = svg.createSVGPoint();
        var toMap = function(x, y){ pt.x = x; pt.y = y; var q = pt.matrixTransform(m); return q.x; };
                var pb = gPool.querySelector('.pool-border'), L = +pb.getAttribute('x');
        Array.from(svg.querySelectorAll('.phase-row-label')).forEach(function(t){ var b = t.getBoundingClientRect(); L = Math.min(L, toMap(b.left, b.top)); });
        L -= 4;
        return [L, +pb.getAttribute('x') + +pb.getAttribute('width') + 4]; })()`);
      // the shot's region (edgesX) in view, zoomed out only until it fits with 20 px to spare
      for (let z = 0; z < 10; z++) {
        const fits = await ev(`(function(){ var sc = svg.parentElement, b = sc.getBoundingClientRect();
          var sx = function(x){ var m = svg.getScreenCTM(); return m.a * x + m.e; };
          sc.scrollLeft += ((sx(${edgesX[0]}) + sx(${edgesX[1]})) / 2) - (b.left + b.width / 2); sc.scrollTop = 0;
          return sx(${edgesX[0]}) >= b.left + 20 && sx(${edgesX[1]}) <= b.right - 20; })()`);
        if (fits) break;
        await click('#btn-zoom-out'); await sleep(250);
      }
      const v = await ev(`(function(){ var sc = svg.parentElement; return [sc.scrollLeft, sc.scrollTop]; })()`);
      // a crop whose edges fall in empty space (T-1514 review: cards cut at the canvas edge): from the middle of the gap
      // before 'Configuratie' to the gap after the next phase's first column (the gateway's label in full), from the phase rows to the pool's
      // bottom; shot through clearShot (T-1429) on an invisible rectangle drawn over that region
      const region = `(function(){ var old = document.getElementById('t1514-region'); if (old) old.remove();
        var pb = gPool.querySelector('.pool-border'), py = +pb.getAttribute('y'), ph = +pb.getAttribute('height');
        var r = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
        r.setAttribute('id', 't1514-region'); r.setAttribute('x', ${edgesX[0]}); r.setAttribute('width', ${edgesX[1] - edgesX[0]});
        r.setAttribute('y', py - 8 - PHASE_ROW_H - 26); r.setAttribute('height', ph + 8 + PHASE_ROW_H + 26 + 6);
        r.setAttribute('fill', 'none'); r.setAttribute('pointer-events', 'none'); gPool.appendChild(r); return true; })()`;   // in the pool's group: map coordinates
      const shotRegion = async () => { await ev(region); await frames();
        const png = await clearShot((m, q) => cl.cmd(m, q), (c, e) => ev(e), '#t1514-region', { pad: 0, padTop: 0, widen: false, scale: 2, rerender: region });
        // the rectangle catches pointer events: gone before the drag, or the drag presses it instead of the step
        await ev(`(function(){ var r = document.getElementById('t1514-region'); if (r) r.remove(); return true; })()`);
        return png; };
      let png = await shotRegion();
      writeFileSync(join(D, `before-drag-${W}.png`), png);
      // shown two lanes lower (the empty 'NAV' lane), so the dropped step and its labels touch nothing in the picture
      // dropped at the middle of the lane two down (T-1514 review: the card and its labels fully inside one lane)
      const dy = await ev(`(function(){ var n = findNode('n_2d825dab'), d = dims(n), i = state.lanes.findIndex(function(l){ return l.id === n.lane; });
        var nxt = state.lanes[i + 2] || state.lanes[i + 1]; return (laneTop(nxt.id) + nxt.height / 2) - (n.y + d.h / 2); })()`);
      await dragNode('n_2d825dab', e0.Group_f3[0] - 1234 - 40, dy);
      await ev(`(function(v){ var sc = svg.parentElement; sc.scrollLeft = v[0]; sc.scrollTop = v[1]; selection = null; renderAll(); return true; })(${JSON.stringify(v)})`); await frames(); await sleep(200);
      png = await shotRegion();
      writeFileSync(join(D, `after-drag-${W}.png`), png);
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
