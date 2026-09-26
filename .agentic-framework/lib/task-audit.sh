#!/bin/bash
# lib/task-audit.sh — Placeholder audit chokepoint for task files (T-1111/T-1113)
#
# Scans a task file for literal placeholder content that should have been
# replaced during authoring. Exists to close the L-006 bleed-through class
# documented in docs/reports/T-1111-placeholder-sections-rca.md and to
# resolve G-018 (silent quality decay).
#
# Called by:
#   - bin/fw task review  (before emit_review marker creation)
#   - lib/inception.sh:do_inception_decide  (before marker/recommendation checks)
#
# Usage:
#   source "$FW_LIB_DIR/task-audit.sh"
#   audit_task_placeholders "$task_file" || exit 1

# The ## Updates and ## Dialogue Log sections are excluded because they
# legitimately document bug patterns that mention these strings. Fenced
# code blocks are also excluded so regression-test-style documentation
# can cite the literal patterns without tripping the gate.
audit_task_placeholders() {
    local task_file="${1:-}"

    if [ -z "$task_file" ] || [ ! -f "$task_file" ]; then
        echo "audit_task_placeholders: missing or unreadable file: ${task_file}" >&2
        return 2
    fi

    local issues=""
    local found=0
    local in_updates=0
    local in_dialogue=0
    local in_fence=0
    local line_num=0
    local line

    while IFS= read -r line || [ -n "$line" ]; do
        line_num=$((line_num + 1))

        # Toggle fenced code block state (```)
        if [[ "$line" =~ ^\`\`\` ]]; then
            in_fence=$((1 - in_fence))
            continue
        fi
        [ $in_fence -eq 1 ] && continue

        # Section tracking — exempt Updates and Dialogue Log
        if [[ "$line" =~ ^##[[:space:]]+Updates ]]; then
            in_updates=1
            continue
        fi
        if [[ "$line" =~ ^##[[:space:]]+Dialogue[[:space:]]+Log ]]; then
            in_dialogue=1
            continue
        fi
        if [[ "$line" =~ ^##[[:space:]] ]]; then
            in_updates=0
            in_dialogue=0
        fi
        [ $in_updates -eq 1 ] && continue
        [ $in_dialogue -eq 1 ] && continue

        # Strip inline backtick spans (`...`) so documentation that quotes the
        # patterns (e.g. T-1298 explaining what audit_task_placeholders detects)
        # is not flagged. Single-backtick spans only — fenced blocks already
        # handled above.
        local cleaned
        cleaned=$(echo "$line" | sed 's/`[^`]*`//g')

        # Placeholder patterns — literal template stubs that should have been
        # replaced. Each pattern here is explicitly chosen because it NEVER
        # appears in legitimate authored content, only in unfilled templates.
        #
        # T-1554: extend with the ordinal-criterion stubs the default template
        # actually ships (.tasks/templates/default.md). Without these, T-1545
        # itself reached the human review queue with literal placeholder ACs
        # visible — same silent-quality-decay class as T-1545 origin (an audit
        # exists, but doesn't match the real placeholder text the template ships).
        if echo "$cleaned" | grep -qE '\[Criterion [0-9]+\]|\[(First|Second|Third|Fourth|Fifth) criterion\]|\[TODO\]|\[PLACEHOLDER\]|\[Your recommendation here\]|\[REQUIRED before'; then
            issues="${issues}
  Line ${line_num}: $(echo "$line" | sed 's/^[[:space:]]*//')"
            found=1
        fi
    done < "$task_file"

    if [ $found -eq 1 ]; then
        local RED='' YELLOW='' NC=''
        if [ -z "${NO_COLOR:-}" ] && [ -t 2 ]; then
            RED=$'\033[0;31m'
            YELLOW=$'\033[1;33m'
            NC=$'\033[0m'
        fi
        echo "${RED}ERROR: Placeholder content detected in task file${NC}" >&2
        echo "  File: ${task_file}" >&2
        echo "  Unfilled placeholders:${issues}" >&2
        echo "" >&2
        echo "${YELLOW}These sections were never filled in. Fill them before review/decide.${NC}" >&2
        echo "${YELLOW}See docs/reports/T-1111-placeholder-sections-rca.md for context.${NC}" >&2
        return 1
    fi

    return 0
}

# T-1497: Empty `## Recommendation` gate for inception tasks.
#
# Pickup-created inceptions (lib/pickup.sh:268) get a template skeleton with
# `## Recommendation` containing only an HTML-comment placeholder. Without
# this gate the human is asked to GO/NO-GO on an empty form. Live regression
# triggered T-1501 + T-1502 in this session.
#
# Returns 0 if `## Recommendation` has a substantive non-commented
# `**Recommendation:**` line. Returns 1 otherwise. Intended to be called from
# do_inception_decide BEFORE any task-body mutation.
#
# Pure function — no env assumptions, no shell-out beyond standard tools.
audit_inception_recommendation() {
    local task_file="${1:-}"

    if [ -z "$task_file" ] || [ ! -f "$task_file" ]; then
        echo "audit_inception_recommendation: missing or unreadable file: ${task_file}" >&2
        return 2
    fi

    # Extract the ## Recommendation section body (between '## Recommendation'
    # and the next '## ' heading), strip HTML comments, then look for a
    # substantive **Recommendation:** line.
    local section
    # T-1528: terminate at any H2-or-deeper heading. Without this, an
    # Updates entry below Recommendation containing a literal `**Recommendation:**`
    # line could be falsely captured into the substantive check. Same class as
    # T-1519/T-1526/T-1527 — see L-293.
    section=$(awk '
        /^## Recommendation[[:space:]]*$/ { in_rec=1; next }
        in_rec && /^#{2,} / { exit }
        in_rec { print }
    ' "$task_file")

    # Strip HTML comments (single-line and multi-line) so placeholder
    # comments containing the word "Recommendation:" are not counted.
    local stripped
    stripped=$(printf '%s\n' "$section" | awk '
        /<!--/ { in_c=1 }
        !in_c { print }
        /-->/ { in_c=0 }
    ')

    # T-1510: also accept the bulleted form `- **Recommendation:** ...` and
    # `* **Recommendation:** ...` — both are valid markdown for inception
    # bodies that author the recommendation as a list item under a parent
    # heading. Without the optional `[-*]?` bullet marker the gate rejected
    # T-844 and T-705 (both DEFER'd weeks ago, with live `- **Recommendation:**`
    # lines on disk).
    # T-1746: also accept inner emphasis on the verdict — `**Recommendation:**
    # **GO**`, `*GO*`, etc. The `\*{0,2}` after the prefix lets the verdict
    # carry markdown emphasis (which agent-authored Recommendations frequently
    # use for visual weight). Without it the gate silently rejected T-1744 GO
    # four times via Watchtower (origin: T-1745 RCA).
    if printf '%s\n' "$stripped" | grep -qE '^[[:space:]]*[-*]?[[:space:]]*\*\*Recommendation:\*\*[[:space:]]*\*{0,2}[A-Za-z]'; then
        return 0
    fi
    return 1
}

# ── T-866 (arc-004): the Hypothesis gate ─────────────────────────────────────
#
# The BVP method this project scores with pairs every value-driver table with a
# hypothesis in a fixed three-part form:
#
#   "We believe that <change>, we will achieve <outcome>.
#    We will know that we are successful when we see <measurable signal>."
#
# The framework implemented Support x Weight and not the hypothesis, so a support
# score has had no referent: it can rank, but it cannot be WRONG, because there is
# no claim for it to be wrong about. This gate is the first half of fixing that.
#
# WHY IT FIRES ONLY ON GO. A NO-GO or DEFER commits nobody to delivering value, so
# demanding a measurable success clause there would be bureaucracy. GO is the
# moment the project takes on a claim, and the only moment at which refusing costs
# less than the thing being prevented.
#
# THE THIRD CLAUSE IS CHECKED WITH A PROXY, AND IT IS AN HONEST ONE. "Names
# something observable" cannot be decided mechanically. What CAN be decided is
# whether the clause contains anything a person could later go and look at — a
# number, a count, a named state. So: does the success clause carry a digit, or one
# of a short list of concrete-observation markers?
#
# That proxy is foolable by someone determined ("we will know when we see 1 happy
# user"). It is NOT foolable by the failure that actually occurs, which is the
# sincere vague clause: "when the system is better", "when the team is more
# productive", "when this feels right". Every one of those is refused. T-624 is the
# design constraint here — it chose a warning as its prevention, the warning was
# correct and adjacent to the field, and the number did not move in 28 days. A gate
# that refuses the common case beats a comment that refuses nothing.
audit_inception_hypothesis() {
    local task_file="${1:-}"
    local decision="${2:-go}"

    if [ -z "$task_file" ] || [ ! -f "$task_file" ]; then
        echo "audit_inception_hypothesis: missing or unreadable file: ${task_file}" >&2
        return 2
    fi

    case "$(printf '%s' "$decision" | tr '[:upper:]' '[:lower:]')" in
        go) ;;
        *) return 0 ;;
    esac

    # Same extraction shape as audit_inception_recommendation (T-1528): stop at any
    # H2-or-deeper heading, so a later section quoting the word cannot leak in.
    local section stripped
    section=$(awk '
        /^## Hypothesis[[:space:]]*$/ { in_h=1; next }
        in_h && /^#{2,} / { exit }
        in_h { print }
    ' "$task_file")

    stripped=$(printf '%s\n' "$section" | awk '
        /<!--/ { in_c=1 }
        !in_c { print }
        /-->/ { in_c=0 }
    ' | sed 's/[[:space:]]*$//' | grep -v '^[[:space:]]*$')

    if [ -z "$stripped" ]; then
        echo "HYPOTHESIS: missing or empty. A GO records that this project believes" >&2
        echo "  something. Say what, in the form the scoring method expects:" >&2
        echo "    We believe that <change>," >&2
        echo "    we will achieve <outcome>." >&2
        echo "    We will know that we are successful when we see <measurable signal>." >&2
        return 1
    fi

    local lower
    lower=$(printf '%s' "$stripped" | tr '[:upper:]' '[:lower:]')

    local missing=""
    printf '%s' "$lower" | grep -q 'we believe that' || missing="$missing 'We believe that'"
    printf '%s' "$lower" | grep -q 'we will achieve' || missing="$missing 'we will achieve'"
    printf '%s' "$lower" | grep -q 'we will know'    || missing="$missing 'We will know'"
    if [ -n "$missing" ]; then
        echo "HYPOTHESIS: not in the three-part form — missing:$missing" >&2
        echo "  The form is not decoration. Each clause answers a different question:" >&2
        echo "  what changes, what that buys, and how anyone would later tell if it worked." >&2
        return 1
    fi

    local success
    success=$(printf '%s' "$lower" | sed -n 's/.*we will know\(.*\)/\1/p')

    if printf '%s' "$success" | grep -qE '[0-9]'; then
        return 0
    fi
    if printf '%s' "$success" | grep -qE 'exit code|returns|reports|refuses|no longer|zero |none of|every |each |passes|fails'; then
        return 0
    fi

    echo "HYPOTHESIS: the success clause names nothing anyone could go and look at." >&2
    echo "  Found: ...we will know${success}" >&2
    echo "  A success clause has to be checkable by someone who was not in the room." >&2
    echo "  'the system is better' cannot be checked; '5 consecutive tests pass per site'" >&2
    echo "  can. Give it a count, a threshold, a named state, or an observable outcome." >&2
    return 1
}
