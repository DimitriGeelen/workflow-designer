#!/usr/bin/env bash
# tier-gate.sh — T-1409 (logic from T-1408): run one of 832's test tiers WHERE the operator's rules say, for HEAD.
#
#   bash tools/pool/tier-gate.sh core|browser        exit 0 only when every required run is green
#
# Rules (operator 2026-11-12/13; T-1397 GO; T-1406 proved pool = local on both tiers):
#   - a change that touches no high-risk path: ring20's pool alone (tools/pool/submit.sh, from git only);
#   - a change that touches a HIGH-RISK path (tools/pool/high-risk.re, the one list): two independent runs on two
#     different machines, the pool AND this machine, side by side; both green, and a disagreement refuses;
#   - no pool result for HEAD (unreachable, refused, timed out, another commit): this machine decides, said and logged;
#   - T1408_POOL=0: this machine only (logged).
# "The change" = HEAD against its upstream (no upstream: every path, so high-risk). Releases do not use this.
# Logs: core keeps the push gate's names (.context/working/prepush-core.*, git-ignored by a committed root rule; T-1405
# keeps a red local run's log); browser writes under build/tiergate/ (build/ is git-ignored).
# Exit: 0 green, 1 red or refused, 2 usage.
set -u
TIER="${1:-}"
case "$TIER" in core|browser) ;; *) echo "usage: tier-gate.sh core|browser" >&2; exit 2 ;; esac
ROOT=$(git rev-parse --show-toplevel) || exit 2
HEAD_SHA=$(cd "$ROOT" && git rev-parse HEAD)
if [ "$TIER" = core ]; then WD="$ROOT/.context/working"; PFX="prepush-core"; else WD="$ROOT/build/tiergate"; PFX="tier-browser"; fi
mkdir -p "$WD"
RUNS="$WD/$PFX.runs.log"
# One list (T-1409): fail closed if it is missing (everything is high-risk, so both runs).
HIGH_RISK_RE=$(head -1 "$ROOT/tools/pool/high-risk.re" 2>/dev/null)
[ -n "$HIGH_RISK_RE" ] || HIGH_RISK_RE='.'
note() { printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${HEAD_SHA:0:12}" "$*" >> "$RUNS"; echo "T-1288 $TIER: $*" >&2; }

node_ok() { "${1:-node}" -e 'process.exit(typeof WebSocket === "function" ? 0 : 1)' 2>/dev/null; }
pick_node() {  # T-1409: the CDP harnesses need a global WebSocket (Node >= 22). System Node 18 has none, and the browser
    # tier then reads 126 CANNOT RUN as red, a "disagreement" with the pool that is this machine's PATH, not the product.
    # Use PATH's node if it has WebSocket, else the newest nvm Node that does; none -> return 1 (no verdict here).
    local n d
    node_ok node && return 0
    for d in $(ls -1d "$HOME"/.nvm/versions/node/v*/bin 2>/dev/null | sort -V -r); do
        n="$d/node"
        if [ -x "$n" ] && node_ok "$n"; then PATH="$d:$PATH"; export PATH; echo "T-1288 $TIER: using $("$n" -v) from $d (PATH's node has no WebSocket)" >&2; return 0; fi
    done
    return 1
}

local_run() {  # the tier here; 0 green, 1 red (a red run's log is kept, newest five)
    if ! pick_node && [ "$TIER" = browser ]; then   # core does not need it, so core runs on regardless
        echo "T-1288 $TIER: CANNOT RUN here — no Node with a global WebSocket (>= 22) on PATH or under ~/.nvm; the CDP legs would all fail without measuring" >&2
        return 4
    fi
    echo "T-1288 $TIER: running the $TIER tier HERE (tests/run-bridge-tests.sh --tier $TIER) ..." >&2
    local out="$WD/$PFX.log" rc red
    ( cd "$ROOT" && bash tests/run-bridge-tests.sh --tier "$TIER" ) </dev/null > "$out" 2>&1 8<&-
    rc=$?
    grep -E "^tier $TIER " "$out" >&2
    if [ "$rc" -ne 0 ]; then
        # T-1405: keep each red run's log under its own name (newest five); $PFX.log is overwritten by the next run.
        red="$WD/$PFX.red-$(date -u +%Y%m%dT%H%M%SZ).log"
        cp "$out" "$red" 2>/dev/null || red=""
        ls -1t "$WD/$PFX".red-*.log 2>/dev/null | tail -n +6 | while read -r old; do rm -f -- "$old"; done
        echo "T-1288 $TIER: LOCAL $TIER tier is RED (rc=$rc). Full output: ${out#"$ROOT"/}${red:+ (kept as ${red#"$ROOT"/})}" >&2
        grep -E '^\s*\[(FAIL|QUARANTINED)\]' "$out" | head -20 >&2
        return 1
    fi
    return 0
}

pool_run() {  # the tier on ring20's pool; 0 green, 1 red, 3 no result for THIS commit (unavailable)
    echo "T-1288 $TIER: running the $TIER tier on ring20's POOL (tools/pool/submit.sh $TIER) ..." >&2
    local last="$ROOT/build/pool/last-$TIER.result" commit code line node log
    ( cd "$ROOT" && ${T1408_POOL_SUBMIT:-bash tools/pool/submit.sh} "$TIER" ) </dev/null > "$WD/$PFX.pool.out" 2>&1 8<&-
    [ -f "$last" ] || { echo "T-1288 $TIER: the pool gave no result (see ${WD#"$ROOT"/}/$PFX.pool.out)" >&2; return 3; }
    commit=$(sed -n 's/^commit=//p' "$last"); code=$(sed -n 's/^exit_code=//p' "$last")
    line=$(sed -n 's/^result_line=//p' "$last"); node=$(sed -n 's/^node=//p' "$last"); log=$(sed -n 's/^tier_log=//p' "$last")
    [ "$commit" = "$HEAD_SHA" ] || { echo "T-1288 $TIER: the pool's result is for ${commit:0:12}, not HEAD ${HEAD_SHA:0:12} — not counted" >&2; return 3; }
    echo "$line   [pool: $node]" >&2
    if [ "$code" = 0 ]; then return 0; fi
    echo "T-1288 $TIER: POOL $TIER tier is RED (exit $code). Full output: ${log#"$ROOT"/}" >&2
    [ -f "$log" ] && grep -E '^\s*\[(FAIL|QUARANTINED)\]' "$log" | head -20 >&2
    return 1
}

refuse() { echo "T-1288 $TIER: REFUSED — $1" >&2; exit 1; }
gr() { [ "$1" = 0 ] && echo green || echo red; }

upstream=$(cd "$ROOT" && git rev-parse -q --verify '@{u}' 2>/dev/null) || upstream=""
if [ -n "$upstream" ]; then changed=$(cd "$ROOT" && git diff --name-only "$upstream" HEAD); else changed=$(cd "$ROOT" && git ls-tree -r --name-only HEAD); fi
risky=$(printf '%s\n' "$changed" | grep -E "$HIGH_RISK_RE" | head -3 | tr '\n' ' ')

if [ "${T1408_POOL:-1}" = 0 ]; then
    note "T1408_POOL=0: $TIER runs locally only (pool skipped on request)"
    local_run || refuse "local $TIER is red, or could not run"
elif [ -n "$risky" ]; then
    note "high-risk change (${risky% }): $TIER runs on the pool AND here, side by side; both must be green"
    prcf="$WD/$PFX.pool.rc"; rm -f "$prcf"
    ( pool_run; echo $? > "$prcf" ) &
    bg=$!
    local_run; lrc=$?
    wait "$bg"; prc=$(cat "$prcf" 2>/dev/null || echo 3)
    if [ "$lrc" = 4 ]; then
        note "high-risk change: this machine CANNOT RUN $TIER (no Node with WebSocket); pool $(gr $prc) — ONE run, not the two the rule asks for"
        refuse "this machine cannot run the $TIER tier (install Node >= 22 or put it on PATH); a high-risk change needs both runs"
    elif [ "$prc" = 3 ]; then
        note "high-risk change: the pool gave no result; local alone ($(gr $lrc)) — ONE run, not the two the rule asks for"
        [ "$lrc" = 0 ] || refuse "local $TIER is red (and the pool gave no result)"
    elif [ "$prc" != "$lrc" ]; then
        refuse "the pool ($(gr $prc)) and this machine ($(gr $lrc)) DISAGREE on a high-risk change: find out why"
    elif [ "$prc" != 0 ]; then
        refuse "$TIER is red on the pool and here"
    else
        note "high-risk change: pool and local both green"
    fi
else
    note "normal change: $TIER runs on the pool"
    pool_run; prc=$?
    if [ "$prc" = 3 ]; then
        note "the pool gave no result: falling back to the local run"
        local_run || refuse "local $TIER is red or could not run (pool unavailable)"
    elif [ "$prc" != 0 ]; then
        refuse "pool $TIER is red"
    else
        note "normal change: pool green"
    fi
fi
exit 0
