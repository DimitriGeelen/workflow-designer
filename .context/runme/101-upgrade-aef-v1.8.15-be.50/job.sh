# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Same steps as job 100 (T-1319, be.45 -> be.48, rc=0), one release candidate on.
JOB_TITLE="Upgrade AEF v1.8.15-be.48 (a936776c7) -> v1.8.15-be.50 (370b2688b): AEF's release candidate field test"
JOB_TASK="T-1334"
JOB_WHY="AEF asks testers to upgrade to v1.8.15-be.50, the release candidate (msg 5f015110): be.49 plus four fixes
(T-4875 suite flake retry, T-4880 per-addressee peer-mail alerts, T-4881 config parity, T-4883 a test flake). Three
clean be.50 upgrades release v1.8.15. They ask for a full upgrade from a non-shallow clone, fw doctor before and after,
our own test run before and after, and whether fw sidecar alerts runs cleanly. be.50 is an ANNOTATED tag (b7170b8f8)
on commit 370b2688b. Our tree before: core tier at the T-1331 commit. Steps as job 100. After the job the agent
re-applies 832's local fixes, runs the core tier and sends AEF the report. Nothing is pushed by this job."

SHA=370b2688bf75624f77a2519e66f1c57240cf2ba3
FROM=a936776c70b42a3d10e9ba1acef08fc2c0eaf38f
TAG=v1.8.15-be.50
UPSTREAM=https://github.com/DimitriGeelen/agentic-engineering-framework.git
DIV=.agentic-framework/.vendor-divergence.yaml
CRON=/etc/cron.d/agentic-audit-832-workflow-designer
OUT=.context/runme/101-upgrade-aef-v1.8.15-be.50
KEY=/opt/832-Workflow-designer/.context/secrets/termlink-identity.key

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "no uncommitted edits under .agentic-framework/ or in .framework.yaml" 'git diff --quiet -- .agentic-framework .framework.yaml'
    check "re-vendor gate installed (T-1000)" 'bash tools/_t1000-install-hook.sh --check'
    check "framework is v1.8.15-be.48 at a936776c7 (.framework.yaml version_sha)" '[ "$(sed -n "s/^version_sha: *//p" .framework.yaml)" = "$FROM" ]'
    check ".fwvendor-preserve.yaml committed as-is" 'git ls-files --error-unmatch .fwvendor-preserve.yaml && git diff --quiet -- .fwvendor-preserve.yaml'
    check "upstream tag $TAG still peels to 370b2688b (annotated tag: compare the ^{} entry)" '[ "$(git ls-remote "$UPSTREAM" "refs/tags/$TAG^{}" | cut -f1)" = "$SHA" ]'
    check "832 TermLink settings present before (settings env, .mcp.json env)" 'identity_settings_ok'
    check "room for the clone on disk (/var/tmp, at least 5G free)" '[ "$(df --output=avail -k /var/tmp | tail -1)" -gt 5242880 ]'
}

steps() {
    step "Capture fw doctor BEFORE" 'do_doctor before'
    step "Upgrade to $TAG (full clone to /var/tmp, check out the tag commit, fw upgrade --allow-delete-locals with CONTEXT_DIR/TASKS_DIR cleared, re-install the re-vendor gate)" 'do_upgrade'
    step "Check the upgrade kept 832's TermLink key settings (settings env, .mcp.json env, RAIL_IDENTITY_FILE)" 'do_identity_check'
    step "Check the upgrade reinstalled the pinned designer: fw designer says PRESENT" 'do_designer_check'
    step "Pristine commit: .agentic-framework/ exactly as the upgrade wrote it (names the owners of deleted paths)" 'do_pristine_commit'
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
    local src here="$PWD"   # the project the step runs in: the repo for real, the clone in a rehearsal (job 092's fix)
    src=$(mktemp -d /var/tmp/t1334-be50.XXXXXX) || return 1
    git clone -q "$UPSTREAM" "$src/fw" || { rm -rf "$src"; return 1; }   # full (non-shallow) clone, as AEF asks
    git -C "$src/fw" -c advice.detachedHead=false checkout -q "$SHA" || { echo "commit $SHA not found upstream"; rm -rf "$src"; return 1; }
    [ "$(git -C "$src/fw" rev-parse HEAD)" = "$SHA" ] || { echo "checked out $(git -C "$src/fw" rev-parse HEAD), expected $SHA"; rm -rf "$src"; return 1; }
    git -C "$src/fw" merge-base --is-ancestor "$FROM" "$SHA" || { echo "$FROM is not an ancestor of $SHA"; rm -rf "$src"; return 1; }
    (cd "$src/fw" && env -u PROJECT_ROOT -u CONTEXT_DIR -u TASKS_DIR FRAMEWORK_ROOT="$src/fw" bin/fw upgrade "$here" --allow-delete-locals)
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
    # Report only: a NOT SYNCED here is a FAILS for AEF, not a reason to stop the upgrade.
    .agentic-framework/bin/fw designer 2>&1 | grep -E 'version|status'
    return 0
}

do_pristine_commit() {
    local owners
    git add -A -- .agentic-framework || return 1
    git reset -q HEAD -- "$DIV" .agentic-framework/.context/settings.yaml .agentic-framework/.context/sidecar 2>/dev/null
    if git diff --cached --name-only | grep -v '^\.agentic-framework/' | grep -q .; then
        echo "something outside .agentic-framework/ got staged; nothing committed"; return 1
    fi
    # the tasks that last committed each path this commit deletes (our local fixes, re-applied next)
    owners=$(git diff --cached --name-status | awk '$1=="D"{print $2}' | while read -r p; do git log -1 --format=%s -- "$p"; done \
             | grep -oE '^T-[0-9]+' | sort -u | tr '\n' ' ')
    echo "committing $(git diff --cached --name-only | wc -l) vendored paths; deletions: $(git diff --cached --name-status | awk '$1=="D"{print $2}' | tr '\n' ' ')"
    git commit -q -m "T-1334: pristine vendor commit — AEF v1.8.15-be.50 (370b2688b) as fw upgrade wrote it (re-vendor protocol step 1, T-1000)" \
        -m "Vendored paths only, from commit $SHA, --allow-delete-locals (our local fixes re-applied next). Excluded: .vendor-divergence.yaml and runtime state.${owners:+ Deletes local-fix paths last committed by: $owners}"
    # deliberately NO pathspec here: \`git commit -- .agentic-framework\` would commit the working-tree state of every path
    # under it, including the divergence file and runtime state just unstaged. The index is the source, and the check above
    # proved it holds only .agentic-framework/ paths.
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
s = s.replace('baseline_commit: %s' % sha, 'baseline_commit: %s\nbaseline_note: "T-1334/T-1000 — pristine vendor commit of AEF v1.8.15-be.50 (370b2688b; re-vendor protocol step 1). Every declared local fix the upgrade overwrote now shows STALE in tools/_t517; resolve each via tools/_t1000-revendor-worklist.py."' % sha, 1)
yaml.safe_load(s)
open(path, "w").write(s)
PY
    git add -- "$DIV" .framework.yaml && git commit -q -m "T-1334: advance the divergence baseline to the pristine AEF v1.8.15-be.50 commit, and record the upgrade in .framework.yaml (re-vendor protocol step 2, T-1000)" -- "$DIV" .framework.yaml
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
    bash tools/_t1192-upgrade-templates.sh --commit --task T-1334
    local rc=$?
    [ "$rc" = 1 ] && { echo "some templates need a person: the agent settles them next (listed above)"; return 0; }
    return "$rc"
}
