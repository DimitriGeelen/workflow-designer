#!/usr/bin/env bash
# _t1408-pool-gate-teeth.sh — T-1408: the pre-push gate's choice of WHERE core runs, with stubbed pool and local runs.
# The real tools/_t1288-prepush-gate.sh in a scratch repo that has an upstream; tests/run-bridge-tests.sh is a stub (exit
# $STUB_LOCAL_RC, and it leaves a marker that it ran); the pool is a stub (T1408_POOL_SUBMIT) that writes
# build/pool/last-core.result for HEAD with exit_code $STUB_POOL_RC, or for another commit, or nothing.
#   1 normal push, pool green        -> pass, local NOT run, cache written
#   2 normal push, pool red          -> refused, cache not written
#   3 normal push, no pool result    -> local runs (green) -> pass, the fallback logged
#   4 pool result for another commit -> not counted -> local fallback
#   5 high-risk, pool + local green  -> pass, both ran
#   6 high-risk, pool green, local red -> refused as a DISAGREEMENT
#   7 T1408_POOL=0                    -> local only
# Control: T1408_GATE=<an older gate> must fail (case 1 runs local there). Exit 0 all hold; 1 one does not; 2 setup.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S=$(mktemp -d "${TMPDIR:-/tmp}/t1408.XXXXXX") || exit 2
trap 'rm -rf "$S"' EXIT
pass=0; fail=0
leg() { if [ "$1" = 0 ]; then pass=$((pass + 1)); echo "  PASS  $2"; else fail=$((fail + 1)); echo "  FAIL  $2"; fi; }
G() { git -c user.name=t -c user.email=t@invalid "$@"; }

git init -q --bare "$S/origin.git" || exit 2
W="$S/w"; git init -q -b main "$W" || exit 2
cd "$W" || exit 2
mkdir -p tools/pool tests docs .context/working build/pool
cp "${T1408_GATE:-$ROOT/tools/_t1288-prepush-gate.sh}" tools/_t1288-prepush-gate.sh || exit 2
git -C "$ROOT" show HEAD:.gitignore > .gitignore 2>/dev/null || exit 2
cat > tests/run-bridge-tests.sh <<'SH'
#!/bin/bash
touch "$(git rev-parse --show-toplevel)/.local-ran"
echo "tier core    $([ "${STUB_LOCAL_RC:-0}" = 0 ] && echo GREEN || echo RED): stub"
exit "${STUB_LOCAL_RC:-0}"
SH
cat > "$S/pool-stub.sh" <<'SH'
#!/bin/bash
# writes build/pool/last-core.result the way tools/pool/submit.sh does; STUB_POOL = green|red|none|othercommit
r="$(git rev-parse --show-toplevel)/build/pool/last-core.result"; rm -f "$r"
c=$(git rev-parse HEAD)
case "${STUB_POOL:-green}" in
  none) exit 1 ;;
  othercommit) c=0000000000000000000000000000000000000000; code=0 ;;
  green) code=0 ;;
  red) code=1 ;;
esac
printf 'name=stub\ncommit=%s\nexit_code=%s\nnode=stub-node\nresult_line=tier core    stub %s\ntier_log=/nonexistent\n' "$c" "$code" "${STUB_POOL:-green}" > "$r"
SH
echo x > docs/a.md
G add -A && G commit -qm init && git remote add origin "$S/origin.git" && G push -q -u origin main || exit 2
export T1408_POOL_SUBMIT="bash $S/pool-stub.sh"

run() {  # run <file-to-change> ; env STUB_POOL / STUB_LOCAL_RC / T1408_POOL set by caller
    echo "$RANDOM" >> "$1"; G add -A; G commit -qm "change $1"
    rm -f .local-ran .context/working/prepush-core.green
    OUT=$(bash tools/_t1288-prepush-gate.sh 2>&1); RC=$?
    LOCAL=$([ -f .local-ran ] && echo yes || echo no); CACHE=$([ -s .context/working/prepush-core.green ] && echo yes || echo no)
    G push -q origin main 2>/dev/null   # move the upstream on, so the next case's diff is its own
}

STUB_POOL=green STUB_LOCAL_RC=0 run docs/a.md
[ "$RC" = 0 ] && [ "$LOCAL" = no ] && [ "$CACHE" = yes ] && grep -q "normal push: pool green" <<<"$OUT"
leg $? "1 normal push, pool green: pass, local not run, cache written (rc=$RC local=$LOCAL cache=$CACHE)"

STUB_POOL=red STUB_LOCAL_RC=0 run docs/a.md
[ "$RC" = 1 ] && [ "$CACHE" = no ] && grep -q "pool core is red" <<<"$OUT"
leg $? "2 normal push, pool red: refused, no cache (rc=$RC cache=$CACHE)"

STUB_POOL=none STUB_LOCAL_RC=0 run docs/a.md
[ "$RC" = 0 ] && [ "$LOCAL" = yes ] && grep -q "falling back to the local run" <<<"$OUT"
leg $? "3 no pool result: the local run decides, fallback logged (rc=$RC local=$LOCAL)"

STUB_POOL=othercommit STUB_LOCAL_RC=0 run docs/a.md
[ "$RC" = 0 ] && [ "$LOCAL" = yes ] && grep -q "not HEAD" <<<"$OUT"
leg $? "4 a pool result for another commit is not counted: local fallback (rc=$RC local=$LOCAL)"

STUB_POOL=green STUB_LOCAL_RC=0 run tools/pool/x.sh
[ "$RC" = 0 ] && [ "$LOCAL" = yes ] && grep -q "high-risk push" <<<"$OUT" && grep -q "pool and local both green" <<<"$OUT"
leg $? "5 high-risk, both green: pass, pool AND local ran (rc=$RC local=$LOCAL)"

STUB_POOL=green STUB_LOCAL_RC=1 run tools/pool/x.sh
[ "$RC" = 1 ] && [ "$CACHE" = no ] && grep -q "DISAGREE" <<<"$OUT"
leg $? "6 high-risk, pool green and local red: refused as a disagreement (rc=$RC cache=$CACHE)"

T1408_POOL=0 STUB_POOL=green STUB_LOCAL_RC=0 run docs/a.md
[ "$RC" = 0 ] && [ "$LOCAL" = yes ] && grep -q "T1408_POOL=0" <<<"$OUT"
leg $? "7 T1408_POOL=0: local only (rc=$RC local=$LOCAL)"

grep -q . .context/working/prepush-core.runs.log && git check-ignore -q .context/working/prepush-core.runs.log
leg $? "8 every decision is logged in .context/working/prepush-core.runs.log, git-ignored by a committed rule"
echo "=== $pass passed, $fail failed ==="
[ "$fail" -eq 0 ]
