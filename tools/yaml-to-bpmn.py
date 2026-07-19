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
    # T-204: typed intermediate events (error/timer/message) all carry the neutral
    # intermediateCatchEvent tag; the kind is carried by <aef:eventDef kind=..> so
    # the tag alone never disambiguates (same reason the editor branches on the
    # extension on import). Mirrors the editor TYPE_TAG.
    "eventError": "intermediateCatchEvent",
    "eventTimer": "intermediateCatchEvent",
    "eventMessage": "intermediateCatchEvent",
}

# T-204: typed intermediate events. The kind is derived from the node TYPE (not an
# aef key); the binding is a kind-specific aef scalar. These mirror the editor's
# EVENT_KIND / EVENT_BINDING_FIELD (src/aef-workflow-designer.html) so both producers
# emit byte-identical <aef:eventDef kind=.. binding=..> — kept honest by
# tests/test_bridge_aef_passthrough.py.
EVENT_KIND = {"eventError": "error", "eventTimer": "timer", "eventMessage": "message"}
EVENT_BINDING_FIELD = {"eventError": "errorStatus", "eventTimer": "timerSpec",
                       "eventMessage": "busTopic"}

# aef: bag keys emitted as <aef:meta> attributes (scalars only). Others
# (decisionInput/decisionOutputs) get their own child elements below.
META_KEYS = ("determinism", "tier", "authority", "endpoint", "sideEffect",
             "autoTriggerKind",
             "restoresFrom", "compensationSnapshot",
             "compensatedBy", "advisory", "decisionOwner",
             # T-060: keys the editor's own aef:meta writer emits
             # (src/aef-workflow-designer.html metaKeys) — kept in parity by
             # tests/test_editor_bridge_meta_parity.py.
             "agentType", "triggeredBy",
             # T-062: recurring scalar keys the authored corpus already used
             # (surfaced by the T-061 loud-drop WARN). Promoted from silent
             # drops to first-class vocabulary; mirrored in the editor's
             # metaKeys for round-trip. See docs/reports/T-062-*.md for the
             # promote-vs-x-* rationale.
             "terminalKind", "state", "note", "softFail", "section", "guard",
             "external", "exitCode", "autoTrigger", "trigger", "gatewayKind",
             "gate",
             # T-081: scopeOf — a subProcess node marking itself as the
             # collapsed scope/body of another node (FC-15 boundary marker).
             # Scalar node-uid back-reference; validator checks it resolves.
             "scopeOf",
             # T-177: task-governance scalars — horizon / workflow_type / owner.
             # Mirrored in the editor's metaKeys for round-trip; kept in parity
             # by tests/test_editor_bridge_meta_parity.py.
             "horizon", "workflowType", "owner")

# T-061 (FC-13): the full set of aef.* keys the bridge handles with dedicated
# emit logic. Any aef key NOT in here and NOT under the aef.x-* extension prefix
# is an unknown key: it is dropped, but LOUDLY (a stderr WARN), never silently.
# This closes the "free-form passthrough is a closed whitelist" gap — the
# namespace is a known vocabulary PLUS an explicit x- passthrough channel.
EXT_PREFIX = "x-"

# T-063: aef keys with a structured (dict/list) value get their own dedicated
# child element (like io/decisionInput) instead of the scalar <aef:meta>
# attribute channel. Moved off META_KEYS so the T-062 structured-value WARN does
# not fire for them; the editor reads AND re-writes these (round-trip), kept in
# parity by tests/test_editor_bridge_structured_parity.py.
#   - list-valued  → a wrapper element with one child per item
#   - dict-valued  → a single element carrying one attribute per field
STRUCTURED_LIST_KEYS = {
    "emits": ("emits", "emit", "value"),        # <aef:emits><aef:emit value=".."/>
    "compensates": ("compensates", "compensate", "ref"),
}
STRUCTURED_DICT_KEYS = ("aggregation", "multiInstance", "timer")

