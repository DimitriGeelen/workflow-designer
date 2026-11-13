#!/usr/bin/env bash
# _t1405-red-log-teeth.sh — T-1405: the pre-push gate keeps each red core run's log, newest five, and names it.
# Runs the real tools/_t1288-prepush-gate.sh in a scratch repo whose suite is a stub: seven red runs, then one green.
#   1  each red refusal names "kept as .context/working/prepush-core-red-<UTC>.log"
#   2  after seven red runs exactly five kept logs remain (the oldest pruned)
#   3  the kept logs are git-ignored (the *.log rule in .context/working/.gitignore)
#   4  a green run leaves the kept red logs alone
# Exit 0 all hold; 1 one does not; 2 setup broken.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S=$(mktemp -d "${TMPDIR:-/tmp}/t1405.XXXXXX") || exit 2
trap 'rm -rf "$S"' EXIT
pass=0; fail=0
leg() { if [ "$1" = 0 ]; then pass=$((pass + 1)); echo "  PASS  $2"; else fail=$((fail + 1)); echo "  FAIL  $2"; fi; }
cd "$S" || exit 2
git init -q && mkdir -p tools tests .context/working || exit 2
cp "${T1405_GATE:-$ROOT/tools/_t1288-prepush-gate.sh}" tools/_t1288-prepush-gate.sh || exit 2   # T1405_GATE: control runs
cp "$ROOT/.context/working/.gitignore" .context/working/.gitignore 2>/dev/null || printf '*.log\n' > .context/working/.gitignore
printf '#!/bin/bash\necho "tier core    RED: 1 passed, 1 failed"\necho "  [FAIL] stub leg"\nexit 1\n' > tests/run-bridge-tests.sh
git add -A && git -c user.name=t -c user.email=t@invalid commit -qm init || exit 2
named=0
for _ in 1 2 3 4 5 6 7; do
    out=$(bash tools/_t1288-prepush-gate.sh 2>&1)
    printf '%s\n' "$out" | grep -q "kept as .context/working/prepush-core-red-" || named=1
    sleep 1.1   # the kept name carries the second; one red run per second
done
leg "$named" "every red refusal names its kept log"
n=$(ls .context/working/prepush-core-red-*.log 2>/dev/null | wc -l)
[ "$n" -eq 5 ]; leg $? "seven red runs keep exactly the newest five (kept: $n)"
ign=$(git status --short --ignored .context/working | grep -c '^!! .context/working/prepush-core-red-')
[ "$ign" -eq 5 ]; leg $? "the kept logs are git-ignored ($ign of 5)"
printf '#!/bin/bash\necho "tier core    GREEN: 2 passed, 0 failed"\nexit 0\n' > tests/run-bridge-tests.sh
git -c user.name=t -c user.email=t@invalid commit -qam green
bash tools/_t1288-prepush-gate.sh >/dev/null 2>&1
n2=$(ls .context/working/prepush-core-red-*.log 2>/dev/null | wc -l)
[ "$n2" -eq 5 ]; leg $? "a green run leaves the kept red logs alone (kept: $n2)"
echo "=== $pass passed, $fail failed ==="
[ "$fail" -eq 0 ]
