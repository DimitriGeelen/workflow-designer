// T-618 — does an authored `determinism` value survive a real save in the real editor?
//
// WHY A SECOND HARNESS AND NOT AN EDIT TO THE FIRST. `_roundtrip-serialization-cdp.mjs`
// returns pass:true on a fixture full of determinism values, and that green says nothing
// about them: its fixed point projects a FIXED 36-key KEYSPEC that does not contain
// `determinism`. Growing that KEYSPEC was the obvious move and it is the wrong one —
// METAKEYS is derived from it (:134) and a key that rides T-570's CARRIAGE rather than the
// export whitelist lands as a denominator orphan. That would mean reshaping the shared
// instrument until it scores this task's own change. So this harness is separate, narrow,
// and makes its own claim.
//
// WHAT IT ASSERTS, and where it looks. The risk is the EMITTER dropping a carried key, so
// every assertion reads the EMITTED XML, never the in-memory model:
//
//     src ──parse──▶ m1 ──build──▶ x1 ──parse──▶ m2 ──build──▶ x2
//
//   1. uid→value map extracted from x1 equals the map extracted from the source
//   2. the map from x2 equals the map from x1 (a fixed point, not just one lucky hop)
//
// TEETH (PL-108: a guard and the thing it guards must be keyed to the same quantity). Before
// trusting a green, the harness perturbs a value in m1, rebuilds, and requires the extractor
// to SEE the perturbation. An extractor that reads nothing returns two empty maps that
// compare equal — the exact vacuous pass this check exists to not be. If the sentinel does
// not appear, the verdict is 2 (cannot measure), never 0.
//
// Exit 0 = values survive. 1 = a value drifted or was dropped. 2 = cannot measure.
import { readdirSync, mkdtempSync, existsSync, readFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { join, dirname, basename } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = dirname(HERE);
const SERVER = join(HERE, 'gallery-serve.py');
const KEYS = ['determinism', 'sideEffect'];
const SENTINEL = '__t618_sentinel__';

const FIX_DIR = (process.env.T618_FIXTURES_DIR || '').trim()
  || join(REPO, 'examples', 'app-processes', 'rendered');

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
async function pageWsUrl(port) { for (let i = 0; i < 60; i++) { try { const r = await fetch(`http://127.0.0.1:${port}/json/list`); const l = await r.json(); const p = l.find(x => x.type === 'page'); if (p) return p.webSocketDebuggerUrl; } catch (_) {} await sleep(100); } throw new Error('no page target'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Extract uid -> {key: value} from an XML STRING, in the browser, using DOM parsing rather
// than a regex: the emitter is free to reorder or requote attributes, and a regex keyed to
// attribute order would report drift that is not drift.
const EXTRACT = (xmlVar) => `(() => {
  const doc = new DOMParser().parseFromString(${xmlVar}, 'application/xml');
  const out = {};
  for (const el of doc.getElementsByTagName('*')) {
    if (el.localName !== 'meta') continue;
    // IDENTITY IS aef:uid, NOT the element id. refreshDisplayIds() regenerates the BPMN
    // id from lane + order on every export — n_request becomes cst_1_refund — so keying
    // the comparison on id reports "every value vanished" on a document where nothing
    // moved. The stable identity is the <aef:uid> sibling of <aef:meta>. Measured, after
    // this harness first keyed on id and produced exactly that false alarm.
    // ...and the two documents do not carry it the same way. The authored source has no
    // <aef:uid> at all — its identity is the node's id attribute. The editor's export emits
    // <aef:uid> AND a regenerated id. So resolve aef:uid first, fall back to the host id;
    // both then land on the same key (n_request), which is what makes the maps comparable.
    const ext = el.parentElement;
    if (!ext) continue;
    let uid = null;
    for (const c of ext.children) if (c.localName === 'uid') { uid = (c.textContent || '').trim(); break; }
    if (!uid) {
      let host = ext;
      while (host && host.localName === 'extensionElements') host = host.parentElement;
      uid = host ? (host.getAttribute('id') || '').trim() : '';
    }
    if (!uid) continue;
    for (const k of ${JSON.stringify(KEYS)}) {
      const v = el.getAttribute(k);
      if (v !== null) { (out[uid] = out[uid] || {})[k] = v; }
    }
  }
  return out;
})()`;

function countValues(map) { let n = 0; for (const u of Object.keys(map)) n += Object.keys(map[u]).length; return n; }

// NODE IDENTITY IS NOT STABLE ACROSS THE FIRST EXPORT, and that is by design, not a defect:
// refreshDisplayIds() derives the id from lane + order, so an authored `n_request` is emitted
// as `cst_1_refund` and <aef:uid> carries the derived form too. A uid-keyed comparison of
// source against export therefore reports "all 8 values vanished" on a document where nothing
// moved — this harness produced exactly that false alarm before the shape was measured.
//
// So the two hops get two different, individually sound assertions:
//   source -> save    MULTISET of values per key (identity-free; catches a drop or a rewrite)
//   save   -> resave  full uid-keyed map (identity IS stable here; catches per-node drift)
// Neither alone is sufficient: the multiset misses a value moving between nodes, and the
// uid map cannot span the rename. Together they cover both.
function multiset(map) {
  const out = {};
  for (const uid of Object.keys(map)) {
    for (const [k, v] of Object.entries(map[uid])) {
      (out[k] = out[k] || {})[v] = (out[k][v] || 0) + 1;
    }
  }
  return out;
}
function multisetDiff(a, b) {
  const problems = [];
  for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) {
    const x = a[k] || {}, y = b[k] || {};
    for (const v of new Set([...Object.keys(x), ...Object.keys(y)])) {
      if ((x[v] || 0) !== (y[v] || 0)) problems.push(`${k}="${v}": ${x[v] || 0} -> ${y[v] || 0}`);
    }
  }
  return problems;
}
function diff(a, b) {
  const problems = [];
  for (const uid of new Set([...Object.keys(a), ...Object.keys(b)])) {
    const x = a[uid] || {}, y = b[uid] || {};
    for (const k of new Set([...Object.keys(x), ...Object.keys(y)])) {
      if (x[k] !== y[k]) problems.push(`${uid}.${k}: ${JSON.stringify(x[k])} -> ${JSON.stringify(y[k])}`);
    }
  }
  return problems;
}

async function main() {
  if (!existsSync(FIX_DIR)) { console.log(`CANNOT MEASURE: fixture dir ${FIX_DIR} missing`); process.exitCode = 2; return; }
  const fixtures = readdirSync(FIX_DIR).filter(f => f.endsWith('.bpmn')).sort();
  if (!fixtures.length) { console.log(`CANNOT MEASURE: no .bpmn in ${FIX_DIR} — an empty dir would pass vacuously`); process.exitCode = 2; return; }

  const doc = mkdtempSync(join(tmpdir(), 't618-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't618-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  let chrome; try { chrome = findChrome(); } catch (e) { console.log('CANNOT MEASURE: ' + e.message + ' — this is an ENVIRONMENT gap, not a pass'); py.kill(); process.exitCode = 2; return; }
  const udd = mkdtempSync(join(tmpdir(), 't618-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });

  let cl, failed = 0, measured = 0, totalValues = 0;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    cl = cdp(await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort'))));
    await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(250);

    console.log(`T-618 — determinism round trip through the real editor (${fixtures.length} fixture(s))`);
    for (const name of fixtures) {
      const text = readFileSync(join(FIX_DIR, name), 'utf8');
      await ev(cmd, `window.__SRC__ = ${JSON.stringify(text)};`);
      const r = await ev(cmd, `(() => {
        const src = window.__SRC__;
        // THE REAL IMPORT PATH, not parse-then-build. buildBpmnXml emits the DISPLAY id,
        // which refreshDisplayIds() populates from the model — skip it and every node is
        // emitted with id="" and the document loses node identity. That is what this
        // harness did on its first run: the teeth-proof reported the perturbation missing
        // and the raw string search found it present, which is the signature of a broken
        // EXTRACTOR rather than a broken emitter. Mirrors _roundtrip-serialization-cdp.mjs:376.
        const m1 = parseBpmnXml(src);
        state = m1; refreshDisplayIds();
        const x1 = buildBpmnXml(m1);
        const m2 = parseBpmnXml(x1);
        state = m2; refreshDisplayIds();
        const x2 = buildBpmnXml(m2);
        const srcMap = ${EXTRACT('src')};
        window.__X1__ = x1; window.__X2__ = x2;
        const a = ${EXTRACT('window.__X1__')};
        const b = ${EXTRACT('window.__X2__')};
        // TEETH: perturb a real value, rebuild, and require the extractor to see it.
        // Keyed on the VALUE, not the uid — the uid is exactly what is not stable here.
        let sentinelSeen = null, sentinelUid = null;
        for (const n of (m1.nodes || [])) {
          if (n.aef && typeof n.aef.determinism === 'string') {
            sentinelUid = n.uid; n.aef.determinism = ${JSON.stringify(SENTINEL)}; break;
          }
        }
        if (sentinelUid) {
          state = m1; refreshDisplayIds();
          window.__XP__ = buildBpmnXml(m1);
          const pm = ${EXTRACT('window.__XP__')};
          window.__RAW__ = window.__XP__.indexOf('__t618_sentinel__') !== -1;
          window.__PMKEYS__ = Object.keys(pm).slice(0, 5);
          {
            const d = new DOMParser().parseFromString(window.__X1__, 'application/xml');
            const errs = d.getElementsByTagName('parsererror');
            const metas = [...d.getElementsByTagName('*')].filter(e => e.localName === 'meta');
            window.__DIAG__ = {
              parseError: errs.length ? (errs[0].textContent || '').slice(0, 200) : null,
              metaCount: metas.length,
              firstMetaParent: metas[0] ? metas[0].parentElement && metas[0].parentElement.localName : null,
              firstMetaGrand: metas[0] && metas[0].parentElement ? (metas[0].parentElement.parentElement && metas[0].parentElement.parentElement.localName) : null,
              firstMetaAttrs: metas[0] ? [...metas[0].attributes].map(a => a.name).slice(0, 8) : null,
              siblings: metas[0] && metas[0].parentElement ? [...metas[0].parentElement.children].map(c => c.localName + (c.textContent ? '=' + c.textContent.slice(0,24) : '')) : null,
              hostAttrs: metas[0] && metas[0].parentElement && metas[0].parentElement.parentElement
                ? [...metas[0].parentElement.parentElement.attributes].map(a => a.name + '=' + a.value).slice(0, 6) : null,
            };
          }
          sentinelSeen = Object.values(pm).some(o => o.determinism === ${JSON.stringify(SENTINEL)});
        }
        return { diag: window.__DIAG__, rawSeen: window.__RAW__, pmKeys: window.__PMKEYS__,
                 srcMapKeys: Object.keys(srcMap).slice(0, 5), aKeys: Object.keys(a).slice(0, 5),
                 srcMap, a, b, sentinelUid, sentinelSeen, x1head: x1.slice(0,1200), m1n0: JSON.stringify((m1.nodes||[])[0]||{}).slice(0,600) };
      })()`);

      const n = countValues(r.srcMap);
      if (n === 0) { console.log(`  ${name}: SKIP — carries none of ${KEYS.join('/')}`); continue; }
      if (!r.sentinelUid || r.sentinelSeen !== true) {
        // TWO CAUSES, ONE SYMPTOM, AND THEY NEED DIFFERENT VERDICTS. The sentinel failing to
        // arrive means either the emitter dropped the key (a real product failure) or the
        // extractor is blind (a broken instrument). `rawSeen` — a plain string search of the
        // emitted document, deliberately not using the parser the extractor uses — separates
        // them. It is the evidence that resolved this harness's own first red, which looked
        // exactly like a dropped key and was in fact identity-keying that could not span
        // refreshDisplayIds(). Guessing between the two is how a broken instrument gets filed
        // as a product bug, or worse, the reverse.
        if (r.rawSeen === false) {
          failed++;
          console.log(`  ${name}: FAIL — the emitter DROPPED the key. ${n} value(s) authored in`
            + ` the source, and a perturbed value is absent from the emitted document entirely`
            + ` (raw string search, not the parser). Authored data is destroyed on save.`);
          continue;
        }
        console.log(`  ${name}: CANNOT MEASURE — the perturbation IS in the emitted XML but the`
          + ` extractor did not see it. The instrument is blind, not the editor.`);
        failed = -1; break;
      }
      measured++; totalValues += n;
      const p1 = multisetDiff(multiset(r.srcMap), multiset(r.a));
      const p2 = diff(r.a, r.b);
      if (p1.length || p2.length) {
        failed++;
        console.log(`  ${name}: FAIL — ${n} authored value(s)`);
        for (const x of p1) console.log(`      source -> save : ${x}`);
        for (const x of p2) console.log(`      save   -> resave: ${x}`);
      } else {
        const types = Object.keys(r.srcMap).length;
        console.log(`  ${name}: OK — ${n} value(s) on ${types} node(s) survive save and resave `
          + `(teeth: perturbation visible at ${r.sentinelUid})`);
      }
    }
  } catch (e) {
    console.log('CANNOT MEASURE: ' + e.message);
    failed = -1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill(); py.kill();
    for (const d of [doc, repo, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  }

  if (failed === -1) { process.exitCode = 2; return; }
  // ORDER MATTERS. A dropped key means the fixture never reaches `measured++`, so checking
  // "did we measure anything?" first reports a real, named FAIL as "cannot measure" and
  // downgrades a product defect to an instrument complaint. A finding outranks a vacuity
  // check whenever there IS a finding.
  if (failed > 0) { console.log(`\n  ${failed} fixture(s) dropped or altered an authored value.`); process.exitCode = 1; return; }
  if (measured === 0) { console.log('CANNOT MEASURE: no fixture carried a value to check'); process.exitCode = 2; return; }
  console.log(`\n  OK — ${totalValues} authored value(s) across ${measured} fixture(s) round-trip unchanged.`);
  process.exitCode = 0;
}

main();
