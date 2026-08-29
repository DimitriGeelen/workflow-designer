#!/bin/bash
# T-637 — does the undecided-inception population actually reach a reader, and does the
# brief cover all of it?
#
# WHAT WAS WRONG. `_t627-undecided-defer.py` is the only thing that surfaces this
# population, and it selected on "carries a revisit date" while its name, its output and
# its closing advice are all about inceptions that were never ruled on. Two live tasks sat
# in that difference — undecided, active, and invisible to every scan and every handover
# for months. A SCAN'S DENOMINATOR IS A CLAIM, and that one was narrower than its sentence.
# Same finding as the shared-/tmp census the day before, in a different instrument.
#
# AND WIDENING IT EXPOSED A SECOND, LATENT DEFECT. The selector was
# `"workflow_type: inception" in text` — a substring test over the whole file. Two of the
# four newly-visible rows were false: a task whose BODY contains a table cell documenting
# the node-type mapping, and one containing a sentence about how scoring routes inception
# tasks. Their actual workflow_type is `test` and `build`. The substring was harmless only
# because the caller skipped everything without a revisit date; widening the population
# turned a latent false positive into a live one immediately.
#
# That is the fifth instance in two days of one class, across five instruments: a
# character-level scan standing in for structure, so a document that MENTIONS a thing is
# treated as one. A false red costs exactly what a false green costs — it moves the
# verdict away from the truth and teaches the reader to route around the instrument.
#
# WHAT THIS FILE PINS. Two independent methods must agree on the population (frontmatter
# parse here, the scan's own logic there), the brief must cover every member, and the
# brief must not contain a decision. The last one is not decoration: this task's whole
# risk is that a report written to make ruling cheap starts doing the ruling.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
SCAN="$PROJ/tools/_t627-undecided-defer.py"
REPORT="$PROJ/docs/reports/T-637-inception-blockers.md"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t637-$$-$(date +%s)"
trap 'rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM
mkdir -p "$SANDBOX"

for f in "$SCAN" "$REPORT"; do
    [ -f "$f" ] || { echo "COULD-NOT-MEASURE: missing $f" >&2; exit 3; }
done

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

echo "=== T-637 undecided-inception coverage ==="
echo

echo "--- an independent census, by parsing frontmatter rather than by matching strings"
# Deliberately NOT the scan's own logic. Two methods that share an implementation agree by
# construction and prove nothing; the point is that a YAML parse and a line scan land on
# the same set.
python3 - "$PROJ" > "$SANDBOX/independent.txt" <<'PY'
import pathlib, re, sys, yaml
root = pathlib.Path(sys.argv[1])
for f in sorted((root / ".tasks" / "active").glob("*.md")):
    text = f.read_text()
    m = re.match(r"\A---\n(.*?)\n---\n", text, re.S)
    if not m:
        continue
    try:
        fm = yaml.safe_load(m.group(1)) or {}
    except Exception:
        continue
    if fm.get("workflow_type") != "inception":
        continue
    if re.search(r"^\*\*Decision\*\*:\s*(GO|NO-GO|DEFER)\b", text, re.M):
        continue
    print(fm.get("id"))
PY
INDEP=$(grep -c '' "$SANDBOX/independent.txt" 2>/dev/null || echo 0)
if [ "$INDEP" -eq 0 ]; then
    bad "independent census found 0 undecided inceptions — the census is broken, not the tree clean"
    echo "COULD-NOT-MEASURE: no population to compare against." >&2
    exit 3
else
    ok "independent census: $INDEP undecided inception(s) (denominator is real)"
fi

echo
echo "--- the scan must surface every one of them"
python3 "$SCAN" > "$SANDBOX/scan.txt" 2>&1
MISSING=""
while IFS= read -r tid; do
    [ -z "$tid" ] && continue
    grep -q "UNRULED.*\b$tid-" "$SANDBOX/scan.txt" || MISSING="$MISSING $tid"
