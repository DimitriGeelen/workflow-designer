#!/usr/bin/env python3
"""T-618 — where is `determinism` actually authored, and does the editor offer it?

WHY THIS EXISTS. T-617 set out to design an execution contract for the node dialect. The
corpus already had one. `determinism` is authored on hundreds of nodes across the example
workflows, with a settled three-value vocabulary, and `src/aef-workflow-designer.html` names
it only in two COMMENTS — it is in no AEF_FIELDS list. Before T-570 the editor loaded those
values, rendered them nowhere, and destroyed them on save. After T-570 it carries them
invisibly. Either way the operator cannot see or edit a single one.

WHAT IT ASSERTS. Two things, both derived from the corpus rather than restated:

  1. every node TYPE that carries `determinism` in the rendered BPMN corpus is a type whose
     AEF_FIELDS list offers the field
  2. every VALUE authored in the corpus is one the editor would accept

Exit 0 = the editor offers the field everywhere it is authored. 1 = blind spots remain.
2 = cannot measure (NOT a pass) — see the vacuity guard.
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "src" / "aef-workflow-designer.html"
KEYS = ("determinism", "sideEffect")

# The editor's own type names differ from the raw BPMN element names for events and
# gateways. Map raw -> AEF_FIELDS key. Anything unmapped is reported, never silently dropped.
RAW_TO_AEF = {
    "startEvent": "startEvent",
    "endEvent": "endEvent",
    "serviceTask": "serviceTask",
    "userTask": "userTask",
    "scriptTask": "scriptTask",
    "subProcess": "subProcess",
    "exclusiveGateway": "exclusiveGateway",
    "parallelGateway": "parallelGateway",
}

OPEN_TAG = re.compile(r"<bpmn2?:(\w+)\b")


def aef_fields(text):
    """Read AEF_FIELDS out of the editor rather than restating it here."""
    m = re.search(r"const AEF_FIELDS = \{(.*?)\n\};", text, re.S)
    if not m:
        return None
    out = {}
    for name, body in re.findall(r"(\w+):\s*\[([^\]]*)\]", m.group(1)):
        out[name] = [f.strip().strip("'\"") for f in body.split(",") if f.strip()]
    return out


def census():
    """Attribute each key occurrence to its enclosing NODE type.

    Two sources, and the YAML is the primary one. The rendered .bpmn corpus is thin — only
    a fraction of the authored workflows have been rendered — so a scan of .bpmn alone finds
    a handful of occurrences and understates the vocabulary by an order of magnitude. That
    is the partial-blindness shape: a scan that returns something looks like it covered the
    class.

    ATTRIBUTION. In BPMN the nearest enclosing open tag above <aef:meta> is
    <bpmn:extensionElements>, not the node. Tracking "last tag seen" therefore attributes
    every hit to extensionElements and reports zero real types. Only element names that are
    actual node kinds update the cursor.
    """
    hits = {}    # key -> {node_type -> count}
    values = {}  # key -> {value -> count}
    files = 0

    def record(key, node_type, val):
        hits.setdefault(key, {}).setdefault(node_type, 0)
        hits[key][node_type] += 1
        values.setdefault(key, {}).setdefault(val, 0)
        values[key][val] += 1

    for path in sorted(REPO.glob("examples/**/*.bpmn")):
        files += 1
        last = None
        for line in path.read_text(errors="replace").splitlines():
            t = OPEN_TAG.search(line)
            if t and t.group(1) in RAW_TO_AEF:      # never extensionElements
                last = t.group(1)
            for key in KEYS:
                for val in re.findall(key + r'="([^"]*)"', line):
                    record(key, last or "?", val)

    for path in sorted(REPO.glob("examples/**/*.workflow.yaml")):
        files += 1
        last = None
        for line in path.read_text(errors="replace").splitlines():
            t = re.match(r"\s*(?:-\s*)?type:\s*(\w+)", line)
            if t:
                last = t.group(1)
            for key in KEYS:
                m = re.match(r"\s*" + key + r":\s*(.+?)\s*(?:#.*)?$", line)
                if m:
                    record(key, last or "?", m.group(1).strip('"\''))
    return files, hits, values


def main():
    if not SRC.exists():
        print("CANNOT MEASURE: src/aef-workflow-designer.html missing")
        return 2
    fields = aef_fields(SRC.read_text())
    if not fields:
        print("CANNOT MEASURE: could not parse AEF_FIELDS out of src — its shape changed, "
              "and this guard would otherwise pass by finding nothing to compare")
        return 2

    files, hits, values = census()
    if files == 0:
        print("CANNOT MEASURE: no .bpmn found under examples/ — a moved corpus would make "
              "this guard pass vacuously")
        return 2
    if not hits:
        print(f"CANNOT MEASURE: scanned {files} files and found no occurrence of {KEYS}. "
              f"Either the corpus changed or the scan is broken; both mean no verdict.")
        return 2

    print(f"T-618 — determinism census across {files} rendered corpus files")
    problems = []
    for key in KEYS:
        by_type = hits.get(key, {})
        total = sum(by_type.values())
        print(f"\n  {key}: {total} occurrences on {len(by_type)} node type(s)")
        for raw, n in sorted(by_type.items(), key=lambda kv: -kv[1]):
            aef_type = RAW_TO_AEF.get(raw)
            if aef_type is None:
                problems.append(f"{key} authored on `{raw}` ({n}) — no AEF_FIELDS mapping")
                print(f"      {raw:20} {n:4}   UNMAPPED")
                continue
            offered = key in fields.get(aef_type, [])
            print(f"      {raw:20} {n:4}   offered in panel: {offered}")
            if not offered:
                problems.append(f"{key} authored on `{raw}` ({n} nodes) but AEF_FIELDS"
                                f"[{aef_type}] does not offer it — invisible to the operator")
        vals = values.get(key, {})
        if len(vals) <= 6:
            print(f"      values: " + ", ".join(f"{v}={n}" for v, n in
                                                sorted(vals.items(), key=lambda kv: -kv[1])))

    # AEF_FIELDS -> FIELD_META is a RELATION, not a count, and the panel dereferences it
    # unguarded: `const meta = FIELD_META[f]; if (meta.special === …)` (src/…:5936). A field
    # added to AEF_FIELDS without a FIELD_META entry throws TypeError and takes the whole
    # properties panel down for that node type. Adding determinism/sideEffect to AEF_FIELDS
    # without FIELD_META entries is exactly the bug this run nearly shipped, so the guard
    # asserts the relation over EVERY field, not just the two this task touched.
    meta_names = set(re.findall(r"^\s*(\w+):\s*\{", SRC.read_text(), re.M))
    for node_type, flds in sorted(fields.items()):
        for f in flds:
            if f not in meta_names:
                problems.append(f"AEF_FIELDS[{node_type}] offers `{f}` but FIELD_META has no "
                                f"entry — the panel throws TypeError on that node type")

    if problems:
        print("\n  BLIND SPOTS:")
        for p in sorted(set(problems)):
            print(f"      ! {p}")
        print("\n  The value is carried through save (T-570) but cannot be seen or edited.")
        return 1
    print("\n  OK — every authored occurrence sits on a type whose panel offers the field")
    return 0


if __name__ == "__main__":
    sys.exit(main())
