#!/usr/bin/env bash
# _t1239-install-hook.sh — wire the LAN-address gate into .git/hooks/pre-commit (832 T-1239).
#
# Same seam as tools/_t1000-install-hook.sh and _t1161-install-hook.sh: one marked line in the framework-written hook;
# a hook reinstall erases it, so the T-1000 installer (run by every upgrade job) calls this one too.
#
#   bash tools/_t1239-install-hook.sh           install (idempotent)
#   bash tools/_t1239-install-hook.sh --check   exit 0 if installed, 1 if not
set -u
ROOT=$(git rev-parse --show-toplevel) || exit 2
HOOK="$ROOT/.git/hooks/pre-commit"
MARK="# 832-T-1239-lan-address-gate"
LINE="bash \"\$(git rev-parse --show-toplevel)/tools/_t1239-lan-address-gate.sh\" || exit 1  $MARK"
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
    active "$HOOK" && { echo "LAN-address gate: installed in $HOOK"; exit 0; }
    echo "LAN-address gate: NOT installed in $HOOK (a hook reinstall removes it; run tools/_t1239-install-hook.sh)"
    exit 1
fi
[ -f "$HOOK" ] || { echo "no $HOOK — run the framework's hook install first"; exit 2; }
active "$HOOK" && { echo "LAN-address gate: already installed"; exit 0; }
drop_commented "$HOOK"
# Right after the shebang and the other 832 lines, so it runs before the framework's own checks.
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
active "$HOOK" && echo "LAN-address gate: installed in $HOOK"
