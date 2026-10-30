# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Finishes job 108 (T-1346), which stopped at step 8/9: the core tier was RED on one leg, the unwired-guard ratchet
# (89 -> 90: closing T-1345 left tools/_t1345-message-shots.mjs with no live caller). Fixed in a commit after the tag
# (wired as browser leg 219; the ratchet is back at 89). Steps 1-7 of job 108 ran: bump d6d732079, both calibrations
# PASS, release cut, release commit 59a2ad081, tag designer-v0.33.0 on it, all local. These are job 108's steps 8-9,
# their code unchanged, plus a first step that re-verifies the release before anything leaves this machine.
# Every step is `step_outward`: the push acts outside the repo, and the tag is not in a rehearsal clone.
JOB_TITLE="Finish release designer 0.33.0: verify the tagged release, core tier, push bleeding-edge and designer-v0.33.0 (job 108's steps 8-9)"
JOB_TASK="T-1346"
JOB_WHY="Job 108 stopped at step 8 (core tier RED): one guard caught a screenshot tool T-1345 left unwired; the agent
wired it (a test-suite change only, after the tag; the designer and the release are untouched). Already done by job 108:
VERSION 0.33.0, kit calibrated PASS by codex and GLM-5.3, release cut and announced, release commit and tag
designer-v0.33.0 (local). Not done: the core tier and the push, so AEF has no tag to fetch yet. Step 1 re-checks the
release (artifact == src at the tag, the kit verifies, the calibration gate passes, the tag is on the release commit).
Step 2 runs the core tier (about 20 minutes; the agent ran it first, so it should be cached green and instant) and stops
the job if red; step 3 pushes bleeding-edge and the tag. Answer y at each. Afterwards the agent tells AEF."

V=0.33.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
KIT="dist/aef-authoring-kit-$V"
REC=docs/authoring-kit/calibration-records/$V.yaml
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V (job 108 step 1 bumped and committed it)" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ]'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "the index holds nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "$ART, $KIT and $REC are committed" 'git ls-files --error-unmatch "$ART" "$REC" >/dev/null 2>&1 && [ -n "$(git ls-files "$KIT")" ] && git diff --quiet HEAD -- "$ART" "$KIT" "$REC"'
    check "tag $TAG exists locally (job 108 step 7)" 'git rev-parse -q --verify "refs/tags/$TAG" >/dev/null'
    check "tag $TAG is not on origin yet" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "the unwired-guard ratchet holds (the leg that stopped job 108)" 'python3 tools/_t451-unwired-guard-census.py --ratchet >/dev/null 2>&1'
}

steps() {
    step_outward "Verify the release: $ART == src at $TAG, the kit verifies, the calibration gate passes" 'do_verify'
    step_outward "Run the core tier now (about 20 minutes, or cached), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_verify() {
    local rel
    rel=$(git rev-parse "$TAG^{commit}") || { echo "cannot resolve $TAG"; return 1; }
    [ "$(git log -1 --format=%H -- "$ART")" = "$rel" ] || { echo "$TAG is not on the commit that carries $ART"; return 1; }
    git show "$TAG:src/aef-workflow-designer.html" | cmp -s - "$ART" || { echo "$ART differs from src at $TAG"; return 1; }
    cmp -s src/aef-workflow-designer.html "$ART" || { echo "src has changed since the release (it should not have)"; return 1; }
    (cd "$KIT" && sha256sum -c SHA256SUMS --quiet) || { echo "the kit does not verify against its SHA256SUMS"; return 1; }
    python3 tools/kit-calibration-gate.py check --version "$V" || { echo "calibration gate refuses $V"; return 1; }
    echo "ok  $TAG on $(git rev-parse --short "$rel"); artifact == src (sha256 $(sha256sum "$ART" | cut -c1-16)..., $(stat -c %s "$ART") bytes); kit verifies; gate passes"
}

# job 108's steps 8-9, unchanged
do_core() {
    PATH="$NODEBIN:$PATH" bash tools/_t1288-prepush-gate.sh || { echo "core tier RED (see .context/working/prepush-core.log); nothing pushed — the agent brings it to you"; return 1; }
    echo "ok  core tier green for this tree; the push hook will find it cached"
}

do_push() {
    git push origin bleeding-edge || { echo "push of bleeding-edge failed"; return 1; }
    git push origin "$TAG" || { echo "push of $TAG failed"; return 1; }
    echo "DONE: release $V cut, committed, tagged $TAG and pushed."
}
