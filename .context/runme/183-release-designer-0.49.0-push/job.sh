# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Release 0.49.0, last two steps of job 182 (core tier, push), with job 178's step code (the same as job 182's). Both
# reach the pool or origin, so both are `step_outward`. Commits: none (job 182 made the release commit and the tag).
JOB_TITLE="Release designer 0.49.0, resumed: core tier, push bleeding-edge and designer-v0.49.0"
JOB_TASK="T-1512"
JOB_WHY="Job 182 did steps 1-8: both reviewers calibrated the kit (PASS), the release was cut, committed (e9a85518f)
and tagged designer-v0.49.0 locally, and the browser tier was green on the pool (168/168). It stopped at step 9 because
the prompt received an empty Enter (10 characters typed before the prompt were discarded, by design). Nothing was
pushed. This job runs the two steps left. Step 1: core tier (about 10-15 minutes, or seconds if cached). Step 2: push
bleeding-edge and the tag. Wait for each [y/N] prompt before typing y. Afterwards the agent tells AEF and Greenfield."

V=0.49.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V and committed" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ] && git diff --quiet HEAD -- VERSION'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "$ART is committed and equals src (the designer tested is the released one)" 'git ls-files --error-unmatch "$ART" >/dev/null && cmp -s src/aef-workflow-designer.html "$ART" && git diff --quiet HEAD -- src/aef-workflow-designer.html'
    check "tag $TAG exists locally, on the commit that carries $ART" '[ "$(git rev-parse -q --verify "refs/tags/$TAG^{commit}")" = "$(git log -1 --format=%H -- "$ART")" ]'
    check "tag $TAG is not on origin yet" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "the release notes' shared-contracts table agrees with what moved (the leg that stopped job 177)" 'python3 tools/_t1425-shared-contracts.py --check >/dev/null 2>&1'
    check "the index holds nothing staged (T-1313)" '[ -z "$(git diff --cached --name-only)" ]'
}

steps() {
    step_outward "Core tier (cached green for this tree: seconds), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
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
