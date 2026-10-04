#!/bin/bash
# T-629 — are G-067's three printed remedies reachable from the state that prints them?
#
# The residual T-628 filed. G-067 (inception open-questions readiness) sits ~25 lines
# above G-020 in the same hook and prints THREE remedies. Two are task-file edits — the
# exact shape T-628 proved unreachable from the shell, because the `.tasks/*` exemption
# is a FILE_PATH test and a Bash call carries no file path.
#
# THE SECOND QUESTION, WHICH T-628 COULD NOT ASK. G-020's remedy 2 converts a build task
# to an inception. If that conversion lands the agent in a G-067 block whose own remedies
# are also unreachable, G-020's escape does not lead out — it leads one gate deeper. The
# grandfather leg below is what answers it: a converted task carries no `## Open
# Questions` section, and G-067 only fires when that section exists, so the hand-off is
# clean. That is asserted here rather than reasoned about, because it is exactly the kind
# of claim that is true until someone makes the conversion template-aware.
#
# ON REMEDY 3. `FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT=1` is a Tier-2 bypass and is not
# the agent's to use (CLAUDE.md §Autonomous Mode Boundaries). Measuring what the gate does
# with it, in a throwaway sandbox against fixture tasks, is a statement about the gate —
# not an authorisation taken in this tree. No real task is bypassed by this file, and the
# leg deliberately asserts the NOTE the hook prints rather than any effect on real state.
#
# HARNESS NOTES INHERITED FROM T-628 (PL-267), both load-bearing:
#   * The mutant is staged BESIDE the original. The hook derives FRAMEWORK_ROOT from its
#     own SCRIPT_DIR; a copy elsewhere loses find_task_file and dies at P-002 well above
#     G-067, so a sandbox-staged mutant would test nothing while looking red for the
#     right-sounding reason.
#   * The teeth are guarded by a reachability leg. A mutant that dies early and a mutant
#     that reaches the gate and behaves correctly produce the same red otherwise.
#
# Written with the Write tool, not a heredoc: the fixture ids are task-id-shaped and the
# focus-drift gate in the hook under test matches them in the command text (PL-164).

set -uo pipefail

PROJ=/opt/832-Workflow-designer
HOOK="$PROJ/.agentic-framework/agents/context/check-active-task.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t629-$$-$(date +%s)"
MUT="$(dirname "$HOOK")/.t629-mutant-$$.sh"
trap 'rm -f "$MUT" 2>/dev/null || true; rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM

[ -f "$HOOK" ] || { echo "COULD-NOT-MEASURE: hook not found at $HOOK" >&2; exit 3; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

UNFILED=T-910    # inception, has ## Open Questions, zero IW entries  -> G-067 fires
FILED=T-911      # inception, has ## Open Questions with one IW entry -> must NOT fire
LEGACY=T-912     # inception, NO ## Open Questions section at all     -> grandfathered

mk_task() {  # <id> <unfiled|filed|legacy>
    mkdir -p "$SANDBOX/.tasks/active"
    local oq=""
    case "$2" in
        unfiled) oq=$'## Open Questions\n\n<!-- template guidance that must not count as a filed question -->\n' ;;
        filed)   oq=$'## Open Questions\n\n- **IW-1: does the gate see a filed question?**\n  confidence: 2\n' ;;
        legacy)  oq="" ;;
    esac
    cat > "$SANDBOX/.tasks/active/$1-t629-fixture.md" <<YAML
---
id: $1
name: "T-629 fixture ($2)"
description: fixture
status: started-work
workflow_type: inception
owner: agent
horizon: now
created: 2026-08-29T00:00:00Z
last_update: 2026-08-29T00:00:00Z
---

# $1

## Acceptance Criteria
### Agent
- [ ] a real, scoped criterion

$oq
## Verification
# Present so the AC range terminates on a following heading (T-628: without one the
# range runs to EOF and the delete-last-line step removes the only AC).
YAML
}

set_focus() {
    mkdir -p "$SANDBOX/.context/working"
    printf 'current_task: %s\npriorities: []\n' "$1" > "$SANDBOX/.context/working/focus.yaml"
}

build_sandbox() {
    mkdir -p "$SANDBOX/.tasks/active"
    printf 'project: t629-sandbox\n' > "$SANDBOX/.framework.yaml"
    mk_task "$UNFILED" unfiled
    mk_task "$FILED"   filed
    mk_task "$LEGACY"  legacy
    set_focus "$UNFILED"
}

