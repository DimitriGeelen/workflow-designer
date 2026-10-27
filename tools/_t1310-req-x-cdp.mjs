#!/usr/bin/env node
// _t1310-req-x-cdp.mjs — T-1310: the io row's "req" and remove "×", and the same in field rows, measured as a person gets
// them in the rendered designer (headless, real server, 1024 and 1440):
//   contrast  computed text colour against the effective background (the first opaque ancestor), WCAG ratio:
//             req label (text) >= 4.5:1, × (a control glyph, non-text) >= 3:1
//   target    the clickable box of req (label incl. checkbox) and × >= 24×24 px (WCAG 2.2 target size, minimum)
// Prints every measurement; with --report it never fails (for recording the numbers before a change).
// T1310_SRC substitutes another designer file. Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1310_SRC || join(REPO, 'src/aef-workflow-designer.html');
const REPORT = process.argv.includes('--report');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const AEF = 'http://anchorpoint.framework/aef/extensions';
// one step: an input with a field (open editor -> field row) and an output
const MAP = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="${AEF}" id="Definitions_t1310" targetNamespace="https://aef.anchorpoint.dev/workflows">
  <bpmn:process id="Process_t1310" isExecutable="true">
    <bpmn:extensionElements>
      <aef:workflowMeta id="t1310-req-x" version="1" schemaVersion="2" title="req x" tier_default="1"/>
    </bpmn:extensionElements>
    <bpmn:startEvent id="Start_1" name="Start"/>
    <bpmn:serviceTask id="Task_a" name="Sync">
      <bpmn:extensionElements>
        <aef:uid value="t1310_a"/>
        <aef:io>
          <aef:input name="opp" type="object" required="true">
            <aef:field path="Amount" role="read" required="true"/>
          </aef:input>
          <aef:output name="result" type="string"/>
        </aef:io>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:endEvent id="End_1" name="End"/>
    <bpmn:sequenceFlow id="f1" sourceRef="Start_1" targetRef="Task_a"/>
    <bpmn:sequenceFlow id="f2" sourceRef="Task_a" targetRef="End_1"/>
  </bpmn:process>
</bpmn:definitions>
`;

// measure(sel, kind): for each element, the colour ratio against its effective background and its clickable box
const MEASURE = `(function(){
  function rgb(s){ var m = /rgba?\\(([^)]+)\\)/.exec(s || ''); if (!m) return null; var p = m[1].split(',').map(function(x){ return parseFloat(x); }); return { r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1 }; }
  function lum(c){ function ch(v){ v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); } return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b); }
  function bgOf(el){ for (var e = el; e; e = e.parentElement) { var c = rgb(getComputedStyle(e).backgroundColor); if (c && c.a > 0.5) return c; } return rgb(getComputedStyle(document.body).backgroundColor) || { r: 255, g: 255, b: 255 }; }
  function ratio(a, b){ var x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); }
  var p = document.getElementById('properties'), out = [];
  [['io req', p.querySelectorAll('.io-row > .io-req'), 4.5], ['io ×', p.querySelectorAll('.io-row > .io-del'), 3],
   ['field req', p.querySelectorAll('.io-field-row .io-req'), 4.5], ['field ×', p.querySelectorAll('.io-field-row .io-del'), 3]].forEach(function(t){
    Array.from(t[1]).slice(0, 1).forEach(function(el){
      var textEl = el.classList.contains('io-req') ? (el.querySelector('span') || el) : el;
      var col = rgb(getComputedStyle(textEl).color), bg = bgOf(el);
      el.scrollIntoView({ block: 'center' });
      var r = el.getBoundingClientRect(), cx = r.left + r.width / 2, cy = r.top + r.height / 2;
      // the HIT AREA, as a pointer finds it: the four corners of a 24×24 square centred on the control must land on it
      // (an ::after hit area counts; a box measure would not see it)
      var miss = [[-11, -11], [11, -11], [-11, 11], [11, 11]].filter(function(d){
        var hit = document.elementFromPoint(cx + d[0], cy + d[1]); return !(hit && (hit === el || el.contains(hit)));
      }).map(function(d){ var h = document.elementFromPoint(cx + d[0], cy + d[1]); return d.join(',') + '->' + (h ? (h.className || h.tagName) : 'nothing'); });
      out.push({ control: t[0], color: getComputedStyle(textEl).color, ratio: Math.round(ratio(col, bg) * 100) / 100, need: t[2],
                 w: Math.round(r.width * 10) / 10, h: Math.round(r.height * 10) / 10, miss: miss });
    });
    if (!t[1].length) out.push({ control: t[0], missing: true });
  });
  return out;
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1310-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1310-repo-'));
  writeFileSync(join(doc, 'designer.html'), readFileSync(SRC, 'utf8'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1310-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  const legs = {}, errs = [];
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('server down:\n' + pyErr.slice(-400));
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(400);
    const E = (js) => ev(cmd, js);
    for (const [w, h] of [[1024, 768], [1440, 900]]) {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
      await E(`(function(){ state = parseBpmnXml(${JSON.stringify(MAP)}); refreshDisplayIds();
        var n = state.nodes.filter(function(x){ return x.uid === 't1310_a'; })[0];
        selection = { kind: 'node', id: n.id }; multiSelect = new Set([n.id]); renderProperties();
        var t = document.querySelector('#properties .io-attrs-toggle'); if (t) t.click(); return true; })()`);
      const m = await E(MEASURE);
      legs[w] = m;
      for (const x of m) {
        if (x.missing) { errs.push(`${w}: no ${x.control} found`); continue; }
        if (x.ratio < x.need) errs.push(`${w}: ${x.control} contrast ${x.ratio}:1 < ${x.need}:1 (${x.color})`);
        if (x.miss.length) errs.push(`${w}: ${x.control} hit area smaller than 24×24 around its centre: ${x.miss.join(' ')}`);
        // the hit area must not cost layout: the visible box keeps its own height (a 24 px box made field rows taller and
        // narrowed name/type, T-1310 sweep)
        if (x.h > 18) errs.push(`${w}: ${x.control} box grew to ${x.w}×${x.h} px: the target must come from the hit area, not the layout`);
      }
    }
    await cmd('Emulation.clearDeviceMetricsOverride');
    const ok = errs.length === 0;
    console.log(JSON.stringify({ ok: ok || REPORT, measuredOk: ok, src: SRC, errs, legs }, null, 2));
    process.exitCode = ok || REPORT ? 0 : 1;
  } catch (e) {
    console.log(JSON.stringify({ ok: false, error: String(e && e.stack || e), legs }, null, 2));
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
