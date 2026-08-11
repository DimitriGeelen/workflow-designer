#!/bin/bash
# T-381 — focus gate wedge: can it be ENTERED, and can it be EXITED?
#
# Two independent mechanisms, measured separately:
#
#   A (ENTRY)  `fw context focus <id>` validates with `find_task_file "$id"` —
#              UNSCOPED, so completed/ resolves. The gate reads it back with
#              `find_task_file "$CURRENT_TASK" active` — SCOPED. Writer accepts a
#              wider set than the reader requires. PL-020 class: validating that a
#              value EXISTS is not validating that its reader can USE it.
#
#   B (EXIT)   check-active-task.sh tests has_bash_write_pattern FIRST and the
#              T-2052 bootstrap exemption is an `elif`. IF a bootstrap command
#              carries a write pattern it would skip the exemption — i.e. the
#              remedy the block message prints would be blocked by the block.
#              THIS IS A HYPOTHESIS READ OFF THE SOURCE, NOT AN OBSERVATION.
#              The legs below report it either way; "exemption reachable, the
#              carried claim was wrong" is a valid and publishable outcome.
#
# Isolation: every leg runs against a throwaway project under the scratchpad,
# reached through the hook's own stdin `cwd` re-anchor (T-2463/T-2465). The live
# repo's focus.yaml is never written. Nothing is deleted — each run gets a fresh
# directory — because a cleanup that silently no-ops is how a probe starts
# measuring the wrong tree (cf. unverified-safeguards).

set -uo pipefail

PROJ=/opt/832-Workflow-designer
FW="$PROJ/.agentic-framework/bin/fw"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t381-$$-$(date +%s)"

# Run the fw CLI so it resolves the SANDBOX, not whatever project the caller is in.
# P-011 executes this probe from inside update-task.sh, which has already sourced
# lib/paths.sh and EXPORTED PROJECT_ROOT/TASKS_DIR/CONTEXT_DIR for the live repo.
# Those win over cwd, so `cd $SANDBOX && fw context focus T-901` looked up T-901 in
# /opt/832-Workflow-designer and reported "Task not found".
#
# That did not merely fail — it PASSED THE ENTRY LEG FOR THE WRONG REASON. The leg
# asserts a non-zero exit, and "task does not exist anywhere" exits non-zero exactly
# like "task exists but is completed". Only the two message-content legs went red.
# A bare rc check would have certified the fix from a tree where the fixture was
# invisible. Hence: legs assert WHY the refusal happened, not just THAT it did.
fw_sb() {  # run fw against the sandbox with inherited path vars stripped
    (cd "$SANDBOX" && env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR \
        -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT "$FW" "$@")
}

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

# ---------------------------------------------------------------- sandbox ----
mk_task() {  # <dir> <id> <status>
    local dir="$1" id="$2" st="$3"
    mkdir -p "$SANDBOX/.tasks/$dir"
    cat > "$SANDBOX/.tasks/$dir/$id-probe-fixture.md" <<YAML
---
id: $id
name: "probe fixture ($dir)"
description: T-381 fixture
status: $st
workflow_type: build
owner: agent
horizon: now
created: 2026-08-08T00:00:00Z
last_update: 2026-08-08T00:00:00Z
---

# $id

## Acceptance Criteria
### Agent
- [ ] fixture only, never completed
YAML
}

build_sandbox() {
    mkdir -p "$SANDBOX/.context/working" "$SANDBOX/.tasks/active" "$SANDBOX/.tasks/completed"
    printf 'project: t381-sandbox\n' > "$SANDBOX/.framework.yaml"
    mk_task active    T-900 started-work
    mk_task completed T-901 work-completed
}

set_focus_raw() {  # writes focus.yaml directly — sets up the STATE under test,
                   # deliberately not via do_focus, so leg A can measure do_focus
                   # itself without depending on it.
    cat > "$SANDBOX/.context/working/focus.yaml" <<YAML
# Working Memory - Current Focus
current_task: $1
priorities: []
blockers: []
pending_decisions: []
reminders: []
focus_session: S-PROBE
YAML
}

# ------------------------------------------------------------- hook probe ----
# Returns: prints "ALLOWED" or "BLOCKED:<first stderr line>".
hook_verdict() {  # <tool_name> <command-or-path>
    local tool="$1" arg="$2" json err rc
    if [ "$tool" = "Bash" ]; then
        json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$arg" "$SANDBOX")
    else
        json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":sys.argv[1]},"cwd":sys.argv[2]}))' "$arg" "$SANDBOX")
    fi
    err=$(printf '%s' "$json" | CLAUDECODE=1 "$FW" hook check-active-task 2>&1 >/dev/null)
    rc=$?
    if [ $rc -eq 0 ]; then echo "ALLOWED"
    else echo "BLOCKED:$(printf '%s' "$err" | grep -m1 'BLOCKED' || printf '%s' "$err" | head -1)"
    fi
}

