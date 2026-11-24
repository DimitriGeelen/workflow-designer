// T-1500 — a lane's <bpmn:documentation> is kept on save. The lane importer never read it, so every save dropped it
// (Greenfield keeps a lane's owner role there, msg 2e879869). Greenfield's sample with lane documentation added:
//
//   K1 every lane documentation comes back on save, text identical, id/textFormat kept, in file order, as the lane's
//      first children (before its extensionElements, tBaseElement order)
//   K2 a second open → save of that output is byte-identical to the first save (stable)
//   K3 a lane without documentation is written as before: the lanes with none carry no documentation element
// Teeth: T1500_EDITOR=<the 0.47.0 designer> fails K1.
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
const EDITOR = process.env.T1500_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const SAMPLE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
// documentation added to two of the sample's four lanes (the sample itself carries none)
const DOCS = {
  Lane_Salesforce: ['<bpmn:documentation>Owner: Sales (account manager)</bpmn:documentation>',
                    '<bpmn:documentation id="Doc_sf_2" textFormat="text/plain">Rule: every opportunity has an account &amp; a contact</bpmn:documentation>'],
  Lane_Tacton: ['<bpmn:documentation>Owner: Pre-sales engineering</bpmn:documentation>'],
};
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

let xml = readFileSync(SAMPLE, 'utf8');
for (const [id, docs] of Object.entries(DOCS)) {
  const re = new RegExp(`(<bpmn:lane id="${id}"[^>]*>)`);
  if (!re.test(xml)) { console.log(`harness: lane ${id} not in the sample`); process.exit(2); }
  xml = xml.replace(re, `$1${docs.join('')}`);
}
const doc = mkdtempSync(join(tmpdir(), 't1500-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
// the documentation elements directly inside one lane of a saved document, and where they sit
const laneDocs = (s, id) => {
  const m = new RegExp(`<bpmn:lane id="${id}"[^>]*>([\\s\\S]*?)</bpmn:lane>`).exec(s);
  if (!m) return null;
  const body = m[1];
  const docs = [...body.matchAll(/<bpmn:documentation\b[^>]*>[\s\S]*?<\/bpmn:documentation>/g)].map(x => x[0]);
  const firstExt = body.indexOf('<bpmn:extensionElements');
  const lastDoc = docs.length ? body.lastIndexOf(docs[docs.length - 1]) : -1;
  return { docs, beforeExt: !docs.length || firstExt < 0 || lastDoc < firstExt };
};
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1500-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  // a fresh page with empty storage: a second import in the same page is renamed <id>_v2 by the library (by design)
  const fresh = async () => {
    for (const pass of [0, 1]) {
      await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
      for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
      if (!pass) await ev(`(function(){ try { localStorage.clear(); sessionStorage.clear(); } catch (e) {} return true; })()`);
    }
  };
  await fresh();
  const save = x => ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); return buildBpmnXml(state); })(${JSON.stringify(x)})`);
  const s1 = await save(xml);
  const bad = [];
  for (const [id, want] of Object.entries(DOCS)) {
    const got = laneDocs(s1, id);
    if (!got) { bad.push(`${id}: lane not in the save`); continue; }
    if (JSON.stringify(got.docs) !== JSON.stringify(want)) bad.push(`${id}: ${JSON.stringify(got.docs).slice(0, 160)}`);
    if (!got.beforeExt) bad.push(`${id}: documentation after extensionElements`);
  }
  leg(!bad.length, `K1 the lane documentation of ${Object.keys(DOCS).length} lanes (${Object.values(DOCS).flat().length} elements) is written back identically, in order, first in each lane`, bad.join('; '));
  await fresh();
  const s2 = await save(s1);
  leg(s1 === s2, `K2 the saved file, opened again on a fresh page and saved, is byte-identical (${s1.length} chars)`);
  const others = ['Lane_Novis', 'Lane_NAV'].map(id => [id, laneDocs(s1, id)]).filter(([, g]) => !g || g.docs.length);
  leg(!others.length, `K3 the lanes without documentation carry none`, others.map(([id]) => id).join(', '));
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
