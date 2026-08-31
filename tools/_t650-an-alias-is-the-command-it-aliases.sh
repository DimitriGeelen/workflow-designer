#!/usr/bin/env bash
# T-650 — an alias is admitted exactly when the command it aliases is.
#
# WHY THIS EXISTS. Completing a task prints a LEARNING PROMPT:
#   Consider: fw fix-learned T-XXX "what was learned"    (update-task.sh:2428)
# and the same transition nulls focus. With focus null, check-active-task.sh refused
# that command. The tool contradicted its own advice one line later.
#
# The sharp part is WHY. `fw fix-learned` is a pure alias — bin/fw ends its branch with
#   exec "$AGENTS_DIR/context/context.sh" add-learning "$fl_text" --task "$fl_task" ...
# so it IS `fw context add-learning`, reached by a different spelling. That target has
# been exempt since T-390, whose comment in safe-commands.sh quotes this very prompt as
# its motivation. T-390 diagnosed the deadlock correctly and exempted the long spelling;
# the prompt emits the short one. The fix and the message it was fixing never matched.
#
# So the invariant under test is not "fix-learned should be allowed". It is:
#
#     THE ALLOWLIST IS A CLAIM ABOUT EFFECTS, SO IT MUST NOT KEY ON SPELLING.
#
# Two spellings of one process must receive one verdict. That is what these legs assert,
# pairwise, so a future alias added without an exemption — or an exemption deleted from
# one spelling only — turns this red.
#
# NAME COLLISION, stated so the next reader does not lose ten minutes: comments inside
# check-active-task.sh reference a *different* T-650 (the vendored framework carries the
# upstream project's task numbers). Ours is the 832 task of the same number. Unrelated.
#
# HOW IT MEASURES. Legs 1-8 drive the REAL hook over the real JSON-on-stdin contract
# Claude Code uses, with `cwd` pointed at a throwaway sandbox. Nothing is executed — the
# hook only inspects. Leg 9 works at function level because the teeth need a MUTATED
# safe-commands.sh, and copying the framework to mutate one file would measure the copy.
#
# THIRD OUTCOME. Exit 3 = INCONCLUSIVE, not pass and not fail. A sandbox the hook does
# not recognise as a project root is a BOOTSTRAP case and the hook allows everything —
# externally identical to a gate that admits everything. The BLOCK controls run FIRST for
# that reason: they are what distinguishes "measured, all admitted" from "measured
# nothing". Borrowed from 001-CashWeb's check-gate-commit-exemption.py (@851), which
# named the same hazard.
#
# Exit 0 = all legs pass.

set -uo pipefail

