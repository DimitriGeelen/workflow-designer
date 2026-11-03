# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Resumes release 0.38.0 where job 122 stopped (step 6, browser tier red: 133 passed, 2 failed). Job 122 already
# bumped and committed VERSION (5471040ca), passed both calibrations and the gate, and cut dist/ (uncommitted).
# The two red legs:
#   - _t1303-io-findings-cdp.mjs: its fixture drew the new W-XML-IO-INCOMPLETE as a fourth finding. Fixed in 486540427.
#   - _t396-release-tag-state.sh: CANNOT MEASURE because tag designer-v0.38.0 did not exist yet. It needs the tag.
# So the browser tier now runs after the LOCAL tag and before anything is pushed: if it is red, nothing leaves this
# machine. Every step reads job 122's uncommitted dist/ output, which a clone of HEAD does not have, so all are
# `step_outward` (not rehearsed); the checks below hold in a clone too.
JOB_TITLE="Resume release 0.38.0 after job 122: verify the cut, commit, tag locally, browser tier, core tier, push"
JOB_TASK="T-1378"
JOB_WHY="Job 122 stopped at step 6: the browser tier was red on two legs, so nothing was committed after the bump and
nothing was tagged or pushed. Both legs are explained:
- the T-1303 harness's own test map now draws one of the new warnings as a fourth finding; the map is fixed;
- the release tag-state probe cannot measure before the tag exists.
This job continues from job 122's cut (dist/ as written then, both calibrations PASS):
  1 verify the cut is intact (artifact == src, kit verifies, ships SKILL.md, calibration gate passes on its bytes);
  2 commit the release files;
  3 tag designer-v0.38.0, locally only;
  4 browser tier (about 17 minutes): if red, it stops and nothing is pushed;
  5 core tier (about 13 minutes);
  6 push bleeding-edge and the tag.
Answer y at every step. Afterwards the agent tells AEF and greenfield."

V=0.38.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
KIT="dist/aef-authoring-kit-$V"
OUT=.context/runme/123-release-0.38.0-resume
REC=docs/authoring-kit/calibration-records/$V.yaml
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V (job 122 bumped and committed it)" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ]'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "the T-1303 harness fix is in HEAD" 'grep -q "typeRef=\"crm:Contact\" operation=\"read\" sourceSystem=\"sys:crm\"" tools/_t1303-io-findings-cdp.mjs'
    check "the index holds nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "tag $TAG does not exist locally" '! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null'
    check "tag $TAG does not exist on origin" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
}

steps() {
    step_outward "Verify job 122's cut: $ART == src, $KIT verifies and ships SKILL.md, the calibration gate passes on its bytes" 'do_verify'
    step_outward "Commit $ART, $KIT, dist/MANIFEST.yaml and the calibration record" 'do_commit'
    step_outward "Tag $TAG (annotated) on the release commit, locally only" 'do_tag'
    step_outward "Browser tier (about 17 minutes; T-1374): stops here if red, and nothing is pushed" 'do_browser'
    step_outward "Core tier (about 13 minutes, or cached), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_verify() {
    { [ -f "$ART" ] && cmp -s src/aef-workflow-designer.html "$ART"; } || { echo "$ART missing or differs from src"; return 1; }
    (cd "$KIT" && sha256sum -c SHA256SUMS --quiet) || { echo "the kit does not verify against its SHA256SUMS"; return 1; }
    [ -f "$KIT/SKILL.md" ] || { echo "the kit has no SKILL.md (T-1376)"; return 1; }
    [ -f "$REC" ] || { echo "no calibration record $REC"; return 1; }
    python3 tools/kit-calibration-gate.py check --version "$V" || { echo "the calibration gate does not pass for $V"; return 1; }
    echo "ok  artifact == src, kit verifies and ships SKILL.md, calibration gate passes"
}

do_commit() {
    git add "$ART" "$KIT" dist/MANIFEST.yaml "$REC" || return 1
    git commit -q -m "T-1378: release designer $V — six general map warnings and --strict (T-1377), kit section 4b and SKILL.md (T-1376), import notice names what it does not draw (T-1372); kit calibrated on its bytes (job 122), browser tier run before the push (job 123)" \
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
    local log="$OUT/browser-tier.log"
    PATH="$NODEBIN:$PATH" bash tests/run-bridge-tests.sh --tier browser > "$log" 2>&1
    local rc=$?
    grep -E '^tier browser|\[FAIL\]' "$log" | cut -c1-300
    [ "$rc" = 0 ] || { echo "browser tier RED (full output: $log); nothing pushed, the tag is local only — the agent brings it to you"; return 1; }
    echo "ok  browser tier green on the release tree"
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
