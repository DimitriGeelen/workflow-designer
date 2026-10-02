#!/usr/bin/env bash
# T-1000: the re-vendor gate, walked through the protocol in a scratch git repo.
# Each refusal leg has a pass leg beside it, so a gate that refuses everything fails too.
# Run: bash tests/test_t1000_revendor_gate.sh   (exit 0 = all legs pass)
set -u
HERE=$(cd "$(dirname "$0")/.." && pwd)
GATE="$HERE/tools/_t1000-revendor-gate.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
leg() { # leg <name> <want: ok|refused> <command...>
    local name=$1 want=$2; shift 2
    if "$@" >"$T/out" 2>&1; then got=ok; else got=refused; fi
    if [ "$got" = "$want" ]; then pass=$((pass+1)); echo "PASS $name"; else fail=$((fail+1)); echo "FAIL $name (wanted $want, got $got)"; sed 's/^/     /' "$T/out" | head -8; fi
}
cd "$T" && git init -q r && cd r || exit 2
git config user.email t@t; git config user.name t
mkdir -p .agentic-framework/lib && echo 1.0.0 > .agentic-framework/VERSION && echo v1 > .agentic-framework/lib/a.sh && echo p > proj.txt
printf 'baseline_commit: 0000000\npaths: []\n' > .agentic-framework/.vendor-divergence.yaml
git add -A && git commit -qm c0 --no-verify
B0=$(git rev-parse HEAD); sed -i "s/0000000/$B0/" .agentic-framework/.vendor-divergence.yaml; git commit -qam "baseline c0" --no-verify
printf '#!/bin/bash\nbash "%s" || exit 1\n' "$GATE" > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

echo p2 >> proj.txt; git add proj.txt
leg "1 ordinary project commit, no upgrade: allowed" ok git commit -qm ordinary

echo 1.1.0 > .agentic-framework/VERSION; echo v2 > .agentic-framework/lib/a.sh; echo p3 >> proj.txt; git add -A
leg "2 G1: upgrade commit mixed with a project file: refused" refused git commit -qm mixed
git restore --staged proj.txt
leg "3 G1: pristine upgrade commit (vendored paths only): allowed" ok git commit -qm pristine
PRISTINE=$(git rev-parse HEAD)

git add proj.txt
leg "4 G2: ordinary commit right after the pristine commit: refused" refused git commit -qm too-early
git restore --staged proj.txt
sed -i "s/^baseline_commit: .*/baseline_commit: 1234567/" .agentic-framework/.vendor-divergence.yaml; git add .agentic-framework/.vendor-divergence.yaml
leg "5 G2: baseline moved, but not to the pristine commit: refused" refused git commit -qm wrong-base
sed -i "s/^baseline_commit: .*/baseline_commit: $PRISTINE/" .agentic-framework/.vendor-divergence.yaml; git add .agentic-framework/.vendor-divergence.yaml
leg "6 G2: baseline advanced to the pristine commit: allowed" ok git commit -qm advance

echo p5 >> proj.txt; git add proj.txt
leg "7 after the advance, ordinary commits flow again: allowed" ok git commit -qm after

echo local-fix >> .agentic-framework/lib/a.sh; git add .agentic-framework/lib/a.sh
leg "9 G4: a local fix to an UNDECLARED vendored path: refused" refused git commit -qm undeclared
printf '  - path: .agentic-framework/lib/a.sh\n    kind: content\n    task: T-X\n    upstream: fix\n    reason: test\n' >> .agentic-framework/.vendor-divergence.yaml
sed -i 's/^paths: \[\]$/entries:/' .agentic-framework/.vendor-divergence.yaml
git add .agentic-framework/.vendor-divergence.yaml .agentic-framework/lib/a.sh
leg "10 G4: the same fix with its declaration staged: allowed" ok git commit -qm declared
echo new > .agentic-framework/lib/b.sh; git add .agentic-framework/lib/b.sh
leg "11 G4: an undeclared local ADDITION: refused" refused git commit -qm added-undeclared
git restore --staged .agentic-framework/lib/b.sh; rm -f .agentic-framework/lib/b.sh

echo 1.2.0 > .agentic-framework/VERSION; echo p4 >> proj.txt; git add -A
leg "8 override is honoured and logged" ok env REVENDOR_GATE_OVERRIDE="test reason" git commit -qm overridden
leg "8b the override was logged" ok grep -q "test reason" .context/working/revendor-gate-overrides.log

echo; echo "T-1000 revendor gate: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
