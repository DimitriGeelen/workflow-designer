// T-604 — the CDP page-target attach race, and the sweep that keeps it fixed.
//
// OBS-313 was OBS-304 resurfacing. OBS-304 named this race and was fixed at FOUR call
// sites; seventy-three others kept the defect, and _t366 even documents it in prose as a
// "remaining unguarded race". A fix applied at the call site instead of the definition
// site gets re-found as a new bug. So L1 is a SCAN, not a memory: a driver added tomorrow
// that hand-rolls the deref turns this red.
//
// The legs assert OUTCOMES — did the attach succeed, did the driver get to run — never
// what the helper believes about itself.
//
// Usage:  node tools/_t604-cdp-attach-race.mjs [--self-test] [--soak N]
import { createServer } from 'node:http';
import { spawn } from 'node:child_process';
import { readFileSync, writeFileSync, readdirSync, existsSync, mkdtempSync, mkdirSync, copyFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pageWsUrl, ATTACH_FAIL } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const HELPER = join(HERE, '_cdp-attach.mjs');
const sleep = ms => new Promise(r => setTimeout(r, ms));

// ── a /json that withholds the page target for the first `withhold` polls ──────────
function stubDevTools(withhold, { neverReady = false } = {}) {
  let polls = 0;
  const srv = createServer((req, res) => {
    polls++;
    res.setHeader('content-type', 'application/json');
    const ready = !neverReady && polls > withhold;
    // Before registration Chromium answers with a valid list that has no page in it.
    res.end(JSON.stringify(ready
      ? [{ type: 'page', webSocketDebuggerUrl: 'ws://127.0.0.1:0/devtools/page/T604' }]
      : [{ type: 'browser', webSocketDebuggerUrl: 'ws://127.0.0.1:0/devtools/browser/B' }]));
  });
  return new Promise(res => srv.listen(0, '127.0.0.1', () => res({
    port: srv.address().port, close: () => srv.close(), polls: () => polls,
  })));
}

