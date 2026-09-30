#!/usr/bin/env bash
# =============================================================================
#  T-925 — RULE THE SEAM QUESTION
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
# =============================================================================
#
#  WHY THE AGENT DOES NOT RUN THIS. check-tier0.sh matches COMMAND TEXT, so a
#  consequential command inside a script is invisible to it — the harness only
#  ever sees "bash runme.sh". On 2026-09-30 an agent moved a force-push into a
#  script to stabilise its Tier 0 approval hash and the move defeated the gate;
#  the push executed with `fw tier0 approve` still reporting "approvals logged:
#  0" (OBS-449). Wrapping commands for the operator is required. Running the
#  wrapper is a four-control bypass in one invocation.
#
#  This script records a DECISION. It changes no code, moves no corpus bytes,
#  and touches nothing under examples/ or tools/yaml-to-bpmn.py.
#
#  Log opens on the first line, before any validation, because the refusal path
#  is the one most likely to be hit first and the one that most needs a trace.
#  runme-LATEST.log is a FILE COPY made on an EXIT trap — never a symlink, which
#  would point at an older successful run and hide a failure.
# =============================================================================
set -uo pipefail

PROJ="/opt/832-Workflow-designer"
cd "$PROJ" || { echo "FATAL: cannot cd to $PROJ"; exit 1; }

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="$PROJ/runme-$TS.log"
exec > >(tee -a "$LOG") 2>&1
trap 'cp -f "$LOG" "$PROJ/runme-LATEST.log" 2>/dev/null || true' EXIT

echo "=== T-925 seam decision — $TS ==="
echo "log: $LOG"
echo

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1 && echo "*** DRY RUN — nothing will be recorded ***" && echo

# ---------------------------------------------------------------------------
# PREFLIGHT — each check states what it proves.
# ---------------------------------------------------------------------------
echo "--- preflight ---"
fail=0
chk() {  # chk <description> <what it proves>  ; command on stdin via eval
    if eval "$2" >/dev/null 2>&1; then
        echo "  ok    $1"
    else
        echo "  FAIL  $1"
        fail=1
    fi
}
chk "task T-925 is active (the decision has somewhere to land)" \
    "ls .tasks/active/T-925-*.md"
chk "the brief exists (you are not being asked to decide blind)" \
    "test -f docs/reports/T-925-workflowmeta-bridge-seam.md"
chk "the bridge still cannot emit workflowMeta (the defect is still real)" \
    "test \"\$(grep -c 'aef:workflowMeta' tools/yaml-to-bpmn.py)\" -eq 0"
chk "exactly 2 renders are bridge-produced (the measured blast radius holds)" \
    "test \"\$(grep -rl 'by tools/yaml-to-bpmn.py' examples/ build/ 2>/dev/null | wc -l)\" -eq 2"
chk "fw is runnable" \
    "test -x .agentic-framework/bin/fw"

if [ "$fail" -ne 0 ]; then
    echo
    echo "REFUSED: a preflight check failed. Nothing was changed."
    echo "The tree is exactly as it was. Log: $LOG"
    exit 2
fi
echo "  all preflight checks passed"
echo

# ---------------------------------------------------------------------------
# THE DECISION
# ---------------------------------------------------------------------------
cat <<'BRIEF'

  ─────────────────────────────────────────────────────────────────────────────
  MY RECOMMENDATION: A — emit all ten attributes
  ─────────────────────────────────────────────────────────────────────────────

  Rationale, one measured fact per line:

    - The bridge produced 1 of the 25 served renders, not 24. T-925 deferred
      itself on "24/24 rendered maps are bridge-produced"; that is false.
    - The 24 AEF renders come from the designer's exporter — they carry DI,
      a collaboration/participant pair, and workflowMeta, none of which the
      bridge emits. Re-rendered and diffed: 15831 vs 14503 bytes.
    - customer-refund appears in NO pin manifest. Nothing AEF pins moves.
    - 10 tests consume the bridge. None does a golden-byte comparison. None
      asserts workflowMeta absence as correct.
    - test_harness_cross_form_agreement.py records this hole as a KNOWN
      disagreement citing T-925. Fixing the bridge RETIRES that entry.
    - Ten attributes are destroyed today, silently: id uuid version
      schemaVersion title description source tier_default pageWidth kind.
    - Precedent: T-060 ruled the same defect a bug one level down, for
      node-level <aef:meta>, and fixed it.

  Full brief: docs/reports/T-925-workflowmeta-bridge-seam.md

BRIEF

