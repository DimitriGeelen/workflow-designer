# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# The decision is `step_operator` (T-1324): fw inception decide refuses in the agent's session, so it is never
# rehearsed. The commit needs the decision's result, so it is `step_outward`. Same checks as job 107 (T-1266).
JOB_TITLE="Decide T-1363: GO for 832's part of cross-system workflows (draw documents, catalog check; the rest waits for AEF T-4991)"
JOB_TASK="T-1363"
JOB_WHY="You asked to prepare the T-1363 decision. The agent recommends GO, for 832's part only.
What the exploration found (with greenfield, on its real WT-01 map): a process across five systems fits standard
BPMN plus the mapping v1.1 inputs and outputs. Instructions, screen states, documents, state-change triggers and
system events all have a standard form, and how a value is built lives in the project's ontology. What was missing
was display and checking, not modelling. Two gaps are already closed in 0.36.0 (conditional events by kind; value
rules in the panel).
GO means two bounded builds, then a stop until AEF's vocabulary (T-4991) decides:
  B1  draw documents (data objects with their state), keeping the save unchanged;
  B2  a validator check against the field catalog (field belongs to the io's object; a step rule must not contradict
      the attribute's rule). This check found 15 real errors in WT-01.
Conditions: each build tested on a made-up map that is not WT-01; nothing on decision status, keys between systems or
the user-started action before AEF T-4991; client data stays out of the repo.
Read: docs/reports/T-1363-cross-system-workflow-primitives.md (Synthesis and recommendation, at the end), and the
task's Recommendation and Go/No-Go evaluation. To decide otherwise, answer n at the step and tell the agent. Nothing is
pushed."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1363 is an active inception with no decision recorded" 'undecided'
    check "every Agent criterion is ticked (job 106 stopped on an open one)" 'agent_acs_ticked'
    check "its success clause is real (no template placeholder)" 'clause_real'
    check "the decide gate's readiness check passes (fw task review)" 'ready'
}

steps() {
    step_operator "T-1363: GO for 832's part (B1 draw documents, B2 catalog check; needs 3-6 wait for AEF T-4991)" 'decide_go'
    step_outward "Commit the decided task (only its files)" 'commit_decided'
}

task_file() { ls .tasks/active/T-1363-*.md 2>/dev/null | head -1; }

undecided() {
    local f; f=$(task_file)
    [ -n "$f" ] || { echo "T-1363 is not active"; return 1; }
    grep -q '^workflow_type: inception' "$f" || { echo "T-1363 is not an inception"; return 1; }
    grep -q '^\*\*Decision\*\*: \(GO\|NO-GO\|DEFER\)' "$f" && { echo "T-1363 already decided"; return 1; }
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
    local out; out=$(.agentic-framework/bin/fw task review T-1363 2>&1)
    grep -q 'Review marker created' <<<"$out" || { echo "no review marker; fw task review said:"; tail -8 <<<"$out"; return 1; }
    grep -q 'not handoff-ready' <<<"$out" && { echo "not handoff-ready"; return 1; }
    return 0
}

decide_go() {
    .agentic-framework/bin/fw inception decide T-1363 go --rationale "Operator (2026-11-02, recorded by job 118): GO for 832's part. Greenfield's WT-01 (five systems) fits standard BPMN plus mapping v1.1 by rules A-F; value rules live in the producer's ontology (SHACL shapes, via the field catalog). The gap was display and checking, not modelling. Already shipped in 0.36.0: conditional/signal events by kind (T-1366), value rules in the io panel (T-1365). Build next: B1 draw documents (data objects with dataState, save unchanged); B2 a validator check against the field catalog (field object = io typeRef; aef:expect contradicting the shape is an error, repeating it a warning). Conditions: each tested on a synthetic map that is not WT-01; no build on decision status, keys or the user-started action before AEF T-4991; client data stays out of the repo. Evidence: docs/reports/T-1363-cross-system-workflow-primitives.md."
}

commit_decided() {
    git add -A -- .tasks/active/T-1363-*.md .tasks/completed/T-1363-*.md .context/episodic/T-1363.yaml 2>/dev/null
    git diff --cached --name-only | grep -vE '^(\.tasks/(active|completed)/T-1363-|\.context/episodic/T-1363\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1363: operator's job 118 records the decision (GO for 832's part: B1 draw documents, B2 catalog check; the rest waits for AEF T-4991)" && git log --oneline -1
}
