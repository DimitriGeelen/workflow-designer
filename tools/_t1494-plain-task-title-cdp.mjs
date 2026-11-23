// T-1494 (Greenfield msg 2e879869, point 2b) — a plain bpmn:task is titled by its own kind in the properties panel,
// not 'serviceTask'. The importer holds an element of a kind it does not edit natively as a serviceTask with its tag
// kept as foreignTag and written back verbatim (T-337); the canvas captions it "(task)", the panel header printed n.type.
//
//   K1 [Greenfield's sample, a plain bpmn:task selected] the panel header names 'task', not 'serviceTask', and keeps a
//      badge (the shape the canvas draws)
//   K2 [the starter map, a real serviceTask selected] the header still reads 'serviceTask'
//   K3 [Greenfield's sample saved] every plain task is written back as <bpmn:task …>, none as serviceTask
// Teeth: T1494_EDITOR=<the 0.46.0 designer> fails K1.
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1494_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const FIXTURE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1494-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
// select a node and read the panel header
const HEAD = pick => `(function(){
  var n = state.nodes.find(${pick}); if (!n) return null;
  selection = { kind: 'node', id: n.id }; renderProperties();
  var h = document.querySelector('.props-header'); if (!h) return { id: n.id, name: null };
  var nm = h.querySelector('.props-type-name'), b = h.querySelector('.props-type-badge');
  return { id: n.id, type: n.type, foreignTag: n.foreignTag || '', name: nm ? nm.textContent : null, badge: !!(b && b.querySelector('svg')) };
})()`;
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1494-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
  for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
  // K2 first, on the starter map as it loads
  const svc = await ev(HEAD(`function(n){ return n.type === 'serviceTask' && !n.foreignTag; }`));
  leg(!!svc && svc.name === 'serviceTask' && svc.badge, `K2 [starter map, ${svc ? svc.id : '?'}] a real service task is still headed 'serviceTask' with its badge`, svc ? `header '${svc.name}'` : 'no service task');
  const xml = readFileSync(FIXTURE, 'utf8');
  const plainIds = [...xml.matchAll(/<bpmn:task\b[^>]*\bid="([^"]+)"/g)].map(m => m[1]);
  await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); return true; })(${JSON.stringify(xml)})`);
  const plain = await ev(HEAD(`function(n){ return n.foreignTag === 'task'; }`));
  leg(plainIds.length > 0 && !!plain && plain.name === 'task' && plain.badge,
    `K1 [Greenfield's sample, ${plainIds.length} plain tasks; ${plain ? plain.id : '?'} selected] the header names 'task' (not 'serviceTask') and keeps a badge`,
    plain ? `header '${plain.name}', badge ${plain.badge}` : 'no node with foreignTag task');
  if (process.env.T1494_SHOTS) {   // the selected plain task with its panel, at three widths
    const { mkdirSync, writeFileSync } = await import('node:fs');
    mkdirSync(process.env.T1494_SHOTS, { recursive: true });
    for (const W of [1024, 1440, 1920]) {
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
      await ev(`(function(){ renderAll(); ${HEAD(`function(n){ return n.foreignTag === 'task'; }`)}; return true; })()`);
      await sleep(400);
      const shot = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1494_SHOTS, `plain-task-panel-${W}.png`), Buffer.from(shot.data, 'base64'));
    }
  }
  const saved = await ev(`buildBpmnXml(state)`);
  // the save writes the designer's display ids, not the file's, so count by tag: the file has no serviceTask
  const back = (saved.match(/<bpmn:task\b/g) || []).length, asSvc = (saved.match(/<bpmn:serviceTask\b/g) || []).length;
  const inFile = (xml.match(/<bpmn:serviceTask\b/g) || []).length;
  leg(plainIds.length > 0 && back === plainIds.length && asSvc === inFile,
    `K3 the save writes the ${plainIds.length} plain tasks back as <bpmn:task> (${back}), and serviceTask only as often as the file has it (${asSvc} of ${inFile})`);
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
