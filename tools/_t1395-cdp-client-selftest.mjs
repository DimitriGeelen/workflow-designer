#!/usr/bin/env node
// T-1395 — proves the shared CDP client (tools/_cdp-client.mjs) cannot wait for ever, against a real Chrome.
//
//   A  Chrome is killed while an evaluate waits (a promise that never resolves) -> the command is rejected
//      with CDP CLOSED within 5 s.
//   B  a command sent after that is rejected at once (CDP CLOSED), not queued into a dead socket.
//   C  a live Chrome, a never-resolving awaitPromise evaluate, cmdMs 1500 -> CDP TIMEOUT.
//   control  the OLD inline client (the 133 copies T-1395 replaced) against the same kill: still waiting
//      after 5 s. If the control stops reproducing the defect, the test has lost its teeth and says so.
//
// Prints PASS / FAIL lines; exit 0 only when every arm and the control hold.
import { spawn } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { cdp, CLOSED, TIMEOUT } from './_cdp-client.mjs';
import { makeProfileDir } from './_cdp-profile.mjs';
import { pageWsUrl } from './_cdp-attach.mjs';

const sleep = ms => new Promise(r => setTimeout(r, ms));
function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 30000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
// The client T-1395 replaced, byte for byte (the control arm reproduces its defect).
function oldCdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }

async function chrome() {
  const udd = makeProfileDir('t1395-udd-');
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: 'ignore' });
  const ws = await pageWsUrl(await waitPortFile(join(udd, 'DevToolsActivePort')));
  return { br, ws };
}
const NEVER = { expression: 'new Promise(() => {})', awaitPromise: true, returnByValue: true };
// Settles to { state, ms, msg } or 'still-waiting' after `budget` ms.
async function outcome(p, budget) {
  const t0 = Date.now();
  return Promise.race([
    p.then(() => ({ state: 'resolved', ms: Date.now() - t0 }), e => ({ state: 'rejected', ms: Date.now() - t0, msg: String(e && e.message || e) })),
    sleep(budget).then(() => ({ state: 'still-waiting', ms: budget })),
  ]);
}

const results = [];
const leg = (ok, name, what) => { results.push(ok); console.log(`${ok ? 'ok  ' : 'FAIL'}  ${name.padEnd(10)} ${what}`); };

// A + B
{
  const { br, ws } = await chrome();
  const cl = cdp(ws); await cl.ready;
  const waiting = cl.cmd('Runtime.evaluate', NEVER);
  await sleep(300); br.kill('SIGKILL');
  const a = await outcome(waiting, 5000);
  leg(a.state === 'rejected' && a.msg.startsWith(CLOSED) && a.ms < 5000, 'A', `Chrome killed mid-command: ${a.state} after ${a.ms} ms${a.msg ? ' — ' + a.msg.slice(0, 120) : ''}`);
  const b = await outcome(cl.cmd('Runtime.evaluate', { expression: '1' }), 1000);
  leg(b.state === 'rejected' && b.msg.startsWith(CLOSED) && b.ms < 200, 'B', `command after the close: ${b.state} after ${b.ms} ms`);
}
// C
{
  const { br, ws } = await chrome();
  const cl = cdp(ws, { cmdMs: 1500 }); await cl.ready;
  const c = await outcome(cl.cmd('Runtime.evaluate', NEVER), 6000);
  leg(c.state === 'rejected' && c.msg.startsWith(TIMEOUT) && c.ms >= 1400 && c.ms < 4000, 'C', `no answer, cmdMs 1500: ${c.state} after ${c.ms} ms${c.msg ? ' — ' + c.msg.slice(0, 80) : ''}`);
  cl.close(); br.kill('SIGKILL');
}
// control
{
  const { br, ws } = await chrome();
  const cl = oldCdp(ws); await cl.ready;
  const waiting = cl.cmd('Runtime.evaluate', NEVER);
  await sleep(300); br.kill('SIGKILL');
  const o = await outcome(waiting, 5000);
  const ok = o.state === 'still-waiting';
  results.push(ok);
  console.log(ok ? 'ok    control: the old client still waiting 5 s after Chrome was killed (the defect, reproduced)'
                 : `FAIL  control: the old client ${o.state} — the test no longer reproduces the defect`);
}
console.log(results.every(Boolean) ? 'PASS  T-1395 shared CDP client: closed and silent waits both end, with a named error' : 'FAIL  T-1395');
process.exit(results.every(Boolean) ? 0 : 1);
