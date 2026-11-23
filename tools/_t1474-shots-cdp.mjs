// T-1474 / T-1469 review shots (not a leg): maps opened as a person opens them (adopt, opening zoom, lens all) at
// 1024/1440/1920, for one designer file.
//   node tools/_t1474-shots-cdp.mjs <designer.html> <outdir> <prefix> <map.bpmn> [<map.bpmn> ...]
// Writes <outdir>/<prefix>-<map>-<width>.png (the whole window).
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, basename } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const [EDITOR, OUT, PREFIX, ...MAPS] = process.argv.slice(2);
if (!EDITOR || !OUT || !PREFIX || !MAPS.length) { console.log('usage: <designer.html> <outdir> <prefix> <map.bpmn>...'); process.exit(2); }
mkdirSync(OUT, { recursive: true });
const sleep = ms => new Promise(r => setTimeout(r, ms));
const doc = mkdtempSync(join(tmpdir(), 't1474s-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1474s-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1920,1080', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let n = 0;
try {
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  const cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  for (const [W, H] of [[1024, 768], [1440, 900], [1920, 1080]]) {
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
    await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
    for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
    await ev('document.fonts.ready');
    for (const m of MAPS) {
      await ev(`(function(xml){ adoptImportedXml(xml, { userImport: true }); renderAll(); if (typeof openingZoom === 'function') openingZoom();
        if (typeof setLens === 'function') setLens('all'); })(${JSON.stringify(readFileSync(m, 'utf8'))})`);
      await sleep(400);
      const shot = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(OUT, `${PREFIX}-${basename(m, '.bpmn')}-${W}.png`), Buffer.from(shot.data, 'base64')); n++;
    }
  }
  cl.close();
} catch (e) { console.log('error: ' + (e && e.message || e)); }
finally { br.kill('SIGKILL'); py.kill('SIGKILL'); removeProfileDir(udd); rmSync(doc, { recursive: true, force: true }); }
console.log(`${n} shot(s) in ${OUT}`);
process.exit(n ? 0 : 1);
