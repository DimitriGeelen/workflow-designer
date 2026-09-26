#!/usr/bin/env bash
# T-873 — teeth for the CLAUDE.md.bak review-signal check in agents/audit/audit.sh.
#
# WHAT IS UNDER TEST, and why it is extracted rather than re-implemented.
#
# The check lives inside a 7,900-line audit.sh that cannot be run against a
# fixture project cheaply. So this instrument lifts the block VERBATIM from the
# real file, between the `T-873 claude-bak-signal: begin/end` anchors, and
# evaluates it against stub `pass`/`warn`. A copy of the logic here would pass
# forever after audit.sh changed underneath it — the extraction is what keeps
# the test attached to the code it claims to cover. If the anchors vanish, the
# instrument reports MISSING ANCHORS and fails rather than silently testing
# nothing (T-3105: not-evaluated is not a pass).
#
# --mutation runs the CONTROL SET first. Every case must pass against the
# UNMUTATED block before any mutant is scored; if the controls go red the
# harness is broken and the run reports MUTATION SETUP BROKEN instead of
# claiming kills. A mutant "killed" by a broken harness is the exact false
# green this whole task is about.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT="$ROOT/.agentic-framework/agents/audit/audit.sh"
BEGIN='# ── T-873 claude-bak-signal: begin'
END='# ── T-873 claude-bak-signal: end ──'

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

extract() {
    # verbatim block between the anchors, exclusive of the anchor lines
    sed -n "/${BEGIN}/,/${END}/p" "$AUDIT" | sed '1d;$d'
}

BLOCK="$(extract)"
if [ -z "$BLOCK" ] || ! printf '%s' "$BLOCK" | grep -q '_t873_bak'; then
    echo "MISSING ANCHORS: could not extract the T-873 block from $AUDIT"
    echo "  The check may have been renamed, moved, or deleted. Nothing was tested."
    exit 1
fi

# Run the extracted block against a fixture dir. Emits lines "PASS|<text>" /
# "WARN|<text>" so cases assert on the verdict AND its wording.
# Mutations are applied as LITERAL text replacements and the application is
# ASSERTED. Bash `${var//pat/rep}` was the obvious tool and is the wrong one:
# the pattern is glob-interpreted, so `[[:space:]]` matches one whitespace
# character and `*` matches anything — a mutation written that way silently
# replaces nothing, the suite stays green, and the mutant is scored SURVIVED.
# That happened here on the first run of this file (T-873), which is why the
# replacement count is checked and a miss is a hard error, never a survival.
mutate() {  # mutate <find> <replace>  (stdin: block, stdout: mutated block)
    FIND="$1" REPL="$2" python3 -c '
import os, sys
src = sys.stdin.read()
find, repl = os.environ["FIND"], os.environ["REPL"]
n = src.count(find)
if n != 1:
    sys.stderr.write("MUTATION NOT APPLIED: pattern found %d time(s), expected exactly 1\n" % n)
    sys.exit(3)
sys.stdout.write(src.replace(find, repl))
'
}

run_block() {
    local proj="$1" mutation="${2:-none}" blk="$BLOCK" rc
    case "$mutation" in
        drop_identical_arm)
            # M1: only warn when lines actually differ — the design this task
            # explicitly rejected. A reviewed-but-uncleared .bak goes unreported.
            blk="$(printf '%s' "$blk" | mutate \
                '        warn "CLAUDE.md.bak present with no differing lines' \
                '        : "CLAUDE.md.bak present with no differing lines')" || return 3
            ;;
        drop_blank_filter)
            # M2: stop excluding blank lines from the lost-line count, so a
            # whitespace-only difference reads as lost governance.
            blk="$(printf '%s' "$blk" | mutate \
                "| grep -cvE '^[[:space:]]*\$' || true" \
                "| grep -c '' || true")" || return 3
            ;;
        none) ;;
        *) echo "unknown mutation: $mutation" >&2; return 99 ;;
    esac
    PROJECT_ROOT="$proj" bash -c '
        pass() { echo "PASS|$1"; }
        warn() { echo "WARN|$1"; }
        '"$blk"'
    ' 2>&1
}

