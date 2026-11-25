// T-1441 — Export and Import → Mermaid and CSV, driven in the real designer (headless Chromium, CDP), on two maps.
//
// Per map:
//   M1 Export → Mermaid downloads a `flowchart LR` with one subgraph per lane, BPMN shapes mapped (event (( )),
//      gateway { }, task [ ]), every flow with its label, and only the syntax subset the parser below handles
//   C1 Export → CSV downloads id,name,type,lane,next,next_labels; Python's csv module reads it back to the same rows
//   R1/R2 round trip: Import → Mermaid / Import → CSV of the file just exported, through the real file chooser,
//      gives back the same step ids, names, types, lanes and flows (with labels)
//   V1/V2 the imported map, saved as BPMN, has no ERROR from tools/validate-workflow.py
//   N1/N2 the import notice names what the format does not carry (positions, step details)
// Teeth: T1441_EDITOR=<the T-1440 designer> fails (no such menu items).
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1441_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const RENDERED = join(ROOT, 'examples', 'aef-processes', 'rendered');
const MAPS = ['arc-lifecycle.bpmn', 'audit-process.bpmn'];
const OUT = process.argv[2] || null;
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1441-doc-')), dl = mkdtempSync(join(tmpdir(), 't1441-dl-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
for (const m of MAPS) copyFileSync(join(RENDERED, m), join(doc, 'rendered', m));
if (OUT) mkdirSync(OUT, { recursive: true });
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1441-');
const br = spawn(chrome, ['--headless=new', '--disable-dev-shm-usage', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
const events = [];
let cl;
// The comparable shape of a map, by PERMANENT identity (aef:uid): steps as uid | name | type | lane, flows as
// uid -> uid : label. The visible ids (lane code + number in the lane + a word) are counted separately: their number
// follows the layout, which Mermaid and CSV do not carry (stated in the import notice), so a change there is reported,
// not failed.
const MODEL = `(function(){ const ln = id => { const l = (state.lanes || []).find(x => x.id === id); return l ? l.name : ''; };
  return { steps: state.nodes.map(n => [n.uid, n.name || '', n.type, ln(n.lane)].join(' | ')).sort(),
           flows: (state.edges || []).map(e => e.source + ' -> ' + e.target + ' : ' + (e.name || '')).sort(),
           ids: Object.fromEntries(state.nodes.map(n => [n.uid, displayIdOf(n)])),
           wid: state.workflowMeta.id, lanes: (state.lanes || []).map(l => l.name),
           usedLanes: (state.lanes || []).filter(l => state.nodes.some(n => n.lane === l.id)).map(l => l.name) }; })()`;
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000, onEvent: m => events.push(m) }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const waitFor = async (pred, ms = 15000) => { const t0 = Date.now(); while (Date.now() - t0 < ms) { const e = events.find(pred); if (e) return e; await sleep(50); } return null; };
  await cmd('Page.enable'); await cmd('Runtime.enable'); await cmd('DOM.enable');
  await cmd('Browser.setDownloadBehavior', { behavior: 'allowAndName', downloadPath: dl, eventsEnabled: true });
  await cmd('Page.setInterceptFileChooserDialog', { enabled: true });
  const exportVia = async fmt => {
    const n0 = events.length;
    await ev(`document.getElementById('btn-export').click(); document.querySelector('#menu-export .tb-menu-item[data-format="${fmt}"]').click(); 1`);
    const done = await waitFor(e => events.indexOf(e) >= n0 && e.method === 'Browser.downloadProgress' && e.params.state === 'completed');
    const begin = done && events.find(e => e.method === 'Browser.downloadWillBegin' && e.params.guid === done.params.guid);
    return done ? { path: join(dl, done.params.guid), text: readFileSync(join(dl, done.params.guid), 'utf8'), name: begin ? begin.params.suggestedFilename : '' } : null;
  };
  const importVia = async (fmt, file) => {
    await ev(`window.alert = m => { window.__alert = String(m); }; window.__alert = ''; 1`);
    const n0 = events.length;
    // A browser opens a file chooser only on a user gesture; a person's click is one, a script's click is not.
    await cmd('Runtime.evaluate', { expression: `document.getElementById('btn-import').click(); document.querySelector('#menu-import .tb-menu-item[data-format="${fmt}"]').click(); 1`, userGesture: true });
    const fc = await waitFor(e => events.indexOf(e) >= n0 && e.method === 'Page.fileChooserOpened', 8000);
    if (!fc) return { chooser: false };
    await cmd('DOM.setFileInputFiles', { files: [file], backendNodeId: fc.params.backendNodeId });
    await sleep(1500);
    return { chooser: true, alert: await ev(`window.__alert`), notice: await ev(`(document.getElementById('lane-fix-msg') || {}).textContent || ''`) };
  };
  for (const MAP of MAPS) {
    const tag = MAP.replace('.bpmn', '');
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP}` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
    await sleep(400);
    const orig = await ev(MODEL);
    const laneCount = await ev(`(state.lanes || []).length`);   // empty lanes are exported too

    // M1 Mermaid
    const mm = await exportVia('mermaid');
    const mt = mm ? mm.text : '';
    if (OUT && mm) writeFileSync(join(OUT, `${tag}.mmd`), mt);
    const subgraphs = (mt.match(/^\s*subgraph /gm) || []).length;
    const edges = (mt.match(/-->/g) || []).length;
    const labelled = orig.flows.filter(f => !f.endsWith(': ')).length;
    const edgeLabels = (mt.match(/-->\|/g) || []).length;
    const okLines = mt.split('\n').every(l => /^\s*$|^flowchart LR$|^\s*%%|^\s*subgraph lane_\w+\[".*"\]$|^\s*end$|^\s*[A-Za-z_]\w*(\(\(".*"\)\)|\{".*"\}|\[".*"\])$|^\s*[A-Za-z_]\w* -->(\|".*"\|)? [A-Za-z_]\w*$/.test(l));
    leg(!!mm && /\.mmd$/.test(mm.name) && mt.startsWith('flowchart LR') && subgraphs === laneCount && edges === orig.flows.length
        && edgeLabels === labelled && okLines && /\(\("/.test(mt) && /\{"/.test(mt) && /\["/.test(mt),
        `M1 [${tag}] Export → Mermaid: flowchart LR, ${laneCount} lane subgraphs, every flow and label, shapes mapped, only the known syntax`,
        `${mm && mm.name}, subgraphs ${subgraphs}, edges ${edges}/${orig.flows.length}, labels ${edgeLabels}/${labelled}, syntax ok ${okLines}`);

    // C1 CSV, read back by Python
    const cs = await exportVia('csv');
    if (OUT && cs) writeFileSync(join(OUT, `${tag}.csv`), cs.text);
    const pyr = cs ? spawnSync('python3', ['-c', 'import csv,json,sys; r=list(csv.reader(open(sys.argv[1], newline="", encoding="utf-8"))); print(json.dumps(r))', cs.path], { encoding: 'utf8' }) : null;
    let rows = []; try { rows = JSON.parse(pyr.stdout); } catch (_) {}
    const head = rows[0] || [];
    const csvSteps = rows.slice(1).map(r => [r[8], r[1], r[2], r[3]].join(' | ')).sort();
    leg(!!cs && /\.csv$/.test(cs.name) && head.join(',') === 'id,name,type,lane,next,next_labels,lane_code,lane_authority,uid' && JSON.stringify(csvSteps) === JSON.stringify(orig.steps),
        `C1 [${tag}] Export → CSV: the header, and Python's csv reads back every step (uid, name, type, lane)`, `${cs && cs.name}, rows ${rows.length - 1}/${orig.steps.length}`);

    // R / V / N for each bridge
    for (const [k, file, n] of [['mermaid', mm && mm.path, 1], ['csv', cs && cs.path, 2]]) {
      const ext = k === 'mermaid' ? 'mmd' : 'csv';
      const named = join(dl, `${tag}.${ext}`); if (file) writeFileSync(named, readFileSync(file));
      const imp = file ? await importVia(k, named) : { chooser: false };
      const back = await ev(MODEL);
      const sameSteps = JSON.stringify(back.steps) === JSON.stringify(orig.steps);
      const sameFlows = JSON.stringify(back.flows) === JSON.stringify(orig.flows);
      const diff = sameSteps && sameFlows ? '' : ` first step diff: ${JSON.stringify(orig.steps.find(x => !back.steps.includes(x)) || back.steps.find(x => !orig.steps.includes(x)) || '')}; BACK: ${JSON.stringify(back.steps.find(x => x.includes((orig.steps.find(y => !back.steps.includes(y)) || "").split(" | ")[1] || "@@")))}; first flow diff: ${JSON.stringify(orig.flows.find(x => !back.flows.includes(x)) || back.flows.find(x => !orig.flows.includes(x)) || '')}`;
      const renum = Object.keys(orig.ids).filter(u => back.ids[u] !== undefined && back.ids[u] !== orig.ids[u]);
      const prefixKept = Object.keys(orig.ids).every(u => back.ids[u] === undefined || back.ids[u].split('_')[0] === orig.ids[u].split('_')[0]);
      // the map keeps its own id; Mermaid brings back every lane (empty ones too), CSV every lane that holds a step
      const wantLanes = k === 'mermaid' ? orig.lanes : orig.usedLanes;
      const lanesOk = JSON.stringify(back.lanes) === JSON.stringify(wantLanes);
      // a map id already open gets _v2, _v3 … (adoptImportedXml's collision rule, as for a second BPMN import)
      const idOk = back.wid === orig.wid || new RegExp('^' + orig.wid.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '_v\\d+$').test(back.wid);
      leg(imp.chooser && !imp.alert && sameSteps && sameFlows && prefixKept && lanesOk && idOk, `R${n} [${tag}] Import → ${k} of that file gives back the same map id, lanes, steps (permanent id, name, type, lane) and flows; lane codes kept`,
          `map id ${back.wid}${idOk ? '' : ' (want ' + orig.wid + ')'}, lanes ${JSON.stringify(back.lanes)}${lanesOk ? '' : ' want ' + JSON.stringify(wantLanes)}, steps ${back.steps.length}/${orig.steps.length}, flows ${back.flows.length}/${orig.flows.length}; visible ids renumbered by the new layout: ${renum.length}${renum.length ? ' (e.g. ' + orig.ids[renum[0]] + ' -> ' + back.ids[renum[0]] + ')' : ''}${imp.alert ? ', alert: ' + imp.alert : ''}${diff}`);
      const xml = await ev(`buildBpmnXml(state)`);
      const xp = join(dl, `${tag}-from-${k}.bpmn`); writeFileSync(xp, xml);
      if (OUT) writeFileSync(join(OUT, `${tag}-from-${k}.bpmn`), xml);
      const val = spawnSync('python3', [join(ROOT, 'tools', 'validate-workflow.py'), xp], { encoding: 'utf8' });
      const vout = (val.stdout || '') + (val.stderr || '');
      const errors = (vout.match(/\bE-[A-Z0-9-]+/g) || []);
      leg(val.status !== 2 && errors.length === 0, `V${n} [${tag}] the map imported from ${k} validates with no ERROR`, vout.split('\n').find(l => /VALID|WARN|INVALID|error/.test(l)) || vout.slice(0, 120));
      leg(/positions/.test(imp.notice || '') && /conditions/.test(imp.notice || '') && /details/.test(imp.notice || '') && new RegExp(k === 'mermaid' ? 'Mermaid' : 'CSV').test(imp.notice || ''),
          `N${n} [${tag}] the import notice names what ${k} does not carry`, (imp.notice || '(no notice)').slice(0, 160));
      await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP}` });
      for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
      await sleep(300);
      await cmd('Page.setInterceptFileChooserDialog', { enabled: true });
    }
  }
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL');
  for (const d of [doc, dl, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
