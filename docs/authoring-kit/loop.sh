#!/usr/bin/env bash
# loop.sh — the generate -> validate -> review -> correct loop, provider-agnostic (T-983, T-982 GO).
#
# The generator and the reviewer are AGENTS you configure; this script only sequences them and
# keeps every round's artefacts. Use a reviewer from a different model or vendor than the
# generator: a reviewer that shares the generator's training shares its blind spots.
#
#   KIT_GENERATOR_CMD  command prefix that runs the generating agent on one prompt, in the CWD,
#                      allowed to read the kit and write files there. Example:
#                        KIT_GENERATOR_CMD='codex exec --skip-git-repo-check --sandbox workspace-write'
#   KIT_REVIEWER_CMD   the same for the reviewing agent. Example:
#                        KIT_REVIEWER_CMD='opencode run -m <provider/model>'
#
#   PROMPT PLACEMENT (0.15.3, L17): the prompt is appended as the command's LAST argument, so the
#   command must end where your CLI parses one more argument as the prompt. Known case: claude's
#   --allowedTools takes several values (<tools...>) and swallows an appended prompt, so the agent
#   starts with none (Evergreen K9: COULD NOT MEASURE until the option was moved). Put such an
#   option before a fully supplied single-value option, e.g.
#                        KIT_REVIEWER_CMD='claude --allowedTools Read Write -p'
#   and check your own CLI for options that take several values or still await one.
#
# Usage:
#   loop.sh <workdir> <source.md> [max_rounds]   run the loop on a source; default 4 rounds
#   loop.sh --calibrate <workdir>                prove the configured reviewer still catches the
#                                                kit's planted defects (calibration/) and raises
#                                                nothing on the clean control map
#   loop.sh --review-only <workdir> <source.md> <map.bpmn>
#                                                one review round of a map you already wrote,
#                                                needs only KIT_REVIEWER_CMD; writes review.rN.json
#                                                (N = next free). Correct the map yourself per
#                                                CORRECT.md, then run it again (T-993, K7)
#
# WHERE TO RUN IT (T-993, K7): from a plain shell or CI. This script starts agents; an agent
# harness may refuse to let one agent start others, and then no review round runs at all.
#
# REVIEWER CONTEXT (T-993, K8): every review prompt's size is printed (estimated tokens = bytes/4
# of REVIEW.md + RUBRIC.md + SOURCE.md + map.bpmn). Set KIT_REVIEWER_CONTEXT=<tokens> to the
# reviewer's real context window and a review it cannot read whole is refused instead of run.
#
# Stop rule: a review round with zero findings, or max_rounds. Every round's map.rN.bpmn,
# review.rN.json and corrections.rN.json is kept: the corrections' "lesson" fields are the loop's
# learnings, and they are meant to be read and promoted (guide, rubric, validator, source owner).
set -u
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

