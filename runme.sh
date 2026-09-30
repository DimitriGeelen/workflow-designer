#!/usr/bin/env bash
# =============================================================================
#  T-925 — TICK THE HUMAN AC AND CLOSE THE TASK
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
# =============================================================================
#
#  WHAT THIS DOES, IN ONE SENTENCE: changes `- [ ]` to `- [x]` on T-925's one
#  [REVIEW] criterion and then closes the task. Nothing else.
#
#  WHY A SCRIPT FOR ONE EDIT. Standing operator instruction: every command-line
#  instruction handed over is wrapped, single or multiple, and the absolute path
#  is printed. I broke it by handing over a bare `sed` and arguing that ticking
#  a Human AC "should be your own act" — which is true and is not an exemption,
#  because YOU RUNNING THIS IS THAT ACT. It is exactly how the T-925 ruling
#  itself was made an hour earlier.
#
#  WHY IT IS LEGITIMATE FOR A SCRIPT TO TICK A HUMAN AC. The rule is that the
#  AGENT must never tick one. This script does not run itself; the operator runs
#  it, sees the exact edit, and confirms. That is the same shape as
#  `fw inception decide`, which also records a human judgement by being invoked.
#
#  THE AGENT DOES NOT RUN THIS. check-tier0.sh matches command TEXT, so anything
#  consequential inside a script is invisible to it — the harness only sees
#  `bash runme.sh` (OBS-449). Only --dry-run was exercised before handover, and
#  the dry run is asserted not to tick.
#
#  Log opens on the first line, before any validation, so the refusal path — the
#  one most likely to be hit first — leaves a trace. runme-LATEST.log is a FILE
#  COPY on an EXIT trap, never a symlink pointing at an older success.
# =============================================================================
set -uo pipefail

PROJ="/opt/832-Workflow-designer"
cd "$PROJ" || { echo "FATAL: cannot cd to $PROJ"; exit 1; }

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="$PROJ/runme-$TS.log"
exec > >(tee -a "$LOG") 2>&1
trap 'cp -f "$LOG" "$PROJ/runme-LATEST.log" 2>/dev/null || true' EXIT

echo "=== T-925: tick the Human AC and close — $TS ==="
echo "log: $LOG"
echo

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1 && echo "*** DRY RUN — nothing will be changed ***" && echo

TASK="$PROJ/.tasks/active/T-925-toolsyaml-to-bpmnpy-drops-document-level.md"

# Content-anchored, never line-number-anchored: a line number silently hits the wrong
# line after any edit above it.
OPEN_RE='^- \[ \] \[REVIEW\] \*\*Rule the seam question'
DONE_RE='^- \[x\] \[REVIEW\] \*\*Rule the seam question'

# ---------------------------------------------------------------------------
# PREFLIGHT — each check says what it proves. A refusal changes nothing.
# ---------------------------------------------------------------------------
echo "--- preflight ---"
fail=0
chk() {
    if eval "$2" >/dev/null 2>&1; then echo "  ok    $1"; else echo "  FAIL  $1"; fail=1; fi
}
chk "T-925 is still active (there is something to close)" \
    "test -f '$TASK'"
chk "the [REVIEW] criterion is present (the anchor still matches)" \
    "grep -qE '$OPEN_RE|$DONE_RE' '$TASK'"
chk "fw is runnable (the close can actually happen)" \
    "test -x '$PROJ/.agentic-framework/bin/fw'"
chk "the ruling this AC records exists (PD-351)" \
    "grep -q 'T-925 seam ruling' '$PROJ/.context/project/decisions.yaml'"

# T-959: THE CHECK THIS SCRIPT WAS MISSING. Ticking the box is worthless if the close is
# then refused — you would be left with a ticked criterion and an open task, which is
# worse than either end state. P-011 runs T-925's ## Verification block on the
# work-completed transition and at no other time (PL-161), so nothing exercises it until
# the moment it matters. `fw task verify` runs exactly that block, read-only, right now.
#
# This is not hypothetical: on 2026-10-01 three of T-925's thirteen lines were FALSE,
# because they asserted the BUG (the emitter drops workflowMeta) that the operator's own
# ruling had since fixed under T-953. The first version of this script would have ticked
# and then failed. Found by running the full bridge suite, not by reading.
chk "T-925's own Verification block passes, so the close will not be refused" \
    "'$PROJ/.agentic-framework/bin/fw' task verify T-925"

if [ "$fail" -ne 0 ]; then
    echo
    echo "REFUSED by a preflight check. Nothing was changed; the tree is as it was."
    echo
    echo "If the FAIL was the Verification-block check, see exactly which line is red:"
    echo "  cd $PROJ && bin/fw task verify T-925"
    echo "That is a real finding about the tree, not a problem with this script — tell the"
    echo "agent which line failed and it will fix the assertion or the thing it asserts."
    echo
    echo "Log: $LOG"
    exit 2
fi

