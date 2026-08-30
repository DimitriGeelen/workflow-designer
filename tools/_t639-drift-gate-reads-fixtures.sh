#!/bin/bash
# T-639 — the focus-drift gate must identify the task a command TARGETS, not every
# task-id-shaped string the command CONTAINS.
#
# WHAT WAS WRONG. All three drift patterns matched the raw $BASH_CMD, so they read
# task ids out of quoted arguments. Pattern 3 held two independent over-matches in
# one condition:
#
#     [[ "$BASH_CMD" =~ (^|[[:space:]])git[[:space:]]+commit ]] && \
#     [[ "$BASH_CMD" =~ (T-[0-9]+): ]]
#
# The first clause is the T-638 defect verbatim — `git commit` anywhere, quoted text
# included. The second is anchored to nothing at all: any `T-N:` in the command
# became the target.
#
# The consequence is self-demonstrating, and it is why this file exists rather than
# an inline probe: a prober that exercises the gate's git-commit path is BLOCKED BY
# THE GATE, because its fixtures contain task ids. Running the T-639 probes from a
# Bash command line reproduced it live. During T-638 every fixture was written as
# `T-x:` instead of `T-1:` to stay under the pattern — the gate was silently shaping
# test data to avoid itself. A guard that fires on the wrong command trains people
# to route around it; this file's own subject says so about a different anchor.
#
# WHY NOT JUST STRIP QUOTES. Pattern 3's task id legitimately lives INSIDE the quoted
# -m value — stripping deletes exactly the thing it needs to read. Patterns 1 and 2
# take a bare argument, where stripping IS the right read. The two cases need
# different reads, and that asymmetry is the substance of the fix.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
CTX="$PROJ/.agentic-framework/agents/context"
HOOK="$CTX/check-active-task.sh"
LIB="$CTX/lib/safe-commands.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t639-$$-$(date +%s)"

# Staged beside the original: the hook resolves FRAMEWORK_ROOT from its own location
# and sources lib/paths.sh relative to it (AEF @790 §4).
MUTANT="$CTX/.t639-mutant-$$.sh"
trap 'rm -f "$MUTANT" 2>/dev/null; rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM

for f in "$HOOK" "$LIB"; do
    [ -f "$f" ] || { echo "COULD-NOT-MEASURE: missing $f" >&2; exit 3; }
done

mkdir -p "$SANDBOX/.context/working"
printf 'current_task: T-639\npriorities: []\n' > "$SANDBOX/.context/working/focus.yaml"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

echo "=== T-639 the drift gate reads targets, not mentions ==="
echo

run() {  # run <hook> <command> -> RC
    python3 -c "
import sys,json
print(json.dumps({'tool_name':'Bash','cwd':sys.argv[1],'tool_input':{'command':sys.argv[2]}}))
" "$SANDBOX" "$2" | bash "$1" >"$SANDBOX/out" 2>&1
    RC=$?
}

# ---------------------------------------------------------------------------
# The fixtures. Every one of these contains a task-id-shaped string; the
# question in each case is whether the command ACTS on that task.
# ---------------------------------------------------------------------------
ONFOCUS='git commit -m "T-639: a real commit on the focused task"'

# Genuine drift — the gate's whole reason to exist. Must keep blocking.
DRIFT_COMMIT='git commit -m "T-1: a real commit on another task"'
DRIFT_UPDATE='.agentic-framework/bin/fw task update T-1 --status issues'
DRIFT_LEARN='.agentic-framework/bin/fw context add-learning "x" --task T-1'

# Mentions — the command acts on nothing. Must stop blocking.
#
# These split into two groups, and the split is a finding, not bookkeeping. The
# pre-fix patterns required the task-id-shaped text to be preceded by WHITESPACE
# (`(^|[[:space:]])git…`, `(^|[[:space:]])…fw…`). Inside a quoted argument, whether
# that holds is a coin flip on which character happens to sit before the match.
#
# GROUP A — actually blocked before. The measured false-positive class.
PROSE_ECHO='echo "the canonical form is: git commit -m \"T-1: msg\""'
PROSE_UPDATE='echo "next you should run fw task update T-1 --status issues"'
# Identical to FIXTURE_ARG below except for ONE leading space inside the quoted
# argument. That space was the whole difference between blocked and allowed, which
# is the sharpest statement of why the old patterns were unsound: the verdict turned
# on a whitespace character inside a string the outer command never interprets.
FIXTURE_LEADING_SPACE='bash tools/probe.sh " git commit -m \"T-1: fixture\""'

