#!/usr/bin/env bash
# run-tier.sh — T-1406: run one of 832's test tiers inside ring20's dispatch pool (T-1397 GO).
#
# Called by the pool as:  bash code/tools/pool/run-tier.sh core|browser   (cwd = the job dir)
# The job dir holds repo.bundle.000, .001, … (one git bundle of 832, split into <= 64 MB parts; refs) and code/ (this
# launcher, read-only). The job dir and a tmpfs are writable; there is no network beyond loopback and no user namespace.
#
# It rebuilds the repo from the bundle in a writable dir, runs `tests/run-bridge-tests.sh --tier <tier>` there, and
# writes out/result.json and out/tier.log (the pool returns out/ to 832 as artifacts).
#   result.json: {tier, commit, exit_code, result_line, fail_lines, duration_s, node, arch, launcher, error}
# Exit code: the tier's own (0 green, 1 red), or 2 when the launcher could not run the tier at all (error says why).
#
# Chromium: the harnesses look under ~/.cache/ms-playwright; HOME is pointed at the write area and that path is linked to
# $PLAYWRIGHT_BROWSERS_PATH (the pool's read-only Playwright browsers, same chromium-NNNN/chrome-linux64 layout), so no
# harness needs to change. Local runs (no PLAYWRIGHT_BROWSERS_PATH) keep the user's own cache.
set -u
TIER="${1:-}"
JOB="$(pwd)"
OUT="$JOB/out"
mkdir -p "$OUT"
T0=$(date +%s)
LOG="$OUT/tier.log"
: > "$LOG"

result() {  # result <exit_code> <error or empty>
    local rc=$1 err=$2 commit result_line fails
    commit=$(git -C "$WORK/repo" rev-parse HEAD 2>/dev/null || echo "")
    result_line=$(grep -E '^tier [a-z]+ ' "$LOG" 2>/dev/null | tail -1)
    fails=$(grep -E '^\s*\[(FAIL|QUARANTINED)\]' "$LOG" 2>/dev/null | head -40)
    python3 - "$OUT/result.json" "$TIER" "$commit" "$rc" "$result_line" "$fails" "$(( $(date +%s) - T0 ))" "$err" <<'PY'
import json, os, platform, sys
path, tier, commit, rc, line, fails, dur, err = sys.argv[1:]
json.dump({"tier": tier, "commit": commit, "exit_code": int(rc), "result_line": line,
           "fail_lines": [l.strip() for l in fails.splitlines() if l.strip()], "duration_s": int(dur),
           "node": platform.node(), "arch": platform.machine(), "launcher": "tools/pool/run-tier.sh (832 T-1406)",
           "error": err or None}, open(path, "w"), indent=2)
PY
    exit "$rc"
}

case "$TIER" in core|browser) ;; *) WORK=/nonexistent; echo "usage: run-tier.sh core|browser" >> "$LOG"; result 2 "bad tier argument '${TIER}'" ;; esac

# Writable work area: the pool's tmpfs if it gives one, else the job dir.
WORK="$(mktemp -d "${TMPDIR:-$JOB}/832-pool.XXXXXX" 2>/dev/null || mktemp -d "$JOB/832-pool.XXXXXX")"
{
    echo "== 832 pool launcher (T-1406): tier=$TIER node=$(uname -n) arch=$(uname -m) work=$WORK"
    echo "== node $(node -v 2>&1), $(python3 --version 2>&1), $(git --version 2>&1)"
} >> "$LOG"

