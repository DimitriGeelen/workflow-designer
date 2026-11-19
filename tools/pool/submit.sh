#!/usr/bin/env bash
# submit.sh — T-1406: run one of 832's test tiers for HEAD on ring20's dispatch pool (T-1397 GO).
#
#   bash tools/pool/submit.sh core|browser            stage HEAD, submit, wait, print the result
#   bash tools/pool/submit.sh local core|browser      run tools/pool/run-tier.sh here on the same inputs (a proof run)
#
# Inputs are built from GIT ONLY, never the working tree (build/peer-data holds a client's documents):
#   code.tar         `git archive HEAD -- tools/pool` (the launcher; small, staged with `pool-client ref-put`)
#   repo.chain.NNN   T-1453: a chain of `git bundle`s (links ending at release tags, then last tag .. HEAD with every ref),
#                    each under the worker's one-file limit; links live in build/pool/stage/chain/ and are staged once
#                    and announced on pool:stage (ring20 copies only from that root); a part already staged (same sha256,
#                    recorded in build/pool/staged.txt) is not announced again.
# The hub address is read from the git-ignored build/pool/hub (no LAN address in tracked files, T-1239).
# Results: `pool-client wait` writes exit_code + result.jsonl to build/pool/wait/<name>/; out/ (result.json, tier.log)
# arrives verified in build/pool/results/<job>/.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
MODE=pool
if [ "${1:-}" = local ]; then MODE=local; shift; fi
TIER="${1:-}"
case "$TIER" in core|browser) ;; *) echo "usage: submit.sh [local] core|browser" >&2; exit 2 ;; esac
STAGE="$ROOT/build/pool/stage"
mkdir -p "$STAGE" "$ROOT/build/pool/wait"
COMMIT=$(git rev-parse HEAD)
SHORT=${COMMIT:0:12}
rm -f "$ROOT/build/pool/last-$TIER${SHARD:+-shard}.result"   # T-1408: never let an older run's outcome stand in for this one

# --- inputs, from git only ---------------------------------------------------------------------------------------
# T-1453: where the chain is cut. CHAIN_MAX is the target size of one link, estimated cheaply with `rev-list
# --disk-usage` (on-disk bytes; a bundle's own pack can be larger, so the target sits well under the hard limit);
# CHAIN_HARD is the worker's limit for one file (256 MiB, read on the worker 2026-11-19: soft = hard = 262144 KiB).
CHAIN_MAX=${CHAIN_MAX:-150000000}
CHAIN_HARD=${CHAIN_HARD:-268435456}
CHAIN_DIR="$ROOT/build/pool/stage/chain"; mkdir -p "$CHAIN_DIR"   # inside the stage root: ring20 copies only from there
CHAIN_CUTS="$CHAIN_DIR/cuts.txt"
du_range() { git rev-list --objects --disk-usage ${1:+"^$1"} "$2" 2>/dev/null || echo 0; }
chain_cuts() {  # the release tags the chain ends its links at, oldest first; kept stable across jobs (cuts.txt)
    local kept="" t prev="" last="" cand
    touch "$CHAIN_CUTS"
    while read -r t; do   # keep the recorded cuts that still lead to HEAD, in order
        [ -n "$t" ] && git merge-base --is-ancestor "refs/tags/$t" HEAD 2>/dev/null && { kept="$kept $t"; prev=$t; }
    done < "$CHAIN_CUTS"
    # extend: while the tail (last cut .. HEAD) is over CHAIN_MAX, cut at the newest release tag whose own link fits
    while [ "$(du_range "$prev" HEAD)" -gt "$CHAIN_MAX" ]; do
        last=""
        while read -r cand; do
            git merge-base --is-ancestor "refs/tags/$cand" HEAD 2>/dev/null || continue
            [ -n "$prev" ] && ! git merge-base --is-ancestor "refs/tags/$prev" "refs/tags/$cand" 2>/dev/null && continue
            [ "$cand" = "$prev" ] && continue
            if [ "$(du_range "$prev" "refs/tags/$cand")" -le "$CHAIN_MAX" ]; then last=$cand; else break; fi
        done < <(git tag -l 'designer-v*' --sort=creatordate)
        if [ -z "$last" ]; then   # even the next tag alone is over CHAIN_MAX: take it anyway (the size check refuses if it is over the hard limit)
            last=$(git tag -l 'designer-v*' --sort=creatordate | while read -r cand; do
                git merge-base --is-ancestor "refs/tags/$cand" HEAD 2>/dev/null || continue
                [ -n "$prev" ] && { git merge-base --is-ancestor "refs/tags/$prev" "refs/tags/$cand" 2>/dev/null || continue; [ "$cand" = "$prev" ] && continue; }
                echo "$cand"; break; done)
            [ -n "$last" ] || break
        fi
        kept="$kept $last"; prev=$last
    done
    printf '%s\n' $kept > "$CHAIN_CUTS"
    echo $kept
}
build_inputs() {
    local dir="$STAGE/$SHORT"
    if [ -f "$dir/.complete" ]; then echo "$dir"; return; fi
    rm -rf "$dir"; mkdir -p "$dir"
    git archive --format=tar HEAD -- tools/pool > "$dir/code.tar"
    # T-1453: the repo goes as a CHAIN of bundles, each a valid bundle under CHAIN_MAX, fetched one after another on the
    # worker. One joined bundle stopped fitting on 2026-11-19 (a worker allows no file over 256 MiB; the repo was 276 MB).
    # Older links end at release tags and never change, so each is built and staged once and reused by every later job;
    # only the last link (last cut .. HEAD, with every ref) is new per commit.
    # T-1406: origin/master too. A commit reachable only from it (the T-1383 licence commit) is cited by an episodic,
    # and the T-567 corpus check needs it in the clone (the first local proof failed there without it).
    local cuts prev n=0 t f
    cuts=$(chain_cuts)
    prev=""
    for t in $cuts; do
        f="$CHAIN_DIR/from-${prev:-root}-to-$t.bundle"   # T-1453: no ".." in a staged path (pool:stage refuses it as not normalised)
        if [ ! -s "$f" ]; then
            git bundle create "$f.tmp" ${prev:+"^$prev"} "refs/tags/$t" >/dev/null 2>&1 || { echo "chain link ${prev:-root}..$t failed" >&2; exit 1; }
            mv "$f.tmp" "$f"
        fi
        ln -sf "$f" "$dir/repo.chain.$(printf '%03d' $n)"; n=$((n + 1)); prev=$t
    done
    git bundle create "$dir/repo.chain.$(printf '%03d' $n)" HEAD bleeding-edge master refs/remotes/origin/master --tags \
        ${prev:+"^$prev"} >/dev/null 2>&1 || { echo "last chain link failed" >&2; exit 1; }
    for f in "$dir"/repo.chain.*; do
        local sz; sz=$(stat -L -c %s "$f")
        [ "$sz" -le "$CHAIN_HARD" ] || { echo "chain link $(basename "$f") is $sz bytes, over $CHAIN_HARD (T-1453)" >&2; exit 1; }
    done
    : > "$dir/.complete"
    echo "$dir"
}

