#!/usr/bin/env node
/**
 * _t562-workflow-id-helpers-cdp.mjs — prove the workflow-id sanitizer and the validator
 * that judges it agree, IN THE LOADED PAGE, at every site that mints an id.
 *
 * The defect this exists for (T-501 D2): `sanitizeWorkflowId` was written inline three
 * times (renameActiveWorkflow, the ID property field, createFromPendingRef) and judged
 * by a fourth inline regex in the save guard. The three disagreed with the judge, so a
 * map could be renamed to an id the save path would later refuse.
 *
 * WHY CDP AND NOT A UNIT TEST. The helpers are pure and could be tested by extracting
 * the text. That would assert the fix is in the FILE. This project spent the week
 * learning that is not the same as asserting it RUNS — so the probe loads the real
 * document in a real browser and calls the real functions, and leg 6 drives an actual
 * rename through `renameActiveWorkflow` rather than calling the helper directly, which
 * is the only leg that can tell "the helper is correct" from "the call site uses it".
 *
 * THE LOAD-BEARING LEG IS 4, NOT 2. A helper that always returned 'workflow' would pass
 * legs 1, 2, 3, 5 and 7 — every output would be valid. Leg 4 pins the other edge: the
 * two rename sites need '' back for unusable input so the rename REFUSES, and only the
 * ghost path may substitute a name. Collapsing that into one unconditional fallback
 * turns a refused rename into a silent rename to "workflow", which is this week's shape
 * again — the failure would render as success.
 *
 * Usage: node tools/_t562-workflow-id-helpers-cdp.mjs [--src <designer.html>]
 *   --src lets the teeth file (tools/_t562-workflow-id-helpers-teeth.sh) point the probe
 *   at a MUTATED copy and require it to go red. Default is the tree's real source.
 * Exit 0 = all legs pass.
 */

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

const srcFlag = process.argv.indexOf('--src');
const SRC = srcFlag > -1 && process.argv[srcFlag + 1]
  ? process.argv[srcFlag + 1]
  : join(REPO, 'src/aef-workflow-designer.html');

// Adversarial set. Every entry is here because some rule in the tree's history got it
// wrong: `_foo`/`__leading`/`___` are the leading-underscore hole the shipping :9162
// rule left open (it stripped `-` only); `trailing__` is the control that stops the fix
// from over-trimming, since a trailing `_` is LEGAL per the validator.
const ADVERSARIAL = ['_foo', '___', '__leading', '-x-', '', '   ', '!!!', 'Ünïcödé Näme',
                     '9lives', 'Cash to Ecwid stock sync', 'proc_stock_sync', 'trailing__',
                     'a', '_', '-_-_', 'My Map!'];

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const legs = [];
function leg(name, pass, detail) { legs.push({ name, pass: !!pass, detail }); }

