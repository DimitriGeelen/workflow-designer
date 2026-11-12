#!/usr/bin/env node
// T-976 — a map whose file positions none of its nodes is laid out along its flows; any position keeps today's placement.
//
// Fixtures (synthetic, tests/fixtures/t976/): flow-order-no-di.bpmn lists its elements End-first, in two lanes, with a
// branch, a merge and one loop back ("recheck": Reject -> Check). partly-positioned.bpmn is the same map with ONE node
// given an <aef:position>, so the layout must not run there.
//
// Legs, at 1440x900 (the layout is independent of the viewport; screenshots at three widths come from --shots):
//   F1  no-DI map: every flow except the loop back points left to right (source centre x < target centre x)
//   F2  no-DI map: the loop back still points right to left (the measure can see a backward flow at all)
//   F3  no-DI map: no two nodes overlap (rects from state: x, y, dims)
//   F4  no-DI map: every node sits in its declared lane's band (laneAtY of its centre = its lane)
//   P1  partly positioned: today's placement kept, so the flows are NOT all forward (the layout did not run)
//   P2  partly positioned: the positioned node is where the file put it (x 900)
// --self-test also runs the source as it was before T-976 (git HEAD:src, or --before <file>) and requires F1 and F3
// red there: the harness must see the defect it guards against.
import { cdp } from './_cdp-client.mjs';
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { spawn, execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, existsSync, readFileSync, readdirSync, copyFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const args = process.argv.slice(2);
const opt = k => { const i = args.indexOf(k); return i >= 0 ? args[i + 1] : null; };
const selfTest = args.includes('--self-test');
const SRC = opt('--src') || join(REPO, 'src/aef-workflow-designer.html');
const shotDir = opt('--shots');
const FIX = join(REPO, 'tests/fixtures/t976');
const TMPDIRS = [];
const mkTmp = prefix => { const d = mkdtempSync(join(tmpdir(), prefix)); TMPDIRS.push(d); return d; };
process.on('exit', () => { for (const d of TMPDIRS) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} } });
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 30000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; }

const MEASURE = `(() => {
  const N = state.nodes, byUid = new Map(N.map(n => [n.uid, n]));
  const name = u => (byUid.get(u) || {}).name || u;
  const box = n => { const d = dims(n) || { w: 0, h: 0 }; return { l: n.x, t: n.y, r: n.x + d.w, b: n.y + d.h, cx: n.x + d.w / 2, cy: n.y + d.h / 2 }; };
  const flows = state.edges.filter(e => byUid.has(e.source) && byUid.has(e.target)).map(e => {
    const a = box(byUid.get(e.source)), b = box(byUid.get(e.target));
    return { from: name(e.source), to: name(e.target), forward: a.cx < b.cx };
  });
  const overlaps = [];
  for (let i = 0; i < N.length; i++) for (let j = i + 1; j < N.length; j++) {
    const a = box(N[i]), b = box(N[j]);
    if (a.l < b.r && b.l < a.r && a.t < b.b && b.t < a.b) overlaps.push(N[i].name + ' / ' + N[j].name);
  }
  const outOfLane = N.filter(n => laneAtY(box(n).cy) !== n.lane).map(n => n.name);
  const xOf = Object.fromEntries(N.map(n => [n.name, Math.round(n.x)]));
  // F5: a drawn flow (its rendered polyline, diagram units) that passes through a node it does not connect.
  const through = [];
  for (const g of document.querySelectorAll('#g-edges g.edge')) {
    const e = state.edges.find(x => x.id === g.getAttribute('data-id')); const p = g.querySelector('path');
    if (!e || !p) continue;
    const pts = polylineFromPath(p.getAttribute('d'));
    for (const n of N) {
      if (n.uid === e.source || n.uid === e.target) continue;
      const b = box(n), l = b.l + 2, r = b.r - 2, t = b.t + 2, bo = b.b - 2;
      let hit = false;
      for (let i = 1; i < pts.length && !hit; i++) {
        const a = pts[i - 1], c = pts[i], steps = Math.max(1, Math.ceil(Math.hypot(c.x - a.x, c.y - a.y) / 2));
        for (let s = 0; s <= steps && !hit; s++) { const x = a.x + (c.x - a.x) * s / steps, y = a.y + (c.y - a.y) * s / steps; hit = x > l && x < r && y > t && y < bo; }
      }
      if (hit) through.push(name(e.source) + ' -> ' + name(e.target) + ' crosses ' + n.name);
    }
  }
  // F6: two node labels (screen rects) that overlap.
  const labels = [...document.querySelectorAll('#g-nodes .node-label')].map(t => ({ t: t.textContent.trim(), r: t.getBoundingClientRect() })).filter(x => x.r.width && x.r.height);
  const labelHits = [];
  for (let i = 0; i < labels.length; i++) for (let j = i + 1; j < labels.length; j++) {
    const a = labels[i].r, b = labels[j].r;
    if (a.left < b.right - 1 && b.left < a.right - 1 && a.top < b.bottom - 1 && b.top < a.bottom - 1) labelHits.push(labels[i].t + ' / ' + labels[j].t);
  }
  return { flows, overlaps, outOfLane, xOf, through, labelHits, labelCount: labels.length };
})()`;