DIR=$(build_inputs)
PARTS=$(cd "$DIR" && ls repo.chain.[0-9][0-9][0-9] | sort)
echo "inputs for $SHORT: code.tar ($(stat -c %s "$DIR/code.tar") B) + $(echo "$PARTS" | wc -l) chain link(s), $(du -shL "$DIR" | cut -f1)" >&2

if [ "$MODE" = local ]; then
    JOBD=$(mktemp -d "${TMPDIR:-/tmp}/832pool-job.XXXXXX")
    mkdir -p "$JOBD/code"; tar -xf "$DIR/code.tar" -C "$JOBD/code"
    for p in $PARTS; do ln -s "$DIR/$p" "$JOBD/$p"; done
    echo "local proof run in $JOBD (tier $TIER) ..." >&2
    ( cd "$JOBD" && bash code/tools/pool/run-tier.sh "$TIER" ) || true
    cat "$JOBD/out/result.json"
    echo "log: $JOBD/out/tier.log" >&2
    exit 0
fi

# --- pool --------------------------------------------------------------------------------------------------------
HUB=$(tr -d '[:space:]' < "$ROOT/build/pool/hub" 2>/dev/null || true)
[ -n "$HUB" ] || { echo "no hub address in build/pool/hub (git-ignored; one line host:port)" >&2; exit 2; }
case "$HUB" in 127.*|localhost*) echo "build/pool/hub must not be a loopback address (pool-client takes it for the local hub)" >&2; exit 2 ;; esac
STAGED="$ROOT/build/pool/staged.txt"; touch "$STAGED"

stage_part() {  # stage_part <file>: announce it on pool:stage once per sha256, wait for pool:stage-out's answer
    local f req sha size
    f=$(readlink -f "$1")   # T-1453: a chain link is a symlink to the shared link under stage/chain; announce the real file
    sha=$(sha256sum "$f" | cut -d' ' -f1); size=$(stat -c %s "$f")
    if grep -qx "$sha" "$STAGED"; then echo "$sha"; return; fi
    req="832-$SHORT-$(basename "$f")-$(date +%s)"
    termlink channel post pool:stage --hub "$HUB" --msg-type stage \
        "$(printf '{"schema":"ring20.pool.stage/1","path":"%s","size":%s,"sha256":"%s","request":"%s","client":"832-Workflow-designer"}' "$f" "$size" "$sha" "$req")" >/dev/null
    local t0; t0=$(date +%s)
    local answer
    while :; do
        # T-1330/T-1331: capture first, then grep the capture (a `cmd | grep -q` under pipefail can fail on SIGPIPE).
        # --tail: the topic holds thousands of records; without it subscribe reads one page from the START and never
        # reaches the answer (the first real run waited 900 s for an answer that had come in 5.3 s).
        answer=$(termlink channel subscribe pool:stage-out --hub "$HUB" --tail 300 2>/dev/null || true)
        answer=$(printf '%s\n' "$answer" | grep -F "$req" || true)
        # T-1453: read the answer's "ok" field, nothing else. `\bok\b` also matched the key in "ok": false, so a refused
        # stage counted as staged (two chain links, 2026-11-19) and was never retried.
        if [ -n "$answer" ] && printf '%s\n' "$answer" | grep -E '"ok" *: *true' >/dev/null; then
            echo "$sha" >> "$STAGED"; echo "$sha"; return
        fi
        if [ -n "$answer" ] && printf '%s\n' "$answer" | grep -E '"ok" *: *false' >/dev/null; then
            echo "staging $(basename "$f") was refused:" >&2
            printf '%s\n' "$answer" >&2
            exit 1
        fi
        [ $(( $(date +%s) - t0 )) -lt 900 ] || { echo "no answer on pool:stage-out for $req within 900 s" >&2; exit 1; }
        sleep 5
    done
}

