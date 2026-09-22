#!/usr/bin/env bash
# _t833-ctl029-partial-complete-controls.sh — does CTL-029 still catch what it should?
#
# T-833. CTL-029 fired on `unticked == 0 and ticked > 0` over the ### Agent section alone,
# reading neither `owner:` nor ### Human. It could not tell an ABANDONED task from one that
# had correctly PARTIAL-COMPLETED to the operator — the state CLAUDE.md prescribes verbatim.
# Every such task produced a standing warning, and those warnings were filed as remediation
# tasks whose only possible fix was for the operator to close something already in its
# correct terminal-pending state. A control that manufactures undoable work is worse than
# one that stays silent.
#
# NARROWING A CONTROL IS DANGEROUS, which is why this exists. The suppression must catch
# exactly one shape and leave every other firing intact:
#
#   SUPPRESSED   owner: human  AND >=1 unticked criterion under ### Human   (partial-complete)
#   STILL FIRES  owner: agent, all Agent ACs ticked                         (abandoned)
#   STILL FIRES  owner: human, Human ACs ALL ticked                         (genuinely unclosed)
#   STILL FIRES  owner: human, no ### Human section at all                  (mis-filed, not partial)
#
# The last two are the ones a careless fix would swallow, and they are the ones that matter:
# a task whose human side is DONE and still sits in active/ is exactly what CTL-029 is for.
#
# Exit: 0 all four branches behave | 1 a branch failed | 3 setup

set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT="$REPO/.agentic-framework/agents/audit/audit.sh"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad(){ FAIL=$((FAIL+1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }
[ -f "$AUDIT" ] || cannot "audit.sh not found"

# Extract the embedded python predicate and drive it against a synthetic .tasks/active.
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
python3 - "$AUDIT" "$WORK/pred.py" <<'PY' || cannot "could not extract the CTL-029 predicate — audit.sh moved; this control is measuring nothing"
import io, re, sys
s = io.open(sys.argv[1], encoding='utf-8').read()
m = re.search(r"# CTL-029: completable-but-not-completed detection.*?<<'PYEOF'[^\n]*\n(.*?)\nPYEOF", s, re.DOTALL)
if not m:
    sys.stderr.write("predicate block not found\n"); sys.exit(1)
io.open(sys.argv[2], 'w', encoding='utf-8').write(m.group(1))
PY

mk(){ # mk <id> <owner> <agent-acs> <human-block>
    mkdir -p "$WORK/active"
    { printf -- '---\nid: %s\nstatus: started-work\nowner: %s\n---\n\n## Acceptance Criteria\n\n### Agent\n%s\n' "$1" "$2" "$3"
      [ -n "$4" ] && printf -- '\n### Human\n%s\n' "$4"
      printf -- '\n## Verification\n'; } > "$WORK/active/$1.md"
}
run(){ python3 "$WORK/pred.py" "$WORK/active" 2>/dev/null; }

echo "=== T-833 CTL-029 controls ==="
rm -rf "$WORK/active"; mk T-001 agent "- [x] done" ""
if run | grep -q "^T-001|"; then ok "abandoned agent-owned task -> STILL FIRES"
else bad "abandoned task suppressed" "the narrowing swallowed the case CTL-029 exists for"; fi

rm -rf "$WORK/active"; mk T-002 human "- [x] done" "- [ ] [REVIEW] rule on it"
if run | grep -q "^T-002|"; then bad "partial-complete still fires" "the fix did not take; the undoable-work warnings continue"
else ok "partial-complete (human + unticked Human AC) -> SUPPRESSED"; fi

rm -rf "$WORK/active"; mk T-003 human "- [x] done" "- [x] [REVIEW] already ruled"
if run | grep -q "^T-003|"; then ok "human-owned with Human ACs ALL ticked -> STILL FIRES (genuinely unclosed)"
else bad "genuinely completable suppressed" "a task whose human side is DONE now hides in active/ forever — the exact defect CTL-029 catches"; fi

rm -rf "$WORK/active"; mk T-004 human "- [x] done" ""
if run | grep -q "^T-004|"; then ok "human-owned with NO ### Human section -> STILL FIRES (mis-filed, not partial)"
else bad "mis-filed task suppressed" "owner: human with no Human AC is the T-767 defect, not partial-complete"; fi

echo; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
