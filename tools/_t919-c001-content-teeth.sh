#!/usr/bin/env bash
# _t919-c001-content-teeth.sh — does the C-001 check test whether the THINKING was preserved?
#
# THE DEFECT. Both audit scanners decided "has research artifact" by LOCATION: a filename under
# docs/reports/ containing the task id, the literal string "docs/reports/" in the body, an episodic
# reference. The active scan had only the filename test. None asked whether the reasoning was
# preserved — which is what C-001 says: "conversations are ephemeral, files are permanent". A task
# file IS a file, committed and durable, and the operator ruled on 2026-09-16 that it counts (OBS-351).
#
# MEASURED BEFORE THE FIX. The completed scan flagged T-250, T-587 and T-879. Every one carried
# substantive exploratory prose in-task. The whole output set was false positives under the ruling.
# OBS-351 recorded 50% on the four RA-00x findings of 2026-09-16; on the live set it was 100%.
#
# WHY A FIXTURE AND NOT THE LIVE CORPUS. The live set moves — the four RA-00x subjects of 2026-09-16
# are not the three flagged on 2026-09-29, and T-015/T-103 have since gained artifacts. Pinning legs
# to live ids is the mutable-corpus rot that took T-885's verification red for ten hours (T-3326).
# The live numbers are reported here for information; the LEGS run on fixtures.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90

SCAN=".agentic-framework/agents/audit/completed-task-scan.py"
LIB=".agentic-framework/lib/research_preserved.py"
[ -f "$SCAN" ] || { echo "SETUP BROKEN: no $SCAN"; exit 1; }
[ -f "$LIB" ]  || { echo "SETUP BROKEN: no $LIB"; exit 1; }

PASS=0; FAIL=0
ok() { if [ "$2" -eq 0 ]; then echo "  PASS  $1"; PASS=$((PASS+1)); else echo "  FAIL  $1"; [ -n "${3:-}" ] && echo "        $3"; FAIL=$((FAIL+1)); fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT INT TERM
mkdir -p "$TMP/.tasks/completed" "$TMP/ep" "$TMP/rep"

mk() {  # $1 id  $2 body
    cat > "$TMP/.tasks/completed/$1-fx.md" <<EOF
---
id: $1
workflow_type: inception
status: work-completed
---
$2
EOF
}

flagged() {  # prints the flagged ids
    python3 "$SCAN" "$TMP/.tasks" "$TMP/ep" "$TMP/rep" 2>/dev/null \
      | python3 -c 'import sys,json; print(" ".join(json.load(sys.stdin).get("missing_research",[])))'
}

echo "=== T-919: C-001 measures preservation, not location ==="
echo

# ── THE NEGATIVE LEG FIRST: the check must still bite ─────────────────────────────────────────
# A fix that silences everything is the check retired by accident, which is worse than the false
# positives it was fixing. This leg is the one that proves that did not happen.
echo "NEGATIVE — an inception with no preserved thinking must STILL warn"

mk T-901 '## Problem Statement
<!-- A comment long enough to pass a naive length test on its own, which is exactly why comments are
     stripped before measuring. Padding padding padding padding padding padding padding. -->
[Describe the problem]

## Open Questions
[TODO]

## Acceptance Criteria
- [x] Several hundred characters of OUTCOME prose, deliberately placed in a section that is not
      research-bearing, to prove that conclusions cannot rescue a task which recorded no exploration.
      If Acceptance Criteria or Updates counted toward the threshold, every inception would pass and
      the check would be retired by accident rather than repaired. Padding to clear 400 easily.
## Updates
More outcome prose, hundreds of characters, describing what happened after the thinking rather than
the thinking itself. This must not count. Padding padding padding padding padding padding padding.'
rm -f "$TMP/.tasks/completed/T-902-fx.md" 2>/dev/null
ok "template-only sections + long outcome prose -> WARNS" \
   "$([ "$(flagged)" = "T-901" ] && echo 0 || echo 1)" "flagged: '$(flagged)'"

mk T-901 '## Hypothesis
We believe that child-3: Reverse discovery (AEF record -> editable process map), we will achieve
arc: designer-authoring-surface child-3. We will know we have succeeded when it works.'
ok "a FILLED-IN template hypothesis (~320 chars, T-184's real shape) -> WARNS" \
   "$([ "$(flagged)" = "T-901" ] && echo 0 || echo 1)" "flagged: '$(flagged)'"
echo

# ── THE POSITIVE LEG ─────────────────────────────────────────────────────────────────────────
echo "POSITIVE — an inception whose reasoning IS in its task file goes silent"

mk T-901 '## Hypothesis
The seam drops workflowMeta on re-import because the emitter writes attributes the reader never reads
back, so a round-trip comparison of them is structurally impossible rather than merely missing. If
that holds, no guard over the node-level seam can ever catch it, and the fix is a denominator derived
from the emitter rather than a hand-kept list. Measured on 20 fixtures before writing anything,
because a guard built on the wrong denominator passes for the wrong reason.'
ok "a real 500-char Hypothesis and nothing else -> SILENT (T-879's shape)" \
   "$([ -z "$(flagged)" ] && echo 0 || echo 1)" "flagged: '$(flagged)'"

# SIZED LIKE THE REAL CASE, NOT LIKE THE THRESHOLD. The first version of this fixture scored 395
# against a 400 threshold and failed — not because the predicate was wrong but because the fixture was
# five characters short. The genuine T-250 scores 1936. A fixture parked one typo from the boundary
# tests the boundary, not the behaviour, and flips on an edit that changes nothing.
mk T-901 '## Problem Statement
The register records H1 as open while the operator considers it already answered by an earlier GO, and
nothing reconciles the two readings. Deciding the scope of one narrow slice is not the same act as
reversing a standing DEFER, and treating it as such would let a scope approval silently overturn four
dispositions nobody revisited. The reading matters because every downstream exit clause depends on it.

## Open Questions
Whether roadmap Arcs 4-6 supersede the standing DEFERs (T-279/280/281/282) and AEF T-2669 NO-GO. And
whether correlations already in use count as ratified when nothing records who assigned them — the
agent treated in-use as NOT ratified, which may be the wrong default. Both are operator questions
rather than agent ones, and recording them here is what makes them answerable later.'
ok "Problem Statement + Open Questions -> SILENT (T-250's shape, sized like it)" \
   "$([ -z "$(flagged)" ] && echo 0 || echo 1)" "flagged: '$(flagged)'"
echo

# ── CONTROLS ─────────────────────────────────────────────────────────────────────────────────
echo "CONTROLS"

# The threshold is calibrated at a real boundary, and both sides of it are live cases. If these two
# numbers ever cross, the threshold has stopped discriminating and the legs above prove nothing.
read -r C320 C513 <<<"$(python3 - <<'PY'
import sys
sys.path.insert(0, ".agentic-framework/lib")
# 1.7.740: AEF adopted this predicate as T-3569 under its own names (T-1005).
from research_preserved import research_prose_chars as research_chars
tmpl = ("## Hypothesis\nWe believe that child-3: Reverse discovery (AEF record -> editable process "
        "map), we will achieve arc: designer-authoring-surface child-3. We will know we have "
        "succeeded when the thing works as described above in the hypothesis statement here.\n")
real = ("## Hypothesis\n" + ("The emitter writes attributes the reader never reads back, so a "
        "round-trip comparison is structurally impossible rather than missing. " * 6) + "\n")
print(research_chars(tmpl), research_chars(real))
PY
)"
ok "filled template scores below the threshold ($C320 < 400)" \
   "$([ "$C320" -lt 400 ] && echo 0 || echo 1)"
