#!/bin/bash
# T-638 — the T-2054 commit exemption must admit a COMMIT, not a command that
# mentions one.
#
# WHAT WAS WRONG. `check-active-task.sh` admits `git commit` with no active task,
# for a narrow and well-argued reason (T-2054: `--status work-completed` nulls
# focus and moves the task out of active/, so the completion's own file-move could
# otherwise never be committed). The written justification is exact — committing
# "persists work already produced under the Write/Edit task gate — it is not new
# work". That holds for a command that IS a commit. The branch tested CONTAINS:
#
#     [[ "$BASH_CMD" =~ (^|[[:space:]])git[[:space:]]+commit($|[[:space:]]) ]]
#
# Measured against the live hook with focus null, that admitted `git commit …; X`
# whole, admitted `git commit … | tee f`, and admitted an arbitrary unknown binary
# whose QUOTED ARGUMENT contained the words "git commit" — nothing committed, the
# sentence was enough. Sixth instance in three days of one class: a character-level
# scan standing in for structure.
#
# It also closed over an ordering bug. The write-pattern check earlier in the hook
# does not exit — it falls through — so a command whose second clause was correctly
# identified as a write still reached this branch and was handed `exit 0`.
#
# WHY MUTATION. A pinned textual copy of the hook would buy drift (rail-463, and
# T-635 in this repo watched a pinned model go green against a line the live gate
# strips). A mutant derived from live source has neither weakness: it is always
# today's hook minus the one line under test. The teeth are the DISAGREEMENT — if
# someone reverts the fix, real and mutant converge and the hole legs go red.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
CTX="$PROJ/.agentic-framework/agents/context"
HOOK="$CTX/check-active-task.sh"
LIB="$CTX/lib/safe-commands.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t638-$$-$(date +%s)"

# The mutant must be staged BESIDE the original: the hook derives FRAMEWORK_ROOT
# from its own location and sources lib/paths.sh + lib/safe-commands.sh relative
# to it. A mutant in a scratch directory dies in paths.sh instead of measuring
# anything (AEF @790 §4).
MUTANT="$CTX/.t638-mutant-$$.sh"
trap 'rm -f "$MUTANT" 2>/dev/null; rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM

for f in "$HOOK" "$LIB"; do
    [ -f "$f" ] || { echo "COULD-NOT-MEASURE: missing $f" >&2; exit 3; }
done

mkdir -p "$SANDBOX/.context/working" "$SANDBOX/.tasks/active"
printf 'current_task: null\npriorities: []\n' > "$SANDBOX/.context/working/focus.yaml"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

echo "=== T-638 the commit exemption is clause-scoped ==="
echo

# ---------------------------------------------------------------- build mutant
python3 - "$HOOK" "$MUTANT" <<'PY'
import sys
src = open(sys.argv[1]).read()
anchor = """    if type _sc_is_commit_only_command &>/dev/null && \\
       _sc_is_commit_only_command "$BASH_CMD" && \\
"""
if src.count(anchor) != 1:
    sys.stderr.write("MUTATION FAILED: %d occurrence(s) of the predicate call, expected 1.\n"
                     "The hook's shape changed — fix this mutation rather than pinning a copy.\n"
                     % src.count(anchor))
    sys.exit(1)
old = """    if [[ "$BASH_CMD" =~ (^|[[:space:]])git[[:space:]]+commit($|[[:space:]]) ]] && \\
"""
open(sys.argv[2], "w").write(src.replace(anchor, old, 1))
PY
if [ $? -ne 0 ]; then
    echo "COULD-NOT-MEASURE: could not derive the pre-fix mutant from live source." >&2
    exit 3
fi
ok "mutant derived from live source (pre-fix regex restored, one line, anchored)"

run() {  # run <hook> <command> -> RC
    python3 -c "
import sys,json
print(json.dumps({'tool_name':'Bash','cwd':sys.argv[1],'tool_input':{'command':sys.argv[2]}}))
" "$SANDBOX" "$2" | bash "$1" >"$SANDBOX/out" 2>&1
    RC=$?
}

# Legitimate forms. Each is something a session genuinely does after
# --status work-completed nulls focus. The fix must not cost any of them.
LEGIT=(
    'git commit -m "T-x: y"'
    'cd /opt/832-Workflow-designer && git commit -m "T-x: y"'
    'git add -A && git commit -m "T-x: y"'
    'git commit -m "T-x: msg with ; a semicolon"'
    'git commit -m "T-x: y" && git push'
)
# Holes. Each was admitted with no active task before this task.
HOLES=(
    'git commit -m "T-x: y"; touch '"$SANDBOX"'/PWNED'
    'git commit -m "T-x: y" && touch '"$SANDBOX"'/PWNED2'
    'git commit -m "T-x: y" | tee '"$SANDBOX"'/TEED'
    'someunknownbinary --flag "please git commit this"'
    'git commit -m "$(cat /etc/hostname)"'
)