need_cmds() {
    local missing=""
    [ -n "${KIT_GENERATOR_CMD:-}" ] || missing="$missing KIT_GENERATOR_CMD"
    [ -n "${KIT_REVIEWER_CMD:-}" ] || missing="$missing KIT_REVIEWER_CMD"
    if [ -n "$missing" ]; then
        echo "loop.sh: refusing to start: set$missing (see the header of this file)" >&2
        exit 2
    fi
}
agent() {  # agent <prefix> <prompt>
    bash -c "$1 \"\$1\"" _ "$2" < /dev/null >> agents.log 2>&1
}
log() { echo "$(date +%H:%M:%S) $*" | tee -a LOOP.txt; }
# T-991: every agent works on a COPY of the kit inside its own working directory, and every
# prompt names only ./kit/ paths. Sandboxed agents (opencode, for one) refuse to read outside
# their working directory: 0.15.0 pointed them at the kit by absolute path, and a real
# calibration with such a reviewer could not even read REVIEW.md ("external_directory ...
# auto-rejecting"). The stub tests missed it because stubs have no sandbox.
stage_kit() {  # stage_kit <dir>
    mkdir -p "$1/kit" || return 1
    local f
    for f in AUTHORING.md CONFORMANCE.md RUBRIC.md GENERATE.md REVIEW.md CORRECT.md \
             validate-workflow.py exemplar.bpmn; do
        [ -f "$KIT/$f" ] && cp "$KIT/$f" "$1/kit/$f"
    done
}
prompt_tokens() {  # prompt_tokens <dir>: estimated tokens a reviewer must read in one prompt
    cat "$1/kit/REVIEW.md" "$1/kit/RUBRIC.md" "$1/SOURCE.md" "$1/map.bpmn" 2>/dev/null | wc -c | awk '{print int($1/4)+1}'
}
fits() {  # fits <dir>: print the size; return 1 if KIT_REVIEWER_CONTEXT is set and too small
    local n; n=$(prompt_tokens "$1")
    if [ -n "${KIT_REVIEWER_CONTEXT:-}" ] && [ "$n" -gt "$KIT_REVIEWER_CONTEXT" ]; then
        echo "review prompt ~${n} tokens > KIT_REVIEWER_CONTEXT=${KIT_REVIEWER_CONTEXT}: the reviewer cannot read it whole; REFUSED" | tee -a "$1/LOOP.txt" >&2
        return 1
    fi
    echo "review prompt ~${n} tokens (reviewer context ${KIT_REVIEWER_CONTEXT:-not declared})" | tee -a "$1/LOOP.txt"
}
count() {
    python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(len(d))" "$1" 2>/dev/null || echo ERR
}

if [ "${1:-}" = "--calibrate" ]; then
    [ -n "${KIT_REVIEWER_CMD:-}" ] || { echo "loop.sh: --calibrate needs KIT_REVIEWER_CMD" >&2; exit 2; }
    WD="${2:?usage: loop.sh --calibrate <workdir>}"
    for which in clean planted; do
        mkdir -p "$WD/$which" && cp "$KIT/calibration/SOURCE.md" "$WD/$which/SOURCE.md"
        cp "$KIT/calibration/$which.bpmn" "$WD/$which/map.bpmn"
        stage_kit "$WD/$which" || { echo "loop.sh: could not stage the kit" >&2; exit 2; }
        fits "$WD/$which" || { echo "CALIBRATION: COULD NOT MEASURE (reviewer context too small)"; exit 3; }
        ( cd "$WD/$which" && rm -f REVIEW.json && agent "$KIT_REVIEWER_CMD" \
            "The kit is in ./kit/. Read ./kit/REVIEW.md and carry it out completely." )
    done
    python3 - "$KIT/calibration/expected.json" "$WD/clean/REVIEW.json" "$WD/planted/REVIEW.json" <<'PY'
import json, sys
exp = json.load(open(sys.argv[1]))["planted"]
def load(p):
    try: return json.load(open(p))
    except Exception: return None
clean, planted = load(sys.argv[2]), load(sys.argv[3])
if clean is None or planted is None:
    print("CALIBRATION: COULD NOT MEASURE (a reviewer wrote no parseable REVIEW.json)"); sys.exit(3)
# A defect is caught when a finding names ANY element that implements it with ANY category
# that truthfully describes it (T-991: a correct reviewer reported the wired-in inspection as
# 'invented' on the FLOW, and exact node+category matching scored that correct catch as a miss).
def hits(e, f):
    return f.get("element") in e["elements"] and f.get("category") in e["categories"]
caught = [e for e in exp if any(hits(e, f) for f in planted)]
planted_ids = {x for e in exp for x in e["elements"]}
false_planted = [f for f in planted if f.get("element") not in planted_ids]
print("recall: %d/%d planted defects caught" % (len(caught), len(exp)))
for e in exp:
    print("  %s %-34s %s" % ("caught" if e in caught else "MISSED", "/".join(e["categories"]), e["elements"][0]))
