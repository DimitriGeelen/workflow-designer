// T-1247 — one definition of "make a Chrome --user-data-dir and always remove it", shared by every CDP driver.
//
// WHY THIS EXISTS. ~120 drivers made their profile with mkdtempSync(join(tmpdir(), '<prefix>-')) and removed it in a
// `finally` block. A `finally` never runs when node is killed by a signal, and _node-cuts-cdp.mjs never removed it at
// all: one load run left 548 /tmp/nodecuts-chrome-* dirs (1.9 GB).
//
// WHAT IT DOES. makeProfileDir(prefix) creates the dir, writes the owner pid into it (OWNER_FILE), and removes it on
// process 'exit', on an uncaught error, and on SIGINT/SIGTERM/SIGHUP (Chrome processes that use the dir are killed
// first, found by their --user-data-dir argument, so no registration is needed; registerChrome() is optional). It also
// sweeps os.tmpdir() for dirs with the same prefix whose owner pid is dead, which covers SIGKILL. A dir with no owner
// file, or whose owner is alive, is never touched. Removal is idempotent, so an existing `finally` cleanup still works.
//
// T-1257: Chrome also makes one dir of its own per launch, <TMPDIR>/org.chromium.Chromium.XXXXXX, holding its
// SingletonSocket and SingletonCookie, and leaves it behind on SIGKILL and SIGTERM alike (measured 2026-11-12: one per
// launch; 2,087 such empty dirs in /tmp). The profile's own SingletonSocket is a symlink INTO that dir, so it is found
// from the profile, not guessed from a shared /tmp: removeChromeTemp() follows the link and removes that dir (only a
// dir named org.chromium.Chromium.*), before the profile goes.
import { mkdtempSync, writeFileSync, readFileSync, readdirSync, rmSync, existsSync, readlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname, basename } from 'node:path';

export const OWNER_FILE = '.t1247-owner-pid';

const dirs = new Set();
const procs = new Map();   // dir -> child process registered by registerChrome
let hooked = false;

const alive = pid => {
  if (!Number.isInteger(pid) || pid <= 0) return false;
  try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
};

function killUsers(dir) {
  const p = procs.get(dir);
  if (p && p.pid) { try { process.kill(p.pid, 'SIGKILL'); } catch {} }
  let pids = [];
  try { pids = readdirSync('/proc').filter(n => /^\d+$/.test(n)); } catch { return; }
  for (const n of pids) {
    if (+n === process.pid) continue;
    try {
      if (readFileSync('/proc/' + n + '/cmdline', 'utf8').includes('--user-data-dir=' + dir)) process.kill(+n, 'SIGKILL');
    } catch {}
  }
}

/** T-1257: the dir Chrome made for this profile's singleton files, found by the profile's SingletonSocket link. */
export function chromeTempOf(dir) {
  try {
    const target = readlinkSync(join(dir, 'SingletonSocket'));
    const d = dirname(target);
    return basename(d).startsWith('org.chromium.Chromium.') ? d : null;
  } catch { return null; }
}

function removeChromeTemp(dir) {
  const d = chromeTempOf(dir);
  if (d) { try { rmSync(d, { recursive: true, force: true }); } catch {} }
}

export function removeProfileDir(dir) {
  if (!dir) return;
  if (!process.env.T1247_NO_CLEANUP) {
    killUsers(dir);
    removeChromeTemp(dir);   // T-1257: read the link before the profile (and the link) is gone
    try { rmSync(dir, { recursive: true, force: true, maxRetries: 3, retryDelay: 50 }); } catch {}
  }
  dirs.delete(dir);
  procs.delete(dir);
}

function removeAll() { for (const d of [...dirs]) removeProfileDir(d); }

function hook() {
  if (hooked) return;
  hooked = true;
  process.on('exit', removeAll);
  for (const [sig, n] of [['SIGINT', 2], ['SIGTERM', 15], ['SIGHUP', 1]]) {
    process.on(sig, () => { removeAll(); process.exit(128 + n); });
  }
  process.on('uncaughtException', e => {
    removeAll();
    console.error(e && e.stack || e);
    process.exit(1);
  });
}

function sweep(prefix) {
  if (process.env.T1247_NO_CLEANUP) return;
  let names = [];
  try { names = readdirSync(tmpdir()); } catch { return; }
  for (const n of names) {
    if (!n.startsWith(prefix) || n.length !== prefix.length + 6) continue;
    const d = join(tmpdir(), n);
    if (dirs.has(d)) continue;
    let pid;
    try { pid = parseInt(readFileSync(join(d, OWNER_FILE), 'utf8'), 10); } catch { continue; }
    if (!Number.isInteger(pid) || alive(pid)) continue;
    killUsers(d);
    removeChromeTemp(d);   // T-1257
    try { rmSync(d, { recursive: true, force: true }); } catch {}
  }
}

/** Create a profile dir `<tmpdir>/<prefix>XXXXXX`, owned by this process, removed on every exit path we can catch. */
export function makeProfileDir(prefix) {
  sweep(prefix);
  const dir = mkdtempSync(join(tmpdir(), prefix));
  writeFileSync(join(dir, OWNER_FILE), String(process.pid));
  dirs.add(dir);
  hook();
  return dir;
}

/** Optional: name the Chrome child that uses `dir`, so it is killed before the dir is removed. */
export function registerChrome(dir, child) { procs.set(dir, child); }