pass_n=0; fail_n=0; FAILED=()
check() {  # check <name> <fixture> <mutation> <expect-regex>
    local name="$1" fixture="$2" mut="$3" want="$4" out rc
    out="$(run_block "$fixture" "$mut")"; rc=$?
    if [ "$rc" -eq 3 ]; then
        # The mutant was never built. Scoring it either way would be a lie:
        # SURVIVED would blame the suite for a defect it was never shown.
        echo "  MUTATION NOT APPLIED ($mut) — $out"
        exit 3
    fi
    if printf '%s\n' "$out" | grep -qE -- "$want"; then
        pass_n=$((pass_n + 1)); [ "${VERBOSE:-0}" = 1 ] && echo "  ok   $name"
    else
        fail_n=$((fail_n + 1)); FAILED+=("$name")
        echo "  FAIL $name"
        echo "       want /$want/"
        echo "       got  ${out:-<no output>}"
    fi
    return 0
}

# ── fixtures ──────────────────────────────────────────────────────────────
mk() { mkdir -p "$WORK/$1"; }

mk no_bak
printf 'line one\nline two\n' > "$WORK/no_bak/CLAUDE.md"

mk lost
printf 'kept\n' > "$WORK/lost/CLAUDE.md"
printf 'kept\ngone one\ngone two\ngone three\n' > "$WORK/lost/CLAUDE.md.bak"

mk identical
printf 'same\ntext\n' > "$WORK/identical/CLAUDE.md"
printf 'same\ntext\n' > "$WORK/identical/CLAUDE.md.bak"

mk blanks_only
printf 'same\ntext\n' > "$WORK/blanks_only/CLAUDE.md"
printf 'same\n\n\n   \ntext\n' > "$WORK/blanks_only/CLAUDE.md.bak"

mk no_claude          # .bak with no CLAUDE.md at all — not this check's business
printf 'orphan\n' > "$WORK/no_claude/CLAUDE.md.bak"

# ── the cases ─────────────────────────────────────────────────────────────
cases() {
    local m="${1:-none}"
    check "no_bak_passes"            "$WORK/no_bak"       "$m" '^PASS\|.*no pending governance-rewrite review'
    check "no_bak_names_population"  "$WORK/no_bak"       "$m" 'examined 1 CLAUDE.md'
    check "lost_lines_warn"          "$WORK/lost"         "$m" '^WARN\|.*governance rewrite unreviewed'
    check "lost_lines_exact_count"   "$WORK/lost"         "$m" '3 line\(s\) in CLAUDE.md.bak'
    check "identical_bak_warns"      "$WORK/identical"    "$m" '^WARN\|.*no differing lines'
    check "blank_only_is_not_loss"   "$WORK/blanks_only"  "$m" '^WARN\|.*no differing lines'
    check "no_claude_md_silent"      "$WORK/no_claude"    "$m" '^$'
}

if [ "${1:-}" = "--mutation" ]; then
    echo "=== CONTROL SET (unmutated block — must be all green) ==="
    cases none
    if [ "$fail_n" -ne 0 ]; then
        echo
        echo "MUTATION SETUP BROKEN: $fail_n control case(s) failed: ${FAILED[*]}"
        echo "  The harness is wrong, not the subject. No mutant was scored — a kill"
        echo "  measured through a broken harness is not evidence of anything."
        exit 2
    fi
    echo "  controls: $pass_n/$pass_n green"
    echo
    rc=0
    for m in drop_identical_arm drop_blank_filter; do
        pass_n=0; fail_n=0; FAILED=()
        echo "=== MUTANT: $m (expect at least one case to go red) ==="
        cases "$m"
        if [ "$fail_n" -eq 0 ]; then
            echo "  SURVIVED — no case detected $m. The suite does not cover it."
            rc=1
        else
            echo "  KILLED by: ${FAILED[*]}"
        fi
        echo
    done
    exit "$rc"
fi

echo "=== T-873 claude-bak review-signal teeth ==="
cases none
echo
echo "$pass_n passed, $fail_n failed"
[ "$fail_n" -eq 0 ]
