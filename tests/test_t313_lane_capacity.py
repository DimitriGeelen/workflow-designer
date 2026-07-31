#!/usr/bin/env python3
"""Lane capacity rule (T-313) — tests for W-XML-LANE-CAPACITY.

Mirrors AEF's `tools/corpus_lint.py::lane_overflow` (their T-2689). Ordering
compares lanes against each other; capacity asks whether a lane can contain its
OWN members. The two are independent — a map can be perfectly ordered and still
draw half a lane past its own band edge.

Three things here are load-bearing and easy to get wrong:

  1. Occupancy is NOT height. A 48px gateway occupies 66 and a 64px task
     occupies 64, so the smallest shape is not the smallest occupant.
  2. The lowest node is found by BOTTOM EDGE, not by y. AEF's counterexample:
     a gateway at y=199 reaches 265 while a task at y=200 reaches 264.
  3. The gate is containment (`extent > height`), NOT the Clean fixpoint. Lanes
     that fit-but-are-untidy are deliberately excluded, and that exclusion is
     pinned here so nobody "fixes" the divergence with AEF's rule later.

Runnable standalone: `python3 tests/test_t313_lane_capacity.py` (exit 0 = pass).
"""

import importlib.util
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURES = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn")
DESIGNER = os.path.join(ROOT, "src", "aef-workflow-designer.html")

_spec = importlib.util.spec_from_file_location(
    "validate_workflow", os.path.join(ROOT, "tools", "validate-workflow.py")
)
vw = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vw)

RULE = "W-XML-LANE-CAPACITY"
SKIP_RULE = "I-XML-LANE-CAPACITY-SKIP"

# Read defensively so this module reports FAILURES rather than crashing when run
# against a build that predates the rule — a teeth run (PL-061) is only readable
# if every assertion gets to speak.
FIT_MARGIN = getattr(vw, "LANE_FIT_MARGIN", None)
OCCUPANCY = getattr(vw, "NODE_OCCUPANCY", {})

BPMN_HEAD = (
    '<bpmn:definitions '
    'xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" '
    'xmlns:aef="http://anchorpoint.framework/aef/extensions" '
    'id="D" targetNamespace="x">'
    '<bpmn:process id="P" isExecutable="true">'
)
BPMN_TAIL = "</bpmn:process></bpmn:definitions>"

failures = []


def check(condition, label, detail=""):
    if condition:
        print("  [PASS] %s" % label)
    else:
        print("  [FAIL] %s%s" % (label, (" -- " + detail) if detail else ""))
        failures.append(label)


def lane(lid, refs, height="200"):
    refs_xml = "".join("<bpmn:flowNodeRef>%s</bpmn:flowNodeRef>" % r for r in refs)
    meta = (
        ""
        if height is None
        else '<bpmn:extensionElements><aef:laneMeta authority="initiative" '
        'height="%s"/></bpmn:extensionElements>' % height
    )
    return '<bpmn:lane id="%s">%s%s</bpmn:lane>' % (lid, meta, refs_xml)


def node(nid, y, tag="serviceTask"):
    pos = "" if y is None else '<aef:position x="100.0" y="%s"/>' % y
    return (
        '<bpmn:%s id="%s"><bpmn:extensionElements>'
        '<aef:uid value="u_%s"/>%s'
        "</bpmn:extensionElements></bpmn:%s>" % (tag, nid, nid, pos, tag)
    )


def build(lanes_xml, nodes_xml):
    return (
        BPMN_HEAD
        + '<bpmn:laneSet id="LS">'
        + "".join(lanes_xml)
        + "</bpmn:laneSet>"
        + "".join(nodes_xml)
        + BPMN_TAIL
    )


def findings(xml, rule=RULE):
    return [f for f in vw.run_xml(xml) if f.rule == rule]


def one_lane(nodes_spec, height="200"):
    """A single lane of (id, y, tag) triples with the given declared height."""
    ids = [n[0] for n in nodes_spec]
    return build(
        [lane("solo", ids, height)],
        [node(nid, y, tag) for nid, y, tag in nodes_spec],
    )


def read_fixture(name):
    with open(os.path.join(FIXTURES, name)) as fh:
        return fh.read()


print("== containment: the rule fires only when the band cannot hold its content ==")

# task at y=100 occupies 64 -> bottom 164; task at y=200 -> bottom 264.
# extent = 264 - 100 = 164.
check(
    findings(one_lane([("a", 100, "serviceTask"), ("b", 200, "serviceTask")], "200"))
    == [],
    "extent 164 inside a declared 200 -> no finding",
)
check(
    findings(one_lane([("a", 100, "serviceTask"), ("b", 200, "serviceTask")], "164"))
    == [],
    "extent EXACTLY equal to the height is contained (gate is strict)",
)
f = findings(one_lane([("a", 100, "serviceTask"), ("b", 200, "serviceTask")], "163"))
check(len(f) == 1, "extent one px over the height -> fires")
check(
    bool(f) and "spilling 1 px" in f[0].message,
    "the spill is reported in px",
    f[0].message if f else "",
)

