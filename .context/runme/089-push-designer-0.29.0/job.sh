# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
JOB_TITLE="Finish release 0.29.0: core tier, then push bleeding-edge and designer-v0.29.0 (088 stopped at its step 8)"
JOB_TASK="T-1311"
JOB_WHY="Job 088 cut, committed and tagged 0.29.0, then stopped at step 8: the core tier was red on _t1066, because my
close attempt on T-1304 had withdrawn its reviewer verdict (stale-review) and left a [REVIEW] criterion without a
**Why you:** line. That criterion is now written for the reviewer (commit 5f89f36d) and _t1066 is green. This job
runs the core tier again and pushes the branch and the tag; nothing is cut or tagged again."

V=0.29.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "tag $TAG exists locally on the commit that carries $ART" '[ "$(git rev-parse "$TAG^{commit}")" = "$(git log -1 --format=%H -- "$ART")" ]'
    check "tag $TAG is not on origin yet" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "$ART equals src (the release is what the branch carries)" 'cmp -s src/aef-workflow-designer.html "$ART"'
    check "the index holds nothing staged (T-1313)" '[ -z "$(git diff --cached --name-only)" ]'
}

steps() {
    step_outward "Run the core tier now (about 12-15 minutes), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_core() {
    PATH="$NODEBIN:$PATH" bash tools/_t1288-prepush-gate.sh || { echo "core tier RED (see .context/working/prepush-core.log); nothing pushed — the agent brings it to you"; return 1; }
    echo "ok  core tier green for this tree; the push hook will find it cached"
}

do_push() {
    git push origin bleeding-edge || { echo "push of bleeding-edge failed"; return 1; }
    git push origin "$TAG" || { echo "push of $TAG failed"; return 1; }
    echo "DONE: bleeding-edge and $TAG pushed. The agent now tells AEF and aef-greenfield-test."
}
