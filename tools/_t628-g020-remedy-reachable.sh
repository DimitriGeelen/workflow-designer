#!/bin/bash
# T-628 — does the G-020 block message prescribe commands the same gate refuses?
#
# ORIGIN. 999-AEF reported the class (rail @775, their T-3216): "a block message is an
# executable contract, not documentation. If you name a remedy, something must actually
# verify the remedy is reachable FROM THE BLOCKED STATE." 577-CashWeb reproduced it
# (@776) and added the clause that explains the blindness: FOLLOWING A REMEDY
# SUCCESSFULLY PROVES THAT YOUR ROUTE WORKS; IT IS NOT EVIDENCE THAT THE REMEDY IS
# REACHABLE. Three trees, this one included, escaped via the Edit tool every time and
# concluded the gate was fine. The agent best placed to notice is the one least likely
# to, because it is not the one that is wedged.
#
# WHY THIS IS A SECOND SCRIPT AND NOT A LEG IN T-386. T-386 probes the FOCUS-DRIFT gate
# in this same hook, and its header already names G-020 as a sibling that "also exits 2".
# We built the class instrument for one gate and never pointed it at the one next to it.
# Keeping them separate keeps each anti-vacuity anchor specific to its own banner — a
# shared harness with a shared "blocked" assertion is exactly the vacuity both files warn
# about.
#
# ASSERT ON OUTPUT, NOT ON EXIT CODE ALONE (577 @774 item 5). "Allowed" here is rc 0 AND
# the T-628 NOTE on stderr. rc 0 alone would also be produced by a hook that died before
# reaching the gate; the NOTE cannot be produced by anything else. Where a leg wants
# "refused" it asserts the G-020 banner, not rc 2 — every earlier gate in this hook exits
# 2 as well, so rc 2 is satisfied from a sandbox where focus was never set.
#
# FIXTURES INCLUDE INVENTED SHAPES. Settled across three trees this week (010 @772 item 3,
# 577 @774 item 3, our @769): a suite built only from real state tests the instances you
# have; only invented fixtures test the class. Two shapes below occur nowhere in our
# corpus — the remedy carrying a write payload, and the remedy aimed at a task that is not
# the focused one. 577's refinement is why both are here rather than one: the cost of
# skipping fixtures depends on whether your corpus holds negatives, and ours holds none.
#
# NOTE FOR WHOEVER EDITS THIS FILE. It cannot be written from a shell heredoc while a
# focus is set: the fixture ids below are task-id-shaped, so the focus-drift gate in the
# very hook under test matches them in the command text (PL-164 — prose about a
# string-matching gate contains the string the gate matches). Use the Write/Edit tool.
# T-386 has the same property for the same reason.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
HOOK="$PROJ/.agentic-framework/agents/context/check-active-task.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t628-$$-$(date +%s)"

