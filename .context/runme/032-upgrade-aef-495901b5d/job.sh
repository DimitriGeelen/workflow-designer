# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Upgrade AEF bleeding-edge 1146a7450 -> 495901b5d (v1.8.11 field test + fw audit --check), re-vendor protocol"
JOB_TASK="T-1185"
JOB_WHY="Your 'yes, prepare the upgrade' (2026-10-16). AEF asked 832 to field-test their v1.8.11 candidate (a75c25472,
14 items; a positive test from another project is their release approval), and has since pushed T-4209
(fw audit --check), which lets our four slow audit probes run in seconds (T-1184). 495901b5d is the upstream
bleeding-edge tip: 133 commits past ours, with both of those as ancestors (checked). Same protocol as job 023:
fw doctor captured first; pristine vendor commit (--allow-delete-locals, backups kept); divergence baseline advanced;
crontab checked; fw doctor after; then Watchtower is restarted on the new code (down a few seconds; reload any open
page). The agent then re-applies our local fixes, re-runs the revert scan and runs the field-test items.
Nothing is pushed. Afterwards: relaunch claude-fw at a natural break (a running wrapper keeps the old code)."

SHA=495901b5db6081b31605e84c620326978cc2d7c4
FROM=1146a745045ee204701419c4ac172030a1ef88a1
UPSTREAM=https://github.com/DimitriGeelen/agentic-engineering-framework.git
DIV=.agentic-framework/.vendor-divergence.yaml
CRON=/etc/cron.d/agentic-audit-832-workflow-designer
OUT=.context/runme/032-upgrade-aef-495901b5d
PORT=3013

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "no uncommitted edits under .agentic-framework/" 'git diff --quiet -- .agentic-framework'
    check "re-vendor gate installed (T-1000)" 'bash tools/_t1000-install-hook.sh --check'
    check "framework is 1146a7450 (.framework.yaml version_sha)" '[ "$(sed -n "s/^version_sha: *//p" .framework.yaml)" = "$FROM" ]'
    check ".fwvendor-preserve.yaml committed as-is" 'git ls-files --error-unmatch .fwvendor-preserve.yaml && git diff --quiet -- .fwvendor-preserve.yaml'
    check "upstream still has 495901b5d" 'git ls-remote "$UPSTREAM" refs/heads/bleeding-edge | grep -q "^$SHA" || git ls-remote "$UPSTREAM" | grep -q "^$SHA"'
}

steps() {
    step "Capture fw doctor BEFORE" 'do_doctor before'
    step "Upgrade to 495901b5d (clone, check out the pinned commit, fw upgrade --allow-delete-locals, re-install the re-vendor gate)" 'do_upgrade'
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
    src=$(mktemp -d /tmp/t1185-aef.XXXXXX) || return 1
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
    git commit -q -m "T-1185: pristine vendor commit — AEF bleeding-edge 495901b5d as fw upgrade wrote it (v1.8.11 field test + T-4209 audit --check; re-vendor protocol step 1, T-1000)" \
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
s = s.replace('baseline_commit: %s' % sha, 'baseline_commit: %s\nbaseline_note: "T-1185/T-1000 — pristine vendor commit of AEF bleeding-edge 495901b5d (v1.8.11 field test + T-4209; re-vendor protocol step 1). Every declared local fix the upgrade overwrote now shows STALE in tools/_t517; resolve each via tools/_t1000-revendor-worklist.py."' % sha, 1)
yaml.safe_load(s)
open(path, "w").write(s)
PY
    git add -- "$DIV" && git commit -q -m "T-1185: advance the divergence baseline to the pristine AEF 495901b5d commit (re-vendor protocol step 2, T-1000)"
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
