#!/usr/bin/env bash
# =============================================================================
#  T-995 — RECORD THE INCEPTION DECISION: why the bridge suite slid 7 -> 38 failures
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHAT THIS DOES: records your go / no-go / defer on inception T-995 with
#  `fw inception decide` (operator-only: the agent may not record it). One step, confirmed.
#
#  THE AGENT'S RECOMMENDATION: GO. Findings: docs/reports/T-995-bridge-suite-slide.md
#    - ~24 of 38 failures: local fixes to the vendored framework reverted by re-vendoring
#      (T-840 on 09-25; the uncommitted T-988 has already erased the T-952 audit rail)
#    - nothing that reads the suite can block anything; 3 releases went out at 38-40
#    - the audit's only report lived inside a vendored file and was erased in a day
#    - OBS-430 (urgent, 09-28) named the rc-0 defect and was never acted on
#    - piping the suite into `head` kills it mid-run and records rc 0 for a partial sweep
#  GO creates: B1 runner record integrity, B2 release refuses on a rise, B3 project rails out
#  of vendored files, B4 re-vendoring becomes gated (applies to T-988 now), B5 re-anchor the
#  floor; U1 proposal to AEF upstream. The 9 designer failures become separate bug tasks.
#
#  The agent ran --dry-run only.
# =============================================================================
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -uo pipefail

PROJ=/opt/832-Workflow-designer
FW="$PROJ/.agentic-framework/bin/fw"
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-995 started $TS  log: $LOG"

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
cd "$PROJ" || fail "project dir missing"

# --- preflight: nothing is written before these pass ---
[ -x "$FW" ] || fail "fw not found at $FW"
TASK=$(ls .tasks/active/T-995-*.md 2>/dev/null | head -1)
[ -n "$TASK" ] || fail "T-995 is not in .tasks/active/ (already decided or moved?)"
echo "ok  T-995 is active: $TASK"
grep -q "^workflow_type: inception" "$TASK" || fail "T-995 is not an inception"
echo "ok  T-995 is an inception"
open=$(awk '/^- \*\*IW-/{q=1} q&&/^  disposition:/{ if ($2=="") n++; q=0 } END{print n+0}' "$TASK")
[ "$open" = 0 ] || fail "$open open question(s) have no disposition"
echo "ok  all 4 open questions are disposed (IW-1 dissolved, IW-2/3/4 answered)"
[ -f docs/reports/T-995-bridge-suite-slide.md ] || fail "research artifact missing"
echo "ok  findings: docs/reports/T-995-bridge-suite-slide.md"

RATIONALE_GO="Slide caused by re-vendoring over local patches (~24/38), no consumer that can block, rails inside vendored files, and an exit-0-on-SIGPIPE record. Build B1-B5, upstream U1; designer failures as separate bug tasks."

echo
echo "YOUR CHOICE (the agent recommends GO):"
echo "  g = GO      — build B1-B5, propose U1 to AEF"
echo "  n = NO-GO   — record that none of this is built (you will be asked why)"
echo "  d = DEFER   — record a deferral (you will be asked what evidence is missing)"
if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: would ask g/n/d, then run: fw inception decide T-995 <go|no-go|defer> --rationale ..."; echo "rc=0  (log: $LOG)"; exit 0; fi

read -r -p "Decision [g/n/d, anything else = stop]: " ans </dev/tty || ans=""
case "$ans" in
  g|G) DEC=go;    RAT="$RATIONALE_GO" ;;
  n|N) DEC=no-go; read -r -p "Why NO-GO (one line): " RAT </dev/tty; [ -n "$RAT" ] || fail "no reason given; nothing recorded" ;;
  d|D) DEC=defer; read -r -p "What evidence is missing (one line): " RAT </dev/tty; [ -n "$RAT" ] || fail "no reason given; nothing recorded" ;;
  *)   fail "not confirmed; nothing recorded" ;;
esac
echo
echo "WILL RUN: fw inception decide T-995 $DEC --rationale \"$RAT\""
read -r -p "Record it? [y/N] " ok </dev/tty || ok=n
[ "$ok" = y ] || [ "$ok" = Y ] || fail "not confirmed; nothing recorded"

"$FW" inception decide T-995 "$DEC" --rationale "$RAT" || fail "fw inception decide failed (see above)"
echo
echo "DONE: T-995 decided: $DEC"
echo "rc=0  (log: $LOG)"
