#!/usr/bin/env bash
# revisit-due-scan.sh — Daily scan for ripe revisit_at deferrals (T-1452 / G-053)
#
# Scans $PROJECT_ROOT/.tasks/active/*.md for frontmatter `revisit_at: <YYYY-MM-DD>`
# entries whose date is <= today (UTC). Writes ripe matches to
# .context/working/.revisits-due.txt — one line per task:
#
#     T-XXX fires YYYY-MM-DD: <name>
#
# When no tasks are ripe the output file is removed entirely so downstream
# readers (handover banner, Watchtower) can treat "file absent" and "file
# empty" as the same signal — nothing to surface.
#
# Idempotent: re-running on the same day produces the same output.
#
# Designed to run from cron (silent on success, log to stderr on error).

set -euo pipefail

# Resolve PROJECT_ROOT: prefer env var (set by cron line); fall back to walking
# up from this script's location looking for the project shape marker
# (.framework.yaml for consumers, FRAMEWORK.md for the framework repo itself).
# T-1868 (G-063): the prior fixed-depth `../../..` form was vendored-only and
# silently resolved to `/opt/.tasks/active` when run inside the framework repo.
if [ -z "${PROJECT_ROOT:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    _walk="$SCRIPT_DIR"
    while [ "$_walk" != "/" ]; do
        if [ -f "$_walk/.framework.yaml" ] || [ -f "$_walk/FRAMEWORK.md" ]; then
            PROJECT_ROOT="$_walk"
            break
        fi
        _walk="$(dirname "$_walk")"
    done
    if [ -z "${PROJECT_ROOT:-}" ]; then
        echo "revisit-due-scan: cannot resolve PROJECT_ROOT (no .framework.yaml or FRAMEWORK.md marker found walking up from $SCRIPT_DIR)" >&2
        exit 1
    fi
fi

TASKS_DIR="$PROJECT_ROOT/.tasks/active"
OUTPUT_FILE="$PROJECT_ROOT/.context/working/.revisits-due.txt"
# T-373 (G-008): second, separate signal — DEFER decisions carrying NO revisit date.
#
# `fw inception decide <id> defer` parks a task at horizon:later and never sets
# `revisit_at` — the string does not occur anywhere in lib/inception.sh. This scan
# then skipped it at the `[ -z "$revisit_at" ] && continue` below, so the canonical
# way to create a deferral produced exactly the state the deferral scanner could not
# see. Absence stood for both "deliberately no date" and "nobody set one", and the
# silent branch was the one that meant the task would never ripen.
#
# Deliberately a SEPARATE file rather than extra lines in .revisits-due.txt: that file
# means "ripe today" and its consumer (handover.sh) prints it under that heading. A
# dateless deferral is not ripe today — it has no date at all. Widening an existing
# signal to cover a second meaning is how the ambiguity got here in the first place.
UNDATED_FILE="$PROJECT_ROOT/.context/working/.revisits-undated.txt"

if [ ! -d "$TASKS_DIR" ]; then
    echo "revisit-due-scan: tasks dir not found at $TASKS_DIR" >&2
    exit 0
fi

TODAY=$(date -u +%Y-%m-%d)

tmp=$(mktemp)
tmp_undated=$(mktemp)
trap 'rm -f "$tmp" "$tmp_undated"' EXIT

for f in "$TASKS_DIR"/*.md; do
    [ -f "$f" ] || continue
    # Pull frontmatter fields. revisit_at must be a *real* ISO date
    # (YYYY-MM-DD digits only), not the commented hint `# revisit_at: YYYY-MM-DD`
    # nor the literal placeholder string `YYYY-MM-DD`.
    revisit_at=$(awk '
        /^---$/ { n++; if (n==2) exit; next }
        n==1 && /^revisit_at:[[:space:]]/ {
            sub(/^revisit_at:[[:space:]]*/, "")
            sub(/[[:space:]]*#.*$/, "")
            sub(/[[:space:]]+$/, "")
            print
            exit
        }
    ' "$f")

    # T-373: make the partition total BEFORE the skip. A task whose Decision block
    # records DEFER but which carries no usable revisit date is not "nothing to do" —
    # it is a deferral with no scheduled return, and it is reported as its own class.
    if ! [[ "$revisit_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        if grep -qE '^\*\*Decision\*\*:[[:space:]]*DEFER' "$f" 2>/dev/null; then
            u_id=$(awk '/^---$/{n++;if(n==2)exit;next} n==1 && /^id:/{sub(/^id:[[:space:]]*/,"");print;exit}' "$f")
            u_name=$(awk '/^---$/{n++;if(n==2)exit;next} n==1 && /^name:/{sub(/^name:[[:space:]]*"?/,"");sub(/"?[[:space:]]*$/,"");print;exit}' "$f")
            [ -n "$u_id" ] && echo "$u_id deferred with no revisit date: $u_name" >> "$tmp_undated"
        fi
        continue
    fi

    # Lexicographic compare on ISO dates is correct
    if [[ "$revisit_at" > "$TODAY" ]]; then
        continue
    fi

    id=$(awk '/^---$/{n++;if(n==2)exit;next} n==1 && /^id:/{sub(/^id:[[:space:]]*/,"");print;exit}' "$f")
    name=$(awk '/^---$/{n++;if(n==2)exit;next} n==1 && /^name:/{sub(/^name:[[:space:]]*"?/,"");sub(/"?[[:space:]]*$/,"");print;exit}' "$f")

    [ -z "$id" ] && continue
    echo "$id fires $revisit_at: $name" >> "$tmp"
done

mkdir -p "$(dirname "$OUTPUT_FILE")"

if [ -s "$tmp" ]; then
    mv "$tmp" "$OUTPUT_FILE"
else
    rm -f "$OUTPUT_FILE"
fi

# Same absent-or-empty convention as above, so readers can treat both alike.
if [ -s "$tmp_undated" ]; then
    mv "$tmp_undated" "$UNDATED_FILE"
else
    rm -f "$UNDATED_FILE"
fi

exit 0
