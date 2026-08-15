#!/usr/bin/env python3
"""
Reads every aef:uid out of a BPMN document WITH ITS STRUCTURAL CONTEXT, using a conforming
parser (expat, via xml.etree).

Sibling of tools/_t520-xml-read.py and it exists for the same reason: when verifying a seam,
the reader must be the class of reader on the far side, because the producer's own parser will
happily agree with the producer's own defect. T-520 measured that concretely — the editor
emitted a raw newline inside an attribute, Chrome's DOMParser handed it back unchanged, and a
full round-trip looked byte-identical while every conforming consumer read a space.

What this one adds over _t520-xml-read.py is the ANCESTRY. T-523 asks what happens to a node
nested inside a <bpmn:subProcess>, and "the uid is still present somewhere in the document" is
not an answer to that: a uid that survives while its containment is flattened is a different
outcome from one that survives intact, and both differ from one that is dropped. A reader that
returns a flat list of values cannot tell those three apart, so it would report the interesting
cases as identical to the boring one.

Per uid it reports:
  value        the attribute value, as a conforming parser sees it
  owner        localname of the element the uid belongs to (the uid sits inside that element's
               <bpmn:extensionElements>, so the owner is that wrapper's parent)
  path         localnames from the document root down to the owner, inclusive
  in_sub       whether any ancestor of the owner is a subProcess

Also reports `flow_children_by_parent`: for each subProcess, how many BPMN flow-node children
it directly contains. That is the containment fact itself, independent of uids — needed because
a document can lose the children while keeping the subProcess, and the uid list alone cannot
distinguish "the child was dropped" from "the child was moved out".

And `flows`: every sequenceFlow with its source, target and nesting. Added after the first
measured run, which showed nested nodes being HOISTED to process level rather than dropped. The
immediate next question a reader asks is whether the flow that connected them came with them —
because two surviving nodes that arrive disconnected is a different and quieter loss than two
nodes that do not arrive at all. Reporting the node outcome without the edge outcome would
have answered half a question and read as if it answered all of it.

Exits 0 ALWAYS. An unparseable document is a RESULT that the caller classifies — one of the
outcomes under test — not a failure of the reader. Anything else would make "the editor emitted
garbage" indistinguishable from "the reader broke".
"""

import json
import sys
import xml.etree.ElementTree as ET

AEF = "http://anchorpoint.framework/aef/extensions"
BPMN = "http://www.omg.org/spec/BPMN/20100524/MODEL"

# BPMN flow NODES (not flows, not artifacts, not structure). Used only to count containment;
# an unknown tag is simply not counted, which is the conservative direction here.
FLOW_NODES = {
    "startEvent", "endEvent", "task", "serviceTask", "userTask", "scriptTask",
    "manualTask", "businessRuleTask", "sendTask", "receiveTask", "callActivity",
    "subProcess", "transaction", "adHocSubProcess",
    "exclusiveGateway", "parallelGateway", "inclusiveGateway", "complexGateway",
    "eventBasedGateway", "intermediateThrowEvent", "intermediateCatchEvent",
    "boundaryEvent",
}


def local(tag):
    return tag.rsplit("}", 1)[-1] if "}" in tag else tag


def main():
    raw = sys.stdin.buffer.read()
    try:
        root = ET.fromstring(raw)
    except Exception as e:  # noqa: BLE001 — any parse failure is the same RESULT to the caller
        print(json.dumps({"parsed": False, "error": str(e), "uids": [],
                          "flow_children_by_parent": {}, "flows": []}))
        return

    uids = []
    containment = {}
    flows = []

    def walk(el, ancestors, ancestor_els):
        tag = local(el.tag)
        here = ancestors + [tag]
        here_els = ancestor_els + [el]

        if el.tag == "{%s}uid" % AEF:
            # ancestors is the chain down to (and including) the element that holds this uid.
            # Strip the extensionElements wrapper to name the real owner.
            chain = [a for a in ancestors]
            strip = bool(chain) and chain[-1] == "extensionElements"
            owner_chain = chain[:-1] if strip else chain
            owner_els = ancestor_els[:-1] if strip else ancestor_els
            uids.append({
                "value": el.get("value"),
                "owner": owner_chain[-1] if owner_chain else None,
                # The owner's element id, needed to ask whether a surviving flow still
                # connects the same two nodes: ids are re-minted on every save (T-513), so
                # the uid is the only stable handle and the id has to be resolved through it.
                "owner_id": owner_els[-1].get("id") if owner_els else None,
                "path": owner_chain,
                # The uid's own element is not an ancestor of itself; ask about the owner.
                "in_sub": "subProcess" in owner_chain[:-1],
            })

        if tag == "sequenceFlow":
            flows.append({
                "id": el.get("id"),
                "source": el.get("sourceRef"),
                "target": el.get("targetRef"),
                "in_sub": "subProcess" in ancestors,
            })

        if tag == "subProcess":
            sub_id = el.get("id") or "<no-id>"
            containment[sub_id] = sum(
                1 for c in el if local(c.tag) in FLOW_NODES
            )

        for child in el:
            walk(child, here, here_els)

    walk(root, [], [])
    print(json.dumps({
        "parsed": True,
        "error": None,
        "uids": uids,
        "flow_children_by_parent": containment,
        "flows": flows,
    }))


main()
