// T-1093 feasibility spike, IW-5 (inception evidence, NOT product code).
//
// Question: Excel, CSV and Mermaid imports carry steps and flows but no positions. If such an import is turned into
// BPMN WITHOUT the diagram part (no bpmndi), does the designer's existing BPMN import still produce a map, and does
// the existing Clean layout make it readable? Then every position-less format reuses one path.
// Method: take a real corpus map, delete its <bpmndi:BPMNDiagram>, load it in the real designer headless, report
// node count, how many nodes sit on top of each other before and after Clean, the validator's verdict, and a shot.
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, copyFileSync, existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir, homedir } from 'node:os';
import { spawn } from 'node:child_process';
import net from 'node:net';
import { makeProfileDir } from '../../../tools/_cdp-profile.mjs';
import { pageWsUrl } from '../../../tools/_cdp-attach.mjs';
import { cdp } from '../../../tools/_cdp-client.mjs';

const OUT = process.argv[2] || '/tmp/t1093-nolayout';
mkdirSync(OUT, { recursive: true });
const MAP = 'arc-lifecycle.bpmn';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const full = readFileSync(join('examples/aef-processes/rendered', MAP), 'utf8');
const bare = full.replace(/<bpmndi:BPMNDiagram[\s\S]*<\/bpmndi:BPMNDiagram>/, '')
                 .replace(/<aef:position\b[^>]*\/>/g, '');          // the designer's own position hint too
writeFileSync(join(OUT, 'bare.bpmn'), bare);
const doc = mkdtempSync(join(tmpdir(), 't1093-nl-'));
copyFileSync('src/aef-workflow-designer.html', join(doc, 'designer.html'));
mkdirSync(join(doc, 'rendered')); writeFileSync(join(doc, 'rendered', 'bare.bpmn'), bare);
const port = await new Promise(r => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => r(p)); }); });
const py = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', doc], { stdio: 'ignore' });
const cache = join(homedir(), '.cache', 'ms-playwright');
const chrome = readdirSync(cache).filter(d => d.startsWith('chromium-')).sort().reverse().map(d => join(cache, d, 'chrome-linux64', 'chrome')).find(existsSync);
const udd = makeProfileDir('t1093nl-');
const br = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu', '--window-size=1440,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
let cl;
try {
  let dp; for (let i = 0; i < 100 && !dp; i++) { try { dp = parseInt(readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').split('\n')[0], 10); } catch (_) { await sleep(100); } }
  cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
  const ev = async e => { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 400)); return r.result.value; };
  await cmd('Page.enable'); await sleep(600);
  await cmd('Page.navigate', { url: `http://127.0.0.1:${port}/designer.html?load=rendered/bare.bpmn` });
  for (let i = 0; i < 100; i++) { if (await ev(`typeof _appReady!=='undefined'&&_appReady===true`).catch(() => false)) break; await sleep(150); }
  await sleep(500);
  const measure = `(function(){ const n = state.nodes; const key = x => Math.round(x.x) + ',' + Math.round(x.y);
    const seen = {}; n.forEach(x => seen[key(x)] = (seen[key(x)] || 0) + 1);
    const stacked = Object.values(seen).filter(v => v > 1).reduce((a, v) => a + v, 0);
    const lanes = new Set(n.map(x => x.lane || x.laneId || '')).size;
    return { nodes: n.length, flows: (state.edges || state.flows || []).length, stacked, lanes }; })()`;
  const before = await ev(measure);
  await cmd('Page.captureScreenshot', { format: 'png' }).then(r => writeFileSync(join(OUT, 'before-clean.png'), Buffer.from(r.data, 'base64')));
  await ev(`document.getElementById('btn-clean').click()`); await sleep(800);
  await ev(`(setZoom(null), 1)`); await sleep(300);
  const after = await ev(measure);
  await cmd('Page.captureScreenshot', { format: 'png' }).then(r => writeFileSync(join(OUT, 'after-clean.png'), Buffer.from(r.data, 'base64')));
  const xml = await ev(`buildBpmnXml(state)`); writeFileSync(join(OUT, 'after-clean.bpmn'), xml);
  const res = { map: MAP, bareHasDiagram: /BPMNDiagram/.test(bare), before, after };
  writeFileSync(join(OUT, 'result.json'), JSON.stringify(res, null, 1));
  console.log(JSON.stringify(res));
} finally {
  try { cl && cl.close(); } catch (_) {}
  br.kill('SIGKILL'); py.kill('SIGKILL');
  process.exit(process.exitCode ?? 0);
}
