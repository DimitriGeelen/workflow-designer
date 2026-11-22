#!/usr/bin/env bash
# T-1481: while the tier engine runs a leg, its shard variables (T1288_SHARD / T1288_SHARD_PLAN / T1288_LEGLOG) are not
# exported to that leg, so a leg that runs the suite or a gate inside itself starts unsharded (core at k=3, 2026-11-22:
# 13 legs red); the engine itself keeps them, exported again after the leg (a first fix that un-exported them for good
# made every shard run every leg).
#   E1 a leg run through _t1288_run starts a child that sees none of the three
#   E2 after the leg, the shell still has them, exported (the next shard placement and any re-run see them)
# Control: T1481_TIERS=<the tier engine before T-1481> fails E1.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIERS=${T1481_TIERS:-$ROOT/tools/_t1288-tiers.sh}
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
out=$(cd "$ROOT" && TMP="$W" T1288_SHARD=1/2 T1288_SHARD_PLAN="$W/plan" T1288_LEGLOG="$W/legs.tsv" bash -c '
    : > "$T1288_SHARD_PLAN"
    T1288_TIERS="core browser"; source "'"$TIERS"'" >/dev/null 2>&1
    pass=0; fail=0; report() { :; }
    probe() { bash -c "echo child=\${T1288_SHARD:-},\${T1288_SHARD_PLAN:-},\${T1288_LEGLOG:-}"; pass=$((pass + 1)); }
    _t1288_run core t1481-probe first probe
    echo "after=$(declare -p T1288_SHARD 2>/dev/null | cut -d" " -f2),$(declare -p T1288_LEGLOG 2>/dev/null | cut -d" " -f2)"' 2>&1)
fails=0
grep -qx 'child=,,' <<<"$out" && echo "PASS  E1 a leg's child process sees none of the shard variables" || { echo "FAIL  E1: $(grep child= <<<"$out")"; fails=1; }
grep -qx 'after=-x,-x' <<<"$out" && echo "PASS  E2 after the leg the engine still exports them" || { echo "FAIL  E2: $(grep after= <<<"$out")"; fails=1; }
[ "$fails" = 0 ] && echo "T-1481 shard env: GREEN" || echo "T-1481 shard env: RED"
exit "$fails"
