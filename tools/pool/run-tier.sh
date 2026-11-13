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

# 1. Rebuild the repo from the bundle parts, in order.
parts=$(ls "$JOB"/repo.bundle.[0-9][0-9][0-9] 2>/dev/null | sort)
[ -n "$parts" ] || result 2 "no repo.bundle.NNN parts in the job dir"
# shellcheck disable=SC2086
cat $parts > "$WORK/repo.bundle" || result 2 "could not join the bundle parts"
# `git bundle verify` needs a repository, so the clone comes first (it checks the bundle too), then the verify inside it.
git clone -q "$WORK/repo.bundle" "$WORK/repo" >> "$LOG" 2>&1 || result 2 "git clone from the bundle failed"
git -C "$WORK/repo" bundle verify "$WORK/repo.bundle" >> "$LOG" 2>&1 || result 2 "the joined bundle does not verify"
git -C "$WORK/repo" fetch -q --tags "$WORK/repo.bundle" '+refs/tags/*:refs/tags/*' >> "$LOG" 2>&1 || true
rm -f "$WORK/repo.bundle"
echo "== repo at $(git -C "$WORK/repo" rev-parse --short HEAD) ($(git -C "$WORK/repo" log -1 --format=%s | cut -c1-80))" >> "$LOG"

# 2. Environment: a writable HOME with the pool's browsers where the harnesses look; git identity for fixture commits.
export HOME="$WORK/home"
mkdir -p "$HOME/.cache"
if [ -n "${PLAYWRIGHT_BROWSERS_PATH:-}" ] && [ -d "$PLAYWRIGHT_BROWSERS_PATH" ]; then
    ln -s "$PLAYWRIGHT_BROWSERS_PATH" "$HOME/.cache/ms-playwright"
    echo "== browsers: $PLAYWRIGHT_BROWSERS_PATH ($(ls "$PLAYWRIGHT_BROWSERS_PATH" | tr '\n' ' '))" >> "$LOG"
fi
git config --global user.name "832 pool run" 2>/dev/null
git config --global user.email "832-pool@invalid" 2>/dev/null
export T1406_POOL=1

# 3. The tier.
( cd "$WORK/repo" && bash tests/run-bridge-tests.sh --tier "$TIER" ) </dev/null >> "$LOG" 2>&1
rc=$?
[ "$rc" -le 1 ] || rc=1
result "$rc" ""