# GROUP B — allowed before, but only BY ACCIDENT: a `"` happened to precede the
# match, so the whitespace anchor missed. Nothing in the old code DECIDED these were
# mentions. They must stay allowed, and after this task they are allowed for a
# reason — no clause invokes git commit — rather than by luck.
FIXTURE_ARG='bash tools/probe.sh "git commit -m \"T-1: fixture\""'
GREP_FOR_IT='grep -c "git commit -m \"T-1: x\"" tools/t.sh'
# The message BODY mentions another task. The target is the PREFIX, which is what
# commit-msg enforces and what `fw git log --task` reads. The old code got this
# right for the wrong reason: it took the FIRST `T-N:` anywhere in the command,
# which happened to be the prefix. Put the mention earlier and it targets the
# wrong task — so this case was one word-order away from a false BLOCK.
BODY_MENTION='git commit -m "T-639: supersedes the approach taken in T-1: see notes"'

echo "--- genuine drift still blocks (the gate must not be weakened)"
for pair in "DRIFT_COMMIT:off-focus commit" "DRIFT_UPDATE:off-focus task update" \
            "DRIFT_LEARN:off-focus add-learning"; do
    v="${pair%%:*}"; d="${pair#*:}"
    run "$HOOK" "${!v}"
    if [ "$RC" -ne 0 ] && grep -q "FOCUS-DRIFT" "$SANDBOX/out"; then ok "blocked: $d"
    else bad "DRIFT NOT CAUGHT — the fix weakened the gate: $d"; fi
done

echo
echo "--- the focused task's own commit is allowed"
run "$HOOK" "$ONFOCUS"
[ "$RC" -eq 0 ] && ok "allowed: on-focus commit" || bad "on-focus commit blocked"

echo
echo "--- a task id the command only MENTIONS is not a target"
for pair in "FIXTURE_ARG:fixture passed to a prober" "GREP_FOR_IT:grep whose pattern is a commit form" \
            "PROSE_ECHO:prose in an echo" "PROSE_UPDATE:prose naming a task update" \
            "FIXTURE_LEADING_SPACE:same fixture, one leading space" \
            "BODY_MENTION:another task named in the message BODY"; do
    v="${pair%%:*}"; d="${pair#*:}"
    run "$HOOK" "${!v}"
    if [ "$RC" -eq 0 ]; then ok "allowed: $d"
    else bad "still blocked by a mention: $d"; fi
done

echo
echo "--- both documented bypasses still work"
run "$HOOK" 'FW_SWITCH_FOCUS=1 git commit -m "T-1: deliberate cross-task commit"'
[ "$RC" -eq 0 ] && ok "FW_SWITCH_FOCUS=1 still bypasses" || bad "env-var bypass broken (T-1890 contract)"
run "$HOOK" '.agentic-framework/bin/fw task update T-1 --status issues --switch-focus'
[ "$RC" -eq 0 ] && ok "--switch-focus still bypasses" || bad "flag bypass broken (T-1890 contract)"

echo
echo "--- teeth: a mutant with the pre-fix patterns must still show the false positives"
python3 - "$HOOK" "$MUTANT" <<'PY'
import sys
src = open(sys.argv[1]).read()
anchor = ('    if type _sc_drift_target &>/dev/null && _sc_drift_target "$BASH_CMD"; then\n'
          '        TARGET_TASK="$_SC_DRIFT_TARGET"\n    fi\n')
