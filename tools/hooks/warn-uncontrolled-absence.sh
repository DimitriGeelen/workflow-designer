#!/usr/bin/env bash
# T-843 Route 3 — WRITE-TIME advisory for uncontrolled absence assertions.
#
# WHY THIS EXISTS ALONGSIDE THE CLOSE GATE. The close gate (T-843, update-task.sh) refuses a
# work-completed whose ## Verification asserts an absence with no control. That is the
# enforcement point and it is sufficient on its own. This hook is the EARLY one: it warns the
# moment such a leg is written, while the author still has the context to fix it in seconds,
# instead of at close when they believe the work is done. Catching it late is what makes a
# gate feel hostile; catching it early is what makes the gate mostly never fire.
#
# ADVISORY, NEVER BLOCKING. PostToolUse, exit 0 always. A write-time BLOCK would be wrong
# here: an author legitimately writes the absence assertion first and its control second, and
# a hook that refuses the intermediate state would make the correct workflow impossible. The
# close gate is where refusal belongs, because by then the block is finished.
#
# INSTALLATION IS THE OPERATOR'S. The agent is structurally blocked from writing
# .claude/settings.json (B-005) and there is no settings.local.json side door. The exact
# registration is in docs/reports/T-843-route-3-hook-handover.md.

set -uo pipefail
ROOT="${CLAUDE_PROJECT_DIR:-${PROJECT_ROOT:-/opt/832-Workflow-designer}}"
CENSUS="$ROOT/tools/_t560-absence-assertion-census.py"

# The hook receives the tool payload as JSON on stdin. Pull the written path out of it
# without requiring jq: fall back to a grep if python is somehow unavailable.
payload="$(cat 2>/dev/null || true)"
target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input") or {}
print(ti.get("file_path") or ti.get("path") or "")
' 2>/dev/null || true)"

# Only task files carry a ## Verification block that the close gate will read.
case "$target" in
    *"/.tasks/active/"*.md|*"/.tasks/completed/"*.md) ;;
    *) exit 0 ;;
esac
[ -f "$target" ] || exit 0
[ -f "$CENSUS" ] || exit 0     # NOT EVALUATED: no classifier, say nothing rather than guess

block="$(sed -n '/^## Verification/,/^## [A-Z]/p' "$target" 2>/dev/null || true)"
[ -n "$block" ] || exit 0

offenders="$(printf '%s\n' "$block" | python3 "$CENSUS" --block --uncontrolled 2>/dev/null || true)"
[ -n "$offenders" ] || exit 0

{
  echo "── uncontrolled absence assertion(s) just written to $(basename "$target") ──"
  printf '%s\n' "$offenders" | while IFS= read -r l; do [ -n "$l" ] && echo "    $l"; done
  echo "  Nothing establishes that these searches could have succeeded, so deleting or"
  echo "  renaming the target makes them pass vacuously. The close gate will refuse this"
  echo "  task at work-completed — fixing it now costs one line:"
  echo "    add a sibling leg grepping the SAME STRING somewhere it IS present,"
  echo "    or assert the positive fact and drop the negation."
  echo "  (Advisory only. If the control is your next edit, ignore this.)"
} >&2
exit 0
