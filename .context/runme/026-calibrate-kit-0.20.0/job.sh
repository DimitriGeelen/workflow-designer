# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Calibrate authoring kit 0.20.0 with codex and GLM-5.3 (Antigravity: your run, as before)"
JOB_TASK="T-1170"
JOB_WHY="Release 0.20.0 (activities-only step numbers, tab title) needs its kit calibrated PASS on its exact bytes by
three vendors before the release job will cut it (ledger L16, tools/kit-calibration-gate.py). Your choice 1: this job
runs codex (OpenAI) and GLM-5.3 (Z.AI, via opencode) here; Antigravity (Google) you run the way you did for 0.19.1.
Guide, rubric and validator are unchanged since 0.19.1; only the version moves, which moves the kit's hash.
Each step builds the kit, runs loop.sh --calibrate from the built kit (the reviewer must catch the planted defects
and raise nothing on the clean map), saves the output in this job's folder and records the result with the gate. A
FAIL is recorded too and not retried: the agent brings it to you. Each run takes several minutes and uses the
reviewer's subscription. Nothing is committed or pushed; the agent commits the record afterwards."

V=0.20.0
OUT=.context/runme/026-calibrate-kit-0.20.0
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"
OCBIN="$HOME/.opencode/bin"
CODEX_CMD='codex exec --skip-git-repo-check --sandbox workspace-write'
GLM_CMD='opencode run -m zai-coding-plan/glm-5.3'

preflight() {
    check "the kit for $V builds" 'python3 tools/kit-calibration-gate.py kit-hash --version "$V" >/dev/null'
    check "codex is installed" 'PATH="$NODEBIN:$PATH" command -v codex >/dev/null'
    check "opencode is installed and lists zai-coding-plan/glm-5.3" 'PATH="$OCBIN:$PATH" timeout 60 opencode models 2>/dev/null | grep -qx "zai-coding-plan/glm-5.3"'
    check "no calibration record for $V yet" '[ ! -e docs/authoring-kit/calibration-records/$V.yaml ]'
}

steps() {
    step "Calibrate with codex (OpenAI): build the $V kit, loop.sh --calibrate, record the result" 'do_calibrate codex openai "$CODEX_CMD"'
    step "Calibrate with GLM-5.3 (Z.AI, opencode): build the $V kit, loop.sh --calibrate, record the result" 'do_calibrate glm-5.3 zai "$GLM_CMD"'
    step "Show the record and what the release gate says now (Antigravity still to come)" 'do_show'
}

do_calibrate() {
    local name="$1" vendor="$2" cmd="$3" kit wd res
    kit=$(mktemp -d /tmp/t1170-kit-$name.XXXXXX) || return 1
    python3 tools/build-authoring-kit.py --version "$V" --out "$kit/kit" >/dev/null || { echo "kit build failed"; return 1; }
    wd="$OUT/calibrate-$name"; res="$OUT/calibrate-$name.out"
    mkdir -p "$wd"
    echo "kit: $kit/kit (sha256 of SHA256SUMS $(sha256sum "$kit/kit/SHA256SUMS" | cut -c1-16)...), reviewer: $cmd"
    ( export PATH="$NODEBIN:$OCBIN:$PATH" KIT_REVIEWER_CMD="$cmd"; bash "$kit/kit/loop.sh" --calibrate "$PWD/$wd" ) 2>&1 | tee "$res"
    python3 tools/kit-calibration-gate.py record --version "$V" --reviewer "$name" --vendor "$vendor" --result-file "$res"
    local rc=$?
    rm -rf "$kit"
    [ "$rc" = 0 ] || { echo "recording the $name result failed (rc $rc)"; return 1; }
    grep -E 'CALIBRATION: (PASS|FAIL|COULD NOT MEASURE)' "$res" | tail -1
}

do_show() {
    cat docs/authoring-kit/calibration-records/$V.yaml
    python3 tools/kit-calibration-gate.py check --version "$V" || echo "(expected while Antigravity has not run: the release gate wants every vendor's PASS)"
    return 0
}