# T-081: aef keys whose value is a LIST OF DICTS — wrapper element with one
# child per item, one attribute per (present) field. Third structured shape
# next to the scalar-list and dict channels above; same editor-parity contract
# (tests/test_editor_bridge_structured_parity.py).
#   constituents — FC-11: what a collapsed composite node is composed of.
#     Entries: {id, name, ref?}. Legal on ANY flow node (collapses happen on
#     gateways too); the subProcess node type is the task-like composite host.
STRUCTURED_ITEMLIST_KEYS = {
    "constituents": ("constituents", "constituent", ("id", "name", "ref")),
}

KNOWN_AEF_KEYS = frozenset(META_KEYS) | frozenset((
    "decisionInput", "decisionOutputs",
    "contextReads", "artifactsWrites",
    "targetWorkflow", "linkId",
    # T-204: typed-event binding scalars — consumed by the <aef:eventDef> branch
    # (keyed on node type), so they are "handled" and must not trip the loud-drop.
    "errorStatus", "timerSpec", "busTopic",
)) | frozenset(STRUCTURED_LIST_KEYS) | frozenset(STRUCTURED_DICT_KEYS) \
  | frozenset(STRUCTURED_ITEMLIST_KEYS)


def _attr(value):
    """Escaped, quoted XML attribute value."""
    return quoteattr(str(value))


