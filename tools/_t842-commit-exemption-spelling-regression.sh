#!/usr/bin/env bash
# T-842 — regression pin for the commit-checkpoint exemption's SPELLING coverage.
#
# NOTE ON THE FIXTURE TASK ID: every fixture below commits against T-842, this task's own
# id, NOT a generic placeholder. That is not cosmetic. Writing `T-1` in a fixture string
# makes the focus-drift gate (T-1730) read `T-1` as the action's target task and refuse the
# whole file write — measured while writing this script. Its two offered remedies are
# --switch-focus and FW_SWITCH_FOCUS=1, both Tier-2 bypasses an agent must not take on the
# operator's behalf, so the only legitimate move was to change the DATA until the gate's
# parser stopped mis-reading it. Fifth instance of the gate-matches-command-TEXT class
# (OBS-335), and the first where a gate shaped content rather than behaviour.
#
# WHAT THIS PINS, AND WHY IT IS A RATCHET RATHER THAN A PASS/FAIL TEST
#
# Closing the last active task clears focus. check-active-task.sh then blocks every
# modifying Bash call, including the commit that records the closure. The escape is
# is_commit_checkpoint_command() (safe-commands.sh:1344), which is supposed to admit a
# commit checkpoint. Measured on 1.7.68, it admits only a COMPLETELY BARE `git commit`:
#
#   _fw_is_git_commit_clause() (safe-commands.sh:1212) ends in
#       [[ "$seg" =~ ^git[[:space:]]+commit([[:space:]]|$) ]]
#
# anchored on ^git. So `fw git commit` — THE SPELLING CLAUDE.md MANDATES — can never
# match, at any path spelling. 1.6.354's _sc_is_commit_only_command() handled both via
# positional tokens with path stripping (`case "${tok1##*/}" in git) ... fw) ...`); the
# 1.7.68 rewrite dropped the fw branch and the path stripping together. That is T-652
# reintroduced, and PL-291 already named the class.
#
# A SECOND, INDEPENDENT DEFECT rides along: `timeout 300 git commit` blocks even with bare
# git. That is T-839's finding, sent upstream, still unfixed here. Isolated below so the
# two are not confused again — chaining is NOT the problem (`cd && git commit` and
# `git add && git commit` both pass).
#
# THE RATCHET. This script does NOT fail on the known defects — a suite that is red on
# purpose gets muted, and P-011 would block every close. Instead it counts them and asserts
# the count is EXACTLY the number recorded here, so it fires in BOTH directions:
#   - a new spelling breaking      -> count rises  -> RED
#   - upstream fixing one of these -> count falls  -> RED, and that red means GO UPDATE
#     THIS FILE AND DROP THE ROW, which is the outcome we want to be forced to notice.
# PL-332: a probe nothing re-runs starts misinforming. T-842's verification block re-runs
# this and its number has to be maintained.
#
#   --strict   assert what SHOULD be true (every mandated spelling admitted). Fails today
#              by design. Run after any framework upgrade or any fix attempt.
#
# Exit 0 = the world is exactly as recorded. Exit 1 = something moved; read the rows.

set -uo pipefail
REPO="${T842_REPO_ROOT:-/opt/832-Workflow-designer}"
STRICT=0
[ "${1:-}" = "--strict" ] && STRICT=1

# shellcheck source=/dev/null
source "$REPO/.agentic-framework/agents/context/lib/safe-commands.sh" 2>/dev/null
if ! type is_commit_checkpoint_command &>/dev/null; then
    echo "REFUSE: is_commit_checkpoint_command not found — the predicate this pins is GONE."
    echo "  That is a bigger change than a regression; do not read this exit as a pass."
    exit 3
fi

FW="$REPO/.agentic-framework/bin/fw"
M='-m "T-842: pin"'
PASS=0; FAIL=0; DEFECTS=0; N=0
say(){ N=$((N+1)); printf '%s %d - %s\n' "$1" "$N" "$2"; }
ok(){  PASS=$((PASS+1)); say ok "$1"; }
bad(){ FAIL=$((FAIL+1)); say "not ok" "$1"; }

