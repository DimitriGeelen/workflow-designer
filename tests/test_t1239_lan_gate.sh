#!/usr/bin/env bash
# T-1239: the LAN-address pre-commit gate rewrites generated text, refuses code, leaves AEF's tree and the ledgers alone.
# Runs the REAL gate in a throwaway repo. Addresses are built at run time, so this file carries none.
set -u
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
A="192.168"; DEV="$A.10.107"; OTHER="$A.10.122"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "PASS  $1"; }
bad() { fail=$((fail + 1)); echo "FAIL  $1"; }
cd "$T" && git init -q && git config user.email t@t && git config user.name t
mkdir -p tools docs .context/handovers .agentic-framework .context/reviews src
cp "$ROOT/tools/_t1239-lan-address-gate.sh" "$ROOT/tools/scrub-lan-addresses.py" tools/
git add tools && git commit -qm base
gate() { bash tools/_t1239-lan-address-gate.sh 2>"$T/err"; }

# 1 a handover with a Watchtower URL: rewritten to a placeholder, port kept, commit allowed
printf 'open http://%s:3013/review/T-1\n' "$DEV" > .context/handovers/h.md
git add .context/handovers/h.md
gate; rc=$?
staged=$(git show :.context/handovers/h.md)
{ [ "$rc" = 0 ] && [ "$staged" = "open http://<dev-host>:3013/review/T-1" ] && ! grep -q "$A" .context/handovers/h.md; } \
    && ok "1 generated text: rewritten to <dev-host>:3013 in the index and the worktree, commit allowed" \
    || bad "1 generated text: rc=$rc staged=$staged"
git commit -qm h --no-verify

# 2 code with an address: refused, nothing rewritten
printf 'HOST = "%s"\n' "$OTHER" > src/app.py
git add src/app.py
gate; rc=$?
{ [ "$rc" = 1 ] && grep -q "src/app.py" "$T/err" && git show :src/app.py | grep -q "$OTHER"; } \
    && ok "2 code: refused, named, left as it was" || bad "2 code: rc=$rc"
git rm -q --cached src/app.py; rm src/app.py

# 3 AEF's vendored tree and the append-only ledgers are never touched
printf 'x %s\n' "$DEV" > .agentic-framework/doc.md; printf '{"u":"%s"}\n' "$DEV" > .context/reviews/v.jsonl
git add .agentic-framework/doc.md .context/reviews/v.jsonl
gate; rc=$?
{ [ "$rc" = 0 ] && git show :.agentic-framework/doc.md | grep -q "$DEV" && git show :.context/reviews/v.jsonl | grep -q "$DEV"; } \
    && ok "3 .agentic-framework/ and .context/reviews/: untouched, allowed" || bad "3 exclusions: rc=$rc"
git commit -qm x --no-verify

# 4 a clean commit passes silently
printf 'no address here\n' > docs/clean.md; git add docs/clean.md
gate; rc=$?
{ [ "$rc" = 0 ] && [ ! -s "$T/err" ]; } && ok "4 clean commit: allowed, silent" || bad "4 clean: rc=$rc"
git commit -qm c --no-verify

# 5 a partly staged file: the staged part is rewritten, the unstaged edit is kept in the worktree
printf 'a http://%s:3000\n' "$DEV" > docs/p.md; git add docs/p.md
printf 'b unstaged edit\n' >> docs/p.md
gate; rc=$?
{ [ "$rc" = 0 ] && [ "$(git show :docs/p.md)" = "a http://<dev-host>:3000" ] && grep -q 'b unstaged edit' docs/p.md; } \
    && ok "5 partly staged: index rewritten, unstaged edit kept" || bad "5 partial: rc=$rc index=$(git show :docs/p.md)"

git reset -q --hard

# T-1320: the hooks as installed, through real commits. A pathspec commit runs pre-commit on a temporary index; the
# post-commit half must leave HEAD, index and worktree equal (before the fix the index kept the address, staged).
mkdir -p .git/hooks
printf '#!/bin/sh\nbash "$(git rev-parse --show-toplevel)/tools/_t1239-lan-address-gate.sh" || exit 1\n' > .git/hooks/pre-commit
printf '#!/bin/bash\n# <<< agentic-framework hook <<<' > .git/hooks/post-commit   # no trailing newline, as a worst case
chmod +x .git/hooks/pre-commit
cp "$ROOT/tools/_t1239-install-hook.sh" tools/
bash tools/_t1239-install-hook.sh >/dev/null; bash tools/_t1239-install-hook.sh >/dev/null   # twice: idempotent
n=$(grep -c '832-T-1320-lan-address-index' .git/hooks/post-commit)
{ [ "$n" = 1 ] && bash tools/_t1239-install-hook.sh --check >/dev/null && grep -q '^# <<< agentic-framework hook <<<$' .git/hooks/post-commit; } \
    && ok "6 installer: one post-commit line after the managed block, idempotent, --check passes" \
    || bad "6 installer: $n line(s); $(cat .git/hooks/post-commit)"

clean3() { [ "$(git show "HEAD:$1")" = "$(git show ":$1")" ] && cmp -s "$1" <(git show "HEAD:$1") && ! git show "HEAD:$1" | grep -q "$A"; }
printf 'see http://%s:3013/x\n' "$DEV" > docs/ps.md; git add docs/ps.md; git commit -qm ps0 --no-verify -- docs/ps.md
printf 'see http://%s:3013/y\n' "$DEV" >> docs/ps.md
git commit -qm ps -- docs/ps.md 2>/dev/null
{ clean3 docs/ps.md && [ -z "$(git diff --cached --name-only)" ] && [ ! -f .git/t1239-rewritten ]; } \
    && ok "7 pathspec commit: HEAD, index and worktree hold the placeholder, nothing left staged" \
    || bad "7 pathspec commit: staged=$(git diff --cached --name-only) index=$(git show :docs/ps.md | tail -1)"

printf 'add http://%s:3000/z\n' "$OTHER" >> docs/ps.md; git add docs/ps.md; git commit -qm plain 2>/dev/null
{ clean3 docs/ps.md && [ -z "$(git diff --cached --name-only)" ]; } \
    && ok "8 plain add + commit: all three equal, nothing staged" || bad "8 plain commit"

# 9 an index entry that differs from HEAD by more than the scrub (someone's staged edit) is never reset
printf 'docs/ps.md\n' > .git/t1239-rewritten
printf 'a real staged edit\n' >> docs/ps.md; git add docs/ps.md; git show HEAD:docs/ps.md > docs/ps.md
before=$(git ls-files -s docs/ps.md)
bash tools/_t1239-lan-address-gate.sh --post-commit
{ [ "$(git ls-files -s docs/ps.md)" = "$before" ] && git show :docs/ps.md | grep -q 'a real staged edit'; } \
    && ok "9 a staged edit that is not the scrub: index left as it was" || bad "9 staged edit reset"

echo "T-1239 LAN gate: $pass passed, $fail failed"
[ "$fail" = 0 ]
