#!/usr/bin/env node
// T-1257 — the shared profile helper removes the temp dir Chrome makes for each launch, and nothing else.
//
// Chrome makes <TMPDIR>/org.chromium.Chromium.XXXXXX per launch (its SingletonSocket and SingletonCookie) and leaves it
// on SIGKILL and SIGTERM; the profile's SingletonSocket is a symlink into it. tools/_cdp-profile.mjs follows that link.
//   A        makeProfileDir + Chrome + removeProfileDir -> no org.chromium.Chromium.* left in TMPDIR, profile gone
//   control  the same Chrome, profile removed the old way (rmSync only) -> the org.chromium dir IS left (the defect)
//   C        a SingletonSocket link into a dir NOT named org.chromium.Chromium.* is not followed (chromeTempOf: null),
//            and removeProfileDir leaves that dir alone
// Runs in its own short TMPDIR (Chrome's socket path must stay under ~107 bytes), removed at the end.
import { spawn } from 'node:child_process';
import { mkdtempSync, mkdirSync, existsSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { makeProfileDir, removeProfileDir, chromeTempOf } from './_cdp-profile.mjs';

const T = mkdtempSync('/tmp/t1257s-');
process.env.TMPDIR = T;   // before the helper creates anything: os.tmpdir() reads it per call, Chrome inherits it

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
const chromeDirs = () => readdirSync(T).filter(n => n.startsWith('org.chromium.Chromium.'));
async function launch(udd) {
  const p = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  for (const t0 = Date.now(); Date.now() - t0 < 30000; await sleep(100)) {
    try { if (readFileSync(join(udd, 'DevToolsActivePort'), 'utf8').trim()) return p; } catch {}
  }
  p.kill('SIGKILL'); throw new Error('Chrome did not start (no DevToolsActivePort)');
}
const results = [];
const leg = (ok, name, what) => { results.push(ok); console.log(`${ok ? 'ok  ' : 'FAIL'}  ${name.padEnd(8)} ${what}`); };

// T-1407 pool-only exception: in ring20's pool sandbox this Chrome keeps no process singleton (no SingletonSocket,
// so no org.chromium.Chromium.* dir is ever made; measured on pool-w2, 2026-11-13). There the defect cannot occur and A
// and the control are not applicable; they say so instead of failing. Only under T1406_POOL=1 AND only when the launch
// demonstrably made no such dir — a local run where the dir is missing stays a FAIL.
let notApplicable = false;
try {
  // A
  {
    const udd = makeProfileDir('t1257a-');
    const p = await launch(udd);
    const linked = chromeTempOf(udd);
    const madeAny = chromeDirs().length > 0;
    if (!linked && !madeAny && process.env.T1406_POOL === '1') {
      notApplicable = true;
      console.log('n/a   A        this Chrome made no per-launch org.chromium.Chromium dir and no SingletonSocket (pool sandbox): nothing to leave behind');
      results.push(true);
    }
    removeProfileDir(udd);
    await sleep(500);
    if (!notApplicable)
      leg(!!linked && chromeDirs().length === 0 && !existsSync(udd), 'A', `the launch's dir ${linked ? linked.split('/').pop() : '(link not found)'}; left after removeProfileDir: ${chromeDirs().length}, profile gone ${!existsSync(udd)}`);
    try { p.kill('SIGKILL'); } catch {}
  }
  // control: the same helper profile, removed the way it was before T-1404 (the profile alone, no link followed)
  if (notApplicable) {
    console.log('n/a   control  the defect cannot occur where Chrome makes no such dir (pool sandbox)');
    results.push(true);
  } else {
    const prof = makeProfileDir('t1257c-');
    const p = await launch(prof);
    p.kill('SIGKILL'); await sleep(500);
    rmSync(prof, { recursive: true, force: true });   // the old removal: the link goes with the profile, unread
    removeProfileDir(prof);                            // the helper now finds no link, so Chrome's dir stays
    const left = chromeDirs();
    const ok = left.length === 1;
    results.push(ok);
    console.log(ok ? `ok    control  the old removal (rmSync only) leaves ${left[0]} (the defect, reproduced)`
                   : `FAIL  control  the old removal left ${left.length} org.chromium dir(s); the test no longer reproduces the defect`);
    for (const n of left) rmSync(join(T, n), { recursive: true, force: true });
  }
  // C
  {
    const other = join(T, 'not-chrome-dir'); mkdirSync(other); writeFileSync(join(other, 'keep'), 'x');
    const udd = makeProfileDir('t1257x-');
    symlinkSync(join(other, 'SingletonSocket'), join(udd, 'SingletonSocket'));
    const got = chromeTempOf(udd);
    removeProfileDir(udd);
    leg(got === null && existsSync(join(other, 'keep')), 'C', `a link into a dir not named org.chromium.Chromium.*: chromeTempOf ${got}, that dir kept ${existsSync(join(other, 'keep'))}`);
  }
} catch (e) {
  results.push(false); console.log('FAIL  setup    ' + (e && e.message || e));
} finally {
  rmSync(T, { recursive: true, force: true });
}
const all = results.length === 3 && results.every(Boolean);
console.log(all ? 'PASS  T-1257: each launch\'s org.chromium.Chromium dir is removed with its profile, and nothing else is'
                : 'FAIL  T-1257');
process.exit(all ? 0 : 1);
