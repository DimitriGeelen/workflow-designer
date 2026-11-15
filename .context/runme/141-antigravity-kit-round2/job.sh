# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="T-979: Antigravity (Google) reads the authoring kit as a round-2 generator: map + what it had to guess"
JOB_TASK="T-979"
JOB_WHY="The kit's external panel has 2 of 3 readers (Codex, GLM); Antigravity is the third (operator, 2026-10-01).
It runs the registry's way (sudo -n -u dimitri-mint-dev, agy --mode plan --sandbox: read-only, unmetered, no
per-round approval per AEF policy/review-backends.yaml). It gets ONLY a copy of the kit and the synthetic source
(an invented bicycle wholesaler; no secrets, no host names). It prints a map and a report; the job saves both in this
job's out/ directory and runs the kit's validator on the map. Nothing is pushed or changed in the repo. Time: up to
about 30 minutes of model time."

AGY=/home/dimitri-mint-dev/.local/bin/agy
OUT=.context/runme/141-antigravity-kit-round2/out
KIT=docs/authoring-kit

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the kit and its synthetic source are present" '[ -s $KIT/AUTHORING.md ] && [ -s $KIT/GENERATE.md ] && [ -s $KIT/calibration/SOURCE.md ]'
}

steps() {
    step_outward "Check Antigravity can be started as dimitri-mint-dev (agy --help, 60 s)" 'do_probe'
    step_outward "Antigravity generates the map from the kit and source, and reports its guesses (up to 30 min)" 'do_run'
    step_outward "Save map.bpmn and REPORT.md from its answer, and run the kit validator on the map" 'do_extract'
}

do_probe() {
    mkdir -p "$OUT" || return 1
    timeout 60 sudo -n -u dimitri-mint-dev -H "$AGY" --help > "$OUT/agy-help.txt" 2>&1
    local rc=$?
    head -40 "$OUT/agy-help.txt"
    [ "$rc" = 0 ] || { echo "agy could not be started (rc $rc); see $OUT/agy-help.txt"; return 1; }
}

do_run() {
    local wd v
    v=$(tr -d '[:space:]' < VERSION)
    wd=$(mktemp -d /tmp/t979-agy.XXXXXX) || return 1
    python3 tools/build-authoring-kit.py --version "$v" --out "$wd/kit" > /dev/null || { echo "kit build failed"; return 1; }
    cp "$KIT/calibration/SOURCE.md" "$wd/SOURCE.md" || return 1
    # the kit ships calibration/ with a finished map of this same source: an answer key, removed so the read is blind
    rm -rf "$wd/kit/calibration"
    chmod -R a+rX "$wd" || return 1
    echo "kit $v built in $wd/kit ($(ls "$wd/kit" | wc -l) files), SHA256SUMS $(sha256sum "$wd/kit/SHA256SUMS" | cut -c1-16)"
    echo "$wd" > "$OUT/workdir.txt"
    local prompt="You are a vendor's generating agent. The authoring kit is in ./kit/ and the process source is ./SOURCE.md.
Use ONLY those files. Read ./kit/GENERATE.md and ./kit/AUTHORING.md and carry out GENERATE.md: turn SOURCE.md into a
BPMN map. You are in a read-only sandbox, so do not write files: PRINT your results instead, as exactly two fenced
blocks and nothing between them:
1) a block opened with \`\`\`xml containing the complete map.bpmn;
2) a block opened with \`\`\`markdown and starting with the line '# REPORT', containing three numbered lists:
   (a) everything you had to GUESS because neither the kit nor the source said it, and what you chose;
   (b) everything the kit's guide got WRONG, was unclear about, or contradicted itself on (cite file and section);
   (c) everything you were TEMPTED TO INVENT (add, connect or name beyond the source) and whether you did.
Be specific; an empty list is allowed only if it is true."
    ( cd "$wd" && timeout 1800 sudo -n -u dimitri-mint-dev -H "$AGY" -p "$prompt" --mode plan --sandbox ) \
        > "$OUT/agy.out" 2>&1
    local rc=$?
    echo "agy exit $rc; answer $(wc -c < "$OUT/agy.out") bytes in $OUT/agy.out"
    [ "$rc" = 0 ] && [ -s "$OUT/agy.out" ]
}

do_extract() {
    python3 - "$OUT" <<'PY' || return 1
import re, sys, os
out = sys.argv[1]
text = open(os.path.join(out, "agy.out"), encoding="utf-8", errors="replace").read()
blocks = re.findall(r"```(\w*)\s*\n(.*?)```", text, re.S)
m = [b for lang, b in blocks if "definitions" in b and "bpmn" in b.lower()]
r = [b for lang, b in blocks if b.lstrip().startswith("# REPORT")]
if not m: print("no BPMN block in the answer"); sys.exit(1)
if not r: print("no REPORT block in the answer"); sys.exit(1)
open(os.path.join(out, "map.bpmn"), "w").write(m[-1])
open(os.path.join(out, "REPORT.md"), "w").write(r[-1])
print("saved map.bpmn (%d bytes) and REPORT.md (%d bytes)" % (len(m[-1]), len(r[-1])))
PY
    python3 "$(cat "$OUT/workdir.txt")/kit/validate-workflow.py" "$OUT/map.bpmn" > "$OUT/validate.txt" 2>&1
    echo "validator exit $?: $(tail -1 "$OUT/validate.txt")"
    return 0
}
