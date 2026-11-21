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

# T-1486 (T-1478 GO; T-1479 measured: leg for leg this machine is 1.07x / 1.24x the pool, but it ran every leg one after
# another on a 24-core host, 26 + 16 min): the tier here runs as LOCAL_K shards at once, each in its own clean clone of
# HEAD (what the pool tests, and no shared files, ports or output paths between shards). LOCAL_K: T1486_LOCAL_K, else
# tools/pool/workers local_shards=<k>, else 1 (unsplit, in the checkout, as before). The browser tier uses its time-
# balanced plan tests/shard-plan-browser-<k>.tsv when there is one; otherwise every k-th leg (_t1288-tiers.sh).
# Per tier: local_shards_browser / local_shards_core. Core stays 1 for now: split, its legs that run the suite or the gate
# inside themselves inherit T1288_SHARD, and its hook and memory legs need the pool's clone set-up (hooks installed,
# tags, branch) — T-1481 makes core shardable (measured 2026-11-22: k=3 core here, 13 legs red; browser k=3 green).
LOCAL_K=${T1486_LOCAL_K:-$(sed -n "s/^local_shards_$TIER=//p" "$ROOT/tools/pool/workers" 2>/dev/null | head -1)}
case "$LOCAL_K" in ''|*[!0-9]*) LOCAL_K=1 ;; esac
local_split() {  # local_split <out>: LOCAL_K shards of the tier here, all at once; 0 only if every shard is green
    local out=$1 base i plan="" rc=0 code
    base=$(mktemp -d "${TMPDIR:-/tmp}/t1486-$TIER.XXXXXX") || return 1
    [ -f "$ROOT/tests/shard-plan-$TIER-$LOCAL_K.tsv" ] && plan="tests/shard-plan-$TIER-$LOCAL_K.tsv"
    echo "T-1288 $TIER: running the $TIER tier HERE as $LOCAL_K shards at once, each in a clean clone of ${HEAD_SHA:0:12}${plan:+ (plan $plan)} ..." >&2
    : > "$out"
    for i in $(seq 1 "$LOCAL_K"); do
        if ! { git clone -q --shared "$ROOT" "$base/s$i" && git -C "$base/s$i" checkout -q "$HEAD_SHA"; } 2>>"$out"; then
            echo "T-1288 $TIER: could not make clone $i of $LOCAL_K here — no verdict" >&2; rm -rf -- "$base"; return 1
        fi
    done
    local pids=()
    for i in $(seq 1 "$LOCAL_K"); do
        ( cd "$base/s$i" || exit 1
          export T1288_SHARD="$i/$LOCAL_K" T1288_LEGLOG="$WD/$PFX.local-s$i.legs.tsv"
          [ -n "$plan" ] && export T1288_SHARD_PLAN="$base/s$i/$plan"
          # the framework's pointers name this checkout; cleared so every leg acts on the clone (as tools/pool/run-tier.sh)
          exec env -u PROJECT_ROOT -u FRAMEWORK_ROOT -u CONTEXT_DIR -u TASKS_DIR -u FW_ROUTED_FROM \
              ${T1486_LOCAL_CMD:-bash tests/run-bridge-tests.sh} --tier "$TIER" ) </dev/null > "$WD/$PFX.local-s$i.log" 2>&1 8<&- &   # T1486_LOCAL_CMD: tests only
        pids+=($!)
    done
    for i in $(seq 1 "$LOCAL_K"); do
        wait "${pids[$((i - 1))]}"; code=$?
        { echo "===== shard $i/$LOCAL_K (exit $code) ====="; cat "$WD/$PFX.local-s$i.log"; } >> "$out"
        # a shard that printed no verdict line ran nothing it can vouch for: not a green
        if [ "$code" -ne 0 ] || ! grep -qE "^tier $TIER +GREEN" "$WD/$PFX.local-s$i.log"; then rc=1; fi
    done
    rm -rf -- "$base"
    return "$rc"
}

