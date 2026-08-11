#!/bin/bash
# T-386 — does the focus-drift block message recommend a command the gate refuses?
#
# T-381 scoped `fw context focus` to active/. The focus-drift block still printed
# `fw context focus $TARGET_TASK` as remedy 1, and the drift target is a COMPLETED
# task in the common case (a follow-up commit naming a task that closed). So the
# gate's first recommendation was unreachable exactly when the gate fires most.
#
# TWO BRANCHES, BOTH MEASURED. Asserting only the completed branch would let a fix
# that suppresses remedy 1 unconditionally pass — that "fixes" the message by
# breaking the case that worked. The active branch is the control for the fix
# itself, not for the harness.
#
# ANTI-VACUITY IS SHARPER HERE THAN AN rc CHECK. Every earlier gate in this hook
# also exits 2 — no-active-task, task-not-active, G-020. A leg asserting "blocked"
# would be satisfied by any of them, from a sandbox where focus was never set, and
# would never have reached the drift gate at all. So the legs assert the FOCUS-DRIFT
# banner specifically, and one leg deliberately drives an earlier gate to show the
# two are distinguishable in this harness.
#
# TEETH BY MUTATION OF LIVE SOURCE, NOT A GIT REF. AEF's rail-463 report: their
# anti-vacuity leg used `git show HEAD~1:…`, they committed the fix one commit
# before the test, so HEAD~1 already carried it and the leg SKIPPED WHILE REPORTING
# ok. A git-ref teeth check has an expiry date set by the next commit and nothing
# announces it. This copies the live hook, strips the fix out of the copy, and
# asserts the copy goes back to recommending the refused command.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
FW="$PROJ/.agentic-framework/bin/fw"
HOOK="$PROJ/.agentic-framework/agents/context/check-active-task.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t386-$$-$(date +%s)"

