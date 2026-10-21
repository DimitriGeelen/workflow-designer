#!/usr/bin/env node
// _t1193-slug-readonly-cdp.mjs — verify T-1193: the Slug field is read-only and follows the name. A hand-typed slug was
// never saved (the export writes no slug; the importer derives every slug from the name), so it reverted on reload and
// the next save changed the id unasked. Legs: the panel's Slug input is read-only; typing into it changes nothing;
// renaming the step changes slug and id; an exported map reloads with the same ids.
// Usage: node tools/_t1193-slug-readonly-cdp.mjs [designer.html]   (control: the pre-T-1193 designer fails leg 1)
// Exit 0 = pass, 1 = a leg failed.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const REPO = join(dirname(new URL(import.meta.url).pathname), '..');
const SERVER = join(REPO, 'tools/gallery-serve.py');
const DESIGNER = process.argv[2] || join(REPO, 'src/aef-workflow-designer.html');
const DIR = process.argv[3] || join(REPO, 'examples/aef-processes/rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

const PROBE = `(function(){
  var pb = svg.querySelector('#g-pool > .pool-border');
  var px = +pb.getAttribute('x'), py = +pb.getAttribute('y'), pw = +pb.getAttribute('width'), ph = +pb.getAttribute('height');
  function worst(sel){ var r = { right: -1e9, bottom: -1e9, rt: '', bt: '' };
    svg.querySelectorAll(sel).forEach(function(t){ var b; try { b = t.getBBox(); } catch(e){ return; } if (!b.width) return;
      var o = b.x + b.width - (px + pw), u = b.y + b.height - (py + ph);
      if (o > r.right) { r.right = o; r.rt = t.textContent.slice(0, 30); }
      if (u > r.bottom) { r.bottom = u; r.bt = t.textContent.slice(0, 30); } });
    return r; }
  return { labels: worst('#g-nodes .node-label'), badges: worst('#g-badges text, #g-badges-top text') };
})()`;

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't1154m-doc-')), repo = mkdtempSync(join(tmpdir(), 't1154m-repo-')), udd = makeProfileDir('t1154m-udd-');
  copyFileSync(DESIGNER, join(doc, 'designer.html')); mkdirSync(join(doc, 'rendered'));
  const files = readdirSync(DIR).filter(f => f.endsWith('.bpmn')).sort();
  for (const f of files) copyFileSync(join(DIR, f), join(doc, 'rendered', f));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: 'ignore' });
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let cl;
  try {
    for (let i = 0; i < 60; i++) { try { if ((await fetch(`http://127.0.0.1:${port}/api/health`)).ok) break; } catch (_) {} await sleep(100); }
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 860, deviceScaleFactor: 1, mobile: false });
    const base = `http://127.0.0.1:${port}/designer.html?load=rendered/`;
    const legs = []; const leg = (n, ok, got) => legs.push([n, !!ok, got]);
    await cmd('Page.navigate', { url: base + 'task-lifecycle.bpmn' }); await sleep(300); await waitReady(cmd); await sleep(300);
    const r = await ev(cmd, `(function(){ var n = state.nodes.filter(function(n){ return !laneLabelBelow(n.type); })[0];
      selection = { kind: 'node', id: n.id }; renderAll();
      var inp = document.querySelector('[data-testid="slug-readonly"]') || Array.prototype.slice.call(document.querySelectorAll('.field-input')).filter(function(i){ return i.value === n.slug; })[0];
      var ro = !!(inp && inp.readOnly), id0 = displayIdOf(n);
      if (inp) { inp.value = 'myslug'; inp.dispatchEvent(new Event('input', { bubbles: true })); inp.dispatchEvent(new Event('change', { bubbles: true })); inp.dispatchEvent(new Event('blur')); }
      var id1 = displayIdOf(n);
      n.name = 'Draft the acceptance criteria'; n.slug = deriveUniqueSlug(n, n.name); refreshDisplayIds(); renderAll();
      var id2 = displayIdOf(n), xml = buildBpmnXml(state);
      return { ro: ro, id0: id0, id1: id1, id2: id2, xml: xml, name: n.name }; })()`);
    leg('the Slug field is read-only', r.ro, r.ro);
    leg('typing into it changes nothing', r.id1 === r.id0, [r.id0, r.id1]);
    leg('renaming the step changes its slug and id', r.id2 !== r.id0 && /_draft$/.test(r.id2), [r.id0, r.id2]);
    const { writeFileSync } = await import('node:fs');
    writeFileSync(join(doc, 'rendered', 'reload.bpmn'), r.xml);
    await ev(cmd, `(localStorage.removeItem('aefAutosaveDoc'), 1)`);
    await cmd('Page.navigate', { url: base + 'reload.bpmn' }); await sleep(300); await waitReady(cmd); await sleep(300);
    const again = await ev(cmd, `buildBpmnXml(state)`);
    const ids = x => (x.match(/ id="[^"]+"/g) || []).sort().join(',');
    leg('an exported map reloads with exactly the same ids', ids(again) === ids(r.xml), { before: ids(r.xml).length, after: ids(again).length });
    // Screenshots of the properties panel with a step selected, for the visual review (CLAUDE.md, T-1174).
    const { mkdirSync: mk } = await import('node:fs');
    mk(join(REPO, '.playwright-mcp'), { recursive: true });
    for (const w of [1024, 1440, 1920]) {
      await cmd('Emulation.setDeviceMetricsOverride', { width: w, height: 860, deviceScaleFactor: 1, mobile: false });
      await ev(cmd, `(localStorage.removeItem('aefAutosaveDoc'), 1)`);
      await cmd('Page.navigate', { url: base + 'task-lifecycle.bpmn' }); await sleep(300); await waitReady(cmd); await sleep(300);
      await ev(cmd, `(function(){ var n = state.nodes.filter(function(n){ return !laneLabelBelow(n.type); })[0]; selection = { kind: 'node', id: n.id }; renderAll(); return 1; })()`);
      await sleep(200);
      const { data } = await cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(REPO, '.playwright-mcp', `t1193-${w}-props.png`), Buffer.from(data, 'base64'));
    }
    for (const [n, ok, got] of legs) console.log((ok ? 'ok    ' : 'FAIL  ') + n + (ok ? '' : '  got: ' + JSON.stringify(got)));
    const failed = legs.filter(l => !l[1]).length;
    console.log(`${failed ? 'FAIL' : 'PASS'}: ${legs.length - failed}/${legs.length}`);
    process.exitCode = failed ? 1 : 0;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL'); await sleep(300);
    for (const d of [doc, repo, udd]) rmSync(d, { recursive: true, force: true });
  }
}
main();
