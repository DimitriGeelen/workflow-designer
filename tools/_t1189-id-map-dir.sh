#!/bin/bash
# _t1189-id-map-dir.sh — T-1189: tools/_t1168-node-id-map.mjs --dir/--designer reproduce the T-1168 migration on a
# directory that is not 832's corpus, so the same tool can renumber another project's maps (AEF T-4224).
# Fixture: the corpus as it stood before the migration (a09c7e72^), split over two directory levels, run against the
# released designer-v0.20.0 artefact.
#   1. the table equals docs/reports/T-1168-node-id-map.md (every map, every old -> new pair)
#   2. --write renames in the --dir copy only, and each file is byte-identical to the committed migration (a09c7e72)
#   3. --check --dir then passes on the renamed copy
# Exit 0 = all legs pass, 1 = a leg failed, 2 = could not run.
cd "$(dirname "$0")/.." || exit 2
T=$(mktemp -d) || exit 2
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/maps/nested"
git show designer-v0.20.0:src/aef-workflow-designer.html > "$T/designer.html" || exit 2
for f in $(git ls-tree --name-only a09c7e72^ examples/aef-processes/rendered/ | grep '\.bpmn$'); do
    b=$(basename "$f"); case "$b" in t*) d="$T/maps/nested";; *) d="$T/maps";; esac
    git show "a09c7e72^:$f" > "$d/$b" || exit 2
done
fail=0
node tools/_t1168-node-id-map.mjs "$T/out.json" --dir "$T/maps" --designer "$T/designer.html" > "$T/run1" 2>&1 || { echo "CANNOT RUN: $(tail -1 "$T/run1")"; exit 2; }
if python3 - "$T/out.json" <<'PY'
import json, re, sys
rep, cur = {}, None
for ln in open("docs/reports/T-1168-node-id-map.md"):
    m = re.match(r"^## (\S+)", ln)
    if m: cur = m.group(1); rep[cur] = {}; continue
    m = re.match(r"^\| `([^`]+)` \| `([^`]+)` \|", ln)
    if m and cur: rep[cur][m.group(1)] = m.group(2)
maps = json.load(open(sys.argv[1]))["maps"]
new = {k.split("/")[-1]: v["map"] for k, v in maps.items()}
nested = sum("/" in k for k in maps)
diff = sorted(k for k in set(rep) | set(new) if rep.get(k) != new.get(k))
ok = len(rep) == 24 and not diff and nested > 0
print(("ok  " if ok else "FAIL") + f"  1. table equals the T-1168 report: {len(new)} maps ({nested} nested), "
      f"{sum(map(len, new.values()))} ids, differing: {diff or 'none'}")
sys.exit(0 if ok else 1)
PY
then :; else fail=1; fi
node tools/_t1168-node-id-map.mjs "$T/out2.json" --dir "$T/maps" --designer "$T/designer.html" --write > "$T/run2" 2>&1
n=0; total=0
for f in $(find "$T/maps" -name '*.bpmn'); do
    total=$((total+1))
    git show "a09c7e72:examples/aef-processes/rendered/$(basename "$f")" | cmp -s - "$f" || { n=$((n+1)); echo "      differs: $(basename "$f")"; }
done
if [ "$n" = 0 ] && [ "$total" = 24 ] && [ -z "$(git status --porcelain -- examples/aef-processes/rendered)" ]; then
    echo "ok    2. --write renamed the --dir copy only; $total/$total files byte-identical to the committed migration"
else echo "FAIL  2. --write: $n of $total files differ from a09c7e72, or 832's corpus was touched"; fail=1; fi
if node tools/_t1168-node-id-map.mjs --check --dir "$T/maps" --designer "$T/designer.html" > "$T/run3" 2>&1; then
    echo "ok    3. --check --dir passes on the renamed copy"
else echo "FAIL  3. --check --dir: $(tail -1 "$T/run3")"; fail=1; fi
[ "$fail" = 0 ] && echo "PASS: 3/3" || echo "FAIL"
exit "$fail"
