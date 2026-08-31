#!/usr/bin/env bash
# T-649 — completing a task while its own work is uncommitted must SAY SO.
#
# WHY THIS EXISTS. G-047: after `--status work-completed` a task's diff can no longer
# be committed under its own id. Focus on the completed task refuses every write; focus
# elsewhere trips focus-drift on a `T-NNN:` subject; work-completed is terminal; and
# with focus null the gate refuses even a READ. Every exit is a Tier-2 bypass, i.e. the
# operator's to grant. The cadence that avoids the trap — COMMIT BEFORE YOU COMPLETE —
# was written down nowhere. That, not the gate conflict, is the defect being fixed:
# nothing told you that you were one command away from an unsatisfiable position.
#
# WHAT THIS PROBER MUST NOT DO, stated because both are tempting and both are wrong:
#   1. It must not run the real update-task.sh against the real .tasks/ — completing a
#      live task to see a warning would be using production state as a fixture, and the
#      transition is not reversible. Every leg runs in a throwaway git repo under a
#      scratch PROJECT_ROOT.
#   2. It must not retype the warning's predicate. It greps the real function out of
#      update-task.sh and executes THAT, so a rewrite is reported rather than skipped.
#
# Exit 0 = all legs pass.

set -uo pipefail

PROJ="${T649_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="$PROJ/.agentic-framework/agents/task-create/update-task.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$SRC" ] || { echo "COULD-NOT-MEASURE: $SRC not found" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-649: completing with uncommitted work must warn (G-047 prevention) ==="
echo

# ---------------------------------------------------------------------------
# Lift the REAL function out of the REAL script. Anchored on its name and closing
# brace; if it is ever rewritten into a shape this cannot find, say so and stop.
extract_fn() {
    python3 - "$SRC" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r"\nwarn_uncommitted_work\(\) \{\n.*?\n\}\n", src, re.S)
if not m:
    sys.stderr.write("COULD-NOT-MEASURE: warn_uncommitted_work() not found in update-task.sh\n")
    sys.exit(3)
sys.stdout.write(m.group(0))
PY
}
FN="$TMP/fn.sh"
extract_fn > "$FN" || exit 3
[ -s "$FN" ] || { echo "COULD-NOT-MEASURE: extracted function was empty" >&2; exit 3; }

# A throwaway repo. Nothing here touches the project's own git state or .tasks/.
REPO="$TMP/repo"
mkdir -p "$REPO/.context/working" "$REPO/.tasks/active" "$REPO/src"
git -C "$REPO" init -q 2>/dev/null
git -C "$REPO" config user.email t649@example.invalid
git -C "$REPO" config user.name  t649
printf 'one\n'   > "$REPO/src/a.txt"
printf 'two\n'   > "$REPO/src/b.txt"
printf 'churn\n' > "$REPO/.context/working/focus.yaml"
printf '# task\n' > "$REPO/.tasks/active/T-999-x.md"
git -C "$REPO" add -A >/dev/null 2>&1
git -C "$REPO" commit -qm "baseline" >/dev/null 2>&1

# run <NEW_STATUS> -> stdout+stderr of the function, plus RC on the last line
run_fn() {
    (
        set +u
        PROJECT_ROOT="$REPO"
        TASK_FILE="$REPO/.tasks/active/T-999-x.md"
        TASK_ID="T-999"
        NEW_STATUS="$1"
        . "$FN"
        warn_uncommitted_work 2>&1
        echo "RC=$?"
    )
}

# ---------------------------------------------------------------------------
echo "--- a clean tree says nothing"
OUT=$(run_fn work-completed)
if ! echo "$OUT" | grep -q "not committed" && echo "$OUT" | grep -q "RC=0"; then
    ok "clean tree: silent, exit 0"
else
    bad "clean tree produced output: $(echo "$OUT" | head -3 | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
