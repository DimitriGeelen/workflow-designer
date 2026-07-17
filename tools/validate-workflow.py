#!/usr/bin/env python3
"""Schema validator for AEF Workflow Designer files.

Validates the workflow files produced by the AEF Workflow Designer against the
contract in docs/designer/schema.md (see especially section 7.3 "Validation",
the required-field tables in sections 3/4.1/5/6.1, and the XML mapping in 7.1/7.2).

Two produced formats are supported and auto-detected:

  * YAML canonical form (section 3) -- the AEF-canonical, source-controlled,
    hand-authorable representation. Edges reference node `uid`s (not displayIds).
  * BPMN 2.0 XML export (section 7) -- what the designer's Save action emits.
    Flow references use `bpmn:id` (displayId); `aef:uid` carries stable identity.

This is a STRUCTURAL validator only. It does not execute workflows -- the
`fw workflow run` runtime executor is explicitly out of scope (T-002 scope fence).

Exit codes (AEF audit convention):
    0  valid          -- no findings
    1  warnings only  -- convention issues, still usable
    2  invalid        -- one or more hard-rule errors (or a load failure)

Usage:
    python3 tools/validate-workflow.py <file> [--format {auto,yaml,xml}]
                                              [--json] [--quiet]

Standalone by design (not wired into the vendored `fw` CLI) to respect the
product/framework boundary and Directive 4 (Portability); the framework may
later adopt it as `fw workflow validate`.
"""

import argparse
import json
import sys
import xml.etree.ElementTree as ET

try:
    import yaml
except ImportError:  # pragma: no cover - environment guard
    sys.stderr.write("error: PyYAML is required (pip install pyyaml)\n")
    sys.exit(2)


# --- Contract constants (docs/designer/schema.md) --------------------------

NODE_TYPES = {
    "startEvent",
    "endEvent",
    "serviceTask",
    "userTask",
    "scriptTask",
    "exclusiveGateway",
    "parallelGateway",
    "linkEventThrow",
    "linkEventCatch",
    # T-081 phase 1: collapsed-only composite node (FC-11). Child flow-node
    # nesting is phase 2 (own inception) — nothing here permits children yet.
    "subProcess",
}

# section 5: lane authority vocabulary
AUTHORITIES = {"sovereignty", "authority", "initiative", "external", "none"}

# section 3: required top-level keys (lanes >= 1; nodes/edges may be empty)
REQUIRED_TOPLEVEL = ["workflowMeta", "pool", "lanes", "nodes", "edges"]

# section 4.1 / 5 / 6.1: required member fields
REQUIRED_NODE_FIELDS = ["uid", "type", "name", "lane", "x", "y"]
REQUIRED_LANE_FIELDS = ["id", "name", "authority", "height"]
REQUIRED_EDGE_FIELDS = ["uid", "source", "target"]

ERROR = "ERROR"
WARN = "WARN"

# section 7.2: BPMN + aef extension namespaces
BPMN_NS = "http://www.omg.org/spec/BPMN/20100524/MODEL"
AEF_NS = "http://anchorpoint.framework/aef/extensions"

# BPMN local tags that are NOT flow nodes (excluded when collecting node ids)
XML_NON_FLOWNODE_TAGS = {"laneSet", "sequenceFlow", "extensionElements"}


class Finding:
    __slots__ = ("severity", "rule", "location", "message")

    def __init__(self, severity, rule, location, message):
        self.severity = severity
        self.rule = rule
        self.location = location
        self.message = message

    def as_dict(self):
        return {
            "severity": self.severity,
            "rule": self.rule,
            "location": self.location,
            "message": self.message,
        }


