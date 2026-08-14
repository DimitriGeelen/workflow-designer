#!/usr/bin/env node
// _t233-ghost-cards-cdp.mjs — do pending off-page refs appear in the Open-project
// browser, and are they distinguishable there from real maps?
//
// WHY THIS IS HERMETIC RATHER THAN SERVED. The obvious probe boots
// tools/gallery-serve.py and reads whatever /api/list happens to return. That
// makes the instrument's population the repo's incidental ghost count — one, at
// the time of writing, and zero the moment somebody claims it. A guard whose
// denominator can silently fall to zero passes loudest exactly when it has
// stopped measuring anything, which is the failure mode this project has now hit
// five times in a week (T-500 §9). So the payload is INJECTED: window.fetch is
// stubbed for /api/list only, and every leg below has a fixed, stated population.
//
// The served surface is verified separately and visually (PL-045 — a slice is not
// live until the SERVED surface is verify-live'd); that check is a screenshot a
// human can look at, recorded under the task's ## Visual Verification. This file
// is the mechanical half, and it deliberately does not duplicate it: a DOM
// assertion cannot see what a rendered card looks like, and a screenshot cannot
// assert that no /api/thumb request was issued.
//
// NEGATIVE CONTROL. Leg 6 renders the SAME modal in pick mode against the SAME
// injected payload and requires the ghosts to be absent. Without it, legs 1-5
// would pass identically if the ghost branch ignored pickMode entirely, and the
// defect that hides behind that — an off-page connector retargeted at a uuid with
// no live map — is worse than the omission this task set out to fix.
import { spawn } from 'node:child_process';
import { readFileSync, readdirSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve } from 'node:path';

