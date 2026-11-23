// T-1475 — the starter map numbers the same on every load. computeDisplayId orders a lane's equal-x steps by uid; the
// starter's uids were minted from Math.random, so its stacked search tasks changed display ids from load to load.
//
//   D1 [no query, a fresh profile each time, 3 loads] the starter's display ids (every node and edge, by its code order)
//      are identical across the loads, and no two nodes share a uid
//   D2 at least one lane holds two steps at the same x (the case the tie-break decides); without it D1 proves nothing
// Teeth: T1475_EDITOR=<the designer before T-1475> fails D1 (the lists differ between loads).
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
const EDITOR = process.env.T1475_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1475-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const READ = `(function(){
  var ids = state.nodes.map(function(n){ return n.name + ' = ' + displayIdOf(n); })
    .concat(state.edges.map(function(e){ return 'edge ' + (e.name || '') + ' = ' + displayIdOf(e); }));
  var uids = state.nodes.map(function(n){ return n.uid; });
  var byLaneX = {}, ties = 0;
  state.nodes.forEach(function(n){ var k = n.lane + '@' + n.x; byLaneX[k] = (byLaneX[k] || 0) + 1; });
  Object.keys(byLaneX).forEach(function(k){ if (byLaneX[k] > 1) ties++; });
  return { ids: ids, uniqueUids: new Set(uids).size === uids.length, ties: ties, map: state.workflowMeta.id };
})()`;
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const runs = [];
  for (let i = 0; i < 3; i++) {
    await stop();
    const udd = makeProfileDir('t1475-'); profiles.push(udd);   // a fresh profile: no autosave, the starter map loads
    br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
    let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
    if (!dp) throw new Error('no devtools port');
    cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
    await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
    await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
    for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
    runs.push(await ev(READ));
  }
  const same = runs.every(r => JSON.stringify(r.ids) === JSON.stringify(runs[0].ids));
  const firstDiff = same ? '' : runs[0].ids.map((x, k) => [x, runs[1].ids[k], runs[2].ids[k]]).filter(t => !(t[0] === t[1] && t[1] === t[2])).slice(0, 3).map(t => t.join(' | ')).join(' ;; ');
  leg(same && runs.every(r => r.uniqueUids), `D1 [starter '${runs[0].map}', 3 fresh loads] the display ids of all ${runs[0].ids.length} nodes and edges are identical across loads, uids unique`, firstDiff);
  leg(runs[0].ties > 0, 'D2 the starter has steps at the same x in one lane (the tie the uid breaks)', `lane@x groups with >1 step: ${runs[0].ties}`);
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
