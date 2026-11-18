# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Fix my 'on:' slip in the two ratification records, then the reviewer re-judges T-732's last box"
JOB_TASK="T-1063"
JOB_WHY="My mistake in job 163: I named the date field of the two ratification records 'on:'. YAML reads the bare word
'on' as true, so the date is unreadable under that name. Renaming it to 'date:' touches your fields, so it runs here.
Step 1 shows the two lines; step 2 writes them and checks every key reads back by name. Then the reviewer judges
T-732's condition-3 box again (it was judged before T-596's tick was applied, my ordering slip) and a green ticks it.
Nothing is pushed."

YAML=docs/research/executable-workflow/arc-0-exit-clauses.yaml
T732=.tasks/active/T-732-drain-the-h-register-four-open-operator-.md

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "the register and T-732 are committed as is" 'git diff --quiet -- $YAML $T732'
    check "exactly two 'on:' lines to rename" 'fix_key --check'
}

steps() {
    step "Show the two lines that change; writes nothing" 'fix_key --check'
    step_operator "Rename 'on:' to 'date:', check every key reads back by name, and commit" 'fix_key --write && do_commit_yaml'
    step_outward "The reviewer judges T-732 again (a model call; its verdict commits itself)" \
        '.agentic-framework/bin/fw reviewer judge T-732'
    step_outward "Apply the green verdict to T-732, and commit" \
        '.agentic-framework/bin/fw reviewer verdict apply T-732; do_commit_apply'
}

fix_key() {
    python3 - "$1" "$YAML" <<'PY'
import sys, yaml, datetime
mode, path = sys.argv[1], sys.argv[2]
lines = open(path).read().split("\n")
hits = [i for i, l in enumerate(lines) if l == "      on: 2026-11-18" and lines[i - 2] == "    ratification:"]
if len(hits) != 2:
    print("REFUSED: expected exactly two 'on: 2026-11-18' lines under a ratification record, found %d" % len(hits)); sys.exit(1)
for i in hits:
    print("line %d: '      on: 2026-11-18' -> '      date: 2026-11-18'" % (i + 1))
    lines[i] = "      date: 2026-11-18"
if mode == "--write":
    open(path, "w").write("\n".join(lines))
    d = yaml.safe_load(open(path))
    recs = [c["ratification"] for c in d["clauses"] if c.get("ratification")]
    assert len(recs) == 2, recs
    for r in recs:
        assert set(r) == {"by", "date", "in"}, r          # every key by name: no True, no stray key
        assert r["by"] == "operator" and r["date"] == datetime.date(2026, 11, 18), r
    print("written; both records read back as by / date / in, date 2026-11-18")
PY
}

do_commit_yaml() {
    git add -- $YAML && git commit -q -m "T-732: ratification records' date key renamed on -> date (YAML read 'on' as true; operator job 165)" -- $YAML \
        && git log --oneline -1
}

do_commit_apply() {
    local p="$T732 .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the steps above)"; return 0
    fi
    git add -- $p && git commit -q -m "T-1063: T-732's green reviewer verdict applied (operator job 165)" -- $p \
        && git log --oneline -1
}
