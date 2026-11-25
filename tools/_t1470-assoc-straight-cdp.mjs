// T-1470 — an association between two steps that line up is drawn straight. Greenfield msg bfd033c1 (2026-11-21,
// 0.45.0 re-check): the dotted associations "Opportunity / Solution – Product" -> "Product (status: Needs Analysis)"
// and "Open Order" -> "Sales Order (status: Open Order)" were drawn diagonally although both steps are vertically
// aligned in the DI (same x, same width; the file's own waypoints are vertical).
//
//   A1 [Greenfield fixture, 1024/1440/1920] both associations are drawn as one vertical segment (|dx| <= 1 px), each
//      end on its step's box (within 3 px)
//   A2 [same, 1440] every other drawn step-to-step association of the fixture whose boxes overlap in x (or y) by at
//      least a third of the narrower box is straight too; the rest are listed
// Teeth: T1470_EDITOR=<the 0.45.0 designer> fails A1. T1470_REPORT=1 prints every association's points and boxes.
import { readFileSync, writeFileSync, mkdtempSync, mkdirSync, copyFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1470_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const FIXTURE = join(ROOT, 'tests', 'fixtures', 'greenfield', 'nooteboom-offerte-tot-order-with-notes.bpmn');
const REPORT = !!process.env.T1470_REPORT;
const PAIRS = [['Opportunity / Solution', 'Product (status: Needs Analysis)'], ['Open Order', 'Sales Order (status: Open Order)']];
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1470-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
copyFileSync(FIXTURE, join(doc, 'rendered', 'greenfield.bpmn'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
// In the page: each drawn step-to-step association: its points, its two steps' drawn boxes, the steps' DI-to-canvas.
const MEASURE = `(function(){
  var L = notesLayout(state); if (!L) return { links: [] };
  var byUid = new Map(state.nodes.map(function(n){ return [n.uid, n]; }));
  var out = [];
  for (var l of L.links) {
    var a = l.ends.sourceRef, z = l.ends.targetRef;
    if (!a || !z || !a.node || !z.node) continue;
    var A = byUid.get(a.node), Z = byUid.get(z.node); if (!A || !Z) continue;
    var dA = dims(A), dZ = dims(Z);
    var p = document.querySelector('path[data-note-assoc="' + l.id + '"]');
    var nums = p ? (p.getAttribute('d') || '').match(/-?\\d+(?:\\.\\d+)?/g) || [] : [];
    var pts = []; for (var i = 0; i + 1 < nums.length; i += 2) pts.push({ x: +nums[i], y: +nums[i + 1] });
    out.push({ id: l.id, from: A.name, to: Z.name, pts: pts.map(function(q){ return [Math.round(q.x), Math.round(q.y)]; }),
      A: [Math.round(A.x), Math.round(A.y), Math.round(dA.w), Math.round(dA.h)], Z: [Math.round(Z.x), Math.round(Z.y), Math.round(dZ.w), Math.round(dZ.h)],
      fileWps: (l.wps || []).map(function(q){ return [Math.round(q.x), Math.round(q.y)]; }),
      raw: p ? (p.tagName + ' ' + (p.getAttribute('d') || p.getAttribute('points') || '')).slice(0, 120) : 'no element' });
  }
  return { links: out };
})()`;
const onBox = (p, b) => p[0] >= b[0] - 3 && p[0] <= b[0] + b[2] + 3 && p[1] >= b[1] - 3 && p[1] <= b[1] + b[3] + 3;
const straight = pts => pts.length >= 2 && pts.every((q, i) => i === 0 || Math.abs(q[0] - pts[i - 1][0]) <= 1 || Math.abs(q[1] - pts[i - 1][1]) <= 1) && pts.length === 2;
const overlap = (a, b, axis) => { const [o, s] = axis === 'x' ? [0, 2] : [1, 3]; const lo = Math.max(a[o], b[o]), hi = Math.min(a[o] + a[s], b[o] + b[s]); return (hi - lo) / Math.min(a[s], b[s]); };
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  for (const W of [1024, 1440, 1920]) {
    await stop();
    const udd = makeProfileDir('t1470-'); profiles.push(udd);
    br = spawn(chrome, ['--headless=new', '--disable-dev-shm-usage', '--no-sandbox', '--disable-gpu', `--window-size=${W},900`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
    let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
    cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
    await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 1, mobile: false });
    await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/greenfield.bpmn` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
    await sleep(600);
    const m = await ev(MEASURE);
    if (REPORT && W === 1440) for (const l of m.links) console.log('      ' + JSON.stringify(l));
    if (process.env.T1470_PROBE && W === +(process.env.T1470_PROBE_W || 1440)) console.log('      probe ' + JSON.stringify(await ev(readFileSync(process.env.T1470_PROBE, 'utf8'))));
    for (const [f, t] of PAIRS) {
      const l = m.links.find(x => x.from.startsWith(f) && x.to.startsWith(t));
      const ok = !!l && l.pts.length === 2 && Math.abs(l.pts[0][0] - l.pts[1][0]) <= 1 && onBox(l.pts[0], l.A) && onBox(l.pts[1], l.Z);
      leg(ok, `A1 [greenfield @${W}] '${f}' -> '${t.slice(0, 24)}' is one vertical segment, each end on its step`,
          l ? `points ${JSON.stringify(l.pts)}; boxes ${JSON.stringify(l.A)} / ${JSON.stringify(l.Z)}; file waypoints ${JSON.stringify(l.fileWps)}` : 'association not drawn');
    }
    if (process.env.T1470_SHOTS && W === 1440) {   // a crop around each pair, for the visual review (not a leg)
      mkdirSync(process.env.T1470_SHOTS, { recursive: true });
      for (const [i, [f]] of PAIRS.entries()) {
        const r = await ev(`(function(){ var n = state.nodes.find(function(x){ return (x.name||'').indexOf(${JSON.stringify(f)}) === 0; });
          var c = svg.getScreenCTM(), wr = canvasWrap.getBoundingClientRect();
          canvasWrap.scrollLeft += (c.a * n.x + c.e) - wr.left - 250; canvasWrap.scrollTop += (c.d * n.y + c.f) - wr.top - 300;
          c = svg.getScreenCTM(); return { x: c.a * n.x + c.e, y: c.d * n.y + c.f, k: c.a }; })()`);
        await sleep(300);
        const clip = { x: Math.max(0, r.x - 120), y: Math.max(0, r.y - 230 * r.k), width: 360, height: 360 * Math.max(1, r.k), scale: 1 };
        const shot = await cl.cmd('Page.captureScreenshot', { format: 'png', clip });
        writeFileSync(join(process.env.T1470_SHOTS, `pair${i + 1}-1440.png`), Buffer.from(shot.data, 'base64'));
      }
    }
    if (W === 1440) {
      const bad = [], other = [];
      for (const l of m.links) {
        const ox = overlap(l.A, l.Z, 'x'), oy = overlap(l.A, l.Z, 'y');
        if (ox >= 1 / 3 || oy >= 1 / 3) { if (!straight(l.pts)) bad.push(`${l.from.slice(0, 20)} -> ${l.to.slice(0, 20)} ${JSON.stringify(l.pts)}`); }
        else other.push(`${l.from.slice(0, 20)} -> ${l.to.slice(0, 20)}`);
      }
      leg(bad.length === 0, `A2 [greenfield @1440] every step-to-step association between boxes that line up is straight`,
          `${bad.length ? 'diagonal: ' + bad.join(' | ') : 'all straight'}; not lined up (any shape): ${other.length ? other.join(' | ') : 'none'}`);
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
