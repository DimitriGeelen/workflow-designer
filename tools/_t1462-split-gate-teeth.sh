#!/usr/bin/env bash
# _t1462-split-gate-teeth.sh — T-1462: the browser gate's pool half runs as two shards in parallel, with the unsplit run
# as a non-gating shadow. Runs the real tools/pool/tier-gate.sh in a scratch repo; the pool is a stub
# (T1408_POOL_SUBMIT) that writes the last-result files and per-leg logs a real job would, and the local tier is a
# green stub.
#   1  both shards green -> the gate is green; each shard has its own result file; the shadow runs and compares clean
#   2  one shard red -> the gate refuses
#   3  a shard gives no result -> the gate waits for the unsplit shadow and takes its verdict
#   4  the shadow's legs differ from the shards' -> a DIFFER marker, and the NEXT gate refuses until it is removed
#   5  T1462_SPLIT=0 -> one unsplit job, no shards
# Exit 0 all hold; 1 one does not; 2 setup broken.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S=$(mktemp -d "${TMPDIR:-/tmp}/t1462.XXXXXX") || exit 2
trap '[ -n "${T1462_KEEP:-}" ] && echo "KEPT $S" || rm -rf "$S"' EXIT   # T1462_KEEP=1: keep the scratch repo to read
pass=0; fail=0
leg() { if [ "$1" = 0 ]; then pass=$((pass + 1)); echo "  PASS  $2"; else fail=$((fail + 1)); echo "  FAIL  $2"; fi; }
cd "$S" || exit 2
git init -q && mkdir -p tools/pool tests docs/reports/T-1452-spikes build/pool || exit 2
cp "${T1462_TIERGATE:-$ROOT/tools/pool/tier-gate.sh}" tools/pool/tier-gate.sh || exit 2   # T1462_TIERGATE: control runs
cp "$ROOT/tools/pool/high-risk.re" tools/pool/ 2>/dev/null
cp "$ROOT/tools/pool/shard-coverage.py" tools/pool/ 2>/dev/null   # T-1480: the gate checks the shards' legs cover the tier
printf 'L1\nL2\nL3\nL4\nL5\nL6\n' > "$S/expected-legs"; export T1480_EXPECTED="$S/expected-legs"   # the stub's six legs
cp "$ROOT/docs/reports/T-1452-spikes/compare-shards.py" docs/reports/T-1452-spikes/ || exit 2
cp "$ROOT/tests/shard-plan-browser-2.tsv" "$ROOT/tests/shard-plan-browser-3.tsv" tests/ || exit 2
printf '#!/bin/bash\ntouch "$(git rev-parse --show-toplevel)/local-ran"\necho "tier browser GREEN: 6 passed, 0 failed"\nexit 0\n' > tests/run-bridge-tests.sh
git -C "$ROOT" show HEAD:.gitignore > .gitignore 2>/dev/null
# The stub pool: STUB_RC_1 / STUB_RC_2 / STUB_RC_W are the shards' and the whole run's exit codes ('none': no result);
# STUB_W_FAILS names a leg the whole run fails while the shards pass it (a disagreement).
cat > stub-submit.sh <<'STUB'
#!/bin/bash
TIER=$1; ROOT=$(git rev-parse --show-toplevel); HEAD=$(git rev-parse HEAD)
echo "${SHARD:-whole}|${POOL_NODE:-}" >> "$ROOT/stub-nodes.log"   # T-1467: where each job was pinned
if [ -n "${SHARD:-}" ]; then i=${SHARD%/*}; k=${SHARD#*/}; rc_var="STUB_RC_$i"; rc=${!rc_var:-0}; suf="-shard${i}of$k"
     legs=$(for n in 1 2 3 4 5 6; do [ $(( (n - 1) % k + 1 )) = "$i" ] && printf 'L%s ' "$n"; done); sleep 1
