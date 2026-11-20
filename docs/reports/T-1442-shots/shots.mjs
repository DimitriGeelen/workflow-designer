// T-1442 visual evidence: the Import and Export menus with Excel added (open), and the designer right after
// Import → Excel (map laid out by Clean, the notice naming what Excel does not carry), at 1024 / 1440 / 1920.
// Also writes the exported .xlsx of two maps under exported/. A shot generator, not a guard.
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
mkdirSync(join(OUT, 'exported'), { recursive: true });
const sleep = ms => new Promise(r => setTimeout(r, ms));
const MAPS = ['audit-process.bpmn', 'arc-lifecycle.bpmn'];
const doc = mkdtempSync(join(tmpdir(), 't1442s-'));
copyFileSync(join(ROOT, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
for (const m of MAPS) copyFileSync(join(ROOT, 'examples/aef-processes/rendered', m), join(doc, 'rendered', m));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1442s-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1920,1080', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl; const report = [];
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready; const { cmd } = cl;
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
  for (const MAP of MAPS) {   // the exported workbooks, for a person to open
    await open(1440, MAP);
    const b64 = await ev(`buildXlsx().then(u => { let s = ''; for (const x of u) s += String.fromCharCode(x); return btoa(s); })`);
    writeFileSync(join(OUT, 'exported', MAP.replace('.bpmn', '.xlsx')), Buffer.from(b64, 'base64'));
  }
  for (const W of [1024, 1440, 1920]) {
    for (const dir of ['import', 'export']) {
      await open(W, MAPS[0]);
      const m = await ev(`(function(){ ioMenuOpen('${dir}'); const list = document.getElementById('menu-${dir}');
        const items = [...list.querySelectorAll('.tb-menu-item')].map(b => { const r = b.getBoundingClientRect();
          return { id: b.dataset.format, text: b.textContent, inWindow: r.left >= 0 && r.right <= innerWidth && r.bottom <= innerHeight,
                   onTop: document.elementFromPoint((r.left + r.right) / 2, (r.top + r.bottom) / 2)?.closest('.tb-menu-item') === b }; });
        return { items: items.length, allInWindow: items.every(i => i.inWindow), allOnTop: items.every(i => i.onTop), ids: items.map(i => i.id) }; })()`);
      await sleep(200);
      writeFileSync(join(OUT, `${W}-${dir}-open.png`), Buffer.from((await cmd('Page.captureScreenshot', { format: 'png' })).data, 'base64'));
      report.push({ width: W, shot: `${dir}-open`, ...m });
    }
    await open(W, MAPS[0]);
    await ev(`buildXlsx().then(u => importXlsxBytes(u, 'audit-process.xlsx')).then(() => 1)`);
    await sleep(900);
    const m = await ev(`(function(){ const el = document.getElementById('lane-fix-notice'); const r = el && el.getBoundingClientRect();
      return { notice: el && getComputedStyle(el).display !== 'none' ? (document.getElementById('lane-fix-msg') || {}).textContent : null,
               inWindow: r ? r.right <= innerWidth && r.bottom <= innerHeight : null }; })()`);
    writeFileSync(join(OUT, `${W}-after-xlsx-import.png`), Buffer.from((await cmd('Page.captureScreenshot', { format: 'png' })).data, 'base64'));
    report.push({ width: W, shot: 'after-xlsx-import', ...m });
  }
  writeFileSync(join(OUT, 'measure.json'), JSON.stringify(report, null, 1));
  console.log(JSON.stringify(report.map(r => [r.width, r.shot, r.items ?? !!r.notice, r.allInWindow ?? r.inWindow, r.allOnTop ?? ''])));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL'); try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  process.exit(process.exitCode ?? 0);
}
