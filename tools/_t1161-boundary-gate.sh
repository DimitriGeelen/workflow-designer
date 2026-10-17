#!/bin/bash
# _t1161-boundary-gate.sh — pre-commit gate for the editor's authority inventory (832 T-1161, OBS-455).
#
# tools/_t682-boundary-inventory.py proves docs/reports/T-682-arc-2-boundary-inventory.md matches the routes of
# tools/gallery-serve.py and that its evidence citations still point at their text (T-1162). It ran on a schedule
# and in the bridge suite only, so a commit could change the server and leave the report behind. This runs it at
# commit time, ONLY when one of the two files is staged, and on the STAGED bytes of both (a fixed working tree
# with a stale staged copy must not pass). Any other commit returns at once.
#
# Wired as one marked line in .git/hooks/pre-commit by tools/_t1161-install-hook.sh.
# Exit 0 = pass or not relevant; 1 = blocked.
set -u
ROOT=$(git rev-parse --show-toplevel) || exit 0
SERVER=tools/gallery-serve.py
REPORT=docs/reports/T-682-arc-2-boundary-inventory.md
staged=$(git diff --cached --name-only --diff-filter=ACMR)
printf '%s\n' "$staged" | grep -qxF -e "$SERVER" -e "$REPORT" || exit 0

T=$(mktemp -d "${TMPDIR:-/tmp}/t1161-gate-XXXXXX") || exit 1
trap 'rm -rf "$T"' EXIT
git show ":$SERVER" > "$T/server.py" 2>/dev/null || { echo "boundary gate: $SERVER is not in the index"; exit 1; }
git show ":$REPORT" > "$T/report.md" 2>/dev/null || { echo "boundary gate: $REPORT is not in the index"; exit 1; }

if python3 - "$ROOT/tools/_t682-boundary-inventory.py" "$T/server.py" "$T/report.md" > "$T/out" 2>&1 <<'PY'
import importlib.util, sys
tool, server, report = sys.argv[1:4]
spec = importlib.util.spec_from_file_location("t682", tool)
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
m.REPORT = report                       # the staged report, not the working tree's
sys.exit(m.check(server_src=open(server, encoding="utf-8").read()))
PY
then
    exit 0
fi
echo ""
echo "BLOCKED (832 T-1161): the staged boundary inventory does not match the staged editor server."
sed 's/^/  /' "$T/out"
echo ""
echo "Fix: python3 tools/_t682-boundary-inventory.py --write   (after adding any new route's semantics)"
echo "     then: git add $REPORT"
exit 1
