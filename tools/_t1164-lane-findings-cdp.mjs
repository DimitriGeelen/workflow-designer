#!/usr/bin/env node
// _t1164-lane-findings-cdp.mjs — verify T-1164 (OBS-465): a validator finding that names a LANE ("lane '<id>'") marks
// that lane's header strip (severity + ✖/⚠ pill), its dock row is anchored and selects the lane, and the mark lives only
// as long as the check that made it. Fixture: a task dragged clear of every lane band (T-964's reproduction), which
// draws W-XML-LANE-GEOMETRY / W-XML-LANE-CAPACITY. Also: such a node does not stretch the drawn pool (T-1154 x T-1164).
// Same harness as _t1091 (gallery-serve.py temp docroot: it serves the validator; ISOLATED headless chromium).
// Writes .playwright-mcp/t1164-<width>-{marked,sticky}.png at 1024/1440/1920 for the visual review.
// T1164_DESIGNER=<file> runs it against another build (control: the pre-T-1164 designer must fail the marking legs).
// Exit 0 = pass. Exit 1 = a step failed. Exit 2 = harness could not run.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SHOTDIR = join(REPO, '.playwright-mcp');
const MAP = 'task-lifecycle';
const LANE_RULES = ['W-XML-LANE-GEOMETRY', 'W-XML-LANE-CAPACITY'];
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// In the page: what the check reported about lanes, and what the canvas and dock show.
const PROBE = `(function(){
  var rows = (findingsView.rows || []).filter(function(r){ return /\\blane \\x27/.test(r.location || '') && !/^(node|[a-zA-Z]+Event|[a-zA-Z]+Gateway|[a-zA-Z]*[tT]ask) /.test(r.location || ''); });
  var laneIds = getLanes().map(function(l){ return l.id; });
  var named = {}; rows.forEach(function(r){ var m = /\\blane \\x27([^\\x27]+)\\x27/.exec(r.location); if (m && laneIds.indexOf(m[1]) >= 0) named[m[1]] = (named[m[1]] === 'ERROR' || r.severity === 'ERROR') ? 'ERROR' : 'WARN'; });
  var marks = {}; svg.querySelectorAll('#g-pool > .lane-header[data-finding]').forEach(function(h){
    marks[h.getAttribute('data-lane-id')] = { sev: h.getAttribute('data-finding'), pill: !!h.querySelector('.node-finding-pill'), glyph: (h.querySelector('.node-finding-badge') || {}).textContent || '' }; });
  var dockRows = Array.prototype.slice.call(document.querySelectorAll('#findings-list .finding-row')).filter(function(r){ return LANE_RULES_IN_PAGE.indexOf(r.getAttribute('data-rule')) >= 0; })
    .map(function(r){ return { rule: r.getAttribute('data-rule'), anchored: r.getAttribute('data-anchored'), lane: r.getAttribute('data-lane') }; });
  return { state: findingsView.state, laneRows: rows.map(function(r){ return [r.rule, r.severity, r.location]; }), named: named, marks: marks,
           dockRows: dockRows, header: (document.getElementById('findings-state') || {}).textContent || '' };
})()`.replace('LANE_RULES_IN_PAGE', JSON.stringify(LANE_RULES));

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't1164-doc-')), repo = mkdtempSync(join(tmpdir(), 't1164-repo-')), udd = mkdtempSync(join(tmpdir(), 't1164-udd-'));
  copyFileSync(process.env.T1164_DESIGNER || join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'));
  copyFileSync(join(REPO, 'examples/aef-processes/rendered', MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let cl; const steps = [], shots = [];
  const push = (n, p, g) => steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { if ((await fetch(`http://127.0.0.1:${port}/api/health`)).ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    const open = async w => {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: 860, deviceScaleFactor: 1, mobile: false });
      await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP}.bpmn` });
      await sleep(300); await waitReady(cmd); await sleep(300);
      await ev(cmd, `(localStorage.removeItem('aefLabelPrefs'), 1)`);
    };
    const shot = async name => {
      const { data } = await cmd('Page.captureScreenshot', { format: 'png' });
      mkdirSync(SHOTDIR, { recursive: true });
      const f = join(SHOTDIR, `t1164-${name}.png`); writeFileSync(f, Buffer.from(data, 'base64')); shots.push(f);
    };
    // The first activity of the second lane, dragged clear of every lane band (below the pool).
    const dragOut = `(function(){ var lane = getLanes()[1]; var n = state.nodes.filter(function(n){ return n.lane === lane.id && !laneLabelBelow(n.type); })[0];
      window.__t1164 = { uid: n.uid, x: n.x, y: n.y, lane: n.lane };
      n.y = POOL_Y + poolHeight() + 140; renderAll(); return { node: displayIdOf(n), lane: lane.id }; })()`;
    const putBack = `(function(){ var s = window.__t1164, n = state.nodes.filter(function(n){ return n.uid === s.uid; })[0]; n.x = s.x; n.y = s.y; n.lane = s.lane; renderAll(); return 1; })()`;

    await open(1440);
    const drawnBefore = await ev(cmd, `+svg.querySelector('#g-pool > .pool-border').getAttribute('height')`);
    const moved = await ev(cmd, dragOut);
    const drawnAfter = await ev(cmd, `+svg.querySelector('#g-pool > .pool-border').getAttribute('height')`);
    const floor = await ev(cmd, `poolHeight()`);
    push('a node dragged below every lane does not stretch the drawn pool around it (T-1154 x T-1164)', drawnAfter <= floor + 8 && drawnAfter - drawnBefore <= 8, { drawnBefore, drawnAfter, savedHeight: floor });
    const xmlBefore = await ev(cmd, `buildBpmnXml(state)`);
    await ev(cmd, `runCheck().then(function(){ return 1; })`); await sleep(300);
    let p = await ev(cmd, PROBE);
    const xmlAfter = await ev(cmd, `buildBpmnXml(state)`);
    const namedIds = Object.keys(p.named);
    push('check: the validator reports lane-anchored findings for the dragged-out node', p.state === 'checked' && p.laneRows.length > 0 && namedIds.length > 0, { moved, laneRows: p.laneRows });
    push('every lane a finding names is marked with the worst severity, pill and glyph', namedIds.length > 0 && namedIds.every(id => p.marks[id] && p.marks[id].sev === p.named[id] && p.marks[id].pill && /[✖⚠]/.test(p.marks[id].glyph)), { named: p.named, marks: p.marks });
    push('no lane is marked that no finding names', Object.keys(p.marks).every(id => p.named[id]), { marks: p.marks, named: p.named });
    push('the dock rows of lane findings are anchored to their lane', p.dockRows.length > 0 && p.dockRows.every(r => r.anchored === '1' && namedIds.includes(r.lane)), p.dockRows);
    const onMap = /(\d+) on the map/.exec(p.header);
    push('the dock header counts the marked lanes as on the map', onMap && +onMap[1] >= namedIds.length, p.header);
    push('marking changes nothing in the export', xmlBefore === xmlAfter, { same: xmlBefore === xmlAfter });
    // Click the first lane row: the lane is selected.
    const sel = await ev(cmd, `(function(){ var r = Array.prototype.slice.call(document.querySelectorAll('#findings-list .finding-row[data-lane]'))[0];
      if (!r) return null; r.click(); return selection ? { kind: selection.kind, id: selection.id, want: r.getAttribute('data-lane') } : { none: 1 }; })()`);
    push('clicking a lane finding row selects that lane', sel && sel.kind === 'lane' && sel.id === sel.want, sel);
    // Sticky copies (T-1091) carry the mark.
    await ev(cmd, `(function(){ var wr = document.querySelector('.canvas-wrap'), r = wr.getBoundingClientRect(); setZoom(2, r.left + 1, r.top + 1);
      wr.scrollLeft = Math.round((wr.scrollWidth - wr.clientWidth) * 0.5); return new Promise(function(res){ setTimeout(res, 250); }); })()`);
    const sticky = await ev(cmd, `Array.prototype.slice.call(document.querySelectorAll('#g-sticky-lanes .lane-header[data-finding]')).map(function(h){ return [h.getAttribute('data-lane-id'), h.getAttribute('data-finding')]; })`);
    push('the pinned lane names (T-1091) carry the mark when scrolled', sticky.length === namedIds.length && sticky.every(([id, s]) => p.named[id] === s), sticky);
    // Fix and re-check: marks gone.
    await ev(cmd, `(zoomFactor = null, applyCanvasZoom(), 1)`);
    await ev(cmd, putBack);
    await ev(cmd, `runCheck().then(function(){ return 1; })`); await sleep(300);
    p = await ev(cmd, PROBE);
    push('node put back and re-checked: no lane finding, no lane marked', p.state === 'checked' && Object.keys(p.named).length === 0 && Object.keys(p.marks).length === 0, { named: p.named, marks: p.marks, laneRows: p.laneRows });
    // An unavailable check clears marks: drag out, check, then a check that cannot reach the validator.
    await ev(cmd, dragOut); await ev(cmd, `runCheck().then(function(){ return 1; })`); await sleep(300);
    const before = Object.keys((await ev(cmd, PROBE)).marks).length;
    await ev(cmd, `(function(){ var real = validateCurrentWorkflow; window.validateCurrentWorkflow = function(){ return Promise.resolve({ ok: false, reason: 'test: validator unreachable' }); };
      return runCheck().then(function(){ window.validateCurrentWorkflow = real; return 1; }); })()`).catch(() => null);
    const after = await ev(cmd, PROBE);
    push('a check that could not run clears every lane mark', before > 0 && Object.keys(after.marks).length === 0 && after.state === 'unavailable', { before, after: after.marks, state: after.state });

    // screenshots: lane marked with the dock open, and scrolled with the sticky strip
    for (const w of [1024, 1440, 1920]) {
      await open(w);
      await ev(cmd, dragOut); await ev(cmd, `runCheck().then(function(){ return 1; })`); await sleep(400);
      await shot(`${w}-marked`);
      await ev(cmd, `(function(){ var wr = document.querySelector('.canvas-wrap'), r = wr.getBoundingClientRect(); setZoom(1.6, r.left + 1, r.top + 1);
        wr.scrollLeft = Math.round((wr.scrollWidth - wr.clientWidth) * 0.5); return new Promise(function(res){ setTimeout(res, 300); }); })()`);
      await shot(`${w}-sticky`);
      // Every pinned name that fits in its lane's visible band (above the open dock) lies wholly inside that band.
      const fit = await ev(cmd, `(function(){ var wr = document.querySelector('.canvas-wrap').getBoundingClientRect(), dr = document.getElementById('findings-drawer').getBoundingClientRect();
        var vTop = wr.top, vBot = Math.min(wr.bottom, dr.height ? dr.top : wr.bottom), out = [];
        document.querySelectorAll('#g-sticky-lanes .lane-header').forEach(function(h){
          var lr = h.querySelector('rect').getBoundingClientRect(), top = Math.max(lr.top, vTop), bot = Math.min(lr.bottom, vBot);
          var lb = null; h.querySelectorAll('.lane-label').forEach(function(t){ var b = t.getBoundingClientRect(); lb = lb ? { top: Math.min(lb.top, b.top), bottom: Math.max(lb.bottom, b.bottom) } : { top: b.top, bottom: b.bottom }; });
          if (!lb || bot - top < (lb.bottom - lb.top) + 4) return;   // no room in the visible band: nothing to assert
          out.push({ lane: h.getAttribute('data-lane-id'), inside: lb.top >= top - 1 && lb.bottom <= bot + 1, label: [Math.round(lb.top), Math.round(lb.bottom)], band: [Math.round(top), Math.round(bot)] }); });
        return out; })()`);
      push(`${w} pinned lane names sit inside the visible part of their lane, above the open dock`, fit.length > 0 && fit.every(f => f.inside), fit);
    }
  } catch (e) {
    push('harness', false, String(e && e.stack || e)); process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    await sleep(300);
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
  for (const s of steps) console.log((s.pass ? 'ok    ' : 'FAIL  ') + s.step + (s.pass ? '' : '  got: ' + JSON.stringify(s.got)));
  const failed = steps.filter(s => !s.pass).length;
  console.log(`${failed ? 'FAIL' : 'PASS'}: ${steps.length - failed}/${steps.length}` + (shots.length ? `  (${shots.length} screenshots in .playwright-mcp/)` : ''));
  if (process.exitCode !== 2) process.exitCode = failed ? 1 : 0;
}
main();