[ -f "$HOOK" ] || { echo "COULD-NOT-MEASURE: hook not found at $HOOK" >&2; exit 3; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

mk_task() {  # <dir> <id> <status>
    mkdir -p "$SANDBOX/.tasks/$1"
    cat > "$SANDBOX/.tasks/$1/$2-t386-fixture.md" <<YAML
---
id: $2
name: "T-386 fixture ($1)"
description: fixture
status: $3
workflow_type: build
owner: agent
horizon: now
created: 2026-08-08T00:00:00Z
last_update: 2026-08-08T00:00:00Z
---

# $2

## Acceptance Criteria
### Agent
- [ ] fixture only
YAML
}

set_focus() {
    mkdir -p "$SANDBOX/.context/working"
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

build_sandbox() {
    mkdir -p "$SANDBOX/.tasks/active" "$SANDBOX/.tasks/completed"
    printf 'project: t386-sandbox\n' > "$SANDBOX/.framework.yaml"
    mk_task active    T-900 started-work    # the focused task
    mk_task active    T-902 started-work    # an ACTIVE drift target
    mk_task completed T-901 work-completed  # a COMPLETED drift target
    set_focus T-900
}

# Full stderr from the hook, for a chosen hook binary (so teeth can point at a copy).
drift_stderr() {  # <hook-path> <command>
    local hook="$1" cmd="$2" json
    json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$cmd" "$SANDBOX")
    printf '%s' "$json" | env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR \
        -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
        CLAUDECODE=1 PROJECT_ROOT="$SANDBOX" bash "$hook" 2>&1 >/dev/null
}

echo "=== T-386 focus-drift remedy reachability ==="
build_sandbox
echo "sandbox: $SANDBOX  (focus T-900; T-901 completed, T-902 active)"

# ------------------------------------------------------------ anti-vacuity ----
echo
echo "--- anti-vacuity: prove we reach the FOCUS-DRIFT gate, not some earlier one"

drift_out=$(drift_stderr "$HOOK" 'git commit -m "T-901: follow-up"')
if printf '%s' "$drift_out" | grep -q "FOCUS-DRIFT"; then
    ok "reached the focus-drift gate (banner present)"
else
    bad "did not reach the focus-drift gate"
    echo "COULD-NOT-MEASURE: legs below would be asserting about the wrong gate." >&2
    printf '%s\n' "$drift_out" | head -6 >&2
    exit 3
fi

# Drive an EARLIER gate to show the harness distinguishes them. Without this, a
# banner-matching leg proves only that the string exists somewhere in the output.
set_focus "null"
early_out=$(drift_stderr "$HOOK" 'git commit -m "T-901: follow-up"')
if printf '%s' "$early_out" | grep -q "FOCUS-DRIFT"; then
    bad "no-focus case ALSO shows FOCUS-DRIFT — the banner does not discriminate"
else
    ok "no-focus case takes a different branch (banner absent) — legs discriminate"
fi
set_focus T-900

# ------------------------------------------------------------------- legs ----
echo
echo "--- branches"

comp=$(drift_stderr "$HOOK" 'git commit -m "T-901: follow-up"')
if printf '%s' "$comp" | grep -q "NOT AVAILABLE"; then
    ok "completed target: remedy 1 marked NOT AVAILABLE"
else
    bad "completed target: remedy 1 still offered as workable"
fi
if printf '%s' "$comp" | grep -q "context focus T-901"; then
    bad "completed target: still prints the refused command 'context focus T-901'"
else
    ok "completed target: the refused command is not printed"
fi
# The reason must be present — an operator told 'not available' without why is left
# guessing whether the id is wrong, which is the failure the merged message caused.
if printf '%s' "$comp" | grep -q "completed"; then
    ok "completed target: reason stated (names 'completed')"
else
    bad "completed target: no reason given"
fi

act=$(drift_stderr "$HOOK" 'git commit -m "T-902: follow-up"')
if printf '%s' "$act" | grep -q "context focus T-902"; then
    ok "active target: remedy 1 unchanged (regression control)"
else
    bad "active target: remedy 1 lost — the fix broke the case that worked"
fi

# Bypass mechanisms must survive in BOTH branches.
for pair in "completed:$comp" "active:$act"; do
    label="${pair%%:*}"; body="${pair#*:}"
    if printf '%s' "$body" | grep -q -- "--switch-focus" && printf '%s' "$body" | grep -q "FW_SWITCH_FOCUS=1"; then
        ok "$label target: options 2 and 3 both present"
    else
        bad "$label target: a bypass mechanism went missing"
    fi
done

# ------------------------------------------------------------------ teeth ----
# Mutate a COPY of the live hook back to the pre-fix behaviour. No git ref, so no
# expiry: this re-derives the broken state from whatever the file says today.
echo
echo "--- teeth (mutate live source, assert the probe goes RED)"

MUT="$SANDBOX/mutant-check-active-task.sh"
python3 - "$HOOK" "$MUT" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
# Revert the T-386 branch to the unconditional remedy-1 print.
start = src.find('            _t386_completed=""')
end   = src.find('            echo "" >&2', src.find('if [ -n "$_t386_completed" ]'))
if start == -1 or end == -1:
    sys.stderr.write("MUTATION FAILED: T-386 branch not found — teeth cannot certify anything\n")
    sys.exit(4)
replacement = ('            echo "    1. Switch focus first:" >&2\n'
               '            echo "       $(_fw_cmd) context focus $TARGET_TASK" >&2\n')
open(sys.argv[2], 'w').write(src[:start] + replacement + src[end:])
PY
mut_rc=$?
if [ $mut_rc -ne 0 ]; then
    bad "teeth: could not build the mutant (rc=$mut_rc) — no teeth were demonstrated"
else
    # The mutant must still be a runnable hook. A mutant that dies on a syntax
    # error would "fail" the leg for a reason unrelated to the fix, certifying
    # teeth that do not exist.
    if bash -n "$MUT" 2>/dev/null; then
        ok "teeth: mutant parses (its failure below is behavioural, not syntactic)"
        mut_out=$(drift_stderr "$MUT" 'git commit -m "T-901: follow-up"')
        if printf '%s' "$mut_out" | grep -q "FOCUS-DRIFT"; then
            ok "teeth: mutant still reaches the drift gate"
        else
            bad "teeth: mutant does not reach the drift gate — leg below is vacuous"
        fi
        if printf '%s' "$mut_out" | grep -q "context focus T-901"; then
            ok "teeth: mutant RE-OFFERS the refused command — the leg has bite"
        else
            bad "teeth: mutant did not re-offer it; this probe would pass on a broken tree"
        fi
    else
        bad "teeth: mutant has a syntax error — cannot certify the leg"
    fi
fi

echo
echo "PASS=$PASS FAIL=$FAIL"

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${PASS:-0} + ${FAIL:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi

[ "$FAIL" -eq 0 ] || exit 1
exit 0
