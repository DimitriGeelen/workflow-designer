#!/usr/bin/env bash
# _t353-repair-probe.sh — T-353 AC1 + AC3: prove the proposed repairs discriminate.
#
# T-352 found 4 latent lines of the form
#     out=$(python3 tools/validate-workflow.py DOC 2>&1); echo "$out" | grep -q "VALID"
# They pass honestly today BECAUSE their documents are valid.  The moment a document goes
# invalid they keep passing — `grep -q "VALID"` matches `INVALID` as a substring — which is
# precisely the case the check exists to catch.  The repair is `grep -q "^VALID"`.
#
# ── WHAT MAKES THIS A PROOF RATHER THAN A RE-ASSERTION ─────────────────────────────────
# "The repaired line still passes" is worthless: so does the broken one.  Four legs per
# target, and leg 1 is the one that carries the argument:
#   1  ORIGINAL  + rejected doc + CURRENT gate  -> must PASS   (the defect, reproduced)
#   2  REPAIRED  + rejected doc + CURRENT gate  -> must FAIL   (the defect, removed)
#   3  REPAIRED  + real doc     + CURRENT gate  -> must PASS   (no regression)
#   4  REPAIRED  + real doc     + REMEDY gate   -> must PASS   (corpus ready for the fix)
# Without leg 1 the repair could be a no-op and legs 2-4 would read identically.  Without
# leg 3 a pattern that refuses EVERYTHING scores perfectly.  Leg 4 is what AC3 means by
# "ready" rather than merely "changed" — it is the only leg run under the remedy.
#
# The gate construct is EXTRACTED from update-task.sh at runtime, exactly as the T-352
# probe does, so this measures the real gate and not a quote of it.  When the remedy lands,
# legs 1 go red by design: the defect they reproduce will no longer exist.
set -uo pipefail

# T-787: ROOT is overridable so a COPY of this probe can be negative-controlled without
# silently re-rooting onto wherever the copy happens to live. PL-193 — a harness that
# derives its subject from its own file location answers confidently about the wrong
# subject; the first attempt at controlling the legs below hit exactly that and reported
# a failure that had nothing to do with the poison.
ROOT="${PROBE_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
GATE_SRC="${GATE_SRC:-$ROOT/.agentic-framework/agents/task-create/update-task.sh}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A document the validator rejects.  Real fixture, not a fabricated one.
REJECTED="tests/fixtures/invalid/E-XML-NODE-TYPE.xml"

pass=0; fails=0
ok()   { echo "  ok   $*"; pass=$((pass+1)); }
fail() { echo "FAIL $*" >&2; fails=$((fails+1)); }

echo "== T-353 repair probe (AC1 + AC3) =="

GATE_COND="$(python3 - "$GATE_SRC" <<'PY'
import re, sys
src = open(sys.argv[1]).read().splitlines()
hits = [l for l in src if re.match(r'^\s*if .*\$cmd', l)]
if len(hits) != 1:
    sys.stderr.write("EXTRACT_ERROR: expected exactly 1 gate line matching '^\\s*if .*$cmd', found %d\n" % len(hits))
    sys.exit(1)
line = hits[0].strip()
line = re.sub(r'^if\s+', '', line)
line = re.sub(r';\s*then$', '', line)
print(line)
PY
)" || GATE_COND=""

if [ -z "$GATE_COND" ]; then
  fail "EXTRACT: could not read the verification construct out of $GATE_SRC. A probe that cannot locate its subject has measured nothing, so this is red on purpose."
  echo; echo "probe: $pass passed, $fails failed"; exit 1
fi

# The remedy construct, derived from the extracted one by the same substitution the
# report proposes — not typed out separately, so the two cannot drift apart.
REMEDY_COND="$(printf '%s' "$GATE_COND" | sed 's/eval "\$cmd"/bash -c '"'"'set -eo pipefail; eval "$1"'"'"' _ "$cmd"/')"
if [ "$REMEDY_COND" = "$GATE_COND" ]; then
  fail "REMEDY: substitution produced an identical construct — legs 4 would measure the current gate twice and silently report readiness. Red on purpose."
  echo; echo "probe: $pass passed, $fails failed"; exit 1
fi

echo "current gate: $GATE_COND"
echo