class Validator:
    def __init__(self):
        self.findings = []

    def err(self, rule, location, message):
        self.findings.append(Finding(ERROR, rule, location, message))

    def warn(self, rule, location, message):
        self.findings.append(Finding(WARN, rule, location, message))

    # -- helpers ------------------------------------------------------------

    @staticmethod
    def _as_list(value):
        return value if isinstance(value, list) else []

    # -- top-level ----------------------------------------------------------

    def validate(self, doc):
        if not isinstance(doc, dict):
            self.err(
                "E-NOT-MAPPING",
                "<root>",
                "workflow file must be a YAML mapping at the top level",
            )
            return

        for key in REQUIRED_TOPLEVEL:
            if key not in doc:
                self.err(
                    "E-TOPLEVEL-MISSING",
                    "<root>",
                    "missing required top-level key '%s'" % key,
                )

        lanes = self._as_list(doc.get("lanes"))
        nodes = self._as_list(doc.get("nodes"))
        edges = self._as_list(doc.get("edges"))

        # section 3: at least one lane is required
        if "lanes" in doc and len(lanes) == 0:
            self.err(
                "E-LANES-EMPTY",
                "lanes",
                "at least one lane is required (nodes/edges may be empty)",
            )

        lane_ids = self._check_lanes(lanes)
        node_uids = self._check_nodes(nodes, lane_ids)
        self._check_uid_uniqueness(nodes, edges)
        self._check_edges(edges, node_uids)
        self._check_gateways(nodes, edges)
        self._check_parallel_gateways(nodes, edges)
        self._check_constituents(nodes, node_uids)
        self._check_reachability(nodes, edges)
        self._check_required_inputs(nodes, edges)

    # -- lanes (section 5, section 2) --------------------------------------

    def _check_lanes(self, lanes):
        lane_ids = set()
        abbrs = {}
        for i, lane in enumerate(lanes):
            loc = "lanes[%d]" % i
            if not isinstance(lane, dict):
                self.err("E-LANE-FIELD", loc, "lane must be a mapping")
                continue
            loc = "lane '%s'" % lane.get("id", "?") if "id" in lane else loc
            for field in REQUIRED_LANE_FIELDS:
                if field not in lane:
                    self.err(
                        "E-LANE-FIELD",
                        loc,
                        "lane missing required field '%s'" % field,
                    )
            if "authority" in lane and lane["authority"] not in AUTHORITIES:
                self.err(
                    "E-AUTHORITY",
                    loc,
                    "authority '%s' not in %s"
                    % (lane["authority"], sorted(AUTHORITIES)),
                )
            if "id" in lane:
                lane_ids.add(lane["id"])
            # section 2: abbr uniqueness across lanes
            abbr = lane.get("abbr")
            if abbr is not None:
                if abbr in abbrs:
                    self.err(
                        "E-ABBR-DUP",
                        loc,
                        "lane abbr '%s' already used by lane '%s'"
                        % (abbr, abbrs[abbr]),
                    )
                else:
                    abbrs[abbr] = lane.get("id", loc)
        return lane_ids

    # -- nodes (section 4.1) ------------------------------------------------

    def _check_nodes(self, nodes, lane_ids):
        node_uids = set()
        for i, node in enumerate(nodes):
            loc = "nodes[%d]" % i
            if not isinstance(node, dict):
                self.err("E-NODE-FIELD", loc, "node must be a mapping")
                continue
            loc = "node '%s'" % node.get("uid", "?") if "uid" in node else loc
            for field in REQUIRED_NODE_FIELDS:
                if field not in node:
                    self.err(
                        "E-NODE-FIELD",
                        loc,
                        "node missing required field '%s'" % field,
                    )
            if "type" in node and node["type"] not in NODE_TYPES:
                self.err(
                    "E-NODE-TYPE",
                    loc,
                    "unknown node type '%s'" % node["type"],
                )
            if "lane" in node and lane_ids and node["lane"] not in lane_ids:
                self.err(
                    "E-NODE-LANE",
                    loc,
                    "node lane '%s' does not match any lane id" % node["lane"],
                )
            if "uid" in node:
                node_uids.add(node["uid"])
        return node_uids

    # -- uid uniqueness (section 7.3) --------------------------------------

    def _check_uid_uniqueness(self, nodes, edges):
        seen = {}
        for kind, items in (("node", nodes), ("edge", edges)):
            for item in items:
                if not isinstance(item, dict):
                    continue
                uid = item.get("uid")
                if uid is None:
                    continue
                if uid in seen:
                    self.err(
                        "E-UID-DUP",
                        "uid '%s'" % uid,
                        "uid '%s' used more than once (also on a %s)"
                        % (uid, seen[uid]),
                    )
                else:
                    seen[uid] = kind

    # -- edges (section 6.1, section 7.3) ----------------------------------

    def _check_edges(self, edges, node_uids):
        for i, edge in enumerate(edges):
            loc = "edges[%d]" % i
            if not isinstance(edge, dict):
                self.err("E-EDGE-FIELD", loc, "edge must be a mapping")
                continue
            loc = "edge '%s'" % edge.get("uid", "?") if "uid" in edge else loc
            for field in REQUIRED_EDGE_FIELDS:
                if field not in edge:
                    self.err(
                        "E-EDGE-FIELD",
                        loc,
                        "edge missing required field '%s'" % field,
                    )
            for endpoint in ("source", "target"):
                ref = edge.get(endpoint)
                if ref is not None and ref not in node_uids:
                    self.err(
                        "E-EDGE-DANGLING",
                        loc,
                        "edge %s '%s' does not resolve to a node uid"
                        % (endpoint, ref),
                    )

    # -- gateways (section 6.5, section 7.3) -------------------------------

    def _check_gateways(self, nodes, edges):
        for node in nodes:
            if not isinstance(node, dict) or node.get("type") != "exclusiveGateway":
                continue
            uid = node.get("uid")
            loc = "node '%s'" % uid
            outgoing = [
                e for e in edges if isinstance(e, dict) and e.get("source") == uid
            ]
            # section 7.3: at least two outgoing edges
            if len(outgoing) < 2:
                self.err(
                    "E-GW-OUTGOING",
                    loc,
                    "exclusiveGateway has %d outgoing edge(s); requires >= 2"
                    % len(outgoing),
                )
            # section 6.5: at most one unconditioned (default) outgoing edge
            unconditioned = [e for e in outgoing if not e.get("condition")]
            if len(unconditioned) > 1:
                self.warn(
                    "W-GW-AMBIGUOUS",
                    loc,
                    "exclusiveGateway has %d outgoing edges without a condition; "
                    "at most one may be the default" % len(unconditioned),
                )

    # -- parallel gateways (fork/join structure) ---------------------------

    def _check_parallel_gateways(self, nodes, edges):
        """Structural checks for parallelGateway fork/join usage.

        Additive to `_check_gateways` (which handles exclusiveGateway only).
        All findings are WARN — a parallelGateway is structurally legal in any
        shape; these flag *modeling* smells that a strict runtime would mishandle:

          W-PGW-CONDITION  an outgoing edge carries a condition. A parallel fork
                           activates ALL branches unconditionally, so the
                           condition is silently ignored (author likely meant an
                           exclusiveGateway).
          W-PGW-NOOP       in-degree <= 1 AND out-degree <= 1: the gateway
                           neither forks nor joins — it does nothing.
          W-PGW-UNBALANCED a parallel fork (out-degree >= 2) exists but no
                           parallel join (in-degree >= 2), or vice versa —
                           forked branches never reconverge (or a join has
                           nothing forking into it).
        """
        pgws = [
            n
            for n in nodes
            if isinstance(n, dict) and n.get("type") == "parallelGateway"
        ]
        if not pgws:
            return

        in_deg = {}
        out_deg = {}
        for e in edges:
            if not isinstance(e, dict):
                continue
            src, tgt = e.get("source"), e.get("target")
            if src is not None:
                out_deg[src] = out_deg.get(src, 0) + 1
            if tgt is not None:
                in_deg[tgt] = in_deg.get(tgt, 0) + 1

        has_fork = False
        has_join = False
        for node in pgws:
            uid = node.get("uid")
            o = out_deg.get(uid, 0)
            i = in_deg.get(uid, 0)
            if o >= 2:
                has_fork = True
            if i >= 2:
                has_join = True

            loc = "node '%s'" % uid
            # W-PGW-CONDITION: conditions on a fork's outgoing edges are ignored
            if o >= 2:
                for e in edges:
                    if (
                        isinstance(e, dict)
                        and e.get("source") == uid
                        and e.get("condition")
                    ):
                        self.warn(
                            "W-PGW-CONDITION",
                            loc,
                            "parallelGateway outgoing edge '%s' has a condition; "
                            "a parallel fork takes all branches, so the condition "
                            "is ignored (did you mean an exclusiveGateway?)"
                            % e.get("uid", "?"),
                        )
            # W-PGW-NOOP: neither forks nor joins
            if i <= 1 and o <= 1:
                self.warn(
                    "W-PGW-NOOP",
                    loc,
                    "parallelGateway has in-degree %d and out-degree %d; it "
                    "neither forks nor joins (no-op)" % (i, o),
                )

        # W-PGW-UNBALANCED: fork without join, or join without fork
        if has_fork and not has_join:
            for node in pgws:
                uid = node.get("uid")
                if out_deg.get(uid, 0) >= 2:
                    self.warn(
                        "W-PGW-UNBALANCED",
                        "node '%s'" % uid,
                        "parallel fork has no matching parallel join in the "
                        "workflow (forked branches never reconverge)",
                    )
        elif has_join and not has_fork:
            for node in pgws:
                uid = node.get("uid")
                if in_deg.get(uid, 0) >= 2:
                    self.warn(
                        "W-PGW-UNBALANCED",
                        "node '%s'" % uid,
                        "parallel join has no matching parallel fork in the "
                        "workflow (nothing forks into it)",
                    )

    # -- constituents / scopeOf (T-081 phase 1, FC-11/FC-15) ----------------

    def _check_constituents(self, nodes, node_uids):
        """Composite-node metadata: aef.constituents (what a collapsed node is
        composed of) and aef.scopeOf (a subProcess marking itself as the
        collapsed body of another node).

        constituents is legal on ANY flow node — FC-11 collapses happen on
        gateways as well as tasks (verification-gate g_gates, git-commit-flow
        g_hooks). Shape rules only:

          E-CONST-SHAPE      not a non-empty list of {id, name, ref?} mappings
          E-CONST-DUP        constituent id duplicated within one node
          W-CONST-FIELD      unknown entry field (would be silently dropped at
                             the bridge seam — no silent drops)
          E-SCOPEOF-SELF     scopeOf references the node itself
          E-SCOPEOF-DANGLING scopeOf does not resolve to a node uid
          W-SCOPEOF-TYPE     scopeOf on a non-subProcess node
        """
        for node in nodes:
            if not isinstance(node, dict):
                continue
            uid = node.get("uid", "?")
            loc = "node '%s'" % uid
            aef = node.get("aef")
            if not isinstance(aef, dict):
                continue
            if "constituents" in aef:
                val = aef["constituents"]
                if not isinstance(val, list) or not val:
                    self.err(
                        "E-CONST-SHAPE",
                        loc,
                        "aef.constituents must be a non-empty list of "
                        "{id, name, ref?} mappings",
                    )
                else:
                    seen_ids = set()
                    for j, entry in enumerate(val):
                        if (
                            not isinstance(entry, dict)
                            or not entry.get("id")
                            or not entry.get("name")
                        ):
                            self.err(
                                "E-CONST-SHAPE",
                                loc,
                                "aef.constituents[%d] must be a mapping with "
                                "non-empty 'id' and 'name'" % j,
                            )
                            continue
                        cid = entry["id"]
                        if cid in seen_ids:
                            self.err(
                                "E-CONST-DUP",
                                loc,
                                "aef.constituents id '%s' duplicated within "
                                "the node" % cid,
                            )
                        seen_ids.add(cid)
                        unknown = set(entry) - {"id", "name", "ref"}
                        if unknown:
                            self.warn(
                                "W-CONST-FIELD",
                                loc,
                                "aef.constituents[%d] has unknown field(s) %s "
                                "(only id, name, ref ride the bridge seam)"
                                % (j, sorted(unknown)),
                            )
            scope = aef.get("scopeOf")
            if scope is not None:
                if scope == uid:
                    self.err(
                        "E-SCOPEOF-SELF",
                        loc,
                        "aef.scopeOf must not reference the node itself",
                    )
                elif node_uids and scope not in node_uids:
                    self.err(
                        "E-SCOPEOF-DANGLING",
                        loc,
                        "aef.scopeOf '%s' does not resolve to a node uid"
                        % scope,
                    )
                if node.get("type") != "subProcess":
                    self.warn(
                        "W-SCOPEOF-TYPE",
                        loc,
                        "aef.scopeOf is a subProcess boundary marker; node "
                        "type is '%s'" % node.get("type"),
                    )

    # -- reachability / dead-ends ------------------------------------------

    def _check_reachability(self, nodes, edges):
        """Forward reachability from starts and backward reachability to ends.

        Pure graph analysis (no `aef:` inspection). Both findings are WARN:

          W-UNREACHABLE  a node is not forward-reachable from any startEvent.
                         `linkEventCatch` nodes are additional seeds (they are
                         cross-workflow entry points), so off-page connectors do
                         not false-positive.
          W-DEADEND      no endEvent is backward-reachable from a node (control
                         never terminates). `linkEventThrow` nodes are additional
                         backward seeds (they are cross-workflow termini).

        A workflow with no startEvent (resp. endEvent) is skipped for the
        corresponding check — there is no anchor to measure against, and the
        missing-event case is a modelling choice the structural rules do not
        mandate.
        """
        by_uid = {
            n["uid"]: n
            for n in nodes
            if isinstance(n, dict) and "uid" in n
        }
        if not by_uid:
            return

        succ = {}
        pred = {}
        for e in edges:
            if not isinstance(e, dict):
                continue
            src, tgt = e.get("source"), e.get("target")
            if src in by_uid and tgt in by_uid:
                succ.setdefault(src, set()).add(tgt)
                pred.setdefault(tgt, set()).add(src)

        def _type(uid):
            return by_uid.get(uid, {}).get("type")

        def _reach(seeds, adj):
            seen = set(seeds)
            stack = list(seeds)
            while stack:
                cur = stack.pop()
                for nxt in adj.get(cur, ()):
                    if nxt not in seen:
                        seen.add(nxt)
                        stack.append(nxt)
            return seen

        # forward reachability from starts (+ linkEventCatch entry points)
        fwd_seeds = [
            uid
            for uid in by_uid
            if _type(uid) in ("startEvent", "linkEventCatch")
        ]
        if fwd_seeds:
            reachable = _reach(fwd_seeds, succ)
            for uid in by_uid:
                if uid not in reachable and _type(uid) not in (
                    "startEvent",
                    "linkEventCatch",
                ):
                    self.warn(
                        "W-UNREACHABLE",
                        "node '%s'" % uid,
                        "node is not reachable from any startEvent",
                    )

        # backward reachability to ends (+ linkEventThrow termini)
        bwd_seeds = [
            uid
            for uid in by_uid
            if _type(uid) in ("endEvent", "linkEventThrow")
        ]
        if bwd_seeds:
            terminating = _reach(bwd_seeds, pred)
            for uid in by_uid:
                if uid not in terminating and _type(uid) not in (
                    "endEvent",
                    "linkEventThrow",
                ):
                    self.warn(
                        "W-DEADEND",
                        "node '%s'" % uid,
                        "no endEvent is reachable from this node (control never "
                        "terminates)",
                    )

    # -- required I/O inputs (section 4.3, section 7.3) --------------------

    def _check_required_inputs(self, nodes, edges):
        by_uid = {
            n["uid"]: n
            for n in nodes
            if isinstance(n, dict) and "uid" in n
        }
        # reverse adjacency: predecessors[target] = {sources}
        preds = {}
        for e in edges:
            if not isinstance(e, dict):
                continue
            src, tgt = e.get("source"), e.get("target")
            if src in by_uid and tgt in by_uid:
                preds.setdefault(tgt, set()).add(src)

        def ancestor_outputs(uid):
            names = set()
            seen = set()
            stack = list(preds.get(uid, ()))
            while stack:
                cur = stack.pop()
                if cur in seen:
                    continue
                seen.add(cur)
                node = by_uid.get(cur, {})
                io = node.get("io") or {}
                for out in self._as_list(io.get("outputs")):
                    if isinstance(out, dict) and "name" in out:
                        names.add(out["name"])
                stack.extend(preds.get(cur, ()))
            return names

        for uid, node in by_uid.items():
            io = node.get("io") or {}
            required = [
                inp
                for inp in self._as_list(io.get("inputs"))
                if isinstance(inp, dict) and inp.get("required")
            ]
            if not required:
                continue
            upstream = ancestor_outputs(uid)
            for inp in required:
                name = inp.get("name")
                if name is not None and name not in upstream:
                    self.warn(
                        "W-IO-INPUT",
                        "node '%s'" % uid,
                        "required input '%s' has no upstream node emitting a "
                        "matching output" % name,
                    )


