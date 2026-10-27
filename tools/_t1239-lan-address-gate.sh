#!/usr/bin/env bash
# _t1239-lan-address-gate.sh — no LAN address (192.168.x.y) enters a commit (832 T-1239).
#
# The repo is mirrored to a public GitHub repository; on 2026-10-20 it carried estate addresses in 992 tracked files.
# The operator ruled: scrub the current files (tools/scrub-lan-addresses.py) and keep new ones out. This gate is the
# "keep out" half, run from .git/hooks/pre-commit (installed by tools/_t1239-install-hook.sh, which the T-1000
# installer calls after every upgrade).
#
# Two kinds of staged file, two answers:
#   generated text and state (.context/, .tasks/, docs/, *.md, *.yaml, *.json, *.jsonl, *.txt, *.log):
#       the framework writes Watchtower URLs into handovers and task updates itself, and a refused handover commit
#       would lose the session's handover; so the addresses are rewritten to placeholders (<dev-host>, <git-host>,
#       <lan-host>, port kept) and the file is re-staged.
#   everything else (code: src/, tools/, tests/, dist/, scripts):
#       refused, because a placeholder would break code that uses the address; a person fixes it (read the host from
#       .context/working/watchtower.url, or use 127.0.0.1 for a service on this host).
# Never touched: .agentic-framework/ (AEF's vendored code) and .context/reviews/ (append-only ledgers).
#
#   exit 0 = clean (possibly after rewriting); 1 = refused
#
# --post-commit (T-1320), run from .git/hooks/post-commit: a pathspec commit (`git commit -- f`) runs pre-commit on a
# temporary index, so the rewrite reaches the commit and the worktree but not the real index, which git fills from the
# unscrubbed worktree copy BEFORE the hook and writes out after it: HEAD and worktree say <dev-host>, the index the
# address, a staged change nobody made. Pre-commit records the paths it rewrote; post-commit sets each one's index
# entry back to HEAD's blob, only where the worktree already equals HEAD and the index differs from HEAD by the
# scrub alone (so no one's staged edit is undone). Always exits 0: the commit has happened.
set -u
ROOT=$(git rev-parse --show-toplevel) || exit 0
cd "$ROOT" || exit 0
PAT='192\.168\.[0-9]{1,3}\.[0-9]{1,3}'
LIST=$(git rev-parse --git-path t1239-rewritten) || LIST=""
if [ "${1:-}" = "--post-commit" ]; then
    [ -n "$LIST" ] && [ -f "$LIST" ] || exit 0
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        head_blob=$(git rev-parse -q --verify "HEAD:$f" 2>/dev/null) || continue
        idx=$(git ls-files -s -- "$f"); idx_blob=$(echo "$idx" | awk '{print $2}'); mode=$(echo "$idx" | awk '{print $1}')
        [ -n "$idx_blob" ] && [ "$idx_blob" != "$head_blob" ] || continue
        [ -f "$f" ] && [ "$(git hash-object -- "$f")" = "$head_blob" ] || continue
        [ "$(git cat-file blob "$idx_blob" | python3 "$ROOT/tools/scrub-lan-addresses.py" --stdin | git hash-object --stdin)" = "$head_blob" ] || continue
        git update-index --cacheinfo "$mode,$head_blob,$f"
    done < "$LIST"
    rm -f "$LIST"
    exit 0
fi
# The list is never cleared here: a second run in the same commit would erase the first run's paths, and an entry left
# by a refused commit is harmless (post-commit re-checks every path before it touches the index).
refused=()
rewritten=()
while IFS= read -r -d '' f; do
    case "$f" in .agentic-framework/*|.context/reviews/*) continue ;; esac
    git diff --cached -U0 -- "$f" | grep -E '^\+[^+]' | grep -qE "$PAT" || continue
    case "$f" in
        .context/*|.tasks/*|docs/*|*.md|*.yaml|*.yml|*.json|*.jsonl|*.txt|*.log)
            # Rewrite the STAGED content, so a partly staged file keeps its unstaged part as it was.
            tmp=$(mktemp) || { refused+=("$f (mktemp failed)"); continue; }
            git show ":$f" | python3 "$ROOT/tools/scrub-lan-addresses.py" --stdin > "$tmp" || { rm -f "$tmp"; refused+=("$f (rewrite failed)"); continue; }
            blob=$(git hash-object -w "$tmp"); mode=$(git ls-files -s -- "$f" | awk '{print $1}')
            git update-index --cacheinfo "$mode,$blob,$f" || { rm -f "$tmp"; refused+=("$f (restage failed)"); continue; }
            # The worktree copy too, when it equals what was staged (the usual case), so the next diff is clean.
            if [ -f "$f" ] && ! grep -qE "$PAT" "$tmp" && python3 "$ROOT/tools/scrub-lan-addresses.py" --stdin < "$f" | cmp -s - "$tmp"; then
                cp "$tmp" "$f"
            fi
            rm -f "$tmp"
            [ -n "$LIST" ] && printf '%s\n' "$f" >> "$LIST"
            rewritten+=("$f") ;;
        *)
            refused+=("$f") ;;
    esac
done < <(git diff --cached --name-only -z --diff-filter=AM)
[ "${#rewritten[@]}" -gt 0 ] && echo "LAN-address gate (T-1239): rewrote addresses to placeholders in ${#rewritten[@]} staged file(s): ${rewritten[*]}" >&2
if [ "${#refused[@]}" -gt 0 ]; then
    echo "" >&2
    echo "ERROR: commit refused — a LAN address (192.168.x.y) is in staged code (T-1239; the repo is mirrored publicly):" >&2
    printf '  %s\n' "${refused[@]}" >&2
    echo "  Read the host from .context/working/watchtower.url, or use 127.0.0.1 for a service on this host." >&2
    exit 1
fi
exit 0