echo
echo "--- the legitimate post-completion forms still pass"
for c in "${LEGIT[@]}"; do
    run "$HOOK" "$c"
    if [ "$RC" -eq 0 ]; then ok "allowed: ${c:0:58}"
    else bad "REGRESSION — the fix cost a real form: ${c:0:58}"; fi
done

echo
echo "--- the holes are closed"
for c in "${HOLES[@]}"; do
    run "$HOOK" "$c"
    if [ "$RC" -ne 0 ]; then ok "blocked: ${c:0:58}"
    else bad "still admitted with no active task: ${c:0:58}"; fi
done

echo
echo "--- teeth: the mutant must still show the hole (else this proves nothing)"
# If this leg goes red, the mutation stopped reproducing the pre-fix behaviour and
# every green above is unearned.
MUT_ADMITS=0
for c in "${HOLES[@]}"; do
    run "$MUTANT" "$c"
    [ "$RC" -eq 0 ] && MUT_ADMITS=$((MUT_ADMITS+1))
done
if [ "$MUT_ADMITS" -eq "${#HOLES[@]}" ]; then
    ok "pre-fix mutant admits all ${#HOLES[@]} — the fix is what closes them, not the harness"
else
    bad "mutant admits only $MUT_ADMITS/${#HOLES[@]} — mutation no longer reproduces the defect"
fi

echo
echo "--- --no-verify stays excluded (unchanged by this task)"
run "$HOOK" 'git commit -m "T-x: y" --no-verify'
[ "$RC" -ne 0 ] && ok "--no-verify blocked" || bad "--no-verify admitted — T-2054's own exclusion was lost"

echo
echo "--- the fix must not WIDEN the gate: real allows nothing the mutant blocked"
# The direction nobody checks. A tightening fix that accidentally admits something
# new is a worse outcome than the hole it closed.
WIDENED=""
for c in "${LEGIT[@]}" "${HOLES[@]}" \
    'echo hello' 'rm -rf /tmp/t638-not-a-real-path' 'python3 -c "print(1)"' \
    'git status' 'git add -A' 'fw handover' 'cat /etc/hostname'; do
    run "$MUTANT" "$c"; M=$RC
    run "$HOOK"   "$c"; R=$RC
    if [ "$M" -ne 0 ] && [ "$R" -eq 0 ]; then WIDENED="$WIDENED|${c:0:40}"; fi
done
if [ -z "$WIDENED" ]; then
    ok "nothing blocked before is allowed now"
else
    bad "the fix WIDENED the gate for:$WIDENED"
fi

echo
echo "--- the ordering bug: a flagged write must not be handed exit 0"
# has_bash_write_pattern runs earlier in the hook and FALLS THROUGH rather than
# exiting, so before this task its verdict was computed and then overridden here.
source "$LIB" 2>/dev/null
PIPED='git commit -m "T-x: y" | tee '"$SANDBOX"'/TEED'
if has_bash_write_pattern "$PIPED"; then
    run "$HOOK" "$PIPED"
    [ "$RC" -ne 0 ] && ok "a command the write check flags is no longer admitted here" \
                    || bad "write flagged upstream, admitted downstream — the override is back"
else
    bad "COULD-NOT-MEASURE: has_bash_write_pattern no longer flags the piped form"
fi

echo
echo "--- and the predicate stays fork-free (PreToolUse runs it on every Bash call)"
BODY=$(python3 - "$LIB" <<'PY'
import sys
code = open(sys.argv[1]).read()
start = code.index("_sc_is_commit_only_command() {")
print("\n".join(l for l in code[start:code.index("\n}", start)].splitlines()
                if not l.lstrip().startswith("#")))
PY
)
FORKS=""
for f in 'awk ' 'sed ' '$(echo' '| cut' 'python3'; do
    case "$BODY" in *"$f"*) FORKS="$FORKS $f" ;; esac
done
[ -z "$FORKS" ] && ok "no per-call fork introduced" || bad "forks a process per Bash call:$FORKS"

echo
echo "--- nothing in the holes actually executed"
STRAY=""
for m in PWNED PWNED2 TEED; do [ -e "$SANDBOX/$m" ] && STRAY="$STRAY $m"; done
[ -z "$STRAY" ] && ok "no marker file created by any blocked command" \
                || bad "a blocked command still ran:$STRAY"

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
