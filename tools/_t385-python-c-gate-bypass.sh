#!/bin/bash
# T-385 — does AEF's OBS-200 class reproduce against OUR vendored task gate?
#
# CLAIM UNDER TEST (AEF, rail offset 465): `python3 -c` is on the safe-list behind
# a TEXTUAL write-indicator deny-list. Idioms that write but match none of the
# deny-list patterns — and carry no shell redirect — pass BOTH predicates, so
# check-active-task.sh exits 0 before the no-active-task check, the task-is-active
# check, G-020 and the T-1730 focus-drift gate ever run.
#
# WHY MEASURE RATHER THAN READ THE REGEX. The failure direction is false NEGATIVE:
# every gate skipped, nothing written to the bypass log, indistinguishable from
# compliance after the fact. A defect whose signature is "no evidence" cannot be
# confirmed by finding no evidence. So each idiom is put to the REAL hook and the
# verdict recorded, and a negative result is only publishable if the controls below
# show the harness could have produced the other answer.
#
# THE PROBE NEVER EXECUTES THE IDIOMS. It hands each command STRING to the hook and
# reads the hook's verdict. Nothing is written by any command under test; the only
# writes are the sandbox fixtures this script creates itself.
#
# TWO CONTROLS, MEASURING DIFFERENT THINGS — this is the part T-381 taught me.
#
#   anti-vacuity control  a shell redirect must come back BLOCKED. Proves the
#                         harness reaches the gate at all. Without it "no bypass
#                         found" and "the hook was never invoked" are the same
#                         output. If this control does not block, the run reports
#                         COULD-NOT-MEASURE (exit 3) and NOT a clean bill.
#
#   positive control      an idiom the deny-list DOES catch (`shutil.`) must come
#                         back BLOCKED. Proves python3 -c is genuinely being
#                         inspected. Without it, "python3 is never checked at all"
#                         and "python3 is checked but these specific idioms slip"
#                         produce identical ALLOWED rows, and they are different
#                         findings with different fixes.
#
# The two AEF did not name are chosen from write forms that occur in THIS repo, so
# the census reports our exposure and not a translation of theirs.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
FW="$PROJ/.agentic-framework/bin/fw"
HOOK="$PROJ/.agentic-framework/agents/context/check-active-task.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t385-$$-$(date +%s)"

# AC: fail loudly if the hook cannot be located. A probe that silently measures
# nothing when its subject is missing is the exact shape of the T-381 false green.
if [ ! -f "$HOOK" ]; then
    echo "COULD-NOT-MEASURE: vendored hook not found at $HOOK" >&2
    exit 3
fi
HOOK_SHA=$(sha256sum "$HOOK" | cut -c1-12)

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

# ---------------------------------------------------------------- sandbox ----
build_sandbox() {
    mkdir -p "$SANDBOX/.context/working" "$SANDBOX/.tasks/active" "$SANDBOX/.tasks/completed"
    printf 'project: t385-sandbox\n' > "$SANDBOX/.framework.yaml"
    cat > "$SANDBOX/.context/working/focus.yaml" <<'YAML'
# Working Memory - Current Focus
current_task: null
priorities: []
blockers: []
pending_decisions: []
reminders: []
focus_session: S-PROBE
YAML
}

# ------------------------------------------------------------- hook probe ----
# Reached through the hook's own stdin `cwd` re-anchor (T-2463/T-2465), with the
# inherited path exports stripped: P-011 runs this from inside update-task.sh,
# which has already EXPORTED PROJECT_ROOT/TASKS_DIR/CONTEXT_DIR for the live repo,
# and exported vars beat cd. That is precisely how T-381's entry leg passed against
# a tree where the fixture did not exist.
hook_verdict() {  # <command string> -> "ALLOWED" | "BLOCKED:<reason line>"
    local cmd="$1" json err rc
    json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$cmd" "$SANDBOX")
    err=$(printf '%s' "$json" | env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR \
            -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
            CLAUDECODE=1 "$FW" hook check-active-task 2>&1 >/dev/null)
    rc=$?
    if [ $rc -eq 0 ]; then echo "ALLOWED"
    else echo "BLOCKED:$(printf '%s' "$err" | grep -m1 'BLOCKED' || printf '%s' "$err" | head -1)"
    fi
}

echo "=== T-385 python3 -c task-gate bypass census ==="
echo "subject : $HOOK"
echo "sha256  : $HOOK_SHA (first 12)"
build_sandbox
echo "sandbox : $SANDBOX  (current_task: null)"

# --------------------------------------------------------------- controls ----
echo
echo "--- controls (no finding is believed until both of these hold)"

