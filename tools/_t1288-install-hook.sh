#!/usr/bin/env bash
# _t1288-install-hook.sh — wire the core-tier gate into .git/hooks/pre-push (832 T-1288).
#
# Same seam as tools/_t1000-install-hook.sh, _t1161 and _t1239, in the other hook: the framework writes
# .git/hooks/pre-push (`fw git install-hooks`) and offers no project extension point, so 832 adds one marked line
# right after the shebang. A hook reinstall erases it (or, since AEF T-4403, comments it out), so the T-1000 installer
# that every upgrade job runs calls this one too, and `--check` exits 1 when the line is not active.
#
#   bash tools/_t1288-install-hook.sh           install (idempotent)
#   bash tools/_t1288-install-hook.sh --check   exit 0 if installed, 1 if not
#
# T1288_HOOK overrides the hook path (the tests use a throwaway hook).
set -u
ROOT=$(git rev-parse --show-toplevel) || exit 2
HOOK="${T1288_HOOK:-$ROOT/.git/hooks/pre-push}"
MARK="# 832-T-1288-core-tier-gate"
# </dev/null: the framework's hook body reads git's ref list from stdin after this line; the gate must not eat it.
LINE="bash \"\$(git rev-parse --show-toplevel)/tools/_t1288-prepush-gate.sh\" </dev/null || exit 1  $MARK"
# T-1240: a gate counts as installed only when an ACTIVE line carries it, not a commented-out one.
active() { grep -E '^[[:space:]]*bash ' "$1" 2>/dev/null | grep -qF "$MARK"; }
drop_commented() { python3 - "$1" "$MARK" <<'PY'
import sys
p, mark = sys.argv[1:3]
lines = open(p, encoding="utf-8").read().split("\n")
open(p, "w", encoding="utf-8").write("\n".join(l for l in lines if not (mark in l and l.lstrip().startswith("#"))))
PY
}
if [ "${1:-}" = "--check" ]; then
    active "$HOOK" && { echo "core-tier pre-push gate: installed in $HOOK"; exit 0; }
    echo "core-tier pre-push gate: NOT installed in $HOOK (a hook reinstall removes it; run tools/_t1288-install-hook.sh)"
    exit 1
fi
[ -f "$HOOK" ] || { echo "no $HOOK — run the framework's hook install first"; exit 2; }
active "$HOOK" && { echo "core-tier pre-push gate: already installed"; exit 0; }
drop_commented "$HOOK"
# Right after the shebang and any other 832 lines, before the framework's managed block.
python3 - "$HOOK" "$LINE" <<'PY'
import sys
p, line = sys.argv[1:3]
lines = open(p, encoding="utf-8").read().split("\n")
at = 1
while at < len(lines) and "# 832-T-" in lines[at]:
    at += 1
lines.insert(at, line)
open(p, "w", encoding="utf-8").write("\n".join(lines))
PY
active "$HOOK" && echo "core-tier pre-push gate: installed in $HOOK"
