#!/usr/bin/env node
// T-892 — the lane panel's Authoring default, driven through the REAL panel in an isolated
// headless Chromium (own --user-data-dir; never the shared MCP browser — G-006). Legs:
//   L1  the panel renders an "Authoring default" <select>; options = '' + AUTHORITIES minus 'none'
//   L2  writing through its change listener sets lane.authoringDefault and re-renders
//   L3  NEVER RE-STAMPS: every existing node's aef bag is byte-identical before/after; the export
//       differs ONLY by authoringDefault="…" on that lane's <aef:laneMeta> (diff non-empty, confined)
//   L4  PRE-FILLS NEW ELEMENTS ONLY: createNodeAt in the defaulted lane -> aef.authority = default;
//       in an undefaulted lane -> no authority key (control)
//   L5  MARKERS RE-RENDER: on the T-893 fixture, default framework->initiative turns frw_4_enter's
//       'differs' marker off; counts asserted before/after
// Screenshots: docs/reports/t892-shots/panel-field.png, node-before.png, node-after.png.
// Exit 0 = all legs pass; 2 otherwise.
import { readFileSync, existsSync, readdirSync, mkdtempSync, copyFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';
const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const OUT = join(REPO, 'docs', 'reports', 't892-shots');
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&typeof renderProperties==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

function fixture() {   // same construction as T-893's driver: agent lane 'none', frw_4_enter own initiative
  let s = readFileSync(join(REPO, 'examples/aef-processes/rendered/task-lifecycle.bpmn'), 'utf8');
  s = s.replace('authority="initiative"', 'authority="none"');
  const i = s.indexOf('id="frw_4_enter"'); const j = s.indexOf('<aef:meta ', i);
  if (i < 0 || j < 0 || j - i > 3000) throw new Error('fixture: frw_4_enter meta not found');
  return s.slice(0, j) + '<aef:meta authority="initiative" ' + s.slice(j + '<aef:meta '.length);
}
const legs = []; const leg = (id, name, ok, detail) => { legs.push({ id, name, ok, detail }); console.log(`${id} ${ok ? 'PASS' : 'FAIL'}  ${name}\n      ${detail}`); };

(async () => {
  const doc = mkdtempSync(join(tmpdir(), 't892-doc-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  writeFileSync(join(doc, 'rendered', 't892.bpmn'), fixture());
  const port = await freePort();
  const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: ['ignore', 'ignore', 'ignore'] });
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't892-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl, rc = 0;
  const shot = async (cmd, sel, file, pad) => {
    const box = await ev(cmd, `(() => { const g = document.querySelector(${JSON.stringify(sel)}); if (!g) return null; const r = g.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height }; })()`);
    if (!box) throw new Error('no element for ' + sel);
    const s = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: Math.max(0, box.x - pad), y: Math.max(0, box.y - pad - 4), width: box.w + 2 * pad, height: box.h + 2 * pad + 4, scale: 2 } });
    mkdirSync(OUT, { recursive: true }); writeFileSync(join(OUT, file), Buffer.from(s.data, 'base64'));
  };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/designer.html'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('static server down');
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/t892.bpmn` });
    await waitReady(cmd);
    for (let i = 0; i < 50 && !(await ev(cmd, '(state.nodes||[]).length > 0')); i++) await sleep(200);
    await ev(cmd, 'labelPrefs.size = "m"; renderAll(); true');
    const nodeId = await ev(cmd, `(state.nodes.find(n => displayIdOf(n) === 'frw_4_enter') || {}).id`);
    if (!nodeId) throw new Error('frw_4_enter not resolved');
    const before = await ev(cmd, `({ aef: JSON.stringify(state.nodes.map(n => n.aef)), xml: buildBpmnXml(state), differs: document.querySelectorAll('[data-authority-marker="differs"]').length, missing: document.querySelectorAll('[data-authority-marker="missing"]').length, laneDefault: (getLanes().find(l => l.id === 'framework') || {}).authoringDefault })`);
    await shot(cmd, `g.node[data-id="${nodeId}"]`, 'node-before.png', 26);

    // ---- L1/L2: drive the REAL panel ----
    const r = await ev(cmd, `(() => {
      selection = { kind: 'lane', id: 'framework' }; renderProperties();
      const fields = Array.from(document.querySelectorAll('#properties .field'));
      const wrap = fields.find(w => { const l = w.querySelector('.field-label'); return l && l.textContent.trim().toLowerCase().indexOf('authoring default') === 0; });
      if (!wrap) return { ok: false, reason: 'SETUP-BROKEN: no Authoring default field in the lane panel' };
      const sel = wrap.querySelector('select');
      if (!sel) return { ok: false, reason: 'SETUP-BROKEN: Authoring default is not a <select>' };
      wrap.setAttribute('data-t892', 'field');
      const options = Array.from(sel.options).map(o => o.value);
      sel.value = 'initiative';
      sel.dispatchEvent(new Event('input', { bubbles: true }));
      sel.dispatchEvent(new Event('change', { bubbles: true }));
      const lane = getLanes().find(l => l.id === 'framework');
      return { ok: true, options, laneDefault: lane.authoringDefault };
    })()`);
    if (!r.ok) throw new Error(r.reason);
    const wantOpts = ['', 'sovereignty', 'authority', 'initiative', 'external'];
    leg('L1', 'panel renders Authoring default <select> with \'\' + AUTHORITIES minus none',
        JSON.stringify(r.options) === JSON.stringify(wantOpts), `options=[${r.options.join(',')}]`);
    leg('L2', 'change through the select sets lane.authoringDefault', r.laneDefault === 'initiative' && before.laneDefault == null,
        `before=${JSON.stringify(before.laneDefault)} after=${JSON.stringify(r.laneDefault)}`);
    await sleep(150);
    // re-select the lane so the panel shows the stored value, then screenshot the field
    await ev(cmd, `selection = { kind: 'lane', id: 'framework' }; renderProperties(); (() => { const w = Array.from(document.querySelectorAll('#properties .field')).find(w => (w.querySelector('.field-label')||{textContent:''}).textContent.trim().toLowerCase().indexOf('authoring default') === 0); if (w) w.setAttribute('data-t892', 'field'); })(); true`);
    await shot(cmd, '#properties .field[data-t892="field"]', 'panel-field.png', 8);

    // ---- L3: never re-stamps ----
    const after = await ev(cmd, `({ aef: JSON.stringify(state.nodes.map(n => n.aef)), xml: buildBpmnXml(state), differs: document.querySelectorAll('[data-authority-marker="differs"]').length, missing: document.querySelectorAll('[data-authority-marker="missing"]').length })`);
    const xmlB = before.xml.split('\n'), xmlA = after.xml.split('\n');
    const changed = xmlA.filter(l => !xmlB.includes(l)).concat(xmlB.filter(l => !xmlA.includes(l)));
    const confined = changed.length > 0 && changed.every(l => l.includes('<aef:laneMeta') && (l.includes('authoringDefault="initiative"') || !l.includes('authoringDefault')));
    leg('L3', 'NEVER RE-STAMPS: node aef bags byte-identical; export differs only on the lane\'s laneMeta',
        before.aef === after.aef && confined,
        `aef identical=${before.aef === after.aef}; changed lines=${changed.length}: ${changed.map(l => l.trim().slice(0, 90)).join(' | ')}`);

    // ---- L5: markers re-render ----
    leg('L5', 'MARKERS RE-RENDER: frw_4_enter differs marker off once the lane default matches it',
        before.differs === 1 && after.differs === 0 && before.missing === after.missing,
        `differs before=${before.differs} after=${after.differs}; missing before=${before.missing} after=${after.missing}`);
    await shot(cmd, `g.node[data-id="${nodeId}"]`, 'node-after.png', 26);

    // ---- L4: pre-fills NEW elements only ----
    const c = await ev(cmd, `(() => {
      const fw = getLanes().find(l => l.id === 'framework'), hu = getLanes().find(l => l.id === 'human');
      const lyF = laneAtY ? null : null;
      const n0 = state.nodes.length;
      // place by lane: find a y inside each lane's band via an existing node of that lane
      const yIn = id => { const n = state.nodes.find(x => x.lane === id); return n ? n.y + 10 : null; };
      createNodeAt('serviceTask', 900, yIn('framework'));
      const a = state.nodes[state.nodes.length - 1];
      createNodeAt('serviceTask', 900, yIn('human'));
      const b = state.nodes[state.nodes.length - 1];
      return { added: state.nodes.length - n0, aLane: a.lane, aAuth: a.aef.authority || null, bLane: b.lane, bHasKey: 'authority' in b.aef, humanDefault: hu.authoringDefault || null };
    })()`);
    leg('L4', 'PRE-FILLS NEW ELEMENTS ONLY: defaulted lane -> aef.authority = default; undefaulted lane -> no key',
        c.added === 2 && c.aLane === 'framework' && c.aAuth === 'initiative' && c.bLane === 'human' && c.bHasKey === false && c.humanDefault === null,
        JSON.stringify(c));
    rc = legs.every(l => l.ok) ? 0 : 2;
    console.log(`${legs.filter(l => l.ok).length}/${legs.length} legs passed; screenshots: ${readdirSync(OUT).filter(f => f.endsWith('.png')).join(', ')}`);
  } catch (e) { console.error('DRIVER ERROR', e && e.message); rc = 2; }
  finally { try { br.kill(); } catch (_) {} try { py.kill(); } catch (_) {} }
  process.exit(rc);
})();
