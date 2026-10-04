#!/bin/bash
# T-639 — RETIRED (T-1039). Superseded by tools/_t1005-drift-target-clause-scoped.py.
#
# WHAT THIS PROTECTED. The focus-drift gate must identify the task a command TARGETS,
# not every task-id-shaped string the command CONTAINS (quoted `git commit -m "…T-1:…"`
# arguments, heredoc bodies, prose mentioning other tasks).
#
# WHY RETIRED. The behavioural legs all pass on 1.7.740, but the teeth leg anchored on a
# function name the vendored framework no longer has, so it could only report
# COULD-NOT-MEASURE. The behaviour is now proven, with its own mutation discipline, by
# _t1005-drift-target-clause-scoped.py (18/18): it checks the target extractor clause by
# clause, including the mention-only fixtures this file used to carry.
#
# SO THE FILE CANNOT SILENTLY ASSERT NOTHING: it delegates. It exits 0 only if the
# successor exists AND passes; a missing or failing successor is a failure here too.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
SUCC="$PROJ/tools/_t1005-drift-target-clause-scoped.py"

if [ ! -f "$SUCC" ]; then
    echo "FAIL: successor $SUCC is missing — T-639 is retired in its favour, so nothing guards the drift gate" >&2
    exit 1
fi

echo "=== T-639 retired: delegating to $(basename "$SUCC") ==="
timeout 300 python3 "$SUCC"
rc=$?
if [ "$rc" -ne 0 ]; then
    echo "FAIL: successor exited $rc" >&2
    exit "$rc"
fi
echo "=== T-639 (via _t1005): PASS ==="