PROJ="${T650_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
HOOK="$PROJ/.agentic-framework/agents/context/check-active-task.sh"
LIB="$PROJ/.agentic-framework/agents/context/lib/safe-commands.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$HOOK" ] || { echo "COULD-NOT-MEASURE: $HOOK not found" >&2; exit 3; }
[ -f "$LIB"  ] || { echo "COULD-NOT-MEASURE: $LIB not found"  >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

# A throwaway project root with focus NULL — the post-completion state.
SANDBOX="$TMP/sandbox"
mkdir -p "$SANDBOX/.context/working" "$SANDBOX/.tasks/active" "$SANDBOX/.tasks/completed"
printf 'framework_version: probe\n' > "$SANDBOX/.framework.yaml"
cat > "$SANDBOX/.context/working/focus.yaml" <<'EOF'
# Working Memory - Current Focus
current_task: null
priorities: []
EOF

echo "=== T-650: an alias is the command it aliases (OBS-331) ==="
echo

# verdict <command> -> prints ADMIT or BLOCK
verdict() {
    local cmd="$1" rc
    python3 - "$SANDBOX" "$cmd" <<'PY' > "$TMP/in.json"
import json, sys
json.dump({"tool_name": "Bash", "cwd": sys.argv[1],
           "tool_input": {"command": sys.argv[2]}}, sys.stdout)
PY
    ( cd "$SANDBOX" && bash "$HOOK" < "$TMP/in.json" >/dev/null 2>&1 )
    rc=$?
    [ "$rc" -eq 0 ] && echo ADMIT || echo BLOCK
}

# ---------------------------------------------------------------------------
# LEG 1 — the controls that make every other leg mean something.
echo "--- rig: does this sandbox actually gate anything?"
CTRL_FAIL=0
for c in 'rm -rf f' 'echo hi > f' 'python3 evil.py'; do
    [ "$(verdict "$c")" = "BLOCK" ] || { echo "  ADMITTED: $c"; CTRL_FAIL=1; }
done
if [ "$CTRL_FAIL" -ne 0 ]; then
    echo
    echo "INCONCLUSIVE: the sandbox admitted a command that must always block with focus" >&2
    echo "null. The hook is treating it as a bootstrap project, so it is allowing" >&2
    echo "everything and the admit legs below would pass against a gate that is not" >&2
    echo "running. Measured nothing. (exit 3)" >&2
    exit 3
fi
ok "BLOCK controls block — the gate is live in this sandbox"

# ---------------------------------------------------------------------------
# LEG 2..5 — pairwise parity. Each pair is one program under two spellings.
echo "--- parity: two spellings of one process must get one verdict"
PAIRS=(
  'fw context add-learning "x" --task T-1 --source P-001|fw fix-learned T-1 "x"'
  # T-652, added when the invariant this file asserts caught its own second instance:
  # `git commit` was admitted under focus-null and `fw git commit` refused — the spelling
  # CLAUDE.md's Quick Reference actually mandates. Same shape, different exemption (this
  # one lives in the T-2054 block, not the allowlist), found by walking into it twenty
  # minutes after the first. Pairs are cheap; that is the argument for keeping this a
  # table rather than a test per alias.
  'git commit -m "T-1: x"|fw git commit -m "T-1: x"'
  'git commit -m "T-1: x"|bin/fw git commit -m "T-1: x"'
)
for pair in "${PAIRS[@]}"; do
    TARGET="${pair%%|*}"; ALIAS="${pair##*|}"
    VT=$(verdict "$TARGET"); VA=$(verdict "$ALIAS")
    if [ "$VT" = "$VA" ]; then
        ok "same verdict ($VT): '$TARGET' == '$ALIAS'"
    else
        bad "SPELLING DECIDED IT — target=$VT alias=$VA  ('$TARGET' vs '$ALIAS')"
    fi
    [ "$VT" = "ADMIT" ] || bad "the exempt TARGET itself was blocked ($VT) — T-390 regressed"
done

# ---------------------------------------------------------------------------
echo "--- the reported symptom is gone"
if [ "$(verdict 'fw fix-learned T-1 "what was learned"')" = "ADMIT" ]; then
    ok "the exact command update-task.sh prints is now runnable when it is printed"
else
    bad "OBS-331 symptom intact: the prompt's own command is still refused"
fi

# ---------------------------------------------------------------------------
echo "--- the other no-task verbs still work (T-390 / T-2052 / T-2054 regression)"
for c in 'fw note "x"' 'fw context add-learning "x" --task T-1' \
         'fw handover' 'fw task create --name x --type build' 'git commit -m "T-1: x"'; do
    if [ "$(verdict "$c")" = "ADMIT" ]; then ok "still admitted: $c"
    else bad "REGRESSION — now blocked: $c"; fi
done

# ---------------------------------------------------------------------------
# The prose exemption is the reason this verb needs TWO list entries. fix-learned
# takes free prose in $2; without the second entry the command is admitted and then
# trips on its own argument.
echo "--- free prose in the learning text is stored, not read as shell"
if [ "$(verdict 'fw fix-learned T-1 "a > b and c && d; rm -rf x"')" = "ADMIT" ]; then
    ok "prose containing >, && and ; is admitted (it is an argument, not a script)"
else
    bad "prose argument read as a write — _sc_is_framework_prose_verb entry missing"
fi

echo "--- T-652: the alias inherits the commit exemption's LIMITS, not just its permission"
for c in 'fw git commit --no-verify -m "T-1: x"' \
         'fw git commit -m "T-1: x" && rm -rf f' \
         'fw git commit -m "$(evil)"'; do
    if [ "$(verdict "$c")" = "BLOCK" ]; then ok "still blocked: $c"
    else bad "ALIAS WIDENED THE EXEMPTION — admitted: $c"; fi
done

echo "--- but a destructive verb OUTSIDE the quotes is still caught"
if [ "$(verdict 'fw fix-learned T-1 "x" && rm -rf f')" = "BLOCK" ]; then
    ok "the exemption covers the argument, not the command line"
else
    bad "SECOND CLAUSE ADMITTED — same defect class as T-638/@851. This is a bypass."
fi

# ---------------------------------------------------------------------------
# LEG 9 — teeth. Revert exactly the two tokens this fix adds, and require BOTH:
#   (a) the alias goes back to being refused, and
#   (b) the admit controls STILL pass.
#
# (b) is not padding. 001-CashWeb lost a cycle to this at @851: their first mutant had a
# bash syntax error, so the file failed to parse, so EVERYTHING blocked — and against
# bypass probes alone a mutant that cannot parse is INDISTINGUISHABLE FROM A CORRECT FIX.
# Only the admit control separates them. Both halves or neither.
echo "--- teeth: revert the two entries; alias must go red, controls must stay green"
MUT="$TMP/mutant-safe-commands.sh"
# The two entries do NOT have the same shape — one is a block on its own line, the
# other is an inline `fix-learned) return 0 ;;`. The first draft of this sed anchored on
# `$` and silently reverted only one of them, then reported the count. Anchoring on the
# token and asserting the count is what turned a half-mutation into a visible failure.
sed -e 's/^\([[:space:]]*\)fix-learned)/\1__t650_reverted)/' "$LIB" > "$MUT"
REVERTED=$(grep -c '__t650_reverted)' "$MUT" || true)
if ! bash -n "$MUT" 2>/dev/null; then
    bad "MUTATION FAILED — mutant does not parse; it would block everything and prove nothing"
elif [ "$REVERTED" -ne 2 ]; then
    bad "MUTATION FAILED — expected 2 'fix-learned)' entries to revert, neutralised $REVERTED"
else
    probe() { ( set +u; source "$MUT" >/dev/null 2>&1; \
                is_bash_safe_command "$1" >/dev/null 2>&1 && echo ADMIT || echo BLOCK ); }
    live()  { ( set +u; source "$LIB" >/dev/null 2>&1; \
                is_bash_safe_command "$1" >/dev/null 2>&1 && echo ADMIT || echo BLOCK ); }
    M_ALIAS=$(probe 'fw fix-learned T-1 "x"')
    M_CTRL=$(probe 'fw context add-learning "x" --task T-1')
    L_ALIAS=$(live  'fw fix-learned T-1 "x"')
    if [ "$M_ALIAS" = "BLOCK" ] && [ "$M_CTRL" = "ADMIT" ] && [ "$L_ALIAS" = "ADMIT" ]; then
        ok "mutant refuses the alias and still admits the target — the entries are load-bearing"
    elif [ "$M_CTRL" != "ADMIT" ]; then
        bad "mutant blocks the CONTROL too ($M_CTRL) — broken mutant, not a demonstration"
    else
        bad "mutant still admits the alias ($M_ALIAS) — the leg above cannot fail"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
