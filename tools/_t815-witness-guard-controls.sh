#!/usr/bin/env bash
# _t815-witness-guard-controls.sh — does the witness ordering guard discriminate?
#
# T-815. The guard asserts that in the committed witness, <bpmn:extensionElements> precedes
# <bpmn:conditionExpression> inside every sequence flow carrying both — the ordering T-690
# established on 2026-09-09 and which the committed witness then contradicted for 17 days.
#
# THE GUARD PASSES TODAY, which is exactly why this exists: a guard whose only observed
# behaviour is "green on the current tree" is indistinguishable from one that examines
# nothing. Three branches:
#
#   A  the live witness                    -> PASS   (baseline; the others mean nothing without it)
#   B  a pair swapped INSIDE one flow      -> FAIL   (the guard has teeth)
#   C  the witness as committed at T-423   -> FAIL   (the real historical drift, not a mutant)
#
# C IS THE STRONGEST BRANCH AND IT IS FREE. The pre-T-690 bytes are immutable at 89bdecdc,
# so the control does not have to synthesise the defect — it replays the one that actually
# happened. The usual objection to git-ref fixtures (a mutant derived from HEAD~N expires
# silently when the next commit lands) does not apply to a pinned immutable sha; the branch
# skips itself with a stated reason if that object ever becomes unreachable, rather than
# passing on absence.
#
# B'S STIMULUS IS FUSSY FOR A MEASURED REASON. The first draft swapped the first matching
# pair in the document, which spanned two different elements and produced a file the guard
# correctly ignored. The second targeted the first sequence flow, which carries no pair at
# all (only 9 of 28 do). A stimulus must fire where the subject looks — the same lesson
# T-809's control B recorded, one file over.
#
# Exit: 0 all branches behaved | 1 a branch disagreed | 3 could not set up

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUARD="$REPO/tools/_t815-witness-ordering-guard.py"
WITNESS="$REPO/tests/fixtures/exported/t423-carrier-witness.bpmn"
PRE_T690_SHA="89bdecdc"   # T-423's commit — the last one before T-690 changed the ordering

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
skip(){ printf '  skip %s\n       %s\n' "$1" "$2"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }

[ -f "$GUARD" ]   || cannot "guard not found: $GUARD"
[ -f "$WITNESS" ] || cannot "witness not found: $WITNESS"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

run_guard() { T815_WITNESS="$1" python3 "$GUARD" >/dev/null 2>&1; }

echo "=== T-815 witness-guard controls ==="

# --- A: baseline. If the live witness does not pass, B and C prove nothing.
if run_guard "$WITNESS"; then
    ok "A live witness -> PASS (baseline live)"
else
    bad "A live witness should PASS" "baseline broken; B and C would prove nothing. Stopping."
    echo; echo "PASS=$PASS FAIL=$FAIL"; exit 1
fi

# --- B: swap the pair inside the first flow that actually carries both.
python3 - "$WORK/swapped.bpmn" "$WITNESS" <<'PY'
import re, sys
dst, src = sys.argv[1], sys.argv[2]
s = open(src, encoding="utf-8").read()
pair = re.compile(
    r"(\s*)(<bpmn:extensionElements>.*?</bpmn:extensionElements>)"
    r"(\s*)(<bpmn:conditionExpression\b.*?</bpmn:conditionExpression>)", re.S)
done = [False]
def swap(m):
    flow = m.group(0)
    if done[0]:
        return flow
    out, n = pair.subn(r"\3\4\1\2", flow, count=1)
    if n:
        done[0] = True
    return out
out = re.sub(r"<bpmn:sequenceFlow\b.*?</bpmn:sequenceFlow>", swap, s, flags=re.S)
open(dst, "w", encoding="utf-8").write(out)
sys.exit(0 if done[0] else 1)
PY
if [ $? -ne 0 ]; then
    bad "B setup" "could not find a sequence flow carrying both children to swap"
elif run_guard "$WORK/swapped.bpmn"; then
    bad "B swapped pair should FAIL" "the guard passed a witness in the wrong order — it is inert"
else
    ok "B pair swapped inside one flow -> FAILS (the guard has teeth)"
fi

# --- C: the real pre-T-690 bytes.
if git -C "$REPO" cat-file -e "$PRE_T690_SHA:tests/fixtures/exported/t423-carrier-witness.bpmn" 2>/dev/null; then
    git -C "$REPO" show "$PRE_T690_SHA:tests/fixtures/exported/t423-carrier-witness.bpmn" \
        > "$WORK/pre-t690.bpmn" 2>/dev/null
    if run_guard "$WORK/pre-t690.bpmn"; then
        bad "C pre-T-690 witness should FAIL" \
            "the guard passes the exact bytes that sat 17 days out of step — it would not have caught the thing it exists for"
    else
        ok "C the real pre-T-690 witness ($PRE_T690_SHA) -> FAILS (replays the actual drift)"
    fi
else
    skip "C pre-T-690 witness" \
         "$PRE_T690_SHA:tests/fixtures/exported/t423-carrier-witness.bpmn is unreachable in this clone — skipped with a reason rather than passed on absence"
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
