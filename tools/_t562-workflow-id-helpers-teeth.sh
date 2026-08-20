#!/usr/bin/env bash
# _t562-workflow-id-helpers-teeth.sh — mutation test for _t562-workflow-id-helpers-cdp.mjs.
#
# "7/7 legs passed" is also what a probe that asserts nothing prints. These mutants pin
# both edges of every claim the probe makes, and each is a fix someone would plausibly
# ship:
#
#   A  unconditional fallback   — sanitizeWorkflowId always returns 'workflow'. This is
#                                 the tempting simplification (one fallback, no param)
#                                 and it turns a REFUSED rename into a silent rename to
#                                 "workflow". Must kill leg 4.
#   B  pre-fix leading strip    — `^-+` instead of `^[-_]+`, i.e. the rule that shipped.
#                                 Must kill legs 2/3/5. If B survives, the probe is not
#                                 measuring the repair at all.
#   C  call site un-wired       — helper correct, `renameActiveWorkflow` keeps its old
#                                 inline copy. THE DISCRIMINATION ARM: this is the only
#                                 mutant that separates "the helper is right" from "the
#                                 call site uses it" (PL-148), and it must kill leg 6
#                                 and ONLY leg 6.
#   D  validator loosened       — `^[a-z0-9_-]+$` accepts a leading separator, so the
#                                 sanitizer and validator agree by lowering the bar
#                                 rather than by fixing the sanitizer. Must kill leg 7.
#
# A control run against the UNMUTATED source must pass, otherwise "every mutant died"
# is satisfied by a probe that fails on everything.
#
# Usage: bash tools/_t562-workflow-id-helpers-teeth.sh
# Exit 0 = control passes AND every mutant is killed AND C is uniquely leg-6.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/src/aef-workflow-designer.html"
PROBE="$ROOT/tools/_t562-workflow-id-helpers-cdp.mjs"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0
report() { # report <PASS|FAIL> <name> <detail>
  if [ "$1" = PASS ]; then pass=$((pass+1)); else fail=$((fail+1)); fi
  printf '%s  %s — %s\n' "$1" "$2" "$3"
}

run_probe() { # run_probe <src> -> writes output to $TMP/out, returns probe rc
  timeout 240 node "$PROBE" --src "$1" > "$TMP/out" 2>&1
}

# ── control ───────────────────────────────────────────────────────────────────────
run_probe "$SRC"; rc=$?
if [ $rc -eq 0 ] && grep -q "7/7 legs passed" "$TMP/out"; then
  report PASS "control (unmutated source)" "probe green, 7/7"
else
  report FAIL "control (unmutated source)" "rc=$rc — a probe that fails here makes every mutant kill meaningless; output: $(tail -3 "$TMP/out" | tr '\n' ' ')"
  echo; echo "$pass passed, $fail failed"; exit 1
fi

# ── mutants ───────────────────────────────────────────────────────────────────────
mutate() { # mutate <name> <python-replacement-expr-file>
  cp "$SRC" "$TMP/$1.html"
}

# A — unconditional fallback
cp "$SRC" "$TMP/A.html"
python3 - "$TMP/A.html" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = "  return s || fallback;"
assert s.count(old) == 1, "mutant A anchor not unique: %d" % s.count(old)
open(p, 'w', encoding='utf-8').write(s.replace(old, "  return 'workflow';"))
PY
[ $? -eq 0 ] || { report FAIL "mutant A anchor" "could not plant"; }

# B — pre-fix leading strip (dashes only)
cp "$SRC" "$TMP/B.html"
python3 - "$TMP/B.html" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = ".replace(/^[-_]+/, '')"
assert s.count(old) == 1, "mutant B anchor not unique: %d" % s.count(old)
open(p, 'w', encoding='utf-8').write(s.replace(old, ".replace(/^-+/, '')"))
PY

# C — call site un-wired (helper stays correct)
cp "$SRC" "$TMP/C.html"
python3 - "$TMP/C.html" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = "  newId = sanitizeWorkflowId(newId, '');"
assert s.count(old) == 1, "mutant C anchor not unique: %d" % s.count(old)
new = "  newId = (newId || '').trim().toLowerCase().replace(/[^a-z0-9_\\-]/g, '-');"
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY

# D — validator loosened to accept a leading separator
cp "$SRC" "$TMP/D.html"
python3 - "$TMP/D.html" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = "/^[a-z0-9][a-z0-9_-]*$/"
assert s.count(old) == 1, "mutant D anchor not unique: %d" % s.count(old)
open(p, 'w', encoding='utf-8').write(s.replace(old, "/^[a-z0-9_-]+$/"))
PY

check_mutant() { # check_mutant <letter> <must-fail-leg-numbers-space-sep> <description>
  local m="$1" want="$2" desc="$3"
  run_probe "$TMP/$m.html"; local rc=$?
  if [ $rc -eq 0 ]; then
    report FAIL "mutant $m killed ($desc)" "probe still passed 7/7 — the leg(s) meant to catch this assert nothing"
    return
  fi
  local missed=""
  for n in $want; do
    grep -q "^FAIL  $n " "$TMP/out" || missed="$missed $n"
  done
  if [ -n "$missed" ]; then
    report FAIL "mutant $m killed ($desc)" "probe went red but leg(s)$missed stayed green; got: $(grep -c '^FAIL' "$TMP/out") FAIL line(s)"
  else
    report PASS "mutant $m killed ($desc)" "legs $(grep '^FAIL' "$TMP/out" | sed 's/^FAIL  \([0-9]*\).*/\1/' | tr '\n' ',' | sed 's/,$//') went red as required"
  fi
  cp "$TMP/out" "$TMP/out.$m"
}

check_mutant A "4" "unconditional fallback — refused rename becomes silent rename"
check_mutant B "2 3 5" "pre-fix leading strip — the shipped rule"
check_mutant C "6" "call site un-wired — helper correct but uncalled"
check_mutant D "7" "validator loosened instead of sanitizer fixed"

# ── C must be UNIQUELY leg 6 ──────────────────────────────────────────────────────
# If C also reddened legs 2/3/5/7 it would be indistinguishable from B, and the probe
# would not actually be proving the call site is wired.
if [ -f "$TMP/out.C" ]; then
  cfails=$(grep -c '^FAIL' "$TMP/out.C")
  if [ "$cfails" = "1" ] && grep -q '^FAIL  6 ' "$TMP/out.C"; then
    report PASS "mutant C is uniquely leg 6" "exactly 1 red leg, and it is the call-site leg"
  else
    report FAIL "mutant C is uniquely leg 6" "$cfails red leg(s) — C must isolate call-site wiring from helper correctness"
  fi
else
  report FAIL "mutant C is uniquely leg 6" "no C output captured"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
echo "$((pass))/$((pass)) teeth legs passed"