run_gate() {
  local cond="$1" cmd="$2" f out
  f="$TMP/runner.$$.$RANDOM.sh"
  {
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'
    echo '_close_locks_cmd=""'
    printf 'PROJECT_ROOT=%q\n' "$ROOT"
    echo 'cmd="$CMD_UNDER_TEST"'
    printf 'if %s; then echo GATE_PASS; else echo GATE_FAIL; fi\n' "$cond"
  } > "$f"
  out="$(CMD_UNDER_TEST="$cmd" bash "$f" 2>/dev/null | tail -1)"
  case "$out" in GATE_PASS|GATE_FAIL) echo "$out" ;; *) echo "GATE_BROKEN($out)" ;; esac
}

check() {  # $1 expected  $2 actual  $3 label
  if [ "$2" = "$1" ]; then ok "$3"; else fail "$3 : expected $1, got $2"; fi
}

orig_line()  { printf 'out=$(python3 tools/validate-workflow.py %s 2>&1); echo "$out" | grep -q "VALID"' "$1"; }
fixed_line() { printf 'out=$(python3 tools/validate-workflow.py %s 2>&1); echo "$out" | grep -q "^VALID"' "$1"; }

# The four targets, as they appear in the archived task files, each with the verdict its
# REAL document is expected to produce.
#
# T-299 is VALID_DOC=no and that is the finding, not a tolerance. T-352 filed all four as
# "latent — passes honestly today because the document is valid". Measured, T-299's document
# validates to `WARN … 0 error(s), 3 warning(s)`: the string VALID does not appear in the
# output at all, so its line is RED today, not passing. Declaring the expectation here rather
# than deriving it from the run keeps the probe falsifiable — if that document ever becomes
# valid, leg 3n goes red and someone has to come back and say so.
# T-787: the T-299 target was the scratchpad path its ARCHIVED line cites. That document
# came from AEF over rail 314 and was never committed here; the scratchpad has since been
# reaped, so this probe's headline went 16/16 -> 12+1 without anything about the repair
# changing. The instrument was right to refuse (it will not measure the load-error path and
# call it a pattern result) — what decayed was the CITATION, recorded as durable in T-353's
# Human AC and in the Phase 5 review while resting on a file outside the repository.
# Substituted: context-memory.bpmn reproduces the same condition from inside the repo —
# `WARN ... 0 error(s)`, with the string VALID appearing zero times — which is what the
# T-299 case exists to test. Equivalence is asserted by leg 0b below, not by this comment.
TARGETS=(
  "T-288|yes|examples/aef-processes/tier0-escalation.workflow.yaml"
  "T-288|yes|examples/aef-processes/rendered/tier0-escalation.bpmn"
  "T-298|yes|examples/aef-processes/rendered/error-escalation-ladder.bpmn"
  "T-299|no|examples/aef-processes/rendered/context-memory.bpmn"
)

