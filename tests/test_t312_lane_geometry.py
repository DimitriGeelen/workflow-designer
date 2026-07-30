#!/usr/bin/env python3
"""Lane/geometry agreement rule (T-312) — tests for W-XML-LANE-GEOMETRY.

The rule mirrors AEF's `fw corpus lint::lane_geometry`. The predicate was
settled jointly on the integration rail (offset 339) and adopted verbatim:

  For lanes in laneSet DECLARATION order, the y-ranges of nodes grouped by
  DECLARED lane must be strictly ordered and non-overlapping. Evaluate only
  when >=2 lanes, >=2 lanes populated, and EVERY node positioned; otherwise
  SKIP (do not pass). Report per violating ADJACENT lane pair, naming the
  extremal witness pair. Equal y counts as a crossing. Crossing counts split
  the repair: 100% of both sides => wholesale inversion => laneSet reorder;
  a subset => placement or stale membership => authority call.

Both-ways coverage: every "fires" case has a mirror that must stay quiet, so
the rule is proven able to go red AND able to stay green (PL-061 — a green
that cannot go red is not evidence).

Runnable standalone: `python3 tests/test_t312_lane_geometry.py`
(exit 0 = pass), matching the repo's other test scripts.
"""

import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURES = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn")

_spec = importlib.util.spec_from_file_location(
    "validate_workflow", os.path.join(ROOT, "tools", "validate-workflow.py")
)
vw = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vw)

RULE = "W-XML-LANE-GEOMETRY"
SKIP_RULE = "I-XML-LANE-GEOMETRY-SKIP"

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


def lane(lid, refs):
    refs_xml = "".join("<bpmn:flowNodeRef>%s</bpmn:flowNodeRef>" % r for r in refs)
    return '<bpmn:lane id="%s">%s</bpmn:lane>' % (lid, refs_xml)


def node(nid, y, tag="serviceTask"):
    """A flow node with an <aef:position>; y=None means no position element."""
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


def two_lane(upper_ys, lower_ys):
    """Two declared lanes, 'up' above 'lo', with the given node y values."""
    up_ids = ["up_%d" % i for i in range(len(upper_ys))]
    lo_ids = ["lo_%d" % i for i in range(len(lower_ys))]
    return build(
        [lane("up", up_ids), lane("lo", lo_ids)],
        [node(n, y) for n, y in zip(up_ids, upper_ys)]
        + [node(n, y) for n, y in zip(lo_ids, lower_ys)],
    )


def read_fixture(name):
    with open(os.path.join(FIXTURES, name)) as fh:
        return fh.read()


print("== agreement: the rule stays quiet when geometry matches declaration ==")

check(
    findings(two_lane([100, 120], [300, 320])) == [],
    "declared order matches drawn order -> no finding",
)
check(
    findings(two_lane([100], [101])) == [],
    "a 1px gap is still strictly ordered -> no finding",
)
check(
    findings(
        build(
            [lane("a", ["a0"]), lane("b", ["b0"]), lane("c", ["c0"])],
            [node("a0", 100), node("b0", 200), node("c0", 300)],
        )
    )
    == [],
    "three lanes in order -> no finding",
)

print("== disagreement: the rule fires, with the right witness pair ==")

f = findings(two_lane([100, 300], [200]))
check(len(f) == 1, "overlapping ranges -> exactly one finding")
check(
    bool(f) and "'up_1'" in f[0].message and "'lo_0'" in f[0].message,
    "witness pair is the upper lane's LOWEST and the lower lane's HIGHEST node",
    f[0].message if f else "",
)
check(
    bool(f) and "up_0" not in f[0].message,
    "non-extremal nodes are not named (a witness pair, not a node list)",
)
check(
    bool(f) and f[0].location == "lane 'up' -> lane 'lo'",
    "location names the adjacent lane pair",
)

f = findings(two_lane([100], [100]))
check(len(f) == 1, "equal y counts as a crossing (one row cannot be two bands)")

print("== repair shape is driven by crossing counts ==")

f = findings(two_lane([300, 310], [100, 110]))
check(
    bool(f) and "wholesale inversion" in f[0].message,
    "100% of both sides crossing -> wholesale inversion",
    f[0].message if f else "",
)
check(
    bool(f) and "2/2 and 2/2" in f[0].message,
    "wholesale case reports full crossing counts on both sides",
)
check(
    bool(f) and "zero-semantic" in f[0].message,
    "wholesale repair is named as a laneSet reorder (zero-semantic)",
)

f = findings(two_lane([100, 300], [200, 400]))
check(
    bool(f) and "authority call, not a layout call" in f[0].message,
    "a subset crossing -> authority call, not a layout call",
    f[0].message if f else "",
)
check(
    bool(f) and "wholesale" not in f[0].message,
    "a subset crossing is NOT reported as a wholesale inversion",
)

print("== per adjacent pair, and only adjacent pairs ==")

f = findings(
    build(
        [lane("a", ["a0"]), lane("b", ["b0"]), lane("c", ["c0"])],
        [node("a0", 300), node("b0", 200), node("c0", 100)],
    )
)
check(len(f) == 2, "three fully inverted lanes -> 2 adjacent-pair findings, not 3")
check(
    {x.location for x in f}
    == {"lane 'a' -> lane 'b'", "lane 'b' -> lane 'c'"},
    "findings are reported on adjacent pairs (a->b, b->c)",
)

