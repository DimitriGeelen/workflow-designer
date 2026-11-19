// T-1439 — the toolbar's Import and Export menus, driven in the real designer (headless Chromium, CDP).
//
// Legs (each prints PASS/FAIL; exit 0 only if all pass):
//   L1 the toolbar has Import ▾ and Export ▾, and the unlabelled "Load…" is gone
//   L2 Import opens a menu naming "BPMN 2.0 / Camunda"; opening Export closes it (at most one open)
//   L3 keyboard: ArrowDown on Export opens it with the first item focused; Escape closes and returns focus
//   L4 an outside click closes an open menu
//   L5 Import → BPMN 2.0 / Camunda opens a file chooser; choosing a corpus map imports it (id and node count)
//   L6 Export → BPMN 2.0 / Camunda downloads exactly the bytes Save downloads (same map, same moment)
//   L7 both menus are built from IO_FORMATS (one entry per format), so a later format adds one line
// Teeth: L6 compares bytes written by the browser itself (Browser.downloadProgress), not a function's return value.
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1439_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const RENDERED = join(ROOT, 'examples', 'aef-processes', 'rendered');
const MAP_OPEN = 'arc-lifecycle.bpmn', MAP_IMPORT = 'audit-process.bpmn';
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1439-doc-')), dl = mkdtempSync(join(tmpdir(), 't1439-dl-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
copyFileSync(join(RENDERED, MAP_OPEN), join(doc, 'rendered', MAP_OPEN));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1439-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
const events = [];
let cl;
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000, onEvent: m => events.push(m) }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const waitFor = async (pred, ms = 10000) => { const t0 = Date.now(); while (Date.now() - t0 < ms) { const e = events.find(pred); if (e) return e; await sleep(50); } return null; };
  await cmd('Page.enable'); await cmd('Runtime.enable'); await cmd('DOM.enable');
  await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP_OPEN}` });
  for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
  await sleep(400);
  const errors = [];
  for (const e of events) if (e.method === 'Runtime.exceptionThrown') errors.push(e.params.exceptionDetails.text);
  leg(errors.length === 0, 'page loads without a script error', errors.join(' | ').slice(0, 200));

  // L1
  const l1 = await ev(`({ imp: (document.getElementById('btn-import')||{}).textContent, exp: (document.getElementById('btn-export')||{}).textContent,
    load: !!document.getElementById('btn-load'), loadText: [...document.querySelectorAll('header button')].some(b => /^\\s*Load…/.test(b.textContent)) })`);
  leg(l1.imp === 'Import ▾' && l1.exp === 'Export ▾' && !l1.load && !l1.loadText, 'L1 toolbar shows Import ▾ and Export ▾; "Load…" gone', JSON.stringify(l1));

  // L2
  await ev(`document.getElementById('btn-import').click()`);
  const l2a = await ev(`({ open: !document.getElementById('menu-import').hidden, exp: document.getElementById('btn-import').getAttribute('aria-expanded'),
    items: [...document.querySelectorAll('#menu-import .tb-menu-item')].map(i => i.textContent) })`);
  await ev(`document.getElementById('btn-export').click()`);
  const l2b = await ev(`({ imp: !document.getElementById('menu-import').hidden, exp: !document.getElementById('menu-export').hidden })`);
  leg(l2a.open && l2a.exp === 'true' && l2a.items.length === 1 && /BPMN 2\.0 \/ Camunda/.test(l2a.items[0]) && !l2b.imp && l2b.exp,
      'L2 Import names BPMN 2.0 / Camunda; opening Export closes Import', JSON.stringify({ l2a, l2b }));
  await ev(`document.getElementById('btn-export').click()`);   // close

  // L3 keyboard
  await ev(`document.getElementById('btn-export').focus()`);
  await cmd('Input.dispatchKeyEvent', { type: 'keyDown', key: 'ArrowDown', code: 'ArrowDown', windowsVirtualKeyCode: 40 });
  await cmd('Input.dispatchKeyEvent', { type: 'keyUp', key: 'ArrowDown', code: 'ArrowDown', windowsVirtualKeyCode: 40 });
  const l3a = await ev(`({ open: !document.getElementById('menu-export').hidden, focus: document.activeElement.className, fmt: document.activeElement.dataset.format })`);
  await cmd('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
  await cmd('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27 });
  const l3b = await ev(`({ open: !document.getElementById('menu-export').hidden, focus: document.activeElement.id })`);
  leg(l3a.open && l3a.focus === 'tb-menu-item' && l3a.fmt === 'bpmn' && !l3b.open && l3b.focus === 'btn-export',
      'L3 ArrowDown opens with the first item focused; Escape closes and refocuses the button', JSON.stringify({ l3a, l3b }));

  // L4 outside click
  await ev(`document.getElementById('btn-import').click()`);
  const r = await ev(`(function(){ const c = document.getElementById('canvas').getBoundingClientRect(); return { x: c.left + 40, y: c.bottom - 40 }; })()`);
  await cmd('Input.dispatchMouseEvent', { type: 'mousePressed', x: r.x, y: r.y, button: 'left', clickCount: 1 });
  await cmd('Input.dispatchMouseEvent', { type: 'mouseReleased', x: r.x, y: r.y, button: 'left', clickCount: 1 });
  const l4 = await ev(`!document.getElementById('menu-import').hidden`);
  leg(l4 === false, 'L4 an outside click closes the open menu');

  // L6 first (the map open now is MAP_OPEN): Export bytes == Save bytes, as the browser writes them
  await cmd('Browser.setDownloadBehavior', { behavior: 'allowAndName', downloadPath: dl, eventsEnabled: true });
  const download = async clickExpr => {
    const n0 = events.length;
    await ev(clickExpr);
    const done = await waitFor(e => events.indexOf(e) >= n0 && e.method === 'Browser.downloadProgress' && e.params.state === 'completed', 15000);
    return done ? readFileSync(join(dl, done.params.guid)) : null;
  };
  const viaExport = await download(`document.getElementById('btn-export').click(); document.querySelector('#menu-export .tb-menu-item[data-format="bpmn"]').click()`);
  const viaSave = await download(`document.getElementById('btn-save').click()`);
  leg(!!viaExport && !!viaSave && viaExport.length > 1000 && Buffer.compare(viaExport, viaSave) === 0,
      'L6 Export → BPMN downloads exactly the bytes Save downloads', `export ${viaExport && viaExport.length} B, save ${viaSave && viaSave.length} B`);

  // L5 import through the real file chooser
  await cmd('Page.setInterceptFileChooserDialog', { enabled: true });
  const n0 = events.length;
  await ev(`document.getElementById('btn-import').click(); document.querySelector('#menu-import .tb-menu-item[data-format="bpmn"]').click()`);
  const fc = await waitFor(e => events.indexOf(e) >= n0 && e.method === 'Page.fileChooserOpened', 8000);
  let l5 = null;
  if (fc) {
    await cmd('DOM.setFileInputFiles', { files: [join(RENDERED, MAP_IMPORT)], backendNodeId: fc.params.backendNodeId });
    for (let i = 0; i < 60; i++) { l5 = await ev(`({ id: state.workflowMeta.id, nodes: state.nodes.length })`); if (l5.id === 'audit-process') break; await sleep(150); }
  }
  leg(!!fc && l5 && l5.id === 'audit-process' && l5.nodes > 0, 'L5 Import → BPMN opens a file chooser and imports the chosen map', JSON.stringify({ chooser: !!fc, l5 }));

  // L7 one list
  const l7 = await ev(`({ imp: IO_FORMATS.import.map(f => f.id), exp: IO_FORMATS.export.map(f => f.id),
    menuImp: (document.getElementById('btn-import').click(), [...document.querySelectorAll('#menu-import .tb-menu-item')].map(i => i.dataset.format)) })`);
  await ev(`document.getElementById('btn-import').click()`);
  leg(JSON.stringify(l7.menuImp) === JSON.stringify(l7.imp) && l7.imp.includes('bpmn') && l7.exp.includes('bpmn'),
      'L7 the Import menu is built from IO_FORMATS', JSON.stringify(l7));
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL');
  for (const d of [doc, dl, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
