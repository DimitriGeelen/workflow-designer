// T-1492 (Greenfield msg 2e879869, request 1) — a selected element's bpmn:documentation is shown in the properties
// panel, read-only, one labelled block per line prefix (Instruction, Rule, Keys, Mapping, Open, Detail, Decision,
// Notes). Greenfield's sample with documentation added in their format to a task, the gateway, the start event and a
// lane (the sample itself carries none):
//
//   D1 [task] the Documentation section shows the blocks in prefix order, each item's text as written; an indented
//      line continues the item above; an unprefixed line is under Notes
//   D2 [gateway, start event] each shows its own documentation
//   D3 [lane] the lane's documentation (its owner role) is shown in the lane's panel (kept on save since T-1500)
//   D4 an element without documentation shows no Documentation section
//   D5 read-only: the save is byte-identical before and after selecting every element and every lane
//   D6 [1024/1440/1920] the task's long documentation stays inside the panel: no horizontal overflow
// Teeth: T1492_EDITOR=<the 0.47.0 designer> fails D1-D3.  T1492_SHOTS=<dir> writes documentation-{1024,1440,1920}.png
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
const EDITOR = process.env.T1492_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');
const SAMPLE = join(ROOT, 'tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn');
const TASK_DOC = [
  'Instruction: Create the opportunity in Salesforce from the customer request.',
  'Rule: An opportunity always has an account and a primary contact; without both it cannot leave stage 1 Qualification, whatever the sales manager agreed by phone.',
  '  This holds for existing customers too.',
  'Keys: Opportunity.Id, Account.Id',
  'Open: Who creates the account when the customer is new?',
  'Decision: Pre-sales is involved from stage 2 on.',
  'Discussed in the workshop of 6-11-2026.',
  'Call back at 10:30 when the customer is new.',
].join('\n');
const INJECT = {
  'bpmn:task id="Activity_opp"': `<bpmn:documentation>${TASK_DOC}</bpmn:documentation>`,
  'bpmn:exclusiveGateway id="Gateway_rd"': '<bpmn:documentation>Rule: Redesign when Tacton cannot configure the requested variant.</bpmn:documentation>',
  'bpmn:startEvent id="StartEvent_start"': '<bpmn:documentation>Detail: A customer request by mail or phone.</bpmn:documentation>',
  'bpmn:lane id="Lane_Salesforce"': '<bpmn:documentation>Owner: Sales (account manager)</bpmn:documentation>',
};
const WANT_TASK = [
  ['Instruction', ['Create the opportunity in Salesforce from the customer request.']],
  ['Rule', ['An opportunity always has an account and a primary contact; without both it cannot leave stage 1 Qualification, whatever the sales manager agreed by phone.\nThis holds for existing customers too.']],
  ['Keys', ['Opportunity.Id, Account.Id']],
  ['Open', ['Who creates the account when the customer is new?']],
  ['Decision', ['Pre-sales is involved from stage 2 on.']],
  ['Notes', ['Discussed in the workshop of 6-11-2026.', 'Call back at 10:30 when the customer is new.']],
];
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0;
const leg = (ok, name, detail) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  ' + detail : ''}`); if (!ok) fails++; };

let xml = readFileSync(SAMPLE, 'utf8');
for (const [open, docEl] of Object.entries(INJECT)) {
  const re = new RegExp(`(<${open.replace(/"/g, '"')}[^>]*>)`);
  if (!re.test(xml)) { console.log(`harness: <${open}> not in the sample`); process.exit(2); }
  xml = xml.replace(re, `$1${docEl}`);
}
const doc = mkdtempSync(join(tmpdir(), 't1492-doc-'));
copyFileSync(EDITOR, join(doc, 'designer.html'));
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
// select by the file's element id (nodes) or lane id; read the Documentation section's blocks
const READ = sel => `(function(){
  ${sel}; renderProperties();
  var s = document.querySelector('[data-testid="props-documentation"]');
  if (!s) return null;
  var p = document.getElementById('props') || s.parentElement;
  return { blocks: Array.from(s.querySelectorAll('.doc-block')).map(function(b){
             return [b.querySelector('.doc-label').textContent, Array.from(b.querySelectorAll('.doc-item')).map(function(i){ return i.textContent; })]; }),
           overflow: Math.max(s.scrollWidth - s.clientWidth, p ? p.scrollWidth - p.clientWidth : 0) };
})()`;
const NODE = text => `var n = state.nodes.find(function(n){ return (n.documentation || []).some(function(d){ return d.text.indexOf(${JSON.stringify(text)}) >= 0; }); });
  selection = n ? { kind: 'node', id: n.id } : null`;
