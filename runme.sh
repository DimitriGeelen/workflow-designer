#!/usr/bin/env bash
# =============================================================================
#  T-1013 — restore two project hooks that the 1.7.740 upgrade dropped
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHAT HAPPENED: the framework upgrade on 10-02 rewrote .claude/settings.json and left out two
#  hooks this project had registered. The agent committed that rewrite on 10-04 (6e0747c3)
#  without noticing. Found today by T-1013. Both have been missing since then:
#    1. PreToolUse on mcp__termlink__.*  ->  tools/_t420-rail-attribution-gate.py
#       (blocks TermLink calls that would post without rail attribution, T-420)
#    2. PostToolUse on Write|Edit        ->  tools/hooks/warn-uncontrolled-absence.sh
#       (ADVISORY, never blocks: warns when a task's ## Verification gets an absence check
#        with no control, T-843)
#
#  CHECKED BEFORE THIS FILE WAS WRITTEN (agent, 2026-10-04):
#    - the rail gate's own tests pass on today's framework: mutation check 15/15, misfire matrix 23/23
#    - the absence hook warns on an uncontrolled absence, stays silent on a positive check,
#      and exits 0 both times
#
#  WHAT THIS DOES: one step. Back up .claude/settings.json, add the two entries back exactly as
#  they were before 6e0747c3, check the file still parses, and show the difference. Nothing else
#  in the file is touched. A restart of the Claude session picks the hooks up.
#
#  NOTE for the v1.8.0 upgrade: `fw upgrade` rewrites this file again. The upgrade plan must
#  re-check both entries afterwards, or this repeats.
# =============================================================================
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-1013 started $TS  log: $LOG"
. "$PROJ/tools/runme-signal.sh"; runme_signal_init "T-1013 restore two dropped hooks" "$LOG"

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
cd "$PROJ" || fail "cannot cd to $PROJ"
SET=.claude/settings.json
GATE="$PROJ/tools/_t420-rail-attribution-gate.py"
WARN="$PROJ/tools/hooks/warn-uncontrolled-absence.sh"

# ── preconditions (nothing is written until all hold) ─────────────────────────
[ -f "$SET" ] || fail "$SET not found"
python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$SET" || fail "$SET does not parse as JSON today; not touching it"
[ -x "$GATE" ] || fail "$GATE missing or not executable"
[ -x "$WARN" ] || fail "$WARN missing or not executable"
STATE=$(python3 - "$SET" "$GATE" "$WARN" <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); gate, warn = sys.argv[2], sys.argv[3]
cmds = [h.get('command', '') for arr in d.get('hooks', {}).values() for m in arr for h in m.get('hooks', [])]
print(('gate-present' if gate in cmds else 'gate-absent') + ' ' + ('warn-present' if warn in cmds else 'warn-absent'))
PY
) || fail "could not read the hooks in $SET"
echo "today: $STATE"
[ "$STATE" = "gate-present warn-present" ] && { echo "Both hooks are already registered. Nothing to do."; echo "rc=0  (log: $LOG)"; exit 0; }

runme_signal step "precondition ok: $STATE"
echo
echo "Will add to $SET (only the missing ones):"
echo "  PreToolUse  matcher mcp__termlink__.*  ->  $GATE"
echo "  PostToolUse matcher Write|Edit         ->  $WARN"
echo "A backup is written next to it first: $SET.bak-$TS"

if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: nothing written."; echo "rc=0  (log: $LOG)"; exit 0; fi

read -r -p "Restore the missing hook(s)? [y/N]: " ans </dev/tty || ans=""
case "$ans" in y|Y) ;; *) echo "Not changed."; runme_signal step "declined"; echo "rc=0  (log: $LOG)"; exit 0 ;; esac

cp -p "$SET" "$SET.bak-$TS" || fail "could not write the backup"
python3 - "$SET" "$GATE" "$WARN" <<'PY' || { cp -p "$SET.bak-$TS" "$SET"; fail "write failed; backup restored"; }
import json, sys
p, gate, warn = sys.argv[1], sys.argv[2], sys.argv[3]
d = json.load(open(p))
hooks = d.setdefault('hooks', {})
def ensure(event, matcher, cmd):
    arr = hooks.setdefault(event, [])
    for m in arr:
        if any(h.get('command') == cmd for h in m.get('hooks', [])):
            return 'already'
    for m in arr:
        if m.get('matcher') == matcher:
            m.setdefault('hooks', []).append({'type': 'command', 'command': cmd}); return 'added to existing matcher'
    arr.append({'matcher': matcher, 'hooks': [{'type': 'command', 'command': cmd}]}); return 'added'
print('gate:', ensure('PreToolUse', 'mcp__termlink__.*', gate))
print('warn:', ensure('PostToolUse', 'Write|Edit', warn))
tmp = p + '.tmp'
with open(tmp, 'w') as fh:
    json.dump(d, fh, indent=2); fh.write('\n')
json.load(open(tmp))
import os; os.replace(tmp, p)
PY
python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$SET" || { cp -p "$SET.bak-$TS" "$SET"; fail "result did not parse; backup restored"; }
echo
echo "Difference:"
diff "$SET.bak-$TS" "$SET" || true
runme_signal step "hooks restored"
echo
echo "DONE: restart the Claude session (claude-fw -c) so the hooks load."
echo "rc=0  (log: $LOG)"
