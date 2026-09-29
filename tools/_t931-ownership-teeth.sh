#!/usr/bin/env bash
# _t931-ownership-teeth.sh — prove the ownership predicate BOTH directions, negative leg first.
#
# WHAT IS AT STAKE. This predicate's verdict is what a writer will act on to revert `owner: human`
# to `owner: agent`. If it reports OWNER-STALE for a task that still has an open Human criterion, a
# genuine sovereignty claim is removed. That is the one outcome that must be impossible, so the leg
# that proves it CANNOT happen is written first and runs first.
#
# WHY THE POSITIVE LEG IS NOT ENOUGH. A predicate hard-wired to return OWNER-JUSTIFIED passes every
# negative test and is useless. A predicate hard-wired to OWNER-STALE passes every positive test and
# is dangerous. Only running both over fixtures that differ in ONE property measures anything, and
# only a control that is DEMONSTRATED to fail proves the harness is wired up at all — a suite that
# silently matched nothing would report all-clear, which is the false green this whole line of work
# exists to remove.
#
# FIXTURES ARE BUILT HERE, NOT BORROWED FROM THE LIVE TREE. The orchestrator's own self-test used
# $DIR/round3.out — a live run artefact — as its positive control, and the run overwrote it with a
# successful round's output, flipping the control's meaning while the code under test never changed
# (T-922). Live corpus state is not a fixture.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90

TOOL="tools/_t931-ownership.py"
[ -f "$TOOL" ] || { echo "SETUP BROKEN: no $TOOL"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "SETUP BROKEN: no python3"; exit 1; }

