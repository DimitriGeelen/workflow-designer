#!/usr/bin/env bash
# submit.sh — T-1406: run one of 832's test tiers for HEAD on ring20's dispatch pool (T-1397 GO).
#
#   bash tools/pool/submit.sh core|browser            stage HEAD, submit, wait, print the result
#   bash tools/pool/submit.sh local core|browser      run tools/pool/run-tier.sh here on the same inputs (a proof run)
#
# Inputs are built from GIT ONLY, never the working tree (build/peer-data holds a client's documents):
#   code.tar         `git archive HEAD -- tools/pool` (the launcher; small, staged with `pool-client ref-put`)
#   repo.bundle.NNN  `git bundle` of HEAD + bleeding-edge + tags, split into <= 64 MB parts, written to build/pool/stage/
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

# --- inputs, from git only ---------------------------------------------------------------------------------------
build_inputs() {
    local dir="$STAGE/$SHORT"
    if [ -f "$dir/.complete" ]; then echo "$dir"; return; fi
    rm -rf "$dir"; mkdir -p "$dir"
    git archive --format=tar HEAD -- tools/pool > "$dir/code.tar"
    git bundle create "$dir/repo.bundle" HEAD bleeding-edge --tags >/dev/null 2>&1
    git bundle verify "$dir/repo.bundle" >/dev/null 2>&1 || { echo "bundle does not verify" >&2; exit 1; }
    split -b 64M -d -a 3 "$dir/repo.bundle" "$dir/repo.bundle."
    rm -f "$dir/repo.bundle"
    : > "$dir/.complete"
    echo "$dir"
}

DIR=$(build_inputs)
PARTS=$(cd "$DIR" && ls repo.bundle.[0-9][0-9][0-9] | sort)
echo "inputs for $SHORT: code.tar ($(stat -c %s "$DIR/code.tar") B) + $(echo "$PARTS" | wc -l) bundle part(s), $(du -sh "$DIR" | cut -f1)" >&2

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
    local f=$1 sha size req since
    sha=$(sha256sum "$f" | cut -d' ' -f1); size=$(stat -c %s "$f")
    if grep -qx "$sha" "$STAGED"; then echo "$sha"; return; fi
    req="832-$SHORT-$(basename "$f")-$(date +%s)"
    since=$(( $(date +%s) * 1000 - 5000 ))
    termlink channel post pool:stage --hub "$HUB" --msg-type stage \
        "$(printf '{"schema":"ring20.pool.stage/1","path":"%s","size":%s,"sha256":"%s","request":"%s","client":"832-Workflow-designer"}' "$f" "$size" "$sha" "$req")" >/dev/null
    local t0; t0=$(date +%s)
    while :; do
        if termlink channel subscribe pool:stage-out --hub "$HUB" --since "$since" --limit 500 2>/dev/null | grep -F "$req" | grep -qiE '"ok" *: *true|\bok\b'; then
            echo "$sha" >> "$STAGED"; echo "$sha"; return
        fi
        if termlink channel subscribe pool:stage-out --hub "$HUB" --since "$since" --limit 500 2>/dev/null | grep -F "$req" | grep -qiE 'error|refus|fail'; then
            echo "staging $(basename "$f") was refused:" >&2
            termlink channel subscribe pool:stage-out --hub "$HUB" --since "$since" --limit 500 2>/dev/null | grep -F "$req" >&2
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

NAME="832-$TIER-$SHORT-$(date -u +%Y%m%dT%H%M%S)"
FOLDER=$(mktemp -d "${TMPDIR:-/tmp}/832pool-folder.XXXXXX")
printf 'tier=%s\ncommit=%s\n' "$TIER" "$COMMIT" > "$FOLDER/job.info"
pool-client --hub "$HUB" submit-cmd "$FOLDER" --name "$NAME" --unit "832/$SHORT" --step "$TIER" \
    --entry "832.bridge-$TIER" --env bridge832-1 --client 832-Workflow-designer --task T-1406 "${REFS[@]}"
rm -rf "$FOLDER"
echo "submitted $NAME; waiting (up to 75 min) ..." >&2
pool-client --hub "$HUB" wait "$NAME" --timeout 4500 --dir "$ROOT/build/pool/wait"
echo "wait result: $ROOT/build/pool/wait/$NAME/ ; out/: $ROOT/build/pool/results/ (job dir named by the pool)" >&2
cat "$ROOT/build/pool/wait/$NAME/exit_code" 2>/dev/null || true
