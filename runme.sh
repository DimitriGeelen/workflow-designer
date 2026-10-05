#!/usr/bin/env bash
# =============================================================================
#  T-1054 — RECORD YOUR DECISION: option 3 (the hybrid runme), GO
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHAT THIS DOES: records your choice with `fw inception decide T-1054 go` (operator-only).
#  One step, confirmed once. Nothing else is changed.
#
#  YOUR CHOICE (in chat, 2026-10-05): option 3 — keep one constant command, but move the
#  safeguards (dry-run, y/N per step, preflight, logging) into ONE reviewed launcher; each job
#  becomes an immutable named file under .context/runme/<name>/; the launcher names the job and
#  its sha256 and refuses a job that changed since its dry-run. Offered to AEF's fw runme.
#  Full reasoning: docs/reports/T-1054-runme-path-brief.md
#
#  After this, the agent creates the build task and builds it; this runme.sh is the LAST one
#  written by hand in the old shape.
# =============================================================================
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-1054 started $TS  log: $LOG"
. "$PROJ/tools/runme-signal.sh"; runme_signal_init "T-1054 inception decision (option 3)" "$LOG"

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
cd "$PROJ" || fail "cannot cd to $PROJ"
FW="$PROJ/.agentic-framework/bin/fw"
[ -x "$FW" ] || fail "fw not found at $FW"
[ -f docs/reports/T-1054-runme-path-brief.md ] || fail "decision report missing"
ls .tasks/active/T-1054-*.md >/dev/null 2>&1 || fail "T-1054 is not active (already decided?)"
[ -f .context/working/.reviewed-T-1054 ] || fail "review marker missing (the agent runs fw task review T-1054 first)"
echo "ok  preconditions: report present, T-1054 active, review marker present"

RAT="Operator chose option 3 (2026-10-05) after an external consult (t1054-runme-path, 5/5 non-Claude, unanimous that the hand-written root runme.sh is wrong: wrong-job risk observed today, dry-run not bound to the live script, safety logic re-implemented per job). Hybrid: one reviewed launcher holds dry-run, y/N per step, preflight, logging and events; each job is an immutable named file under .context/runme/<name>/; the launcher shows job name + sha256 and refuses a job changed since its dry-run; operator command stays constant. Offered upstream to AEF fw runme. Scored 30 vs 16/23/24 (docs/reports/T-1054-runme-path-brief.md)."

echo
echo "WILL RUN: fw inception decide T-1054 go --rationale \"<option 3, see above>\""
runme_signal step "asking: record GO (option 3)"
if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: nothing recorded."; echo "rc=0  (log: $LOG)"; exit 0; fi

runme_confirm "Record GO for option 3?" || fail "not confirmed; nothing recorded"
"$FW" inception decide T-1054 go --rationale "$RAT" || fail "fw inception decide failed (see above)"
runme_signal step "decided: go"
echo
echo "DONE: T-1054 decided GO (option 3). The agent now builds it as a separate task."
echo "rc=0  (log: $LOG)"
