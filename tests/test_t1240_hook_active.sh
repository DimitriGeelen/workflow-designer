#!/usr/bin/env bash
# T-1240: a gate whose hook line is COMMENTED OUT (AEF T-4403 on reinstall) reads NOT installed, and the installers put
# an active line back. Runs the real installers (or the ones named in T1240_DIR, to prove the old ones failed) on a
# throwaway repo whose hook looks like the one job 059's upgrade left.
set -u
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC=${T1240_DIR:-$ROOT/tools}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "PASS  $1"; }
bad() { fail=$((fail + 1)); echo "FAIL  $1"; }
cd "$T" && git init -q && mkdir -p tools
cp "$SRC/_t1000-install-hook.sh" "$SRC/_t1161-install-hook.sh" "$SRC/_t1239-install-hook.sh" tools/ 2>/dev/null
for g in _t1000-revendor-gate.sh _t1161-boundary-gate.sh _t1239-lan-address-gate.sh; do printf '#!/bin/bash\nexit 0\n' > tools/$g; done
H=.git/hooks/pre-commit
cat > $H <<'HOOK'
#!/bin/bash
# >>> agentic-framework hook >>>
echo framework
# <<< agentic-framework hook <<<
# T-4403: kept from the previous pre-commit by fw git install-hooks (commented out — uncomment the lines that are yours)
# bash "$(git rev-parse --show-toplevel)/tools/_t1000-revendor-gate.sh" || exit 1  # 832-T-1000-revendor-gate
# bash "$(git rev-parse --show-toplevel)/tools/_t1161-boundary-gate.sh" || exit 1  # 832-T-1161-boundary-gate
# bash "$(git rev-parse --show-toplevel)/tools/_t1239-lan-address-gate.sh" || exit 1  # 832-T-1239-lan-address-gate
HOOK
for i in 1000 1161 1239; do
    if bash tools/_t$i-install-hook.sh --check >/dev/null 2>&1; then bad "1/$i commented-only gate reads INSTALLED (false green)"
    else ok "1/$i commented-only gate reads NOT installed"; fi
done
bash tools/_t1000-install-hook.sh >/dev/null 2>&1   # installs all three
for m in 832-T-1000-revendor-gate 832-T-1161-boundary-gate 832-T-1239-lan-address-gate; do
    act=$(grep -E '^[[:space:]]*bash ' $H | grep -cF "$m"); com=$(grep -E '^[[:space:]]*#' $H | grep -cF "$m")
    { [ "$act" = 1 ] && [ "$com" = 0 ]; } && ok "2 $m: one active line, commented copy removed" || bad "2 $m: active=$act commented=$com"
done
n=$(grep -n '832-T-' $H | head -3 | cut -d: -f1 | tr '\n' ' ')
[ "$n" = "2 3 4 " ] && ok "3 the three gates sit right after the shebang (lines 2-4)" || bad "3 gate lines at: $n"
bash tools/_t1000-install-hook.sh --check >/dev/null 2>&1 && ok "4 --check now exits 0" || bad "4 --check after install"
echo "T-1240 hook gates: $pass passed, $fail failed"
[ "$fail" = 0 ]
