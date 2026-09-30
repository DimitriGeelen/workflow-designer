#!/usr/bin/env bash
# _t943-heading-states.sh — the three states extract_verification_block must not conflate.
#
# Asserted directly against the live function, not through the gate's printed output, so this
# stays true if the caller's wording changes. The gate-level behaviour is covered by
# tools/_t574-p011-block-locator-teeth.py; this is the contract underneath it.
#
#   rc 0 + content   a well-formed section          -> run those commands
#   rc 0 + empty     there is genuinely no section  -> documented pass-through
#   rc 3 + empty     a heading is there but no line matches exactly  -> REFUSE
#   rc 2 + empty     the section cannot be decoded  -> REFUSE (T-3232, not exercised here)
#
# Before T-943 the middle two were the same value, which is how a task could close having run
# zero commands while printing a pass. Two of the fixtures below carry `false` — a command that
# MUST block a close if it runs — so a regression cannot read as green.
#
# The over-fire controls matter as much as the defect cases: this corpus is full of tasks whose
# bodies discuss `## Verification` in prose, and a substring test would refuse all of them.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export FRAMEWORK_ROOT="$ROOT/.agentic-framework"
LIB="$FRAMEWORK_ROOT/lib/verification-port.sh"

[ -f "$LIB" ] || { echo "ABORT: lib not found: $LIB" >&2; exit 1; }
# shellcheck disable=SC1090
source "$LIB" || { echo "ABORT: could not source $LIB" >&2; exit 1; }
if ! declare -F extract_verification_block >/dev/null 2>&1; then
    echo "ABORT: extract_verification_block is not defined after sourcing the lib." >&2
    echo "  The function moved or was renamed. This probe cannot test what it claims to;" >&2
    echo "  that is a failure, not a skip." >&2
    exit 1
fi

TD="$(mktemp -d)"
trap 'rm -rf "$TD"' EXIT

mk() { printf '%s' "$2" > "$TD/$1.md"; }

mk wellformed        '## Acceptance Criteria
- [x] a

## Verification
true

## Updates
'
mk absent            '## Acceptance Criteria
- [x] a

## Updates
'
# T-572's real shape: a backticked mention glued the heading to the end of an AC line.
mk glued             '## Acceptance Criteria
- [x] the commands live in the `## Verification` section ## Verification
false

## Updates
'
mk suffixed          '## Acceptance Criteria
- [x] a

## Verification (P-011)
false

## Updates
'
# OVER-FIRE CONTROLS — prose mentions must not be read as malformed headings.
mk prose_with_heading '## Acceptance Criteria
- [x] the commands live in the `## Verification` section

## Verification
true

## Updates
'
mk prose_no_heading  '## Acceptance Criteria
- [x] see CLAUDE.md on the `## Verification` gate

## Updates
'

fails=0
check() {
    local name="$1" want_rc="$2" want_shape="$3" out rc
    out="$(extract_verification_block "$TD/$name.md")"; rc=$?
    local shape="empty"; [ -n "$out" ] && shape="content"
    if [ "$rc" = "$want_rc" ] && [ "$shape" = "$want_shape" ]; then
        printf 'PASS  %-20s rc=%s %-7s\n' "$name" "$rc" "$shape"
    else
        printf 'FAIL  %-20s rc=%s %-7s (want rc=%s %s)\n' "$name" "$rc" "$shape" "$want_rc" "$want_shape"
        fails=$((fails + 1))
    fi
}

check wellformed         0 content
check absent             0 empty
check glued              3 empty
check suffixed           3 empty
check prose_with_heading 0 content
check prose_no_heading   0 empty

# The load-bearing assertion: the two pass-through-looking states must DIFFER.
a_out="$(extract_verification_block "$TD/absent.md")";  a_rc=$?
g_out="$(extract_verification_block "$TD/glued.md")";   g_rc=$?
if [ -z "$a_out" ] && [ -z "$g_out" ] && [ "$a_rc" != "$g_rc" ]; then
    printf 'PASS  %-20s both empty, rc %s vs %s — absent and malformed are DISTINGUISHABLE\n' \
        "absent-vs-malformed" "$a_rc" "$g_rc"
else
    printf 'FAIL  %-20s absent rc=%s malformed rc=%s — the states are conflated, which IS the defect\n' \
        "absent-vs-malformed" "$a_rc" "$g_rc"
    fails=$((fails + 1))
fi

echo
if [ "$fails" -eq 0 ]; then
    echo "PASS: 7/7 — the four states are distinct and prose mentions do not over-fire"
    exit 0
fi
echo "FAIL: $fails leg(s)"
exit 1
