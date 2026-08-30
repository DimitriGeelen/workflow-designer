#!/bin/bash
# T-640 — `curl` and `wget` sat on the safe-list unconditionally, so a command that
# fetches a URL INTO A FILE was admitted with no active task.
#
# WHY THIS IS A GATE PROBE AND NOT JUST A CORPUS TEST. The corpus in
# .agentic-framework/web/test_safe_commands.py calls has_bash_write_pattern directly.
# That pins the predicate, which is only half the claim. The other half is ORDERING:
# check-active-task.sh runs the write-check BEFORE consulting the allowlist, and the
# write verdict has to win. `curl` IS on the safe-list — so if the two were consulted
# in the other order, or if the write branch fell through the way T-638's did, every
# assertion below would still pass at the predicate level and the gate would still let
# the download through. Only driving the real hook can tell those apart.
#
# The safe-list states its own admission rule: a command earns a place by not writing.
# That is the stated basis on which `awk` and `uniq` are excluded. `curl -o` writes a
# file with no shell redirect at all, so the list was violating its own rule in the one
# direction the rule exists to prevent.
#
# BREADTH ON wget IS DELIBERATE. wget with no flag writes the fetched file into the
# working directory — "no output flag" is the defect, not the safe case. The two
# genuinely read-only forms (`wget -O -`, `wget -q -O-`) are refused as collateral,
# which is stated here rather than hidden because it is a real cost.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
CTX="$PROJ/.agentic-framework/agents/context"
HOOK="$CTX/check-active-task.sh"
LIB="$CTX/lib/safe-commands.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t640-$$-$(date +%s)"

# Both mutants are staged BESIDE their originals: the hook resolves FRAMEWORK_ROOT
# from its own location and sources lib/ relative to it, so a copy anywhere else dies
# in paths.sh instead of measuring anything (AEF @790 §4).
MUTANT="$CTX/.t640-mutant-$$.sh"
MUTANT_LIB="$CTX/lib/.t640-mutant-lib-$$.sh"
trap 'rm -f "$MUTANT" "$MUTANT_LIB" 2>/dev/null; rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM

for f in "$HOOK" "$LIB"; do
    [ -f "$f" ] || { echo "COULD-NOT-MEASURE: missing $f" >&2; exit 3; }
done

# T-641: a sandbox without a .tasks/ marker is INERT — fw_reanchor_from_cwd walks up
# looking for .framework.yaml or .tasks/, finds neither, and returns 0 unchanged, so
# the hook reads the REAL focus.yaml. Silent no-op. The marker is what makes this
# directory a project; the first leg below proves it took hold rather than assuming it.
mkdir -p "$SANDBOX/.context/working" "$SANDBOX/.tasks/active"
printf 'current_task: null\npriorities: []\n' > "$SANDBOX/.context/working/focus.yaml"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

run() {  # run <hook> <command> -> RC
    python3 -c "
import sys,json
print(json.dumps({'tool_name':'Bash','cwd':sys.argv[1],'tool_input':{'command':sys.argv[2]}}))
" "$SANDBOX" "$2" | bash "$1" >"$SANDBOX/out" 2>&1
    RC=$?
}
run_at() {  # run_at <hook> <cwd> <command> -> RC — for the inversion leg only
    python3 -c "
import sys,json
print(json.dumps({'tool_name':'Bash','cwd':sys.argv[1],'tool_input':{'command':sys.argv[2]}}))
" "$2" "$3" | bash "$1" >"$SANDBOX/out" 2>&1
    RC=$?
}

echo "=== T-640 a fetcher that writes a file is a write ==="
echo

# ---------------------------------------------------------------------------
echo "--- the sandbox is actually in effect (T-641: it silently is not, by default)"
# The inversion: one command, two working directories. Under the sandbox there is no
# active task so it must be REFUSED; under the real project root a task is focused so
# it must be ALLOWED. If the sandbox were inert both would read the same live focus
# and both would pass, so no single accident satisfies both halves.
CANARY='touch some-new-file'
run "$HOOK" "$CANARY";                A=$RC
run_at "$HOOK" "$PROJ" "$CANARY";     B=$RC
if [ "$A" -ne 0 ] && [ "$B" -eq 0 ]; then
    ok "sandbox null-focus governs; the live project root still admits the same command"
elif [ "$B" -ne 0 ]; then
    echo "  SKIP  live project root also refuses the canary (no focused task right now) — inversion not decidable"
else
    bad "SANDBOX INERT — the hook is reading the real focus, so every leg below is meaningless (see T-641 / paths.sh fw_reanchor_from_cwd)"
fi

# ---------------------------------------------------------------------------
# The fixtures. Writers take a URL INTO a file; readers take a URL and emit to stdout.
WRITERS=(
    'curl -o out.txt https://example.com/f:curl -o'
    'curl --output out.txt https://example.com/f:curl --output'
    'curl --output=out.txt https://example.com/f:curl --output='
    'curl -O https://example.com/f.tar:curl -O'
    'curl -sO https://example.com/f.tar:curl -sO (flag inside a cluster)'
    'curl --remote-name https://example.com/f.tar:curl --remote-name'
    'wget https://example.com/f.tar:wget with no flag at all'
    'wget -O out.txt https://example.com/f:wget -O'
    'wget --output-document=out.txt https://example.com/f:wget --output-document'
)
READERS=(
    'curl -sf https://example.com/:curl -sf (the /resume skill step 5 form)'
    'curl -s -o /dev/null -w "%{http_code}" https://example.com/:curl status probe, -o /dev/null'
    'curl https://example.com/ -H "x: y":curl with a header'
    'curl -s https://example.com/ | jq .:curl piped to jq'
    'curl --output-dir /tmp https://example.com/:curl --output-dir alone (a directory option, not a write)'
)

