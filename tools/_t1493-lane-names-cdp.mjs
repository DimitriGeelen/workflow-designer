// T-1493 (Greenfield msg 2e879869, point 2a) — the properties panel's Lane dropdown shows lane NAMES, as the canvas does,
// and still stores the lane id.
//
//   L1 [Greenfield's sample, a step selected] the Lane options read Salesforce, Tacton, Novis + 98/97, NAV (the file's
//      names) and their values are the ids (Lane_Salesforce …); the selected option is the step's own lane
//   L2 choosing another option moves the step to that lane (n.lane = its id), as before
//   L3 two lanes given the same name are told apart (name plus id); a lane without a name shows its id
//   L4 the save of the untouched sample is byte-identical before and after opening the panel on every step
// Teeth: T1493_EDITOR=<the 0.46.0 designer> fails L1.
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
const EDITOR = process.env.T1493_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const FIXTURE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
const LANES = [['Lane_Salesforce', 'Salesforce'], ['Lane_Tacton', 'Tacton'], ['Lane_Novis', 'Novis + 98/97'], ['Lane_NAV', 'NAV']];
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1493-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
// the Lane <select> of the selected node's panel
const LANE_SEL = `(function(){
  var f = Array.from(document.querySelectorAll('.field')).find(function(w){ var l = w.querySelector('.field-label'); return l && /^Lane\\b/.test(l.textContent.trim()); });
  return f ? f.querySelector('select') : null; })()`;
const OPTS = `(function(){ var s = ${LANE_SEL}; if (!s) return null;
  return { opts: Array.from(s.options).map(function(o){ return [o.value, o.textContent]; }), value: s.value }; })()`;
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1493-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
  for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
  const xml = readFileSync(FIXTURE, 'utf8');
  await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); return true; })(${JSON.stringify(xml)})`);
  const before = await ev(`buildBpmnXml(state)`);
  // L4 first: open the panel on every step, then save
  await ev(`(function(){ state.nodes.forEach(function(n){ selection = { kind: 'node', id: n.id }; renderProperties(); }); selection = null; renderProperties(); return true; })()`);
  const after = await ev(`buildBpmnXml(state)`);
  // L1
  const sel = await ev(`(function(){ var n = state.nodes.find(function(n){ return n.lane === 'Lane_Tacton' && /Task$/.test(n.type); });
    selection = { kind: 'node', id: n.id }; renderProperties(); return n.id; })()`);
  const o = await ev(OPTS);
  const want = JSON.stringify(LANES), got = o ? JSON.stringify(o.opts) : 'none';
  leg(!!o && got === want && o.value === 'Lane_Tacton', `L1 [${sel}] the Lane options show the lane names with the ids as values, its own lane selected`, got === want ? '' : `got ${got}`);
  if (process.env.T1493_SHOTS) {   // the step's panel with its Lane field, at three widths
    const { mkdirSync, writeFileSync } = await import('node:fs');
    mkdirSync(process.env.T1493_SHOTS, { recursive: true });
    for (const W of [1024, 1440, 1920]) {
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
      await ev(`(function(){ renderAll(); selection = { kind: 'node', id: ${JSON.stringify(sel)} }; renderProperties(); return true; })()`);
      await sleep(400);
      const shot = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1493_SHOTS, `lane-field-${W}.png`), Buffer.from(shot.data, 'base64'));
    }
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  }
  // L2
  const moved = await ev(`(function(){ var s = ${LANE_SEL}; s.value = 'Lane_NAV'; s.dispatchEvent(new Event('change'));
    var n = state.nodes.find(function(n){ return n.id === ${JSON.stringify(sel)}; }); return n ? n.lane : null; })()`);
  leg(moved === 'Lane_NAV', `L2 choosing 'NAV' moves the step to lane Lane_NAV`, `n.lane = ${moved}`);
  // L3
  const dup = await ev(`(function(){ var ls = getLanes(); ls[1].name = ls[0].name; var keep = ls[3].name; ls[3].name = '';
    selection = { kind: 'node', id: ${JSON.stringify(sel)} }; renderProperties(); var r = ${OPTS}; return r ? r.opts : null; })()`);
  const texts = dup ? dup.map(x => x[1]) : [];
  leg(!!dup && new Set(texts).size === texts.length && texts[3] === 'Lane_NAV' && texts[0].includes('Salesforce') && texts[0] !== texts[1],
    `L3 two lanes named alike are told apart, a nameless lane shows its id`, JSON.stringify(texts));
  leg(before.length > 0 && before === after, `L4 the sample's save is byte-identical after opening the panel on every step (${before.length} chars)`);
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
