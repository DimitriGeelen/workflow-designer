#!/usr/bin/env python3
"""yaml-to-bpmn — render a Workflow Designer canonical YAML file as BPMN-XML.

Part of the T-038 operator review surface (phase P2). The canonical corpus is
`*.workflow.yaml`, but the diagram editor (`src/aef-workflow-designer.html`)
reads BPMN-XML. This bridge emits the BPMN-XML form documented in
`docs/designer/schema.md` §7 — the same grammar the golden
`tests/fixtures/valid/investigate.bpmn` uses and that `tools/validate-workflow.py`
(XmlValidator) checks. The bridge is therefore *self-checking*: its output can be
fed straight back into the validator.

Layout note: the editor positions nodes from `aef:position` (x/y), not a standard
BPMN-DI section, so no DI is emitted.

Usage:
    python3 tools/yaml-to-bpmn.py INPUT.workflow.yaml [--out OUTPUT.bpmn]

With no --out, writes BPMN-XML to stdout. Exit 0 on success, 2 on error.
"""
import argparse
import sys
from xml.sax.saxutils import escape, quoteattr

import yaml

BPMN_NS = "http://www.omg.org/spec/BPMN/20100524/MODEL"
AEF_NS = "http://anchorpoint.framework/aef/extensions"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"

# YAML node `type` → BPMN element local name. Most map 1:1; link events differ
# (schema §7.2): a catch is an intermediateCatchEvent, a throw an
# intermediateThrowEvent.
TYPE_MAP = {
    "linkEventCatch": "intermediateCatchEvent",
    "linkEventThrow": "intermediateThrowEvent",
}

# aef: bag keys emitted as <aef:meta> attributes (scalars only). Others
# (decisionInput/decisionOutputs) get their own child elements below.
META_KEYS = ("determinism", "tier", "authority", "endpoint", "sideEffect",
             "timer", "multiInstance", "aggregation", "autoTriggerKind",
             "compensates", "restoresFrom", "compensationSnapshot",
             "compensatedBy", "advisory", "decisionOwner")


def _attr(value):
    """Escaped, quoted XML attribute value."""
    return quoteattr(str(value))


def bpmn_element_name(node_type):
    return TYPE_MAP.get(node_type, node_type)


