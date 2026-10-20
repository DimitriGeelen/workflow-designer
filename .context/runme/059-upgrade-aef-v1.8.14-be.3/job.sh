# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Upgrade AEF v1.8.12 -> v1.8.14-be.3 (pinned pre-release, 346c4ed33): AEF's fixes for 832 T-4399, T-4421, T-3924, T-4454 and T-4469; re-vendor protocol; TermLink identity kept"
JOB_TASK="T-1225"
JOB_WHY="AEF has cut pinned pre-release v1.8.14-be.3 (tag 346c4ed33, base v1.8.13). It holds everything in be.2, the
four fixes we reported (T-4399 corpus_spec keeps the BPMN default attribute, T-4421 fw fabric register reads .mjs
headers, T-3924 fw config set writes the key the commit hook reads, T-4454 claude-fw registers this session with 832's
own TermLink key), PLUS T-4469: a reviewer's verdict-only commit is no longer refused by the inception gates. That
refusal is what blocks our push today; after this upgrade the agent acknowledges the stuck row against this task, as
AEF ruled. Checked on the GitHub mirror: be.2 (c80a8261d) and v1.8.12 are its ancestors, the T-4469 commit aaa3876f8 is
in it, and its hooks.sh carries the exemption. This replaces job 057 (be.2, retired). Same re-vendor protocol: doctor
before and after, pristine vendor commit, divergence baseline, the usual local framework fixes re-applied by the agent
afterwards. Watchtower is NOT restarted. Nothing is pushed. T-4454 takes effect for a session started through claude-fw
after this upgrade."

SHA=346c4ed330ff14afc60d215ea9b117efe94489cc
FROM=ee1d6fcfe6d6758156b74c82c083ae5e5ca2ff66
UPSTREAM=https://github.com/DimitriGeelen/agentic-engineering-framework.git
DIV=.agentic-framework/.vendor-divergence.yaml
CRON=/etc/cron.d/agentic-audit-832-workflow-designer
OUT=.context/runme/059-upgrade-aef-v1.8.14-be.3
KEY=/opt/832-Workflow-designer/.context/secrets/termlink-identity.key

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "no uncommitted edits under .agentic-framework/" 'git diff --quiet -- .agentic-framework'
    check "re-vendor gate installed (T-1000)" 'bash tools/_t1000-install-hook.sh --check'
    check "framework is v1.8.12 (.framework.yaml version_sha)" '[ "$(sed -n "s/^version_sha: *//p" .framework.yaml)" = "$FROM" ]'
    check ".fwvendor-preserve.yaml committed as-is" 'git ls-files --error-unmatch .fwvendor-preserve.yaml && git diff --quiet -- .fwvendor-preserve.yaml'
    check "upstream tag v1.8.14-be.3 is still 346c4ed33" '[ "$(git ls-remote "$UPSTREAM" "refs/tags/v1.8.14-be.3^{}" "refs/tags/v1.8.14-be.3" | tail -1 | cut -f1)" = "$SHA" ] || [ "$(git ls-remote "$UPSTREAM" "refs/tags/v1.8.14-be.3^{}" | cut -f1)" = "$SHA" ]'
    check "832 TermLink settings present before (settings env, .mcp.json env)" 'identity_settings_ok'
}

steps() {
    step "Capture fw doctor BEFORE" 'do_doctor before'
    step "Upgrade to v1.8.14-be.3 (clone, check out the tag commit, fw upgrade --allow-delete-locals, re-install the re-vendor gate)" 'do_upgrade'
    step "Check the upgrade kept 832's TermLink key settings (settings env, .mcp.json env, RAIL_IDENTITY_FILE)" 'do_identity_check'
    step "Pristine commit: .agentic-framework/ exactly as the upgrade wrote it" 'do_pristine_commit'
    step "Advance the divergence baseline to that commit (commit it alone)" 'do_baseline'
    step "Check the crontab still points at the vendored framework" 'do_cron_check'
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
    src=$(mktemp -d /tmp/t1225-be2.XXXXXX) || return 1
    git clone -q "$UPSTREAM" "$src/fw" || { rm -rf "$src"; return 1; }
    git -C "$src/fw" -c advice.detachedHead=false checkout -q "$SHA" || { echo "commit $SHA not found upstream"; rm -rf "$src"; return 1; }
    [ "$(git -C "$src/fw" rev-parse HEAD)" = "$SHA" ] || { echo "checked out $(git -C "$src/fw" rev-parse HEAD), expected $SHA"; rm -rf "$src"; return 1; }
    git -C "$src/fw" merge-base --is-ancestor "$FROM" "$SHA" || { echo "$FROM is not an ancestor of $SHA"; rm -rf "$src"; return 1; }
    (cd "$src/fw" && env -u PROJECT_ROOT FRAMEWORK_ROOT="$src/fw" bin/fw upgrade /opt/832-Workflow-designer --allow-delete-locals)
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

do_pristine_commit() {
    git add -A -- .agentic-framework || return 1
    git reset -q HEAD -- "$DIV" .agentic-framework/.context/settings.yaml .agentic-framework/.context/sidecar 2>/dev/null
    if git diff --cached --name-only | grep -v '^\.agentic-framework/' | grep -q .; then
        echo "something outside .agentic-framework/ got staged; nothing committed"; return 1
    fi
    echo "committing $(git diff --cached --name-only | wc -l) vendored paths"
    git commit -q -m "T-1225: pristine vendor commit — AEF v1.8.14-be.3 (346c4ed33) as fw upgrade wrote it (re-vendor protocol step 1, T-1000)" \
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
s = s.replace('baseline_commit: %s' % sha, 'baseline_commit: %s\nbaseline_note: "T-1225/T-1000 — pristine vendor commit of AEF v1.8.14-be.3 (346c4ed33; re-vendor protocol step 1). Every declared local fix the upgrade overwrote now shows STALE in tools/_t517; resolve each via tools/_t1000-revendor-worklist.py."' % sha, 1)
yaml.safe_load(s)
open(path, "w").write(s)
PY
    git add -- "$DIV" && git commit -q -m "T-1225: advance the divergence baseline to the pristine AEF v1.8.14-be.3 commit (re-vendor protocol step 2, T-1000)"
}

do_cron_check() {
    if grep -q '/tmp/' "$CRON"; then
        echo "crontab has /tmp/ paths; rewriting with the vendored fw"
        .agentic-framework/bin/fw cron install && ! grep -q '/tmp/' "$CRON"
    else
        echo "crontab ok: $(grep -c 'agentic-framework/bin/fw' "$CRON") framework job line(s), no /tmp/ paths"
    fi
}
