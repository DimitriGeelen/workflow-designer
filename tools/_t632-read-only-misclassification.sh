#!/bin/bash
# T-632 — read-only commands refused by the active-task gate, in two directions.
#
# OBSERVED, both inside the first five minutes of a session that had written nothing:
#
#     WURL=$(cat .context/working/watchtower.url 2>/dev/null); curl -sf "$WURL/" >/dev/null
#     sed -n '340,420p' .agentic-framework/agents/context/lib/safe-commands.sh
#
# Neither writes anything. The first is step 5 of the framework's own /resume skill.
#
# TWO INDEPENDENT MECHANISMS, and the first hypothesis was wrong. `>/dev/null` looked
# like the trigger and is not — has_bash_write_pattern excludes it explicitly. Reading
# the predicate instead of trusting the reproduction gave:
#
#   (a) The redirect walk captured its target with [^[:space:];|]*, which does not stop
#       at `)`. Inside a command substitution the target reads `/dev/null)`, which is not
#       the string `/dev/null`, so the sink exclusion misses and the command is
#       classified as a write onto a file named `/dev/null)`. `$(cmd 2>&1)` had the same
#       shape: target `&1)`, fd-dup exclusion missed.
#
#   (b) sed, sort, cut, tr, diff and the rest of the read-only text tools were absent
#       from the allowlist entirely — not misclassified, never classified. Since T-405
#       judges EVERY segment of a pipeline, one such stage condemned the whole pipeline:
#       `cat f | sed -n 1,20p` refused while `cat f` passed.
#
# WHY THE EXISTING CORPUS DID NOT CATCH (a) — this is the part worth keeping. The
# corpus at web/test_safe_commands.py is PL-025's own prescribed remedy and it pins a
# RESUME_STEP5 constant for exactly this command. It stayed green throughout, because
# the variant it pins writes `2>/dev/null || echo ...` — and the `||` splits the segment
# BEFORE the close paren, so that copy never contains the `2>/dev/null)` adjacency that
# breaks. The corpus was built from the three commands blocked in the 2026-08-09
# incident. It pinned those instances faithfully and never tested the class.
#
# That is 577's rule (@774) landing on our own tree: A SELF-TEST BUILT FROM THE CORPUS
# TESTS THE INSTANCES YOU HAVE; ONLY INVENTED FIXTURES TEST THE CLASS. Leg 4 below
# measures it rather than asserting it — it runs the corpus's own pinned constant
# through the PRE-FIX predicate and shows it passing, which is the evidence that the
# corpus could not have failed.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
LIB="$PROJ/.agentic-framework/agents/context/lib/safe-commands.sh"
HOOK="$PROJ/.agentic-framework/agents/context/check-active-task.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t632-$$-$(date +%s)"
trap 'rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM
mkdir -p "$SANDBOX"

