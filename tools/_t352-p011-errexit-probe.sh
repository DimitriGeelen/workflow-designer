#!/usr/bin/env bash
# _t352-p011-errexit-probe.sh — does the P-011 verification gate judge `a; b` on `b` alone?
#
# Covers T-352 AC1 (the false green reproduced through the gate's own construct), AC3 (the
# intuitive fix is a non-fix, with a positive control beside it), and the measurement AC4
# needs (which half of the template's "runs under `set -eo pipefail`" sentence is true).
#
# ── WHY THIS EXTRACTS THE GATE'S LINE INSTEAD OF COPYING IT ────────────────────────────
# AC1 requires this harness to be the REGRESSION WITNESS: it must go red when the gate is
# fixed. A copied construct cannot do that — it would keep reproducing the old behaviour
# out of a string literal in this file long after update-task.sh stopped behaving that way,
# and would report a false green about a false green. So the condition is read out of
# update-task.sh at runtime by matching `^\s*if .*$cmd`. Three consequences, all intended:
#   • Remedy applied (`bash -c "set -eo pipefail; …"`) -> the extracted line now FAILS the
#     known-bad input -> AC1's expectation of PASS goes red. That red is the success signal.
#   • Gate line deleted or restructured past the matcher -> extraction fails loudly. Also
#     red, and it must be: a probe that cannot find its subject has measured nothing.
#   • Nobody has to remember to update this file. The subject is the file, not a quote of it.
#
# ── WHY EACH CASE RUNS IN A FRESH `bash`, NOT IN A FUNCTION CALL HERE ──────────────────
# The defect IS an execution context: `set -euo pipefail` at update-task.sh:14 is suppressed
# because the subshell sits in the CONDITION of an `if`. If this probe invoked the construct
# from inside its own `if run_case …; then`, the suppression would come from MY `if` and the
# measurement would be circular — it would read PASS even against a fixed gate. Each case is
# therefore written to a generated script that sets errexit at the top exactly as
# update-task.sh does and places the construct at statement level, then run as a child.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE_SRC="${GATE_SRC:-$ROOT/.agentic-framework/agents/task-create/update-task.sh}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0; fails=0
ok()   { echo "  ok   $*"; pass=$((pass+1)); }
fail() { echo "FAIL $*" >&2; fails=$((fails+1)); }

echo "== T-352 P-011 errexit probe =="
echo "gate source: ${GATE_SRC#$ROOT/}"

# ── Extract the gate's own condition ───────────────────────────────────────────────────
# Match on `$cmd` rather than on `eval "$cmd"` deliberately: the proposed remedy replaces
# the eval with `bash -c … "$cmd"`, and a matcher keyed to `eval` would stop finding the
# line at exactly the moment the fix lands, turning a meaningful red into a confusing one.
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
  fail "EXTRACT: could not read the verification construct out of $GATE_SRC. Either the gate was restructured or the remedy landed — re-read this probe's header before assuming a bug. A probe that cannot locate its subject has measured nothing, so this is red on purpose."
  echo; echo "probe: $pass passed, $fails failed"; exit 1
fi
echo "extracted condition:"
echo "    $GATE_COND"
echo

# ── Case runner ────────────────────────────────────────────────────────────────────────
# $1 = condition text, $2 = the verification line under test. Prints GATE_PASS/GATE_FAIL.
run_gate() {
  local cond="$1" cmd="$2" f out
  f="$TMP/runner.$$.$RANDOM.sh"
  {
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'                  # update-task.sh:14, verbatim
    echo '_close_locks_cmd=""'                # the gate computes this; empty here
    printf 'PROJECT_ROOT=%q\n' "$ROOT"
    echo 'cmd="$CMD_UNDER_TEST"'
    printf 'if %s; then echo GATE_PASS; else echo GATE_FAIL; fi\n' "$cond"
  } > "$f"
  out="$(CMD_UNDER_TEST="$cmd" bash "$f" 2>/dev/null | tail -1)"
  case "$out" in GATE_PASS|GATE_FAIL) echo "$out" ;; *) echo "GATE_BROKEN($out)" ;; esac
}

# Form B — the fix anyone reasoning about this reaches for first: re-issue `set -e` inside
# the subshell. Injected right after the opening paren, which is where it would be written.
COND_B="$(printf '%s' "$GATE_COND" | sed 's/^(/(set -e; /')"

# Form C — the proposed remedy. `bash -c '…' _ "$cmd"` passes the command as an ARGUMENT
# rather than interpolating it into the -c string: interpolation would re-parse verification
# lines containing quotes and break them, which is a worse defect than the one being fixed.
COND_C="$(printf '%s' "$GATE_COND" | sed 's/eval "\$cmd"/bash -c '"'"'set -eo pipefail; eval "$1"'"'"' _ "$cmd"/')"

