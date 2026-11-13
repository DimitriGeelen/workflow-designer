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

# T-1299: one core run at a time. Three gates once ran side by side (a handover's push and two by hand), tripling the load,
# and their overlap removed each other's temp dirs and rehearsal clones (T-1298). A second gate waits for the first, then
# finds the first one's green key below and needs no run of its own. The suite gets the lock's fd closed (8<&-).
mkdir -p "$ROOT/.context/working"
exec 8>"$ROOT/.context/working/prepush-core.lock"
if ! flock -n 8; then
    echo "T-1288 pre-push: another core-tier run holds the lock — waiting for it (up to 60 min) ..." >&2
    flock -w "${T1299_LOCK_WAIT:-3600}" 8 || { echo "T-1288 pre-push: the other core run still holds the lock — push refused" >&2; exit 1; }
fi

# A green core run is remembered by the tree of what it tests: src, tools, tests, the authoring kit and the vendored
# framework at HEAD. A push whose HEAD has the same key (a handover, a task-file commit) needs no new run; any change
# to those trees runs the core tier again. Only a GREEN run records a key. Remove the file to force a run.
GREEN="$ROOT/.context/working/prepush-core.green"
# T-1295: the suite's own bookkeeping (run history, bypass log) changes with every run, so it is not part of the key;
# otherwise committing a run's history line would invalidate the run it records.
key=$(cd "$ROOT" && git ls-tree -r HEAD -- src tools tests docs/authoring-kit .agentic-framework \
      | grep -vE $'\t''tests/\.(run-history|prepush-bypass)\.tsv$' | sha256sum | cut -c1-64)
if [ -s "$GREEN" ] && [ "$(cat "$GREEN")" = "$key" ]; then
    echo "T-1288 pre-push: core tier already GREEN for this tree (src/tools/tests/kit/framework unchanged) — no run needed" >&2
    exit 0
fi

