#!/usr/bin/env node
// _t1069-authority-marker-clearance-cdp.mjs — the T-893 authority marker must not sit under the
// node's own edges (T-1069).
//
// Independent reviewer AMBER on T-893 (.context/reviews/evidence/T-893/AC1-judge-t-893-r5-...md):
// "⚠ no authority" is ~67px of 8px mono starting at n.x+2, so it spans the TOP-CENTRE of a standard
// task — exactly where a top-entering sequence flow lands; its line and arrowhead cross the marker.
// The cause is structural (marker width vs the gap left of top-centre), not one fixture.
//
// Drives the REAL editor (file://, headless Chromium) over all 24 rendered corpus maps, forcing each
// marker state on EVERY node, and MEASURES each marker's bbox against the rendered segments of the
// edges INCIDENT to that node (its own incoming/outgoing flows):
//   M1  'missing' markers (every element and lane stripped of authority): 0 crossings
//   M2  'differs' markers (every element given an authority unlike its lane default): 0 crossings
//   M3  setup control: both states actually rendered markers (else M1/M2 assert nothing)
//   M4  no information lost: every marker carries a <title> with its full text AND receives pointer
//       events, so the title actually shows on hover
//
// --self-test reruns on a poisoned copy that always draws the full-length text (the pre-T-1069
// form): M1 must FAIL.
//
// Usage:  node tools/_t1069-authority-marker-clearance-cdp.mjs [--self-test]
// Exit:   0 pass · 1 leg failed · 2 setup broken
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = join(ROOT, 'src', 'aef-workflow-designer.html');
const MAPDIR = join(ROOT, 'examples', 'aef-processes', 'rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function chrome() {
  const c = join(homedir(), '.cache', 'ms-playwright');
  if (!existsSync(c)) return null;
  return readdirSync(c).filter(d => d.startsWith('chromium-')).sort().reverse()
    .map(d => join(c, d, 'chrome-linux64', 'chrome')).find(existsSync) || null;
}

const FORCE = (mode) => `(function(){
  var mode = ${JSON.stringify(mode)};
  if (mode === 'missing') {
    getLanes().forEach(function(l){ l.authority = 'none'; delete l.authoringDefault; });
    state.nodes.forEach(function(n){ if (n.aef) delete n.aef.authority; });
  } else {
    state.nodes.forEach(function(n){
      var d = effectiveLaneDefault(findLane(n.lane));
      n.aef = n.aef || {};
      n.aef.authority = d === 'external' ? 'sovereignty' : 'external';
    });
  }
  renderAll();
  var hit = function(r, a, b){ return !(Math.max(a.x, b.x) < r.x1 || Math.min(a.x, b.x) > r.x2 || Math.max(a.y, b.y) < r.y1 || Math.min(a.y, b.y) > r.y2); };
  var markers = Array.prototype.slice.call(document.querySelectorAll('[data-authority-marker="' + mode + '"]'));
  var out = { markers: markers.length, crossings: [], untitled: 0 };
  markers.forEach(function(m){
    var g = m.closest('[data-id]'); if (!g) return;
    var id = g.getAttribute('data-id');
    var b = m.getBBox(); var r = { x1: b.x, x2: b.x + b.width, y1: b.y, y2: b.y + b.height };
    // a <title> only shows as a tooltip on an element that receives pointer events (reviewer
    // AMBER on T-893: pointer-events:none made the hover claim false while a <title> was present)
    var t = m.querySelector('title');
    if (!t || !t.textContent || getComputedStyle(m).pointerEvents === 'none') out.untitled++;
    state.edges.forEach(function(e){
      if (e.source !== id && e.target !== id) return;
      var pl = e._renderedPolyline || [];
      var shown = m.firstChild && m.firstChild.nodeType === 3 ? m.firstChild.nodeValue : m.textContent;   // not the <title>
      for (var i = 0; i < pl.length - 1; i++) if (hit(r, pl[i], pl[i+1])) { out.crossings.push(id + ' "' + shown + '" x ' + e.id); break; }
    });
  });
  return out;
})()`;