f = findings(
    build(
        [lane("a", ["a0"]), lane("b", []), lane("c", ["c0"])],
        [node("a0", 300), node("c0", 100)],
    )
)
check(
    len(f) == 1 and f[0].location == "lane 'a' -> lane 'c'",
    "an empty lane between two populated ones does not break adjacency",
)

print("== SKIP, not PASS: unevaluable maps must not report clean ==")

xml = two_lane([100, None], [300])
check(findings(xml) == [], "a map with an unpositioned node emits no violation")
skips = findings(xml, SKIP_RULE)
check(len(skips) == 1, "...and emits a SKIP note instead")
check(
    bool(skips) and "not passed by it" in skips[0].message,
    "the note says SKIPPED, not passed",
    skips[0].message if skips else "",
)
check(
    bool(skips) and skips[0].severity == vw.INFO,
    "the SKIP note is INFO severity",
)
check(
    vw.exit_code(vw.run_xml(xml)) == 0,
    "a SKIP note does not turn a clean map into a failing one",
)

# y=0 is the designer's sentinel for "no position was encoded" (src:9710-9713,
# patched to the lane centre at src:9805). Treating it as a real coordinate
# would invent geometry AND would fire a bogus violation on every hand-authored
# map, since every node would sit at y=0.
xml = two_lane([0, 0], [0])
check(
    findings(xml) == [] and len(findings(xml, SKIP_RULE)) == 1,
    "y=0 reads as the unpositioned sentinel, not as a coordinate at the top",
)

check(
    findings(build([lane("a", ["a0", "a1"])], [node("a0", 300), node("a1", 100)]))
    == [],
    "a single lane makes no ordering claim -> out of scope, silent",
)
check(
    findings(build([lane("a", ["a0", "a1"])], [node("a0", 300), node("a1", 100)]), SKIP_RULE)
    == [],
    "...and a single-lane map does not emit a SKIP note either (noise, not signal)",
)
check(
    findings(
        build(
            [lane("a", ["a0"]), lane("b", [])],
            [node("a0", 300)],
        )
    )
    == [],
    "one populated lane + one empty lane -> out of scope, silent",
)

print("== origin-free: no band reconstruction from cumulative heights ==")

# AEF anchored bands at the topmost node and produced 7 phantom mismatches on a
# map that is clean under this predicate. The guard: a map whose lanes are in
# order stays clean no matter how large the gap between them, because no band
# edge is ever computed. A height-walking implementation would place the second
# lane's band well above y=5000 and report a false violation.
check(
    findings(two_lane([100, 140], [5000, 5040])) == [],
    "a huge inter-lane gap is still clean (bands are never reconstructed)",
)
src = open(os.path.join(ROOT, "tools", "validate-workflow.py")).read()
start = src.find("def _check_lane_geometry")
end = src.find("def _check_iw9_authority")
geom = src[start:end] if 0 <= start < end else ""
check(
    bool(geom)
    and "height"
    not in geom.replace("lane heights", "").replace("cumulative lane heights", ""),
    "the implementation never reads a lane height attribute",
    "rule body not found" if not geom else "found a height read in the rule body",
)

print("== fixtures: all three observed shapes ==")

f = findings(read_fixture("lane-position-conflict.bpmn"))
check(
    len(f) == 1 and "agt_2_act" in f[0].message and "frw_1_check" in f[0].message,
    "shape 3 (two-node swap, T-310 fixture) fires on exactly the known pair",
    f[0].message if f else "",
)
check(
    bool(f) and "authority call" in f[0].message,
    "...and is classified as an authority call",
)

f = findings(read_fixture("lane-geometry-partial-overflow.bpmn"))
check(
    len(f) == 1 and "hum_2_gate" in f[0].message and "agt_3_pick" in f[0].message,
    "shape 2 (partial overflow, the promoted-map shape) fires with its witness pair",
    f[0].message if f else "",
)
check(
    bool(f) and "1/2 and 1/4" in f[0].message,
    "...with subset crossing counts, not a wholesale inversion",
)

f = findings(read_fixture("lane-geometry-unpositioned.bpmn"))
check(f == [], "the unpositioned fixture reports no violation")
check(
    len(findings(read_fixture("lane-geometry-unpositioned.bpmn"), SKIP_RULE)) == 1,
    "...and is SKIPPED with a note",
)

with open(
    os.path.join(ROOT, "tests", "fixtures", "warn", "W-XML-LANE-GEOMETRY.xml")
) as fh:
    f = findings(fh.read())
check(
    len(f) == 1 and "wholesale inversion" in f[0].message,
    "shape 1 (wholesale inversion) fires and is classified for a laneSet reorder",
    f[0].message if f else "",
)

print("== the naive check this rule beats ==")

# A summary-statistic check (compare lane centroids or medians) reports the
# partial-overflow fixture clean. That is why the predicate compares extrema.
lanes_ys = {"human": [100.0, 110.0], "agent": [105.0, 115.0, 120.0, 400.0]}
centroids = [sum(v) / len(v) for v in lanes_ys.values()]
medians = [sorted(v)[len(v) // 2] for v in lanes_ys.values()]
check(
    centroids == sorted(centroids) and medians == sorted(medians),
    "centroid- and median-ordered checks BOTH pass the partial-overflow fixture",
    "%s / %s" % (centroids, medians),
)
check(
    len(findings(read_fixture("lane-geometry-partial-overflow.bpmn"))) == 1,
    "...while the extremal predicate catches it",
)

print()
if failures:
    print("== FAILED: %d assertion(s) ==" % len(failures))
    for name in failures:
        print("   - %s" % name)
    sys.exit(1)
print("== all lane-geometry assertions passed ==")
