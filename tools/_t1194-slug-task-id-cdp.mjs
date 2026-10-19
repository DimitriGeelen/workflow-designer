#!/usr/bin/env node
// _t1194-slug-task-id-cdp.mjs — verify T-1194: deriveSlug skips a leading task id, so "T-001: Orientation ..." gives the
// slug `orientation` (ids like agt_1_orientation, not agt_1_001); a name that is only a task id keeps its digits; every
// other name gives exactly the slug it gave before. Runs the designer's own deriveSlug in headless chromium (same
// harness as _t1091), plus one end-to-end leg: a node renamed "T-002: Your First Governed Commit" exports that slug.
// T1194_DESIGNER=<file> runs it against another build (control: the pre-T-1194 designer fails the task-id cases).
// Exit 0 = pass. Exit 1 = a case failed. Exit 2 = harness could not run.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const MAP = 'task-lifecycle';
const sleep = ms => new Promise(r => setTimeout(r, ms));

// [name, expected slug]. The first group changes with T-1194; the second must give what it always gave.
const CASES = [
  ['T-001: Orientation and Framework Health Check', 'orientation'],
  ['T-002: Your First Governed Commit', 'your'],
  ['T-003 - First governed commit', 'first'],
  ['T-004 — Walk One Task All the Way Round', 'walk'],
  ['T-005 Generate first handover', 'generate'],
  ['  t-1168: lower-case id', 'lower'],
  ['T-001', '001'],
  ['T-001:', '001'],
  ['Run completion gate battery', 'run'],
  ['Task captured (filed)', 'task'],
  ['A task with T-001: inside', 'task'],
  ['T-shirt sizing', 'shirt'],
  ['TX-001: not a task id', 'tx'],
  ['Extraordinarilylongfirstword here', 'extraordinarilyl'],
  // T-1196: the framework's other id prefixes are skipped the same way; look-alike words are not.
  ['G-062 close gates — headline mechanic fired?', 'close'],
  ['G-020 build-readiness gate armed', 'build'],
  ['OBS-314: pool sizing', 'pool'],
  ['L-417 - stale slice references', 'stale'],
  ['G-062', '062'],
  ['G-force test', 'force'],
  ['L-shaped layout', 'shaped'],
  ['OBSERVE the gate', 'observe'],
  ['', 'node'],
];

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't1194-doc-')), repo = mkdtempSync(join(tmpdir(), 't1194-repo-')), udd = mkdtempSync(join(tmpdir(), 't1194-udd-'));
  copyFileSync(process.env.T1194_DESIGNER || join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'));
  copyFileSync(join(REPO, 'examples/aef-processes/rendered', MAP + '.bpmn'), join(doc, 'rendered', MAP + '.bpmn'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: 'ignore' });
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let cl; const steps = [];
  const push = (n, p, g) => steps.push({ step: n, pass: !!p, got: g });
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { if ((await fetch(`http://127.0.0.1:${port}/api/health`)).ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down');
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/${MAP}.bpmn` });
    await sleep(300); await waitReady(cmd); await sleep(300);
    const got = await ev(cmd, `${JSON.stringify(CASES.map(c => c[0]))}.map(function(n){ return deriveSlug(n); })`);
    CASES.forEach(([name, want], i) => push(`deriveSlug(${JSON.stringify(name)}) = ${want}`, got[i] === want, got[i]));
    // End to end: a task-named activity exports the word slug in its id.
    const e2e = await ev(cmd, `(function(){ var n = state.nodes.filter(function(n){ return !laneLabelBelow(n.type); })[0];
      n.name = 'T-002: Your First Governed Commit'; n.slug = deriveSlug(n.name); refreshDisplayIds(); renderAll();
      var id = displayIdOf(n), x = buildBpmnXml(state); return { id: id, inExport: x.indexOf('id="' + id + '"') >= 0 }; })()`);
    push('end to end: a node named "T-002: Your First Governed Commit" gets an id ending _your and exports it', /_\d+_your$/.test(e2e.id) && e2e.inExport, e2e);
  } catch (e) {
    push('harness', false, String(e && e.stack || e)); process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    await sleep(300);
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
  for (const s of steps) console.log((s.pass ? 'ok    ' : 'FAIL  ') + s.step + (s.pass ? '' : '  got: ' + JSON.stringify(s.got)));
  const failed = steps.filter(s => !s.pass).length;
  console.log(`${failed ? 'FAIL' : 'PASS'}: ${steps.length - failed}/${steps.length}`);
  if (process.exitCode !== 2) process.exitCode = failed ? 1 : 0;
}
main();
