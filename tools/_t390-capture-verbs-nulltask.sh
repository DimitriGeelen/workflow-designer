#!/bin/bash
# T-390 — are the knowledge-capture verbs reachable with a NULL current_task?
#
# CLAIM UNDER TEST: `fw note` and `fw context add-learning` were BLOCKED by
# check-active-task.sh when focus is null. That state is created by
# `--status work-completed` (it nulls focus and moves the task to completed/), and
# update-task.sh prints a LEARNING PROMPT at that exact moment — so the framework
# asks for a learning in the one state where its own gate refuses the command.
#
# MEASURES THE REAL VENDORED HOOK, not a copy: the verdict comes from invoking
# `fw hook check-active-task` with a synthetic PreToolUse payload, the same entry
# point Claude Code uses. Reading the case statement would not prove reachability —
# the sub-verb is extracted by awk positional index, so a correct-looking case arm
# can still be unreachable for a command shape that shifts the position.
#
# TWO CONTROLS, MEASURING DIFFERENT THINGS (T-381 / T-385 lineage):
#
#   anti-vacuity   a command that MUST stay blocked with null focus (`rm -rf`)
#                  comes back BLOCKED. Proves the harness reaches the gate. Without
#                  it, "everything is allowed now" and "the hook never ran" are the
#                  same ALLOWED row — and this task WIDENS an allowlist, so a hook
#                  that silently stopped running would look exactly like success.
#
#   positive       a non-capture `fw` sub-verb that was never exempt (`fw config
#                  set`) stays BLOCKED. Proves the change is verb-scoped and did not
#                  degrade into a blanket `fw` allowance — the failure mode that
#                  would turn a targeted fix into a hole.
#
# Exit 3 = COULD-NOT-MEASURE. A probe that cannot reach its subject must not emit a
# census; "0 failures" and "0 tests that ran" are otherwise the same number.
set -uo pipefail

PROJ=/opt/832-Workflow-designer
FW="$PROJ/.agentic-framework/bin/fw"
HOOK="$PROJ/.agentic-framework/agents/context/check-active-task.sh"
LIB="$PROJ/.agentic-framework/agents/context/lib/safe-commands.sh"
SCRATCH="${TMPDIR:-/tmp}"
SANDBOX="$SCRATCH/t390-$$"

[ -f "$HOOK" ] || { echo "COULD-NOT-MEASURE: hook not found at $HOOK" >&2; exit 3; }
[ -f "$LIB" ]  || { echo "COULD-NOT-MEASURE: safe-commands lib not found at $LIB" >&2; exit 3; }
command -v python3 >/dev/null 2>&1 || { echo "COULD-NOT-MEASURE: no python3" >&2; exit 3; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

# A sandbox whose focus.yaml has current_task: null — the state under test.
mkdir -p "$SANDBOX/.context/working" "$SANDBOX/.tasks/active" "$SANDBOX/.tasks/completed"
cat > "$SANDBOX/.context/working/focus.yaml" <<'EOF'
current_task: null
priorities: []
EOF
trap 'rm -rf "$SANDBOX"' EXIT

# Ask the REAL hook for a verdict on a command string. Nothing under test is run.
# Path vars are unset so the hook resolves the sandbox rather than the live repo
# (exported vars beat cd — the T-381 trap).
hook_verdict() { # <command string> [hook_path] -> ALLOWED | BLOCKED:<line>
    local cmd="$1" hook_override="${2:-}" json err rc
    json=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$cmd" "$SANDBOX")
    if [ -n "$hook_override" ]; then
        err=$(printf '%s' "$json" | env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR \
                -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
                CLAUDECODE=1 PROJECT_ROOT="$SANDBOX" bash "$hook_override" 2>&1 >/dev/null)
    else
        err=$(printf '%s' "$json" | env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR \
                -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
                CLAUDECODE=1 "$FW" hook check-active-task 2>&1 >/dev/null)
    fi
    rc=$?
    if [ $rc -eq 0 ]; then echo "ALLOWED"
    else echo "BLOCKED:$(printf '%s' "$err" | grep -m1 'BLOCKED' || printf '%s' "$err" | head -1)"
    fi
}

echo "=== T-390 capture-verbs-under-null-task probe ==="
echo "    hook: $(sha256sum "$HOOK" | cut -c1-12)  lib: $(sha256sum "$LIB" | cut -c1-12)"
echo

# ── CONTROLS FIRST — nothing below is publishable unless both are green ────────
v="$(hook_verdict 'rm -rf /tmp/something')"
if [[ "$v" == BLOCKED* ]]; then
    ok "anti-vacuity control: a must-block command IS blocked (harness reaches the gate)"
else
    echo "  CONTROL FAILED: rm -rf came back $v — the gate is not being reached."
    echo "COULD-NOT-MEASURE: refusing to report an allowlist census from an unreached gate" >&2
    exit 3
fi

v="$(hook_verdict 'fw config set PORT 9999')"
if [[ "$v" == BLOCKED* ]]; then
    ok "positive control: a non-capture fw sub-verb stays BLOCKED (exemption is verb-scoped)"
else
    echo "  CONTROL FAILED: 'fw config set' came back $v — the fix widened into a blanket fw allowance."
    echo "COULD-NOT-MEASURE: a verb-scoped claim cannot be reported from a blanket allowance" >&2
    exit 3
fi
echo

# ── THE ROWS ──────────────────────────────────────────────────────────────────
for cmd in \
    'fw note "observed something"' \
    'fw context add-learning "a learning" --task T-390' \
    'fw context add-pattern failure "a pattern" --task T-390' \
    'fw context add-decision "a decision" --task T-390' \
    'fw context generate-episodic T-390' \
    'fw handover' \
    'bin/fw note "prefixed form"' \
; do
    v="$(hook_verdict "$cmd")"
    if [ "$v" = "ALLOWED" ]; then ok "reachable with null focus: $cmd"
    else bad "STILL BLOCKED with null focus: $cmd -> $v"; fi
done
echo

# ── UNCHANGED BEHAVIOUR — the exemption must not leak sideways ────────────────
for cmd in \
    'fw context focus T-001' \
    'fw context status' \
; do
    v="$(hook_verdict "$cmd")"
    if [ "$v" = "ALLOWED" ]; then ok "pre-existing exemption intact: $cmd"
    else bad "REGRESSION — was allowed before, now blocked: $cmd -> $v"; fi
done
echo

# ── TEETH: mutate LIVE source, never a git ref ────────────────────────────────
# A git-ref mutant has an expiry date set by the next commit and nothing announces
# when it goes inert (AEF rail 467). These are derived from the current file at run
# time, so they cannot go stale.
MUTDIR="$SANDBOX/mut"; mkdir -p "$MUTDIR/lib"
cp "$HOOK" "$MUTDIR/check-active-task.sh"
sed 's/^                        add-learning|add-pattern|add-decision|generate-episodic)/                        add-learning-DISABLED)/' \
    "$LIB" > "$MUTDIR/lib/safe-commands.sh"

if ! grep -q 'add-learning-DISABLED' "$MUTDIR/lib/safe-commands.sh"; then
    bad "TEETH mutant did not apply — the sed target moved; teeth are inert"
else
    v="$(hook_verdict 'fw context add-learning "x" --task T-390' "$MUTDIR/check-active-task.sh")"
    if [[ "$v" == BLOCKED* ]]; then
        ok "TEETH: removing the case arm DOES re-block add-learning (the arm is load-bearing)"
    else
        bad "TEETH: add-learning still ALLOWED with its case arm removed ($v) — the rows above prove nothing"
    fi
fi

echo

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${PASS:-0} + ${FAIL:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
