#!/usr/bin/env bash
# T-651 — zero-byte untracked files at the repo root are redirect debris, and the audit
# must say so.
#
# WHAT HAPPENED. 23 empty files appeared in the 832 root across two incidents, named
# `DEFER`, `Supersedes`, `rail`, `risk,`, `**their**`, `scope*,`, `them.` — the first word
# of each line of some markdown. Markdown handed to a shell through an unquoted expansion
# stops being text: `> Supersedes the earlier note` becomes "truncate a file named
# Supersedes". Leg 1 below reproduces that rather than asserting it, because the audit
# comment makes a provenance claim and a claim in a comment is still just a claim.
#
# THE PART WORTH REMEMBERING. They sat for five days in a repo that was audited twelve
# times in that window. Nothing missed them — nothing LOOKED. They are untracked, so no
# commit hook sees them; and `git status` files them under `??`, which is exactly the
# block a careful agent learns to filter past (832's own standing rule is "never
# `git add -A`, stage explicit paths", which trains the eye to skip that region). The
# discipline that prevents one accident created the blind spot for another.
#
# WHY THE SIZE TEST IS THE WHOLE CHECK. Legitimate untracked root files exist
# (screenshots, scratch output). Redirect debris is always 0 bytes. Leg 5 mutates the size
# test away and requires the non-empty control to START firing — without that leg,
# "no false positive on a screenshot" passes trivially against a check that never fires.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

PROJ="${T651_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="$PROJ/.agentic-framework/agents/audit/audit.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$SRC" ] || { echo "COULD-NOT-MEASURE: $SRC not found" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-651: stray root files are caught (and the mechanism that makes them) ==="
echo

# ---------------------------------------------------------------------------
echo "--- 1. the mechanism itself: markdown through an unquoted expansion"
REPRO="$TMP/repro"; mkdir -p "$REPRO"
(
  cd "$REPRO" || exit 1
  printf '> Supersedes the earlier note\n> DEFER is not a verdict\n' > body.md
  BODY="$(cat body.md)"
  # COMMAND position, not argument position. This distinction is the whole finding and
  # this leg is what established it: `sh -c "echo $BODY"` leaves the FIRST file holding
  # "the earlier note" (echo's args land in the redirect), whereas all 23 real files were
  # 0 bytes. Only command position produces that, because then every line is a bare
  # redirect with no command to write anything. The first draft of this leg used the echo
  # form and failed against its own 0-byte assertion — which is how the argument/command
  # distinction got found instead of assumed.
  sh -c "$BODY" >/dev/null 2>&1
)
if [ -f "$REPRO/Supersedes" ] && [ -f "$REPRO/DEFER" ] \
   && [ ! -s "$REPRO/Supersedes" ] && [ ! -s "$REPRO/DEFER" ]; then
    ok "two blockquote lines in COMMAND position produced two 0-byte files"
else
    bad "could not reproduce the mechanism — the audit comment's provenance claim is unverified"
fi

# ---------------------------------------------------------------------------
# Lift the REAL check out of the REAL audit. Anchored on its marker comment and the
# first column-0 `fi`; inner `fi`s are indented, so they do not terminate the match.
extract() {
    python3 - "$SRC" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r"\n# T-651: zero-byte untracked files at the repo ROOT.*?\nfi\n", src, re.S)
if not m:
    sys.stderr.write("COULD-NOT-MEASURE: T-651 check not found in audit.sh\n"); sys.exit(3)
sys.stdout.write(m.group(0))
PY
}
CHK="$TMP/check.sh"
extract > "$CHK" || exit 3
[ -s "$CHK" ] || { echo "COULD-NOT-MEASURE: extracted check was empty" >&2; exit 3; }

REPO="$TMP/repo"
mkdir -p "$REPO/sub"
git -C "$REPO" init -q 2>/dev/null
git -C "$REPO" config user.email t651@example.invalid
git -C "$REPO" config user.name  t651
: > "$REPO/tracked-empty"                 # a legitimate .gitkeep analogue
printf 'x\n' > "$REPO/sub/real.txt"
git -C "$REPO" add -A >/dev/null 2>&1
git -C "$REPO" commit -qm baseline >/dev/null 2>&1

# run the check against $REPO with pass/warn/fail stubbed -> prints "PASS" or "WARN <evidence>"
run_check() {
    local body="${1:-$CHK}"
    ( set +u
      PROJECT_ROOT="$REPO"
      pass() { echo "PASS"; }
      warn() { echo "WARN $1 :: $2"; }
      fail() { echo "FAIL $1"; }
      . "$body" )
}

echo "--- 2. clean root"
[ "$(run_check | head -1)" = "PASS" ] \
    && ok "clean root: PASS" \
    || bad "clean root did not pass: $(run_check | head -2 | tr '\n' ' ')"

echo "--- 3. a 0-byte untracked root file is caught and named"
: > "$REPO/Supersedes"
OUT=$(run_check)
if echo "$OUT" | grep -q '^WARN' && echo "$OUT" | grep -q 'Supersedes'; then
    ok "caught and named it"
else
    bad "not caught: $(echo "$OUT" | head -2 | tr '\n' ' ')"
fi

echo "--- 4. controls: what must NOT trip it"
printf 'PNG\n' > "$REPO/screenshot.png"     # untracked but real content
: > "$REPO/sub/nested-empty"                # untracked, empty, but NOT at root
OUT=$(run_check)
MISFIRE=""
echo "$OUT" | grep -q 'screenshot.png'  && MISFIRE="$MISFIRE non-empty-file"
echo "$OUT" | grep -q 'nested-empty'    && MISFIRE="$MISFIRE nested-file"
echo "$OUT" | grep -q 'tracked-empty'   && MISFIRE="$MISFIRE tracked-empty-file"
if [ -z "$MISFIRE" ]; then
    ok "ignores non-empty, nested, and tracked-empty files"
else
    bad "false positive on:$MISFIRE"
fi

# ---------------------------------------------------------------------------
echo "--- 5. teeth: drop the size test and the non-empty control must start firing"
MUT="$TMP/mutant.sh"
sed 's/\[ ! -s "\$PROJECT_ROOT\/\$_f" \] && //' "$CHK" > "$MUT"
if ! bash -n "$MUT" 2>/dev/null; then
    bad "MUTATION FAILED — mutant does not parse; proves nothing"
elif diff -q "$CHK" "$MUT" >/dev/null; then
    bad "MUTATION FAILED — size test not found to remove; the leg above is untested"
else
    MOUT=$(run_check "$MUT")
    if echo "$MOUT" | grep -q 'screenshot.png'; then
        ok "without the size test the screenshot IS flagged — the discriminator is load-bearing"
    else
        bad "mutant still ignores the screenshot — leg 4 cannot fail and proves nothing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
