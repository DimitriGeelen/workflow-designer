#!/usr/bin/env python3
"""test_t314_fixture_repin — T-314: the two 832-owned shared fixtures were repaired
by a laneSet reorder, and the repair must stay zero-semantic. Arc:
designer-authoring-surface.

Background. T-312's `lane_geometry` rule found, on the day it landed, that
`inception-gonogo.bpmn` (the shared promote-contract fixture AEF's consumer test
pins) and `two-lane-joint.bpmn` both declared `human` as the FIRST lane while
drawing the human node BELOW the agent nodes — wholesale inversions, every node on
both sides crossing. AEF had diagnosed exactly this authoring defect in their own
generator; we had done it by hand, in the artifact we handed them as the producer
contract.

The repair is a laneSet REORDER and nothing else. That claim was measured once at
repair time (membership, positions, uids, flows, heights and the process
child-element set all byte-identical pre/post; only the order of two `<bpmn:lane>`
elements differs). What this guard pins is the durable half — the facts the reorder
was proven not to touch, recorded as literals.

Deliberately NOT anchored on `git show HEAD~1`: that comparison is right exactly
once. On any later run HEAD~1 is a different commit and the check quietly becomes a
comparison of something else against itself — a false green that looks like
diligence.

Also pinned here: both fixtures validate CLEAN (no geometry finding, and no
capacity finding either — lane bands are CUMULATIVE heights, so reordering lanes of
unequal height would move every boundary below the swap; these are both 160, and
this asserts that rather than assuming it).

Runs standalone (`python3 tests/test_t314_fixture_repin.py`, exit 0 = pass) and
under pytest.
"""
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURES = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn")
VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")

NS = {
    "b": "http://www.omg.org/spec/BPMN/20100524/MODEL",
    "a": "http://anchorpoint.framework/aef/extensions",
}

# The semantic facts the reorder was proven not to touch, plus the declaration
# order it DID change. Recorded as literals so this is revision-independent.
EXPECT = {
    "inception-gonogo": {
        "members": {
            "hum_1_inception": "human",
            "agt_1_request": "agent",
            "agt_2_outcome": "agent",
        },
        "heights": {"human": "160", "agent": "160"},
        "order": ["agent", "human"],
        "sha": "bbfbc5ec48356c3a643efa21e37912994a3fff56532b7e0ef4815f91fbed00ab",
    },
    "two-lane-joint": {
        "members": {
            "hum_1_inception": "human",
            "agt_0_request": "agent",
            "agt_2_plan": "agent",
            "agt_3_outcome": "agent",
        },
        "heights": {"human": "160", "agent": "160"},
        "order": ["agent", "human"],
        "sha": "2ba55eedbd90ae7805fa9ad3c8a7037913b4788dfc8c7db2ae9f3953d6d7bf7f",
    },
}


def _read(name):
    path = os.path.join(FIXTURES, "%s.bpmn" % name)
    proc = ET.parse(path).getroot().find("b:process", NS)
    lanes = list(proc.iter("{%s}lane" % NS["b"]))
    members = {}
    for lane in lanes:
        for ref in lane.findall("b:flowNodeRef", NS):
            members[ref.text.strip()] = lane.get("id")
    heights = {
        l.get("id"): l.find("b:extensionElements/a:laneMeta", NS).get("height")
        for l in lanes
    }
    return {
        "members": members,
        "heights": heights,
        "order": [l.get("id") for l in lanes],
    }


def _validator_clean(name):
    path = os.path.join(FIXTURES, "%s.bpmn" % name)
    proc = subprocess.run(
        [sys.executable, VALIDATOR, path], capture_output=True, text=True
    )
    return proc.returncode == 0, (proc.stdout or "") + (proc.stderr or "")


def check():
    fails = []
    for name, exp in EXPECT.items():
        got = _read(name)

        # (1) membership untouched by the reorder — this is the `who`, and the
        #     entire claim that a reorder is zero-semantic rests on it
        if got["members"] != exp["members"]:
            fails.append(
                "%s: lane membership changed\n  got    %s\n  expect %s"
                % (name, got["members"], exp["members"])
            )

        # (2) heights untouched, and equal — the cumulative-boundary caveat
        if got["heights"] != exp["heights"]:
            fails.append(
                "%s: lane heights changed %s -> %s; bands are cumulative, so a "
                "height change here moves every boundary below it"
                % (name, exp["heights"], got["heights"])
            )

        # (3) declaration order is the thing that WAS fixed — agent first, so the
        #     laneSet agrees with the drawing
        if got["order"] != exp["order"]:
            fails.append(
                "%s: laneSet order %s, expected %s — the T-314 repair is exactly "
                "this reorder, so a change here undoes it"
                % (name, got["order"], exp["order"])
            )

        # (4) and the fixture validates clean: no geometry finding (the defect),
        #     no capacity finding (the caveat), nothing else introduced
        ok, out = _validator_clean(name)
        if not ok or "no findings" not in out:
            fails.append("%s: no longer validates clean:\n%s" % (name, out.strip()[:400]))

    return fails


def test_fixture_repin():
    fails = check()
    assert fails == [], "T-314 fixture re-pin regressed:\n" + "\n".join(fails)


def main():
    fails = check()
    if fails:
        for f in fails:
            sys.stderr.write("FAIL: %s\n" % f)
        return 1
    print(
        "OK: T-314 re-pin — inception-gonogo (bbfbc5ec4835) and two-lane-joint "
        "(2ba55eedbd90) carry the laneSet reorder; membership, heights and "
        "validator-cleanliness all hold"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