[ -f "$HOOK" ] || { echo "COULD-NOT-MEASURE: hook not found at $HOOK" >&2; exit 3; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

FOCUSED=T-900      # focused, unscoped -> G-020 fires
OTHER=T-902        # a DIFFERENT unscoped task (bounding fixture)
SCOPED=T-903       # scoped -> G-020 must NOT fire (discrimination control)

mk_task() {  # <id> <placeholder|real>
    mkdir -p "$SANDBOX/.tasks/active"
    local ac
    if [ "$2" = "placeholder" ]; then ac='- [ ] [First criterion]'; else ac='- [ ] a real, scoped criterion'; fi
    cat > "$SANDBOX/.tasks/active/$1-t628-fixture.md" <<YAML
---
id: $1
name: "T-628 fixture ($2 ACs)"
description: fixture
status: started-work
workflow_type: build
owner: agent
horizon: now
created: 2026-08-29T00:00:00Z
last_update: 2026-08-29T00:00:00Z
---

# $1

## Acceptance Criteria
### Agent
$ac

## Verification
# A trailing section is not decoration. The gate reads the AC block with
# `sed -n '/^## Acceptance Criteria/,/^## [^A]/p'` piped to a delete-last-line sed, so
# with no following heading the range runs to EOF and that delete removes the
# only AC. A fixture ending at its ACs therefore reads as UNSCOPED no matter what it
# says, and the "scoped" control silently stops being a control. Caught by that leg
# failing on the first run: real task files always carry later sections, so this shape
# is a property of the fixture, not of the gate.
YAML
}

set_focus() {
    mkdir -p "$SANDBOX/.context/working"
    printf 'current_task: %s\npriorities: []\n' "$1" > "$SANDBOX/.context/working/focus.yaml"
}

build_sandbox() {
    mkdir -p "$SANDBOX/.tasks/active"
    printf 'project: t628-sandbox\n' > "$SANDBOX/.framework.yaml"
    mk_task "$FOCUSED" placeholder
    mk_task "$OTHER"   placeholder
    mk_task "$SCOPED"  real
    set_focus "$FOCUSED"
}

# rc + stderr from a chosen hook binary, for a Bash tool call.
run_hook() {  # <hook-path> <command>   -> sets RC, OUT
    local hook="$1" cmd="$2" json
    json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' "$cmd" "$SANDBOX")
    OUT=$(printf '%s' "$json" | env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR \
        -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
        CLAUDECODE=1 PROJECT_ROOT="$SANDBOX" bash "$hook" 2>&1 >/dev/null)
    RC=$?
}

echo "=== T-628 G-020 remedy reachability ==="
build_sandbox
echo "sandbox: $SANDBOX  (focus $FOCUSED unscoped; $OTHER unscoped; $SCOPED scoped)"

# ------------------------------------------------------------ anti-vacuity ----
echo
echo "--- anti-vacuity: prove we reach G-020 specifically, not an earlier exit-2 gate"

run_hook "$HOOK" 'echo probe > /tmp/t628.marker'
if printf '%s' "$OUT" | grep -q 'G-020'; then
    ok "reached G-020 (banner names it)"
else
    bad "did not reach G-020"
    echo "COULD-NOT-MEASURE: every leg below would be asserting about the wrong gate." >&2
    printf '%s\n' "$OUT" | head -8 >&2
    exit 3
fi

set_focus "$SCOPED"
run_hook "$HOOK" 'echo probe > /tmp/t628.marker'
if printf '%s' "$OUT" | grep -q 'G-020'; then
    bad "a SCOPED task also shows G-020 — the banner does not discriminate"
else
    ok "scoped task takes a different branch — the banner discriminates"
fi
set_focus "$FOCUSED"

# ------------------------------------------------------- the printed remedies ----
echo
echo "--- remedy 2, verbatim, from inside the firing state"

for spelling in \
    "fw task update $FOCUSED --type inception" \
    "bin/fw task update $FOCUSED --type inception" \
    ".agentic-framework/bin/fw task update $FOCUSED --type inception"
do
    run_hook "$HOOK" "$spelling"
    if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -q 'T-628'; then
        ok "reachable: $spelling"
    else
        bad "REFUSED by the gate that prints it (rc=$RC): $spelling"
    fi
done

echo
echo "--- bounding: the exemption must not become a general retype route"

# INVENTED FIXTURE 1 — occurs nowhere in our corpus. The remedy aimed at a task that is
# not the focused one. Without the "$CURRENT_TASK" anchor in the exemption, this passes.
# The assertion is "the EXEMPTION did not fire", not "G-020 refused it". Those differ,
# and the first run proved it: this command is refused with rc 2 by the FOCUS-DRIFT gate
# (a fw verb naming a task that is not the focus) before G-020 is ever reached. A leg
# demanding the G-020 banner here failed while the tree was correct — a false red, which
# is the same defect as a false green. The T-628 NOTE is the discriminating string:
# nothing but the exemption can emit it.
run_hook "$HOOK" "fw task update $OTHER --type inception"
if printf '%s' "$OUT" | grep -q 'prescribed conversion (T-628)'; then
    bad "exemption admits retyping an arbitrary task from inside a block (rc=$RC)"
elif [ "$RC" -eq 0 ]; then
    bad "a DIFFERENT task id was allowed through (rc=0, no exemption NOTE) — which gate passed it?"
else
    ok "a DIFFERENT task id is still refused (exemption is anchored to focus)"
fi

# INVENTED FIXTURE 2 — occurs nowhere in our corpus. The remedy plus a write payload:
# the remedy is the pretext, the redirect is the act.
run_hook "$HOOK" "fw task update $FOCUSED --type inception > /etc/t628-should-never-exist"
if printf '%s' "$OUT" | grep -q 'G-020'; then
    ok "remedy carrying a write payload is still refused"
else
    bad "exemption passes a redirect riding on the remedy (rc=$RC)"
fi

echo
echo "--- the message itself"

run_hook "$HOOK" 'echo probe > /tmp/t628.marker'
if printf '%s' "$OUT" | grep -q 'Edit/Write tool'; then
    ok "remedy 1 is surface-accurate (names the tool path)"
else
    bad "remedy 1 still implies a shell edit is available"
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

# THE MUTANT LIVES NEXT TO THE ORIGINAL, NOT IN THE SANDBOX.
#
# T-386 stages its mutant inside the sandbox and that works — for T-386. The hook derives
# FRAMEWORK_ROOT from its own SCRIPT_DIR, so a copy anywhere else sources no paths.sh, no
# config.sh, and has no find_task_file. Measured: such a copy dies at the P-002
# "task is not active" gate with rc 2, because ACTIVE_FILE never resolves. T-386 survives
# that because the focus-drift gate it probes sits ~140 lines ABOVE the first missing
# function; G-020 sits ~200 lines below it. The same harness is sound for one gate and
# silently tests nothing for its neighbour, and the only reason we know is that this leg
# stayed red and got debugged instead of relaxed.
#
# Cleaned up on every exit path, including interrupts — a stray executable in the agents
# directory would register as fabric drift and outlive the run that made it.
MUT="$(dirname "$HOOK")/.t628-mutant-$$.sh"
trap 'rm -f "$MUT" 2>/dev/null || true; rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM
python3 - "$HOOK" "$MUT" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
# Strip the T-628 exemption: from its `if` to the `fi` that closes it.
#
# Anchored on `${BASH_CMD:-}`, which occurs ONLY in this block. The obvious anchor —
# `if [ "$TOOL_NAME" = "Bash" ]` — matches at three sites, the earliest being the
# focus-drift gate ~340 lines above; a non-greedy match from there swallowed that gate
# whole and produced a mutant that failed to parse. The teeth leg reported "syntax
# error" rather than a bogus pass, which is the only reason this was visible. The
# indent backreference keeps the closing `fi` matched to the right nesting level.
pat = re.compile(r'\n( *)if \[ "\$TOOL_NAME" = "Bash" \] && \[ -n "\$\{BASH_CMD:-\}" \].*?prescribed conversion \(T-628\).*?\n\1fi\n', re.S)
new, n = pat.subn('\n', src)
if n != 1:
    sys.stderr.write("MUTATION FAILED: T-628 exemption not found (%d matches) — teeth cannot certify anything\n" % n)
    sys.exit(1)
open(sys.argv[2], 'w').write(new)
PY
mut_rc=$?
if [ "$mut_rc" -ne 0 ]; then
    bad "teeth: could not build the mutant (rc=$mut_rc) — no teeth were demonstrated"
elif ! bash -n "$MUT" 2>/dev/null; then
    bad "teeth: mutant has a syntax error — cannot certify the leg"
else
    ok "teeth: mutant parses (its failure below is behavioural, not syntactic)"
    # Guard the teeth the way the suite guards itself: prove the mutant still REACHES
    # G-020 before asserting anything about what G-020 does there. Without this, a mutant
    # that dies at an earlier gate produces the same red as a mutant that reaches G-020
    # and is refused — and a future refactor that moves the failure point would turn this
    # leg vacuous with nothing to announce it.
    run_hook "$MUT" 'echo probe > /tmp/t628.marker'
    if printf '%s' "$OUT" | grep -q 'G-020'; then
        ok "teeth: mutant still reaches G-020 (the leg below is about the right gate)"
        run_hook "$MUT" "fw task update $FOCUSED --type inception"
        if printf '%s' "$OUT" | grep -q 'G-020'; then
            ok "teeth: without the fix the gate REFUSES its own remedy — the leg has bite"
        else
            bad "teeth: mutant did not refuse it; this probe would pass on a broken tree"
        fi
    else
        bad "teeth: mutant does not reach G-020 — the teeth leg would be vacuous"
    fi
fi

# cleanup handled by the EXIT trap above
echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