async function measure(src, fixture, W, H, shot) {
  const doc = mkTmp('t976-doc-'), repo = mkTmp('t976-repo-');
  copyFileSync(src, join(doc, 'designer.html'));
  const MAP = readFileSync(join(FIX, fixture), 'utf8');
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: 'ignore' });
  const udd = makeProfileDir('t976-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', `--window-size=${W},${H}`, '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  const BASE = `http://127.0.0.1:${port}`;
  let cl;
  try {
    for (let i = 0; i < 100; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    const ready = +process.env.CDP_READY_MS || 30000;
    for (let t0 = Date.now(); ; await sleep(150)) {
      if (await ev(cmd, `typeof adoptImportedXml==='function'&&_appReady===true`).catch(() => false)) break;
      if (Date.now() - t0 > ready) throw new Error('editor not ready');
    }
    await ev(cmd, `adoptImportedXml(${JSON.stringify(MAP)}, { userImport: true }); openingZoom(); true`); await sleep(900);
    const m = await ev(cmd, MEASURE);
    if (shot) { mkdirSync(shotDir, { recursive: true }); const s = await cmd('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(shotDir, `${fixture.replace(/\.bpmn$/, '')}-${W}.png`), Buffer.from(s.data, 'base64')); }
    return m;
  } finally { try { cl && cl.close(); } catch (_) {} try { br.kill('SIGKILL'); } catch (_) {} try { py.kill('SIGKILL'); } catch (_) {} }
}

const LOOP = f => f.from === 'Reject and notify' && f.to === 'Check the order';
function judge(noDi, partly) {
  const legs = [], leg = (ok, name, what) => legs.push({ ok, name, what });
  const back = noDi.flows.filter(f => !f.forward && !LOOP(f));
  leg(back.length === 0, 'F1', `no-DI map: flows pointing backwards (loop aside): ${back.length}${back.length ? ' — ' + back.map(f => f.from + ' -> ' + f.to).join('; ') : ''}`);
  const loop = noDi.flows.find(LOOP);
  leg(!!loop && !loop.forward, 'F2', `no-DI map: the loop back (Reject -> Check) still points backwards: ${loop ? !loop.forward : 'loop not found'}`);
  leg(noDi.overlaps.length === 0, 'F3', `no-DI map: overlapping node pairs: ${noDi.overlaps.length}${noDi.overlaps.length ? ' — ' + noDi.overlaps.join('; ') : ''}`);
  leg(noDi.outOfLane.length === 0, 'F4', `no-DI map: nodes outside their lane's band: ${noDi.outOfLane.length}${noDi.outOfLane.length ? ' — ' + noDi.outOfLane.join(', ') : ''}`);
  leg(noDi.through.length === 0, 'F5', `no-DI map: flows drawn through a node they do not connect: ${noDi.through.length}${noDi.through.length ? ' — ' + noDi.through.join('; ') : ''}`);
  leg(noDi.labelCount >= 8 && noDi.labelHits.length === 0, 'F6', `no-DI map: overlapping node labels: ${noDi.labelHits.length} of ${noDi.labelCount} labels${noDi.labelHits.length ? ' — ' + noDi.labelHits.join('; ') : ''}`);
  const pBack = partly.flows.filter(f => !f.forward && !LOOP(f)).length;
  leg(pBack > 0, 'P1', `partly positioned: today's placement kept (flows backwards: ${pBack}, must be > 0)`);
  leg(partly.xOf['Order received'] === 900, 'P2', `partly positioned: the positioned node at x ${partly.xOf['Order received']} (file: 900)`);
  return legs;
}
const report = legs => { for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'}  ${l.name}  ${l.what}`); return legs.every(l => l.ok); };

async function runAll(src, shots) {
  const noDi = await measure(src, 'flow-order-no-di.bpmn', 1440, 900, false);
  const partly = await measure(src, 'partly-positioned.bpmn', 1440, 900, false);
  if (shots && shotDir) for (const [W, H] of [[1024, 768], [1440, 900], [1920, 1080]]) await measure(src, 'flow-order-no-di.bpmn', W, H, true);
  return judge(noDi, partly);
}

async function main() {
  console.log(`order: ${readFileSync(join(FIX, 'flow-order-no-di.bpmn'), 'utf8').match(/<bpmn:(?:task|startEvent|endEvent|exclusiveGateway) id="[^"]+"/g).map(s => s.split('"')[1]).join(' ')}`);
  const live = await runAll(SRC, true);
  const ok = report(live);
  if (!selfTest) { console.log(ok ? `\nPASS — ${live.length} legs` : `\nFAIL — ${live.filter(l => !l.ok).length} leg(s)`); process.exit(ok ? 0 : 1); }
  let before = opt('--before');
  if (!before) {
    before = join(mkTmp('t976-before-'), 'designer.html');
    const rev = opt('--before-rev') || 'e065f7f78';   // the last commit before T-976 touched src
    writeFileSync(before, execFileSync('git', ['-C', REPO, 'show', `${rev}:src/aef-workflow-designer.html`], { maxBuffer: 64 * 1024 * 1024 }));
  }
  console.log('\nbefore T-976 (must be red on F1 and F3):');
  const old = await runAll(before, false);
  report(old);
  const sees = !old.find(l => l.name === 'F1').ok && !old.find(l => l.name === 'F3').ok;
  console.log(sees ? 'control: the old source is red on F1 and F3 (the defect, seen)' : 'control: the old source is NOT red on F1 and F3 — this harness no longer sees the defect');
  // Poison: columns 40 px apart. Nodes then overlap, flows run through nodes and labels collide: F3, F5 and F6 must
  // all go red, or those legs could not tell a crowded layout from a clean one.
  const html = readFileSync(SRC, 'utf8'), anchor = '  const PITCH = 160;';
  if (!html.includes(anchor)) { console.log('SETUP BROKEN: poison anchor not found'); process.exit(2); }
  const poisoned = join(mkTmp('t976-poison-'), 'designer.html'); writeFileSync(poisoned, html.replace(anchor, '  const PITCH = 40;'));
  console.log('\npoison (columns 40 px apart; must be red on F3, F5 and F6):');
  const pz = await runAll(poisoned, false);
  report(pz);
  const bites = ['F3', 'F5', 'F6'].every(k => !pz.find(l => l.name === k).ok);
  console.log(bites ? 'poison: F3, F5 and F6 all red (the crowding legs bite)' : 'poison: NOT all of F3, F5, F6 red — a crowding leg is blind');
  const all = ok && sees && bites;
  console.log(all ? `\nPASS — ${live.length} legs, the control sees the defect, and the poison arm is caught` : `\nFAIL — live ${ok ? 'green' : 'red'}, control ${sees ? 'sees' : 'blind'}, poison ${bites ? 'caught' : 'missed'}`);
  process.exit(all ? 0 : 1);
}
main().catch(e => { console.log('SETUP BROKEN: ' + (e && e.stack || e)); process.exit(2); });
