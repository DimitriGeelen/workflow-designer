// T-1465 — labels: no flow label is drawn on the "+ Add another lane" strip below the pool. Found in T-1456's screenshot
// review: task-lifecycle's "gate failed — rework" sat on the strip, under the button text. Measured on the DRAWN labels
// (#g-edges text.edge-label, getBBox) against rect.pool-add-lane-strip-bg, headless Chromium over CDP, one browser per
// load (T-1456's lesson).
//
//   S1 [every corpus map and the Greenfield fixture, 1024/1440/1920] no flow label overlaps the strip; at least one label measured.
//   S2 [same] every flow and its label is drawn inside the drawn pool (rect.pool-border): on task-lifecycle and task-gate
//      the router puts a loop bar under the last lane; the drawn pool now encloses it (fitPoolToLabels). Routes the
//      author set are listed, not counted.
// Teeth: T1465_EDITOR=<the 0.45.0 designer> fails S1 and S2 on task-lifecycle.
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1465_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const RENDERED = join(ROOT, 'examples', 'aef-processes', 'rendered');
const FIXTURE = join(ROOT, 'tests', 'fixtures', 'greenfield', 'nooteboom-offerte-tot-order-with-notes.bpmn');
const CORPUS = process.env.T1465_MAPS ? process.env.T1465_MAPS.split(',') : readdirSync(RENDERED).filter(f => f.endsWith('.bpmn')).sort();
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1465-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
for (const m of CORPUS) copyFileSync(join(RENDERED, m), join(doc, 'rendered', m));
copyFileSync(FIXTURE, join(doc, 'rendered', 'greenfield.bpmn'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
// T-1456: one browser per map load. On the pool, the third large page loaded in ONE tab stopped answering at
// 1920 (twice, both workers) and did not even answer Debugger.pause, which interrupts any running script (proven
// here on a deliberate hang): the page process itself was gone or blocked, not our code looping. A fresh browser per
// load keeps every measure independent of the ones before it; a reported crash is named (Inspector.targetCrashed).
let br = null, cl = null, udd = null;
const profiles = [];
const dialogs = [], crashes = [];
let paused = null, step = 'start';
// In the page: every flow's drawn polyline, its ends' sides, lane bounds; the two counts and the 'wel' details.
// In the page: every drawn flow label's box against the "+ Add another lane" strip below the pool.
const MEASURE = `(function(){
  const strip = document.querySelector('rect.pool-add-lane-strip-bg');
  if (!strip) return { strip: null, hits: [], labels: 0 };
  const sb = strip.getBBox();
  const S = { x: sb.x, y: sb.y, w: sb.width, h: sb.height };
  const hits = [];
  let n = 0;
  for (const t of document.querySelectorAll('#g-edges text.edge-label')) {
    let b; try { b = t.getBBox(); } catch (e) { continue; }
    n++;
    const L = { x: b.x, y: b.y, w: b.width, h: b.height };
    if (L.x < S.x + S.w && S.x < L.x + L.w && L.y < S.y + S.h && S.y < L.y + L.h)
      hits.push((t.textContent || '').slice(0, 40) + ' [' + t.dataset.el + '] label y ' + Math.round(L.y) + '-' + Math.round(L.y + L.h) + ', strip y ' + Math.round(S.y) + '-' + Math.round(S.y + S.h)
        + (function(){ const g = document.querySelector('#g-edges g.edge[data-id="' + t.dataset.el + '"] path.edge-path'); return g ? '; flow ' + polylineFromPath(g.getAttribute('d')).map(q => Math.round(q.x) + ',' + Math.round(q.y)).join(' ') : ''; })());
  }
  // S2: every flow (and its label) is drawn inside the drawn pool (rect.pool-border); a route the author set is listed
  const out = [], excused = [];
  const pb = document.querySelector('#g-pool rect.pool-border, rect.pool-border');
  if (pb) {
    const pbb = pb.getBBox(), top = pbb.y, bot = pbb.y + pbb.height;
    for (const g of document.querySelectorAll('#g-edges g.edge[data-id]')) {
      const e = state.edges.find(x => x.id === g.dataset.id), p = g.querySelector('path.edge-path');
      if (!e || !p) continue;
      const lab = g.querySelector('text.edge-label'); let lb = null; try { lb = lab && lab.getBBox(); } catch (err) {}
      const ys = polylineFromPath(p.getAttribute('d')).map(q => q.y).concat(lb ? [lb.y, lb.y + lb.height] : []).filter(y => y < top - 1 || y > bot + 1);
      if (!ys.length) continue;
      const what = e.id + ' ' + (e.name || '').slice(0, 30) + ' y ' + ys.map(Math.round).join(',') + ' pool ' + Math.round(top) + '-' + Math.round(bot);
      const authored = (e.waypoints && e.waypoints.length) || (e.routingHints && Object.keys(e.routingHints).length) || typeof e.detourY === 'number';
      (authored ? excused : out).push(what);
    }
  }
  return { strip: S, hits, labels: n, out, excused };
})()`;
// T-1257: removeProfileDir also removes Chrome's own per-launch org.chromium.Chromium.* dir (found through the
// profile's SingletonSocket link); a plain rmSync of the profile left one behind per load (_t1257 red, 2026-11-20).
const stopBrowser = async () => {
  try { cl && cl.close(); } catch (_) {}
  if (br) { const dead = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([dead, sleep(3000)]); }
  if (udd) removeProfileDir(udd);
  cl = null; br = null; udd = null;
};
const startBrowser = async W => {
  await stopBrowser();
  udd = makeProfileDir('t1465-'); profiles.push(udd);   // a fresh profile: no storage carried over either
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', `--window-size=${W},900`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  // T-1395's rule: a JavaScript dialog blocks every Runtime.evaluate until answered: accept it at once, and NAME it.
  const c = cdp(await pageWsUrl(dp), { cmdMs: 60000, onEvent: m => {
    if (m.method === 'Page.javascriptDialogOpening') { dialogs.push(`${m.params.type}: ${String(m.params.message).slice(0, 160)}`); c.cmd('Page.handleJavaScriptDialog', { accept: true }).catch(() => {}); }
    if (m.method === 'Inspector.targetCrashed') crashes.push(step);
    if (m.method === 'Debugger.paused') paused = m.params; } });
  await c.ready;
  await c.cmd('Page.enable'); await c.cmd('Runtime.enable'); await c.cmd('Inspector.enable').catch(() => {}); await c.cmd('Debugger.enable');
  cl = c;
};
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const open = async (map, W) => {
    step = `open ${map} @${W}`;
    await startBrowser(W);
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 1, mobile: false });
    await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${map}` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
    await sleep(500);
    step = `measure ${map} @${W}`;
    return ev(MEASURE);
  };
  let sum = 0, labels = 0, outN = 0; const per = [], outs = [], exc = [];
  for (const W of [1024, 1440, 1920]) {
    for (const map of [...CORPUS, 'greenfield.bpmn']) {
      const m = await open(map, W);
      if (!m.strip) { leg(false, `[${map} @${W}] no add-lane strip drawn`, ''); continue; }
      sum += m.hits.length; labels += m.labels;
      outN += m.out.length; for (const x of m.out) outs.push(`${map.replace('.bpmn', '')} @${W}: ${x}`);
      if (W === 1440) for (const x of m.excused) exc.push(`${map.replace('.bpmn', '')}: ${x}`);
      for (const h of m.hits) per.push(`${map.replace('.bpmn', '')} @${W}: ${h}`);
      // T1465_SHOTS=<dir>: a screenshot of each map in its opening view (for the visual review), not a leg
      if (process.env.T1465_SHOTS) {
        const shot = await cl.cmd('Page.captureScreenshot', { format: 'png' });
        mkdirSync(process.env.T1465_SHOTS, { recursive: true });
        writeFileSync(join(process.env.T1465_SHOTS, `${map.replace('.bpmn', '')}-${W}.png`), Buffer.from(shot.data, 'base64'));
        if (W === 1920) {   // and the whole map: a 3000 px wide window, so a flow at the far right is in the picture too
          await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 3000, height: 1000, deviceScaleFactor: 1, mobile: false });
          await sleep(800);
          const wide = await cl.cmd('Page.captureScreenshot', { format: 'png' });
          writeFileSync(join(process.env.T1465_SHOTS, `${map.replace('.bpmn', '')}-wide.png`), Buffer.from(wide.data, 'base64'));
        }
      }
    }
  }
  leg(sum === 0 && labels > 0, `S1 [${CORPUS.length} corpus maps + the Greenfield fixture @1024/1440/1920] no flow label lies on the "+ Add another lane" strip (T-1465)`,
      `${labels} labels measured; on the strip: ${sum ? sum + ': ' + per.join(' | ') : 'none'}`);
  leg(outN === 0, `S2 [same] every flow and its label is drawn inside the drawn pool`,
      `${outN ? outN + ': ' + outs.join(' | ') : 'none'}; routes the author set, outside the pool: ${exc.length ? exc.join(' | ') : 'none'}`);
} catch (e) {
  leg(false, 'harness error', `${String(e && e.message || e).slice(0, 300)} (during: ${step})`);
  // A page that stopped answering: pause its JavaScript and print where it is (our code or the browser's).
  if (/CDP TIMEOUT/.test(String(e && e.message)) && cl) {
    try {
      await cl.cmd('Debugger.pause');   // enabled at the start: enabling it needs the busy main thread
      for (let i = 0; i < 100 && !paused; i++) await sleep(100);
      console.log(paused ? 'STACK of the page that stopped answering: ' + paused.callFrames.slice(0, 10).map(f => `${f.functionName || '(anon)'}:${f.location.lineNumber + 1}`).join(' < ')
                         : 'STACK: the page did not pause within 10 s (not busy in JavaScript: stuck in layout, paint or the browser)');
    } catch (e2) { console.log('STACK: could not pause the page: ' + String(e2 && e2.message || e2).slice(0, 160)); }
  }
} finally {
  await stopBrowser(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  if (crashes.length) console.log(`NOTE  the page process crashed during: ${crashes.join(' | ')}`);
  if (dialogs.length) console.log(`NOTE  ${dialogs.length} JavaScript dialog(s) opened and were accepted: ${dialogs.join(' | ')}`);
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
