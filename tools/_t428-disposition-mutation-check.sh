#!/usr/bin/env bash
# _t428-disposition-mutation-check.sh — prove the disposition check can move.
#
# T-428.
#
# ONE FIXTURE, ALL FIVE VERDICTS
# ------------------------------
# Every verdict is asserted against a SINGLE scratch register rather than one register
# per verdict. Five separate fixtures would all pass on an implementation that returns a
# constant per file — which is not a hypothetical failure mode, it is the shape the T-427
# provenance bug had (a per-tree constant that happened to be right on the tree it was
# built from). Making the fixture heterogeneous is what forces the classifier to actually
# discriminate.
#
# THE PREFIX LEG IS NOT PEDANTRY
# ------------------------------
# task_location matches "T-20-" and not "T-20". The live register contains both T-020 and
# T-201, and a substring match would resolve T-20 against T-201's file and silently
# reclassify a dangling row as live — a false negative in the direction of silence, which
# is the direction this whole instrument exists to close.
#
# WHAT THE MUTATIONS ARE FOR
# --------------------------
# A green suite on an instrument nobody has broken proves nothing. Each mutation disables
# exactly one discrimination and names which leg must go red. If a mutation leaves the
# suite green, the corresponding leg was never testing anything.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
REAL="$PWD"
CHK="$REAL/tools/_t428-assumption-disposition-check.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0

check() {   # check <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf '  PASS  %s\n' "$1"; pass=$((pass+1))
  else
    printf '  FAIL  %s\n        expected [%s] got [%s]\n' "$1" "$2" "$3"; fail=$((fail+1))
  fi
}

# count <root> <verdict> -> the integer the checker printed for that bucket
count() {
  T428_ROOT="$2" python3 "${3:-$CHK}" 2>/dev/null \
    | awk -v k="$1" '$1==k {print $2; exit}'
}

exitcode() {   # exitcode <root> [script]
  T428_ROOT="$1" python3 "${2:-$CHK}" >/dev/null 2>&1
  echo $?
}

# ---------------------------------------------------------------- fixture
mkfixture() {   # mkfixture <dir>
  local d="$1"
  mkdir -p "$d/.tasks/active" "$d/.tasks/completed" "$d/.context/project"
  printf -- '---\nid: T-900\n---\n' > "$d/.tasks/active/T-900-still-open.md"
  printf -- '---\nid: T-901\n---\n' > "$d/.tasks/completed/T-901-closed.md"
  # T-201 exists, T-20 does NOT — the prefix trap.
  printf -- '---\nid: T-201\n---\n' > "$d/.tasks/completed/T-201-lookalike.md"
  cat > "$d/.context/project/assumptions.yaml" <<'YAML'
assumptions:
- id: A-900
  statement: owner closed the door behind it
  status: untested
  validation_method: TBD
  evidence: []
  linked_task: T-901
- id: A-901
  statement: still somebody's problem
  status: untested
  validation_method: TBD
  evidence: []
  linked_task: T-900
- id: A-902
  statement: answered, and the answer was written down
  status: validated
  validation_method: measured
  evidence:
  - outcome: probe returned 12/12
    date: '2026-08-11'
  linked_task: T-901
- id: A-903
  statement: status says answered, nothing says how
  status: validated
  validation_method: TBD
  evidence: []
  linked_task: T-901
- id: A-904
  statement: points at a task that does not exist
  status: untested
  validation_method: TBD
  evidence: []
  linked_task: T-777
- id: A-905
  statement: linked to T-20, and only T-201 exists — must not resolve
  status: untested
  validation_method: TBD
  evidence: []
  linked_task: T-20
YAML
}

echo "=== T-428 disposition mutation check ==="
echo

mkfixture "$WORK/base"

# ---------------------------------------------------------------- P: all five verdicts, one register
echo "P — every verdict discriminated inside ONE heterogeneous register"
check "P1 untested + closed owner is DANGLING"      "1" "$(count dangling    "$WORK/base")"
check "P2 untested + open owner is LIVE"            "1" "$(count live        "$WORK/base")"
check "P3 disposed WITH evidence is DISPOSED"       "1" "$(count disposed    "$WORK/base")"
check "P4 disposed WITHOUT evidence is UNEVIDENCED" "1" "$(count unevidenced "$WORK/base")"
check "P5 unresolvable linked_task is ORPHAN"       "2" "$(count orphan      "$WORK/base")"
check "P6 findings exit 1"                          "1" "$(exitcode          "$WORK/base")"