expect() {  # <label> <expected ALLOWED|BLOCKED> <verdict>
    local label="$1" want="$2" got="$3"
    case "$got" in
        "$want"*) ok  "$label  [$got]" ;;
        *)        bad "$label  want=$want got=$got" ;;
    esac
}

echo "=== T-381 focus gate wedge ==="
build_sandbox
echo "sandbox: $SANDBOX"

# ------------------------------------------------------------------ teeth ----
# Before any finding is believed the harness must show it can emit BOTH verdicts.
# A harness that can only say BLOCKED would "confirm" the wedge on a fixed tree.
echo
echo "--- teeth (harness must produce both verdicts before any leg is believed)"
set_focus_raw T-900
t_allow=$(hook_verdict Bash "ls -la")
expect "teeth: sane focus + safe cmd -> ALLOWED" ALLOWED "$t_allow"
set_focus_raw "null"
t_block=$(hook_verdict Bash "touch \$SANDBOX/x.txt")
expect "teeth: no focus + gated cmd -> BLOCKED" BLOCKED "$t_block"

# ------------------------------------------------- A: can the wedge be ENTERED
echo
echo "--- A: entry (does the writer accept a completed id?)"
set_focus_raw "null"
a_out=$(fw_sb context focus T-901 2>&1); a_rc=$?
if [ $a_rc -ne 0 ]; then
    ok "A: writer REJECTS a completed id (rc=$a_rc)"
    case "$a_out" in
        *"completed"*) ok "A: refusal names the reason (completed)" ;;
        *)             bad "A: refusal message does not say 'completed': $(printf '%s' "$a_out" | head -1)" ;;
    esac
    case "$a_out" in
        *"work-on"*) ok "A: refusal names the recovery command (work-on)" ;;
        *)           bad "A: refusal does not name a recovery command" ;;
    esac
else
    bad "A: writer ACCEPTED completed T-901 (rc=0) — wedge is enterable"
fi
# The writer must still accept a genuinely active id — a refusal that refuses
# everything would pass the leg above while breaking the command outright.
set_focus_raw "null"
if fw_sb context focus T-900 >/dev/null 2>&1; then
    ok "A: writer still ACCEPTS an active id (not a blanket refusal)"
else
    bad "A: writer rejects an ACTIVE id — fix over-reached"
fi
# whichever way the writer behaves, force the wedged STATE for the exit legs
set_focus_raw T-901
w=$(hook_verdict Bash "touch \$SANDBOX/x.txt")
expect "A: wedged state blocks a gated command" BLOCKED "$w"
case "$w" in
    *"not active"*) ok "A: block message names the real cause (not active)" ;;
    *)              bad "A: block message does not say 'not active': $w" ;;
esac

# --------------------------------------------------- B: can the wedge be EXITED
# The block message prints these as the unblock path. Measure all four forms.
echo
echo "--- B: exit (are the PRINTED remedies themselves allowed while wedged?)"
set_focus_raw T-901
declare -A FORMS=(
  ["bare context focus"]="$FW context focus T-900"
  ["bare work-on"]="$FW work-on T-900"
  ["cd&& context focus (CLAUDE.md mandated form)"]="cd $SANDBOX && $FW context focus T-900"
  ["cd&& work-on (CLAUDE.md mandated form)"]="cd $SANDBOX && $FW work-on T-900"
)
for k in "bare context focus" "bare work-on" \
         "cd&& context focus (CLAUDE.md mandated form)" "cd&& work-on (CLAUDE.md mandated form)"; do
    expect "B: $k" ALLOWED "$(hook_verdict Bash "${FORMS[$k]}")"
done

# The precise ordering question: a bootstrap verb carrying a write pattern.
# `>` is the write pattern; the command is still purely a bootstrap invocation.
echo
echo "--- B2: bootstrap verb + write pattern (the elif-ordering question)"
# REPORTED, NOT SCORED. The B legs above settle the question this task exists to
# answer: every remedy the block message actually prints is allowed. B2 probes a
# narrower case — a bootstrap verb that ALSO redirects to a file. It is blocked,
# and that is defensible rather than broken: a redirect writes a file, and "writes
# need a task" is the rule the precheck is there to enforce. Scoring it PASS by
# rewriting the expectation to match what was observed would be fitting the test
# to the tree; scoring it FAIL would claim a defect this task did not establish.
# So it prints, and goes to the observation register for a separate decision.
b2=$(hook_verdict Bash "$FW context focus T-900 > $SANDBOX/focus.log")
echo "  OBSERVED  bootstrap verb + '>' redirect -> $b2"
echo "            (not scored — see comment; filed as an observation, not a defect)"

# --------------------------------------------------------------- summary -----
echo
echo "=== summary ==="

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${PASS:-0} + ${FAIL:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi

echo "passed: $PASS   failed: $FAIL"
[ $FAIL -eq 0 ]
