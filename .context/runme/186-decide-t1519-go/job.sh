# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# A verb only the operator may run (fw inception decide) is `step_operator` (T-1324): never rehearsed.
JOB_TITLE="Record your GO on T-1519: a scope attribute (framework | project) on aef:workflowMeta"
JOB_TASK="T-1519"
JOB_WHY="You said 'go on T-1519' (2026-11-26). This records it with fw inception decide, the operator's verb.
What GO means: aef:workflowMeta/@scope = framework | project; a map without it is read as project (does not ship);
separate from kind. 832 builds the validator value check, the designer's Scope select and the docs; AEF builds the
vendoring filter. AEF agreed all four points (msg ab4c1d03) and AEF's operator confirmed (msg 7a18d0f0).
Additive and optional: no stored map changes or becomes invalid. One step. Nothing is pushed."

T=T-1519
RATIONALE="Operator GO 2026-11-26. Both sides agree (report docs/reports/T-1519-map-scope-attribute.md; AEF msg ab4c1d03, their T-5415; AEF operator confirmed msg 7a18d0f0): aef:workflowMeta/@scope = framework | project, absent read as project, separate from kind, no third value. 832 builds the validator value check (warning on other values), the designer Scope select, AUTHORING 6 and skill rule 1; AEF builds the fw vendor filter and its test and marks its framework maps, shipped together with 832's release. Additive and optional: no stored map changes or becomes invalid."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "$T is an active inception" 'f=$(ls .tasks/active/$T-*.md) && grep -q "^workflow_type: inception" "$f"'
    check "$T has no decision recorded yet" '! grep -qE "^\*\*Decision\*\*: (GO|NO-GO)" .tasks/active/$T-*.md'
    check "the agent recommendation is GO" 'grep -q "^\*\*Recommendation:\*\* GO" .tasks/active/$T-*.md'
    check "the hypothesis is in the three-part form the decide gate requires" 'grep -q "^we will achieve" .tasks/active/$T-*.md'
    check "the research report is committed" 'git ls-files --error-unmatch docs/reports/T-1519-map-scope-attribute.md >/dev/null && git diff --quiet HEAD -- docs/reports/T-1519-map-scope-attribute.md'
}

steps() {
    step_operator "Record GO on $T: fw inception decide $T go --rationale '…'" 'do_decide'
}

do_decide() {
    .agentic-framework/bin/fw inception decide "$T" go --rationale "$RATIONALE"
}
