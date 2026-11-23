// T-1469 (Greenfield msg bfd033c1) — the io badge never covers a name line. The badge sits in the task's top-right
// corner (y 4-16); a 4-line name's first line starts at ~6.5 and, when long, ran under it ("1→1" over the end of
// 'Opportunity – Solution (doorgestreept) – onder water' on 0.45.0). clearIoBadges() moves such a badge up.
//
//   B1 [starter map, a task given Greenfield's name + 1 input + 1 output, lens all] no name line's box meets the io
//      badge's box, and the badge still touches the task's top-right corner (moved up, not away)
//   B2 a task whose name does not reach the badge keeps the badge at y = task top + 4 (no needless move)
//   B3 [every map in examples/aef-processes/rendered, lens all] no task's name line meets its io badge
// Teeth: T1469_EDITOR=<the 0.46.0 designer> fails B1.
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1469_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const CORPUS = join(ROOT, 'examples/aef-processes/rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1469-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
// For every task with an io badge: does any name line's box meet the badge box; where is the badge vs the task's top.
const MEASURE = `(function(){
  var out = [];
  state.nodes.forEach(function(n){
    var g = gNodes.querySelector('[data-id="' + n.id + '"]') || gNodes;
    var rect = null;
    gNodes.querySelectorAll('rect').forEach(function(r){
      if (rect) return;
      var lbl = r.nextSibling;
      if (lbl && lbl.classList && lbl.classList.contains('node-io-badge') && (r.getAttribute('data-iob') === n.uid ||
          (!r.hasAttribute('data-iob') && Math.abs(parseFloat(r.getAttribute('x')) + parseFloat(r.getAttribute('width')) + 4 - (n.x + dims(n).w)) < 0.5 &&
           Math.abs(parseFloat(r.getAttribute('y')) - (n.y + 4)) < 0.5))) rect = r;
    });
    if (!rect) return;
    var b = rect.getBBox();
    var lines = Array.from(gNodes.querySelectorAll('text[data-fitn="' + n.uid + '"]')).map(function(t){ return t.getBBox(); });
    var hit = lines.some(function(r){ return r.width && r.x < b.x + b.width && r.x + r.width > b.x && r.y < b.y + b.height && r.y + r.height > b.y; });
    out.push({ name: n.name, hit: hit, badgeY: Math.round((b.y - n.y) * 10) / 10, badgeBottom: Math.round((b.y + b.height - n.y) * 10) / 10,
               lines: lines.length });
  });
  return out;
})()`;
const GF_NAME = 'Opportunity – Solution (doorgestreept) – onder water';
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1469-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
  for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
  await ev(`document.fonts.ready`);
  // B1/B2: one task gets Greenfield's name and io; the others keep theirs
  const setup = await ev(`(function(){
    if (typeof setLens === 'function') setLens('all');
    var tasks = state.nodes.filter(function(n){ return /Task$/.test(n.type); });
    var t = tasks[0]; t.name = ${JSON.stringify(GF_NAME)}; t.io = { inputs: [{ name: 'opportunity', type: 'ref' }], outputs: [{ name: 'solution', type: 'ref' }] };
    renderAll(); return { gf: t.name, plain: tasks.filter(function(x){ return x !== t && x.io && ((x.io.inputs||[]).length || (x.io.outputs||[]).length); }).map(function(x){ return x.name; }) };
  })()`);
  await ev(`new Promise(function(r){ requestAnimationFrame(function(){ requestAnimationFrame(function(){ r(); }); }); })`);
  const m = await ev(MEASURE);
  const gf = m.find(x => x.name === GF_NAME);
  leg(!!gf && !gf.hit && gf.badgeBottom > 0, `B1 [${GF_NAME}, ${gf ? gf.lines : '?'} lines, 1→1] no name line meets the io badge, which still touches the task (badge top ${gf ? gf.badgeY : '?'}, bottom ${gf ? gf.badgeBottom : '?'} from the task top)`, gf ? '' : 'badge not found');
  const plain = m.filter(x => x.name !== GF_NAME && !x.hit);
  const moved = plain.filter(x => Math.abs(x.badgeY - 4) > 0.5 && x.lines < 3);
  leg(plain.length > 0 && !moved.length, `B2 tasks whose name does not reach the badge keep it at task top + 4 (${plain.length} badge(s))`, moved.map(x => `${x.name}: ${x.badgeY}`).join('; '));
  if (process.env.T1469_SHOTS) {
    mkdirSync(process.env.T1469_SHOTS, { recursive: true });
    for (const W of [1024, 1440, 1920]) {
      await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 2, mobile: false });
      await ev(`(function(){ var t = state.nodes.find(function(n){ return n.name === ${JSON.stringify(GF_NAME)}; }); zoomFactor = 2; applyCanvasZoom(); renderAll();
        var r = gNodes.querySelector('[data-fitn="' + t.uid + '"]'); if (r) r.scrollIntoView({ block: 'center', inline: 'center' }); })()`);
      await sleep(400);
      const shot = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1469_SHOTS, `io-badge-${W}.png`), Buffer.from(shot.data, 'base64'));
    }
  }
  // B3: the corpus
  const corpus = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  const hits = [];
  let badges = 0;
  for (const f of corpus) {
    const r = await ev(`(function(xml){ adoptImportedXml(xml, { userImport: true }); if (typeof setLens === 'function') setLens('all'); renderAll(); return ${MEASURE}; })(${JSON.stringify(readFileSync(join(CORPUS, f), 'utf8'))})`);
    badges += r.length;
    for (const x of r) if (x.hit) hits.push(`${f}: ${x.name}`);
  }
  leg(corpus.length > 0 && !hits.length, `B3 [${corpus.length} corpus maps, ${badges} io badges] no name line meets its io badge`, hits.slice(0, 4).join('; '));
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
