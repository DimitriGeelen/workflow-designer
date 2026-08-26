#!/usr/bin/env node
// _t600-label-wrap.mjs — runtime verifier for T-600 (overlong below-label wrapping).
//
// Loads the REAL editor in headless Chromium (PL-005: the editor's own render is the
// only honest oracle) and MEASURES rendered text (PL-008: char estimates lie), because
// the defect is a width overrun, not a structural one.
//
// Legs (all must pass):
//   L1  a long event/gateway name wraps onto >= 2 lines with wrapNames on
//   L2  every wrapped line MEASURES at or under the size-scaled cap
//   L3  the id badge sits below the wrapped block, not on top of it
//   L4  a short name stays on exactly ONE line (T-105's contract is preserved)
//   L5  with wrapNames off the same long name is ONE line wider than the cap
//       (the option really switches, and the measurement can produce a failing value)
//   L6  wrapOverlongBelowLabels() is called BEFORE deCollideBelowLabels() and
//       adjustLabelPlacements() — side placement re-stacks, it never re-wraps
//   L7  adjustLabelPlacements() preserves the wrapped line count
//
// --self-test loads a POISONED copy of the editor with the wrap call removed and
// requires L1/L2/L3/L7 to FAIL there. A leg that cannot fail asserts nothing (T-592).
//
// Usage:  node tools/_t600-label-wrap.mjs [--self-test]
// Exit:   0 pass · 1 leg failed · 2 driver/integrity error
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve } from 'node:path';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = join(ROOT, 'src', 'aef-workflow-designer.html');
const LONG = 'run halted because the operator pressed the kill switch';
const SHORT = 'Join';

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright');
  const cands = [];
  if (existsSync(cache)) for (const d of readdirSync(cache))
    if (d.startsWith('chromium-')) cands.push(join(cache, d, 'chrome-linux64', 'chrome'));
  cands.sort().reverse();
  for (const c of cands) if (existsSync(c)) return c;
  throw new Error('No Chromium under ' + cache);
}
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function waitForPortFile(f, timeoutMs = 20000) {
  const t0 = Date.now();
  for (;;) {
    if (existsSync(f)) {
      const first = readFileSync(f, 'utf8').split('\n')[0];
      if (first && first.trim()) return parseInt(first.trim(), 10);
    }
    if (Date.now() - t0 > timeoutMs) throw new Error('Chromium DevTools port timeout');
    await sleep(100);
  }
}
function cdpClient(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0; const pending = new Map();
  ws.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } });
  const ready = new Promise((res, rej) => { ws.addEventListener('open', res); ws.addEventListener('error', () => rej(new Error('CDP ws error'))); });
  const cmd = (method, params = {}) => new Promise((res, rej) => {
    const mid = ++id;
    pending.set(mid, m => m.error ? rej(new Error(method + ': ' + JSON.stringify(m.error))) : res(m.result));
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  return { ready, cmd, close: () => ws.close() };
}
async function evalJson(cmd, expression) {
  const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error('eval threw: ' + JSON.stringify(r.exceptionDetails).slice(0, 400));
  return r.result.value;
}

// Rename the first label-below node to `name`, re-render, and read back MEASURED lines.
const probeExpr = (name, wrap) => `(function(){ try{
  labelPrefs.wrapNames = ${wrap ? 'true' : 'false'};
  var isBelow=function(n){ return n.type==='startEvent'||n.type==='endEvent'||
    /Gateway$/.test(n.type)||/^linkEvent/.test(n.type)||/^event/.test(n.type); };
  var n=state.nodes.filter(isBelow)[0];
  if(!n) return {ok:false,error:'no label-below node in the default document'};
  n.name=${JSON.stringify(name)};
  renderAll();
  // id badges are re-parented into gBadges/gBadgesTop by layerIdBadges(), so the
  // badge leg must look at the whole document, not at gNodes.
  var all=Array.prototype.slice.call(document.querySelectorAll('text[data-nl="'+n.uid+'"]'));
  var lines=all.filter(function(t){return t.getAttribute('class')==='node-label';});
  var idEl=all.filter(function(t){return t.getAttribute('class')==='node-id-badge';})[0];
  var cap={s:150,m:165,l:180}[labelPrefs.size];
  var widths=lines.map(function(t){return Math.round(t.getComputedTextLength());});
  var ys=lines.map(function(t){return +t.getAttribute('y');});
  // Snapshot every measurement BEFORE re-running the placement pass — that pass
  // MUTATES the same y attributes, and reading them afterwards would report the
  // side-placed stack while claiming to describe the below-placed one.
  var idY=idEl?+idEl.getAttribute('y'):null;
  var before=lines.length;
  adjustLabelPlacements();
  var after=gNodes.querySelectorAll('text[data-nl="'+n.uid+'"].node-label').length;
  return {ok:true, uid:n.uid, cap:cap, nLines:lines.length, widths:widths,
          maxY:Math.max.apply(null,ys), idY:idY,
          afterPlacement:after, beforePlacement:before};
}catch(e){ return {ok:false,error:String(e&&e.stack||e)}; } })()`;

async function runProbes(editorPath) {
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't600-chrome-'));
  const proc = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let client;
  try {
    const port = await waitForPortFile(join(udd, 'DevToolsActivePort'));
    const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    client = cdpClient(targets.find(t => t.type === 'page').webSocketDebuggerUrl);
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: 'file://' + editorPath });
    const t0 = Date.now();
    for (;;) {
      if (await evalJson(cmd, `(typeof renderAll==='function' && typeof state==='object' && !!state && !!state.nodes)`)) break;
      if (Date.now() - t0 > 25000) throw new Error('editor load timeout');
      await sleep(150);
    }
    return {
      long: await evalJson(cmd, probeExpr(LONG, true)),
      short: await evalJson(cmd, probeExpr(SHORT, true)),
      off: await evalJson(cmd, probeExpr(LONG, false)),
    };
  } finally {
    try { client && client.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}

// Legs that the poisoned build must break. Returns [{id, ok, detail}].
function measuredLegs(r) {
  const L = [];
  const long = r.long, short = r.short, off = r.off;
  for (const [k, v] of Object.entries(r))
    if (!v || !v.ok) return [{ id: 'probe:' + k, ok: false, detail: (v && v.error) || 'probe returned nothing' }];
  L.push({ id: 'L1', ok: long.nLines >= 2, detail: `long name rendered ${long.nLines} line(s)` });
  L.push({ id: 'L2', ok: long.widths.every(w => w <= long.cap), detail: `line widths ${long.widths.join(',')} vs cap ${long.cap}` });
  L.push({ id: 'L3', ok: long.idY !== null && long.idY > long.maxY, detail: `id badge y=${long.idY}, last name line y=${long.maxY}` });
  L.push({ id: 'L7', ok: long.afterPlacement === long.beforePlacement && long.beforePlacement >= 2,
           detail: `lines ${long.beforePlacement} -> ${long.afterPlacement} across adjustLabelPlacements()` });
  L.push({ id: 'L4', ok: short.nLines === 1, detail: `short name rendered ${short.nLines} line(s)` });
  L.push({ id: 'L5', ok: off.nLines === 1 && off.widths[0] > off.cap,
           detail: `wrapNames=false -> ${off.nLines} line(s), width ${off.widths[0]} vs cap ${off.cap}` });
  return L;
}

function sourceOrderLeg() {
  const src = readFileSync(EDITOR, 'utf8');
  const w = src.indexOf('  wrapOverlongBelowLabels();');
  const d = src.indexOf('  deCollideBelowLabels();');
  const a = src.indexOf('  adjustLabelPlacements();');
  return { id: 'L6', ok: w > 0 && d > 0 && a > 0 && w < d && w < a,
           detail: `call offsets wrap=${w} deCollide=${d} placements=${a}` };
}

async function main() {
  const selfTest = process.argv.includes('--self-test');
  const report = (legs) => { for (const l of legs) console.log(`  ${l.ok ? 'PASS' : 'FAIL'}  ${l.id}  ${l.detail}`); };

  console.log('T-600 label wrap — measured legs');
  const live = await runProbes(EDITOR);
  const legs = measuredLegs(live).concat([sourceOrderLeg()]);
  legs.sort((x, y) => x.id.localeCompare(y.id));
  report(legs);
  const failed = legs.filter(l => !l.ok);

  if (!selfTest) {
    console.log(failed.length ? `FAIL — ${failed.length} leg(s)` : `PASS — ${legs.length} leg(s)`);
    process.exit(failed.length ? 1 : 0);
  }

  // Two poison arms. One removal cannot break every leg: L1/L2/L7 are about the wrap
  // happening at all, L3 is about the ORDER the wrapped lines are inserted in — with a
  // single unwrapped line the badge is trivially below the name, so arm A cannot
  // exercise L3 and arm B exists to do exactly that.
  const src = readFileSync(EDITOR, 'utf8');
  const CALL = '  wrapOverlongBelowLabels();';
  const ORDER = 'if (idEl && idEl.parentNode === g) g.insertBefore(t, idEl); else g.appendChild(t);';
  if (!src.includes(CALL) || !src.includes(ORDER)) {
    console.log('SELF-TEST INTEGRITY FAIL — a poison target is missing from the editor source');
    process.exit(2);
  }
  const arms = [
    { name: 'A — wrap pass never invoked', patched: src.replace(CALL, '  /* T-600 poison A */'), mustFail: ['L1', 'L2', 'L7'] },
    { name: 'B — wrapped lines appended AFTER the id badge', patched: src.replace(ORDER, 'g.appendChild(t);'), mustFail: ['L3'] },
  ];
  const dir = mkdtempSync(join(tmpdir(), 't600-poison-'));
  let armed = 0;
  for (const arm of arms) {
    const f = join(dir, `poison-${arm.mustFail.join('')}.html`);
    writeFileSync(f, arm.patched);
    console.log(`\npoison arm ${arm.name} — ${arm.mustFail.join(',')} must FAIL`);
    const pLegs = measuredLegs(await runProbes(f));
    report(pLegs);
    const survivors = pLegs.filter(l => arm.mustFail.includes(l.id) && l.ok).map(l => l.id);
    const brokenControls = pLegs.filter(l => ['L4', 'L5'].includes(l.id) && !l.ok).map(l => l.id);
    if (failed.length) { console.log(`\nFAIL — ${failed.length} live leg(s)`); process.exit(1); }
    if (survivors.length) { console.log(`\nSELF-TEST FAIL — ${survivors.join(',')} passed under poison; ${survivors.length} leg(s) assert nothing`); process.exit(2); }
    if (brokenControls.length) { console.log(`\nSELF-TEST FAIL — control leg(s) ${brokenControls.join(',')} broke under poison; they are not independent of it`); process.exit(2); }
    armed += arm.mustFail.length;
  }
  if (failed.length) { console.log(`\nFAIL — ${failed.length} live leg(s)`); process.exit(1); }
  console.log(`\nPASS — ${legs.length} live leg(s); ${armed} leg(s) proven failable across ${arms.length} poison arm(s)`);
}
main().catch(e => { console.error('DRIVER ERROR: ' + (e && e.stack || e)); process.exit(2); });