echo
echo "--- a fetch that lands in a file is refused with no active task"
for spec in "${WRITERS[@]}"; do
    cmd="${spec%:*}"; desc="${spec##*:}"
    run "$HOOK" "$cmd"
    [ "$RC" -ne 0 ] && ok "refused: $desc" || bad "ADMITTED with no task — writes a file unguarded: $desc"
done

echo
echo "--- a fetch that only reads stays admitted (the guard must not cost us the read path)"
for spec in "${READERS[@]}"; do
    cmd="${spec%:*}"; desc="${spec##*:}"
    run "$HOOK" "$cmd"
    [ "$RC" -eq 0 ] && ok "admitted: $desc" || bad "READ PATH BROKEN — over-broad guard: $desc"
done

# ---------------------------------------------------------------------------
echo
echo "--- teeth: strip the two guards and the downloads must come straight back"
python3 - "$LIB" "$MUTANT_LIB" <<'PY'
import sys
# Located by scanning for the guard's OPENING line and deleting through its matching
# `    fi`, rather than by one large regex. A regex over shell source has to re-encode
# the guard's own backslashes (\bcurl\b) at two levels of quoting, and getting that
# wrong is how the first draft of this mutation failed — loudly, but it still failed.
lines = open(sys.argv[1]).read().splitlines(keepends=True)
def drop_guard(lines, needle):
    for i, ln in enumerate(lines):
        if needle in ln and ln.lstrip().startswith("if "):
            for j in range(i + 1, len(lines)):
                if lines[j].rstrip("\n") == "    fi":
                    return lines[:i] + lines[j + 1:], True
            break
    return lines, False
out, got_curl = drop_guard(lines, r"grep -qE '\bcurl\b")
out, got_wget = drop_guard(out,   r"grep -qE '\bwget\b'")
if not (got_curl and got_wget):
    sys.stderr.write("MUTATION FAILED: curl guard found=%s, wget guard found=%s.\n"
                     "The guards' shape changed — fix this mutation rather than pinning a copy.\n"
                     % (got_curl, got_wget))
    sys.exit(1)
if out == lines:
    sys.stderr.write("MUTATION FAILED: replacement was a no-op.\n"); sys.exit(1)
open(sys.argv[2], "w").write("".join(out))
PY
[ $? -eq 0 ] || { echo "COULD-NOT-MEASURE: could not derive the pre-fix mutant from live source." >&2; exit 3; }

# The hook sources its library as "$SCRIPT_DIR/lib/safe-commands.sh"; point that one
# line at the mutant library so the ORDERING under test stays the real hook's.
python3 - "$HOOK" "$MUTANT" "$MUTANT_LIB" <<'PY'
import sys
src = open(sys.argv[1]).read()
anchor = '    source "$SCRIPT_DIR/lib/safe-commands.sh" 2>/dev/null || true\n'
if src.count(anchor) != 1:
    sys.stderr.write("MUTATION FAILED: %d occurrence(s) of the library source line, expected 1.\n"
                     % src.count(anchor))
    sys.exit(1)
open(sys.argv[2], "w").write(src.replace(anchor, '    source "%s" 2>/dev/null || true\n' % sys.argv[3], 1))
PY
[ $? -eq 0 ] || { echo "COULD-NOT-MEASURE: could not repoint the mutant hook at the mutant library." >&2; exit 3; }

MUT_ADMITS=0
for spec in "${WRITERS[@]}"; do
    cmd="${spec%:*}"
    run "$MUTANT" "$cmd"
    [ "$RC" -eq 0 ] && MUT_ADMITS=$((MUT_ADMITS+1))
done
if [ "$MUT_ADMITS" -eq "${#WRITERS[@]}" ]; then
    ok "pre-fix mutant admits all ${#WRITERS[@]} downloads — the guards are what refuse them"
else
    bad "mutant admits only $MUT_ADMITS/${#WRITERS[@]} — the mutation no longer reproduces the defect, so these legs prove nothing"
fi

# And the mutant must AGREE on the readers: this task refused downloads, it did not
# change the read path. A mutant that disagreed here would mean the guard moved
# something it was never supposed to touch.
MUT_READS=0
for spec in "${READERS[@]}"; do
    cmd="${spec%:*}"
    run "$MUTANT" "$cmd"
    [ "$RC" -eq 0 ] && MUT_READS=$((MUT_READS+1))
done
[ "$MUT_READS" -eq "${#READERS[@]}" ] \
    && ok "readers were admitted before too — this task claims no credit for them" \
    || bad "the guards changed a verdict on the read path ($MUT_READS/${#READERS[@]} admitted before)"

# ---------------------------------------------------------------------------
echo
echo "--- ordering: the write verdict beats the allowlist, and does not merely fall through"
# `curl` is ON the safe-list. That is the whole point of this leg: the only reason a
# download is refused is that the write-check runs first AND exits rather than falling
# through to a later branch that would admit it — the exact defect T-638 found in the
# same function's neighbourhood. Proven by construction: same command, same allowlist,
# opposite verdicts, with the guards as the only difference.
run "$HOOK"   'curl -o out.txt https://example.com/f'; REAL=$RC
run "$MUTANT" 'curl -o out.txt https://example.com/f'; MUT=$RC
if [ "$REAL" -ne 0 ] && [ "$MUT" -eq 0 ]; then
    ok "curl is safe-listed in BOTH, yet refused only with the guards — the write-check wins and exits"
else
    bad "ordering not demonstrated (real=$REAL mutant=$MUT); a fall-through here would admit the download"
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
