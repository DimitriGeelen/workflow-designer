# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Re-calibrate the 0.20.0 kit with codex and GLM-5.3: the validator in it changed (T-1159)"
JOB_TASK="T-1170"
JOB_WHY="The 0.20.0 kit ships the validator (validate-workflow.py). Tonight's T-1159 fix changed it: the YAML form now
lets a node's own aef.authority win over its lane, as the BPMN form already did. The kit's bytes moved
(ffa08c70 -> be1d3c5e), so job 027's codex and GLM passes no longer cover what would ship, and the release gate refuses.
The kit reviews BPMN maps, whose checks did not change; this is the byte-exact rule doing its job. Same steps as 027:
build the kit, loop.sh --calibrate from it, record each result; a FAIL is recorded and not retried; the gate moves
027's runs into voided_runs. Antigravity is your run on this kit, as before, if you want it in the record.
Nothing is committed or pushed."

V=0.20.0
OUT=.context/runme/030-recalibrate-kit-0.20.0-validator
REC=docs/authoring-kit/calibration-records/0.20.0.yaml
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"
OCBIN="$HOME/.opencode/bin"
CODEX_CMD='codex exec --skip-git-repo-check --sandbox workspace-write'
GLM_CMD='opencode run -m zai-coding-plan/glm-5.3'

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the kit for $V builds" 'python3 tools/kit-calibration-gate.py kit-hash --version "$V" >/dev/null'
    check "the existing $V record measured an EARLIER build (job 027), not this one" 'h=$(python3 tools/kit-calibration-gate.py kit-hash --version "$V"); ! grep -q "^kit_sha256: $h" "$REC"'
    check "the validator in the kit is the committed one (no uncommitted change)" 'git diff --quiet HEAD -- tools/validate-workflow.py'
    check "codex is installed" 'PATH="$NODEBIN:$PATH" command -v codex >/dev/null'
    check "opencode is installed and lists zai-coding-plan/glm-5.3" 'PATH="$OCBIN:$PATH" timeout 60 opencode models 2>/dev/null | grep -qx "zai-coding-plan/glm-5.3"'
}

steps() {
    step "Calibrate with codex (OpenAI): build the $V kit, loop.sh --calibrate, record the result" 'do_calibrate codex openai "$CODEX_CMD"'
    step "Calibrate with GLM-5.3 (Z.AI, opencode): build the $V kit, loop.sh --calibrate, record the result" 'do_calibrate glm-5.3 zai "$GLM_CMD"'
    step "Show the record (027's runs now under voided_runs) and what the release gate says" 'do_show'
}

do_calibrate() {
    local name="$1" vendor="$2" cmd="$3" kit wd res rc
    kit=$(mktemp -d /tmp/t1170-kit-$name.XXXXXX) || return 1
    python3 tools/build-authoring-kit.py --version "$V" --out "$kit/kit" >/dev/null || { echo "kit build failed"; return 1; }
    wd="$OUT/calibrate-$name"; res="$OUT/calibrate-$name.out"
    mkdir -p "$wd"
    echo "kit: $kit/kit (sha256 of SHA256SUMS $(sha256sum "$kit/kit/SHA256SUMS" | cut -c1-16)...), reviewer: $cmd"
    ( export PATH="$NODEBIN:$OCBIN:$PATH" KIT_REVIEWER_CMD="$cmd"; bash "$kit/kit/loop.sh" --calibrate "$PWD/$wd" ) 2>&1 | tee "$res"
    python3 tools/kit-calibration-gate.py record --version "$V" --reviewer "$name" --vendor "$vendor" --result-file "$res"
    rc=$?
    rm -rf "$kit"
    grep -E 'CALIBRATION: (PASS|FAIL|COULD NOT MEASURE)' "$res" | tail -1
    [ "$rc" = 0 ] || { echo "$name did not PASS (recorded); the agent brings it to you"; return 1; }
}

do_show() {
    cat "$REC"
    python3 tools/kit-calibration-gate.py check --version "$V"
    return 0
}