# rc + stderr from a chosen hook binary, for a Bash tool call. Extra env may be prefixed.
run_hook() {  # <hook-path> <command> [VAR=VAL ...]   -> sets RC, OUT
    local hook="$1" cmd="$2"; shift 2
    local json
    json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$cmd" "$SANDBOX")
    OUT=$(printf '%s' "$json" | env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR \
        -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
        CLAUDECODE=1 PROJECT_ROOT="$SANDBOX" "$@" bash "$hook" 2>&1 >/dev/null)
    RC=$?
}

# Same, for the Edit TOOL (T-1039). Remedies 1 and 2 are task-file edits, and the Edit tool is
# the surface on which the gate exempts the task file (a FILE_PATH test). The Bash runner
# above cannot exercise that, which is why it only ever saw the refusals.
run_edit_hook() {  # <hook-path> <file-path>   -> sets RC, OUT
    local hook="$1" fp="$2" json
    json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":sys.argv[1],"old_string":"a","new_string":"b"},"cwd":sys.argv[2]}))' "$fp" "$SANDBOX")
    OUT=$(printf '%s' "$json" | env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR \
        -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
        CLAUDECODE=1 PROJECT_ROOT="$SANDBOX" bash "$hook" 2>&1 >/dev/null)
    RC=$?
}

echo "=== T-629 G-067 remedy reachability ==="
build_sandbox
echo "sandbox: $SANDBOX  ($UNFILED unfiled; $FILED filed; $LEGACY no-section)"

# ------------------------------------------------------------ anti-vacuity ----
echo
echo "--- anti-vacuity: prove we reach G-067 specifically"

run_hook "$HOOK" 'echo probe > /tmp/t629.marker'
if printf '%s' "$OUT" | grep -q 'G-067'; then
    ok "reached G-067 (banner names it)"
else
    bad "did not reach G-067"
    echo "COULD-NOT-MEASURE: every leg below would be asserting about the wrong gate." >&2
    printf '%s\n' "$OUT" | head -10 >&2
    exit 3
fi

set_focus "$FILED"
run_hook "$HOOK" 'echo probe > /tmp/t629.marker'
if printf '%s' "$OUT" | grep -q 'G-067'; then
    bad "a FILED question still shows G-067 — the banner does not discriminate"
else
    ok "a filed IW entry clears the gate — the banner discriminates"
fi

# ------------------------------------------------------------- the hand-off ----
echo
echo "--- the hand-off: does G-020's remedy 2 land you inside G-067?"

# A task converted from build to inception carries no '## Open Questions' section, and
# G-067 fires only when that section exists. If this leg ever goes red, G-020's escape
# has started leading one gate deeper instead of out.
set_focus "$LEGACY"
run_hook "$HOOK" 'echo probe > /tmp/t629.marker'
if printf '%s' "$OUT" | grep -q 'G-067'; then
    bad "an inception with NO Open Questions section is blocked — G-020's remedy leads into G-067"
else
    ok "no Open Questions section is grandfathered — G-020's remedy 2 leads OUT, not deeper"
fi
set_focus "$UNFILED"

# ------------------------------------------------------- the printed remedies ----
echo
echo "--- the three printed remedies, verbatim, from inside the firing state"

# Remedy 1: add an IW entry to the task file. Remedy 2: remove the section. Both are
# task-file edits, and both are stated by the message without naming a surface.
run_hook "$HOOK" "sed -i 's/^## Open Questions/## Open Questions\\n- **IW-1: x**/' .tasks/active/$UNFILED-t629-fixture.md"
if printf '%s' "$OUT" | grep -q 'G-067'; then
    ok "remedy 1 via shell is REFUSED (expected — no FILE_PATH, exemption cannot apply)"
else
    bad "remedy 1 via shell was allowed (rc=$RC) — the surface analysis is wrong"
fi

run_hook "$HOOK" "sed -i '/^## Open Questions/d' .tasks/active/$UNFILED-t629-fixture.md"
if printf '%s' "$OUT" | grep -q 'G-067'; then
    ok "remedy 2 via shell is REFUSED (expected — same shape)"
else
    bad "remedy 2 via shell was allowed (rc=$RC) — the surface analysis is wrong"
fi

# Remedy 3 is the only one the message states with an explicit mechanism. Asserted on the
# NOTE the hook prints, not on rc: rc 0 is also what a hook that died early returns.
run_hook "$HOOK" 'echo probe > /tmp/t629.marker' FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT=1
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q 'FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT'; then
    ok "remedy 3 (Tier-2 override) is reachable and announces itself"
