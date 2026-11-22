#!/usr/bin/env bash
# T-1481: the tier engine reads T1288_SHARD / T1288_SHARD_PLAN / T1288_LEGLOG once and does not export them to the legs
# it runs, so a leg that runs the suite or a gate inside itself starts unsharded (core at k=3, 2026-11-22: 13 legs red).
#   E1 after sourcing tools/_t1288-tiers.sh with the three set, the shell still has them (the engine uses them)
#   E2 a child process sees none of them
# Control: T1481_TIERS=<the tier engine before T-1481> fails E2.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIERS=${T1481_TIERS:-$ROOT/tools/_t1288-tiers.sh}
plan=$(mktemp); trap 'rm -f "$plan"' EXIT
out=$(cd "$ROOT" && T1288_SHARD=1/2 T1288_SHARD_PLAN="$plan" T1288_LEGLOG=/dev/null bash -c '
    T1288_TIERS="core browser"; source "'"$TIERS"'" >/dev/null 2>&1
    echo "shell=${T1288_SHARD:-},${T1288_SHARD_PLAN:+set},${T1288_LEGLOG:-}"
    bash -c "echo child=\${T1288_SHARD:-},\${T1288_SHARD_PLAN:-},\${T1288_LEGLOG:-}"')
fails=0
grep -qx 'shell=1/2,set,/dev/null' <<<"$out" && echo "PASS  E1 the engine keeps its shard variables" || { echo "FAIL  E1: $out"; fails=1; }
grep -qx 'child=,,' <<<"$out" && echo "PASS  E2 a leg's child process sees none of them" || { echo "FAIL  E2: $out"; fails=1; }
[ "$fails" = 0 ] && echo "T-1481 shard env: GREEN" || echo "T-1481 shard env: RED"
exit "$fails"
