// T-1440 — Export → SVG, PNG 1x/2x/4x and PDF, driven in the real designer (headless Chromium, CDP), on two maps.
//
// Per map:
//   S1 Export → SVG downloads a standalone SVG: parses as XML, has the map's step names, ZERO remote references,
//      none of the editor chrome (resize grips, "+ Add another lane", hit targets)
//   S2 paper palette (operator ruling a): white background rect, and no near-black fill left on any shape or label
//      backing (the spike's "black bars"), and every text fill dark enough to read on white
//   P1 Export → PNG 1x/2x/4x download PNGs at exactly width*scale x height*scale of the SVG
//   D1 Export → PDF: the print sheet holds the paper picture; printed to PDF (what "Save as PDF" does), the PDF text has
//      the map's step names and NONE of the editor's (toolbar, palette, panel)
//   U1 the screen is unchanged afterwards (no export-paper / printing-map class left, selection restored)
// Teeth: run with T1440_EDITOR=<the T-1439 designer> and it fails (no such menu items).
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn, execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1440_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const RENDERED = join(ROOT, 'examples', 'aef-processes', 'rendered');
const MAPS = ['arc-lifecycle.bpmn', 'audit-process.bpmn'];
const OUT = process.argv[2] || null;          // optional: keep the exported files here (evidence)
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1440-doc-')), dl = mkdtempSync(join(tmpdir(), 't1440-dl-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
for (const m of MAPS) copyFileSync(join(RENDERED, m), join(doc, 'rendered', m));
if (OUT) mkdirSync(OUT, { recursive: true });
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1440-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
const events = [];
let cl;
const lum = c => { c = String(c).trim(); let r, g, b; const h = /^#([0-9a-f]{6})$/i.exec(c); if (h) { const n = parseInt(h[1], 16); r = n >> 16; g = (n >> 8) & 255; b = n & 255; } else { const m = c.match(/[\d.]+/g); if (!m) return 1; [r, g, b] = m.map(Number); } return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255; };
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000, onEvent: m => events.push(m) }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const waitFor = async (pred, ms = 15000) => { const t0 = Date.now(); while (Date.now() - t0 < ms) { const e = events.find(pred); if (e) return e; await sleep(50); } return null; };
  await cmd('Page.enable'); await cmd('Runtime.enable');
  await cmd('Browser.setDownloadBehavior', { behavior: 'allowAndName', downloadPath: dl, eventsEnabled: true });
  const viaMenu = async fmt => {
    const n0 = events.length;
    await ev(`document.getElementById('btn-export').click(); document.querySelector('#menu-export .tb-menu-item[data-format="${fmt}"]').click(); 1`);
    const done = await waitFor(e => events.indexOf(e) >= n0 && e.method === 'Browser.downloadProgress' && e.params.state === 'completed');
    const begin = done && events.find(e => e.method === 'Browser.downloadWillBegin' && e.params.guid === done.params.guid);
    return done ? { buf: readFileSync(join(dl, done.params.guid)), name: begin ? begin.params.suggestedFilename : '' } : null;
  };
  for (const MAP of MAPS) {
    const tag = MAP.replace('.bpmn', '');
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP}` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
    await sleep(400);
    const names = await ev(`state.nodes.map(n => n.name || n.label || '').filter(s => s && s.length > 3).slice(0, 40)`);
    // select a node first, so U1 can prove the selection comes back
    await ev(`(selection = { kind: 'node', id: state.nodes[1].id }, renderAll(), 1)`);

    // S1 / S2 — the SVG as downloaded
    const s = await viaMenu('svg');
    const svg = s ? s.buf.toString('utf8') : '';
    if (OUT && svg) writeFileSync(join(OUT, `${tag}.svg`), svg);
    const remote = (svg.match(/url\(\s*['"]?(https?:)?\/\/|(xlink:)?href="https?:|@import/g) || []).length;
    const chrome = /Add another lane|lane-resize|pool-resize|edge-hit|pool-add-lane/.test(svg);
    const found = names.filter(n => svg.includes(n.replace(/&/g, '&amp;').replace(/</g, '&lt;').split('\n')[0].slice(0, 12))).length;
    leg(!!s && /\.svg$/.test(s.name) && svg.startsWith('<?xml') && remote === 0 && !chrome && found >= Math.min(names.length, 5),
        `S1 [${tag}] Export → SVG: standalone, step names in, 0 remote refs, no editor chrome`,
        `${s && s.name} ${svg.length} B, remote ${remote}, chrome ${chrome}, names ${found}/${names.length}`);
    // S2: analyse the downloaded SVG in the page (DOMParser), the same bytes the user gets
    const s2 = await ev(`(function(){ const d = new DOMParser().parseFromString(${JSON.stringify(svg)}, 'image/svg+xml');
      const root = d.documentElement, bg = root.querySelector('rect');
      const fill = el => (el.getAttribute('style') || '').match(/(?:^|;)fill:([^;]+)/);
      const dark = [], text = [];
      // only shapes that enclose an area can paint a fill: an open path (the script icon's lines, the gateway's x) has
      // the default black fill and paints nothing, on screen as in the file
      for (const el of root.querySelectorAll('rect, path, circle, polygon, ellipse')) {
        if (el.tagName === 'path' && !/[zZ]/.test(el.getAttribute('d') || '')) continue;
        const f = fill(el); if (f && /rgb|#/.test(f[1])) dark.push(f[1].trim()); }
      for (const el of root.querySelectorAll('text')) { const f = fill(el); if (f && /rgb/.test(f[1])) text.push(f[1]); }
      return { parseError: !!d.querySelector('parsererror'), bg: bg && bg.getAttribute('fill'), fills: dark, texts: text }; })()`);
    const nearBlack = s2.fills.filter(f => lum(f) < 0.12).length;
    const paleText = s2.texts.filter(f => lum(f) > 0.6).length;
    leg(!s2.parseError && /^#fff(fff)?$/i.test(s2.bg || '') && nearBlack === 0 && paleText === 0,
        `S2 [${tag}] paper palette: white background, no near-black shape fill, no pale text`,
        `bg ${s2.bg}, near-black fills ${nearBlack}/${s2.fills.length}, pale texts ${paleText}/${s2.texts.length}`);

    // P1 — PNG sizes
    const dims = await ev(`(function(){ const r = buildExportSvg(); return [r.width, r.height]; })()`);
    for (const sc of [1, 2, 4]) {
      const p = await viaMenu('png' + sc);
      const ok = !!p && p.buf.slice(1, 4).toString() === 'PNG';
      const w = ok ? p.buf.readUInt32BE(16) : 0, h = ok ? p.buf.readUInt32BE(20) : 0;
      if (OUT && ok && sc === 2) writeFileSync(join(OUT, `${tag}@2x.png`), p.buf);
      leg(ok && w === Math.round(dims[0] * sc) && h === Math.round(dims[1] * sc) && new RegExp(`@${sc}x\\.png$`).test(p.name),
          `P1 [${tag}] Export → PNG ${sc}x is ${dims[0] * sc}x${dims[1] * sc}`, `${p && p.name} ${w}x${h}`);
    }

    // D1 — PDF through the print path
    await ev(`window.__printed = 0; window.print = () => { window.__printed++; }; 1`);
    await ev(`document.getElementById('btn-export').click(); document.querySelector('#menu-export .tb-menu-item[data-format="pdf"]').click(); 1`);
    const sheet = await ev(`({ printed: window.__printed, cls: document.body.classList.contains('printing-map'), svg: !!document.querySelector('#print-sheet svg') })`);
    const pdf = await cmd('Page.printToPDF', { printBackground: true, preferCSSPageSize: true });
    const pdfBuf = Buffer.from(pdf.data, 'base64');
    const pdfPath = join(dl, `${tag}.pdf`); writeFileSync(pdfPath, pdfBuf);
    if (OUT) writeFileSync(join(OUT, `${tag}.pdf`), pdfBuf);
    let txt = ''; try { txt = execFileSync('pdftotext', [pdfPath, '-'], { encoding: 'utf8' }); } catch (_) {}
    const flat = txt.replace(/\s+/g, ' ');
    const inPdf = names.filter(n => flat.includes(n.split(/\s+/).slice(0, 2).join(' '))).length;
    const editorWords = ['Clean layout', 'View XML', 'Select / Move', 'Add Lane', 'Settings'].filter(w => flat.includes(w));
    await ev(`window.dispatchEvent(new Event('afterprint')); 1`);
    leg(sheet.printed === 1 && sheet.cls && sheet.svg && inPdf >= Math.min(names.length, 5) && editorWords.length === 0,
        `D1 [${tag}] Export → PDF prints the map alone`, `printed ${sheet.printed}, step names in PDF ${inPdf}/${names.length}, editor words ${JSON.stringify(editorWords)}, ${pdfBuf.length} B`);

    // U1 — screen unchanged
    const u = await ev(`({ paper: document.body.classList.contains('export-paper'), printing: document.body.classList.contains('printing-map'),
      sel: selection && selection.id, want: state.nodes[1].id, bg: getComputedStyle(document.body).getPropertyValue('--bg').trim() })`);
    leg(!u.paper && !u.printing && u.sel === u.want && u.bg === '#0d0f13', `U1 [${tag}] the screen is unchanged afterwards (dark, selection kept)`, JSON.stringify(u));
  }
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL');
  for (const d of [doc, dl, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
