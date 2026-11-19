// T-1438 screenshots (docs/reports/T-1438-shots/): overview and selected at 1024/1440/1920, and the picker. Setup from
// tools/_t1438-instance-counts-cdp.mjs. — the instance overlay's overview: "● N" on each step holding N live instances, with none selected.
// Real designer, headless Chromium (CDP), static server; the snapshot is served at api/instances (python http.server
// ignores the query string), written from the map's own step ids so the expected counts are the fixture's, not the
// designer's.
//
// Legs (PASS/FAIL each; exit 0 only if all pass):
//   C1 with none selected, each step holding N >= 1 NODE instances shows "● N", its title lists those task ids, and no
//      other step shows a count (3 steps: 3, 2, 1 instances)
//   C2 STALE and NO-POSITION instances put no count on the map; the picker's first line says "· 6 on steps"
//   C3 selecting an instance hides every count and draws its overlay ([data-instance] present); clearing brings them back
//   C4 the counts write nothing to the map: buildBpmnXml identical before / with counts. A picture export shows what the
//      screen shows (as the single-instance overlay always has, T-1440): the export carries the 3 count pills
// Teeth: T1438_EDITOR=dist/aef-workflow-designer-0.44.0.html ... --expect-red: C1 and C2 must fail there.
import { readFileSync, writeFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, mkdirSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir } from '../../../tools/_cdp-profile.mjs';
import { pageWsUrl } from '../../../tools/_cdp-attach.mjs';
import { cdp } from '../../../tools/_cdp-client.mjs';

const HERE = dirname(fileURLToPath(import.meta.url)), ROOT = resolve(HERE, '../../..');
const EDITOR = process.env.T1438_EDITOR ? resolve(ROOT, process.env.T1438_EDITOR) : join(ROOT, 'src', 'aef-workflow-designer.html');
const MAP = join(ROOT, 'examples', 'aef-processes', 'rendered', 'inception-lifecycle.bpmn');
const EXPECT_RED = process.argv.includes('--expect-red');
const sleep = ms => new Promise(r => setTimeout(r, ms));
const results = {};
const leg = (k, ok, name, detail) => { results[k] = ok; console.log(`${ok ? 'PASS' : 'FAIL'}  ${k} ${name}${detail ? '  ' + detail : ''}`); };

const doc = mkdtempSync(join(tmpdir(), 't1438-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
mkdirSync(join(doc, 'm')); copyFileSync(MAP, join(doc, 'm', 'il.bpmn'));
mkdirSync(join(doc, 'api'));
writeFileSync(join(doc, 'api', 'instances'), JSON.stringify({ template: 'x', state: 'NO-INSTANCES', examined: 0, instances: [], refusals: [] }));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1438-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl, harnessError = null;
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  await cmd('Page.enable'); await cmd('Runtime.enable');
  await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=m/il.bpmn` });
  for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
  await sleep(500);
  // the snapshot, from the map's own steps: 3 on the first task-like step, 2 on the second, 1 on the third; plus noise
  const ids = await ev(`state.nodes.filter(n => !/Event$/.test(n.type)).map(n => displayIdOf(n)).slice(0, 4)`);
  if (ids.length < 4) throw new Error('the map has fewer than 4 steps: ' + JSON.stringify(ids));
  const tpl = await ev(`state.workflowMeta.id`);
  const want = { [ids[0]]: ['T-9001', 'T-9002', 'T-9003'], [ids[1]]: ['T-9004', 'T-9005'], [ids[2]]: ['T-9006'] };
  const instances = [];
  for (const [node, tasks] of Object.entries(want)) for (const t of tasks) instances.push({ task: t, state: 'NODE', node, status: 'started-work', owner: 'agent' });
  instances.push({ task: 'T-9007', state: 'STALE', node: 'gone_node', status: 'started-work' });
  instances.push({ task: 'T-9008', state: 'NO-POSITION', status: 'captured' });
  writeFileSync(join(doc, 'api', 'instances'), JSON.stringify({ template: tpl, state: 'INSTANCES', examined: 8, instances, refusals: [] }));
  const shot = async (name, clip) => { const r = await cmd('Page.captureScreenshot', { format: 'png', ...(clip ? { clip: { ...clip, scale: 2 } } : {}) }); writeFileSync(join(HERE, name), Buffer.from(r.data, 'base64')); console.log('wrote', name); };
  for (const [w, h] of [[1024, 768], [1440, 900], [1920, 1080]]) {
    await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false });
    await ev(`(async()=>{ await loadInstanceSnapshot(); selectInstance(null); renderAll(); zoomFactor = null; applyCanvasZoom(); if (typeof openingZoom==='function') openingZoom(); zoomFactor = null; applyCanvasZoom(); await new Promise(r=>setTimeout(r,400)); })()`);
    await shot(`${w}-overview.png`);
    await ev(`(async()=>{ selectInstance('T-9004'); renderAll(); await new Promise(r=>setTimeout(r,300)); })()`);
    await shot(`${w}-selected.png`);
    await ev(`(async()=>{ selectInstance(null); renderAll(); await new Promise(r=>setTimeout(r,200)); })()`);
  }
  // close-ups at 100% (1440 wide): each counted step with its neighbours, so the pill is judged at its real size
  await cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await ev(`(async()=>{ selectInstance(null); renderAll(); setZoom(1); await new Promise(r=>setTimeout(r,300)); })()`);
  for (const [k, node] of Object.keys(want).entries()) {
    const b = await ev(`(async()=>{ const n = state.nodes.find(x => displayIdOf(x) === ${JSON.stringify(node)}); const g = document.querySelector('#g-nodes g[data-id="' + n.id + '"]');
      g.scrollIntoView({ block: 'center', inline: 'center' }); await new Promise(r=>setTimeout(r,250)); const r = g.getBoundingClientRect(); return { x: r.left, y: r.top, w: r.width, h: r.height }; })()`);
    await shot(`closeup-${k + 1}-${node}.png`, { x: Math.max(0, b.x - 160), y: Math.max(0, b.y - 90), width: b.w + 320, height: b.h + 180 });
  }
  const r = await ev(`(function(){ const b = document.getElementById('instancePicker').getBoundingClientRect(); return { x: b.left - 4, y: b.top - 4, width: b.width + 8, height: b.height + 8 }; })()`);
  await shot('picker.png', r);
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL');
  for (const d of [doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  process.exit(0);
}
