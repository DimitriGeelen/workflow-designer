// T-1503 (T-1491 GO, slice D) — phases on or off, and each phase row on or off, as a view for this map in this browser
// (never written to the file). Greenfield's sample ('Fase' Category_fase with dividers, 'Fase in Salesforce'
// Category_sf above it):
//
//   V1 the Settings switch "Show phases" (shown because the map has phases) hides every bracket, name, row label and
//      divider; switched back, all return
//   V2 hiding row 'Fase in Salesforce' (its switch in Settings) leaves row 1 with its 4 dividers, in place; hiding row
//      'Fase' instead removes its dividers and moves row 2 down into row 1's place
//   V3 the row panel's "Visible on the map" switch hides and shows its row
//   V4 the choice is restored when the same map is opened again in this browser; another map (the starter) shows no
//      phases switch (it has no phases) and a third map with phases is unaffected
//   V5 never written: the save is byte-identical with phases shown, all hidden, and one row hidden
// Teeth: T1503_EDITOR=<a designer before T-1503> fails V1.  T1503_SHOTS=<dir>: settings and hidden-row shots
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1503_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const FIXTURE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1503-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
// what the phase layer draws: rows (by label), phases per row, dividers, and each row's bracket line y
const DRAWN = `(function(){ var g = document.getElementById('g-phases');
  var rows = {}; Array.from(g.querySelectorAll('g[data-phase]')).forEach(function(p){ var r = p.getAttribute('data-phase-row'); var b = p.querySelector('path').getBBox();
    (rows[r] = rows[r] || { n: 0, y: Math.round(b.y) }).n++; });
  return { labels: Array.from(g.querySelectorAll('text.phase-row-label')).map(function(t){ return t.textContent; }),
           rows: rows, dividers: g.querySelectorAll('line.phase-divider').length, nodes: g.childNodes.length }; })()`;
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1503-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--disable-dev-shm-usage', '--no-sandbox', '--disable-gpu', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  const load = async (clear) => {
    for (const pass of clear ? [0, 1] : [1]) {
      await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
      for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
      if (!pass) await ev(`(function(){ try { localStorage.clear(); sessionStorage.clear(); } catch (e) {} return true; })()`);
    }
  };
  const xml = readFileSync(FIXTURE, 'utf8');
  const importIt = x => ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); if (typeof syncSettingsUI === 'function') syncSettingsUI(); return state.workflowMeta.id; })(${JSON.stringify(x)})`);
  // a click on a settings checkbox, as a person (dispatching the change the way the browser does)
  const toggle = sel => ev(`(function(){ var c = document.querySelector(${JSON.stringify(sel)}); if (!c) return false; c.click(); return true; })()`);
  await load(true);
  const id = await importIt(xml);
  const before = await ev(`buildBpmnXml(state)`);
  const d0 = await ev(DRAWN);
  const grpShown = await ev(`(function(){ var g = document.getElementById('set-phases-group'); return !!g && !g.hidden; })()`);
  // V1
  const t1 = await toggle('#set-show-phases');
  const d1 = await ev(DRAWN);
  const savedHidden = await ev(`buildBpmnXml(state)`);
  await toggle('#set-show-phases');
  const d1b = await ev(DRAWN);
  leg(grpShown && t1 && d0.labels.length === 2 && d0.dividers === 4 && d1.nodes === 0 && JSON.stringify(d1b) === JSON.stringify(d0),
    `V1 Settings "Show phases" hides every bracket, name, row label and divider, and shows them again`,
    JSON.stringify({ grpShown, t1, before: d0.nodes, hidden: d1.nodes, back: d1b.nodes }));
  // V2
  await toggle('[data-phase-row="Category_sf"]');
  const d2 = await ev(DRAWN);
  const savedRowHidden = await ev(`buildBpmnXml(state)`);
  await toggle('[data-phase-row="Category_sf"]');
  await toggle('[data-phase-row="Category_fase"]');
  const d3 = await ev(DRAWN);
  await toggle('[data-phase-row="Category_fase"]');
  leg(JSON.stringify(d2.labels) === '["Fase"]' && d2.dividers === 4 && d2.rows['0'] && d2.rows['0'].y === d0.rows['0'].y && !d2.rows['1']
      && JSON.stringify(d3.labels) === '["Fase in Salesforce"]' && d3.dividers === 0 && d3.rows['0'] && d3.rows['0'].y === d0.rows['0'].y && d3.rows['0'].n === 6,
    `V2 hiding 'Fase in Salesforce' keeps 'Fase' and its 4 dividers in place; hiding 'Fase' drops its dividers and moves the other row down`,
    JSON.stringify({ d2: [d2.labels, d2.dividers], d3: [d3.labels, d3.dividers, d3.rows] }).slice(0, 220));
  // V3
  await ev(`(function(){ selection = { kind: 'phaseRow', id: 'Category_sf' }; renderAll(); return true; })()`);
  const t3 = await toggle('[data-testid="phase-row-visible"] input');
  const d4 = await ev(DRAWN);
  await toggle('[data-testid="phase-row-visible"] input');
  const d5 = await ev(DRAWN);
  leg(t3 && JSON.stringify(d4.labels) === '["Fase"]' && JSON.stringify(d5.labels) === JSON.stringify(d0.labels),
    `V3 the row panel's "Visible on the map" hides and shows its row`, JSON.stringify([t3, d4.labels, d5.labels]));
  // V4: hide row 2, reload, open the same map: still hidden; the starter has no phases switch; another map unaffected
  await toggle('[data-phase-row="Category_sf"]');
  await load(false);
  const starterGrp = await ev(`(function(){ syncSettingsUI(); var g = document.getElementById('set-phases-group'); return !!g && !g.hidden; })()`);
  await importIt(xml);
  const d6 = await ev(DRAWN);
  // another map: the same sample under another process id (the map's id derives from it)
  const other = xml.replace(/Process_Nooteboom/g, 'Process_Other_Map');
  await importIt(other);
  const d7 = await ev(DRAWN);
  leg(starterGrp === false && JSON.stringify(d6.labels) === '["Fase"]' && d7.labels.length === 2,
    `V4 the choice comes back with the same map after a reload; the starter shows no phases switch; another map is unaffected`,
    JSON.stringify({ starterGrp, same: d6.labels, other: d7.labels }));
  // V5
  leg(before === savedHidden && before === savedRowHidden, `V5 never written: the save is byte-identical with phases shown, all hidden, one row hidden (${before.length} chars)`);
  if (process.env.T1503_SHOTS) {
    mkdirSync(process.env.T1503_SHOTS, { recursive: true });
    await load(true);
    await importIt(xml);
    await ev(`(function(){ if (typeof openingZoom === 'function') openingZoom(); return true; })()`);   // the opening view, readable
    for (const W of [1024, 1440, 1920]) {
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
      await ev(`(function(){ var b = document.getElementById('btn-settings'); if (b) b.click(); syncSettingsUI();
        var g = document.getElementById('set-phases-group'); if (g) g.scrollIntoView({ block: 'center' }); return true; })()`);
      await sleep(400);
      let s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1503_SHOTS, `settings-phases-${W}.png`), Buffer.from(s.data, 'base64'));
      await toggle('[data-phase-row="Category_sf"]');
      await ev(`(function(){ var b = document.getElementById('btn-close-settings'); if (b) b.click(); return true; })()`);
      await sleep(400);
      s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1503_SHOTS, `row-hidden-${W}.png`), Buffer.from(s.data, 'base64'));
      await toggle('[data-phase-row="Category_sf"]');
    }
  }
  void id;
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
