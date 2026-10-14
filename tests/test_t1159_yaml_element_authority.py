#!/usr/bin/env python3
"""T-1159 (OBS-436): the YAML form's IW-9 check applies T-888 clause 2, "the element carries its authority".

The XML form's `_check_iw9_authority` has let a node's own `<aef:meta authority=>` win over its lane since T-889;
the YAML twin read the lane only, so the two forms disagreed about the same map once a node stated an authority
its lane does not. Each case below is checked on BOTH forms, and they must agree:

  (a) inception, element `sovereignty`, lane `initiative`  -> O-3 passes (the element wins)
  (b) inception, element `initiative`, lane `sovereignty`  -> O-3 fails, and says the source is the element
  (c) inception, no element authority, lane `sovereignty`  -> O-3 passes (the lane is the fallback)
  (d) inception, no element authority, lane `initiative`   -> O-3 fails, source: its lane
  (e) serviceTask, element `authority` (agent), lane `sovereignty` (human) -> no O-1 mismatch (the element wins)
  (f) serviceTask, no element authority, lane `sovereignty` -> O-1 mismatch (lane fallback, unchanged)

Exit 0 = all agree and match the expectation; 1 = a case failed.
"""
import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_spec = importlib.util.spec_from_file_location("validate_workflow", os.path.join(ROOT, "tools", "validate-workflow.py"))
vw = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vw)

O3, O1 = "E-INCEPTION-NOT-SOVEREIGN", "W-TYPE-LANE-MISMATCH"


def yaml_map(ntype, lane_auth, elem_auth, extra_aef=""):
    aef = []
    if extra_aef:
        aef.append(extra_aef)
    if elem_auth:
        aef.append("authority: %s" % elem_auth)
    aef_block = ("    aef:\n" + "".join("      %s\n" % a for a in aef)) if aef else ""
    return (
        "workflowMeta: {id: t1159, version: 1, schemaVersion: 2}\n"
        "pool: {id: P, name: t1159}\n"
        "lanes:\n"
        "  - {id: L, name: L, abbr: lan, authority: %s, height: 200}\n"
        "nodes:\n"
        "  - uid: n1\n"
        "    type: %s\n"
        "    name: probe\n"
        "    slug: probe\n"
        "    lane: L\n"
        "    x: 100\n"
        "    y: 100\n"
        "%s"
        "edges: []\n"
    ) % (lane_auth, ntype, aef_block)


def xml_map(ntype, lane_auth, elem_auth, extra_attr=""):
    attrs = extra_attr + ((' authority="%s"' % elem_auth) if elem_auth else "")
    meta = "<aef:meta%s/>" % attrs if attrs else ""
    return (
        '<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" '
        'xmlns:aef="http://anchorpoint.framework/aef/extensions" id="D" targetNamespace="x">'
        '<bpmn:process id="P" isExecutable="true"><bpmn:laneSet id="LS">'
        '<bpmn:lane id="L"><bpmn:extensionElements><aef:laneMeta authority="%s"/></bpmn:extensionElements>'
        "<bpmn:flowNodeRef>n1</bpmn:flowNodeRef></bpmn:lane></bpmn:laneSet>"
        '<bpmn:%s id="n1" name="probe"><bpmn:extensionElements><aef:uid value="n1"/>%s'
        "</bpmn:extensionElements></bpmn:%s></bpmn:process></bpmn:definitions>"
    ) % (lane_auth, ntype, meta, ntype)


def findings(form, text, rule):
    run = vw.run_yaml if form == "yaml" else vw.run_xml
    return [f for f in run(text) if f.rule == rule]


CASES = [
    # label, type, lane authority, element authority, rule, expect fired, expected source word in message
    ("(a) inception: element sovereignty wins over an initiative lane", "subProcess", "initiative", "sovereignty", O3, False, None),
    ("(b) inception: element initiative wins over a sovereignty lane", "subProcess", "sovereignty", "initiative", O3, True, "the element"),
    ("(c) inception: no element authority, sovereignty lane passes", "subProcess", "sovereignty", None, O3, False, None),
    ("(d) inception: no element authority, initiative lane fails", "subProcess", "initiative", None, O3, True, "its lane"),
    ("(e) serviceTask: element authority (agent) wins over a sovereignty lane", "serviceTask", "sovereignty", "authority", O1, False, None),
    ("(f) serviceTask: no element authority, sovereignty lane mismatches", "serviceTask", "sovereignty", None, O1, True, None),
]


def main():
    fails = []
    for label, ntype, lane_auth, elem_auth, rule, expect, source in CASES:
        inception = ntype == "subProcess"
        y = findings("yaml", yaml_map(ntype, lane_auth, elem_auth, "workflowType: inception" if inception else ""), rule)
        x = findings("xml", xml_map(ntype, lane_auth, elem_auth, ' workflowType="inception"' if inception else ""), rule)
        got_y, got_x = bool(y), bool(x)
        ok = got_y == expect and got_x == expect
        if ok and source:
            ok = all(source in f.message for f in y + x)
        print("%s  %s   yaml=%s xml=%s (want %s)" % ("PASS" if ok else "FAIL", label, got_y, got_x, expect))
        if not ok:
            fails.append(label)
            for f in y + x:
                print("        ", f.rule, f.message[:150])
    print("%d/%d cases: YAML and XML agree on the element-wins rule" % (len(CASES) - len(fails), len(CASES)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