class XmlValidator:
    """Validates the BPMN-XML export form (docs/designer/schema.md section 7)."""

    def __init__(self):
        self.findings = []

    def err(self, rule, location, message):
        self.findings.append(Finding(ERROR, rule, location, message))

    def warn(self, rule, location, message):
        self.findings.append(Finding(WARN, rule, location, message))

    @staticmethod
    def _local(tag):
        # strip '{namespace}' prefix from an ElementTree tag
        return tag.rsplit("}", 1)[-1] if "}" in tag else tag

    def validate(self, root):
        # section 7: root is bpmn:definitions containing a bpmn:process
        process = root.find("{%s}process" % BPMN_NS)
        if self._local(root.tag) != "definitions" or process is None:
            self.err(
                "E-XML-STRUCTURE",
                "<root>",
                "expected <bpmn:definitions> containing a <bpmn:process>",
            )
            return

        # -- bpmn:id uniqueness (section 7.3) -------------------------------
        seen_ids = set()
        for el in root.iter():
            el_id = el.get("id")
            if el_id is None:
                continue
            if el_id in seen_ids:
                self.err(
                    "E-XML-ID-DUP",
                    "bpmn:id '%s'" % el_id,
                    "bpmn:id '%s' is not unique within the document" % el_id,
                )
            else:
                seen_ids.add(el_id)

        # -- aef:uid uniqueness (section 7.3) -------------------------------
        seen_uids = set()
        for el in root.iter("{%s}uid" % AEF_NS):
            value = el.get("value")
            if value is None:
                continue
            if value in seen_uids:
                self.err(
                    "E-XML-UID-DUP",
                    "aef:uid '%s'" % value,
                    "aef:uid '%s' is not unique within the document" % value,
                )
            else:
                seen_uids.add(value)

        # -- collect flow nodes vs sequence flows ---------------------------
        flow_node_ids = set()
        node_type = {}
        seq_flows = []
        gateways = []
        parallel_gateways = []
        for child in list(process):
            local = self._local(child.tag)
            if local == "sequenceFlow":
                seq_flows.append(child)
                continue
            if local in XML_NON_FLOWNODE_TAGS:
                continue
            node_id = child.get("id")
            if node_id is not None:
                flow_node_ids.add(node_id)
                node_type[node_id] = local
                if local == "exclusiveGateway":
                    gateways.append(node_id)
                elif local == "parallelGateway":
                    parallel_gateways.append(node_id)

        # -- sequenceFlow endpoint resolution (section 7.3) -----------------
        outgoing_count = {}
        for flow in seq_flows:
            fid = flow.get("id", "?")
            for attr in ("sourceRef", "targetRef"):
                ref = flow.get(attr)
                if ref is not None and ref not in flow_node_ids:
                    self.err(
                        "E-XML-FLOW-DANGLING",
                        "sequenceFlow '%s'" % fid,
                        "%s '%s' does not resolve to a flow-node bpmn:id"
                        % (attr, ref),
                    )
            src = flow.get("sourceRef")
            if src is not None:
                outgoing_count[src] = outgoing_count.get(src, 0) + 1

        # -- lane membership (section 7.3) ----------------------------------
        assigned = set()
        lane_set = process.find("{%s}laneSet" % BPMN_NS)
        if lane_set is not None:
            for ref_el in lane_set.iter("{%s}flowNodeRef" % BPMN_NS):
                ref = (ref_el.text or "").strip()
                if not ref:
                    continue
                assigned.add(ref)
                if ref not in flow_node_ids:
                    self.err(
                        "E-XML-LANEREF-DANGLING",
                        "flowNodeRef '%s'" % ref,
                        "flowNodeRef '%s' does not resolve to a flow-node bpmn:id"
                        % ref,
                    )

        # -- exclusiveGateway outgoing count (section 7.3) ------------------
        for gid in gateways:
            count = outgoing_count.get(gid, 0)
            if count < 2:
                self.err(
                    "E-XML-GW-OUTGOING",
                    "exclusiveGateway '%s'" % gid,
                    "exclusiveGateway has %d outgoing flow(s); requires >= 2"
                    % count,
                )

        # -- unassigned flow nodes (convention, WARN) -----------------------
        for node_id in sorted(flow_node_ids):
            if node_id not in assigned:
                self.warn(
                    "W-XML-NODE-UNASSIGNED",
                    "node '%s'" % node_id,
                    "flow node '%s' is not assigned to any lane" % node_id,
                )

        # -- degrees + adjacency (shared by the checks below) ---------------
        in_deg = {}
        out_deg = {}
        succ = {}
        pred = {}
        for flow in seq_flows:
            src = flow.get("sourceRef")
            tgt = flow.get("targetRef")
            if src in flow_node_ids:
                out_deg[src] = out_deg.get(src, 0) + 1
            if tgt in flow_node_ids:
                in_deg[tgt] = in_deg.get(tgt, 0) + 1
            if src in flow_node_ids and tgt in flow_node_ids:
                succ.setdefault(src, set()).add(tgt)
                pred.setdefault(tgt, set()).add(src)

        # -- parallelGateway structure (mirrors the YAML validator, WARN) ---
        has_fork = False
        has_join = False
        for gid in parallel_gateways:
            o = out_deg.get(gid, 0)
            i = in_deg.get(gid, 0)
            if o >= 2:
                has_fork = True
            if i >= 2:
                has_join = True
            loc = "parallelGateway '%s'" % gid
            if o >= 2:
                for flow in seq_flows:
                    if flow.get("sourceRef") == gid and (
                        flow.find("{%s}conditionExpression" % BPMN_NS) is not None
                    ):
                        self.warn(
                            "W-XML-PGW-CONDITION",
                            loc,
                            "parallelGateway outgoing flow '%s' has a "
                            "conditionExpression; a parallel fork takes all "
                            "branches, so the condition is ignored"
                            % flow.get("id", "?"),
                        )
            if i <= 1 and o <= 1:
                self.warn(
                    "W-XML-PGW-NOOP",
                    loc,
                    "parallelGateway has in-degree %d and out-degree %d; it "
                    "neither forks nor joins (no-op)" % (i, o),
                )
        if has_fork and not has_join:
            for gid in parallel_gateways:
                if out_deg.get(gid, 0) >= 2:
                    self.warn(
                        "W-XML-PGW-UNBALANCED",
                        "parallelGateway '%s'" % gid,
                        "parallel fork has no matching parallel join in the "
                        "workflow (forked branches never reconverge)",
                    )
        elif has_join and not has_fork:
            for gid in parallel_gateways:
                if in_deg.get(gid, 0) >= 2:
                    self.warn(
                        "W-XML-PGW-UNBALANCED",
                        "parallelGateway '%s'" % gid,
                        "parallel join has no matching parallel fork in the "
                        "workflow (nothing forks into it)",
                    )

        # -- reachability / dead-ends (mirrors the YAML validator, WARN) -----
        # BPMN link events map to intermediate throw/catch events (schema 7.2):
        # catch is a cross-workflow entry, throw a cross-workflow terminus.
        def _reach(seeds, adj):
            seen = set(seeds)
            stack = list(seeds)
            while stack:
                cur = stack.pop()
                for nxt in adj.get(cur, ()):
                    if nxt not in seen:
                        seen.add(nxt)
                        stack.append(nxt)
            return seen

        fwd_starts = ("startEvent", "intermediateCatchEvent")
        bwd_ends = ("endEvent", "intermediateThrowEvent")
        fwd_seeds = [n for n in flow_node_ids if node_type.get(n) in fwd_starts]
        if fwd_seeds:
            reachable = _reach(fwd_seeds, succ)
            for n in sorted(flow_node_ids):
                if n not in reachable and node_type.get(n) not in fwd_starts:
                    self.warn(
                        "W-XML-UNREACHABLE",
                        "node '%s'" % n,
                        "node is not reachable from any startEvent",
                    )
        bwd_seeds = [n for n in flow_node_ids if node_type.get(n) in bwd_ends]
        if bwd_seeds:
            terminating = _reach(bwd_seeds, pred)
            for n in sorted(flow_node_ids):
                if n not in terminating and node_type.get(n) not in bwd_ends:
                    self.warn(
                        "W-XML-DEADEND",
                        "node '%s'" % n,
                        "no endEvent is reachable from this node (control never "
                        "terminates)",
                    )

        # v1.1 IW-9 authority enforcement (mapping-v1 §3/§7): O-1 type/lane
        # mismatch (WARN) + O-3 inception-must-be-sovereignty-laned (ERROR).
        self._check_iw9_authority(process)

    def _check_iw9_authority(self, process):
        """v1.1 IW-9 authority enforcement on the BPMN form (mapping-v1 §3/§7).

        O-3 (E-INCEPTION-NOT-SOVEREIGN, ERROR): a subProcess carrying
          ``aef:meta workflowType="inception"`` MUST be a member of a lane whose
          ``aef:laneMeta authority="sovereignty"`` — the go/no-go boundary is
          human-owned. Fails fast on a malformed inception.
        O-1 (W-TYPE-LANE-MISMATCH, WARN): a userTask/serviceTask/scriptTask whose
          task-type-implied performer disagrees with the lane authority collapse.
          The lane is authority-of-record and wins; task-type is presentational.
        """
        # lane authority -> task-YAML owner collapse (mapping-v1 §3)
        AUTHORITY_OWNER = {
            "sovereignty": "human",
            "initiative": "agent",
            "authority": "agent",
            # external -> no task authored; none -> unspecified (both skipped)
        }
        TYPE_PERFORMER = {
            "userTask": "human",
            "serviceTask": "agent",
            "scriptTask": "agent",
        }
        # A missing laneSet must NOT short-circuit O-3 (T-199). Absent lanes means
        # absent authority-of-record — precisely what §7's MUST rejects — so an
        # early return here made the one diagram carrying no human signal at all
        # the only diagram that passed. Leave node_authority empty instead and let
        # every node read as authority-absent. O-1 below is already guarded on
        # `authority is not None`, so a lane-less diagram stays WARN-quiet: absent
        # authority is not a disagreement, there is nothing to disagree with.
        lane_set = process.find("{%s}laneSet" % BPMN_NS)
        lanes = (
            lane_set.findall("{%s}lane" % BPMN_NS) if lane_set is not None else []
        )
        # flow-node id -> its lane's authority
        node_authority = {}
        for lane in lanes:
            lm = lane.find(
                "{%s}extensionElements/{%s}laneMeta" % (BPMN_NS, AEF_NS)
            )
            authority = lm.get("authority") if lm is not None else None
            for ref_el in lane.findall("{%s}flowNodeRef" % BPMN_NS):
                ref = (ref_el.text or "").strip()
                if ref:
                    node_authority[ref] = authority
        for child in list(process):
            local = self._local(child.tag)
            nid = child.get("id")
            if nid is None:
                continue
            authority = node_authority.get(nid)
            # O-3: an inception's boundary MUST be sovereignty(human)-laned
            if local == "subProcess":
                meta = child.find(
                    "{%s}extensionElements/{%s}meta" % (BPMN_NS, AEF_NS)
                )
                wft = meta.get("workflowType") if meta is not None else None
                if wft == "inception" and authority != "sovereignty":
                    self.err(
                        "E-INCEPTION-NOT-SOVEREIGN",
                        "subProcess '%s'" % nid,
                        'inception (workflowType="inception") must be in a '
                        "sovereignty (human) lane; its lane authority is %s "
                        "(O-3, mapping-v1 §7)"
                        % ("absent" if authority is None else "'%s'" % authority),
                    )
            # O-1: task-type should agree with lane authority (lane wins)
            if local in TYPE_PERFORMER and authority is not None:
                owner = AUTHORITY_OWNER.get(authority)
                if owner is not None and owner != TYPE_PERFORMER[local]:
                    self.warn(
                        "W-TYPE-LANE-MISMATCH",
                        "node '%s'" % nid,
                        "%s implies performer '%s' but its lane authority '%s' "
                        "collapses to owner '%s'; the lane wins, task-type is "
                        "presentational (O-1, mapping-v1 §3)"
                        % (local, TYPE_PERFORMER[local], authority, owner),
                    )


