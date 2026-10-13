# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Upgrade AEF bleeding-edge ed683536a -> 1146a7450 (final G-114 fix, v1.8.11 candidate), re-vendor protocol"
JOB_TASK="T-1167"
JOB_WHY="AEF released v1.8.10, an emergency fix for G-114: a decision recorded in Watchtower could be silently undone
by the next ordinary commit. We run bleeding-edge ed683536a, which has the first fix (T-4081) but not the final one
(T-4127). AEF advised (msg 36d1129c) NOT the v1.8.10 tag, which would drop the bleeding-edge fixes we field-tested,
but the bleeding-edge tip 1146a7450 (also T-4145 sidecar framing, T-4149 boundary hook parser, T-4150 budget-gate
classifier). Checked today: nothing staged, and AEF's revert scan finds 0 decisions undone in 60 days.
Same protocol as job 018: fw doctor captured first; pristine vendor commit (--allow-delete-locals, backups kept);
divergence baseline advanced; crontab checked; fw doctor after; then Watchtower is restarted on the new code.
The agent then re-applies our local fixes and re-runs the revert scan. Nothing is pushed.
Afterwards: relaunch claude-fw at a natural break (a running wrapper keeps the old code)."

SHA=1146a745045ee204701419c4ac172030a1ef88a1
FROM=ed683536a85ee1668c668c82b850eac2676b4f72
UPSTREAM=https://github.com/DimitriGeelen/agentic-engineering-framework.git
DIV=.agentic-framework/.vendor-divergence.yaml
CRON=/etc/cron.d/agentic-audit-832-workflow-designer
OUT=.context/runme/023-upgrade-aef-1146a7450
PORT=3013

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "no uncommitted edits under .agentic-framework/" 'git diff --quiet -- .agentic-framework'
    check "re-vendor gate installed (T-1000)" 'bash tools/_t1000-install-hook.sh --check'
    check "framework is ed683536a (.framework.yaml version_sha)" '[ "$(sed -n "s/^version_sha: *//p" .framework.yaml)" = "$FROM" ]'
    check ".fwvendor-preserve.yaml committed as-is" 'git ls-files --error-unmatch .fwvendor-preserve.yaml && git diff --quiet -- .fwvendor-preserve.yaml'
    check "upstream bleeding-edge still has 1146a7450" 'git ls-remote "$UPSTREAM" refs/heads/bleeding-edge | grep -q "^$SHA" || git ls-remote "$UPSTREAM" | grep -q "^$SHA"'
}

steps() {
    step "Capture fw doctor BEFORE" 'do_doctor before'
    step "Upgrade to 1146a7450 (clone, check out the pinned commit, fw upgrade --allow-delete-locals, re-install the re-vendor gate)" 'do_upgrade'
    step "Pristine commit: .agentic-framework/ exactly as the upgrade wrote it" 'do_pristine_commit'
    step "Advance the divergence baseline to that commit (commit it alone)" 'do_baseline'
    step "Check the crontab still points at the vendored framework" 'do_cron_check'
    step "Capture fw doctor AFTER" 'do_doctor after'
    step "Restart Watchtower on port $PORT, then check it is newer than its web code and answering" 'do_restart'
}

do_doctor() {
    .agentic-framework/bin/fw doctor > "$OUT/doctor-$1.txt" 2>&1
    echo "fw doctor $1: rc=$? — saved to $OUT/doctor-$1.txt ($(grep -c . "$OUT/doctor-$1.txt") lines)"
    return 0
}

do_upgrade() {
    local src
    src=$(mktemp -d /tmp/t1167-aef.XXXXXX) || return 1
    git clone -q "$UPSTREAM" "$src/fw" || { rm -rf "$src"; return 1; }
    git -C "$src/fw" -c advice.detachedHead=false checkout -q "$SHA" || { echo "commit $SHA not found upstream"; rm -rf "$src"; return 1; }
    [ "$(git -C "$src/fw" rev-parse HEAD)" = "$SHA" ] || { echo "checked out $(git -C "$src/fw" rev-parse HEAD), expected $SHA"; rm -rf "$src"; return 1; }
    git -C "$src/fw" cat-file -e "$FROM^{commit}" || { echo "clone lacks our version_sha $FROM"; rm -rf "$src"; return 1; }
    (cd "$src/fw" && env -u PROJECT_ROOT FRAMEWORK_ROOT="$src/fw" bin/fw upgrade /opt/832-Workflow-designer --allow-delete-locals)
    local rc=$?
    rm -rf "$src"
    [ "$rc" = 0 ] || { echo "fw upgrade exited $rc"; return 1; }
    [ "$(sed -n 's/^version_sha: *//p' .framework.yaml)" = "$SHA" ] || { echo ".framework.yaml version_sha is not $SHA after the upgrade"; return 1; }
    echo "VERSION now: $(tr -d '[:space:]' < .agentic-framework/VERSION)"
    bash tools/_t1000-install-hook.sh >/dev/null && bash tools/_t1000-install-hook.sh --check
}