# ── Fixtures ───────────────────────────────────────────────────────────────────────────
mkdir -p "$TMP/fix"
cat > "$TMP/fix/broken.bpmn" <<'XML'
<?xml version="1.0"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL">
  <bpmn:process id="p1"><bpmn:task id="t1"/></bpmn:process>
</bpmn:definitions>
XML

# The real shape, verbatim from the template's "Safe pattern" hint. The validator exits 2
# and prints "INVALID"; `grep -q "VALID"` matches INVALID as a SUBSTRING. Two independent
# defects stacked — either alone is survivable, together they produce a confident green.
FALSE_GREEN='out=$(python3 '"$ROOT"'/tools/validate-workflow.py '"$TMP"'/fix/broken.bpmn 2>&1); echo "$out" | grep -q "VALID"'

# Positive control: a line that SHOULD pass. Without it, "form C fails more often" is not
# evidence that form C is right — a construct that failed everything would score the same.
POS_CONTROL='out=$(echo "suite: 12 passed, 0 failed" 2>&1); echo "$out" | grep -q "0 failed"'

# Negative control: last command genuinely fails. Without it, GATE_PASS is unfalsifiable —
# a runner that always printed GATE_PASS would satisfy every other assertion in this file.
NEG_CONTROL='out=$(echo "suite: 3 failed" 2>&1); echo "$out" | grep -q "0 failed"'

expect() { # $1=label $2=cond $3=cmd $4=expected $5=meaning
  local got; got="$(run_gate "$2" "$3")"
  if [ "$got" = "$4" ]; then ok "$1 -> $got   ($5)"
  else fail "$1: expected $4, got $got — $5"; fi
}

# ── AC1: the false green, through the gate's own construct ─────────────────────────────
echo "[AC1] the gate's construct, as it stands today"
expect "A/false-green " "$GATE_COND" "$FALSE_GREEN" GATE_PASS \
  "validator exits 2 and prints INVALID, yet the line PASSES: a; b is judged on b alone"
expect "A/neg-control " "$GATE_COND" "$NEG_CONTROL" GATE_FAIL \
  "runner CAN report failure — without this, GATE_PASS above would be unfalsifiable"
expect "A/pos-control " "$GATE_COND" "$POS_CONTROL" GATE_PASS \
  "an honest line still passes"

# ── AC3: the intuitive fix is a non-fix, and the accepted one discriminates ────────────
echo "[AC3] set -e re-issued inside the subshell (form B) vs bash -c (form C)"
expect "B/false-green " "$COND_B" "$FALSE_GREEN" GATE_PASS \
  "STILL WRONG: the errexit-suppressed context is inherited; re-setting the option does not clear it"
expect "B/pos-control " "$COND_B" "$POS_CONTROL" GATE_PASS \
  "form B is not stricter either — it is simply inert"
expect "C/false-green " "$COND_C" "$FALSE_GREEN" GATE_FAIL \
  "CORRECT: a fresh shell restores errexit, so a's exit code is no longer discarded"
expect "C/pos-control " "$COND_C" "$POS_CONTROL" GATE_PASS \
  "form C DISCRIMINATES rather than merely refusing more: the honest line still passes"

# ── AC4: the advice the template now gives must itself be true ─────────────────────────
# The template fix promotes the `&&` file form to PREFERRED and demotes the capture form.
# That advice is only worth giving if `&&` really does survive the suppressed errexit — and
# it does for a reason that has nothing to do with `set -e`: the exit status of `a && b`
# when `a` fails IS a's status, so nothing needs to trap anything. Asserting it here means
# the template's advice is measured rather than reasoned, and goes red if that ever changes.
echo "[AC4] the '&&' form the template now recommends"
AND_FORM='python3 '"$ROOT"'/tools/validate-workflow.py '"$TMP"'/fix/broken.bpmn > '"$TMP"'/o.txt 2>&1 && grep -q "VALID" '"$TMP"'/o.txt'
expect "A/and-form   " "$GATE_COND" "$AND_FORM" GATE_FAIL \
  "same two commands joined by && correctly FAIL — this is the shape the template now lists first"

# ── AC4 input: which half of the template's sentence is true ───────────────────────────
# The template asserts "P-011 runs each command under `set -eo pipefail`". Options are
# inherited by the subshell, but only ERREXIT is neutralised by sitting in an if-condition;
# pipefail changes how a pipeline's status is COMPUTED and is unaffected. Measured, not
# reasoned: `false | true` returns 0 without pipefail and 1 with it.
echo "[AC4] is pipefail actually in effect, or is the whole sentence wrong?"
expect "A/pipefail   " "$GATE_COND" 'false | true' GATE_FAIL \
  "pipefail IS active (rc would be 0 without it) — so the template is half right: -o pipefail yes, -e no"

echo
echo "probe: $pass passed, $fails failed"
[ "$fails" -eq 0 ] || exit 1