# P5 expects 2: A-904 (T-777, absent) and A-905 (T-20, prefix trap). Asserted apart:
echo
echo "N — the prefix trap: T-20 must not resolve against T-201"
NOPREFIX="$(T428_ROOT="$WORK/base" python3 "$CHK" 2>/dev/null | grep -c 'A-905')"
check "N1 A-905 appears in the report (not silently resolved)" "1" "$NOPREFIX"

# ---------------------------------------------------------------- C: clean tree exits 0
echo
echo "C — a register with nothing wrong must exit 0, and say PASS"
mkfixture "$WORK/clean"
python3 - "$WORK/clean/.context/project/assumptions.yaml" <<'PY'
import sys, yaml
p = sys.argv[1]
d = yaml.safe_load(open(p))
d["assumptions"] = [a for a in d["assumptions"] if a["id"] == "A-902"]
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
check "C1 clean register exits 0" "0" "$(exitcode "$WORK/clean")"
CLEAN_OUT="$(T428_ROOT="$WORK/clean" python3 "$CHK" 2>/dev/null | grep -c '^PASS')"
check "C2 clean register says PASS" "1" "$CLEAN_OUT"

# ---------------------------------------------------------------- L: ambiguity fails LOUD
echo
echo "L — cannot-answer must not read like nothing-found"
mkdir -p "$WORK/broken/.context/project" "$WORK/broken/.tasks/active" "$WORK/broken/.tasks/completed"
printf 'assumptions:\n- id: A-1\n  status: [unclosed\n' > "$WORK/broken/.context/project/assumptions.yaml"
check "L1 unparseable register exits 2" "2" "$(exitcode "$WORK/broken")"

mkdir -p "$WORK/notasks/.context/project"
cp "$WORK/base/.context/project/assumptions.yaml" "$WORK/notasks/.context/project/"
check "L2 missing task tree exits 2 (not 0)" "2" "$(exitcode "$WORK/notasks")"

mkfixture "$WORK/empty"
printf 'assumptions: []\n' > "$WORK/empty/.context/project/assumptions.yaml"
check "L3 empty register exits 2, not PASS" "2" "$(exitcode "$WORK/empty")"

# ---------------------------------------------------------------- R: the remedy must not launder
echo
echo "R — printed remedy must never offer a status flip (OBS-017)"
LAUNDER="$(T428_ROOT="$WORK/base" python3 "$CHK" 2>/dev/null \
  | grep -ciE 'run:? *(bin/)?(\.agentic-framework/bin/)?fw assumption validate')"
check "R1 no runnable 'fw assumption validate' remedy" "0" "$LAUNDER"

# ---------------------------------------------------------------- M: mutations must move legs
echo
echo "M — disable one discrimination each; the named leg must go red"

# M1: collapse completed/active — everything untested becomes live. P1 must break.
sed 's/return "dangling" if where == "completed" else "live"/return "live"/' \
  "$CHK" > "$WORK/m1.py"
check "M1 collapsing owner-state kills the DANGLING leg" "0" "$(count dangling "$WORK/base" "$WORK/m1.py")"

# M2: stop looking at evidence — unevidenced disappears into disposed. P4 must break.
sed 's/return "disposed" if row.get("evidence") else "unevidenced"/return "disposed"/' \
  "$CHK" > "$WORK/m2.py"
check "M2 ignoring evidence kills the UNEVIDENCED leg" "0" "$(count unevidenced "$WORK/base" "$WORK/m2.py")"

# M3: substring match instead of prefix — T-20 resolves against T-201, orphan drops to 1.
sed 's/if name.startswith(prefix) and name.endswith(".md"):/if str(task_id) in name and name.endswith(".md"):/' \
  "$CHK" > "$WORK/m3.py"
check "M3 substring matching hides the prefix trap" "1" "$(count orphan "$WORK/base" "$WORK/m3.py")"

echo
echo "  pass=$pass fail=$fail"

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${pass:-0} + ${fail:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi

[ "$fail" -eq 0 ] || exit 1
