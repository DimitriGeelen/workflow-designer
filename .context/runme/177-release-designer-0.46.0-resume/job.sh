# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Job 176 resumed after its step 3 (GLM-5.3 calibration FAIL, rightly: the calibration maps broke the kit's own rule,
# fixed by T-1477). Job 176's steps 2-10, same code; step 1 (the bump) is done and committed. Before: the browser tier runs after the LOCAL tag and before the push, because the
# T-396 tag-state leg cannot measure before the version's tag exists (job 122; CLAUDE.md T-1374 rule).
# Step 1 (the version bump) is rehearsed in a clone. Steps 2-3 call live reviewers (model time) and every later step
# needs their result (the gate reads their record), so steps 2-10 are `step_outward`; the browser tier also starts
# the pool. Commits name only T-1476.
JOB_TITLE="Release designer 0.46.0, resumed: calibrate the corrected kit the kit (codex, GLM-5.3), cut, commit, tag designer-v0.46.0 locally, browser tier on the pool (4 shards), core tier, push"
JOB_TASK="T-1476"
JOB_WHY="Job 176 stopped at step 3: GLM-5.3 caught all three planted defects but found one more thing, and it was right:
both calibration maps wrote their source quotes with the source's line breaks, raising 5 warnings each that the kit's
own guide does not allow. You chose option 1: fix the fixture and re-release. T-1477 put each quote on one line, words
unchanged; no other finding moved. The kit now builds differently, so both reviewers calibrate again (job 176's rows
move to voided_runs, kept, not deleted). Step 1 of job 176 (VERSION 0.46.0) is done and committed.
Steps 1-2 calibrate with codex and GLM-5.3 (a few minutes each); if one does not PASS, nothing is released and the
agent brings it to you. Step 6 tags locally. Step 7 runs the browser tier on the pool, split in 4 (about 7-12 min).
Step 8 runs core (about 20 min), step 9 pushes bleeding-edge and the tag. Answer y at every step."

V=0.46.0
PREV=0.45.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
KIT="dist/aef-authoring-kit-$V"
OUT=.context/runme/177-release-designer-0.46.0-resume
REC=docs/authoring-kit/calibration-records/$V.yaml
INPUTS="VERSION src/aef-workflow-designer.html scripts/release-designer.sh tools/build-authoring-kit.py docs/authoring-kit tools/validate-workflow.py tests/test_rule_dialect_axis.py"
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"
OCBIN="$HOME/.opencode/bin"
CODEX_CMD='codex exec --skip-git-repo-check --sandbox workspace-write'
GLM_CMD='opencode run -m zai-coding-plan/glm-5.3'

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V and committed (job 176 step 1)" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ] && git diff --quiet HEAD -- VERSION'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "the release inputs are committed" 'git diff --quiet HEAD -- $INPUTS'
    check "release notes for $V exist, are committed and are not a draft" 'git ls-files --error-unmatch docs/releases/RELEASE-NOTES-$V.md >/dev/null && git diff --quiet HEAD -- docs/releases/RELEASE-NOTES-$V.md && ! grep -q DRAFT docs/releases/RELEASE-NOTES-$V.md'
    check "the release notes name all five designer endpoints and whether AEF serves each (T-1289, T-1315)" 'for e in /api/validate /api/instances /api/field-profile /api/field-suggestions /api/field-catalog; do grep -q "$e" docs/releases/RELEASE-NOTES-$V.md || exit 1; done'
    check "the index holds nothing staged (T-1313: commits here name their paths, but say so up front)" '[ -z "$(git diff --cached --name-only)" ]'
    check "the unwired-guard ratchet holds (the leg that stopped job 108 at step 8)" 'python3 tools/_t451-unwired-guard-census.py --ratchet >/dev/null 2>&1'
    check "the dialect axis passes (the kit's class column comes from it)" 'python3 tests/test_rule_dialect_axis.py >/dev/null'
    check "tag $TAG does not exist locally" '! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null'
    check "tag $TAG does not exist on origin" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "no $V artifact or kit in dist/ yet" '[ ! -e "$ART" ] && [ ! -e "$KIT" ]'
    check "the $V calibration record, if any, is for another kit than the one that builds now (job 176's; voided on the first new row)" '[ ! -e "$REC" ] || ! grep -q "$(python3 tools/kit-calibration-gate.py kit-hash --version "$V")" "$REC"'
    check "T-1465, T-1470, T-1471, T-1472, T-1477 are closed (the changes this release carries)" 'for t in T-1465 T-1470 T-1471 T-1472 T-1477; do ls .tasks/completed/$t-*.md >/dev/null 2>&1 || exit 1; done'
    check "/tmp has at least 4 GB free (job 128 stopped at the cut on a full /tmp)" '[ "$(df --output=avail -k /tmp | tail -1)" -gt 4194304 ]'
    check "the kit for $V builds" 'python3 tools/kit-calibration-gate.py kit-hash --version "$V" >/dev/null'
    check "codex is installed" 'PATH="$NODEBIN:$PATH" command -v codex >/dev/null'
    check "opencode is installed and lists zai-coding-plan/glm-5.3" 'PATH="$OCBIN:$PATH" timeout 60 opencode models 2>/dev/null | grep -qx "zai-coding-plan/glm-5.3"'
}

