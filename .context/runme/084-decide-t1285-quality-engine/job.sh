# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="T-1285 GO: build the quality engine in six ranked steps (you asked how to stop going round in circles)"
JOB_TASK="T-1285"
JOB_WHY="You asked on 2026-10-23 what we need to do, structurally, to improve quality. The inception measured it
(docs/reports/T-1285-quality-engine.md):
- about 1 in 4 of your operator runs stops (30 stopped, 77 done; 22 of 83 jobs retired), mostly because a rehearsal
  checks preconditions but never exercises the steps' framework gates;
- ~70% of what reviewers found could have been caught by a check on the rendered map;
- the suite was red every run while catching 0 product regressions;
- AEF went 13-25 days without 4 designer endpoints, with nothing comparing the two.
GO records the build plan, one bounded task at a time, in this order:
  1 deep rehearsal for operator jobs (steps run against a throwaway clone, gates included)
  2 a 'what a person sees' gate on every map at 1024/1440/1920 before any review
  3 a hermetic core suite that must be green on every push, plus a quarantine with owners
  4 a generated designer-to-host contract checked against AEF at every release and upgrade
  5 verifiable reviewer findings (file:line + quote check)
  6 upstream our 37 local framework patches; framework tags in batches
Success clause (T-1285's 'We will know' line), over the next 5 designer UI tasks: at most 1 official review round
each, a core suite 100% green on every push, 0 AEF endpoint gaps undetected at release time, and each release job
completing on its first run. If the order or the clause is not what you want, answer n and tell the agent. The last
step commits only T-1285's files. Nothing is pushed."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1285 is an active inception, started-work, no decision yet" 'open_inception'
    check "its success clause is real (no template placeholder on the 'We will know' line)" 'clause_real'
    check "the decide gate's readiness check passes (fw task review)" 'ready'
}

steps() {
    step "T-1285: GO" '.agentic-framework/bin/fw inception decide T-1285 go --rationale "Operator 2026-10-23 asked how to improve quality structurally. Spikes (docs/reports/T-1285-quality-engine.md): ~1 in 4 operator runs stops (largest cause: dry-run never exercises the step gates); ~70% of reviewer findings mechanically decidable; suite red every run with 0 product regressions; AEF missing 4 designer endpoints for 13-25 days. Build in ranked order: deep rehearsal, what-a-person-sees gate, hermetic core suite, host contract, verifiable findings, upstream local patches."'
    step "Commit T-1285's files only" 'commit_decided'
}

task_file() { ls .tasks/active/T-1285-*.md .tasks/completed/T-1285-*.md 2>/dev/null | head -1; }

open_inception() {
    local f; f=$(ls .tasks/active/T-1285-*.md 2>/dev/null | head -1)
    [ -n "$f" ] || { echo "T-1285 is not active"; return 1; }
    grep -q '^workflow_type: inception' "$f" || { echo "not an inception"; return 1; }
    grep -q '^status: started-work$' "$f" || { echo "status is $(grep -m1 '^status:' "$f")"; return 1; }
    grep -q '^\*\*Decision\*\*: \(GO\|NO-GO\|DEFER\)' "$f" && { echo "already decided"; return 1; }
    return 0
}

clause_real() {
    local line; line=$(grep -m1 '^We will know that we are successful when we see' "$(task_file)")
    [ -n "$line" ] || { echo "no success clause"; return 1; }
    case "$line" in *'[NEEDS YOU'*|*'<measurable signal>'*) echo "placeholder success clause"; return 1 ;; esac
}

ready() {
    local out; out=$(.agentic-framework/bin/fw task review T-1285 2>&1)
    printf '%s\n' "$out" | grep -q 'Review marker created' || { echo "no review marker"; return 1; }
    printf '%s\n' "$out" | grep -q 'not handoff-ready' && { echo "not handoff-ready"; return 1; }
    return 0
}

commit_decided() {
    local p
    for p in ':(glob).tasks/active/T-1285-*.md' ':(glob).tasks/completed/T-1285-*.md' .context/episodic/T-1285.yaml; do
        git add -A -- "$p" 2>/dev/null || true
    done
    git diff --cached --name-only | grep -vE '^(\.tasks/(active|completed)/T-1285-|\.context/episodic/T-1285\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    git diff --cached --name-only
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1285: operator's job 084 records GO (quality engine: six ranked build steps)" && git log --oneline -1
}
