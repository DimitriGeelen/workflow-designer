#!/bin/bash
# T-866 (arc-004) — teeth for the Hypothesis gate.
#
# WHAT IT DEFENDS. The BVP method pairs every value-driver table with a hypothesis
# in a fixed three-part form. The framework implemented Support x Weight and not
# the hypothesis, so a support score has had no referent: it can rank, but it
# cannot be WRONG, because there is no claim for it to be wrong about. This gate
# makes a GO decision require that claim.
#
# THE FAILURE MODE THIS SUITE IS SHAPED AROUND IS NOT "the gate does not fire".
# It is T-624's failure, repeated with a worse exit code. T-624 chose a warning as
# its prevention; the warning was correct, emphatic, and physically adjacent to the
# field it governed, and the number it tracked did not move in 28 days. A gate that
# refuses EVERYTHING is just as useless — authors route around it — and a gate that
# refuses NOTHING is the warning again. So the suite pins both edges:
#   - the vague-but-sincere clause must be REFUSED (that is the real population)
#   - a genuinely checkable clause must be ACCEPTED (or authors learn to bypass)
#   - NO-GO and DEFER must pass untouched (they take on no claim; gating them is
#     bureaucracy, and bureaucracy is how a gate loses its legitimacy)
#
# THE AGENT CANNOT RUN THE LIVE PATH. The inception decision verb is Tier 0 and
# fires on the phrase in any command text, so these teeth exercise the audit
# function directly against fixtures. The end-to-end wiring is a Human AC on T-866,
# stated as such rather than quietly skipped — this suite proves the predicate,
# not the plumbing, and says so.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
SUBJECT="${SUBJECT:-$ROOT/.agentic-framework/lib/task-audit.sh}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t866.XXXXXX")"
trap 'rm -rf "$WORK"; rm -f "${MUT:-}"' EXIT

PASS=0; FAIL=0
# unreadable_file_errors belongs with the GATE cases, not the controls. It was
# filed as a control first and the mutation run refused: an always-pass stub
# returns 0 for a missing file too, so the rc=2 path dies with everything else.
# Third time today a control set has corrected a classification of mine rather
# than found a defect in the subject — the reflex "a surviving case means missing
# coverage" is wrong about as often as it is right, and the first hypothesis
# should be that the case is in the wrong bucket.
#
# FOURTH correction, same run: research_kind_exempt was filed as a control too.
# It asserts rc=0 AND that the output SAYS "exempt" — and the always-pass stub
# returns 0 silently, so the message assertion dies with the body. The message is
# kept rather than weakened: an exemption that fires without saying so is an
# unobservable escape hatch, which is the thing this gate is designed not to be.
GATE_CASES="empty_section_refused missing_clause_refused vague_success_refused refusal_names_what_is_missing unreadable_file_errors research_word_in_body_still_gated research_kind_exempt"
CONTROL_CASES="checkable_success_accepted nogo_passes_untouched defer_passes_untouched"

ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

grep -q 'audit_inception_hypothesis()' "$SUBJECT" || {
    echo "TEETH BROKEN — audit_inception_hypothesis not found in $SUBJECT."
    echo "This probe can no longer test what it claims to test. Not reporting a pass."
    exit 4; }

mk() { # $1 = file, $2 = hypothesis body, $3 = extra frontmatter line, $4 = problem text
    { printf -- '---\nid: T-9992\nworkflow_type: inception\n'
      [ -n "${3:-}" ] && printf '%s\n' "$3"
      printf -- '---\n\n'
      printf '## Problem Statement\n\n%s\n\n' "${4:-something}"
      printf '## Hypothesis\n\n%s\n\n' "$2"
      printf '## Assumptions\n\nnone\n'
    } > "$1"
}

FULL_VAGUE="We believe that we will refactor the scheduler,
we will achieve a cleaner system.
We will know that we are successful when the system is better and the team is happier."
FULL_GOOD="We believe that adding an import guard,
we will achieve rejection of malformed BPMN.
We will know that we are successful when we see 0 fabricated lanes across all 24 corpus maps."
FULL_WORDY_GOOD="We believe that tightening the absence control,
we will achieve honest failure reporting.
We will know that we are successful when the probe no longer reports a pass for a file it never read."

run_gate() { # $1 = file, $2 = decision -> prints stderr, returns rc
    ( set +e
      source "$SUBJECT" 2>/dev/null
      audit_inception_hypothesis "$1" "$2" 2>&1
      echo "RC=$?" )
}

# ── mutation ────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--mutation" ]; then
    MUT="$(dirname "$SUBJECT")/.t866-mutated-$$.sh"
    python3 - "$SUBJECT" "$MUT" <<'PYEOF'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
m = re.search(r"\naudit_inception_hypothesis\(\) \{.*?\n\}\n", t, re.S)
if not m:
    sys.exit("mutation anchor not found — audit_inception_hypothesis was renamed or removed")
