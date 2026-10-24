#!/usr/bin/env bash
# _t1000-install-hook.sh — wire the re-vendor gate into .git/hooks/pre-commit (832 T-1000).
#
# The framework writes .git/hooks/pre-commit (`fw git install-hooks`) and offers NO project
# extension point, so the only seam is one marked line in that file. A hook reinstall erases
# it; that is the same class of loss T-995 is about, so it is not left silent: `--check`
# exits 1 when the line is missing, and T-999's project audit calls it. Asked upstream (AEF,
# conversation revendor-protocol): a project hooks directory the framework hook sources.
#
#   bash tools/_t1000-install-hook.sh           install (idempotent)
#   bash tools/_t1000-install-hook.sh --check   exit 0 if installed, 1 if not
set -u
ROOT=$(git rev-parse --show-toplevel) || exit 2
HOOK="$ROOT/.git/hooks/pre-commit"
MARK="# 832-T-1000-revendor-gate"
LINE="bash \"\$(git rev-parse --show-toplevel)/tools/_t1000-revendor-gate.sh\" || exit 1  $MARK"
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

# T-1208: the boundary-inventory gate (T-1161) lives in the same hook and is erased by the same reinstall; it
# was lost after both the v1.8.11 and the v1.8.12 upgrade. Every upgrade job already runs this installer right
# after `fw upgrade`, so it installs (and checks) that gate too; one call covers every 832 line in the hook.
T1161="$ROOT/tools/_t1161-install-hook.sh"
T1239="$ROOT/tools/_t1239-install-hook.sh"   # T-1239: the LAN-address gate, same hook, same reinstall
# T-1288: the core-tier gate in .git/hooks/pre-push, erased by the same reinstall. Installed here so every upgrade
# job re-installs it; its --check joins the one below once the operator has installed it the first time.
T1288="$ROOT/tools/_t1288-install-hook.sh"

if [ "${1:-}" = "--check" ]; then
    rc=0
    if active "$HOOK"; then echo "revendor gate: installed in $HOOK"
    else echo "revendor gate: NOT installed in $HOOK (a hook reinstall removes it; run tools/_t1000-install-hook.sh)"; rc=1; fi
    [ -f "$T1161" ] && { bash "$T1161" --check || rc=1; }
    [ -f "$T1239" ] && { bash "$T1239" --check || rc=1; }
    exit $rc
fi
[ -f "$T1161" ] && bash "$T1161" >/dev/null
[ -f "$T1239" ] && bash "$T1239" >/dev/null
[ -f "$T1288" ] && bash "$T1288" >/dev/null
[ -f "$HOOK" ] || { echo "no $HOOK: run fw git install-hooks first" >&2; exit 2; }
if active "$HOOK"; then echo "already installed"; exit 0; fi
drop_commented "$HOOK"
# Directly after the shebang, so no early `exit 0` in the framework hook can skip it.
tmp=$(mktemp) && { head -1 "$HOOK"; echo "$LINE"; tail -n +2 "$HOOK"; } > "$tmp" && cat "$tmp" > "$HOOK" && rm -f "$tmp"
active "$HOOK" && echo "installed: $HOOK line 2" || { echo "install failed" >&2; exit 1; }
