#!/usr/bin/env bash
# T-843 — integration probe for check_verification_uncontrolled_absence.
#
# Proves the GATE fires, not just the predicate underneath it, and — the AC that matters —
# that the remedy its block message NAMES actually clears it. OBS-374 and the bvp verb gap
# are both checks whose printed remedy could not be applied; writing a third would be
# indefensible, so the remedy is executed here rather than asserted.
#
# HOW THE FUNCTION IS OBTAINED. Extracted from the LIVE update-task.sh by source text and
# eval'd, because sourcing that file whole would run its main flow. PL-275 warns that a
# model of a runner drifts from the runner — so nothing is re-typed: the bytes under test
# are read out of the shipped file every run, and if the function is renamed or removed this
# probe fails rather than silently testing a stale copy.

set -uo pipefail
REPO="${T843_REPO_ROOT:-/opt/832-Workflow-designer}"
export PROJECT_ROOT="$REPO"
UT="$REPO/.agentic-framework/agents/task-create/update-task.sh"
PASS=0; FAIL=0; N=0
say(){ N=$((N+1)); printf '%s %d - %s\n' "$1" "$N" "$2"; }
ok(){  PASS=$((PASS+1)); say ok "$1"; }
bad(){ FAIL=$((FAIL+1)); say "not ok" "$1"; }

FN=$(sed -n '/^check_verification_uncontrolled_absence() {/,/^}/p' "$UT")
if [ -z "$FN" ]; then
    bad "could not extract check_verification_uncontrolled_absence from update-task.sh"
    printf '\n# passed %d, failed %d\n' "$PASS" "$FAIL"; exit 1
fi
ok "extracted the live gate function from update-task.sh ($(printf '%s\n' "$FN" | wc -l) lines)"

# Minimal environment the function needs. Stubs only for things outside the unit.
HARNESS='RED=""; YELLOW=""; NC=""; FRAMEWORK_ROOT="'"$REPO"'/.agentic-framework";
log_gate_bypass(){ echo "BYPASS-LOGGED:$1" >&2; }
'"$FN"'
'

run(){ # run <block> [env assignments...] -> prints combined output, returns gate rc
    local block="$1"; shift
    env "$@" bash -c "$HARNESS"'
check_verification_uncontrolled_absence "$1"
echo "GATE-RETURNED-0"' _ "$block" 2>&1
}

# ── 1. THE OFFENDING SHAPE MUST BE REFUSED ────────────────────────────────────
UNCTRL="test -f .context/working/.gate-bypass-log.yaml
! grep -q 'FW_ALLOW_UNCONTROLLED_ABSENCE' .context/working/.gate-bypass-log.yaml"
out=$(run "$UNCTRL"); rc=$?
if [ "$rc" -ne 0 ] && ! printf '%s' "$out" | grep -q 'GATE-RETURNED-0'; then
    ok "uncontrolled absence assertion is REFUSED (rc=$rc)"
else
    bad "uncontrolled absence assertion was ADMITTED (rc=$rc) — the gate does not bite"
fi
printf '%s' "$out" | grep -q 'ERROR: Cannot complete — uncontrolled absence assertion' \
  && ok "refusal names the defect" || bad "refusal does not name the defect"
printf '%s' "$out" | grep -q "greps the SAME pattern where it IS present" \
  && ok "refusal names repair route 1" || bad "refusal omits repair route 1"
printf '%s' "$out" | grep -q 'assert the positive fact directly' \
  && ok "refusal names repair route 2" || bad "refusal omits repair route 2"
printf '%s' "$out" | grep -q 'FW_ALLOW_UNCONTROLLED_ABSENCE=1' \
  && ok "refusal names its own escape (not PL-304)" || bad "refusal hides its escape — PL-304"
# The weaker control must be named as weaker, not as sufficient.
printf '%s' "$out" | grep -q 'proves the PATH but not the PATTERN' \
  && ok "refusal says test -f is the WEAKER control, not a fix" \
  || bad "refusal implies test -f is sufficient — the documented overstatement"

# ── 2. THE REMEDY IT NAMES ACTUALLY CLEARS IT ─────────────────────────────────
# Route 1, applied verbatim as the message prescribes: a companion leg grepping the SAME
# STRING somewhere it IS present.
REMEDIED="grep -q 'FW_ALLOW_UNCONTROLLED_ABSENCE' .agentic-framework/agents/task-create/update-task.sh
test -f .context/working/.gate-bypass-log.yaml
! grep -q 'FW_ALLOW_UNCONTROLLED_ABSENCE' .context/working/.gate-bypass-log.yaml"
out=$(run "$REMEDIED"); rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'GATE-RETURNED-0'; then
    ok "THE PRINTED REMEDY CLEARS THE GATE — route 1 applied verbatim"
else
    bad "the remedy the gate prints does NOT clear it (rc=$rc) — an un-actionable check"
fi
printf '%s' "$out" | grep -q 'ERROR' && bad "remedied block still printed an ERROR" \
                                     || ok "remedied block produces no error output"

# ── 3. A CLEAN BLOCK IS NOT TOUCHED (negative control) ────────────────────────
CLEAN="git diff --quiet HEAD -- README.md
grep -q 'hello' README.md"
out=$(run "$CLEAN"); rc=$?
[ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'GATE-RETURNED-0' \
  && ok "a block with no absence legs passes untouched" \
  || bad "a clean block was refused (rc=$rc) — false positive"

# ── 4. NOT EVALUATED: an unreadable pattern must NOT block ────────────────────
UNREAD='! grep -q $T843_PATTERN some-file.txt'
out=$(run "$UNREAD"); rc=$?
[ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'GATE-RETURNED-0' \
  && ok "unreadable absence leg does NOT block the close" \
  || bad "unreadable absence leg BLOCKED the close — failing over a parser limit"
printf '%s' "$out" | grep -q 'NOT EVALUATED' \
  && ok "unreadable absence leg is reported as NOT EVALUATED" \
  || bad "unreadable absence leg passed SILENTLY — claims coverage it does not have"

# ── 5. NOT EVALUATED: classifier missing must not block, and must not pass mute ─
# PROJECT_ROOT/FRAMEWORK_ROOT pointed at a tree with no census.
EMPTY=$(mktemp -d); trap 'rm -rf "$EMPTY"' EXIT
out=$(run "$UNCTRL" PROJECT_ROOT="$EMPTY" FRAMEWORK_ROOT="$REPO/.agentic-framework"); rc=$?
if [ "$rc" -eq 0 ]; then
    ok "classifier absent: close is not blocked"
else
    bad "classifier absent: close was BLOCKED (rc=$rc) — would break every project without the census"
fi
printf '%s' "$out" | grep -q 'NOT EVALUATED' \
  && ok "classifier absent is reported as NOT EVALUATED, not as a pass" \
  || bad "classifier absent passed SILENTLY — the exact false green this gate is for"

# ── 6. THE ESCAPE WORKS AND IS LOGGED ─────────────────────────────────────────
out=$(run "$UNCTRL" FW_ALLOW_UNCONTROLLED_ABSENCE=1); rc=$?
[ "$rc" -eq 0 ] && ok "documented escape admits the block" || bad "documented escape does not work (rc=$rc)"
printf '%s' "$out" | grep -q 'BYPASS-LOGGED:FW_ALLOW_UNCONTROLLED_ABSENCE' \
  && ok "the escape is LOGGED (a silent bypass is not a bypass)" \
  || bad "the escape is NOT logged"

printf '\n# passed %d, failed %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
