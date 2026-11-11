# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# Closes T-358 (no invented lanes or pool on import; shipped in 0.41.0). T-358 is human-owned because it carries the
# operator's ruling, so completing it is the operator's: `fw task update ... --status work-completed` refuses inside
# the agent's session (sovereignty gate R-033). Both Human criteria are ticked (the reviewer's on the drawing, the
# operator's on the ruling, ticked in Watchtower on 2026-11-10). The close runs T-358's own verification (core and
# browser tiers, about 40 minutes) and writes the episodic summary; the job then commits the close and pushes it.
JOB_TITLE="Close T-358 (no invented lanes or pool, shipped in 0.41.0): run its verification, complete it, commit, push"
JOB_TASK="T-358"
JOB_WHY="T-358 is done: both halves of your rulings (lanes 2026-11-08, pool 2026-11-09) shipped in 0.41.0, AEF serves it,
and both of its review criteria are ticked. It is human-owned (it carries your ruling), so the framework lets only you
complete it. Step 1 runs its verification (core + browser tiers, about 40 minutes) and moves it to completed; step 2
commits that move; step 3 pushes. If step 1 refuses, nothing is changed; the agent reads why from the log.
Answer y at each step."

TASK=T-358

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "T-358 is still active" 'ls .tasks/active/T-358-*.md >/dev/null 2>&1'
    check "both of T-358's review criteria are ticked" '[ "$(grep -c "^- \[x\] \[REVIEW\]" .tasks/active/T-358-*.md)" = 2 ]'
    check "the index holds nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
}

steps() {
    step_operator "Complete T-358: run its verification (core + browser tiers, ~40 min) and move it to completed" 'do_close'
    step_outward "Commit the close (the task file and its episodic summary only; needs step 1's result)" 'do_commit'
    step_outward "Push bleeding-edge to origin" 'git push origin bleeding-edge'
}

do_close() {
    PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH" .agentic-framework/bin/fw task update "$TASK" --status work-completed
}

do_commit() {
    local done_f
    done_f=$(ls .tasks/completed/T-358-*.md 2>/dev/null | head -1)
    [ -n "$done_f" ] || { echo "T-358 is not in .tasks/completed — step 1 did not complete it"; return 1; }
    # the framework stages the move itself; commit exactly its three paths, nothing else in the tree
    local active_f=".tasks/active/$(basename "$done_f")"
    git commit -q -m "T-358: close — no invented lanes or pool on import, marked instead (operator rulings 2026-11-08/09); shipped in 0.41.0

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -- "$done_f" .context/episodic/T-358.yaml "$active_f" || return 1
    echo "ok  close committed $(git rev-parse --short HEAD)"
}