# IDEMPOTENCY — the T-954 lesson, earned by this script's predecessor.
if grep -qE "$DONE_RE" "$TASK"; then
    echo "  STOP  idempotency check: the [REVIEW] criterion is ALREADY ticked"
    echo
    echo "REFUSED by the idempotency preflight check — not by a failure."
    echo "Nothing was changed."
    echo
    echo "If T-925 is still in .tasks/active/ it only needs the close:"
    echo "  cd $PROJ && bin/fw task update T-925 --status work-completed"
    echo
    echo "Log: $LOG"
    exit 4
fi
echo "  all preflight checks passed"
echo

# ---------------------------------------------------------------------------
# SHOW THE EXACT EDIT. The script is checking a box on your behalf; you should
# see precisely what you are authorising before it happens.
# ---------------------------------------------------------------------------
LINE_NO="$(grep -nE "$OPEN_RE" "$TASK" | head -1 | cut -d: -f1)"
echo "--- the exact edit ---"
echo "  file : ${TASK#$PROJ/}"
echo "  line : $LINE_NO"
echo
echo "  before:"
sed -n "${LINE_NO}p" "$TASK" | sed 's/^/    /'
echo "  after:"
sed -n "${LINE_NO}p" "$TASK" | sed "s/^- \[ \]/- [x]/" | sed 's/^/    /'
echo
cat <<'WHAT'
  WHAT THE CRITERION SAYS, and why it is already satisfied in substance:

    "[REVIEW] Rule the seam question: should yaml-to-bpmn.py emit
     <aef:workflowMeta>?"

  You ruled it. Option A, recorded as PD-351, and the emitter change shipped
  under T-953 (128 of 128 documents now derive from an authored id). This box
  is a RECORD of that decision, lagging behind it — and it is stuck only
  because the agent is forbidden to tick a Human AC on your behalf.

  Ticking it asserts nothing new. It closes the bookkeeping.

WHAT

if [ "$DRY" -eq 1 ]; then
    echo "DRY RUN — would tick line $LINE_NO and then close T-925. Stopping here."
    echo "Log: $LOG"
    exit 0
fi

printf '  tick it and close T-925? [y/N] ' > /dev/tty
IFS= read -r yn < /dev/tty || yn=""
case "$yn" in
    y|Y) ;;
    *) echo; echo "ABORTED by operator — nothing changed. Log: $LOG"; exit 3 ;;
esac
echo

# ---------------------------------------------------------------------------
echo "--- ticking ---"
cp -f "$TASK" "$TASK.t957.bak"
sed -i "s/$OPEN_RE/- [x] [REVIEW] **Rule the seam question/" "$TASK"

if grep -qE "$DONE_RE" "$TASK"; then
    echo "  ok    line $LINE_NO is now ticked"
    rm -f "$TASK.t957.bak"
else
    echo "  FAIL  the edit did not land — restoring from backup"
    mv -f "$TASK.t957.bak" "$TASK"
    echo
    echo "REFUSED: the tick could not be applied and the file was restored."
    echo "Log: $LOG"
    exit 5
fi
echo

echo "--- closing T-925 ---"
"$PROJ/.agentic-framework/bin/fw" task update T-925 --status work-completed
rc=$?
echo

if [ "$rc" -eq 0 ]; then
    echo "DONE: T-925's Human AC is ticked and the task is closed."
    echo
    echo "The gate prints a git-add line for the rename and the episodic. If you would"
    echo "rather not run it, tell the agent T-925 is closed and it will commit the"
    echo "leftovers — that part is its job, not yours."
elif grep -q 'R-033' "$LOG" 2>/dev/null; then
    # T-959 round 2: this is the EXPECTED ending, not a failure. Measured live on
    # 2026-10-01 — the first version of this block guessed "probably a verification
    # command failed", which was wrong and sent the reader looking in the wrong place.
    # The tick is all a script CAN do here, by design.
    echo "TICK LANDED. The close is held by the sovereignty gate (R-033), which is correct."
    echo
    echo "T-925 is owner: human. R-033 refuses ANY agent-initiated work-completed on a"
    echo "human-owned task — unconditionally, regardless of whether the Human AC is ticked."
    echo "Its only bypass is --skip-sovereignty, which is yours to authorise, never mine."
    echo
    echo "Finish it in one click — this is the designed path, and the click IS the"
    echo "authorisation (web/blueprints/tasks.py:1063 passes --skip-sovereignty as a"
    echo "recorded human action):"
    echo
    echo "    $(cat "$PROJ/.context/working/watchtower.url" 2>/dev/null || echo http://localhost:3013)/review/T-925"
    echo
    echo "Nothing is being skipped in substance: the agent measured all 13 verification"
    echo "lines green before you ran this, and the preflight above re-checked them."
else
    echo "The tick LANDED but the close exited $rc, and NOT on the sovereignty gate."
    echo "Read the gate output above — then send the agent the failing line. Diagnosing"
    echo "it is its job, not yours."
fi

echo
echo "Log:  $LOG"
echo "Copy: $PROJ/runme-LATEST.log"
exit "$rc"
