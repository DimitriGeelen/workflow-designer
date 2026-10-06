#!/usr/bin/env node
// _t1061-deeplink-settled-cdp.mjs — the editor says when its ?load= deep link has SETTLED (832 T-1061).
//
// _appReady flips at the end of Init; the ?load= fetch is async and lands later. Probes used to sleep
// a fixed 400 ms after _appReady and lost that race on a busy host (T-1060). The editor now sets
// window._deepLinkSettled on every exit of its ?load handler. This drives the REAL editor and checks
// each state the probes rely on:
//   leg 1  no ?load                         -> 'none'
//   leg 2  ?load of a served map            -> 'adopted', and the map's node is in state
//   leg 3  ?load of a missing file (404)    -> 'failed' (the editor's alert is dismissed), never left null
//   leg 4  null until settled: with the fetch held back, the value is null right after _appReady
// exit 0 = all legs pass; 1 = a leg failed; 2 = CANNOT RUN
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const argi = process.argv.indexOf('--src');
const EDITOR = argi > -1 ? process.argv[argi + 1] : join(REPO, 'src', 'aef-workflow-designer.html');

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; for (const x of ['/usr/bin/chromium', '/usr/bin/google-chrome']) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 20000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

// cdp with events: the alert on the failure path must be dismissed or the page stays blocked.
function cdpE(ws, onEvent) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', e => { const m = JSON.parse(e.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } else if (m.method) onEvent(m, cmd); }); const ready = new Promise(r => s.addEventListener('open', r)); function cmd(method, params = {}) { return new Promise((res, rej) => { const i = ++id; p.set(i, m => m.error ? rej(new Error(method + ': ' + m.error.message)) : res(m.result)); s.send(JSON.stringify({ id: i, method, params })); }); } return { cmd, ready, close: () => s.close() }; }

const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" id="d1" targetNamespace="x">
  <bpmn:process id="p1" isExecutable="false">
    <bpmn:task id="T1" name="settled probe"><bpmn:extensionElements><aef:uid value="u-t1061-node"/></bpmn:extensionElements></bpmn:task>
  </bpmn:process>
</bpmn:definitions>`;

async function settledAfterReady(cmd, url, maxMs) {
  await cmd('Page.navigate', { url });
  const t0 = Date.now(); let first;
  for (;;) {
    const r = await ev(cmd, `({ready: typeof _appReady!=='undefined' && _appReady===true, s: (typeof _deepLinkSettled==='undefined' ? 'UNDEFINED' : _deepLinkSettled)})`).catch(() => null);
    if (r && r.ready && first === undefined) first = r.s;
    if (r && r.ready && r.s !== null) return { first, settled: r.s, ms: Date.now() - t0 };
    if (Date.now() - t0 > maxMs) return { first, settled: r ? r.s : 'NO-PAGE', ms: Date.now() - t0, timeout: true };
    await sleep(50);
  }
}

async function main() {
  const legs = []; const leg = (ok, name, d) => legs.push(`${ok ? 'PASS' : 'FAIL'}  ${name}${d ? ' — ' + d : ''}`);
  if (!existsSync(EDITOR)) { console.log('CANNOT RUN: editor missing: ' + EDITOR); return 2; }
  const doc = mkdtempSync(join(tmpdir(), 't1061-doc-')), repo = mkdtempSync(join(tmpdir(), 't1061-repo-')), udd = mkdtempSync(join(tmpdir(), 't1061-udd-'));
  // leg 4 needs a held-back fetch: a second editor copy whose ?load fetch waits 2 s
  const html = readFileSync(EDITOR, 'utf8');
  const hook = '    const res = await fetch(src);';
  writeFileSync(join(doc, 'designer.html'), html);
  writeFileSync(join(doc, 'slow.html'), html.split(hook).join('    await new Promise(r => setTimeout(r, 2000));\n' + hook));
  mkdirSync(join(doc, 'rendered'), { recursive: true }); writeFileSync(join(doc, 'rendered', 't1061.bpmn'), MAP);
  mkdirSync(join(repo, 'examples', 'aef-processes', 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  let chrome; try { chrome = findChrome(); } catch (e) { console.log('CANNOT RUN: ' + e.message); py.kill(); return 2; }
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', `--remote-debugging-port=0`, `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dialogs = 0, cl;
  try {
    for (let i = 0; i < 80; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdpE(await pageWsUrl(dp), (m, cmd) => { if (m.method === 'Page.javascriptDialogOpening') { dialogs++; cmd('Page.handleJavaScriptDialog', { accept: true }).catch(() => {}); } });
    await cl.ready; const { cmd } = cl; await cmd('Page.enable'); await cmd('Runtime.enable');

    let r = await settledAfterReady(cmd, BASE + '/designer.html', 25000);
    leg(r.settled === 'none', "1 no ?load -> 'none'", JSON.stringify(r));
    r = await settledAfterReady(cmd, BASE + '/designer.html?load=' + encodeURIComponent('rendered/t1061.bpmn'), 25000);
    const has = await ev(cmd, `(state.nodes||[]).some(n => n.uid==='u-t1061-node')`).catch(() => false);
    leg(r.settled === 'adopted' && has, "2 ?load of a served map -> 'adopted', node present", JSON.stringify(r) + ' node=' + has);
    r = await settledAfterReady(cmd, BASE + '/designer.html?load=' + encodeURIComponent('rendered/missing.bpmn'), 25000);
    leg(r.settled === 'failed' && dialogs >= 1, "3 ?load of a missing file -> 'failed' (alert dismissed)", JSON.stringify(r) + ' dialogs=' + dialogs);
    r = await settledAfterReady(cmd, BASE + '/slow.html?load=' + encodeURIComponent('rendered/t1061.bpmn'), 25000);
    leg(r.first === null && r.settled === 'adopted', "4 null right after _appReady while the fetch is held back, then 'adopted'", JSON.stringify(r));
  } catch (e) { console.log('CANNOT RUN: ' + e.message); return 2; }
  finally { try { cl && cl.close(); } catch (_) {} br.kill(); py.kill();
    await new Promise(r => { if (br.exitCode !== null) return r(); br.once('exit', r); setTimeout(r, 3000); });
    // Chrome may still be flushing its profile when it is killed; cleanup must never hide the result
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 }); } catch (_) {} } }
  console.log(legs.join('\n'));
  const bad = legs.filter(l => l.startsWith('FAIL')).length;
  console.log(bad ? `\n${bad} leg(s) failed` : `\n${legs.length}/${legs.length} T-1061 legs passed`);
  return bad ? 1 : 0;
}
main().then(rc => process.exit(rc));
