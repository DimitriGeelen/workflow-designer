#!/bin/bash
# T-634 — do P-011's guards actually stop a completion, and WHAT makes them stop it?
#
# 999-AEF @790 §3, on their own version of the T-630 fix, caught before shipping:
#
#     "I first wrote leg 2 as `return 1`. The caller invokes run_verification_commands
#      BARE — no `if`, no `||` — so a non-zero return is discarded and the close proceeds.
#      A GUARD THAT RETURNS TO A CALLER WHO DOES NOT CHECK IS A PRINT STATEMENT."
#
# Our guard is `return 1` and our caller is bare, so the shape matched theirs exactly and
# this file was opened to fix it. MEASURED FIRST, AND THE ANSWER WAS NO: a malformed
# verification block prints "Nothing was run" and the task stays in active/. The reason is
# line 14, `set -euo pipefail` — under errexit a bare call to a function that returns
# non-zero aborts the script. Nothing needed fixing.
#
# THE FINDING IS THEREFORE A DEPENDENCY, NOT A DEFECT, and it is worth a probe because it
# is invisible at the guards themselves:
#
#   - the three `return 1` guards block ONLY because of errexit at the call site;
#   - the ordinary "N verifications failed" path fourteen lines below uses `exit 1` and
#     blocks regardless;
#   - so one function carries two mechanisms for one job, and only one survives a change
#     of calling context. `if run_verification_commands; then`, `... || true`, a `&&`
#     chain or a subshell would turn all three guards into print statements with NO DIFF
#     TO THE GUARDS. Same class as T-404's two redirect regexes: one question, two
#     implementations, only one of them hardened.
#
# Rewriting the guards to `exit 1` is NOT the remedy. `exit` from a library-style function
# is blunter, and the file's convention is deliberate — the T-522 EXIT-trap watchdog
# depends on the script exiting rather than being killed mid-transition. The remedy is a
# leg that goes red if the dependency stops holding.
#
# HARNESS NOTE (AEF @790 §4, confirmed here the hard way): update-task.sh derives
# FRAMEWORK_ROOT from its own location with no env override, so a mutant copied to a
# scratch dir dies in lib/paths.sh long before reaching any gate — a red leg that looks
# like teeth and is actually a missing dependency. Mutants are staged BESIDE the original.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
GATE="$PROJ/.agentic-framework/agents/task-create/update-task.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t634-$$-$(date +%s)"
MUT="$(dirname "$GATE")/.t634-mutant-$$.sh"
trap 'rm -f "$MUT" 2>/dev/null || true; rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM

[ -f "$GATE" ] || { echo "COULD-NOT-MEASURE: gate not found at $GATE" >&2; exit 3; }
mkdir -p "$SANDBOX"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

