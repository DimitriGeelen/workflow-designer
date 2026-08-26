#!/usr/bin/env node
// _t485-unknown-extension-survival.mjs — what does our editor do to extension content it was
// never told about?
//
// ORIGIN: AEF rail 601 §3. Their `_KNOWN_EXT` is an INVERSE-POLARITY coverage list — it
// enumerates what a preserve-everything catch-all skips, so a member handled nowhere is
// dropped silently. We have no such catch-all: parseBpmnXml reads specific named elements.
// That makes ours a strict allowlist, and the failure mode one polarity further along —
// not "a member handled nowhere" but "an element nobody told us about".
//
// This is the live seam question. AEF ships v1.2 with a new aef: element; a pinned editor
// opens the document, the operator moves one node, saves. Does the new element come back?
// Reading the parser cannot answer it: the parser names what it knows and is silent about
// the rest. Only a round trip can.
//
// THREE CASES, because they can differ and lumping them would hide which one bites:
//   A  unknown aef:-namespaced ELEMENT      <aef:futureThing>...</aef:futureThing>
//   B  unknown FOREIGN-namespace element    <zz:vendorThing>...</zz:vendorThing>
//   C  unknown ATTRIBUTE on a KNOWN element <aef:meta tier="1" futureAttr="...">
//
// POSITIVE CONTROL (PL-095): a KNOWN element is injected into the same document in the same
// operation. If it does not survive, the injection itself never parsed and a report of
// "all dropped" would be an artifact of the probe rather than a property of the editor.
// Control failure => exit 2, no verdict published.
//
// Reports; the gate is the caller's. Exit 0 = ran and controls held.
import { spawn } from 'node:child_process';
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const sleep = ms => new Promise(r => setTimeout(r, ms));

const MARK = { A: '__T485_AEF_ELEM__', B: '__T485_FOREIGN_ELEM__', C: '__T485_ATTR__', CTL: '__T485_CONTROL__' };

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Anchor every payload on the FIRST <aef:meta ... tier="..."> in the document.
//
// The first form of this function injected into the first <bpmn:extensionElements> block and
// used a fresh <aef:endpoint> as the control. The control failed 0/45 and the probe refused
// to publish — correctly, because the failure was MINE, not the editor's: the first
// extensionElements in these documents is process-level, and the parser reads aef:endpoint
// off flow-node elements. Reported as "everything dropped", that would have been a false
// finding about the editor sent to AEF about their own seam.
//
// Two changes, both to remove a way the probe can be wrong rather than to make it pass:
//   - anchor on <aef:meta tier=...>, which only ever appears on a node, so placement is
//     guaranteed node-level instead of assumed;
//   - make the control a MUTATION of an existing known value (tier, measured LIVE in T-484)
//     rather than an injected new element. A mutation cannot land in the wrong place and
//     cannot be shadowed by an existing element the parser reads first.
function inject(xml) {
  const m = /<aef:meta\s([^>]*?)tier="([^"]*)"/.exec(xml);
  if (!m) return null;                       // no node-level meta with a tier — not usable
  let out = xml.slice(0, m.index) +
    '<aef:meta ' + m[1] + 'tier="' + MARK.CTL + '" futureAttr="' + MARK.C + '"' +
    xml.slice(m.index + m[0].length);
  // A and B go immediately before that same element, so they are inside the SAME node's
  // extensionElements as the control. If the control survives and these do not, the
  // difference is the editor's handling and not where the bytes were placed.
  const anchor = out.indexOf('<aef:meta ');
  const payload =
    '<aef:futureThing kind="' + MARK.A + '">' + MARK.A + '</aef:futureThing>\n        ' +
    '<zz:vendorThing xmlns:zz="http://example.invalid/zz" val="' + MARK.B + '">' + MARK.B + '</zz:vendorThing>\n        ';
  return out.slice(0, anchor) + payload + out.slice(anchor);
}

const RT_EXPR = `(function(){
  try{
    var m1 = parseBpmnXml(window.__DOC__);
    if(!m1) return { ok:false, reason:'parse-null' };
    state = m1; refreshDisplayIds();
    return { ok:true, emit: buildBpmnXml(state), nodes: m1.nodes.length };
  }catch(e){ return { ok:false, reason:'exception: '+(e&&e.message||e) }; }
})()`;

