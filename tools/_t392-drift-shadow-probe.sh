#!/bin/bash
# T-392 — does the safe-list early return shadow the focus-drift gate?
#
# WHAT THIS MEASURES
#   check-active-task.sh has two independent questions:
#       "does this need an active task?"     -> SESSION state   (needs focus.yaml)
#       "is it attributed to the right task?" -> COMMAND string  (needs nothing)
#   The safe-list fast path answers the first and `exit 0`s at ~line 95-97.
#   The focus-drift gate answers the second at ~line 299. T-390 added the capture
#   verbs (`fw context add-*`, `note`, `handover`) to is_bash_safe_command, so any
#   command matching them now returns at 97 and the gate at 299 is UNREACHABLE for
#   drift pattern 2. The gate did not fail — it stopped being CONSULTED, which is
#   silent in exactly the way a gate that finds nothing is silent.
#
# HOW IT DRIVES THE HOOK
#   Not by touching the live focus. check-active-task.sh:56 calls
#   fw_reanchor_from_hook_stdin, which re-anchors PROJECT_ROOT to the top-level
#   `cwd` of the stdin payload (paths.sh:95-113, re-anchors to the nearest
#   ancestor holding .tasks/ or .framework.yaml). We hand it a sandbox. The live
#   .context/working/focus.yaml is never read and never written.
#
# THE CONTROL THAT MAKES THE REST MEAN ANYTHING (leg 0)
#   If that re-anchor silently no-ops, the hook reads the REAL focus and every
#   result below describes the live repo instead of the fixture. A leg asserting
#   only "it blocked" would pass just as happily in that world. So leg 0 requires
#   the block message to NAME BOTH fixture ids (T-9001 focused, T-9002 targeted).
#   Real focus is a T-3xx id, so a leaked read cannot produce that string.
#   Exits 3 (not 1) when leg 0 fails: "measured nothing" is a different outcome
#   from "measured a defect", and collapsing them is the bug this task is about.
#
# Exit: 0 all legs as expected | 1 a leg disagreed | 3 probe could not measure

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.agentic-framework/agents/context/check-active-task.sh"
[ -f "$HOOK" ] || { echo "PROBE ABORT: hook not found at $HOOK"; exit 3; }

SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/t392-XXXXXX")
BOX="$SCRATCH/box"
# The mutant must live BESIDE the original: check-active-task.sh:29-31 derives
# FRAMEWORK_ROOT from its own SCRIPT_DIR and sources lib/paths.sh relative to it,
# so a mutant anywhere else dies at line 31 before reaching any gate — and a leg
# asserting "no block appeared" would then pass for a reason that has nothing to
# do with the defect. Learned the expensive way in T-391; AEF hit the identical
# trap from the other direction (rail 482 §5).
MUT="$(dirname "$HOOK")/.t392-mutant-$$.sh"
trap 'rm -rf "$SCRATCH"; rm -f "$MUT"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n     expected: %s\n     got rc=%s: %s\n' "$1" "$2" "$RC" "$(echo "$OUT" | tr '\n' ' ' | cut -c1-220)"; }

# --- fixture -----------------------------------------------------------------
mkdir -p "$BOX/.tasks/active" "$BOX/.context/working"
cat > "$BOX/.tasks/active/T-9001-probe-fixture.md" <<'EOF'
---
id: T-9001
name: "probe fixture — focused task"
status: started-work
workflow_type: build
owner: agent
horizon: now
---
# T-9001
EOF
cat > "$BOX/.tasks/active/T-9002-probe-target.md" <<'EOF'
---
id: T-9002
name: "probe fixture — drift target"
status: started-work
workflow_type: build
owner: agent
horizon: now
---
# T-9002
EOF
echo 'session_id: S-PROBE-T392' > "$BOX/.context/working/session.yaml"

set_focus() { # <task-id|null>
    if [ "$1" = "null" ]; then
        printf 'current_task: null\nfocus_session: S-PROBE-T392\n' > "$BOX/.context/working/focus.yaml"
    else
        printf 'current_task: %s\nfocus_session: S-PROBE-T392\n' "$1" > "$BOX/.context/working/focus.yaml"
    fi
}

