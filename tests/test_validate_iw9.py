#!/usr/bin/env python3
"""IW-9 v1.1 validator-enforcement tests (T-196).

Covers the two BPMN-form rules added to tools/validate-workflow.py when the
IW-9/G-3 deltas graduated to v1.1 (mapping-v1 §3/§7):

  O-3  E-INCEPTION-NOT-SOVEREIGN (ERROR) — a subProcess carrying
       aef:meta workflowType="inception" MUST be in a lane whose
       aef:laneMeta authority="sovereignty".
  O-1  W-TYPE-LANE-MISMATCH (WARN) — a userTask/serviceTask/scriptTask whose
       task-type-implied performer disagrees with the lane authority collapse.

Runnable standalone: `python3 tests/test_validate_iw9.py` (exit 0 = pass,
non-zero = failure), matching the repo's other test scripts.
"""

import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURES = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn")

# tools/validate-workflow.py has a hyphen — load it by path.
_spec = importlib.util.spec_from_file_location(
    "validate_workflow", os.path.join(ROOT, "tools", "validate-workflow.py")
)
vw = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vw)


def rules(text):
    return {f.rule for f in vw.run_xml(text)}


def read_fixture(name):
    with open(os.path.join(FIXTURES, name)) as fh:
        return fh.read()


BPMN_HEAD = (
    '<bpmn:definitions '
    'xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" '
    'xmlns:aef="http://anchorpoint.framework/aef/extensions" '
    'id="D" targetNamespace="x">'
    '<bpmn:process id="P" isExecutable="true">'
)
BPMN_TAIL = "</bpmn:process></bpmn:definitions>"


def lane(lid, authority, refs):
    refs_xml = "".join("<bpmn:flowNodeRef>%s</bpmn:flowNodeRef>" % r for r in refs)
    return (
        '<bpmn:lane id="%s"><bpmn:extensionElements>'
        '<aef:laneMeta authority="%s"/></bpmn:extensionElements>%s</bpmn:lane>'
        % (lid, authority, refs_xml)
    )