def exit_code(findings):
    if any(f.severity == ERROR for f in findings):
        return 2
    if any(f.severity == WARN for f in findings):
        return 1
    return 0


def detect_format(path, text):
    """Return 'xml' or 'yaml' from the extension, falling back to content sniff."""
    lower = path.lower()
    if lower.endswith((".bpmn", ".xml")):
        return "xml"
    if lower.endswith((".yaml", ".yml")):
        return "yaml"
    # content sniff: leading '<' (ignoring BOM/whitespace) => XML
    stripped = text.lstrip("﻿ \t\r\n")
    return "xml" if stripped.startswith("<") else "yaml"


def run_yaml(text):
    validator = Validator()
    try:
        doc = yaml.safe_load(text)
    except yaml.YAMLError as exc:
        validator.err("E-YAML-PARSE", "<file>", "YAML parse error: %s" % exc)
        return validator.findings
    validator.validate(doc)
    return validator.findings


def run_xml(text):
    validator = XmlValidator()
    try:
        root = ET.fromstring(text)
    except ET.ParseError as exc:
        validator.err("E-XML-PARSE", "<file>", "XML parse error: %s" % exc)
        return validator.findings
    validator.validate(root)
    return validator.findings


def render_text(path, findings):
    lines = []
    for f in findings:
        lines.append("%-5s [%s] %s: %s" % (f.severity, f.rule, f.location, f.message))
    errors = sum(1 for f in findings if f.severity == ERROR)
    warns = sum(1 for f in findings if f.severity == WARN)
    if not findings:
        lines.append("VALID  %s -- no findings" % path)
    else:
        lines.append(
            "%s  %s -- %d error(s), %d warning(s)"
            % ("INVALID" if errors else "WARN", path, errors, warns)
        )
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Validate an AEF Workflow Designer file (YAML or BPMN-XML)."
    )
    parser.add_argument("file", help="path to the workflow file (YAML or BPMN-XML)")
    parser.add_argument(
        "--format",
        choices=("auto", "yaml", "xml"),
        default="auto",
        help="input format (default: auto-detect by extension/content)",
    )
    parser.add_argument(
        "--json", action="store_true", help="emit findings as JSON"
    )
    parser.add_argument(
        "--quiet", action="store_true", help="suppress the human-readable report"
    )
    args = parser.parse_args(argv)

    try:
        with open(args.file, "r") as fh:
            text = fh.read()
    except FileNotFoundError:
        findings = [Finding(ERROR, "E-LOAD", args.file, "file not found")]
    except OSError as exc:
        findings = [Finding(ERROR, "E-LOAD", args.file, "cannot read file: %s" % exc)]
    else:
        fmt = args.format if args.format != "auto" else detect_format(args.file, text)
        findings = run_xml(text) if fmt == "xml" else run_yaml(text)

    # relabel the '<file>' placeholder location with the real path
    for f in findings:
        if f.location == "<file>":
            f.location = args.file

    code = exit_code(findings)

    if args.json:
        print(
            json.dumps(
                {
                    "file": args.file,
                    "exit_code": code,
                    "findings": [f.as_dict() for f in findings],
                },
                indent=2,
            )
        )
    elif not args.quiet:
        print(render_text(args.file, findings))

    return code


if __name__ == "__main__":
    sys.exit(main())
