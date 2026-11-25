// T-1499 (Greenfield msg ee60b420) — notes above the pool and the phase rows share the band above the pool. Greenfield's
// sample with three notes added just above the pool (as their workshop map has), each with an association to a step:
//
//   N1 [1024/1440/1920] no note box meets a phase bracket, phase name or row label
//   N2 each association still joins its note and its step (one end on the note's box, the other on the step's)
//   N3 every phase name and row label carries a halo (paint-order stroke) so a crossing line leaves it legible
//   N4 with phases hidden (T-1503) the notes are drawn at their file positions
//   N5 the save is byte-identical with phases shown and hidden (the notes' DI never changes); a map without phases
//      draws its notes where the file has them
// Teeth: T1499_EDITOR=<dist 0.49.0> fails N1.  T1499_SHOTS=<dir> writes notes-phases-{1024,1440,1920}.png
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync, mkdirSync, writeFileSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1499_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const SAMPLE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
// three notes just above the pool (the pool's top edge is drawn at y 30), each pointing at a step below it
const NOTES = [
  { id: 'Note_t1', x: 262, y: -2, w: 150, h: 44, text: 'Opportunity always from a customer request', to: 'Activity_opp', tx: 332, ty: 112 },
  { id: 'Note_t2', x: 700, y: 0, w: 160, h: 40, text: 'Product status set by Tacton', to: 'Activity_prod', tx: 788, ty: 112 },
  { id: 'Note_t3', x: 1300, y: -4, w: 150, h: 46, text: 'Proposal needs the sales lead', to: 'Activity_prop', tx: 1396, ty: 112 },
];
function withNotes(xml) {
  const sem = NOTES.map(n => `<bpmn:textAnnotation id="${n.id}"><bpmn:text>${n.text}</bpmn:text></bpmn:textAnnotation>` +
    `<bpmn:association id="Assoc_${n.id}" associationDirection="None" sourceRef="${n.id}" targetRef="${n.to}"/>`).join('');
  const di = NOTES.map(n => `<bpmndi:BPMNShape id="${n.id}_di" bpmnElement="${n.id}"><dc:Bounds x="${n.x}" y="${n.y}" width="${n.w}" height="${n.h}"/></bpmndi:BPMNShape>` +
    `<bpmndi:BPMNEdge id="Assoc_${n.id}_di" bpmnElement="Assoc_${n.id}"><di:waypoint x="${n.x + n.w / 2}" y="${n.y + n.h}"/><di:waypoint x="${n.tx}" y="${n.ty}"/></bpmndi:BPMNEdge>`).join('');
  if (!xml.includes('</bpmn:process>') || !xml.includes('</bpmndi:BPMNPlane>')) throw new Error('sample has no process/plane end');
  return xml.replace('</bpmn:process>', sem + '</bpmn:process>').replace('</bpmndi:BPMNPlane>', di + '</bpmndi:BPMNPlane>');
}
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const doc = mkdtempSync(join(tmpdir(), 't1499-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
// the drawn notes (by their text) and every phase text/bracket box; association end points
const MEASURE = `(function(){
  var gn = document.getElementById('g-notes'), gp = document.getElementById('g-phases');
  var notes = Array.from(gn.querySelectorAll('[data-note]')).map(function(g){ var b = g.getBBox(); return { id: g.getAttribute('data-note'), x: b.x, y: b.y, w: b.width, h: b.height }; });
  var phase = gp ? Array.from(gp.querySelectorAll('text.phase-label, text.phase-row-label, path.phase-bracket')).map(function(e){ var b = e.getBBox(); return { what: e.tagName === 'path' ? 'bracket' : e.textContent, x: b.x, y: b.y, w: b.width, h: b.height }; }) : [];
  var halo = gp ? Array.from(gp.querySelectorAll('text.phase-label, text.phase-row-label')).every(function(t){ var c = getComputedStyle(t); return c.paintOrder.indexOf('stroke') === 0 && parseFloat(c.strokeWidth) >= 2; }) : false;
  var links = Array.from(gn.querySelectorAll('path[data-note-assoc]')).map(function(l){ return { id: l.getAttribute('data-note-assoc'), pts: l.getAttribute('d') || '' }; });
  return { notes: notes, phase: phase, halo: halo, links: links, nPhase: gp ? gp.childNodes.length : 0 };
})()`;
const meets = (a, b) => a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1499-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--disable-dev-shm-usage', '--no-sandbox', '--disable-gpu', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  for (const pass of [0, 1]) {
    await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
    for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
    if (!pass) await ev(`(function(){ try { localStorage.clear(); sessionStorage.clear(); } catch (e) {} return true; })()`);
  }
  const xml = withNotes(readFileSync(SAMPLE, 'utf8'));
  const bad1 = [], bad2 = [];
  let m0 = null;
  for (const W of [1024, 1440, 1920]) {
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: process.env.T1499_SHOTS ? 2 : 1, mobile: false });
    await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); if (typeof openingZoom === 'function') openingZoom(); return true; })(${JSON.stringify(xml)})`);
    const m = await ev(MEASURE);
    if (!m0) m0 = m;
    if (m.notes.length !== 3) bad1.push(`${W}: ${m.notes.length} notes drawn`);
    for (const n of m.notes) for (const p of m.phase) if (meets(n, p)) bad1.push(`${W}: ${n.id} on '${p.what}'`);
    const noteLinks = m.links.filter(l => /^Assoc_Note_/.test(l.id));   // the sample's own 2 step-to-step associations aside
    for (const l of noteLinks) if (!l.pts) bad2.push(`${W}: ${l.id} no points`);
    if (noteLinks.length !== 3) bad2.push(`${W}: ${noteLinks.length} note links drawn`);
    if (process.env.T1499_SHOTS) {
      mkdirSync(process.env.T1499_SHOTS, { recursive: true });
      await ev(`(function(){ var c = document.querySelector('.canvas-wrap'); if (c) { c.scrollLeft = 0; c.scrollTop = 0; } return true; })()`);
      await sleep(300);
      const s = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1499_SHOTS, `notes-phases-${W}.png`), Buffer.from(s.data, 'base64'));
      // the third note lies right of the opening view: a second shot scrolled to it (first judgement, amber)
      await ev(`(function(){ var n = document.querySelector('#g-notes [data-note="Note_t3"]'); if (n) n.scrollIntoView({ block: 'center', inline: 'center' }); return !!n; })()`);
      await sleep(300);
      const s3 = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1499_SHOTS, `notes-phases-note3-${W}.png`), Buffer.from(s3.data, 'base64'));
    }
  }
  leg(!bad1.length, `N1 [1024/1440/1920] the three notes above the pool meet no phase bracket, name or row label`, bad1.slice(0, 4).join('; '));
  // N2: each link's ends: one on its note's box (as drawn), the other on its step
  const ends = await ev(`(function(){ var L = notesLayout(state); if (!L) return null; var byId = {}; L.notes.forEach(function(n){ byId[n.id] = n; });
    return L.links.filter(function(l){ return /^Assoc_Note_/.test(l.id); }).map(function(l){ var a = l.pts[0], z = l.pts[l.pts.length - 1]; return { id: l.id, a: a, z: z, note: byId[(l.ends.sourceRef || {}).id] || null }; }); })()`);
  const steps = Object.fromEntries(NOTES.map(n => [n.to, { x: n.tx - 65, y: n.ty, w: 130, h: 66 }]));
  const near = (r, p) => p && p.x >= r.x - 4 && p.x <= r.x + r.w + 4 && p.y >= r.y - 4 && p.y <= r.y + r.h + 4;
  const badEnds = (ends || []).filter(e => e.note && !(near(e.note, e.a) || near(e.note, e.z))).map(e => e.id);
  leg(!!ends && ends.length === 3 && !badEnds.length && !bad2.length, `N2 each association joins its note (where it is drawn) and its step`, [badEnds.join(','), bad2.join('; ')].filter(Boolean).join(' | '));
  leg(m0.halo === true, `N3 every phase name and row label carries a halo (paint-order: stroke)`);
  // N4 / N5
  const before = await ev(`buildBpmnXml(state)`);
  const hidden = await ev(`(function(){ setPhaseView({ hideAll: true, hiddenRows: [] }); var L = notesLayout(state);
    return L.notes.map(function(n){ return n.id + '@' + Math.round(n.y); }); })()`);
  const savedHidden = await ev(`buildBpmnXml(state)`);
  await ev(`setPhaseView({ hideAll: false, hiddenRows: [] })`);
  const fileY = NOTES.map(n => `${n.id}@${Math.round(n.y)}`);
  leg(JSON.stringify(hidden) === JSON.stringify(fileY), `N4 with phases hidden the notes are drawn at their file positions`, JSON.stringify(hidden));
  const noPhases = await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); var L = notesLayout(state);
    return L.notes.map(function(n){ return n.id + '@' + Math.round(n.y); }); })(${JSON.stringify(xml.replace(/<bpmn:category\b[\s\S]*?<\/bpmn:category>/g, '').replace(/<bpmn:group\b[^>]*\/>/g, '').replace(/<bpmndi:BPMNShape[^>]*bpmnElement="Group_[^"]*"[\s\S]*?<\/bpmndi:BPMNShape>/g, ''))})`);
  leg(before === savedHidden && JSON.stringify(noPhases) === JSON.stringify(fileY),
    `N5 the save is byte-identical with phases shown and hidden (${before.length} chars); a map without phases draws its notes where the file has them`, JSON.stringify(noPhases));
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
