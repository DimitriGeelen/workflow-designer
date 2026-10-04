#!/bin/bash
# T-631 — Tier-0 approval is deliberately the OPERATOR's act, and the block says how.
#
# ORIGINAL QUESTION (T-631). Is the Tier-0 approval route reachable while Tier 0 is
# blocking? check-tier0 prints `fw tier0 approve` as its way forward; if the same hook
# refused that command the wedged party would be the operator. The original answer was "no,
# the route is open", and the tool asserted `fw tier0 approve` PASSES the gate.
#
# WHY THAT PREMISE IS OBSOLETE (T-1039, from T-1035 Spike B). Vendored 1.7.740 made Tier-0
# self-approval human-only on purpose (check-tier0.sh, "Tier 0 self-approval (T-3593 R2)" and
# the round-5 rule: a command naming `tier0` is Tier 0 unless it is a plainly spelled
# status|list|help). An agent's `fw tier0 approve` is REFUSED by design. The operator is not
# wedged by that: they type the approval in their own terminal, where PreToolUse hooks do not
# run. What still has to hold, and what this file now pins:
#
#   1. the agent surface refuses self-approval, in every spelling that would make an agent
#      look human (plain, bin/ prefix, --i-am-human, env -u CLAUDECODE, CLAUDECODE=), and
#      says WHY (a SELF-APPROVAL risk label, not just any refusal);
#   2. the read-only verbs stay usable (status), so the hardening is not an over-block;
#   3. the block on a destructive command names the operator's route: the
#      `cd <project> && fw tier0 approve` line AND the Watchtower /approvals URL;
#   4. the block leaves a pending record for the operator's approval to pick up.
#
# TEETH. Two mutants of the live hook, staged beside it (it derives FRAMEWORK_ROOT from its own
# location): (a) `approve` added to the read-only verb list -> the agent's plain
# self-approval passes, leg 1 must go red; (b) the operator-route echo lines removed -> leg 3
# must go red.
#
# HERMETIC. Every run uses a throwaway PROJECT_ROOT, so the pending-approval file the hook
# writes lands in the sandbox and dies with it. Nothing here is ever approved.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
HOOK="$PROJ/.agentic-framework/agents/context/check-tier0.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t631-$$-$(date +%s)"
MUT_A="$(dirname "$HOOK")/.t631-mutant-a-$$.sh"
MUT_B="$(dirname "$HOOK")/.t631-mutant-b-$$.sh"
trap 'rm -f "$MUT_A" "$MUT_B" 2>/dev/null || true; rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM

[ -f "$HOOK" ] || { echo "COULD-NOT-MEASURE: hook not found at $HOOK" >&2; exit 3; }
mkdir -p "$SANDBOX/.context/working" "$SANDBOX/.tasks/active"
printf 'project: t631-sandbox\n' > "$SANDBOX/.framework.yaml"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

run_hook() {  # <hook> <command>  -> RC, OUT
    local hook="$1" cmd="$2" json
    json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$cmd" "$SANDBOX")
    OUT=$(printf '%s' "$json" | env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR \
        -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
        CLAUDECODE=1 PROJECT_ROOT="$SANDBOX" bash "$hook" 2>&1 >/dev/null)
    RC=$?
}

# The spellings that would let an agent approve its own block. Plain first: it is the one the
# round-5 rule alone decides (no dedicated pattern names it).
SELF_APPROVE=(
    'fw tier0 approve'
    'bin/fw tier0 approve'
    'fw tier0 approve --i-am-human'
    'env -u CLAUDECODE fw tier0 approve'
    'CLAUDECODE= fw tier0 approve'
)
FORCE_PUSH='git push --force origin master'

echo "=== T-631 Tier-0 approval is the operator's act, and the block says how ==="
echo

echo "--- control: the Tier 0 gate fires on a destructive command"
run_hook "$HOOK" "$FORCE_PUSH"
if [ "$RC" -eq 2 ] && printf '%s' "$OUT" | grep -q 'TIER 0 BLOCK'; then
    ok "control: a force push is blocked (rc=2, TIER 0 BLOCK banner)"
else
    bad "control: Tier 0 did not fire (rc=$RC) — every leg below would be vacuous"
    echo "COULD-NOT-MEASURE: no firing gate to test." >&2
    exit 3
fi

echo
echo "--- 1. the agent surface refuses self-approval, and says why"
for c in "${SELF_APPROVE[@]}"; do
    run_hook "$HOOK" "$c"
    if [ "$RC" -eq 2 ] && printf '%s' "$OUT" | grep -q 'TIER 0 SELF-APPROVAL'; then
        ok "refused as SELF-APPROVAL (rc=2): $c"
    else
        bad "self-approval spelling not refused as such (rc=$RC): $c"
    fi
done

echo
echo "--- 2. the read-only verb stays usable (the hardening is not an over-block)"
run_hook "$HOOK" 'fw tier0 status'
if [ "$RC" -eq 0 ]; then
    ok "'fw tier0 status' passes the gate (rc=0)"
