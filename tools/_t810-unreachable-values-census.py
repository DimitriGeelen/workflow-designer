#!/usr/bin/env python3
"""_t810-unreachable-values-census.py — authored corpus values the panel cannot show.

T-810, value review finding F-11.

THE SHAPE, recorded three times in this repo before this instrument existed:

    T-566   305 values   metaKeys vs AEF_FIELDS
    T-618   215 values   `determinism`, loaded and rendered nowhere
    F-11     17 values   `decisionOutputs` on exclusiveGateway

Each time it was found by a human reading files, and each time the remedy was specific to
the field that happened to be noticed. Nothing counted the general case, so the fourth
instance was always going to be found the same way. This counts it.

WHAT "UNREACHABLE" MEANS HERE, precisely: the corpus carries an <aef:FIELD> element on a
BPMN element whose editor node type does not list FIELD in AEF_FIELDS. The value survives
export (the emitters are type-agnostic, and T-570's carriage keeps unknown keys), so
nothing is destroyed — but the operator can neither see nor edit it. Invisible, not lost.

WHY IT READS THE EDITOR RATHER THAN A HAND-KEPT LIST: AEF_FIELDS is the panel's actual
source of truth. A copy of it here would drift, and a census that measures a stale copy of
the thing it audits is the defect it is auditing (PL-181: a coverage fraction whose
denominator is hand-typed is self-referential).

NOT A GATE. It prints a census and exits 0 whether or not values are unreachable. Whether
a given field SHOULD be offered on a given type is a design judgement — `emits` on a
startEvent would be meaningless, and the AEF_FIELDS comment says as much. This tells you
where authored values are stranded; a human decides which of those are mistakes.

Exit: 0 census produced | 1 could not measure
"""

import glob
import os
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from typing import NoReturn

AEF_NS = "{http://anchorpoint.framework/aef/extensions}"

REPO_ROOT = os.environ.get(
    "T810_REPO_ROOT",
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
)
SRC = os.path.join(REPO_ROOT, "src", "aef-workflow-designer.html")
CORPUS_GLOB = os.path.join(REPO_ROOT, "examples", "aef-processes", "rendered", "*.bpmn")

# BPMN element name -> editor node type. The editor's own type vocabulary differs from
# BPMN's for events (eventTimer vs the timerEventDefinition child), so only the
# unambiguous 1:1 cases are mapped. An unmapped element is REPORTED as unmapped rather
# than silently dropped — a census that quietly skips what it cannot classify reports a
# smaller number than the truth and looks healthier for it.
BPMN_TO_EDITOR = {
    "task": "serviceTask",       # bare task renders with the task-like schema
    "serviceTask": "serviceTask",
    "userTask": "userTask",
    "scriptTask": "scriptTask",
    "subProcess": "subProcess",
    "exclusiveGateway": "exclusiveGateway",
    "parallelGateway": "parallelGateway",
    "startEvent": "startEvent",
    "endEvent": "endEvent",
}

# Extension children that are structural rather than authored property values — they have
# their own channels and no panel field is expected.
STRUCTURAL = {"uid", "position", "anchors", "laneMeta", "workflowMeta", "meta",
              "eventDef", "link", "io", "constituent", "constituents"}


def die(msg) -> NoReturn:
    print(f"CANNOT MEASURE: {msg}", file=sys.stderr)
    sys.exit(1)


def parse_aef_fields(src_path):
    """Read AEF_FIELDS out of the editor source — the panel's real source of truth."""
    if not os.path.exists(src_path):
        die(f"editor source not found: {src_path}")
    text = open(src_path, encoding="utf-8").read()
    start = text.find("const AEF_FIELDS = {")
    if start == -1:
        die("AEF_FIELDS declaration not found in src. Either it was renamed — in which "
            "case this census is blind and that is a failure, not a pass — or the file "
            "is not the editor.")
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                block = text[start:i + 1]
                break
    else:
        die("AEF_FIELDS block never closes — refusing to guess where it ends")

    fields = {}
    for m in re.finditer(r"(\w+)\s*:\s*\[([^\]]*)\]", block):
        node_type = m.group(1)
        keys = re.findall(r"'([^']+)'", m.group(2))
        fields[node_type] = keys
    if not fields:
        die("parsed the AEF_FIELDS block and extracted ZERO node types — the shape "
            "changed and this parser no longer matches it")
    return fields