ANTI=$(hook_verdict 'echo hello > /tmp/t385-probe-never-written.txt')
case "$ANTI" in
    BLOCKED*) ok "anti-vacuity: shell redirect is BLOCKED  [harness reaches the gate]" ;;
    *)        bad "anti-vacuity: shell redirect came back $ANTI"
              echo
              echo "COULD-NOT-MEASURE: the harness does not reach the gate." >&2
              echo "Every ALLOWED below would be meaningless. Refusing to report a census." >&2
              exit 3 ;;
esac

POS=$(hook_verdict 'python3 -c "import shutil; shutil.copy(a,b)"')
case "$POS" in
    BLOCKED*) ok "positive control: deny-listed python idiom (shutil.) is BLOCKED  [python3 -c IS inspected]" ;;
    *)        bad "positive control: shutil. came back $POS — python3 -c may not be inspected at all"
              echo "  NOTE: with this control failing, an ALLOWED row below does NOT mean" >&2
              echo "  'the deny-list has a hole' — it may mean the deny-list never runs." >&2 ;;
esac

# ----------------------------------------------------------------- census ----
# Column 3 records who named the idiom, so my contribution and theirs stay separable.
echo
echo "--- census (ALLOWED = reaches the interpreter with no active task, all gates skipped)"

BYPASSED=0
TOTAL=0
declare -a ROWS=()

probe() {  # <label> <source> <command>
    local label="$1" src="$2" cmd="$3" v
    v=$(hook_verdict "$cmd")
    TOTAL=$((TOTAL+1))
    if [ "$v" = "ALLOWED" ]; then
        BYPASSED=$((BYPASSED+1))
        printf '  %-9s %-26s %-8s %s\n' "ALLOWED" "$label" "$src" "<- gate skipped"
        ROWS+=("ALLOWED|$label|$src")
    else
        printf '  %-9s %-26s %-8s %s\n' "BLOCKED" "$label" "$src" ""
        ROWS+=("BLOCKED|$label|$src")
    fi
}

# The three AEF named at rail 465.
probe "pathlib.write_text"  "AEF" 'python3 -c "import pathlib; pathlib.Path(p).write_text(s)"'
probe "pathlib.write_bytes" "AEF" 'python3 -c "import pathlib; pathlib.Path(p).write_bytes(b)"'
probe "os.replace"          "AEF" 'python3 -c "import os; os.replace(a,b)"'

# Ours. Two of these four are grounded in this repo's own Python and two are not —
# stated separately, because "an idiom we actually use" and "an idiom that probes a
# boundary" are different arguments and only the first speaks to our exposure.
# Counts measured under tools/ lib/ web/, vendored tree excluded.
#
#   IN USE HERE:
#     subprocess.*      49 call sites. The deny-list names os.system and stops
#                       there, so the interpreter's OTHER exec surface is unguarded.
#     .unlink()         4 call sites. os.unlink is denied; Path.unlink is the same
#                       operation under a different name.
#   NOT IN USE HERE (0 sites) — these probe the predicate, not our habits:
#     open(p, "a")      boundary probe: the regex demands a quote then w, so the
#                       append mode of the very function it names walks through.
#     shell=True        see the note below — its value is precisely that nobody
#                       needs to be using it for it to defeat enumeration.
probe "subprocess.run"      "832" 'python3 -c "import subprocess; subprocess.run([cp, src, dst])"'
probe "open(...,'"'"'a'"'"')"       "832" 'python3 -c "print(x, file=open(p, \"a\"))"'
probe "pathlib.unlink"      "832" 'python3 -c "import pathlib; pathlib.Path(p).unlink()"'

# THE ROW THAT CHANGES THE SHAPE OF THE FINDING, not just its count.
# Every idiom above is one more name for a deny-list to learn. This one is not:
# it is a general shell, reached through the safe-listed interpreter, carrying no
# textual signature at all because the command lives in a variable. If it is
# ALLOWED then the deny-list cannot be closed by enumeration even in principle —
# one permitted entry re-admits every pattern the list denies, including the ones
# it already names. That is a different claim from "the list is missing entries",
# and it is the one that decides whether the fix is more patterns or no interpreter.
probe "subprocess shell=True" "832" 'python3 -c "import subprocess; subprocess.call(cmd, shell=True)"'

# ---------------------------------------------------------------- verdict ----
echo
echo "--- verdict"
echo "  subject     : vendored check-active-task.sh @ sha $HOOK_SHA (NOT 'the framework')"
echo "  bypassed    : $BYPASSED of $TOTAL probed idioms reached the interpreter with current_task: null"
echo "  controls    : anti-vacuity=$ANTI positive=${POS%%:*}"

if [ "$BYPASSED" -gt 0 ]; then
    echo "  reproduces  : YES — the OBS-200 class is present in our vendored tree"
else
    echo "  reproduces  : NO — with both controls green, this is a real negative"
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
