#!/usr/bin/env node
// _t1369-documents-cdp.mjs — T-1369 (T-1363 GO, build B1): documents (BPMN data objects) are drawn with their state and
// their associations, inside the lane of the task that produces them, and that lane grows to hold them (operator
// 2026-11-02, option 1). Drives the REAL editor headless on tests/fixtures/t1369/documents.bpmn (made up: a quote, sent
// then signed, three tasks, four associations) and asserts:
//   1. both references are drawn ([data-data-object]), labelled with name and [state], under their producing task;
//   2. every document lies inside its anchor task's lane band, which grew to hold it;
//   3. four dotted associations: two outputs (task -> document) and two inputs (document -> task);
//   4. the save keeps every data element and association (T-1096), and a second open -> save is byte-identical
//      (the grown lane is saved, so nothing grows twice);
//   6. (T-1372) the import notice says how many documents and associations are drawn, and names as "not shown yet"
//      only a data store or a document no task links to;
//   5. a map WITHOUT documents (kitchen-sink is not one: it has one; so tests/fixtures/t1366/plain-event-kinds.bpmn)
//      draws nothing in the data layer and its lanes do not change.
// T1369_SRC substitutes another designer file (the BITE: on the pre-T-1369 source, legs 1-3 are red; on the 0.37.0 source, leg 6 is red).
// Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn, spawnSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';   // T-1395: rejects on Chrome's death and after cmdMs, never waits for ever

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1369_SRC || join(REPO, 'src/aef-workflow-designer.html');
const MAP = readFileSync(join(REPO, 'tests/fixtures/t1369/documents.bpmn'), 'utf8');
const PLAIN = readFileSync(join(REPO, 'tests/fixtures/t1366/plain-event-kinds.bpmn'), 'utf8');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 500)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const ASSERT = `(() => {
  var errs = [], info = {};
  function strip(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); }
  function lanesNow(){ var y = POOL_Y + POOL_HEADER, out = {}; getLanes().forEach(function(l){ out[l.id] = { top: y, bottom: y + l.height, h: l.height }; y += l.height; }); return out; }
  function load(xml){ adoptImportedXml(xml); renderAll(); }

  load(window.__MAP__);
  var groups = Array.from(document.querySelectorAll('#g-data [data-data-object]'));
  var docs = groups.map(function(g){
    var b = g.querySelector('path').getBBox();
    return { id: g.getAttribute('data-data-object'), placed: g.getAttribute('data-placed'), x: b.x, y: b.y, w: b.width, h: b.height,
             labels: Array.from(g.querySelectorAll('text')).map(function(t){ return t.textContent; }) };
  });
  info.docs = docs;
  var byName = function(nm){ return state.nodes.filter(function(n){ return n.name === nm; })[0]; };
  var want = { R_SENT: ['Send the quote', 'sent'], R_SIGNED: ['Customer signs', 'signed'] };
  Object.keys(want).forEach(function(id){
    var d = docs.filter(function(x){ return x.id === id; })[0], t = byName(want[id][0]);
    if (!d) { errs.push('leg1: ' + id + ' is not drawn'); return; }
    if (d.labels.indexOf('Quote') < 0 || d.labels.indexOf('[' + want[id][1] + ']') < 0) errs.push('leg1: ' + id + ' labels ' + JSON.stringify(d.labels));
    var tw = dims(t);
    if (!(d.y >= t.y + tw.h && Math.abs((d.x + d.w / 2) - (t.x + tw.w / 2)) < 2)) errs.push('leg1: ' + id + ' is not centred under "' + want[id][0] + '": ' + JSON.stringify([d.x, d.y, t.x, t.y]));
    var ln = lanesNow()[t.lane], bottom = 0;
    Array.from(document.querySelectorAll('#g-data [data-data-object="' + id + '"] text')).forEach(function(x){ var bb = x.getBBox(); bottom = Math.max(bottom, bb.y + bb.height); });
    if (!(d.y >= ln.top && bottom <= ln.bottom)) errs.push('leg2: ' + id + ' (to y ' + Math.round(bottom) + ') is not inside its lane ' + JSON.stringify(ln));
  });
  info.lanes = lanesNow();
  var assoc = Array.from(document.querySelectorAll('#g-data [data-data-assoc]')).map(function(p){ return { id: p.getAttribute('data-data-assoc'), dir: p.getAttribute('data-dir'), dash: p.getAttribute('stroke-dasharray') }; });
  info.assoc = assoc;
  var dirOf = {}; assoc.forEach(function(a){ dirOf[a.id] = a.dir; });
  if (assoc.length !== 4 || dirOf.DOA_1 !== 'out' || dirOf.DOA_2 !== 'out' || dirOf.DIA_2 !== 'in' || dirOf.DIA_3 !== 'in' || assoc.some(function(a){ return !a.dash; }))
    errs.push('leg3: expected 4 dotted associations DOA_1/DOA_2 out, DIA_2/DIA_3 in: ' + JSON.stringify(assoc));

  var o1 = strip(buildBpmnXml(state));
  ['dataObject id="DO_Q"', 'dataObjectReference id="R_SENT"', 'dataObjectReference id="R_SIGNED"', 'dataState name="sent"', 'dataState name="signed"',
   'id="DOA_1"', 'id="DOA_2"', 'id="DIA_2"', 'id="DIA_3"'].forEach(function(s2){ if (o1.indexOf(s2) < 0) errs.push('leg4: the save lost ' + s2); });
  state = parseBpmnXml(o1); refreshDisplayIds(); renderAll();   // reopen the save itself (adopt would rename a second copy)
  var o2 = strip(buildBpmnXml(state));
  if (o1 !== o2) errs.push('leg4: a second open -> save differs from the first (lanes grew twice?)');
  info.lanesAfterReopen = lanesNow();

  // 6. T-1372: the import notice says what is drawn, and names as "not drawn" only what is not
  load(window.__MAP__); if (typeof maybeShowLaneFixNotice === 'function') maybeShowLaneFixNotice();
  var n1 = (document.getElementById('lane-fix-msg') || {}).textContent || '';
  info.notice = n1;
  if (!/2 documents drawn/.test(n1) || !/4 links to those tasks/.test(n1) || /but not drawn|not shown yet/.test(n1))
    errs.push('leg6: the notice should say 2 documents and 4 links are drawn and nothing is hidden: ' + JSON.stringify(n1));
  var extra = window.__MAP__.replace('<bpmn:sequenceFlow id="F1"',
    '<bpmn:dataStoreReference id="DS1" name="CRM"/><bpmn:dataObjectReference id="R_LOOSE" name="Memo" dataObjectRef="DO_Q"/><bpmn:sequenceFlow id="F1"');
  load(extra); maybeShowLaneFixNotice();
  var n2 = (document.getElementById('lane-fix-msg') || {}).textContent || '';
  info.noticeExtra = n2;
  // T-1381: data stores are drawn when a task links to them; this added CRM has no link, so it reads "no task links to".
  if (!/1 data store no task links to \\(CRM\\)/.test(n2) || !/1 document no task links to \\(Memo\\)/.test(n2) || !/in the file and saved back unchanged, but not drawn/.test(n2) || !/2 documents drawn/.test(n2))
    errs.push('leg6: with a data store and an unlinked document, both should be NAMED as not drawn: ' + JSON.stringify(n2));

  load(window.__PLAIN__);
  var before = JSON.stringify(state.lanes.map(function(l){ return [l.id, l.height]; }));
  if (document.querySelectorAll('#g-data > *').length) errs.push('leg5: a map without documents drew something in the data layer');
  info.plainLanes = before;
  return { ok: errs.length === 0, errs: errs, info: info, xml: o1 };
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1369-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1369-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1369-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl, r = null;
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const x = await fetch(BASE + '/api/health'); if (x.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__MAP__ = ${JSON.stringify(MAP)}; window.__PLAIN__ = ${JSON.stringify(PLAIN)};`);
    r = await ev(cmd, ASSERT);
    if (r && r.xml) {
      const p = spawnSync('python3', ['-I', '-c', 'import sys, xml.etree.ElementTree as E; E.fromstring(sys.stdin.buffer.read())'], { input: r.xml });
      if (p.status !== 0) { r.ok = false; r.errs.push('leg4 (expat): ' + String(p.stderr).trim().split('\n').pop()); }
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