def emit(workflow):
    meta = workflow.get("workflowMeta", {}) or {}
    pool = workflow.get("pool", {}) or {}
    lanes = workflow.get("lanes", []) or []
    nodes = workflow.get("nodes", []) or []
    edges = workflow.get("edges", []) or []

    wid = meta.get("id", pool.get("id", "workflow"))
    process_id = pool.get("id", "Pool_%s" % wid)
    process_name = pool.get("name", wid)

    # index edges per node for incoming/outgoing
    outgoing = {}
    incoming = {}
    for e in edges:
        if not isinstance(e, dict):
            continue
        src, tgt, euid = e.get("source"), e.get("target"), e.get("uid")
        if src is not None and euid is not None:
            outgoing.setdefault(src, []).append(euid)
        if tgt is not None and euid is not None:
            incoming.setdefault(tgt, []).append(euid)

    # nodes assigned per lane (flowNodeRef)
    lane_nodes = {}
    for n in nodes:
        if isinstance(n, dict) and "lane" in n and "uid" in n:
            lane_nodes.setdefault(n["lane"], []).append(n["uid"])

    out = []
    out.append('<?xml version="1.0" encoding="UTF-8"?>')
    out.append("<!-- Generated from %s by tools/yaml-to-bpmn.py. Do not edit by hand. -->"
               % escape(str(wid)))
    out.append('<bpmn:definitions')
    out.append('    xmlns:bpmn=%s' % _attr(BPMN_NS))
    out.append('    xmlns:aef=%s' % _attr(AEF_NS))
    out.append('    xmlns:xsi=%s>' % _attr(XSI_NS))
    out.append('  <bpmn:process id=%s name=%s>' % (_attr(process_id), _attr(process_name)))
    out.append('')

    # -- laneSet ---------------------------------------------------------
    out.append('    <bpmn:laneSet id=%s>' % _attr("LaneSet_%s" % wid))
    for lane in lanes:
        if not isinstance(lane, dict):
            continue
        lid = lane.get("id", "")
        out.append('      <bpmn:lane id=%s name=%s>'
                   % (_attr(lid), _attr(lane.get("name", lid))))
        out.append('        <bpmn:extensionElements>')
        out.append('          <aef:laneMeta abbr=%s authority=%s height=%s/>'
                   % (_attr(lane.get("abbr", "")),
                      _attr(lane.get("authority", "none")),
                      _attr(lane.get("height", 120))))
        out.append('        </bpmn:extensionElements>')
        for uid in lane_nodes.get(lid, []):
            out.append('        <bpmn:flowNodeRef>%s</bpmn:flowNodeRef>' % escape(str(uid)))
        out.append('      </bpmn:lane>')
    out.append('    </bpmn:laneSet>')
    out.append('')

    # -- nodes -----------------------------------------------------------
    for n in nodes:
        if not isinstance(n, dict):
            continue
        uid = n.get("uid", "")
        elem = bpmn_element_name(n.get("type", "task"))
        out.append('    <bpmn:%s id=%s name=%s>'
                   % (elem, _attr(uid), _attr(n.get("name", uid))))
        out.append('      <bpmn:extensionElements>')
        out.append('        <aef:uid value=%s/>' % _attr(uid))
        out.append('        <aef:position x=%s y=%s/>'
                   % (_attr(n.get("x", 0)), _attr(n.get("y", 0))))
        aef = n.get("aef", {}) or {}
        meta_attrs = " ".join('%s=%s' % (k, _attr(aef[k]))
                              for k in META_KEYS if k in aef and not isinstance(aef[k], (dict, list)))
        if meta_attrs:
            out.append('        <aef:meta %s/>' % meta_attrs)
        if "decisionInput" in aef:
            out.append('        <aef:decisionInput>%s</aef:decisionInput>'
                       % escape(str(aef["decisionInput"])))
        if "decisionOutputs" in aef:
            out.append('        <aef:decisionOutputs>%s</aef:decisionOutputs>'
                       % escape(str(aef["decisionOutputs"])))
        out.append('      </bpmn:extensionElements>')
        for fid in incoming.get(uid, []):
            out.append('      <bpmn:incoming>%s</bpmn:incoming>' % escape(str(fid)))
        for fid in outgoing.get(uid, []):
            out.append('      <bpmn:outgoing>%s</bpmn:outgoing>' % escape(str(fid)))
        out.append('    </bpmn:%s>' % elem)
    out.append('')

    # -- sequence flows --------------------------------------------------
    for e in edges:
        if not isinstance(e, dict):
            continue
        euid = e.get("uid", "")
        name = e.get("name")
        name_attr = (' name=%s' % _attr(name)) if name else ""
        out.append('    <bpmn:sequenceFlow id=%s%s sourceRef=%s targetRef=%s>'
                   % (_attr(euid), name_attr,
                      _attr(e.get("source", "")), _attr(e.get("target", ""))))
        out.append('      <bpmn:extensionElements><aef:uid value=%s/></bpmn:extensionElements>'
                   % _attr(euid))
        if e.get("condition"):
            out.append('      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">'
                       '%s</bpmn:conditionExpression>' % escape(str(e["condition"])))
        out.append('    </bpmn:sequenceFlow>')

    out.append('')
    out.append('  </bpmn:process>')
    out.append('</bpmn:definitions>')
    return "\n".join(out) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description="Render a workflow YAML file as BPMN-XML.")
    ap.add_argument("input", help="path to a *.workflow.yaml file")
    ap.add_argument("--out", help="output path (default: stdout)")
    args = ap.parse_args(argv)

    try:
        with open(args.input) as fh:
            workflow = yaml.safe_load(fh)
    except (OSError, yaml.YAMLError) as exc:
        sys.stderr.write("error: cannot read/parse %s: %s\n" % (args.input, exc))
        return 2
    if not isinstance(workflow, dict):
        sys.stderr.write("error: %s is not a workflow mapping\n" % args.input)
        return 2

    xml = emit(workflow)
    if args.out:
        try:
            with open(args.out, "w") as fh:
                fh.write(xml)
        except OSError as exc:
            sys.stderr.write("error: cannot write %s: %s\n" % (args.out, exc))
            return 2
    else:
        sys.stdout.write(xml)
    return 0


if __name__ == "__main__":
    sys.exit(main())