local_run() {  # the tier here; 0 green, 1 red (a red run's log is kept, newest five)
    if ! pick_node && [ "$TIER" = browser ]; then   # core does not need it, so core runs on regardless
        echo "T-1288 $TIER: CANNOT RUN here — no Node with a global WebSocket (>= 22) on PATH or under ~/.nvm; the CDP legs would all fail without measuring" >&2
        return 4
    fi
    local out="$WD/$PFX.log" rc red
    if [ "$LOCAL_K" -ge 2 ]; then
        local_split "$out"; rc=$?
    else
        echo "T-1288 $TIER: running the $TIER tier HERE (tests/run-bridge-tests.sh --tier $TIER) ..." >&2
        ( cd "$ROOT" && bash tests/run-bridge-tests.sh --tier "$TIER" ) </dev/null > "$out" 2>&1 8<&-
        rc=$?
    fi
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

pool_job() {  # pool_job <shard i/k or empty> <tag>: ONE pool job for HEAD; 0 green, 1 red, 3 no result for THIS commit
    local shard=$1 tag=$2 last commit code line node log
    last="$ROOT/build/pool/last-$TIER${shard:+-shard${shard%/*}of${shard#*/}}.result"
    local node=""   # T-1467: a shard on its configured node, the shadow ("" shard, tag .shadow-*) on the shadow node
    if [ -n "$shard" ]; then node=$(node_of "${shard%/*}"); elif [ "${tag#.shadow}" != "$tag" ]; then node=$SHADOW_NODE; fi
    ( cd "$ROOT" && SHARD="$shard" POOL_NODE="$node" ${T1408_POOL_SUBMIT:-bash tools/pool/submit.sh} "$TIER" ) </dev/null > "$WD/$PFX.pool$tag.out" 2>&1 8<&-
    if [ ! -f "$last" ]; then   # T-1453: say why, when the pool said why (a refusal names its reason)
        echo "T-1288 $TIER: the pool${shard:+ (shard $shard)} gave no result (see ${WD#"$ROOT"/}/$PFX.pool$tag.out)" >&2
        grep -E '^POOL [A-Z]+ on ' "$WD/$PFX.pool$tag.out" 2>/dev/null | tail -1 | sed "s/^/T-1288 $TIER: /" >&2
        return 3
    fi
    commit=$(sed -n 's/^commit=//p' "$last"); code=$(sed -n 's/^exit_code=//p' "$last")
    line=$(sed -n 's/^result_line=//p' "$last"); node=$(sed -n 's/^node=//p' "$last"); log=$(sed -n 's/^tier_log=//p' "$last")
    if [ -z "$commit" ]; then   # T-1453: the job failed before it tested anything; say why, by the job's own words
        echo "T-1288 $TIER: the pool job${shard:+ (shard $shard)} failed before testing (exit $code on $node): $(sed -n 's/^error=//p' "$last") — not counted" >&2; return 3
    fi
    [ "$commit" = "$HEAD_SHA" ] || { echo "T-1288 $TIER: the pool's result${shard:+ (shard $shard)} is for ${commit:0:12}, not HEAD ${HEAD_SHA:0:12} — not counted" >&2; return 3; }
    echo "$line   [pool: $node${shard:+, shard $shard}]" >&2
    if [ "$code" = 0 ]; then return 0; fi
    echo "T-1288 $TIER: POOL $TIER tier${shard:+ (shard $shard)} is RED (exit $code). Full output: ${log#"$ROOT"/}" >&2
    [ -f "$log" ] && grep -E '^\s*\[(FAIL|QUARANTINED)\]' "$log" | head -20 >&2
    return 1
}

# T-1462 (T-1452 GO for lever B, operator 2026-11-20 "1, adopt the split now"): the browser tier runs on the pool as two
# shards in parallel (pool-w1 + pool-w2, the time-balanced plan tests/shard-plan-browser-2.tsv), about 12 min instead of
# 23. The unsplit run still goes, as a SHADOW the gate does not wait for: when it ends, compare-shards.py checks that
# the shards ran exactly its legs with the same outcome. A difference leaves a marker that refuses every later gate
# until a person has looked (and removed it): a disagreement still stops a push, one push later, without the gate
# paying for the full run each time. T1462_SPLIT=0 runs the unsplit job as the gate's pool half, as before.
SHADOW_DIR="$ROOT/build/tiergate/split-shadow"
# T-1467 (operator 2026-11-20: "I want the full split now. I want us to use all pool workers"): k shards, k = the
# number of capable workers. T1462_K, else tools/pool/workers (browser_shards=<k>, what ring20 admits), else 2; the
# time-balanced plan tests/shard-plan-browser-<k>.tsv must exist (shard-plan.py builds it from a whole run).
K=${T1462_K:-$(sed -n 's/^browser_shards=//p' "$ROOT/tools/pool/workers" 2>/dev/null | head -1)}
case "$K" in ''|*[!0-9]*) K=2 ;; esac
[ "$K" -ge 2 ] && [ -f "$ROOT/tests/shard-plan-browser-$K.tsv" ] || K=2
# Which node runs each shard and the shadow (ring20 T-2644 pin; tools/pool/workers: shard_nodes="pool-w1 pool-w2 ...",
# shadow_node=pool-132). The shards on the fast slots, the unsplit shadow on the slow node so it takes no fast slot.
SHARD_NODES=$(sed -n 's/^shard_nodes=//p' "$ROOT/tools/pool/workers" 2>/dev/null | head -1 | tr -d '"')
SHADOW_NODE=$(sed -n 's/^shadow_node=//p' "$ROOT/tools/pool/workers" 2>/dev/null | head -1 | tr -d '"')
node_of() { echo "$SHARD_NODES" | awk -v i="$1" '{print $i}'; }
split_ok() { [ "$TIER" = browser ] && [ "${T1462_SPLIT:-1}" != 0 ] && [ -f "$ROOT/tests/shard-plan-browser-$K.tsv" ]; }
shadow_start() {  # the unsplit job, detached from this gate; writes its rc and the comparison when it ends
    mkdir -p "$SHADOW_DIR"; local tag="${HEAD_SHA:0:12}-$(date -u +%Y%m%dT%H%M%SZ)"
    SHADOW_RC="$SHADOW_DIR/$tag.rc"
    ( trap '' HUP; cd "$ROOT"
      pool_job "" ".shadow-$tag" 2>> "$SHADOW_DIR/$tag.log"; echo $? > "$SHADOW_RC.tmp"; mv "$SHADOW_RC.tmp" "$SHADOW_RC"
      whole=$(sed -n 's/^name=//p' "$ROOT/build/pool/last-$TIER.result" 2>/dev/null)
      shards=(); missing=0
      for i in $(seq 1 "$K"); do n=$(sed -n 's/^name=//p' "$SHADOW_DIR/$tag.shard$i" 2>/dev/null); [ -n "$n" ] && shards+=("$n") || missing=1; done
      if [ -n "$whole" ] && [ "$missing" = 0 ]; then
          # written under a temporary name; the marker (if any) first, the .compare last: a visible .compare is complete
          python3 "$ROOT/docs/reports/T-1452-spikes/compare-shards.py" "$whole" "${shards[@]}" > "$SHADOW_DIR/$tag.compare.tmp" 2>&1
          if grep -qE '^FAIL  C[123]' "$SHADOW_DIR/$tag.compare.tmp"; then
              cp "$SHADOW_DIR/$tag.compare.tmp" "$SHADOW_DIR/DIFFER-$tag"
              printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${HEAD_SHA:0:12}" "SPLIT SHADOW DISAGREES: $SHADOW_DIR/DIFFER-$tag" >> "$RUNS"
          fi
          mv "$SHADOW_DIR/$tag.compare.tmp" "$SHADOW_DIR/$tag.compare"
      else echo "no comparison: whole='$whole' shards='${shards[*]}' (of $K)" > "$SHADOW_DIR/$tag.compare.tmp"; mv "$SHADOW_DIR/$tag.compare.tmp" "$SHADOW_DIR/$tag.compare"; fi
    ) </dev/null > /dev/null 2>&1 &
    SHADOW_TAG=$tag
}
pool_run() {  # the tier on ring20's pool; 0 green, 1 red, 3 no result for THIS commit (unavailable)
    if ! split_ok; then
        echo "T-1288 $TIER: running the $TIER tier on ring20's POOL (tools/pool/submit.sh $TIER) ..." >&2
        pool_job "" ""; return $?
    fi
    echo "T-1288 $TIER: running the $TIER tier on ring20's POOL as $K shards in parallel, the unsplit run as a non-gating shadow (T-1462, T-1467) ..." >&2
    shadow_start
    local i pids=() rcs=() anyred=0 allgreen=1
    for i in $(seq 1 "$K"); do rm -f "$WD/$PFX.pool.s$i.rc"; ( pool_job "$i/$K" ".s$i"; echo $? > "$WD/$PFX.pool.s$i.rc" ) & pids+=($!); done
    wait "${pids[@]}"
    for i in $(seq 1 "$K"); do
        rcs+=("$(cat "$WD/$PFX.pool.s$i.rc" 2>/dev/null || echo 3)")
        cp "$ROOT/build/pool/last-$TIER-shard${i}of$K.result" "$SHADOW_DIR/$SHADOW_TAG.shard$i" 2>/dev/null
    done
    for r in "${rcs[@]}"; do [ "$r" = 0 ] || allgreen=0; [ "$r" = 1 ] && anyred=1; done
    if [ "$allgreen" = 1 ]; then return 0; fi
    if [ "$anyred" = 1 ]; then return 1; fi
    # a shard gave no result: the unsplit shadow decides for the pool (waited for, up to its own limit)
    echo "T-1288 $TIER: a shard gave no result (rc per shard: ${rcs[*]}): waiting for the unsplit run instead ..." >&2
    local t=0; while [ ! -f "$SHADOW_DIR/$SHADOW_TAG.rc" ] && [ $t -lt 4800 ]; do sleep 10; t=$((t + 10)); done
    return "$(cat "$SHADOW_DIR/$SHADOW_TAG.rc" 2>/dev/null || echo 3)"
}

