#!/usr/bin/env bash
# _t352-teeth.sh — prove each check in _t352-p011-errexit-probe.sh CAN fail, and fails for
# its OWN stated reason. Every leg requires a SPECIFIC substring: a leg that accepts any
# non-zero exit banks syntax errors as evidence (T-338 (d), T-343 (d), T-348 (c), T-350).
#
# Leg (a) is the one that matters most, and it is not a mutation of the subject in the usual
# sense — it applies the PROPOSED REMEDY and requires the probe to go red. AC1 says the probe
# must be the regression witness, i.e. it must fail on the fix. That is a claim about the
# probe, and a claim about a probe is worth exactly what a teeth leg says it is worth.
#
# Legs (b)–(d) attack the probe's own scope rather than the gate (the T-335/T-351 lesson):
# the extraction guard, the pipefail discriminator, and the negative control are all
# assertions that would otherwise read as coverage without anyone having seen them fire.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROBE="$ROOT/tools/_t352-p011-errexit-probe.sh"
GATE="$ROOT/.agentic-framework/agents/task-create/update-task.sh"
# Order matters and cost a run: clearing stale mutants must NOT be the same call that
# removes $TMP, or invoking it once at startup deletes the scratch dir created a line above
# and every leg then fails on a missing file. Sweep first, create second, trap third.
rm -f "$ROOT"/tools/.t352-mut-*.sh
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP" "$ROOT"/tools/.t352-mut-*.sh' EXIT
pass=0; fail=0

# Mutants of the PROBE live in tools/, not in $TMP, and that is not tidiness — the probe
# derives ROOT from its own location, so a copy in /tmp resolves GATE_SRC to
# /tmp/.agentic-framework/… and the validator path to /tmp/tools/…. The first run of this
# file put them in $TMP and legs (c)/(d) went red with the EXTRACTION message instead of
# their own: the probe correctly refused to measure a subject it could not find, which is
# leg (b)'s guard doing its job in a context it was not written for. Relocating an
# instrument changes what it measures whenever it locates itself relatively.
# Mutants of the GATE may live in $TMP: they are only ever read, never executed.

# The T-350 lesson, encoded: a mutation that did not apply produces a green (or a red for an
# unrelated reason) and either way proves nothing. Never run a leg whose mutation is unproven.
assert_mutated() { # $1=orig $2=mutant $3=leg
  if cmp -s "$1" "$2"; then
    echo "LEG $3: BROKEN — mutation did not change the file; a verdict here would prove nothing" >&2
    return 1
  fi
  return 0
}

check() { # $1=id $2=desc $3=expected substring  (out/rc set by caller)
  local id="$1" desc="$2" want="$3"
  if [ "$rc" -eq 0 ]; then
    echo "LEG $id: FAILED TO GO RED — probe still passed with the mutation applied ($desc)" >&2
    fail=$((fail+1)); return
  fi
  if [ "$rc" -eq 124 ]; then
    echo "LEG $id: BROKEN — probe timed out; a red on a hang proves nothing about $desc" >&2
    fail=$((fail+1)); return
  fi
  if ! echo "$out" | grep -qF "$want"; then
    echo "LEG $id: RED FOR THE WRONG REASON — probe failed but never said: $want" >&2
    echo "$out" | grep -E '^FAIL' | sed 's/^/    /' >&2
    fail=$((fail+1)); return
  fi
  echo "LEG $id: ok — red, naming its own condition ($desc)"
  echo "         -> $(echo "$out" | grep -F "$want" | head -1 | cut -c1-160)"
  pass=$((pass+1))
}

echo "== T-352 teeth =="

# ── (a) APPLY THE REMEDY: the probe must fail on the fix ───────────────────────────────
# If this leg cannot go red, AC1's central claim is false and the probe is a monument to a
# defect rather than a witness to it — it would keep passing after the gate was repaired.
echo "[leg a] gate patched to the form-C remedy; probe must go red"
mut_a="$TMP/update-task.a.sh"
cp "$GATE" "$mut_a"
python3 - "$mut_a" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old = 'cd "$PROJECT_ROOT" && eval "$cmd")'
new = 'cd "$PROJECT_ROOT" && bash -c \'set -eo pipefail; eval "$1"\' _ "$cmd")'
if old not in s:
    sys.stderr.write("anchor missing\n"); sys.exit(1)
open(p, 'w').write(s.replace(old, new, 1))
PY
if [ $? -ne 0 ] || ! assert_mutated "$GATE" "$mut_a" a; then
  echo "LEG a: BROKEN — remedy did not apply" >&2; fail=$((fail+1))
