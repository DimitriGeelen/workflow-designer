#!/bin/bash
# T-902 (arc-001) — teeth for E-META-AUTHORITY, the YAML twin of E-XML-META-AUTHORITY.
#
# WHAT IT DEFENDS. The YAML form could carry a node-level authority all along (the
# bridge's META_KEYS projects aef.authority onto aef:meta/@authority) and nothing
# gated the value. T-889 classified its XML rule GAP rather than assert a counterpart
# that did not exist; this is the counterpart, so the harness's PAIRED claim is true.
#
# CONTROLS FIRST: absent is silent, valid is silent, and the corpus maps that carry
# the key on nodes today (enumerated, count > 0) all validate clean — the gate lands
# on real data without a false red. THE GATE CASE: an out-of-vocabulary value fires
# and names the uid. Under --mutation the gate is removed from a COPY of the validator
# and the gate case must go red while every control stays green.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
VAL="${VAL:-$ROOT/tools/validate-workflow.py}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t902.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

grep -q 'T-902-GATE' "$VAL" || { echo "TEETH BROKEN — T-902-GATE anchor not found in $VAL. Not reporting a pass."; exit 4; }

BASE="$ROOT/examples/aef-processes/task-lifecycle.workflow.yaml"
mk() { # $1 out, $2 authority value or "" for none: inject under the first node's aef bag
    python3 - "$BASE" "$1" "$2" <<'PY'
import sys
src, dst, val = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(src, encoding="utf-8").read()
needle = "  - uid: n_file\n    type: startEvent\n    name: Task captured (filed)\n    slug: captured\n    lane: framework\n    x: 120\n    y: 334\n    aef:\n"
assert s.count(needle) == 1, "fixture anchor not found exactly once"
if val:
    s = s.replace(needle, needle + "      authority: %s\n" % val, 1)
open(dst, "w", encoding="utf-8").write(s)
PY
}
run() { python3 "$VAL" "$1" 2>&1; }

echo "=== T-902 teeth: E-META-AUTHORITY on the YAML form (subject: ${VAL#$ROOT/}) ==="
# ── controls
mk "$WORK/absent.yaml" ""
out=$(run "$WORK/absent.yaml"); rc=$?
[ $rc -eq 0 ] && ! echo "$out" | grep -q 'E-META-AUTHORITY' && ok control_absent_is_silent || bad control_absent_is_silent "rc=$rc"
mk "$WORK/valid.yaml" "sovereignty"
out=$(run "$WORK/valid.yaml"); rc=$?
[ $rc -eq 0 ] && ! echo "$out" | grep -q 'E-META-AUTHORITY' && ok control_valid_is_silent || bad control_valid_is_silent "rc=$rc $(echo "$out" | grep META)"
# the corpus population: every YAML map carrying node-level aef.authority validates clean
pop=$(grep -ln '^      authority:' "$ROOT"/examples/aef-processes/*.workflow.yaml)
n=$(echo "$pop" | grep -c .)
bad_maps=""
for f in $pop; do python3 "$VAL" "$f" >/dev/null 2>&1 || bad_maps="$bad_maps ${f##*/}"; done
[ "$n" -gt 0 ] && [ -z "$bad_maps" ] && ok "control_corpus_population_clean_${n}_maps" || bad control_corpus_population_clean "n=$n bad=$bad_maps"
# the vocabulary is read from one place: the rule body names AUTHORITIES and re-lists no value
python3 - "$VAL" <<'PY' && ok control_vocabulary_reused_not_relisted || bad control_vocabulary_reused_not_relisted "rule body re-lists a value or does not name AUTHORITIES"
import sys, re
s = open(sys.argv[1]).read()
i = s.find("def _check_meta_authority"); j = s.find("\n    def ", i + 1)
body = s[i:j]
assert "AUTHORITIES" in body
assert not re.search(r"\{\s*['\"]sovereignty['\"]", body)
PY

# ── gate case
mk "$WORK/bad.yaml" "overlord"
out=$(run "$WORK/bad.yaml"); rc=$?
[ $rc -eq 2 ] && echo "$out" | grep -q "E-META-AUTHORITY" && echo "$out" | grep -q "n_file" && echo "$out" | grep -q "overlord" \
    && ok gate_out_of_vocabulary_fires_naming_uid_and_value || bad gate_out_of_vocabulary_fires_naming_uid_and_value "rc=$rc $(echo "$out" | tail -2)"

# ── mutation
if [ "${1:-}" = "--mutation" ]; then
    MUT="$WORK/validate.mutant.py"
    python3 - "$VAL" "$MUT" <<'PY'
import sys
s = open(sys.argv[1]).read()
needle = "        self._check_meta_authority(nodes)\n"
assert s.count(needle) == 1
open(sys.argv[2], "w").write(s.replace(needle, "        pass  # MUTANT: meta-authority gate removed\n", 1))
PY
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutant"; exit 1; }
    python3 -m py_compile "$MUT" || { echo "MUTATION SETUP FAILED: mutant does not parse"; exit 1; }
    grep -q 'MUTANT: meta-authority gate removed' "$MUT" || { echo "MUTATION SETUP FAILED: mutation not applied"; exit 1; }
    echo "=== T-902 MUTATION RUN (gate removed) ==="
    mout=$(VAL="$MUT" bash "$0" 2>&1); echo "$mout" | sed 's/^/  | /'
    for c in control_absent_is_silent control_valid_is_silent control_corpus_population_clean control_vocabulary_reused_not_relisted; do
        echo "$mout" | grep -q "^  PASS  $c" || { echo "MUTATION SETUP BROKEN — control $c failed under the mutant"; exit 1; }
    done
    echo "$mout" | grep -q '^  FAIL  gate_out_of_vocabulary_fires_naming_uid_and_value$' || { echo "MUTATION FAILED — the gate case passes against a validator with no gate"; exit 1; }
    echo "MUTATION OK — controls green, the gate case went red."
    exit 0
fi
echo; echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