[ -f "$LIB" ] || { echo "COULD-NOT-MEASURE: lib not found at $LIB" >&2; exit 3; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

# Ask a predicate in a given copy of the lib. Never interpolate the command into the
# script text: the corpus is full of quotes and redirect operators, and interpolating
# would make this harness the thing under test rather than the predicate.
ask() {  # <lib> <func> <cmd>  -> rc 0 = true
    bash -c 'source "$1"; if '"$2"' "$3"; then exit 0; fi; exit 1' _ "$1" "$2" "$3"
}
gate_allows() {  # <lib> <cmd> — mirrors check-active-task.sh:92-97 ordering
    ask "$1" has_bash_write_pattern "$2" && return 1
    ask "$1" is_bash_safe_command "$2"
}

echo "=== T-632 read-only misclassification ==="
echo

# ---------------------------------------------------------------------------
# The PRE-FIX copy. Built by reverting the fix in a scratch copy, NOT by reading
# git history: a `git show HEAD~1:` anchor silently starts testing the fix against
# itself the moment one more commit lands (AEF's rail-463 lesson).
# ---------------------------------------------------------------------------
PREFIX_LIB="$SANDBOX/safe-commands-prefix.sh"
python3 - "$LIB" "$PREFIX_LIB" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
n = 0

# (a) put `)` back into the redirect target's character class
fixed_re = "([^[:space:];|)]*)(.*)$'"
old_re   = "([^[:space:];|]*)(.*)$'"
if src.count(fixed_re) != 1:
    sys.stderr.write("MUTATION FAILED: redirect-target anchor not found exactly once\n")
    sys.exit(1)
src = src.replace(fixed_re, old_re, 1); n += 1

# (b) remove the read-only text-processing verbs from the allowlist
# Anchored on BOTH ends — the opening comment and the next category heading. An
# earlier draft anchored the tail on the sort branch's `;;` with an indent
# backreference and silently matched nothing, because the `;;` sits one indent level
# deeper than the branch label. A mutation that matches nothing reports success and
# certifies an untested fix; that is why every failure here is fatal, not a warning.
pat = re.compile(r'\n *# Category 2b: read-only text processing \(T-632\).*?(?=\n *# Category 3: Searching)', re.S)
if len(pat.findall(src)) != 1:
    sys.stderr.write("MUTATION FAILED: Category 2b block not found exactly once\n")
    sys.exit(1)
src = pat.sub("\n", src, count=1); n += 1

open(sys.argv[2], 'w').write(src)
sys.stderr.write("pre-fix copy built (%d reversions)\n" % n)
PY
if [ ! -s "$PREFIX_LIB" ]; then
    echo "COULD-NOT-MEASURE: could not build the pre-fix copy — nothing below has teeth." >&2
    exit 3
fi
if ! bash -n "$PREFIX_LIB" 2>/dev/null; then
    echo "COULD-NOT-MEASURE: pre-fix copy has a syntax error — its verdicts would be noise." >&2
    exit 3
fi

echo "--- (a) the defect, reproduced against the pre-fix predicate"
for c in 'WURL=$(cat url 2>/dev/null)' 'x=$(cmd 2>&1)'; do
    if ask "$PREFIX_LIB" has_bash_write_pattern "$c"; then
        ok "pre-fix: classified as a WRITE (this is the bug) — $c"
    else
        bad "pre-fix: no longer reproduces — teeth are gone, fix the fixture: $c"
    fi
done

echo
echo "--- (b) the allowlist gap, reproduced against the pre-fix predicate"
for c in 'sed -n 1,20p f' 'cat f | sed -n 1,20p' 'sort -u f' 'cut -d: -f1 f'; do
    if ask "$PREFIX_LIB" is_bash_safe_command "$c"; then
        bad "pre-fix: already safe — this leg proves nothing: $c"
    else
        ok "pre-fix: refused as not-safe (this is the bug) — $c"
    fi
done

echo
echo "--- both directions are fixed in the LIVE predicate"
for c in 'WURL=$(cat url 2>/dev/null)' 'x=$(cat f 2>&1)' 'sed -n 1,20p f' \
         'cat f | sed -n 1,20p' 'sort -u f' 'cut -d: -f1 f' 'diff a b' 'sha256sum f'; do
    if gate_allows "$LIB" "$c"; then
        ok "live: allowed with null focus — $c"
    else
        bad "live: STILL blocked — $c"
    fi
done

echo
echo "--- teeth: the writes this gate exists to catch are still caught"
# A predicate narrowed into uselessness passes every leg above. These are the legs it
# cannot pass. `y=$(cmd > real.txt)` is the discriminating one for fix (a): stopping the
# target at `)` must not stop the walk from seeing a genuine write inside a substitution.
for c in 'echo hi > out.txt' 'y=$(cmd > real.txt)' 'sed -i s/a/b/ f' 'sed s/a/b/w out f' \
         'sort -o out f' 'sort --output=out f' 'tee out' 'rm -f x' 'cat <<EOF'; do
    if ask "$LIB" has_bash_write_pattern "$c"; then
        ok "still a write — $c"
    else
        bad "WRITE NO LONGER CAUGHT — the fix widened the hole: $c"
    fi
done

echo
echo "--- the two verbs deliberately NOT admitted stay out"
# Not an oversight, and a future 'helpful' widening should trip here rather than in
# production. awk has unrestricted print>file and system(), both living inside the
# quoted program the stripper deletes. uniq's second positional operand is an output
# file, and quoted operands collapse to nothing, so operand counting cannot see it.
for c in 'awk "{print}" f' 'uniq in out'; do
    if gate_allows "$LIB" "$c"; then
        bad "admitted a verb that can write with no shell redirect: $c"
    else
        ok "still gated (documented exclusion) — $c"
    fi
done

echo
echo "--- why the existing corpus stayed green: it pinned the instance, not the class"
# The corpus constant and the natural form differ by ONE thing — whether a `||` happens
# to fall between the redirect and the close paren. Measured, not argued.
CORPUS_FORM='WURL=$(cat url 2>/dev/null || echo "http://localhost:3000"); curl -sf "$WURL/" > /dev/null'
NATURAL_FORM='WURL=$(cat url 2>/dev/null); curl -sf "$WURL/" > /dev/null'
if gate_allows "$PREFIX_LIB" "$CORPUS_FORM"; then
    ok "pre-fix: the form the corpus pins PASSES — the corpus could not have failed"
else
    bad "pre-fix: the corpus form fails too, so the corpus WOULD have caught this"
fi
if gate_allows "$PREFIX_LIB" "$NATURAL_FORM"; then
    bad "pre-fix: the natural form passes too — the two forms do not discriminate"
else
    ok "pre-fix: the natural form is REFUSED — one '||' apart from the pinned one"
fi
if gate_allows "$LIB" "$NATURAL_FORM" && gate_allows "$LIB" "$CORPUS_FORM"; then
    ok "live: both forms allowed"
else
    bad "live: one of the two resume forms is still blocked"
fi

echo
echo "--- the ordering invariant the sed/sort guards depend on"
# sed and sort are on the allowlist now. That is only safe because the write check runs
# FIRST in the hook and its verdict overrides the allowlist. If that order ever flips,
# `sed -i` becomes allowlisted. Asserted against the hook, not the lib — the hook is the
# thing that acts.
if grep -n 'has_bash_write_pattern' "$HOOK" | head -1 | grep -q '^9[0-9]:' \
   && [ "$(grep -n 'has_bash_write_pattern "\$BASH_CMD"' "$HOOK" | head -1 | cut -d: -f1)" \
        -lt "$(grep -n 'is_bash_safe_command "\$BASH_CMD"' "$HOOK" | head -1 | cut -d: -f1)" ]; then
    ok "hook: write check precedes the allowlist check"
else
    bad "hook: allowlist is consulted before the write check — sed -i would be allowed"
fi
if gate_allows "$LIB" 'sed -i s/a/b/ f'; then
    bad "gate_allows lets sed -i through — the ordering guard is not holding"
else
    ok "end-to-end: sed -i is on the allowlist verb list and still refused"
fi

echo
echo "--- end-to-end through the HOOK, with focus actually null"
# Everything above asks the predicates. This asks the thing that acts. A null-focus
# sandbox is the state compaction creates, and the state in which this class of defect
# is the difference between a session recovering and a session wedged.
mkdir -p "$SANDBOX/.context/working" "$SANDBOX/.tasks/active"
printf 'project: t632-sandbox\n' > "$SANDBOX/.framework.yaml"
printf 'current_task: null\n' > "$SANDBOX/.context/working/focus.yaml"

hook_rc() {  # <command> -> rc
    python3 -c '
import json,sys
print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2]}))' \
        "$1" "$SANDBOX" \
    | env -u PROJECT_ROOT -u TASKS_DIR -u CONTEXT_DIR -u _FW_PATHS_DERIVED_BY -u FRAMEWORK_ROOT \
        CLAUDECODE=1 PROJECT_ROOT="$SANDBOX" bash "$HOOK" >/dev/null 2>&1
}

# Anti-vacuity FIRST: if the hook does not refuse anything in this sandbox, every
# "allowed" verdict below is the hook failing open, not the fix working.
if hook_rc 'make install'; then
    bad "hook control: a non-allowlisted command was ALLOWED with null focus — hook fails open here"
    echo "COULD-NOT-MEASURE: no firing gate; the legs below would be vacuous." >&2
else
    ok "hook control: a non-allowlisted command is refused with null focus"
    for c in 'WURL=$(cat .context/working/watchtower.url 2>/dev/null); curl -sf "$WURL/" >/dev/null' \
             "sed -n '340,420p' .agentic-framework/agents/context/lib/safe-commands.sh"; do
        if hook_rc "$c"; then
            ok "hook: allowed with null focus — ${c:0:58}..."
        else
            bad "hook: STILL refused with null focus — $c"
        fi
    done
    if hook_rc 'sed -i "s/a/b/" src.sh'; then
        bad "hook: sed -i ALLOWED with null focus — the allowlist entry is unguarded"
    else
        ok "hook: sed -i still refused with null focus"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
