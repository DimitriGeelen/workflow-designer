# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Record your GO on import/export (T-1093): build it in the six-step order you approved"
JOB_TASK="T-1093"
JOB_WHY="You answered 'a' (2026-11-19): build import/export in the proposed order. Recording an inception decision is a
command only you may run, so it is this one step. What it records: GO, with the order 1) a named Import/Export menu
(BPMN/Camunda visible), 2) SVG, PNG, PDF out, 3) Mermaid and CSV out and in, 4) Excel out and in, 5) Word out,
6) Visio out and in (tested on a real Visio file). Both of 832's gates on a GO pass (hypothesis, readiness). Nothing
is pushed; the agent commits the closed task and opens the first build task."

T=T-1093
RATIONALE="Operator's ruling 'a' (2026-11-19, in session): GO in the agent's proposed order. Every requested format was produced in the browser with no library or server and has a stated fidelity promise (spikes in docs/reports/T-1093-spikes/, report docs/reports/T-1093-import-export-formats.md). Order: 1) named Import/Export menu, BPMN/Camunda visible; 2) SVG, PNG 1x/2x/4x, PDF via print stylesheet; 3) Mermaid and CSV out then in (BPMN without layout + Clean); 4) Excel out and in (ZIP core); 5) Word out; 6) Visio out, then in on a real operator file. One build task each, each with its round-trip or render test and its loss stated."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1093 is an active inception" 'grep -q "^workflow_type: inception" .tasks/active/T-1093-*.md'
    check "T-1093 is committed as is" 'git diff --quiet -- .tasks/active/T-1093-*.md'
    check "its recommendation reads GO" 'grep -q "^\*\*Recommendation:\*\* GO" .tasks/active/T-1093-*.md'
}

steps() {
    step_operator "Record GO on T-1093 (fw inception decide; only you may run it)" \
        '.agentic-framework/bin/fw inception decide $T go --rationale "$RATIONALE"'
}