CODE_SHA=$(pool-client --hub "$HUB" ref-put "$DIR/code.tar" | tail -1 | grep -oE '[0-9a-f]{64}' | head -1)
[ -n "$CODE_SHA" ] || { echo "ref-put of code.tar gave no sha256" >&2; exit 1; }
REFS=(--ref "code.tar=$CODE_SHA")
for p in $PARTS; do
    s=$(stage_part "$DIR/$p")
    echo "staged $p $s" >&2
    REFS+=(--ref "$p=$s")
done

# The pool toolchain the 832 entries require (ring20 names it; bridge832-2 since 2026-11-13 10:30Z adds the framework's
# web stack, ruamel.yaml, ripgrep and sqlite3). POOL_ENV overrides it for a one-off run.
POOL_ENV="${POOL_ENV:-bridge832-2}"
NAME="832-$TIER${SHARD:+-shard${SHARD%/*}of${SHARD#*/}}-$SHORT-$(date -u +%Y%m%dT%H%M%S)"
FOLDER=$(mktemp -d "${TMPDIR:-/tmp}/832pool-folder.XXXXXX")
printf 'tier=%s\ncommit=%s\n' "$TIER" "$COMMIT" > "$FOLDER/job.info"
# T-1452 (lever B, shadow): SHARD=i/k runs one shard of the tier; its result counts for nothing but the comparison
if [ -n "${SHARD:-}" ]; then printf 'shard=%s\n' "$SHARD" >> "$FOLDER/job.info"; fi
pool-client --hub "$HUB" submit-cmd "$FOLDER" --name "$NAME" --unit "832/$SHORT" --step "$TIER" \
    --entry "832.bridge-$TIER" --env "$POOL_ENV" --client 832-Workflow-designer --task T-1406 "${REFS[@]}"
rm -rf "$FOLDER"
echo "submitted $NAME; waiting (up to 75 min) ..." >&2
pool-client --hub "$HUB" wait "$NAME" --timeout 4500 --dir "$ROOT/build/pool/wait" || true
echo "wait result: $ROOT/build/pool/wait/$NAME/ ; out/: $ROOT/build/pool/results/$NAME/" >&2
# T-1453 (1409's lesson v): a refused job is read at once and named, never left as "no result"
python3 - "$ROOT/build/pool/wait/$NAME/pool-result.json" <<'PY' >&2 || true
import json, sys
try: d = json.load(open(sys.argv[1]))
except Exception: sys.exit(0)
if d.get("outcome") not in (None, "ok", "done", "completed", "succeeded"):
    print("POOL %s on %s: %s" % (str(d.get("outcome")).upper(), d.get("node") or "?", d.get("reason") or "(no reason given)"))
PY
cat "$ROOT/build/pool/wait/$NAME/exit_code" 2>/dev/null || true

# T-1408: the outcome for the pre-push gate, one key=value per line, in build/pool/last-<tier>.result (git-ignored).
# Written only when the pool returned a result.json for THIS commit; the gate reads a missing file as "pool unavailable".
RES="$ROOT/build/pool/results/$NAME/result.json"
for _ in 1 2 3 4 5 6; do [ -f "$RES" ] && break; sleep 10; done   # out/ is delivered just after the wait answers
if [ -f "$RES" ]; then
    python3 - "$RES" "$NAME" "$ROOT/build/pool/last-$TIER${SHARD:+-shard}.result" <<'PY'
import json, sys
res, name, dest = sys.argv[1:]
d = json.load(open(res))
with open(dest, "w") as f:
    f.write("name=%s\ncommit=%s\nexit_code=%s\nnode=%s\nresult_line=%s\ntier_log=%s\nerror=%s\n" % (
        name, d.get("commit", ""), d.get("exit_code", ""), d.get("node", ""),
        (d.get("result_line") or "").replace("\n", " "), res.replace("result.json", "tier.log"),
        (d.get("error") or "").replace("\n", " ")))   # T-1453: why a job failed before testing
PY
fi