print("== occupancy is not height ==")

# A single 48px gateway at y=0 occupies 66 because its label draws below it.
check(
    len(findings(one_lane([("g", 100, "exclusiveGateway")], "65"))) == 1,
    "a lone 48px gateway needs 66, not 48 (label allowance)",
)
check(
    findings(one_lane([("g", 100, "exclusiveGateway")], "66")) == [],
    "...and exactly 66 contains it",
)
check(
    findings(one_lane([("t", 100, "serviceTask")], "64")) == [],
    "a 64px task needs exactly 64 (no label allowance)",
)
check(
    len(findings(one_lane([("e", 100, "startEvent")], "53"))) == 1
    and findings(one_lane([("e", 100, "startEvent")], "54")) == [],
    "a 36px event occupies 54 — MORE than its height, less than a task",
)

print("== the lowest node is found by bottom edge, not by y (AEF rail 341) ==")

# Their counterexample, exactly: gateway y=199 -> 265, task y=200 -> 264.
xml = one_lane([("gate", 199, "exclusiveGateway"), ("task", 200, "serviceTask")], "60")
f = findings(xml)
check(len(f) == 1, "the mixed-type lane fires")
check(
    bool(f) and "'gate'" in f[0].message and "'task'" not in f[0].message,
    "the GATEWAY at the smaller y is named, not the task at the larger y",
    f[0].message if f else "",
)
check(
    bool(f) and "bottom edge 265" in f[0].message,
    "...and its bottom edge (265) is what defined the extent",
)
# A largest-y sort would compute extent from the task: 264 - 199 = 65.
# The correct answer is 265 - 199 = 66.
check(
    bool(f) and "member extent 66" in f[0].message,
    "the extent is 66 (bottom-edge sort), not 65 (largest-y sort)",
    f[0].message if f else "",
)

print("== DELIBERATE DIVERGENCE from the Clean fixpoint — do not 'fix' this ==")

# AEF gate on containment; so do we. Their aef-task-lifecycle agent lane
# (h=200, extent=194, fixpoint wants 218) and aef-inception-flow agent lane
# (h=220, extent=204, fixpoint wants 228) contain their content while missing the
# fixpoint. Both rules agree to stay silent. Their reason, adopted: a lint that
# reports tidiness as breakage trains people to ignore it — tidiness is the
# mapMessiness nudge's job (T-102), not this rule's.
# Deleting either case below is what "fixing" the divergence would look like.
for height, extent, label in ((200, 194, "task-lifecycle"), (220, 204, "inception-flow")):
    top = 100
    bottom_node_y = top + extent - 64  # a task, so occupancy 64
    xml = one_lane(
        [("top", top, "serviceTask"), ("bot", bottom_node_y, "serviceTask")],
        str(height),
    )
    check(
        findings(xml) == [],
        "fit-but-untidy stays SILENT: %s shape (h=%d, extent=%d, fixpoint wants %d)"
        % (label, height, extent, extent + 2 * (FIT_MARGIN or 12)),
    )
check(
    FIT_MARGIN == 12,
    "LANE_FIT_MARGIN mirrors the renderer constant (src:6966)",
)

print("== SKIP, not PASS, and the scope guard that keeps it quiet ==")

xml = one_lane([("a", 100, "serviceTask"), ("b", None, "serviceTask")], "50")
check(findings(xml) == [], "an unpositioned member yields no violation")
skips = findings(xml, SKIP_RULE)
check(len(skips) == 1, "...and emits a SKIP note instead")
check(
    bool(skips) and "not passed by it" in skips[0].message,
    "the note says SKIPPED, not passed",
    skips[0].message if skips else "",
)
check(
    bool(skips) and skips[0].severity == getattr(vw, "INFO", "INFO") and vw.exit_code(vw.run_xml(xml)) == 0,
    "the SKIP note is INFO and does not fail the map",
)

# Scope guard (AEF adopted this from T-312 and kept it verbatim): a lane with no
# members or no declared height makes NO containment claim. Out of scope, not
# unevaluable. Without this, every hand-authored heightless fixture gains a
# permanent unresolvable note.
xml = build([lane("empty", [], "200"), lane("solo", ["a"], "200")], [node("a", 100)])
check(
    findings(xml) == [] and findings(xml, SKIP_RULE) == [],
    "a lane with no members is out of scope — silent, no note",
)
xml = one_lane([("a", 100, "serviceTask"), ("b", 900, "serviceTask")], None)
check(
    findings(xml) == [] and findings(xml, SKIP_RULE) == [],
    "a lane with no declared height is out of scope — silent, even when it would spill",
)

xml = build(
    [lane("solo", ["a", "x"], "50")],
    [node("a", 100), '<bpmn:transaction id="x"><bpmn:extensionElements>'
     '<aef:position x="1.0" y="200.0"/></bpmn:extensionElements></bpmn:transaction>'],
)
check(
    findings(xml) == [] and len(findings(xml, SKIP_RULE)) == 1,
    "an unknown node type SKIPs the lane rather than guessing an occupancy",
)

