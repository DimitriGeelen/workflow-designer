#!/bin/bash
# _t1192-upgrade-templates.sh — T-1192: after a framework upgrade, settle the task templates it synced.
# `fw upgrade` copies .agentic-framework/.tasks/templates/*.md over .tasks/templates/ and leaves them uncommitted,
# or, where we keep our own template, writes <name>.upstream beside it. Both were found later by hand (T-1138,
# T-1188). This lists each case; --commit settles the safe ones and names the rest.
#   SYNCED      modified/untracked template identical to the vendored copy: safe to commit
#   DIFFERS     modified template NOT identical to the vendored copy: a person decides
#   SUPERSEDED  <name>.upstream whose every line our template already has: safe to remove
#   KEEP        <name>.upstream with lines our template lacks: a person merges them (the line count is printed)
#
#   tools/_t1192-upgrade-templates.sh [--root DIR] [--commit --task T-XXXX]
# Exit 0 = nothing needs a person (all SYNCED/SUPERSEDED, or nothing found). 1 = a DIFFERS or KEEP. 2 = could not run.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMMIT=0; TASK=""
while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="$2"; shift 2 ;;
        --commit) COMMIT=1; shift ;;
        --task) TASK="$2"; shift 2 ;;
        *) echo "unknown argument: $1"; exit 2 ;;
    esac
done
[ "$COMMIT" = 1 ] && ! [[ "$TASK" =~ ^T-[0-9]+$ ]] && { echo "--commit needs --task T-XXXX"; exit 2; }
cd "$ROOT" || exit 2
LOCAL=.tasks/templates; VEND=.agentic-framework/.tasks/templates
[ -d "$LOCAL" ] && [ -d "$VEND" ] || { echo "CANNOT RUN: no $LOCAL or $VEND under $ROOT"; exit 2; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "CANNOT RUN: $ROOT is not a git repo"; exit 2; }

synced=(); superseded=(); person=0; found=0
for f in "$LOCAL"/*.md; do
    [ -f "$f" ] || continue
    if git ls-files --error-unmatch -- "$f" >/dev/null 2>&1 && git diff --quiet HEAD -- "$f"; then continue; fi
    found=1
    if [ -f "$VEND/$(basename "$f")" ] && cmp -s "$f" "$VEND/$(basename "$f")"; then
        echo "SYNCED      $f (identical to $VEND/$(basename "$f"))"; synced+=("$f")
    else
        echo "DIFFERS     $f (not identical to the vendored copy: decide by hand)"; person=1
    fi
done
for u in "$LOCAL"/*.upstream; do
    [ -f "$u" ] || continue
    found=1
    base="${u%.upstream}"
    if [ ! -f "$base" ]; then echo "KEEP        $u (no $base to compare with)"; person=1; continue; fi
    n=$(diff -- "$u" "$base" | grep -c '^<')
    if [ "$n" = 0 ]; then echo "SUPERSEDED  $u (every line is in $base)"; superseded+=("$u")
    else echo "KEEP        $u ($n line(s) $base lacks: merge by hand)"; person=1; fi
done
[ "$found" = 0 ] && echo "nothing to settle: no modified template, no .upstream file"

if [ "$COMMIT" = 1 ]; then
    for u in "${superseded[@]}"; do rm -f -- "$u" && echo "removed     $u"; done
    if [ "${#synced[@]}" -gt 0 ]; then
        git add -- "${synced[@]}" && git commit -q -m "$TASK: commit the task template(s) fw upgrade synced, identical to the vendored copy: ${synced[*]}" -- "${synced[@]}" \
            && echo "committed   ${#synced[@]} template(s): $(git log -1 --format=%h)" || { echo "commit failed"; exit 2; }
    fi
fi
exit "$person"