# T-1453: a worker caps the size of one file (2026-11-19: soft = hard = 262144, i.e. 256 MiB, as bash counts -f in
# 1024-byte blocks). It is logged on every job, so the cause of a failure here is read, never guessed.
FSZ_SOFT=$(ulimit -S -f); FSZ_HARD=$(ulimit -H -f)
[ "$FSZ_SOFT" = "$FSZ_HARD" ] || ulimit -S -f "$FSZ_HARD" 2>/dev/null || true
echo "== file-size limit (1024-byte blocks): soft $FSZ_SOFT, hard $FSZ_HARD, now $(ulimit -S -f)" >> "$LOG"
fits() { [ "$(ulimit -S -f)" = unlimited ] || [ "$1" -le $(( $(ulimit -S -f) * 1024 )) ]; }
# 1. Rebuild the repo. Since T-1453 it arrives as a CHAIN of bundles (repo.chain.NNN), each a valid bundle under the
# limit, fetched in order into one repository, so no file larger than one link is ever written. The joined form
# (repo.bundle.NNN parts) is still read, for a job staged before the chain.
chain=$(ls "$JOB"/repo.chain.[0-9][0-9][0-9] 2>/dev/null | sort)
if [ -n "$chain" ]; then
    last=$(printf '%s\n' $chain | tail -1)
    for b in $chain; do fits "$(stat -L -c %s "$b")" || result 2 "chain link $(basename "$b") ($(stat -L -c %s "$b") bytes) is over this worker's file-size limit (T-1453)"; done
    git init -q "$WORK/repo" >> "$LOG" 2>&1 || result 2 "git init failed"
    git -C "$WORK/repo" config gc.auto 0   # never repack the links into one pack over the limit
    git -C "$WORK/repo" remote add origin "$last"
    for b in $chain; do
        git -C "$WORK/repo" fetch -q "$b" '+refs/heads/*:refs/remotes/origin/*' '+refs/tags/*:refs/tags/*' >> "$LOG" 2>&1 \
            || result 2 "fetching chain link $(basename "$b") failed (a missing earlier link, or a corrupt one)"
    done
    # the real origin/master (cited commits, T-1406) after the heads, which map onto the same names
    git -C "$WORK/repo" fetch -q "$last" '+refs/remotes/*:refs/remotes/*' >> "$LOG" 2>&1 || true
    head=$(git -C "$WORK/repo" bundle list-heads "$last" HEAD 2>/dev/null | awk '{print $1}' | head -1)
    [ -n "$head" ] || result 2 "the last chain link names no HEAD"
    # as `git clone` did: the branch HEAD is on, checked out and tracking origin (bleeding-edge first)
    br=$(git -C "$WORK/repo" bundle list-heads "$last" 2>/dev/null | awk -v h="$head" '$1 == h && $2 ~ /^refs\/heads\// {sub("refs/heads/", "", $2); print $2}' \
        | awk '$0 == "bleeding-edge" {print; found = 1; exit} {first = first ? first : $0} END {if (!found && first) print first}')
    if [ -n "$br" ]; then git -C "$WORK/repo" checkout -q -b "$br" "$head" && git -C "$WORK/repo" branch -q -u "origin/$br" "$br" 2>/dev/null || true
    else git -C "$WORK/repo" checkout -q --detach "$head"; fi
    [ "$(git -C "$WORK/repo" rev-parse HEAD 2>/dev/null)" = "$head" ] || result 2 "checkout of $head from the chain failed"
    echo "== repo from $(printf '%s\n' $chain | wc -l) chain link(s), on ${br:-detached HEAD}" >> "$LOG"
else
    parts=$(ls "$JOB"/repo.bundle.[0-9][0-9][0-9] 2>/dev/null | sort)
    [ -n "$parts" ] || result 2 "no repo.chain.NNN links or repo.bundle.NNN parts in the job dir"
    # shellcheck disable=SC2086
    BUNDLE_BYTES=$(cat $parts | wc -c)
    fits "$BUNDLE_BYTES" || result 2 "the joined bundle ($BUNDLE_BYTES bytes) is larger than this worker allows one file to be ($(( $(ulimit -S -f) * 1024 )) bytes) — T-1453"
    # shellcheck disable=SC2086
    cat $parts > "$WORK/repo.bundle" || result 2 "could not join the bundle parts"
    # `git bundle verify` needs a repository, so the clone comes first (it checks the bundle too), then the verify inside it.
    git clone -q "$WORK/repo.bundle" "$WORK/repo" >> "$LOG" 2>&1 || result 2 "git clone from the bundle failed"
    git -C "$WORK/repo" bundle verify "$WORK/repo.bundle" >> "$LOG" 2>&1 || result 2 "the joined bundle does not verify"
    git -C "$WORK/repo" fetch -q "$WORK/repo.bundle" '+refs/tags/*:refs/tags/*' '+refs/remotes/*:refs/remotes/*' >> "$LOG" 2>&1 || true
    rm -f "$WORK/repo.bundle"
