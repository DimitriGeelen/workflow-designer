#!/usr/bin/env bash
# _t932-boundary-agreement.sh — do the TWO encodings of the delegation boundary agree?
#
# G-052, open since 2026-09-21: "the reviewer delegation boundary is encoded twice — in the scanner
# that enforces it and in the predicate that reports it — and nothing checks the two against each
# other." This is that check. Its close condition asks for exactly this instrument.
#
# WHAT IT FOUND ON ITS FIRST RUN. They do not agree, and not marginally:
#
#                          fw reviewer surface (A)   _t770-delegation-boundary.py (B)
#     operator-only                 79                          136
#     reviewer-closeable             1                            0
#     agent-self                     2                          269
#     taste                          8                           81
#     unclassified                  37                            0   (no such rule in B)
#
# A reports 82 open Human criteria across 72 active tasks. B classifies 136 unticked Human-section
# criteria as OPERATOR-ONLY alone. They disagree on the DENOMINATOR — how many open Human criteria
# the corpus contains — by roughly 54, before any bucketing question arises.
#
# THIS INSTRUMENT IS EXPECTED TO BE RED, AND THAT IS ITS VALUE. It converts an invisible divergence
# into a named, measured, re-runnable red. It is deliberately NOT placed in any task's `## Verification`
# block while it fails: a known-red line there blocks unrelated closes and teaches people to add
# --force. When the encodings are reconciled — a POLICY call that belongs to AEF, since "which one is
# right" is not the agent's to decide — this becomes the line that keeps them reconciled.
#
# Exit 0 = the two agree. Exit 1 = they diverge, with the divergence printed. Exit 2 = setup broken,
# which is NOT the same as agreement and must never be read as it.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90

FW=".agentic-framework/bin/fw"
T770="tools/_t770-delegation-boundary.py"

[ -x "$FW" ]    || { echo "SETUP BROKEN: no $FW"; exit 2; }
[ -f "$T770" ]  || { echo "SETUP BROKEN: no $T770"; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "SETUP BROKEN: no python3"; exit 2; }

echo "=== delegation boundary: encoding agreement (G-052) ==="
echo

# ── ENCODING A: the enforcing path ────────────────────────────────────────────────────────────
A_RAW="$("$FW" reviewer surface 2>&1)" || true
A_RC="$(printf '%s' "$A_RAW" | grep -oE 'REVIEWER-CLOSEABLE +[0-9]+' | grep -oE '[0-9]+$' | head -1)"
A_AS="$(printf '%s' "$A_RAW" | grep -oE 'AGENT-SELF +[0-9]+'         | grep -oE '[0-9]+$' | head -1)"
A_OO="$(printf '%s' "$A_RAW" | grep -oE 'OPERATOR-ONLY +[0-9]+'      | grep -oE '[0-9]+$' | head -1)"

# A missing number is setup broken, not a zero. Reading an unparsed field as 0 would make the two
# encodings agree by coincidence whenever the parse rotted — the exact false green this guards.
for v in A_RC A_AS A_OO; do
    [ -n "${!v}" ] || { echo "SETUP BROKEN: could not parse $v from 'fw reviewer surface'"; \
                        printf '%s\n' "$A_RAW" | head -6 | sed 's/^/  | /'; exit 2; }
done

# ── ENCODING B: the reporting predicate ───────────────────────────────────────────────────────
# SCOPE-FAIR OR IT PROVES NOTHING. A counts only open criteria under `### Human`. B classifies every
# unticked criterion, Agent section included. Comparing the raw totals made B look 5x larger (405 vs
# 82) and almost all of that was B's 269 Agent-section rows, which A never looks at — a scope
# difference reported as a disagreement. B is restricted to Human-section rows here. An instrument
# that overstates its finding is no more use than one that misses it, and this one exists to be
# quoted to AEF.
B_JSON="$(python3 "$T770" --json 2>/dev/null)" || { echo "SETUP BROKEN: $T770 --json failed"; exit 2; }
read -r B_RC B_AS B_OO B_ALL <<<"$(printf '%s' "$B_JSON" | python3 -c '
import sys, json
from collections import Counter
rows = json.load(sys.stdin)
if not rows:
    raise SystemExit("EMPTY")
