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
echo "--- the message itself"

run_hook "$HOOK" 'echo probe > /tmp/t629.marker'
if printf '%s' "$OUT" | grep -q 'Edit/Write tool'; then
    ok "remedies 1 and 2 name the surface that works"
else
    bad "remedies 1 and 2 are stated without a surface — shell forms are refused"
fi
if printf '%s' "$OUT" | grep -qE '^Attempting to modify:[[:space:]]*$'; then
    bad "prints a bare 'Attempting to modify:' with an empty target"
else
    ok "no empty 'Attempting to modify:' line"
fi
if printf '%s' "$OUT" | grep -q 'Attempting to run (Bash): echo probe'; then
    ok "names the actual restricted Bash command"
else
    bad "does not name the restricted command"
fi

# ------------------------------------------------------------------ teeth ----
echo
echo "--- teeth (mutate live source, assert the probe goes RED)"

python3 - "$HOOK" "$MUT" <<'PY'
import sys
src = open(sys.argv[1]).read()
# Revert the T-629 wording to its pre-fix form — BOTH remedies, not just the first.
#
# The first draft reverted remedy 1 alone, and the teeth leg stayed green on the mutant:
# remedy 2's line also carries "Edit/Write tool", so the assertion still matched and the
# leg proved nothing. A partial mutation under a whole-file assertion has no bite, and it
# fails in the safe-looking direction — the suite reports PASS. Revert the whole fix, or
# narrow the assertion to the one line the mutation touches; doing neither is the vacuity
# this file exists to avoid.
edits = [
    ("  1. Edit $CURRENT_TASK with the Edit/Write tool and add at least one entry under '## Open Questions':",
     "  1. Edit $CURRENT_TASK and add at least one entry under '## Open Questions':"),
    ("  2. Or remove the '## Open Questions' section entirely, also with the Edit/Write tool (grandfathered).",
     "  2. Or remove the '## Open Questions' section entirely (grandfathered)."),
]
for old, new in edits:
    if src.count(old) != 1:
        sys.stderr.write("MUTATION FAILED: %r not found exactly once (%d) — teeth cannot certify anything\n" % (old[:40], src.count(old)))
        sys.exit(1)
    src = src.replace(old, new)
open(sys.argv[2], 'w').write(src)
PY
mut_rc=$?
if [ "$mut_rc" -ne 0 ]; then
    bad "teeth: could not build the mutant (rc=$mut_rc) — no teeth were demonstrated"
elif ! bash -n "$MUT" 2>/dev/null; then
    bad "teeth: mutant has a syntax error — cannot certify the leg"
else
    ok "teeth: mutant parses (its failure below is behavioural, not syntactic)"
    run_hook "$MUT" 'echo probe > /tmp/t629.marker'
    if printf '%s' "$OUT" | grep -q 'G-067'; then
        ok "teeth: mutant still reaches G-067 (the leg below is about the right gate)"
        if printf '%s' "$OUT" | grep -q 'Edit/Write tool'; then
            bad "teeth: mutant still names the surface — the leg has no bite"
        else
            ok "teeth: without the fix the remedy is stated with no surface — the leg has bite"
        fi
    else
        bad "teeth: mutant does not reach G-067 — the teeth leg would be vacuous"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
