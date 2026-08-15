#!/usr/bin/env node
/**
 * T-520 — what happens to an externally-assigned aef:uid whose VALUE is not XML-attribute-safe.
 *
 * Second of the four gaps _t515 names in its own does_not_cover, taken after T-518 closed the
 * first. Mapping standard §6.3 invites AEF to assign aef:uid externally and says NOTHING about
 * the value. The uid rides in an XML attribute, so the character set is not a free choice.
 *
 * WHY THIS IS NOT ONE QUESTION. Three different mechanisms bound the value and they fail in
 * three different ways, needing three different sentences in §6.3:
 *
 *   escapable        & < > "  are legal once escaped. A correct writer emits &amp;/&lt;/&quot;
 *                    and the value survives byte-identical. A writer doing naive string
 *                    concatenation emits a malformed document instead.
 *   normalised       XML attribute-value normalisation (XML 1.0 §3.3.3) replaces a literal
 *                    newline or tab with a SPACE unless it is written as a character reference.
 *                    A value carrying one cannot survive an attribute round-trip in general.
 *                    This is not a defect in any implementation — it is the wire format.
 *   unrepresentable  most C0 control characters are illegal in XML 1.0 anywhere, escaped or
 *                    not. No conforming document can carry them at all.
 *
 * So a bare pass/fail would be the wrong output. Each candidate is classified into a MEASURED
 * outcome and the report separates "the editor does this" from "XML makes this impossible",
 * because only the first is ours to change.
 *
 * WHY IT MATTERS. AEF's reverse renderer keys records on uid. A uid that comes back TRANSFORMED
 * silently addresses the wrong record, or none — the T-518 shape. A uid that breaks the document
 * fails loudly, which is worse for the user and far better for correctness. Finding out which
 * candidates land in which bucket is the whole deliverable.
 *
 * STIMULUS IS VERIFIED BEFORE THE VERDICT (PL-206). Every candidate is read back OUT of the
 * input document before the round-trip runs. If the value the parser sees is not the value
 * intended, the run REFUSES instead of reporting a result — a probe whose stimulus never
 * contained the hostile character would pass forever while testing nothing. The control-char
 * case is the one where a staging failure is itself the finding, and it is distinguished from a
 * broken fixture by the plain-value control going through the identical staging path.
 *
 * CHARACTERISATION, NOT A VERDICT (as T-518). Nobody has ratified what SHOULD happen. The
 * editor honouring §5's promise to return what it was given is correct; where a value cannot
 * survive, the obligation belongs on the assigner and the wording is AEF's. This pins what IS
 * and goes red on a CHANGE, rather than legislating a co-designed standard from a test file.
 *
 * Usage: node tools/_t520-uid-xml-safety.mjs
 *   rc 0  measured, and every candidate matches its pin
 *   rc 1  a candidate's behaviour changed — tell AEF before they notice
 *   rc 2  REFUSE: could not measure (no corpus, staging failed, control dead, unpinned case)
 */
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const CORPUS = process.env.T520_CORPUS || join(REPO, 'examples', 'aef-processes', 'rendered');
const SRC = 'src/aef-workflow-designer.html';
const sleep = ms => new Promise(r => setTimeout(r, ms));

// ── the candidates ────────────────────────────────────────────────────────────────────────
// `raw` is the value AEF would hand us. `stage` is how it must be written INTO an XML attribute
// to mean that value — the two differ precisely because this is the problem under test.
const AMP = String.fromCharCode(38), LT = String.fromCharCode(60), GT = String.fromCharCode(62);
const QUOT = String.fromCharCode(34), APOS = String.fromCharCode(39);
const CANDIDATES = [
  { key: 'plain',      raw: 'n_plaincontrol01',              why: 'NEGATIVE CONTROL — a value with nothing hostile in it. If this does not survive byte-identical, every other verdict in this run is a property of the harness rather than of the value, so its failure REFUSES the whole run.' },
  { key: 'ampersand',  raw: 'n_a' + AMP + 'b',               why: 'the classic naive-concatenation break: & starts an entity reference' },
  { key: 'lt',         raw: 'n_a' + LT + 'b',                why: '< is never legal raw in an attribute value' },
  { key: 'quot',       raw: 'n_a' + QUOT + 'b',              why: 'the attribute delimiter itself' },
  { key: 'gt',         raw: 'n_a' + GT + 'b',                why: '> is legal raw in an attribute, so a writer MAY leave it; either way it must round-trip' },
  { key: 'apos',       raw: 'n_a' + APOS + 'b',              why: "legal raw in a double-quoted attribute, hostile if the writer switches to single quotes" },
  { key: 'combined',   raw: 'n_' + AMP + LT + GT + QUOT + APOS, why: 'all of the above at once — catches a writer that escapes one pass but not re-entrantly' },
  { key: 'nonascii',   raw: 'n_café_日本',      why: 'non-ASCII UTF-8; nothing in XML forbids it, so a failure here is an encoding bug not a spec limit' },
  { key: 'newline',    raw: 'n_a\nb',                        why: 'ATTRIBUTE-VALUE NORMALISATION: survives only if the writer emits &#10;. Lossy by spec otherwise.' },
  { key: 'tab',        raw: 'n_a\tb',                        why: 'same normalisation rule as newline' },
  { key: 'ctrl',       raw: 'n_a' + String.fromCharCode(1) + 'b',
    why: 'U+0001 is illegal in XML 1.0 ANYWHERE, escaped or not. Built by charCode, not written as a literal: a raw control byte in source is invisible in review, makes the file binary to grep, and survives no copy-paste — the fixture would quietly become a plain string and this case would pass while testing nothing.' },
];

