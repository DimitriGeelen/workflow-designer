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
set -u
ROOT=$(git rev-parse --show-toplevel) || exit 0
cd "$ROOT" || exit 0
PAT='192\.168\.[0-9]{1,3}\.[0-9]{1,3}'
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