fi
# .git/hooks is not cloned; the framework's hooks go in first (fw git install-hooks), then 832 adds its gates to them
# (T-1000, T-1161, T-1239), and core checks they are in place. Pointers cleared so both target the clone (T-1398 class).
( cd "$WORK/repo" && env -u PROJECT_ROOT -u FRAMEWORK_ROOT -u CONTEXT_DIR -u TASKS_DIR -u FW_ROUTED_FROM \
    sh -c '.agentic-framework/bin/fw git install-hooks && bash tools/_t1000-install-hook.sh' ) >> "$LOG" 2>&1 \
    || echo "== hook install failed (see above)" >> "$LOG"
echo "== repo at $(git -C "$WORK/repo" rev-parse --short HEAD) ($(git -C "$WORK/repo" log -1 --format=%s | cut -c1-80))" >> "$LOG"

# 2. Environment: a writable HOME with the pool's browsers where the harnesses look; git identity for fixture commits.
export HOME="$WORK/home"
mkdir -p "$HOME/.cache"
if [ -n "${PLAYWRIGHT_BROWSERS_PATH:-}" ] && [ -d "$PLAYWRIGHT_BROWSERS_PATH" ]; then
    # Every 832 finder (node and python) looks for ~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome. The pool's
    # read-only tree may lay a build out as chrome-linux/ instead (the first browser run found chromium-1187 but "no
    # chromium" in 59 legs), so build our own cache dir: each entry linked as is, and for each chromium-NNNN a
    # chrome-linux64 that points at whichever of chrome-linux64/ or chrome-linux/ holds the chrome binary.
    PW="$HOME/.cache/ms-playwright"; mkdir -p "$PW"
    for e in "$PLAYWRIGHT_BROWSERS_PATH"/*; do
        n=$(basename "$e")
        case "$n" in
            chromium-[0-9]*)
                mkdir -p "$PW/$n"
                for sub in "$e"/*; do ln -s "$sub" "$PW/$n/$(basename "$sub")"; done
                if [ ! -e "$PW/$n/chrome-linux64/chrome" ]; then
                    for alt in chrome-linux64 chrome-linux; do
                        if [ -x "$e/$alt/chrome" ]; then rm -f "$PW/$n/chrome-linux64"; ln -s "$e/$alt" "$PW/$n/chrome-linux64"; break; fi
                    done
                fi
                echo "== browsers: $n contains [$(ls "$e" | tr '\n' ' ')]; chrome at $(readlink -f "$PW/$n/chrome-linux64/chrome" 2>/dev/null || echo 'NOT FOUND')" >> "$LOG" ;;
            *) ln -s "$e" "$PW/$n" ;;
        esac
    done
    echo "== browsers: $PLAYWRIGHT_BROWSERS_PATH ($(ls "$PLAYWRIGHT_BROWSERS_PATH" | tr '\n' ' '))" >> "$LOG"
fi
git config --global user.name "832 pool run" 2>/dev/null
git config --global user.email "832-pool@invalid" 2>/dev/null
export T1406_POOL=1

# 3. The tier, with no project pointer inherited from the caller (the T-1398 class: a session's PROJECT_ROOT or
#    FRAMEWORK_ROOT made the first local proof's budget and audit legs read the REAL repo's .context/, not the clone's).
( cd "$WORK/repo" && exec env -u PROJECT_ROOT -u FRAMEWORK_ROOT -u CONTEXT_DIR -u TASKS_DIR -u FW_ROUTED_FROM \
    -u FW_CLAUDE_FW_SUPERVISED -u CLAUDE_CODE_SESSION_ID -u CLAUDECODE -u CLAUDE_PID \
    bash tests/run-bridge-tests.sh --tier "$TIER" ) </dev/null >> "$LOG" 2>&1
rc=$?
[ "$rc" -le 1 ] || rc=1
result "$rc" ""
