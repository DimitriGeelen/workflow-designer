#!/usr/bin/env bash
# T-371 teeth for the audit.sh C-002 partition fix.
#
# The defect being fixed is a two-state collapse: `grep -q PAT file` returns
# non-zero both when the file is ABSENT and when it is PRESENT WITHOUT the
# pattern, and the single else-branch described the second while the first was
# true. Proving the fix therefore requires showing all THREE states are now
# reachable AND produce DISTINCT messages. Showing only that the new absent-branch
# fires would not distinguish a real partition from a renamed single branch.
#
# Each state is driven by mutating the hook file, then restored. Runs the audit's
# C-002 block in isolation rather than the whole audit, so the legs are cheap and
# nothing else in the audit can mask the result.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 2

HOOK=".git/hooks/commit-msg"
AUDIT=".agentic-framework/agents/audit/audit.sh"
TMP="$(mktemp -d)"
BK="$TMP/commit-msg.bak"
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=1; }

# Restore is unconditional: leaving this repo unenforced would reproduce the very
# defect under test. Same reasoning as the T-350 harness precondition.
restore() { [ -f "$BK" ] && cp -p "$BK" "$HOOK" && chmod +x "$HOOK"; rm -rf "$TMP"; }
trap restore EXIT

[ -f "$HOOK" ] || { echo "no commit-msg hook to test with — run: fw git install-hooks"; exit 2; }
cp -p "$HOOK" "$BK"

# Extract the C-002 partition from audit.sh and run it against a chosen PROJECT_ROOT
# state. Extracted at runtime rather than copied: a copied construct keeps testing
# an old shape long after the subject changes — a false green about a false green.
run_c002() {
  local marker='# C-002 OE: Check commit-msg hook has research artifact check installed'
  local start end body
  start=$(grep -n "^${marker}$" "$AUDIT" | head -1 | cut -d: -f1)
  [ -n "$start" ] || { echo "MARKER-NOT-FOUND"; return; }
  # take until the closing 'fi' of the if/elif/else chain
  body=$(awk -v s="$start" 'NR>=s{print} NR>s && /^fi$/{exit}' "$AUDIT")
  PROJECT_ROOT="$REPO_ROOT" bash -c "
    pass() { echo \"PASS|\$1\"; }
    warn() { echo \"WARN|\$1\"; }
    $body
  " 2>&1
}

echo "== T-371 audit C-002 partition teeth =="

# ---- state 1: hook ABSENT ------------------------------------------------------
rm -f "$HOOK"
OUT_ABSENT="$(run_c002)"
case "$OUT_ABSENT" in
  *"ABSENT — no gate at all"*) pass "state ABSENT reports absence, and says no gate exists at all" ;;
  *) fail "state ABSENT did not report absence. got: ${OUT_ABSENT:0:110}" ;;
esac

# ---- state 2: hook PRESENT, WITHOUT the C-002 pattern --------------------------
printf '#!/bin/sh\n# a hook with no C-002 gate\nexit 0\n' > "$HOOK"; chmod +x "$HOOK"
OUT_NOPAT="$(run_c002)"
case "$OUT_NOPAT" in
  *"present but missing research artifact check"*) pass "state PRESENT-WITHOUT reports the sub-gate, not absence" ;;
  *) fail "state PRESENT-WITHOUT misreported. got: ${OUT_NOPAT:0:110}" ;;
esac

# ---- state 3: hook PRESENT, WITH the pattern -----------------------------------
cp -p "$BK" "$HOOK"; chmod +x "$HOOK"
OUT_OK="$(run_c002)"
case "$OUT_OK" in
  PASS*) pass "state PRESENT-WITH passes" ;;
  *) fail "state PRESENT-WITH did not pass. got: ${OUT_OK:0:110}" ;;
esac

# ---- the partition must actually DISCRIMINATE ----------------------------------
# This is the leg that matters. Three branches that emit the same string are not a
# partition, and every check above would still have passed on a substring match.
if [ "$OUT_ABSENT" != "$OUT_NOPAT" ] && [ "$OUT_NOPAT" != "$OUT_OK" ] && [ "$OUT_ABSENT" != "$OUT_OK" ]; then
  pass "all three states produce DISTINCT output — the collapse is genuinely gone"
else
  fail "two or more states produced identical output — still collapsed"
fi

# ---- and the pre-fix behaviour must be shown to have been wrong -----------------
# Reproduce the old one-line construct against the ABSENT state. If it does not
# mis-report, then the defect this task claims never existed.
rm -f "$HOOK"
if grep -q "inception-research-warnings" "$HOOK" 2>/dev/null; then
  old="would-pass"
else
  old="missing research artifact check"
fi
cp -p "$BK" "$HOOK"; chmod +x "$HOOK"
if [ "$old" = "missing research artifact check" ]; then
  pass "pre-fix construct reproduced: on an ABSENT hook it reported 'missing research artifact check'"
else
  fail "could not reproduce the pre-fix mis-report — the premise of this task is unproven"
fi

echo
if [ "$FAIL" -eq 0 ]; then echo "RESULT: PASS"; else echo "RESULT: FAIL"; fi
exit "$FAIL"
