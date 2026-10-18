# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Release designer 0.23.0: calibrate the kit (codex, GLM-5.3), then cut, commit, tag designer-v0.23.0, push"
JOB_TASK="T-1202"
JOB_WHY="Your 'release 0.23.0' (2026-10-18). 0.23.0 (minor): the designer is unchanged apart from its version; the
authoring kit gains the CONVENTIONAL class and a basis column (T-1200, your T-1165 GO), so 15 rules about graph shape
stop being labelled universal. Validator findings are unchanged. Notes: docs/releases/RELEASE-NOTES-0.23.0.md.
Steps 1-2 run live reviewers on the 0.23.0 kit (codex, then GLM-5.3): a few minutes each and model time. The kit text
changed, so this calibration is a real one. If one does not PASS the job stops and nothing is released. Steps 6-7 are
outward: the tag is permanent, step 7 pushes bleeding-edge and the tag. Afterwards the agent re-pins Watchtower and
tells AEF."

V=0.23.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
KIT="dist/aef-authoring-kit-$V"
OUT=.context/runme/040-release-designer-0.23.0
REC=docs/authoring-kit/calibration-records/$V.yaml
INPUTS="VERSION src/aef-workflow-designer.html scripts/release-designer.sh tools/build-authoring-kit.py docs/authoring-kit tools/validate-workflow.py tests/test_rule_dialect_axis.py"
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"
OCBIN="$HOME/.opencode/bin"
CODEX_CMD='codex exec --skip-git-repo-check --sandbox workspace-write'
GLM_CMD='opencode run -m zai-coding-plan/glm-5.3'

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ]'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "the release inputs are committed" 'git diff --quiet HEAD -- $INPUTS'
    check "release notes exist and are committed" 'git ls-files --error-unmatch docs/releases/RELEASE-NOTES-$V.md >/dev/null && git diff --quiet HEAD -- docs/releases/RELEASE-NOTES-$V.md'
    check "the dialect axis passes (the kit's class column comes from it)" 'python3 tests/test_rule_dialect_axis.py >/dev/null'
    check "tag $TAG does not exist locally" '! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null'
    check "tag $TAG does not exist on origin" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "no $V artifact or kit in dist/ yet" '[ ! -e "$ART" ] && [ ! -e "$KIT" ]'
    check "no $V calibration record yet (this job makes it)" '[ ! -e "$REC" ]'
    check "the kit for $V builds" 'python3 tools/kit-calibration-gate.py kit-hash --version "$V" >/dev/null'
    check "codex is installed" 'PATH="$NODEBIN:$PATH" command -v codex >/dev/null'
    check "opencode is installed and lists zai-coding-plan/glm-5.3" 'PATH="$OCBIN:$PATH" timeout 60 opencode models 2>/dev/null | grep -qx "zai-coding-plan/glm-5.3"'
}

steps() {
    step "Calibrate with codex (OpenAI): build the $V kit, loop.sh --calibrate, record the result" 'do_calibrate codex openai "$CODEX_CMD"'
    step "Calibrate with GLM-5.3 (Z.AI, opencode): build the $V kit, loop.sh --calibrate, record the result" 'do_calibrate glm-5.3 zai "$GLM_CMD"'
    step "Release gate: the $V kit carries a PASS calibration of its exact bytes" 'do_gate'
    step "Cut release $V: scripts/release-designer.sh (render gate ON, announce ON; writes dist/)" 'do_cut'
    step "Commit $ART, $KIT, dist/MANIFEST.yaml and the calibration record" 'do_commit'
    step "Tag $TAG (annotated) on the release commit" 'do_tag'
    step "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_calibrate() {
    local name="$1" vendor="$2" cmd="$3" kit wd res rc
    kit=$(mktemp -d /tmp/t1202-kit-$name.XXXXXX) || return 1
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
    scripts/release-designer.sh || { echo "release-designer.sh failed (see above); dist/ may need a look"; return 1; }
    { [ -f "$ART" ] && cmp -s src/aef-workflow-designer.html "$ART"; } || { echo "$ART missing or differs from src"; return 1; }
    (cd "$KIT" && sha256sum -c SHA256SUMS --quiet) || { echo "the kit does not verify against its SHA256SUMS"; return 1; }
    echo "ok  artifact == src, kit verifies"
}

do_commit() {
    git add "$ART" "$KIT" dist/MANIFEST.yaml "$REC" || return 1
    git commit -q -m "T-1202: release designer $V — authoring kit: CONVENTIONAL class and basis column (T-1200), 15 graph-shape rules re-classed; designer unchanged; kit calibrated on its bytes" \
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
