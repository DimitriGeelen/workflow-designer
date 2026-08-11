#!/bin/bash
# T-396 — does release-designer.sh report the TAG as a release output?
#
# 0.9.0 was cut, announced, pushed and left untagged, because the script reported
# two of the three things a cut produces. This asserts the third is now reported,
# in BOTH directions — a message that only ever says "NOT YET TAGGED" would pass a
# one-sided test while being useless.
#
# Runs entirely in throwaway clones. The live dist/ and the live VERSION are never
# touched, and no rail announcement is emitted (RELEASE_SKIP_ANNOUNCE=1).
#
# Exit: 0 both branches as expected | 1 a branch disagreed | 3 could not measure

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO/VERSION")"
TAG="designer-v$VERSION"
SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/t396-XXXXXX")
trap 'rm -rf "$SCRATCH"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n     %s\n' "$1" "$2"; }

echo "=== T-396 release tag-state probe (VERSION=$VERSION, tag=$TAG) ==="
echo

# --- anti-vacuity: the live repo must actually HAVE the tag ------------------
# Branch A below asserts "reports TAGGED". If the tag were absent from source,
# the clone would lack it too and branch A would fail for a reason that says
# nothing about the script. Establish the precondition before relying on it.
if ! git -C "$REPO" rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>&1; then
    echo "  CANNOT MEASURE: $TAG does not exist in $REPO, so the TAGGED branch"
    echo "  has no fixture. That is itself the T-395 condition, not a probe result."
    exit 3
fi

# Sets OUT and RC in the CALLER's scope. Never via OUT=$(run_release ...):
# command substitution forks a subshell and an RC assigned inside it never
# reaches the parent (T-391, where exactly that went unnoticed).
#
# `git clone` copies COMMITTED state, so a clone-based probe silently tests the
# last commit rather than the change under test. First run of this probe did
# exactly that: both branches reported the pre-change final line and four legs
# went red for a reason that had nothing to do with either branch. Overlay the
# working-tree script so the probe measures what is actually being changed —
# same family as [[rehearsed-in-the-wrong-shell]]: the fixture was a different
# artifact than the one under test.
run_release() { # <clone-dir>
    cp "$REPO/scripts/release-designer.sh" "$1/scripts/release-designer.sh"
    ( cd "$1" && RELEASE_SKIP_ANNOUNCE=1 bash scripts/release-designer.sh ) \
        > "$SCRATCH/out.txt" 2>&1
    RC=$?
    OUT=$(cat "$SCRATCH/out.txt")
}

# --- branch A: tag PRESENT ---------------------------------------------------
echo "-- branch A: tag exists -> must report TAGGED --"
git clone --quiet "$REPO" "$SCRATCH/with-tag" 2>/dev/null || { echo "  CANNOT MEASURE: clone failed"; exit 3; }
run_release "$SCRATCH/with-tag"
if echo "$OUT" | grep -q "^Release $VERSION: CUT but NOT ANNOUNCED — TAGGED$"; then
    ok "final line reports TAGGED"
else
    bad "final line reports TAGGED" "got: $(echo "$OUT" | tail -1)"
fi
if echo "$OUT" | grep -q "WARNING: release $VERSION is NOT TAGGED"; then
    bad "no false NOT-TAGGED warning when the tag exists" "warning fired anyway"
else
    ok "no false NOT-TAGGED warning when the tag exists"
fi

# --- branch B: tag ABSENT ----------------------------------------------------
# --no-tags gives a clone with the same commits and no refs/tags, which is the
# real shape of a fresh cut: the artifact is built, the tag does not exist yet.
echo
echo "-- branch B: tag absent -> must report NOT YET TAGGED and name the command --"
git clone --quiet --no-tags "$REPO" "$SCRATCH/no-tag" 2>/dev/null || { echo "  CANNOT MEASURE: clone failed"; exit 3; }
if git -C "$SCRATCH/no-tag" tag -l | grep -q .; then
    echo "  CANNOT MEASURE: --no-tags clone still carries tags; branch B has no fixture"
    exit 3
fi
run_release "$SCRATCH/no-tag"
if echo "$OUT" | grep -q "^Release $VERSION: CUT but NOT ANNOUNCED — NOT YET TAGGED$"; then
    ok "final line reports NOT YET TAGGED"
else
    bad "final line reports NOT YET TAGGED" "got: $(echo "$OUT" | tail -1)"
fi
echo "$OUT" | grep -q "WARNING: release $VERSION is NOT TAGGED" \
    && ok "loud warning names the missing tag" \
    || bad "loud warning names the missing tag" "absent"
# The remedy must be copy-pasteable and complete: cd, tag, push (CLAUDE.md §T-609).
echo "$OUT" | grep -q "git tag -a $TAG .*&& git push origin $TAG" \
    && ok "remedy is a single copy-pasteable line incl. cd and push" \
    || bad "remedy line" "not found or incomplete"
# The ordering trap is the whole reason the script cannot self-tag.
echo "$OUT" | grep -q "commit first, then tag HEAD" \
    && ok "states the tag must follow the release commit" \
    || bad "ordering caveat" "absent"

# --- the substrings other tooling greps must survive -------------------------
echo
echo "-- backward compatibility (T-389 greps the script source) --"
grep -q "CUT but NOT ANNOUNCED" "$REPO/scripts/release-designer.sh" \
    && ok "'CUT but NOT ANNOUNCED' still present in script source" \
    || bad "'CUT but NOT ANNOUNCED' present" "removed — T-389 verification would break"
grep -q "CUT and ANNOUNCED" "$REPO/scripts/release-designer.sh" \
    && ok "'CUT and ANNOUNCED' still present in script source" \
    || bad "'CUT and ANNOUNCED' present" "removed"

# --- idempotence: the probe must not have changed the artifact ---------------
echo
echo "-- idempotence (T-387): re-running must not alter dist/ --"
if git -C "$SCRATCH/with-tag" diff --quiet -- dist/ 2>/dev/null; then
    ok "dist/ byte-unchanged after a re-run at the same VERSION"
else
    bad "dist/ unchanged on re-run" "re-run mutated dist/ — breaks the T-387 guarantee"
fi

echo
echo "=== summary: $PASS as expected, $FAIL disagreeing ==="

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${PASS:-0} + ${FAIL:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi

[ "$FAIL" -eq 0 ] || exit 1
exit 0
