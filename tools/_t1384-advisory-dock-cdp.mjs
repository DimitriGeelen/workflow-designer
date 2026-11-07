#!/usr/bin/env node
// _t1384-advisory-dock-cdp.mjs — the advisory dock gives the map its room back (T-1384, OBS-493).
//
// It opens tests/fixtures/t1381/data-stores.bpmn the REAL way (adoptImportedXml with userImport, then openingZoom).
// Three advisories show: the import notice, the Clean-layout nudge and the authority summary. Both side panels are
// open, at 1024x768, 1440x900 and 1920x1080. It measures:
//   D1  the dock's top padding: at most 25% of the canvas height at 1024 (it was 270 of 685px, 39%); at most
//       200px at 1440 and 182px at 1920 (the values before T-1384)
//   D2  no advisory box intersects the drawn diagram: the pool, any node, any data shape (T-1078's rule)
//   D3  nothing is lost.
//       - The import notice's and authority summary's textContent are exactly what they were.
//       - On a narrow canvas each hidden part sits behind a visible ".dock-more" control naming how many it hides;
//         clicking it shows every part, and clicking again hides them.
//       - On a wide canvas every part is shown with no control.
//       - The Clean layout button is visible.
//   D4  setup control: all three advisories are visible (else D1-D3 assert nothing).
//
// --self-test reruns on poisoned copies, or the legs assert nothing (T-592):
//   A  DOCK_NARROW_PX set to 0 (never collapse)   -> D1 must FAIL
//   B  the ".dock-more" click handler removed     -> D3 must FAIL
// --src FILE runs on another copy of the designer (to show it is red on the source before T-1384).
// --shots DIR writes the canvas at each width, and at 1024 the dock opened.
//
// Usage:  node tools/_t1384-advisory-dock-cdp.mjs [--self-test] [--src FILE] [--shots DIR]
// Exit:   0 pass · 1 leg failed · 2 setup broken
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, mkdirSync, existsSync, readFileSync, readdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const args = process.argv.slice(2);
const opt = k => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : null; };
const selfTest = args.includes('--self-test');
const SRC = opt('--src') || join(REPO, 'src/aef-workflow-designer.html');
const shotDir = opt('--shots');
const MAP = readFileSync(join(REPO, 'tests/fixtures/t1381/data-stores.bpmn'), 'utf8');
const SERVER = join(HERE, 'gallery-serve.py');
const AUTH = '⚠ This map declares no authority: none of its 5 elements carries one and no lane offers a default ' +
             '(markers summarised here, not drawn per element)';
const WIDTHS = [[1024, 768, { pct: 25 }], [1440, 900, { px: 200 }], [1920, 1080, { px: 182 }]];
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; }

// Everything measured in the page, in one read.
const MEASURE = `(() => {
  const wrap = document.querySelector('.canvas-wrap');
  const ids = ['lane-fix-notice', 'clean-nudge', 'authority-summary'];
  const box = id => { const e = document.getElementById(id); return e && e.style.display !== 'none' ? e : null; };
  const vis = el => { const r = el.getBoundingClientRect(); return r.width > 0 && r.height > 0; };
  const rects = ids.map(box).filter(Boolean).map(e => e.getBoundingClientRect());
  const shapes = [...document.querySelectorAll('#g-pool rect, #g-nodes > g, #g-data > *')].map(e => e.getBoundingClientRect()).filter(r => r.width && r.height);
  const hit = rects.some(a => shapes.some(b => a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom));
  const parts = id => { const e = box(id); if (!e) return null;
    const ps = [...e.querySelectorAll('.notice-part, .notice-head, .notice-rest')];
    const more = e.querySelector('.dock-more');
    return { text: e.querySelector('.clean-nudge-msg').textContent, n: ps.length, shown: ps.filter(vis).length,
             more: more && vis(more) ? more.textContent : null }; };
  const apply = document.getElementById('clean-nudge-apply');
  return { shown: ids.map(box).filter(Boolean).length, pad: parseFloat(wrap.style.paddingTop || '0'), wrapH: wrap.clientHeight,
           wrapW: wrap.clientWidth, hit, notice: parts('lane-fix-notice'), auth: parts('authority-summary'),
           apply: !!(apply && vis(apply)) };
})()`;
const CLICK = id => `(() => { const m = document.querySelector('#${id} .dock-more'); if (!m) return false; m.click(); return true; })()`;

