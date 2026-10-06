#!/usr/bin/env node
// _t1068-corpus-labels.mjs — corpus guard for event/gateway label placement (T-1068, T-601).
//
// Adapted from the independent reviewer's probe on T-601 (.context/reviews/evidence/T-601/
// rev-probe-judge-t-601-r1-b0c0fde028d9.mjs). Loads every map in examples/aef-processes/rendered
// into the REAL editor, measures every event/gateway label block (name lines + id badge) against
// the lane furniture READ FROM THE DOM (g.lane-header > rect), not from the scorer's own arithmetic.
//
// Legs:
//   C1  no label line is drawn under another node's shape (hidden text) on any corpus map
//   C2  the four labels the reviewer named stay fixed:
//         session-capture n_start, git-commit-flow n_start, arc-lifecycle n_req  — not under a shape
//         session-capture g_found                                               — inside its own lane
//   C3  at most 1 label touches the lane header strip (only where nothing else is legible)
//
// --self-test reruns on a poisoned editor: the T-1068 occlusion weights reverted to a flat 1 per
// node and no own-shape term. C1 and C2 must FAIL there, or they assert nothing (T-592).
//
// Usage:  node tools/_t1068-corpus-labels.mjs [--self-test]
// Exit:   0 pass · 1 leg failed · 2 driver/integrity error
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = join(ROOT, 'src', 'aef-workflow-designer.html');
const MAPDIR = join(ROOT, 'examples', 'aef-processes', 'rendered');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function chrome() {
  const c = join(homedir(), '.cache', 'ms-playwright');
  if (!existsSync(c)) return null;
  return readdirSync(c).filter(d => d.startsWith('chromium-')).sort().reverse()
    .map(d => join(c, d, 'chrome-linux64', 'chrome')).find(existsSync) || null;
}

const measure = `(function(){
  labelPrefs.wrapNames = true;
  var isB=function(n){ return n.type==='startEvent'||n.type==='endEvent'||/Gateway$/.test(n.type)||/^linkEvent/.test(n.type)||/^event/.test(n.type); };
  renderAll();
  var hdr=Array.prototype.slice.call(document.querySelectorAll('g.lane-header > rect')).map(function(r){
    return {x1:+r.getAttribute('x'), x2:+r.getAttribute('x')+(+r.getAttribute('width')), y1:+r.getAttribute('y'), y2:+r.getAttribute('y')+(+r.getAttribute('height'))}; });
  if(!hdr.length) return {out:[]};
  var hx2=hdr[0].x2, top=hdr[0].y1, bot=hdr[hdr.length-1].y2, out=[];
  state.nodes.filter(isB).forEach(function(n){
    var d=NODE_DEFAULTS[n.type], cy=n.y+d.h/2;
    var own=hdr.find(function(b){return cy>=b.y1&&cy<b.y2;});
    var rs=Array.prototype.slice.call(document.querySelectorAll('text[data-nl="'+n.uid+'"]')).map(function(t){return t.getBBox();}).filter(function(b){return b.width>0;});
    if(!rs.length) return;
    var x1=Math.min.apply(null,rs.map(function(b){return b.x;}));
    var y1=Math.min.apply(null,rs.map(function(b){return b.y;})), y2=Math.max.apply(null,rs.map(function(b){return b.y+b.height;}));
    var under=0; state.nodes.forEach(function(m){ if(m===n) return; var dm=NODE_DEFAULTS[m.type];
      rs.forEach(function(b){ if(b.x+b.width>m.x+1&&b.x<m.x+dm.w-1&&b.y+b.height>m.y+1&&b.y<m.y+dm.h-1) under++; }); });
    out.push({uid:n.uid, under:under, header:(x1<hx2&&y2>top&&y1<bot), lane:!!(own&&(y1<own.y1-1||y2>own.y2+1))});
  });
  return {out:out};
})()`;

