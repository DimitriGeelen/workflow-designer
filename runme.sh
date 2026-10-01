#!/usr/bin/env bash
# =============================================================================
#  T-982 — RECORD THE GO DECISION ON THE GENERATE-REVIEW-LEARN LOOP
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHAT THIS DOES: records the operator's GO on inception T-982 (agent-led map generation with
#  an iterative review-correct loop whose learnings feed back into the guide, rubric and
#  validator). GO means three build slices: B1 the loop ships in the kit (citation convention,
#  rubric v3, review/correct briefs, loop driver, planted-defect calibration set + test);
#  B2 the learning ledger and its promotion step; B3 provenance on save + structural diff so
#  human edits become proposed learnings. Report: docs/reports/T-982-generate-review-loop.md
#
#  THE AGENT DOES NOT RUN THIS. An inception decision is the operator's authority, and
#  check-tier0.sh matches command TEXT, so a decision moved into a script is invisible to
#  it (OBS-449). The agent only ran --dry-run.
# =============================================================================
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-982 started $TS  log: $LOG"

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
FW="$PROJ/.agentic-framework/bin/fw"
RATIONALE="GO: the generate -> review -> correct -> learn loop was run end to end on two sources (docs/reports/T-982-generate-review-loop.md). Reviewer caught 3/3 planted defects, 0 false positives; a blind spot shared by two agent reviewers was closed by one human disagreement turned into rubric v3, which then caught 2/2 with 0 false alarms on a clean control; the corrector applied the findings and named the cause; re-review clean. The deterministic validator accepted every planted defect. Build slices: B1 loop in the kit with reviewer calibration, B2 learning ledger + promotion with human checkpoint, B3 provenance on save + structural diff for human edits."

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }

# --- preflight: each check says what it proves; nothing is written before all pass ---
cd "$PROJ" || fail "project dir missing"
[ -x "$FW" ] || fail "fw not found at $FW"
TASK=$(ls .tasks/active/T-982-*.md 2>/dev/null | head -1)
[ -n "$TASK" ] || fail "T-982 is not in .tasks/active (already decided or moved?)"
echo "ok  T-982 exists: $TASK"
grep -q '^workflow_type: inception' "$TASK" || fail "T-982 is not an inception"
echo "ok  T-982 is an inception"
test -s docs/reports/T-982-generate-review-loop.md || fail "the research report is missing"
echo "ok  research report present"
if grep -qE '^\*\*Decision\*\*: *(GO|NO-GO)' "$TASK"; then fail "T-982 already carries a decision"; fi
echo "ok  no decision recorded yet"
# Added after the first real run stopped here: `fw inception decide` refuses without a
# review marker (T-973 gate). The agent runs `fw task review T-982` to create it; this
# check makes the script say so up front instead of failing at the last step.
test -f .context/working/.reviewed-T-982 || fail "no review marker: run  cd $PROJ && $FW task review T-982"
echo "ok  review marker present (fw task review T-982 has run)"
# The second real run stopped at the hypothesis gate. Run the framework's OWN gate functions
# here, so any refusal happens before the confirm prompt rather than after it.
bash -c "source .agentic-framework/lib/task-audit.sh && audit_task_placeholders '$TASK' && audit_inception_recommendation '$TASK' && audit_inception_hypothesis '$TASK' go" \
  || fail "a decide gate refuses T-982 (placeholders / recommendation / hypothesis): see the lines above"
echo "ok  placeholder, recommendation and hypothesis gates pass"

echo
echo "WILL RUN:"
echo "  $FW inception decide T-982 go --rationale \"<rationale above, $(echo -n "$RATIONALE" | wc -c) chars>\""
if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: nothing written."; echo "rc=0  (log: $LOG)"; exit 0; fi

echo
read -r -p "Record GO on T-982? [y/N] " ans </dev/tty || ans=n
[ "$ans" = y ] || [ "$ans" = Y ] || fail "not confirmed, nothing written"

"$FW" inception decide T-982 go --rationale "$RATIONALE" || fail "fw inception decide returned non-zero"
echo
echo "DONE: GO recorded on T-982."
echo "rc=0  (log: $LOG)"
