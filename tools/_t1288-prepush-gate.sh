#!/usr/bin/env bash
# _t1288-prepush-gate.sh — run the bridge suite's core tier before a push; red blocks it (832 T-1288).
#
# Run from .git/hooks/pre-push (one marked line, tools/_t1288-install-hook.sh). The core tier is hermetic and must be
# green (tests/run-bridge-tests.sh --tier core): a red core is a regression, or a leg that belongs in
# tests/quarantine.yaml with an owner, never something to push past silently.
#
# Bypass, logged: T1288_PREPUSH_BYPASS="<reason>" git push ...   One line per bypass is appended to
# tests/.prepush-bypass.tsv (date, HEAD, user, reason); an empty reason is refused.
set -u
ROOT=$(git rev-parse --show-toplevel) || exit 2
LOG="$ROOT/tests/.prepush-bypass.tsv"

if [ -n "${T1288_PREPUSH_BYPASS+x}" ]; then
    reason=$(printf '%s' "$T1288_PREPUSH_BYPASS" | tr '\t\n' '  ')
    if [ -z "${reason// /}" ]; then
        echo "T-1288 pre-push: T1288_PREPUSH_BYPASS is set but empty — a bypass needs its reason. Push refused." >&2
        exit 1
    fi
    printf '%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(git rev-parse --short HEAD 2>/dev/null)" \
        "$(id -un 2>/dev/null || echo "?")" "$reason" >> "$LOG"
    echo "T-1288 pre-push: core tier BYPASSED ($reason) — logged to tests/.prepush-bypass.tsv" >&2
    exit 0
fi

# The hook runs with git's own variables set (GIT_DIR and friends); the legs build throwaway repositories of their
# own, which those variables would silently redirect to this one.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES

echo "T-1288 pre-push: running the core tier (tests/run-bridge-tests.sh --tier core) ..." >&2
out="$ROOT/.context/working/prepush-core.log"
mkdir -p "$(dirname "$out")"
( cd "$ROOT" && bash tests/run-bridge-tests.sh --tier core ) </dev/null > "$out" 2>&1
rc=$?
grep -E '^tier core ' "$out" >&2
if [ "$rc" -ne 0 ]; then
    echo "T-1288 pre-push: core tier is RED (rc=$rc) — push refused. Full output: .context/working/prepush-core.log" >&2
    grep -E '^\s*\[(FAIL|QUARANTINED)\]' "$out" | head -20 >&2
    echo "  A known non-product red belongs in tests/quarantine.yaml (leg, reason, owner, fix_by)." >&2
    echo "  To push anyway, logged: T1288_PREPUSH_BYPASS=\"<reason>\" git push ..." >&2
    exit 1
fi
exit 0
