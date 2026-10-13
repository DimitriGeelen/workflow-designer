# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Finish the AEF 1146a7450 upgrade: steps 4-7 of job 023 (baseline, crontab, doctor after, Watchtower restart)"
JOB_TASK="T-1167"
JOB_WHY="Job 023 ran steps 1-3: the framework is upgraded to bleeding-edge 1146a7450 and committed as pristine (40b8e12c).
Step 4 was not confirmed, so it stopped there; the re-run was rightly refused, because its preflight expects the
old framework. This job continues from step 4 with checks for the state 023 left: HEAD is the pristine commit and
the framework is 1146a7450. Steps: advance the divergence baseline to 40b8e12c (one commit, that file only);
check the crontab; capture fw doctor after; restart Watchtower on the new code. Nothing is pushed.
Afterwards the agent re-applies our local fixes and re-runs AEF's decision-revert scan."

SHA=1146a745045ee204701419c4ac172030a1ef88a1
PRISTINE=40b8e12c
DIV=.agentic-framework/.vendor-divergence.yaml
CRON=/etc/cron.d/agentic-audit-832-workflow-designer
OUT=.context/runme/024-upgrade-aef-1146a7450-finish
PORT=3013

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "framework is 1146a7450 (.framework.yaml version_sha)" '[ "$(sed -n "s/^version_sha: *//p" .framework.yaml)" = "$SHA" ]'
    check "the pristine commit 40b8e12c is in history and touched .agentic-framework/" 'git merge-base --is-ancestor $PRISTINE HEAD && git show --name-only --format= $PRISTINE | grep -q "^\.agentic-framework/"'
    check "no uncommitted edits under .agentic-framework/ (besides the divergence file)" 'git diff --quiet -- .agentic-framework ":!$DIV"'
    check "the divergence baseline is not yet advanced" '! grep -q "^baseline_commit: $(git rev-parse $PRISTINE)" "$DIV"'
}

steps() {
    step "Advance the divergence baseline to the pristine commit 40b8e12c (commit that file alone)" 'do_baseline'
    step "Check the crontab still points at the vendored framework" 'do_cron_check'
    step "Capture fw doctor AFTER" 'do_doctor after'
    step "Restart Watchtower on port $PORT, then check it is newer than its web code and answering" 'do_restart'
}

do_doctor() {
    .agentic-framework/bin/fw doctor > "$OUT/doctor-$1.txt" 2>&1
    echo "fw doctor $1: rc=$? — saved to $OUT/doctor-$1.txt ($(grep -c . "$OUT/doctor-$1.txt") lines)"
    return 0
}

do_baseline() {
    local p; p=$(git rev-parse $PRISTINE)
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
    git add -- "$DIV" && git commit -q -m "T-1167: advance the divergence baseline to the pristine AEF 1146a7450 commit (re-vendor protocol step 2, T-1000)" -- "$DIV"
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
