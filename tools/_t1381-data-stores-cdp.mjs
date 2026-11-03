#!/usr/bin/env node
// _t1381-data-stores-cdp.mjs — T-1381: data stores (bpmn:dataStoreReference) are drawn as BPMN draws them, a cylinder
// with its name, by T-1369's rule: under the task that writes them (else the first that reads them), side by side with
// that task's documents, in that task's lane, which grows to hold them. Drives the REAL editor headless on
// tests/fixtures/t1381/data-stores.bpmn (made up: an order book written by "Record the order" and read by "Confirm the
// order", a stock store read by "Check stock" in another lane, an archive no task links to, and one document) and asserts:
//   1. Order book and Stock are drawn as stores ([data-data-store]), labelled with their name, under their anchor task;
//      Order book stands beside the document of the same task, not on it;
//   2. each store and its label lie inside its anchor task's lane band, which grew to hold it;
//   3. the links: DOA_1 out (task -> store), DIA_1 in, DIA_2 in, all dotted; DOA_2 (to the document) out;
//   4. Archive (no task links to it) is not drawn; the import notice counts 1 document and 2 data stores as drawn and
//      names "1 data store no task links to (Archive)" as not drawn;
//   5. the save keeps every data element and association, and a second open -> save is byte-identical.
// T1381_SRC substitutes another designer file (the BITE: on the pre-T-1381 source, legs 1-4 are red).
// Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn, spawnSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1381_SRC || join(REPO, 'src/aef-workflow-designer.html');
const MAP = readFileSync(join(REPO, 'tests/fixtures/t1381/data-stores.bpmn'), 'utf8');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 500)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const ASSERT = `(() => {
  var errs = [], info = {};
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function lanesNow(){ var y = POOL_Y + POOL_HEADER, out = {}; getLanes().forEach(function(l){ out[l.id] = { top: y, bottom: y + l.height, h: l.height }; y += l.height; }); return out; }
  function box(g){ var b = g.getBBox(); return { x: b.x, y: b.y, w: b.width, h: b.height }; }
  // The Warehouse lane's height without Stock's link (so nothing to draw there): what the lane would be without T-1381.
  var lanesFile = {}; (function(){ var tmp = parseBpmnXml(window.__MAP__.replace(/<bpmn:dataInputAssociation id="DIA_2">[\\s\\S]*?<\\/bpmn:dataInputAssociation>/, ''));
    (tmp.lanes || []).forEach(function(l){ lanesFile[l.id] = l.height; }); })();
  adoptImportedXml(window.__MAP__); renderAll();
  var stores = Array.from(document.querySelectorAll('#g-data [data-data-store]')).map(function(g){
    return { id: g.getAttribute('data-data-store'), box: box(g), hasEllipse: !!g.querySelector('ellipse'),
             labels: Array.from(g.querySelectorAll('text')).map(function(t){ return t.textContent; }) };
  });
  var docs = Array.from(document.querySelectorAll('#g-data [data-data-object]')).map(function(g){ return { id: g.getAttribute('data-data-object'), box: box(g) }; });
  info.stores = stores; info.docs = docs;
  var byName = function(nm){ return state.nodes.filter(function(n){ return n.name === nm; })[0]; };
  var want = { R_BOOK: ['Record the order', 'Order book'], R_STOCK: ['Check stock', 'Stock'] };
  Object.keys(want).forEach(function(id){
    var d = stores.filter(function(x){ return x.id === id; })[0], t = byName(want[id][0]);
    if (!d) { errs.push('leg1: store ' + id + ' is not drawn'); return; }
    if (!d.hasEllipse) errs.push('leg1: ' + id + ' is not drawn as a cylinder (no top ellipse)');
    if (d.labels.indexOf(want[id][1]) < 0) errs.push('leg1: ' + id + ' labels ' + JSON.stringify(d.labels));
    var tw = dims(t);
    if (!(d.box.y >= t.y + tw.h)) errs.push('leg1: ' + id + ' is not under "' + want[id][0] + '": ' + JSON.stringify([d.box, t.x, t.y]));
    var ln = lanesNow()[t.lane];
    if (!(d.box.y >= ln.top && d.box.y + d.box.h <= ln.bottom)) errs.push('leg2: ' + id + ' ' + JSON.stringify(d.box) + ' is not inside its lane ' + JSON.stringify(ln));
  });
  // Neighbours under one task: neither the shapes nor their labels may overlap (a group's box holds both).
  var book = stores.filter(function(x){ return x.id === 'R_BOOK'; })[0], conf = docs.filter(function(x){ return x.id === 'R_CONF'; })[0];
  if (book && conf && !(book.box.x + book.box.w <= conf.box.x || conf.box.x + conf.box.w <= book.box.x))
    errs.push('leg1: Order book and the order confirmation (shape or label) overlap: ' + JSON.stringify([book.box, conf.box]));
  info.lanes = lanesNow(); info.lanesFile = lanesFile;
  if (!(lanesNow().L2.h > lanesFile.L2)) errs.push('leg2: the Warehouse lane did not grow for Stock: ' + JSON.stringify([lanesFile, lanesNow()]));
  var assoc = Array.from(document.querySelectorAll('#g-data [data-data-assoc]')).map(function(p){ return { id: p.getAttribute('data-data-assoc'), dir: p.getAttribute('data-dir'), dash: p.getAttribute('stroke-dasharray') }; });
  info.assoc = assoc;
  var dirOf = {}; assoc.forEach(function(a){ dirOf[a.id] = a.dir; });
  if (assoc.length !== 4 || dirOf.DOA_1 !== 'out' || dirOf.DOA_2 !== 'out' || dirOf.DIA_1 !== 'in' || dirOf.DIA_2 !== 'in' || assoc.some(function(a){ return !a.dash; }))
    errs.push('leg3: expected 4 dotted links DOA_1/DOA_2 out, DIA_1/DIA_2 in: ' + JSON.stringify(assoc));

  if (document.querySelector('#g-data [data-data-store="R_ARCHIVE"]')) errs.push('leg4: Archive (no task links to it) is drawn');
  if (typeof maybeShowLaneFixNotice === 'function') maybeShowLaneFixNotice();
  var n1 = (document.getElementById('lane-fix-msg') || {}).textContent || '';
  info.notice = n1;
  if (!/1 document and 2 data stores drawn under the tasks that make or use them, with 4 links to those tasks/.test(n1)
      || !/1 data store no task links to \\(Archive\\)/.test(n1) || !/in the file and saved back unchanged, but not drawn/.test(n1))
    errs.push('leg4: the notice should count 1 document and 2 data stores drawn and name Archive as not drawn: ' + JSON.stringify(n1));

  var o1 = strip(buildBpmnXml(state));
  ['dataStoreReference id="R_BOOK"', 'dataStoreReference id="R_STOCK"', 'dataStoreReference id="R_ARCHIVE"', 'dataObjectReference id="R_CONF"',
   'dataState name="draft"', 'id="DOA_1"', 'id="DOA_2"', 'id="DIA_1"', 'id="DIA_2"'].forEach(function(s2){ if (o1.indexOf(s2) < 0) errs.push('leg5: the save lost ' + s2); });
  state = parseBpmnXml(o1); refreshDisplayIds(); renderAll();
  var o2 = strip(buildBpmnXml(state));
  if (o1 !== o2) errs.push('leg5: a second open -> save differs from the first (lanes grew twice?)');
  return { ok: errs.length === 0, errs: errs, info: info, xml: o1 };
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1381-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1381-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1381-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl, r = null;
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const x = await fetch(BASE + '/api/health'); if (x.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__MAP__ = ${JSON.stringify(MAP)};`);
    r = await ev(cmd, ASSERT);
    if (r && r.xml) {
      const p = spawnSync('python3', ['-I', '-c', 'import sys, xml.etree.ElementTree as E; E.fromstring(sys.stdin.buffer.read())'], { input: r.xml });
      if (p.status !== 0) { r.ok = false; r.errs.push('leg5 (expat): ' + String(p.stderr).trim().split('\n').pop()); }
      delete r.xml;
    }
  } catch (e) {
    r = { ok: false, errs: ['run: ' + String(e && e.stack || e)] };
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill();
    try { rmSync(repo, { recursive: true, force: true }); rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  }
  console.log(JSON.stringify({ ok: !!(r && r.ok), src: SRC, result: r }, null, 2));
  process.exitCode = r && r.ok ? 0 : 1;
}
main();
