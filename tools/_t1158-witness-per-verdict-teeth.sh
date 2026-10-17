#!/bin/bash
# T-1158 (OBS-418) — teeth for per-verdict witness lists in the round-trip guard's node-level and
# workflowMeta-level self-tests (tools/_roundtrip-serialization-cdp.mjs).
#
# WHAT IT DEFENDS. Both levels used to keep ONE `witnesses` list for every verdict, so a BLIND finding
# was printed next to fixtures where the key was LIVE — the reader is sent to a file where nothing is
# wrong (measured at the lane level under T-910). Now a BLIND names `blind_in` (fixture + the value the
# parser saw before/after) and, separately, `also_live_in`.
#
# HOW. A mutant whose projection ignores ONE key in ONE fixture only — the discriminating case, a key
# BLIND in one document and LIVE in others. A mutant that blinded the key everywhere could not tell
# pooled lists from per-verdict ones. The target fixture sorts LAST among those carrying the key, so a
# pooled list (first names pushed, any verdict) would have filled with LIVE fixtures and named the
# wrong evidence. Expected, per level: blind_in is exactly [target], its value_before/value_after show
# the parser DID see the mutation (value_after carries the __DRIFT__ mark) while the projection did not,
# and also_live_in is non-empty and excludes the target.
#
# CONTROL: the unmutated guard passes with no BLIND at either level (otherwise the mutants' findings
# could be the guard's own).

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
SUBJECT="${SUBJECT:-$ROOT/tools/_roundtrip-serialization-cdp.mjs}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t1158.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

# level | key | target fixture | marker unique to the target | anchor (start of the projection to blind)
NODE_CASE="selftest|agentType|offpage-seam.bpmn|Process_offpage_seam|METAKEYS.forEach(function(k){ if(aef[k]!=null&&aef[k]!=='') meta[k]=String(aef[k]); });"
WM_CASE="wm_selftest|title|typed-events.bpmn|Process_typed|WMSPEC.forEach(function(k){ var v=s[k];"

mutant() { # $1 case, $2 out
    python3 - "$SUBJECT" "$2" "$ROOT" "$1" <<'PY'
import sys
src, out, root, case = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
level, key, target, marker, anchor = case.split("|", 4)
s = open(src).read()
for old, new in (("const HERE = dirname(fileURLToPath(import.meta.url));", f"const HERE = {root + '/tools'!r};"),
                 ("from './_cdp-attach.mjs';", f"from {root + '/tools/_cdp-attach.mjs'!r};")):
    if s.count(old) != 1: sys.exit(f"MUTATION SETUP FAILED: {old!r} found {s.count(old)}x")
    s = s.replace(old, new)
if level == "clean":                            # path rewrites only: the control copy
    open(out, "w").write(s); sys.exit(0)
if s.count(anchor) < 1: sys.exit(f"MUTATION SETUP FAILED: projection anchor not found: {anchor!r}")
# First occurrence: the node-level PREFLIGHT_EXPR proj, or the WM_PREFLIGHT_EXPR wmProj.
i = s.find(anchor)
head = anchor.split("{", 1)[0] + "{"           # "...forEach(function(k){"
inject = f" if(k==={key!r}&&window.__FIXTURE__.indexOf({marker!r})>=0) return;"
s = s[:i] + head + inject + anchor[len(head):] + s[i + len(anchor):]
open(out, "w").write(s)
PY
}

verdict_of() { # $1 file -> JSON on stdout (the guard prints one JSON document)
    python3 -c 'import json,sys; t=open(sys.argv[1]).read(); print(json.dumps(json.loads(t[t.index("{"):])))' "$1"
}

echo "=== T-1158 teeth: per-verdict witnesses in the node + workflowMeta self-tests ==="

# ── control ────────────────────────────────────────────────────────────────────
mutant "clean||||" "$WORK/clean.mjs" || { echo "MUTATION SETUP FAILED: control copy"; exit 1; }
node "$WORK/clean.mjs" > "$WORK/clean.out" 2>&1; rc=$?
if python3 - "$WORK/clean.out" <<'PY'
import json,sys
t=open(sys.argv[1]).read(); d=json.loads(t[t.index("{"):])
ok = d.get("pass") is True and not d["selftest"]["blind"] and not d["wm_selftest"]["blind"]
sys.exit(0 if ok else 1)
PY
then ok control_unmutated_guard_has_no_blind; else bad control_unmutated_guard_has_no_blind "rc=$rc (see $WORK/clean.out)"; fi

# ── the two mutants ────────────────────────────────────────────────────────────
for CASE in "$NODE_CASE" "$WM_CASE"; do
    IFS='|' read -r level key target marker _ <<< "$CASE"
    name="${level}_${key}_blind_names_only_${target%.bpmn}"
    MUT="$WORK/t1158-mutant-$level.mjs"   # HERE and the import are absolute in the mutant
    mutant "$CASE" "$MUT" || { bad "$name" "mutation setup failed"; continue; }
    grep -q "indexOf('$marker')" "$MUT" || { bad "$name" "mutation not applied"; continue; }
    node "$MUT" > "$WORK/$level.out" 2>&1; rc=$?
    if out=$(python3 - "$WORK/$level.out" "$level" "$key" "$target" <<'PY'
import json,sys
f, level, key, target = sys.argv[1:5]
t=open(f).read()
try: d=json.loads(t[t.index("{"):])
except Exception as e: print(f"no JSON verdict: {e}"); sys.exit(1)
lv=d.get(level) or {}
hits=[b for b in lv.get("blind", []) if b.get("key")==key]
if len(hits)!=1: print(f"expected one BLIND entry for {key}, got {lv.get('blind')}"); sys.exit(1)
b=hits[0]
if "witnesses" in b: print(f"pooled witnesses list still present, naming {b['witnesses']} for a BLIND that is only in {target}"); sys.exit(1)
names=[x.get("fixture") for x in b.get("blind_in", [])]
if names!=[target]: print(f"blind_in names {names}, expected [{target}]"); sys.exit(1)
w=b["blind_in"][0]
# The parser saw the mutation (values differ) and the projection did not: that pair is the evidence.
if w.get("value_before") is None or w.get("value_before")==w.get("value_after") or "__DRIFT__" not in str(w.get("value_after")):
    print(f"value_before/value_after do not show the parser seeing the mutation: {w}"); sys.exit(1)
live=b.get("also_live_in", [])
if not live or target in live: print(f"also_live_in {live} must be non-empty and exclude {target}"); sys.exit(1)
if d.get("pass") is not False: print("the mutant's BLIND did not fail the guard"); sys.exit(1)
print(f"blind_in={names} also_live_in={live}")
PY
    ); then ok "$name"; printf '        %s\n' "$out"; else bad "$name" "$out (rc=$rc)"; fi
done

echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
