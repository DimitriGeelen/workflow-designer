#!/usr/bin/env node
/**
 * _t361-export-trailer-cdp.mjs — prove the repaired trailer survives a REAL export.
 *
 * The source guard (tests/test_emitted_comment_claims.py) proves the string was
 * edited. It does not prove any produced artifact stopped saying it — that is the
 * whole lesson of this task, where a constant and an emitter agreed with each other
 * about a sentence that was false outside the process.
 *
 * So: load the actual designer in a real browser, parse a real document, call the
 * real buildBpmnXml, and read the bytes that come out.
 *
 * Writes the exported document to tests/fixtures/exported/t361-trailer-witness.bpmn
 * so the guard's "current" branch has a witness. Before this, that branch had never
 * fired once — 0 current, 106 legacy — and a bucket that has never filled cannot be
 * reported as working.
 *
 * Usage: node tools/_t361-export-trailer-cdp.mjs
 * Exit 0 = exported bytes carry the approved trailer and name no external party.
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const INPUT = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 's4-exemplar.bpmn');
const OUTDIR = join(REPO, 'tests', 'fixtures', 'exported');
const OUT = join(OUTDIR, 't361-trailer-witness.bpmn');

const FALSE_TAIL = 'AEF generates it from node coordinates';
const PREFIX = 'BPMN DI (visual layout) omitted';

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  if (!existsSync(INPUT)) throw new Error('input fixture missing: ' + INPUT);
  const doc = mkdtempSync(join(tmpdir(), 't361-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't361-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't361-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, exported = null;
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    await ev(cmd, `window.__IN__ = ${JSON.stringify(readFileSync(INPUT, 'utf8'))};`);
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

  if (!exported) { console.log('FAIL — export returned null (parse failed)'); return 1; }

  const fails = [];
  if (exported.includes(FALSE_TAIL)) fails.push(`exported bytes STILL carry the false tail: ${FALSE_TAIL}`);
  if (!exported.includes(PREFIX)) fails.push('exported bytes lost the compatibility prefix');
  const m = exported.match(/<!--\s*(BPMN DI \(visual layout\) omitted[^>]*?)\s*-->/);
  if (!m) fails.push('no DI trailer comment found in exported bytes at all');
  else console.log(`  trailer as EXPORTED: ${JSON.stringify(m[1])}`);
  if (m && /(?<!\w)AEF(?!\w)(?!:)/i.test(m[1])) fails.push('exported trailer names AEF as a party');

  mkdirSync(OUTDIR, { recursive: true });
  writeFileSync(OUT, exported, 'utf8');
  console.log(`  witness written: ${OUT.replace(REPO + '/', '')} (${exported.length} bytes)`);

  if (fails.length) { for (const f of fails) console.log('  FAIL ' + f); console.log('\nFAIL'); return 1; }
  console.log('\nPASS — real exported bytes carry the repaired trailer and name no external party');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
