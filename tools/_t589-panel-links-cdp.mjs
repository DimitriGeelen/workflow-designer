#!/usr/bin/env node
// _t589-panel-links-cdp.mjs — the properties panel can point at code, tests and a fabric card.
//
// WHAT IS BEING PROVEN. Two new authorable fields (`fabricRef`, `links`) appear on the four
// task-like node types, render as real anchors, and survive a save. The interesting half is
// that they must do this WITHOUT a contract change: both are scalars, so they ride T-570's
// <aef:meta> carriage, metaKeys stays at 20, and nothing needs AEF's ratification.
//
// THE CONTROL ARM IS A SECOND BUILD, NOT AN ASSERTION. Every leg below is of the form
// "an anchor is present" — which is also what a probe that mis-measures the DOM produces.
// So leg 1 loads the PRE-CHANGE editor (git show HEAD:src/…, written to baseline.html) and
// requires it to render ZERO anchors for the same node in the same fixture. If the baseline
// already links, this fixture never reached the gap and no leg below evidences anything.
// That is the T-560 lesson: an assertion of absence is satisfied for free by a blind harness.
//
// WHY THE URL RULE GETS ITS OWN LEG. The designer had no navigation at all before this
// (measured: linkify 0, window.open 0, location.href 0, literal `<a ` 0). Deciding what
// becomes clickable is therefore a new policy, and it is a WHITELIST — http(s) and
// root-relative paths only. Leg 5 drives `javascript:` and a protocol-relative `//host/path`
// through it, because those are exactly the two shapes a "looks like a link" rule waves past.
//
// --src <path> runs against an alternate editor build so a teeth harness can mutate a copy.
// Exit 0 = all legs pass, 1 = a leg failed, 2 = misconfigured (NOT a pass).
import { spawn, spawnSync } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const argi = process.argv.indexOf('--src');
const EDITOR = argi > -1 ? process.argv[argi + 1] : join(REPO, 'src', 'aef-workflow-designer.html');

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 20000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 25000) throw new Error('editor not ready'); await sleep(150); } }

// The links value, with every shape the render rule has to separate:
//   1 an https URL          -> anchor
//   2 a root-relative path  -> anchor (same origin as whatever served the page)
//   3 prose                 -> TEXT (must not vanish, must not pretend to be clickable)
//   4 javascript: scheme    -> TEXT (the reason the rule is a whitelist)
//   5 //host/path           -> TEXT (looks root-relative, resolves OFF-origin)
const LINKS = [
  'https://example.test/src/orders.js',
  '/fabric/component/bpmn-cli',
  'see the runbook, not a url',
  'javascript:alert(1)',
  '//evil.example/x',
].join('\n');
const FABRIC = 'bpmn-cli';
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;').replace(/\n/g, '&#10;');

// T1 carries both new keys. T2 is task-like but carries NEITHER — it is the arm for
// "empty renders no dead link" and for "a sibling's values are not acquired". G1 is a
// gateway: not one of the four implementation-bearing types, so it must be offered neither.
const FIXTURE = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:aef="http://anchorpoint.framework/aef/extensions" id="d1" targetNamespace="http://x">
  <bpmn:process id="Process_t589" isExecutable="false">
    <bpmn:serviceTask id="T1" name="Linked">
      <bpmn:extensionElements>
        <aef:uid value="u-t589-1"/>
        <aef:position x="200.0" y="140.0"/>
        <aef:meta tier="2" note="carrier" fabricRef="${esc(FABRIC)}" links="${esc(LINKS)}"/>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:serviceTask id="T2" name="Plain">
      <bpmn:extensionElements>
        <aef:uid value="u-t589-2"/>
        <aef:position x="400.0" y="140.0"/>
        <aef:meta tier="1"/>
      </bpmn:extensionElements>
    </bpmn:serviceTask>
    <bpmn:exclusiveGateway id="G1" name="Branch">
      <bpmn:extensionElements>
        <aef:uid value="u-t589-3"/>
        <aef:position x="600.0" y="140.0"/>
      </bpmn:extensionElements>
    </bpmn:exclusiveGateway>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="Di_1"><bpmndi:BPMNPlane id="Pl_1" bpmnElement="Process_t589">
    <bpmndi:BPMNShape id="S_T1" bpmnElement="T1"><dc:Bounds x="200" y="140" width="120" height="64"/></bpmndi:BPMNShape>
    <bpmndi:BPMNShape id="S_T2" bpmnElement="T2"><dc:Bounds x="400" y="140" width="120" height="64"/></bpmndi:BPMNShape>
    <bpmndi:BPMNShape id="S_G1" bpmnElement="G1"><dc:Bounds x="600" y="140" width="50" height="50"/></bpmndi:BPMNShape>
  </bpmndi:BPMNPlane></bpmndi:BPMNDiagram>
