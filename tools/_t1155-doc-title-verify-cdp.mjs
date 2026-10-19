#!/usr/bin/env node
// _t1155-doc-title-verify-cdp.mjs — verify T-1155 (OBS-371): the browser tab title and the XML panel
// heading name the map that is OPEN, not the literal "investigate.bpmn" the page used to carry.
//
// Serves the editor from a TEMP docroot (gallery-serve.py) and drives it in ISOLATED headless
// chromium (own --user-data-dir; G-006), the same harness as _t911.
//
// WHAT IT ASSERTS:
//   1. Map A opened by deep link: document.title is "AEF Workflow Designer — <A>.bpmn" and the XML
//      panel heading says <A>.bpmn. Control: neither says investigate.bpmn.
//   2. Map B opened in a fresh load: the title follows to <B>.bpmn — two different maps, so a title
//      that is right by coincidence for one map cannot pass.
//   3. In-place switch back to A through loadFromLibrary (the library switch path, no reload).
//   4. Rename through the REAL ID input of the properties panel (value + blur, the deferred commit
//      a user's Enter/blur triggers): title and XML heading follow the new id.
//   5. Screenshot of the XML panel heading for the READ step.
//
// Exit 0 = pass. Exit 1 = a step failed. Exit 2 = harness could not run.
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
const SHOTDIR = join(REPO, '.playwright-mcp');
const MAP_A = 'audit-process';
const MAP_B = 'git-commit-flow';
const RENAMED = 't1155-renamed-map';
const OLD = 'investigate.bpmn';
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const READ = `({ id: (state.workflowMeta||{}).id || null, title: document.title,
  heading: (document.getElementById('xml-panel-docname')||{}).textContent || null })`;
const names = (r, id) => r.title === `AEF Workflow Designer — ${id}.bpmn` && r.heading === `${id}.bpmn`;
const notOld = r => !String(r.title).includes(OLD) && !String(r.heading).includes(OLD);

async function open(cmd, base, map) {
  await cmd('Page.navigate', { url: `${base}/designer.html?load=rendered/${map}.bpmn` });
  await sleep(300); await waitReady(cmd); await sleep(500);
  return ev(cmd, READ);
}

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't1155-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1155-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  for (const m of [MAP_A, MAP_B]) copyFileSync(join(REPO, 'examples/aef-processes/rendered/' + m + '.bpmn'), join(doc, 'rendered', m + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1155-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1280,860', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const verdict = { steps: [], shots: [] };
  const push = (n, p, g) => verdict.steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1280, height: 860, deviceScaleFactor: 1, mobile: false });

    const a = await open(cmd, BASE, MAP_A);
    push(`map A (${MAP_A}) loaded: title and XML heading name ${MAP_A}.bpmn`, a.id === MAP_A && names(a, MAP_A), a);
    push(`control: neither says ${OLD}`, notOld(a), a);

    const b = await open(cmd, BASE, MAP_B);
    push(`map B (${MAP_B}) loaded: the title follows to ${MAP_B}.bpmn`, b.id === MAP_B && names(b, MAP_B) && notOld(b), b);

    // In-place switch: put A into the library alongside B, then switch to it without a reload.
    const sw = await ev(cmd, `(async function(){
      var r = await fetch('rendered/${MAP_A}.bpmn'); var xml = await r.text();
      var before = Array.from(library.keys());
      if (!library.has('${MAP_A}')) library.set('${MAP_A}', parseBpmnXml(xml));
      var mid = ${READ};
      var ok = loadFromLibrary('${MAP_A}');
      return { before: before, ok: ok, mid: mid, after: ${READ} };
    })()`).catch(e => ({ error: String(e) }));
    push(`in-place switch to ${MAP_A} via loadFromLibrary: the title follows (no reload)`,
      sw && sw.ok === true && sw.mid && names(sw.mid, MAP_B) && names(sw.after, MAP_A), sw);

    // Rename through the real ID input (deferred commit on blur).
    const rn = await ev(cmd, `(function(){
      selection = null; multiSelect.clear(); renderProperties();
      var inputs = Array.prototype.slice.call(document.querySelectorAll('#properties .field input.field-input'));
      var target = null;
      for (var i=0;i<inputs.length;i++){ var l = inputs[i].parentElement.querySelector('.field-label');
        if (l && l.textContent.trim().indexOf('ID') === 0) { target = inputs[i]; break; } }
      if (!target) return { ok:false, reason:'no ID input in the workflow panel' };
      target.focus(); target.value = ${JSON.stringify(RENAMED)};
      target.dispatchEvent(new Event('input', { bubbles:true }));
      target.dispatchEvent(new Event('blur'));
      return { ok:true };
    })()`);
    await sleep(300);
    const r = await ev(cmd, READ);
    push(`rename through the ID input to ${RENAMED}: title and XML heading follow`, rn.ok && r.id === RENAMED && names(r, RENAMED), { rename: rn, now: r });

    await ev(cmd, `document.getElementById('btn-xml').click()`); await sleep(400);
    const box = await ev(cmd, `(function(){ var e=document.querySelector('.xml-panel-header'); if(!e) return null; var r=e.getBoundingClientRect(); return { x:r.x, y:r.y, w:r.width, h:r.height }; })()`);
    if (box && box.w > 2 && box.h > 2) {
      const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: box.x, y: box.y, width: box.w, height: box.h, scale: 2 } });
      mkdirSync(SHOTDIR, { recursive: true });
      const f = join(SHOTDIR, 't1155-xml-panel-heading.png');
      writeFileSync(f, Buffer.from(s.data, 'base64'));
      verdict.shots.push({ shot: 't1155-xml-panel-heading.png', captured: true, path: f });
    } else verdict.shots.push({ shot: 't1155-xml-panel-heading.png', captured: false, reason: 'no box for .xml-panel-header' });

    verdict.pass = verdict.steps.every(s => s.pass) && verdict.shots.every(s => s.captured);
    process.stdout.write(JSON.stringify(verdict, null, 2) + '\n');
    process.exitCode = verdict.pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), steps: verdict.steps }, null, 2) + '\n');
    process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
