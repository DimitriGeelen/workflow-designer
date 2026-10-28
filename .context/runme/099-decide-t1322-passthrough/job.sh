# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
JOB_TITLE="Decide T-1322: GO on keeping the third-party BPMN content a save drops (generic passthrough + open notice)"
JOB_TASK="T-1322"
JOB_WHY="Opening a BPMN file from another tool and saving it unedited loses content today, silently: measured in the
real editor, 7 of the 11 third-party test files lose 383 items outside the diagram geometry (Bizagi/CaseAgile/Zeebe
extensions 300; a gateway's default flow, isInterrupting, loop markers, annotations 74; attributes and a comment 9).
The last six fixes each added one name to what the designer reads; that never finishes for vendor extensions.
The agent recommends GO on option A: every element keeps what the designer does not read and writes it back in place,
references rewritten to the new ids; plus an open notice naming what still cannot be kept (diagram geometry,
subprocess nesting, nested lanes). Three build slices of about a session each. Maps the designer wrote do not change.
Read first: docs/reports/T-1322-third-party-passthrough.md (sections 2 and 5), or Watchtower /inception/T-1322.
To decide otherwise (NO-GO, DEFER, or B/C only), answer n at the step and tell the agent. Nothing is pushed."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1322 is an active inception with no decision recorded" 'undecided'
    check "its success clause is real (no template placeholder)" 'clause_real'
    check "the decide gate's readiness check passes (fw task review)" 'ready'
}

# Both steps are step_outward, not because they leave the repo but because the rehearsal runs in the agent's session,
# where fw inception decide refuses by design (T-679: the decision is the operator's). Rehearsing it would need
# --i-am-human from an agent, which is the thing the gate exists to stop. The commit needs the decision's result.
# Gap filed as T-1324.
steps() {
    step_outward "T-1322: GO, option A (generic per-element passthrough) with option C's open notice for the rest" 'decide_go'
    step_outward "Commit the decided task (only its files)" 'commit_decided'
}

task_file() { ls .tasks/active/T-1322-*.md 2>/dev/null | head -1; }

undecided() {
    local f; f=$(task_file)
    [ -n "$f" ] || { echo "T-1322 is not active"; return 1; }
    grep -q '^workflow_type: inception' "$f" || { echo "T-1322 is not an inception"; return 1; }
    grep -q '^\*\*Decision\*\*: \(GO\|NO-GO\|DEFER\)' "$f" && { echo "T-1322 already decided"; return 1; }
    return 0
}

clause_real() {
    local line; line=$(grep -m1 '^We will know that we are successful when we see' "$(task_file)")
    [ -n "$line" ] || { echo "no success clause"; return 1; }
    case "$line" in *'[NEEDS YOU'*|*'<measurable signal>'*) echo "placeholder success clause"; return 1 ;; esac
}

ready() {
    local out; out=$(.agentic-framework/bin/fw task review T-1322 2>&1)
    printf '%s\n' "$out" | grep -q 'Review marker created' || { echo "no review marker"; return 1; }
    printf '%s\n' "$out" | grep -q 'not handoff-ready' && { echo "not handoff-ready"; return 1; }
    return 0
}

decide_go() {
    .agentic-framework/bin/fw inception decide T-1322 go --rationale "Operator (job 099): GO on option A, a generic per-element passthrough for the BPMN content the designer does not model, with option C's open notice for what A cannot keep (F6 geometry, F8 subprocess nesting, F9 nested lanes). Evidence: docs/reports/T-1322-third-party-passthrough.md, 7 of 11 third-party fixtures lose 383 non-DI items on one unedited save. Build in three slices (per-element; process-level with reference rewrite; comments + notice); F3/F4 ids and F6/F8/F9 models are separate decisions."
}

commit_decided() {
    git add -A -- .tasks/active/T-1322-*.md .tasks/completed/T-1322-*.md .context/episodic/T-1322.yaml 2>/dev/null
    git diff --cached --name-only | grep -vE '^(\.tasks/(active|completed)/T-1322-|\.context/episodic/T-1322\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1322: operator's job 099 records the decision (GO: generic per-element passthrough + open notice)" && git log --oneline -1
}