check(){   # check <ALLOW|BLOCK|DEFECT-BLOCK> <label> <cmd>
    local expect="$1" label="$2" cmd="$3" got
    if is_commit_checkpoint_command "$cmd"; then got=ALLOW; else got=BLOCK; fi
    case "$expect" in
        DEFECT-BLOCK)
            if [ "$STRICT" -eq 1 ]; then
                [ "$got" = ALLOW ] && ok "$label (strict: now ALLOWED — defect fixed)" \
                                   || bad "$label (strict: still BLOCKED — mandated spelling unusable)"
            elif [ "$got" = BLOCK ]; then
                DEFECTS=$((DEFECTS+1)); ok "KNOWN-DEFECT still present: $label"
            else
                bad "KNOWN-DEFECT now ALLOWED ($label) — upstream fixed it. Drop the row and lower EXPECTED_DEFECTS."
            fi ;;
        *)
            [ "$got" = "$expect" ] && ok "$label -> $got" || bad "$label -> $got, expected $expect" ;;
    esac
}

echo "=== A. what MUST be admitted, and is (the invariants) ==="
check ALLOW "bare git commit"                  "git commit $M"
check ALLOW "bare git commit -q"               "git commit -q $M"
check ALLOW "cd REPO && bare git commit"       "cd $REPO && git commit $M"
check ALLOW "git add && bare git commit"       "git add x && git commit $M"
# The trailer CLAUDE.md mandates carries <angle brackets> inside a quoted -m; T-3245 made
# the predicate quote-aware for exactly this. If this row ever blocks, that fix regressed.
check ALLOW "commit carrying the Co-Authored-By trailer (T-3245)" \
      'git commit -m "T-842: pin

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"'

echo
echo "=== B. what MUST be refused (negative controls — these prove the predicate says no) ==="
check BLOCK "rm -rf /"                          'rm -rf /'
check BLOCK "--no-verify voids the allowance"   "git commit --no-verify $M"
check BLOCK "command substitution"              'git commit -m "T-842: $(whoami)"'
check BLOCK "a redirect is a write"             "git commit $M > /var/tmp/t842.out"
check BLOCK "not a commit at all"               'git push origin master'
check BLOCK "commit smuggling a second verb"    "git commit $M && rm -rf /var/tmp/x"

echo
echo "=== C. KNOWN DEFECTS — mandated spellings the predicate cannot match ==="
echo "    CLAUDE.md mandates BOTH 'fw git commit' AND 'cd /path && .agentic-framework/bin/fw ...'"
check DEFECT-BLOCK "DEFECT A: fw git commit (on PATH)"       "fw git commit $M"
check DEFECT-BLOCK "DEFECT A: absolute-path fw git commit"   "$FW git commit $M"
check DEFECT-BLOCK "DEFECT A: relative-path fw git commit"   ".agentic-framework/bin/fw git commit $M"
check DEFECT-BLOCK "DEFECT A: the copy-pasteable mandated form (cd && fw git commit)" \
      "cd $REPO && $FW git commit $M"
check DEFECT-BLOCK "DEFECT B: timeout + BARE git commit (T-839, sent upstream, unfixed)" \
      "timeout 300 git commit $M"

echo
echo "=== D. the ratchet ==="
EXPECTED_DEFECTS=5   # 4 mandated spellings from defect A (one root cause) + 1 for defect B
if [ "$STRICT" -eq 1 ]; then
    echo "# strict mode: ratchet not evaluated (every DEFECT row was asserted as ALLOW above)"
elif [ "$DEFECTS" -eq "$EXPECTED_DEFECTS" ]; then
    ok "ratchet holds: $DEFECTS known defect(s), expected $EXPECTED_DEFECTS"
else
    bad "ratchet MOVED: $DEFECTS known defect(s), expected $EXPECTED_DEFECTS — read section C and update this file"
fi

printf '\n# passed %d, failed %d, known-defects %d\n' "$PASS" "$FAIL" "$DEFECTS"
[ "$FAIL" -eq 0 ]