OPTIONS=(
  "A — emit all ten attributes (recommended)"
  "B — emit id only; leave the other nine destroyed"
  "C — rule the bridge is deliberately lossy; record as accepted limitation"
)
CODES=(A B C)
REC=0   # index of the recommended option

# menu: draws on /dev/tty, echoes ONLY the chosen code to stdout so the log
# records the choice without the cursor redraws.
menu() {
    local sel=$REC n=${#OPTIONS[@]}
    if [ ! -t 0 ] || [ ! -e /dev/tty ]; then
        echo "no tty — falling back to the recommended option" >&2
        echo "$REC"
        return 0
    fi
    while :; do
        {
            printf '\n'
            for i in $(seq 0 $((n-1))); do
                if [ "$i" -eq "$sel" ]; then
                    printf '  \033[7m %d) %s \033[0m' "$((i+1))" "${OPTIONS[$i]}"
                else
                    printf '     %d) %s' "$((i+1))" "${OPTIONS[$i]}"
                fi
                [ "$i" -eq "$REC" ] && printf '   <- recommended'
                printf '\n'
            done
            printf '\n  press 1-%d, or arrows + Enter:  ' "$n"
        } > /dev/tty

        IFS= read -rsn1 key < /dev/tty || { printf '\n' > /dev/tty; echo "$REC"; return 0; }
        case "$key" in
            [1-9])
                if [ "$key" -le "$n" ]; then printf '\n' > /dev/tty; echo "$((key-1))"; return 0; fi
                printf '\n  not an option — try again\n' > /dev/tty ;;
            "")  printf '\n' > /dev/tty; echo "$sel"; return 0 ;;
            $'\033')
                IFS= read -rsn2 -t 0.3 rest < /dev/tty || rest=""
                case "$rest" in
                    '[A') sel=$(( (sel - 1 + n) % n )) ;;
                    '[B') sel=$(( (sel + 1) % n )) ;;
                esac ;;
            *) printf '\n  unrecognised key — try again\n' > /dev/tty ;;
        esac
        # redraw: move up over the block we printed
        printf '\033[%dA\033[J' "$((n + 3))" > /dev/tty
    done
}

IDX="$(menu)"
CODE="${CODES[$IDX]}"
CHOICE="${OPTIONS[$IDX]}"

echo "CHOICE: $CODE"
echo "        $CHOICE"
echo

if [ "$DRY" -eq 1 ]; then
    echo "DRY RUN — would record decision $CODE on T-925 and stop here."
    echo "Log: $LOG"
    exit 0
fi

# ---------------------------------------------------------------------------
# CONFIRM the one irreversible-ish step (it writes a decision record).
# ---------------------------------------------------------------------------
printf '  record decision %s on T-925? [y/N] ' "$CODE" > /dev/tty
IFS= read -r yn < /dev/tty || yn=""
case "$yn" in
    y|Y) ;;
    *) echo "ABORTED by operator — nothing recorded. Log: $LOG"; exit 3 ;;
esac
echo

echo "--- recording ---"
.agentic-framework/bin/fw context add-decision \
    "T-925 seam ruling: $CODE — $CHOICE" \
    --task T-925 \
    --rationale "Operator ruling on whether tools/yaml-to-bpmn.py should emit <aef:workflowMeta>. Priced in docs/reports/T-925-workflowmeta-bridge-seam.md: the bridge produced 1 of 25 served renders (not the 24 the original deferral assumed), customer-refund is in no pin manifest, 10 bridge tests contain no golden-byte comparison, and test_harness_cross_form_agreement.py holds a KNOWN disagreement citing T-925 that a fix would retire."
rc=$?

echo
if [ "$rc" -eq 0 ]; then
    echo "RECORDED: decision $CODE on T-925."
else
    echo "WARNING: add-decision exited $rc — the choice is in this log either way: $CODE"
fi

cat <<NEXT

  ─────────────────────────────────────────────────────────────────────────────
  WHAT IS STILL YOURS TO DO
  ─────────────────────────────────────────────────────────────────────────────

  The [REVIEW] Human AC on T-925 is still unticked. I must never tick it — only
  you may. Tick it in:
      .tasks/active/T-925-toolsyaml-to-bpmnpy-drops-document-level.md

  Then, if you chose A or B, slice 2 is the emitter change and it is mine to
  build. If you chose C, the T-301 baseline entry becomes a permanent accepted
  limitation and I will reword it to say so.

  Log: $LOG
  Copy: $PROJ/runme-LATEST.log

NEXT
exit 0
