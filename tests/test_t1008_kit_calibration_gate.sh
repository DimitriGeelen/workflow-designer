#!/usr/bin/env bash
# T-1008 / L16: a new kit is released only with a PASS calibration of its own bytes.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; G="$ROOT/tools/kit-calibration-gate.py"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT; export KIT_CALIBRATION_RECORDS="$W/rec"
V=9.9.9-test; pass=0; fail=0
ok() { pass=$((pass+1)); echo "PASS $1"; }; bad() { fail=$((fail+1)); echo "FAIL $1"; }
printf 'recall: 3/3 planted defects caught\nfalse findings: 0 on the clean map, 0 on unplanted elements\nCALIBRATION: PASS\n' > "$W/pass.txt"
printf 'recall: 3/3 planted defects caught\nfalse findings: 2 on the clean map, 0 on unplanted elements\nCALIBRATION: FAIL\n' > "$W/fail.txt"

python3 "$G" check --version $V > "$W/o"; [ $? -ne 0 ] && grep -q "no calibration record" "$W/o" && ok "no record refuses" || bad "no record refuses"
python3 "$G" record --version $V --reviewer codex --vendor openai --result-file "$W/pass.txt" >/dev/null
python3 "$G" check --version $V >/dev/null && ok "PASS record of these bytes passes" || bad "PASS record of these bytes passes"
python3 "$G" record --version $V --reviewer glm --vendor zai --result-file "$W/fail.txt" >/dev/null
python3 "$G" check --version $V > "$W/o"; [ $? -ne 0 ] && grep -q "not PASS for glm" "$W/o" && ok "one FAIL refuses" || bad "one FAIL refuses"
sed -i 's/^kit_sha256: .*/kit_sha256: 0000/' "$W/rec/$V.yaml"
python3 "$G" check --version $V > "$W/o"; [ $? -ne 0 ] && grep -q "measured a different kit" "$W/o" && ok "record for other bytes refuses" || bad "record for other bytes refuses"
printf 'nothing here\n' > "$W/junk.txt"; python3 "$G" record --version $V --reviewer x --vendor y --result-file "$W/junk.txt" >/dev/null 2>&1
[ $? -ne 0 ] && ok "a non-calibration output is not recorded" || bad "a non-calibration output is not recorded"
echo "t1008 gate: $pass passed, $fail failed"; [ $fail -eq 0 ]