async function run(src, tag) {
  const out = [];
  for (const [W, H, lim] of WIDTHS) {
    const doc = mkdtempSync(join(tmpdir(), 't1384-doc-')); const repo = mkdtempSync(join(tmpdir(), 't1384-repo-'));
    copyFileSync(src, join(doc, 'designer.html'));
    const port = await freePort();
    const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: 'ignore' });
    const udd = makeProfileDir('t1384-udd-');
    const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', `--window-size=${W},${H}`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
    const BASE = `http://127.0.0.1:${port}`;
    try {
      for (let i = 0; i < 100; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
      const cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
      await cmd('Page.enable'); await cmd('Runtime.enable');
      await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
      await cmd('Page.navigate', { url: `${BASE}/designer.html` });
      for (let t0 = Date.now(); Date.now() - t0 < 20000; await sleep(150)) if (await ev(cmd, `typeof adoptImportedXml==='function'&&_appReady===true`).catch(() => false)) break;
      await ev(cmd, `adoptImportedXml(${JSON.stringify(MAP)}, { userImport: true }); openingZoom(); true`); await sleep(900);
      const shot = async name => { if (!shotDir) return; mkdirSync(shotDir, { recursive: true }); const s = await cmd('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(shotDir, name), Buffer.from(s.data, 'base64')); };
      const m = await ev(cmd, MEASURE); await shot(`${tag}-${W}.png`);
      const r = { W, lim, m };
      if (m.wrapW < 700) {   // narrow: open each collapsed notice, then close it again
        const clicked = [await ev(cmd, CLICK('lane-fix-notice')), await ev(cmd, CLICK('authority-summary'))]; await sleep(300);
        r.open = await ev(cmd, MEASURE); r.clicked = clicked; await shot(`${tag}-${W}-open.png`);
        await ev(cmd, CLICK('lane-fix-notice')); await ev(cmd, CLICK('authority-summary')); await sleep(300);
        r.closed = await ev(cmd, MEASURE);
      }
      out.push(r); cl.close();
    } finally { br.kill('SIGKILL'); py.kill(); }
  }
  return out;
}

function legs(rs) {
  const L = [], leg = (id, ok, what) => L.push({ id, ok: !!ok, what });
  const wide = rs.find(r => r.W === 1920)?.m;
  for (const { W, lim, m, open, closed, clicked } of rs) {
    leg(`D4@${W}`, m.shown === 3 && m.notice && m.auth && m.apply, `three advisories visible (${m.shown}), Clean layout button visible`);
    const pct = 100 * m.pad / m.wrapH;
    leg(`D1@${W}`, lim.pct != null ? pct <= lim.pct : m.pad <= lim.px,
        `dock padding ${m.pad}px of ${m.wrapH}px (${pct.toFixed(0)}%), limit ${lim.pct != null ? lim.pct + '%' : lim.px + 'px'}`);
    leg(`D2@${W}`, !m.hit, 'no advisory box over the pool, a node or a data shape');
    leg(`D3-text@${W}`, m.auth && m.auth.text === AUTH && wide && m.notice && m.notice.text === wide.notice.text
        && /not drawn/.test(m.notice.text) && /NOT kept/.test(m.notice.text), 'notice and authority text exactly as before, data-loss lines present');
    if (m.wrapW < 700) {
      const named = x => x && x.shown < x.n && x.more === `▸ ${x.n - x.shown} more`;
      leg(`D3-named@${W}`, named(m.notice) && named(m.auth), `collapsed parts behind a control naming them: notice "${m.notice?.more}" (${m.notice?.shown}/${m.notice?.n}), authority "${m.auth?.more}" (${m.auth?.shown}/${m.auth?.n})`);
      const all = x => x && x.shown === x.n && x.more === '▾ less';
      leg(`D3-open@${W}`, clicked.every(Boolean) && all(open.notice) && all(open.auth) && !open.hit, 'one click shows every part, still off the diagram');
      leg(`D3-close@${W}`, named(closed.notice) && named(closed.auth), 'a second click hides them again');
    } else {
      const full = x => x && x.shown === x.n && x.more == null;
      leg(`D3-full@${W}`, full(m.notice) && full(m.auth), 'wide canvas: every part shown, no control');
    }
  }
  return L;
}
const report = L => { for (const l of L) console.log(`${l.ok ? 'ok  ' : 'FAIL'}  ${l.id.padEnd(14)} ${l.what}`); };

async function main() {
  const live = legs(await run(SRC, 'live')); report(live);
  const failed = live.filter(l => !l.ok);
  if (!selfTest) { console.log(failed.length ? `FAIL — ${failed.length} leg(s)` : `PASS — ${live.length} legs`); process.exit(failed.length ? 1 : 0); }
  if (failed.length) { console.log(`\nFAIL — ${failed.length} live leg(s)`); process.exit(1); }
  const src = readFileSync(SRC, 'utf8');
  const NARROW = 'const DOCK_NARROW_PX = 700;';
  const CLICKH = "  const more = ev.target.closest?.('.clean-nudge .dock-more');\n  if (!more) return;\n";
  if (!src.includes(NARROW) || !src.includes(CLICKH)) { console.log('SELF-TEST INTEGRITY FAIL — a poison target is missing from the editor source'); process.exit(2); }
  const arms = [
    { name: 'A — never collapse', must: 'D1', patched: src.replace(NARROW, 'const DOCK_NARROW_PX = 0;') },
    { name: 'B — the more control does nothing', must: 'D3', patched: src.replace(CLICKH, '  return;\n') },
  ];
  const dir = mkdtempSync(join(tmpdir(), 't1384-poison-'));
  for (const [i, arm] of arms.entries()) {
    const f = join(dir, `poison-${i}.html`); writeFileSync(f, arm.patched);
    console.log(`\npoison arm ${arm.name} — ${arm.must} must FAIL at some width`);
    const pl = legs(await run(f, `poison-${'AB'[i]}`)); report(pl);
    if (!pl.some(l => l.id.startsWith(arm.must) && !l.ok)) { console.log(`\nSELF-TEST FAIL — ${arm.must} passed under poison; it asserts nothing`); process.exit(2); }
  }
  console.log(`\nPASS — ${live.length} legs, and both poison arms caught`);
}
main().catch(e => { console.error(e); process.exit(2); });
