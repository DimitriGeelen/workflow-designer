#!/bin/bash
# T-905 (arc-001) — teeth for the round-trip guard's VERIFIED computed-source declarations.
#
# WHAT IT DEFENDS. COMPUTED_SOURCES exists so that aef[<var>] must name the list it
# iterates. Until T-905 the guard only checked that a declaration EXISTED, so
# `key: 'metaKeys'` — a source `key` never iterates — was indistinguishable from a
# correct entry. Now the guard derives each variable's binding sources from the
# stripped emitter body and diffs them against the declaration, and every declared
# source must exist where it says it lives.
#
# MUTANTS are applied to a COPY of the guard inside tools/ (the guard resolves the
# repo from its own location, so a copy in /tmp would look at the wrong tree) and
# never to src/. Each mutant is asserted applied before it is scored; the copy is
# removed on EXIT. CONTROLS run first and must hold: the unmutated guard is green
# in --denominators-only mode, reports the three declarations verified, shows `key`
# bound from the structured literals and not metaKeys, and classifies every key
# those literals contribute.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
GUARD="$ROOT/tools/_roundtrip-serialization-cdp.mjs"
MUT="$ROOT/tools/.t905-mutant.mjs"
trap 'rm -f "$MUT"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

grep -q 'function checkComputedSources' "$GUARD" || {
    echo "TEETH BROKEN — checkComputedSources not found in the guard. Not reporting a pass."; exit 4; }

echo "=== T-905 teeth: computed-source declarations are verified against the emitter ==="
base=$(node "$GUARD" --denominators-only 2>&1); rc=$?
[ $rc -eq 0 ] && echo "$base" | grep -q 'computed sources 3 verified' \
    && ok control_baseline_green_three_verified || bad control_baseline_green_three_verified "rc=$rc $(echo "$base" | grep summary)"
# key is bound from the structured literals and never from metaKeys — read from the report, not asserted
keyblock=$(echo "$base" | python3 -c "import json,sys; d=json.load(sys.stdin); print(' '.join(d['denominator']['computedSources']['key']['actual']))" 2>/dev/null)
# T-1044: T-573 (5b6931a4) moved key's first source to the module-scope STRUCT_LIST_KEYS.
[[ "$keyblock" == *STRUCT_LIST_KEYS* && "$keyblock" == *structItemList* && "$keyblock" == *aggregation* && "$keyblock" != *metaKeys* ]] \
    && ok control_key_bound_from_structured_not_metaKeys || bad control_key_bound_from_structured_not_metaKeys "actual=$keyblock"
# the bag is reported OPEN, not enumerated
echo "$base" | grep -q '"k <- carriedKeys"' && ok control_bag_reported_open || bad control_bag_reported_open "$(echo "$base" | grep -A4 openSources | head -5)"
# every key the structured literals contribute is classified (the guard is green, so none is an orphan) and non-empty
contrib=$(echo "$base" | python3 -c "import json,sys; d=json.load(sys.stdin); print(' '.join(d['denominator']['computedSources']['key']['contributed']))" 2>/dev/null)
[[ "$contrib" == *emits* && "$contrib" == *constituents* && "$contrib" == *timer* ]] \
    && ok control_structured_keys_join_projection || bad control_structured_keys_join_projection "contributed=$contrib"

mutate() { # $1 name, $2 python replacement expression file content via stdin
    cp "$GUARD" "$MUT"
    python3 - "$MUT" "$1" <<'PY'
import sys
p, which = sys.argv[1], sys.argv[2]
s = open(p).read()
if which == "misdeclare_key":
    old = "    { moduleObject: 'STRUCT_LIST_KEYS' },                       // for (const key in STRUCT_LIST_KEYS)\n    { inline: \"['aggregation', 'multiInstance', 'timer']\" },   // for (const key of [...])\n    { object: 'structItemList' },                              // for (const key in structItemList)\n"
    new = "    { literal: 'metaKeys' },  // MUTANT misdeclare_key\n"
elif which == "omit_k_source":
    old = "    { bag: 'carriedKeys' },        // [...metaKeys.filter(...), ...carriedKeys].map(k => ...)\n"
    new = "    // MUTANT omit_k_source\n"
elif which == "nonexistent_source":
    old = "    { module: 'EVENT_BINDING_FIELD' },                         // const bindField = EVENT_BINDING_FIELD[node.type]\n"
    new = "    { module: 'EVENT_BINDING_FIELD' }, { literal: 'noSuchList' },  // MUTANT nonexistent_source\n"
else:
    sys.exit("unknown mutant")
assert s.count(old) == 1, "anchor count != 1 for " + which
open(p, "w").write(s.replace(old, new, 1))
PY
    if cmp -s "$GUARD" "$MUT" || ! grep -q "MUTANT $1" "$MUT"; then echo "MUTATION SETUP BROKEN — $1 did not apply"; exit 1; fi
}
expect_red() { # $1 name, $2 grep pattern the refusal must carry
    mutate "$1"
    local out; out=$(node "$MUT" --denominators-only 2>&1); local rc=$?
    if [ $rc -ne 0 ] && echo "$out" | grep -q "$2"; then ok "$1_goes_red_and_names_it"
    else bad "$1_goes_red_and_names_it" "rc=$rc $(echo "$out" | grep -m2 -i 'problem\|COMPUTED')"; fi
}
expect_red misdeclare_key      'COMPUTED_SOURCES.key declares metaKeys but the emitter never binds key from it'
expect_red omit_k_source       'aef\[k\] is bound from carriedKeys which COMPUTED_SOURCES.k does not declare'
expect_red nonexistent_source  'noSuchList.*which does not exist in the emitter'   # JSON escapes the quotes
rm -f "$MUT"

echo; echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