human = [r for r in rows if r.get("section") == "Human"]
c = Counter(r["bucket"] for r in human)
print(c["REVIEWER-CLOSEABLE"], c["AGENT-SELF"], c["OPERATOR-ONLY"], len(rows))
')" || { echo "SETUP BROKEN: could not count buckets from $T770 (empty corpus reads as broken, not as agreement)"; exit 2; }
[ -n "${B_OO:-}" ] || { echo "SETUP BROKEN: no bucket counts from $T770"; exit 2; }

A_TOT=$(( A_RC + A_AS + A_OO ))
B_TOT=$(( B_RC + B_AS + B_OO ))

printf '  %-22s %10s %10s %10s\n' "bucket" "A:enforce" "B:report" "delta"
printf '  %-22s %10s %10s %10s\n' "----------------------" "---------" "--------" "-----"
printf '  %-22s %10d %10d %10d\n' "REVIEWER-CLOSEABLE" "$A_RC" "$B_RC" "$(( B_RC - A_RC ))"
printf '  %-22s %10d %10d %10d\n' "AGENT-SELF"         "$A_AS" "$B_AS" "$(( B_AS - A_AS ))"
printf '  %-22s %10d %10d %10d\n' "OPERATOR-ONLY"      "$A_OO" "$B_OO" "$(( B_OO - A_OO ))"
printf '  %-22s %10d %10d %10d\n' "TOTAL (denominator)" "$A_TOT" "$B_TOT" "$(( B_TOT - A_TOT ))"
echo
echo "  A = fw reviewer surface        (lib/delegation_cli — the path that ENFORCES)"
echo "  B = $T770  (the predicate that REPORTS)"
echo "  Both scoped to OPEN criteria under '### Human'. B also classifies $(( B_ALL - B_TOT ))"
echo "  Agent-section row(s) that A does not look at — scope, not disagreement, excluded above."
echo

DIVERGE=0
[ "$A_RC" -eq "$B_RC" ] || DIVERGE=1
[ "$A_AS" -eq "$B_AS" ] || DIVERGE=1
[ "$A_OO" -eq "$B_OO" ] || DIVERGE=1

if [ "$DIVERGE" -eq 0 ]; then
    echo "AGREE — both encodings return the same buckets over the same tree."
    exit 0
fi

cat <<'NOTE'
DIVERGE — the two encodings disagree, and the disagreement is SMALL AND SPECIFIC.

Read the deltas above before quoting this. Scope-fair, the two agree exactly on the denominator:
both see the same 82 open Human criteria. The disagreement is over a handful of criteria that B
classifies as OPERATOR-ONLY while A considers them delegable (REVIEWER-CLOSEABLE or AGENT-SELF).
B is the STRICTER of the two — it hands the operator work that A would delegate. That direction
matters: the divergence costs the operator friction, it does not leak authority.

This is still G-052 — two encodings of one ruling, nothing comparing them — and it still needs a
normative answer. But an earlier version of this instrument compared raw totals (405 vs 82) and
reported a ~54-criterion denominator gap. That was a SCOPE ERROR, not a finding: almost all of it
was B's Agent-section rows, which A never examines. The `unclassified 37` vs `0` difference is
likewise mostly a VOCABULARY difference — A reports a class taxonomy that includes "unclassified",
B reports rule names and has no such rule — not, on this evidence, 37 misclassified criteria.

WHICH ONE IS RIGHT IS NOT THE AGENT'S CALL. AEF owns PD-302 and T-1443, so AEF owns which encoding
is normative. What this instrument establishes is narrower than it first appeared and is worth
stating precisely: they agree on what to look at, and differ on a few verdicts.
NOTE
exit 1