const profiles = [];
let br = null, cl = null;
const stop = async () => { try { cl && cl.close(); } catch (_) {} if (br) { const d = new Promise(r => br.once('exit', r)); try { br.kill('SIGKILL'); } catch (_) {} await Promise.race([d, sleep(3000)]); } cl = null; br = null; };
try {
  const ev = async e => { const r = await cl.cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails).slice(0, 300)); return r.result.value; };
  const udd = makeProfileDir('t1492-'); profiles.push(udd);
  br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  let dp; for (let k = 0; k < 150 && !dp; k++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  if (!dp) throw new Error('no devtools port');
  cl = cdp(await pageWsUrl(dp), { cmdMs: 60000 }); await cl.ready;
  await cl.cmd('Page.enable'); await cl.cmd('Runtime.enable');
  await cl.cmd('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  for (const pass of [0, 1]) {
    await cl.cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html` });
    for (let k = 0; k < 150; k++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
    if (!pass) await ev(`(function(){ try { localStorage.clear(); sessionStorage.clear(); } catch (e) {} return true; })()`);
  }
  await ev(`(function(x){ adoptImportedXml(x, { userImport: true }); renderAll(); return true; })(${JSON.stringify(xml)})`);
  const before = await ev(`buildBpmnXml(state)`);
  // the nodes by their documentation text (the importer renames ids to display ids)
  const T = await ev(READ(NODE('Create the opportunity')));
  leg(!!T && JSON.stringify(T.blocks) === JSON.stringify(WANT_TASK), `D1 [task 'Opportunity aanmaken'] blocks in prefix order, continuation joined, unprefixed under Notes`,
    T ? (JSON.stringify(T.blocks) === JSON.stringify(WANT_TASK) ? '' : JSON.stringify(T.blocks).slice(0, 220)) : 'no Documentation section');
  const G = await ev(READ(NODE('Redesign when Tacton')));
  const S = await ev(READ(NODE('A customer request by mail')));
  leg(!!G && !!S && JSON.stringify(G.blocks) === JSON.stringify([['Rule', ['Redesign when Tacton cannot configure the requested variant.']]])
      && JSON.stringify(S.blocks) === JSON.stringify([['Detail', ['A customer request by mail or phone.']]]),
    `D2 [gateway 'Redesign?', start event] each shows its own documentation`, JSON.stringify([G && G.blocks, S && S.blocks]).slice(0, 200));
  const L = await ev(READ(`selection = { kind: 'lane', id: 'Lane_Salesforce' }`));
  leg(!!L && JSON.stringify(L.blocks) === JSON.stringify([['Owner', ['Sales (account manager)']]]),
    `D3 [lane Salesforce] its documentation shown in the lane's panel, a label outside the known list ('Owner') as its own block`, L ? JSON.stringify(L.blocks) : 'no Documentation section');
  const none = await ev(`(function(){ var n = state.nodes.find(function(n){ return !(n.documentation || []).length && /Task$/.test(n.type); });
    selection = { kind: 'node', id: n.id }; renderProperties(); return !!document.querySelector('[data-testid="props-documentation"]'); })()`);
  leg(none === false, `D4 an element without documentation shows no Documentation section`);
  await ev(`(function(){ state.nodes.forEach(function(n){ selection = { kind: 'node', id: n.id }; renderProperties(); });
    getLanes().forEach(function(l){ selection = { kind: 'lane', id: l.id }; renderProperties(); }); selection = null; renderProperties(); return true; })()`);
  const after = await ev(`buildBpmnXml(state)`);
  leg(before.length > 0 && before === after, `D5 the save is byte-identical after selecting every element and lane (${before.length} chars)`);
  const over = [];
  for (const W of [1024, 1440, 1920]) {
    await cl.cmd('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: process.env.T1492_SHOTS ? 2 : 1, mobile: false });
    const r = await ev(`(function(){ renderAll(); return ${READ(NODE('Create the opportunity'))}; })()`);
    if (!r || r.overflow > 0) over.push(`${W}: ${r ? r.overflow + 'px' : 'no section'}`);
    if (process.env.T1492_SHOTS) {
      mkdirSync(process.env.T1492_SHOTS, { recursive: true });
      await ev(`(function(){ var s = document.querySelector('[data-testid="props-documentation"]'); if (s) s.scrollIntoView({ block: 'start' }); return true; })()`);
      await sleep(400);
      const shot = await cl.cmd('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(process.env.T1492_SHOTS, `documentation-${W}.png`), Buffer.from(shot.data, 'base64'));
    }
  }
  leg(!over.length, `D6 [1024/1440/1920] the long documentation stays inside the panel (no horizontal overflow)`, over.join('; '));
} catch (e) {
  leg(false, 'harness error', String(e && e.message || e).slice(0, 300));
} finally {
  await stop(); py.kill('SIGKILL');
  for (const d of profiles) removeProfileDir(d);
  try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  console.log(fails ? `${fails} leg(s) FAILED` : 'all legs passed');
  process.exit(fails ? 1 : 0);
}
