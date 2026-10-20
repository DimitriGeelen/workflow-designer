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
if [ "${1:-}" = "--check" ]; then
    grep -qF "$MARK" "$HOOK" 2>/dev/null && { echo "LAN-address gate: installed in $HOOK"; exit 0; }
    echo "LAN-address gate: NOT installed in $HOOK (a hook reinstall removes it; run tools/_t1239-install-hook.sh)"
    exit 1
fi
[ -f "$HOOK" ] || { echo "no $HOOK — run the framework's hook install first"; exit 2; }
grep -qF "$MARK" "$HOOK" && { echo "LAN-address gate: already installed"; exit 0; }
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
grep -qF "$MARK" "$HOOK" && echo "LAN-address gate: installed in $HOOK"
