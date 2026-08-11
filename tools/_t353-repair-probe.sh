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

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
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
TARGETS=(
  "T-288|yes|examples/aef-processes/tier0-escalation.workflow.yaml"
  "T-288|yes|examples/aef-processes/rendered/tier0-escalation.bpmn"
  "T-298|yes|examples/aef-processes/rendered/error-escalation-ladder.bpmn"
  "T-299|no|/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/draft-task-creation-v2.bpmn"
)

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
