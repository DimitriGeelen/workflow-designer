// T-1442 — Export and Import → Excel (.xlsx), driven in the real designer (headless Chromium, CDP), on two maps.
//
// Per map:
//   X1 Export → Excel downloads a .xlsx; an independent reader (Python's zipfile + ElementTree, and openpyxl when it is
//      installed) finds one sheet "Steps" whose rows are exactly the rows the CSV export gives for the same map
//   R1 round trip: Import → Excel of that file, through the real file chooser, gives back the same map id, lanes that
//      hold a step, steps (permanent id, name, type, lane) and flows with labels
//   V1 the imported map, saved as BPMN, has no ERROR from tools/validate-workflow.py
//   N1 the import notice says Excel and names what it does not carry (positions, conditions, details)
// Once:
//   F1 a workbook NOT written by us (tests/fixtures/xlsx/arc-lifecycle-libreoffice.xlsx: made with openpyxl, a first
//      sheet "Notes" without an id column, the step table on sheet 2 "Process" with its columns in another order and an
//      extra numeric column, then re-saved by LibreOffice: shared strings, numbers) imports to the same steps and flows
//   E1 a file that is not a zip (a CSV renamed .xlsx) is refused with an alert naming why; the open map is unchanged
//   E2 a workbook with no sheet holding an "id" column (tests/fixtures/xlsx/no-id-column.xlsx) is refused the same way
// Teeth: T1442_EDITOR=<the 0.44.0 designer> fails (no Excel menu items).
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
const EDITOR = process.env.T1442_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const RENDERED = join(ROOT, 'examples', 'aef-processes', 'rendered');
const FIX = join(ROOT, 'tests', 'fixtures', 'xlsx');
const MAPS = ['arc-lifecycle.bpmn', 'audit-process.bpmn'];
const OUT = process.argv[2] || null;
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

// The independent reader: stdlib only (zipfile + ElementTree), so it runs wherever python3 does; openpyxl on top when
// importable. Prints {"sheets": [...], "rows": [[...]], "openpyxl": rows-or-null}.
const PY_READ = String.raw`
import json, sys, zipfile, xml.etree.ElementTree as ET
N = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
z = zipfile.ZipFile(sys.argv[1])
wb = ET.fromstring(z.read('xl/workbook.xml'))
sheets = [s.get('name') for s in wb.iter(N + 'sheet')]
ws = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
rows = []
for r in ws.iter(N + 'row'):
    rows.append([''.join(t.text or '' for t in c.iter(N + 't')) for c in r.iter(N + 'c')])
op = None
try:
    import openpyxl
    w = openpyxl.load_workbook(sys.argv[1])
    op = [[('' if v is None else str(v)) for v in row] for row in w['Steps'].iter_rows(values_only=True)]
except ImportError:
    op = None
print(json.dumps({'sheets': sheets, 'rows': rows, 'openpyxl': op}))
`;
const PY_CSV = 'import csv,json,sys; print(json.dumps(list(csv.reader(open(sys.argv[1], newline="", encoding="utf-8")))))';

