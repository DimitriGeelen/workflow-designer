#!/usr/bin/env bash
# =============================================================================
#  T-1035 — YOUR GO / NO-GO / DEFER on the census of 13 lost-looking hook fixes
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHAT THIS DOES: shows the result, asks for your decision, then records it with
#  `fw inception decide` (operator-only). One step, confirmed twice.
#  Full report: docs/reports/T-1035-hook-fix-census.md
#
#  THE QUESTION: 13 checks for 832's own fixes to the framework's hooks were failing on the
#  current framework. Were those fixes lost in the 10-02 upgrade, like the five T-1020 found?
#
#  THE ANSWER (each behaviour tested directly on today's code):
#    - 11 of 13 still hold: 6 because the framework now does the same thing itself, 5 because
#      our own re-applied fixes hold. Their checks were stale, not the behaviour.
#    - 2 are lost, both annoyances rather than safety holes, both in "no task is active":
#        T-650: `fw git commit` and `fw fix-learned` are refused, while the plain
#               `git commit` / `fw context add-learning` they stand for are allowed.
#        T-662: that refusal no longer says why, or how to get through.
#      (The agent hit both twice today while closing tasks.)
#
#  GO means: small build tasks, before the v1.8.0 upgrade:
#    1. restore T-650 and T-662 (and send both to AEF);
#    2. repair the checks so all 13 can run in the test suite and pass;
#    3. tidy the divergence register (one stale entry; declare the two restores).
# =============================================================================
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-1035 started $TS  log: $LOG"
. "$PROJ/tools/runme-signal.sh"; runme_signal_init "T-1035 inception decision" "$LOG"

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
cd "$PROJ" || fail "cannot cd to $PROJ"
FW="$PROJ/.agentic-framework/bin/fw"
[ -x "$FW" ] || fail "fw not found at $FW"
[ -f docs/reports/T-1035-hook-fix-census.md ] || fail "census report missing"
ls .tasks/active/T-1035-*.md >/dev/null 2>&1 || fail "T-1035 is not active (already decided?)"
[ -f .context/working/.reviewed-T-1035 ] || fail "review marker missing (the agent runs fw task review T-1035 first)"

RATIONALE_GO="Census of 13 hook-fix teeth (docs/reports/T-1035-hook-fix-census.md): 11 behaviours hold on 1.7.740 (6 adopted upstream, 5 by 832's re-applies; their teeth are stale), 2 are lost, both usability: T-650 (fw git commit / fw fix-learned refused with no task while their bare forms pass) and T-662 (the null-focus block no longer names the cause or the way through). Build tasks: restore both and send upstream; repair the teeth so all 13 wire green; register hygiene. Before the v1.8.0 upgrade."

sed -n '/^\*\*Summary\.\*\*/,/^## Dialogue/p' docs/reports/T-1035-hook-fix-census.md | sed '$d'
echo
echo "Decide: g = GO (recommended), n = NO-GO, d = DEFER"
runme_signal step "asking: decision g/n/d"

if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: would ask g/n/d, then run: fw inception decide T-1035 <go|no-go|defer> --rationale ..."; echo "rc=0  (log: $LOG)"; exit 0; fi

read -r -p "Decision [g/n/d, anything else = stop]: " ans </dev/tty || ans=""
case "$ans" in
  g|G) DEC=go;    RAT="$RATIONALE_GO" ;;
  n|N) DEC=no-go; read -r -p "Why NO-GO (one line): " RAT </dev/tty; [ -n "$RAT" ] || fail "no reason given; nothing recorded" ;;
  d|D) DEC=defer; read -r -p "What evidence is missing (one line): " RAT </dev/tty; [ -n "$RAT" ] || fail "no reason given; nothing recorded" ;;
  *)   fail "not confirmed; nothing recorded" ;;
esac
echo
echo "WILL RUN: fw inception decide T-1035 $DEC --rationale \"$RAT\""
read -r -p "Record it? [y/N] " ok </dev/tty || ok=n
[ "$ok" = y ] || [ "$ok" = Y ] || fail "not confirmed; nothing recorded"

"$FW" inception decide T-1035 "$DEC" --rationale "$RAT" || fail "fw inception decide failed (see above)"
runme_signal step "decided: $DEC"
echo
echo "DONE: T-1035 decided: $DEC"
echo "rc=0  (log: $LOG)"
