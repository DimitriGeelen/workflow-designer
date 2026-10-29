# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Step 1 (the version bump) is rehearsed in a clone. Steps 2-3 call live reviewers (model time) and every later step needs
# their result (the gate reads their record), so steps 2-9 are `step_outward`. Same shape as job 096 (T-1321, 0.31.0,
# done): both commits name their paths, the release commit names only T-1336, the notes check covers all five endpoints.
JOB_TITLE="Release designer 0.32.0: bump, calibrate the kit (codex, GLM-5.3), cut, commit, tag designer-v0.32.0, core tier, push"
JOB_TASK="T-1336"
JOB_WHY="Release 0.32.0 (minor): a file made in another tool keeps, on save, what the designer does not model.
- Unknown attributes, children, extensions, comments, artifacts with their shapes, conditionExpression language/id
  (T-1325, T-1326, T-1327, T-1268, T-1265): one unedited save of the 11 test files lost 394 items, now 11.
- The file's definitions/process/collaboration ids, targetNamespace and isExecutable kept (T-1262, T-1270); original
  element ids recorded as x832:origin, chosen with AEF (T-1261); another tool's geometry kept until a shape moves
  (T-1264); node order as declared (T-1271); unique ids (T-1102).
Designer-written maps (all of AEF's) save byte-for-byte as in 0.31.0. Notes: docs/releases/RELEASE-NOTES-0.32.0.md.
Held until AEF released v1.8.15 (done today; 832 is on it). Steps 2-3 calibrate the kit with live reviewers, a few
minutes each and model time; if one does not PASS, nothing is released. Step 8 runs the core tier (about 15 minutes)
and stops the job if red; step 9 pushes bleeding-edge and the tag. Afterwards the agent tells AEF."

V=0.32.0
PREV=0.31.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
KIT="dist/aef-authoring-kit-$V"
OUT=.context/runme/104-release-designer-0.32.0
REC=docs/authoring-kit/calibration-records/$V.yaml
INPUTS="VERSION src/aef-workflow-designer.html scripts/release-designer.sh tools/build-authoring-kit.py docs/authoring-kit tools/validate-workflow.py tests/test_rule_dialect_axis.py"
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"
OCBIN="$HOME/.opencode/bin"
CODEX_CMD='codex exec --skip-git-repo-check --sandbox workspace-write'
GLM_CMD='opencode run -m zai-coding-plan/glm-5.3'

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is still $PREV (step 1 bumps it)" '[ "$(tr -d "[:space:]" < VERSION)" = "$PREV" ]'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "the release inputs are committed" 'git diff --quiet HEAD -- $INPUTS'
    check "release notes for $V exist, are committed and are not a draft" 'git ls-files --error-unmatch docs/releases/RELEASE-NOTES-$V.md >/dev/null && git diff --quiet HEAD -- docs/releases/RELEASE-NOTES-$V.md && ! grep -q DRAFT docs/releases/RELEASE-NOTES-$V.md'
    check "the release notes name the five endpoints AEF does not serve (T-1289, T-1315)" 'for e in /api/validate /api/instances /api/field-profile /api/field-suggestions /api/field-catalog; do grep -q "$e" docs/releases/RELEASE-NOTES-$V.md || exit 1; done'
    check "the index holds nothing staged (T-1313: commits here name their paths, but say so up front)" '[ -z "$(git diff --cached --name-only)" ]'
    check "the dialect axis passes (the kit's class column comes from it)" 'python3 tests/test_rule_dialect_axis.py >/dev/null'
    check "tag $TAG does not exist locally" '! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null'
    check "tag $TAG does not exist on origin" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "no $V artifact or kit in dist/ yet" '[ ! -e "$ART" ] && [ ! -e "$KIT" ]'
    check "no $V calibration record yet" '[ ! -e "$REC" ]'
    check "the kit for $V builds" 'python3 tools/kit-calibration-gate.py kit-hash --version "$V" >/dev/null'
    check "codex is installed" 'PATH="$NODEBIN:$PATH" command -v codex >/dev/null'
    check "opencode is installed and lists zai-coding-plan/glm-5.3" 'PATH="$OCBIN:$PATH" timeout 60 opencode models 2>/dev/null | grep -qx "zai-coding-plan/glm-5.3"'
}

