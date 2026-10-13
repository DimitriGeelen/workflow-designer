# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Close T-1127 (element detail view, shipped in 0.18.0) — your option 1"
JOB_TASK="T-1127"
JOB_WHY="You chose option 1. The agent cannot do it: T-1127 is owner:human, and an agent session may neither close a
human-owned task nor change its owner (R-033, T-3586). It has no Human criteria, so the reviewer agents have no route
either (AEF T-3449 'READY TO CLOSE'); 832 is proposing to AEF that the reviewer closes this case in future.
Evidence: shipped in designer 0.18.0 (release notes), 6/6 criteria ticked, verification 3/3 (checked again just now).
This runs the one command AEF's review queue lists for it."

preflight() {
    check "T-1127 is still active and owner:human" 'f=$(ls .tasks/active/T-1127-*.md 2>/dev/null) && grep -q "^owner: human" "$f"'
    check "every criterion is ticked and there are no Human criteria" 'f=$(ls .tasks/active/T-1127-*.md) && ! grep -qE "^- \[ \]" "$f" && ! grep -q "^### Human" "$f"'
    check "shipped: named in the 0.18.0 release notes" 'grep -q "T-1127" docs/releases/RELEASE-NOTES-0.18.0.md'
}

steps() {
    step "Close T-1127 (work-completed; the framework re-runs its verification)" '.agentic-framework/bin/fw task update T-1127 --status work-completed'
    # Only T-1127's own files: the task folders hold many unrelated uncommitted edits a folder-wide add would sweep in.
    step "Commit the closure (T-1127's files only)" 'git add -A -- ":(glob).tasks/*/T-1127-*" && git commit -q -m "T-1127: closed by the operator (job 022) — shipped in 0.18.0, all criteria ticked, no Human criteria" -- ":(glob).tasks/*/T-1127-*"'
}
