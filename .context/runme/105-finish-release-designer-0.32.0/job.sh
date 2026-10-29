# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Finishes job 104 (T-1336), which stopped at step 6/9 because that step was not confirmed: steps 1-5 ran (bump
# committed in beb803315, both calibrations PASS, release cut and announced), 6-9 did not. These are job 104's steps
# 6-9, their code unchanged, plus a first step that re-verifies what step 5 left in dist/. Every step is `step_outward`:
# the dist/ files and the calibration record are uncommitted, so a rehearsal clone of HEAD does not have them.
JOB_TITLE="Finish release designer 0.32.0: verify dist/, commit, tag designer-v0.32.0, core tier, push (job 104's steps 6-9)"
JOB_TASK="T-1336"
JOB_WHY="Job 104 stopped at step 6 (the release commit) because it was not confirmed; you said to finish the release.
Already done by job 104: VERSION and APP_VERSION 0.32.0 (committed), kit calibrated PASS by codex and GLM-5.3, release
cut into dist/ (sha256 8ed494c1..., 1298447 bytes), announced on the AEF rail. Not done: the release commit, the tag,
the core tier, the push — AEF has been told of 0.32.0 but has no tag to fetch until this job pushes it. Step 1 re-checks
dist/ (artifact == src, kit verifies, the calibration gate passes) before anything is committed. Step 4 runs the core
tier (about 15 minutes) and stops the job if red; step 5 pushes bleeding-edge and the tag. Afterwards the agent tells AEF."

V=0.32.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
KIT="dist/aef-authoring-kit-$V"
REC=docs/authoring-kit/calibration-records/$V.yaml
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V (job 104 step 1 bumped and committed it)" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ]'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "the index holds nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "tag $TAG does not exist locally" '! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null'
    check "tag $TAG does not exist on origin" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
}

steps() {
    step_outward "Verify what job 104 cut: $ART == src, the kit verifies, the calibration gate passes for $V" 'do_verify'
    step_outward "Commit $ART, $KIT, dist/MANIFEST.yaml and the calibration record" 'do_commit'
    step_outward "Tag $TAG (annotated) on the release commit" 'do_tag'
    step_outward "Run the core tier now (about 15 minutes), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_verify() {
    [ -f "$ART" ] || { echo "$ART is missing"; return 1; }
    cmp -s src/aef-workflow-designer.html "$ART" || { echo "$ART differs from src"; return 1; }
    (cd "$KIT" && sha256sum -c SHA256SUMS --quiet) || { echo "the kit does not verify against its SHA256SUMS"; return 1; }
    [ -f "$REC" ] || { echo "$REC is missing"; return 1; }
    python3 tools/kit-calibration-gate.py check --version "$V" || { echo "calibration gate refuses $V"; return 1; }
    echo "ok  artifact == src (sha256 $(sha256sum "$ART" | cut -c1-16)..., $(stat -c %s "$ART") bytes), kit verifies, gate passes"
}

# job 104's steps 6-9, unchanged
do_commit() {
    git add "$ART" "$KIT" dist/MANIFEST.yaml "$REC" || return 1
    # the subject comes from the notes' first line; it names no shipped task (see the header)
    git commit -q -m "T-1336: release designer $V — a file from another tool keeps what the designer does not model: content, ids, identity, geometry, order; kit calibrated on its bytes" \
        -m "Notes: docs/releases/RELEASE-NOTES-$V.md" -- "$ART" "$KIT" dist/MANIFEST.yaml "$REC" || return 1
    echo "ok  release commit $(git rev-parse --short HEAD)"
}

do_tag() {
    local rel sha
    rel=$(git log -1 --format=%H -- "$ART")
    [ -n "$rel" ] || { echo "no commit carries $ART"; return 1; }
    sha=$(sha256sum "$ART" | awk '{print $1}')
    git tag -a "$TAG" "$rel" -m "designer $V (sha256 $sha) + authoring kit" || return 1
    echo "ok  tagged $TAG on $(git rev-parse --short "$rel")"
}

do_core() {
    PATH="$NODEBIN:$PATH" bash tools/_t1288-prepush-gate.sh || { echo "core tier RED (see .context/working/prepush-core.log); nothing pushed — the agent brings it to you"; return 1; }
    echo "ok  core tier green for this tree; the push hook will find it cached"
}

do_push() {
    git push origin bleeding-edge || { echo "push of bleeding-edge failed"; return 1; }
    git push origin "$TAG" || { echo "push of $TAG failed"; return 1; }
    echo "DONE: release $V cut, committed, tagged $TAG and pushed."
}
