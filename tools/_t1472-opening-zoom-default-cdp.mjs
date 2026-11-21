// T-1472 — the starter map opens readable too. AEF (msgs ab0a31c3, 05448169, 2026-11-21): /designer/app with no query,
// top-level, headless at a 1024 px viewport: the built-in starter map ("investigate") opened at "fit", its text well
// below 9 px. openingZoom() (T-1256/T-1278: never open with the smallest drawn map text under OPEN_MIN_TEXT_PX) ran on
// every load path but the first render at start-up, where no load happens.
//
//   O1 [no query, empty storage, 1024/1440/1920] the smallest drawn map text (OPEN_TEXT_SEL) is >= OPEN_MIN_TEXT_PX
//   (Measured on 0.45.0: 2.7 px at 1024, 5.1 at 1440, 7.8 at 1920 — fit was below the floor at every width.)
// Teeth: T1472_EDITOR=<the 0.45.0 designer> fails O1 at 1024.
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
const EDITOR = process.env.T1472_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1472-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const MEASURE = `(function(){
  var fit = svg.getScreenCTM().a, min = Infinity, n = 0;
  for (var t of svg.querySelectorAll(OPEN_TEXT_SEL)) {
    var r = t.getBoundingClientRect(); if (!r.width) continue;
    var px = parseFloat(getComputedStyle(t).fontSize) * fit; n++;
    if (px > 0 && px < min) min = px;
  }
  return { zoom: zoomFactor, ctm: Math.round(fit * 1000) / 1000, minPx: Math.round(min * 10) / 10, texts: n, floor: OPEN_MIN_TEXT_PX,
           map: state.workflowMeta.id, canvasW: canvasWrap.clientWidth };
})()`;
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const res = {};
  for (const W of [1024, 1440, 1920]) {
    await stop();
    const udd = makeProfileDir('t1472-'); profiles.push(udd);   // a fresh profile: no autosave, as on a first visit
    br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', `--window-size=${W},900`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
    let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
    cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
    await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 1, mobile: false });
    await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
    await ev(`document.fonts.ready.then(function(){ return new Promise(function(r){ setTimeout(r, 500); }); })`);
    res[W] = await ev(MEASURE);
    if (process.env.T1472_SHOTS) {   // the opening view, for the visual review (not a leg)
      const shot = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      mkdirSync(process.env.T1472_SHOTS, { recursive: true });
      writeFileSync(join(process.env.T1472_SHOTS, `starter-${W}.png`), Buffer.from(shot.data, 'base64'));
    }
    leg(res[W].texts > 0 && res[W].minPx >= res[W].floor, `O1 [starter map, no query, @${W}] the smallest drawn map text is >= ${res[W].floor} px`, JSON.stringify(res[W]));
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