else rc=${STUB_RC_W:-0}; suf=""; legs="L1 L2 L3 L4 L5 L6"; sleep 3; fi
name="stub-$TIER$suf-$$"; last="$ROOT/build/pool/last-$TIER$suf.result"; rm -f "$last"
[ "$rc" = none ] && { echo "POOL REFUSED on stub: no capable node"; exit 1; }
d="$ROOT/build/pool/results/$name"; mkdir -p "$d"
echo "{\"commit\": \"$HEAD\", \"node\": \"stub\", \"duration_s\": 1, \"exit_code\": $rc}" > "$d/result.json"
for l in $legs; do f=0; [ -z "$suf" ] && [ "$l" = "${STUB_W_FAILS:-}" ] && f=1; printf '%s\t%s\tfirst\t%s\t%s\t1\n' "$TIER" "$l" $((1 - f)) "$f" >> "$d/legs.tsv"; done
printf 'name=%s\ncommit=%s\nexit_code=%s\nnode=stub\nresult_line=tier %s stub rc %s\ntier_log=%s\nerror=\n' "$name" "$HEAD" "$rc" "$TIER" "$rc" "$d/tier.log" > "$last"
exit "$rc"
STUB
export T1408_POOL_SUBMIT="bash $S/stub-submit.sh"
git add -A && git -c user.name=t -c user.email=t@invalid commit -qm init || exit 2
export PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH"   # the gate's local browser run needs a Node with WebSocket
gate() { bash tools/pool/tier-gate.sh browser > "$S/gate.out" 2>&1; echo $?; }
shadow_done() { local t=0; while [ "$(ls build/tiergate/split-shadow/*.compare 2>/dev/null | wc -l)" -lt "$1" ] && [ $t -lt 60 ]; do sleep 1; t=$((t + 1)); done; }

