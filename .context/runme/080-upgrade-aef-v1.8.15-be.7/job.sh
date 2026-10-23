# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Upgrade AEF v1.8.15-be.5 (fea3e4c76) -> v1.8.15-be.7 (ce8075dba): be.6's fixes for three be.5 regressions (incl. review seats dying on first dispatch, T-4683) plus T-4684 dispatch-dir gitignore; re-vendor protocol; TermLink identity kept"
JOB_TASK="T-1280"
JOB_WHY="AEF cut pre-release v1.8.15-be.7 (commit ce8075dba, a lightweight tag) on OneDev and GitHub. It replaces job 079
(be.6, retired before it ran) and goes be.5 -> be.7 in one step. It carries be.6's fixes for three be.5 regressions:
- T-4683: the first codex/opencode/antigravity review seat died, so multi-seat reviewer panels cannot complete on be.5;
- T-4681: finalizing a partial-complete task with an empty Verification was refused;
- T-4682: tests spawned real termlink sessions.
It also brings:
- T-4677: plain-language business names on aef-task-lifecycle;
- T-4684: upgrade adds .context/dispatch/ to the consumer gitignore, from our be.5 report; our own line stays;
- T-4685 and T-4687: stricter project resolution.
AEF's known open issue T-4688 (upgrade writes into the clone it runs from) does not affect this job, which uses a
fresh clone each run. The steps are the same as job 078: clone to /var/tmp, doctor before and after, the upgrade, the
designer check, the pristine commit (naming T-1279), the baseline, the crontab and the templates. After the job, the
agent re-applies the local fixes, restarts Watchtower, runs the suite and reports WORKS/FAILS for be.5..be.7 together.
Nothing is pushed."

SHA=ce8075dba7a7f67ddf683da43a3e99691395da2c
FROM=fea3e4c761f991c2c7995b5f920aa52fc779cb81
TAG=v1.8.15-be.7
UPSTREAM=https://github.com/DimitriGeelen/agentic-engineering-framework.git
DIV=.agentic-framework/.vendor-divergence.yaml
CRON=/etc/cron.d/agentic-audit-832-workflow-designer
OUT=.context/runme/080-upgrade-aef-v1.8.15-be.7
KEY=/opt/832-Workflow-designer/.context/secrets/termlink-identity.key

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "no uncommitted edits under .agentic-framework/" 'git diff --quiet -- .agentic-framework'
    check "re-vendor gate installed (T-1000)" 'bash tools/_t1000-install-hook.sh --check'
    check "framework is v1.8.15-be.5 at fea3e4c76 (.framework.yaml version_sha)" '[ "$(sed -n "s/^version_sha: *//p" .framework.yaml)" = "$FROM" ]'
    check ".fwvendor-preserve.yaml committed as-is" 'git ls-files --error-unmatch .fwvendor-preserve.yaml && git diff --quiet -- .fwvendor-preserve.yaml'
    check "upstream tag $TAG is still ce8075dba (lightweight tag: no ^{} entry)" '[ "$(git ls-remote "$UPSTREAM" "refs/tags/$TAG" | cut -f1)" = "$SHA" ]'
    check "832 TermLink settings present before (settings env, .mcp.json env)" 'identity_settings_ok'
    check "room for the clone on disk (/var/tmp, at least 5G free)" '[ "$(df --output=avail -k /var/tmp | tail -1)" -gt 5242880 ]'
}

steps() {
    step "Capture fw doctor BEFORE" 'do_doctor before'
    step "Upgrade to $TAG (clone to /var/tmp, check out the tag commit, fw upgrade --allow-delete-locals with CONTEXT_DIR/TASKS_DIR cleared, re-install the re-vendor gate)" 'do_upgrade'
    step "Check the upgrade kept 832's TermLink key settings (settings env, .mcp.json env, RAIL_IDENTITY_FILE)" 'do_identity_check'
    step "Check the upgrade reinstalled the pinned designer (T-4672): fw designer says PRESENT" 'do_designer_check'
    step "Pristine commit: .agentic-framework/ exactly as the upgrade wrote it (message names T-1279)" 'do_pristine_commit'
    step "Advance the divergence baseline to that commit (commit it alone)" 'do_baseline'
    step "Check the crontab still points at the vendored framework" 'do_cron_check'
    step "Task templates the upgrade synced: commit the identical ones, name the rest (T-1192)" 'do_templates'
    step "Capture fw doctor AFTER" 'do_doctor after'
}

identity_settings_ok() {
    python3 - "$KEY" <<'PY'
import json, sys
k = sys.argv[1]
s = (json.load(open(".claude/settings.json")).get("env") or {}).get("TERMLINK_IDENTITY_FILE")
m = ((json.load(open(".mcp.json"))["mcpServers"].get("termlink") or {}).get("env") or {}).get("TERMLINK_IDENTITY_FILE")
ok = s == k and m == k
print("settings env: %s | .mcp.json env: %s" % (s, m))
sys.exit(0 if ok else 1)
PY
}

