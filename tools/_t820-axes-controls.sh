#!/usr/bin/env bash
# _t820-axes-controls.sh — does the axis runner fail when ANY ONE axis is unsatisfied?
#
# T-820. tools/_t820-rule-axes.sh exists because T-816 satisfied two of five axes and passed
# its own gate. A runner that only reports green when everything already passes would be the
# same defect one level up: it would look like coverage and add none.
#
# THE BRANCH THAT MATTERS is per-axis. It is not enough that the runner fails when everything
# is broken — it must fail when exactly ONE axis does, because that is the real case. T-816
# had three of five passing.
#
# HOW: run the real runner against a REPO override whose tests/ directory contains a stub for
# exactly one axis that exits 1, and real copies of the rest. Repeat, moving the stub. The
# runner must fail on every placement. Then a clean copy must pass, or the failures prove
# nothing.
#
# WHY NOT MUTATE A VALIDATOR RULE INSTEAD: that would drive the axes themselves, which are
# already well tested and slow. What is under test here is the RUNNER's aggregation — whether
# it reports one failure among four successes — and a stub isolates exactly that.
#
# Exit: 0 the runner fails on each single-axis break and passes when clean | 1 otherwise | 3 setup

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$REPO/tools/_t820-rule-axes.sh"

AXES=(
  tests/test_rule_form_parity.py
  tests/test_rule_dialect_axis.py
  tests/test_finding_anchorability.py
  tests/test_harness_cross_form_agreement.py
  tests/test_check_pass_reachability.py
)

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }

[ -f "$RUNNER" ] || cannot "axis runner not found: $RUNNER"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# A sandbox repo whose only real content is tools/ + tests/ stubs. The runner resolves REPO
# from its own location, so the copy must carry it.
build_sandbox() { # <axis-to-break, or empty for none>
    local broken="${1:-}"
    rm -rf "$WORK/repo"
    mkdir -p "$WORK/repo/tools" "$WORK/repo/tests"
    cp "$RUNNER" "$WORK/repo/tools/"
    local a
    for a in "${AXES[@]}"; do
        if [ "$a" = "$broken" ]; then
            printf '#!/usr/bin/env python3\nimport sys\nsys.exit(1)\n' > "$WORK/repo/$a"
        else
            printf '#!/usr/bin/env python3\nimport sys\nsys.exit(0)\n' > "$WORK/repo/$a"
        fi
    done
}

run_sandbox() { bash "$WORK/repo/tools/$(basename "$RUNNER")" >/dev/null 2>&1; }

echo "=== T-820 axis-runner controls ==="

# --- baseline: all axes green -> runner must PASS. Without this the breaks prove nothing.
build_sandbox ""
if run_sandbox; then
    ok "baseline: all 5 stubs exit 0 -> runner PASSES"
else
    bad "baseline should pass" "the runner fails even when every axis passes; breaks below would be meaningless"
    echo; echo "PASS=$PASS FAIL=$FAIL"; exit 1
fi

# --- one axis at a time.
for a in "${AXES[@]}"; do
    build_sandbox "$a"
    if run_sandbox; then
        bad "single break: $(basename "$a")" \
            "the runner PASSED with this axis failing — it does not aggregate, and a rule author would be told they were done"
    else
        ok "single break: $(basename "$a") -> runner FAILS"
    fi
done

# --- a MISSING axis must be could-not-measure (3), not a pass.
build_sandbox ""
rm -f "$WORK/repo/${AXES[2]}"
run_sandbox
_rc=$?
if [ "$_rc" -eq 3 ]; then
    ok "missing axis file -> exit 3 (could-not-measure, not silently 4-of-5)"
else
    bad "missing axis should exit 3" "got $_rc — a renamed or deleted axis would be skipped rather than reported"
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
