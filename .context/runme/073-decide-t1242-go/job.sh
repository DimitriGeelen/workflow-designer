# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="T-1242 GO: build structured io attributes in the designer (AEF has ruled T-4415)"
JOB_TASK="T-1242"
JOB_WHY="You asked to prioritise structured io attributes (shape, fields, source and target system), then chose to
wait for AEF's ruling. AEF's operator ruled T-4415 GO today on DRAFT 2 (AEF f1f7c30dd), the exact text 832 and
greenfield checked, including against greenfield's two full maps. This records 832's own GO on T-1242, so the
designer build can start in four slices, each with screenshots and an independent reviewer:
  1 read, show and keep every v1.1 io construct (read-only first)
  2 edit the io attributes (fieldRef, typeRef, role, operation, cardinality, systems; absorbs T-1229)
  3 edit field lists and expectations
  4 show AEF's v1.1 lint findings
Success clause (on the 'We will know' line in T-1242): greenfield's VZN-T1 v29 and the 54 v1 maps here save with
0 bytes changed, and a v1.1 example map using every construct round-trips with 0 bytes changed and shows each
attribute. If that clause does not say what you mean, answer n and tell the agent. The last step commits only
T-1242's files. Nothing is pushed."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1242 is an active inception, started-work, no decision yet" 'open_inception'
    check "its success clause is real (no template placeholder on the 'We will know' line)" 'clause_real'
    check "the decide gate's readiness check passes (fw task review)" 'ready'
}

steps() {
    step "T-1242: GO" '.agentic-framework/bin/fw inception decide T-1242 go --rationale "AEF T-4415 GO (operator ruling 2026-10-21, ruled DRAFT 2 at AEF f1f7c30dd, verified by 832 and greenfield incl. full maps); operator asked to prioritise; build in four slices, read-only first"'
    step "Commit T-1242's files only" 'commit_decided'
}

task_file() { ls .tasks/active/T-1242-*.md .tasks/completed/T-1242-*.md 2>/dev/null | head -1; }

open_inception() {
    local f; f=$(ls .tasks/active/T-1242-*.md 2>/dev/null | head -1)
    [ -n "$f" ] || { echo "T-1242 is not active"; return 1; }
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
    local out; out=$(.agentic-framework/bin/fw task review T-1242 2>&1)
    printf '%s\n' "$out" | grep -q 'Review marker created' || { echo "no review marker"; return 1; }
    printf '%s\n' "$out" | grep -q 'not handoff-ready' && { echo "not handoff-ready"; return 1; }
    return 0
}

commit_decided() {
    local p
    for p in ':(glob).tasks/active/T-1242-*.md' ':(glob).tasks/completed/T-1242-*.md' .context/episodic/T-1242.yaml; do
        git add -A -- "$p" 2>/dev/null || true
    done
    git diff --cached --name-only | grep -vE '^(\.tasks/(active|completed)/T-1242-|\.context/episodic/T-1242\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    git diff --cached --name-only
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1242: operator's job 073 records GO (AEF T-4415 ruled; designer build in four slices)" && git log --oneline -1
}
