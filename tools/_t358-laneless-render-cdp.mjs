#!/usr/bin/env node
// _t358-laneless-render-cdp.mjs — T-358 (operator ruling 2026-11-08, AB: drop + mark): a third-party map that declares no
// lanes opens with NO lanes, and the canvas still draws it properly. Before, the importer gave it the 3-lane Authority
// Model (every node in `Human · Sovereignty`). Dropping that left the pool as tall as its header strip, with every node
// drawn below it (seen in the screenshots, 2026-11-08); poolHeight() now encloses the nodes when there are no lanes.
// It opens every lane-less fixture in tests/fixtures/third-party the REAL way (adoptImportedXml with userImport, then
// openingZoom) at 1024, 1440 and 1920, and asserts:
//   L1 no lane: state.lanes is empty and no lane band is drawn;
//   L2 every node (shape and name) lies within the pool outline's height (rect.pool-border), which is what a pool with
//      no lanes must get right. Horizontal overflow is not judged: the pool's left edge does not grow, so a node a file
//      places left of it (nested-subprocesses' start event, x=26) is 4px outside in 0.40.0 too, lanes or not;
//   L3 the save has no <bpmn:laneSet>, no 'sovereignty', and laneProvenance on aef:workflowMeta;
//   L4 (pool half, operator ruling 2026-11-09, AB) the save writes no invented <bpmn:participant>/<bpmn:collaboration>
//      unless the source's own content needs the collaboration (multiple-diagrams: a second process), always marks
//      poolProvenance="defaulted:no-participant", and a re-open of the save still knows (state.poolDeclared false);
//      a source that DOES declare its pool (collaboration-message-flows) keeps it, unmarked — the negative control;
//   L0 setup: the map has nodes and the pool outline exists.
// --self-test adds three poisoned copies of the designer, each must fail: A puts the fabrication back (L1, L3 red);
// B removes the no-lane pool height (L2 red); C writes the invented collaboration again (L4 red).
// Usage:  node tools/_t358-laneless-render-cdp.mjs [--self-test] [--src FILE] [--shots DIR]
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
const SERVER = join(HERE, 'gallery-serve.py');
const WIDTHS = [[1024, 768], [1440, 900], [1920, 1080]];
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; }


const FIXDIR = join(REPO, 'tests/fixtures/third-party');
const MAPS = readdirSync(FIXDIR).filter(f => f.endsWith('.bpmn')).sort()
  .filter(f => !/<(?:[A-Za-z0-9_]+:)?laneSet\b/.test(readFileSync(join(FIXDIR, f), 'utf8')));

const MEASURE = `(() => {
  const pool = document.querySelector('#g-pool rect.pool-border'); const p = pool ? pool.getBoundingClientRect() : null;
  const nodes = [...document.querySelectorAll('#g-nodes > g')].map(e => ({ r: e.getBoundingClientRect(), id: e.getAttribute('data-id') || '' }))
    .filter(x => x.r.width && x.r.height);
  const outside = p ? nodes.filter(x => x.r.top < p.top - 1 || x.r.bottom > p.bottom + 1)
    .map(x => x.id || Math.round(x.r.left) + ',' + Math.round(x.r.top)) : null;
  const out = buildBpmnXml(state).replace(/<!--[\\s\\S]*?-->/g, '');
  const wm = (out.match(/<aef:workflowMeta [^>]*>/) || [''])[0];
  return { lanes: (state.lanes || []).length, bands: document.querySelectorAll('#g-pool .lane-bg').length,
           nodes: nodes.length, pool: !!p, outside,
           laneSet: /<bpmn:laneSet\b/.test(out), sov: /sovereignty/.test(out),
           marker: (wm.match(/laneProvenance="([^"]*)"/) || [null, null])[1],
           parts: (out.match(/<bpmn:participant\\b/g) || []).length, keepsCollab: !!(state.collab || ((typeof processLevelKeptOut === 'function') && (processLevelKeptOut(state).collabArtifacts || []).length)),
           poolMark: (wm.match(/poolProvenance="([^"]*)"/) || [null, null])[1],
           reDeclared: (function(){ var m2 = parseBpmnXml(out); return m2 ? m2.poolDeclared : 'reparse-failed'; })() };
})()`;

