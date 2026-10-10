#!/usr/bin/env node
// _t1120-collab-pools-drawn-cdp.mjs — T-1120 (P2): the kept pools are DRAWN (read-only) and the message flows
// run between them; the canvas and the exported DI use one layout.
//
// T-1119 kept every pool and message flow on save but showed only ours (with a notice). P2 draws the rest:
// a band per kept pool below ours, its elements moved into it, message flows dashed with an open circle at
// the source and an open arrowhead at the target (BPMN 2.0.2). Legs:
//   A  synthetic Sales + Tacton CPQ: 1 kept band, 2 dashed message flows with both markers
//   B  kitchen-sink: 1 kept band, 2 message flows
//   C  drag "Ask CPQ for price" 80 px right: its message flow's start moves 80 px (live node)
//   D  exported DI == canvas: P_cpq's shape == its band; MF_config's waypoints == its drawn path
//   E  read-only: the layer takes no pointer events
//   F  a one-pool map draws no kept band and no message flow
//   G  flows between the same two ends are drawn apart (kitchen-sink: one each way between the pools)
//   T1120_SHOTS=<dir> also writes screenshots.   node tools/_t1120-collab-pools-drawn-cdp.mjs [--designer PATH]
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const argv = process.argv.slice(2);
const DESIGNER = (argv.indexOf('--designer') >= 0 && argv[argv.indexOf('--designer') + 1]) || join(REPO, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }


const FIX = join(REPO, 'tests', 'fixtures');
const SYN = readFileSync(join(FIX, 'aef-bpmn', 't1119-sales-cpq-collaboration.bpmn'), 'utf8');
const KS = readFileSync(join(FIX, 'third-party', 'kitchen-sink.bpmn'), 'utf8');
const ONE = readFileSync(join(FIX, 'aef-bpmn', 't1092-no-authority.bpmn'), 'utf8');
const VIEW = `(function(){ var g = document.getElementById('g-collab');
  var flows = g ? Array.prototype.slice.call(g.querySelectorAll('[data-message-flow]')) : [];
  return { bands: g ? g.querySelectorAll('[data-collab-pool]').length : -1, flows: flows.length,
    styled: flows.every(function(f){ return f.getAttribute('stroke-dasharray') && /mf-start/.test(f.getAttribute('marker-start')||'') && /mf-end/.test(f.getAttribute('marker-end')||''); }),
    pe: g ? g.getAttribute('pointer-events') : null }; })()`;
