# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Your 'a' on Arc-0 condition 3: approve its definition, then let the reviewer tick T-732 and T-596"
JOB_TASK="T-1063"
JOB_WHY="You approved condition 3's definition ('Arc 0 cannot close while any open roadmap question is unanswered or
unrecorded'). The fields are yours, so your session writes them: definition_ratified true, the 'pending' note removed,
and a small record saying you ratified it (condition 1 gets the same record for today's ratification). The checker
must then read condition 3 BLOCKED on H5/H6 only, and Arc 0 1 of 3 (tested on a copy). One more of your verbs rides
along: T-596's box is out of date (it asks you to confirm two questions are OPEN that you have since answered), and
the reviewer proposes rewording it as history; step 4 accepts that. The reviewer then judges T-596 and T-732 again,
and green verdicts tick the boxes (H1 is already green). Nothing is pushed."

YAML=docs/research/executable-workflow/arc-0-exit-clauses.yaml
ROADMAP=docs/research/executable-workflow/roadmap-5be23719.md
T732=.tasks/active/T-732-drain-the-h-register-four-open-operator-.md
T596=.tasks/active/T-596-arc-0-exit-gate-is-uncheckable-the-opera.md
VID596=V-20261118-7571175e

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-596's task file exists under that name" '[ -f $T596 ]'
    check "the register and both task files are committed as is" 'git diff --quiet -- $YAML $T732 $T596'
    check "condition 3 still reads unratified" 'ratify3 --check'
}

steps() {
    step "Show the changes to conditions 1 and 3; writes nothing" 'ratify3 --check'
    step_operator "Write them, check the file reads back, and commit" 'ratify3 --write && do_commit_yaml'
    step_operator "Run the Arc-0 checker: condition 3 must be BLOCKED on H5/H6 only, Arc 0 1 of 3" 'show_gate'
    step_operator "Accept the reviewer's rewording of T-596's out-of-date box (shows before/after first)" \
        '.agentic-framework/bin/fw reviewer restatement accept $VID596 --dry-run && .agentic-framework/bin/fw reviewer restatement accept $VID596 && do_commit_restatement'
    step_outward "The reviewer judges T-596 and T-732 again (model calls; verdicts commit themselves)" \
        '.agentic-framework/bin/fw reviewer judge T-596 && .agentic-framework/bin/fw reviewer judge T-732'
    step_outward "Apply the green verdicts to T-596 and T-732, and commit" \
        '.agentic-framework/bin/fw reviewer verdict apply T-596; .agentic-framework/bin/fw reviewer verdict apply T-732; do_commit_apply'
}

show_gate() {
    python3 tools/_t597_arc0_clauses.py $YAML $ROADMAP 1 > /tmp/.job163-gate 2>&1
    sed -n '1,6p' /tmp/.job163-gate
    grep -q "clause-1   SATISFIED" /tmp/.job163-gate && grep -q "clause-3   BLOCKED" /tmp/.job163-gate \
        && grep -q "Arc 0: 1 of 3 satisfied" /tmp/.job163-gate && ! grep -q "INTEGRITY" /tmp/.job163-gate
}

ratify3() {
    python3 - "$1" "$YAML" <<'PY'
import sys, yaml
mode, path = sys.argv[1], sys.argv[2]
lines = open(path).read().split("\n")


def block(cid):
    s = next(i for i, l in enumerate(lines) if l == "  - id: " + cid)
    e = next((i for i, l in enumerate(lines) if i > s and (l.startswith("  - id: ") or (l and not l.startswith(" ")))), len(lines))
    return s, e


s3, e3 = block("clause-3")
dr = [i for i in range(s3, e3) if lines[i] == "    definition_ratified: false"]
rp = [i for i in range(s3, e3) if lines[i].startswith("    ratification_pending:")]
if len(dr) != 1 or len(rp) != 1 or any(lines[i].startswith("    ratification:") for i in range(s3, e3)):
    print("REFUSED: clause 3 does not read as expected (already ratified, or changed)"); sys.exit(1)
end_rp = rp[0] + 1
while end_rp < e3 and lines[end_rp].startswith("      "):
    end_rp += 1
print("clause-3 line %d: definition_ratified false -> true, plus a ratification record (by operator)" % (dr[0] + 1))
print("clause-3 lines %d-%d: the 'ratification_pending' note removed" % (rp[0] + 1, end_rp))
del lines[rp[0]:end_rp]
lines[dr[0]:dr[0] + 1] = ["    definition_ratified: true",
                          "    ratification:",
                          "      by: operator",
                          "      on: 2026-11-18",
                          "      in: 832 T-732 (operator ruling 'a', in session; written by operator job 163)"]
s1, e1 = block("clause-1")
d1 = [i for i in range(s1, e1) if lines[i] == "    definition_ratified: true"]
if len(d1) != 1 or any(lines[i].startswith("    ratification:") for i in range(s1, e1)):
    print("REFUSED: clause 1 does not read as expected"); sys.exit(1)
print("clause-1 line %d: ratification record added (by operator, 2026-11-18, T-736)" % (d1[0] + 1))
lines[d1[0] + 1:d1[0] + 1] = ["    ratification:",
                              "      by: operator",
                              "      on: 2026-11-18",
                              "      in: 832 T-736 (operator ruling 'A'; written by operator jobs 161, 162)"]
if mode == "--write":
    open(path, "w").write("\n".join(lines))
    d = yaml.safe_load(open(path))
    c = {x["id"]: x for x in d["clauses"]}
    assert c["clause-3"]["definition_ratified"] is True and "ratification_pending" not in c["clause-3"]
    assert c["clause-1"]["ratification"]["by"] == "operator" and c["clause-3"]["ratification"]["by"] == "operator"
    print("written; the file parses and both records read back")
PY
}

do_commit_yaml() {
    git add -- $YAML && git commit -q -m "T-732: operator ratifies the Arc-0 clause-3 definition (ruling 'a'); clauses 1 and 3 carry a ratification record by operator (operator job 163)" -- $YAML \
        && git log --oneline -1
}

do_commit_restatement() {
    local p="$T596 .context/reviews/restatements.jsonl"
    git add -- $p && git commit -q -m "T-1063: operator accepted reviewer restatement $VID596 on T-596 AC1 (operator job 163)" -- $p \
        && git log --oneline -1
}

do_commit_apply() {
    local p="$T596 $T732 .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the steps above)"; return 0
    fi
    git add -- $p && git commit -q -m "T-1063: green reviewer verdicts applied to T-596 and T-732 (operator job 163)" -- $p \
        && git log --oneline -1
}