// ── L1: nobody hand-rolls the deref ───────────────────────────────────────────────
// Two files are not drivers and are excluded by name: the shared helper (which owns the
// deref) and this verifier (whose job is to CONTAIN the pre-fix shape, in its poison arms).
// Nothing else is exempt — the exemption is a fixed list, not a pattern, so a new driver
// cannot quietly join it.
const NOT_DRIVERS = new Set(['_cdp-attach.mjs', '_t604-cdp-attach-race.mjs']);
function scanDrivers(dir) {
  const offenders = [];
  for (const f of readdirSync(dir)) {
    if (!f.endsWith('.mjs') || NOT_DRIVERS.has(f)) continue;
    const src = readFileSync(join(dir, f), 'utf8');
    // strip comments so documented-but-unfixed prose (see _t366) is not counted as code
    const code = src.replace(/\/\*[\s\S]*?\*\//g, '').split('\n')
      .filter(l => !l.trim().startsWith('//')).join('\n');
    if (/find\(\s*t\s*=>\s*t\.type\s*===\s*'page'\s*\)/.test(code)) offenders.push(f);
  }
  return offenders;
}

function findChrome() {
  const cache = join(homedir(), '.cache', 'ms-playwright');
  if (existsSync(cache)) for (const d of readdirSync(cache)) {
    if (!d.startsWith('chromium-')) continue;
    const c = join(cache, d, 'chrome-linux64', 'chrome');
    if (existsSync(c)) return c;
  }
  throw new Error('No Chromium under ' + cache);
}

// ── L5: the real subject. Spawn Chromium as the drivers do and attach immediately. ──
async function realAttach(rounds) {
  const chrome = findChrome();
  let ok = 0; const fails = [];
  for (let i = 0; i < rounds; i++) {
    const udd = mkdtempSync(join(tmpdir(), 't604-real-'));
    const proc = spawn(chrome, ['--headless=new', '--no-sandbox', '--disable-gpu',
      '--disable-dev-shm-usage', '--remote-debugging-port=0', '--user-data-dir=' + udd, 'about:blank'],
      { stdio: ['ignore', 'ignore', 'ignore'] });
    try {
      let port;
      // 5ms granularity, not the drivers' 100ms: this deliberately catches the browser
      // at the earliest possible instant, which is what makes the race reachable at all.
      for (let k = 0; k < 6000; k++) {
        const f = join(udd, 'DevToolsActivePort');
        if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n')[0]; if (t.trim()) { port = +t.trim(); break; } }
        await sleep(5);
      }
      if (!port) { fails.push('round ' + i + ': no DevToolsActivePort'); continue; }
      const url = await pageWsUrl(port, { budgetMs: 15000, stepMs: 25 });
      if (/^ws:\/\//.test(url)) ok++; else fails.push('round ' + i + ': odd url ' + url);
    } catch (e) { fails.push('round ' + i + ': ' + (e && e.message || e)); }
    finally { try { proc.kill('SIGKILL'); } catch {} }
  }
  return { ok, rounds, fails };
}

async function legs({ scanDir, realRounds }) {
  const L = [];

  const offenders = scanDrivers(scanDir);
  L.push({ id: 'L1', ok: offenders.length === 0,
    detail: `drivers hand-rolling the page-target deref: ${offenders.length}` +
            (offenders.length ? ` [${offenders.join(', ')}]` : '') });

  // L2 — the outcome: an attach that races registration still lands.
  const s2 = await stubDevTools(4);
  let got = null, err2 = null;
  try { got = await pageWsUrl(s2.port, { budgetMs: 4000, stepMs: 20 }); } catch (e) { err2 = e.message; }
  s2.close();
  L.push({ id: 'L2', ok: got === 'ws://127.0.0.1:0/devtools/page/T604',
    detail: `attach through 4 page-less polls: ${got ? 'attached' : 'FAILED — ' + err2}` });

  // L3 — a genuine attach failure is NAMED, not a bare TypeError.
  const s3 = await stubDevTools(0, { neverReady: true });
  let msg3 = '';
  try { await pageWsUrl(s3.port, { budgetMs: 500, stepMs: 20 }); msg3 = '(did not throw)'; }
  catch (e) { msg3 = e.message; }
  s3.close();
  const named = msg3.startsWith(ATTACH_FAIL) && /BROWSER ATTACH failure/.test(msg3)
                && !/Cannot read properties/.test(msg3);
  L.push({ id: 'L3', ok: named,
    detail: `unattachable browser reports: ${JSON.stringify(msg3.slice(0, 96))}` });

  // L4 — CONTROL, independent of the race: with a page target present from poll 1 the
  // helper returns the advertised url. Stays green under a poison that removes retrying.
  const s4 = await stubDevTools(0);
  let got4 = null; try { got4 = await pageWsUrl(s4.port, { budgetMs: 1000, stepMs: 20 }); } catch (e) { got4 = 'ERR ' + e.message; }
  s4.close();
  L.push({ id: 'L4', ok: got4 === 'ws://127.0.0.1:0/devtools/page/T604',
    detail: `uncontested attach returns the advertised url: ${got4 === 'ws://127.0.0.1:0/devtools/page/T604'}` });

  // L5 — the faithful one: a real Chromium, caught as early as the OS allows.
  const r = await realAttach(realRounds);
  L.push({ id: 'L5', ok: r.ok === r.rounds,
    detail: `real Chromium attach ${r.ok}/${r.rounds}` + (r.fails.length ? ` — ${r.fails[0]}` : '') });

  return L;
}

async function main() {
  const selfTest = process.argv.includes('--self-test');
  const soakIdx = process.argv.indexOf('--soak');
  const report = ls => { for (const l of ls) console.log(`  ${l.ok ? 'PASS' : 'FAIL'}  ${l.id}  ${l.detail}`); };
  console.log('T-604 CDP page-target attach race — sweep and attach legs');

  if (soakIdx !== -1) {
    // Expensive determinism evidence: run a REAL driver self-test N times and prove the
    // verdict never varies on unchanged code. Not a gate leg — too slow — but the thing
    // OBS-313 actually claimed, measured rather than asserted.
    const n = +(process.argv[soakIdx + 1] || 6);
    const { execFileSync } = await import('node:child_process');
    const verdicts = new Map();
    for (let i = 0; i < n; i++) {
      let rc = 0, out = '';
      try { out = execFileSync('node', [join(HERE, '_t603-multiprocess-import.mjs'), '--self-test'],
        { encoding: 'utf8', timeout: 180000 }); } catch (e) { rc = e.status ?? 2; out = (e.stdout || '') + (e.stderr || ''); }
      const last = out.trim().split('\n').pop();
      const key = `rc=${rc} :: ${last}`;
      verdicts.set(key, (verdicts.get(key) || 0) + 1);
      console.log(`  run ${i + 1}/${n}  ${key}`);
    }
    console.log(`\ndistinct verdicts: ${verdicts.size}`);
    for (const [k, v] of verdicts) console.log(`  x${v}  ${k}`);
    const deterministic = verdicts.size === 1 && [...verdicts.keys()][0].startsWith('rc=0');
    console.log(deterministic ? `\nPASS — ${n} runs, one verdict` : `\nFAIL — verdict varied across ${n} runs on unchanged code`);
    process.exit(deterministic ? 0 : 1);
  }

  const rounds = selfTest ? 3 : 5;
  const live = await legs({ scanDir: HERE, realRounds: rounds });
  report(live);
  const failed = live.filter(l => !l.ok);
  if (!selfTest) {
    console.log(failed.length ? `FAIL — ${failed.length} leg(s)` : `PASS — ${live.length} leg(s)`);
    process.exit(failed.length ? 1 : 0);
  }
  if (failed.length) { console.log(`\nFAIL — ${failed.length} live leg(s)`); process.exit(1); }

  // ── poison arms ────────────────────────────────────────────────────────────────
  // FAITHFUL to pre-T-604. Two arms, because one arm cannot reach both defects: the
  // helper's retry and the call sites are different code. An arm that only restored the
  // helper would leave L1 asserting nothing, which is the exact vacuous-leg trap.
  const helperSrc = readFileSync(HELPER, 'utf8');
  const RETRY = "      const targets = await (await fetch('http://' + host + ':' + port + '/json')).json();";
  if (!helperSrc.includes(RETRY)) { console.log('SELF-TEST INTEGRITY FAIL — helper poison target missing'); process.exit(2); }

  // Arm A: the helper stops retrying — one read, one deref, exactly the pre-fix shape.
  const armA = helperSrc.replace(
    /export async function pageWsUrl[\s\S]*$/,
    `export async function pageWsUrl(port, opts = {}) {
  const host = opts.host ?? '127.0.0.1';
  const targets = await (await fetch('http://' + host + ':' + port + '/json')).json();
  return targets.find(t => t.type === 'page').webSocketDebuggerUrl;
}
`);
  if (armA === helperSrc) { console.log('SELF-TEST INTEGRITY FAIL — arm A rewrote nothing'); process.exit(2); }
  const dirA = mkdtempSync(join(tmpdir(), 't604-armA-'));
  writeFileSync(join(dirA, '_cdp-attach.mjs'), armA);
  writeFileSync(join(dirA, 'probe.mjs'),
    `import { pageWsUrl } from './_cdp-attach.mjs';\n` +
    `const port = +process.argv[2];\n` +
    `try { const u = await pageWsUrl(port, { budgetMs: 4000, stepMs: 20 }); console.log('OK ' + u); }\n` +
    `catch (e) { console.log('THREW ' + e.message); }\n`);

  console.log('\npoison arm A — helper reverted to a single unretried read; L2 and L3 must FAIL');
  // execFile, NOT execFileSync: the stub /json server lives in THIS process, so a
  // synchronous child would block the event loop that has to answer it — the arm would
  // deadlock rather than report, and a poison arm that hangs proves exactly as little as
  // one that never executed.
  const { execFile } = await import('node:child_process');
  const { promisify } = await import('node:util');
  const pExecFile = promisify(execFile);
  const runArm = async (withhold, opts) => {
    const s = await stubDevTools(withhold, opts);
    let out;
    try { out = (await pExecFile('node', [join(dirA, 'probe.mjs'), String(s.port)], { timeout: 30000 })).stdout.trim(); }
    finally { s.close(); }
    return out;
  };
  const a2 = await runArm(4);
  const a3 = await runArm(0, { neverReady: true });
  const a4 = await runArm(0);
  const armALegs = [
    { id: 'L2', ok: a2.startsWith('OK'), detail: `attach through 4 page-less polls: ${a2.slice(0, 70)}` },
    { id: 'L3', ok: a3.startsWith('THREW ' + ATTACH_FAIL), detail: `unattachable reports: ${a3.slice(0, 70)}` },
    { id: 'L4', ok: a4.startsWith('OK'), detail: `uncontested attach: ${a4.slice(0, 40)}` },
  ];
  report(armALegs);
  const aSurv = armALegs.filter(l => ['L2', 'L3'].includes(l.id) && l.ok).map(l => l.id);
  const aCtl = armALegs.filter(l => l.id === 'L4' && !l.ok).map(l => l.id);

  // Arm B: one driver hand-rolls the deref again — the pre-fix CALL SITE, which is the
  // defect that actually shipped 73 times. Poisons a COPY of the tree, never the tree.
  const dirB = mkdtempSync(join(tmpdir(), 't604-armB-'));
  mkdirSync(join(dirB, 'tools'));
  for (const f of readdirSync(HERE)) if (f.endsWith('.mjs')) copyFileSync(join(HERE, f), join(dirB, 'tools', f));
  const victim = join(dirB, 'tools', '_t603-multiprocess-import.mjs');
  const vsrc = readFileSync(victim, 'utf8');
  const CALL = 'cdpClient(await pageWsUrl(port))';
  if (!vsrc.includes(CALL)) { console.log(`SELF-TEST INTEGRITY FAIL — arm B target missing in victim`); process.exit(2); }
  writeFileSync(victim, vsrc.replace(CALL, "cdpClient(targets.find(t => t.type === 'page').webSocketDebuggerUrl)"));
  const offB = scanDrivers(join(dirB, 'tools'));
  console.log('\npoison arm B — one driver hand-rolls the deref again; L1 must FAIL');
  const armBLegs = [
    { id: 'L1', ok: offB.length === 0, detail: `drivers hand-rolling the deref: ${offB.length} [${offB.join(', ')}]` },
  ];
  report(armBLegs);
  const bSurv = armBLegs.filter(l => l.ok).map(l => l.id);

  if (aSurv.length) { console.log(`\nSELF-TEST FAIL — ${aSurv.join(',')} passed with the retry removed; they assert nothing`); process.exit(2); }
  if (aCtl.length) { console.log(`\nSELF-TEST FAIL — control leg ${aCtl.join(',')} broke under arm A; not independent`); process.exit(2); }
  if (bSurv.length) { console.log(`\nSELF-TEST FAIL — L1 passed with a hand-rolled deref present; the scan asserts nothing`); process.exit(2); }
  console.log(`\nPASS — ${live.length} live leg(s); 3 proven failable across 2 arms`);
}

main().catch(e => { console.error('DRIVER ERROR: ' + (e && e.stack || e)); process.exit(2); });