do_pristine_commit() {
    git add -A -- .agentic-framework || return 1
    git reset -q HEAD -- "$DIV" .agentic-framework/.context/settings.yaml .agentic-framework/.context/sidecar 2>/dev/null
    if git diff --cached --name-only | grep -v '^\.agentic-framework/' | grep -q .; then
        echo "something outside .agentic-framework/ got staged; nothing committed"; return 1
    fi
    echo "committing $(git diff --cached --name-only | wc -l) vendored paths"
    git commit -q -m "T-1167: pristine vendor commit — AEF bleeding-edge 1146a7450 as fw upgrade wrote it (final G-114 fix T-4127; re-vendor protocol step 1, T-1000)" \
        -m "Vendored paths only, from commit $SHA, --allow-delete-locals (our local fixes re-applied next). Excluded: .vendor-divergence.yaml and runtime state."
}

do_baseline() {
    local p; p=$(git rev-parse HEAD)
    git show --name-only --format= HEAD | grep -q '^\.agentic-framework/' || { echo "HEAD is not the pristine commit"; return 1; }
    python3 - "$DIV" "$p" <<'PY' || return 1
import re, sys, yaml
path, sha = sys.argv[1:]
lines = open(path).read().split("\n")
out, skip = [], False
for ln in lines:
    if ln.startswith("baseline_note_previous:"):
        skip = True; continue
    if skip and (ln.startswith(" ") or ln == ""):
        continue
    skip = False
    out.append(ln)
s = "\n".join(out)
s, n = re.subn(r'^baseline_commit:.*$', 'baseline_commit: %s' % sha, s, count=1, flags=re.M)
if n != 1: sys.exit(1)
s, n = re.subn(r'^baseline_note:', 'baseline_note_previous:', s, count=1, flags=re.M)
if n != 1: sys.exit(1)
s = s.replace('baseline_commit: %s' % sha, 'baseline_commit: %s\nbaseline_note: "T-1167/T-1000 — pristine vendor commit of AEF bleeding-edge 1146a7450 (final G-114 fix; re-vendor protocol step 1). Every declared local fix the upgrade overwrote now shows STALE in tools/_t517; resolve each via tools/_t1000-revendor-worklist.py."' % sha, 1)
yaml.safe_load(s)
open(path, "w").write(s)
PY
    git add -- "$DIV" && git commit -q -m "T-1167: advance the divergence baseline to the pristine AEF 1146a7450 commit (re-vendor protocol step 2, T-1000)"
}

do_cron_check() {
    if grep -q '/tmp/' "$CRON"; then
        echo "crontab has /tmp/ paths; rewriting with the vendored fw"
        .agentic-framework/bin/fw cron install && ! grep -q '/tmp/' "$CRON"
    else
        echo "crontab ok: $(grep -c 'agentic-framework/bin/fw' "$CRON") framework job line(s), no /tmp/ paths"
    fi
}

do_restart() {
    .agentic-framework/bin/fw watchtower restart --port "$PORT" || return 1
    sleep 3
    local pid start newest
    pid=$(tr -d '[:space:]' < .context/working/watchtower.pid)
    start=$(date -d "$(ps -o lstart= -p "$pid")" +%s) || { echo "cannot read the start time of pid $pid"; return 1; }
    newest=$(find .agentic-framework/web -type f -printf '%T@\n' | sort -n | tail -1 | cut -d. -f1)
    [ "$start" -ge "$newest" ] || { echo "Watchtower pid $pid still predates .agentic-framework/web"; return 1; }
    curl -sf "$(.agentic-framework/bin/fw watchtower url)/" >/dev/null || { echo "Watchtower does not answer"; return 1; }
    echo "ok  Watchtower restarted (pid $pid), newer than its web code, answering at $(.agentic-framework/bin/fw watchtower url)"
}
