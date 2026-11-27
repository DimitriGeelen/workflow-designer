// T-1528 (T-1519 GO, agreed with AEF msg ab4c1d03) — aef:workflowMeta/@scope = framework | project, absent read as
// project. Before this the designer did not read the attribute, so a scope AEF wrote was dropped by the next save.
//
//   S1 a map without scope saves byte-identically to the released designer (T1528_READER, default dist 0.51.0)
//   S2 scope="framework" and scope="project" survive open + save, written right after the other workflowMeta attributes
//   S3 the workflow panel's Scope select: choosing framework writes it; one undo takes it back; choosing unset clears it
//   S4 a value outside the set (hand-edited) is kept as is and shown in the select, and the validator warns on the save
//      (W-XML-WORKFLOW-SCOPE: the same validator the designer's Check runs)
// Teeth: T1528_EDITOR=<dist 0.51.0> fails S2, S3, S4.
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1528_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const READER = process.env.T1528_READER || join(ROOT, 'dist', 'aef-workflow-designer-0.51.0.html');
const FIXTURE = join(ROOT, 'tests/fixtures/t1528/unmarked.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1528-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
if (existsSync(READER)) copyFileSync(READER, join(doc, 'reader.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const profiles = [];
const dialogs = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1528-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  // a dialog (alert/confirm) blocks the page, and every later command waits on it: record its text, dismiss it, and
  // report it (pool runs at c1800044a and 8618e0661 hung 60 s in B5, a page call and then a mouse event)
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000, onEvent: m => {
    if (m.method === 'Page.javascriptDialogOpening') {
      dialogs.push(`${m.params.type}: ${String(m.params.message).slice(0, 200)}`);
      cl.cmd('Page.handleJavaScriptDialog', { accept: true }).catch(() => {});
    }
    if (m.method === 'Inspector.targetCrashed') dialogs.push('CRASH: the page crashed');
  } }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable'); await cl.cmd('Inspector.enable').catch(() => {});
  await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  const open = async page => {
    // Leave the current page first (about:blank), so it can neither autosave into storage after the clear nor answer a
    // ready check meant for the next page; then clear the origin's storage (designer and reader share it); then load.
    // Before: clear-then-reload raced both (pool run at c1800044a: CDP TIMEOUT in B5's first open after B4's reader;
    // with 1.5 s navigation latency locally: the starter and the sample saved as *_v2, a library entry written after
    // the clear).
    const origin = `http://127.0.0.1:${port}`;
    await cl.cmd('Page.navigate', { url: 'about:blank' });
    for (let k = 0; k < 100; k++) { if (await ev(`location.href === 'about:blank'`).catch(() => false)) break; await sleep(100); }
    await cl.cmd('Storage.clearDataForOrigin', { origin, storageTypes: 'local_storage,session_storage,indexeddb,cache_storage' });
    await cl.cmd('Page.navigate', { url: `${origin}/${page}` });
    for (let k = 0; k < 200; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
    await ev(`document.fonts.ready`);
  };
  const frames = () => ev(`new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); })`);
  const press = async (x, y) => { for (const type of ['mousePressed', 'mouseReleased']) await cl.cmd('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 }); await frames(); };
  const click = async sel => {
    const r = await ev(`(function(){ var e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; e.scrollIntoView({ block: 'center', inline: 'center' });
      var b = e.getBoundingClientRect(); return { x: b.left + b.width / 2, y: b.top + b.height / 2 }; })()`);
    if (!r) return false;
    await frames(); await press(r.x, r.y); return true;
  };
  // a real click on the map at map coordinates (x, y), the view panned first so the point is on screen
  const clickMap = async (x, y) => {
    // the map scrolls inside its container (wider than the screen's canvas area): scroll the point into the middle first,
    // then check that it is the map, not a panel, under the pointer
    const r = await ev(`(function(){ var sc = svg.parentElement;
      var at = function(){ var m = svg.getScreenCTM(); return { x: m.a * ${x} + m.c * ${y} + m.e, y: m.b * ${x} + m.d * ${y} + m.f }; };
      var p = at(), b = sc.getBoundingClientRect();
      sc.scrollLeft += p.x - (b.left + b.width / 2); sc.scrollTop += p.y - (b.top + b.height / 2);
      p = at(); b = sc.getBoundingClientRect();
      var e = document.elementFromPoint(p.x, p.y);
      return { x: p.x, y: p.y, in: p.x > b.left + 2 && p.x < b.right - 2 && p.y > b.top + 2 && p.y < b.bottom - 2 && !!e && svg.contains(e) }; })()`);
    if (!r.in) return false;
    await cl.cmd('Input.dispatchMouseEvent', { type: 'mouseMoved', x: r.x, y: r.y });
    await press(r.x, r.y); return true;
  };
  const adopt = x => ev(`(function(x){ adoptImportedXml(x, { userImport: true }); if (typeof openingZoom === 'function') openingZoom(); return true; })(${JSON.stringify(x)})`);
  const save = () => ev(`buildBpmnXml(state)`);
  const fixture = readFileSync(FIXTURE, 'utf8');
  const mark = v => fixture.replace(/(<aef:workflowMeta\b[^>]*?)(\/>)/, `$1 scope="${v}"$2`);
  // re-opening the same map in one session renames it in the library (_v2, _v3): compare with the id set aside
  // (the id is also part of the definitions, collaboration and process ids, so every occurrence of it is set aside)
  const norm = x => { const m = x.match(/<aef:workflowMeta id="([^"]*)"/); return m ? x.split(m[1]).join('ID') : x; };
  const wmLine = x => (x.match(/<aef:workflowMeta\b[^>]*>/) || [''])[0];
  const scopeSelect = `(function(){ var ls = Array.from(document.querySelectorAll('#properties .field')).filter(function(f){
      var l = f.querySelector('.field-label'); return l && /^Scope/.test(l.textContent); });
    return ls.length === 1 ? ls[0].querySelector('select') : null; })()`;
  const showPanel = () => ev(`(function(){ selection = null; if (typeof multiSelect !== 'undefined' && multiSelect) multiSelect.clear(); renderAll(); renderProperties(); return true; })()`);
  // choose an option as a person does: the select's value, then its change event (what the browser fires)
  const choose = v => ev(`(function(){ var s = ${scopeSelect}; if (!s) return false; s.value = ${JSON.stringify(v)};
    s.dispatchEvent(new Event('change', { bubbles: true })); return true; })()`);

  // S1 unmarked: byte-identical to the released designer's save
  let reader = null;
  if (existsSync(join(doc, 'reader.html'))) { await open('reader.html'); await adopt(fixture); await frames(); reader = await save(); }
  await open('designer.html');
  await adopt(fixture); await frames();
  const s1 = await save();
  leg(!!reader && s1 === reader && !/scope=/.test(wmLine(s1)),
    'S1 a map without scope saves byte-identically to the released designer, with no scope attribute',
    JSON.stringify({ reader: !!reader, same: s1 === reader, wm: wmLine(s1) }));

  // S2 both values survive open + save, right after the attributes before them
  const s2 = {};
  for (const v of ['framework', 'project']) {
    await adopt(mark(v)); await frames();
    const out = await save();
    await adopt(out); await frames();
    const again = await save();
    s2[v] = { wm: wmLine(out), stable: norm(out) === norm(again), rest: norm(out.replace(` scope="${v}"`, '')) === norm(s1) };
  }
  leg(Object.entries(s2).every(([v, r]) => new RegExp(`\\sscope="${v}"/>$`).test(r.wm) && r.stable && r.rest),
    'S2 scope="framework" and scope="project" survive open + save (twice), and nothing else in the save changes',
    JSON.stringify(s2));

  // S3 the Scope select: set, undo, clear
  await adopt(fixture); await frames(); await showPanel(); await frames();
  const has = await ev(`!!${scopeSelect}`);
  const opts = has ? await ev(`Array.from(${scopeSelect}.options).map(function(o){ return o.value; })`) : null;
  await choose('framework'); await frames();
  const a = await save();
  await ev(`undo()`); await frames();
  const u = await save();
  await showPanel(); await frames();
  await choose('project'); await frames(); await showPanel(); await frames();
  const shown = has ? await ev(`${scopeSelect}.value`) : null;
  await choose(''); await frames();
  const c = await save();
  leg(has && JSON.stringify(opts) === JSON.stringify(['', 'framework', 'project']) && /\sscope="framework"\/>/.test(wmLine(a))
      && !/scope=/.test(wmLine(u)) && shown === 'project' && !/scope=/.test(wmLine(c)) && norm(c) === norm(s1),
    'S3 the workflow panel Scope select (unset, framework, project): framework is written, one undo takes it back, unset clears it',
    JSON.stringify({ has, opts, set: wmLine(a), undone: wmLine(u), shown, cleared: norm(c) === norm(s1) }));

  // S4 a value outside the set: kept, shown, and warned on by the validator
  await adopt(mark('everyone')); await frames(); await showPanel(); await frames();
  const bad = await save();
  const shownBad = await ev(`(function(){ var s = ${scopeSelect}; return s ? s.value : null; })()`);
  const f = join(doc, 'bad.bpmn'); writeFileSync(f, bad);
  const vr = spawnSync('python3', [join(ROOT, 'tools/validate-workflow.py'), f], { encoding: 'utf8' });
  leg(/\sscope="everyone"\/>/.test(wmLine(bad)) && shownBad === 'everyone' && /\[W-XML-WORKFLOW-SCOPE\]/.test(vr.stdout) && / 0 error\(s\)/.test(vr.stdout),
    'S4 a scope outside the set is kept and shown as is; the validator warns (W-XML-WORKFLOW-SCOPE) and finds no error',
    JSON.stringify({ wm: wmLine(bad), shownBad, validator: (vr.stdout || '').trim().split('\n').slice(-2) }));

  if (process.env.T1528_SHOTS) {
    const D = process.env.T1528_SHOTS; mkdirSync(D, { recursive: true });
    for (const W of [1024, 1440, 1920]) {
      for (const v of ['', 'framework']) {
        await open('designer.html');
        await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
        await adopt(v ? mark(v) : fixture); await frames(); await showPanel(); await frames();
        await ev(`(function(){ var s = ${scopeSelect}; if (s) s.scrollIntoView({ block: 'center' }); return true; })()`); await frames(); await sleep(200);
        const s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
        writeFileSync(join(D, `workflow-panel-${v || 'unset'}-${W}.png`), Buffer.from(s.data, 'base64'));
      }
    }
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  }
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300) + (dialogs.length ? '  dialogs: ' + JSON.stringify(dialogs) : ''));
} finally {
  if (dialogs.length) leg(false, 'no dialog opened during the run', JSON.stringify(dialogs).slice(0, 400));
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
