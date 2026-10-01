#!/usr/bin/env bash
# =============================================================================
#  T-981 — INSTALL THE SIDECAR SWEEP JOB INTO /etc/cron.d
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHAT THIS DOES: installs this project's generated crontab (.context/cron/agentic-audit.crontab)
#  into /etc/cron.d via `fw cron install`. The only change is ONE added job, sidecar-sweep-5m: it
#  walks the peer-consult ack ledger every 5 minutes and escalates messages nobody acknowledged.
#  Without it (T-980 D4) an unread consult from this project never escalates. The job came from
#  AEF's lib/cron-seed.sh (T-3673); upgrade could not add it here (it appends at column 0 and our
#  registry indents), so the agent added it to the registry by hand and regenerated the crontab.
#
#  THE AGENT DOES NOT RUN THIS: /etc/cron.d is host state. The agent ran the dry run only.
# =============================================================================
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-981 started $TS  log: $LOG"

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
FW="$PROJ/.agentic-framework/bin/fw"
cd "$PROJ" || fail "project dir missing"

# --- preflight ---
python3 -c "import yaml;d=yaml.safe_load(open('.context/cron-registry.yaml'));assert any(j['id']=='sidecar-sweep-5m' for j in d['jobs'])" \
  || fail "the registry does not parse or lacks sidecar-sweep-5m"
echo "ok  registry parses and carries sidecar-sweep-5m"
grep -q 'sidecar sweep' .context/cron/agentic-audit.crontab || fail "generated crontab lacks the sweep line: run $FW cron generate"
echo "ok  generated crontab carries the sweep line"
"$FW" cron install --dry-run > "$PROJ/.context/working/.runme-cron-dry.txt" 2>&1 || fail "fw cron install --dry-run failed"
ADDED=$(grep -c '^  +[0-9]' "$PROJ/.context/working/.runme-cron-dry.txt"); REMOVED=$(grep -c '^  -[0-9]' "$PROJ/.context/working/.runme-cron-dry.txt")
echo "ok  install diff: $ADDED job line(s) added, $REMOVED removed"
[ "$REMOVED" -eq 0 ] || fail "the install would REMOVE job lines; read .context/working/.runme-cron-dry.txt first"

echo
echo "WILL RUN:  $FW cron install"
if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: nothing written."; echo "rc=0  (log: $LOG)"; exit 0; fi
read -r -p "Install the crontab into /etc/cron.d? [y/N] " a </dev/tty || a=n
[ "$a" = y ] || [ "$a" = Y ] || fail "not confirmed, nothing written"
"$FW" cron install || fail "fw cron install failed"
grep -q 'sidecar sweep' /etc/cron.d/agentic-audit-832-workflow-designer || fail "installed, but the sweep line is not in /etc/cron.d"
echo
echo "DONE: sweep job installed; it first runs at the next :03/:08/:13/... minute."
echo "rc=0  (log: $LOG)"
