#!/usr/bin/env node
// _set-workflow-kind-cdp.mjs — headless driver for the corpus kind backfill (T-876).
//
// Loads the REAL editor (src/aef-workflow-designer.html) in headless Chromium and, for each
// examples/aef-processes/rendered/*.bpmn:
//   1. adopts the map and serialises it UNCHANGED with the editor's own buildBpmnXml(), so the
//      caller can prove the unset default is inert (the emitted bytes equal the committed file);
//   2. sets state.workflowMeta.kind (as the properties panel's Kind select does, T-911) and
//      serialises again, with a thumbnail for the .editor-versions store append.
// The corpus is EDITOR-SAVED dialect (T-288): never regenerate it with tools/yaml-to-bpmn.py
// (G-012, T-300). Same dependency-free CDP plumbing as tools/_clean-layout-cdp.mjs.
//
// Output: JSON on stdout keyed by map basename:
//   { "<map>": { ok, kindBefore, xmlUnchanged, xml, thumb } }
// Usage:  node tools/_set-workflow-kind-cdp.mjs <kind> [map ...]   (no maps → all rendered/*.bpmn)
import { makeProfileDir } from './_cdp-profile.mjs';
import { spawn } from 'node:child_process';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { homedir } from 'node:os';
import { join, resolve, basename } from 'node:path';
import { pageWsUrl } from './_cdp-attach.mjs';
import { cdp as cdpShared } from './_cdp-client.mjs';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = join(ROOT, 'src', 'aef-workflow-designer.html');
const RENDERED = join(ROOT, 'examples', 'aef-processes', 'rendered');
const KINDS = ['documentation', 'work-plan'];

function findChrome() {
  const roots = [process.env.PLAYWRIGHT_BROWSERS_PATH, join(homedir(), '.cache', 'ms-playwright')].filter(Boolean);
  const cands = [];
  for (const cache of roots) {
    if (!existsSync(cache)) continue;
    for (const d of readdirSync(cache)) {
      if (!d.startsWith('chromium-')) continue;
      cands.push(join(cache, d, 'chrome-linux64', 'chrome'), join(cache, d, 'chrome-linux', 'chrome'));
    }
  }
  cands.sort().reverse();
  for (const c of cands) if (existsSync(c)) return c;
  throw new Error('No Chromium binary found under ' + roots.join(', '));
}

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function waitForPortFile(f, timeoutMs = 30000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (existsSync(f)) {
      const txt = readFileSync(f, 'utf8').split('\n');
      if (txt[0] && txt[0].trim()) return { port: parseInt(txt[0].trim(), 10) };
    }
    await sleep(100);
  }
  throw new Error('Chromium did not report a DevTools port in time');
}

async function evalJson(cmd, expression) {
  const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error('page eval threw: ' + JSON.stringify(r.exceptionDetails));
  return r.result.value;
}

async function main() {
  const [kind, ...rest] = process.argv.slice(2);
  if (!KINDS.includes(kind)) {
    process.stderr.write(`usage: _set-workflow-kind-cdp.mjs <${KINDS.join('|')}> [map ...]\n`);
    process.exitCode = 2;
    return;
  }
  const maps = rest.length
    ? rest.map(a => a.endsWith('.bpmn') ? a : join(RENDERED, a + '.bpmn'))
    : readdirSync(RENDERED).filter(f => f.endsWith('.bpmn')).sort().map(f => join(RENDERED, f));

  const chrome = findChrome();
  const udd = makeProfileDir('kind-chrome-');
  const proc = spawn(chrome, [
    '--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank',
  ], { stdio: ['ignore', 'ignore', 'pipe'] });
  let stderr = '';
  proc.stderr.on('data', d => { stderr += d.toString(); });

  let client;
  try {
    const { port } = await waitForPortFile(join(udd, 'DevToolsActivePort'));
    client = cdpShared(await pageWsUrl(port));
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable');
    await cmd('Runtime.enable');
    await cmd('Page.navigate', { url: 'file://' + EDITOR });
    const t0 = Date.now();
    for (;;) {
      const ok = await evalJson(cmd,
        `(typeof buildBpmnXml==='function' && typeof adoptImportedXml==='function' && typeof state==='object' && !!state)`);
      if (ok) break;
      if (Date.now() - t0 > 60000) throw new Error('Editor did not finish loading (buildBpmnXml undefined)');
      await sleep(150);
    }
    await evalJson(cmd, `(window.alert=window.confirm=window.prompt=function(){return true;},true)`);

    const out = {};
    for (const f of maps) {
      const name = basename(f, '.bpmn');
      const text = readFileSync(f, 'utf8');
      const expr = `(async function(){ try{
        adoptImportedXml(${JSON.stringify(text)});
        if (!state.workflowMeta || typeof state.workflowMeta !== 'object') return {ok:false,error:'no state.workflowMeta after adopt'};
        var before = state.workflowMeta.kind || null;
        var xmlUnchanged = buildBpmnXml(state);
        state.workflowMeta.kind = ${JSON.stringify(kind)};
        var xml = buildBpmnXml(state);
        var thumb=null; try{ if(typeof captureThumbnail==='function') thumb=await captureThumbnail(); }catch(e){}
        return {ok:true,kindBefore:before,xmlUnchanged:xmlUnchanged,xml:xml,thumb:thumb};
      }catch(e){ return {ok:false,error:String(e&&e.stack||e)}; } })()`;
      out[name] = await evalJson(cmd, expr);
    }
    process.stdout.write(JSON.stringify(out) + '\n');
  } catch (e) {
    process.stderr.write('DRIVER ERROR: ' + (e && e.stack || e) + '\n' + (stderr ? 'chrome stderr tail:\n' + stderr.slice(-800) + '\n' : ''));
    process.exitCode = 1;
  } finally {
    try { client && client.close(); } catch (_) {}
    try { proc.kill('SIGKILL'); } catch (_) {}
  }
}

main();
