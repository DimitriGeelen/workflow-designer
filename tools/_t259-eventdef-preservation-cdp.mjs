#!/usr/bin/env node
// _t259-eventdef-preservation-cdp.mjs — T-259 (T-257 GO) correctness guard for the
// eventDef preservation passthrough on start/throw hosts. The fixed-point round-trip
// harness (_roundtrip-serialization-cdp.mjs) cannot catch a CONSISTENT drop: parse
// discarding <aef:eventDef> and build never emitting it is a perfectly stable fixed
// point — exactly the rail-201 field defect (AEF T-2620: layout-only open→save in
// 0.4.0 destroyed start timer + throw message eventDefs while the catch survived).
// This harness drives the REAL editor runtime against the REAL peer field bytes
// (tests/fixtures/aef-bpmn/t257-eventdef-roundtrip/draft-trigger-handling-v1.bpmn,
// byte-check EXACT MATCH by AEF at rail 215) and asserts:
//   * parse keeps th_obs_fire a startEvent and th_signal a linkEventThrow (NO type
//     override — the T-237 catch-only decision is untouched) with the eventDef
//     kind/binding captured as inert passthrough fields;
//   * th_pickup still takes the T-204 typed-catch override (type eventMessage) —
//     precedence unchanged;
//   * build re-emits all three <aef:eventDef> markers, exactly one per carrier,
//     inside the correct host tags (startEvent / intermediateThrowEvent stay
//     themselves — no tag mutation);
//   * the emitted XML re-parses to the same model (passthrough is itself a fixed
//     point, so a SECOND save is also lossless);
//   * BITE: with <aef:eventDef> stripped from the source, no passthrough fields
//     appear and no eventDef is emitted — the guard is driven by the element,
//     not vacuous string echo.
// Isolation mirrors the typed-events harness: temp docroot served by
// gallery-serve.py on a free port, isolated headless chromium (G-006).
// Exit 0 = preserved + bites; 1 = assertion failed; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, mkdirSync, copyFileSync, rmSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SERVER = join(HERE, 'gallery-serve.py');
const FIXTURE = join(REPO, 'tests', 'fixtures', 'aef-bpmn', 't257-eventdef-roundtrip', 'draft-trigger-handling-v1.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof parseBpmnXml==='function'&&typeof buildBpmnXml==='function'&&typeof refreshDisplayIds==='function'&&_appReady===true)`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const ASSERT_EXPR = `(function(){
  var text = window.__FIXTURE__;
  var errs = [];
  // The three eventDef carriers in the peer field bytes (rail 208/209, byte-verified 215):
  //   th_obs_fire  startEvent               <aef:eventDef kind="timer"/>            → passthrough
  //   th_signal    intermediateThrowEvent    <aef:eventDef kind="message"/>          → passthrough
  //   th_pickup    intermediateCatchEvent    <aef:eventDef kind="message"/>          → T-204 override (unchanged)
  function checkModel(m, label){
    if(!m){ errs.push(label+': parse-null'); return null; }
    var byUid = {}; m.nodes.forEach(function(n){ byUid[n.uid]=n; });
    var s = byUid['th_obs_fire'], t = byUid['th_signal'], c = byUid['th_pickup'];
    if(!s || !t || !c){ errs.push(label+': missing carrier node(s)'); return byUid; }
    if(s.type !== 'startEvent') errs.push(label+': th_obs_fire type '+s.type+' != startEvent (passthrough must not override type)');
    if((s.aef||{}).eventDefKind !== 'timer') errs.push(label+': th_obs_fire eventDefKind '+JSON.stringify((s.aef||{}).eventDefKind)+' != "timer"');
    if(t.type !== 'linkEventThrow') errs.push(label+': th_signal type '+t.type+' != linkEventThrow (passthrough must not override type)');
    if((t.aef||{}).eventDefKind !== 'message') errs.push(label+': th_signal eventDefKind '+JSON.stringify((t.aef||{}).eventDefKind)+' != "message"');
    if(c.type !== 'eventMessage') errs.push(label+': th_pickup type '+c.type+' != eventMessage (T-204 catch override regressed)');
    if((c.aef||{}).eventDefKind) errs.push(label+': th_pickup grew a passthrough eventDefKind — override must consume the element');
    return byUid;
  }
  try {
    var m = checkModel(parseBpmnXml(text), 'parse1');
    if(errs.length) return { ok:false, errs:errs };
    state = parseBpmnXml(text); refreshDisplayIds();
    // T-311: authored doc blocks now survive the round-trip, so exported bytes can
    // contain prose that names elements. Every assertion below is structural, so it
    // reads the document without its comments. This fixture's doc block happens not
    // to quote <aef:eventDef> today — the strip is here so that stays irrelevant
    // rather than becoming a silent false green when the fixture text is edited.
    var emit = buildBpmnXml(state).replace(/<!--[\\s\\S]*?-->/g, '');
    var n = (emit.match(/<aef:eventDef /g)||[]).length;
    if(n !== 3) errs.push('emit: expected exactly 3 <aef:eventDef>, got '+n);
    if(emit.indexOf('<aef:eventDef kind="timer" binding=""/>') < 0) errs.push('emit: missing canonical timer eventDef');
    // Host tags must survive untouched (no throw→catch mutation — the T-237 concern):
    function hostBlock(uid, tag){
      var re = new RegExp('<bpmn:'+tag+' [^>]*>[\\\\s\\\\S]*?<\\\\/bpmn:'+tag+'>','g');
      var blocks = emit.match(re)||[];
      for (var i=0;i<blocks.length;i++) if(blocks[i].indexOf('<aef:uid value="'+uid+'"') >= 0) return blocks[i];
      return null;
    }
    var sb = hostBlock('th_obs_fire','startEvent');
    if(!sb) errs.push('emit: th_obs_fire not inside a <bpmn:startEvent> block');
    else if(sb.indexOf('<aef:eventDef kind="timer"') < 0) errs.push('emit: startEvent block lost its timer eventDef');
    var tb = hostBlock('th_signal','intermediateThrowEvent');
    if(!tb) errs.push('emit: th_signal not inside a <bpmn:intermediateThrowEvent> block (tag mutated?)');
    else if(tb.indexOf('<aef:eventDef kind="message"') < 0) errs.push('emit: throw block lost its message eventDef');
    // Second save is also lossless — the passthrough is a fixed point:
    checkModel(parseBpmnXml(emit), 'reparse');
    // BITE: strip every eventDef from the source — passthrough fields must NOT
    // appear and the emitted XML must carry ZERO eventDefs.
    var stripped = text.replace(/<aef:eventDef[^>]*\\/>/g, '');
    var m2 = parseBpmnXml(stripped);
    var byUid2 = {}; if(m2) m2.nodes.forEach(function(n){ byUid2[n.uid]=n; });
    var p2 = byUid2['th_obs_fire'];
    var biteOk = !!p2 && !((p2.aef||{}).eventDefKind);
    if(!biteOk) errs.push('BITE FAIL: stripped source still produced eventDefKind '+(p2&&p2.aef?JSON.stringify(p2.aef.eventDefKind):'<missing node>'));
    if(m2){ state = m2; refreshDisplayIds(); var emit2 = buildBpmnXml(state);
      var n2 = (emit2.match(/<aef:eventDef /g)||[]).length;
      if(n2 !== 0){ errs.push('BITE FAIL: stripped source emitted '+n2+' eventDef(s)'); biteOk = false; } }
    return { ok: errs.length===0, errs:errs, biteOk:biteOk };
  } catch(e) { return { ok:false, errs:['exception: '+(e&&e.message||e)] }; }
})()`;

async function main() {
  if (!existsSync(FIXTURE)) { process.stdout.write(JSON.stringify({ ok:false, error:'fixture missing: '+FIXTURE })+'\n'); process.exitCode = 2; return; }
  const text = readFileSync(FIXTURE, 'utf8');
  const doc = mkdtempSync(join(tmpdir(), 't259-doc-'));
  const repo = mkdtempSync(join(tmpdir(), 't259-repo-'));
  copyFileSync(join(REPO, 'src/aef-workflow-designer.html'), join(doc, 'designer.html'));
  mkdirSync(join(doc, 'rendered'), { recursive: true });
  const port = await freePort();
  const py = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let pyErr = ''; py.stderr.on('data', d => pyErr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't259-udd-'));
  const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1200,820', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    let up = false; for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) { up = true; break; } } catch (_) {} await sleep(100); }
    if (!up) throw new Error('sidecar down:\n' + pyErr.slice(-400));
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    const tg = await (await fetch(`http://127.0.0.1:${dp}/json`)).json();
    const page = tg.find(t => t.type === 'page');
    cl = cdp(page.webSocketDebuggerUrl); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: `${BASE}/designer.html` });
    await waitReady(cmd); await sleep(300);
    await ev(cmd, `window.__FIXTURE__ = ${JSON.stringify(text)};`);
    const r = await ev(cmd, ASSERT_EXPR);
    const out = { ok: !!(r && r.ok), preservation: r };
    process.stdout.write(JSON.stringify(out, null, 2) + '\n');
    process.exitCode = out.ok ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ ok: false, error: String(e && e.stack || e) }, null, 2) + '\n');
    process.exitCode = 1;
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { py.kill('SIGKILL'); } catch (_) {}
    try { rmSync(repo, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
