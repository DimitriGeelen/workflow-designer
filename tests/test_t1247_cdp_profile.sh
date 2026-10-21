#!/usr/bin/env bash
# T-1247: tools/_cdp-profile.mjs removes the Chrome profile dir on SIGTERM (and kills the process using it), leaves a
# SIGKILLed owner's dir for the next makeProfileDir of the same prefix to sweep, and never removes a live owner's dir or
# a dir with no owner file. Bite control: T1247_NO_CLEANUP=1 makes the SIGTERM leg red.
# Everything runs inside a private TMPDIR with a unique prefix; the host's /tmp is never touched.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"
trap 'pkill -f -- "--user-data-dir=$T" 2>/dev/null; rm -rf "$T"' EXIT
export TMPDIR="$T"
P="t1247test-"
fail=0
ok()  { echo "ok   $*"; }
bad() { echo "FAIL $*"; fail=1; }

cat > "$T/child.mjs" <<JS
import { makeProfileDir, registerChrome } from '$ROOT/tools/_cdp-profile.mjs';
import { spawn } from 'node:child_process';
const dir = makeProfileDir('$P');
if (process.argv[2] === 'register') registerChrome(dir, spawn('sleep', ['300']));
else spawn('sh', ['-c', 'sleep 300', '--user-data-dir=' + dir], { stdio: 'ignore' });
console.log('READY ' + dir);
setInterval(() => {}, 1000);
JS

# start a child, wait for READY, set DIR and CPID
start() {
  : > "$T/out"; node "$T/child.mjs" "${1:-}" > "$T/out" 2>&1 & CPID=$!
  for _ in $(seq 1 100); do command grep -q READY "$T/out" && break; sleep 0.1; done
  DIR="$(sed -n 's/^READY //p' "$T/out")"
  [ -n "$DIR" ] && [ -f "$DIR/.t1247-owner-pid" ] || { bad "child did not create an owned dir"; return 1; }
}
users() { pgrep -f -- "--user-data-dir=$1" | wc -l; }

# 1. SIGTERM: dir gone, process using it gone, exit 143
start || exit 1
[ "$(users "$DIR")" -ge 1 ] || bad "no process was using the dir before the signal (test setup)"
kill -TERM "$CPID"; wait "$CPID"; rc=$?
[ ! -e "$DIR" ] && ok "SIGTERM removed the dir" || bad "SIGTERM left $DIR"
[ "$rc" -eq 143 ] && ok "exit code 128+15" || bad "exit code $rc, want 143"
[ "$(users "$DIR")" -eq 0 ] && ok "process using the dir was killed" || bad "process using the dir survived"

# 2. registerChrome path: the registered child dies too
start register || exit 1
kill -INT "$CPID"; wait "$CPID"; rc=$?
[ ! -e "$DIR" ] && [ "$rc" -eq 130 ] && ok "SIGINT with registered child: dir removed, exit 130" || bad "SIGINT leg (rc=$rc, dir exists: $([ -e "$DIR" ] && echo yes || echo no))"

# 3. SIGKILL: dir stays with a dead owner; a live owner's dir and an ownerless dir are never swept; next make sweeps
start || exit 1
DEAD="$DIR"; kill -KILL "$CPID"; wait "$CPID" 2>/dev/null
pkill -f -- "--user-data-dir=$DEAD" 2>/dev/null
[ -d "$DEAD" ] && ok "SIGKILL left the dir (as expected)" || bad "SIGKILL leg: dir missing before sweep"
mkdir "$T/${P}ownerl"                       # prefix + 6 chars, no owner file
start || exit 1; LIVE="$DIR"; LPID="$CPID"  # second child's makeProfileDir sweeps $DEAD
[ ! -e "$DEAD" ] && ok "next makeProfileDir swept the dead owner's dir" || bad "dead owner's dir survived the sweep"
[ -d "$LIVE" ] && ok "live owner's dir kept" || bad "live owner's dir removed"
[ -d "$T/${P}ownerl" ] && ok "dir with no owner file kept" || bad "dir with no owner file was removed"
start || exit 1                             # third child sweeps again while LIVE's owner is alive
[ -d "$LIVE" ] && ok "live owner's dir survives a later sweep" || bad "live owner's dir removed by a later sweep"
kill -TERM "$CPID" "$LPID"; wait "$CPID" "$LPID" 2>/dev/null

# 4. bite control: with cleanup disabled the SIGTERM leg must leave the dir behind
export T1247_NO_CLEANUP=1
start || exit 1
kill -TERM "$CPID"; wait "$CPID" 2>/dev/null
if [ -d "$DIR" ]; then ok "bite control: with cleanup disabled the dir is left (leg 1 would be red)"; else bad "bite control did not bite"; fi
pkill -f -- "--user-data-dir=$DIR" 2>/dev/null
unset T1247_NO_CLEANUP

[ "$fail" -eq 0 ] && echo "T-1247 cdp profile: all legs pass" || echo "T-1247 cdp profile: FAILED"
exit "$fail"
