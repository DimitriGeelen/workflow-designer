#!/usr/bin/env bash
# Test suite for tools/validate-workflow.py.
#
# Asserts:
#   - the golden fixture(s) validate clean (exit 0)
#   - every invalid/*.yaml fixture triggers the rule named by its filename and
#     exits 2 (INVALID)
#   - every warn/*.yaml fixture triggers the rule named by its filename and
#     exits 1 (WARN only, non-fatal)
#
# Fixture naming contract: <RULE-ID>.yaml, where RULE-ID is the exact rule
# emitted by the validator (e.g. E-NODE-TYPE, W-IO-INPUT).
#
# Exit 0 iff all assertions pass.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATOR="$ROOT/tools/validate-workflow.py"
FIXTURES="$ROOT/tests/fixtures"

pass=0
fail=0

report() {
  # $1 = PASS|FAIL, $2 = message
  printf '  [%s] %s\n' "$1" "$2"
}

# Run the validator, capture output and exit code.
run() {
  # $1 = file; sets globals OUT and CODE
  OUT="$(python3 "$VALIDATOR" "$1" 2>&1)"
  CODE=$?
}

assert() {
  # $1 = condition (0 ok), $2 = message
  if [ "$1" -eq 0 ]; then
    pass=$((pass + 1))
    report PASS "$2"
  else
    fail=$((fail + 1))
    report FAIL "$2"
  fi
}

echo "== golden (must be clean, exit 0) =="
for f in "$FIXTURES"/valid/*.yaml; do
  [ -e "$f" ] || continue
  run "$f"
  name="$(basename "$f")"
  if [ "$CODE" -eq 0 ]; then assert 0 "$name -> exit 0"; else
    assert 1 "$name -> expected exit 0, got $CODE"
    printf '%s\n' "$OUT" | sed 's/^/      /'
  fi
done

echo "== invalid (must error, exit 2, expected rule fires) =="
for f in "$FIXTURES"/invalid/*.yaml; do
  [ -e "$f" ] || continue
  run "$f"
  rule="$(basename "$f" .yaml)"
  ok=0
  [ "$CODE" -eq 2 ] || ok=1
  printf '%s\n' "$OUT" | grep -q "\[$rule\]" || ok=1
  if [ "$ok" -eq 0 ]; then
    assert 0 "$rule -> exit 2 and rule present"
  else
    assert 1 "$rule -> expected exit 2 + rule [$rule], got exit $CODE"
    printf '%s\n' "$OUT" | sed 's/^/      /'
  fi
done

echo "== warn (must warn, exit 1, expected rule fires) =="
for f in "$FIXTURES"/warn/*.yaml; do
  [ -e "$f" ] || continue
  run "$f"
  rule="$(basename "$f" .yaml)"
  ok=0
  [ "$CODE" -eq 1 ] || ok=1
  printf '%s\n' "$OUT" | grep -q "\[$rule\]" || ok=1
  if [ "$ok" -eq 0 ]; then
    assert 0 "$rule -> exit 1 and rule present"
  else
    assert 1 "$rule -> expected exit 1 + rule [$rule], got exit $CODE"
    printf '%s\n' "$OUT" | sed 's/^/      /'
  fi
done

echo
echo "== summary: $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
