#!/usr/bin/env bash
# T-1482: tools/pool/round.sh runs the browser gate and the core push gate together (stub gates here).
#   R1 both green -> exit 0, both run at the same time (the round takes about the longer, not the sum)
#   R2 browser red -> exit 1 at once; the slow core gate is STOPPED (its process group: the child it started never
#      finishes) and the round says so
#   R3 core red -> exit 1; the slow browser gate is stopped the same way
# Control: T1482_ROUND=<a round that waits for both and stops nothing> fails R2 and R3 (the slow gate's marker appears).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROUND=${T1482_ROUND:-$ROOT/tools/pool/round.sh}
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
fails=0
ok() { echo "PASS  $1"; }
bad() { echo "FAIL  $1"; fails=1; }
run() {  # run <browser cmd> <core cmd> -> sets rc, out, secs
    local s; s=$(date +%s)
    out=$(cd "$ROOT" && T1482_BROWSER_CMD="$1" T1482_CORE_CMD="$2" bash "$ROUND" 2>&1); rc=$?
    secs=$(( $(date +%s) - s ))
}
run "bash -c 'sleep 3; exit 0'" "bash -c 'sleep 3; exit 0'"
[ "$rc" = 0 ] && [ "$secs" -lt 6 ] && grep -q 'browser green' <<<"$out" && grep -q 'core    green' <<<"$out" \
  && ok "R1 both green: exit 0 in ${secs}s (together, not 6 s in a row)" || bad "R1 rc=$rc ${secs}s: $out"
run "bash -c 'sleep 1; exit 1'" "bash -c 'sleep 4; touch $W/core-finished; sleep 20'"
sleep 5
[ "$rc" = 1 ] && [ "$secs" -lt 8 ] && [ ! -e "$W/core-finished" ] && grep -q 'core    STOPPED' <<<"$out" && grep -q 'browser RED' <<<"$out" \
  && ok "R2 browser red: exit 1 in ${secs}s, core stopped before it finished" || bad "R2 rc=$rc ${secs}s marker=$([ -e "$W/core-finished" ] && echo yes || echo no): $out"
run "bash -c 'sleep 4; touch $W/browser-finished; sleep 20'" "bash -c 'sleep 1; exit 1'"
sleep 5
[ "$rc" = 1 ] && [ "$secs" -lt 8 ] && [ ! -e "$W/browser-finished" ] && grep -q 'browser STOPPED' <<<"$out" && grep -q 'core    RED' <<<"$out" \
  && ok "R3 core red: exit 1 in ${secs}s, browser stopped before it finished" || bad "R3 rc=$rc ${secs}s marker=$([ -e "$W/browser-finished" ] && echo yes || echo no): $out"
[ "$fails" = 0 ] && echo "T-1482 round: GREEN" || echo "T-1482 round: RED"
exit "$fails"
