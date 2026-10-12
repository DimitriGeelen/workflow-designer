# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Release designer 0.19.1: cut, commit, tag designer-v0.19.1, push"
JOB_TASK="T-1135"
JOB_WHY="Your W5 answer A: release 0.19.1 first, then the framework field test (job 018). 0.19.1 is a patch for the defect
Greenfield found in their 0.18.0 re-test (T-1134): on a portal that serves maps but not the field endpoints, the designer
offered field settings (Save then failed, HTTP 403) and, in 0.19.0, the suggest button — now read-only, saying the server
does not offer them (stub portal: 0.18.0 1/4 -> 4/4). Authoring kit re-issued as 0.19.1 with its calibration maps
corrected (T-1136: GLM found the clean map broke the guide's own citation rule; the failed run is on record) and PASS by
codex, GLM and Antigravity. Notes: docs/releases/RELEASE-NOTES-0.19.1.md. Steps 3-4 are outward: the tag is permanent,
step 4 pushes bleeding-edge and the tag to origin. master is not advanced."

V=0.19.1
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
KIT="dist/aef-authoring-kit-$V"
INPUTS="VERSION src/aef-workflow-designer.html scripts/release-designer.sh tools/build-authoring-kit.py docs/authoring-kit tools/validate-workflow.py"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ]'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "the release inputs are committed" 'git diff --quiet HEAD -- $INPUTS'
    check "release notes exist and are committed" 'git ls-files --error-unmatch docs/releases/RELEASE-NOTES-$V.md >/dev/null && git diff --quiet HEAD -- docs/releases/RELEASE-NOTES-$V.md'
    check "tag $TAG does not exist locally" '! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null'
    check "tag $TAG does not exist on origin" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "kit $V carries a PASS calibration of its exact bytes (ledger L16)" 'python3 tools/kit-calibration-gate.py check --version "$V"'
    check "no $V artifact or kit in dist/ yet" '[ ! -e "$ART" ] && [ ! -e "$KIT" ]'
}

steps() {
    step "Cut release $V: scripts/release-designer.sh (render gate ON, announce ON; writes dist/)" 'do_cut'
    step "Commit $ART, $KIT and dist/MANIFEST.yaml" 'do_commit'
    step "Tag $TAG (annotated) on the release commit" 'do_tag'
    step "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_cut() {
    scripts/release-designer.sh || { echo "release-designer.sh failed (see above); dist/ may need a look"; return 1; }
    { [ -f "$ART" ] && cmp -s src/aef-workflow-designer.html "$ART"; } || { echo "$ART missing or differs from src"; return 1; }
    (cd "$KIT" && sha256sum -c SHA256SUMS --quiet) || { echo "the kit does not verify against its SHA256SUMS"; return 1; }
    echo "ok  artifact == src, kit verifies"
}

do_commit() {
    git add "$ART" "$KIT" dist/MANIFEST.yaml || return 1
    git commit -q -m "T-1135: release designer $V — field settings and suggestions offered only where the server has the endpoints (T-1134); kit re-issued with corrected calibration maps (T-1136)" \
        -m "Notes: docs/releases/RELEASE-NOTES-$V.md" || return 1
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

do_push() {
    git push origin bleeding-edge || { echo "push of bleeding-edge failed"; return 1; }
    git push origin "$TAG" || { echo "push of $TAG failed"; return 1; }
    echo "DONE: release $V cut, committed, tagged $TAG and pushed."
}