async function main() {
  if (!existsSync(SRC)) throw new Error('source missing: ' + SRC);

  const doc = mkdtempSync(join(tmpdir(), 't562-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't562-repo-'));
  copyFileSync(SRC, join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't562-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl;
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const page = { webSocketDebuggerUrl: await pageWsUrl(dp) };
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    // ── leg 1: both helpers exist as functions in the loaded page ──────────────────
    const shapes = await ev(cmd, `({ san: typeof sanitizeWorkflowId, val: typeof isValidWorkflowId })`);
    leg('1 helpers defined in page', shapes.san === 'function' && shapes.val === 'function',
        `sanitizeWorkflowId=${shapes.san} isValidWorkflowId=${shapes.val}`);
    if (shapes.san !== 'function' || shapes.val !== 'function') return;

    // ── leg 2: the contract — sanitizer output always satisfies the validator ──────
    await ev(cmd, `window.__ADV__ = ${JSON.stringify(ADVERSARIAL)};`);
    const contract = await ev(cmd, `(function(){
      var bad = [];
      for (var i = 0; i < window.__ADV__.length; i++) {
        var x = window.__ADV__[i], out = sanitizeWorkflowId(x, 'workflow');
        if (!isValidWorkflowId(out)) bad.push([x, out]);
      }
      return { bad: bad, n: window.__ADV__.length };
    })()`);
    leg('2 sanitizer output always passes validator', contract.bad.length === 0,
        `${contract.n} adversarial inputs, ${contract.bad.length} invalid ${JSON.stringify(contract.bad)}`);

    // ── leg 3: the leading-underscore repair is DEMONSTRATED against the old rule ──
    // Reproduces the pre-fix :9162 rule in-page and requires it to fail where the
    // helper succeeds. Without this, "0 invalid" is also what a corpus that never
    // contains a leading underscore reports — which is exactly how the hole survived
    // the T-501 census.
    const repair = await ev(cmd, `(function(){
      function preFix(r){ return String(r || 'workflow').trim().toLowerCase()
        .replace(/[^a-z0-9_\\-]/g,'-').replace(/^-+|-+$/g,'') || 'workflow'; }
      var probes = ['_foo','___','__leading'], rows = [];
      for (var i=0;i<probes.length;i++){
        var p = probes[i];
        rows.push({ input:p, old:preFix(p), oldValid:isValidWorkflowId(preFix(p)),
                    now:sanitizeWorkflowId(p,'workflow'), nowValid:isValidWorkflowId(sanitizeWorkflowId(p,'workflow')) });
      }
      return rows;
    })()`);
    const repairOk = repair.every(r => r.oldValid === false && r.nowValid === true);
    leg('3 leading-separator hole closed (old rule shown failing)', repairOk,
        repair.map(r => `${JSON.stringify(r.input)} old=${JSON.stringify(r.old)}(${r.oldValid?'valid':'INVALID'}) now=${JSON.stringify(r.now)}(${r.nowValid?'valid':'INVALID'})`).join('; '));

    // ── leg 4: per-site fallback discrimination — THE load-bearing leg ─────────────
    const fb = await ev(cmd, `({
      renameEmpty:  sanitizeWorkflowId('!!!', ''),
      renameSpaces: sanitizeWorkflowId('   ', ''),
      ghost:        sanitizeWorkflowId('!!!', 'workflow'),
      realStillReal: sanitizeWorkflowId('Cash to Ecwid stock sync', '')
    })`);
    const fbOk = fb.renameEmpty === '' && fb.renameSpaces === '' && fb.ghost === 'workflow'
                 && fb.realStillReal === 'cash-to-ecwid-stock-sync';
    leg('4 empty fallback preserved for rename sites', fbOk,
        `rename('!!!')=${JSON.stringify(fb.renameEmpty)} rename('   ')=${JSON.stringify(fb.renameSpaces)} ghost('!!!')=${JSON.stringify(fb.ghost)} real=${JSON.stringify(fb.realStillReal)}`);

    // ── leg 5: exhaustive property — the fix is a strict repair ────────────────────
    // Over every string of length 0..4 from an alphabet covering each character class:
    // no invalid output, and no output that the OLD :9162 rule already got right is
    // changed. That is the statement "byte-identical where it already worked", proven
    // rather than sampled on the 30 ids the corpus happens to hold.
    const prop = await ev(cmd, `(function(){
      function preFix(r){ return String(r || 'workflow').trim().toLowerCase()
        .replace(/[^a-z0-9_\\-]/g,'-').replace(/^-+|-+$/g,'') || 'workflow'; }
      var alpha = ['a','9','_','-',' ','!','Ü',''], n=0, invalid=0, regress=0, wasValid=0, ex=null;
      (function rec(s,d){
        n++;
        var o = preFix(s), f = sanitizeWorkflowId(s,'workflow');
        if (!isValidWorkflowId(f)) { invalid++; if(!ex) ex = ['invalid', s, f]; }
        if (isValidWorkflowId(o)) { wasValid++; if (o !== f) { regress++; if(!ex) ex = ['regress', s, o, f]; } }
        if (d === 0) return;
        for (var i=0;i<alpha.length;i++) rec(s+alpha[i], d-1);
      })('', 4);
      return { n:n, invalid:invalid, regress:regress, wasValid:wasValid, ex:ex };
    })()`);
    leg('5 strict repair over exhaustive input space', prop.invalid === 0 && prop.regress === 0,
        `${prop.n} inputs; invalid=${prop.invalid}; already-valid outputs changed=${prop.regress}/${prop.wasValid}${prop.ex ? ' e.g. ' + JSON.stringify(prop.ex) : ''}`);

    // ── leg 6: the CALL SITE uses the helper (not just the helper being correct) ───
    // Drives a real rename. `_Bad Name` sanitizes to `bad-name`; under the pre-fix
    // inline rule at :2685 it would have become `_bad-name`, which the save guard
    // rejects. Asserting through renameActiveWorkflow is what distinguishes a wired
    // call site from a correct-but-uncalled helper (PL-148).
    const wired = await ev(cmd, `(function(){
      var before = state.workflowMeta.id;
      var ok = renameActiveWorkflow('_Bad Name');
      var after = state.workflowMeta.id;
      var refused = renameActiveWorkflow('!!!');          // unusable -> must REFUSE
      var afterRefuse = state.workflowMeta.id;
      return { before:before, ok:ok, after:after, valid:isValidWorkflowId(after),
               refused:refused, afterRefuse:afterRefuse };
    })()`);
    const wiredOk = wired.ok === true && wired.after === 'bad-name' && wired.valid === true
                    && wired.refused === false && wired.afterRefuse === 'bad-name';
    leg('6 renameActiveWorkflow routes through the helper', wiredOk,
        `'_Bad Name' -> ${JSON.stringify(wired.after)} (valid=${wired.valid}); '!!!' refused=${wired.refused}, id unchanged=${wired.afterRefuse === 'bad-name'}`);

    // ── leg 7: the save guard uses the validator ──────────────────────────────────
    const guard = await ev(cmd, `({ good: isValidWorkflowId('audit-process'), lead: isValidWorkflowId('_x'),
                                    dash: isValidWorkflowId('-x'), space: isValidWorkflowId('a b'),
                                    trail: isValidWorkflowId('trailing__') })`);
    const guardOk = guard.good === true && guard.lead === false && guard.dash === false
                    && guard.space === false && guard.trail === true;
    leg('7 validator discriminates (trailing _ legal, leading _ not)', guardOk, JSON.stringify(guard));

  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}

main().then(() => {
  for (const l of legs) console.log(`${l.pass ? 'PASS' : 'FAIL'}  ${l.name} — ${l.detail}`);
  const passed = legs.filter(l => l.pass).length;
  console.log(`\n${passed}/${legs.length} legs passed`);
  process.exit(passed === legs.length && legs.length === 7 ? 0 : 1);
}).catch(e => {
  for (const l of legs) console.log(`${l.pass ? 'PASS' : 'FAIL'}  ${l.name} — ${l.detail}`);
  console.error('ERROR: ' + (e && e.message ? e.message : e));
  process.exit(2);
});
