# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Record the GO on inception T-1219 (traceable data elements on aef:io), as the reviewer judged it"
JOB_TASK="T-1219"
JOB_WHY="The framework classes an inception decision as Tier 0, so it is yours to record. The independent reviewer
judged the go/no-go green on 2026-10-19 (after an amber that asked for the template to be filled, which it now is).
GO means: keeping unknown aef: attributes through a save is built (T-1220, planned for 0.24.0); the new fields (ref,
role, cardinality, dataType) follow AEF's mapping-v1.1 inception T-4415 and get designer fields only after AEF's
operator rules on it. Nothing is built by this job; it only records the decision on the task.
If you disagree, do not run it; tell the agent, and it records NO-GO or DEFER instead."

RATIONALE="Reviewer green (2026-10-19). Preservation of unknown aef: attributes is built as T-1220 (planned for 0.24.0, T-1223); the fields ref/role/cardinality/dataType follow AEF's mapping-v1.1 inception T-4415 and get designer fields only after AEF's operator rules on it."

preflight() {
    check "T-1219 is an active inception" 'grep -q "^workflow_type: inception" .tasks/active/T-1219-*.md'
    check "no decision is recorded on T-1219 yet" '! grep -q "^\*\*Decision\*\*:" .tasks/active/T-1219-*.md'
    check "the reviewer verdict on T-1219 is green" 'grep "\"T-1219\"" .context/reviews/verdicts.jsonl | tail -1 | grep -q "\"verdict\": *\"green\""'
}

steps() {
    step "Record GO on T-1219 (fw inception decide)" '.agentic-framework/bin/fw inception decide T-1219 go --rationale "$RATIONALE"'
}