# --- T-1408: WHERE the core tier runs (operator's rulings 2026-11-12/13; T-1397 GO; T-1406 proved pool = local) ------
# A normal push runs core on ring20's pool (tools/pool/submit.sh, from git only, quiet VMs). A push that changes a
# HIGH-RISK path needs two independent runs on two different machines: the pool AND this machine, both green; if they
# disagree the push is refused. No pool result (unreachable, refused, timed out) falls back to the local run, said and
# logged; T1408_POOL=0 forces local. Releases are not touched here: the release job keeps its own local runs.
HIGH_RISK_RE='^(src/aef-workflow-designer\.html|tools/validate-workflow\.py|\.agentic-framework/|tests/run-bridge-tests\.sh|tools/_t1288-|tools/pool/)'
RUNS="$ROOT/.context/working/prepush-core.runs.log"   # git-ignored by the committed root rule .context/working/prepush-core.*
HEAD_SHA=$(cd "$ROOT" && git rev-parse HEAD)
note() { printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${HEAD_SHA:0:12}" "$*" >> "$RUNS"; echo "T-1288 pre-push: $*" >&2; }

local_core() {  # the core tier here; 0 green, 1 red (T-1405 keeps a red run's log)
    echo "T-1288 pre-push: running the core tier HERE (tests/run-bridge-tests.sh --tier core) ..." >&2
    local out="$ROOT/.context/working/prepush-core.log" rc red
    mkdir -p "$(dirname "$out")"
    ( cd "$ROOT" && bash tests/run-bridge-tests.sh --tier core ) </dev/null > "$out" 2>&1 8<&-
    rc=$?
    grep -E '^tier core ' "$out" >&2
    if [ "$rc" -ne 0 ]; then
        # T-1405: keep each red run's log under its own name (newest five); prepush-core.log is overwritten by the next run.
        red="$ROOT/.context/working/prepush-core.red-$(date -u +%Y%m%dT%H%M%SZ).log"
        cp "$out" "$red" 2>/dev/null || red=""
        ls -1t "$ROOT"/.context/working/prepush-core.red-*.log 2>/dev/null | tail -n +6 | while read -r old; do rm -f -- "$old"; done
        echo "T-1288 pre-push: LOCAL core tier is RED (rc=$rc). Full output: .context/working/prepush-core.log${red:+ (kept as ${red#"$ROOT"/})}" >&2
        grep -E '^\s*\[(FAIL|QUARANTINED)\]' "$out" | head -20 >&2
        return 1
    fi
    return 0
}

pool_core() {  # the core tier on ring20's pool; 0 green, 1 red, 3 no result for THIS commit (unavailable)
    echo "T-1288 pre-push: running the core tier on ring20's POOL (tools/pool/submit.sh core) ..." >&2
    local last="$ROOT/build/pool/last-core.result" commit code line node log
    ( cd "$ROOT" && ${T1408_POOL_SUBMIT:-bash tools/pool/submit.sh core} ) </dev/null > "$ROOT/.context/working/prepush-core.pool.out" 2>&1 8<&-
    [ -f "$last" ] || { echo "T-1288 pre-push: the pool gave no result (see .context/working/prepush-core.pool.out)" >&2; return 3; }
    commit=$(sed -n 's/^commit=//p' "$last"); code=$(sed -n 's/^exit_code=//p' "$last")
    line=$(sed -n 's/^result_line=//p' "$last"); node=$(sed -n 's/^node=//p' "$last"); log=$(sed -n 's/^tier_log=//p' "$last")
    [ "$commit" = "$HEAD_SHA" ] || { echo "T-1288 pre-push: the pool's result is for ${commit:0:12}, not HEAD ${HEAD_SHA:0:12} — not counted" >&2; return 3; }
    echo "$line   [pool: $node]" >&2
    if [ "$code" = 0 ]; then return 0; fi
    echo "T-1288 pre-push: POOL core tier is RED (exit $code). Full output: ${log#"$ROOT"/}" >&2
    [ -f "$log" ] && grep -E '^\s*\[(FAIL|QUARANTINED)\]' "$log" | head -20 >&2
    return 1
}

refuse() {
    echo "T-1288 pre-push: push refused — $1" >&2
    echo "  A known non-product red belongs in tests/quarantine.yaml (leg, reason, owner, fix_by)." >&2
    echo "  To push anyway, logged: T1288_PREPUSH_BYPASS=\"<reason>\" git push ..." >&2
    exit 1
}

# High-risk = the push changes a listed path. Compared with the upstream; with no upstream, everything is new (high-risk).
upstream=$(cd "$ROOT" && git rev-parse -q --verify '@{u}' 2>/dev/null) || upstream=""
if [ -n "$upstream" ]; then changed=$(cd "$ROOT" && git diff --name-only "$upstream" HEAD); else changed=$(cd "$ROOT" && git ls-tree -r --name-only HEAD); fi
risky=$(printf '%s\n' "$changed" | grep -E "$HIGH_RISK_RE" | head -3 | tr '\n' ' ')

if [ "${T1408_POOL:-1}" = 0 ]; then
    note "T1408_POOL=0: core runs locally only (pool skipped on request)"
    local_core || refuse "local core is red"
elif [ -n "$risky" ]; then
    note "high-risk push (${risky% }): core runs on the pool AND here, side by side; both must be green"
    prcf="$ROOT/.context/working/prepush-core.pool.rc"; rm -f "$prcf"
    ( pool_core; echo $? > "$prcf" ) &
    ppid_=$!
    local_core; lrc=$?
    wait "$ppid_"; prc=$(cat "$prcf" 2>/dev/null || echo 3)
    if [ "$prc" = 3 ]; then
        note "high-risk push: the pool gave no result; local alone ($([ $lrc = 0 ] && echo green || echo red)) — ONE run, not the two the rule asks for"
        [ "$lrc" = 0 ] || refuse "local core is red (and the pool gave no result)"
    elif [ "$prc" != "$lrc" ]; then
        refuse "the pool ($([ $prc = 0 ] && echo green || echo red)) and this machine ($([ $lrc = 0 ] && echo green || echo red)) DISAGREE on a high-risk change: find out why before pushing"
    elif [ "$prc" != 0 ]; then
        refuse "core is red on the pool and here"
    else
        note "high-risk push: pool and local both green"
    fi
else
    note "normal push: core runs on the pool"
    pool_core; prc=$?
    if [ "$prc" = 3 ]; then
        note "the pool gave no result: falling back to the local run"
        local_core || refuse "local core is red (pool unavailable)"
    elif [ "$prc" != 0 ]; then
        refuse "pool core is red"
    else
        note "normal push: pool green"
    fi
fi
printf '%s\n' "$key" > "$GREEN"
exit 0
