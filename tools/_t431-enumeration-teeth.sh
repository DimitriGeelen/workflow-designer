#!/usr/bin/env bash
# _t431-enumeration-teeth.sh — prove the A-012 probe moves when either enumeration moves.
#
# T-431.
#
# ONE FIXTURE TREE, EVERY VERDICT
# -------------------------------
# All legs run against a single scratch root carrying both sources. Separate roots per leg
# would pass on an implementation returning a per-root constant — the T-427 shape, and the
# reason T-428's and T-429's fixtures are heterogeneous too.
#
# WHY M1 AND M2 ARE THE MUTATIONS THEY ARE
# ----------------------------------------
# They are not invented failure modes. They are the two bugs this probe actually had:
# splitting the allowed-values cell on bare `|` (which tears `a \| b \| c` apart and reads
# the first item as the whole enumeration — six of AEF's seven types reported unmapped, a
# confident and entirely wrong finding), and requiring backticks on values that the
# workflowType row writes bare (extraction found nothing and the probe exited 2). Both are
# kept as legs because a bug that has happened once is the cheapest available test case.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
PROBE="$PWD/tools/_t431-a012-enumeration-probe.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0
check() {
  if [ "$2" = "$3" ]; then printf '  PASS  %s\n' "$1"; pass=$((pass+1))
  else printf '  FAIL  %s\n        expected [%s] got [%s]\n' "$1" "$2" "$3"; fail=$((fail+1)); fi
}
run()  { T431_ROOT="$1" python3 "${2:-$PROBE}" 2>/dev/null; }
rc()   { T431_ROOT="$1" python3 "${2:-$PROBE}" >/dev/null 2>&1; echo $?; }
has()  { run "$1" "${3:-$PROBE}" | grep -cF "$2"; }

mkfix() {   # mkfix <root> <aef-types> <aef-owners> <std-types> <std-owners> <task-owner>
  local d="$1"
  mkdir -p "$d/.agentic-framework/lib" "$d/docs/standards" "$d/.tasks/active" "$d/.tasks/completed"
  cat > "$d/.agentic-framework/lib/enums.sh" <<SH
    VALID_TYPES="$2"
    VALID_OWNERS="$3"
is_valid_owner() {
    [[ " \$VALID_OWNERS " == *" \$1 "* ]]
}
SH
  # A real call site, in a different file. The definition alone must count as zero — that
  # is the whole point of the enforcement measurement, and a fixture with no caller cannot
  # tell "counts definitions" from "counts calls".
  cat > "$d/.agentic-framework/lib/caller.sh" <<'SH'
check_owner() { is_valid_owner "$1" || echo "bad owner" >&2; }
SH
  {
    printf '| key | Task-YAML field | Allowed values | Default |\n|---|---|---|---|\n'
    printf '| `workflowType` | `workflow_type` | %s | inferred |\n' "$4"
    printf '| ~~`owner`~~ *(derived)* | `owner` | %s | lane |\n' "$5"
  } > "$d/docs/standards/aef-bpmn-mapping-v1.md"
  printf -- '---\nid: T-001\nowner: %s\n---\n' "$6" > "$d/.tasks/active/T-001-x.md"
}

echo "=== T-431 A-012 enumeration teeth ==="
echo

# E1 — the two sides agree exactly. Bare values on one row, backticked on the other,
# because that is how the real standard is written.
mkfix "$WORK/ok" "build test" "human agent" 'build \| test' '`human` \| `agent`' human
check "E1 exact agreement exits 0"          "0" "$(rc "$WORK/ok")"
check "E1b and says PASS"                   "1" "$(has "$WORK/ok" 'PASS — A-012 holds')"
check "E1c reads BOTH values, not the first" "1" "$(has "$WORK/ok" 'standard has (2): build test')"