# A throwaway project root with one otherwise-completable task. `tags:` and the other
# frontmatter keys are not decoration: a later gate greps for them, and under errexit a
# grep miss kills the run — which is how the first draft of this harness produced a
# "blocked" verdict that had nothing to do with P-011.
make_sandbox() {  # <root> <task-id> <verification-block>
    local root="$1" tid="$2" verif="$3"
    rm -rf "$root"
    mkdir -p "$root/.tasks/active" "$root/.tasks/completed" "$root/.context/working"
    printf 'project: t634-sandbox\n' > "$root/.framework.yaml"
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

# The fixture that trips a guard. A single incomplete construct: P-011 runs one line per
# command, so `if true; then` is caught by the MALFORMED BLOCK guard and NOTHING is run.
# Deliberately this guard and not the RUNNER DEFECT one: the extractor strips blank lines
# before counting, so a whitespace-only line cannot produce an unreconciled count against
# the live gate, and T-630's `< /dev/null` closed the stdin route that could. All three
# guards share one exit path, so tripping any of them measures the same property.
BAD_BLOCK='if true; then'

echo "=== T-634 does a guard's verdict reach the caller? ==="
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
echo "--- the guard, through the REAL script"
LIVE="$SANDBOX/live"
make_sandbox "$LIVE" "T-902" "$BAD_BLOCK"
run_gate "$GATE" "$LIVE" "T-902"
if printf '%s' "$OUT" | grep -q 'MALFORMED BLOCK'; then
    ok "live: the guard fires and says nothing was run"
else
    bad "live: the guard did not fire — the fixture no longer reaches it"
fi
if completed "$LIVE" "T-902"; then
    bad "live: THE TASK COMPLETED ANYWAY — the guard is a print statement (AEF @790 §3)"
else
    ok "live: completion is blocked (rc=$RC) — the verdict reaches the caller"
fi

echo
echo "--- WHAT blocks it: remove errexit and the same fixture must complete"
# This is the whole point of the file. The leg above passing does not tell you WHY, and
# the guards' own text (`return 1`) says the opposite. If dropping `set -e` leaves the
# task still blocked, then errexit is not the mechanism and this analysis is wrong.
python3 - "$GATE" "$MUT" <<'PY'
import sys
src = open(sys.argv[1]).read()
# Anchor on the LINE, not the substring: the phrase "set -euo pipefail" also appears in
# two comments explaining errexit behaviour, so a substring count of 1 was never going to
# hold and the first draft failed loudly here rather than mutating a comment. Loudly is
# the point — a mutation that silently edits prose certifies nothing.
lines = src.splitlines(keepends=True)
hits = [i for i, ln in enumerate(lines) if ln.rstrip("\n") == "set -euo pipefail"]
if len(hits) != 1:
    sys.stderr.write("MUTATION FAILED: %d executable errexit line(s), expected 1\n" % len(hits))
    sys.exit(1)
lines[hits[0]] = "set -uo pipefail\n"
open(sys.argv[2], "w").write("".join(lines))
PY
if [ ! -s "$MUT" ] || ! bash -n "$MUT" 2>/dev/null; then
    bad "teeth: errexit mutant not built or does not parse — the dependency is unproven"
else
    ok "teeth: mutant parses (any failure below is behavioural, not syntactic)"
    NOEE="$SANDBOX/noerrexit"
    make_sandbox "$NOEE" "T-903" "$BAD_BLOCK"
    run_gate "$MUT" "$NOEE" "T-903"
    if completed "$NOEE" "T-903"; then
        ok "teeth: without errexit the SAME fixture completes — errexit is what blocks it"
    else
        bad "teeth: still blocked without errexit — the guard blocks for some other reason"
    fi
fi

echo
echo "--- the call site must not suppress errexit"
# Three guards depend on this line's shape. In a condition, an && / || chain, or a
# subshell, errexit is suppressed and all three go inert with no diff to the guards.
SITE=$(grep -nE '(^|[^#])\brun_verification_commands\b' "$GATE" \
       | grep -v 'log_gate_bypass' | grep -v '^979:' || true)
NSITE=$(printf '%s' "$SITE" | grep -c '' || echo 0)
if [ "$NSITE" -ne 1 ]; then
    bad "expected exactly 1 call site, found $NSITE — the analysis covers only one:"
    printf '%s\n' "$SITE" | sed 's/^/          /'
else
    ok "exactly one call site (denominator is real)"
    LINE=${SITE#*:}
    if printf '%s' "$LINE" | grep -qE '^\s*run_verification_commands\s*$'; then
        ok "call site is a bare statement — errexit applies to it"
    else
        bad "call site is guarded/chained, which SUPPRESSES errexit: $LINE"
    fi
fi

echo
echo "--- --skip-verification must not buy past an unreconciled count"
SKIP="$SANDBOX/skip"
make_sandbox "$SKIP" "T-904" "$BAD_BLOCK"
run_gate "$GATE" "$SKIP" "T-904" --skip-verification
if completed "$SKIP" "T-904"; then
    bad "--skip-verification bypassed a guard that reports the runner does not know what it ran"
else
    ok "--skip-verification does not bypass it (rc=$RC)"
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
