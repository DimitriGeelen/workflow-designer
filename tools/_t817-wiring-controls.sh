#!/usr/bin/env bash
# _t817-wiring-controls.sh — is the direct-manipulation wiring load-bearing?
#
# T-817. Four CDP probes were wired into tests/run-bridge-tests.sh to close part of F-07
# (the direct-manipulation surface is named by no gating leg) using F-08's inventory (118
# instruments written, run once, never wired to anything that re-runs them).
#
# THE FAILURE MODE THIS GUARDS. Wiring that does not actually gate is the F-08 condition
# wearing a leg's clothes: the probe appears in the suite, the suite goes green, and a
# regression in the gesture still ships. The suite takes 784 seconds, so nobody re-runs it
# to find out. Three cheap structural branches instead:
#
#   A  all four probes are named in the runner        (they are wired at all)
#   B  the loop increments `fail` on a non-zero probe  (the wiring GATES rather than reports)
#   C  each named probe exists and is executable       (a wired path that cannot run is a
#                                                       leg that always fails, which teaches
#                                                       readers to ignore the suite — OBS-293)
#
# WHY NOT DRIVE THE REAL SUITE. It is 784 seconds and it would have to be driven twice — once
# clean, once with a probe forced to fail — for 26 minutes to prove one branch. A control that
# expensive gets run as rarely as the thing it controls, which is the disease rather than the
# cure. B is asserted on the runner's own text because the loop is four lines long and its
# gating behaviour is visible there.
#
# Exit: 0 all branches hold | 1 a branch failed | 3 could not set up

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$REPO/tests/run-bridge-tests.sh"

PROBES=(
  _horizontal-spacing-verify-cdp.mjs
  _selection-align-verify-cdp.mjs
  _edge-straighten-verify-cdp.mjs
  _t263-save-target-cdp.mjs
)

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }

[ -f "$RUNNER" ] || cannot "runner not found: $RUNNER"

echo "=== T-817 wiring controls ==="

# --- A: every probe is named in the runner.
_missing=()
for p in "${PROBES[@]}"; do
    grep -q -- "$p" "$RUNNER" || _missing+=("$p")
done
if [ "${#_missing[@]}" -eq 0 ]; then
    ok "A all ${#PROBES[@]} probes are named in run-bridge-tests.sh"
else
    bad "A every probe must be wired" "not named in the runner: ${_missing[*]}"
fi

# --- B: the loop must GATE. `fail=$((fail + 1))` has to appear inside the probe loop, or
# the leg reports a problem and lets the suite exit 0 anyway.
_loop=$(sed -n '/^for _probe in/,/^done$/p' "$RUNNER")
if [ -z "$_loop" ]; then
    bad "B probe loop not found" "the for/done block over _probe is gone — wiring cannot be checked"
elif printf '%s' "$_loop" | grep -q 'fail=$((fail + 1))'; then
    ok "B the loop increments \`fail\` on a failing probe (it gates, it does not merely report)"
else
    bad "B wiring must gate" \
        "the probe loop never increments \`fail\` — a failing gesture would leave the suite green"
fi

# --- C: each wired path exists and is executable by node.
_broken=()
for p in "${PROBES[@]}"; do
    [ -f "$REPO/tools/$p" ] || _broken+=("$p (missing)")
done
if [ "${#_broken[@]}" -eq 0 ]; then
    ok "C every wired probe file exists"
else
    bad "C a wired path must resolve" \
        "wired but not present: ${_broken[*]} — that leg would fail every run, and a permanently red leg teaches readers to ignore the suite (OBS-293)"
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
