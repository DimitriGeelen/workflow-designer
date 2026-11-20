// T-1446 visual evidence: the Export menu with the three PDF entries (open) at 1024 / 1440 / 1920, and every page of
// the three PDFs of two maps rendered to PNG (pdftoppm, 50 dpi) under pdf/. A shot generator, not a guard.
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn, execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const { makeProfileDir } = await import(join(ROOT, 'tools/_cdp-profile.mjs'));
const { pageWsUrl } = await import(join(ROOT, 'tools/_cdp-attach.mjs'));
const { cdp } = await import(join(ROOT, 'tools/_cdp-client.mjs'));
const OUT = process.argv[2] || dirname(fileURLToPath(import.meta.url));
const EDITOR = process.env.T1446_EDITOR || join(ROOT, 'src/aef-workflow-designer.html');
mkdirSync(join(OUT, 'pdf'), { recursive: true });
const sleep = ms => new Promise(r => setTimeout(r, ms));
const MAPS = ['arc-lifecycle.bpmn', 'cross-host-dispatch.bpmn'];
const doc = mkdtempSync(join(tmpdir(), 't1446s-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
for (const m of MAPS) copyFileSync(join(ROOT, 'examples/aef-processes/rendered', m), join(doc, 'rendered', m));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1446s-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1920,1080', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl; const report = [];
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 120000 }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const open = async (W, MAP) => {
    await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 820, deviceScaleFactor: 1, mobile: false });
    // fresh storage per shot, cleared AFTER the previous page is gone (its unload writes the autosave that would
    // come back as "Restored your unsaved work")
    await cmd('Page.navigate', { url: 'about:blank' }); await sleep(300);
    await cmd('Storage.clearDataForOrigin', { origin: `http://127.0.0.1:${port}`, storageTypes: 'all' });
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP}` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
    await sleep(500);
  };
  await cmd('Page.enable');
  for (const W of [1024, 1440, 1920]) {
    await open(W, MAPS[0]);
    const m = await ev(`(function(){ ioMenuOpen('export'); const items = [...document.querySelectorAll('#menu-export .tb-menu-item')].map(b => { const r = b.getBoundingClientRect();
        return { id: b.dataset.format, inWindow: r.left >= 0 && r.right <= innerWidth && r.bottom <= innerHeight,
                 onTop: document.elementFromPoint((r.left + r.right) / 2, (r.top + r.bottom) / 2)?.closest('.tb-menu-item') === b }; });
      return { items: items.length, allInWindow: items.every(i => i.inWindow), allOnTop: items.every(i => i.onTop) }; })()`);
    await sleep(200);
    writeFileSync(join(OUT, `${W}-export-open.png`), Buffer.from((await cmd('Page.captureScreenshot', { format: 'png' })).data, 'base64'));
    report.push({ width: W, ...m });
  }
  for (const MAP of MAPS) {
    const tag = MAP.replace('.bpmn', '');
    await open(1440, MAP);
    for (const mode of ['a4', 'a3', 'pages']) {
      await ev(`window.print = () => {}; printMapSheet('${mode}'); 1`);
      const pdf = Buffer.from((await cmd('Page.printToPDF', { printBackground: true, preferCSSPageSize: true })).data, 'base64');
      await ev(`window.dispatchEvent(new Event('afterprint')); 1`);
      const p = join(OUT, 'pdf', `${tag}-${mode}.pdf`);
      writeFileSync(p, pdf);
      execFileSync('pdftoppm', ['-r', '50', '-png', p, join(OUT, 'pdf', `${tag}-${mode}`)]);
      rmSync(p);
      report.push({ map: tag, mode, pages: readdirSync(join(OUT, 'pdf')).filter(f => f.startsWith(`${tag}-${mode}-`)).length });
    }
  }
  writeFileSync(join(OUT, 'measure.json'), JSON.stringify(report, null, 1));
  console.log(JSON.stringify(report));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL'); try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  process.exit(process.exitCode ?? 0);
}
