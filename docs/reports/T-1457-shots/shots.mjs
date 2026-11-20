// T-1457 visual evidence: Productieorder (lane NAV) on the Greenfield fixture at 1024 / 1440 / 1920, BEFORE
// (T1456_BEFORE=<designer>, default the designer before T-1456) and AFTER (src). A shot generator, not a guard.
//   node docs/reports/T-1456-shots/shots.mjs [outdir]   (T1456_BEFORE: the designer before the fix; default build/t1456-before.html = git show 44d7d11a0:src/aef-workflow-designer.html)
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const { makeProfileDir } = await import(join(ROOT, 'tools/_cdp-profile.mjs'));
const { pageWsUrl } = await import(join(ROOT, 'tools/_cdp-attach.mjs'));
const { cdp } = await import(join(ROOT, 'tools/_cdp-client.mjs'));
const OUT = process.argv[2] || dirname(fileURLToPath(import.meta.url));
const EDITORS = { before: process.env.T1456_BEFORE || join(ROOT, 'build/t1456-before.html'), after: process.env.T1456_AFTER || join(ROOT, 'src/aef-workflow-designer.html') };
mkdirSync(OUT, { recursive: true });
const sleep = ms => new Promise(r => setTimeout(r, ms));
const doc = mkdtempSync(join(tmpdir(), 't1456s-'));
for (const [k, f] of Object.entries(EDITORS)) copyFileSync(f, join(doc, `${k}.html`));
mkdirSync(join(doc, 'r'));
copyFileSync(join(ROOT, 'tests/fixtures/greenfield/nooteboom-offerte-tot-order-with-notes.bpmn'), join(doc, 'r', 'greenfield.bpmn'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1456s-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1920,1080', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl;
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  await cmd('Page.enable');
  // the canvas region [x0, y0, x1, y1] (map coordinates) shown in a clip of the page, at 100% zoom
  const shot = async (ed, map, W, region, name) => {
    await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: 'about:blank' }); await sleep(200);
    await cmd('Storage.clearDataForOrigin', { origin: `http://127.0.0.1:${port}`, storageTypes: 'all' });
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/${ed}.html?load=r/${map}` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
    await sleep(500);
    const r = await ev(`(function(){ const c = document.getElementById('canvas'), m = c.getScreenCTM(); const p = (x, y) => { const q = c.createSVGPoint(); q.x = x; q.y = y; return q.matrixTransform(m); };
      const a = p(${region[0]}, ${region[1]}), b = p(${region[2]}, ${region[3]}); return [a.x, a.y, b.x, b.y]; })()`);
    // scroll the region into the window, then clip it
    await ev(`(function(){ const w = document.querySelector('.canvas-wrap') || document.scrollingElement; w.scrollLeft += ${Math.round(r[0])} - 260; w.scrollTop += ${Math.round(r[1])} - 140; return 1; })()`);
    await sleep(300);
    const r2 = await ev(`(function(){ const c = document.getElementById('canvas'), m = c.getScreenCTM(); const p = (x, y) => { const q = c.createSVGPoint(); q.x = x; q.y = y; return q.matrixTransform(m); };
      const a = p(${region[0]}, ${region[1]}), b = p(${region[2]}, ${region[3]}); return [a.x, a.y, b.x, b.y]; })()`);
    const clip = { x: Math.max(0, r2[0]), y: Math.max(0, r2[1]), width: Math.min(W, r2[2]) - Math.max(0, r2[0]), height: Math.min(900, r2[3]) - Math.max(0, r2[1]), scale: 1 };
    writeFileSync(join(OUT, name), Buffer.from((await cmd('Page.captureScreenshot', { format: 'png', clip })).data, 'base64'));
  };
  for (const ed of ['before', 'after'])
    for (const W of [1024, 1440, 1920]) await shot(ed, 'greenfield.bpmn', W, [2150, 120, 2560, 560], `productieorder-${W}-${ed}.png`);
  console.log('shots written to', OUT);
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL'); try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  process.exit(process.exitCode ?? 0);
}