# The gate accepts everything: the classic "prevention that refuses nothing".
t = t[:m.start()] + "\naudit_inception_hypothesis() { return 0; }\n" + t[m.end():]
open(dst, "w").write(t)
PYEOF
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutant"; exit 1; }
    bash -n "$MUT" || { echo "MUTATION SETUP FAILED: mutant does not parse"; exit 1; }
    echo "=== T-866 MUTATION RUN (gate accepts everything — T-624's failure) ==="
    out=$(SUBJECT="$MUT" bash "${BASH_SOURCE[0]}" 2>&1)
    printf '%s\n' "$out" | sed 's/^/  | /'
    echo
    broken=""
    for c in $CONTROL_CASES; do
        printf '%s' "$out" | grep -q "PASS  $c\$" || broken="$broken $c"
    done
    if [ -n "$broken" ]; then
        echo "MUTATION SETUP BROKEN — cases that should survive an always-pass gate also failed:$broken"
        echo "The mutant is not blind, it is broken. Every red above is false."
        exit 1
    fi
    survivors=""
    for c in $GATE_CASES; do
        printf '%s' "$out" | grep -q "PASS  $c\$" && survivors="$survivors $c"
    done
    [ -n "$survivors" ] && { echo "MUTATION FAILED — these pass against a gate that refuses nothing:$survivors"; exit 1; }
    echo "MUTATION OK — controls green, every refusal case went red."
    exit 0
fi

echo "=== T-866 Hypothesis-gate teeth ==="
echo "subject: $SUBJECT"
echo

# ── GATE CASES: the refusals ────────────────────────────────────────────────
mk "$WORK/empty.md" ""
out=$(run_gate "$WORK/empty.md" go)
if printf '%s' "$out" | grep -q 'RC=1' && printf '%s' "$out" | grep -q 'missing or empty'; then
    ok empty_section_refused
else bad empty_section_refused "an absent hypothesis was accepted for GO: $(printf '%s' "$out" | tr '\n' '/')"; fi

mk "$WORK/partial.md" "We believe that the importer is wrong, and we should fix it."
out=$(run_gate "$WORK/partial.md" go)
if printf '%s' "$out" | grep -q 'RC=1' && printf '%s' "$out" | grep -q 'three-part form'; then
    ok missing_clause_refused
else bad missing_clause_refused "a one-clause hypothesis passed: $(printf '%s' "$out" | tr '\n' '/')"; fi

mk "$WORK/vague.md" "$FULL_VAGUE"
out=$(run_gate "$WORK/vague.md" go)
if printf '%s' "$out" | grep -q 'RC=1' && printf '%s' "$out" | grep -q 'nothing anyone could go and look at'; then
    ok vague_success_refused
else bad vague_success_refused "THE REAL POPULATION passed — a sincere vague clause is the failure that actually occurs: $(printf '%s' "$out" | tr '\n' '/')"; fi

# A refusal that does not tell the author what to do is a warning with a worse
# exit code, which is precisely T-624's failure.
out=$(run_gate "$WORK/partial.md" go)
if printf '%s' "$out" | grep -q "we will achieve"; then
    ok refusal_names_what_is_missing
else bad refusal_names_what_is_missing "the refusal did not name the absent clause"; fi

# ── CONTROL CASES: what must NOT be refused ─────────────────────────────────
mk "$WORK/good.md" "$FULL_GOOD"
out=$(run_gate "$WORK/good.md" go)
if printf '%s' "$out" | grep -q 'RC=0'; then ok checkable_success_accepted
else bad checkable_success_accepted "a checkable clause was refused — authors route around a gate that refuses everything: $(printf '%s' "$out" | tr '\n' '/')"; fi

out=$(run_gate "$WORK/vague.md" no-go)
if printf '%s' "$out" | grep -q 'RC=0'; then ok nogo_passes_untouched
else bad nogo_passes_untouched "NO-GO was gated; it takes on no claim, so this is bureaucracy"; fi

out=$(run_gate "$WORK/vague.md" defer)
if printf '%s' "$out" | grep -q 'RC=0'; then ok defer_passes_untouched
else bad defer_passes_untouched "DEFER was gated; it takes on no claim"; fi

out=$(run_gate "$WORK/nope.md" go)
if printf '%s' "$out" | grep -q 'RC=2'; then ok unreadable_file_errors
else bad unreadable_file_errors "a missing file did not report rc=2 — it must be distinguishable from a refusal"; fi

# Prose-form acceptance is reported but not gated on: it documents that the
# observability proxy accepts a non-numeric but genuinely checkable clause.
out=$(run_gate "$WORK/good2.md" go) 2>/dev/null
mk "$WORK/good2.md" "$FULL_WORDY_GOOD"
out=$(run_gate "$WORK/good2.md" go)
printf '%s' "$out" | grep -q 'RC=0' \
  && echo "  note  non-numeric but checkable clause accepted ('no longer reports')" \
  || echo "  note  non-numeric checkable clause REFUSED — proxy is stricter than intended"

# ── The research exemption (operator 2026-09-26) ───────────────────────────
# Not every inception carries a claim; "research how X works" produces
# understanding. Forcing it into "we will achieve <outcome>" would manufacture
# a fake claim to pass a gate, which teaches authors to write fiction.
mk "$WORK/research.md" "" "inception_kind: research"
out=$(run_gate "$WORK/research.md" go)
if printf '%s' "$out" | grep -q 'RC=0' && printf '%s' "$out" | grep -q 'exempt'; then
    ok research_kind_exempt
else bad research_kind_exempt "a declared research inception was still gated: $(printf '%s' "$out" | tr '\n' '/')"; fi

# THE CASE THAT KEEPS THE EXEMPTION HONEST. It must require the DECLARED field,
# not the word appearing somewhere in the prose — otherwise every inception that
# mentions research escapes, and the gate has a hole shaped like a common word.
mk "$WORK/researchword.md" "" "" "We need to research how the importer handles lanes. Research is the point."
out=$(run_gate "$WORK/researchword.md" go)
if printf '%s' "$out" | grep -q 'RC=1'; then
    ok research_word_in_body_still_gated
else bad research_word_in_body_still_gated "the word 'research' in prose exempted the task — the exemption must be a declared field, not a word match"; fi


echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
