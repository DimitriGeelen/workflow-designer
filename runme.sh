#!/usr/bin/env bash
# =============================================================================
#  T-1020 — YOUR GO / NO-GO / DEFER on the census of silently lost local fixes
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHAT THIS DOES: shows the census result, asks for your decision, then records it with
#  `fw inception decide` (operator-only: the agent may not record it). One step, confirmed twice.
#  Full report: docs/reports/T-1020-silent-loss-census.md
#
#  THE QUESTION: the framework upgrade on 10-02 erased one of our local fixes with no trace
#  (T-931, found yesterday). Did it erase others?
#
#  THE ANSWER (measured over 211 changes, each checked with its own probe or by behaviour):
#  FIVE more were lost. Most other candidates are still present.
#    1. T-939 SECURITY: this host's real machine-id is back in a vendored report (it had been
#       redacted). The key that encrypts the framework's stored secrets derives from it. The same
#       file is in AEF's PUBLIC GitHub repo (both branches). AEF has been told (no value sent).
#    2. T-908: `fw fabric impact` crashes on 24 cards and hides the crash, so it prints an empty
#       chain, which reads as "nothing depends on this file".
#    3. T-866: an inception can be decided GO without a hypothesis anyone could check.
#    4. T-912: `fw note promote` records "task" instead of the task id it created.
#    5. T-914: `fw note resolve` (the way to close a fixed observation) is gone.
#
#  GO means: one small build task per lost fix, each with a test, each also sent to AEF.
#  It does NOT decide anything about rotating keys or rewriting git history for item 1; those
#  stay your separate decisions.
# =============================================================================
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-1020 started $TS  log: $LOG"
. "$PROJ/tools/runme-signal.sh"; runme_signal_init "T-1020 inception decision" "$LOG"

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
cd "$PROJ" || fail "cannot cd to $PROJ"
FW="$PROJ/.agentic-framework/bin/fw"
[ -x "$FW" ] || fail "fw not found at $FW"
[ -f docs/reports/T-1020-silent-loss-census.md ] || fail "census report missing"
ls .tasks/active/T-1020-*.md >/dev/null 2>&1 || fail "T-1020 is not active (already decided?)"

RATIONALE_GO="Census found five local fixes the 1.7.740 re-vendor erased silently (T-939 machine-id re-published, T-908 fabric impact silent crash, T-866 GO without observable hypothesis, T-912 promote records 'task', T-914 note resolve gone). Restore each as its own build task with a probe, and send each upstream in bundle E (T-1021). Key rotation and any history rewrite for T-939 are decided separately."

sed -n '/^## Recommendation: GO/,/^Each becomes/p' docs/reports/T-1020-silent-loss-census.md
echo
echo "Decide: g = GO (recommended), n = NO-GO, d = DEFER"
runme_signal step "asking: decision g/n/d"

if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: would ask g/n/d, then run: fw inception decide T-1020 <go|no-go|defer> --rationale ..."; echo "rc=0  (log: $LOG)"; exit 0; fi

read -r -p "Decision [g/n/d, anything else = stop]: " ans </dev/tty || ans=""
case "$ans" in
  g|G) DEC=go;    RAT="$RATIONALE_GO" ;;
  n|N) DEC=no-go; read -r -p "Why NO-GO (one line): " RAT </dev/tty; [ -n "$RAT" ] || fail "no reason given; nothing recorded" ;;
  d|D) DEC=defer; read -r -p "What evidence is missing (one line): " RAT </dev/tty; [ -n "$RAT" ] || fail "no reason given; nothing recorded" ;;
  *)   fail "not confirmed; nothing recorded" ;;
esac
echo
echo "WILL RUN: fw inception decide T-1020 $DEC --rationale \"$RAT\""
read -r -p "Record it? [y/N] " ok </dev/tty || ok=n
[ "$ok" = y ] || [ "$ok" = Y ] || fail "not confirmed; nothing recorded"

"$FW" inception decide T-1020 "$DEC" --rationale "$RAT" || fail "fw inception decide failed (see above)"
runme_signal step "decided: $DEC"
echo
echo "DONE: T-1020 decided: $DEC"
echo "rc=0  (log: $LOG)"
