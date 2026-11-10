# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Resumes release 0.41.0 where job 128 stopped (step 5, the cut): the render gate could not launch Chromium because
# /tmp (a 32 GB tmpfs) was full ("Less than 64MB of free space in temporary directory"). Job 128 had already bumped and
# committed VERSION (f0b1bd6e6) and both calibrations PASSED (record written, uncommitted, gate passed at step 4).
# The failed cut left dist/aef-workflow-designer-0.41.0.html (uncommitted, no manifest); step 1 removes it so the cut
# starts clean. Every step reads job 128's uncommitted calibration record, which a clone of HEAD does not have, so all
# are `step_outward`; the checks below hold in a clone too.
JOB_TITLE="Resume release 0.41.0 after job 128 (stopped at the cut, /tmp full): cut, commit, tag locally, browser tier, core tier, push"
JOB_TASK="T-1387"
JOB_WHY="Job 128 stopped at step 5: the release build's render check could not start Chromium because /tmp was full.
Nothing was committed after the version bump and nothing was tagged or pushed. Steps 1-4 of job 128 stand: version
0.41.0 committed, the kit calibrated PASS by codex and GLM-5.3, the gate passed. This job continues from there:
  1 check job 128's calibration record still passes the gate, and remove the half-built artifact the failed cut left;
  2 cut release 0.41.0 (scripts/release-designer.sh, render gate ON);
  3 commit the release files;
  4 tag designer-v0.41.0, locally only;
  5 browser tier (about 20 minutes): if red, it stops and nothing is pushed;
  6 core tier (about 20 minutes);
  7 push bleeding-edge and the tag.
The checks refuse to start with less than 2 GB free in /tmp. Answer y at every step. Afterwards the agent tells AEF."

V=0.41.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
KIT="dist/aef-authoring-kit-$V"
OUT=.context/runme/129-release-0.41.0-resume
REC=docs/authoring-kit/calibration-records/$V.yaml
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V (job 128 bumped and committed it)" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ]'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "the index holds nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "tag $TAG does not exist locally" '! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null'
    check "tag $TAG does not exist on origin" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "at least 2 GB free in /tmp (job 128 stopped on a full /tmp)" '[ "$(df -Pk /tmp | awk "NR==2{print \$4}")" -ge 2097152 ]'
}

steps() {
    step_outward "Check job 128's calibration record passes the gate, and remove the half-built $ART left by the failed cut" 'do_prepare'
    step_outward "Cut release $V: scripts/release-designer.sh (render gate ON, announce ON; writes dist/)" 'do_cut'
    step_outward "Commit $ART, $KIT, dist/MANIFEST.yaml and the calibration record" 'do_commit'
    step_outward "Tag $TAG (annotated) on the release commit, locally only" 'do_tag'
    step_outward "Browser tier (about 20 minutes; T-1374): stops here if red, and nothing is pushed" 'do_browser'
    step_outward "Core tier (about 20 minutes, or cached), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
}

do_prepare() {
    [ -f "$REC" ] || { echo "no calibration record $REC (job 128 steps 2-3 wrote it)"; return 1; }
    python3 tools/kit-calibration-gate.py check --version "$V" || { echo "the calibration gate does not pass for $V"; return 1; }
    [ -e "$KIT" ] && { echo "$KIT already exists: look before cutting"; return 1; }
    if [ -f "$ART" ]; then git ls-files --error-unmatch "$ART" >/dev/null 2>&1 && { echo "$ART is tracked: refusing to remove"; return 1; }; rm -f "$ART"; echo "removed the half-built $ART"; fi
    echo "ok  calibration gate passes for $V; dist/ clean for the cut"
}

do_cut() {
    PATH="$NODEBIN:$PATH" scripts/release-designer.sh || { echo "release-designer.sh failed (see above); dist/ may need a look"; return 1; }
    { [ -f "$ART" ] && cmp -s src/aef-workflow-designer.html "$ART"; } || { echo "$ART missing or differs from src"; return 1; }
    (cd "$KIT" && sha256sum -c SHA256SUMS --quiet) || { echo "the kit does not verify against its SHA256SUMS"; return 1; }
    [ -f "$KIT/SKILL.md" ] || { echo "the kit has no SKILL.md (T-1376)"; return 1; }
    echo "ok  artifact == src, kit verifies and ships SKILL.md"
}

do_commit() {
    git add "$ART" "$KIT" dist/MANIFEST.yaml "$REC" || return 1
    git commit -q -m "T-1387: release designer $V — no invented lanes or pool on import, marked instead (T-358); the validator drops E-XML-LANES-EMPTY for a process with no laneSet (T-358); eventDef keeps unread content (T-347); kit calibrated on its bytes" \
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
