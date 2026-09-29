#!/usr/bin/env bash
# _t820-rule-axes.sh — run EVERY classification axis a validator rule must satisfy.
#
# T-820. Adding one rule (E-XML-ABBR-DUP, T-816) requires satisfying FIVE independent axes
# maintained in five separate files. T-816 satisfied TWO, wrote verification legs for those
# two, and passed its own gate — because the legs were as incomplete as the work. The other
# THREE were found only by running the 784-second suite afterwards, one of them only after
# this tool had already been written claiming there were four.
#
# THE FIVE, and each exists for a different reason:
#
#   form parity      tests/test_rule_form_parity.py
#                    Does the OTHER form need this rule? PAIRED / GAP / OUT_OF_SCOPE.
#                    "Adding a rule to one form without deciding whether the other form
#                     needs it is exactly the T-317 class."
#
#   dialect axis     tests/test_rule_dialect_axis.py
#                    WHAT does the rule read, and is that carrier governance-bearing or
#                    presentational? "Until it does, nothing knows whether surfacing it to
#                     an author states a correctness fact or a house convention."
#
#   anchorability    tests/test_finding_anchorability.py
#                    CAN the canvas point at the thing? "An unclassified rule is measured
#                     against the wrong population and manufactures a false answer."
#
#   cross-form       tests/test_harness_cross_form_agreement.py
#                    Do the two implementations actually AGREE on a real document? Marking a
#                    rule PAIRED is a CLAIM; this is what tests it. "A rule added to the
#                     parity table without a behavioural decision would be reported as
#                     agreeing by a guard that never compared it."
#
#   pass reachability tests/test_check_pass_reachability.py
#                    Has anyone ever SEEN it fire, on a document that lives in the tree?
#                    "A rule nobody has ever seen fire is a rule nobody has shown to work --
#                     add a fixture, or declare it here with the reason." A control probe
#                    that mutates a throwaway copy does not satisfy this, and should not:
#                    the witness has to outlive the run that made it.
#
# WHY A SINGLE COMMAND. Each axis already fails loudly and correctly — the machinery was
# never the problem. The problem is that they are discoverable only by having met them, so
# the author who knows two writes legs for two. This is the caller that knows all of them.
#
# This file was itself written listing FOUR, and the fifth was found minutes later by the
# suite. That is the argument for the tool rather than against it: the list belongs
# somewhere a reader can extend, not in the head of whoever last added a rule. ADD TO `AXES`
# when a sixth appears — and it is a when.
#
# Run it when adding or changing a validator rule; put it in that task's ## Verification.
#
# Exit: 0 all axes pass | 1 an axis failed | 3 an axis is missing from the tree

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# T-826. THIS RUNNER IS WHOLE-SUITE AND HAS NO PER-RULE MODE. It never read $1,
# and the docstring above ("put it in that task's ## Verification") invites a
# caller to pass the rule it just added and read the verdict as being ABOUT that
# rule. It is not. Measured under T-826 by control: `_t820-rule-axes.sh
# E-WORKFLOW-KIND`, `... E-TOPLEVEL-MISSING` and `... E-NOT-A-REAL-RULE` produced
# BYTE-IDENTICAL output -- a rule id that does not exist scored the same as one
# that does. So when the five suites are green this runner hands any caller a
# green earned by OTHER PEOPLE'S rules, and when they are red (4/5 are, today) it
# hands them a red they did not cause. Silently. That is the T-816 defect this
# file exists to prevent, wearing this file as a costume.
#
# Refusing is the fix rather than implementing a filter: a per-rule verdict means
# each of the five suites growing a rule-scoped mode, which is real work and is
# T-927. Until then the honest answer to "does MY rule satisfy the axes" is a
# task-local teeth script that greps this runner's failure lines for its own rule
# id and carries a control proving that grep can fail -- see
# tools/_t826-kind-rule-axes-teeth.sh for the pattern.
if [ "$#" -gt 0 ]; then
    cat >&2 <<REFUSAL
REFUSED: $(basename "$0") takes no arguments; it got $# ("$1").
  This runner is WHOLE-SUITE. It runs five axis files over EVERY validator rule
  and reports their exit codes. It has never filtered by rule, so a verdict read
  as being about "$1" is a verdict about the whole tree -- green because of other
  rules, or red because of them.
  Run it with no arguments for the suite verdict. For a per-rule answer, write a
  rule-scoped check that names your rule and carries a control proving it can
  fail; tools/_t826-kind-rule-axes-teeth.sh is the worked example. Per-rule modes
  in the five suites themselves are T-927.
REFUSAL
    exit 2
fi

AXES=(
  "form parity:tests/test_rule_form_parity.py"
  "dialect axis:tests/test_rule_dialect_axis.py"
  "anchorability:tests/test_finding_anchorability.py"
  "cross-form agreement:tests/test_harness_cross_form_agreement.py"
  "pass reachability:tests/test_check_pass_reachability.py"
)

PASS=0; FAIL=0
FAILED_AXES=""

echo "=== T-820: every classification axis a validator rule must satisfy ==="

for entry in "${AXES[@]}"; do
    label="${entry%%:*}"
    path="${entry#*:}"
    if [ ! -f "$REPO/$path" ]; then
        # A missing axis is not a passing one. If an axis file is renamed or deleted, this
        # must say so rather than quietly checking three of four — that is the exact shape
        # of the defect this tool exists for, one level up.
        printf 'COULD-NOT-MEASURE: axis %-22s missing: %s\n' "$label" "$path" >&2
        exit 3
    fi
    if python3 "$REPO/$path" >/dev/null 2>&1; then
        PASS=$((PASS + 1))
        printf '  ok   %-22s %s\n' "$label" "$path"
    else
        FAIL=$((FAIL + 1))
        FAILED_AXES="$FAILED_AXES $label"
        printf '  FAIL %-22s %s\n' "$label" "$path"
    fi
done

echo
if [ "$FAIL" -eq 0 ]; then
    echo "all $PASS axes pass"
    exit 0
fi

echo "FAILED AXES:$FAILED_AXES" >&2
echo >&2
echo "  Run the named file directly — each prints which rule is unclassified and why the" >&2
echo "  classification matters. Do NOT classify a rule to make a check green: each axis" >&2
echo "  asks a different real question, and the cross-form axis in particular tests a" >&2
echo "  CLAIM (that two implementations agree) rather than a declaration." >&2
exit 1