else
    bad "'fw tier0 status' is refused (rc=$RC) — the gate over-blocks a read"
fi

echo
echo "--- 3. the block message names the operator's route"
run_hook "$HOOK" "$FORCE_PUSH"
if printf '%s' "$OUT" | grep -qE "^[[:space:]]+cd [^ ]+ && (.*/)?fw tier0 approve[[:space:]]*$"; then
    ok "names the operator's terminal command: cd <project> && fw tier0 approve"
else
    bad "the operator's 'cd <project> && fw tier0 approve' line is missing from the block message"
fi
if printf '%s' "$OUT" | grep -qE '^[[:space:]]+https?://[^ ]+/approvals[[:space:]]*$'; then
    ok "names the Watchtower approvals URL (…/approvals)"
else
    bad "the Watchtower /approvals URL is missing from the block message"
fi
if printf '%s' "$OUT" | grep -q 'human-only'; then
    ok "says the approval is human-only (the reader is told not to expect the agent to do it)"
else
    bad "the message no longer says the approval is human-only"
fi

echo
echo "--- 4. the block leaves the operator's approval something to pick up"
if [ -s "$SANDBOX/.context/working/.tier0-approval.pending" ]; then
    ok "pending-approval record written (sandbox)"
else
    bad "no pending-approval record was written — the operator's 'fw tier0 approve' would find nothing"
fi

echo
echo "--- teeth: mutate the live hook, the matching leg must go RED"
# (a) `approve` becomes a plainly read-only verb: the agent's plain self-approval passes.
python3 - "$HOOK" "$MUT_A" <<'PYEOF'
import sys
src = open(sys.argv[1]).read()
anchor = "(?:\\s+(?:status|list|help|--help|-h))?')"
if src.count(anchor) != 1:
    sys.stderr.write("MUTATION FAILED: read-only verb list found %d times, expected 1\n" % src.count(anchor))
    sys.exit(1)
open(sys.argv[2], "w").write(src.replace(anchor, "(?:\\s+(?:status|list|approve|help|--help|-h))?')", 1))
PYEOF
rc_a=$?
# (b) the operator-route lines are removed from the block message.
python3 - "$HOOK" "$MUT_B" <<'PYEOF'
import sys
src = open(sys.argv[1]).read()
for anchor in ('echo "    $(_emit_user_command "tier0 approve")" >&2\n', 'echo "    ${WT_URL}/approvals" >&2\n'):
    if src.count(anchor) != 1:
        sys.stderr.write("MUTATION FAILED: %r found %d times, expected 1\n" % (anchor[:40], src.count(anchor)))
        sys.exit(1)
    src = src.replace(anchor, "", 1)
open(sys.argv[2], "w").write(src)
PYEOF
rc_b=$?
if [ "$rc_a" -ne 0 ] || [ "$rc_b" -ne 0 ] || ! bash -n "$MUT_A" 2>/dev/null || ! bash -n "$MUT_B" 2>/dev/null; then
    bad "teeth: mutants not built or do not parse (a=$rc_a b=$rc_b) — no teeth were demonstrated"
else
    ok "teeth: both mutants parse (any failure below is behavioural, not syntactic)"
    run_hook "$MUT_A" "$FORCE_PUSH"
    if [ "$RC" -eq 2 ] && printf '%s' "$OUT" | grep -q 'TIER 0 BLOCK'; then
        ok "teeth: mutant (a) still reaches the Tier 0 block (the leg below is about the right gate)"
        run_hook "$MUT_A" 'fw tier0 approve'
        if [ "$RC" -eq 0 ]; then
            ok "teeth: with 'approve' read-only, the agent's plain self-approval PASSES — leg 1 has bite"
        else
            bad "teeth: mutant (a) still refuses plain self-approval (rc=$RC) — leg 1 would stay green on a broken gate"
        fi
        run_hook "$MUT_A" 'fw tier0 approve --i-am-human'
        if [ "$RC" -eq 2 ]; then
            ok "teeth: mutant (a) still refuses the --i-am-human spelling — the legs are independent, not one blanket"
        else
            bad "teeth: mutant (a) lets --i-am-human through — the mutation is wider than intended"
        fi
    else
        bad "teeth: mutant (a) does not reach the Tier 0 block — teeth would be vacuous"
    fi
    run_hook "$MUT_B" "$FORCE_PUSH"
    if [ "$RC" -eq 2 ] && printf '%s' "$OUT" | grep -q 'TIER 0 BLOCK'; then
        if ! printf '%s' "$OUT" | grep -qE "^[[:space:]]+cd [^ ]+ && (.*/)?fw tier0 approve[[:space:]]*$" \
           && ! printf '%s' "$OUT" | grep -qE '^[[:space:]]+https?://[^ ]+/approvals[[:space:]]*$'; then
            ok "teeth: mutant (b) blocks but names no operator route — leg 3 has bite"
        else
            bad "teeth: mutant (b) still shows the operator route — leg 3 would stay green on a broken message"
        fi
    else
        bad "teeth: mutant (b) does not reach the Tier 0 block — teeth would be vacuous"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
