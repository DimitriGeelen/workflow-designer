#!/usr/bin/env bash
# T-371 teeth: prove the git enforcement hooks FIRE, in both directions.
#
# Existence is not enforcement. A hook that is present but non-executable, or that
# exits 0 on every input, is indistinguishable from the six-day absence this task
# exists to fix — that is the whole lesson of T-350 (a safeguard never confirmed to
# have applied is not one). So each leg below must be able to fail:
#
#   (a) a message with no task reference must be REJECTED   -> the gate has teeth
#   (b) a conforming message must be ACCEPTED               -> it is a gate, not a wall
#   (c) the hook file must be executable                    -> git silently skips it otherwise
#
# (b) is not filler. A hook that rejects everything would pass (a) and would still be
# broken; without (b) this harness would green on a gate nobody could commit through.
#
# Invokes the hook exactly as git does — `commit-msg <path-to-message-file>` from the
# repo root — so no commits are created and history is untouched.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 2

HOOK=".git/hooks/commit-msg"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=1; }

echo "== T-371 hook teeth =="

# ---- (c) present and executable -----------------------------------------------
if [ -f "$HOOK" ]; then pass "commit-msg hook present"; else fail "commit-msg hook MISSING"; fi
if [ -x "$HOOK" ]; then
  pass "commit-msg hook executable (git skips non-executable hooks silently)"
else
  fail "commit-msg hook NOT executable — git would skip it and report nothing"
fi

if [ ! -x "$HOOK" ]; then
  echo; echo "RESULT: FAIL — cannot exercise a hook that will not run."; exit 1
fi

# ---- (a) the gate must reject a violation -------------------------------------
BAD="$TMP/bad.msg"
printf 'tidy up some files\n' > "$BAD"
if "$HOOK" "$BAD" >"$TMP/bad.out" 2>&1; then
  fail "(a) message with NO task reference was ACCEPTED — P-002 gate is inert"
  sed 's/^/        /' "$TMP/bad.out" | head -5
else
  pass "(a) message with no task reference rejected (rc=$?)"
fi

# ---- (b) ...and accept a conforming one ---------------------------------------
GOOD="$TMP/good.msg"
printf 'T-371: prove the restored commit-msg hook fires\n' > "$GOOD"
if "$HOOK" "$GOOD" >"$TMP/good.out" 2>&1; then
  pass "(b) conforming message accepted — gate discriminates, does not just refuse"
else
  fail "(b) conforming message REJECTED — this is a wall, not a gate"
  sed 's/^/        /' "$TMP/good.out" | head -5
fi

# ---- the other three hooks: presence + executability only ----------------------
# Deliberately NOT exercised. pre-commit is a secret scanner and feeding it a
# synthetic credential to watch it fire is a worse idea than the coverage is worth;
# pre-push runs a full audit. Stating the limit explicitly so a green here is not
# read as "all four hooks proven".
echo "  --  scope: only commit-msg is exercised; the other three are checked for"
echo "      presence and executability only (see comment in this file for why)"
for h in pre-commit post-commit pre-push; do
  if [ -x ".git/hooks/$h" ]; then pass "$h present + executable"; else fail "$h missing or not executable"; fi
done

echo
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — commit-msg gate proven to fire in both directions."
else
  echo "RESULT: FAIL"
fi
exit "$FAIL"
