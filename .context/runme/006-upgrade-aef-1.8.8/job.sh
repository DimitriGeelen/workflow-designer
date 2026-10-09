# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Upgrade the framework: AEF 1.8.6 -> 1.8.8, through the re-vendor protocol"
JOB_TASK="T-1104"
JOB_WHY="AEF 1.8.8 (released 2026-10-09; supersedes 1.8.7, which this job targeted before it ran) carries
the 1.8.7 security fix (T-3984: claude-fw no longer resolves the framework from the current directory),
the budget-critical auto-handover fixes (T-3989/T-3997/T-4004), T-3986 (reviewer seats may answer
not-evaluated; lets us re-judge the AMBER rows on T-1082/T-310/T-893), T-3998 (hooks redeployed when their
content changes) and T-4008. Same protocol as the 1.8.6 upgrade (job 004): step 1 uses
--allow-delete-locals so the vendor writes pristine 1.8.8 (backups kept), and the agent re-applies our
local framework fixes from the divergence register afterwards. Pinned to tag v1.8.8 = commit f0fc5839.
Nothing is pushed. Step 2 may sit several minutes in the post-commit hook; the commit has landed by then."

TAG=v1.8.8
TAG_SHA=f0fc5839396060b7ea447e7a933e794c4866716d
UPSTREAM=https://github.com/DimitriGeelen/agentic-engineering-framework.git
DIV=.agentic-framework/.vendor-divergence.yaml
CRON=/etc/cron.d/agentic-audit-832-workflow-designer

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "no uncommitted edits under .agentic-framework/" 'git diff --quiet -- .agentic-framework'
    check "re-vendor gate installed (T-1000)" 'bash tools/_t1000-install-hook.sh --check'
    check "framework is 1.8.6 in HEAD and working tree" '[ "$(git show HEAD:.agentic-framework/VERSION | tr -d "[:space:]")" = 1.8.6 ] && [ "$(tr -d "[:space:]" < .agentic-framework/VERSION)" = 1.8.6 ]'
    check ".fwvendor-preserve.yaml committed as-is" 'git ls-files --error-unmatch .fwvendor-preserve.yaml && git diff --quiet -- .fwvendor-preserve.yaml'
}

steps() {
    step "Upgrade to $TAG (clone pinned commit, fw upgrade --allow-delete-locals, re-install the re-vendor gate)" 'do_upgrade'
    step "Pristine commit: .agentic-framework/ exactly as the upgrade wrote it" 'do_pristine_commit'
    step "Advance the divergence baseline to that commit (commit it alone)" 'do_baseline'
    step "Check the crontab still points at the vendored framework" 'do_cron_check'
}

do_upgrade() {
    local src
    src=$(mktemp -d /tmp/t1104-aef188.XXXXXX) || return 1
    git -c advice.detachedHead=false clone -q --branch "$TAG" "$UPSTREAM" "$src/fw" || { rm -rf "$src"; return 1; }
    [ "$(git -C "$src/fw" rev-parse HEAD)" = "$TAG_SHA" ] || { echo "$TAG moved: now $(git -C "$src/fw" rev-parse HEAD), expected $TAG_SHA"; rm -rf "$src"; return 1; }
    git -C "$src/fw" cat-file -e "$(sed -n 's/^version_sha: *//p' .framework.yaml)^{commit}" || { echo "clone lacks our version_sha"; rm -rf "$src"; return 1; }
    (cd "$src/fw" && env -u PROJECT_ROOT FRAMEWORK_ROOT="$src/fw" bin/fw upgrade /opt/832-Workflow-designer --allow-delete-locals)
    local rc=$?
    rm -rf "$src"
    [ "$rc" = 0 ] || { echo "fw upgrade exited $rc"; return 1; }
    [ "$(tr -d '[:space:]' < .agentic-framework/VERSION)" = 1.8.8 ] || { echo "VERSION is not 1.8.8 after the upgrade"; return 1; }
    bash tools/_t1000-install-hook.sh >/dev/null && bash tools/_t1000-install-hook.sh --check
}

do_pristine_commit() {
    git add -A -- .agentic-framework || return 1
    git reset -q HEAD -- "$DIV" .agentic-framework/.context/settings.yaml .agentic-framework/.context/sidecar 2>/dev/null
    if git diff --cached --name-only | grep -v '^\.agentic-framework/' | grep -q .; then
        echo "something outside .agentic-framework/ got staged; nothing committed"; return 1
    fi
    echo "committing $(git diff --cached --name-only | wc -l) vendored paths"
    git commit -q -m "T-1104: pristine vendor commit — AEF 1.8.8 as fw upgrade wrote it (re-vendor protocol step 1, T-1000)" \
        -m "Vendored paths only, from tag $TAG ($TAG_SHA), --allow-delete-locals (our local fixes re-applied in step 3). Excluded: .vendor-divergence.yaml and runtime state."
}

do_baseline() {
    local p; p=$(git rev-parse HEAD)
    git show --name-only --format= HEAD | grep -qx '.agentic-framework/VERSION' || { echo "HEAD is not the pristine commit"; return 1; }
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
s = s.replace('baseline_commit: %s' % sha, 'baseline_commit: %s\nbaseline_note: "T-1104/T-1000 — pristine vendor commit of AEF 1.8.8 (re-vendor protocol step 1). Every declared local fix the upgrade overwrote now shows STALE in tools/_t517; resolve each via tools/_t1000-revendor-worklist.py."' % sha, 1)
yaml.safe_load(s)
open(path, "w").write(s)
PY
    git add -- "$DIV" && git commit -q -m "T-1104: advance the divergence baseline to the pristine AEF 1.8.8 commit (re-vendor protocol step 2, T-1000)"
}

do_cron_check() {
    if grep -q '/tmp/' "$CRON"; then
        echo "crontab has /tmp/ paths; rewriting with the vendored fw"
        .agentic-framework/bin/fw cron install && ! grep -q '/tmp/' "$CRON"
    else
        echo "crontab ok: $(grep -c 'agentic-framework/bin/fw' "$CRON") framework job line(s), no /tmp/ paths"
    fi
}