steps() {
    step "Bump VERSION and APP_VERSION to $V and commit (parity checked)" 'do_bump'
    step_outward "Calibrate with codex (OpenAI): build the $V kit, loop.sh --calibrate, record the result" 'do_calibrate codex openai "$CODEX_CMD"'
    step_outward "Calibrate with GLM-5.3 (Z.AI, opencode): build the $V kit, loop.sh --calibrate, record the result" 'do_calibrate glm-5.3 zai "$GLM_CMD"'
    step_outward "Release gate: the $V kit carries a PASS calibration of its exact bytes" 'do_gate'
    step_outward "Cut release $V: scripts/release-designer.sh (render gate ON, announce ON; writes dist/)" 'do_cut'
    step_outward "Commit $ART, $KIT, dist/MANIFEST.yaml and the calibration record" 'do_commit'
    step_outward "Tag $TAG (annotated) on the release commit" 'do_tag'
    step_outward "Run the core tier now (about 15 minutes), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_bump() {
    printf '%s\n' "$V" > VERSION || return 1
    sed -i "s/^const APP_VERSION = '[0-9][0-9.]*';/const APP_VERSION = '$V';/" src/aef-workflow-designer.html || return 1
    bash tools/_t808-version-parity.sh || { echo "parity failed after the bump"; return 1; }
    git add VERSION src/aef-workflow-designer.html || return 1
    git commit -q -m "T-1336: $V — VERSION and APP_VERSION bumped by the release job (parity ok)" -- VERSION src/aef-workflow-designer.html || return 1
    echo "ok  bumped to $V in $(git rev-parse --short HEAD)"
}

do_calibrate() {
    local name="$1" vendor="$2" cmd="$3" kit wd res rc
    kit=$(mktemp -d /tmp/t1336-kit-$name.XXXXXX) || return 1
    python3 tools/build-authoring-kit.py --version "$V" --out "$kit/kit" >/dev/null || { echo "kit build failed"; rm -rf "$kit"; return 1; }
    wd="$OUT/calibrate-$name"; res="$OUT/calibrate-$name.out"
    mkdir -p "$wd"
    echo "kit: $kit/kit (sha256 of SHA256SUMS $(sha256sum "$kit/kit/SHA256SUMS" | cut -c1-16)...), reviewer: $cmd"
    ( export PATH="$NODEBIN:$OCBIN:$PATH" KIT_REVIEWER_CMD="$cmd"; bash "$kit/kit/loop.sh" --calibrate "$PWD/$wd" ) 2>&1 | tee "$res"
    python3 tools/kit-calibration-gate.py record --version "$V" --reviewer "$name" --vendor "$vendor" --result-file "$res"
    rc=$?
    rm -rf "$kit"
    grep -E 'CALIBRATION: (PASS|FAIL|COULD NOT MEASURE)' "$res" | tail -1
    [ "$rc" = 0 ] || { echo "$name did not PASS (recorded); nothing is released — the agent brings it to you"; return 1; }
}

do_gate() {
    cat "$REC"
    python3 tools/kit-calibration-gate.py check --version "$V"
}

do_cut() {
    PATH="$NODEBIN:$PATH" scripts/release-designer.sh || { echo "release-designer.sh failed (see above); dist/ may need a look"; return 1; }
    { [ -f "$ART" ] && cmp -s src/aef-workflow-designer.html "$ART"; } || { echo "$ART missing or differs from src"; return 1; }
    (cd "$KIT" && sha256sum -c SHA256SUMS --quiet) || { echo "the kit does not verify against its SHA256SUMS"; return 1; }
    echo "ok  artifact == src, kit verifies"
}

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
