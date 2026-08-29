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
# green summary was reached on `verify_fail == 0` without ever comparing `verify_pass` to
# `verify_total`.
#
# MECHANISM. The runner loop is fed by a herestring and `eval`s each command. Without a
# stdin redirect on the `eval`, it inherits the loop's stdin — which IS the list of
# remaining verification commands — so a command that reads stdin eats the rest of the
# list. Those lines were already counted by `wc -l` before the loop, so they sit in the
# denominator and never run. The fix has two halves: `< /dev/null` on the eval
# (update-task.sh:1218) stops the swallowing, and a reconciliation guard after the loop
# refuses a pass verdict if `pass + fail` ever again fails to equal `total`.
#
# ── T-635: THIS FILE USED TO ASSERT AGAINST A MODEL, AND THE MODEL HAD DRIFTED ─────────
#
# The first version pinned two runner shapes here as text — pre-fix and fixed — and ran
# the fixture through those. The argument for pinning was sound as far as it went: a
# pre-fix reproduction read from git history (`git show HEAD~1:`) silently starts testing
# the fix against itself as soon as one more commit lands (AEF, rail-463). But a pinned
# copy has the opposite failure, and it had already happened twice:
#
#   - the model ended in `exit 1`; the live guard uses `return 1` and blocks only because
#     of `set -euo pipefail` 1700 lines away (T-634);
#   - the model computed `total` with `wc -l` BEFORE skipping blank lines. The live gate
#     strips them first — `verify_cmds` is filtered at update-task.sh:1082 by
#     `grep -vE '^\s*$|^\s*#|^\s*```'` and only then counted at 1179.
#
# The second drift was load-bearing. The old leg 3 fed a whitespace-only line to the model
# to manufacture a counted-but-never-run command; against the real gate that line never
# survives extraction, so it is never in the denominator, so it cannot leave a gap. A green
# leg measuring a scenario the gate cannot reach (OBS-323).
#
# WHAT THE REWRITE ESTABLISHED, and it is more than OBS-323 asked for. With the filter at
# 1082 and the redirect at 1218, EVERY line that survives extraction has a non-space
# character, so every line produces a verdict. NO VERIFICATION-BLOCK INPUT CAN REACH THE
# RECONCILIATION GUARD. It is a regression detector, not an input validator — and a guard
# that no input can trip is not tested by inputs. It is tested by mutation or not at all.
#
# So every leg below drives the REAL update-task.sh, and the pre-fix shape is DERIVED from
# the live source by deleting the redirect rather than copied from memory. That has the
# git-history approach's freedom from drift without its self-testing problem: the mutant is
# always exactly today's gate minus the one line under test.
#
# HARNESS NOTE (AEF @790 §4, confirmed by T-634): update-task.sh derives FRAMEWORK_ROOT
# from its own location with no env override, so a mutant copied to a scratch dir dies in
# lib/paths.sh before reaching any gate — a red leg that looks like teeth and is actually a
# missing dependency. Mutants are staged BESIDE the original.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
GATE="$PROJ/.agentic-framework/agents/task-create/update-task.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t630-$$-$(date +%s)"
MUT="$(dirname "$GATE")/.t630-mutant-$$.sh"
trap 'rm -f "$MUT" 2>/dev/null || true; rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM

[ -f "$GATE" ] || { echo "COULD-NOT-MEASURE: gate not found at $GATE" >&2; exit 3; }
mkdir -p "$SANDBOX"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

# A throwaway project root with one otherwise-completable task. The frontmatter keys are
# not decoration: later gates grep for them, and under errexit a grep miss kills the run
# before P-011 is reached (T-634 lost a session to exactly that).
make_sandbox() {  # <root> <task-id> <verification-block>
    local root="$1" tid="$2" verif="$3"
    rm -rf "$root"
    mkdir -p "$root/.tasks/active" "$root/.tasks/completed" "$root/.context/working"
    printf 'project: t630-sandbox\n' > "$root/.framework.yaml"
    printf -- '---\nid: %s\nname: "sandbox probe"\ndescription: sandbox probe\nstatus: started-work\nworkflow_type: build\nowner: agent\nhorizon: now\ntags: []\ncomponents: []\nrelated_tasks: []\ncreated: 2026-08-29T00:00:00Z\nlast_update: 2026-08-29T00:00:00Z\ndate_finished: null\n---\n\n# %s: sandbox probe\n\n## Context\n\nprobe\n\n## Acceptance Criteria\n\n### Agent\n- [x] the only criterion\n\n## Verification\n\n%s\n\n## Updates\n\n- none\n' \
        "$tid" "$tid" "$verif" > "$root/.tasks/active/$tid-sandbox-probe.md"
}

