# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Scrub LAN addresses from 832's tracked files (about 850 files), then commit (T-1239)"
JOB_TASK="T-1239"
JOB_WHY="You ruled today: scrub the LAN addresses (192.168.x.y) from the current files, keep new ones out, no history
rewrite. tools/scrub-lan-addresses.py replaces each with a placeholder (this host <dev-host>, the git server
<git-host>, any other <lan-host>; the port after it is kept). It skips AEF's vendored tree (.agentic-framework/,
AEF is asked to clean it upstream) and the append-only review ledgers (.context/reviews/, rewriting them breaks
their integrity check). Most of it is history: handovers, closed tasks, reports. This is your job, not the agent's,
because the agent may not rewrite task files from a shell (the guard that protects your Human ticks). The pre-commit
gate that keeps new addresses out is already active. Old commits on GitHub still contain the addresses, as agreed.
Nothing is pushed: the agent runs the full test suite first, then pushes."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "the scrub tool is committed as-is" 'git diff --quiet -- tools/scrub-lan-addresses.py'
    check "the LAN-address gate is active in the pre-commit hook" 'bash tools/_t1239-install-hook.sh --check'
    check "the dry run would rewrite between 700 and 1000 files" 'dry_run_in_range'
}

steps() {
    step "Stage the scrubbed committed content of each file, scrub the working copies (tools/scrub-lan-addresses.py)" 'python3 tools/scrub-lan-addresses.py'
    step "Check: no address left in the index outside AEF's tree and the ledgers" 'remaining_zero'
    step "Commit exactly what the scrub staged (other uncommitted edits stay uncommitted)" 'commit_scrub'
}

dry_run_in_range() {
    local n
    n=$(python3 tools/scrub-lan-addresses.py --dry-run | sed -n 's/^would rewrite: \([0-9]*\) file.*/\1/p')
    echo "dry run: ${n:-?} file(s)"
    [ -n "$n" ] && [ "$n" -ge 700 ] && [ "$n" -le 1000 ]
}

remaining_zero() {
    local n
    n=$(git grep --cached -lIE '192\.168\.[0-9]+\.[0-9]+' -- . ':!.agentic-framework' ':!.context/reviews' | wc -l)
    echo "files in the index still carrying an address: $n"
    [ "$n" = 0 ]
}

commit_scrub() {
    git diff --cached --name-only | grep -E '^\.agentic-framework/|^\.context/reviews/' && { echo "refusing: an excluded path is staged"; return 1; }
    git diff --cached --diff-filter=D --name-only | grep -q . && { echo "refusing: a deletion is staged, which the scrub never makes"; return 1; }
    echo "staged: $(git diff --cached --name-only | wc -l) file(s)"
    .agentic-framework/bin/fw git commit -m "T-1239: scrub LAN addresses from 832's tracked files (operator job 065; placeholders <dev-host>/<git-host>/<lan-host>, ports kept; AEF's tree and the review ledgers excluded)" && git log --oneline -1
}
