# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Record the GO on inception T-1215 (plain bpmn:task: AEF accepts it with a round trip, option a), as the reviewer judged it"
JOB_TASK="T-1215"
JOB_WHY="The framework classes an inception decision as Tier 0, so it is yours to record. The independent reviewer
judged the go/no-go green on 2026-10-20, after an amber that corrected the evidence (8 of 11 third-party fixtures carry a
plain bpmn:task; our own kit's example is one). GO means option (a): AEF's intake accepts bpmn:task with a round trip
(AEF said they would file it as a TYPE_TO_TAG addition, like callActivity in their T-4374, on our decision); the designer
changes nothing, it already keeps bpmn:task. Nothing is built by this job. If you disagree, do not run it; tell the
agent, and it records NO-GO or DEFER instead."

RATIONALE="Reviewer green (2026-10-20, after evidence correction). Plain bpmn:task is common (8/11 third-party fixtures; the authoring kit's own example) and AEF can accept it cheaply with a round trip (msg abc0de1e); converting it in the designer would invent an executor and rewrite authors' maps. Option (a); no designer change."

preflight() {
    check "T-1215 is an active inception" 'grep -q "^workflow_type: inception" .tasks/active/T-1215-*.md'
    check "no decision is recorded on T-1215 yet" '! grep -q "^\*\*Decision\*\*:" .tasks/active/T-1215-*.md'
    check "the reviewer verdict on T-1215 is green" 'grep "\"T-1215\"" .context/reviews/verdicts.jsonl | tail -1 | grep -q "\"verdict\": *\"green\""'
}

steps() {
    step "Record GO on T-1215 (fw inception decide)" '.agentic-framework/bin/fw inception decide T-1215 go --rationale "$RATIONALE"'
}
