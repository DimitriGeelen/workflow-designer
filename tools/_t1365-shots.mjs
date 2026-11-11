#!/usr/bin/env node
// _t1365-shots.mjs — T-1365 visual evidence: tests/fixtures/t1365/value-rules.bpmn with the synthetic field catalog
// (tests/fixtures/t1365/field-catalog.json) served as /api/field-catalog, the step selected and its io editor open.
// Writes to OUT (default docs/reports/T-1365-evidence/), at W = 1024, 1440, 1920:
//   panel-<W>.png        the whole window, rules folded (the one-line summary under each field);
//   panel-<W>-open.png   the whole window, every rule opened;
//   fields-<W>-open.png  the fields section of the panel, 2x, rules opened.
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
const OUT = process.argv[2] || join(REPO, 'docs/reports/T-1365-evidence');
const SRC = join(REPO, 'src/aef-workflow-designer.html');
const MAP = readFileSync(join(REPO, 'tests/fixtures/t1365/value-rules.bpmn'), 'utf8');
const CATALOG = readFileSync(join(REPO, 'tests/fixtures/t1365/field-catalog.json'), 'utf8');
const SERVER = join(HERE, 'gallery-serve.py');
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; }

const OPEN = `(async () => {
  adoptImportedXml(window.__MAP__); renderAll(); await loadFieldCatalog();
  var n = state.nodes.filter(function(x){ return x.name === 'Register the order'; })[0];
  selection = { kind: 'node', id: n.id }; multiSelect = new Set([n.id]); renderAll(); renderProperties();
  var p = document.getElementById('properties'), t = p.querySelector('.io-attrs-toggle');
  if (t && !(t.nextElementSibling && t.nextElementSibling.classList.contains('io-attrs'))) t.click();
  var f = document.querySelector('#properties .io-fields'); if (f) f.scrollIntoView({ block: 'start' });
  return !!f; })()`;
const RECT = `(() => { var f = document.querySelector('#properties .io-fields'); if (!f) return null; var b = f.getBoundingClientRect(); return { x: b.x, y: b.y, w: b.width, h: b.height }; })()`;

async function shoot(W, H, repo, shots) {
  const doc = mkdtempSync(join(tmpdir(), 't1365s-doc-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: 'ignore' });
  const udd = makeProfileDir('t1365s-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', `--window-size=${W},${H}`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  const BASE = `http://127.0.0.1:${port}`;
  try {
    for (let i = 0; i < 100; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
    const cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    for (let t0 = Date.now(); Date.now() - t0 < 20000; await sleep(150)) if (await ev(cmd, `typeof adoptImportedXml==='function'&&_appReady===true`).catch(() => false)) break;
    await ev(cmd, `window.__MAP__ = ${JSON.stringify(MAP)};`);
    if (!(await ev(cmd, OPEN))) throw new Error('no io fields section at ' + W);
    await sleep(500);
    const save = async (name, clip) => { const s = await cmd('Page.captureScreenshot', clip ? { format: 'png', clip } : { format: 'png' }); writeFileSync(join(OUT, name), Buffer.from(s.data, 'base64')); shots.push(name); };
    await save(`panel-${W}.png`);
    await ev(cmd, `document.querySelectorAll('#properties .io-field-rule details').forEach(function(d){ d.open = true; }); var f = document.querySelector('#properties .io-fields'); f && f.scrollIntoView({ block: 'start' }); true`);
    await sleep(300);
    await save(`panel-${W}-open.png`);
    const r = await ev(cmd, RECT);
    if (r) { const x = Math.max(0, r.x - 8), y = Math.max(0, r.y - 8); await save(`fields-${W}-open.png`, { x, y, width: Math.min(W - x, r.w + 16), height: Math.min(H - y, r.h + 16), scale: 2 }); }
    cl.close();
  } finally { br.kill('SIGKILL'); py.kill(); }
}

async function main() {
  mkdirSync(OUT, { recursive: true });
  const repo = mkdtempSync(join(tmpdir(), 't1365s-repo-'));
  writeFileSync(join(repo, 'field-catalog.json'), CATALOG);
  const shots = [];
  for (const [W, H] of [[1024, 768], [1440, 900], [1920, 1080]]) await shoot(W, H, repo, shots);
  console.log(JSON.stringify({ ok: true, out: OUT, shots }, null, 1));
}
main().catch(e => { console.error(e); process.exit(1); });
