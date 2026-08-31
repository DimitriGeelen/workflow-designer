#!/usr/bin/env bash
# T-660 — the actionability checker must actually discriminate, and must not be fooled by
# the worked examples the task template keeps inside an HTML comment.
#
# WHY THE COMMENT LEG IS THE IMPORTANT ONE. Every task file carries [REVIEW] and [REVIEWER]
# examples — with real `- [ ]` boxes AND complete Steps/Expected/If-not — inside the ###
# Human section's comment. An instrument that counts them reports perfect actionability for
# every task in the queue, which is the exact failure this instrument exists to prevent.
# T-655 hit this same trap from the other direction, so it is asserted, not assumed.
#
# Fixtures only. This never reads the project's real tasks.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

# T-661: mutation completeness is asserted by the shared helper — "the original form is
# gone", not "my marker appears exactly N times". See tools/lib/mutation-assert.sh.
. "$(dirname "${BASH_SOURCE[0]}")/lib/mutation-assert.sh"

PROJ="${T660_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CHECKER="$PROJ/tools/_t660-human-ac-actionability.py"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$CHECKER" ] || { echo "COULD-NOT-MEASURE: $CHECKER not found" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-660: the actionability checker must have teeth ==="
echo

# write_task <root> <id> <owner> <human-section-body>
write_task() {
    local root="$1" id="$2" owner="$3" human="$4"
    mkdir -p "$root/.tasks/active"
    {
        echo "---"
        echo "id: $id"
        echo "name: \"fixture\""
        echo "status: work-completed"
        echo "owner: $owner"
        echo "---"
        echo ""
        echo "## Acceptance Criteria"
        echo ""
        echo "### Agent"
        echo "- [x] done"
        echo ""
        echo "### Human"
        printf '%s\n' "$human"
        echo ""
        echo "## Updates"
    } > "$root/.tasks/active/$id-fixture.md"
}

ACTIONABLE='- [ ] [REVIEW] Approve the thing
  **Steps:**
  1. Run: `cd /opt/x && bin/fw task review T-001`
  **Expected:** Decision recorded
  **If not:** Ask the agent'

run_checker() { ( cd "$1" && PROJECT_ROOT="$1" python3 "$CHECKER" 2>&1; echo "rc$?" ); }

# ---------------------------------------------------------------------------
echo "--- a well-formed Human AC passes"
R="$TMP/a"; write_task "$R" T-001 human "$ACTIONABLE"
OUT=$(run_checker "$R")
if echo "$OUT" | grep -q 'rc0' && echo "$OUT" | grep -q 'OK —'; then
    ok "actionable queue -> exit 0"
else
    bad "a well-formed AC was rejected: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- an unresolved placeholder is caught, and named"
R="$TMP/b"; write_task "$R" T-002 human "${ACTIONABLE/T-001/T-XXX}"
OUT=$(run_checker "$R")
if echo "$OUT" | grep -q 'rc1' && echo "$OUT" | grep -q 'T-002' && echo "$OUT" | grep -q "placeholder 'T-XXX'"; then
    ok "the exact defect from the live queue is caught and named"
else
    bad "placeholder not caught: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- each missing block is reported specifically, not as one lump"
for spec in "**Steps:**|no Steps" "**Expected:**|no Expected" "**If not:**|no If-not"; do
    marker="${spec%%|*}"; want="${spec#*|}"
    R="$TMP/c-$RANDOM"
    # -F: these markers contain * and : and must be matched literally, not as a regex.
    write_task "$R" T-003 human "$(printf '%s\n' "$ACTIONABLE" | grep -Fv "$marker")"
    OUT=$(run_checker "$R")
    if echo "$OUT" | grep -q 'rc1' && echo "$OUT" | grep -q "$want"; then
        ok "missing '$marker' reported as '$want...'"
    else
        bad "missing '$marker' not reported specifically: $(echo "$OUT" | tr '\n' ' ' | head -c 160)"
    fi
done

# ---------------------------------------------------------------------------
# THE TRAP. A task whose ONLY well-formed criteria live inside the template's HTML comment
# must be reported as not actionable. An instrument reading through the comment sees a
# perfect Steps/Expected/If-not and passes it.
echo "--- worked examples inside an HTML comment do not count as actionability"
R="$TMP/d"
write_task "$R" T-004 human '- [ ] [REVIEW] Approve the thing
<!--
  [REVIEW] example (genuine human judgment):
    - [ ] [REVIEW] Dashboard renders correctly
      **Steps:**
      1. Open the dashboard
      **Expected:** All panels visible
      **If not:** Screenshot the broken panel
-->'
OUT=$(run_checker "$R")
if echo "$OUT" | grep -q 'rc1' && echo "$OUT" | grep -q 'no Steps'; then
    ok "commented example does not launder a bare criterion into an actionable one"
else
    bad "the checker read through the HTML comment — every task would look perfect: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- a ticked criterion is not the queue's problem, and an agent task is not the queue"
# `${VAR/- [ ]/...}` cannot do this: in a bash replacement pattern `[ ]` is a glob character
# class, so it matches a single space rather than the literal brackets. sed, with -F-style
# literal intent spelled out.
R="$TMP/e"
write_task "$R" T-005 human "$(printf '%s\n' "$ACTIONABLE" | sed -e 's/^- \[ \]/- [x]/' -e '/\*\*Steps:\*\*/d')"
OUT=$(run_checker "$R")
TICKED_OK=$(echo "$OUT" | grep -c 'rc0' || true)
R="$TMP/f"; write_task "$R" T-006 agent "$(printf '%s\n' "$ACTIONABLE" | sed 's/T-001/T-XXX/')"
OUT2=$(run_checker "$R")
if [ "$TICKED_OK" -eq 1 ] && echo "$OUT2" | grep -q 'rc0'; then
    ok "already-ticked ignored; a non-human-owned task is not counted as live queue"
else
    bad "scope wrong: ticked_rc0=$TICKED_OK agent_out=$(echo "$OUT2" | tr '\n' ' ' | head -c 140)"
fi

# ---------------------------------------------------------------------------
# Found the hard way: the first matcher demanded the literal `**Steps:**` and flagged two of
# the best-written ACs in the live queue. A chosen-set assertion finds only the spellings its
# author thought of, and this one would have had me rewrite good prose to satisfy it.
echo "--- real-world block spellings are accepted, not just the template's exact wording"
R="$TMP/g"
write_task "$R" T-007 human '- [ ] [REVIEW] Pick the new baseline ref
  **Steps — option A (recommended), register it as a Stop hook:**
  1. Run: `cd /opt/x && bin/fw hook-enable --name thing`
  **Expected:** the gate goes green
  **If it is still red after that:** the residue is something later than the stamp'
OUT=$(run_checker "$R")
if echo "$OUT" | grep -q 'rc0'; then
    ok "variant Steps/If- headings accepted — actionability, not house style"
else
    bad "a well-written AC was flagged on wording: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- teeth: blind the comment stripper and the trap fixture must flip to actionable"
MUT="$TMP/checker-mutant.py"
sed 's|^COMMENT = re.compile(r"<!--.\*?-->", re.S)|COMMENT = re.compile(r"(?!x)x")|' "$CHECKER" > "$MUT"
BASE=$(run_checker "$TMP/d")
# T-661: completeness, not a marker count. See tools/lib/mutation-assert.sh.
if ! MUTATED=$(assert_mutation_complete "$CHECKER" "$MUT" '^COMMENT = re.compile(r"<!--' 'comment stripper'); then
    bad "$MUTATED"
elif ! echo "$BASE" | grep -q 'rc1'; then
    # PL-297/PL-299: the unmutated subject must demonstrably fail this fixture first.
    bad "PRECONDITION FAILED — unmutated checker already passes the trap fixture, so the mutant proves nothing"
else
    OUT=$( cd "$TMP/d" && PROJECT_ROOT="$TMP/d" python3 "$MUT" 2>&1; echo "rc$?" )
    if echo "$OUT" | grep -q 'rc0'; then
        ok "mutant passes a fixture the real checker demonstrably fails — the strip is load-bearing"
    else
        bad "mutant behaved identically; the comment leg cannot fail and proves nothing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
