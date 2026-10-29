# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
JOB_TITLE="Decide T-1266: GO on keeping subprocess nesting on save (option a, drawn flat; two slices)"
JOB_TASK="T-1266"
JOB_WHY="You said GO (2026-10-29) on the agent's recommendation; this records it (job 106 stopped: two Agent criteria were not ticked; fw inception decide is yours to run).
Today a save of another tool's file moves subprocess contents up into the process, so an engine runs a different
process (boundary-events gains its only start event at top level; kitchen-sink 4 -> 16 top-level starts). Option (a):
remember each nested node's subprocess at import and write nodes and flows back inside it on save, still drawn flat.
Slice 1 the plain round-trip (validator and notice updated); slice 2 the edit rules (a moved node stays nested, a flow
across the boundary is refused, deleting a subprocess moves its contents up and says so). Designer-written maps do not
change. Read: docs/reports/T-1266-subprocess-nesting.md (Findings, Options compared, Recommendation).
To decide otherwise, answer n at the step and tell the agent. Nothing is pushed."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1266 is an active inception with no decision recorded" 'undecided'
    check "every Agent criterion is ticked (job 106 stopped here: fw inception decide refuses on an open one)" 'agent_acs_ticked'
    check "its success clause is real (no template placeholder)" 'clause_real'
    check "the decide gate's readiness check passes (fw task review)" 'ready'
}

# Both steps are step_outward, not because they leave the repo but because the rehearsal runs in the agent's session,
# where fw inception decide refuses by design (T-679: the decision is the operator's). Rehearsing it would need
# --i-am-human from an agent, which is the thing the gate exists to stop. The commit needs the decision's result.
# Gap filed as T-1324.
steps() {
    step_outward "T-1266: GO, option (a): keep subprocess nesting on save, drawn flat (two build slices)" 'decide_go'
    step_outward "Commit the decided task (only its files)" 'commit_decided'
}

task_file() { ls .tasks/active/T-1266-*.md 2>/dev/null | head -1; }

undecided() {
    local f; f=$(task_file)
    [ -n "$f" ] || { echo "T-1266 is not active"; return 1; }
    grep -q '^workflow_type: inception' "$f" || { echo "T-1266 is not an inception"; return 1; }
    grep -q '^\*\*Decision\*\*: \(GO\|NO-GO\|DEFER\)' "$f" && { echo "T-1266 already decided"; return 1; }
    return 0
}

agent_acs_ticked() {
    local open; open=$(awk '/^### Agent/{a=1;next} /^### /{a=0} a && /^- \[ \]/' "$(task_file)")
    [ -z "$open" ] || { echo "open Agent criteria:"; echo "$open"; return 1; }
}

clause_real() {
    local line; line=$(grep -m1 '^We will know that we are successful when we see' "$(task_file)")
    [ -n "$line" ] || { echo "no success clause"; return 1; }
    case "$line" in *'[NEEDS YOU'*|*'<measurable signal>'*) echo "placeholder success clause"; return 1 ;; esac
}

ready() {
    local out; out=$(.agentic-framework/bin/fw task review T-1266 2>&1)
    # on failure, show what the review said (job 106's first rehearsal only reported "no review marker")
    grep -q 'Review marker created' <<<"$out" || { echo "no review marker; fw task review said:"; tail -8 <<<"$out"; return 1; }
    grep -q 'not handoff-ready' <<<"$out" && { echo "not handoff-ready"; return 1; }
    return 0
}

decide_go() {
    .agentic-framework/bin/fw inception decide T-1266 go --rationale "Operator (2026-10-29, recorded by job 107): GO on option (a) — record each nested node's parent subprocess at import and write nodes and flows back inside their container on save, still drawn flat; slice 1 round-trip (validator walks containers, nested nodes outside lanes are not E-XML-NODE-UNASSIGNED, notice updated, T-523 re-pinned), slice 2 edit rules (moved node stays nested, flow across the boundary refused, deleting a subprocess moves its contents up and says so, new nodes never nested). Not (b): canvas redesign for a case AEF never has. Evidence: docs/reports/T-1266-subprocess-nesting.md."
}

commit_decided() {
    git add -A -- .tasks/active/T-1266-*.md .tasks/completed/T-1266-*.md .context/episodic/T-1266.yaml 2>/dev/null
    git diff --cached --name-only | grep -vE '^(\.tasks/(active|completed)/T-1266-|\.context/episodic/T-1266\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1266: operator's job 107 records the decision (GO: keep subprocess nesting on save, option a, two slices)" && git log --oneline -1
}