def failures():
    fails = []

    # (a) real corpus positive: inception-gonogo is sovereignty-laned → no O-3 error
    got = rules(read_fixture("inception-gonogo.bpmn"))
    if "E-INCEPTION-NOT-SOVEREIGN" in got:
        fails.append("(a) inception-gonogo.bpmn wrongly flagged E-INCEPTION-NOT-SOVEREIGN")

    # (b) crafted negative: inception in a NON-sovereignty (initiative) lane → O-3 ERROR
    bad = (
        BPMN_HEAD
        + '<bpmn:laneSet id="LS">'
        + lane("agent", "initiative", ["sp1"])
        + "</bpmn:laneSet>"
        + '<bpmn:subProcess id="sp1" name="bad inception">'
        '<bpmn:extensionElements><aef:meta workflowType="inception"/>'
        "</bpmn:extensionElements></bpmn:subProcess>"
        + BPMN_TAIL
    )
    if "E-INCEPTION-NOT-SOVEREIGN" not in rules(bad):
        fails.append("(b) inception in initiative lane NOT flagged E-INCEPTION-NOT-SOVEREIGN")

    # (b2) inception in a sovereignty lane → no O-3 error
    good = (
        BPMN_HEAD
        + '<bpmn:laneSet id="LS">'
        + lane("human", "sovereignty", ["sp1"])
        + "</bpmn:laneSet>"
        + '<bpmn:subProcess id="sp1" name="good inception">'
        '<bpmn:extensionElements><aef:meta workflowType="inception"/>'
        "</bpmn:extensionElements></bpmn:subProcess>"
        + BPMN_TAIL
    )
    if "E-INCEPTION-NOT-SOVEREIGN" in rules(good):
        fails.append("(b2) inception in sovereignty lane wrongly flagged O-3")

    # (c) serviceTask (→agent) in a sovereignty (→human) lane → O-1 WARN
    mismatch = (
        BPMN_HEAD
        + '<bpmn:laneSet id="LS">'
        + lane("human", "sovereignty", ["st1"])
        + "</bpmn:laneSet>"
        + '<bpmn:serviceTask id="st1" name="svc"><bpmn:extensionElements>'
        '<aef:uid value="u1"/></bpmn:extensionElements></bpmn:serviceTask>'
        + BPMN_TAIL
    )
    if "W-TYPE-LANE-MISMATCH" not in rules(mismatch):
        fails.append("(c) serviceTask in sovereignty lane NOT flagged W-TYPE-LANE-MISMATCH")

    # (c2) scriptTask (→agent) in an authority (→agent) lane → NO mismatch
    agree = (
        BPMN_HEAD
        + '<bpmn:laneSet id="LS">'
        + lane("framework", "authority", ["sc1"])
        + "</bpmn:laneSet>"
        + '<bpmn:scriptTask id="sc1" name="scr"><bpmn:extensionElements>'
        '<aef:uid value="u2"/></bpmn:extensionElements></bpmn:scriptTask>'
        + BPMN_TAIL
    )
    if "W-TYPE-LANE-MISMATCH" in rules(agree):
        fails.append("(c2) scriptTask in authority lane wrongly flagged W-TYPE-LANE-MISMATCH")

    # (d) real corpus: resume-status has no inception → no O-3 finding
    got = rules(read_fixture("resume-status.bpmn"))
    if "E-INCEPTION-NOT-SOVEREIGN" in got:
        fails.append("(d) resume-status.bpmn (no inception) wrongly flagged O-3")

    # ---- absent-authority family (T-199) -----------------------------------
    # mapping-v1 §3 (IW-9 v1.1) makes aef:laneMeta@authority the SOLE
    # authority-of-record. So "no authority" is NOT a softer case than "wrong
    # authority" — it is the same failure: §7's MUST is unmet. 832 issued this
    # reading to AEF as a conformance ruling (rail offset 49, vetoing their
    # name-only-Human leniency); these cases GUARD the ruling rather than
    # leaving it asserted-only (PL-034: a promise with no guard).
    #
    # Case (h) is the one that was actually broken: _check_iw9_authority opened
    # with `if lane_set is None: return`, so the single diagram carrying no human
    # signal whatsoever was the only diagram that passed — leaving 832's
    # reference validator MORE lenient than AEF's compiler, which already
    # fail-fasts there.
    inception_sp = (
        '<bpmn:subProcess id="sp1" name="inception">'
        '<bpmn:extensionElements><aef:meta workflowType="inception"/>'
        "</bpmn:extensionElements></bpmn:subProcess>"
    )

    def laneset(inner):
        return '<bpmn:laneSet id="LS">%s</bpmn:laneSet>' % inner

    absent_authority_cases = {
        # (f) lane NAMED "Human" but carrying no laneMeta — a name is a string a
        #     human typed, not a governance assertion. English-only name-matching
        #     is exactly the lock-in laneMeta exists to prevent (Directive 4).
        "f/name-only-Human-lane": laneset(
            '<bpmn:lane id="l1" name="Human">'
            "<bpmn:flowNodeRef>sp1</bpmn:flowNodeRef></bpmn:lane>"
        ),
        # (g) laneMeta present but no @authority attribute
        "g/laneMeta-without-authority": laneset(
            '<bpmn:lane id="l1" name="Human"><bpmn:extensionElements>'
            '<aef:laneMeta abbr="hum"/></bpmn:extensionElements>'
            "<bpmn:flowNodeRef>sp1</bpmn:flowNodeRef></bpmn:lane>"
        ),
        # (h) NO laneSet at all — the regression this task fixes
        "h/no-laneSet-at-all": "",
        # (i) authority="external" — a real authority, but not sovereignty
        "i/authority-external": laneset(
            '<bpmn:lane id="l1" name="Outside"><bpmn:extensionElements>'
            '<aef:laneMeta authority="external"/></bpmn:extensionElements>'
            "<bpmn:flowNodeRef>sp1</bpmn:flowNodeRef></bpmn:lane>"
        ),
        # (j) lanes exist and are sovereignty, but the inception is in NONE of them
        "j/inception-outside-every-lane": laneset(
            '<bpmn:lane id="l1" name="Human"><bpmn:extensionElements>'
            '<aef:laneMeta authority="sovereignty"/></bpmn:extensionElements>'
            "<bpmn:flowNodeRef>someone_else</bpmn:flowNodeRef></bpmn:lane>"
        ),
    }
    for label, lane_xml in absent_authority_cases.items():
        xml = BPMN_HEAD + lane_xml + inception_sp + BPMN_TAIL
        if "E-INCEPTION-NOT-SOVEREIGN" not in rules(xml):
            fails.append(
                "(%s) inception with no sovereignty authority-of-record was "
                "ACCEPTED — O-3 not enforced" % label
            )

    # (k) the message must name the CAUSE (absent vs wrong), not just the verdict
    no_lane_xml = BPMN_HEAD + inception_sp + BPMN_TAIL
    msgs = [
        f.message for f in vw.run_xml(no_lane_xml)
        if f.rule == "E-INCEPTION-NOT-SOVEREIGN"
    ]
    if not any("absent" in m for m in msgs):
        fails.append(
            "(k) absent-authority block message does not name the cause "
            "('absent'); got: %r" % msgs
        )

    # (l) O-1 must stay quiet when there is no laneSet: absent authority is not a
    #     disagreement. Widening O-3 must not spray WARNs over lane-less diagrams.
    lane_less_task = (
        BPMN_HEAD
        + '<bpmn:serviceTask id="st9" name="svc"><bpmn:extensionElements>'
        '<aef:uid value="u9"/></bpmn:extensionElements></bpmn:serviceTask>'
        + BPMN_TAIL
    )
    if "W-TYPE-LANE-MISMATCH" in rules(lane_less_task):
        fails.append(
            "(l) serviceTask in a laneSet-less process wrongly flagged "
            "W-TYPE-LANE-MISMATCH — absent authority is not a mismatch"
        )

    return fails


def main():
    fails = failures()
    if fails:
        for f in fails:
            sys.stderr.write("FAIL: %s\n" % f)
        return 1
    print("OK: IW-9 validator rules (O-1 W-TYPE-LANE-MISMATCH, O-3 "
          "E-INCEPTION-NOT-SOVEREIGN) — 14 checks pass, incl. the full "
          "absent-authority family (T-199)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
