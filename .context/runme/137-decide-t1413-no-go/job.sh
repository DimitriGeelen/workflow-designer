# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# Job 136's shape. The decision is `step_operator` (T-1324): fw inception decide refuses in the agent's session, so it
# is never rehearsed. The commit needs the decision's result, so it is `step_outward`.
JOB_TITLE="Decide T-1413: NO-GO on running 832 as a ring20 swarm (Docker) service"
JOB_TASK="T-1413"
JOB_WHY="Your inception of 2026-11-14 ('Do we want to start moving it into a docker-type style of service?'), after
external consultation. Answering y records NO-GO; answering n records nothing (then tell the agent what you want).
Why NO-GO (independent reviewer: green, 'the NO-GO recommendation is supported'):
- AEF: the vendored single HTML file stays their contract; a hosted 832 changes nothing they depend on; they know of no
  users outside AEF/Watchtower.
- ring20: their closest precedent (workshop-designer, one HTML designer) was moved OFF swarm in May to a static app; a
  read-only designer is not worth a swarm service; only a server that writes would justify one, with auth + backups;
  they know of no users in the fleet.
- The audit's deployment section is opt-in (runs only with --section deployment), so nothing in 832 changes; the three
  old warnings T-752..T-754 close on this ruling.
Open option, NOT decided here: an always-on public read-only designer (static app, as workshop-designer) as its own
small task, if you want one to show. Read: docs/reports/T-1413-docker-service-inception.md. Nothing is pushed."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1413 is an active inception with no decision recorded" 'undecided'
    check "its success clause is real (no template placeholder)" 'clause_real'
    check "the decide gate's readiness check passes (fw task review)" 'ready'
}

steps() {
    step_operator "T-1413: NO-GO (832 stays one vendored file; no swarm service; deployment section stays opt-in)" 'decide_no_go'
    step_outward "Commit the decided task (only its files)" 'commit_decided'
}

task_file() { ls .tasks/active/T-1413-*.md 2>/dev/null | head -1; }

undecided() {
    local f; f=$(task_file)
    [ -n "$f" ] || { echo "T-1413 is not active"; return 1; }
    grep -q '^workflow_type: inception' "$f" || { echo "T-1413 is not an inception"; return 1; }
    grep -q '^\*\*Decision\*\*: \(GO\|NO-GO\|DEFER\)' "$f" && { echo "T-1413 already decided"; return 1; }
    return 0
}

clause_real() {
    local line; line=$(grep -m1 '^We will know that we are successful when we see' "$(task_file)")
    [ -n "$line" ] || { echo "no success clause"; return 1; }
    case "$line" in *'[NEEDS YOU'*|*'<measurable signal>'*) echo "placeholder success clause"; return 1 ;; esac
}

ready() {
    local out; out=$(.agentic-framework/bin/fw task review T-1413 2>&1)
    grep -q 'Review marker created' <<<"$out" || { echo "no review marker; fw task review said:"; tail -8 <<<"$out"; return 1; }
    grep -q 'not handoff-ready' <<<"$out" && { echo "not handoff-ready"; return 1; }
    return 0
}

decide_no_go() {
    .agentic-framework/bin/fw inception decide T-1413 no-go --rationale "Operator (2026-11-14, job 137), after external consultation and an independent review (green, V-20261114-e8788bd9): 832 does not become a ring20 swarm service. AEF (msg 1d7d8b4b): the vendored single HTML file stays the contract; a hosted 832 changes nothing AEF depends on; no known users outside AEF/Watchtower. ring20 (msg b86d15f0): the closest precedent, workshop-designer, was moved off swarm to a static app; a read-only designer does not warrant a swarm service; only a writing server would, with auth and backups; no known fleet users. The audit's deployment section is opt-in (--section deployment only), so nothing in 832 changes and T-752..T-754 close on this ruling. Not decided here: an optional always-on public read-only designer as a static app, its own task if wanted."
}

commit_decided() {
    git add -A -- .tasks/active/T-1413-*.md .tasks/completed/T-1413-*.md .context/episodic/T-1413.yaml 2>/dev/null
    git diff --cached --name-only | grep -vE '^(\.tasks/(active|completed)/T-1413-|\.context/episodic/T-1413\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1413: operator's job 137 records the decision (NO-GO: 832 stays one vendored file, no swarm service)" && git log --oneline -1
}
