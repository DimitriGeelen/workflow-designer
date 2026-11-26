// T-1521 — a deep link to a version opens that version whether `load` is encoded or not. Written unencoded,
// ?load=/api/version?id=M&v=1 gives the PAGE the `v` (the `load` value ends at the `&`), and before this the designer
// fetched /api/version?id=M, the latest version, without a word (found by the T-1516 reviewer).
//
// The harness serves its own small project API: /api/version?id=M[&v=N] answers versions 1-3 of the authoring kit's
// exemplar, each titled "M v<N>" (no v: the latest, 3). Each case opens a fresh page and waits for the deep link to
// settle (window._deepLinkSettled, T-1061), then reads the opened map's title.
//
//   V1 ?load=/api/version?id=M&v=1 (unencoded) opens version 1
//   V2 the encoded form (?load=%2Fapi%2Fversion%3Fid%3DM%26v%3D1) opens version 1
//   V3 ?load=/api/version?id=M opens the latest (3)
//   V4 a load with its own v (?load=%2Fapi%2Fversion%3Fid%3DM%26v%3D2&v=1) keeps its own: version 2
//   V5 the fetches the server saw match (the unencoded link asked for v=1)
// Teeth: T1521_EDITOR=<dist 0.51.0> fails V1 (it opens version 3).
import { readFileSync, mkdtempSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import http from 'node:http';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1521_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const kits = readdirSync(join(ROOT, 'dist')).filter(d => /^aef-authoring-kit-\d/.test(d)).sort((a, b) =>
  a.replace(/\D+/g, '.').localeCompare(b.replace(/\D+/g, '.'), undefined, { numeric: true }));
const EXEMPLAR = readFileSync(join(ROOT, 'dist', kits[kits.length - 1], 'exemplar.bpmn'), 'utf8');
const version = n => EXEMPLAR.replace(/(<aef:workflowMeta\b[^>]*\btitle=")[^"]*(")/, `$1M v${n}$2`);
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const page = readFileSync(EDITOR, 'utf8');
const seen = [];
const server = http.createServer((req, res) => {
  const u = new URL(req.url, 'http://x');
  if (u.pathname === '/designer.html') { res.writeHead(200, { 'content-type': 'text/html' }); return res.end(page); }
  if (u.pathname === '/api/version' && u.searchParams.get('id') === 'M') {
    seen.push(u.search);
    const v = u.searchParams.has('v') ? +u.searchParams.get('v') : 3;
    if (!(v >= 1 && v <= 3)) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { 'content-type': 'application/xml' }); return res.end(version(v));
  }
  res.writeHead(404); res.end();
});
const port = await new Promise(r => server.listen(0, '127.0.0.1', () => r(server.address().port)));
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const profiles = [], dialogs = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1521-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000, onEvent: m => {
    if (m.method === 'Page.javascriptDialogOpening') { dialogs.push(`${m.params.type}: ${String(m.params.message).slice(0, 200)}`); cl.cmd('Page.handleJavaScriptDialog', { accept: true }).catch(() => {}); }
    if (m.method === 'Inspector.targetCrashed') dialogs.push('CRASH: the page crashed');
  } }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable'); await cl.cmd('Inspector.enable').catch(() => {});
  const origin = `http://127.0.0.1:${port}`;
  // a fresh page per case: away first, storage cleared (no autosaved draft can be restored over the link), then load
  const openLink = async query => {
    await cl.cmd('Page.navigate', { url: 'about:blank' });
    for (let k = 0; k < 100; k++) { if (await ev(`location.href === 'about:blank'`).catch(() => false)) break; await sleep(100); }
    await cl.cmd('Storage.clearDataForOrigin', { origin, storageTypes: 'local_storage,session_storage,indexeddb,cache_storage' });
    await cl.cmd('Page.navigate', { url: `${origin}/designer.html${query}` });
    let settled = null;
    for (let k = 0; k < 200 && !settled; k++) { settled = await ev(`window._deepLinkSettled || null`).catch(() => null); if (!settled) await sleep(150); }
    const title = await ev(`(state && state.workflowMeta && state.workflowMeta.title) || null`).catch(() => null);
    return { settled, title };
  };
  const enc = s => encodeURIComponent(s);
  const v1 = await openLink(`?load=/api/version?id=M&v=1`);
  leg(v1.settled === 'adopted' && v1.title === 'M v1', `V1 ?load=/api/version?id=M&v=1 written unencoded opens version 1`, JSON.stringify(v1));
  const v2 = await openLink(`?load=${enc('/api/version?id=M&v=1')}`);
  leg(v2.settled === 'adopted' && v2.title === 'M v1', `V2 the encoded form opens version 1`, JSON.stringify(v2));
  const v3 = await openLink(`?load=/api/version?id=M`);
  leg(v3.settled === 'adopted' && v3.title === 'M v3', `V3 ?load=/api/version?id=M opens the latest (version 3)`, JSON.stringify(v3));
  const v4 = await openLink(`?load=${enc('/api/version?id=M&v=2')}&v=1`);
  leg(v4.settled === 'adopted' && v4.title === 'M v2', `V4 a load with its own v=2 keeps it over the page's v=1`, JSON.stringify(v4));
  leg(JSON.stringify(seen) === JSON.stringify(['?id=M&v=1', '?id=M&v=1', '?id=M', '?id=M&v=2']),
    `V5 the server was asked for v=1, v=1, the latest, v=2`, JSON.stringify(seen));
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300) + (dialogs.length ? '  dialogs: ' + JSON.stringify(dialogs) : ''));
} finally {
  if (dialogs.length) leg(false, 'no dialog opened during the run', JSON.stringify(dialogs).slice(0, 400));
  await stop(); server.close();
  for (const d of profiles) removeProfileDir(d);
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