echo "--- working-memory churn alone is not worth a warning"
printf 'changed\n' > "$REPO/.context/working/focus.yaml"
OUT=$(run_fn work-completed)
if ! echo "$OUT" | grep -q "not committed"; then
    ok ".context/ churn alone: still silent (this is normal and constant)"
else
    bad ".context/ churn triggered the warning — it will cry wolf on every completion"
fi

# ---------------------------------------------------------------------------
echo "--- the task file itself is not 'uncommitted work' — the transition moves it anyway"
printf '# task edited\n' > "$REPO/.tasks/active/T-999-x.md"
OUT=$(run_fn work-completed)
if ! echo "$OUT" | grep -q "not committed"; then
    ok "task file alone: still silent"
else
    bad "the task's own file triggered the warning: $(echo "$OUT" | head -4 | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
echo "--- real modified source DOES warn, names the file, the cadence and the gap"
printf 'one changed\n' > "$REPO/src/a.txt"
OUT=$(run_fn work-completed)
MISSING=""
echo "$OUT" | grep -q "src/a.txt"                    || MISSING="$MISSING the-filename"
echo "$OUT" | grep -q "COMMIT BEFORE YOU COMPLETE"   || MISSING="$MISSING the-cadence"
echo "$OUT" | grep -q "G-047"                        || MISSING="$MISSING the-gap-ref"
echo "$OUT" | grep -q "T-999"                        || MISSING="$MISSING the-task-id"
if [ -z "$MISSING" ]; then
    ok "warns, and the message is actionable (file + cadence + G-047 + task id)"
else
    bad "warning is missing:$MISSING  | got: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- it is a WARNING: the function still succeeds, so the transition is not gated"
if echo "$OUT" | grep -q "RC=0"; then
    ok "returns 0 with a dirty tree — completion proceeds, the reader is merely told"
else
    bad "returned non-zero — this is a GATE, not a warning, and blocking here punishes the common case"
fi

# ---------------------------------------------------------------------------
echo "--- it does not fire on other transitions"
OUT2=$(run_fn started-work)
if ! echo "$OUT2" | grep -q "not committed"; then
    ok "started-work: silent (only the irreversible transition matters)"
else
    bad "fired on a started-work transition"
fi

# ---------------------------------------------------------------------------
echo "--- more than five files: it truncates rather than dumping the tree"
for i in $(seq 1 8); do printf 'x\n' > "$REPO/src/f$i.txt"; done
git -C "$REPO" add -A >/dev/null 2>&1
git -C "$REPO" commit -qm "add many" >/dev/null 2>&1
for i in $(seq 1 8); do printf 'changed\n' > "$REPO/src/f$i.txt"; done
OUT=$(run_fn work-completed)
if echo "$OUT" | grep -qE "and [0-9]+ more"; then
    ok "long list is truncated with a count: $(echo "$OUT" | grep -oE 'and [0-9]+ more')"
else
    bad "no truncation on a 9-file dirty tree — the warning will bury its own advice"
fi

# ---------------------------------------------------------------------------
echo "--- teeth: delete the check and the dirty-tree leg must stop passing"
NOFN="$TMP/nofn.sh"
sed 's/^\(  *\)echo "  ⚠ \$count tracked file(s) modified and not committed:" >&2/\1:/' "$FN" > "$NOFN"
if ! grep -q '^\s*:$' "$NOFN"; then
    bad "MUTATION FAILED — could not neutralise the warning line; this leg proves nothing"
else
    OUT=$( set +u
           PROJECT_ROOT="$REPO"; TASK_FILE="$REPO/.tasks/active/T-999-x.md"
           TASK_ID="T-999"; NEW_STATUS="work-completed"
           . "$NOFN"; warn_uncommitted_work 2>&1 )
    if ! echo "$OUT" | grep -q "not committed"; then
        ok "mutant is silent on the same dirty tree — the check is what produces the warning"
    else
        bad "mutant still warned — the leg above cannot fail and proves nothing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