# ── leg 0a: PORTABILITY. No target may resolve outside the repository. ────────────────
# This is the defect T-787 fixed, asserted so it cannot return silently. A target that
# lives in a scratchpad makes every leg below contingent on state no checkout carries.
for entry in "${TARGETS[@]}"; do
  d="${entry##*|}"
  case "$d" in
    /*) fail "portability: target '$d' is an absolute path — it cannot travel with the repo" ;;
    *)  if [ -e "$ROOT/$d" ]; then ok "portability: $d is repo-relative and present"
        else fail "portability: repo-relative target '$d' does not exist"; fi ;;
  esac
done

# ── leg 0b: the SUBSTITUTION is equivalent, measured rather than asserted. ────────────
# The T-299 case needs a document on which BOTH the original `grep -q "VALID"` and the
# repaired `grep -q "^VALID"` fail — that is what makes "a tightened pattern cannot fix a
# stale document" a measurement. Zero occurrences of VALID is the strongest form of that.
sub_out="$(cd "$ROOT" && timeout 60 python3 tools/validate-workflow.py examples/aef-processes/rendered/context-memory.bpmn 2>&1)"
if echo "$sub_out" | grep -q '^WARN' && echo "$sub_out" | grep -q '0 error(s)'; then
  ok "substitution: context-memory.bpmn emits WARN with 0 error(s), as T-299's document did"
else
  fail "substitution: context-memory.bpmn no longer emits 'WARN ... 0 error(s)' — the stand-in has drifted"
fi
if echo "$sub_out" | grep -q 'VALID'; then
  fail "substitution: 'VALID' now appears in context-memory.bpmn's output — it no longer reproduces the T-299 condition"
else
  ok "substitution: 'VALID' appears zero times, so both the original and repaired patterns fail on it"
fi

# ── leg 0c: the ARCHIVED line's defect is still there, so the finding is not lost. ────
# T-299's completed task cites a path outside this repository that can never be re-run.
# Derived from the archived line rather than hardcoded, so this measures the record and
# not a copy of it. If that document is ever committed, this goes RED and a human has to
# come back and say so — the same declared-expectation discipline as `valid_doc` above.
T299_FILE="$ROOT/.tasks/completed/T-299-task-creation-pair-round-leg-aef-t-2666-.md"
t299_path="$(grep -oE 'validate-workflow\.py [^ ]+' "$T299_FILE" 2>/dev/null | head -1 | awk '{print $2}')"
if [ -z "$t299_path" ]; then
  fail "provenance: could not find a validate-workflow.py invocation in T-299's archived record"
elif [ -e "$t299_path" ]; then
  fail "provenance: T-299's archived target '$t299_path' now EXISTS — the finding has changed, re-rule it"
else
  ok "provenance: T-299's archived line still cites '$t299_path', which is not in this repo"
fi

for entry in "${TARGETS[@]}"; do
  task="${entry%%|*}"
  rest="${entry#*|}"
  valid_doc="${rest%%|*}"
  doc="${rest#*|}"
  short="$(basename "$doc")"
  echo "-- $task  $short  (document expected valid: $valid_doc)"

  if [ ! -e "$doc" ]; then
    fail "$task/$short : target document is missing, so every leg below would measure the load-error path instead of the pattern. Red on purpose."
    continue
  fi

  check GATE_PASS "$(run_gate "$GATE_COND"   "$(orig_line  "$REJECTED")")" "$task/$short  leg1 original+rejected   (defect reproduced)"
  check GATE_FAIL "$(run_gate "$GATE_COND"   "$(fixed_line "$REJECTED")")" "$task/$short  leg2 repaired+rejected   (defect removed)"

  if [ "$valid_doc" = "yes" ]; then
    check GATE_PASS "$(run_gate "$GATE_COND"   "$(fixed_line "$doc")")"    "$task/$short  leg3 repaired+real       (no regression)"
    check GATE_PASS "$(run_gate "$REMEDY_COND" "$(fixed_line "$doc")")"    "$task/$short  leg4 repaired+real+remedy(corpus ready)"
  else
    # The document is NOT valid, so "the repaired line passes on it" is not the property to
    # assert — asserting it would force this red green. What IS assertable, and what corrects
    # T-352's classification, is that the line is already failing BEFORE any repair.
    check GATE_FAIL "$(run_gate "$GATE_COND"   "$(orig_line  "$doc")")"    "$task/$short  leg3n original+real       (NOT latent — red already)"
    check GATE_FAIL "$(run_gate "$GATE_COND"   "$(fixed_line "$doc")")"    "$task/$short  leg4n repaired+real       (repair cannot fix a stale doc)"
  fi
done

echo
echo "probe: $pass passed, $fails failed"
# T-430 abstention guard. This probe's verdict is the bare `[ "$fails" -eq 0 ]` below —
# the script's exit status, with no `exit N` anywhere on the success path, which is why
# the census could not classify it and named it as unanswerable rather than clean.
#
# The loop it ends with iterates over discovered tasks. If discovery returns nothing —
# a corpus move, a renamed fixture directory, a glob that stops matching — the loop body
# never executes, `pass` and `fails` are both 0, and `[ 0 -eq 0 ]` succeeds. The probe
# then reports "0 passed, 0 failed" and exits green, which is the sentence a fully clean
# corpus produces minus two digits nobody reads.
#
# Unlike the fails-only suites this task is mostly about, the counter needed here already
# existed: ok() has always incremented `pass`. What was missing was any line that consults
# it. The guard is the whole fix.
if [ $(( ${pass:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
[ "$fails" -eq 0 ]
