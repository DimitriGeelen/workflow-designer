#!/usr/bin/env node
// _t1365-value-rules-cdp.mjs — T-1365: the io panel shows, under each aef:field whose fieldRef the project's field
// catalog knows, how a value of that attribute is built (the catalog row's SHACL-derived rule: datatype, maxLength,
// pattern, allowed values, description, a made-up example, where the value comes from). Read-only. Drives the REAL
// editor headless against the server's /api/field-catalog, on synthetic fixtures (tests/fixtures/t1365/, no client
// data), and asserts:
//   a. no catalog (404): no rule line anywhere — the field rows are as before;
//   b. a catalog: the id field shows "crm:Order.Id · string · max 18 · pattern" and, opened, its format, pattern,
//      made-up example and source; the status field shows "one of 3" and the allowed values; the field the catalog
//      does not know says so; the field addressed by path gets no rule line;
//   c. display only: in one page, buildBpmnXml is byte-identical before the catalog loads and after every rule is opened.
// T1365_SRC substitutes another designer file (the BITE: on the pre-T-1365 source, b is red).
// Exit 0 = all legs green; 1 = a leg failed; 2 = misconfig.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const SRC = process.env.T1365_SRC || join(REPO, 'src/aef-workflow-designer.html');
const MAP = readFileSync(join(REPO, 'tests/fixtures/t1365/value-rules.bpmn'), 'utf8');
const CATALOG = readFileSync(join(REPO, 'tests/fixtures/t1365/field-catalog.json'), 'utf8');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 500)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&typeof loadFieldCatalog==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > (+process.env.CDP_READY_MS || 20000)) throw new Error('editor not ready'); await sleep(150); } }

// Open the map, select the step, open its first io editor, open every rule; report what the field rows show.
const PROBE = `(async () => {
  adoptImportedXml(window.__MAP__); renderAll();
  var strip = function(x){ return x.replace(/<!--[\\s\\S]*?-->/g, ''); };
  var before = strip(buildBpmnXml(state));   // c: the same page, before the catalog loads
  await loadFieldCatalog();
  var n = state.nodes.filter(function(x){ return x.name === 'Register the order'; })[0];
  selection = { kind: 'node', id: n.id }; multiSelect = new Set([n.id]); renderProperties();
  var p = document.getElementById('properties');
  var t = p.querySelector('.io-attrs-toggle');
  if (t && !(t.nextElementSibling && t.nextElementSibling.classList.contains('io-attrs'))) t.click();
  p = document.getElementById('properties');
  p.querySelectorAll('.io-field-rule details').forEach(function(d){ d.open = true; });
  var rows = Array.from(p.querySelectorAll('.io-field-row')).map(function(r){
    var a = r.querySelector('[data-fattr="addr"]'), rule = r.querySelector('.io-field-rule');
    var dl = {}; if (rule) rule.querySelectorAll('dt').forEach(function(dt){ dl[dt.textContent] = dt.nextElementSibling ? dt.nextElementSibling.textContent : ''; });
    var sum = rule && rule.querySelector('summary');
    return { addr: a ? a.value : null, rule: rule ? rule.dataset.rule : null, summary: sum ? sum.textContent : (rule ? rule.textContent : null), dl: dl };
  });
  return { rows: rows, before: before, after: strip(buildBpmnXml(state)) };
})()`;

async function main() {
  if (!existsSync(SRC)) { console.log(JSON.stringify({ ok: false, error: 'designer missing: ' + SRC })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1365-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1365-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = makeProfileDir('t1365-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const errs = [], legs = {};
  let cl;
  try {
    let up = false; for (let i = 0; i < 100; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    const fresh = async () => { await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd); await sleep(300); await ev(cmd, `window.__MAP__ = ${JSON.stringify(MAP)};`); return ev(cmd, PROBE); };

    // a. no catalog
    const a = await fresh();
    legs.a = a.rows.map(r => ({ addr: r.addr, rule: r.rule }));
    if (a.rows.length !== 4) errs.push('a: expected 4 field rows, got ' + a.rows.length);
    if (a.rows.some(r => r.rule)) errs.push('a: without a catalog a rule line appeared: ' + JSON.stringify(legs.a));

    // b. a catalog
    writeFileSync(join(repo, 'field-catalog.json'), CATALOG);
    const b = await fresh();
    const by = addr => b.rows.filter(r => r.addr === addr)[0] || {};
    const id = by('ex:attr-order-id'), st = by('ex:attr-order-status'), un = by('ex:attr-order-unknown'), pa = by('Order.note');
    legs.b = { id: { summary: id.summary, dl: id.dl }, status: { summary: st.summary, dl: st.dl }, unknown: un.summary, path: pa.rule };
    if (id.rule !== 'catalog' || !/crm:Order\.Id/.test(id.summary || '') || !/string/.test(id.summary || '') || !/max 18/.test(id.summary || '') || !/pattern/.test(id.summary || ''))
      errs.push('b: the id field summary should read "crm:Order.Id · string · max 18 · pattern ...": ' + JSON.stringify(id.summary));
    if (!id.dl || id.dl.pattern !== '^ORD[A-Z0-9]{15}$' || !/ORD000000000000AAA/.test(id.dl.example || '') || !/made up/.test(id.dl.example || '')
        || !/18 characters/.test(id.dl.format || '') || !/set by the CRM/.test(id.dl['comes from'] || ''))
      errs.push('b: the opened id rule lacks its pattern, made-up example, format or source: ' + JSON.stringify(id.dl));
    if (st.rule !== 'catalog' || !/one of 3/.test(st.summary || '') || (st.dl || {}).allowed !== 'Open | Complete | Cancelled' || !/quoting tool/.test((st.dl || {}).derived || ''))
      errs.push('b: the status field should show "one of 3", the allowed values and what it derives from: ' + JSON.stringify(legs.b.status));
    if (un.rule !== 'none' || !/not in the project's field catalog/.test(un.summary || '')) errs.push('b: the unknown field should say it is not in the catalog: ' + JSON.stringify(un));
    if (pa.rule) errs.push('b: the field addressed by path got a rule line: ' + JSON.stringify(pa));

    // c. display only: in the same page, the save before the catalog loaded and after every rule was opened
    legs.c = { same: b.before === b.after, bytes: [b.before.length, b.after.length] };
    if (b.before !== b.after) errs.push('c: the save differs once the catalog is loaded and the rules opened (display must not write)');
  } catch (e) {
    errs.push('run: ' + String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill();
    try { rmSync(repo, { recursive: true, force: true }); rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  }
  console.log(JSON.stringify({ ok: errs.length === 0, src: SRC, errs, legs }, null, 2));
  process.exitCode = errs.length ? 1 : 0;
}
main();
