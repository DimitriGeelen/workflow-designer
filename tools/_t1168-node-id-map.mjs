#!/usr/bin/env node
// _t1168-node-id-map.mjs — T-1168: for every map in examples/aef-processes/rendered/, load it in the designer and
// record which node ids the activities-only numbering changes (old id in the file -> id the designer now exports).
// Pairs old and new through the node's uid (<aef:uid>, or the uid the importer derives from the old id), so a
// renumbering that reuses a number for another node is mapped by NODE, never by number.
//
// The corpus is NOT byte-identical to today's export even before this change: bake-clean-layout.py baked it
// from an older designer (no exporter= attribute, conditionExpression placed differently). Re-baking would
// carry that unrelated drift, so the corpus is migrated by renaming ids IN PLACE (whole tokens) and nothing
// else. The check is therefore: every node id the designer now exports appears as an element id in the renamed
// file, and no old id that was renamed survives in it. `pureRename` additionally reports byte equality with the
// export, for information.
//
//   node tools/_t1168-node-id-map.mjs <out.json> [--write]
//   node tools/_t1168-node-id-map.mjs --check
// --write rewrites each changed map in place with the id substitution, only when its ids are consistent.
// --check (standing guard, wired in run-bridge-tests.sh): after the migration the committed corpus must carry
//   exactly the ids the designer exports; any map with a renamed id is red (the corpus drifted from the
//   designer's numbering, or the numbering changed again without a migration).
// Exit 0 = every map's ids consistent (and, with --check, none renamed). 1 = not. 2 = harness could not run.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const RENDERED = join(REPO, 'examples/aef-processes/rendered');
const CHECK = process.argv.includes('--check');
const OUT = CHECK ? null : process.argv[2];
const WRITE = process.argv.includes('--write');
if (!OUT && !CHECK) { console.error('usage: _t1168-node-id-map.mjs <out.json> [--write] | --check'); process.exit(2); }
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof state==='object'&&!!state&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// In the page: pair every node's old id (as written in the committed file) with the id the export now writes.
// The importer's uid for an element with no <aef:uid> is n_<FNV-1a 32 of its id> (parseBpmnXml, T-364: hash32 and
// deriveUid are local to the importer, so copied here). Salting only happens on a collision; a node the copy
// fails to pair shows up as unpaired below rather than mis-mapped.
const PAIR = file => `(async function(){
  function hash32(s){ var h = 0x811c9dc5; for (var i = 0; i < s.length; i++){ h ^= s.charCodeAt(i); h = Math.imul(h, 0x01000193) >>> 0; } return h.toString(16).padStart(8, '0'); }
  function deriveUid(p, seed){ return p + '_' + hash32(seed); }
  var xml = await (await fetch('rendered/${file}')).text();
  var doc = new DOMParser().parseFromString(xml, 'application/xml');
  var old = {};
  Array.prototype.forEach.call(doc.getElementsByTagName('*'), function(e){
    var id = e.getAttribute('id'); if (!id) return;
    var u = null;
    Array.prototype.forEach.call(e.getElementsByTagName('*'), function(c){ if (!u && c.localName === 'uid' && c.parentNode && c.parentNode.parentNode === e) u = c.getAttribute('value'); });
    old[u || deriveUid('n', id)] = id;
  });
  refreshDisplayIds();
  var map = {}, unpaired = [];
  state.nodes.forEach(function(n){ var o = old[n.uid], nw = displayIdOf(n); if (!o) unpaired.push(nw); else if (o !== nw) map[o] = nw; });
  return { map: map, unpaired: unpaired, newIds: state.nodes.map(displayIdOf), xml: xml, exported: buildBpmnXml(state) };
})()`;

