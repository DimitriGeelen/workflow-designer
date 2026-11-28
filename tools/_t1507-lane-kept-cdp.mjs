// T-1507 — a lane's other-tool attributes and extensionElements children are kept on save. The lane importer read only
// id, name, documentation (T-1500) and aef:laneMeta, so every save dropped the rest (T-1506 census: every lane of
// Greenfield's sample and the kitchen-sink). Both fixtures, with foreign lane data added here (they carry none):
//
//   L1 Greenfield's sample: Lane_Salesforce's camunda:candidateGroups (prefix declared on the root) and its
//      camunda:properties extension, and Lane_Tacton's sig:color (prefix declared on the lane itself) come back on save,
//      namespaces intact; the kitchen-sink's lane keeps its k:mark attribute and k:meta extension
//   L2 the save, opened again on a fresh page and saved, is byte-identical
//   L3 lane edits: a renamed lane with a new authority keeps its foreign data; an added lane has none; a deleted lane
//      takes its own with it
//   L4 both fixtures as they are (no foreign lane data) save byte-identically to the released designer (T1507_READER,
//      default dist 0.53.0)
// Teeth: T1507_EDITOR=<dist 0.53.0> fails L1, L3.
import { readFileSync, mkdtempSync, copyFileSync, existsSync, readdirSync, rmSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { makeProfileDir, removeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp } from './_cdp-client.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const EDITOR = process.env.T1507_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const READER = process.env.T1507_READER || join(ROOT, 'dist', 'aef-workflow-designer-0.53.0.html');
const SAMPLE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
const KSINK = join(ROOT, 'tests/fixtures/third-party/kitchen-sink.bpmn');
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

const CAM = 'http://camunda.org/schema/1.0/bpmn', SIG = 'http://www.signavio.com', KNS = 'urn:t1507:k';
const gf0 = readFileSync(SAMPLE, 'utf8'), ks0 = readFileSync(KSINK, 'utf8');
const sub = (x, re, by) => { if (!re.test(x)) { console.log(`harness: ${re} not in the fixture`); process.exit(2); } return x.replace(re, by); };
let gf = sub(gf0, /<bpmn:definitions\b/, `<bpmn:definitions xmlns:camunda="${CAM}"`);
gf = sub(gf, /<bpmn:lane id="Lane_Salesforce" name="Salesforce">/,
  `<bpmn:lane id="Lane_Salesforce" name="Salesforce" camunda:candidateGroups="sales"><bpmn:extensionElements><camunda:properties><camunda:property name="owner" value="Sales" /></camunda:properties></bpmn:extensionElements>`);
gf = sub(gf, /<bpmn:lane id="Lane_Tacton" name="Tacton">/, `<bpmn:lane id="Lane_Tacton" name="Tacton" xmlns:sig="${SIG}" sig:color="#ffcc00">`);
const ks = sub(ks0, /<bpmn:lane id="Lane_1vakzes" name="Lane">/,
  `<bpmn:lane id="Lane_1vakzes" name="Lane" xmlns:k="${KNS}" k:mark="m1"><bpmn:extensionElements><k:meta a="b" /></bpmn:extensionElements>`);
// what a saved document says about one lane, read by the browser's own XML parser
const LANE = `(function(x, id){ var d = new DOMParser().parseFromString(x, 'application/xml');
  if (d.getElementsByTagName('parsererror').length) return { error: 'parsererror' };
  var l = Array.from(d.getElementsByTagNameNS('http://www.omg.org/spec/BPMN/20100524/MODEL', 'lane')).find(function(e){ return e.getAttribute('id') === id; });
  if (!l) return null;
  var ext = Array.from(l.children).find(function(c){ return c.localName === 'extensionElements'; });
  return { name: l.getAttribute('name'), cand: l.getAttributeNS('${CAM}', 'candidateGroups'), color: l.getAttributeNS('${SIG}', 'color'),
    mark: l.getAttributeNS('${KNS}', 'mark'),
    ext: ext ? Array.from(ext.children).map(function(c){ return c.namespaceURI + ' ' + c.localName
      + (c.localName === 'properties' && c.firstElementChild ? ':' + c.firstElementChild.getAttribute('name') + '=' + c.firstElementChild.getAttribute('value') : '')
      + (c.getAttribute('a') ? ' a=' + c.getAttribute('a') : ''); }) : [] }; })`;

const doc = mkdtempSync(join(tmpdir(), 't1507-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
if (existsSync(READER)) copyFileSync(READER, join(doc, 'reader.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1507-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--disable-dev-shm-usage', '--no-sandbox', '--disable-gpu', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  // a fresh page with empty storage: a second import in the same page is renamed <id>_v2 by the library (by design)
  const fresh = async (page = 'designer.html') => {
    for (const pass of [0, 1]) {
      await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/${page}` });
      for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
      if (!pass) await ev(`(function(){ try { localStorage.clear(); sessionStorage.clear(); } catch (e) {} return true; })()`);
    }
  };
  const save = x => ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); return buildBpmnXml(state); })(${JSON.stringify(x)})`);
  const lane = (x, id) => ev(`${LANE}(${JSON.stringify(x)}, ${JSON.stringify(id)})`);

  await fresh();
  const s1 = await save(gf);
  const sf = await lane(s1, 'Lane_Salesforce'), tc = await lane(s1, 'Lane_Tacton');
  await fresh();
  const k1 = await save(ks);
  const kl = await lane(k1, 'Lane_1vakzes');
  const okSf = sf && sf.cand === 'sales' && sf.ext.includes(`${CAM} properties:owner=Sales`) && sf.ext.some(e => / laneMeta$/.test(e));
  const okTc = tc && tc.color === '#ffcc00';
  const okK = kl && kl.mark === 'm1' && kl.ext.includes(`${KNS} meta a=b`);
  leg(okSf && okTc && okK, 'L1 the lanes\' foreign attributes (root- and lane-declared prefixes) and foreign extensions come back on save, namespaces intact (Greenfield sample, kitchen-sink)',
    JSON.stringify({ sf, tc, kl }).slice(0, 500));

  await fresh();
  const s2 = await save(s1);
  await fresh();
  const k2 = await save(k1);
  leg(s1 === s2 && k1 === k2, `L2 each save, opened again on a fresh page and saved, is byte-identical (${s1.length}, ${k1.length} chars)`);

  await fresh();
  const e3 = await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll();
    var l = state.lanes.find(function(l){ return l.id === 'Lane_Salesforce'; }); l.name = 'Sales CRM'; l.authority = 'sovereignty';
    addLane(); var added = state.lanes[state.lanes.length - 1].id;
    deleteLane('Lane_Tacton'); renderAll(); return { added: added, xml: buildBpmnXml(state) }; })(${JSON.stringify(gf)})`);
  const r = await lane(e3.xml, 'Lane_Salesforce'), a = await lane(e3.xml, e3.added), gone = await lane(e3.xml, 'Lane_Tacton');
  leg(!!r && r.name === 'Sales CRM' && r.cand === 'sales' && r.ext.includes(`${CAM} properties:owner=Sales`)
      && !!a && !a.cand && !a.color && a.ext.every(e => / laneMeta$/.test(e)) && !gone && !/sig:color/.test(e3.xml),
    'L3 a renamed lane with a new authority keeps its foreign data; an added lane has none; a deleted lane takes its own with it',
    JSON.stringify({ r, a, gone, sigLeft: /sig:color/.test(e3.xml) }).slice(0, 400));

  // L4 no foreign lane data: byte-identical to the released designer (the sample declares no workflowMeta, so each open
  // mints a uuid: set it aside)
  const nu = x => x.replace(/(<aef:workflowMeta\b[^>]*\suuid=")[^"]*"/, '$1U"');
  await fresh(); const g0 = await save(gf0); await fresh(); const kk0 = await save(ks0);
  let rg = null, rk = null;
  if (existsSync(join(doc, 'reader.html'))) { await fresh('reader.html'); rg = await save(gf0); await fresh('reader.html'); rk = await save(ks0); }
  leg(!!rg && nu(rg) === nu(g0) && nu(rk) === nu(kk0), 'L4 both fixtures without foreign lane data save byte-identically to the released designer',
    JSON.stringify({ reader: !!rg, gf: !!rg && nu(rg) === nu(g0), ks: !!rk && nu(rk) === nu(kk0) }));
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
