#!/usr/bin/env node
// _t1372-shots.mjs — T-1372 visual evidence: the import notice on tests/fixtures/t1369/documents.bpmn (a made-up quote in
// two states), opened in the real editor. Writes to OUT (default docs/reports/T-1372-evidence/):
//   notice-<W>.png          the whole window at W = 1024, 1440, 1920 with the notice: 2 documents drawn, nothing hidden;
//   notice-1440-extra.png   the same map plus a data store and a document no task links to, both named as not shown;
//   notice-1440-before.png  the notice on T1372_BEFORE (the 0.37.0 source: everything "kept ... not shown yet").
// Exit 0 = every shot written; 1 = a shot failed.
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, mkdirSync, existsSync, readFileSync, readdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { cdp } from './_cdp-client.mjs';   // T-1395: rejects on Chrome's death and after cmdMs, never waits for ever

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const OUT = process.argv[2] || join(REPO, 'docs/reports/T-1372-evidence');
const SRC = join(REPO, 'src/aef-workflow-designer.html');
const BEFORE = process.env.T1372_BEFORE || '';
const MAP = readFileSync(join(REPO, 'tests/fixtures/t1369/documents.bpmn'), 'utf8');
const EXTRA = MAP.replace('<bpmn:sequenceFlow id="F1"',
  '<bpmn:dataStoreReference id="DS1" name="CRM"/><bpmn:dataObjectReference id="R_LOOSE" name="Memo" dataObjectRef="DO_Q"/><bpmn:sequenceFlow id="F1"');
const SERVER = join(HERE, 'gallery-serve.py');
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; }

async function shoot(src, W, H, shots, plan) {
  const doc = mkdtempSync(join(tmpdir(), 't1372s-doc-')); const repo = mkdtempSync(join(tmpdir(), 't1372s-repo-'));
  copyFileSync(src, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: 'ignore' });
  const udd = makeProfileDir('t1372s-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', `--window-size=${W},${H}`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  const BASE = `http://127.0.0.1:${port}`;
  try {
    for (let i = 0; i < 100; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
    const cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    for (let t0 = Date.now(); Date.now() - t0 < 20000; await sleep(150)) if (await ev(cmd, `typeof adoptImportedXml==='function'&&_appReady===true`).catch(() => false)) break;
    for (const [xml, name] of plan) {
      await ev(cmd, `adoptImportedXml(${JSON.stringify(xml)}); renderAll(); maybeShowLaneFixNotice(); true`); await sleep(700);
      const s = await cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(OUT, name), Buffer.from(s.data, 'base64')); shots.push(name);
    }
    cl.close();
  } finally { br.kill('SIGKILL'); py.kill(); }
}

async function main() {
  mkdirSync(OUT, { recursive: true });
  const shots = [];
  await shoot(SRC, 1024, 768, shots, [[MAP, 'notice-1024.png']]);
  await shoot(SRC, 1440, 900, shots, [[MAP, 'notice-1440.png'], [EXTRA, 'notice-1440-extra.png']]);
  await shoot(SRC, 1920, 1080, shots, [[MAP, 'notice-1920.png']]);
  if (BEFORE) await shoot(BEFORE, 1440, 900, shots, [[MAP, 'notice-1440-before.png']]);
  console.log(JSON.stringify({ ok: true, out: OUT, shots }, null, 1));
}
main().catch(e => { console.error(e); process.exit(1); });