async function probe(editorPath) {
  const exe = chrome();
  if (!exe) throw new Error('no Playwright chromium under ~/.cache/ms-playwright');
  const udd = mkdtempSync(join(tmpdir(), 't1069-'));
  const proc = spawn(exe, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let ws;
  try {
    let port;
    for (let i = 0; i < 400 && !port; i++) {
      const f = join(udd, 'DevToolsActivePort');
      if (existsSync(f)) port = +readFileSync(f, 'utf8').split('\n')[0] || undefined;
      await sleep(100);
    }
    if (!port) throw new Error('chromium did not open a DevTools port');
    ws = new WebSocket(await pageWsUrl(port));
    let id = 0; const pend = new Map();
    const cmd = (method, params = {}) => new Promise((res, rej) => { const k = ++id;
      pend.set(k, m => m.error ? rej(new Error(method + JSON.stringify(m.error))) : res(m.result));
      ws.send(JSON.stringify({ id: k, method, params })); });
    ws.addEventListener('message', ev => { const m = JSON.parse(ev.data);
      if (m.id && pend.has(m.id)) { pend.get(m.id)(m); pend.delete(m.id); }
      if (m.method === 'Page.javascriptDialogOpening') cmd('Page.handleJavaScriptDialog', { accept: true }); });
    await new Promise((r, j) => { ws.addEventListener('open', r); ws.addEventListener('error', () => j(new Error('CDP ws error'))); });
    const ev = async (expression) => { const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
      if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 500)); return r.result.value; };
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1600, height: 1000, deviceScaleFactor: 2, mobile: false });
    const agg = { missing: { markers: 0, crossings: [], untitled: 0 }, differs: { markers: 0, crossings: [], untitled: 0 } };
    for (const m of readdirSync(MAPDIR).filter(f => f.endsWith('.bpmn')).sort()) {
      const xml = readFileSync(join(MAPDIR, m), 'utf8');
      for (const mode of ['missing', 'differs']) {
        await cmd('Page.navigate', { url: 'file://' + editorPath });
        for (let t0 = Date.now(); ; ) {
          if (await ev(`typeof renderAll==='function'&&typeof adoptImportedXml==='function'&&typeof state!=='undefined'&&!!state&&window._deepLinkSettled!==null`).catch(() => false)) break;
          if (Date.now() - t0 > 40000) throw new Error('editor load timeout'); await sleep(150);
        }
        await ev(`(function(){ try{ localStorage.clear(); }catch(e){} adoptImportedXml(${JSON.stringify(xml)}, {userImport:true}); return 1; })()`);
        const r = await ev(FORCE(mode));
        agg[mode].markers += r.markers; agg[mode].untitled += r.untitled;
        for (const c of r.crossings) agg[mode].crossings.push(m.replace('.bpmn', '') + '/' + c);
      }
    }
    return agg;
  } finally {
    try { ws && ws.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}

function legs(a) {
  const show = xs => xs.length ? xs.slice(0, 4).join('; ') + (xs.length > 4 ? ` … (+${xs.length - 4})` : '') : 'none';
  return [
    { id: 'M1', ok: a.missing.crossings.length === 0, detail: `'missing' markers crossing their node's own edges: ${a.missing.crossings.length} — ${show(a.missing.crossings)}` },
    { id: 'M2', ok: a.differs.crossings.length === 0, detail: `'differs' markers crossing their node's own edges: ${a.differs.crossings.length} — ${show(a.differs.crossings)}` },
    { id: 'M3', ok: a.missing.markers > 0 && a.differs.markers > 0, detail: `markers rendered: missing ${a.missing.markers}, differs ${a.differs.markers}` },
    { id: 'M4', ok: a.missing.untitled === 0 && a.differs.untitled === 0, detail: `markers without a hoverable full-text <title>: ${a.missing.untitled + a.differs.untitled}` },
  ];
}
const report = L => { for (const l of L) console.log(`  ${l.ok ? 'PASS' : 'FAIL'}  ${l.id}  ${l.detail}`); };

async function main() {
  const selfTest = process.argv.includes('--self-test');
  const ed = process.argv.find(a => a.endsWith('.html')) || EDITOR;
  console.log('T-1069 authority marker clearance — all corpus maps, every node forced to each state');
  const live = legs(await probe(ed));
  report(live);
  const failed = live.filter(l => !l.ok);
  if (!selfTest) { console.log(failed.length ? `FAIL — ${failed.length} leg(s)` : `PASS — ${live.length} legs`); process.exit(failed.length ? 1 : 0); }
  const src = readFileSync(EDITOR, 'utf8');
  const FIT = 'const fitMarker = (forms) => forms.find(t => t.length * MARKER_CH <= avail) || forms[forms.length - 1];\n';
  if (!src.includes(FIT)) { console.log('SELF-TEST INTEGRITY FAIL — poison target missing from the editor source'); process.exit(2); }
  const f = join(mkdtempSync(join(tmpdir(), 't1069-poison-')), 'poisoned.html');
  writeFileSync(f, src.replace(FIT, 'const fitMarker = (forms) => forms[0];\n'));
  console.log('\npoison arm — the full-length marker always drawn (the pre-T-1069 form); M1 must FAIL');
  const pl = legs(await probe(f)); report(pl);
  if (failed.length) { console.log(`\nFAIL — ${failed.length} live leg(s)`); process.exit(1); }
  if (pl.find(l => l.id === 'M1').ok) { console.log('\nSELF-TEST FAIL — M1 passed under poison; it asserts nothing'); process.exit(2); }
  if (!pl.find(l => l.id === 'M3').ok) { console.log('\nSELF-TEST FAIL — the setup control broke under poison'); process.exit(2); }
  console.log(`\nPASS — ${live.length} live legs; M1 proven failable`);
}
main().catch(e => { console.error('DRIVER ERROR: ' + (e && e.stack || e)); process.exit(2); });
