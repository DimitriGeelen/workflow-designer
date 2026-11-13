#!/usr/bin/env bash
# _t1409-tier-gate-teeth.sh — T-1409: tools/pool/tier-gate.sh runs the BROWSER tier where the rules say.
# A scratch repo with an upstream; tests/run-bridge-tests.sh is a stub that records which tier it was asked for and exits
# $STUB_LOCAL_RC; the pool is a stub (T1408_POOL_SUBMIT) that records its tier argument and writes
# build/pool/last-browser.result for HEAD with $STUB_POOL (green|red|none).
#   1 normal change, pool green     -> 0, local NOT run, the pool asked for "browser"
#   2 normal change, pool red       -> 1
#   3 high-risk change, both green  -> 0, pool AND local ran, local asked for "--tier browser"
#   4 high-risk, pool red, local green -> 1, a DISAGREEMENT
#   5 no pool result                -> local decides (0), fallback logged
#   6 high-risk, no Node with WebSocket here -> 1, CANNOT RUN, local not started, not a "disagreement"
# Control: T1409_TIERGATE=<another script> must fail. Exit 0 all hold; 1 one does not; 2 setup broken.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S=$(mktemp -d "${TMPDIR:-/tmp}/t1409.XXXXXX") || exit 2
trap 'rm -rf "$S"' EXIT
pass=0; fail=0
leg() { if [ "$1" = 0 ]; then pass=$((pass + 1)); echo "  PASS  $2"; else fail=$((fail + 1)); echo "  FAIL  $2"; fi; }
G() { git -c user.name=t -c user.email=t@invalid "$@"; }
git init -q --bare "$S/origin.git" || exit 2
W="$S/w"; git init -q -b main "$W" || exit 2
cd "$W" || exit 2
mkdir -p tools/pool tests docs build/pool
cp "${T1409_TIERGATE:-$ROOT/tools/pool/tier-gate.sh}" tools/pool/tier-gate.sh || exit 2
cp "$ROOT/tools/pool/high-risk.re" tools/pool/high-risk.re || exit 2
git -C "$ROOT" show HEAD:.gitignore > .gitignore 2>/dev/null || exit 2
cat > tests/run-bridge-tests.sh <<'SH'
#!/bin/bash
echo "$*" > "$(git rev-parse --show-toplevel)/.local-ran"
echo "tier browser $([ "${STUB_LOCAL_RC:-0}" = 0 ] && echo GREEN || echo RED): stub"
exit "${STUB_LOCAL_RC:-0}"
SH
cat > "$S/pool-stub.sh" <<'SH'
#!/bin/bash
top=$(git rev-parse --show-toplevel); echo "$*" > "$top/.pool-ran"
r="$top/build/pool/last-${1:-core}.result"; rm -f "$r"
case "${STUB_POOL:-green}" in none) exit 1 ;; green) code=0 ;; red) code=1 ;; esac
printf 'name=stub\ncommit=%s\nexit_code=%s\nnode=stub-node\nresult_line=tier browser stub\ntier_log=/nonexistent\n' "$(git rev-parse HEAD)" "$code" > "$r"
SH
echo x > docs/a.md
G add -A && G commit -qm init && git remote add origin "$S/origin.git" && G push -q -u origin main || exit 2
export T1408_POOL_SUBMIT="bash $S/pool-stub.sh"
# A stub node first on PATH and a HOME with no ~/.nvm: whether "node has WebSocket" is the case's choice
# ($STUB_NODE_WS, default yes), never this machine's Node (T-1409: system Node 18 has none).
mkdir -p "$S/bin" "$S/home"
printf '#!/bin/bash\n[ "${STUB_NODE_WS:-yes}" = yes ]\n' > "$S/bin/node"; chmod +x "$S/bin/node"

run() {
    echo "$RANDOM" >> "$1"; G add -A; G commit -qm "change $1"
    rm -f .local-ran .pool-ran
    OUT=$(PATH="$S/bin:$PATH" HOME="$S/home" bash tools/pool/tier-gate.sh browser 2>&1); RC=$?
    LOCAL=$(cat .local-ran 2>/dev/null || echo no); POOL=$(cat .pool-ran 2>/dev/null || echo no)
    G push -q origin main 2>/dev/null
}

STUB_POOL=green run docs/a.md
[ "$RC" = 0 ] && [ "$LOCAL" = no ] && [ "$POOL" = browser ]
leg $? "1 normal change, pool green: 0, local not run, the pool asked for browser (rc=$RC local=$LOCAL pool=$POOL)"

STUB_POOL=red run docs/a.md
[ "$RC" = 1 ]
leg $? "2 normal change, pool red: refused (rc=$RC)"

STUB_POOL=green STUB_LOCAL_RC=0 run tools/pool/x.sh
[ "$RC" = 0 ] && [ "$LOCAL" = "--tier browser" ] && [ "$POOL" = browser ]
leg $? "3 high-risk, both green: 0, pool AND local ran, local asked for --tier browser (rc=$RC local=$LOCAL)"

STUB_POOL=red STUB_LOCAL_RC=0 run tools/pool/x.sh
[ "$RC" = 1 ] && grep -q "DISAGREE" <<<"$OUT"
leg $? "4 high-risk, pool red and local green: refused as a disagreement (rc=$RC)"

STUB_POOL=none STUB_LOCAL_RC=0 run docs/a.md
[ "$RC" = 0 ] && [ "$LOCAL" = "--tier browser" ] && grep -q "falling back to the local run" <<<"$OUT"
leg $? "5 no pool result: the local browser run decides, fallback logged (rc=$RC local=$LOCAL)"

STUB_NODE_WS=no STUB_POOL=green STUB_LOCAL_RC=0 run tools/pool/x.sh
[ "$RC" = 1 ] && [ "$LOCAL" = no ] && grep -q "CANNOT RUN" <<<"$OUT" && ! grep -q "DISAGREE" <<<"$OUT"
leg $? "6 high-risk, no Node with WebSocket here: refused as CANNOT RUN (local not started), never a disagreement (rc=$RC local=$LOCAL)"
echo "=== $pass passed, $fail failed ==="
[ "$fail" -eq 0 ]
