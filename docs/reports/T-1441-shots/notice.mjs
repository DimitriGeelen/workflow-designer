// T-1441 visual evidence: the designer right after Import → Mermaid / CSV (the map laid out by Clean, and the import
// notice naming what the format does not carry), at 1024 / 1440 / 1920. A shot generator, not a guard.
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
const OUT = process.argv[2] || '/tmp/t1441-shots';
mkdirSync(OUT, { recursive: true });
const sleep = ms => new Promise(r => setTimeout(r, ms));
const MAP = 'audit-process.bpmn';
const doc = mkdtempSync(join(tmpdir(), 't1441s-'));
copyFileSync(join(ROOT, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered')); copyFileSync(join(ROOT, 'examples/aef-processes/rendered', MAP), join(doc, 'rendered', MAP));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1441s-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1920,1080', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl; const report = [];
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  await cmd('Page.enable');
  for (const W of [1024, 1440, 1920]) {
    for (const kind of ['mermaid', 'csv']) {
      await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 820, deviceScaleFactor: 1, mobile: false });
      await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP}` });
      for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
      await sleep(400);
      await ev(`(function(){ const t = ${kind === 'mermaid' ? 'buildMermaid()' : 'buildCsv()'}; importBridgeText('${kind}', t, 'audit-process.${kind === 'mermaid' ? 'mmd' : 'csv'}'); return 1; })()`);
      await sleep(900);
      const m = await ev(`(function(){ const el = document.getElementById('lane-fix-notice'); const r = el && el.getBoundingClientRect();
        return { notice: el && getComputedStyle(el).display !== 'none' ? (document.getElementById('lane-fix-msg') || {}).textContent : null,
                 rect: r ? [Math.round(r.left), Math.round(r.top), Math.round(r.right), Math.round(r.bottom)] : null, inWindow: r ? r.right <= innerWidth && r.bottom <= innerHeight : null }; })()`);
      const shot = await cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(OUT, `${W}-after-${kind}-import.png`), Buffer.from(shot.data, 'base64'));
      report.push({ width: W, kind, ...m });
    }
  }
  writeFileSync(join(OUT, 'notice.json'), JSON.stringify(report, null, 1));
  console.log(JSON.stringify(report.map(r => [r.width, r.kind, !!r.notice, r.inWindow])));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL'); try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  process.exit(process.exitCode ?? 0);
}