const LOAD = xml => `(function(){ adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); renderAll(); return true; })()`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1120-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1120-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1120-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; };' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    const shot = async name => { if (!process.env.T1120_SHOTS) return; mkdirSync(process.env.T1120_SHOTS, { recursive: true });
      // the whole canvas, not the viewport: the kept bands lie below our pool — a tall window for the shot only
      await cmd('Emulation.setDeviceMetricsOverride', { width: 1600, height: 2400, deviceScaleFactor: 1, mobile: false });
      await ev(cmd, 'renderAll(); true'); await sleep(400);
      const r = await cmd('Page.captureScreenshot', { format: 'png' });
      await cmd('Emulation.clearDeviceMetricsOverride');
      writeFileSync(join(process.env.T1120_SHOTS, name), Buffer.from(r.data, 'base64')); };

    await ev(cmd, LOAD(SYN)); await sleep(250);
    let v = await ev(cmd, VIEW);
    leg(v.bands === 1 && v.flows === 2 && v.styled, 'A synthetic: 1 kept band (Tacton CPQ), 2 dashed message flows with circle + arrowhead', JSON.stringify(v));
    leg(v.pe === 'none', 'E read-only: the kept-pool layer takes no pointer events', 'pointer-events=' + v.pe);
    await shot('sales-cpq.png');
    // C: drag the source node of MF_config
    const pt = `(function(){ var p = document.querySelector('[data-message-flow="MF_config"]'); if (!p) return null; var m = p.getAttribute('d').match(/M(-?[\\d.]+),(-?[\\d.]+)/); return { x: +m[1], y: +m[2] }; })()`;
    const before = await ev(cmd, pt);
    await ev(cmd, `(function(){ var n = state.nodes.find(function(x){ return x.uid === 'n_ask'; }); n.x += 80; renderNodes(); renderEdges(); return true; })()`);
    const after = await ev(cmd, pt);
    leg(before && after && Math.round(after.x - before.x) === 80, 'C dragging "Ask CPQ for price" 80 px moves its message flow start 80 px', JSON.stringify({ before, after }));
    // D: export == canvas
    const d = await ev(cmd, `(function(){ var x = buildBpmnXml(state); var doc = new DOMParser().parseFromString(x, 'application/xml');
      var DI = 'http://www.omg.org/spec/BPMN/20100524/DI', DC = 'http://www.omg.org/spec/DD/20100524/DC';
      var sh = Array.prototype.slice.call(doc.getElementsByTagNameNS(DI, 'BPMNShape')).find(function(e){ return e.getAttribute('bpmnElement') === 'P_cpq'; });
      var bd = sh ? sh.getElementsByTagNameNS(DC, 'Bounds')[0] : null;
      var ed = Array.prototype.slice.call(doc.getElementsByTagNameNS(DI, 'BPMNEdge')).find(function(e){ return e.getAttribute('bpmnElement') === 'MF_config'; });
      var wps = ed ? Array.prototype.slice.call(ed.childNodes).filter(function(c){ return c.localName === 'waypoint'; }).map(function(w){ return w.getAttribute('x') + ',' + w.getAttribute('y'); }).join(' ') : '';
      var band = document.querySelector('[data-collab-pool="P_cpq"]'); var path = document.querySelector('[data-message-flow="MF_config"]');
      var drawn = path ? (path.getAttribute('d').match(/-?[\\d.]+,-?[\\d.]+/g) || []).join(' ') : '';
      return { di: bd ? [bd.getAttribute('x'), bd.getAttribute('y'), bd.getAttribute('width'), bd.getAttribute('height')].join(',') : null,
               canvas: band ? [band.getAttribute('x'), band.getAttribute('y'), band.getAttribute('width'), band.getAttribute('height')].join(',') : null,
               wps: wps, drawn: drawn }; })()`);
    leg(d.di && d.di === d.canvas && d.wps && d.wps === d.drawn, 'D exported DI == canvas (CPQ pool bounds, MF_config waypoints)', JSON.stringify(d));

    await ev(cmd, LOAD(KS)); await sleep(250);
    v = await ev(cmd, VIEW);
    leg(v.bands === 1 && v.flows === 2 && v.styled, 'B kitchen-sink: 1 kept band, 2 message flows', JSON.stringify(v));
    const paths = await ev(cmd, `Array.prototype.slice.call(document.querySelectorAll('#g-collab [data-message-flow]')).map(function(p){ return p.getAttribute('d'); })`);
    leg(paths.length === 2 && new Set(paths).size === 2, 'G kitchen-sink: the two flows between the same two pools are drawn apart, not on top of each other', JSON.stringify(paths));
    await shot('kitchen-sink.png');

    await ev(cmd, LOAD(ONE)); await sleep(250);
    v = await ev(cmd, VIEW);
    leg(v.bands === 0 && v.flows === 0, 'F a one-pool map draws no kept band and no message flow', JSON.stringify(v));
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
  for (const l of legs) console.log(`${l.ok ? 'PASS' : 'FAIL'}  ${l.name}${l.detail ? ' — ' + l.detail : ''}`);
  const want = 7;
  const ok = legs.length === want && legs.every(l => l.ok);
  console.log(ok ? `${legs.length}/${want} legs passed` : `FAILED (${legs.filter(l => !l.ok).length} of ${legs.length})`);
  process.exitCode = ok ? 0 : 1;
}
main();
