#!/usr/bin/env bash
# T-370: prove the pinned ref AEF is asked to vendor resolves, on ORIGIN, to exactly
# the bytes we published on the rail.
#
# Why the expectations are hard-coded literals rather than re-derived:
# normally that is the G-015 moving-global-in-a-gate defect. Here it is the point.
# `docs/standards/aef-bpmn-mapping-v1.md` Part I is FROZEN and must not be edited
# under agent control. A literal sha is therefore a guard in the correct direction:
# if these bytes ever change, this probe goes red, and that red is the finding.
# Re-deriving the expectation from the subject would pass over an edit silently.
#
# Reads only. Touches nothing. Exit 0 = the ref is deliverable as published.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 2

P="docs/standards/aef-bpmn-mapping-v1.md"
PIN_COMMIT="4a1a30e115faae79d0e8fa95a05858903e0ac550"   # last commit touching $P (T-204)
EXP_BLOB="6b256a34198b8278fb5062719151bf2aa4510254"
EXP_SHA_FULL="fbada7b3907f928e40bd6cafb32803f94e606fcb84ab2b357476793ba11288bb"
EXP_BYTES_FULL=10790
EXP_SHA_PART1="970dd530258b1cde1682a3ad9068808efbf3bb9a664b181499d8ee8328b9106f"
EXP_BYTES_PART1=7905
PART1_FIRST_LINE=30
PART1_LAST_LINE=145

FAIL=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=1; }

# The comparator under test. Returns 0 only when the bytes on stdin hash to $2.
# Every positive check below routes through this, so control (c) proving it can
# return non-zero is what makes the passes evidence rather than decoration.
sha_is() { local want="$1"; local got; got="$(sha256sum | cut -d' ' -f1)"; [ "$got" = "$want" ]; }

echo "== T-370 pinned-ref probe =="
echo "path       $P"
echo "pin        $PIN_COMMIT"
echo

# ---- 0. the ref must resolve on ORIGIN, not merely in the local clone ----------
echo "[0] origin reachability + ref resolution"
if git fetch origin master --quiet 2>/dev/null; then
  pass "git fetch origin master"
else
  fail "git fetch origin master — cannot confirm what the peer would receive"
fi
if git cat-file -e "origin/master:$P" 2>/dev/null; then
  pass "origin/master:$P resolves"
else
  fail "origin/master:$P does not resolve on origin"
fi

# ---- 1. the pinned commit and origin/master must carry the SAME blob ----------
# git's blob id is content-addressed, so equality here is proof of identical bytes
# that does not depend on our own hashing being right.
echo "[1] blob identity"
B_PIN="$(git rev-parse "$PIN_COMMIT:$P" 2>/dev/null || echo MISSING)"
B_ORI="$(git rev-parse "origin/master:$P" 2>/dev/null || echo MISSING)"
[ "$B_PIN" = "$EXP_BLOB" ] && pass "pinned commit blob == published blob ($EXP_BLOB)" \
                           || fail "pinned commit blob $B_PIN != $EXP_BLOB"
[ "$B_ORI" = "$EXP_BLOB" ] && pass "origin/master blob == published blob" \
                           || fail "origin/master blob $B_ORI != $EXP_BLOB — the standard moved"

# ---- 2. whole-file bytes as served from origin --------------------------------
echo "[2] whole file, read from origin"
N="$(git cat-file blob "origin/master:$P" | wc -c)"
[ "$N" -eq "$EXP_BYTES_FULL" ] && pass "bytes = $EXP_BYTES_FULL" || fail "bytes = $N, expected $EXP_BYTES_FULL"
if git cat-file blob "origin/master:$P" | sha_is "$EXP_SHA_FULL"; then
  pass "sha256 = $EXP_SHA_FULL"
else
  fail "sha256 mismatch against published value"
fi

# ---- 3. the frozen half, pinnable independently of the provisional half -------
echo "[3] Part I (lines $PART1_FIRST_LINE-$PART1_LAST_LINE)"
# Materialise once. Do NOT pipe the extraction into `head`/`grep -q`: those exit
# early, the upstream `git cat-file` takes a SIGPIPE (141), and `pipefail` then
# promotes 141 over grep's successful match. That produced a RED on a correct
# document on this probe's first run — a failure in the direction that sends you
# to debug working bytes. Same pipefail class already measured here under P-011.
PART1_TMP="$(mktemp)"; trap 'rm -f "$PART1_TMP"' EXIT
git cat-file blob "origin/master:$P" | sed -n "${PART1_FIRST_LINE},${PART1_LAST_LINE}p" > "$PART1_TMP"

N1="$(wc -c < "$PART1_TMP")"
[ "$N1" -eq "$EXP_BYTES_PART1" ] && pass "bytes = $EXP_BYTES_PART1" || fail "bytes = $N1, expected $EXP_BYTES_PART1"
if sha_is "$EXP_SHA_PART1" < "$PART1_TMP"; then
  pass "sha256 = $EXP_SHA_PART1"
else
  fail "Part I sha256 mismatch"
fi
# the range must actually BE Part I, not an offset that happens to hash right
first_line="$(head -1 "$PART1_TMP")"; last_line="$(tail -1 "$PART1_TMP")"
case "$first_line" in
  '# Part I'*) pass "range starts at '# Part I'" ;;
  *)           fail "range starts at '${first_line:0:40}', not the Part I heading" ;;
esac
case "$last_line" in
  '# Part II'*) fail "range has run into Part II" ;;
  *)            pass "range stops before Part II" ;;
esac
if grep -q '^## 6\. Conformance requirements' "$PART1_TMP"; then
  pass "§6 (their §6.3 question) is inside the delivered range"
else
  fail "§6 missing from Part I range — wrong bytes for the question they asked"
fi

# ---- 4. negative controls -----------------------------------------------------
# Without these the section above is a fetch that cannot fail informatively.
echo "[4] negative controls"

# (a) wrong path at the same commit must NOT resolve
if git cat-file -e "origin/master:docs/standards/does-not-exist.md" 2>/dev/null; then
  fail "(a) a nonexistent path resolved — the ref is not path-specific"
else
  pass "(a) wrong path does not resolve"
fi

# (b) a revision from before the file existed must NOT resolve.
# Chosen mechanically: the root commit.
ROOT="$(git rev-list --max-parents=0 HEAD | tail -1)"
if git cat-file -e "$ROOT:$P" 2>/dev/null; then
  fail "(b) path resolved at the root commit — ref is not revision-pinned"
else
  pass "(b) wrong revision ($(echo "$ROOT" | cut -c1-8)) does not resolve"
fi

# (c) the comparator must be able to say NO.
# This is the one that matters: every PASS above is produced by sha_is, and a
# comparator that returned 0 unconditionally would have produced all of them.
if printf 'not the standard' | sha_is "$EXP_SHA_FULL"; then
  fail "(c) comparator accepted wrong bytes — every check above is meaningless"
else
  pass "(c) comparator rejects wrong bytes"
fi

# (d) and it must accept the right ones when handed them directly, so (c) is not
# passing merely because sha_is is broken in the always-reject direction.
if git cat-file blob "origin/master:$P" | sha_is "$EXP_SHA_FULL"; then
  pass "(d) comparator accepts correct bytes — it discriminates in both directions"
else
  fail "(d) comparator rejected correct bytes"
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: PASS — ref is deliverable exactly as published on the rail."
else
  echo "RESULT: FAIL — do not quote this ref until resolved."
fi
exit "$FAIL"
