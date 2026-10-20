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

echo "T-1239 LAN gate: $pass passed, $fail failed"
[ "$fail" = 0 ]