</bpmn:definitions>`;

// A document carrying NEITHER new key. Both builds must export it to identical bytes —
// adding an authorable field must not perturb documents that do not use it.
const PLAIN_DOC = FIXTURE
  .replace(` fabricRef="${esc(FABRIC)}" links="${esc(LINKS)}"`, '')
  .replace('Process_t589', 'Process_t589p');

// Panel + round-trip snapshot, taken in ONE evaluation so no leg observes another's mutation.
const SNAP = `(function(){
  function byUid(u){ return (state.nodes||[]).find(function(x){ return x.uid===u; }); }
  var n1 = byUid('u-t589-1'), n2 = byUid('u-t589-2'), n3 = byUid('u-t589-3');
  if (!n1 || !n2 || !n3) return { err: 'fixture absent; uids = ' + JSON.stringify((state.nodes||[]).map(function(x){return x.uid;})) };

  // Render the panel for a given node and describe it. selection.id is the node's .id
  // (NOT its uid) — see the shift-click handler; anchoring on uid here would select
  // nothing and every leg would read an empty panel as "no anchors" and pass.
  function panelFor(n){
    selection = { kind: 'node', id: n.id };
    renderProperties();
    var root = document.getElementById('properties');
    var as = [].slice.call(root.querySelectorAll('a')).map(function(a){
      return { href: a.getAttribute('href'), abs: a.href, text: a.textContent,
               target: a.getAttribute('target'), rel: a.getAttribute('rel') };
    });
    // The label div holds the label as its FIRST text node and then appends a hint span,
    // so .textContent is "Fabric component· component card name · opens the card". Reading
    // the whole thing made every exact-match lookup return -1 — which silently turned the
    // "a gateway is offered neither field" leg GREEN, because no label ever equals any
    // string. Measured here, not imagined: that leg passed against a panel it could not read.
    var labels = [].slice.call(root.querySelectorAll('.field-label'))
      .map(function(d){ return d.firstChild ? d.firstChild.textContent : d.textContent; });
    return { anchors: as, labels: labels, text: root.textContent };
  }

  var p1 = panelFor(n1), p2 = panelFor(n2), p3 = panelFor(n3);

  // Real save → re-parse. Not a read of the two whitelists: that is precisely the check
  // that said T-570's keys were fine while the round trip said they were destroyed.
  var imported1 = JSON.parse(JSON.stringify(n1.aef || {}));
  selection = null; renderProperties();
  var xml  = buildBpmnXml(state);
  var xml2 = buildBpmnXml(state);
  var st2  = parseBpmnXml(xml);
  var b1 = (st2.nodes||[]).find(function(x){ return x.uid==='u-t589-1'; });
  var b2 = (st2.nodes||[]).find(function(x){ return x.uid==='u-t589-2'; });

  return {
    p1: p1, p2: p2, p3: p3,
    imported1: imported1,
    back1: b1 ? b1.aef : null,
    back2: b2 ? b2.aef : null,
    stable: xml === xml2,
    metaAttrOrder: (function(){
      var re = /<bpmn:extensionElements>[\\s\\S]*?<\\/bpmn:extensionElements>/g, mm;
      while ((mm = re.exec(xml))) { if (mm[0].indexOf('u-t589-1') > -1) {
        var m = mm[0].match(/<aef:meta ([^>]*?)\\/>/);
        return m ? (m[1].match(/([A-Za-z_][\\w.\\-]*)=/g) || []).map(function(s){ return s.slice(0,-1); }) : [];
      } }
      return [];
    })(),
    // metaKeys is a const INSIDE the export function, not a page global — asking the page
    // for it returns null, which a "=== 20" check would read as a failure rather than as
    // "could not look". Counted from the source file in Node instead (see METAKEYS_N).
    xml: xml
  };
})()`;

async function main() {
  const out = [];
  let npass = 0, nfail = 0;
  const report = (ok, name, detail) => { ok ? npass++ : nfail++; out.push(`${ok ? 'PASS' : 'FAIL'}  ${name} — ${detail}`); };

  if (!existsSync(EDITOR)) { console.log('CANNOT RUN: editor missing: ' + EDITOR); return 2; }
  if (!existsSync(SERVER)) { console.log('CANNOT RUN: server missing: ' + SERVER); return 2; }

  // metaKeys lives inside the export function, so it is counted from the source rather than
  // asked of the page. Anchored on the declaration and required to match exactly once — if
  // the array moves or is duplicated this returns null and leg 9 fails as "could not look"
  // rather than quietly comparing against nothing.
  const src = readFileSync(EDITOR, 'utf8');
  const mk = src.match(/const metaKeys = \[([\s\S]*?)\];/g);
  const METAKEYS_N = (mk && mk.length === 1)
    ? (mk[0].match(/'[a-zA-Z]+'/g) || []).length
    : null;

  const doc = mkdtempSync(join(tmpdir(), 't589-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't589-repo-'));
  const udd = mkdtempSync(join(tmpdir(), 't589-udd-'));
  copyFileSync(EDITOR, join(doc, 'designer.html'));

  // The control arm: the editor as it stood BEFORE this task's change. Taken from git
  // rather than from a hand-kept copy — a copy agrees today and drifts tomorrow, and
  // "these two builds differ" is the entire claim being made.
  //
  // PINNED, NOT `HEAD`. The first version of this read HEAD, which worked exactly until the
  // change was committed — at which point HEAD *became* the change and the control compared
  // the build against itself. The completion gate caught it. Worth recording precisely
  // because of what ELSE happened in that run: leg 10 (byte-identity) went GREEN while
  // comparing a build to itself, which is a tautology, and 9 of 10 legs passed. Only the
  // control noticed, which is the whole argument for having one.
  const BASELINE_REF = process.env.T589_BASELINE_REF || '12c10d09';
  const g = spawnSync('git', ['-C', REPO, 'show', `${BASELINE_REF}:src/aef-workflow-designer.html`], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  if (g.status !== 0 || !g.stdout) { console.log(`CANNOT RUN: could not read ${BASELINE_REF}:src/aef-workflow-designer.html for the control arm`); return 2; }
  // A baseline that already contains the change is not a baseline. Refuse rather than
  // report, since every leg below is "these two differ".
  if (/fabricLink/.test(g.stdout)) { console.log(`CANNOT RUN: baseline ${BASELINE_REF} already contains this change — it is not a pre-change build. Re-point T589_BASELINE_REF.`); return 2; }
  writeFileSync(join(doc, 'baseline.html'), g.stdout);

  mkdirSync(join(doc, 'rendered'), { recursive: true });
  writeFileSync(join(doc, 'rendered', 't589.bpmn'), FIXTURE);
  writeFileSync(join(doc, 'rendered', 't589-plain.bpmn'), PLAIN_DOC);
  mkdirSync(join(repo, 'examples', 'aef-processes', 'rendered'), { recursive: true });

  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  let chrome; try { chrome = findChrome(); } catch (e) { console.log('CANNOT RUN: ' + e.message); py.kill(); return 2; }
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false;
    for (let i = 0; i < 80; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    let page = null;
    for (let i = 0; i < 40 && !page; i++) {
      try { page = (await (await fetch(`http://127.0.0.1:${dp}/json`)).json()).find(t => t.type === 'page'); } catch (_) {}
      if (!page) await sleep(150);
    }
    if (!page) throw new Error('no page target after retries');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');

    const load = async (html, bpmn) => {
      await cmd('Page.navigate', { url: `${BASE}/${html}?load=` + encodeURIComponent('rendered/' + bpmn) });
      await waitReady(cmd); await sleep(500);
    };

    // ── Control arm: the PRE-CHANGE build, same fixture, same node.
    await load('baseline.html', 't589.bpmn');
    const base = await ev(cmd, SNAP);
    if (base.err) throw new Error('baseline: ' + base.err);
    const baseXmlPlainReady = true;

    // ── The build under test.
    await load('designer.html', 't589.bpmn');
    const s = await ev(cmd, SNAP);
    if (s.err) throw new Error(s.err);

    // ── Leg 1: CONTROL. Before the change, the panel for this node had no anchors at all
    // and did not show the values. If this leg fails, nothing below is evidence.
    // The first draft of this leg asserted the baseline "does not surface fabricRef" and
    // FAILED — correctly, and the harness was the thing that was wrong. T-570 already added
    // an "Other extensions" readout that discloses every carried scalar read-only under its
    // RAW key name. So the baseline does show both values; what it cannot do is navigate to
    // them or let anyone author them. The control now says exactly that, which is a narrower
    // and truer claim than the one this task started with.
    const baseAnchors = base.p1.anchors.length;
    const bl = base.p1.labels;
    const rawDisclosed = bl.indexOf('fabricRef') > -1 && bl.indexOf('links') > -1;
    const notAuthorable = bl.indexOf('Fabric component') === -1 && bl.indexOf('Links') === -1;
    report(baseAnchors === 0 && rawDisclosed && notAuthorable, 'control-baseline-cannot-navigate',
      baseAnchors === 0 && rawDisclosed && notAuthorable
        ? 'HEAD build: 0 anchors anywhere in the panel; both keys visible only as read-only "Other extensions" rows under their raw names — disclosed, not authorable, not clickable'
        : `HEAD build had ${baseAnchors} anchor(s); rawDisclosed=${rawDisclosed} notAuthorable=${notAuthorable}; labels=${JSON.stringify(bl)}`);

    // ── Leg 2: both fields are offered, on a task-like node, above Note.
    const labels = s.p1.labels;
    const iFab = labels.indexOf('Fabric component'), iLnk = labels.indexOf('Links'), iNote = labels.indexOf('Note');
    // Promoting a key to an authorable field must also REMOVE it from the read-only
    // "Other extensions" disclosure — the two surfaces select from one rule (shownKeys),
    // and showing one fact in two places is how they drift into disagreeing.
    const stillRaw = ['fabricRef', 'links'].filter(k => labels.indexOf(k) > -1);
    report(iFab > -1 && iLnk > -1 && iNote > -1 && iFab < iNote && iLnk < iNote && stillRaw.length === 0,
      'fields-render-above-note',
      `labels ${JSON.stringify(labels.filter(l => ['Fabric component', 'Links', 'Note', 'Endpoint'].indexOf(l) > -1))} — fabric@${iFab} links@${iLnk} note@${iNote}`
      + (stillRaw.length ? `; ALSO still disclosed raw as ${JSON.stringify(stillRaw)}` : '; no longer duplicated in Other extensions'));

    // ── Leg 3: the fabric anchor. ROOT-RELATIVE href (so it follows whatever origin served
    // the page — a hard-coded :3000 would already be wrong, Watchtower serves on 3013), and
    // it must resolve to the real /fabric/component/<name> route.
    const fa = s.p1.anchors.find(a => (a.href || '').indexOf('/fabric/component/') === 0);
    const faOk = !!fa && fa.href === '/fabric/component/' + FABRIC && fa.target === '_blank' && /noopener/.test(fa.rel || '');
    report(faOk, 'fabric-anchor-root-relative',
      fa ? `href=${JSON.stringify(fa.href)} target=${fa.target} rel=${JSON.stringify(fa.rel)}` : 'no /fabric/component/ anchor rendered');

    // ── Leg 4: each navigable line becomes its own anchor, and the prose line survives as TEXT.
    const hrefs = s.p1.anchors.map(a => a.href);
    const wantLinked = ['https://example.test/src/orders.js', '/fabric/component/bpmn-cli'];
    const linkedOk = wantLinked.every(u => hrefs.indexOf(u) > -1);
    const proseKept = s.p1.text.indexOf('see the runbook, not a url') > -1;
    report(linkedOk && proseKept, 'links-each-line-anchored',
      `anchored ${JSON.stringify(hrefs)}; prose line ${proseKept ? 'shown as text' : 'MISSING from the panel'}`);

    // ── Leg 5: the whitelist. `javascript:` and a protocol-relative `//host` must NOT become
    // anchors — and must still be visible as text, so nothing is silently swallowed.
    const badLinked = hrefs.filter(h => /^javascript:/i.test(h) || /^\/\//.test(h));
    const badShown = s.p1.text.indexOf('javascript:alert(1)') > -1 && s.p1.text.indexOf('//evil.example/x') > -1;
    report(badLinked.length === 0 && badShown, 'unsafe-shapes-are-text-not-links',
      badLinked.length === 0
        ? (badShown ? 'javascript: and //host render as text, still visible' : 'not linked, but the lines VANISHED from the panel')
        : `made clickable: ${JSON.stringify(badLinked)}`);

    // ── Leg 6: ROUND TRIP. Both keys come back byte-identical after a real save and re-parse,
    // including the multi-line links value through escAttr's &#10;. Compared against what
    // IMPORT produced, not a hand-written list, so the leg cannot drift from the fixture.
    const back1 = s.back1 || {};
    const missing = Object.keys(s.imported1).filter(k => back1[k] !== s.imported1[k]);
    report(missing.length === 0 && back1.links === LINKS && back1.fabricRef === FABRIC, 'roundtrip-both-keys',
      missing.length === 0
        ? `all ${Object.keys(s.imported1).length} keys survive parse→build→parse; links kept its ${LINKS.split('\n').length} lines`
        : `lost or altered: ${JSON.stringify(missing.map(k => k + ': ' + JSON.stringify(back1[k])))}`);

    // ── Leg 7: empty means NO anchor. A dead link that always looks clickable is worse than
    // no link — and /fabric/component/ with no name is a 404.
    const t2Fabric = s.p2.anchors.filter(a => (a.href || '').indexOf('/fabric/component/') === 0);
    const t2HasField = s.p2.labels.indexOf('Fabric component') > -1;
    report(t2HasField && t2Fabric.length === 0 && !(s.back2 || {}).fabricRef, 'empty-field-no-dead-link',
      `plain node: field offered=${t2HasField}, fabric anchors=${t2Fabric.length}, acquired fabricRef=${JSON.stringify((s.back2 || {}).fabricRef)}`);

    // ── Leg 8: a gateway is not implementation-bearing, so it is offered neither field.
    const gwHas = s.p3.labels.filter(l => l === 'Fabric component' || l === 'Links');
    report(gwHas.length === 0, 'gateway-not-offered',
      gwHas.length === 0 ? 'exclusiveGateway offers neither field' : `gateway was offered ${JSON.stringify(gwHas)}`);

    // ── Leg 9: NOT A CONTRACT CHANGE. metaKeys is still 20 and both new keys ride the
    // carriage as ordinary carried attributes, after the known keys.
    const order = s.metaAttrOrder;
    const iTier = order.indexOf('tier'), iNoteA = order.indexOf('note');
    const iFabA = order.indexOf('fabricRef'), iLnkA = order.indexOf('links');
    const carriedAfterKnown = iFabA > -1 && iLnkA > -1 && iTier > -1 && iNoteA > -1
      && Math.min(iFabA, iLnkA) > Math.max(iTier, iNoteA);
    report(METAKEYS_N === 20 && carriedAfterKnown && s.stable, 'no-contract-change',
      `metaKeys=${METAKEYS_N} (want 20); two exports ${s.stable ? 'byte-identical' : 'DIFFER'}; meta order ${JSON.stringify(order)}`);

    // ── Leg 10: BYTE IDENTITY. A document carrying NEITHER key exports to the same bytes from
    // the pre-change build and this one. Both exports are taken in this run from the same
    // fixture — not compared against a stored golden, which would only prove the golden.
    await load('baseline.html', 't589-plain.bpmn');
    let xmlBase = await ev(cmd, `buildBpmnXml(state)`);
    await load('designer.html', 't589-plain.bpmn');
    let xmlNew = await ev(cmd, `buildBpmnXml(state)`);
    // A document with no <aef:workflowMeta uuid> gets one MINTED at load, freshly random per
    // page load. That differs between the two builds for a reason that has nothing to do with
    // this change, so it is masked — and the mask is required to fire EXACTLY ONCE on each
    // side. A blanket regex that silently matched zero times, or matched several, would hide
    // the very difference this leg exists to catch.
    const UUID_RE = /(<aef:workflowMeta [^>]*uuid=")[0-9a-fA-F-]{36}(")/g;
    const hits = x => (String(x).match(UUID_RE) || []).length;
    const mask = x => String(x).replace(UUID_RE, '$1<minted-per-load>$2');
    if (hits(xmlBase) !== 1 || hits(xmlNew) !== 1) {
      throw new Error(`uuid mask must apply exactly once per side, got base=${hits(xmlBase)} new=${hits(xmlNew)} — refusing to compare under a mask that is not doing what it claims`);
    }
    xmlBase = mask(xmlBase); xmlNew = mask(xmlNew);

    const same = xmlBase === xmlNew;
    let where = '';
    if (!same && typeof xmlBase === 'string' && typeof xmlNew === 'string') {
      let i = 0; while (i < xmlBase.length && xmlBase[i] === xmlNew[i]) i++;
      where = ` first difference at byte ${i}:\n         base: ${JSON.stringify(xmlBase.slice(Math.max(0, i - 50), i + 60))}\n         new:  ${JSON.stringify(xmlNew.slice(Math.max(0, i - 50), i + 60))}`;
    }
    report(same && typeof xmlBase === 'string' && xmlBase.length > 200, 'byte-identical-when-unused',
      same ? `${xmlBase.length} bytes, identical from both builds`
        : `bytes DIFFER (${(xmlBase || '').length} vs ${(xmlNew || '').length}) — an unused field perturbed an untouched document.${where}`);
    if (!baseXmlPlainReady) report(false, 'internal', 'unreachable');

  } catch (e) {
    console.log('CANNOT RUN: ' + e.message);
    try { cl && cl.close(); } catch (_) {}
    br.kill(); py.kill();
    await sleep(400);
    for (const d of [doc, repo, udd]) rmSync(d, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });
    return 2;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill(); py.kill();
  }
  await sleep(400);
  for (const d of [doc, repo, udd]) rmSync(d, { recursive: true, force: true, maxRetries: 20, retryDelay: 100 });

  console.log(out.join('\n'));
  console.log(`\n${npass} passed, ${nfail} failed`);
  if (nfail === 0) console.log(`${npass}/${npass} T-589 legs passed`);
  return nfail === 0 ? 0 : 1;
}

main().then(c => { process.exitCode = c; });
