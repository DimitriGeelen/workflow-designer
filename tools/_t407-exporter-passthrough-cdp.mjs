#!/usr/bin/env node
/**
 * _t407-exporter-passthrough-cdp.mjs — what does OUR export do to a FOREIGN
 * producer identity?
 *
 * AEF asked (rail 491) whether `exporter` names "who authored this process" or
 * "who wrote these bytes", and put two options to us. Answering from code reading
 * would be answering the question T-361 exists to punish: buildBpmnXml plainly
 * writes exporter unconditionally, and the whole lesson of T-361 is that a
 * constant and an emitter can agree with each other about something that is not
 * true of the produced artifact.
 *
 * So this measures. Input is tests/fixtures/third-party/simple.bpmn — a REAL
 * Camunda Modeler document (PROVENANCE.md), carrying
 * `exporter="camunda modeler" exporterVersion="2.6.0"` on <definitions>. It goes
 * through the real editor in a real browser: parseBpmnXml -> buildBpmnXml.
 *
 * Reports what came out. Three outcomes are meaningful and all three are printed
 * rather than collapsed into pass/fail — the question was WHICH of them we do:
 *
 *   ours-only     we overwrite: the export claims OUR authorship of OUR bytes.
 *                 The "who wrote these bytes" reading, and AEF's option 2.
 *   theirs-kept   we preserve: the export claims CAMUNDA authored bytes our
 *                 emitter just wrote. A false provenance record — AEF's option 1
 *                 and the shape they were right to hesitate over.
 *   absent        no producer identity at all — the pre-T-399 state, and a
 *                 regression of it.
 *
 * Usage: node tools/_t407-exporter-passthrough-cdp.mjs
 * Exit 0 = ours-only. Exit 1 = theirs-kept or absent. Exit 2 = harness/control error.
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const INPUT = join(REPO, 'tests', 'fixtures', 'third-party', 'simple.bpmn');

const OURS = 'aef-workflow-designer';

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

function exporterAttrs(xml) {
  const out = [];
  const re = /\bexporter(Version)?\s*=\s*"([^"]*)"/g;
  let m;
  while ((m = re.exec(xml)) !== null) out.push([m[1] ? 'exporterVersion' : 'exporter', m[2]]);
  return out;
}

async function main() {
  if (!existsSync(INPUT)) throw new Error('input fixture missing: ' + INPUT);
  const inBytes = readFileSync(INPUT, 'utf8');
  const inAttrs = exporterAttrs(inBytes);

  // CONTROL on the INPUT. Without it, an "ours-only" verdict is equally consistent
  // with an input that never carried a foreign identity in the first place — the
  // probe would report "we overwrite" having overwritten nothing.
  if (!inAttrs.some(([k, v]) => k === 'exporter' && v && !v.includes(OURS))) {
    console.log('  FAIL control — input carries no FOREIGN exporter; nothing to overwrite');
    console.log('        input attrs: ' + JSON.stringify(inAttrs));
    return 2;
  }
  console.log('  input  <definitions> ' + inAttrs.map(([k, v]) => `${k}="${v}"`).join(' '));

  const doc = mkdtempSync(join(tmpdir(), 't407-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't407-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't407-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, exported = null;
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    await ev(cmd, `window.__IN__ = ${JSON.stringify(inBytes)};`);
    exported = await ev(cmd, `(function(){
      var m = parseBpmnXml(window.__IN__);
      if(!m) return null;
      state = m; refreshDisplayIds();
      return buildBpmnXml(state);
    })()`);
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  if (!exported) { console.log('  FAIL — export returned null (parse failed)'); return 2; }

  const outAttrs = exporterAttrs(exported);
  console.log('  output <definitions> ' + (outAttrs.length
    ? outAttrs.map(([k, v]) => `${k}="${v}"`).join(' ')
    : '(no exporter attribute)'));

  const hasOurs = outAttrs.some(([k, v]) => k === 'exporter' && v === OURS);
  const keptTheirs = outAttrs.some(([k, v]) => v && v.toLowerCase().includes('camunda'));

  let verdict;
  if (keptTheirs) verdict = 'theirs-kept';
  else if (hasOurs) verdict = 'ours-only';
  else verdict = 'absent';

  console.log(`\n  VERDICT: ${verdict}`);
  if (verdict === 'ours-only') {
    console.log('  We overwrite a foreign producer identity with our own. `exporter` therefore');
    console.log('  means WHO WROTE THESE BYTES on our side — matching what every emitter in the');
    console.log('  third-party corpus means by it (PROVENANCE.md). AEF option 2, already shipped');
    console.log('  by us, arrived at before the question was asked.');
    return 0;
  }
  if (verdict === 'theirs-kept') {
    console.log('  We preserve a foreign identity on bytes our own emitter wrote — a provenance');
    console.log('  claim we cannot support. AEF option 1, and a defect here.');
    return 1;
  }
  console.log('  Our export carries NO producer identity — the T-399 authorship test cannot');
  console.log('  recognise our own output. Regression of T-399.');
  return 1;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