async function probe(editorPath) {
  const exe = chrome();
  if (!exe) throw new Error('no Playwright chromium under ~/.cache/ms-playwright');
  const udd = mkdtempSync(join(tmpdir(), 't1068-corpus-'));
  const proc = spawn(exe, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let ws;
  try {
    let port;
    for (let i = 0; i < 400 && !port; i++) {
      const f = join(udd, 'DevToolsActivePort');
      if (existsSync(f)) port = +readFileSync(f, 'utf8').split('\n')[0] || undefined;
      await sleep(100);
    }
    if (!port) throw new Error('chromium did not open a DevTools port');
    ws = new WebSocket(await pageWsUrl(port));
    let id = 0; const pend = new Map();
    const cmd = (method, params = {}) => new Promise((res, rej) => { const k = ++id;
      pend.set(k, m => m.error ? rej(new Error(method + JSON.stringify(m.error))) : res(m.result));
      ws.send(JSON.stringify({ id: k, method, params })); });
    ws.addEventListener('message', ev => { const m = JSON.parse(ev.data);
      if (m.id && pend.has(m.id)) { pend.get(m.id)(m); pend.delete(m.id); }
      if (m.method === 'Page.javascriptDialogOpening') cmd('Page.handleJavaScriptDialog', { accept: true }); });
    await new Promise((r, j) => { ws.addEventListener('open', r); ws.addEventListener('error', () => j(new Error('CDP ws error'))); });
    const ev = async (expression) => { const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
      if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 500)); return r.result.value; };
    await cmd('Page.enable'); await cmd('Runtime.enable');
    // Same viewport as the reviewer's probe: the canvas width feeds contentRightEdge() and so the pool.
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1600, height: 1000, deviceScaleFactor: 2, mobile: false });
    const rows = {};
    for (const m of readdirSync(MAPDIR).filter(f => f.endsWith('.bpmn')).sort()) {
      await cmd('Page.navigate', { url: 'file://' + editorPath });
      for (let t0 = Date.now(); ; ) {
        if (await ev(`typeof renderAll==='function'&&typeof adoptImportedXml==='function'&&typeof state!=='undefined'&&!!state&&window._deepLinkSettled!==null`).catch(() => false)) break;
        if (Date.now() - t0 > 40000) throw new Error('editor load timeout'); await sleep(150);
      }
      const xml = readFileSync(join(MAPDIR, m), 'utf8');
      await ev(`(function(){ try{ localStorage.clear(); }catch(e){} adoptImportedXml(${JSON.stringify(xml)}, {userImport:true}); return 1; })()`);
      for (const o of (await ev(measure)).out) rows[m.replace('.bpmn', '') + '/' + o.uid] = o;
    }
    return rows;
  } finally {
    try { ws && ws.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}

const NAMED_UNDER = ['session-capture/n_start', 'git-commit-flow/n_start', 'arc-lifecycle/n_req'];
const NAMED_LANE = ['session-capture/g_found'];

function legs(rows) {
  const keys = Object.keys(rows);
  const under = keys.filter(k => rows[k].under > 0);
  const header = keys.filter(k => rows[k].header);
  const missing = NAMED_UNDER.concat(NAMED_LANE).filter(k => !rows[k]);
  const named = NAMED_UNDER.filter(k => rows[k] && rows[k].under > 0)
    .concat(NAMED_LANE.filter(k => rows[k] && rows[k].lane));
  return [
    { id: 'C1', ok: keys.length > 0 && under.length === 0, detail: `${keys.length} labels; under a shape: ${under.length ? under.join(', ') : 'none'}` },
    { id: 'C2', ok: !missing.length && !named.length, detail: missing.length ? `named label(s) not found: ${missing.join(', ')}` : `named labels regressed: ${named.length ? named.join(', ') : 'none'}` },
    { id: 'C3', ok: header.length <= 1, detail: `on the header strip: ${header.length} (${header.join(', ') || 'none'}), limit 1` },
  ];
}
const report = ls => { for (const l of ls) console.log(`  ${l.ok ? 'PASS' : 'FAIL'}  ${l.id}  ${l.detail}`); };

async function main() {
  const selfTest = process.argv.includes('--self-test');
  console.log('T-1068 corpus label placement — measured on every rendered map');
  const live = legs(await probe(EDITOR));
  report(live);
  const failed = live.filter(l => !l.ok);
  if (!selfTest) {
    console.log(failed.length ? `FAIL — ${failed.length} leg(s)` : `PASS — ${live.length} leg(s)`);
    process.exit(failed.length ? 1 : 0);
  }
  const src = readFileSync(EDITOR, 'utf8');
  const OWN = '      if (n === self) { if (onShape(r, n, d)) cost += 6; continue; }\n';
  const OTHER = '      cost += onShape(r, n, d) ? 6 : 1;\n';
  if (!src.includes(OWN) || !src.includes(OTHER)) { console.log('SELF-TEST INTEGRITY FAIL — a poison target is missing from the editor source'); process.exit(2); }
  const f = join(mkdtempSync(join(tmpdir(), 't1068-poison-')), 'poisoned-editor.html');
  writeFileSync(f, src.replace(OWN, '      if (n === self) continue;\n').replace(OTHER, '      cost += 1;\n'));
  console.log('\npoison arm — occlusion weights reverted to a flat 1, no own-shape term; C1, C2 must FAIL');
  const pl = legs(await probe(f));
  report(pl);
  if (failed.length) { console.log(`\nFAIL — ${failed.length} live leg(s)`); process.exit(1); }
  const survivors = pl.filter(l => ['C1', 'C2'].includes(l.id) && l.ok).map(l => l.id);
  if (survivors.length) { console.log(`\nSELF-TEST FAIL — ${survivors.join(',')} passed under poison; they assert nothing`); process.exit(2); }
  console.log(`\nPASS — ${live.length} live leg(s); 2 proven failable`);
}
main().catch(e => { console.error('DRIVER ERROR: ' + (e && e.stack || e)); process.exit(2); });