print("false findings: %d on the clean map, %d on unplanted elements" % (len(clean), len(false_planted)))
ok = len(caught) == len(exp) and not clean and not false_planted
print("CALIBRATION: %s" % ("PASS" if ok else "FAIL"))
sys.exit(0 if ok else 1)
PY
    exit $?
fi

if [ "${1:-}" = "--review-only" ]; then
    [ -n "${KIT_REVIEWER_CMD:-}" ] || { echo "loop.sh: --review-only needs KIT_REVIEWER_CMD" >&2; exit 2; }
    WD="${2:?usage: loop.sh --review-only <workdir> <source.md> <map.bpmn>}"; SRC="${3:?source.md}"; MAP="${4:?map.bpmn}"
    mkdir -p "$WD" && cp "$SRC" "$WD/SOURCE.md" && cp "$MAP" "$WD/map.bpmn" && stage_kit "$WD" && cd "$WD" || exit 2
    r=1; while [ -e "review.r$r.json" ]; do r=$((r + 1)); done
    cp map.bpmn "map.r$r.reviewed.bpmn"
    log "review-only round $r; validator: $(python3 kit/validate-workflow.py map.bpmn | tail -1)"
    fits . || exit 3
    rm -f REVIEW.json
    agent "$KIT_REVIEWER_CMD" "The kit is in ./kit/. Read ./kit/REVIEW.md and carry it out completely."
    n=$(count REVIEW.json)
    [ "$n" = ERR ] && { log "STOPPED: no parseable REVIEW.json"; exit 1; }
    cp REVIEW.json "review.r$r.json"
    log "review-only round $r: $n finding(s)$([ "$n" = 0 ] && echo ': DONE, clean review')"
    [ "$n" = 0 ] && exit 0 || exit 1
fi

need_cmds
WD="${1:?usage: loop.sh <workdir> <source.md> [max_rounds]}"; SRC="${2:?source.md}"; MAX="${3:-4}"
mkdir -p "$WD" && cp "$SRC" "$WD/SOURCE.md" && stage_kit "$WD" && cd "$WD" || exit 2
PRE="The kit is in ./kit/."

log "round 0: generate"
agent "$KIT_GENERATOR_CMD" "$PRE Read ./kit/GENERATE.md and carry it out completely."
[ -s map.bpmn ] || { log "STOPPED: the generator wrote no map.bpmn"; exit 1; }
cp map.bpmn map.r0.bpmn
log "validator: $(python3 kit/validate-workflow.py map.bpmn | tail -1)"
for r in $(seq 1 "$MAX"); do
    rm -f REVIEW.json
    log "round $r: review"
    fits . || { log "STOPPED: reviewer context too small in round $r"; exit 3; }
    agent "$KIT_REVIEWER_CMD" "$PRE Read ./kit/REVIEW.md and carry it out completely."
    n=$(count REVIEW.json)
    [ "$n" = ERR ] && { log "STOPPED: no parseable REVIEW.json in round $r"; exit 1; }
    cp REVIEW.json "review.r$r.json"
    log "round $r: $n finding(s)"
    [ "$n" = 0 ] && { log "DONE: clean review in round $r"; exit 0; }
    rm -f CORRECTIONS.json
    log "round $r: correct"
    agent "$KIT_GENERATOR_CMD" "$PRE Read ./kit/CORRECT.md and carry it out completely."
    [ "$(count CORRECTIONS.json)" = ERR ] && { log "STOPPED: no parseable CORRECTIONS.json in round $r"; exit 1; }
    cp CORRECTIONS.json "corrections.r$r.json"; cp map.bpmn "map.r$r.bpmn"
    log "validator: $(python3 kit/validate-workflow.py map.bpmn | tail -1)"
done
log "DONE: $MAX rounds without a clean review; read review.r$MAX.json"
exit 1