// ── the pin ───────────────────────────────────────────────────────────────────────────────
// Set from the first MEASURED run, not from expectation. An unpinned candidate REFUSES rather
// than passing: "I have no reference for this" must not be indistinguishable from "it matched".
//
// This table was wrong twice, in opposite directions, and both mistakes are worth keeping here.
//
// FIRST I drafted it from expectation: `newline` and `tab` pinned as `transformed`, reasoning
// from XML 1.0 §3.3.3. The run disagreed — both came back byte-identical — so I corrected the
// pin to `identical` and very nearly shipped that, with a comment congratulating the editor for
// emitting numeric character references.
//
// IT DOES NOT. `emitted_as` showed a RAW newline sitting inside the attribute. The value only
// looked intact because the reader was Chrome's DOMParser, which does not apply attribute-value
// normalisation here. Checked against expat directly: `<aef:uid value="n_a{newline}b"/>` reads
// back as `n_a b`. The editor writes something a conforming parser cannot read back, and the
// browser reader agreed with the defect because it is the same lenient reader that produced it.
//
// So the second correction restores `transformed` — the value I first guessed — but for a
// completely different and much more serious reason than the one I guessed it for. Getting the
// right answer from the wrong model is not getting it right; the fix was to change the
// INSTRUMENT (verdicts now come from a conforming parser), not the number.
const PIN = {
  plain: 'identical', ampersand: 'identical', lt: 'identical', quot: 'identical',
  gt: 'identical', apos: 'identical', combined: 'identical', nonascii: 'identical',
  newline: 'transformed', tab: 'transformed', ctrl: 'not-representable-in-xml',
};

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

// Reads the uid VALUES a parser actually sees, and reports whether the document parsed at all.
// Both halves matter: an unparseable document is a distinct outcome from a parsed one with a
// changed value, and collapsing them would hide the difference between "the editor emitted
// something broken" and "the editor emitted something lossy".
const READ = t => `(function(){
  var AEF='http://anchorpoint.framework/aef/extensions';
  var d=new DOMParser().parseFromString(${JSON.stringify(t)},'application/xml');
  var perr=d.getElementsByTagName('parsererror');
  if(perr && perr.length) return {parsed:false, error:(perr[0].textContent||'').slice(0,200), uids:[]};
  var u=d.getElementsByTagNameNS(AEF,'uid'); var out=[];
  for(var i=0;i<u.length;i++) out.push(u[i].getAttribute('value'));
  return {parsed:true, error:null, uids:out};
})()`;

const ROUNDTRIP = src => `(function(){ state = parseBpmnXml(${JSON.stringify(src)}); refreshDisplayIds(); return buildBpmnXml(state); })()`;

// How a value must be WRITTEN into a double-quoted attribute to mean itself. Newline and tab
// need numeric references or normalisation eats them; that is the whole point of those cases.
const stage = v => v
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;').replace(/'/g, '&apos;')
  .replace(/\n/g, '&#10;').replace(/\r/g, '&#13;').replace(/\t/g, '&#9;')
  .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, c => '&#' + c.charCodeAt(0) + ';');

const refuse = (msg, extra = {}) => { console.log(JSON.stringify({ ok: false, refusal: msg, ...extra }, null, 2)); process.exitCode = 2; };
const show = v => JSON.stringify(v);

