#!/usr/bin/env node
/**
 * _t358-export-determinism.mjs — is buildBpmnXml DETERMINISTIC for the same input?
 *
 * Found while measuring T-358's repair candidates: a cross-build byte comparison was
 * reporting spurious "output changed" on one fixture. The instrument self-check
 * (emit the same document twice in the SAME build) showed the build is not
 * byte-stable with itself on that document — so the comparison was void, not the
 * candidate faulty.
 *
 * This matters well beyond T-358: `_t308` byte-identity (24/24) is the gate this
 * whole arc uses to prove a change moves no bytes. If export is nondeterministic for
 * some class of input, that gate is sound only for the class it happens to cover.
 *
 * Reports, per document: whether two consecutive parse->emit cycles agree, and if
 * not, the first differing line.
 *
 * Usage: node tools/_t358-export-determinism.mjs
 * Exit 0 = every document emitted identically twice. Exit 1 = at least one did not.
 */

import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');

const DOCS = [
  ['lane-provenance/authored-lanes.bpmn', join(REPO, 'tests/fixtures/lane-provenance/authored-lanes.bpmn')],
  ['lane-provenance/no-laneset.bpmn',     join(REPO, 'tests/fixtures/lane-provenance/no-laneset.bpmn')],
  ['third-party/simple.bpmn',             join(REPO, 'tests/fixtures/third-party/simple.bpmn')],
  ['third-party/kitchen-sink.bpmn',       join(REPO, 'tests/fixtures/third-party/kitchen-sink.bpmn')],
  ['corpus/audit-process.bpmn',           join(REPO, 'examples/aef-processes/rendered/audit-process.bpmn')],
  ['corpus/arc-lifecycle.bpmn',           join(REPO, 'examples/aef-processes/rendered/arc-lifecycle.bpmn')],
];

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

async function main() {
  const doc = mkdtempSync(join(tmpdir(), 't358-det-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't358-det-repo-'));
  writeFileSync(join(doc, 'designer.html'), readFileSync(join(REPO, 'src/aef-workflow-designer.html'), 'utf8'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't358-det-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl; const rows = [];
  try {
    let up = false;
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    for (const [label, path] of DOCS) {
      if (!existsSync(path)) { rows.push({ label, skip: 'missing' }); continue; }
      await ev(cmd, `window.__IN__ = ${JSON.stringify(readFileSync(path, 'utf8'))};`);
      const r = await ev(cmd, `(function(){
        function once(){ var prev=state; var m=parseBpmnXml(window.__IN__); if(!m) return null;
          state=m; var x=buildBpmnXml(state); state=prev; return x; }
        var a = once(), b = once();
        if (a===null||b===null) return { fatal:'parse returned null' };
        if (a === b) return { same:true, len:a.length };
        var la=a.split('\\n'), lb=b.split('\\n'), i=0;
        while(i<la.length && i<lb.length && la[i]===lb[i]) i++;
        // Classify every differing line. uid is the tie-breaker in computeDisplayId's
        // sort and displayIds ARE emitted, so a random uid could in principle permute
        // emitted element ids too. "All differing lines are uid lines" is the claim
        // that bounds the defect to aef:uid values; anything else is a wider defect.
        var uidDiff = 0, otherDiff = 0, otherSample = null;
        for (var j=0;j<Math.max(la.length,lb.length);j++){
          if (la[j] === lb[j]) continue;
          if (/<aef:uid\\b/.test(la[j]||'') && /<aef:uid\\b/.test(lb[j]||'')) uidDiff++;
          else { otherDiff++; if(!otherSample) otherSample = { a:(la[j]||'').trim().slice(0,130), b:(lb[j]||'').trim().slice(0,130) }; }
        }
        return { same:false, len:a.length, lineNo:i+1,
                 a:(la[i]||'').trim().slice(0,150), b:(lb[i]||'').trim().slice(0,150),
                 totalDiff: la.filter(function(l,j){return l!==lb[j];}).length,
                 uidDiff: uidDiff, otherDiff: otherDiff, otherSample: otherSample };
      })()`);
      rows.push({ label, ...r });
    }
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  console.log('\nIs buildBpmnXml deterministic? (same document, two consecutive parse->emit cycles)\n');
  let bad = 0, wider = 0;
  for (const r of rows) {
    if (r.skip) { console.log(`  ${r.label.padEnd(38)} SKIP (${r.skip})`); continue; }
    if (r.fatal) { console.log(`  ${r.label.padEnd(38)} FATAL ${r.fatal}`); bad++; continue; }
    if (r.same) { console.log(`  ${r.label.padEnd(38)} stable   (${r.len} bytes)`); continue; }
    bad++;
    console.log(`  ${r.label.padEnd(38)} NOT STABLE — ${r.totalDiff} line(s) differ, first at line ${r.lineNo}`);
    console.log(`      run 1: ${r.a}`);
    console.log(`      run 2: ${r.b}`);
    console.log(`      of those: ${r.uidDiff} aef:uid line(s), ${r.otherDiff} other`);
    if (r.otherDiff) {
      wider++;
      console.log(`      *** NOT confined to uid values — a non-uid line moved:`);
      console.log(`          run 1: ${r.otherSample.a}`);
      console.log(`          run 2: ${r.otherSample.b}`);
    }
  }
  console.log();
  if (bad) {
    console.log(`  ${bad} document(s) do not emit deterministically.`);
    console.log('  Any byte-identity claim is scoped to the class of document that IS stable —');
    console.log('  it cannot speak for the rest. _t308 covers designer-produced corpus maps.');
    if (wider) {
      console.log(`\n  ${wider} document(s) drift on a NON-uid line. The defect is wider than`);
      console.log('  "aef:uid values churn": uid is the tie-breaker in computeDisplayId\'s sort and');
      console.log('  displayIds are emitted, so a uid-only normaliser (tools/_t358-byteid-thirdparty.mjs)');
      console.log('  is NOT sufficient for these documents and any claim resting on it must be re-run.');
    } else {
      console.log('\n  Every differing line is an aef:uid line: on THIS corpus the nondeterminism is');
      console.log('  confined to uid values, so a uid-normalising comparison is sound for it. This is');
      console.log('  a measured property of these documents, not a proof that a displayId tie cannot');
      console.log('  permute emitted ids on some other document.');
    }
    return 1;
  }
  console.log('  All documents emit deterministically.');
  return 0;
}

main().then(c => process.exit(c)).catch(e => { console.error('ERROR: ' + (e && e.message)); process.exit(2); });
