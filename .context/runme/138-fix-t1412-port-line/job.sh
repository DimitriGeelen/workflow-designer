# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# Why a job: T-1412 is closed, a closed record may only gain a dated Updates entry from the agent, and a closed task
# cannot be reopened (work-completed is terminal). Removing one Verification line is the operator's edit.
JOB_TITLE="Remove T-1412's hard-coded-port verification line (it blocks every push: G-015 hygiene)"
JOB_TASK="T-876"
JOB_WHY="Since this afternoon every push is refused by the core suite: verification-hygiene finds a NEW G-015 carrier,
T-1412's line  ! ss -tln | grep -q ':45111 '  (a hard-coded port). The agent wrote it when closing T-1412 (the SPRIND
video page). The line next to it,  test ! -e build/sprind-video , already proves the page was taken down, so this
step deletes exactly the port line and commits. Nothing else changes. After it, the agent pushes T-876 (the corpus kind
backfill) through the gate again."

TASK_FILE=".tasks/completed/T-1412-sprind-video-serve-the-designer-read-onl.md"
PORT_LINE="! ss -tln | grep -q ':45111 '"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1412 has the port line exactly once as a whole line" 'one_line'
    check "the sibling check (build/sprind-video gone) is still there" 'grep -qxF "test ! -e build/sprind-video" "$TASK_FILE"'
}

steps() {
    step "Delete the port line from T-1412's Verification and confirm hygiene passes" 'drop_line'
    step "Commit T-1412's record (only that file)" 'commit_it'
}

one_line() { [ "$(grep -cxF "$PORT_LINE" "$TASK_FILE")" = 1 ]; }

drop_line() {
    python3 - "$TASK_FILE" "$PORT_LINE" <<'PY'
import sys
path, line = sys.argv[1], sys.argv[2]
lines = open(path).read().split("\n")
assert lines.count(line) == 1, "port line not found exactly once"
lines.remove(line)
open(path, "w").write("\n".join(lines))
PY
    python3 tools/verification-hygiene.py >/dev/null 2>&1 || { python3 tools/verification-hygiene.py 2>&1 | tail -6; return 1; }
    echo "hygiene: OK"
}

commit_it() {
    git add -- "$TASK_FILE"
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1412: drop the hard-coded-port verification line (G-015 carrier); 'build/sprind-video gone' already proves the page was taken down (operator job 138)" -- "$TASK_FILE" && git log --oneline -1
}
