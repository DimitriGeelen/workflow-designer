// T-1439 visual evidence: the toolbar with the Import and the Export menu open, at 1024 / 1440 / 1920.
// Writes <out>/<width>-<state>.png: state = closed | import-open | export-open. A shot generator, not a guard.
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
const OUT = process.argv[2] || '/tmp/t1439-shots';
mkdirSync(OUT, { recursive: true });
const sleep = ms => new Promise(r => setTimeout(r, ms));
const MAP = 'arc-lifecycle.bpmn';
const doc = mkdtempSync(join(tmpdir(), 't1439s-'));
copyFileSync(join(ROOT, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered')); copyFileSync(join(ROOT, 'examples/aef-processes/rendered', MAP), join(doc, 'rendered', MAP));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1439s-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1920,1080', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl; const report = [];
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  await cmd('Page.enable');
  for (const W of [1024, 1440, 1920]) {
    await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 800, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP}` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
    await sleep(500);
    for (const st of ['closed', 'import-open', 'export-open']) {
      await ev(`ioMenuClose('import', false); ioMenuClose('export', false); 1`);
      if (st !== 'closed') await ev(`ioMenuOpen('${st.split('-')[0]}'); 1`);
      await sleep(200);
      // what is checked, measured: each entry's rect inside the window, the open menu not covered by anything
      const m = await ev(`(function(){
        const r = id => { const b = document.getElementById(id).getBoundingClientRect(); return [Math.round(b.left), Math.round(b.top), Math.round(b.right), Math.round(b.bottom)]; };
        const out = { imp: r('btn-import'), exp: r('btn-export'), headerBottom: Math.round(document.querySelector('header').getBoundingClientRect().bottom) };
        const open = document.querySelector('.tb-menu-list:not([hidden])');
        if (open) { const b = open.getBoundingClientRect(); out.menu = [Math.round(b.left), Math.round(b.top), Math.round(b.right), Math.round(b.bottom)];
          const it = open.querySelector('.tb-menu-item').getBoundingClientRect();
          const hit = document.elementFromPoint(it.left + it.width / 2, it.top + it.height / 2);
          out.menuOnTop = open.contains(hit); out.inWindow = b.left >= 0 && b.right <= innerWidth; }
        return out; })()`);
      const clipH = Math.max(m.headerBottom, m.menu ? m.menu[3] : 0) + 24;
      const shot = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: W, height: clipH, scale: 1 } });
      writeFileSync(join(OUT, `${W}-${st}.png`), Buffer.from(shot.data, 'base64'));
      report.push({ width: W, state: st, ...m });
    }
  }
  writeFileSync(join(OUT, 'measure.json'), JSON.stringify(report, null, 1));
  console.log(JSON.stringify(report));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL'); try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  process.exit(process.exitCode ?? 0);
}