def _scalarize(value):
    """A dict-field value may itself be a list (e.g. aggregation.outputs). Join
    lists to a comma string so they ride a single attribute; scalars pass through."""
    if isinstance(value, list):
        return ", ".join(str(v) for v in value)
    return str(value)


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
        meta_pairs = ['%s=%s' % (k, _attr(aef[k]))
                      for k in META_KEYS if k in aef and not isinstance(aef[k], (dict, list))]
        # T-061 (FC-13): explicit aef.x-* extension keys pass through as
        # <aef:meta> attributes (scalars only) — opt-in, so a passthrough is
        # always intentional, never a typo silently promoted to a real field.
        for k in aef:
            if k.startswith(EXT_PREFIX) and not isinstance(aef[k], (dict, list)):
                meta_pairs.append('%s=%s' % (k, _attr(aef[k])))
        # T-062: a META_KEYS or aef.x-* key is a scalar attribute channel. If it
        # carries a dict/list it cannot be emitted — warn instead of dropping it
        # silently (the same "no silent failures" contract as the unknown-key
        # WARN below). Flatten such a value to a scalar in the source YAML.
        for k in aef:
            if (k in META_KEYS or k.startswith(EXT_PREFIX)) and isinstance(aef[k], (dict, list)):
                sys.stderr.write(
                    "WARN yaml-to-bpmn: node %r: aef key %r has a %s value that "
                    "cannot ride the scalar <aef:meta> channel — flatten it to a "
                    "scalar (dropped)\n" % (uid, k, type(aef[k]).__name__))
        if meta_pairs:
            out.append('        <aef:meta %s/>' % " ".join(meta_pairs))
        if "decisionInput" in aef:
            out.append('        <aef:decisionInput>%s</aef:decisionInput>'
                       % escape(str(aef["decisionInput"])))
        if "decisionOutputs" in aef:
            out.append('        <aef:decisionOutputs>%s</aef:decisionOutputs>'
                       % escape(str(aef["decisionOutputs"])))
        # Context/artifact flow annotations (editor reads getAttribute('paths')).
        if aef.get("contextReads"):
            out.append('        <aef:contextReads paths=%s/>' % _attr(aef["contextReads"]))
        if aef.get("artifactsWrites"):
            out.append('        <aef:artifactsWrites paths=%s/>' % _attr(aef["artifactsWrites"]))
        # Link event pairing (editor reads targetWorkflow/linkId attributes).
        if aef.get("targetWorkflow") or aef.get("linkId"):
            out.append('        <aef:link targetWorkflow=%s linkId=%s/>'
                       % (_attr(aef.get("targetWorkflow", "")), _attr(aef.get("linkId", ""))))
        # T-204: typed intermediate event — kind derives from the node TYPE (not an
        # aef key), binding from the kind-specific aef scalar. Emitted as
        # <aef:eventDef kind=.. binding=..>, byte-mirroring the editor's aefExtensionXml
        # so the two producers agree (editor↔bridge parity).
        _ntype = n.get("type", "")
        if _ntype in EVENT_KIND:
            out.append('        <aef:eventDef kind=%s binding=%s/>'
                       % (_attr(EVENT_KIND[_ntype]),
                          _attr(aef.get(EVENT_BINDING_FIELD[_ntype], ""))))
        # I/O data contract — a top-level node key (sibling of aef), not under aef.
        # Editor io reader: required only when true; outputs carry no required.
        io = n.get("io", {}) or {}
        io_inputs = io.get("inputs", []) or []
        io_outputs = io.get("outputs", []) or []
        if io_inputs or io_outputs:
            out.append('        <aef:io>')
            for i in io_inputs:
                if not isinstance(i, dict):
                    continue
                req = ' required="true"' if i.get("required") else ''
                out.append('          <aef:input name=%s type=%s%s/>'
                           % (_attr(i.get("name", "")), _attr(i.get("type", "string")), req))
            for o in io_outputs:
                if not isinstance(o, dict):
                    continue
                out.append('          <aef:output name=%s type=%s/>'
                           % (_attr(o.get("name", "")), _attr(o.get("type", "string"))))
            out.append('        </aef:io>')
        # T-063: structured aef values get dedicated child elements (not the
        # scalar <aef:meta> channel). list-valued → wrapper + one child per item;
        # dict-valued → one element with an attribute per field.
        for key, (wrap, item, attr) in STRUCTURED_LIST_KEYS.items():
            val = aef.get(key)
            if isinstance(val, list) and val:
                out.append('        <aef:%s>' % wrap)
                for v in val:
                    out.append('          <aef:%s %s=%s/>' % (item, attr, _attr(v)))
                out.append('        </aef:%s>' % wrap)
        for key in STRUCTURED_DICT_KEYS:
            val = aef.get(key)
            if isinstance(val, dict) and val:
                attrs = " ".join('%s=%s' % (fk, _attr(_scalarize(fv)))
                                 for fk, fv in val.items())
                out.append('        <aef:%s %s/>' % (key, attrs))
        # T-081: list-of-dicts channel — one child element per entry, one
        # attribute per present field (field order fixed by the key spec so
        # emission is deterministic regardless of YAML dict order).
        for key, (wrap, item, fields) in STRUCTURED_ITEMLIST_KEYS.items():
            val = aef.get(key)
            if isinstance(val, list) and val:
                out.append('        <aef:%s>' % wrap)
                for entry in val:
                    if not isinstance(entry, dict):
                        sys.stderr.write(
                            "WARN yaml-to-bpmn: node %r: aef.%s entry %r is not "
                            "a mapping (dropped)\n" % (uid, key, entry))
                        continue
                    pairs = " ".join('%s=%s' % (f, _attr(entry[f]))
                                     for f in fields
                                     if f in entry and entry[f] is not None)
                    out.append('          <aef:%s %s/>' % (item, pairs))
                out.append('        </aef:%s>' % wrap)
        # T-061 (FC-13): no silent drops. Any aef key that is neither handled
        # above nor an explicit aef.x-* extension is reported to stderr (still
        # dropped, but visible). Non-fatal: exit code is unchanged so the
        # pipeline is not broken by a stray key — "no silent failures", not
        # "no failures".
        for k in aef:
            if k in KNOWN_AEF_KEYS or k.startswith(EXT_PREFIX):
                continue
            sys.stderr.write(
                "WARN yaml-to-bpmn: node %r: unknown aef key %r dropped "
                "(use aef.%s%s for intentional passthrough)\n"
                % (uid, k, EXT_PREFIX, k))
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