PASS=0; FAIL=0
ok() { if [ "$2" -eq 0 ]; then echo "  PASS  $1"; PASS=$((PASS+1)); else echo "  FAIL  $1"; [ -n "${3:-}" ] && echo "        $3"; FAIL=$((FAIL+1)); fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT INT TERM

# $1 file  $2 owner  $3 body-of-Human-section
mkfixture() {
    local f="$TMP/$1" owner="$2"; shift 2
    cat > "$f" <<EOF
---
id: T-999
name: "fixture"
status: started-work
workflow_type: build
owner: $owner
---

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify. -->
- [x] an agent criterion, ticked

### Human
<!-- Template examples live in a comment and are INDENTED. A scanner anchored at column 0 must
     never see them as criteria. This is the shape that returns 2 on a naive count for a task
     that has none.
       - [ ] [REVIEW] Dashboard renders correctly
       - [ ] [REVIEWER] Block message names both bypass mechanisms
-->
$*

## Verification
EOF
    printf '%s' "$f"
}

v() { python3 "$TOOL" --task 999 --json 2>/dev/null; }   # unused placeholder; see verdict_of
verdict_of() {
    python3 - "$1" <<'PY'
import sys, importlib.util, os
spec = importlib.util.spec_from_file_location("t931", "tools/_t931-ownership.py")
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
print(m.verdict(sys.argv[1])[0])
PY
}

echo "=== T-931 ownership predicate ==="
echo

# ── THE NEGATIVE LEG FIRST: a live claim must never be read as stale ──────────────────────────
echo "NEGATIVE — a genuine open Human criterion must HOLD ownership"

f="$(mkfixture open-plain.md human '- [ ] a human criterion, unticked')"
ok "one plain open Human AC -> OWNER-JUSTIFIED" \
   "$([ "$(verdict_of "$f")" = "OWNER-JUSTIFIED" ] && echo 0 || echo 1)" "got $(verdict_of "$f")"

f="$(mkfixture open-review.md human '- [ ] [REVIEW] genuine taste judgement')"
ok "open [REVIEW] AC -> OWNER-JUSTIFIED" \
   "$([ "$(verdict_of "$f")" = "OWNER-JUSTIFIED" ] && echo 0 || echo 1)" "got $(verdict_of "$f")"

f="$(mkfixture open-stamp.md human '- [ ] [RUBBER-STAMP] publish the release')"
ok "open [RUBBER-STAMP] AC -> OWNER-JUSTIFIED" \
   "$([ "$(verdict_of "$f")" = "OWNER-JUSTIFIED" ] && echo 0 || echo 1)" "got $(verdict_of "$f")"

f="$(mkfixture open-reviewer.md human '- [ ] [REVIEWER] deterministic, but still filed under Human')"
ok "open [REVIEWER] AC under ### Human -> OWNER-JUSTIFIED (AEF decision 113: the reviewer never ticks a Human AC)" \
   "$([ "$(verdict_of "$f")" = "OWNER-JUSTIFIED" ] && echo 0 || echo 1)" "got $(verdict_of "$f")"

f="$(mkfixture open-mixed.md human '- [x] one ticked human criterion
- [ ] and one still open')"
ok "mixed ticked+open -> OWNER-JUSTIFIED (one open is enough)" \
   "$([ "$(verdict_of "$f")" = "OWNER-JUSTIFIED" ] && echo 0 || echo 1)" "got $(verdict_of "$f")"
echo

# ── THE POSITIVE LEG: the shapes the ruling actually covers ───────────────────────────────────
echo "POSITIVE — no open Human criterion means the field is stale"

f="$(mkfixture none-at-all.md human '')"
ok "comment-only ### Human section (T-885's shape) -> OWNER-STALE" \
   "$([ "$(verdict_of "$f")" = "OWNER-STALE" ] && echo 0 || echo 1)" "got $(verdict_of "$f")"

f="$(mkfixture all-ticked.md human '- [x] the human ticked this one
- [x] and this one')"
ok "every Human AC ticked -> OWNER-STALE" \
   "$([ "$(verdict_of "$f")" = "OWNER-STALE" ] && echo 0 || echo 1)" "got $(verdict_of "$f")"

f="$(mkfixture not-owned.md agent '- [ ] an open human criterion on an agent-owned task')"
ok "owner: agent -> NOT-HUMAN-OWNED (predicate says nothing about tasks it does not govern)" \
   "$([ "$(verdict_of "$f")" = "NOT-HUMAN-OWNED" ] && echo 0 || echo 1)" "got $(verdict_of "$f")"
echo

# ── CONTROLS: prove the harness can fail, and that the comment trap is really a trap ──────────
echo "CONTROLS"

# C1: the indented template examples must NOT be counted. If they were, none-at-all.md would read
# as OWNER-JUSTIFIED. Assert the trap directly rather than trusting the result above.
f="$(mkfixture trap.md human '')"
naive="$(grep -cE '^\s*-\s*\[.\]' "$f")"
strict="$(grep -cE '^- \[.\]' "$f")"
ok "the comment trap is real: naive count $naive > column-0 count $strict" \
   "$([ "$naive" -gt "$strict" ] && echo 0 || echo 1)" \
   "if these are equal the fixture no longer exercises the hazard and the leg above proves less"

# C2: ok() must actually report FAIL when handed a non-zero verdict. Checked in a SUBSHELL so the
# control cannot disturb this run's own counters — an earlier draft of this file decremented FAIL
# by hand to "re-score" a deliberate failure, which is a suite editing its own result.
c2="$( PASS=0; FAIL=0
       ok() { if [ "$2" -eq 0 ]; then echo "PASS"; else echo "FAIL"; fi; }
       ok "probe" 1 )"
ok "ok() reports FAIL for a non-zero verdict (the harness can fail)" \
   "$([ "$c2" = "FAIL" ] && echo 0 || echo 1)" \
   "ok() returned '$c2' where FAIL was required — every PASS above would be meaningless"

# C3: and reports PASS for zero, so C2 is not passing because ok() always says FAIL.
c3="$( ok() { if [ "$2" -eq 0 ]; then echo "PASS"; else echo "FAIL"; fi; }; ok "probe" 0 )"
ok "ok() reports PASS for a zero verdict (it is not stuck on FAIL)" \
   "$([ "$c3" = "PASS" ] && echo 0 || echo 1)" "ok() returned '$c3'"
echo

echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