// ── the authority for every verdict below, and the reason this probe was rewritten ────────
// The first version read the round-tripped document with the BROWSER's DOMParser, because the
// document is already in a browser and that is the free thing to do. It reported every value
// surviving byte-identical, including a raw newline — which XML 1.0 §3.3.3 says is impossible,
// since attribute-value normalisation turns a literal newline into a space before the
// application sees it. Chrome's DOMParser does not apply it here; expat does.
//
// So the browser reader AGREED WITH THE DEFECT. Measuring a cross-project seam with the
// producer's own lenient parser certifies exactly the corruption the probe exists to find.
// Every verdict is now taken from a conforming parser, which is also the class of parser on
// AEF's side; the browser's reading is still collected, because the DISAGREEMENT between the
// two is the finding rather than a nuisance.
const readConforming = text => new Promise((res, rej) => {
  // Path written as one repo-relative literal rather than join(HERE, '_t520-xml-read.py').
  // T-451's census decides reachability by TEXTUAL reference to `tools/<name>` in an executable
  // position, and its own LIMIT section says a caller composing the path at runtime is invisible
  // to it. The composed form made this reader look like a standing guard with no live caller and
  // moved the ratchet by +1. Spelling the path out makes the edge visible to inspection, which
  // is what the census is actually asking for — cheaper and more honest than a baseline entry.
  const p = spawn('python3', [join(REPO, 'tools/_t520-xml-read.py')], { stdio: ['pipe', 'pipe', 'pipe'] });
  let o = '', e = '';
  p.stdout.on('data', d => o += d); p.stderr.on('data', d => e += d);
  p.on('close', code => {
    if (code !== 0) return rej(new Error('conforming reader exited ' + code + ': ' + e.slice(-300)));
    try { res(JSON.parse(o)); } catch (_) { rej(new Error('conforming reader emitted non-JSON: ' + o.slice(0, 200))); }
  });
  p.stdin.end(Buffer.from(text, 'utf8'));
});

