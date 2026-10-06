#!/usr/bin/env node
// _t1067-side-label-wrap-cdp.mjs — a side-placed event label that collides is tried as a wrapped block (832 T-1067).
//
// The independent reviewer (fw reviewer judge T-600, RED) found that the operator's own sentence
// "run halted - operator kill switch" never wrapped: it is under wrapOverlongBelowLabels()'s fixed
// width cap, so it stayed one line beside its shape over the neighbouring task, Wrap on or off.
// T-1067 lets adjustLabelPlacements() try the name as a 2- or 3-line block when every single-line
// placement collides, keeping it only when the measured score is STRICTLY better.
//
// Stimulus: the editor's default document, end event "Ready" (badge hum_2_ready, human lane),
// renamed to the operator's sentence — exactly the reviewer's reproduction.
//   L1  CONTROL: the editor BEFORE T-1067 (git HEAD~ copy, or --before PATH) keeps ONE line and collides
//   L2  the current editor wraps it (>= 2 name lines)
//   L3  the current editor's collision score is strictly lower than before
//   L4  with "Wrap long labels" OFF the current editor keeps one line (the preference is respected)
//   L5  a short name ("Ready") is untouched: one line, same placement as before (T-105)
//   L6  the settings controls show the stored prefs on load (reviewer side finding), current editor only
//   --shots DIR  also saves element screenshots of the label at sizes S/M/L, wrap on and off (visual check)
// exit 0 = all legs pass; 1 = a leg failed; 2 = CANNOT RUN
import { spawn, execFileSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SRC = join(REPO, 'src', 'aef-workflow-designer.html');
const SENTENCE = 'run halted - operator kill switch';
const BADGE = 'hum_2_ready';
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright');
  const c = existsSync(cache) ? readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse()
    .map(d => join(cache, d, 'chrome-linux64', 'chrome')).filter(existsSync) : [];
  if (!c.length) throw new Error('No Chromium under ' + cache);
  return c[0];
}

// Rename the node with badge BADGE, render, and score the final label block the way
// adjustLabelPlacements does for edges and nodes (pool furniture is not needed for the claim).
const probe = (name, wrap) => `(function(){ try {
  labelPrefs.wrapNames = ${wrap};
  var n = state.nodes.filter(function(x){ var b=document.querySelector('text.node-id-badge[data-nl="'+x.uid+'"]'); return b && b.textContent===${JSON.stringify(BADGE)}; })[0];
  if (!n) return {ok:false, error:'no node with badge ${BADGE}'};
  n.name = ${JSON.stringify(name)};
  renderAll();
  var lines = Array.prototype.slice.call(document.querySelectorAll('text.node-label[data-nl="'+n.uid+'"]'));
  var score = 0;
  lines.forEach(function(t){
    var bb = t.getBBox(); if (!bb.width) return;
    var r = {x1:bb.x-1, x2:bb.x+bb.width+1, y1:bb.y-1, y2:bb.y+bb.height+1};
    state.edges.forEach(function(e){ var pl=e._renderedPolyline; if(!pl) return;
      for (var i=0;i<pl.length-1;i++){ var a=pl[i], b=pl[i+1];
        if (Math.max(a.x,b.x) < r.x1 || Math.min(a.x,b.x) > r.x2 || Math.max(a.y,b.y) < r.y1 || Math.min(a.y,b.y) > r.y2) continue; score++; } });
    state.nodes.forEach(function(m){ if (m===n) return; var d=NODE_DEFAULTS[m.type];
      if (m.x+d.w+4 < r.x1 || m.x-4 > r.x2) return; if (nodeVisualBottom(m) < r.y1 || m.y-4 > r.y2) return; score++; });
  });
  return {ok:true, nLines:lines.length, score:score, x:lines[0]&&lines[0].getAttribute('x'), anchor:lines[0]&&lines[0].getAttribute('text-anchor'),
          text: lines.map(function(t){return t.textContent;})};
} catch(e) { return {ok:false, error:String(e&&e.stack||e)}; } })()`;

