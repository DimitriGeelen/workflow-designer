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
# Fixture naming contract: <RULE-ID>.<ext>, where RULE-ID is the exact rule
# emitted by the validator (e.g. E-NODE-TYPE, W-IO-INPUT, E-XML-ID-DUP) and
# <ext> is yaml/yml (YAML canonical form) or bpmn/xml (BPMN-XML export form).
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
# T-1402: a fixture whose rule checks io against the field catalog (T-1370) has a companion catalog,
# fixtures/catalogs/<RULE-ID>.json; it is passed with --field-catalog, as tests/test_t1370_catalog_checks.py does.
# Without it those rules cannot fire, which left four cases red here, unnoticed, from 2026-11-02 to 2026-11-12.
run() {
  # $1 = file; sets globals OUT and CODE
  local base cat
  base="$(basename "$1")"; cat="$FIXTURES/catalogs/${base%.*}.json"
  if [ -f "$cat" ]; then OUT="$(python3 "$VALIDATOR" "$1" --field-catalog "$cat" 2>&1)"
  else OUT="$(python3 "$VALIDATOR" "$1" 2>&1)"; fi
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
for f in "$FIXTURES"/valid/*; do
  [ -e "$f" ] || continue
  run "$f"
  name="$(basename "$f")"
  if [ "$CODE" -eq 0 ]; then assert 0 "$name -> exit 0"; else
    assert 1 "$name -> expected exit 0, got $CODE"
    printf '%s\n' "$OUT" | sed 's/^/      /'
  fi
done

echo "== invalid (must error, exit 2, expected rule fires) =="
for f in "$FIXTURES"/invalid/*; do
  [ -e "$f" ] || continue
  run "$f"
  base="$(basename "$f")"
  rule="${base%.*}"
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
for f in "$FIXTURES"/warn/*; do
  [ -e "$f" ] || continue
  run "$f"
  base="$(basename "$f")"
  rule="${base%.*}"
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