function collectDocs() {
  const roots = [join(REPO, 'examples'), join(REPO, 'tests', 'fixtures', 'aef-bpmn')];
  const found = [];
  const walk = d => { if (!existsSync(d)) return; for (const e of readdirSync(d, { withFileTypes: true })) { const p = join(d, e.name); if (e.isDirectory()) walk(p); else if (e.name.endsWith('.bpmn')) found.push(p); } };
  roots.forEach(walk);
  return found.sort();
}

async function main() {
  const docs = collectDocs().filter(p => readFileSync(p, 'utf8').includes('<bpmn:extensionElements>'));
  if (!docs.length) { console.log(JSON.stringify({ pass: false, error: 'no document has an extensionElements block — verdict would be vacuous' })); process.exitCode = 1; return; }

  const doc = mkdtempSync(join(tmpdir(), 't485-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't485-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't485-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl;
  const tally = { A: { survived: 0, dropped: 0 }, B: { survived: 0, dropped: 0 }, C: { survived: 0, dropped: 0 }, CTL: { survived: 0, dropped: 0 } };
  const verdict = { population: 0, perDoc: [], errors: [] };
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) { } await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);

    for (const p of docs) {
      const rel = p.replace(REPO + '/', '');
      const injected = inject(readFileSync(p, 'utf8'));
      if (!injected) continue;
      await ev(cmd, `window.__DOC__ = ${JSON.stringify(injected)};`);
      const r = await ev(cmd, RT_EXPR);
      if (!r || !r.ok) { verdict.errors.push({ doc: rel, error: (r && r.reason) || 'no result' }); continue; }
      verdict.population++;
      const row = { doc: rel };
      for (const k of ['A', 'B', 'C', 'CTL']) {
        const survived = r.emit.includes(MARK[k]);
        tally[k][survived ? 'survived' : 'dropped']++;
        row[k] = survived ? 'PRESERVED' : 'DROPPED';
      }
      verdict.perDoc.push(row);
    }

    if (!verdict.population) throw new Error('no document round-tripped — nothing measured');

    // Control: the known element must survive, otherwise the injection never parsed and a
    // report of "everything dropped" would be a property of this probe, not of the editor.
    const ctlOk = tally.CTL.survived === verdict.population;
    verdict.control = { known_element_survived: tally.CTL.survived, of: verdict.population, held: ctlOk };
    verdict.cases = {
      'A_unknown_aef_element':      { ...tally.A, verdict: tally.A.survived ? 'PRESERVED' : 'DROPPED' },
      'B_unknown_foreign_element':  { ...tally.B, verdict: tally.B.survived ? 'PRESERVED' : 'DROPPED' },
      'C_unknown_attr_on_known_el': { ...tally.C, verdict: tally.C.survived ? 'PRESERVED' : 'DROPPED' },
    };
    if (!ctlOk) {
      verdict.pass = false;
      verdict.error = 'positive control failed — the injected KNOWN element did not survive, so no conclusion about the unknown ones is available';
      console.log(JSON.stringify(verdict, null, 2));
      process.exitCode = 2; return;
    }
    verdict.pass = true;
    verdict.summary = `${verdict.population} documents; unknown aef element ${verdict.cases.A_unknown_aef_element.verdict}, ` +
      `foreign-namespace element ${verdict.cases.B_unknown_foreign_element.verdict}, ` +
      `unknown attribute on known element ${verdict.cases.C_unknown_attr_on_known_el.verdict}; ` +
      `control ${tally.CTL.survived}/${verdict.population}`;
    // perDoc is evidence, but 45 rows drown the verdict — keep a sample and the counts.
    verdict.perDocSample = verdict.perDoc.slice(0, 5);
    delete verdict.perDoc;
    console.log(JSON.stringify(verdict, null, 2));
    process.exitCode = 0;
  } catch (e) {
    console.log(JSON.stringify({ pass: false, error: String(e && e.message || e) }, null, 2));
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) { }
    try { br.kill(); } catch (_) { }
    try { py.kill(); } catch (_) { }
  }
}
main();