let shotsDir = null;
async function measure(editorPath, tag) {
  const udd = mkdtempSync(join(tmpdir(), 't1067-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1600,1000',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let ws;
  try {
    let port; for (let i = 0; i < 200 && !port; i++) { try { port = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0]); } catch (_) { await sleep(100); } }
    if (!port) throw new Error('Chromium DevTools port timeout');
    ws = new WebSocket(await pageWsUrl(port)); let id = 0; const p = new Map();
    ws.addEventListener('message', e => { const m = JSON.parse(e.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } });
    await new Promise(r => ws.addEventListener('open', r));
    const cmd = (method, params = {}) => new Promise((res, rej) => { const i = ++id; p.set(i, m => m.error ? rej(new Error(method + ': ' + m.error.message)) : res(m.result)); ws.send(JSON.stringify({ id: i, method, params })); });
    const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true }); return r.result.value; };
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: 'file://' + editorPath });
    for (let i = 0; ; i++) {
      if (await ev("typeof _appReady!=='undefined'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null)").catch(() => false)) break;
      if (i > 200) throw new Error('editor not ready');
      await sleep(150);
    }
    const out = {};
    out.long = await ev(probe(SENTENCE, true));
    out.off = await ev(probe(SENTENCE, false));
    out.short = await ev(probe('Ready', true));
    out.ui = await ev("({pref: labelPrefs.wrapNames, box: document.getElementById('set-wrap-labels').checked, size: labelPrefs.size, sel: document.getElementById('set-label-size').value})");
    if (shotsDir) {
      for (const size of ['s', 'm', 'l']) for (const wrap of [true, false]) {
        await ev(`(labelPrefs.size=${JSON.stringify(size)}, 0)`);
        const r = await ev(probe(SENTENCE, wrap) + `; (function(){ var n=state.nodes.filter(function(x){var b=document.querySelector('text.node-id-badge[data-nl="'+x.uid+'"]');return b&&b.textContent===${JSON.stringify(BADGE)};})[0];
          var t=document.querySelector('text.node-label[data-nl="'+n.uid+'"]'); var r=t.getBoundingClientRect(); return {x:r.x,y:r.y}; })()`);
        await cmd('Page.bringToFront');
        const shot = await cmd('Page.captureScreenshot', { format: 'png', clip: { x: Math.max(0, r.x - 260), y: Math.max(0, r.y - 120), width: 520, height: 260, scale: 2 } });
        writeFileSync(join(shotsDir, `t1067-${tag}-${size}-wrap${wrap ? 'ON' : 'OFF'}.png`), Buffer.from(shot.data, 'base64'));
      }
      await ev(`(labelPrefs.size='m', 0)`);
    }
    return out;
  } finally { try { ws && ws.close(); } catch (_) {} br.kill(); await sleep(300); try { rmSync(udd, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 }); } catch (_) {} }
}

async function main() {
  const bi = process.argv.indexOf('--before');
  let before = bi > -1 ? process.argv[bi + 1] : null;
  const tmp = mkdtempSync(join(tmpdir(), 't1067-src-'));
  try {
    if (!before) {
      // the editor as it was before T-1067: the last commit whose src has no T-1067 marker
      const revs = execFileSync('git', ['-C', REPO, 'log', '--format=%H', '-n', '20', '--', 'src/aef-workflow-designer.html']).toString().trim().split('\n');
      let pick = null;
      for (const r of revs) { const s = execFileSync('git', ['-C', REPO, 'show', `${r}:src/aef-workflow-designer.html`], { maxBuffer: 64e6 }).toString(); if (!s.includes('T-1067')) { pick = s; break; } }
      if (!pick) { console.log('CANNOT RUN: no pre-T-1067 editor found in the last 20 commits'); return 2; }
      before = join(tmp, 'before.html'); writeFileSync(before, pick);
    }
    const si = process.argv.indexOf('--shots'); if (si > -1) shotsDir = process.argv[si + 1];
    const a = await measure(before, 'before'), b = await measure(SRC, 'after');
    for (const x of [a.long, a.off, a.short, b.long, b.off, b.short]) if (!x || !x.ok) { console.log('CANNOT RUN: ' + JSON.stringify(x)); return 2; }
    const legs = [];
    const leg = (ok, name, d) => legs.push(`${ok ? 'PASS' : 'FAIL'}  ${name} — ${d}`);
    leg(a.long.nLines === 1 && a.long.score > 0, 'L1 CONTROL: before T-1067 the sentence stays one line and collides', JSON.stringify(a.long));
    leg(b.long.nLines >= 2, 'L2 now it wraps into a block', JSON.stringify(b.long));
    leg(b.long.score < a.long.score, 'L3 the collision score is strictly lower than before', `${a.long.score} -> ${b.long.score}`);
    leg(b.off.nLines === 1, "L4 with 'Wrap long labels' off it stays one line", JSON.stringify(b.off));
    leg(b.short.nLines === 1 && b.short.x === a.short.x && b.short.anchor === a.short.anchor, 'L5 a short name is untouched (T-105)', `${JSON.stringify(a.short)} vs ${JSON.stringify(b.short)}`);
    leg(b.ui.box === b.ui.pref && b.ui.sel === b.ui.size, 'L6 settings controls show the stored prefs on load', JSON.stringify(b.ui));
    console.log(legs.join('\n'));
    const bad = legs.filter(l => l.startsWith('FAIL')).length;
    console.log(bad ? `\n${bad} leg(s) failed` : `\n${legs.length}/${legs.length} T-1067 legs passed`);
    return bad ? 1 : 0;
  } catch (e) { console.log('CANNOT RUN: ' + e.message); return 2; }
  finally { rmSync(tmp, { recursive: true, force: true }); }
}
main().then(rc => process.exit(rc));
