#!/bin/bash
# T-630 — P-011 counted commands it never ran, and called the result a pass.
#
# OBSERVED, in the gate's own output, completing T-629:
#
#     Running 4 verification command(s)...
#       PASS: bash tools/_t629-g067-remedy-reachable.sh
#       PASS: bash tools/_t628-g020-remedy-reachable.sh
#     Verification: 2/4 passed ✓
#
# Two commands produced neither verdict; the task completed. `verify_fail` was 0, and the
# green summary is reached on `verify_fail == 0` without ever comparing `verify_pass` to
# `verify_total`.
#
# MECHANISM. The runner loop is fed by a herestring and `eval`s each command without
# redirecting stdin, so `eval` inherits the loop's stdin — the list of remaining commands.
# A verification command that reads stdin eats the rest of the list. Those lines were
# already counted by `wc -l` before the loop, so they appear in the denominator and never
# run. The more commands a task declares, the more one stdin-reader can swallow.
#
# WHAT THIS FILE PROVES, AND WHY IT IS SHAPED THIS WAY. Two runner shapes are pinned here
# as text: the pre-fix one and the fixed one. The pre-fix copy is what gives the suite
# teeth that do not expire — it is not read from git history (AEF's rail-463 lesson: a
# `git show HEAD~1:` anchor silently starts testing the fix against itself as soon as one
# more commit lands) and not read from the live file (which now carries the fix). It is a
# frozen reproduction of the defect, and the fixed shape is asserted to survive exactly
# the input that breaks it.
#
# THE FIXTURE IS INVENTED. No task file in our corpus declares a verification command that
# reads stdin — which is precisely why the defect survived: the corpus contains no
# negative for it. `cat` standing in for any stdin-reading tool is the whole trick, and it
# is a shape we had to make up rather than find. 577 @774 item 3: the cost of skipping
# invented fixtures depends on whether the corpus holds negatives, not on how big it is.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
GATE="$PROJ/.agentic-framework/agents/task-create/update-task.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t630-$$-$(date +%s)"
trap 'rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM
mkdir -p "$SANDBOX"

[ -f "$GATE" ] || { echo "COULD-NOT-MEASURE: gate not found at $GATE" >&2; exit 3; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

# The invented fixture: a four-command block whose SECOND command reads stdin.
FIXTURE=$'echo one\ncat >/dev/null\necho three\necho four'

# --- runner shapes, pinned as text ------------------------------------------------
# Pre-fix: eval inherits the loop's stdin, summary gates on verify_fail alone.
cat > "$SANDBOX/runner-prefix.sh" <<'OLD'
cmds="$1"
total=$(echo "$cmds" | wc -l); pass=0; fail=0
while IFS= read -r cmd; do
  # Trim as the real runner does (update-task.sh:1190) — without this the model
  # skips a step the gate has, and a whitespace-only line gets eval'd instead of
  # skipped. That difference silently removed the gap the reconciliation leg needs.
  cmd=$(echo "$cmd" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  [ -z "$cmd" ] && continue
  if (eval "$cmd") > /dev/null 2>&1; then pass=$((pass+1)); else fail=$((fail+1)); fi
done <<< "$cmds"
if [ "$fail" -gt 0 ]; then echo "VERDICT=fail pass=$pass fail=$fail total=$total"; exit 1; fi
echo "VERDICT=pass pass=$pass fail=$fail total=$total"
OLD

# Fixed: `< /dev/null` on the eval, plus reconciliation before any pass verdict.
cat > "$SANDBOX/runner-fixed.sh" <<'NEW'
cmds="$1"
total=$(echo "$cmds" | wc -l); pass=0; fail=0
while IFS= read -r cmd; do
  # Trim as the real runner does (update-task.sh:1190) — without this the model
  # skips a step the gate has, and a whitespace-only line gets eval'd instead of
  # skipped. That difference silently removed the gap the reconciliation leg needs.
  cmd=$(echo "$cmd" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  [ -z "$cmd" ] && continue
  if (eval "$cmd") > /dev/null 2>&1 < /dev/null; then pass=$((pass+1)); else fail=$((fail+1)); fi
done <<< "$cmds"
seen=$((pass + fail))
if [ "$seen" -ne "$total" ]; then echo "VERDICT=runner-defect pass=$pass fail=$fail total=$total"; exit 1; fi
if [ "$fail" -gt 0 ]; then echo "VERDICT=fail pass=$pass fail=$fail total=$total"; exit 1; fi
echo "VERDICT=pass pass=$pass fail=$fail total=$total"
NEW

echo "=== T-630 P-011 stdin-swallow ==="
echo

echo "--- the defect, reproduced against the pinned pre-fix runner"
out=$(bash "$SANDBOX/runner-prefix.sh" "$FIXTURE" 2>&1)
echo "    $out"
if printf '%s' "$out" | grep -q 'VERDICT=pass pass=2 .* total=4'; then
    ok "pre-fix runner: 2 of 4 ran and it returned PASS (this is the bug)"
else
    bad "pre-fix runner did not reproduce the defect — teeth are gone, fix the fixture"
    echo "COULD-NOT-MEASURE: without a live reproduction the leg below proves nothing." >&2
    exit 3
fi

echo
echo "--- the same input through the fixed runner"
out=$(bash "$SANDBOX/runner-fixed.sh" "$FIXTURE" 2>&1)
echo "    $out"
if printf '%s' "$out" | grep -q 'VERDICT=pass pass=4 fail=0 total=4'; then
    ok "fixed runner: all four commands ran"
else
    bad "fixed runner did not run all four: $out"
fi

echo
echo "--- reconciliation refuses a pass verdict when a command never reports"
# A block with a blank line the filter would normally strip, forced past it: the loop
# `continue`s without a verdict while wc -l has already counted the line. This is the
# generic case the guard exists for — stdin-swallowing is only one way to get here.
out=$(bash "$SANDBOX/runner-fixed.sh" $'echo one\n \necho three' 2>&1)
echo "    $out"
if printf '%s' "$out" | grep -q 'VERDICT=runner-defect'; then
    ok "an uncounted command blocks the pass verdict instead of shrinking the numerator"
else
    bad "reconciliation did not fire: $out"
fi

echo
echo "--- the live gate carries both halves of the fix"
# Asserted against the real file, because the pinned shapes above are a model of it and a
# model that has drifted from the thing it models is worse than no model. Two greps, two
# distinct halves — the redirect alone leaves the counting hole open for any other cause.
if grep -q '2>&1 < /dev/null' "$GATE"; then
    ok "live gate: eval redirects stdin"
else
    bad "live gate: eval does NOT redirect stdin — the model has drifted from the gate"
fi
if grep -q '_verify_seen' "$GATE"; then
    ok "live gate: reconciliation guard present"
else
    bad "live gate: no reconciliation guard — a silent skip would still read as a pass"
fi
if grep -q 'RUNNER DEFECT' "$GATE"; then
    ok "live gate: the defect has its own failure line, distinct from a verification failure"
else
    bad "live gate: an unreconciled count is not separately reported"
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