# T-1452 (1409's first question: can we see what happened?): every run leaves a verdict line in the runs log, a red
# one too. Before, refuse() wrote only to the screen, so a red run and a killed one both left a start line and nothing
# else (12 such runs on 2026-11-19 alone), and the timing report could not tell them apart.
_GATE_ENDED=0
refuse() { note "REFUSED — $1"; _GATE_ENDED=1; exit 1; }
trap 'rc=$?; [ "$_GATE_ENDED" = 1 ] || [ "$rc" = 0 ] || note "ENDED without a verdict (exit $rc: interrupted or failed before deciding)"' EXIT
trap 'exit 130' INT TERM HUP
gr() { [ "$1" = 0 ] && echo green || echo red; }

if split_ok && ls "$SHADOW_DIR"/DIFFER-* >/dev/null 2>&1; then
    refuse "a split run disagreed with its unsplit shadow: $(ls "$SHADOW_DIR"/DIFFER-* | head -3 | tr '\n' ' ')— read it, find out why, then remove the marker (T-1462)"
fi
upstream=$(cd "$ROOT" && git rev-parse -q --verify '@{u}' 2>/dev/null) || upstream=""
if [ -n "$upstream" ]; then changed=$(cd "$ROOT" && git diff --name-only "$upstream" HEAD); else changed=$(cd "$ROOT" && git ls-tree -r --name-only HEAD); fi
risky=$(printf '%s\n' "$changed" | grep -E "$HIGH_RISK_RE" | head -3 | tr '\n' ' ')

