#!/usr/bin/env bash
# =============================================================================
#  T-1049 — INSTALL THE ONE NEW CRON JOB AEF 1.8.2 ADDED (hourly vector-index reindex)
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHY: the upgrade you ran put `index-reindex-hourly` into the cron registry, but the
#  installed crontab (/etc/cron.d/agentic-audit-832-workflow-designer) does not have it yet.
#  AEF's release note: after upgrading, run `fw cron install`. Without it, semantic recall
#  (fw recall, fw ask, Watchtower search) never sees new learnings and reports.
#  Safe on 1.8.2: the job refuses when disk is short and cleans up after itself (AEF T-3860).
#  Our index is 45 KB; the disk has ~373 GB free.
#
#  WHAT IT DOES: checks the pending change is exactly that one job, then one y/N step:
#  `fw cron install` (rewrites the crontab atomically). The agent ran --dry-run only.
# =============================================================================
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-1049 cron install started $TS  log: $LOG"
. "$PROJ/tools/runme-signal.sh"; runme_signal_init "T-1049 install the index-reindex-hourly cron job" "$LOG"

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
cd "$PROJ" || fail "project dir missing"
FW=.agentic-framework/bin/fw
CRON=/etc/cron.d/agentic-audit-832-workflow-designer

# --- preflight: nothing is written before all of these pass ---
[ "$(tr -d '[:space:]' < .agentic-framework/VERSION)" = "1.8.2" ] || fail "framework is not 1.8.2; the reindex disk guard needs 1.8.2"
echo "ok  framework 1.8.2 (reindex disk guard present)"
grep -q 'index reindex' "$CRON" && { echo "ok  the job is already installed; nothing to do"; echo "rc=0  (log: $LOG)"; exit 0; }
PLAN=$("$FW" cron install --dry-run 2>&1) || fail "fw cron install --dry-run failed: $PLAN"
added=$(printf '%s\n' "$PLAN" | grep -c '^  +[^+]')
removed=$(printf '%s\n' "$PLAN" | grep -c '^  -[^-]')
printf '%s\n' "$PLAN" | grep -q '^  +.*index reindex' || fail "the pending change does not add the reindex job"
[ "$removed" -eq 0 ] || { printf '%s\n' "$PLAN"; fail "the pending change also REMOVES $removed line(s); not what this script is for — tell the agent"; }
[ "$added" -le 3 ] || { printf '%s\n' "$PLAN"; fail "the pending change adds $added lines, expected the one job (blank, comment, job) — tell the agent"; }
echo "ok  pending change: only the hourly reindex job is added, nothing removed"
df -P "$PROJ" | awk 'NR==2 {printf "ok  free disk: %.0f GB\n", $4/1048576}'

echo
echo "WILL RUN:  $FW cron install   (adds 'index-reindex-hourly', 20 * * * *)"
if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: nothing written."; echo "rc=0  (log: $LOG)"; exit 0; fi

echo
runme_confirm "Install the cron job now?" || fail "not confirmed; nothing written"
runme_signal step "fw cron install"
"$FW" cron install || fail "fw cron install failed (see above)"
grep -q 'index reindex' "$CRON" || fail "the crontab still has no reindex job after install"
grep -q '/tmp/' "$CRON" && fail "the crontab now has a /tmp/ path — tell the agent"
echo "ok  installed: $(grep -c 'agentic-framework/bin/fw' "$CRON") job lines, reindex at minute 20"
echo
echo "DONE. Optional, at a quiet moment: restart your Claude sessions with 'claude-fw --termlink'"
echo "so the new sidecar hooks (mail wakes the agent) load."
echo "rc=0  (log: $LOG)"