print("== coverage: the occupancy table cannot silently fall behind the palette ==")

src = open(DESIGNER).read()


def _block(marker, opener="{"):
    i = src.index(marker)
    depth = 0
    for j in range(i, len(src)):
        if src[j] == opener:
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                return src[i : j + 1]
    return ""


defaults_src = _block("const NODE_DEFAULTS = {")
tagmap_src = _block("const TYPE_TAG = {")
heights = {
    m.group(1): int(m.group(2))
    for m in re.finditer(r"(\w+):\s*\{[^}]*?\bh:\s*(\d+)", defaults_src)
}
tags = {m.group(1): m.group(2) for m in re.finditer(r"(\w+):\s*'([\w]+)'", tagmap_src)}
check(len(heights) >= 11, "NODE_DEFAULTS parsed from src (%d types)" % len(heights))
check(len(tags) >= 11, "TYPE_TAG parsed from src (%d types)" % len(tags))


def label_below(t):
    # src:6970-6972 — mirrored, not guessed
    return (
        t in ("startEvent", "endEvent", "linkEventThrow", "linkEventCatch")
        or t.startswith("event")
        or t.endswith("Gateway")
    )


derived = {}
conflicts = []
for typ, h in heights.items():
    tag = tags.get(typ)
    if tag is None:
        continue
    occ = h + (18 if label_below(typ) else 0)
    if tag in derived and derived[tag] != occ:
        conflicts.append((tag, derived[tag], occ))
    derived[tag] = occ
# typed events additionally serialise to bpmn:boundaryEvent when attached to a
# host (src:9403); they share the 36px event footprint.
derived["boundaryEvent"] = heights["eventError"] + 18

check(not conflicts, "no two designer types map to one tag with different occupancy",
      str(conflicts))
missing = sorted(t for t in derived if t not in OCCUPANCY)
check(not missing, "every exportable BPMN tag has an occupancy entry", str(missing))
wrong = sorted(
    "%s: table=%s derived=%s" % (t, OCCUPANCY[t], derived[t])
    for t in derived
    if t in OCCUPANCY and OCCUPANCY[t] != derived[t]
)
check(not wrong, "the occupancy table matches the renderer's own constants", str(wrong))
check(
    derived.get("exclusiveGateway", 0) > derived.get("serviceTask", 0),
    "derived from source, a gateway really does outrank a task (66 > 64)",
    str({k: derived.get(k) for k in ("exclusiveGateway", "serviceTask")}),
)

print("== composition with the ordering rule (T-312) ==")

# Bands tile the axis, so heights are the only free variable: a containing set of
# heights exists iff the lanes are already ordered. The repair hint must say which
# world it is in, because advising a height change on an out-of-order map is
# advice that cannot work.
ordered = build(
    [lane("up", ["u"], "10"), lane("lo", ["l"], "400")],
    [node("u", 100), node("l", 300)],
)
f = findings(ordered)
check(
    len(f) == 1 and "ZERO node movement" in f[0].message,
    "ordering-clean overflow -> repair is a pure height change",
    f[0].message if f else "",
)
inverted = build(
    [lane("up", ["u"], "10"), lane("lo", ["l"], "400")],
    [node("u", 300), node("l", 100)],
)
f = findings(inverted)
check(
    len(f) == 1 and "no set of lane heights can contain them" in f[0].message,
    "ordering-dirty overflow -> repair says fix the ordering first",
    f[0].message if f else "",
)
check(
    len([x for x in vw.run_xml(inverted) if x.rule == "W-XML-LANE-GEOMETRY"]) == 1,
    "...and the ordering rule is indeed firing on that map",
)

print("== fixtures: both live shapes AEF measured ==")

f = findings(read_fixture("lane-capacity-large-spill.bpmn"))
check(
    len(f) == 1 and "declared height 260" in f[0].message,
    "large spill fixture fires on the agent lane",
    f[0].message if f else "",
)
check(
    bool(f) and "member extent 567" in f[0].message and "spilling 307 px" in f[0].message,
    "...reproducing AEF's knowledge-leveling numbers exactly (567 / 307)",
)
check(
    bool(f) and "'agt_2_wait'" in f[0].message,
    "...and naming the lowest-drawn member",
)

with open(os.path.join(ROOT, "tests", "fixtures", "warn", "W-XML-LANE-CAPACITY.xml")) as fh:
    small = fh.read()
f = findings(small)
check(
    len(f) == 1 and "'agt_1_gate'" in f[0].message,
    "small-spill fixture names the GATEWAY, the node a height-only table misses",
    f[0].message if f else "",
)
check(
    findings(small, "W-XML-LANE-GEOMETRY") == [],
    "...and that fixture is ordering-CLEAN, so it isolates capacity from ordering",
)

print()
if failures:
    print("== FAILED: %d assertion(s) ==" % len(failures))
    for name in failures:
        print("   - %s" % name)
    sys.exit(1)
print("== all lane-capacity assertions passed ==")