def main():
    aef_fields = parse_aef_fields(SRC)
    files = sorted(glob.glob(CORPUS_GLOB))
    if not files:
        die(f"no corpus documents matched {CORPUS_GLOB}")

    # (field, bpmn_type) -> count
    reachable = defaultdict(int)
    unreachable = defaultdict(int)
    unmapped = defaultdict(int)
    total_values = 0
    # T-836: the unreachable set splits by CARRIER SHAPE, and the shape is what decides
    # whether a repair is a one-line AEF_FIELDS edit or a field design.
    #
    # This started as a content-vs-empty split on a claim that 6 of the 30 were empty
    # elements. THAT CLAIM WAS FALSE and the first version of this code encoded it: it
    # tested text and attributes and never tested CHILD ELEMENTS, so it reported
    # <aef:emits><aef:emit value="pass"/>…</aef:emits> as empty. Measured: 30 of 30 carry
    # content, 0 are empty. The honest instrument is not "is there content" — that answer
    # is always yes — but "what shape is it", because a text carrier can go in a text
    # field and a child-element carrier cannot.
    unreachable_carrier = defaultdict(int)   # (field, bpmn_type, shape) -> count

    for path in files:
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError as e:
            die(f"{os.path.basename(path)} does not parse: {e}")

        # Walk elements, find their extensionElements child, classify each aef child.
        for el in root.iter():
            ext = None
            for child in list(el):
                if child.tag.split("}")[-1] == "extensionElements":
                    ext = child
                    break
            if ext is None:
                continue
            bpmn_type = el.tag.split("}")[-1]
            for c in list(ext):
                if not c.tag.startswith(AEF_NS):
                    continue
                field = c.tag.split("}")[-1]
                if field in STRUCTURAL:
                    continue
                total_values += 1
                editor_type = BPMN_TO_EDITOR.get(bpmn_type)
                if editor_type is None:
                    unmapped[(field, bpmn_type)] += 1
                elif field in aef_fields.get(editor_type, []):
                    reachable[(field, bpmn_type)] += 1
                else:
                    unreachable[(field, bpmn_type)] += 1
                    # All three carriers are live in this corpus and each was found only by
                    # looking: text (endpoint), attributes (aggregation over=/reduce=,
                    # multiInstance over=, timer kind=/cycle=/anchor=) and child elements
                    # (emits -> <aef:emit value=…>, compensates -> <aef:compensate ref=…>).
                    # Testing only the first two reports the child-carriers as empty.
                    shapes = []
                    if (c.text or "").strip():
                        shapes.append("text")
                    if c.attrib:
                        shapes.append("attrs")
                    if len(list(c)):
                        shapes.append("children")
                    unreachable_carrier[(field, bpmn_type, "+".join(shapes) or "EMPTY")] += 1

    if total_values == 0:
        die("parsed the corpus and found ZERO authored aef values — either the corpus is "
            "empty or the namespace/STRUCTURAL filter no longer matches reality")

    n_unreachable = sum(unreachable.values())
    print("=== T-810 unreachable authored-value census (F-11) ===")
    print(f"corpus: {len(files)} document(s), {total_values} authored aef value(s)")
    print(f"reachable in panel: {sum(reachable.values())}   "
          f"UNREACHABLE: {n_unreachable}   unmapped node type: {sum(unmapped.values())}")
    print()

    if unreachable:
        print("UNREACHABLE — authored in the corpus, not offered by the panel on that type:")
        for (field, btype), n in sorted(unreachable.items(), key=lambda x: (-x[1], x[0])):
            print(f"  {field:<18} on {btype:<20} {n:>3}")
        print()
    else:
        print("no unreachable authored values.")
        print()

    if unmapped:
        print("node types this census cannot map to an editor type (reported, not hidden):")
        for (field, btype), n in sorted(unmapped.items(), key=lambda x: (-x[1], x[0])):
            print(f"  {field:<18} on {btype:<20} {n:>3}")
        print()

    # T-836: carrier shapes, printed after the existing blocks so every pre-existing line
    # is byte-identical and anything parsing them keeps working.
    by_shape = defaultdict(int)
    for (field, btype, shape), n in unreachable_carrier.items():
        by_shape[shape] += n

    if unreachable_carrier:
        print("CARRIER SHAPE of the unreachable values — what the repair has to hold:")
        for (field, btype, shape), n in sorted(unreachable_carrier.items(),
                                               key=lambda x: (-x[1], x[0][0])):
            print(f"  {field:<18} on {btype:<20} {n:>3}   carrier: {shape}")
        print("  text     → a text field can hold it; an AEF_FIELDS entry may suffice.")
        print("  attrs    → multi-key payload; needs a field definition, not a list edit.")
        print("  children → repeated sub-elements; a scalar text field would misrepresent")
        print("             it and may destroy it on save.")
        print()

    n_empty = by_shape.get("EMPTY", 0)
    shape_summary = ", ".join(f"{s}={by_shape[s]}" for s in sorted(by_shape))
    print(f"of the {n_unreachable} unreachable, by carrier: {shape_summary}")
    print(f"TOTAL_UNREACHABLE={n_unreachable}")
    print(f"UNREACHABLE_EMPTY={n_empty}")
    for s in ("text", "attrs", "children"):
        print(f"UNREACHABLE_CARRIER_{s.upper()}={by_shape.get(s, 0)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
