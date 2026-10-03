#!/usr/bin/env bash
# _t931-ownership-sweep.sh — the second layer: detect a stale `owner: human` and correct it.
#
# T-931, operator ruling 2026-09-29, two layers:
#   LAYER 1  the process itself reverts ownership at the moment nothing human is left open —
#            update-task.sh's R-033 branch, authorised by the OWNER-STALE predicate.
#   LAYER 2  and if that is overlooked, something detects and corrects it. That is this sweep.
#
# Layer 1 only fires when someone runs `fw task update` on the task. A task nobody touches keeps a
# stale claim forever, which is how 45 of them accumulated — 10 with every Human criterion already
# TICKED by the operator, and 13 with every Agent criterion ticked too. Ten of those 13 had been
# reported by the audit as CTL-029 "completable, not closed" for a month: the control saw the
# symptom and could not name the cause, because the cause is a frontmatter field no check read.
#
# ATTENDED BY DESIGN — NEVER ON CRON. This script WRITES to a sovereignty-protected field. An
# unattended sweep that strips `owner: human` across the corpus is the most dangerous shape available
# here: a wrong predicate removes a real claim from N tasks with nobody watching, and the first
# symptom is a task closing that the operator wanted to see. Cron runs the DETECTOR (the audit
# check), which can only over-report. The corrector is run by hand. `--apply` is required and
# `--dry-run` is the default; there is no config that inverts that.
#
# It does not write the field itself either: every change goes through
# `fw task update <id> --owner agent`, so the R-033 gate, its audit line and the task's own
# machinery all still run. A sweep that edited frontmatter directly would be a second writer for a
# field this work exists to give exactly one.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90

TOOL="tools/_t931-ownership.py"
FW=".agentic-framework/bin/fw"; [ -x "$FW" ] || FW="bin/fw"   # vendoring project, or the framework repo itself (T-1009)
APPLY=0
READY_ONLY=0

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) APPLY=1 ;;
        --dry-run) APPLY=0 ;;
        --ready-only) READY_ONLY=1 ;;
        -h|--help)
            sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done

[ -f "$TOOL" ] || { echo "SETUP BROKEN: no $TOOL"; exit 1; }
[ -x "$FW" ]   || { echo "SETUP BROKEN: no $FW (there is no bin/fw in this project)"; exit 1; }

FILTER=(--stale-only)
[ "$READY_ONLY" -eq 1 ] && FILTER=(--ready-only)

ROWS="$(python3 "$TOOL" "${FILTER[@]}" --json)" || { echo "predicate failed"; exit 1; }
N="$(printf '%s' "$ROWS" | python3 -c 'import sys,json; print(len(json.load(sys.stdin)))')"

# An empty candidate set is reported as such, never as a clean result: "nothing to correct" and
# "the predicate returned nothing" look identical in a success message and are completely
# different facts (T-3105).
if [ "$N" -eq 0 ]; then
    echo "NO CANDIDATES — the predicate returned zero OWNER-STALE tasks."
    echo "That is either a genuinely clean corpus or a predicate that stopped matching."
    echo "Confirm it can still see the corpus at all:  python3 $TOOL | tail -2"
    exit 0
fi

echo "=== T-931 ownership sweep — $([ "$APPLY" -eq 1 ] && echo 'APPLY' || echo 'DRY RUN') ==="
echo "$N task(s) where owner: human has no open Human criterion behind it."
echo

printf '%s' "$ROWS" | python3 -c '
import sys, json
for r in json.load(sys.stdin):
    print("  %-8s human %d/%d open  agent %d/%d  %s"
          % (r["task"], r["open_human"], r["total_human"],
             r["agent_ticked"], r["agent_total"], r["detail"][:78]))
'
echo

if [ "$APPLY" -eq 0 ]; then
    echo "DRY RUN — nothing written. To correct these:"
    echo "  bash $0 --apply"
    exit 0
fi

OK=0; REFUSED=0
while IFS= read -r id; do
    [ -n "$id" ] || continue
    if out="$("$FW" task update "$id" --owner agent 2>&1)"; then
        echo "  CORRECTED  $id"
        OK=$((OK+1))
    else
        # A refusal here is informative, not a nuisance: it means the gate disagreed with the
        # predicate about this task, and that disagreement is exactly what G-052 is open about.
        echo "  REFUSED    $id"
        printf '%s\n' "$out" | sed 's/^/             /' | head -4
        REFUSED=$((REFUSED+1))
    fi
done < <(printf '%s' "$ROWS" | python3 -c '
import sys, json
for r in json.load(sys.stdin): print(r["task"])
')

echo
echo "=== SUMMARY ==="
echo "corrected: $OK"
echo "refused:   $REFUSED"
[ "$REFUSED" -eq 0 ] || echo "A refusal means the gate and the predicate disagree — that is a G-052 finding, not a retry."
exit 0
