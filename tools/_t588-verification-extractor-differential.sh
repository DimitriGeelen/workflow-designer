#!/usr/bin/env bash
# T-588 — RETIRED (T-1045, 2026-10-05). The differential's question is answered: upstream FIXED it.
#
# WHAT IT ASKED. Upstream's ## Verification extractor was `sed -n '/^## Verification/,/^## /p' |
# sed '$d'` with three defects: (1) a last-section block lost its final leg to `$d`; (2) the sed range
# RESTARTED, so a later, superseded block ran too; (3) a prefix match let `## Verification Notes`
# hand prose to the eval loop and skip the real block. This tool compared that line with OUR
# extractor in update-task.sh, and exited 1 when "a differential changed — upstream may have FIXED it".
#
# WHY RETIRED. Both premises are gone as of the 1.7.740 drop (pristine commit 2659abad):
#   - upstream's lib/verification-port.sh now extracts with an anchored awk that opens only at the
#     FIRST exact `## Verification` heading (its own comment at :177 names the old sed form's defects);
#   - OUR side no longer lives in update-task.sh: the gate calls that same port function, with our
#     T-943 divergence (rc 3 on a heading-shaped line that is not exact) on top.
# So the tool could only abort ("expected exactly 1 line matching our anchored heading locator …
# found 0") — and it aborted SILENTLY, because abort() ran inside a $(…) and its message was
# captured. Its teeth therefore abstained (rc 2) in the _t509 sweep: T-1045.
#
# SUCCESSORS, which test the LIVE extractor directly rather than diffing two copies:
#   tools/_t943-heading-states.sh       defect 3 (prefix/suffix headings), defect 2 (superseded and
#                                       duplicate headings below the real one — added by T-1045, with
#                                       a restart-on-match mutant shown red), the absent/malformed split
#   tools/_t574-p011-block-locator-teeth.py   the gate-level behaviour incl. defect 1 ("trailing":
#                                       Verification as the final section) and the prefix shape, with mutants
# This file delegates to both; a missing or failing successor is a failure here.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rc=0
for s in tools/_t943-heading-states.sh tools/_t574-p011-block-locator-teeth.py; do
  if [ ! -f "$ROOT/$s" ]; then
    echo "FAIL: successor $s is missing — T-588 is retired in its favour, so nothing guards the extractor" >&2
    rc=1; continue
  fi
  case "$s" in *.py) timeout 600 python3 "$ROOT/$s" >/dev/null 2>&1 ;; *) timeout 300 bash "$ROOT/$s" >/dev/null 2>&1 ;; esac
  r=$?
  if [ "$r" -ne 0 ]; then echo "FAIL: successor $s exited $r (run it directly to see why)" >&2; rc=1
  else echo "ok    successor $s"; fi
done
[ "$rc" -eq 0 ] && echo "=== T-588 retired: both successors PASS ==="
exit "$rc"
