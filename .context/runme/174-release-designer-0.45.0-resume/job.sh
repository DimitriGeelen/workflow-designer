# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Job 173's last three steps (browser tier, core tier, push), with job 173's own step code. Every step needs Chrome,
# local servers or origin, so all three are `step_outward`. Commits: none (job 173 made the release commit and the tag).
JOB_TITLE="Release designer 0.45.0, resumed after the browser tier: browser tier, core tier, push bleeding-edge and designer-v0.45.0"
JOB_TASK="T-1466"
JOB_WHY="Job 173 stopped at its step 8, the browser tier: 150 passed, 1 failed, and the failure was not a test result:
in the notes harness (_t1447) Chrome did not start ('CDP ATTACH FAILED ... the code under test was never reached'),
the infrastructure class logged in build/tiergate/rerun-notes.log. Everything before it is done: VERSION 0.45.0,
both kit calibrations PASS (codex, GLM-5.3), the release cut and committed (0d7157263), tag designer-v0.45.0 on that
commit, local only. Nothing was pushed. This job runs the browser tier again (about 25 min; stops if red, nothing
pushed), then core (about 20 min, or cached), then pushes bleeding-edge and the tag. Answer y at every step."

V=0.45.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
OUT=.context/runme/174-release-designer-0.45.0-resume
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V and committed (job 173)" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ] && git diff --quiet HEAD -- VERSION'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "$ART is committed and equals src" 'git ls-files --error-unmatch "$ART" >/dev/null && cmp -s src/aef-workflow-designer.html "$ART"'
    check "tag $TAG exists locally, on the commit that carries $ART" '[ "$(git rev-parse -q --verify "refs/tags/$TAG^{commit}")" = "$(git log -1 --format=%H -- "$ART")" ]'
    check "tag $TAG is not on origin yet" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "the index holds nothing staged (T-1313)" '[ -z "$(git diff --cached --name-only)" ]'
    check "/tmp has at least 4 GB free" '[ "$(df --output=avail -k /tmp | tail -1)" -gt 4194304 ]'
}

steps() {
    step_outward "Browser tier (about 25 minutes; T-1374): stops here if red, and nothing is pushed" 'do_browser'
    step_outward "Core tier (about 20 minutes, or cached), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_browser() {
    local log="$OUT/browser-tier.log"
    PATH="$NODEBIN:$PATH" bash tests/run-bridge-tests.sh --tier browser > "$log" 2>&1
    local rc=$?
    grep -E '^tier browser|\[FAIL\]' "$log" | cut -c1-300
    [ "$rc" = 0 ] || { echo "browser tier RED (full output: $log); nothing pushed, the tag is local only — the agent brings it to you"; return 1; }
    echo "ok  browser tier green on the release tree"
}

do_core() {
    PATH="$NODEBIN:$PATH" bash tools/_t1288-prepush-gate.sh || { echo "core tier RED (see .context/working/prepush-core.log); nothing pushed — the agent brings it to you"; return 1; }
    echo "ok  core tier green for this tree; the push hook will find it cached"
}

do_push() {
    git push origin bleeding-edge || { echo "push of bleeding-edge failed"; return 1; }
    git push origin "$TAG" || { echo "push of $TAG failed"; return 1; }
    echo "DONE: release $V committed, tagged $TAG, browser and core tiers green, pushed."
}
