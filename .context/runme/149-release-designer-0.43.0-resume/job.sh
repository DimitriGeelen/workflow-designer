# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# RESUMES job 148 (release 0.43.0) at its step 4. Job 148 stopped at 06:01Z: step 4 was not confirmed (the launcher
# received an empty Enter). Steps 1-3 had run: the bump is committed (4eb6aee59), and codex and GLM-5.3 both PASSed the
# kit (3/3 caught, 0 false), recorded in docs/authoring-kit/calibration-records/0.43.0.yaml (untracked until step 3
# here). The step bodies are job 148's, unchanged. Commits name only T-1422.
JOB_TITLE="Release designer 0.43.0, resumed at the gate: gate, cut, commit, tag designer-v0.43.0 locally, browser tier, core tier, push"
JOB_TASK="T-1422"
JOB_WHY="Job 148 stopped at its step 4 (the release gate) because that step got an empty Enter instead of y. Nothing went
wrong before it: VERSION is 0.43.0 (committed), and both kit calibrations PASSed (codex 3/3, GLM-5.3 3/3, 0 false
findings). This job carries on from there with job 148's own step code:
gate (reads the PASS record), cut (writes dist/), commit, tag locally, browser tier (about 25 min; stops if red, nothing
pushed), core tier (about 20 min), push. Answer y at every step. Nothing is calibrated again."

V=0.43.0
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
KIT="dist/aef-authoring-kit-$V"
OUT=.context/runme/149-release-designer-0.43.0-resume
REC=docs/authoring-kit/calibration-records/$V.yaml
RECABS=/opt/832-Workflow-designer/$REC   # untracked until step 3: a rehearsal clone has none, so checks read it here
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "./VERSION is $V (bumped by job 148, committed)" '[ "$(tr -d "[:space:]" < VERSION)" = "$V" ] && git diff --quiet HEAD -- VERSION'
    check "APP_VERSION in src matches VERSION (T-808)" 'bash tools/_t808-version-parity.sh >/dev/null'
    check "the $V calibration record holds a PASS for codex and for glm-5.3" '[ -s $RECABS ] && grep -q codex $RECABS && grep -q glm-5.3 $RECABS'
    check "the index holds nothing staged (T-1313)" '[ -z "$(git diff --cached --name-only)" ]'
    check "tag $TAG does not exist locally" '! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null'
    check "tag $TAG does not exist on origin" '! git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1'
    check "no $V artifact or kit in dist/ yet" '[ ! -e "$ART" ] && [ ! -e "$KIT" ]'
    check "/tmp has at least 4 GB free" '[ "$(df --output=avail -k /tmp | tail -1)" -gt 4194304 ]'
}

steps() {
    step_outward "Release gate: the $V kit carries a PASS calibration of its exact bytes" 'do_gate'
    step_outward "Cut release $V: scripts/release-designer.sh (render gate ON, announce ON; writes dist/)" 'do_cut'
    step_outward "Commit $ART, $KIT, dist/MANIFEST.yaml and the calibration record" 'do_commit'
    step_outward "Tag $TAG (annotated) on the release commit, locally only" 'do_tag'
    step_outward "Browser tier (about 25 minutes; T-1374): stops here if red, and nothing is pushed" 'do_browser'
    step_outward "Core tier (about 20 minutes, or cached), so the push finds it green" 'do_core'
    step_outward "Push bleeding-edge and $TAG to origin" 'do_push'
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
    git commit -q -m "T-1422: release designer $V — validator knows the kit's source: citation; kit: no callActivity advice, new exemplar built to every rule, guide and checklist aligned; kit calibrated on its bytes (codex 3/3, GLM-5.3 3/3)" \
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
    mkdir -p "$OUT"
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