if src.count(anchor) != 1:
    sys.stderr.write("MUTATION FAILED: %d occurrence(s) of the drift-target call, expected 1.\n"
                     "The hook's shape changed — fix this mutation rather than pinning a copy.\n"
                     % src.count(anchor))
    sys.exit(1)
old = '''    if [[ "$BASH_CMD" =~ (^|[[:space:]])([^[:space:]]*/)?fw[[:space:]]+task[[:space:]]+update[[:space:]]+(T-[0-9]+) ]]; then
        TARGET_TASK="${BASH_REMATCH[3]}"
    elif [[ "$BASH_CMD" =~ (^|[[:space:]])([^[:space:]]*/)?fw[[:space:]]+context[[:space:]]+add- ]] && \\
         [[ "$BASH_CMD" =~ --task[[:space:]=]+(T-[0-9]+) ]]; then
        TARGET_TASK="${BASH_REMATCH[1]}"
    elif [[ "$BASH_CMD" =~ (^|[[:space:]])git[[:space:]]+commit ]] && \\
         [[ "$BASH_CMD" =~ (T-[0-9]+): ]]; then
        TARGET_TASK="${BASH_REMATCH[1]}"
    fi
'''
open(sys.argv[2], "w").write(src.replace(anchor, old, 1))
PY
if [ $? -ne 0 ]; then
    echo "COULD-NOT-MEASURE: could not derive the pre-fix mutant from live source." >&2
    exit 3
fi
# Group A must go red under the mutant — those are the ones the fix actually
# changed. Group B must stay green under BOTH: the fix did not move them, it only
# gave them a reason. Asserting both directions is what stops this leg from
# claiming credit for cases that were never broken.
MUT_BLOCKS=0
for v in PROSE_ECHO PROSE_UPDATE FIXTURE_LEADING_SPACE; do
    run "$MUTANT" "${!v}"
    [ "$RC" -ne 0 ] && MUT_BLOCKS=$((MUT_BLOCKS+1))
done
if [ "$MUT_BLOCKS" -eq 3 ]; then
    ok "pre-fix mutant blocks all 3 of group A — the fix is what admits them"
else
    bad "mutant blocks only $MUT_BLOCKS/3 of group A — mutation no longer reproduces the defect"
fi

MUT_B_OK=0
for v in FIXTURE_ARG GREP_FOR_IT BODY_MENTION; do
    run "$MUTANT" "${!v}"
    [ "$RC" -eq 0 ] && MUT_B_OK=$((MUT_B_OK+1))
done
if [ "$MUT_B_OK" -eq 3 ]; then
    ok "group B passed before too — this task claims no credit for those 3"
else
    bad "group B is misfiled: $((3-MUT_B_OK)) of them WERE blocked before, so they belong in group A"
fi

echo
echo "--- and the mutant must AGREE on genuine drift (proving we only moved the false ones)"
AGREE=1
for v in DRIFT_COMMIT DRIFT_UPDATE DRIFT_LEARN ONFOCUS; do
    run "$MUTANT" "${!v}"; M=$RC
    run "$HOOK"   "${!v}"; R=$RC
    if { [ "$M" -eq 0 ] && [ "$R" -ne 0 ]; } || { [ "$M" -ne 0 ] && [ "$R" -eq 0 ]; }; then AGREE=0; fi
done
[ "$AGREE" -eq 1 ] && ok "real and mutant agree on every genuine case" \
                   || bad "the fix changed a verdict on genuine drift"

echo
echo "--- no per-call fork added (this runs on every Bash tool call)"
BODY=$(python3 - "$LIB" <<'PY'
import sys
code = open(sys.argv[1]).read()
start = code.index("_sc_drift_target() {")
print("\n".join(l for l in code[start:code.index("\n}", start)].splitlines()
                if not l.lstrip().startswith("#")))
PY
)
FORKS=""
for f in 'awk ' 'sed ' '$(echo' '| cut' 'python3' 'grep '; do
    case "$BODY" in *"$f"*) FORKS="$FORKS $f" ;; esac
done
[ -z "$FORKS" ] && ok "no fork introduced" || bad "forks a process per Bash call:$FORKS"

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