# E2 — AEF grows a type the standard never mapped.
mkfix "$WORK/grew" "build test spike" "human agent" 'build \| test' '`human` \| `agent`' human
check "E2 shipped-but-unmapped is a finding" "1" "$(has "$WORK/grew" 'SHIPPED BUT UNMAPPED : spike')"
check "E2b exits 1"                          "1" "$(rc "$WORK/grew")"

# E3 — the standard maps to a value AEF does not ship.
mkfix "$WORK/ghost" "build" "human agent" 'build \| test' '`human` \| `agent`' human
check "E3 mapped-but-not-shipped is a finding" "1" "$(has "$WORK/ghost" 'MAPPED BUT NOT SHIPPED: test')"

# E4 — a value in daily use that AEF's own enumeration does not contain.
mkfix "$WORK/used" "build test" "human claude-code" 'build \| test' '`human` \| `agent`' agent
check "E4 in-use-not-declared is a finding"  "1" "$(has "$WORK/used" 'IN USE, NOT DECLARED : agent(1)')"
check "E4b enforcement reported as 1 site"   "1" "$(has "$WORK/used" 'is_valid_owner() call sites in the vendored tree: 1')"

# L — ambiguity must fail LOUD, and never as agreement.
mkfix "$WORK/noenum" "build" "human" 'build' '`human`' human
rm "$WORK/noenum/.agentic-framework/lib/enums.sh"
check "L1 missing enums.sh exits 2"          "2" "$(rc "$WORK/noenum")"

mkfix "$WORK/noname" "build" "human" 'build' '`human`' human
sed -i 's/`workflow_type`/`something_else`/' "$WORK/noname/docs/standards/aef-bpmn-mapping-v1.md"
check "L2 standard row renamed exits 2, not 0" "2" "$(rc "$WORK/noname")"

# M — each mutation is a bug this probe actually had.
#
# Mutations are applied by literal replacement and the mutator EXITS NON-ZERO WHEN ITS
# ANCHOR IS ABSENT. The first version used sed with `|` delimiters against expressions full
# of escaped pipes; two of the three seds died with "unknown option to `s'", produced no
# output file, and the legs went GREEN — because a missing mutant file makes the grep find
# nothing, which is what the leg was asserting. A leg that passes because its mutation
# never applied is the exact defect T-429 was about, one layer in.
echo
echo "M — re-install each real bug; the named leg must go red"

mutate() {   # mutate <out> <literal-find> <literal-replace>
  python3 - "$PROBE" "$1" "$2" "$3" <<'PY' || { echo "  FAIL  mutation anchor missing: $2" >&2; exit 2; }
import sys
src = open(sys.argv[1], encoding="utf-8").read()
find, repl = sys.argv[3], sys.argv[4]
if find not in src:
    sys.exit(1)
open(sys.argv[2], "w", encoding="utf-8").write(src.replace(find, repl, 1))
PY
}

mutate "$WORK/m1.py" 'for tok in re.split(r"\\\|", cells[2]):' 'for tok in cells[2].split("|"):'
check "M1 splitting on bare pipe reads one value as the whole list" \
  "0" "$(has "$WORK/ok" 'standard has (2): build test' "$WORK/m1.py")"

mutate "$WORK/m2.py" 'if re.fullmatch(r"[a-z][a-z-]*", tok):' 'if re.fullmatch(r"NEVER", tok):'
check "M2 rejecting every token makes extraction fail, not agree" \
  "2" "$(rc "$WORK/ok" "$WORK/m2.py")"

mutate "$WORK/m3.py" 'if re.match(r"\s*%s\s*\(\)" % re.escape(symbol), line):' 'if False:'
check "M3 counting the definition as a call site inflates enforcement" \
  "1" "$(has "$WORK/used" 'call sites in the vendored tree: 2' "$WORK/m3.py")"

echo
echo "  pass=$pass fail=$fail"

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${pass:-0} + ${fail:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
[ "$fail" -eq 0 ] || exit 1
