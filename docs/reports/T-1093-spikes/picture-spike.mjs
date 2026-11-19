// T-1093 feasibility spike, pictures and print (inception evidence, NOT product code).
//
// Questions (IW-2/IW-3): can the designer produce, with nothing but the browser,
//   - an SVG of the map that is SELF-CONTAINED (Sprind's requirement: no webfont or remote reference),
//   - a PNG at 1x/2x/4x from that SVG,
//   - a PDF through the browser's own print path (Chrome's "Save as PDF" is Page.printToPDF)?
// and how big is each? Runs the real designer headless on one corpus map. Writes into argv[2].
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, copyFileSync, existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import net from 'node:net';
import { makeProfileDir } from '../../../tools/_cdp-profile.mjs';
import { pageWsUrl } from '../../../tools/_cdp-attach.mjs';
import { cdp } from '../../../tools/_cdp-client.mjs';

const OUT = process.argv[2] || '/tmp/t1093-pictures';
mkdirSync(OUT, { recursive: true });
const MAP = 'arc-lifecycle.bpmn';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const doc = mkdtempSync(join(tmpdir(), 't1093-doc-'));
copyFileSync('src/aef-workflow-designer.html', join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
copyFileSync(join('examples/aef-processes/rendered', MAP), join(doc, 'rendered', MAP));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1093-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl;
try {
  let dp; for (let i = 0; i < 100 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; };
  await cmd('Page.enable');
  await sleep(600);
  await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP}` });
  for (let i = 0; i < 100; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
  await ev(`(setZoom(null), 1)`); await sleep(300);

  // 1. SVG as the page has it: clone #canvas, inline the computed font/colour of every text, fix the viewBox.
  const svgRaw = await ev(`new XMLSerializer().serializeToString(document.getElementById('canvas'))`);
  const svgSelf = await ev(`(function(){
    const src = document.getElementById('canvas'), c = src.cloneNode(true);
    // First attempt inlined text style only: every shape came out solid black (the designer colours shapes
    // through its stylesheet, which a standalone SVG does not carry). So: every element's computed paint.
    const PROPS = ['fill', 'fill-opacity', 'stroke', 'stroke-width', 'stroke-opacity', 'stroke-dasharray', 'opacity',
                   'font-family', 'font-size', 'font-weight', 'font-style', 'text-anchor', 'dominant-baseline', 'visibility', 'display'];
    const srcAll = [src, ...src.querySelectorAll('*')], cAll = [c, ...c.querySelectorAll('*')];
    srcAll.forEach((el, i) => { const cs = getComputedStyle(el);
      cAll[i].setAttribute('style', PROPS.map(p => p + ':' + cs.getPropertyValue(p)).join(';')); });
    // Editor chrome is not part of the map: anything not rendered, and the "add lane" affordance.
    cAll.forEach((el, i) => { const cs = getComputedStyle(srcAll[i]);
      if (cs.display === 'none' || cs.visibility === 'hidden') el.remove(); });
    c.querySelectorAll('[class*="add-lane"], [class*="handle"], [class*="ghost"]').forEach(e => e.remove());
    c.setAttribute('width', src.viewBox.baseVal.width); c.setAttribute('height', src.viewBox.baseVal.height);
    c.removeAttribute('class');
    return new XMLSerializer().serializeToString(c); })()`);
  const fontsUsed = await ev(`[...new Set([...document.querySelectorAll('#canvas text')].map(t => getComputedStyle(t).fontFamily))]`);
  const remote = s => (s.match(/(url\(\s*['"]?(https?:)?\/\/|href="https?:|@import)/g) || []).length;
  writeFileSync(join(OUT, 'map.svg'), svgSelf);

  // 2. PNG from that SVG at 1x/2x/4x, through an <img> and a canvas (no library).
  const png = {};
  for (const scale of [1, 2, 4]) {
    const b64 = await ev(`new Promise((res, rej) => { const svg = ${JSON.stringify(svgSelf)};
      const img = new Image(); img.onload = () => { const c = document.createElement('canvas');
        c.width = img.width * ${scale}; c.height = img.height * ${scale}; const g = c.getContext('2d');
        g.fillStyle = '#fff'; g.fillRect(0, 0, c.width, c.height); g.drawImage(img, 0, 0, c.width, c.height);
        res(c.toDataURL('image/png').split(',')[1]); }; img.onerror = () => rej('svg did not load as an image');
      img.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg); })`);
    const buf = Buffer.from(b64, 'base64'); writeFileSync(join(OUT, `map@${scale}x.png`), buf);
    png[`${scale}x`] = { bytes: buf.length, w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) };
  }

  // 3. PDF through the browser's print path (what "Save as PDF" does), with today's page as is.
  const pdf = await cmd('Page.printToPDF', { landscape: true, printBackground: true, preferCSSPageSize: false });
  const pdfBuf = Buffer.from(pdf.data, 'base64'); writeFileSync(join(OUT, 'page.pdf'), pdfBuf);

  const res = { map: MAP, svg: { rawBytes: svgRaw.length, selfContainedBytes: svgSelf.length, remoteRefs: remote(svgSelf), fontsUsed },
    png, pdf: { bytes: pdfBuf.length } };
  writeFileSync(join(OUT, 'result.json'), JSON.stringify(res, null, 1));
  console.log(JSON.stringify(res));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL');
  process.exit(process.exitCode ?? 0);
}