do_doctor() {
    .agentic-framework/bin/fw doctor > "$OUT/doctor-$1.txt" 2>&1
    echo "fw doctor $1: rc=$? — saved to $OUT/doctor-$1.txt ($(grep -c . "$OUT/doctor-$1.txt") lines)"
    return 0
}

do_upgrade() {
    local src
    src=$(mktemp -d /var/tmp/t1280-be7.XXXXXX) || return 1
    git clone -q "$UPSTREAM" "$src/fw" || { rm -rf "$src"; return 1; }
    git -C "$src/fw" -c advice.detachedHead=false checkout -q "$SHA" || { echo "commit $SHA not found upstream"; rm -rf "$src"; return 1; }
    [ "$(git -C "$src/fw" rev-parse HEAD)" = "$SHA" ] || { echo "checked out $(git -C "$src/fw" rev-parse HEAD), expected $SHA"; rm -rf "$src"; return 1; }
    git -C "$src/fw" merge-base --is-ancestor "$FROM" "$SHA" || { echo "$FROM is not an ancestor of $SHA"; rm -rf "$src"; return 1; }
    (cd "$src/fw" && env -u PROJECT_ROOT -u CONTEXT_DIR -u TASKS_DIR FRAMEWORK_ROOT="$src/fw" bin/fw upgrade /opt/832-Workflow-designer --allow-delete-locals)
    local rc=$?
    rm -rf "$src"
    [ "$rc" = 0 ] || { echo "fw upgrade exited $rc"; return 1; }
    [ "$(sed -n 's/^version_sha: *//p' .framework.yaml)" = "$SHA" ] || { echo ".framework.yaml version_sha is not $SHA after the upgrade"; return 1; }
    echo "VERSION now: $(tr -d '[:space:]' < .agentic-framework/VERSION)"
    bash tools/_t1000-install-hook.sh >/dev/null && bash tools/_t1000-install-hook.sh --check
}

do_identity_check() {
    identity_settings_ok || { echo "the upgrade changed 832's TermLink key settings; stop and tell the agent"; return 1; }
    local r
    r=$(sed -n 's/^RAIL_IDENTITY_FILE: *//p' .framework.yaml)
    [ "$r" = ".context/secrets/termlink-identity.key" ] || { echo "RAIL_IDENTITY_FILE is '$r'"; return 1; }
    echo "ok  RAIL_IDENTITY_FILE: $r"
}

do_designer_check() {
    # Report only: a NOT SYNCED here is a FAILS for AEF T-4672, not a reason to stop the upgrade.
    .agentic-framework/bin/fw designer 2>&1 | grep -E 'version|status'
    return 0
}

do_pristine_commit() {
    git add -A -- .agentic-framework || return 1
    git reset -q HEAD -- "$DIV" .agentic-framework/.context/settings.yaml .agentic-framework/.context/sidecar 2>/dev/null
    if git diff --cached --name-only | grep -v '^\.agentic-framework/' | grep -q .; then
        echo "something outside .agentic-framework/ got staged; nothing committed"; return 1
    fi
    echo "committing $(git diff --cached --name-only | wc -l) vendored paths; deletions: $(git diff --cached --name-status | awk '$1=="D"{print $2}' | tr '\n' ' ')"
    git commit -q -m "T-1280: pristine vendor commit (removes designer_open.html last committed by T-1279, our previous upgrade task; re-applied as a local fix next) — AEF v1.8.15-be.7 (ce8075dba) as fw upgrade wrote it (re-vendor protocol step 1, T-1000)" \
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
s = s.replace('baseline_commit: %s' % sha, 'baseline_commit: %s\nbaseline_note: "T-1280/T-1000 — pristine vendor commit of AEF v1.8.15-be.7 (ce8075dba; re-vendor protocol step 1). Every declared local fix the upgrade overwrote now shows STALE in tools/_t517; resolve each via tools/_t1000-revendor-worklist.py."' % sha, 1)
yaml.safe_load(s)
open(path, "w").write(s)
PY
    git add -- "$DIV" && git commit -q -m "T-1280: advance the divergence baseline to the pristine AEF v1.8.15-be.7 commit (re-vendor protocol step 2, T-1000)"
}

do_cron_check() {
    if grep -q '/tmp/' "$CRON"; then
        echo "crontab has /tmp/ paths; rewriting with the vendored fw"
        .agentic-framework/bin/fw cron install && ! grep -q '/tmp/' "$CRON"
    else
        echo "crontab ok: $(grep -c 'agentic-framework/bin/fw' "$CRON") framework job line(s), no /tmp/ paths"
    fi
}

do_templates() {
    bash tools/_t1192-upgrade-templates.sh --commit --task T-1280
    local rc=$?
    [ "$rc" = 1 ] && { echo "some templates need a person: the agent settles them next (listed above)"; return 0; }
    return "$rc"
}
