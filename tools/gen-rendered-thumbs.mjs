#!/usr/bin/env node
// gen-rendered-thumbs.mjs — T-153: generate consistent tiles for the rendered corpus.
//
// The Open-project modal shows a ▦ placeholder for every rendered-only corpus map because
// those BPMNs carry NO DI coordinates and NO saved PNG — layout is computed at render time
// by renderAll(). This batch generator renders each corpus map headlessly (the same CDP
// harness family as tools/_*-verify-cdp.mjs), captures a PNG via the editor's own
// captureThumbnail(), and writes it to the tracked cache .editor-versions/_rendered/<id>.png.
// gallery-serve.py's /api/thumb?id=<id> (no &v=) then serves it, so every card gets a real
// tile and T-156 hover-zoom becomes useful everywhere.
//
// Hermetic: serves the CURRENT src/aef-workflow-designer.html (source of truth, not the
// build mirror) from a temp docroot with all corpus maps copied in, drives it in ISOLATED
// headless chromium (own --user-data-dir; G-006), and only writes PNGs into the real repo.
//
// Usage:  node tools/gen-rendered-thumbs.mjs          # all corpus maps
//         node tools/gen-rendered-thumbs.mjs id1 id2  # only the named ids
// Exit 0 = every requested map produced a non-empty PNG.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = join(REPO, 'examples', 'aef-processes', 'rendered');
const OUT = join(REPO, '.editor-versions', '_rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright'); const c = [];
  if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome'));
  c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium (run: npx playwright install chromium)');
}
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&typeof captureThumbnail==='function')`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }
// After ?load fires (async fetch+adopt+renderAll), wait until the canvas frames real content.
async function waitLoaded(cmd, id) {
  const t0 = Date.now();
  for (;;) {
    const st = await ev(cmd, `(function(){try{
      var bb=document.getElementById('canvas').getBBox();
      return {id:(state&&state.workflowMeta&&state.workflowMeta.id)||'',w:bb.width,h:bb.height,n:document.querySelectorAll('#canvas .node,#canvas [data-node-id]').length};
    }catch(_){return {id:'',w:0,h:0,n:0};}})()`).catch(() => ({ id: '', w: 0, h: 0, n: 0 }));
    if ((st.id === id || Date.now() - t0 > 6000) && st.w > 1 && st.h > 1 && st.n > 0) return st;
    if (Date.now() - t0 > 12000) return st; // safety net: capture whatever is on screen
    await sleep(150);
  }
}

async function main() {
  let ids = process.argv.slice(2).filter(a => !a.startsWith('-'));
  if (!ids.length) ids = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).map(f => f.slice(0, -5)).sort();
  if (!ids.length) throw new Error('no corpus maps found in ' + CORPUS);

  const doc = mkdtempSync(join(tmpdir(), 'thumb-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'thumb-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  for (const id of ids) copyFileSync(join(CORPUS, id + '.bpmn'), join(doc, 'rendered', id + '.bpmn'));

  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'thumb-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1280,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  mkdirSync(OUT, { recursive: true });
  const results = [];
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('gallery-serve did not come up');
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1280, height: 900, deviceScaleFactor: 1, mobile: false });

    for (const id of ids) {
      let ok = false, bytes = 0, note = '';
      try {
        await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${id}.bpmn` });
        await sleep(400);
        await waitReady(cmd);
        const st = await waitLoaded(cmd, id);
        await sleep(500); // final render/label settle
        let dataUrl = await ev(cmd, `captureThumbnail()`);
        if (!dataUrl) { await sleep(600); dataUrl = await ev(cmd, `captureThumbnail()`); } // one retry
        if (dataUrl && dataUrl.startsWith('data:image/png')) {
          const raw = Buffer.from(dataUrl.split(',', 2)[1], 'base64');
          if (raw.length > 0) { writeFileSync(join(OUT, id + '.png'), raw); ok = true; bytes = raw.length; }
          else note = 'empty png';
        } else note = 'captureThumbnail returned null';
        if (ok) note = `${bytes}B  bbox ${Math.round(st.w)}x${Math.round(st.h)} nodes ${st.n}`;
      } catch (e) { note = String(e && e.message || e); }
      results.push({ id, ok, note });
      console.log(`${ok ? '✓' : '✗'} ${id.padEnd(28)} ${note}`);
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  const good = results.filter(r => r.ok).length;
  console.log(`\n${good}/${results.length} thumbnails generated → ${OUT}`);
  process.exit(good === results.length ? 0 : 1);
}
main().catch(e => { console.error('FATAL', e); process.exit(2); });
