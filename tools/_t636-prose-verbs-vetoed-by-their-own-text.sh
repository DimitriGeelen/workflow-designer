#!/bin/bash
# T-636 — the observation inbox refused an observation about `rm`.
#
# OBSERVED. T-635 completed, which cleared focus. The next act was to file what T-635
# turned up, and `fw note "<text>" --tag census --task T-635` came back:
#
#     BLOCKED: No active task. Framework rule: nothing gets done without a task.
#
# `fw note` is allowlisted for exactly that state. safe-commands.sh (T-390) says so in
# as many words: "Blocking it with no active task is self-defeating in a specific way:
# the framework could not record the observation that it cannot record observations."
#
# MECHANISM, measured rather than inferred — and the two hypotheses that read as obvious
# were both wrong, which is the reason this file exists rather than a one-line patch:
#
#   - NOT the `>` in the prose. `fw note "a > b"` is not a write: T-404's redirect walk
#     runs on the QUOTE-STRIPPED string and never sees it.
#   - NOT apostrophe desync in the stripper. `_sc_strip_quoted` is a character state
#     machine that tracks WHICH quote opened the span, so an apostrophe inside a
#     double-quoted argument is content, not a delimiter. (Worth stating: the same
#     hypothesis was correct about T-633's census, and wrong here. The difference is a
#     hand-rolled regex versus a state machine.)
#   - IT IS the destructive-VERB scan, which by deliberate decision (T-404) runs on the
#     RAW string. The word `rm` inside the quoted prose matched, `has_bash_write_pattern`
#     returned true, and check-active-task checks that BEFORE consulting the allowlist —
#     so the allowlist branch is not reached at all.
#
# T-404's reasoning for the raw scan is sound and is not being reversed here: a false
# positive costs "you need an active task", while a false negative would let
# `sh -c "rm -rf x"` past the gate. THAT ARGUMENT IS ABOUT EXECUTION. It inverts exactly
# where the argument is prose the framework stores and never runs — and in this project
# that prose is overwhelmingly about shell behaviour. Measured below: one word vetoes
# `fw note`, `fw context add-learning`, `fw task create --name` and `fw git commit -m`.
#
# THE SHAPE OF THE FAILURE IS WORSE THAN THE FAILURE. It presents as "No active task",
# so the remedy it hands you is "create a task" — which is precisely what T-390 added
# the exemption to avoid, and precisely the wrong thing to do with an observation you
# are not acting on. A block message that names the wrong cause sends the reader
# somewhere useful-looking and wrong.
#
# ADJACENT, same class, found while probing this one: the focus-drift gate (T-1730) read
# a task id out of a PROBE FIXTURE — the string `T-1:` inside a quoted test input — and
# blocked on drift toward a task that does not exist. Not fixed here (one bug, one task);
# recorded so the pattern is on file. Gates that read prose as instructions are a family,
# not an incident.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
CTXDIR="$PROJ/.agentic-framework/agents/context"
LIB="$CTXDIR/lib/safe-commands.sh"
HOOK="$CTXDIR/check-active-task.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t636-$$-$(date +%s)"
MUTLIB="$CTXDIR/lib/.t636-mutant-lib-$$.sh"
MUTHOOK="$CTXDIR/.t636-mutant-hook-$$.sh"
trap 'rm -f "$MUTLIB" "$MUTHOOK" 2>/dev/null || true; rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM

for f in "$LIB" "$HOOK"; do
    [ -f "$f" ] || { echo "COULD-NOT-MEASURE: missing $f" >&2; exit 3; }
done
mkdir -p "$SANDBOX/.tasks/active" "$SANDBOX/.context/working"
printf 'project: t636-sandbox\n' > "$SANDBOX/.framework.yaml"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

# Focus genuinely null — not "focus on a task that happens not to exist". The whole
# question is what the gate does with NO active task, so a sandbox that accidentally
# carries one would make every leg below vacuous. The control at the end proves it.
printf 'current_task: null\npriorities: []\n' > "$SANDBOX/.context/working/focus.yaml"

