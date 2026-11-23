// T-1473 (T-1461 GO, slice 1) — phases drawn read-only from the file's bpmn:group + bpmn:category, on Greenfield's
// sample (tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn: 'Fase' 5 values, 'Fase in Salesforce' 6 values).
//
//   P1 [fixture, 1024/1440/1920] row 1: 5 named brackets in file order (Opportunity … Productie & service) and 4
//      dividers through all lanes (pool top to bottom); row 2: 6 brackets above row 1, no dividers of its own; each
//      bracket spans its group's x range (clamped to the lanes); the whole phase layer inside the drawing's viewBox
//   P2 [fixture, opened as a person opens it, each width] every phase name drawn at >= OPEN_MIN_TEXT_PX; no phase name
//      overlaps another phase name or the pool header
//   P3 read-only: the fixture's save is byte-identical with the phase layer drawn and with it suppressed
//   P4 [every map in examples/aef-processes/rendered] a map without groups draws nothing in the phase layer
//   P5 [fixture, 1440] the import notice does not list the groups drawn as phases as "not shown yet" (the first
//      shots still said "11 groups kept unchanged and saved back, not shown yet" over the drawn phases)
//   P6 [tests/fixtures/third-party/kitchen-sink.bpmn] groups that do not span the pool's full height are boxes, not
//      phases (T-1461 F3): none drawn, the notice still counts them (the first cut drew them; _t1327 leg3 caught it)
// Teeth: T1473_EDITOR=<the 0.46.0 designer> fails P1 (no phase layer).
// T1473_SHOTS=<dir> writes phases-{1024,1440,1920}.png of the opening view.
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1473_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const FIXTURE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
const CORPUS = join(ROOT, 'examples/aef-processes/rendered');
const ROW1 = ['Opportunity', 'Configuratie', 'Offerte & onderhandeling', 'Order', 'Productie & service'];
const ROW2_N = 6;
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1473-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);

// The phase layer as drawn, plus what it must match: the groups' DI x ranges, the pool border, the viewBox.
const MEASURE = `(function(){
  var g = document.getElementById('g-phases');
  if (!g) return { layer: false };
  var pb = gPool.querySelector('.pool-border');
  var P = pb ? { x: +pb.getAttribute('x'), y: +pb.getAttribute('y'), w: +pb.getAttribute('width'), h: +pb.getAttribute('height') } : null;
  var vb = svg.viewBox && svg.viewBox.baseVal;
  var fit = svg.getScreenCTM().a;
  var rows = {};
  g.querySelectorAll('g[data-phase]').forEach(function(pg){
    var ri = pg.getAttribute('data-phase-row'), path = pg.querySelector('path'), t = pg.querySelector('text');
    var pbb = path.getBBox(), tb = t.getBBox(), tr = t.getBoundingClientRect();
    var title = pg.querySelector('title');
    (rows[ri] = rows[ri] || []).push({ id: pg.getAttribute('data-phase'), name: title ? title.textContent : t.textContent,
      x1: pbb.x - 2, x2: pbb.x + pbb.width + 2, y: pbb.y, tb: { x: tb.x, y: tb.y, w: tb.width, h: tb.height },
      px: parseFloat(getComputedStyle(t).fontSize) * fit, drawn: tr.width > 0 });
  });
  var divs = Array.from(g.querySelectorAll('line.phase-divider')).map(function(l){
    return { id: l.getAttribute('data-phase-divider'), x: +l.getAttribute('x1'), y1: +l.getAttribute('y1'), y2: +l.getAttribute('y2') }; });
  var bb = g.childNodes.length ? g.getBBox() : null;
  var header = null;
  var ht = gPool.querySelector('text');
  if (ht) { var hb = ht.getBBox(); header = { x: hb.x, y: hb.y, w: hb.width, h: hb.height }; }
  var di = {};
  var NS = 'xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" xmlns:di="http://www.omg.org/spec/DD/20100524/DI" xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"';
  ((state.procKept && state.procKept.di) || []).forEach(function(d){
    var doc = new DOMParser().parseFromString('<r ' + NS + '>' + d.xml + '</r>', 'application/xml');
    var b = doc.getElementsByTagNameNS('http://www.omg.org/spec/DD/20100524/DC', 'Bounds')[0];
    if (b) di[d.ref] = { x: +b.getAttribute('x'), w: +b.getAttribute('width') };
  });
  return { layer: true, rows: rows, divs: divs, pool: P, laneHeader: LANE_HEADER, poolHeader: POOL_HEADER,
           vb: vb ? { x: vb.x, y: vb.y, w: vb.width, h: vb.height } : null, bb: bb ? { x: bb.x, y: bb.y, w: bb.width, h: bb.height } : null,
           header: header, di: di, minPx: OPEN_MIN_TEXT_PX, children: g.childNodes.length };
})()`;
const meets = (a, b) => a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;

