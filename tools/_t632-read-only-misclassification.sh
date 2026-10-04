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

# RE-ANCHORED (T-1039) on 1.7.740. Both mutations target today's code, not the 1.7.6xx
# spelling this tool was written against; each must land exactly once or the tool says so.
#
# (a) the sink exclusion's terminator class. has_bash_write_pattern strips `>/dev/null`
#     tokens before the redirect scan, and the token may end at `)` so that
#     `$(cat url 2>/dev/null)` is read-only. Take `)` out of the terminator class and a
#     redirect to /dev/null inside a command substitution is a write again (the 832 T-632
#     defect (a)).
fixed_re = "([[:space:];|&)]|$)#\\1 \\3#"
old_re   = "([[:space:];|&]|$)#\\1 \\3#"
if src.count(fixed_re) != 1:
    sys.stderr.write("MUTATION FAILED: /dev/null terminator anchor found %d times, expected 1\n" % src.count(fixed_re))
    sys.exit(1)
src = src.replace(fixed_re, old_re, 1); n += 1

# (b) the read-only text-filter arm of the allowlist (Category 2b). Rename the arm's verbs
#     out of existence so sed/sort/cut/... fall through to "not on the allowlist" (defect (b)).
#     Anchored on the full verb list line, which occurs once.
arm = "        sed|awk|sort|uniq|cut|tr|nl|od|paste|join|fold|expand|unexpand|rev|comm|cmp|diff|colordiff|column|jq|seq|base64|md5sum|sha1sum|sha256sum|cksum|strings|xxd|tput|zcat|gunzip)\n"
if src.count(arm) != 1:
    sys.stderr.write("MUTATION FAILED: Category 2b verb arm found %d times, expected 1\n" % src.count(arm))
    sys.exit(1)
src = src.replace(arm, "        __t632_removed_text_filters__)\n", 1); n += 1

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
for c in 'WURL=$(cat url 2>/dev/null)'; do
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
echo "--- awk and uniq: admitted only where they cannot write"
# T-1039: upstream (1.7.740) now ALLOWLISTS awk and uniq, so "awk stays gated" is no longer
# the contract. The contract is the one this tool always protected: a verb that can write
# without a shell redirect must be caught by has_bash_write_pattern. awk has unrestricted
# print>file / print|cmd / system() inside its quoted program; uniq's second operand is an
# output file. Each write form must stay gated; the plain read form may pass.
for c in 'awk "{print > \"out\"}" f' "awk '{print > \"out\"}' f" "awk 'BEGIN{system(\"touch x\")}'" \
         "awk '{print | \"sh\"}' f" 'uniq in out'; do
    if gate_allows "$LIB" "$c"; then
        bad "a write-capable form is admitted with no task: $c"
    else
        ok "write-capable form still gated — $c"
    fi
done
if gate_allows "$LIB" "awk '{print \$1}' f"; then
    ok "plain read-only awk is admitted (upstream allowlist) — the gate is not over-narrow"
else
    bad "plain read-only awk is refused — the gate over-blocks a read"
fi

echo
echo "--- the natural resume form: refused before the fix, allowed after"
# T-1039: this section used to also pin the form the old corpus carried, to show that a
# `|| echo ...` between the redirect and the close paren hid the defect. On 1.7.740 that
# chained-substitution form is refused in BOTH copies, by upstream's conservative handling
# of any chain inside $(...) -- a different rule, not this one -- so it no longer
# discriminates. It is reported, not asserted. The natural form still does.
CORPUS_FORM='WURL=$(cat url 2>/dev/null || echo "http://localhost:3000"); curl -sf "$WURL/" > /dev/null'
NATURAL_FORM='WURL=$(cat url 2>/dev/null); curl -sf "$WURL/" > /dev/null'
if gate_allows "$PREFIX_LIB" "$NATURAL_FORM"; then
    bad "pre-fix: the natural form passes too — the mutant does not reproduce the defect"
else
    ok "pre-fix: the natural form is REFUSED (the defect)"
fi
if gate_allows "$LIB" "$NATURAL_FORM"; then
    ok "live: the natural form is allowed"
else
    bad "live: the natural resume form is still blocked"
fi
gate_allows "$LIB" "$CORPUS_FORM" || echo "  NOTE  chained \$(a || b) substitution is refused by upstream's chain rule (live and pre-fix alike); not a T-632 matter"

echo
echo "--- the ordering invariant the sed/sort guards depend on"
# sed and sort are on the allowlist now. That is only safe because the write check runs
# FIRST in the hook and its verdict overrides the allowlist. If that order ever flips,
# `sed -i` becomes allowlisted. Asserted against the hook, not the lib — the hook is the
# thing that acts.
W_LINE=$(grep -n 'has_bash_write_pattern "\$BASH_CMD"' "$HOOK" | head -1 | cut -d: -f1)
S_LINE=$(grep -n 'is_bash_safe_command "\$BASH_CMD"' "$HOOK" | head -1 | cut -d: -f1)
if [ -n "$W_LINE" ] && [ -n "$S_LINE" ] && [ "$W_LINE" -lt "$S_LINE" ] \
   && sed -n "${W_LINE}p" "$HOOK" | grep -qE '^[[:space:]]*if ' \
   && sed -n "${S_LINE}p" "$HOOK" | grep -qE '^[[:space:]]*elif '; then
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