function substitute(xml, map) {
  const keys = Object.keys(map).sort((a, b) => b.length - a.length);
  if (!keys.length) return xml;
  const re = new RegExp('(?<![A-Za-z0-9_.-])(' + keys.map(k => k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|') + ')(?![A-Za-z0-9_.-])', 'g');
  return xml.replace(re, m => map[m]);
}

async function main() {
  const files = readdirSync(RENDERED).filter(f => f.endsWith('.bpmn')).sort();
  const doc = mkdtempSync(join(tmpdir(), 't1168m-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't1168m-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  for (const f of files) copyFileSync(join(RENDERED, f), join(doc, 'rendered', f));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1168m-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl; const result = { maps: {}, notPure: [] };
  try {
    for (let i = 0; i < 60; i++) { try { if ((await fetch(BASE + '/api/health')).ok) break; } catch (_) {} await sleep(100); }
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')))); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    for (const f of files) {
      await cmd('Page.navigate', { url: `${BASE}/designer.html?load=rendered/${f}` });
      await sleep(300); await waitReady(cmd); await sleep(300);
      const r = await ev(cmd, PAIR(f));
      const renamed = substitute(r.xml, r.map);
      const pure = renamed === r.exported && r.unpaired.length === 0;
      const has = id => renamed.includes(' id="' + id + '"');
      const missing = r.newIds.filter(id => !has(id));
      const survivors = Object.keys(r.map).filter(o => !Object.values(r.map).includes(o) && has(o));
      const consistent = r.unpaired.length === 0 && missing.length === 0 && survivors.length === 0;
      result.maps[f.replace(/\.bpmn$/, '')] = { changed: Object.keys(r.map).length, idsConsistent: consistent,
        pureRename: pure, unpaired: r.unpaired, missing, survivors, map: r.map };
      if (!consistent) result.notPure.push(f);
      if (process.env.T1168_DUMP_DIR) {
        writeFileSync(join(process.env.T1168_DUMP_DIR, f + '.renamed'), renamed);
        writeFileSync(join(process.env.T1168_DUMP_DIR, f + '.exported'), r.exported);
      }
      if (WRITE && consistent && Object.keys(r.map).length) writeFileSync(join(RENDERED, f), renamed);
    }
    if (OUT) writeFileSync(OUT, JSON.stringify(result, null, 2) + '\n');
    const changed = Object.entries(result.maps).filter(([, v]) => v.changed).length;
    if (CHECK) {
      const drifted = Object.entries(result.maps).filter(([, v]) => v.changed).map(([k, v]) => `${k} (${v.changed}: ${Object.entries(v.map).slice(0, 3).map(([o, n]) => o + '->' + n).join(', ')})`);
      console.log(drifted.length ? `FAIL: ${drifted.length} corpus map(s) carry ids the designer no longer exports: ${drifted.join('; ')}`
                                 : `PASS: all ${files.length} corpus maps carry exactly the node ids the designer exports`);
      // Task records hold task-lifecycle positions (current_node, T-880/T-923): every one must name a node
      // task-lifecycle.bpmn still has, or the migration missed a record.
      const tl = readFileSync(join(RENDERED, 'task-lifecycle.bpmn'), 'utf8');
      const tlIds = new Set([...tl.matchAll(/ id="([^"]+)"/g)].map(m => m[1]));
      const dangling = [];
      for (const d of ['active', 'completed']) {
        const dir = join(REPO, '.tasks', d);
        if (!existsSync(dir)) continue;
        for (const f of readdirSync(dir).filter(x => x.endsWith('.md'))) {
          const m = readFileSync(join(dir, f), 'utf8').match(/^current_node:[ \t]*(\S+)/m);
          if (m && m[1] !== 'null' && !tlIds.has(m[1])) dangling.push(`${f.slice(0, 6)}:${m[1]}`);
        }
      }
      console.log(dangling.length ? `FAIL: ${dangling.length} task record(s) name a node task-lifecycle.bpmn does not have: ${dangling.slice(0, 8).join(', ')}`
                                  : 'PASS: every task record\'s current_node is a node of task-lifecycle.bpmn');
      process.exitCode = drifted.length || result.notPure.length || dangling.length ? 1 : 0;
      return;
    }
    console.log(`${files.length} maps, ${changed} with renamed ids, ${result.notPure.length} with inconsistent ids${result.notPure.length ? ': ' + result.notPure.join(', ') : ''}${WRITE ? ' (written)' : ''}`);
    process.exitCode = result.notPure.length ? 1 : 0;
  } catch (e) {
    console.error(String(e && e.stack || e)); process.exitCode = 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }
}
main();
