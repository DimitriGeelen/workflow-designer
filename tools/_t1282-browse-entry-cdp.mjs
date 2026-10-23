#!/usr/bin/env node
// _t1282-browse-entry-cdp.mjs — T-1282 (AEF T-4716): the URL entry ?browse=1 opens the Open-project card browser
// once /api/health confirms the project API, so AEF routes Watchtower /designer straight to it.
// Drives the REAL editor headless (gallery-serve.py over a temp version store holding AEF's project corpus,
// .agentic-framework/.context/designer/projects/*, every version, so the browser lists the maps AEF stores).
// Cases:
//   1. opens:     ?browse=1 opens #project-modal in Open-project mode (title "Open project map", a card per map,
//                 delete affordances = no pick callback); ✕ closes it and leaves the designer as it was;
//   2. closed:    no parameter, no browser;
//   3. pick:      picking aef-task-lifecycle in the ?browse=1 browser loads it (tl_create present, saved version
//                 = the latest), byte-identical (the uuid minted per open masked) to picking the same card from the Open project button;
//   4. load wins: ?browse=1&load=/api/version?id=aef-inception-flow&v=N adopts that map (the same bytes as picking it) and no browser opens;
//   5. no API:    on a static server (no /api/health) ?browse=1 opens nothing and raises no page error.
// T1282_SRC substitutes another designer file (HEAD before T-1282: cases 1 and 3 must go red). Exit 0 = green;
// 1 = red; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1282_SRC || join(REPO, 'src/aef-workflow-designer.html');
const PROJECTS = join(REPO, '.agentic-framework/.context/designer/projects');
const PICK = 'aef-task-lifecycle', DEEP = 'aef-inception-flow';
const SETTLE_MS = 1500;   // how long "nothing opens" is watched for, after the API answered
// A file that declares no uuid gets one minted on every open (T-224), so two opens of the same version differ in
// that attribute alone; the comparisons below mask it.
const unmint = x => x.replace(/(<aef:workflowMeta\b[^>]*\buuid=")[^"]*"/, '$1-"');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(), on = []; s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } else if (m.method) on.forEach(f => f(m)); }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, on: f => on.push(f), close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }
async function until(cmd, expr, ms) { const t0 = Date.now(); for (;;) { if (await ev(cmd, expr).catch(() => false)) return true; if (Date.now() - t0 > ms) return false; await sleep(100); } }

// The temp version store: every AEF project version, its index from meta.json (what /api/list reads).
function buildStore(repo) {
  const ids = readdirSync(PROJECTS).filter(d => existsSync(join(PROJECTS, d, 'meta.json'))).sort(), latest = {};
  for (const id of ids) {
    const meta = JSON.parse(readFileSync(join(PROJECTS, id, 'meta.json'), 'utf8')), out = join(repo, '.editor-versions', id);
    mkdirSync(out, { recursive: true });
    const index = meta.versions.filter(v => existsSync(join(PROJECTS, id, `v${v.v}.bpmn`)));
    for (const v of index) copyFileSync(join(PROJECTS, id, `v${v.v}.bpmn`), join(out, `v${v.v}.bpmn`));
    writeFileSync(join(out, 'index.json'), JSON.stringify(index.map(v => ({ v: v.v, ts: v.ts, note: v.note || '' })), null, 2));
    latest[id] = Math.max(...index.map(v => v.v));
  }
  return { ids, latest };
}

// What the page shows: the browser, its mode, its cards; the document; the deep link.
const PROBE = `(function(){
  var m = document.getElementById('project-modal'), h = m && m.querySelector('strong');
  return { open: !!m, title: h ? h.textContent : null,
           cards: m ? Array.prototype.map.call(m.querySelectorAll('button[title^="Open "]'), function(b){ return b.title.slice(5); }) : [],
           deletes: m ? m.querySelectorAll('button[title^="Delete "]').length : 0,
           api: typeof _apiAvailable !== 'undefined' && _apiAvailable === true,
           deepLink: typeof _deepLinkSettled === 'undefined' ? null : _deepLinkSettled,
           uids: state.nodes.map(function(n){ return n.uid; }).filter(Boolean),
           savedV: typeof _loadedSavedVersion === 'undefined' ? null : _loadedSavedVersion,
           bytes: buildBpmnXml(state) };
})()`;

async function session(withApi, fn) {
  const doc = mkdtempSync(join(tmpdir(), 't1282-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1282-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const store = buildStore(repo);
  const port = await freePort();
  const py = withApi
    ? spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] })
    : spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1282-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { await fetch(BASE + '/designer.html'); up = true; break; } catch (_) {} await sleep(100); }
    if (!up) throw new Error('server down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    const pageErrors = [];
    cl.on(m => { if (m.method === 'Runtime.exceptionThrown') pageErrors.push(JSON.stringify(m.params.exceptionDetails).slice(0, 300)); });
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
    // a fresh page per URL: localStorage cleared so no autosave restores the previous case's map
    const open = async query => {
      await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd);
      await ev(cmd, `localStorage.clear(), sessionStorage.clear(), true`);
      await cmd('Page.navigate', { url: `${BASE}/designer.html${query}` }); await waitReady(cmd);
      if (withApi) await until(cmd, `_apiAvailable === true`, 8000);
    };
    return await fn({ cmd, open, pageErrors, store });
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}

