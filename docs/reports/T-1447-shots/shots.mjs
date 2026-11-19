// T-1447 screenshots: Greenfield's workshop map in the designer at 1024/1440/1920 (opening view, after import), a close-up of
// the notes, and the paper export (PNG 2x). Run: node docs/reports/T-1447-shots/shots.mjs
import { readFileSync, writeFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, mkdirSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir } from '../../../tools/_cdp-profile.mjs';
import { pageWsUrl } from '../../../tools/_cdp-attach.mjs';
import { cdp } from '../../../tools/_cdp-client.mjs';

const HERE = dirname(fileURLToPath(import.meta.url)), ROOT = resolve(HERE, '../../..');
const FIXTURE = join(ROOT, 'tests', 'fixtures', 'greenfield', 'nooteboom-offerte-tot-order-with-notes.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));
const doc = mkdtempSync(join(tmpdir(), 't1447-shots-'));
copyFileSync(join(ROOT, 'src', 'aef-workflow-designer.html'), join(doc, 'designer.html'));
mkdirSync(join(doc, 'm')); copyFileSync(FIXTURE, join(doc, 'm', 'gf.bpmn'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1447s-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1920,1080', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl;
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const shot = async (name, clip) => { const r = await cmd('Page.captureScreenshot', { format: 'png', ...(clip ? { clip: { ...clip, scale: 1 } } : {}) }); writeFileSync(join(HERE, name), Buffer.from(r.data, 'base64')); console.log('wrote', name); };
  await cmd('Page.enable'); await cmd('Runtime.enable');
  for (const [w, h] of [[1024, 768], [1440, 900], [1920, 1080]]) {
    await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
    // a fresh start per width: no autosaved work from the previous width, so no "Restored your unsaved work" notice
    await cmd('Storage.clearDataForOrigin', { origin: `http://127.0.0.1:${port}`, storageTypes: 'all' });
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
    await ev(`(async()=>{ const t = await (await fetch('m/gf.bpmn')).text(); await adoptImportedXml(t, { userImport: true }); await new Promise(r=>setTimeout(r,500)); })()`);
    await shot(`${w}-greenfield.png`);
    if (w !== 1920) {
      // T-1447 review: readable close-ups at this width — 100% zoom, both side panels hidden, the whole map in tiles
      // (dismiss the import notices first, so they cover nothing)
      await ev(`(function(){ for (const b of [...document.querySelectorAll('button')].filter(b => /^\\s*[×✕]\\s*$/.test(b.textContent) && b.offsetParent && b.getBoundingClientRect().top < 260)) { try { b.click(); } catch (_) {} }
        document.getElementById('btn-toggle-palette').click(); document.getElementById('btn-toggle-props').click(); })()`);
      await sleep(300);
      await ev(`setZoom(1)`); await sleep(300);
      const ext = await ev(`(function(){ const b = svg.getBBox(); const w = canvasWrap; return { sw: w.scrollWidth, sh: w.scrollHeight, cw: w.clientWidth, ch: w.clientHeight }; })()`);
      let k = 0;
      for (let y = 0; y < ext.sh; y += ext.ch - 120) for (let x = 0; x < ext.sw; x += ext.cw - 200) {
        await ev(`(function(){ canvasWrap.scrollLeft = ${x}; canvasWrap.scrollTop = ${y}; })()`); await sleep(250);
        const r = await ev(`(function(){ const b = canvasWrap.getBoundingClientRect(); return { x: b.left, y: b.top, width: canvasWrap.clientWidth, height: canvasWrap.clientHeight }; })()`);
        await shot(`${w}-notes-${String(++k).padStart(2, '0')}.png`, r);
      }
    }
    if (w === 1920) {
      // a close-up: zoom so the notes read at full size, centred on the first note
      await ev(`(function(){ if (typeof setZoom === 'function') setZoom(1); else if (typeof applyCanvasZoom === 'function') { canvasZoom = 1; applyCanvasZoom(); } })()`);
      await sleep(300);
      const r = await ev(`(function(){ const g = document.querySelector('#g-notes [data-note]'); g.scrollIntoView({block:'center', inline:'center'}); const b = g.getBoundingClientRect(); return {x: b.left, y: b.top}; })()`);
      await sleep(300);
      const b = await ev(`(function(){ const b = document.querySelector('#g-notes [data-note]').getBoundingClientRect(); return {x: b.left, y: b.top}; })()`);
      await shot('1920-closeup.png', { x: Math.max(0, b.x - 300), y: Math.max(0, b.y - 250), width: 1100, height: 650 });
      const png = await ev(`(async()=>{ const blob = await renderPng(2); const buf = new Uint8Array(await blob.arrayBuffer()); let s=''; for (let i=0;i<buf.length;i+=32768) s+=String.fromCharCode.apply(null, buf.subarray(i,i+32768)); return btoa(s); })()`);
      writeFileSync(join(HERE, 'greenfield-export.png'), Buffer.from(png, 'base64')); console.log('wrote greenfield-export.png');
    }
  }
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL');
  for (const d of [doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
}
