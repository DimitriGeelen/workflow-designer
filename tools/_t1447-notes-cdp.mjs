// T-1447 — imported text annotations and associations, drawn read-only, in the real designer (headless Chromium, CDP).
//
// Fixture: Greenfield's Camunda workshop map (tests/fixtures/greenfield/nooteboom-offerte-tot-order-with-notes.bpmn, owner
// consented 2026-11-19): 12 text annotations, 10 associations (8 note -> step, 2 one-way task -> task).
// Every expectation is read from the FIXTURE (its DI bounds, its ids, its step names), never from the designer's own record.
//
// Legs (each prints PASS/FAIL; exit 0 only if all pass):
//   N1 every annotation draws at its DI bounds (the bracket's corner, height) with its full text
//   N2 every association draws, dotted, from its source to its target (each end on the right step or note);
//      a one-way association has an arrowhead at its target, an undirected one none
//   N3 moving a step redraws its associations to the step's new place (they follow it); the others keep the file's waypoints
//   N4 read-only and underneath: the layer takes no pointer events and sits below edges and nodes; a click on a note selects nothing
//   N5 save writes the same bytes as 0.44.0 (the release before this task) for the fixture
//   N6 the import notice no longer says annotations or associations are "not shown yet"
//   N7 the picture export (SVG) carries the notes and their lines
// Teeth: T1447_EDITOR=dist/aef-workflow-designer-0.44.0.html runs the same legs on the designer before this task;
// N1, N2, N3, N6 and N7 must fail there (`--expect-red`).
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, mkdirSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1447_EDITOR ? resolve(ROOT, process.env.T1447_EDITOR) : join(ROOT, 'src', 'aef-workflow-designer.html');
const BASELINE = join(ROOT, 'dist', 'aef-workflow-designer-0.44.0.html');
const FIXTURE = join(ROOT, 'tests', 'fixtures', 'greenfield', 'nooteboom-offerte-tot-order-with-notes.bpmn');
const EXPECT_RED = process.argv.includes('--expect-red');
const sleep = ms => new Promise(r => setTimeout(r, ms));
const results = {};
const leg = (key, ok, name, detail) => { results[key] = ok; console.log(`${ok ? 'PASS' : 'FAIL'}  ${key} ${name}${detail ? '  ' + detail : ''}`); };

// ── what the fixture says (parsed here, independently of the designer) ──
const XML = readFileSync(FIXTURE, 'utf8');
const attr = (tag, a) => { const m = tag.match(new RegExp(`\\s${a}="([^"]*)"`)); return m ? m[1] : null; };
const unesc = s => s.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&#x([0-9a-f]+);/gi, (m, h) => String.fromCodePoint(parseInt(h, 16))).replace(/&#(\d+);/g, (m, d) => String.fromCodePoint(+d)).replace(/&amp;/g, '&');
const bounds = new Map();
for (const m of XML.matchAll(/<bpmndi:BPMNShape\b([^>]*)>\s*<dc:Bounds\b([^>]*)\/>/g)) {
  bounds.set(attr(m[1], 'bpmnElement'), ['x', 'y', 'width', 'height'].map(k => parseFloat(attr(m[2], k))));
}
const notes = [...XML.matchAll(/<bpmn:textAnnotation\b([^>]*)>\s*<bpmn:text>([\s\S]*?)<\/bpmn:text>/g)]
  .map(m => ({ id: attr(m[1], 'id'), text: unesc(m[2]).replace(/\s+/g, ' ').trim(), b: bounds.get(attr(m[1], 'id')) }));
const names = new Map([...XML.matchAll(/<bpmn:(?:task|userTask|serviceTask|sendTask|receiveTask|manualTask|scriptTask|businessRuleTask|startEvent|endEvent|exclusiveGateway|parallelGateway|intermediateThrowEvent|intermediateCatchEvent|subProcess|callActivity)\b([^>]*)>/g)]
  .map(m => [attr(m[1], 'id'), unesc(attr(m[1], 'name') || '')]));
