#!/usr/bin/env node
// _t253-live-url-probe.mjs — read-only probe of the LIVE :8834 gallery URL the
// operator reported dead. Own isolated headless chromium + fresh profile (G-006);
// only GETs the served pages, writes nothing server-side.
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join } from 'node:path';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp as cdpClient } from './_cdp-client.mjs';   // T-1395: rejects on Chrome's death and after cmdMs, never waits for ever

const URL_UNDER_TEST = process.argv[2] || 'http://127.0.0.1:8834/designer.html?load=rendered%2Fharvest-pipeline.bpmn';   // this host (T-1239)
const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const events = []; const c = cdpClient(ws, { onEvent: m => events.push(m) }); return { ...c, events }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) return { __err: JSON.stringify(r.exceptionDetails).slice(0, 500) }; return r.result.value; }

async function main() {
  const udd = makeProfileDir('t253probe-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1400,900', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let cl;
  try {
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable'); await cmd('Log.enable');
    await cmd('Page.navigate', { url: URL_UNDER_TEST });
    await sleep(3500);
    const state = await ev(cmd, `(function(){
      try {
        return { appReady: typeof _appReady !== 'undefined' ? _appReady : '(undef)',
                 mapId: (typeof state !== 'undefined' && state.workflowMeta) ? state.workflowMeta.id : '(no state)',
                 nodes: (typeof state !== 'undefined' && state.nodes) ? state.nodes.length : -1,
                 zoomBtn: !!document.getElementById('btn-zoom-fit'),
                 title: document.title, url: location.href };
      } catch (e) { return { err: String(e) }; }
    })()`);
    const consoleMsgs = cl.events.filter(e => e.method === 'Runtime.exceptionThrown' || e.method === 'Log.entryAdded')
      .map(e => JSON.stringify(e.params).slice(0, 300));
    const png = await cmd('Page.captureScreenshot', { format: 'png' });
    writeFileSync(join(process.cwd(), '.playwright-mcp', 't253-live-probe.png'), Buffer.from(png.data, 'base64'));
    console.log(JSON.stringify({ url: URL_UNDER_TEST, state, consoleMsgs }, null, 1));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    try { br.kill('SIGKILL'); } catch (_) {}
    try { rmSync(udd, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
