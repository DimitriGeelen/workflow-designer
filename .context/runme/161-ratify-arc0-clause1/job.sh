# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Your 'A' on T-736: mark Arc-0 condition 1 as met (AEF's 'done'), then let the reviewer tick T-736 and T-592"
JOB_TASK="T-1063"
JOB_WHY="You said: 'if AEF says it's done, then it's done.' Two fields on Arc-0 condition 1 are yours alone, so your
session sets them: attestation (cites AEF's report @1539, their commit 174f31777) and definition_ratified: true.
Step 1 shows the change, step 2 writes and commits it. Then the reviewer judges T-736's box, and its green verdicts
tick T-736 and T-592 (your 'b', already judged green). Nothing is pushed."

YAML=docs/research/executable-workflow/arc-0-exit-clauses.yaml
T736=.tasks/active/T-736-aef-attested-arc-0-clause-1-green-with-i.md
T592=.tasks/active/T-592-verification-legs-that-pipe-a-self-repor.md

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "the register and both task files are committed as is" 'git diff --quiet -- $YAML $T736 $T592'
    check "condition 1 still reads unratified (attestation null, definition_ratified false)" 'set_clause1 --check'
}

steps() {
    step "Show the two field changes on condition 1 (before and after); writes nothing" 'set_clause1 --check'
    step_operator "Write them, check the file still parses, and commit" 'set_clause1 --write && do_commit_yaml'
    step_outward "The reviewer judges T-736's box (a model call; its verdict commits itself)" \
        '.agentic-framework/bin/fw reviewer judge T-736'
    step_outward "Apply the reviewer's green verdicts to T-736 and T-592, and commit" \
        '.agentic-framework/bin/fw reviewer verdict apply T-736 && .agentic-framework/bin/fw reviewer verdict apply T-592 && do_commit_apply'
}

# Changes exactly two lines inside the clause-1 block, and refuses if they are not as expected.
set_clause1() {
    python3 - "$1" "$YAML" <<'PY'
import sys, yaml
mode, path = sys.argv[1], sys.argv[2]
lines = open(path).read().split("\n")
start = next(i for i, l in enumerate(lines) if l == "  - id: clause-1")
end = next(i for i, l in enumerate(lines) if l == "  - id: clause-2")
want = {"    definition_ratified: false": "    definition_ratified: true",
        "    attestation: null": '    attestation: "AEF @1539 (agent-chat-arc, EWCR-ARC0-ATTEST-832), their T-3394 commit 174f31777, measured at 996a4f9a5: CORE/BROAD intersection 0/0 with coverage control; ratified by the operator 2026-11-18 (832 T-736)"'}
hits = [(i, lines[i]) for i in range(start, end) if lines[i] in want]
if sorted(l for _, l in hits) != sorted(want):
    print("REFUSED: condition 1 does not read as expected (already ratified, or changed)"); sys.exit(1)
for i, old in hits:
    print("line %d\n  - %s\n  + %s" % (i + 1, old.strip(), want[old].strip()))
    lines[i] = want[old]
if mode == "--write":
    open(path, "w").write("\n".join(lines))
    yaml.safe_load(open(path))
    print("written; the file parses")
PY
}

do_commit_yaml() {
    git add -- $YAML && git commit -q -m "T-736: operator ratifies Arc-0 clause 1 on AEF's attestation (@1539, 174f31777) — attestation set, definition_ratified true (operator job 161)" -- $YAML \
        && git log --oneline -1
}

do_commit_apply() {
    local p="$T736 $T592 .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the steps above)"; return 0
    fi
    git add -- $p && git commit -q -m "T-1063: green reviewer verdicts applied to T-736 and T-592 (operator job 161)" -- $p \
        && git log --oneline -1
}