if [ "${T1408_POOL:-1}" = 0 ]; then
    note "T1408_POOL=0: $TIER runs locally only (pool skipped on request)"
    local_run || refuse "local $TIER is red, or could not run"
    note "local only: green"   # T-1452: the verdict line, as every other path writes one
elif [ "${T1467_POOL_ONLY:-0}" = 1 ]; then
    # T-1467 (operator 2026-11-20, option 1 for release 0.45.0): the pool alone, even for a high-risk change. This host is
    # a busy desktop where a Chrome start fails now and then (release job 173 and 174 each lost one leg to it); the
    # release's browser tier runs on the quiet pool workers instead. No pool result is a refusal here, never a local run.
    note "T1467_POOL_ONLY=1: $TIER runs on the pool only (operator's choice for releases, 2026-11-20)${risky:+; high-risk change: ${risky% }}"
    pool_run; prc=$?
    [ "$prc" = 3 ] && refuse "the pool gave no result (T1467_POOL_ONLY: no local fallback)"
    [ "$prc" = 0 ] || refuse "pool $TIER is red"
    note "pool only: green"
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
        note "normal change: local green (pool gave no result)"   # T-1452: a verdict line on every path
    elif [ "$prc" != 0 ]; then
        refuse "pool $TIER is red"
    else
        note "normal change: pool green"
    fi
fi
exit 0