const HERE = resolve(new URL('.', import.meta.url).pathname);
const ROOT = resolve(HERE, '..');
const EDITOR = process.env.T233_EDITOR || join(ROOT, 'src', 'aef-workflow-designer.html');

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright');
  const cands = [];
  if (existsSync(cache)) for (const d of readdirSync(cache))
    if (d.startsWith('chromium-')) cands.push(join(cache, d, 'chrome-linux64', 'chrome'));
  cands.sort().reverse();
  for (const c of cands) if (existsSync(c)) return c;
  throw new Error('No Chromium under ' + cache);
}
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function waitForPortFile(f, timeoutMs = 15000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (existsSync(f)) {
      const txt = readFileSync(f, 'utf8').split('\n');
      if (txt[0] && txt[0].trim()) return { port: parseInt(txt[0].trim(), 10) };
    }
    await sleep(100);
  }
  throw new Error('Chromium did not report a DevTools port');
}
function cdpClient(wsUrl) {
  const ws = new WebSocket(wsUrl);
  let id = 0; const pending = new Map();
  ws.addEventListener('message', ev => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  });
  const ready = new Promise((res, rej) => {
    ws.addEventListener('open', res);
    ws.addEventListener('error', () => rej(new Error('CDP websocket error')));
  });
  const cmd = (method, params = {}) => new Promise((res, rej) => {
    const mid = ++id;
    pending.set(mid, m => m.error ? rej(new Error(method + ': ' + JSON.stringify(m.error))) : res(m.result));
    ws.send(JSON.stringify({ id: mid, method, params }));
  });
  return { ready, cmd, close: () => ws.close() };
}
async function evalJson(cmd, expression) {
  const r = await cmd('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (r.exceptionDetails) throw new Error('page eval threw: ' + JSON.stringify(r.exceptionDetails).slice(0, 600));
  return r.result.value;
}

let failures = 0;
function leg(name, ok, detail) {
  console.log(`  [${ok ? 'PASS' : 'FAIL'}] ${name}${detail ? ' — ' + detail : ''}`);
  if (!ok) failures++;
}

// Injected /api/list payload. Two maps and three ghosts, so every leg's
// denominator is stated here and cannot drift with the corpus.
const PAYLOAD = {
  maps: [
    { id: 'alpha-map', title: 'Alpha map', latest: null, openTarget: { kind: 'rendered' } },
    { id: 'beta-map', title: 'Beta map', latest: { v: 3 }, openTarget: { kind: 'version' } },
  ],
  ghosts: [
    { uuid: '11111111-1111-4111-8111-111111111111', name: 'future-map', referenced_by: ['alpha-map'] },
    { uuid: '22222222-2222-4222-8222-222222222222', name: 'review-map', referenced_by: ['alpha-map', 'beta-map'] },
    { uuid: '33333333-3333-4333-8333-333333333333', name: '', referenced_by: [] },
  ],
};
const N_MAPS = PAYLOAD.maps.length, N_GHOSTS = PAYLOAD.ghosts.length;

// Stub /api/list, count /api/thumb requests, and neutralise everything the modal
// would otherwise reach the network for. Returns the installer expression.
const STUB = `(function(){
  window.__thumbRequests = [];
  const realFetch = window.fetch;
  window.fetch = function(url, opts){
    const u = String(url);
    if (u.indexOf('/api/list') === 0 || u.indexOf('/api/list') > -1)
      return Promise.resolve(new Response(JSON.stringify(${JSON.stringify(PAYLOAD)}), {status:200, headers:{'Content-Type':'application/json'}}));
    if (u.indexOf('/api/thumb') > -1) { window.__thumbRequests.push(u); return Promise.resolve(new Response('', {status:404})); }
    return realFetch.apply(this, arguments);
  };
  // <img src="/api/thumb?..."> never goes through fetch(), so record the ASSIGNMENT.
  //
  // The first version of this leg counted surviving <img> elements in the modal and
  // read 0 where it expected 2 — a false FAIL. Under file:// every thumb URL fails,
  // img.onerror fires, and src:8882 replaces the <img> with the ▦ placeholder, so by
  // the time anything is counted the evidence has been swept up by the very fallback
  // T-149 added. Counting a residue measures whether the environment kept it, not
  // whether the request was made. Intercepting the setter measures the request.
  window.__imgSrcSets = [];
  const desc = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, 'src');
  Object.defineProperty(HTMLImageElement.prototype, 'src', {
    configurable: true,
    get() { return desc.get.call(this); },
    set(v) { window.__imgSrcSets.push(String(v)); desc.set.call(this, v); },
  });
  _apiAvailable = true;
  return true;
})()`;

async function main() {
  const chrome = findChrome();
  const udd = mkdtempSync(join(tmpdir(), 't233-leg-'));
  const proc = spawn(chrome, [
    '--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
    '--remote-debugging-port=0', `--user-data-dir=${udd}`, '--window-size=1600,1000', 'about:blank',
  ], { stdio: ['ignore', 'ignore', 'pipe'] });
  try {
    const { port } = await waitForPortFile(join(udd, 'DevToolsActivePort'));
    const targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
    const page = targets.find(t => t.type === 'page');
    if (!page) throw new Error('no page target');
    const client = cdpClient(page.webSocketDebuggerUrl);
    await client.ready;
    const { cmd } = client;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Emulation.setDeviceMetricsOverride', { width: 1600, height: 1000, deviceScaleFactor: 1, mobile: false });
    await cmd('Page.navigate', { url: 'file://' + EDITOR });
    const t0 = Date.now();
    for (;;) {
      const ok = await evalJson(cmd, `(typeof openProjectModal==='function' && typeof createFromPendingRef==='function')`);
      if (ok) break;
      if (Date.now() - t0 > 20000) throw new Error('editor load timeout');
      await sleep(150);
    }
    await evalJson(cmd, STUB);
    await evalJson(cmd, `(window.alert=window.confirm=window.prompt=function(){return true;},true)`);

    // ── Default (manage) mode ────────────────────────────────────────────────
    await evalJson(cmd, `(closeProjectModal(), openProjectModal())`);
    await sleep(400);

    const seen = await evalJson(cmd, `(function(){
      const body = document.querySelector('#project-modal > div > div:nth-child(2)');
      const ghostCards = Array.from(document.querySelectorAll('#project-modal [data-ghost]'));
      const kids = body ? Array.from(body.children) : [];
      const firstGhostIndex = kids.findIndex(k => k.hasAttribute && k.hasAttribute('data-ghost'));
      const lastMapIndex = kids.reduce((acc, k, i) => (k.hasAttribute && k.hasAttribute('data-ghost')) ? acc : i, -1);
      return {
        ghostCount: ghostCards.length,
        totalCards: kids.length,
        emptyState: !!(body && /No project maps found/.test(body.textContent)),
        firstGhostIndex, lastMapIndex,
        styles: ghostCards.map(c => {
          const cs = getComputedStyle(c);
          return { borderStyle: cs.borderTopStyle, hasImg: !!c.querySelector('img'),
                   glyph: (c.textContent.match(/◌/g) || []).length,
                   badge: /pending ref/.test(c.textContent),
                   refs: /referenced by \\d+/.test(c.textContent),
                   hasDelete: !!(c.parentElement && c.parentElement.querySelector && c.parentElement !== body && c.parentElement.querySelector('button[title^="Delete"]')) };
        }),
        thumbFetches: window.__thumbRequests.length,
        imgSrcSets: window.__imgSrcSets.slice(),
        ghostUuids: ghostCards.map(c => c.getAttribute('data-ghost')),
        labels: ghostCards.map(c => c.textContent.slice(0, 24)),
      };
    })()`);

    leg(`ghost cards rendered (${N_GHOSTS} injected)`,
      seen.ghostCount === N_GHOSTS, `saw ${seen.ghostCount}, total cards ${seen.totalCards}`);

    leg('empty state suppressed when maps exist',
      seen.emptyState === false, seen.emptyState ? 'still says "No project maps found"' : '');

    leg('ghosts render AFTER the map cards',
      seen.firstGhostIndex > seen.lastMapIndex && seen.firstGhostIndex === N_MAPS,
      `first ghost at ${seen.firstGhostIndex}, last map at ${seen.lastMapIndex}`);

    // POPULATION GUARD on every leg below that is phrased as "…on every ghost card".
    // The negative control (T233_EDITOR pointed at the pre-change source) initially
    // reported these three as PASS while rendering zero ghosts: `every()` over an empty
    // array is true, and "no ghost requested a thumbnail" is trivially satisfied when
    // there are no ghosts. Three green legs, nothing measured. Asserting the denominator
    // inside each leg is what makes a green line mean the thing it says.
    const pop = seen.styles.length === N_GHOSTS;

    const distinct = pop && seen.styles.every(s => s.borderStyle === 'dashed' && !s.hasImg && s.glyph >= 2 && s.badge && s.refs);
    leg('four independent distinction signals on every ghost card',
      distinct, pop ? (distinct ? 'dashed + ◌ tile + ◌ badge + referenced-by, no <img>' : JSON.stringify(seen.styles))
        : `population ${seen.styles.length}, expected ${N_GHOSTS} — nothing measured`);

    const thumbUrls = seen.imgSrcSets.filter(s => s.indexOf('/api/thumb') > -1);
    const ghostThumb = thumbUrls.filter(u => seen.ghostUuids.some(id => id && u.indexOf(id) > -1));
    leg('no /api/thumb request attributable to a ghost',
      pop && thumbUrls.length === N_MAPS && ghostThumb.length === 0 && seen.thumbFetches === 0,
      `${seen.ghostUuids.length}/${N_GHOSTS} ghosts present; ${thumbUrls.length} thumb URLs requested `
      + `(expected ${N_MAPS}, one per MAP), ${ghostThumb.length} carrying a ghost uuid, ${seen.thumbFetches} thumb fetch()`);

    leg('no 🗑 delete affordance on a ghost',
      pop && seen.styles.every(s => !s.hasDelete),
      pop ? '' : `population ${seen.styles.length}, expected ${N_GHOSTS} — nothing measured`);

    // ── Filter ───────────────────────────────────────────────────────────────
    const filtered = await evalJson(cmd, `(function(){
      const f = document.querySelector('#project-modal input[type=search]');
      f.value = 'review'; f.oninput();
      const vis = Array.from(document.querySelectorAll('#project-modal [data-ghost]'))
        .filter(c => c.style.display !== 'none').length;
      f.value = ''; f.oninput();
      const back = Array.from(document.querySelectorAll('#project-modal [data-ghost]'))
        .filter(c => c.style.display !== 'none').length;
      return { vis, back };
    })()`);
    leg('ghost cards participate in the filter',
      filtered.vis === 1 && filtered.back === N_GHOSTS,
      `"review" → ${filtered.vis} of ${N_GHOSTS}, cleared → ${filtered.back}`);

    // ── Claim path is T-228's, called not reimplemented ──────────────────────
    const claim = await evalJson(cmd, `(function(){
      const calls = [];
      const real = window.createFromPendingRef;
      window.createFromPendingRef = function(g){ calls.push(g && g.uuid); return true; };
      const card = document.querySelector('#project-modal [data-ghost]');
      // No card is a FAIL, not a crash: the negative control has no ghosts to click,
      // and an instrument that dies mid-suite reports nothing about the legs after it.
      if (!card) { window.createFromPendingRef = real; return { calls, uuid: null, modalGone: false, absent: true }; }
      const uuid = card.getAttribute('data-ghost');
      card.click();
      window.createFromPendingRef = real;
      return { calls, uuid, modalGone: !document.getElementById('project-modal') };
    })()`);
    leg('click calls createFromPendingRef with that ghost and closes the modal',
      !claim.absent && claim.calls.length === 1 && claim.calls[0] === claim.uuid && claim.modalGone,
      claim.absent ? 'no ghost card to click — nothing measured'
        : `calls=${JSON.stringify(claim.calls)} modalGone=${claim.modalGone}`);

    // ── Leg: pick mode must NOT offer ghosts (negative control) ──────────────
    await evalJson(cmd, `(closeProjectModal(), openProjectModal({ pick: function(){} }))`);
    await sleep(400);
    // Cards, not <img>: the thumbnails have already been replaced by ▦ placeholders
    // (see the setter note above), so an image count here would read 0 for both kinds.
    const pick = await evalJson(cmd, `(function(){
      const body = document.querySelector('#project-modal > div > div:nth-child(2)');
      return {
        ghosts: document.querySelectorAll('#project-modal [data-ghost]').length,
        cards: body ? body.children.length : -1,
        title: (document.querySelector('#project-modal strong') || {}).textContent || '',
      };
    })()`);
    leg('pick mode offers maps and NO ghosts',
      pick.ghosts === 0 && pick.cards === N_MAPS,
      `${pick.ghosts} ghosts / ${pick.cards} cards in "${pick.title}"`);

    // ── Leg: ghosts alone are not an empty project ───────────────────────────
    await evalJson(cmd, `(function(){
      const only = { maps: [], ghosts: ${JSON.stringify(PAYLOAD.ghosts)} };
      const realFetch = window.fetch;
      window.fetch = function(u){
        if (String(u).indexOf('/api/list') > -1)
          return Promise.resolve(new Response(JSON.stringify(only), {status:200, headers:{'Content-Type':'application/json'}}));
        return realFetch.apply(this, arguments);
      };
      return true;
    })()`);
    await evalJson(cmd, `(closeProjectModal(), openProjectModal())`);
    await sleep(400);
    const ghostsOnly = await evalJson(cmd, `(function(){
      const body = document.querySelector('#project-modal > div > div:nth-child(2)');
      return { ghosts: document.querySelectorAll('#project-modal [data-ghost]').length,
               empty: /No project maps found/.test(body ? body.textContent : '') };
    })()`);
    leg('a project of nothing but pending refs is not reported empty',
      ghostsOnly.ghosts === N_GHOSTS && ghostsOnly.empty === false,
      `${ghostsOnly.ghosts} ghosts, emptyState=${ghostsOnly.empty}`);

    client.close();
  } finally {
    proc.kill('SIGKILL');
  }
  console.log(failures === 0 ? '\nT-233 ghost cards: all legs PASS' : `\nT-233 ghost cards: ${failures} leg(s) FAILED`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch(e => { console.error('probe error:', e.message); process.exit(2); });
