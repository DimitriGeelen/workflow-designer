// T-1446 — Export → PDF on one A4 page, one A3 page, or A4 pages at a readable size, measured in the PDF itself.
//
// Per map (headless Chromium, CDP; the print is Page.printToPDF of the print sheet, as in _t1440):
//   M1 the Export menu has the three PDF entries (pdf, pdf-a3, pdf-pages)
//   A1 one page A4: 1 page of 842x595 pt; the map alone (step names in, editor words out)
//   B1 one page A3: 1 page of 1191x842 pt; step names larger than on the A4 page
//   P1 readable pages: every page A4 landscape, as many as the layout computed; step names at >= 8 pt
//   P2 every step name is on some page; no step box crosses an inner cut; each page heading names its part
//      ("page k of N") when there are several, and a map that fits at 8 pt on one page gives exactly one page
// Text size: pdftotext -bbox word heights, calibrated on the page heading (13 pt), so it is measured, not assumed.
// Teeth: T1446_EDITOR=<the 0.44.0 designer> fails (no such menu entries).
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
const EDITOR = process.env.T1446_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const RENDERED = join(ROOT, 'examples', 'aef-processes', 'rendered');
const MAPS = process.env.T1446_MAPS ? process.env.T1446_MAPS.split(',') : ['arc-lifecycle.bpmn', 'audit-process.bpmn', 'resume-status.bpmn'];
const OUT = process.argv[2] || null;
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1446-doc-')), dl = mkdtempSync(join(tmpdir(), 't1446-dl-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
for (const m of MAPS) copyFileSync(join(RENDERED, m), join(doc, 'rendered', m));
if (OUT) mkdirSync(OUT, { recursive: true });
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1446-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl;
const EDITOR_WORDS = ['Clean layout', 'View XML', 'Select / Move', 'Add Lane', 'Settings'];
// pdftotext -bbox: per page its size and words with their boxes
function pdfWords(path) {
  const html = execFileSync('pdftotext', ['-bbox', path, '-'], { encoding: 'utf8' });
  const pages = [];
  for (const pm of html.matchAll(/<page width="([\d.]+)" height="([\d.]+)">([\s\S]*?)<\/page>/g)) {
    const words = [...pm[3].matchAll(/<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)<\/word>/g)]
      .map(w => ({ h: +w[4] - +w[2], t: w[5].replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"') }));
    pages.push({ w: Math.round(+pm[1]), h: Math.round(+pm[2]), words, text: words.map(w => w.t).join(' ') });
  }
  return pages;
}
const median = a => { const s = a.slice().sort((x, y) => x - y); return s.length ? s[Math.floor(s.length / 2)] : 0; };
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 120000 }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  await cmd('Page.enable'); await cmd('Runtime.enable');
  let sawOnePage = false, sawSeveral = false;
  // '@small': no corpus map fits on one readable page (pool and lanes alone are wider), so a 3-step map made through
  // Import -> CSV stands for the small case
  for (const MAP of [...MAPS, '@small']) {
    const tag = MAP === '@small' ? 'small-3-steps' : MAP.replace('.bpmn', '');
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP === '@small' ? MAPS[0] : MAP}` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
    await sleep(400);
    if (MAP === '@small') {
      await ev(`importBridgeText('csv', 'id,name,type,lane,next\\nsml_start,Order received,startEvent,Sales,sml_check\\nsml_check,Check stock,task,Sales,sml_end\\nsml_end,Order confirmed,endEvent,Sales,\\n', 'small.csv'); 1`);
      await sleep(900);
    }
    const meta = await ev(`({ names: state.nodes.map(n => n.name || '').filter(Boolean), title: state.workflowMeta.title || state.workflowMeta.id })`);
    // a step name's words that are not in the title, at least 4 letters: the words whose height we read
    const titleWords = new Set(meta.title.toLowerCase().split(/\W+/));
    const nameWords = new Set(meta.names.flatMap(n => n.split(/\s+/)).filter(w => /^[A-Za-z]{4,}$/.test(w) && !titleWords.has(w.toLowerCase())));
    const has = await ev(`document.getElementById('btn-export').click(); [...document.querySelectorAll('#menu-export .tb-menu-item')].map(b => b.dataset.format)`);
    await ev(`document.getElementById('btn-export').click(); 1`);
    leg(['pdf', 'pdf-a3', 'pdf-pages'].every(f => has.includes(f)), `M1 [${tag}] Export has PDF one page A4, one page A3 and readable A4 pages`, JSON.stringify(has.filter(f => /pdf/.test(f))));
    const run = async fmt => {
      if (!has.includes(fmt)) return null;
      await ev(`window.__printed = 0; window.print = () => { window.__printed++; }; 1`);
      await ev(`document.getElementById('btn-export').click(); document.querySelector('#menu-export .tb-menu-item[data-format="${fmt}"]').click(); 1`);
      const info = await ev(`({ printed: window.__printed, layout: typeof _lastPrintLayout !== 'undefined' ? _lastPrintLayout : null,
        heads: [...document.querySelectorAll('#print-sheet h1')].map(h => h.textContent) })`);
      const pdf = Buffer.from((await cmd('Page.printToPDF', { printBackground: true, preferCSSPageSize: true })).data, 'base64');
      await ev(`window.dispatchEvent(new Event('afterprint')); 1`);
      const p = join(dl, `${tag}-${fmt}.pdf`); writeFileSync(p, pdf);
      if (OUT) writeFileSync(join(OUT, `${tag}-${fmt}.pdf`), pdf);
      const pages = pdfWords(p);
      // calibration: the heading is 13 pt; its first word's box height is 13 pt's height in this PDF
      const headFirst = meta.title.split(/\s+/)[0];
      const headH = median(pages.map(pg => (pg.words.find(w => w.t === headFirst) || {}).h).filter(Boolean));
      const stepH = median(pages.flatMap(pg => pg.words.filter(w => nameWords.has(w.t)).map(w => w.h)));
      // the smallest step name: a name's size is its smallest word, a word's size its LARGEST occurrence (the same word
      // also appears in smaller text: flow labels, lane names, notes)
      const big = new Map();
      for (const pg2 of pages) for (const w of pg2.words) if (nameWords.has(w.t)) big.set(w.t, Math.max(big.get(w.t) || 0, w.h));
      const perName = meta.names.map(n => n.split(/\s+/).filter(w => nameWords.has(w)).map(w => big.get(w) || 0)).filter(a => a.length).map(a => Math.min(...a));
      const minStepH = perName.length ? Math.min(...perName) : 0;
      const all = pages.map(pg => pg.text).join(' ');
      const namesIn = meta.names.filter(n => { const ws = n.split(/\s+/).filter(w => /^[A-Za-z]{4,}$/.test(w)); return !ws.length || ws.every(w => all.includes(w)); }).length;
      return { info, pages, pt: headH ? 13 * stepH / headH : 0, minPt: headH ? 13 * minStepH / headH : 0,
               namesIn, editor: EDITOR_WORDS.filter(w => all.includes(w)) };
    };
    const a4 = await run('pdf'), a3 = await run('pdf-a3'), pg = await run('pdf-pages');
    const sz = r => r ? r.pages.map(p => `${p.w}x${p.h}`).join(',') : '-';
    leg(!!a4 && a4.pages.length === 1 && a4.pages[0].w === 842 && a4.pages[0].h === 595 && a4.editor.length === 0 && a4.namesIn === meta.names.length,
        `A1 [${tag}] one page A4: one 842x595 pt page with the map alone`, `${sz(a4)}, names ${a4 && a4.namesIn}/${meta.names.length}, step text ${a4 && a4.pt.toFixed(1)} pt, editor words ${a4 && JSON.stringify(a4.editor)}`);
    leg(!!a3 && a3.pages.length === 1 && a3.pages[0].w === 1191 && a3.pages[0].h === 842 && a3.editor.length === 0 && a4 && a3.pt > a4.pt * 1.1,
        `B1 [${tag}] one page A3: one 1191x842 pt page, step names larger than on A4`, `${sz(a3)}, step text ${a3 && a3.pt.toFixed(1)} pt vs A4 ${a4 && a4.pt.toFixed(1)} pt`);
    const L = pg && pg.info.layout;
    leg(!!pg && !!L && pg.pages.length === L.parts.length && pg.pages.every(p => p.w === 842 && p.h === 595) && pg.minPt >= 7.6 && pg.editor.length === 0,
        `P1 [${tag}] readable pages: ${L ? L.parts.length : '?'} A4 page(s), as computed; every step name at >= 8 pt (measured)`,
        `${sz(pg)}, step text median ${pg && pg.pt.toFixed(1)} pt, smallest ${pg && pg.minPt.toFixed(1)} pt, layout says ${L ? L.textPt.toFixed(1) : '?'} pt`);
    if (L) {
      // every step box (not larger than half a page: a group around steps cannot be) lies whole inside some page part
      const halfW = 277 / (8 * 25.4 / 72 / (L.textPx || 11)) / 2, halfH = 175 / (8 * 25.4 / 72 / (L.textPx || 11)) / 2;
      const cut = L.boxes.filter(b => b.x1 - b.x0 < halfW && b.y1 - b.y0 < halfH)
        .filter(b => !L.parts.some(p => b.x0 >= p.x - 0.5 && b.x1 <= p.x + p.w + 0.5 && b.y0 >= p.y - 0.5 && b.y1 <= p.y + p.h + 0.5));
      const innerX = L.xs.map(s => s[1]).slice(0, -1), innerY = L.ys.map(s => s[1]).slice(0, -1);
      const n = L.parts.length;
      const headsOk = n === 1 ? !/page \d+ of/.test(pg.info.heads[0] || '') : pg.info.heads.every((h, k) => h.includes(`page ${k + 1} of ${n}`));
      // what the pages must hold: from the map's left edge (lane names) to just after its last step, all lanes' height
      const fits = L.extent.x1 - L.extent.x0 <= L.maxW && L.extent.y1 - L.extent.y0 <= L.maxH;
      if (fits) sawOnePage = true; else sawSeveral = true;
      leg(pg.namesIn === meta.names.length && cut.length === 0 && headsOk && (fits ? n === 1 : n > 1),
          `P2 [${tag}] every step name on some page, every step box whole on some page, headings name the part, ${fits ? 'fits on one page -> exactly one' : 'too wide/tall -> several pages'}`,
          `${n} part(s) ${L.xs.length} col x ${L.ys.length} row, names ${pg.namesIn}/${meta.names.length}, boxes not whole on any page ${cut.length}${cut.length ? ' (first ' + JSON.stringify(cut[0], (k, v) => typeof v === 'number' ? Math.round(v) : v) + ', cuts x ' + JSON.stringify(innerX.map(Math.round)) + ' y ' + JSON.stringify(innerY.map(Math.round)) + ')' : ''}, heads ${JSON.stringify(pg.info.heads.map(h => h.replace(/^.*·\s*/, '')))}`);
    }
  }
  leg(sawOnePage && sawSeveral, 'P3 the maps cover both cases: one that fits on one readable page and one that needs several', `one page: ${sawOnePage}, several: ${sawSeveral}`);
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL');
  for (const d of [doc, dl, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