const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const frames = () => ev(`new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); })`);
  const udd = makeProfileDir('t1473-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  const xml = readFileSync(FIXTURE, 'utf8');
  for (const W of [1024, 1440, 1920]) {
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 1, mobile: false });
    await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
    for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
    await ev(`document.fonts.ready`);
    await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); if (typeof openingZoom === 'function') openingZoom(); })(${JSON.stringify(xml)})`);
    await frames();
    const m = await ev(MEASURE);
    if (!m.layer) { leg(false, `P1 [${W}] phase layer drawn`, 'no #g-phases'); leg(false, `P2 [${W}] phase names readable`, 'no #g-phases'); continue; }
    const r0 = m.rows['0'] || [], r1 = m.rows['1'] || [];
    const P = m.pool, left = P.x + m.laneHeader, right = P.x + P.w;
    const spanBad = [...r0, ...r1].filter(b => { const d = m.di[b.id]; if (!d) return true;
      return Math.abs(b.x1 - Math.max(left, d.x)) > 3 || Math.abs(b.x2 - Math.min(right, d.x + d.w)) > 3; }).map(b => b.name);
    const divBad = m.divs.filter(d => Math.abs(d.y1 - (P.y + m.poolHeader)) > 1 || Math.abs(d.y2 - (P.y + P.h)) > 1);
    const divX = m.divs.map(d => d.x).sort((a, b) => a - b), r0x = r0.slice(1).map(b => b.x1).sort((a, b) => a - b);
    const divAtBounds = divX.length === r0x.length && divX.every((x, i) => Math.abs(x - r0x[i]) <= 3);
    const above = r1.length && r0.length && Math.max(...r1.map(b => b.y)) < Math.min(...r0.map(b => b.y));
    const inside = m.bb && m.vb && m.bb.y >= m.vb.y - 0.5 && m.bb.x >= m.vb.x - 0.5 && m.bb.x + m.bb.w <= m.vb.x + m.vb.w + 0.5;
    const names = r0.map(b => b.name);
    leg(r0.length === 5 && JSON.stringify(names) === JSON.stringify(ROW1) && m.divs.length === 4 && divAtBounds && !divBad.length &&
        r1.length === ROW2_N && above && !spanBad.length && inside,
      `P1 [${W}] row 1: ${r0.length} brackets, ${m.divs.length} dividers through the lanes; row 2: ${r1.length} brackets above; spans match the groups; layer inside the viewBox`,
      [JSON.stringify(names) !== JSON.stringify(ROW1) ? 'row 1 names ' + JSON.stringify(names) : '', !divAtBounds ? 'dividers not at the row-1 boundaries' : '',
       divBad.length ? divBad.length + ' divider(s) not pool-top..bottom' : '', !above ? 'row 2 not above row 1' : '',
       spanBad.length ? 'span off: ' + spanBad.join(', ') : '', !inside ? 'layer outside the viewBox ' + JSON.stringify({ bb: m.bb, vb: m.vb }) : ''].filter(Boolean).join('; '));
    const all = [...r0, ...r1];
    const small = all.filter(b => b.drawn && !(b.px >= m.minPx - 0.01)).map(b => `${b.name} ${b.px.toFixed(1)}px`);
    const over = [];
    for (let i = 0; i < all.length; i++) for (let j = i + 1; j < all.length; j++) if (meets(all[i].tb, all[j].tb)) over.push(`${all[i].name} / ${all[j].name}`);
    const onHeader = m.header ? all.filter(b => meets(b.tb, m.header)).map(b => b.name) : [];
    leg(all.length > 0 && !small.length && !over.length && !onHeader.length,
      `P2 [${W}] ${all.length} phase names at >= ${m.minPx}px at the opening zoom, none on another or on the pool header`,
      [small.join(', '), over.join(', '), onHeader.length ? 'on header: ' + onHeader.join(', ') : ''].filter(Boolean).join('; '));
    if (W === 1440) {
      const note = await ev(`(function(){ var n = document.getElementById('lane-fix-notice'); return n ? n.textContent : ''; })()`);
      leg(!/\bgroups?\b[^.]*not shown yet/.test(note) && note.length > 0,
        `P5 the import notice no longer calls the groups drawn as phases "not shown yet"`, /not shown yet/.test(note) ? note.replace(/\s+/g, ' ').slice(0, 160) : '');
    }
    if (process.env.T1473_SHOTS) {
      mkdirSync(process.env.T1473_SHOTS, { recursive: true });
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
      await frames(); await sleep(300);
      const shot = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1473_SHOTS, `phases-${W}.png`), Buffer.from(shot.data, 'base64'));
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 1, mobile: false });
    }
  }
  // P3: read-only
  const same = await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll();
    var drawn = document.getElementById('g-phases'); var n = drawn ? drawn.childNodes.length : 0;
    var a = buildBpmnXml(state);
    var keep = typeof renderPhases === 'function' ? renderPhases : null;
    if (keep) renderPhases = function(){ var g = document.getElementById('g-phases'); if (g) g.innerHTML = ''; };
    renderAll(); var b = buildBpmnXml(state);
    if (keep) renderPhases = keep; renderAll();
    return { n: n, same: a === b, len: a.length };
  })(${JSON.stringify(xml)})`);
  leg(same.n > 0 && same.same, `P3 the fixture's save (${same.len} chars) is byte-identical with the ${same.n} phase element(s) drawn and suppressed`);
  // P4: maps without groups
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  const drew = [];
  for (const f of corpus) {
    const src = readFileSync(join(CORPUS, f), 'utf8');
    if (/<bpmn:group\b/.test(src)) continue;
    const n = await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); var g = document.getElementById('g-phases'); return g ? g.childNodes.length : -1; })(${JSON.stringify(src)})`);
    if (n !== 0) drew.push(`${f}: ${n}`);
  }
  leg(corpus.length > 0 && !drew.length, `P4 [${corpus.length} corpus maps without groups] no phase layer content`, drew.slice(0, 4).join('; '));
  // P6: groups that are boxes, not phases (T-1461 F3): the kitchen-sink's three bpmn.io groups, each with its own
  // category, sit inside one lane; none is drawn as a phase, and the notice still counts them as kept, not shown
  const ks = await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll();
    var g = document.getElementById('g-phases'); var n = document.getElementById('lane-fix-notice');
    return { drawn: g ? g.childNodes.length : -1, note: n ? n.textContent.replace(/\\s+/g, ' ') : '' }; })(${JSON.stringify(readFileSync(join(ROOT, 'tests/fixtures/third-party/kitchen-sink.bpmn'), 'utf8'))})`);
  leg(ks.drawn === 0 && /3 groups kept unchanged/.test(ks.note),
    `P6 [kitchen-sink: 3 groups inside one lane, each its own category] none drawn as a phase; the notice still counts the 3 groups`,
    ks.drawn !== 0 ? `${ks.drawn} phase element(s) drawn` : (/3 groups/.test(ks.note) ? '' : 'notice: ' + ks.note.slice(0, 160)));
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