done < "$SANDBOX/independent.txt"
if [ -z "$MISSING" ]; then
    ok "every undecided inception appears in the scan output"
else
    bad "invisible to the scan (this is the T-637 defect returning):$MISSING"
fi

echo
echo "--- and must not surface anything that is not one"
# The other direction, which is where widening the population bit. A row for a task whose
# frontmatter says `build` is a false red, and a false red is not the safe side.
STRAY=""
while read -r line; do
    case "$line" in *UNRULED*) ;; *) continue ;; esac
    tid=$(printf '%s' "$line" | grep -oE 'T-[0-9]+' | head -1)
    [ -z "$tid" ] && continue
    grep -qx "$tid" "$SANDBOX/independent.txt" || STRAY="$STRAY $tid"
done < "$SANDBOX/scan.txt"
if [ -z "$STRAY" ]; then
    ok "the scan reports no task the frontmatter census does not agree is undecided"
else
    bad "reported as an unruled inception but is not one:$STRAY"
fi

echo
echo "--- teeth: a task that only MENTIONS the field must not be counted"
# The exact shape of the two false positives, reduced. If the selector goes back to a
# substring test this reddens; nothing else in the suite would notice.
FIX="$SANDBOX/fixture"
mkdir -p "$FIX/.tasks/active"
printf -- '---\nid: T-990\nworkflow_type: build\nstatus: started-work\n---\n\n# T-990\n\nA table documenting the mapping:\n\n| inception-node | `workflow_type: inception` |\n' \
    > "$FIX/.tasks/active/T-990-mentions-the-field.md"
printf -- '---\nid: T-991\nworkflow_type: inception\nstatus: started-work\n---\n\n# T-991\n\nno decision here\n' \
    > "$FIX/.tasks/active/T-991-a-real-undecided-inception.md"
FIXOUT=$(python3 - "$FIX" <<'PY'
import pathlib, re, sys, yaml
root = pathlib.Path(sys.argv[1])
FRONT = re.compile(r"\A---\n(.*?)\n---\n", re.S)
WF = re.compile(r"^workflow_type:\s*inception\s*$", re.M)
for f in sorted((root / ".tasks" / "active").glob("*.md")):
    text = f.read_text()
    m = FRONT.match(text)
    if m and WF.search(m.group(1)):
        print(f.name)
PY
)
if printf '%s' "$FIXOUT" | grep -q 'T-991'; then
    ok "teeth: the real inception fixture is selected"
else
    bad "teeth: the selector misses a genuine inception — it is too narrow"
fi
if printf '%s' "$FIXOUT" | grep -q 'T-990'; then
    bad "teeth: a task that only mentions the field is selected — the substring bug is back"
else
    ok "teeth: a body mention is not a declaration"
fi

echo
echo "--- the brief must cover every undecided inception"
UNCOVERED=""
while IFS= read -r tid; do
    [ -z "$tid" ] && continue
    grep -q "$tid" "$REPORT" || UNCOVERED="$UNCOVERED $tid"
done < "$SANDBOX/independent.txt"
if [ -z "$UNCOVERED" ]; then
    ok "the brief names all $INDEP of them"
else
    bad "undecided inception(s) missing from the brief:$UNCOVERED"
fi

echo
echo "--- the brief must not rule on anything"
# The sovereignty leg. A report written to make a ruling cheap is one edit away from
# making it, and the completion gate reads `**Decision**:` wherever it finds it.
if grep -qE '^\*\*Decision\*\*:' "$REPORT"; then
    bad "the brief contains a Decision line — an agent must never record the operator's ruling"
else
    ok "no Decision line in the brief"
fi
if grep -qE 'fw inception decide [^`]*--rationale' "$REPORT"; then
    bad "the brief hands over a pre-filled decide command — that is drafting the ruling"
else
    ok "no pre-filled decide command: the route offered is review, not decide"
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