const assocs = [...XML.matchAll(/<bpmn:association\b([^>]*?)\/?>/g)]
  .map(m => ({ id: attr(m[1], 'id'), src: attr(m[1], 'sourceRef'), tgt: attr(m[1], 'targetRef'), dir: attr(m[1], 'associationDirection') || 'None' }));

const doc = mkdtempSync(join(tmpdir(), 't1447-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
copyFileSync(BASELINE, join(doc, 'baseline.html'));
mkdirSync(join(doc, 'm')); copyFileSync(FIXTURE, join(doc, 'm', 'gf.bpmn'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1447-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
const events = [];
let cl, harnessError = null;
try {
  if (notes.length !== 12 || assocs.length !== 10) throw new Error(`fixture parse: ${notes.length} notes, ${assocs.length} associations (expected 12, 10)`);
  let dp; for (let i = 0; i < 150 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000, onEvent: m => events.push(m) }); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  await cmd('Page.enable'); await cmd('Runtime.enable');
  const open = async page => {
    await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/${page}` });
    for (let i = 0; i < 150; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
    await ev(`(async()=>{ const t = await (await fetch('m/gf.bpmn')).text(); await adoptImportedXml(t, { userImport: true }); await new Promise(r=>setTimeout(r,300)); })()`);
  };

  // N5 first: the baseline's save bytes
  await open('baseline.html');
  const baseSave = (await ev(`buildBpmnXml(state)`)).replace(/(<aef:workflowMeta\b[^>]*\suuid=")[^"]*"/, '$1…"');
  await open('designer.html');
  const errors = events.filter(e => e.method === 'Runtime.exceptionThrown').map(e => e.params.exceptionDetails.text);

  // what the canvas drew
  const drawn = await ev(`(function(){
    const out = { notes: {}, links: {}, nodes: {} };
    for (const g of document.querySelectorAll('#g-notes [data-note]')) {
      const d = g.querySelector('path').getAttribute('d'), m = d.match(/^M([-\\d.]+),([-\\d.]+) H([-\\d.]+) V([-\\d.]+)/);
      out.notes[g.getAttribute('data-note')] = { x: +m[3], y: +m[2], bottom: +m[4],
        text: [...g.querySelectorAll('text')].map(t => t.textContent).join(' ').replace(/\\s+/g, ' ').trim() };
    }
    for (const p of document.querySelectorAll('#g-notes [data-note-assoc]')) {
      const pts = p.getAttribute('d').slice(1).split(' L').map(s => s.split(',').map(Number));
      out.links[p.getAttribute('data-note-assoc')] = { first: pts[0], last: pts[pts.length - 1], n: pts.length,
        dash: p.getAttribute('stroke-dasharray'), end: p.getAttribute('marker-end'), start: p.getAttribute('marker-start') };
    }
    for (const n of state.nodes) { const d = dims(n); out.nodes[n.name] = { x: n.x, y: n.y, w: d.w, h: d.h, uid: n.uid }; }
    return out;
  })()`);
  const rectOfRef = (ref, nodes) => {
    if (bounds.has(ref) && notes.some(n => n.id === ref)) { const b = bounds.get(ref); return { x: b[0], y: b[1], w: b[2], h: b[3] }; }
    return nodes[names.get(ref)] || null;
  };
  const on = (r, p) => r && p[0] >= r.x - 3 && p[0] <= r.x + r.w + 3 && p[1] >= r.y - 3 && p[1] <= r.y + r.h + 3;

  leg('P0', errors.length === 0, 'page loads and imports without a script error', errors.join(' | ').slice(0, 200));

  // N1
  const badNotes = notes.filter(n => { const d = drawn.notes[n.id]; return !d || Math.abs(d.x - n.b[0]) > 0.6 || Math.abs(d.y - n.b[1]) > 0.6
    || Math.abs(d.bottom - (n.b[1] + n.b[3])) > 0.6 || d.text !== n.text; }).map(n => n.id);
  leg('N1', Object.keys(drawn.notes).length === 12 && badNotes.length === 0, 'all 12 annotations at their DI bounds with their full text',
    JSON.stringify({ drawn: Object.keys(drawn.notes).length, bad: badNotes }));

  // N2
  const badLinks = assocs.filter(a => { const d = drawn.links[a.id];
    return !d || d.dash !== '2 3' || !on(rectOfRef(a.src, drawn.nodes), d.first) || !on(rectOfRef(a.tgt, drawn.nodes), d.last)
      || (a.dir === 'One' ? d.end !== 'url(#assoc-end)' || d.start : d.end || d.start); }).map(a => a.id);
  leg('N2', Object.keys(drawn.links).length === 10 && badLinks.length === 0,
    'all 10 associations dotted, source to target; one-way ones with an arrowhead at the target', JSON.stringify({ drawn: Object.keys(drawn.links).length, bad: badLinks }));

  // N3: move the target of a one-way task -> task association and the step of one note
  const oneWay = assocs.find(a => a.dir === 'One'), noteLink = assocs.find(a => a.dir === 'None');
  const movedName = names.get(oneWay.tgt), movedNote = names.get(noteLink.tgt);
  const after = await ev(`(function(){
    const a = state.nodes.find(n => n.name === ${JSON.stringify(movedName)}), b = state.nodes.find(n => n.name === ${JSON.stringify(movedNote)});
    a.x += 160; a.y += 90; b.x -= 120; renderAll();
    const out = {};
    for (const p of document.querySelectorAll('#g-notes [data-note-assoc]')) {
      const pts = p.getAttribute('d').slice(1).split(' L').map(s => s.split(',').map(Number));
      out[p.getAttribute('data-note-assoc')] = { first: pts[0], last: pts[pts.length - 1], n: pts.length };
    }
    const nodes = {}; for (const n of state.nodes) { const d = dims(n); nodes[n.name] = { x: n.x, y: n.y, w: d.w, h: d.h }; }
    return { links: out, nodes };
  })()`);
  const follows = [oneWay, noteLink].every(a => { const d = after.links[a.id];
    return d && on(rectOfRef(a.src, after.nodes), d.first) && on(rectOfRef(a.tgt, after.nodes), d.last); });
  const untouched = assocs.filter(a => a !== oneWay && a !== noteLink && names.get(a.src) !== movedName && names.get(a.src) !== movedNote
    && names.get(a.tgt) !== movedName && names.get(a.tgt) !== movedNote);
  const kept = untouched.every(a => after.links[a.id] && after.links[a.id].n === drawn.links[a.id].n
    && String(after.links[a.id].first) === String(drawn.links[a.id].first));
  leg('N3', follows && kept && untouched.length > 0, 'a moved step takes its associations along; the others keep the file\'s waypoints',
    JSON.stringify({ follows, kept, untouched: untouched.length }));
  await ev(`(function(){ const a = state.nodes.find(n => n.name === ${JSON.stringify(movedName)}), b = state.nodes.find(n => n.name === ${JSON.stringify(movedNote)});
    a.x -= 160; a.y -= 90; b.x += 120; renderAll(); })()`);

  // N4
  const n4 = await ev(`(function(){
    const g = document.getElementById('g-notes'); if (!g) return { layer: false };
    const kids = [...g.parentNode.children].map(c => c.id);
    const note = g.querySelector('[data-note] text'); const r = note.getBoundingClientRect();
    const hit = document.elementFromPoint(r.left + 3, r.top + r.height / 2);
    selected = null; if (typeof selectedEdge !== 'undefined') selectedEdge = null;
    hit && hit.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, clientX: r.left + 3, clientY: r.top + r.height / 2 }));
    hit && hit.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, clientX: r.left + 3, clientY: r.top + r.height / 2 }));
    hit && hit.dispatchEvent(new MouseEvent('click', { bubbles: true, clientX: r.left + 3, clientY: r.top + r.height / 2 }));
    return { layer: true, pe: g.getAttribute('pointer-events'), below: kids.indexOf('g-notes') < kids.indexOf('g-edges') && kids.indexOf('g-notes') < kids.indexOf('g-nodes'),
      hitInNotes: !!(hit && hit.closest && hit.closest('#g-notes')), selected: (typeof selected !== 'undefined' && selected) ? String(selected) : null };
  })()`);
  leg('N4', n4.layer && n4.pe === 'none' && n4.below && !n4.hitInNotes && !n4.selected, 'read-only, under edges and nodes; a click on a note selects nothing', JSON.stringify(n4));

  // N5
  // the map's uuid is minted fresh on every import (both pages imported the file), so it is masked; every other byte counts
  // T-1456/T-1457 (2026-11-20, a deliberate routing change): Productieorder's incoming and outgoing ends, 8 px apart, are
  // re-spread 12 px apart. These two flows' file bends equal the designer's own routing, so a save writes the new route:
  // their waypoint coordinates are masked on both sides; every other byte, of them and of every other edge, counts.
  const REROUTED = ['flow_19', 'flow_20'];
  const maskRerouted = x => typeof x === 'string' ? x.replace(/(<bpmndi:BPMNEdge\b[^>]*\sbpmnElement="([^"]+)"[^>]*>)([\s\S]*?)(<\/bpmndi:BPMNEdge>)/g,
    (all, open, id, body, close) => REROUTED.includes(id) ? open + body.replace(/(?:<di:waypoint\b[^>]*\/>\s*)+/, '<di:waypoint (rerouted, T-1456)/>') + close : all) : x;
  const maskUuid = x => typeof x === 'string' ? maskRerouted(x.replace(/(<aef:workflowMeta\b[^>]*\suuid=")[^"]*"/, '$1…"')) : x;
  const save = maskUuid(await ev(`buildBpmnXml(state)`));
  const base = maskRerouted(baseSave);
  if (save !== base) { let i = 0; while (i < save.length && save[i] === base[i]) i++; console.log('N5 first difference at ' + i + ': new ' + JSON.stringify(save.slice(i - 60, i + 60)) + ' | 0.44.0 ' + JSON.stringify(base.slice(i - 60, i + 60))); }
  leg('N5', typeof save === 'string' && save.length > 1000 && save === base, 'save writes the same bytes as 0.44.0 (the import-minted uuid masked; T-1456 re-routed flows: coordinates masked)', `${save && save.length} vs ${base && base.length} B`);

  // N6
  const notice = await ev(`(function(){ const m = document.getElementById('lane-fix-msg'); return m ? m.textContent : ''; })()`);
  leg('N6', !!notice && !/annotation[^.;]*not shown yet/.test(notice) && !/association[^.;]*not shown yet/.test(notice),
    'the import notice does not call the annotations or associations "not shown yet"', JSON.stringify(notice.slice(0, 300)));

  // N7
  const svgOut = await ev(`(function(){ const s = buildExportSvg(); return typeof s === 'string' ? s : (s && s.svg) ? (typeof s.svg === 'string' ? s.svg : new XMLSerializer().serializeToString(s.svg)) : new XMLSerializer().serializeToString(s); })()`);
  const nNotes = (svgOut.match(/data-note="/g) || []).length, nLinks = (svgOut.match(/data-note-assoc="/g) || []).length;
  leg('N7', nNotes === 12 && nLinks === 10 && !/url\(#assoc-end\)/.test(svgOut), 'the SVG export carries the 12 notes and 10 lines (markers renamed with the export prefix)',
    JSON.stringify({ nNotes, nLinks }));
} catch (e) {
  harnessError = String(e && e.message || e).slice(0, 300);
  console.log('FAIL  harness error  ' + harnessError);
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL');
  for (const d of [doc, udd]) { try { rmSync(d, { recursive: true, force: true }); } catch (_) {} }
  let rc;
  if (harnessError) rc = 2;
  else if (EXPECT_RED) {
    const mustFail = ['N1', 'N2', 'N3', 'N6', 'N7'], wrong = mustFail.filter(k => results[k] !== false);
    console.log(wrong.length ? `BITE MISSING: ${wrong.join(', ')} passed on the old designer` : 'bites: N1, N2, N3, N6, N7 all red on the old designer');
    rc = wrong.length ? 1 : 0;
  } else {
    const failed = Object.entries(results).filter(([, v]) => !v).map(([k]) => k);
    console.log(failed.length ? `${failed.length} leg(s) FAILED: ${failed.join(', ')}` : 'all legs passed');
    rc = failed.length ? 1 : 0;
  }
  process.exit(rc);
}
