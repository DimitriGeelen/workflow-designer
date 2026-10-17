#!/usr/bin/env node
// _t1154-pool-label-fit-cdp.mjs — verify T-1154 (OBS-314): the DRAWN pool encloses every rendered node label and id
// badge on the right, with a margin, while the BPMN export keeps the box-based pool width (no text measurement).
//   - corpus: on all 24 maps, nothing rendered reaches past the pool's right border
//   - fixture: a long label put under the right-most node is enclosed; shortening it shrinks the pool back
//   - export: identical with the label pad and with it forced to 0, and across label sizes s/m/l
// Same harness as _t1091 (gallery-serve.py temp docroot, ISOLATED headless chromium).
// Writes .playwright-mcp/t1154-<width>-{fit,zoomed}.png of the fixture at 1024/1440/1920 for the visual review.
// T1154_DESIGNER=<file> runs it against another build (control: the pre-T-1154 designer fails the enclosure legs).
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
const RENDERED = join(REPO, 'examples/aef-processes/rendered');
const FIXTURE_MAP = 'healing-loop';     // the corpus map that overhung (+3 px) when T-1154 was measured
const LONG = 'Resolved, recorded and promoted to a durable project learning';
const MIN_MARGIN = 10;                  // POOL_LABEL_MARGIN is 12; bbox rounding leaves at least 10
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// In the page: how far the furthest rendered label / badge sits from the drawn pool's right border (negative = inside).
const OVERHANG = `(function(){
  var pb = svg.querySelector('#g-pool > .pool-border');
  var edge = +pb.getAttribute('x') + +pb.getAttribute('width'), worst = -1e9, what = '';
  svg.querySelectorAll('#g-nodes .node-label, #g-badges text, #g-badges-top text').forEach(function(t){
    var b; try { b = t.getBBox(); } catch (e) { return; } if (!b.width) return;
    var o = b.x + b.width - edge; if (o > worst) { worst = o; what = t.textContent.slice(0, 40); } });
  return { overhang: worst, what: what, drawnW: +pb.getAttribute('width') };
})()`;
// The participant's exported DI width, read from the export itself.
const EXPORT_W = `(function(){ var x = buildBpmnXml(state);
  var m = x.match(/<bpmndi:BPMNShape[^>]*bpmnElement="[^"]*"[^>]*isHorizontal="true"[^>]*>\\s*<dc:Bounds[^>]*width="(\\d+)"/) ||
          x.match(/<dc:Bounds x="[^"]*" y="[^"]*" width="(\\d+)"/);
  return { xml: x, w: m ? +m[1] : null }; })()`;

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't1154-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1154-repo-'));
  copyFileSync(process.env.T1154_DESIGNER || join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const maps = readdirSync(RENDERED).filter(f => f.endsWith('.bpmn')).sort();
  for (const f of maps) copyFileSync(join(RENDERED, f), join(doc, 'rendered', f));
  // a two-pool collaboration (T-1119): the only shape that exports a pool DI width
  copyFileSync(join(REPO, 'tests/fixtures/aef-bpmn/t1119-sales-cpq-collaboration.bpmn'), join(doc, 'rendered', 'collab-fixture.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1154-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const steps = [], shots = [];
  const push = (n, p, g) => steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    const open = async (map, w) => {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: 860, deviceScaleFactor: 1, mobile: false });
      await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${map}.bpmn` });
      await sleep(300); await waitReady(cmd); await sleep(300);
      await ev(cmd, `document.fonts.ready.then(function(){ return new Promise(function(r){ setTimeout(r, 200); }); })`);
    };
    const shot = async name => {
      const { data } = await cmd('Page.captureScreenshot', { format: 'png' });
      mkdirSync(SHOTDIR, { recursive: true });
      const f = join(SHOTDIR, `t1154-${name}.png`); writeFileSync(f, Buffer.from(data, 'base64')); shots.push(f);
    };
    // The right-most node by box edge, renamed to a long label (below-labelled node types get it under the shape).
    // Only nodes whose label sits BELOW the shape (events, gateways): a task's label is inside its box.
    const lengthen = name => ev(cmd, `(function(){ var best = null, br = -1e9;
      state.nodes.forEach(function(n){ if (!laneLabelBelow(n.type)) return; var d = NODE_DEFAULTS[n.type] || NODE_DEFAULTS.serviceTask; if (n.x + d.w > br) { br = n.x + d.w; best = n; } });
      best.name = ${JSON.stringify(name)}; renderAll(); return { type: best.type, uid: best.uid }; })()`);

    // 1. corpus
    await ev(cmd, `1`);
    const bad = [];
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 860, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await sleep(300); await waitReady(cmd);
    await ev(cmd, `(localStorage.removeItem('aefLabelPrefs'), 1)`);
    for (const f of maps) {
      await open(f.replace(/\.bpmn$/, ''), 1440);
      const o = await ev(cmd, OVERHANG);
      if (!(o.overhang <= -MIN_MARGIN)) bad.push(`${f}: ${o.overhang.toFixed(1)} (${o.what})`);
    }
    push(`corpus: on all ${maps.length} maps every label and badge sits >= ${MIN_MARGIN}px inside the pool's right border`, bad.length === 0, bad);

    // 2-5. fixture: long label under the right-most node
    await open(FIXTURE_MAP, 1440);
    const base = await ev(cmd, OVERHANG);
    const node = await lengthen(LONG); await sleep(150);
    const lo = await ev(cmd, OVERHANG);
    push(`fixture: a long label under the right-most node (${node.type}) is enclosed`, lo.overhang <= -MIN_MARGIN && lo.drawnW > base.drawnW, { before: base, after: lo });
    const ex = await ev(cmd, EXPORT_W);
    const exNoPad = await ev(cmd, `(function(){ var keep = poolLabelPad; poolLabelPad = 0; var x = buildBpmnXml(state); poolLabelPad = keep; return x; })()`).catch(e => 'ERR ' + e);
    push('export: identical with the label pad and with it forced to 0', exNoPad === ex.xml, { same: exNoPad === ex.xml, len: ex.xml.length });
    const bySize = [];
    for (const s of ['s', 'm', 'l']) { await ev(cmd, `(setLabelPref('size', '${s}'), 1)`); await sleep(120); bySize.push(await ev(cmd, `buildBpmnXml(state)`)); }
    const lAfter = await ev(cmd, OVERHANG);
    push('export: identical across label sizes s/m/l', bySize[0] === bySize[1] && bySize[1] === bySize[2], { lens: bySize.map(x => x.length) });
    push('fixture at label size l: still enclosed', lAfter.overhang <= -MIN_MARGIN, lAfter);
    await ev(cmd, `(setLabelPref('size', 'm'), 1)`); await sleep(120);
    await lengthen('Done'); await sleep(150);
    const sh = await ev(cmd, OVERHANG);
    push('fixture: shortening the label shrinks the drawn pool back (no stale widening)', sh.drawnW < lo.drawnW && sh.overhang <= -MIN_MARGIN, { long: lo.drawnW, short: sh.drawnW });

    // A collaboration map exports its pool's DI width (T-1119; a one-pool map exports no pool shape at all): that width
    // must stay the box-based one, below the widened drawn pool.
    let collab = null;
    for (const f of ['collab-fixture.bpmn', ...maps]) { await open(f.replace(/\.bpmn$/, ''), 1440); if (await ev(cmd, `!!state.collab`)) { collab = f; break; } }
    if (collab) {
      // Here a long label is wrapped and placed inside by T-601 (measured: 103 px inside), so no pad arises naturally.
      // The property under test is the separation itself: with a 100 px pad drawn, the exported pool shape keeps the
      // box-based width and the export is byte-identical to the pad-free one.
      const x0 = await ev(cmd, `buildBpmnXml(state)`);
      const boxW = await ev(cmd, `Math.round(contentRightEdge() - POOL_X)`);
      const r = await ev(cmd, `(function(){ poolLabelPad = 100; renderPool();
        var pb = svg.querySelector('#g-pool > .pool-border'), x = buildBpmnXml(state), w = +pb.getAttribute('width');
        poolLabelPad = 0; renderAll(); return { drawnW: w, xml: x }; })()`);
      const pm = r.xml.match(/isHorizontal="true">\s*<dc:Bounds x="[^"]*" y="[^"]*" width="(\d+)"/);
      const pw = pm ? +pm[1] : null;
      push(`export (${collab}, collaboration): with a 100px pad drawn, the pool's DI width stays box-based and the export is unchanged`,
           pw === boxW && r.drawnW === boxW + 100 && r.xml === x0, { exportW: pw, boxW, drawnW: r.drawnW, same: r.xml === x0 });
    } else {
      push('export (collaboration): the T-1119 two-pool fixture no longer loads as a collaboration, so the pool-shape branch is untested', false, null);
    }

    // screenshots of the fixture
    for (const w of [1024, 1440, 1920]) {
      await open(FIXTURE_MAP, w);
      await lengthen(LONG); await sleep(250);
      await shot(`${w}-fit`);
      await ev(cmd, `(function(){ var wr = document.querySelector('.canvas-wrap'), r = wr.getBoundingClientRect(); setZoom(1.6, r.left + 1, r.top + 1);
        wr.scrollLeft = wr.scrollWidth; return new Promise(function(res){ setTimeout(res, 250); }); })()`);
      await shot(`${w}-zoomed`);
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
