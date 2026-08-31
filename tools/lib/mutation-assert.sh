#!/usr/bin/env bash
# Shared mutation-completeness assertion for the tools/_t*.sh prober family.
#
# WHY THIS EXISTS (T-661, from 999-AEF at rail @897).
#
# Every mutation leg in this repo asserted its mutation had landed by counting the
# SUBSTITUTED marker and pinning that count to an exact number:
#
#     MUTATED=$(grep -c 'if false; then' "$MUT")
#     if [ "$MUTATED" -ne 1 ]; then bad "MUTATION FAILED — got $MUTATED"; fi
#
# AEF hit the same shape in a bats assertion of theirs and named it exactly: an EQUALITY
# where the invariant is a FLOOR. Their suite went red for adding a THIRD correct call
# site of a thing that should have had no upper bound at all. Ours has the same booby
# trap: add a second legitimate site to any mutated subject and the prober reports
# "MUTATION FAILED" for a change that made its teeth STRONGER.
#
# There is a second defect underneath, which is the one that decides the fix. Counting
# the marker asks "did my substitution text appear?" — but `if false; then` is a string
# the subject may already contain for unrelated reasons, and a count of 1 cannot tell a
# landed mutation from a coincidence. The question the leg actually needs answered is
# whether the ORIGINAL form is GONE. So:
#
#     before = occurrences of the original form in the SUBJECT   -> must be >= 1
#     after  = occurrences of the original form in the MUTANT    -> must be 0
#
# That is strictly stronger than either the equality or a bare floor:
#   - before == 0 catches a STALE ANCHOR — a sed that matched nothing because the subject
#     moved under it. The old form could not distinguish this from a real mutation when
#     the marker happened to appear anyway; it is the failure that certifies teeth the
#     prober does not have.
#   - after > 0 catches a PARTIAL mutation — the half-mutated subject that reads like a
#     passing one.
#   - neither has an upper bound, so N correct sites mutate to N and the leg stays green.
#
# We already held PL-061 ("assert failure-SHAPE, never pin totals") from T-305 and PL-075
# ("witnesses over counts") from T-330 when all six of these were written. The learnings
# existed and did not reach the code. One writer, in one file, is the part that does.

# assert_mutation_complete <subject_file> <mutant_file> <original_pattern> [label]
#
# Echoes a one-line diagnosis to stdout and returns non-zero when the mutation is not
# demonstrably complete; returns 0 silently when it is. Callers keep their own ok/bad
# reporting, so this stays a predicate and never decides a leg's verdict for it.
#
# <original_pattern> is a BRE for grep, matched against the PRE-mutation form. Anchor it
# the same way the sed that produced the mutant is anchored, or the two can disagree.
assert_mutation_complete() {
    local subject="$1" mutant="$2" pattern="$3" label="${4:-mutation}"
    local before after

    if [ ! -f "$subject" ]; then
        echo "MUTATION UNMEASURABLE — subject '$subject' does not exist"
        return 1
    fi
    if [ ! -f "$mutant" ]; then
        echo "MUTATION UNMEASURABLE — mutant '$mutant' does not exist"
        return 1
    fi

    before=$(grep -c -- "$pattern" "$subject" 2>/dev/null || true)
    after=$(grep -c -- "$pattern" "$mutant" 2>/dev/null || true)
    before=${before:-0}
    after=${after:-0}

    if [ "$before" -lt 1 ]; then
        # The anchor no longer matches the subject at all. Every downstream leg would
        # then be comparing the subject against an identical copy of itself.
        echo "STALE ANCHOR — the $label pattern matches 0 sites in the subject; the sed had nothing to mutate and the 'mutant' is an unmodified copy"
        return 1
    fi
    if [ "$after" -ne 0 ]; then
        echo "MUTATION INCOMPLETE — $after of $before $label site(s) survived; a half-mutated subject reads like a passing one"
        return 1
    fi
    return 0
}