steps() {
    step_outward "Calibrate with codex (OpenAI): build the $V kit, loop.sh --calibrate, record the result" 'do_calibrate codex openai "$CODEX_CMD"'
    step_outward "Calibrate with GLM-5.3 (Z.AI, opencode): build the $V kit, loop.sh --calibrate, record the result" 'do_calibrate glm-5.3 zai "$GLM_CMD"'
    step_outward "Release gate: the $V kit carries a PASS calibration of its exact bytes" 'do_gate'
    step_outward "Cut release $V: scripts/release-designer.sh (render gate ON, announce ON; writes dist/)" 'do_cut'
    step_outward "Commit $ART, $KIT, dist/MANIFEST.yaml and the calibration record" 'do_commit'
    step_outward "Tag $TAG (annotated) on the release commit, locally only" 'do_tag'
    step_outward "Browser tier on the pool, 4 shards (T1467_POOL_ONLY=1; about 7-12 min): stops here if red or no result, nothing pushed" 'do_browser'
    step_outward "Core tier (about 20 minutes, or cached), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_bump() {
    printf '%s\n' "$V" > VERSION || return 1
    sed -i "s/^const APP_VERSION = '[0-9][0-9.]*';/const APP_VERSION = '$V';/" src/aef-workflow-designer.html || return 1
    bash tools/_t808-version-parity.sh || { echo "parity failed after the bump"; return 1; }
    git add VERSION src/aef-workflow-designer.html || return 1
    git commit -q -m "T-1476: $V — VERSION and APP_VERSION bumped by the release job (parity ok)" -- VERSION src/aef-workflow-designer.html || return 1
    echo "ok  bumped to $V in $(git rev-parse --short HEAD)"
}

do_calibrate() {
    local name="$1" vendor="$2" cmd="$3" kit wd res rc
    kit=$(mktemp -d /tmp/t1476-kit-$name.XXXXXX) || return 1
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
    [ -f "$KIT/SKILL.md" ] || { echo "the kit has no SKILL.md (T-1376)"; return 1; }
    grep -q 'Expense claim' "$KIT/exemplar.bpmn" || { echo "the kit does not ship the T-1418 exemplar"; return 1; }
    echo "ok  artifact == src, kit verifies, ships SKILL.md and the new exemplar"
}

do_commit() {
    git add "$ART" "$KIT" dist/MANIFEST.yaml "$REC" || return 1
    git commit -q -m "T-1476: release designer $V — toolbar fits AEF's frame, starter map opens readable, nothing on the add-lane strip, straight associations; kit calibrated on its bytes" \
        -m "Notes: docs/releases/RELEASE-NOTES-$V.md" -- "$ART" "$KIT" dist/MANIFEST.yaml "$REC" || return 1
    echo "ok  release commit $(git rev-parse --short HEAD)"
}

do_tag() {
    local rel sha
    rel=$(git log -1 --format=%H -- "$ART")
    [ -n "$rel" ] || { echo "no commit carries $ART"; return 1; }
    sha=$(sha256sum "$ART" | awk '{print $1}')
    git tag -a "$TAG" "$rel" -m "designer $V (sha256 $sha) + authoring kit" || return 1
    echo "ok  tagged $TAG on $(git rev-parse --short "$rel") (local; pushed in the last step)"
}

do_browser() {
    PATH="$NODEBIN:$PATH" T1467_POOL_ONLY=1 bash tools/pool/tier-gate.sh browser || { echo "browser tier RED or no pool result (build/tiergate/tier-browser.runs.log); nothing pushed, the tag is local only — the agent brings it to you"; return 1; }
    echo "ok  browser tier green on the pool (split) for the release tree"
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