else
  out="$(GATE_SRC="$mut_a" timeout 120 bash "$PROBE" 2>&1)"; rc=$?
  check a "the remedy makes the known-bad line FAIL, so the probe's PASS expectation flips" \
    "A/false-green : expected GATE_PASS, got GATE_FAIL"
fi

# ── (b) THE PROBE'S OWN SCOPE: remove the subject entirely ─────────────────────────────
# A probe that cannot locate the construct it measures must say so. Without this leg the
# extraction guard is an untested branch, and the failure mode it guards against — silently
# measuring nothing and reporting green — is exactly the class this arc keeps finding.
echo "[leg b] gate line removed; probe must blame ITSELF, not report a green"
mut_b="$TMP/update-task.b.sh"
python3 - "$GATE" "$mut_b" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
lines = open(src).read().splitlines(True)
keep = [l for l in lines if not re.match(r'^\s*if .*\$cmd', l)]
if len(keep) == len(lines):
    sys.stderr.write("anchor missing\n"); sys.exit(1)
open(dst, 'w').writelines(keep)
PY
if [ $? -ne 0 ] || ! assert_mutated "$GATE" "$mut_b" b; then
  echo "LEG b: BROKEN — gate line was not removed" >&2; fail=$((fail+1))
else
  out="$(GATE_SRC="$mut_b" timeout 120 bash "$PROBE" 2>&1)"; rc=$?
  check b "extraction guard fires and names the probe, rather than passing on an empty measurement" \
    "EXTRACT: could not read the verification construct"
fi

# ── (c) THE pipefail DISCRIMINATOR ─────────────────────────────────────────────────────
# The AC4 measurement claims pipefail is active while errexit is not. That is only evidence
# if the check could have come out the other way. Strip the options from the generated
# runner and the pipefail leg must flip — proving it reads the option, not a constant.
echo "[leg c] runner stripped of 'set -euo pipefail'; the pipefail measurement must flip"
mut_c="$ROOT/tools/.t352-mut-c.sh"
python3 - "$PROBE" "$mut_c" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()
old = "    echo 'set -euo pipefail'                  # update-task.sh:14, verbatim\n"
if old not in s:
    sys.stderr.write("anchor missing\n"); sys.exit(1)
# A COMMENT, not `: options removed by teeth leg (c)` — that was the first attempt and the
# unquoted parens are a bash syntax error, so the runner died at parse and every assertion
# returned GATE_BROKEN. check()'s substring requirement is the only reason that did not bank
# as "leg c goes red, therefore the pipefail measurement discriminates".
open(dst, 'w').write(s.replace(old, "    echo '# options removed by teeth leg c'\n", 1))
PY
if [ $? -ne 0 ] || ! assert_mutated "$PROBE" "$mut_c" c; then
  echo "LEG c: BROKEN — runner options were not stripped" >&2; fail=$((fail+1))
else
  out="$(timeout 120 bash "$mut_c" 2>&1)"; rc=$?
  check c "without pipefail, 'false | true' returns 0 — the measurement is a real discriminator" \
    "A/pipefail   : expected GATE_FAIL, got GATE_PASS"
fi

# ── (d) THE NEGATIVE CONTROL ───────────────────────────────────────────────────────────
# Every GATE_PASS in this probe is worthless unless GATE_FAIL is reachable. Make the runner
# incapable of reporting failure; the negative control is the only assertion that should
# notice, and if it does not, then "PASS" was never falsifiable in the first place.
echo "[leg d] runner made incapable of reporting failure; the negative control must catch it"
mut_d="$ROOT/tools/.t352-mut-d.sh"
python3 - "$PROBE" "$mut_d" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()
old = "if %s; then echo GATE_PASS; else echo GATE_FAIL; fi\\n"
new = "if %s; then echo GATE_PASS; else echo GATE_PASS; fi\\n"
if old not in s:
    sys.stderr.write("anchor missing\n"); sys.exit(1)
open(dst, 'w').write(s.replace(old, new, 1))
PY
if [ $? -ne 0 ] || ! assert_mutated "$PROBE" "$mut_d" d; then
  echo "LEG d: BROKEN — runner verdict was not neutered" >&2; fail=$((fail+1))
else
  out="$(timeout 120 bash "$mut_d" 2>&1)"; rc=$?
  check d "GATE_FAIL is reachable — without this, every GATE_PASS above asserts nothing" \
    "A/neg-control : expected GATE_FAIL, got GATE_PASS"
fi

echo
echo "teeth: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