const clickCard = (cmd, id) => ev(cmd, `(function(){ var b = document.querySelector('#project-modal button[title="Open ${id}"]'); if (!b) return false; b.click(); return true; })()`);

async function main() {
  if (!existsSync(SRC) || !existsSync(join(PROJECTS, PICK, 'meta.json')) || !existsSync(join(PROJECTS, DEEP, 'meta.json'))) { console.log(JSON.stringify({ ok: false, error: 'missing input' })); process.exitCode = 2; return; }
  const errs = [], report = { src: SRC };
  try {
    await session(true, async ({ cmd, open, pageErrors, store }) => {
      // 1. opens, in Open-project mode; ✕ leaves the designer as it was
      await open('?browse=1');
      const opened = await until(cmd, `!!document.getElementById('project-modal') && document.querySelectorAll('#project-modal button[title^="Open "]').length > 0`, 5000);
      const c1 = await ev(cmd, PROBE);
      const before = c1.bytes;
      await ev(cmd, `(function(){ var h = document.querySelector('#project-modal strong'); if (h) h.parentElement.querySelector('button.btn').click(); return true; })()`);
      await sleep(200);
      const c1x = await ev(cmd, PROBE);
      report.opens = { opened, api: c1.api, title: c1.title, cards: c1.cards.length, deletes: c1.deletes, closed: !c1x.open, unchanged: c1x.bytes === before };
      if (!c1.api) errs.push('opens: the project API was never confirmed — vacuous');
      if (!opened || !c1.open) errs.push('opens: ?browse=1 did not open the project browser');
      else {
        if (c1.title !== 'Open project map') errs.push(`opens: the browser is titled "${c1.title}", not Open-project mode`);
        if (c1.cards.join() !== store.ids.join()) errs.push(`opens: the cards are [${c1.cards}], the store holds [${store.ids}]`);
        if (c1.deletes !== store.ids.length) errs.push(`opens: ${c1.deletes} delete affordances for ${store.ids.length} cards (pick mode has none)`);
        if (!report.opens.closed) errs.push('opens: ✕ did not close the browser');
        if (!report.opens.unchanged) errs.push('opens: closing the browser changed the document');
      }
      // 2. no parameter: closed
      await open('');
      await sleep(SETTLE_MS);
      const c2 = await ev(cmd, PROBE);
      report.closed = { api: c2.api, open: c2.open };
      if (!c2.api) errs.push('closed: the project API was never confirmed — vacuous');
      if (c2.open) errs.push('closed: the browser opened without ?browse=1');
      // 3. pick: the ?browse=1 card loads the map, the same bytes as the Open project button's card
      await open('?browse=1');
      await until(cmd, `!!document.querySelector('#project-modal button[title="Open ${PICK}"]')`, 5000);
      const clicked = await clickCard(cmd, PICK);
      await until(cmd, `!document.getElementById('project-modal') && state.nodes.some(function(n){ return n.uid === 'tl_create'; })`, 5000);
      const c3 = await ev(cmd, PROBE);
      await open('');
      await ev(cmd, `document.getElementById('btn-open-project').click(), true`);
      await until(cmd, `!!document.querySelector('#project-modal button[title="Open ${PICK}"]')`, 5000);
      const clickedB = await clickCard(cmd, PICK);
      await until(cmd, `!document.getElementById('project-modal') && state.nodes.some(function(n){ return n.uid === 'tl_create'; })`, 5000);
      const c3b = await ev(cmd, PROBE);
      report.pick = { clicked, closed: !c3.open, tl_create: c3.uids.includes('tl_create'), savedV: c3.savedV, latest: store.latest[PICK], viaButton: clickedB, sameBytes: unmint(c3.bytes) === unmint(c3b.bytes), bytes: c3.bytes.length };
      if (!clicked) errs.push(`pick: no ${PICK} card in the ?browse=1 browser`);
      else {
        if (c3.open) errs.push('pick: the browser stayed open after the pick');
        if (!report.pick.tl_create) errs.push(`pick: ${PICK} was not loaded (no tl_create node)`);
        if (c3.savedV !== store.latest[PICK]) errs.push(`pick: loaded saved version ${c3.savedV}, the latest is ${store.latest[PICK]}`);
        if (!clickedB) errs.push('pick: the Open project button browser has no card to compare with — vacuous');
        else if (!report.pick.sameBytes) errs.push('pick: the map picked from ?browse=1 differs in bytes from the same card picked via Open project');
      }
      // 4. ?load wins over ?browse=1
      const v = store.latest[DEEP];
      await open(`?browse=1&load=${encodeURIComponent(`/api/version?id=${DEEP}&v=${v}`)}`);
      await until(cmd, `_deepLinkSettled === 'adopted'`, 5000);
      await sleep(SETTLE_MS);
      const c4 = await ev(cmd, PROBE);
      // the same map picked from the Open project button: the document ?load adopted must be that one
      await open('');
      await ev(cmd, `document.getElementById('btn-open-project').click(), true`);
      await until(cmd, `!!document.querySelector('#project-modal button[title="Open ${DEEP}"]')`, 5000);
      const clickedD = await clickCard(cmd, DEEP);
      await until(cmd, `!document.getElementById('project-modal') && state.nodes.length > 0`, 5000);
      const c4b = await ev(cmd, PROBE);
      report.loadWins = { api: c4.api, deepLink: c4.deepLink, open: c4.open, nodes: c4.uids.length, sameAsPicked: clickedD && unmint(c4.bytes) === unmint(c4b.bytes) };
      if (!c4.api) errs.push('load wins: the project API was never confirmed — vacuous');
      if (c4.deepLink !== 'adopted') errs.push(`load wins: the deep link settled "${c4.deepLink}", not adopted`);
      if (!c4.uids.length) errs.push('load wins: the document is empty');
      if (!report.loadWins.sameAsPicked) errs.push(`load wins: the document ?load adopted is not ${DEEP} v${v} as Open project opens it`);
      if (c4.open) errs.push('load wins: the browser opened although ?load named a document');
      report.pageErrors = pageErrors.slice();
      for (const e of pageErrors) errs.push('page error (API session): ' + e);
    });
    // 5. no API: nothing opens, no page error
    await session(false, async ({ cmd, open, pageErrors }) => {
      await open('?browse=1');
      await sleep(SETTLE_MS + 500);
      const c5 = await ev(cmd, PROBE);
      report.noApi = { api: c5.api, open: c5.open, pageErrors: pageErrors.slice() };
      if (c5.api) errs.push('no API: _apiAvailable is true on a static server — the case is not what it claims');
      if (c5.open) errs.push('no API: the browser opened without a project API');
      for (const e of pageErrors) errs.push('no API: page error ' + e);
    });
  } catch (e) { errs.push('exception: ' + (e && e.stack || e)); }
  report.ok = !errs.length; report.errs = errs;
  console.log(JSON.stringify(report, null, 2));
  process.exitCode = errs.length ? 1 : 0;
}
main();