# 1
rc=$(STUB_RC_1=0 STUB_RC_2=0 gate)
[ "$rc" = 0 ] && grep -q '2 shards in parallel' gate.out; leg $? "both shards green: the gate is green and says it ran 2 shards (rc $rc)"
[ -f build/pool/last-browser-shard1of2.result ] && [ -f build/pool/last-browser-shard2of2.result ]; leg $? "each shard has its own result file"
shadow_done 1
c=$(ls build/tiergate/split-shadow/*.compare 2>/dev/null | head -1)
[ -n "$c" ] && grep -q '^PASS  C3' "$c" && ! ls build/tiergate/split-shadow/DIFFER-* >/dev/null 2>&1; leg $? "the unsplit shadow ran and compared clean (C3 pass, no DIFFER marker)"
# 2
rc=$(STUB_RC_1=0 STUB_RC_2=1 gate); shadow_done 2
[ "$rc" = 1 ] && grep -q 'shard 2/2' gate.out; leg $? "one shard red: the gate refuses and names the shard (rc $rc)"
# 3
rc=$(STUB_RC_1=none STUB_RC_2=0 STUB_RC_W=0 gate); shadow_done 3
[ "$rc" = 0 ] && grep -q 'waiting for the unsplit run' gate.out; leg $? "a shard gave no result: the gate waited for the unsplit run and took its green (rc $rc)"
# 4
rc=$(STUB_RC_1=0 STUB_RC_2=0 STUB_W_FAILS=L3 gate); shadow_done 4
ls build/tiergate/split-shadow/DIFFER-* >/dev/null 2>&1; leg $? "the shadow failed a leg the shards passed: a DIFFER marker is left"
rc=$(STUB_RC_1=0 STUB_RC_2=0 gate)
[ "$rc" = 1 ] && grep -q 'disagreed with its unsplit shadow' gate.out; leg $? "the next gate refuses until the marker is removed (rc $rc)"
rm -f build/tiergate/split-shadow/DIFFER-*
# 5
rm -f build/pool/last-browser-shard*.result
rc=$(T1462_SPLIT=0 STUB_RC_W=0 gate)
[ "$rc" = 0 ] && ! grep -q '2 shards' gate.out && [ ! -f build/pool/last-browser-shard1of2.result ]; leg $? "T1462_SPLIT=0: one unsplit job, no shards (rc $rc)"
# 6 (T-1467) k = 3 from tools/pool/workers, each shard pinned to its node, the shadow to the shadow node
printf 'browser_shards=3\nshard_nodes="w-a w-b w-a"\nshadow_node=w-slow\n' > tools/pool/workers
git add -A && git -c user.name=t -c user.email=t@invalid commit -qm workers
rm -f stub-nodes.log
rc=$(STUB_RC_1=0 STUB_RC_2=0 STUB_RC_3=0 gate); shadow_done 5
c=$(ls -t build/tiergate/split-shadow/*.compare 2>/dev/null | head -1)
[ "$rc" = 0 ] && grep -q '3 shards in parallel' gate.out && [ -f build/pool/last-browser-shard3of3.result ] && grep -q '^PASS  C1' "$c"
leg $? "k = 3 from tools/pool/workers: 3 shards, all green, the shadow compares all three (rc $rc)"
grep -qx '1/3|w-a' stub-nodes.log && grep -qx '2/3|w-b' stub-nodes.log && grep -qx '3/3|w-a' stub-nodes.log && grep -qx 'whole|w-slow' stub-nodes.log
leg $? "each shard went to its configured node, the shadow to the shadow node ($(tr '\n' ' ' < stub-nodes.log))"
# 7 (T-1467) T1467_POOL_ONLY=1: a high-risk change on the pool alone, no local run
rm -f local-ran
rc=$(T1467_POOL_ONLY=1 STUB_RC_1=0 STUB_RC_2=0 STUB_RC_3=0 gate); shadow_done 6
[ "$rc" = 0 ] && [ ! -f local-ran ] && grep -q 'pool only: green' build/tiergate/tier-browser.runs.log
leg $? "T1467_POOL_ONLY=1: green on the pool alone, the local tier never started (rc $rc)"
rc=$(T1467_POOL_ONLY=1 STUB_RC_1=0 STUB_RC_2=1 STUB_RC_3=0 gate); shadow_done 7
[ "$rc" = 1 ] && [ ! -f local-ran ]; leg $? "T1467_POOL_ONLY=1 with a red shard: refused, still no local run (rc $rc)"
# 8 (T-1481) core: unsplit on the pool with no core_shards line; split and pinned from core_shards / core_shard_nodes
cp "$ROOT/tests/shard-plan-core-2.tsv" tests/ && git add -A && git -c user.name=t -c user.email=t@invalid commit -qm coreplan
rm -f stub-nodes.log build/pool/last-core*.result
rc=$(T1467_POOL_ONLY=1 STUB_RC_W=0 bash tools/pool/tier-gate.sh core > "$S/gate.out" 2>&1; echo $?)
[ "$rc" = 0 ] && grep -qx 'whole|' stub-nodes.log && [ "$(wc -l < stub-nodes.log)" = 1 ]
leg $? "core with no core_shards line: one unsplit pool job, as before (rc $rc; $(tr '\n' ' ' < stub-nodes.log))"
printf 'core_shards=2\ncore_shard_nodes="w-s1 w-s2"\n' >> tools/pool/workers
git add -A && git -c user.name=t -c user.email=t@invalid commit -qm coreworkers
rm -f stub-nodes.log; n0=$(ls build/tiergate/split-shadow/*.compare 2>/dev/null | wc -l)
rc=$(T1467_POOL_ONLY=1 STUB_RC_1=0 STUB_RC_2=0 STUB_RC_W=0 bash tools/pool/tier-gate.sh core > "$S/gate.out" 2>&1; echo $?); shadow_done $((n0 + 1))
c=$(ls -t build/tiergate/split-shadow/core-*.compare 2>/dev/null | head -1)
[ "$rc" = 0 ] && grep -q 'core tier on ring20.s POOL as 2 shards' gate.out && grep -q 'shard-coverage: ok' gate.out \
  && grep -qx '1/2|w-s1' stub-nodes.log && grep -qx '2/2|w-s2' stub-nodes.log && grep -qx 'whole|' stub-nodes.log && [ -n "$c" ] && grep -q '^PASS  C1' "$c"
leg $? "core_shards=2: 2 shards pinned to the core nodes, coverage ok, the core shadow compares clean (rc $rc; $(tr '\n' ' ' < stub-nodes.log))"
echo "=== $pass passed, $fail failed ==="
[ "$fail" -eq 0 ]
