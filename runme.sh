#!/usr/bin/env bash
# =============================================================================
#  T-980 — RECORD THE GO DECISION ON THE SIDECAR RCA
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHAT THIS DOES: records the operator's GO on inception T-980 ("why the peer-consult
#  sidecar never works for 832"). GO means: fix it UPSTREAM (AEF D1-D4, TermLink D5-D6),
#  keep the documented local workaround until the next bleeding-edge upgrade, then verify
#  here with `fw sidecar whoami` + a live round trip. Report: docs/reports/T-980-sidecar-rca.md
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
echo "runme.sh T-980 started $TS  log: $LOG"

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
FW="$PROJ/.agentic-framework/bin/fw"
RATIONALE="GO: the peer-consult sidecar works only in the repos that built it (AEF, TermLink, neither vendored); every vendored consumer is deaf. Seven defects, each sufficient (docs/reports/T-980-sidecar-rca.md): D1 identity from FRAMEWORK_ROOT, D2 sidecar-inbox hook never installed, D3 hook cannot parse the CLI dict and fails silent (79 in, 0 out), D4 sweep cron only for AEF, D5 listeners only for TermLink-declared agents, D6 shared host key receipted by TermLink, D7 Ring20 reads DMs not inboxes. Fix upstream, not by patching the vendored copy; RCA sent to AEF as a pickup. Local workaround until the bleeding-edge upgrade: FRAMEWORK_ROOT override for sidecar_cli.py. Verify after upgrade: whoami names 832-Workflow-designer and a live round trip is read here."

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }

# --- preflight: each check says what it proves; nothing is written before all pass ---
cd "$PROJ" || fail "project dir missing"
[ -x "$FW" ] || fail "fw not found at $FW"
TASK=$(ls .tasks/active/T-980-*.md 2>/dev/null | head -1)
[ -n "$TASK" ] || fail "T-980 is not in .tasks/active (already decided or moved?)"
echo "ok  T-980 exists: $TASK"
grep -q '^workflow_type: inception' "$TASK" || fail "T-980 is not an inception"
echo "ok  T-980 is an inception"
test -s docs/reports/T-980-sidecar-rca.md || fail "the RCA report is missing"
echo "ok  RCA report present"
if grep -qE '^\*\*Decision\*\*: *(GO|NO-GO)' "$TASK"; then fail "T-980 already carries a decision"; fi
echo "ok  no decision recorded yet"
# Added after the first real run stopped here: `fw inception decide` refuses without a
# review marker (T-973 gate). The agent runs `fw task review T-980` to create it; this
# check makes the script say so up front instead of failing at the last step.
test -f .context/working/.reviewed-T-980 || fail "no review marker: run  cd $PROJ && $FW task review T-980"
echo "ok  review marker present (fw task review T-980 has run)"
# The second real run stopped at the hypothesis gate. Run the framework's OWN gate functions
# here, so any refusal happens before the confirm prompt rather than after it.
bash -c "source .agentic-framework/lib/task-audit.sh && audit_task_placeholders '$TASK' && audit_inception_recommendation '$TASK' && audit_inception_hypothesis '$TASK' go" \
  || fail "a decide gate refuses T-980 (placeholders / recommendation / hypothesis): see the lines above"
echo "ok  placeholder, recommendation and hypothesis gates pass"

echo
echo "WILL RUN:"
echo "  $FW inception decide T-980 go --rationale \"<rationale above, $(echo -n "$RATIONALE" | wc -c) chars>\""
if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: nothing written."; echo "rc=0  (log: $LOG)"; exit 0; fi

echo
read -r -p "Record GO on T-980? [y/N] " ans </dev/tty || ans=n
[ "$ans" = y ] || [ "$ans" = Y ] || fail "not confirmed, nothing written"

"$FW" inception decide T-980 go --rationale "$RATIONALE" || fail "fw inception decide returned non-zero"
echo
echo "DONE: GO recorded on T-980."
echo "rc=0  (log: $LOG)"
