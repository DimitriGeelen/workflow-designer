#!/usr/bin/env node
// _t1092-authority-summary-cdp.mjs — T-1092: authority markers configurable (default ON), and a map
// that declares NO authority gets one summary instead of "⚠ no authority" on every element.
//
// aef-greenfield-test (T-172 #6): on their client maps (imported, no authority anywhere) the marker
// sat on 30 of 77 nodes; their patch hid it behind a Settings option, default OFF. The operator kept
// T-888 clause 4 (missing authority stays visible) and chose: default ON, plus ONE summary in the
// advisory dock when the map declares no authority at all. Legs:
//   1  default: labelPrefs.showAuthority is true and the Settings box is ticked
//   2  no-authority fixture: 0 per-element markers
//   3  ...and the summary is shown, naming the 4 elements
//   4  ...and it sits in the dock: the canvas is pushed below it (T-1078), not covered
//   5  dismissing hides it for this map; reloading the SAME map keeps it hidden
//   6  loading ANOTHER no-authority map shows it again
//   7  mixed fixture (one element declares authority): the other 3 keep their "missing" marker
//   8  ...and no summary
//   9  toggle OFF: no markers on the mixed map
//  10  toggle OFF: no summary on the no-authority map
//  11  the OFF choice survives a page reload (aefLabelPrefs), and the box is unticked
//   node tools/_t1092-authority-summary-cdp.mjs [--designer PATH]   (the unchanged designer must FAIL)
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
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
const argv = process.argv.slice(2);
const DESIGNER = (argv.indexOf('--designer') >= 0 && argv[argv.indexOf('--designer') + 1]) || join(REPO, 'src', 'aef-workflow-designer.html');
const FIX = join(REPO, 'tests', 'fixtures', 'aef-bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));


function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }

async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }
const LOAD = xml => `(() => { adoptImportedXml(${JSON.stringify(xml)}, { userImport: true }); renderAll(); return true; })()`;
const VIEW = `(() => { const b = document.getElementById('authority-summary'); const m = document.getElementById('authority-summary-msg');
  const shown = !!(b && b.style.display !== 'none' && b.offsetHeight > 0);
  return { markers: document.querySelectorAll('[data-authority-marker]').length,
           missing: document.querySelectorAll('[data-authority-marker="missing"]').length,
           shown, msg: m ? m.textContent : null,
           pad: document.querySelector('.canvas-wrap').style.paddingTop || '',
           key: (typeof authSummaryKey === 'function') ? authSummaryKey() : null,
           pref: (typeof labelPrefs === 'object') ? labelPrefs.showAuthority : undefined,
           box: document.getElementById('set-show-authority') ? document.getElementById('set-show-authority').checked : null }; })()`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const NONE = readFileSync(join(FIX, 't1092-no-authority.bpmn'), 'utf8');
  const MIXED = readFileSync(join(FIX, 't1092-mixed-authority.bpmn'), 'utf8');
  const OTHER = NONE.replace(/Process_t1092_none/g, 'Process_t1092_other');
  const doc = mkdtempSync(join(tmpdir(), 't1092-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1092-repo-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1092-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    const open = async () => { await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(300); };
    const load = async xml => { await ev(cmd, LOAD(xml)); await sleep(250); return ev(cmd, VIEW); };
    // T1092_SHOTS=<dir>: also write screenshots of the two fixtures (visual verification, not a leg)
    const shot = async name => { if (!process.env.T1092_SHOTS) return; mkdirSync(process.env.T1092_SHOTS, { recursive: true });
      const r = await cmd('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(process.env.T1092_SHOTS, name), Buffer.from(r.data, 'base64')); };
    await open();

    let v = await ev(cmd, VIEW);
    leg(v.pref === true && v.box === true, '1 default: markers ON (pref true, Settings box ticked)', `pref=${v.pref} box=${v.box}`);
    v = await load(NONE);
    leg(v.markers === 0, '2 no-authority map: no per-element marker', `markers=${v.markers}`);
    leg(v.shown && /declares no authority/.test(v.msg || '') && /\b4 elements\b/.test(v.msg || ''), '3 ...one summary, naming the 4 elements', JSON.stringify(v.msg));
    leg(v.shown && v.pad !== '' && parseInt(v.pad, 10) > 12, '4 ...in the dock: the canvas is pushed below it', `pad=${v.pad}`);
    await shot('no-authority-summary.png');
    const dismissed = await ev(cmd, `(() => { const x = document.getElementById('authority-summary-dismiss'); if (!x) return false; x.click(); return true; })()`);
    await sleep(150);
    const vd = await ev(cmd, VIEW);
    const vr = await load(NONE);
    leg(dismissed && !vd.shown && !vr.shown, '5 dismiss hides it for this map, also after reloading the same map', `clicked=${dismissed} after=${vd.shown} same-map=${vr.shown} key ${vd.key} -> ${vr.key}`);
    v = await load(OTHER);
    leg(v.shown, '6 another no-authority map shows it again', `shown=${v.shown}`);
    v = await load(MIXED);
    leg(v.missing === 3, '7 mixed map: the 3 elements without authority keep their "missing" marker', `missing=${v.missing}`);
    leg(!v.shown, '8 mixed map: no summary', `shown=${v.shown}`);
    await shot('mixed-authority-markers.png');
    await ev(cmd, `setLabelPref('showAuthority', false); true`); await sleep(200);
    v = await ev(cmd, VIEW);
    leg(v.markers === 0, '9 toggle OFF: no marker on the mixed map', `markers=${v.markers}`);
    v = await load(OTHER.replace(/t1092_other/g, 't1092_third'));
    leg(v.markers === 0 && !v.shown, '10 toggle OFF: no summary on a no-authority map', `markers=${v.markers} shown=${v.shown}`);
    await open();
    v = await ev(cmd, VIEW);
    leg(v.pref === false && v.box === false, '11 OFF survives a reload (aefLabelPrefs), box unticked', `pref=${v.pref} box=${v.box}`);
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [repo, doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
  for (const l of legs) console.log(`${l.ok ? 'PASS' : 'FAIL'}  ${l.name}${l.detail ? ' — ' + l.detail : ''}`);
  const want = 11;
  const ok = legs.length === want && legs.every(l => l.ok);
  console.log(ok ? `${legs.length}/${want} legs passed` : `FAILED (${legs.filter(l => !l.ok).length} of ${legs.length})`);
  process.exitCode = ok ? 0 : 1;
}
main();
