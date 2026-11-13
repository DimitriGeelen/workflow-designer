# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# Job 121's shape. The decision is `step_operator` (T-1324): fw inception decide refuses in the agent's session, so it
# is never rehearsed. The commit needs the decision's result, so it is `step_outward`. T-1397's Agent criteria carry
# @auto-tick-on-decide, so the decision ticks them; no check for them here.
JOB_TITLE="Decide T-1397: GO for running 832's test tiers on ring20's pool (your ruling of 2026-11-12, recorded)"
JOB_TASK="T-1397"
JOB_WHY="This records the ruling you already gave in conversation on 2026-11-12, so the build can start. Nothing new
to judge: trust the ring20 pool; for high-risk changes, two independent runs on two different machines; releases keep
their local run.
What is agreed with ring20 (their operator gave the GO; their T-2651): 832's two tiers run in their sandboxed pool on
quiet amd64 VMs (no network, no user namespaces, up to 1 h, 1 GiB core / 3 GiB browser). Code goes from git only;
staging only from build/pool/stage/, so build/peer-data (the client's documents) never leaves .107.
GO means building: the launcher tools/pool/run-tier.sh, harnesses honouring PLAYWRIGHT_BROWSERS_PATH, pool-only
exceptions for the few mount-namespace tests, three pool-vs-local comparison runs, and only then the push gate
accepting a matching pool green. Read: the task's Recommendation, Go/No-Go Criteria and Decisions. To decide otherwise,
answer n at the step and tell the agent. Nothing is pushed."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1397 is an active inception with no decision recorded" 'undecided'
    check "its success clause is real (no template placeholder)" 'clause_real'
    check "the decide gate's readiness check passes (fw task review)" 'ready'
}

steps() {
    step_operator "T-1397: GO (832's tiers on ring20's pool; pool green counts; two runs on different machines for high-risk; releases stay local)" 'decide_go'
    step_outward "Commit the decided task (only its files)" 'commit_decided'
}

task_file() { ls .tasks/active/T-1397-*.md 2>/dev/null | head -1; }

undecided() {
    local f; f=$(task_file)
    [ -n "$f" ] || { echo "T-1397 is not active"; return 1; }
    grep -q '^workflow_type: inception' "$f" || { echo "T-1397 is not an inception"; return 1; }
    grep -q '^\*\*Decision\*\*: \(GO\|NO-GO\|DEFER\)' "$f" && { echo "T-1397 already decided"; return 1; }
    return 0
}

clause_real() {
    local line; line=$(grep -m1 '^We will know that we are successful when we see' "$(task_file)")
    [ -n "$line" ] || { echo "no success clause"; return 1; }
    case "$line" in *'[NEEDS YOU'*|*'<measurable signal>'*) echo "placeholder success clause"; return 1 ;; esac
}

ready() {
    local out; out=$(.agentic-framework/bin/fw task review T-1397 2>&1)
    grep -q 'Review marker created' <<<"$out" || { echo "no review marker; fw task review said:"; tail -8 <<<"$out"; return 1; }
    grep -q 'not handoff-ready' <<<"$out" && { echo "not handoff-ready"; return 1; }
    return 0
}

decide_go() {
    .agentic-framework/bin/fw inception decide T-1397 go --rationale "Operator (2026-11-12, in conversation; recorded by job 136): trust the ring20 pool - a node is made available for a reason, runs are isolated and can be told apart. For high-impact, high-risk changes: two independent runs on two different machines; releases keep their local run. ring20's operator gave the GO for 832 on its pool (their T-2651): amd64 only, sandboxed (no network, no user namespaces), code from git only, staging only from build/pool/stage/ so build/peer-data never leaves .107, full log returned. Build: tools/pool/run-tier.sh; harnesses honour PLAYWRIGHT_BROWSERS_PATH; pool-only exceptions for the mount-namespace tests; three pool-vs-local comparison runs of the same commits (the success signal); then the push gate accepts a matching pool green, with the two-run rule for high-risk."
}

commit_decided() {
    git add -A -- .tasks/active/T-1397-*.md .tasks/completed/T-1397-*.md .context/episodic/T-1397.yaml 2>/dev/null
    git diff --cached --name-only | grep -vE '^(\.tasks/(active|completed)/T-1397-|\.context/episodic/T-1397\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1397: operator's job 136 records the decision (GO: 832's test tiers on ring20's pool; pool green counts, two runs on different machines for high-risk)" && git log --oneline -1
}
