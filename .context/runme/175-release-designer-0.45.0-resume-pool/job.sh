# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Release 0.45.0, resumed (third time) with your option 1: the browser tier on the pool alone, split (T-1467).
# All three steps reach the pool or origin, so all are `step_outward`. Commits: none.
JOB_TITLE="Release designer 0.45.0: browser tier on the pool (4 shards), core tier, push bleeding-edge and designer-v0.45.0"
JOB_TASK="T-1466"
JOB_WHY="You chose option 1: the release's browser tier on the pool, split, instead of on this machine. Jobs 173 and 174
each stopped on one test whose Chrome did not start here (a busy desktop host; 150 passed, 1 failed each time; not a
test result). Done before this: VERSION 0.45.0, both kit calibrations PASS, the release commit 0d7157263 and the tag
designer-v0.45.0 on it (local). Since then bleeding-edge gained the full split (T-1467) and two retire markers; the
designer file is the same as in the release commit (the preflight checks it). Step 1 runs the browser tier on the pool:
4 shards on pool-w1 and pool-w2 (about 6-12 min), the unsplit shadow on pool-132; red or no result stops the job and
nothing is pushed. Step 2: core (pool and here, about 20 min). Step 3: push bleeding-edge and the tag. Answer y."

V=0.45.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V and committed (job 173)" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ] && git diff --quiet HEAD -- VERSION'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "$ART is committed and equals src (the designer the pool tests is the released one)" 'git ls-files --error-unmatch "$ART" >/dev/null && cmp -s src/aef-workflow-designer.html "$ART" && git diff --quiet HEAD -- src/aef-workflow-designer.html'
    check "tag $TAG exists locally, on the commit that carries $ART" '[ "$(git rev-parse -q --verify "refs/tags/$TAG^{commit}")" = "$(git log -1 --format=%H -- "$ART")" ]'
    check "tag $TAG is not on origin yet" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "the split gate is in (T-1467: T1467_POOL_ONLY and tools/pool/workers)" 'grep -q T1467_POOL_ONLY tools/pool/tier-gate.sh && grep -q "^browser_shards=" tools/pool/workers'
    check "the index holds nothing staged (T-1313)" '[ -z "$(git diff --cached --name-only)" ]'
}

steps() {
    step_outward "Browser tier on the pool, 4 shards (T1467_POOL_ONLY=1; about 6-12 min): stops here if red or no result, nothing pushed" 'do_browser'
    step_outward "Core tier (pool and here, about 20 minutes), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_browser() {
    PATH="$NODEBIN:$PATH" T1467_POOL_ONLY=1 bash tools/pool/tier-gate.sh browser || { echo "browser tier RED or no pool result (build/tiergate/tier-browser.runs.log); nothing pushed — the agent brings it to you"; return 1; }
    echo "ok  browser tier green on the pool (split)"
}

do_core() {
    PATH="$NODEBIN:$PATH" bash tools/_t1288-prepush-gate.sh || { echo "core tier RED (see .context/working/prepush-core.log); nothing pushed — the agent brings it to you"; return 1; }
    echo "ok  core tier green for this tree; the push hook will find it cached"
}

do_push() {
    git push origin bleeding-edge || { echo "push of bleeding-edge failed"; return 1; }
    git push origin "$TAG" || { echo "push of $TAG failed"; return 1; }
    echo "DONE: release $V committed, tagged $TAG, browser (pool, split) and core tiers green, pushed."
}