async function run(src, tag) {
  const res = [];
  for (const f of MAPS) for (const [W, H] of WIDTHS) {
    const MAP = readFileSync(join(FIXDIR, f), 'utf8');
    const doc = mkdtempSync(join(tmpdir(), 't358r-doc-')); const repo = mkdtempSync(join(tmpdir(), 't358r-repo-'));
    copyFileSync(src, join(doc, 'designer.html'));
    const port = await freePort();
    const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: 'ignore' });
    const udd = makeProfileDir('t358r-udd-');
    const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', `--window-size=${W},${H}`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
    const BASE = `http://127.0.0.1:${port}`;
    let cl;
    try {
      for (let i = 0; i < 100; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
      cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
      await cmd('Page.enable'); await cmd('Runtime.enable');
      await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
      await cmd('Page.navigate', { url: `${BASE}/designer.html` });
      for (let t0 = Date.now(); Date.now() - t0 < 30000; await sleep(150)) if (await ev(cmd, `typeof adoptImportedXml==='function'&&_appReady===true`).catch(() => false)) break;
      await ev(cmd, `adoptImportedXml(${JSON.stringify(MAP)}, { userImport: true }); openingZoom(); true`); await sleep(900);
      const m = await ev(cmd, MEASURE);
      if (shotDir && tag === 'live') { mkdirSync(shotDir, { recursive: true }); const s = await cmd('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(shotDir, `${f.replace(/\.bpmn$/, '')}-${W}.png`), Buffer.from(s.data, 'base64')); }
      res.push({ f, W, m, declaresPool: /<(?:[A-Za-z0-9_]+:)?participant\b/.test(MAP) });
    } catch (e) { res.push({ f, W, err: String(e && e.message || e).slice(0, 300) }); }
    finally { try { cl && cl.close(); } catch (_) {} try { br.kill('SIGKILL'); } catch (_) {} try { py.kill('SIGKILL'); } catch (_) {} }
  }
  return res;
}

function judge(res) {
  const legs = [];
  const leg = (ok, name, what) => legs.push({ ok, name, what });
  for (const { f, W, m, err, declaresPool } of res) {
    const k = `${f.replace(/\.bpmn$/, '')}@${W}`;
    if (err || !m) { leg(false, 'L0 ' + k, 'setup: ' + (err || 'no measurement')); continue; }
    leg(m.nodes > 0 && m.pool, 'L0 ' + k, `setup: ${m.nodes} node(s) drawn, pool outline ${m.pool ? 'present' : 'MISSING'}`);
    leg(m.lanes === 0 && m.bands === 0, 'L1 ' + k, `no lane: state ${m.lanes}, bands drawn ${m.bands}`);
    leg(Array.isArray(m.outside) && m.outside.length === 0, 'L2 ' + k, `every node within the pool's height` + (m.outside && m.outside.length ? ` — ${m.outside.length} outside: ${m.outside.slice(0, 4).join(' ')}` : ''));
    leg(!m.laneSet && !m.sov && /^defaulted:/.test(m.marker || ''), 'L3 ' + k, `save: laneSet ${m.laneSet}, sovereignty ${m.sov}, marker ${m.marker}`);
    if (declaresPool) leg(m.parts > 0 && m.poolMark === null && m.reDeclared === true, 'L4 ' + k,
        `the source declares its pool: kept (${m.parts} participant(s)), unmarked (${m.poolMark}), re-open poolDeclared ${m.reDeclared}`);
    else leg((m.parts === 0 || m.keepsCollab) && m.poolMark === 'defaulted:no-participant' && m.reDeclared === false, 'L4 ' + k,
        `save: ${m.parts} participant(s)${m.keepsCollab ? ' (the source\'s collaboration content needs one)' : ''}, poolProvenance ${m.poolMark}, re-open poolDeclared ${m.reDeclared}`);
  }
  return legs;
}
const report = legs => { for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'}  ${l.name.padEnd(42)} ${l.what}`); return legs.every(l => l.ok); };

async function main() {
  if (!MAPS.length) { console.log('SETUP BROKEN: no lane-less fixture in tests/fixtures/third-party'); process.exit(2); }
  console.log(`lane-less fixtures: ${MAPS.join(', ')}`);
  const live = judge(await run(SRC, 'live'));
  const ok = report(live);
  if (!selfTest) { console.log(ok ? `\nPASS — ${live.length} legs` : `\nFAIL — ${live.filter(l => !l.ok).length} leg(s)`); process.exit(ok ? 0 : 1); }
  const html = readFileSync(SRC, 'utf8');
  const POISON = {
    'A (the fabrication is back)': ["  const carriedLaneProv = aefMetaEl && aefMetaEl.getAttribute('laneProvenance');",
      "  const carriedLaneProv = aefMetaEl && aefMetaEl.getAttribute('laneProvenance');\n  if (!lanes.length) lanes.push(...defaultLanes());", /^L[13] /],
    'B (no-lane pool height removed)': ["  if (lanes.length) return POOL_HEADER + lanes.reduce((s, l) => s + l.height, 0);",
      "  return POOL_HEADER + lanes.reduce((s, l) => s + l.height, 0);", /^L2 /],
    'C (the invented collaboration is written again)': ["  if (s.poolDeclared === false && !s.collab && !(pkOut.collabArtifacts || []).length) lines.splice(collabStart, lines.length - collabStart);",
      "", /^L4 /],
  };
  let caught = 0;
  for (const [name, [a, b, want]] of Object.entries(POISON)) {
    if (!html.includes(a)) { console.log(`SETUP BROKEN: poison ${name} anchor not found`); process.exit(2); }
    const p = join(mkdtempSync(join(tmpdir(), 't358r-poison-')), 'designer.html'); writeFileSync(p, html.replace(a, b));
    const legs = judge(await run(p, 'poison'));
    const red = legs.filter(l => !l.ok && want.test(l.name));
    console.log(`poison ${name}: ${red.length ? `caught (${red.length} ${want.source.replace(/[\^\\[\] ]/g, '')} leg(s) red)` : 'NOT caught'}`);
    if (red.length) caught++;
  }
  const all = ok && caught === Object.keys(POISON).length;  // T-358 pool half: three arms
  console.log(all ? `\nPASS — ${live.length} legs, and all ${caught} poison arms caught` : `\nFAIL — live ${ok ? 'green' : 'red'}, ${caught}/${Object.keys(POISON).length} poison arms caught`);
  process.exit(all ? 0 : 1);
}
main().catch(e => { console.log('SETUP BROKEN: ' + (e && e.stack || e)); process.exit(2); });