const doc = mkdtempSync(join(tmpdir(), 't1442-doc-')), dl = mkdtempSync(join(tmpdir(), 't1442-dl-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered'));
for (const m of MAPS) copyFileSync(join(RENDERED, m), join(doc, 'rendered', m));
if (OUT) mkdirSync(OUT, { recursive: true });
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1442-');
const br = spawn(chrome, ['--headless=new', '--disable-dev-shm-usage', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
const events = [];
let cl;
// The comparable shape of a map, by PERMANENT identity (aef:uid), as in _t1441: visible ids follow the new layout.
const MODEL = `(function(){ const ln = id => { const l = (state.lanes || []).find(x => x.id === id); return l ? l.name : ''; };
  return { steps: state.nodes.map(n => [n.uid, n.name || '', n.type, ln(n.lane)].join(' | ')).sort(),
           flows: (state.edges || []).map(e => e.source + ' -> ' + e.target + ' : ' + (e.name || '')).sort(),
           wid: state.workflowMeta.id, n: state.nodes.length,
           usedLanes: (state.lanes || []).filter(l => state.nodes.some(n => n.lane === l.id)).map(l => l.name) }; })()`;
const firstDiff = (a, b) => JSON.stringify(a.find(x => !b.includes(x)) || b.find(x => !a.includes(x)) || '');
try {
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000, onEvent: m => events.push(m) }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const waitFor = async (pred, ms = 15000) => { const t0 = Date.now(); while (Date.now() - t0 < ms) { const e = events.find(pred); if (e) return e; await sleep(50); } return null; };
  await cmd('Page.enable'); await cmd('Runtime.enable'); await cmd('DOM.enable');
  await cmd('Browser.setDownloadBehavior', { behavior: 'allowAndName', downloadPath: dl, eventsEnabled: true });
  const open = async MAP => {
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP}` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true&&state.nodes.length>0`).catch(() => false)) break; await sleep(150); }
    await sleep(400);
    await cmd('Page.setInterceptFileChooserDialog', { enabled: true });
  };
  const exportVia = async fmt => {
    const n0 = events.length;
    const has = await ev(`document.getElementById('btn-export').click(); !!document.querySelector('#menu-export .tb-menu-item[data-format="${fmt}"]')`);
    if (!has) return null;
    await ev(`document.querySelector('#menu-export .tb-menu-item[data-format="${fmt}"]').click(); 1`);
    const done = await waitFor(e => events.indexOf(e) >= n0 && e.method === 'Browser.downloadProgress' && e.params.state === 'completed');
    const begin = done && events.find(e => e.method === 'Browser.downloadWillBegin' && e.params.guid === done.params.guid);
    return done ? { path: join(dl, done.params.guid), name: begin ? begin.params.suggestedFilename : '' } : null;
  };
  const importVia = async (fmt, file) => {
    await ev(`window.alert = m => { window.__alert = String(m); }; window.__alert = ''; 1`);
    const n0 = events.length;
    const has = await ev(`document.getElementById('btn-import').click(); !!document.querySelector('#menu-import .tb-menu-item[data-format="${fmt}"]')`);
    if (!has) return { chooser: false };
    // A browser opens a file chooser only on a user gesture; a person's click is one, a script's click is not.
    await cmd('Runtime.evaluate', { expression: `document.querySelector('#menu-import .tb-menu-item[data-format="${fmt}"]').click(); 1`, userGesture: true });
    const fc = await waitFor(e => events.indexOf(e) >= n0 && e.method === 'Page.fileChooserOpened', 8000);
    if (!fc) return { chooser: false };
    await cmd('DOM.setFileInputFiles', { files: [file], backendNodeId: fc.params.backendNodeId });
    await sleep(2000);
    return { chooser: true, alert: await ev(`window.__alert`), notice: await ev(`(document.getElementById('lane-fix-msg') || {}).textContent || ''`) };
  };
  let arcOrig = null, arcCsv = null;
  for (const MAP of MAPS) {
    const tag = MAP.replace('.bpmn', '');
    await open(MAP);
    const orig = await ev(MODEL);
    if (tag === 'arc-lifecycle') arcOrig = orig;

    // X1: the CSV export is the reference table; the .xlsx must hold exactly its rows
    const cs = await exportVia('csv');
    const csvRows = cs ? JSON.parse(spawnSync('python3', ['-c', PY_CSV, cs.path], { encoding: 'utf8' }).stdout || '[]') : [];
    if (cs && tag === 'arc-lifecycle') { arcCsv = join(dl, 'arc-lifecycle.csv'); writeFileSync(arcCsv, readFileSync(cs.path)); }
    const xl = await exportVia('xlsx');
    if (OUT && xl) writeFileSync(join(OUT, `${tag}.xlsx`), readFileSync(xl.path));
    if (OUT && cs) writeFileSync(join(OUT, `${tag}.csv`), readFileSync(cs.path));
    let rd = null, rdErr = '';
    const named = join(dl, `${tag}.xlsx`); if (xl) writeFileSync(named, readFileSync(xl.path));   // openpyxl goes by the extension
    if (xl) { const r = spawnSync('python3', ['-c', PY_READ, named], { encoding: 'utf8' }); try { rd = JSON.parse(r.stdout); } catch (_) { rdErr = (r.stderr || '').trim().split('\n').pop(); } }
    const sameRows = rd && JSON.stringify(rd.rows) === JSON.stringify(csvRows);
    const opOk = rd && (rd.openpyxl === null || JSON.stringify(rd.openpyxl) === JSON.stringify(csvRows));
    leg(!!xl && /\.xlsx$/.test(xl.name) && rd && JSON.stringify(rd.sheets) === '["Steps"]' && csvRows.length > 1 && sameRows && opOk,
        `X1 [${tag}] Export → Excel: one sheet "Steps" holding exactly the CSV export's rows (stdlib reader${rd && rd.openpyxl !== null ? ' and openpyxl' : ''})`,
        `${xl ? xl.name : 'no download (no Excel menu item?)'}, sheets ${rd ? JSON.stringify(rd.sheets) : '-'}, rows ${rd ? rd.rows.length : 0}/${csvRows.length}` +
        `${rd && !sameRows ? ', first row diff: ' + firstDiff(rd.rows.map(r => r.join(',')), csvRows.map(r => r.join(','))) : ''}${rd && !opOk ? ', openpyxl differs' : ''}${rdErr ? ', reader: ' + rdErr : ''}`);

    // R1 / V1 / N1
    const imp = xl ? await importVia('xlsx', named) : { chooser: false };
    const back = await ev(MODEL);
    const idOk = back.wid === orig.wid || new RegExp('^' + orig.wid.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '_v\\d+$').test(back.wid);
    const sameSteps = JSON.stringify(back.steps) === JSON.stringify(orig.steps), sameFlows = JSON.stringify(back.flows) === JSON.stringify(orig.flows);
    const lanesOk = JSON.stringify(back.usedLanes) === JSON.stringify(orig.usedLanes);
    leg(imp.chooser && !imp.alert && idOk && sameSteps && sameFlows && lanesOk,
        `R1 [${tag}] Import → Excel of that file gives back the same map id, lanes, steps (permanent id, name, type, lane) and flows with labels`,
        `map id ${back.wid}, lanes ${back.usedLanes.length}/${orig.usedLanes.length}, steps ${back.steps.length}/${orig.steps.length}, flows ${back.flows.length}/${orig.flows.length}` +
        `${imp.alert ? ', alert: ' + imp.alert : ''}${sameSteps ? '' : ', step diff ' + firstDiff(orig.steps, back.steps)}${sameFlows ? '' : ', flow diff ' + firstDiff(orig.flows, back.flows)}${imp.chooser ? '' : ', no file chooser (no Excel menu item?)'}`);
    const xml = await ev(`buildBpmnXml(state)`);
    const xp = join(dl, `${tag}-from-xlsx.bpmn`); writeFileSync(xp, xml);
    if (OUT) writeFileSync(join(OUT, `${tag}-from-xlsx.bpmn`), xml);
    const val = spawnSync('python3', [join(ROOT, 'tools', 'validate-workflow.py'), xp], { encoding: 'utf8' });
    const vout = (val.stdout || '') + (val.stderr || '');
    const errors = vout.match(/\bE-[A-Z0-9-]+/g) || [];
    leg(imp.chooser && val.status !== 2 && errors.length === 0, `V1 [${tag}] the map imported from Excel validates with no ERROR`, vout.split('\n').find(l => /VALID|WARN|INVALID|error/.test(l)) || vout.slice(0, 120));
    leg(/Excel/.test(imp.notice || '') && /positions/.test(imp.notice || '') && /conditions/.test(imp.notice || '') && /details/.test(imp.notice || ''),
        `N1 [${tag}] the import notice says Excel and names what it does not carry`, (imp.notice || '(no notice)').slice(0, 160));
  }

  // F1: a workbook written by other programs
  await open(MAPS[0]);
  const foreign = join(FIX, 'arc-lifecycle-libreoffice.xlsx');
  const fi = existsSync(foreign) ? await importVia('xlsx', foreign) : { chooser: false, alert: 'fixture missing: ' + foreign };
  const fb = await ev(MODEL);
  const fSteps = arcOrig && JSON.stringify(fb.steps) === JSON.stringify(arcOrig.steps), fFlows = arcOrig && JSON.stringify(fb.flows) === JSON.stringify(arcOrig.flows);
  leg(fi.chooser && !fi.alert && fSteps && fFlows && /Excel/.test(fi.notice || ''),
      'F1 a LibreOffice-saved workbook (shared strings, a numeric column, the table on sheet 2 behind a sheet without "id", columns reordered) imports to the same steps and flows',
      `steps ${fb.steps.length}/${arcOrig ? arcOrig.steps.length : '?'}, flows ${fb.flows.length}/${arcOrig ? arcOrig.flows.length : '?'}${fi.alert ? ', alert: ' + fi.alert : ''}` +
      `${arcOrig && !fSteps ? ', step diff ' + firstDiff(arcOrig.steps, fb.steps) : ''}${arcOrig && !fFlows ? ', flow diff ' + firstDiff(arcOrig.flows, fb.flows) : ''}`);

  // E1 / E2: refused, named, nothing imported
  for (const [n, file, want, what] of [
    ['E1', arcCsv && (writeFileSync(join(dl, 'not-a-workbook.xlsx'), readFileSync(arcCsv)), join(dl, 'not-a-workbook.xlsx')), /not a zip/, 'a CSV renamed .xlsx'],
    ['E2', join(FIX, 'no-id-column.xlsx'), /"id" column/, 'a workbook with no "id" column']]) {
    await open(MAPS[0]);
    const before = await ev(MODEL);
    const r = file && existsSync(file) ? await importVia('xlsx', file) : { chooser: false, alert: '' };
    const after = await ev(MODEL);
    leg(r.chooser && want.test(r.alert || '') && after.wid === before.wid && after.n === before.n,
        `${n} ${what} is refused with an alert naming why, and the open map is unchanged`,
        `alert: ${(r.alert || '(none)').replace(/\n/g, ' ')}; map ${after.wid} (${after.n} steps), was ${before.wid} (${before.n})${file && existsSync(file) ? '' : ', input missing: ' + file}`);
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