ok "real prose scores above it ($C513 >= 400)" \
   "$([ "$C513" -ge 400 ] && echo 0 || echo 1)"

# ONE ENCODING: both scanners must import the predicate, never restate it. A second copy is how the
# delegation boundary ended up encoded twice and disagreeing (G-052, measured 2026-09-29).
ok "completed scan IMPORTS the predicate" \
   "$(grep -qE 'from research_preserved import research_preserved(_in_task)?' "$SCAN" && echo 0 || echo 1)"
ok "active scan IMPORTS the predicate" \
   "$(grep -qE 'from research_preserved import research_preserved(_in_task)?' .agentic-framework/agents/audit/active-task-scan.py && echo 0 || echo 1)"
ok "neither scanner carries its own RESEARCH_SECTIONS list" \
   "$(! grep -qE '^RESEARCH_SECTIONS' "$SCAN" .agentic-framework/agents/audit/active-task-scan.py && echo 0 || echo 1)" \
   "a second copy of the section vocabulary is the start of the drift"

# The in-task record must not then trip the "has artifact but doesn't reference it" branch: a task
# cannot fail to reference itself. This fired on T-280 in the first version of the fix.
ok "in-task record skips the unreferenced branch (a task cannot fail to cite itself)" \
   "$(grep -qE 'elif not in_task_record:|and not in_task_record' .agentic-framework/agents/audit/active-task-scan.py && echo 0 || echo 1)"
echo

echo "For information, not asserted (the live corpus moves):"
python3 "$SCAN" .tasks .context/episodic docs/reports 2>/dev/null | python3 -c '
import sys, json
d = json.load(sys.stdin)
print("  completed inceptions examined: %s" % d.get("stats", {}).get("inception_count"))
print("  still flagged: %s" % (d.get("missing_research") or "none"))'
echo

echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