run_hook() {  # <hook> <command>  -> RC, OUT
    local hook="$1" cmd="$2" json
    json=$(python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' \
        "$cmd" "$SANDBOX")
    OUT=$(printf '%s' "$json" | env -u TASKS_DIR -u CONTEXT_DIR -u _FW_PATHS_DERIVED_BY \
        -u FRAMEWORK_ROOT CLAUDECODE=1 PROJECT_ROOT="$SANDBOX" bash "$hook" 2>&1 >/dev/null)
    RC=$?
}

# The prose that could not be filed. `rm` is the trigger word; the sentence is the real
# one from T-635's finding, because a fixture invented to contain the trigger would not
# show that this is the ORDINARY shape of our observations rather than a contrived one.
PROSE='fw note "the runner writes its output to a shared path, greps it, and rm -f s it"'

echo "=== T-636 framework prose verbs vetoed by their own text ==="
echo

echo "--- anti-vacuity: with focus null the gate must still refuse something"
run_hook "$HOOK" 'make install'
if [ "$RC" -ne 0 ]; then
    ok "control: a non-exempt command is refused with no active task (rc=$RC)"
else
    bad "control: the gate allows everything here — every leg below is vacuous"
    echo "COULD-NOT-MEASURE: no firing gate to measure an exemption against." >&2
    exit 3
fi

echo
echo "--- the refusal that started this, through the REAL hook"
run_hook "$HOOK" "$PROSE"
if [ "$RC" -eq 0 ]; then
    ok "fw note carrying the word rm is accepted with no active task"
else
    bad "still refused (rc=$RC) — the exemption is not reached:"
    printf '%s\n' "$OUT" | head -4 | sed 's/^/          /'
fi

echo
echo "--- every verb the framework declares safe-without-task, pinned"
# The exemption was written for `note` and would have been just as broken for the other
# three. Pinning them together is what makes the next regression a red leg rather than a
# blocked session: whichever verb loses the exemption, this list notices.
declare -a VERBS=(
  'fw note "a note mentioning rm and tee"'
  'fw context add-learning "a learning about rm -rf and tee"'
  'fw context add-pattern failure "a pattern about rmdir"'
  'fw context add-decision "chose tee over a redirect"'
  'fw task create --name "rmdir leaves the parent behind"'
  'fw git commit -m "drop the rm -rf call"'
  'fw handover'
)
for v in "${VERBS[@]}"; do
    run_hook "$HOOK" "$v"
    if [ "$RC" -eq 0 ]; then
        ok "accepted: ${v:0:58}"
    else
        bad "REFUSED with no active task: $v"
    fi
done

echo
echo "--- the exemption must not widen the gate"
# Each of these must STILL be refused. The exemption scans the stripped string rather
# than skipping the scan, so a destructive verb OUTSIDE the quotes is untouched by it;
# and a command substitution is a route from the argument back to the shell, which is
# the execution case T-404's asymmetry is actually about.
declare -a MUSTBLOCK=(
  'fw note "harmless" && rm -rf /tmp/x'
  'fw note "$(rm -rf /tmp/x)"'
  'rm -rf /tmp/x'
  'sh -c "rm -rf /tmp/x"'
  'fw notes-something-else "rm -rf"'
)
for v in "${MUSTBLOCK[@]}"; do
    run_hook "$HOOK" "$v"
    if [ "$RC" -ne 0 ]; then
        ok "still refused: ${v:0:58}"
    else
        bad "THE EXEMPTION WIDENED THE GATE — now allowed with no task: $v"
    fi
done

echo
echo "--- teeth: remove the exemption from the live source and the refusal must return"
# Two-file mutation, both staged beside their originals: the hook derives its lib path
# from its own location, so a mutant hook in a scratch dir would source the real lib and
# quietly measure nothing (AEF @790 §4, confirmed twice in T-628 and T-634).
python3 - "$LIB" "$MUTLIB" <<'PY'
import sys
src = open(sys.argv[1]).read()
anchor = '        cmd="$_SC_STRIPPED"\n'
if src.count(anchor) != 1:
    sys.stderr.write("MUTATION FAILED: %d occurrence(s) of the exemption assignment, expected 1\n"
                     % src.count(anchor))
    sys.exit(1)
# Neutralise the exemption without deleting the branch: the guard stays, the effect goes.
open(sys.argv[2], "w").write(src.replace(anchor, '        :\n', 1))
PY
if [ ! -s "$MUTLIB" ] || ! bash -n "$MUTLIB" 2>/dev/null; then
    bad "teeth: mutant library not built or does not parse — the exemption is unproven"
else
    python3 - "$HOOK" "$MUTHOOK" "$MUTLIB" <<'PY'
import sys
src = open(sys.argv[1]).read()
anchor = 'source "$SCRIPT_DIR/lib/safe-commands.sh"'
if src.count(anchor) != 1:
    sys.stderr.write("MUTATION FAILED: %d occurrence(s) of the lib source line, expected 1\n"
                     % src.count(anchor))
    sys.exit(1)
open(sys.argv[2], "w").write(src.replace(anchor, 'source "%s"' % sys.argv[3], 1))
PY
    if [ ! -s "$MUTHOOK" ] || ! bash -n "$MUTHOOK" 2>/dev/null; then
        bad "teeth: mutant hook not built or does not parse"
    else
        ok "teeth: both mutants parse (any failure below is behavioural, not syntactic)"
        run_hook "$MUTHOOK" 'make install'
        if [ "$RC" -ne 0 ]; then
            ok "teeth: the mutant still refuses the control — it is a working gate"
        else
            bad "teeth: the mutant refuses nothing — it measures nothing either"
        fi
        run_hook "$MUTHOOK" "$PROSE"
        if [ "$RC" -ne 0 ]; then
            ok "teeth: without the exemption the observation is refused again — it is load-bearing"
        else
            bad "teeth: still accepted without the exemption — the exemption is not what fixed this"
        fi

        echo
        echo "--- not ours: a compound command led by 'git commit' passes on the T-2054 branch"
        # Found by the must-not-widen list above, which is what that list is for. The hook
        # allows ANY command containing `git commit` with no active task (T-2054, so a
        # session can checkpoint completed work; the commit-msg hook enforces T-XXX). It
        # matches the string, not the first clause, so `fw git commit -m "x"; <anything>`
        # is carried past the active-task gate whole. Tier 0 is a separate hook and still
        # sees the second clause, so this is a hole in one layer, not an open door.
        #
        # Recorded, not fixed: one bug, one task. And the assertion is deliberately NOT
        # "this is allowed" — pinning today's hole would go red the day someone closes it.
        # It asserts that the real hook and the exemption-free mutant AGREE, which is the
        # only claim T-636 is entitled to make about it: whatever this behaviour is, the
        # exemption did not cause it. That stays true after a fix.
        COMPOUND='fw git commit -m "checkpoint"; rm -rf /tmp/t636-not-a-real-path'
        run_hook "$HOOK" "$COMPOUND";    REAL_RC=$RC
        run_hook "$MUTHOOK" "$COMPOUND"; MUT_RC=$RC
        if [ "$REAL_RC" -eq "$MUT_RC" ]; then
            ok "real and exemption-free hooks agree (both rc=$REAL_RC) — not caused by T-636"
        else
            bad "the exemption CHANGED this case (real rc=$REAL_RC, without it rc=$MUT_RC)"
        fi
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
