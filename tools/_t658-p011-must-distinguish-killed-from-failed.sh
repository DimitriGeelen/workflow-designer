#!/usr/bin/env bash
# T-658 — the P-011 runner must not render "never finished" in the words of "returned wrong".
#
# WHY THIS EXISTS. OBS-332. Every non-zero exit was reported as `FAIL: <cmd> (exit N)`. A
# command that ran and returned a verdict and a command that was killed before producing one
# read identically, so the operator was told "your check is wrong" when the truth was "your
# check did not finish". Seen on T-651: an `fw audit` verification line returned on its first
# invocation, hung on an immediate second against the lock FDs the transition itself holds,
# and was killed externally at five minutes. The gate called that a plain FAIL.
#
# WHAT THIS PROBER MUST NOT DO: it must not retype the runner. It greps the real region out
# of update-task.sh and gives it a function context so `return`/`exit` behave as they do in
# situ. It never touches the project's real tasks.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

# T-661: mutation completeness is asserted by the shared helper — "the original form is
# gone", not "my marker appears exactly N times". See tools/lib/mutation-assert.sh.
. "$(dirname "${BASH_SOURCE[0]}")/lib/mutation-assert.sh"

PROJ="${T658_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="$PROJ/.agentic-framework/agents/task-create/update-task.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$SRC" ] || { echo "COULD-NOT-MEASURE: $SRC not found" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-658: a killed verification command must not read as a failed one ==="
echo

# --- extract the real region: loop + reconciliation + summary ----------------
REGION="$TMP/region.sh"
python3 - "$SRC" > "$REGION" <<'PY' || exit 3
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r"\n    verify_pass=0\n.*?\n    fi\n\}\n", src, re.S)
if not m:
    sys.stderr.write("COULD-NOT-MEASURE: verification runner region not found\n")
    sys.exit(3)
body = m.group(0)
body = body[:body.rindex("\n}\n")]          # drop the function's closing brace
sys.stdout.write(body)
PY
[ -s "$REGION" ] || { echo "COULD-NOT-MEASURE: extracted region was empty" >&2; exit 3; }
grep -q 'verify_pass=0' "$REGION" || { echo "COULD-NOT-MEASURE: region missing its head" >&2; exit 3; }
grep -q 'Options:' "$REGION"      || { echo "COULD-NOT-MEASURE: region missing the summary" >&2; exit 3; }

# run <region> <cmd-per-line...> -> combined stdout+stderr of the real runner
run() {
    local region="$1"; shift
    local harness="$TMP/harness-$RANDOM.sh"
    local cmds; cmds=$(printf '%s\n' "$@")
    local total; total=$(printf '%s\n' "$@" | grep -c . || true)
    {
        echo '#!/usr/bin/env bash'
        echo 'GREEN=""; RED=""; YELLOW=""; NC=""'
        echo "PROJECT_ROOT=\"$TMP\""
        echo 'SKIP_VERIFICATION=false'
        echo 'log_gate_bypass() { :; }'
        echo "verify_total=$total"
        echo "verify_cmds=\$(cat <<'CMDS_EOF'"
        printf '%s\n' "$cmds"
        echo "CMDS_EOF"
        echo ")"
        # A function context so `return 1` in the reconciliation branch is legal, exactly
        # as it is in situ. `exit 1` in the summary exits this harness — also as in situ.
        echo 'run_verification() {'
        echo '  local verify_pass verify_fail verify_failures verify_unfinished'
        echo '  local verify_unfinished_list exit_code _vk_signal _vk_ran _verify_seen'
        cat "$region"
        echo ''   # the region ends mid-line; without this the closing brace lands as `fi}`
        echo '}'
        echo 'run_verification'
    } > "$harness"
    bash "$harness" 2>&1
}

# ---------------------------------------------------------------------------
echo "--- an ordinary failure is still an ordinary failure"
OUT=$(run "$REGION" 'exit 1')
if echo "$OUT" | grep -q 'FAIL' && ! echo "$OUT" | grep -q 'DID NOT FINISH'; then
    ok "exit 1 -> FAIL, no kill language (the change is additive)"
else
    bad "exit 1 misclassified: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- timeout(1) and signal deaths are named as not-finished"
for spec in "124:timeout" "137:signal 9" "143:signal 15"; do
    code="${spec%%:*}"; want="${spec#*:}"
    OUT=$(run "$REGION" "exit $code")
    if echo "$OUT" | grep -q 'DID NOT FINISH' && echo "$OUT" | grep -q "$want"; then
        ok "exit $code -> DID NOT FINISH ($want)"
    else
        bad "exit $code not reported as killed/$want: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
    fi
done

