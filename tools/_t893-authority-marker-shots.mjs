#!/usr/bin/env node
// T-893 — element-level screenshots of the authority marker in all three states x all three
// label sizes, taken in an ISOLATED headless Chromium (own --user-data-dir; never the shared
// Playwright MCP browser — G-006). Also decides two legs on observed bytes:
//   L1  marker counts per state on the fixture match the fixture's construction
//   L2  rendering markers mutates nothing: buildBpmnXml before == after (clause 3)
// Screenshots go to docs/reports/t893-shots/<state>-<size>.png for the task's Visual
// Verification section. Exit 0 = both legs pass and 9 files written; 2 otherwise.
import { readFileSync, existsSync, readdirSync, mkdtempSync, copyFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';
const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const OUT = join(REPO, 'docs', 'reports', 't893-shots');
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&typeof renderProperties==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

function fixture() {
  let s = readFileSync(join(REPO, 'examples/aef-processes/rendered/task-lifecycle.bpmn'), 'utf8');
  if (s.indexOf('authority="initiative"') < 0) throw new Error('fixture base lacks an initiative lane');
  s = s.replace('authority="initiative"', 'authority="none"');           // agent lane -> retired sentinel: its elements are MISSING
  const i = s.indexOf('id="frw_4_enter"'); const j = s.indexOf('<aef:meta ', i);
  if (i < 0 || j < 0 || j - i > 3000) throw new Error('fixture: frw_4_enter meta not found');
  s = s.slice(0, j) + '<aef:meta authority="initiative" ' + s.slice(j + '<aef:meta '.length);   // own authority != lane default: DIFFERS
  return s;
}

(async () => {
  const doc = mkdtempSync(join(tmpdir(), 't893-doc-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  writeFileSync(join(doc, 'rendered', 't893.bpmn'), fixture());
  const port = await freePort();
  const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: ['ignore', 'ignore', 'ignore'] });
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't893-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl, rc = 0;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/designer.html'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('static server down');
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/t893.bpmn` });
    await waitReady(cmd);
    for (let i = 0; i < 50 && !(await ev(cmd, '(state.nodes||[]).length > 0')); i++) await sleep(200);
    const nodes = await ev(cmd, 'state.nodes.map(n => ({ id: n.id, lane: n.lane, own: (n.aef||{}).authority || null }))');
    const lanes = await ev(cmd, 'getLanes().map(l => ({ id: l.id, authority: l.authority, authoringDefault: l.authoringDefault }))');
    const before = await ev(cmd, 'buildBpmnXml(state)');
    // g.node[data-id] carries the INTERNAL n.id; ask the editor which internal id each display id maps to.
    const pick = await ev(cmd, `(() => { const by = d => (state.nodes.find(n => displayIdOf(n) === d) || {}).id || null; return { none: by('frw_3_start'), differs: by('frw_4_enter'), missing: by('agt_2_perform') }; })()`);
    if (!pick.none || !pick.differs || !pick.missing) throw new Error('display ids not resolved: ' + JSON.stringify(pick) + ' sample=' + JSON.stringify(nodes.slice(0, 3)));
    mkdirSync(OUT, { recursive: true });
    const counts = {};
    for (const size of ['s', 'm', 'l']) {
      await ev(cmd, `labelPrefs.size = ${JSON.stringify(size)}; renderAll(); true`);
      await sleep(150);
      const c = await ev(cmd, `({ differs: document.querySelectorAll('[data-authority-marker="differs"]').length, missing: document.querySelectorAll('[data-authority-marker="missing"]').length, nodes: state.nodes.length })`);
      counts[size] = c;
      for (const [st, id] of Object.entries(pick)) {
        const box = await ev(cmd, `(() => { const g = document.querySelector('g.node[data-id="${id}"]'); if (!g) return null; const r = g.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height }; })()`);
        if (!box) throw new Error('no node ' + id + ' for ' + st);
        const shot = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: Math.max(0, box.x - 24), y: Math.max(0, box.y - 28), width: box.w + 48, height: box.h + 44, scale: 2 } });
        writeFileSync(join(OUT, `${st}-${size}.png`), Buffer.from(shot.data, 'base64'));
      }
    }
    const after = await ev(cmd, 'buildBpmnXml(state)');
    const agentNodes = nodes.filter(n => n.lane === 'agent').length;
    const l1 = ['s', 'm', 'l'].every(k => counts[k].differs === 1 && counts[k].missing === agentNodes);
    console.log(`L1 ${l1 ? 'PASS' : 'FAIL'}  marker counts per size: ${JSON.stringify(counts)}; agent-lane nodes=${agentNodes} (all MISSING under the retired sentinel), frw_4_enter DIFFERS`);
    const l2 = before === after && before.length > 1000;
    console.log(`L2 ${l2 ? 'PASS' : 'FAIL'}  buildBpmnXml before == after rendering markers (${before.length} bytes); the default never writes`);
    console.log(`lanes: ${JSON.stringify(lanes)}`);
    console.log(`screenshots: ${readdirSync(OUT).filter(f => f.endsWith('.png')).length} in ${OUT}`);
    rc = (l1 && l2) ? 0 : 2;
  } catch (e) { console.error('DRIVER ERROR', e && e.message); rc = 2; }
  finally { try { br.kill(); } catch (_) {} try { py.kill(); } catch (_) {} }
  process.exit(rc);
})();
