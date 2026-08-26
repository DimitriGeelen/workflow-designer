#!/usr/bin/env node
// _horizontal-spacing-verify-cdp.mjs — verify T-115: Horizontal spacing control (respaceColumns).
// Serves the editor from a TEMP docroot, drives it in ISOLATED headless chromium (own
// --user-data-dir; G-006). Loads a dense corpus map (verification-gate), then proves the
// respaceColumns(gap) contract empirically: it clusters nodes into pool-wide columns and
// re-spaces them so consecutive column CENTRES sit exactly `gap` px apart (anchored left),
// preserving column count (no fold, monotonic), and one undo() restores every node-x exactly.
// Also asserts the wired Settings input (#set-col-spacing) drives the same function live.
// Screenshots the re-spaced map for the READ step. Exit 0 = pass.
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
const MAP = 'verification-gate';
const GAP = 150;
const BAND = 48; // must match COL_SPACING_BAND in the editor
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&typeof respaceColumns==='function')`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Cluster node centre-xs into columns (band split) and return the sorted column-centre array.
// Mirrors respaceColumns' clustering so the test computes the same columns the editor does.
const COL_HELPER = `(function(){
  var arr = state.nodes.map(function(n){ var d=NODE_DEFAULTS[n.type]; return n.x + d.w/2; }).sort(function(a,b){return a-b;});
  var cols=[[arr[0]]];
  for (var i=1;i<arr.length;i++){ if (arr[i]-arr[i-1] > ${BAND}) cols.push([]); cols[cols.length-1].push(arr[i]); }
  return cols.map(function(c){ return c.reduce(function(s,v){return s+v;},0)/c.length; });
})()`;

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 'hs-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 'hs-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 'hs-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  const near = (a, b, t = 0.6) => Math.abs(a - b) <= t;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down');
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1200, height: 820, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${MAP}.bpmn` });
    await waitReady(cmd); await sleep(500);

    // Precondition: multi-column map loaded, geometry NOT mutated on load, undo stack empty
    // (cleanOnImport defaults false) so a subsequent Ctrl+Z exercises respaceColumns' own revert.
    const before = await ev(cmd, `(function(){
      window.__x0 = new Map(state.nodes.map(function(n){return [n.id, n.x];}));
      return { n: state.nodes.length, cols: ${COL_HELPER}, hist: (typeof _history!=='undefined'?_history.length:-1) };
    })()`);
    push('loaded-multi-column', before.n > 2 && before.cols.length >= 3, { nodes: before.n, columns: before.cols.length });
    push('clean-load-empty-undo-stack', before.hist === 0, { historyDepth: before.hist });

    // Apply respaceColumns(GAP) directly and assert the contract.
    const moved = await ev(cmd, `respaceColumns(${GAP})`);
    push('respace-moves-nodes', typeof moved === 'number' && moved > 0, { moved });

    const after = await ev(cmd, COL_HELPER);
    // column count preserved (no fold), and consecutive column centres exactly GAP apart
    const gaps = after.slice(1).map((v, i) => v - after[i]);
    const gapsUniform = gaps.length > 0 && gaps.every(g => near(g, GAP));
    push('column-count-preserved', after.length === before.cols.length, { before: before.cols.length, after: after.length });
    push('column-gaps-equal-target', gapsUniform, { gaps: gaps.map(g => Math.round(g)), target: GAP });

    // Undo (real Ctrl+Z path) restores every node-x exactly.
    const undone = await ev(cmd, `(function(){
      var ok = undo();
      var restored = state.nodes.every(function(n){ return Math.abs(n.x - window.__x0.get(n.id)) < 0.01; });
      return { ok: ok, restored: restored, maxDelta: Math.max.apply(null, state.nodes.map(function(n){return Math.abs(n.x - window.__x0.get(n.id));})) };
    })()`);
    push('undo-restores-all-xs', undone.ok && undone.restored, undone);

    // Wired Settings input drives the same function live (AC: change fires respaceColumns).
    const viaInput = await ev(cmd, `(function(){
      var before = state.nodes.map(function(n){return n.x;}).join(',');
      var el = document.getElementById('set-col-spacing');
      if (!el) return { ok:false, why:'no #set-col-spacing' };
      el.value = 200; el.dispatchEvent(new Event('change'));
      var after = state.nodes.map(function(n){return n.x;}).join(',');
      var cols = ${COL_HELPER};
      var gaps = cols.slice(1).map(function(v,i){return v-cols[i];});
      return { ok: before!==after, prefApplied: (typeof viewPrefs!=='undefined' && viewPrefs.colSpacing===200), gaps: gaps.map(Math.round) };
    })()`);
    const inputGapsOk = viaInput.gaps && viaInput.gaps.length > 0 && viaInput.gaps.every(g => Math.abs(g - 200) <= 1);
    push('settings-input-drives-respace', viaInput.ok && viaInput.prefApplied && inputGapsOk, viaInput);

    // Screenshot the re-spaced map for the READ step.
    const shot = await cmd('Page.captureScreenshot', { format: 'png' });
    writeFileSync(join(tmpdir(), 'horizontal-spacing-full.png'), Buffer.from(shot.data, 'base64'));
    verdict.screenshotFull = join(tmpdir(), 'horizontal-spacing-full.png');

    verdict.pass = verdict.steps.every(s => s.pass);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), steps: verdict.steps }, null, 2) + '\n');
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    try { rmSync(repo, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