run_gate() {  # <script> <root> <task-id> [extra args...]
    local script="$1" root="$2" tid="$3"; shift 3
    OUT=$(env -u TASKS_DIR -u CONTEXT_DIR -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
        CLAUDECODE=1 PROJECT_ROOT="$root" \
        bash "$script" "$tid" --status work-completed "$@" 2>&1)
    RC=$?
}
completed() { ls "$1/.tasks/completed/$2"* >/dev/null 2>&1; }

# THE INVENTED FIXTURE. Four commands whose SECOND reads stdin. No task file in our corpus
# declares a stdin-reading verification command — which is precisely why the defect
# survived: the corpus contains no negative for it. `cat` stands in for any stdin-reading
# tool, and it is a shape we had to make up rather than find (577 @774 item 3: the cost of
# skipping invented fixtures depends on whether the corpus holds negatives, not on size).
SWALLOW=$'echo one\ncat > /dev/null\necho three\necho four'

echo "=== T-630 P-011 stdin-swallow (T-635: measured against the live gate) ==="
echo

echo "--- anti-vacuity: the sandbox must be able to complete a task at all"
CTRL="$SANDBOX/ctrl"
make_sandbox "$CTRL" "T-901" 'echo one'
run_gate "$GATE" "$CTRL" "T-901"
if completed "$CTRL" "T-901"; then
    ok "control: a clean task completes here (rc=$RC) — 'blocked' below will mean something"
else
    bad "control: even a clean task cannot complete — every leg below is vacuous"
    printf '%s\n' "$OUT" | tail -6 | sed 's/^/          /'
    echo "COULD-NOT-MEASURE: sandbox cannot complete anything." >&2
    exit 3
fi

echo
echo "--- the fix, through the LIVE gate: a stdin-reader must not eat the list"
LIVE="$SANDBOX/live"
make_sandbox "$LIVE" "T-902" "$SWALLOW"
run_gate "$GATE" "$LIVE" "T-902"
if printf '%s' "$OUT" | grep -q 'Verification: 4/4 passed'; then
    ok "live gate: all four declared commands reported (4/4)"
else
    bad "live gate: not all four reported — the redirect is gone or the fixture missed:"
    printf '%s\n' "$OUT" | grep -E 'Running|PASS:|FAIL:|Verification:|DEFECT' | sed 's/^/          /'
fi
if completed "$LIVE" "T-902"; then
    ok "live gate: the task completes (rc=$RC)"
else
    bad "live gate: a fixture that should pass is blocked — the harness, not the gate"
fi

echo
echo "--- teeth: delete the redirect from the LIVE source and the swallow must return"
# Derived, not remembered. The mutant is today's gate minus one line, so it cannot drift
# from the thing it is testing the way a pinned copy did (T-635).
python3 - "$GATE" "$MUT" <<'PY'
import sys
src = open(sys.argv[1]).read()
# Anchor asserted unique. A mutation that matches nothing reports success and certifies an
# untested fix (T-632 shipped one of those and caught it only by re-reading the diff).
anchor = "2>&1 < /dev/null"
if src.count(anchor) != 1:
    sys.stderr.write("MUTATION FAILED: %d occurrence(s) of the stdin redirect, expected 1\n"
                     % src.count(anchor))
    sys.exit(1)
open(sys.argv[2], "w").write(src.replace(anchor, "2>&1", 1))
PY
if [ ! -s "$MUT" ] || ! bash -n "$MUT" 2>/dev/null; then
    bad "teeth: mutant not built or does not parse — the redirect's role is unproven"