# Sets OUT and RC in the CALLER's scope. Deliberately NOT `OUT=$(run_hook ...)`:
# command substitution forks a subshell, so an RC assigned inside never reaches
# the parent — that defect passed unnoticed in the T-391 probe while a
# neighbouring leg stayed green.
run_hook() { # <command-string> [hook-override]
    local cmd="$1" hook="${2:-$HOOK}"
    python3 -c "
import json,sys
print(json.dumps({'tool_name':'Bash','tool_input':{'command':sys.argv[1]},'cwd':sys.argv[2]}))
" "$cmd" "$BOX" > "$SCRATCH/in.json"
    env -u TASKS_DIR -u CONTEXT_DIR -u _FW_PATHS_LOADED -u _FW_PATHS_DERIVED_BY \
        CLAUDECODE=1 bash "$hook" < "$SCRATCH/in.json" > "$SCRATCH/out.txt" 2>&1
    RC=$?
    OUT=$(cat "$SCRATCH/out.txt")
}

echo "=== T-392 drift-shadow probe ==="
echo "hook: $HOOK"
echo

# --- leg 0: ANTI-VACUITY — is the fixture even visible? ----------------------
echo "-- leg 0: fixture visibility (probe self-check) --"
set_focus T-9001
run_hook 'fw task update T-9002 --status issues'
if [ "$RC" -eq 2 ] && echo "$OUT" | grep -q "T-9001" && echo "$OUT" | grep -q "T-9002"; then
    ok "drift pattern 1 blocks AND the message names both fixture ids (re-anchor works)"
else
    echo "  PROBE CANNOT MEASURE: expected rc=2 naming T-9001 and T-9002."
    echo "  got rc=$RC: $(echo "$OUT" | tr '\n' ' ' | cut -c1-300)"
    echo
    echo "  Every leg below would be describing the live repo, not the fixture."
    echo "  Reporting UNMEASURED rather than a result. (exit 3)"
    exit 3
fi
echo

# --- legs 1-3: which drift patterns actually reach the gate? -----------------
echo "-- legs 1-3: gate reachability per drift pattern (focus=T-9001, target=T-9002) --"

run_hook 'fw task update T-9002 --status issues'
[ "$RC" -eq 2 ] && ok "pattern 1 (fw task update T-9002) REACHES the gate -> blocked" \
                || bad "pattern 1 (fw task update T-9002)" "rc=2 (blocked)"

run_hook 'git commit -m "T-9002: unrelated work"'
[ "$RC" -eq 2 ] && ok "pattern 3 (git commit T-9002:) REACHES the gate -> blocked" \
                || bad "pattern 3 (git commit T-9002:)" "rc=2 (blocked)"

# THE DEFECT. Pre-fix this is rc=0 — the command names a different task than the
# focused one and sails through, because is_bash_safe_command matched first.
run_hook 'fw context add-learning "x" --task T-9002'
if [ "$RC" -eq 0 ]; then
    printf '  BUG  pattern 2 (fw context add-* --task T-9002) is SHADOWED -> allowed (rc=0)\n'
    printf '       the drift gate never runs; T-390 safe-listed the verb at ~line 95-97\n'
    SHADOWED=1
else
    printf '  ok   pattern 2 (fw context add-* --task T-9002) REACHES the gate -> blocked\n'
    PASS=$((PASS+1)); SHADOWED=0
fi
echo

# --- leg 4: the T-390 deadlock must STAY fixed ------------------------------
echo "-- leg 4: null focus, capture verbs still allowed (T-390 must not regress) --"
set_focus null
for c in 'fw note "an observation"' \
         'fw handover' \
         'fw context add-learning "no task id here"' \
         'fw context add-pattern failure "x"'; do
    run_hook "$c"
    [ "$RC" -eq 0 ] && ok "null focus: [$c] allowed" \
                    || bad "null focus: [$c]" "rc=0 (allowed — deadlock must stay fixed)"
done
echo

# --- leg 5: over-correction control -----------------------------------------
# A fix that made every safe command consult focus would show up here.
echo "-- leg 5: task-agnostic safe verbs keep the fast path (focus=T-9001) --"
set_focus T-9001
for c in 'fw doctor' 'git status' 'ls -la' 'fw context status'; do
    run_hook "$c"
    [ "$RC" -eq 0 ] && ok "no-task-named: [$c] still exits early" \
                    || bad "no-task-named: [$c]" "rc=0 (must never consult focus)"
done
echo

# --- summary -----------------------------------------------------------------
echo "=== summary ==="
echo "  legs as expected: $PASS"
echo "  legs disagreeing: $FAIL"
if [ "${SHADOWED:-0}" -eq 1 ]; then
    echo
    echo "  VERDICT: shadowing REPRODUCED on this copy."
    echo "  Patterns 1 and 3 reach the focus-drift gate; pattern 2 does not."
    echo "  The gate is intact — nothing reaches it."
fi
[ "$FAIL" -eq 0 ] || exit 1
exit 0
