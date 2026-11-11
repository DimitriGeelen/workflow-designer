#!/usr/bin/env node
// _t1392-settings-reach-cdp.mjs — T-1392: every control in Settings can be reached. Until T-1392 the dialog had no
// max-height and its body no overflow, inside a fixed modal 90px from the top, so at 1024x768 (and 1920x1080) it ran
// past the window's bottom and its lower settings (Labels, "Reset to defaults") could not be reached at all.
// At 1024x768, 1440x900 and 1920x1080 it opens Settings and asserts:
//   S1 the dialog ends inside the window;
//   S2 the last control ("Reset to defaults", #btn-settings-reset) scrolls into view and is the element at its own
//      centre (a click lands on it);
//   S3 after that scroll the header's Close button is still in view.
// --self-test adds one poisoned designer (the T-1392 rules removed): S1 and S2 must go red.
// Usage:  node tools/_t1392-settings-reach-cdp.mjs [--self-test] [--src FILE] [--shots DIR]
// Exit:   0 pass · 1 leg failed · 2 setup broken
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, mkdirSync, existsSync, readFileSync, readdirSync, copyFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { cdp } from './_cdp-client.mjs';   // T-1395: rejects on Chrome's death and after cmdMs, never waits for ever

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const args = process.argv.slice(2);
const opt = k => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : null; };
const selfTest = args.includes('--self-test');
const SRC = opt('--src') || join(REPO, 'src/aef-workflow-designer.html');
const shotDir = opt('--shots');
const SERVER = join(HERE, 'gallery-serve.py');
const WIDTHS = [[1024, 768], [1440, 900], [1920, 1080]];
const sleep = ms => new Promise(r => setTimeout(r, ms));
// T-1388: every temp dir this harness makes (doc, repo, poison copies) is removed when the process ends, whatever the
// outcome; the Chrome profiles are makeProfileDir's and clean themselves. Before, each run left them in /tmp (a tmpfs).
const TMPDIRS = [];
const mkTmp = prefix => { const d = mkdtempSync(join(tmpdir(), prefix)); TMPDIRS.push(d); return d; };
process.on('exit', () => { for (const d of TMPDIRS) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} } });
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; }


const MEASURE = `(() => {
  const dlg = document.querySelector('#settings-modal .settings-dialog');
  const r0 = dlg.getBoundingClientRect();
  const reset = document.getElementById('btn-settings-reset');
  reset.scrollIntoView({ block: 'center' });
  const r = reset.getBoundingClientRect();
  const hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
  const close = document.getElementById('btn-close-settings').getBoundingClientRect();
  return { winH: innerHeight, dlgBottom: Math.round(r0.bottom), resetIn: r.top >= 0 && r.bottom <= innerHeight,
           resetHit: hit === reset || reset.contains(hit), closeIn: close.top >= 0 && close.bottom <= innerHeight };
})()`;

async function run(src, tag) {
  const res = [];
  for (const [W, H] of WIDTHS) {
    const doc = mkTmp('t1392-doc-'), repo = mkTmp('t1392-repo-');
    copyFileSync(src, join(doc, 'designer.html'));
    const port = await freePort();
    const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: 'ignore' });
    const udd = makeProfileDir('t1392-udd-');
    const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', `--window-size=${W},${H}`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
    const BASE = `http://127.0.0.1:${port}`;
    let cl;
    try {
      for (let i = 0; i < 100; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
      cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
      await cmd('Page.enable'); await cmd('Runtime.enable');
      await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
      await cmd('Page.navigate', { url: `${BASE}/designer.html` });
      for (let t0 = Date.now(); Date.now() - t0 < 30000; await sleep(150)) if (await ev(cmd, `typeof openSettings==='function'&&_appReady===true`).catch(() => false)) break;
      // the field-profile answer comes ~1 s after ready; wait for it so the dialog is its normal height (T-1391)
      for (let t0 = Date.now(); Date.now() - t0 < 10000; await sleep(150)) if (await ev(cmd, `_fieldProfileStatus !== 'standalone'`).catch(() => false)) break;
      await ev(cmd, `(openSettings(), true)`); await sleep(400);
      if (shotDir && tag === 'live') { mkdirSync(shotDir, { recursive: true }); const s = await cmd('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(shotDir, `settings-top-${W}.png`), Buffer.from(s.data, 'base64')); }
      const m = await ev(cmd, MEASURE); await sleep(200);
      if (shotDir && tag === 'live') { const s = await cmd('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(shotDir, `settings-bottom-${W}.png`), Buffer.from(s.data, 'base64')); }
      res.push({ W, m });
    } catch (e) { res.push({ W, err: String(e && e.message || e).slice(0, 300) }); }
    finally { try { cl && cl.close(); } catch (_) {} try { br.kill('SIGKILL'); } catch (_) {} try { py.kill('SIGKILL'); } catch (_) {} }
  }
  return res;
}
function judge(res) {
  const legs = []; const leg = (ok, name, what) => legs.push({ ok, name, what });
  for (const { W, m, err } of res) {
    if (err || !m) { leg(false, `S0 @${W}`, 'setup: ' + (err || 'no measurement')); continue; }
    leg(m.dlgBottom <= m.winH, `S1 @${W}`, `the dialog ends at ${m.dlgBottom}px, inside the ${m.winH}px window`);
    leg(m.resetIn && m.resetHit, `S2 @${W}`, `"Reset to defaults" scrolled into view: ${m.resetIn}, a click lands on it: ${m.resetHit}`);
    leg(m.closeIn, `S3 @${W}`, `Close still in view after scrolling: ${m.closeIn}`);
  }
  return legs;
}
const report = legs => { for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'}  ${l.name.padEnd(10)} ${l.what}`); return legs.every(l => l.ok); };
async function main() {
  const live = judge(await run(SRC, 'live')); const ok = report(live);
  if (!selfTest) { console.log(ok ? `\nPASS — ${live.length} legs` : `\nFAIL — ${live.filter(l => !l.ok).length} leg(s)`); process.exit(ok ? 0 : 1); }
  const html = readFileSync(SRC, 'utf8');
  const A = '    max-height: calc(100vh - 110px);', B = '  .settings-body { padding: 14px 18px 18px; overflow-y: auto; min-height: 0; }';
  if (!html.includes(A) || !html.includes(B)) { console.log('SETUP BROKEN: poison anchor not found'); process.exit(2); }
  const p = join(mkTmp('t1392-poison-'), 'designer.html'); writeFileSync(p, html.replace(A, '').replace(B, '  .settings-body { padding: 14px 18px 18px; }'));
  const pl = judge(await run(p, 'poison'));
  const caught = pl.some(l => !l.ok && /^S1 /.test(l.name)) && pl.some(l => !l.ok && /^S2 /.test(l.name));
  console.log(`poison (the T-1392 rules removed): ${caught ? 'caught' : 'NOT caught'} — ${pl.filter(l => !l.ok).map(l => l.name.trim()).join(', ')}`);
  console.log(ok && caught ? `\nPASS — ${live.length} legs, and the poison arm caught` : `\nFAIL — live ${ok ? 'green' : 'red'}, poison ${caught ? 'caught' : 'not caught'}`);
  process.exit(ok && caught ? 0 : 1);
}
main().catch(e => { console.log('SETUP BROKEN: ' + (e && e.stack || e)); process.exit(2); });
