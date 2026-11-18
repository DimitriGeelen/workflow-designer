# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Fix my mistake in job 161: write your Arc-0 ratification in the shape the checker reads, then tick T-736"
JOB_TASK="T-1435"
JOB_WHY="Job 161 wrote your ratification of Arc-0 condition 1 as plain text. The Arc-0 checker needs a structured
record (who attested, where) plus 'satisfied: true', and it crashed on the text (my error; it now refuses such text
instead of crashing). This job rewrites the same facts in the right shape, in your session because the fields are
yours, then runs the checker (it must say 'clause-1 SATISFIED' and 'Arc 0: 1 of 3 satisfied'). Then the reviewer
judges T-736 again and its green ticks the box. Nothing is pushed."

YAML=docs/research/executable-workflow/arc-0-exit-clauses.yaml
ROADMAP=docs/research/executable-workflow/roadmap-5be23719.md
T736=.tasks/active/T-736-aef-attested-arc-0-clause-1-green-with-i.md

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "the register and T-736 are committed as is" 'git diff --quiet -- $YAML $T736'
    check "condition 1 reads as job 161 left it" 'fix_clause1 --check'
}

steps() {
    step "Show the change to condition 1; writes nothing" 'fix_clause1 --check'
    step_operator "Write it, check the file parses, and commit" 'fix_clause1 --write && do_commit_yaml'
    step_operator "Run the Arc-0 checker: must show clause-1 SATISFIED and 'Arc 0: 1 of 3 satisfied'" 'show_gate'
    step_outward "The reviewer judges T-736's box again (a model call; its verdict commits itself)" \
        '.agentic-framework/bin/fw reviewer judge T-736'
    step_outward "Apply the reviewer's verdict to T-736 (ticks only if green) and commit" \
        '.agentic-framework/bin/fw reviewer verdict apply T-736 && do_commit_apply'
}

show_gate() {
    python3 tools/_t597_arc0_clauses.py $YAML $ROADMAP 1 > /tmp/.job162-gate 2>&1
    sed -n '1,6p' /tmp/.job162-gate
    grep -q "clause-1   SATISFIED" /tmp/.job162-gate && grep -q "Arc 0: 1 of 3 satisfied" /tmp/.job162-gate
}

fix_clause1() {
    python3 - "$1" "$YAML" <<'PY'
import sys, yaml
mode, path = sys.argv[1], sys.argv[2]
lines = open(path).read().split("\n")
start = next(i for i, l in enumerate(lines) if l == "  - id: clause-1")
end = next(i for i, l in enumerate(lines) if l == "  - id: clause-2")
att = [i for i in range(start, end) if lines[i].startswith('    attestation: "AEF @1539')]
blk = [i for i in range(start, end) if lines[i] == "    blocks_arc_0_exit: true"]
if len(att) != 1 or len(blk) != 1 or any(lines[i].startswith("    satisfied:") for i in range(start, end)):
    print("REFUSED: condition 1 does not read as job 161 left it"); sys.exit(1)
new = ["    attestation:",
       "      attested_by: 999-Agentic-Engineering-Framework (AEF T-3394, arc-019)",
       '      attested_at: "agent-chat-arc @1539, correlation EWCR-ARC0-ATTEST-832"',
       "      their_commit: 174f31777",
       "      measured_at_their_commit: 996a4f9a5",
       "      measurement: CORE/BROAD intersection 0/0 with coverage control; r2 @1603 CORE 31/31",
       "      ratified_by: operator",
       "      ratified_on: 2026-11-18",
       "      ratified_in: 832 T-736 (operator jobs 161, 162)",
       "    satisfied: true"]
print("line %d: attestation becomes a record (attested_by, attested_at, citation), satisfied: true added" % (att[0] + 1))
print("line %d: blocks_arc_0_exit: true -> false" % (blk[0] + 1))
lines[blk[0]] = "    blocks_arc_0_exit: false"
lines[att[0]:att[0] + 1] = new
if mode == "--write":
    open(path, "w").write("\n".join(lines))
    yaml.safe_load(open(path))
    print("written; the file parses")
PY
}

do_commit_yaml() {
    git add -- $YAML && git commit -q -m "T-736: Arc-0 clause 1 ratification rewritten as an attestation record with satisfied: true and blocks_arc_0_exit: false (operator job 162; job 161 had written a string the checker cannot read)" -- $YAML \
        && git log --oneline -1
}

do_commit_apply() {
    local p="$T736 .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the steps above)"; return 0
    fi
    git add -- $p && git commit -q -m "T-1063: T-736's green reviewer verdict applied (operator job 162)" -- $p \
        && git log --oneline -1
}
