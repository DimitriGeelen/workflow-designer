#!/usr/bin/env bash
# T-345 — RETIRED (T-1221). Superseded by leg 8 of tools/_t344-watch-set-denominator.sh.
#
# WHAT THIS PROTECTED. audit.sh asked the same fabric-coverage question twice, and before T-345 the two
# answers differed by 49 in one run; the one that read as reassurance was the broken one. This harness
# extracted both checks at runtime, required them to return the same unregistered count over a non-empty
# population, and reverted each glob fix to show the counts then diverge.
#
# WHY RETIRED. There is no second check any more. AEF T-2735 (vendored with 1.7.68, 7b5e227e) moved the
# coverage verdict into the drift block of check_fabric_coverage, and the first block now only counts
# cards and orphans (audit.sh ~2665-2673: "Coverage verdict belongs to the drift check below (T-2735)").
# Both of this file's extractions matched nothing from 1.7.68 on, so it could only report "it moved".
# The property that outlives it (the audit's one coverage count agrees with an independent count over a
# non-empty watch set) is leg 8 of _t344, whose teeth are tools/_t550-audit-parse-anchor-teeth.py.
# Decision recorded on T-345 (2026-10-19).
#
# SO THE FILE CANNOT SILENTLY ASSERT NOTHING: it delegates. It exits 0 only if the successor exists AND
# passes; a missing or failing successor is a failure here too.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUCCESSOR="$REPO/tools/_t344-watch-set-denominator.sh"

echo "T-345 — RETIRED (T-1221): the two-check agreement is now _t344 leg 8 (audit vs independent count)"
if [ ! -f "$SUCCESSOR" ]; then
  echo "  FAIL  successor $SUCCESSOR is missing — nothing measures this property now"
  exit 1
fi
out=$(bash "$SUCCESSOR" 2>&1); rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q 'coverage checks agree:'; then
  echo "  PASS  successor passes and its leg 8 reports agreement"
  exit 0
fi
echo "  FAIL  successor exit $rc, or its leg 8 did not report agreement:"
printf '%s\n' "$out" | tail -5 | sed 's/^/        /'
exit 1