async function main() {
  if (!existsSync(CORPUS)) return refuse('no corpus at ' + CORPUS);
  const files = readdirSync(CORPUS).filter(f => f.endsWith('.bpmn')).sort();
  if (!files.length) return refuse('corpus empty — an xml-safety probe with no subject is not a pass');
  const srcName = basename(files[0], '.bpmn');
  const ORIGINAL = readFileSync(join(CORPUS, files[0]), 'utf8');

  const doc = mkdtempSync(join(tmpdir(), 't520-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't520-repo-'));
  copyFileSync(join(REPO, SRC), join(doc, 'designer.html'));
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't520-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    cl = cdp(tg.find(t => t.type === 'page').webSocketDebuggerUrl); await cl.ready;
    const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(200);

    const base = await readConforming(ORIGINAL);
    if (!base.parsed) return refuse('the corpus fixture itself does not parse — no verdict here is about the editor', { error: base.error });
    const nodeUids = base.uids.filter(u => u && u.startsWith('n_'));
    if (!nodeUids.length) return refuse(`corpus map ${srcName} carries no node uid to substitute — nothing to make hostile`);

    // The carrier is chosen by VALUE, not by element id: T-513 established that the element id
    // is re-minted from lane + x-order + name on every save, so it is the one handle this
    // operation rewrites. T-518 keyed on it and produced pure artifacts. Not repeating that.
    const TARGET = nodeUids[0];
    const occurrences = ORIGINAL.split(`value="${TARGET}"`).length - 1;
    if (occurrences !== 1) return refuse(`target uid ${show(TARGET)} appears ${occurrences} times as an attribute literal — substitution would not be surgical`, { TARGET });

    const results = [];
    for (const c of CANDIDATES) {
      const staged = stage(c.raw);
      const input = ORIGINAL.replace(`value="${TARGET}"`, `value="${staged}"`);

      // ── stimulus check (PL-206), BEFORE any round-trip ────────────────────────────────
      // Does a parser reading this input actually see the value we meant? If not, the
      // round-trip below would be measuring something other than the candidate.
      // Staged value is judged by the CONFORMING parser too: what matters is the value AEF's
      // side would see, not the value this browser happens to reconstruct.
      const inp = await readConforming(input);
      if (!inp.parsed) {
        // Not a broken fixture — XML itself rejects the character. That IS the finding, and it
        // is separable from a fixture bug only because `plain` goes through this same path.
        results.push({ key: c.key, outcome: 'not-representable-in-xml', why: c.why, detail: (inp.error || '').split('\n')[0] });
        continue;
      }
      if (!inp.uids.includes(c.raw)) {
        if (c.key === 'plain') return refuse('the NEGATIVE CONTROL could not be staged — the harness cannot put a known-safe value into the fixture, so no verdict in this run means anything', { staged, saw: inp.uids.slice(0, 5) });
        results.push({ key: c.key, outcome: 'lost-on-input', why: c.why, staged, saw_instead: inp.uids.filter(u => !base.uids.includes(u)) });
        continue;
      }

      // ── the measurement ───────────────────────────────────────────────────────────────
      let out;
      try { out = await ev(cmd, ROUNDTRIP(input)); }
      catch (e) { results.push({ key: c.key, outcome: 'editor-threw', why: c.why, detail: String(e.message).slice(0, 200) }); continue; }
      const after = await readConforming(out);
      const afterBrowser = await ev(cmd, READ(out));
      // Collected for every candidate, reported only when the two readers disagree — that
      // disagreement is the whole seam risk: 832 sees one value, AEF sees another, silently.
      const browserSaw = afterBrowser.parsed ? afterBrowser.uids.filter(u => !base.uids.includes(u)) : null;
      const readerSplit = afterBrowser.parsed && after.parsed
        && (afterBrowser.uids.includes(c.raw) !== after.uids.includes(c.raw));
      if (!after.parsed) {
        // The serious one: the editor accepted a legal value and emitted a document nobody can
        // parse. Loud, but loud AFTER the file is written is still data loss.
        results.push({ key: c.key, outcome: 'output-malformed', why: c.why, detail: (after.error || '').split('\n')[0] });
        continue;
      }
      // How the value was actually SPELLED on the wire. The parsed value being right already
      // proves the encoding is correct — a raw newline in an attribute would normalise to a
      // space and come back transformed — but the literal is the evidence a reader can check,
      // and it is what tells AEF *why* the lossy-by-spec cases are not lossy here.
      const lits = [...String(out).matchAll(/<aef:uid[^>]*value="([^"]*)"/g)].map(m => m[1]);
      const baseLits = [...String(ORIGINAL).matchAll(/<aef:uid[^>]*value="([^"]*)"/g)].map(m => m[1]);
      const emitted = lits.find(l => !baseLits.includes(l)) ?? null;

      const n = after.uids.filter(u => u === c.raw).length;
      const split = readerSplit ? { reader_disagreement: true, browser_saw: browserSaw } : {};
      if (n === 1) { results.push({ key: c.key, outcome: 'identical', why: c.why, emitted_as: emitted, ...split }); continue; }
      if (n > 1) { results.push({ key: c.key, outcome: 'duplicated', why: c.why, count: n, ...split }); continue; }
      const fresh = after.uids.filter(u => !base.uids.includes(u));
      results.push({
        key: c.key, outcome: 'transformed', why: c.why, sent: c.raw,
        came_back: fresh.length ? fresh : null, emitted_as: emitted, ...split,
      });
    }

    if (results.find(r => r.key === 'plain')?.outcome !== 'identical') {
      return refuse('the NEGATIVE CONTROL did not survive byte-identical — "identical" is then a property of nothing and every other verdict in this run is uninterpretable',
                    { plain: results.find(r => r.key === 'plain') });
    }

    const unpinned = results.filter(r => !(r.key in PIN));
    if (unpinned.length) return refuse('candidate(s) with no pinned reference — an unpinned case must not be able to pass', { unpinned: unpinned.map(r => r.key) });
    const changed = results.filter(r => PIN[r.key] !== r.outcome).map(r => ({ key: r.key, pinned: PIN[r.key], measured: r.outcome }));

    const report = {
      ok: changed.length === 0,
      probe: 'T-520 aef:uid XML-attribute safety',
      corpus_map: srcName,
      carrier_uid_replaced: TARGET,
      results,
      changed,
      does_not_cover: [
        'one corpus map, one node carrier — not edges, not subProcess-nested elements',
        'values assigned through interactive authoring rather than import',
        "AEF's reverse renderer, which cannot be exercised from here",
      ],
    };
    console.log(JSON.stringify(report, null, 2));
    if (changed.length) {
      console.log('\nCHANGED — the editor no longer treats these values as pinned. Tell AEF: their');
      console.log('reverse renderer keys records on uid, so a changed transform silently re-points records.');
      process.exitCode = 1;
    }
  } catch (e) {
    refuse('probe could not run: ' + (e && e.message ? e.message : String(e)));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill(); } catch (_) {}
    try { py.kill(); } catch (_) {}
  }
}

main();
