#!/usr/bin/env bash
# =============================================================================
#  T-1022 — ENABLE THE BARE-IMPORT GATE (pending since T-936, 2026-09-29)
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHY: `import` is ImageMagick's screen-capture tool. When a python heredoc leaks to the shell,
#  its first line runs import(1), which photographs the screen and writes megabytes of PostScript
#  at the repo root, exiting 0. It happened four times in seven days here (OBS-448, 37MB).
#  .agentic-framework/agents/context/check-bare-import.sh refuses such a command, but only once it
#  is registered as a hook, and that means writing .claude/settings.json. Agents are structurally
#  barred from that file (B-005), so it is your step.
#
#  WHAT THIS DOES (one confirmed step):
#    1. fw hook-enable --event PreToolUse --matcher Bash --name check-bare-import
#       This adds ONE hook entry to .claude/settings.json and changes nothing else.
#  BEFORE THAT it checks, and stops at the first failure:
#    - the gate script exists and its tests pass (tools/_t936-bare-import-gate-teeth.sh, 17 cases:
#      8 commands it must refuse, 9 working commands it must allow, including python heredocs);
#    - the hook is not already registered (re-running is harmless; it stops here);
#    - it shows you the --dry-run of the settings change.
#  Undo: remove the check-bare-import entry under PreToolUse/Bash in .claude/settings.json.
# =============================================================================
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-1022 started $TS  log: $LOG"
. "$PROJ/tools/runme-signal.sh"; runme_signal_init "T-1022 enable bare-import gate" "$LOG"

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }
confirm() { runme_signal step "asking: $1"; runme_confirm "$1"; }

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
cd "$PROJ" || fail "cannot cd to $PROJ"
FW="$PROJ/.agentic-framework/bin/fw"
GATE="$PROJ/.agentic-framework/agents/context/check-bare-import.sh"

echo
echo "== preconditions"
[ -x "$FW" ] || fail "fw not found at $FW"
[ -f "$GATE" ] || fail "gate script missing: $GATE"
echo "ok  gate script present"
if bash "$PROJ/tools/_t936-bare-import-gate-teeth.sh" > "$PROJ/.context/working/runme-$TS-teeth.out" 2>&1; then
    echo "ok  gate tests: $(grep -E '^PASS:' "$PROJ/.context/working/runme-$TS-teeth.out")"
else
    tail -20 "$PROJ/.context/working/runme-$TS-teeth.out"
    fail "gate tests are red; not enabling a gate that misbehaves"
fi
if python3 -c "
import json,sys
d=json.load(open('$PROJ/.claude/settings.json'))
for h in d.get('hooks',{}).get('PreToolUse',[]):
    for x in h.get('hooks',[]):
        if 'check-bare-import' in x.get('command',''):
            sys.exit(0)
sys.exit(1)"; then
    echo "ok  already enabled; nothing to do"
    runme_signal step "already enabled"
    echo "rc=0  (log: $LOG)"; exit 0
fi
echo "ok  not yet enabled"

echo
echo "== what step 1 would write (--dry-run of fw hook-enable)"
"$FW" hook-enable --event PreToolUse --matcher Bash --name check-bare-import --dry-run 2>&1 | grep -n "check-bare-import" | head -5
runme_signal step "preconditions ok"

if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: nothing written."; echo "rc=0  (log: $LOG)"; exit 0; fi

echo
confirm "Step 1/1: register check-bare-import as a PreToolUse(Bash) hook in .claude/settings.json?" || fail "declined at step 1"
"$FW" hook-enable --event PreToolUse --matcher Bash --name check-bare-import || fail "fw hook-enable failed"
grep -q "check-bare-import" "$PROJ/.claude/settings.json" || fail "hook-enable returned 0 but settings.json does not name the hook"
echo "ok  enabled"; runme_signal step "1/1 done: hook enabled"

echo
echo "DONE: the bare-import gate is enabled. It takes effect for new tool calls in Claude Code."
echo "rc=0  (log: $LOG)"
