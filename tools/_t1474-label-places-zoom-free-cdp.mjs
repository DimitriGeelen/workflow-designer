// T-1474 — a map's flow labels take the same places whatever the zoom at render time. clearFlowLabels measures the
// node texts it avoids (.node-label, .node-id-badge, .node-io-badge); hinted, their boxes changed with the zoom and 16
// corpus flow labels took another place at fit than at 100% (T-1256 had unhinted only the flow labels themselves).
//
//   Z1 [every map in examples/aef-processes/rendered, lens all] rendered at fit, at 100% and at 200%: every flow label
//      (by its edge) has the same box at all three
// Teeth: T1474_EDITOR=<the 0.46.0 designer> fails Z1.
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
const EDITOR = process.env.T1474_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const CORPUS = join(ROOT, 'examples/aef-processes/rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1474-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const PLACES = `(function(){
  var out = {};
  gEdges.querySelectorAll('text.edge-label[data-el]').forEach(function(t){
    var b = t.getBBox(); out[t.getAttribute('data-el') + ' ' + t.textContent] = [Math.round(b.x * 10) / 10, Math.round(b.y * 10) / 10];
  });
  return out;
})()`;
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1474-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--disable-dev-shm-usage', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
  for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
  await ev(`document.fonts.ready`);
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  let labels = 0; const moved = [];
  for (const f of corpus) {
    const xml = JSON.stringify(readFileSync(join(CORPUS, f), 'utf8'));
    const at = {};
    for (const [name, z] of [['fit', 'null'], ['100%', '1'], ['200%', '2']]) {
      at[name] = await ev(`(function(xml){ adoptImportedXml(xml, { userImport: true }); if (typeof setLens === 'function') setLens('all');
        zoomFactor = ${z}; applyCanvasZoom(); renderAll(); return ${PLACES}; })(${xml})`);
    }
    for (const k of Object.keys(at.fit)) {
      labels++;
      for (const z of ['100%', '200%']) if (JSON.stringify(at.fit[k]) !== JSON.stringify(at[z][k])) moved.push(`${f} "${k.split(' ').slice(1).join(' ')}" fit ${JSON.stringify(at.fit[k])} vs ${z} ${JSON.stringify(at[z][k])}`);
    }
  }
  leg(corpus.length > 0 && labels > 0 && !moved.length, `Z1 [${corpus.length} corpus maps, ${labels} flow labels] each at the same place rendered at fit, 100% and 200%`,
      moved.length ? `${moved.length} differ: ` + moved.slice(0, 3).join('; ') : '');
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
