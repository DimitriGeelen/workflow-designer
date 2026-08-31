#!/usr/bin/env bash
# T-662 — under NULL focus the post-completion commit path must (a) still work as two
# separate commands and (b) be NAMED in the block message when someone tries it as one.
#
# G-047 recorded this as "jointly unsatisfiable" on the strength of a block message that
# never mentioned the way through. The gap was a discoverability defect wearing an
# impossibility's clothes, so the thing under test here is the MESSAGE as much as the gate.
#
# Runs the real hook against a null-focus fixture. Never edits this repo's focus.yaml.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

PROJ="${T662_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
HOOK="$PROJ/.agentic-framework/agents/context/check-active-task.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$HOOK" ] || { echo "COULD-NOT-MEASURE: $HOOK not found" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-662: the null-focus commit path must work AND be discoverable ==="
echo

# A project root whose focus.yaml is null — the state `--status work-completed` leaves.
ROOT="$TMP/proj"
mkdir -p "$ROOT/.context/working" "$ROOT/.tasks/active"
printf '%s\n' '# Working Memory - Current Focus' 'current_task: null' 'priorities: []' \
    > "$ROOT/.context/working/focus.yaml"

# The hook reads a JSON envelope on STDIN (check-active-task.sh:9,36-37) and re-anchors
# PROJECT_ROOT from the envelope's own `cwd` (T-2463). Passing env vars instead produces a
# uniform "No active task" for every input, which reads exactly like the gap being real —
# the first draft of this prober "confirmed" G-047 that way.
envelope() {
    python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash",
                  "tool_input": {"command": sys.argv[1]},
                  "cwd": sys.argv[2]}))' "$1" "$ROOT"
}

# run <command> [hook] -> "rc<n>|<stderr>"
run() {
    local out rc
    out=$( cd "$ROOT" && envelope "$1" | PROJECT_ROOT="$ROOT" CLAUDECODE=1 bash "${2:-$HOOK}" 2>&1 )
    rc=$?
    printf 'rc%s|%s' "$rc" "$out"
}

ADD='git add .tasks/completed/T-999-x.md .context/episodic/T-999.yaml'
COMMIT='fw git commit -m "T-999: completed"'
COMPOUND="$ADD; $COMMIT"

# ---------------------------------------------------------------------------
# The two legs G-047 clause (d) says are impossible. If either blocks, the gap's
# original text was right and this task's premise is wrong — which is a finding, not
# a failure to paper over.
echo "--- the two-command path is admitted under null focus"
R=$(run "$ADD")
case "$R" in
    rc0*) ok "git add admitted with no focus (clause (d) said it was refused)" ;;
    *)    bad "git add BLOCKED — G-047 clause (d) was right after all: ${R:0:160}" ;;
esac

R=$(run "$COMMIT")
case "$R" in
    rc0*) ok "fw git commit admitted with no focus (T-2054 exemption)" ;;
    *)    bad "commit BLOCKED — the post-completion path really is closed: ${R:0:160}" ;;
esac

# ---------------------------------------------------------------------------
# The first draft of this prober asserted "add and commit cannot share a line". They can —
# the leg failed and the claim was wrong, not the gate. What actually defeats the T-2054
# exemption is a $(...) on the commit's line. Keeping both directions so the message can
# never drift back to the wrong explanation.
echo "--- add and commit MAY share a line; a \$(...) beside the commit may not"
R=$(run "$COMPOUND")
case "$R" in
    rc0*) ok "git add + fw git commit on one line is admitted (the obvious guess is wrong)" ;;
    *)    bad "add+commit compound refused — the advisory's premise is wrong: ${R:0:160}" ;;
esac

R=$(run 'echo hi; fw git commit -m "T-1: c"')
case "$R" in
    rc0*) ok "a plain extra clause beside the commit is admitted" ;;
    *)    bad "plain compound refused, so the blocker is not the substitution: ${R:0:160}" ;;
esac

SUBST='echo "n=$(wc -l < f)"; fw git commit -m "T-1: c"'
R=$(run "$SUBST")
if [ "${R%%|*}" = "rc0" ]; then
    bad "the \$(...) compound was ADMITTED — the rule the advisory states is not the real one"
else
    ok "a \$(...) sharing the commit's line is refused (T-638 per-clause)"
    # Control: the SAME substitution without a commit clause must be allowed, or the
    # blocker is the substitution alone and the advisory names the wrong cause.
    R2=$(run 'echo "n=$(wc -l < f)"; git add y.md')
    case "$R2" in
        rc0*) ok "control: the same \$(...) is fine without a commit — the pairing is the cause" ;;
        *)    bad "control failed: \$(...) blocks on its own, so the advisory misattributes it" ;;
    esac
    if printf '%s' "$R" | grep -q 'substitution sharing the line'; then
        ok "the refusal names the actual cause and the way through"
    else
        bad "refusal does not name the cause — this is the whole defect: ${R:0:200}"
    fi
fi

# ---------------------------------------------------------------------------
# PL-299: the advisory must be CONDITIONAL. If it prints on every null-focus block it
# carries no information, and a leg asserting its presence would pass on any message.
echo "--- the advisory does not print on unrelated blocked work"
R=$(run 'python3 tools/some-script.py --rebuild')
if [ "${R%%|*}" = "rc0" ]; then
    bad "PRECONDITION FAILED — unrelated work was admitted, so its silence proves nothing"
elif printf '%s' "$R" | grep -q 'substitution sharing the line'; then
    bad "advisory printed on unrelated work — it is decoration, not a signal"
else
    ok "advisory is specific to git add/commit, and that block still fires"
fi

# ---------------------------------------------------------------------------
echo "--- teeth: remove the advisory and the discoverability leg must go red"
MUT="$TMP/hook-mutant.sh"
sed 's|substitution sharing the line with the commit:|REMOVED BY MUTATION|' "$HOOK" > "$MUT"
# Pattern is the ECHO's exact wording, not the bare phrase: the explanatory comment above
# the advisory contains the phrase too, and matching both reports MUTATION INCOMPLETE for a
# mutation that did precisely what it should. The anchor must be as narrow as the sed.
if ! MSG=$(bash -c '. "'"$PROJ"'/tools/lib/mutation-assert.sh"; assert_mutation_complete "$1" "$2" "$3" advisory' \
             _ "$HOOK" "$MUT" 'substitution sharing the line with the commit:'); then
    bad "$MSG"
else
    R=$(run "$SUBST" "$MUT")
    if printf '%s' "$R" | grep -q 'substitution sharing the line'; then
        bad "mutant still prints the advisory; the leg above cannot fail and proves nothing"
    else
        ok "advisory absent under mutation — the discoverability leg is load-bearing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
