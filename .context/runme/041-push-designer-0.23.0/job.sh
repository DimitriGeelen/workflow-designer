# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
JOB_TITLE="Push the 0.23.0 release: bleeding-edge and tag designer-v0.23.0 to origin (job 040's step 7)"
JOB_TASK="T-1202"
JOB_WHY="Job 040 ran steps 1-6 on 2026-10-18 (codex PASS, GLM-5.3 PASS, gate, cut, release commit 7bf5ffee, tag
designer-v0.23.0) and stopped at step 7 because the push was not confirmed. Nothing is on origin yet. This job is that
one step. It is outward: once pushed, the tag is public and AEF can pin it. If you held the push back on purpose, do
not run this; tell the agent why instead."

V=0.23.0
TAG="designer-v$V"
REL=7bf5ffee

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "tag $TAG exists locally on the release commit $REL" '[ "$(git rev-parse --short "$TAG^{commit}")" = "$REL" ]'
    check "the tagged artifact is dist/aef-workflow-designer-$V.html" 'git cat-file -e "$TAG:dist/aef-workflow-designer-$V.html"'
    check "tag $TAG is not on origin yet" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "origin/bleeding-edge is an ancestor of HEAD (a fast-forward push)" 'git fetch -q origin bleeding-edge && git merge-base --is-ancestor origin/bleeding-edge HEAD'
}

steps() {
    step "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_push() {
    git push origin bleeding-edge || { echo "push of bleeding-edge failed"; return 1; }
    git push origin "$TAG" || { echo "push of $TAG failed"; return 1; }
    echo "DONE: bleeding-edge and $TAG pushed."
}
