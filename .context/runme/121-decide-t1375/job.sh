# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# The decision is `step_operator` (T-1324): fw inception decide refuses in the agent's session, so it is never
# rehearsed. The commit needs the decision's result, so it is `step_outward`. Same checks as job 118.
JOB_TITLE="Decide T-1375: GO for a map skill in the authoring kit and six general validator warnings (greenfield's proposal)"
JOB_TASK="T-1375"
JOB_WHY="You asked to go ahead with greenfield's proposal as an inception. The agent recommends GO.
The problem: rules agreed with consumers (io per object, a condition on every decision branch, documents as data
objects, aef:position = DI) live in sidecar threads and agent memory, and nothing refuses a map that breaks them.
The kit's AUTHORING.md mentions io once. greenfield's own check script found 15 and 17 findings on two maps that had
been considered done.
GO means two bounded builds:
  1  kit text: io and data sections in AUTHORING.md, a SKILL.md entry point, the README points to it;
  2  validator: six new warnings (io incomplete; a step in an authority lane without io when the map has io;
     a decision branch without a condition; an unknown documentation prefix; a document linked to no step;
     aef:position differs from DI), and --strict, which turns them into errors.
Not in it: the Mapping-line check (W-05) waits for AEF's vocabulary (T-4991); greenfield's own project rules stay
in its project. Today's maps without io stay quiet.
Read: docs/reports/T-1375-authoring-kit-map-skill-and-checks.md (the table under IW-2), and the task's
Recommendation. To decide otherwise, answer n at the step and tell the agent. Nothing is pushed."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1375 is an active inception with no decision recorded" 'undecided'
    check "every Agent criterion is ticked" 'agent_acs_ticked'
    check "its success clause is real (no template placeholder)" 'clause_real'
    check "the decide gate's readiness check passes (fw task review)" 'ready'
}

steps() {
    step_operator "T-1375: GO (build 1 kit text + SKILL.md, build 2 six validator warnings + --strict; W-05 waits for AEF T-4991)" 'decide_go'
    step_outward "Commit the decided task (only its files)" 'commit_decided'
}

task_file() { ls .tasks/active/T-1375-*.md 2>/dev/null | head -1; }

undecided() {
    local f; f=$(task_file)
    [ -n "$f" ] || { echo "T-1375 is not active"; return 1; }
    grep -q '^workflow_type: inception' "$f" || { echo "T-1375 is not an inception"; return 1; }
    grep -q '^\*\*Decision\*\*: \(GO\|NO-GO\|DEFER\)' "$f" && { echo "T-1375 already decided"; return 1; }
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
    local out; out=$(.agentic-framework/bin/fw task review T-1375 2>&1)
    grep -q 'Review marker created' <<<"$out" || { echo "no review marker; fw task review said:"; tail -8 <<<"$out"; return 1; }
    grep -q 'not handoff-ready' <<<"$out" && { echo "not handoff-ready"; return 1; }
    return 0
}

decide_go() {
    .agentic-framework/bin/fw inception decide T-1375 go --rationale "Operator (2026-11-02, recorded by job 121): GO on greenfield's proposal (their T-390/T-393). Agreed general map rules move from threads and memory into the kit. Build 1: AUTHORING.md gets io-and-data sections (io per object with system and operation; fields with fieldRef and role; expect only for this step; Mapping lines; conditions on every branch; documents as data objects; aef:position = DI; documentation prefixes, 832's rule C), a SKILL.md entry point at the kit root, and the README points to it. Build 2: validate-workflow.py gets six WARNs (IO-INCOMPLETE, IO-MISSING only when the map carries io, GW-BRANCH-UNCONDITIONED, DOC-PREFIX, DATA-UNLINKED, POSITION-DI) and --strict to raise them to ERROR, each with fixtures and registry entries. W-05 waits on AEF T-4991; project rules stay in each project. Success: validate-workflow.py --strict --field-catalog reports on TRB-T1 and KLS-T1 every finding check-map.py reports under W-02/03/07/10/11/14. Evidence: docs/reports/T-1375-authoring-kit-map-skill-and-checks.md."
}

commit_decided() {
    git add -A -- .tasks/active/T-1375-*.md .tasks/completed/T-1375-*.md .context/episodic/T-1375.yaml 2>/dev/null
    git diff --cached --name-only | grep -vE '^(\.tasks/(active|completed)/T-1375-|\.context/episodic/T-1375\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1375: operator's job 121 records the decision (GO: kit skill + six general validator warnings with --strict; W-05 waits for AEF T-4991)" && git log --oneline -1
}