else
    ok "teeth: mutant parses (any failure below is behavioural, not syntactic)"

    SWAL="$SANDBOX/swallowed"
    make_sandbox "$SWAL" "T-903" "$SWALLOW"
    run_gate "$MUT" "$SWAL" "T-903"

    # Half one: the redirect is load-bearing. Without it the same fixture loses commands.
    if printf '%s' "$OUT" | grep -qE 'only [0-9]+ produced a verdict'; then
        ok "teeth: without the redirect the stdin-reader eats the list — the fix is real"
    else
        bad "teeth: no commands were swallowed without the redirect — the fixture no longer bites:"
        printf '%s\n' "$OUT" | grep -E 'Running|PASS:|FAIL:|Verification:|DEFECT' | sed 's/^/          /'
    fi

    # Half two: and the reconciliation guard catches it. THIS IS THE FIRST TIME THAT GUARD
    # IS EXERCISED AGAINST THE LIVE GATE — no Verification-block input can reach it (leg
    # below), so mutation is the only instrument that can.
    if printf '%s' "$OUT" | grep -q 'RUNNER DEFECT'; then
        ok "teeth: reconciliation names it a runner defect, not a verification failure"
    else
        bad "teeth: a swallowed command did not trip reconciliation — the guard is inert"
    fi
    if completed "$SWAL" "T-903"; then
        bad "teeth: THE TASK COMPLETED with commands that never ran — this is the T-629 bug"
    else
        ok "teeth: completion is blocked (rc=$RC)"
    fi

    # --skip-verification means "I accept these failures". An unreconciled count is not a
    # failure the operator can accept — it is the runner reporting it does not know what it
    # ran. Measured against the mutant because that is the only route to the guard.
    SKIP="$SANDBOX/skip"
    make_sandbox "$SKIP" "T-904" "$SWALLOW"
    run_gate "$MUT" "$SKIP" "T-904" --skip-verification
    if completed "$SKIP" "T-904"; then
        bad "--skip-verification bought past RUNNER DEFECT — an unknowable result was accepted"
    else
        ok "--skip-verification does not bypass reconciliation (rc=$RC)"
    fi
fi

echo
echo "--- why mutation is the only instrument: no INPUT can reach that guard"
# The old leg 3 tried to reach it with a whitespace-only line, against a model that counted
# before stripping. The live gate strips first, so such a line is not in the denominator at
# all. Measured here rather than argued, because that is the claim the old leg got wrong.
BLANKY=$'echo one\n \necho three'
GAP="$SANDBOX/gap"
make_sandbox "$GAP" "T-905" "$BLANKY"
run_gate "$GATE" "$GAP" "T-905"
if printf '%s' "$OUT" | grep -q 'Running 2 verification command(s)'; then
    ok "a whitespace-only line is filtered BEFORE counting — it never enters the denominator"
elif printf '%s' "$OUT" | grep -q 'Running 3 verification command(s)'; then
    bad "the blank line IS counted — extraction changed, and reconciliation is now input-reachable"
else
    bad "could not read a command count from the gate's output:"
    printf '%s\n' "$OUT" | grep -E 'Running|Verification:|DEFECT' | sed 's/^/          /'
fi
if completed "$GAP" "T-905"; then
    ok "and it completes: nothing was skipped, so nothing is unreconciled"
else
    bad "a blank line blocked completion — the filter at update-task.sh:1082 is not doing this"
fi

# The leg above measures ONE input. The claim it supports — that no input reaches the
# guard — is a general one, and it rests on a structural premise: the runner loop has
# exactly ONE path that skips a counted line without producing a verdict (`[ -z "$cmd" ]
# && continue`), and extraction has already removed everything that can take it. A second
# skip path added later would make reconciliation input-reachable again and quietly expire
# the reasoning in this file's header. Pinning the premise is not a substitute for the
# behaviour above; it is what stops a general claim outliving its grounds.
LOOPSKIP=$(python3 - "$GATE" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r'\n( *)while IFS= read -r cmd; do\n(.*?)\n\1done <<< "\$verify_cmds"\n',
              src, re.S)
if not m:
    print("NOLOOP"); sys.exit(0)
body = m.group(2)
print(len(re.findall(r'(?m)^\s*(?!#)[^\n#]*\bcontinue\b', body)))
PY
)
if [ "$LOOPSKIP" = "1" ]; then
    ok "the runner loop has exactly one skip path — the general claim still has its premise"
elif [ "$LOOPSKIP" = "NOLOOP" ]; then
    bad "could not locate the runner loop — this file's reachability claim is unverified"
else
    bad "the runner loop now has $LOOPSKIP skip paths; reconciliation may be input-reachable again"
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