# ---------------------------------------------------------------------------
# THE BOUNDARY. 128 is not 128+N for any N>=1; calling it a signal death would invent a
# "signal 0" and mislabel an ordinary failure as a hang. 127 (command not found) and 2 are
# the codes most likely to be adjacent in a careless range test.
echo "--- boundaries: 128, 127 and 2 stay ordinary failures"
BOUND_BAD=""; BOUND_MUTE=""
for code in 128 127 2; do
    OUT=$(run "$REGION" "exit $code")
    echo "$OUT" | grep -q 'DID NOT FINISH' && BOUND_BAD="$BOUND_BAD $code"
    # An absence-assertion passes on a run that produced NOTHING. Caught live here: a
    # harness syntax error made every other leg fail while this one reported PASS, because
    # "no kill language" is trivially true of an error message. Require the positive too.
    echo "$OUT" | grep -q 'FAIL' || BOUND_MUTE="$BOUND_MUTE $code"
done
if [ -n "$BOUND_MUTE" ]; then
    bad "PRECONDITION FAILED — no FAIL verdict at all for exit code(s):$BOUND_MUTE (the run did not happen; absence of kill language proves nothing)"
elif [ -z "$BOUND_BAD" ]; then
    ok "128/127/2 classified as FAIL — no off-by-one into the kill range"
else
    bad "these were wrongly called kills:$BOUND_BAD"
fi

# ---------------------------------------------------------------------------
echo "--- a kill with no output says so, instead of printing an empty evidence block"
OUT=$(run "$REGION" 'exit 137')
if echo "$OUT" | grep -q 'no output captured'; then
    ok "silence after a kill is stated, not left blank"
else
    bad "empty evidence block after a kill — the thing that made the incident unreadable"
fi

# ---------------------------------------------------------------------------
# AC: the distinction must survive into the SUMMARY, not only the per-line output. A
# per-line label the final message flattens back into "N failed" has not fixed the defect.
echo "--- the summary separates the two kinds and keeps the total whole"
OUT=$(run "$REGION" 'true' 'exit 1' 'exit 124')
MISSING=""
echo "$OUT" | grep -q '2/3 verification(s) did not pass' || MISSING="$MISSING the-whole-total"
echo "$OUT" | grep -q '1 ran and reported a failure'      || MISSING="$MISSING the-ran-group"
echo "$OUT" | grep -q '1 never finished'                  || MISSING="$MISSING the-killed-group"
echo "$OUT" | grep -q 'RUNNER DEFECT'                     && MISSING="$MISSING broke-T630-reconciliation"
if [ -z "$MISSING" ]; then
    ok "summary names both groups, total preserved, reconciliation intact"
else
    bad "summary incomplete:$MISSING | got: $(echo "$OUT" | tr '\n' ' ' | head -c 260)"
fi

# ---------------------------------------------------------------------------
echo "--- ...and points at the fw audit hazard that causes it (OBS-332a)"
if echo "$OUT" | grep -q 'fw audit --section'; then
    ok "remedy names --section as the supported form"
else
    bad "the timeout branch does not mention the whole-audit hazard"
fi

# ---------------------------------------------------------------------------
echo "--- an all-failed run is unchanged: no kill language, no kill advice"
OUT=$(run "$REGION" 'exit 1' 'exit 2')
if echo "$OUT" | grep -q '2/2 verification(s) failed' && ! echo "$OUT" | grep -q 'never finished'; then
    ok "ordinary failures read exactly as before"
else
    bad "kill language leaked into a run with no kills: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- a clean run still passes"
OUT=$(run "$REGION" 'true' 'true')
if echo "$OUT" | grep -q 'Verification: 2/2 passed'; then
    ok "2/2 passed"
else
    bad "a clean run no longer passes: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- teeth: collapse the classification and 124 must read as a plain failure"
MUT="$TMP/region-mutant.sh"
sed 's|^            if \[ -n "\$_vk_signal" \]; then|            if false; then|' "$REGION" > "$MUT"
BASELINE=$(run "$REGION" 'exit 124')
# T-661: completeness, not a marker count. See tools/lib/mutation-assert.sh.
if ! MUTATED=$(assert_mutation_complete "$REGION" "$MUT" '^            if \[ -n "\$_vk_signal" \]; then' 'classification branch'); then
    bad "$MUTATED"
elif ! echo "$BASELINE" | grep -q 'DID NOT FINISH'; then
    # PL-297: silence after a mutation only means something if there was noise before it.
    bad "PRECONDITION FAILED — unmutated region does not classify 124, so the mutant's silence proves nothing"
else
    OUT=$(run "$MUT" 'exit 124')
    if ! echo "$OUT" | grep -q 'DID NOT FINISH'; then
        ok "mutant loses a distinction the unmutated region demonstrably makes"
    else
        bad "mutant still classified; the legs above cannot fail and prove nothing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
