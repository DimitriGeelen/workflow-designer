# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Re-calibrate the corrected 0.20.0 kit with codex and GLM-5.3 (Antigravity: your run, as before)"
JOB_TASK="T-1173"
JOB_WHY="Job 026: codex PASS, GLM-5.3 FAIL with one correct finding on the clean calibration map (the Warehouse lane's
second quote joined the source's line break, so it was not verbatim; it came in with T-1136 for 0.19.1). Your choice 1:
both calibration maps fixed (T-1173), and the kit re-calibrated by all three vendors. The fix changed the kit's bytes,
so 026's results no longer apply; the gate now moves them into voided_runs (with GLM's finding) instead of dropping
them. Same steps as 026: build the kit, loop.sh --calibrate from it, record each result; a FAIL is recorded and not
retried. Antigravity you run on this corrected kit, as before. Nothing is committed or pushed."

V=0.20.0
OUT=.context/runme/027-recalibrate-kit-0.20.0
REC=docs/authoring-kit/calibration-records/0.20.0.yaml
NODEBIN="$HOME/.nvm/versions/node/v22.22.1/bin"
OCBIN="$HOME/.opencode/bin"
CODEX_CMD='codex exec --skip-git-repo-check --sandbox workspace-write'
GLM_CMD='opencode run -m zai-coding-plan/glm-5.3'

preflight() {
    check "the kit for $V builds" 'python3 tools/kit-calibration-gate.py kit-hash --version "$V" >/dev/null'
    check "every quote in the clean calibration map is verbatim in SOURCE.md (T-1173)" 'python3 -c "import re,sys; src=open(\"docs/authoring-kit/calibration/SOURCE.md\").read(); sys.exit(0 if all(q in src for q in re.findall(r\"source: \\\"([^\\\"]*)\\\"\", open(\"docs/authoring-kit/calibration/clean.bpmn\").read())) else 1)"'
    check "the existing $V record measured an EARLIER build (job 026), not this one" 'h=$(python3 tools/kit-calibration-gate.py kit-hash --version "$V"); ! grep -q "^kit_sha256: $h" "$REC"'
    check "codex is installed" 'PATH="$NODEBIN:$PATH" command -v codex >/dev/null'
    check "opencode is installed and lists zai-coding-plan/glm-5.3" 'PATH="$OCBIN:$PATH" timeout 60 opencode models 2>/dev/null | grep -qx "zai-coding-plan/glm-5.3"'
}

steps() {
    step "Calibrate with codex (OpenAI): build the corrected $V kit, loop.sh --calibrate, record the result" 'do_calibrate codex openai "$CODEX_CMD"'
    step "Calibrate with GLM-5.3 (Z.AI, opencode): build the corrected $V kit, loop.sh --calibrate, record the result" 'do_calibrate glm-5.3 zai "$GLM_CMD"'
    step "Show the record (026's runs now under voided_runs) and what the release gate says" 'do_show'
}

do_calibrate() {
    local name="$1" vendor="$2" cmd="$3" kit wd res rc
    kit=$(mktemp -d /tmp/t1173-kit-$name.XXXXXX) || return 1
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
