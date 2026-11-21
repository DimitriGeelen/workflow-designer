#!/usr/bin/env bash
# T-1486 teeth: tools/pool/tier-gate.sh's local half as LOCAL_K shards, each in a clean clone of HEAD.
# Hermetic: a scratch git repo holding a copy of tier-gate.sh; the pool off (T1408_POOL=0, local only); the tier itself
# replaced by a stub (T1486_LOCAL_CMD) that records where and as which shard it ran, and answers as each case says.
#   L1 three green shards: the local verdict is green, each shard ran once as i/3, each in its own clone (not the repo)
#   L2 one shard exits 1: red
#   L3 one shard prints no "tier <tier> GREEN" line and exits 0: red (no verdict is not a green)
#   L4 the clones are removed afterwards
#   L5 T1486_LOCAL_K=1: the old unsplit path (the stub is not used, no shard logs)
# Exit 0 = all legs pass.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S=$(mktemp -d "${TMPDIR:-/tmp}/t1486.XXXXXX") || exit 2
trap 'rm -rf -- "$S"' EXIT
fails=0
leg() { if [ "$1" = 0 ]; then echo "PASS  $2"; else echo "FAIL  $2${3:+  — $3}"; fails=$((fails + 1)); fi; }

R="$S/repo"; mkdir -p "$R/tools/pool" "$R/tests" "$R/build/tiergate"
cp "${T1486_TIERGATE:-$ROOT/tools/pool/tier-gate.sh}" "$R/tools/pool/tier-gate.sh" || exit 2
cp "$ROOT/tools/pool/high-risk.re" "$R/tools/pool/" 2>/dev/null
printf 'browser_shards=2\nlocal_shards=3\n' > "$R/tools/pool/workers"
# the unsplit path (L5) runs tests/run-bridge-tests.sh in the repo itself: a stub that says so
cat > "$R/tests/run-bridge-tests.sh" <<'EOF'
#!/usr/bin/env bash
echo "unsplit $PWD" >> "${T1486_REC:?}"; echo "tier $2 GREEN: 1 passed, 0 failed"
EOF
( cd "$R" && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -q -m init ) || exit 2
TMPC="$S/clones"; mkdir -p "$TMPC"

STUB="$S/stub.sh"
cat > "$STUB" <<'EOF'
#!/usr/bin/env bash
# records "<shard> <dir>"; T1486_CASE says what shard 2 or 3 does
echo "$T1288_SHARD $PWD" >> "${T1486_REC:?}"
case "${T1486_CASE:-green}:$T1288_SHARD" in
  red:2/3) echo "tier $2 RED: 0 passed, 1 failed"; exit 1 ;;
  silent:3/3) exit 0 ;;
esac
echo "tier $2 GREEN: 5 passed, 0 failed"
EOF
chmod +x "$STUB"

run() {  # run <case> [env...]: the gate, local only, k=3 unless overridden
    local c=$1; shift
    : > "$S/rec"
    ( cd "$R" && env TMPDIR="$TMPC" T1408_POOL=0 T1486_CASE="$c" T1486_REC="$S/rec" T1486_LOCAL_CMD="bash $STUB" "$@" \
        bash tools/pool/tier-gate.sh browser ) > "$S/out" 2>&1
}

run green; rc=$?
n=$(wc -l < "$S/rec"); shards=$(cut -d' ' -f1 "$S/rec" | sort | tr '\n' ' ')
inrepo=$(awk -v r="$R" '$2 == r' "$S/rec" | wc -l); dirs=$(cut -d' ' -f2 "$S/rec" | sort -u | wc -l)
leg "$([ "$rc" = 0 ] && [ "$n" = 3 ] && [ "$shards" = "1/3 2/3 3/3 " ] && [ "$inrepo" = 0 ] && [ "$dirs" = 3 ] && echo 0 || echo 1)" \
    "L1 three green shards: green, each shard once as i/3, each in its own clone" "rc=$rc runs=$n shards='$shards' in-repo=$inrepo dirs=$dirs"
left=$(find "$TMPC" -mindepth 1 -maxdepth 1 -name 't1486-*' | wc -l)
leg "$([ "$left" = 0 ] && echo 0 || echo 1)" "L4 the clones are removed afterwards" "left=$left"
run red; rc=$?
leg "$([ "$rc" != 0 ] && echo 0 || echo 1)" "L2 a shard that exits 1 makes the local verdict red" "rc=$rc"
run silent; rc=$?
leg "$([ "$rc" != 0 ] && echo 0 || echo 1)" "L3 a shard with no GREEN line (exit 0) makes the local verdict red" "rc=$rc"
run green T1486_LOCAL_K=1; rc=$?
leg "$([ "$rc" = 0 ] && grep -q "^unsplit $R\$" "$S/rec" && ! grep -q '/3 ' "$S/rec" && echo 0 || echo 1)" \
    "L5 T1486_LOCAL_K=1 runs the old unsplit path in the repo" "rc=$rc rec=$(tr '\n' '|' < "$S/rec")"

[ "$fails" = 0 ] && echo "T-1486: GREEN — all legs pass" || { echo "T-1486: RED — $fails leg(s) failed"; sed -n 1,20p "$S/out"; }
exit $(( fails > 0 ))