else
    bad "remedy 3 did not take effect (rc=$RC) — the only remedy with a stated mechanism"
fi

echo
echo "--- the remedies the message names actually work (T-1039: through the Edit tool)"

TASKFILE="$SANDBOX/.tasks/active/$UNFILED-t629-fixture.md"
run_edit_hook "$HOOK" "$TASKFILE"
if [ "$RC" -eq 0 ] && ! printf '%s' "$OUT" | grep -q 'G-067'; then
    ok "remedies 1 and 2 (edit the task file) are reachable through the Edit tool (rc=0)"
else
    bad "the Edit tool is refused on the task file the message tells you to edit (rc=$RC)"
fi
run_edit_hook "$HOOK" "$SANDBOX/src/app.py"
if printf '%s' "$OUT" | grep -q 'G-067'; then
    ok "control: the same Edit tool on a SOURCE file is still refused by G-067 — the exemption is path-scoped"
else
    bad "control: Edit on a source file is not refused by G-067 (rc=$RC) — the gate is not firing"
fi

echo
echo "--- the message itself"

run_hook "$HOOK" 'echo probe > /tmp/t629.marker'
MISSING=""
printf '%s' "$OUT" | grep -q "Edit $UNFILED and add at least one entry under '## Open Questions'" || MISSING="$MISSING remedy-1"
printf '%s' "$OUT" | grep -q 'IW-1:'                                                             || MISSING="$MISSING entry-shape"
printf '%s' "$OUT" | grep -q "remove the '## Open Questions' section entirely"                   || MISSING="$MISSING remedy-2"
printf '%s' "$OUT" | grep -q 'FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT=1'                         || MISSING="$MISSING remedy-3-override"
if [ -z "$MISSING" ]; then
    ok "the message names all three remedies, the entry shape and the override variable"
else
    bad "the message no longer names:$MISSING"
fi
if printf '%s' "$OUT" | grep -q 'Blocked command: echo probe'; then
    ok "names the actual restricted Bash command"
else
    bad "does not name the restricted command"
fi

# ------------------------------------------------------------------ teeth ----
echo
echo "--- teeth (mutate live source, assert the probe goes RED)"

# T-1039: the previous teeth swapped the message text for older text and then asserted the
# older text was present -- it asserted its own mutation, so it could not fail. The behaviour
# that makes remedies 1 and 2 reachable is the exempt-path case that lets the Edit tool
# touch "$PROJECT_ROOT"/.tasks/*. Take that arm out and the remedy must become unreachable.
python3 - "$HOOK" "$MUT" <<'PYEOF'
import sys
src = open(sys.argv[1]).read()
anchor = '    "$PROJECT_ROOT"/.context/*|"$PROJECT_ROOT"/.tasks/*|"$PROJECT_ROOT"/.claude/*|"$PROJECT_ROOT"/.git/*)\n        exit 0\n'
if src.count(anchor) != 1:
    sys.stderr.write("MUTATION FAILED: exempt-path arm found %d times, expected 1 -- teeth cannot certify anything\n" % src.count(anchor))
    sys.exit(1)
mutant = '    "$PROJECT_ROOT"/.context/*|"$PROJECT_ROOT"/.claude/*|"$PROJECT_ROOT"/.git/*)\n        exit 0\n'
open(sys.argv[2], "w").write(src.replace(anchor, mutant, 1))
PYEOF
mut_rc=$?
if [ "$mut_rc" -ne 0 ]; then
    bad "teeth: could not build the mutant (rc=$mut_rc) -- no teeth were demonstrated"
elif ! bash -n "$MUT" 2>/dev/null; then
    bad "teeth: mutant has a syntax error -- cannot certify the leg"
else
    ok "teeth: mutant parses (its failure below is behavioural, not syntactic)"
    run_edit_hook "$MUT" "$SANDBOX/src/app.py"
    if printf '%s' "$OUT" | grep -q 'G-067'; then
        ok "teeth: mutant still reaches G-067 (the leg below is about the right gate)"
        run_edit_hook "$MUT" "$TASKFILE"
        if [ "$RC" -ne 0 ]; then
            ok "teeth: without the task-file exemption the Edit remedy is REFUSED (rc=$RC) -- the leg has bite"
        else
            bad "teeth: mutant still lets the Edit tool through -- the reachability leg would pass on a broken tree"
        fi
    else
        bad "teeth: mutant does not reach G-067 -- the teeth leg would be vacuous"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
