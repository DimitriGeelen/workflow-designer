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

if [ "${1:-}" = "--check" ]; then
    grep -qF "$MARK" "$HOOK" 2>/dev/null && { echo "revendor gate: installed in $HOOK"; exit 0; }
    echo "revendor gate: NOT installed in $HOOK (a hook reinstall removes it; run tools/_t1000-install-hook.sh)"
    exit 1
fi
[ -f "$HOOK" ] || { echo "no $HOOK: run fw git install-hooks first" >&2; exit 2; }
if grep -qF "$MARK" "$HOOK"; then echo "already installed"; exit 0; fi
# Directly after the shebang, so no early `exit 0` in the framework hook can skip it.
tmp=$(mktemp) && { head -1 "$HOOK"; echo "$LINE"; tail -n +2 "$HOOK"; } > "$tmp" && cat "$tmp" > "$HOOK" && rm -f "$tmp"
grep -qF "$MARK" "$HOOK" && echo "installed: $HOOK line 2" || { echo "install failed" >&2; exit 1; }
