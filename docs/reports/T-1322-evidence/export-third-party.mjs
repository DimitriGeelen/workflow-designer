// T-1322 measurement: open each third-party file as a person would (adoptImportedXml, userImport) and save it
// (buildBpmnXml). Writes <out>/<name>.bpmn. Read-only on the repo.
import { makeProfileDir } from '/opt/832-Workflow-designer/tools/_cdp-profile.mjs';
import { pageWsUrl } from '/opt/832-Workflow-designer/tools/_cdp-attach.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, basename } from 'node:path';
import net from 'node:net';
const REPO = '/opt/832-Workflow-designer';
const OUT = process.argv[2];
const FILES = process.argv.slice(3);
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); return c.find(existsSync); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { for (let i = 0; i < 150; i++) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0]) return +t[0]; } await sleep(100); } throw new Error('no port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise(r => s.addEventListener('open', r)); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
mkdirSync(OUT, { recursive: true });
const doc = mkdtempSync(join(tmpdir(), 't1322-doc-')), repo = mkdtempSync(join(tmpdir(), 't1322-repo-'));
copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
const port = await freePort();
const py = spawn('python3', [join(REPO, 'tools/gallery-serve.py'), String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: 'ignore' });
const udd = makeProfileDir('t1322-');
const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl;
try {
  for (let i = 0; i < 100; i++) { try { if ((await fetch(`http://127.0.0.1:${port}/api/health`)).ok) break; } catch (_) {} await sleep(100); }
  cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
  await cmd('Page.enable'); await cmd('Runtime.enable');
  const E = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
  for (let i = 0; i < 200; i++) { if (await E(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
  for (const f of FILES) {
    const xml = readFileSync(f, 'utf8');
    try {
      const out = await E(`(async function(){ await adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); return buildBpmnXml(state); })()`);
      writeFileSync(join(OUT, basename(f)), out);
      console.log('ok  ' + basename(f));
    } catch (e) { console.log('ERR ' + basename(f) + ' ' + e.message.slice(0, 200)); }
  }
} finally { try { cl && cl.close(); } catch (_) {} br.kill('SIGKILL'); py.kill('SIGKILL'); for (const d of [doc, repo, udd]) rmSync(d, { recursive: true, force: true }); }
