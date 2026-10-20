#!/usr/bin/env bash
# _t1161-install-hook.sh — wire the boundary-inventory gate into .git/hooks/pre-commit (832 T-1161).
#
# Same seam as tools/_t1000-install-hook.sh: the framework writes .git/hooks/pre-commit (`fw git install-hooks`)
# and offers no project extension point, so 832 adds one marked line. A hook reinstall erases it; `--check` exits 1
# then, and the bridge suite runs `--check` for this line and the T-1000 one.
#
#   bash tools/_t1161-install-hook.sh           install (idempotent)
#   bash tools/_t1161-install-hook.sh --check   exit 0 if installed, 1 if not
set -u
ROOT=$(git rev-parse --show-toplevel) || exit 2
HOOK="$ROOT/.git/hooks/pre-commit"
MARK="# 832-T-1161-boundary-gate"
LINE="bash \"\$(git rev-parse --show-toplevel)/tools/_t1161-boundary-gate.sh\" || exit 1  $MARK"
# T-1240: a gate counts as installed only when an ACTIVE line carries it. AEF T-4403 (be.3) keeps foreign hook lines
# on reinstall but COMMENTS THEM OUT; the marker text survives in the comment, so a plain grep read a dead gate as
# installed (job 059: both 832 gates stopped and every check stayed green).
active() { grep -E '^[[:space:]]*bash ' "$1" 2>/dev/null | grep -qF "$MARK"; }
drop_commented() { python3 - "$1" "$MARK" <<'PY'
import sys
p, mark = sys.argv[1:3]
lines = open(p, encoding="utf-8").read().split("\n")
open(p, "w", encoding="utf-8").write("\n".join(l for l in lines if not (mark in l and l.lstrip().startswith("#"))))
PY
}
if [ "${1:-}" = "--check" ]; then
    active "$HOOK" && { echo "boundary gate: installed in $HOOK"; exit 0; }
    echo "boundary gate: NOT installed in $HOOK (a hook reinstall removes it; run tools/_t1161-install-hook.sh)"
    exit 1
fi
[ -f "$HOOK" ] || { echo "no $HOOK — run the framework's hook install first"; exit 2; }
active "$HOOK" && { echo "boundary gate: already installed"; exit 0; }
drop_commented "$HOOK"
# Second line, right after the shebang and the T-1000 line if present, so it runs before the framework's own checks.
python3 - "$HOOK" "$LINE" <<'PY'
import sys
p, line = sys.argv[1:3]
lines = open(p, encoding="utf-8").read().split("\n")
at = 1
if len(lines) > 1 and "832-T-1000-revendor-gate" in lines[1]:
    at = 2
lines.insert(at, line)
open(p, "w", encoding="utf-8").write("\n".join(lines))
PY
active "$HOOK" && echo "boundary gate: installed in $HOOK"
