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

# IW-9 authority collapse (mapping-v1 section 3): lane authority -> task-YAML
# owner.
#
# Module scope, not per-class (T-322). These tables decide who is authoritative;
# a second copy inside each validator would let the two forms drift apart on the
# governance question itself, which is the defect T-322 exists to close. Same
# reasoning as the T-315 occupancy hoist.
#
# T-331: the collapse is now a TOTAL, EXPLICIT PARTITION of AUTHORITIES across
# three tables. It used to be one table plus a comment saying "external" and
# "none" were "absent here on purpose". Absence cannot carry a decision:
# `AUTHORITY_OWNER.get(a) is None` could not distinguish "the standard defines
# this to produce no task" from "nobody ever decided what this compiles to", and
# both silently SKIPPED the O-1 check rather than satisfying it. The comment
# asserting they were equivalent was answerable to nothing and could not fail.
# See test_validate_iw9.py, which requires the three sets to partition
# AUTHORITIES exactly — so a sixth authority value cannot be admitted to the
# vocabulary without someone stating its compiled outcome.
AUTHORITY_OWNER = {
    "sovereignty": "human",
    "initiative": "agent",
    "authority": "agent",
}

# mapping-v1 §3 names this outcome normatively: `external -> no task`. The node
# is not owner-less by omission; it compiles to nothing at all, by decision.
AUTHORITY_NO_TASK = {"external"}

# Accepted vocabulary with NO compiled outcome anywhere. schema.md §Lanes
# defines "none" as a lane that "doesn't carry authority semantics", and
# mapping-v1 §3 makes the lane the SOLE authority-of-record for who-performs.
# A task node in such a lane therefore has no derivable owner — the sole source
# is declared absent (PL-035: absence of the named sole source is a violation,
# not a pass). "none" appears in no collapse map in the frozen standard.
AUTHORITY_NO_OWNER_DERIVABLE = {"none"}

# task type -> the performer the type implies. The lane is authority-of-record
# and wins; task type is presentational (mapping-v1 section 3, O-1).
TYPE_PERFORMER = {
    "userTask": "human",
    "serviceTask": "agent",
    "scriptTask": "agent",
}

# section 3: required top-level keys (lanes >= 1; nodes/edges may be empty)
REQUIRED_TOPLEVEL = ["workflowMeta", "pool", "lanes", "nodes", "edges"]

# section 4.1 / 5 / 6.1: required member fields
REQUIRED_NODE_FIELDS = ["uid", "type", "name", "lane", "x", "y"]
REQUIRED_LANE_FIELDS = ["id", "name", "authority", "height"]
REQUIRED_EDGE_FIELDS = ["uid", "source", "target"]

ERROR = "ERROR"
WARN = "WARN"
# INFO is non-blocking and never affects the exit code. It exists so a rule can
# report "I could not evaluate this map" without that reading as a pass (T-312:
# "an unevaluable map must not report clean").
INFO = "INFO"

# section 7.2: BPMN + aef extension namespaces
BPMN_NS = "http://www.omg.org/spec/BPMN/20100524/MODEL"
AEF_NS = "http://anchorpoint.framework/aef/extensions"

# BPMN local tags that are NOT flow nodes (excluded when collecting node ids)
# T-359: legal children of <process> that are NOT flow nodes. Everything else in
# <process> is treated as a flow node and gated against XML_NODE_TYPES, so an
# omission here is a FALSE POSITIVE — an ERROR reported on a valid document.
#
# This set previously held three entries: laneSet, sequenceFlow, extensionElements.
# Those are the only non-flow-node children OUR OWN emitters produce, so the list was
# complete for the population that wrote it and wrong for BPMN. Found when
# tests/fixtures/third-party/bizagi-nested-ns.bpmn put <documentation> directly under
# <process> — legal, it is on BaseElement — and the validator called it an unknown
# flow-node element.
#
# It had been firing on ioSpecification and dataObject the whole time. Those carry
# ids, so the finding anchored to a real subject and the T-335 anchorability guard
# stayed green; only the id-less <documentation> produced `node '?'` and made the
# class visible. The guard keyed on a by-product of the defect, so it only ever
# protected the instances that happened to lack it.
#
# DO NOT ADD A FLOW-NODE TYPE HERE TO QUIET A REPORT. task, businessRuleTask,
# manualTask, receiveTask, transaction, adHocSubProcess and callActivity are real
# flow nodes outside our vocabulary; those errors are CORRECT (the T-321 gate, and
# the reason <bpmn:serviceTaks> no longer validates clean). Suppressing them here
# would silence the genuine vocabulary gap using the fix for a different bug.
XML_NON_FLOWNODE_TAGS = {
    # BaseElement children, legal on every element including <process>
    "documentation", "extensionElements",
    # FlowElementsContainer / Process own properties
    "laneSet", "sequenceFlow", "property", "ioSpecification",
    "auditing", "monitoring", "supports",
    # data
    "dataObject", "dataObjectReference", "dataStoreReference",
    "dataInput", "dataOutput", "dataInputAssociation", "dataOutputAssociation",
    # artifacts — annotations and grouping, never executed
    "association", "textAnnotation", "group", "artifact",
    # participants/roles
    "resourceRole", "performer", "correlationSubscription",
}

# T-321: the XML form's flow-node vocabulary, DERIVED from the YAML one rather
# than hand-written beside it. Two hand-maintained lists describing one modelling
# language drift, which is the T-322 defect one level up.
#
# The relationship is a TRANSLATION plus a small extension, not "a superset" as
# the T-320 census supposed. Measured over 96 authored BPMN and both emitters:
# the bridge (tools/yaml-to-bpmn.py TYPE_MAP) and the designer (TYPE_TAG,
# src:9230ff) produce EXACTLY the same 10 element names as each other, because
# link and typed events are renamed on the way out — linkEventThrow becomes
# intermediateThrowEvent, and eventError/Timer/Message all become a neutral
# intermediateCatchEvent whose kind rides <aef:eventDef>. So
# intermediateCatchEvent / intermediateThrowEvent are not extra vocabulary; they
# are what the YAML names are CALLED here.
#
# Derived, so adding a YAML node type automatically admits its XML spelling and
# the two forms cannot fall out of step.
# The translation itself. Declared here rather than imported so the validator
# stays a standalone tool with no load-time dependency on the bridge — and
# tests/test_xml_node_type_vocab.py asserts it agrees with BOTH emitters, so the
# copy cannot drift silently. (A hand-copy with no drift guard is the thing this
# whole arc keeps finding; a hand-copy WITH one is a declaration.)
XML_TYPE_MAP = {
    "linkEventCatch": "intermediateCatchEvent",
    "linkEventThrow": "intermediateThrowEvent",
    "eventError": "intermediateCatchEvent",
    "eventTimer": "intermediateCatchEvent",
    "eventMessage": "intermediateCatchEvent",
}

XML_TRANSLATED_NODE_TYPES = frozenset(
    XML_TYPE_MAP.get(t, t) for t in NODE_TYPES
)

# The genuine extension: one element, legal BPMN, that no emitter of ours can
# produce. Everything admitted here needs a reason, because this set is the only
# place the gate can be widened without touching NODE_TYPES.
#
#   boundaryEvent -- attached-event modelling, 2 occurrences in the deliberate
#     fixture tests/fixtures/aef-bpmn/boundary-events.bpmn. Legal BPMN, read by
#     the designer's import path (src:9731 treats it as a catch host), but the
#     editor cannot draw one, so nothing we emit contains it. Admitted rather
#     than reported: refusing it would call a valid diagram invalid.
#
# PL-064 applies to what is NOT here: absence from the corpus is not absence of
# demand. This set is deliberately small and explicit so widening it is a visible
# decision rather than a silent one.
XML_ONLY_NODE_TYPES = frozenset({"boundaryEvent"})

XML_NODE_TYPES = XML_TRANSLATED_NODE_TYPES | XML_ONLY_NODE_TYPES

# Occupancy is NOT node height (T-313). The renderer's own containment function
# adds an 18px allowance for types whose name is drawn BELOW the shape
# (src:6975):
#
#   botOf(n)   = n.y + h(type) + (labelBelow(type) ? 18 : 0)
#   labelBelow = startEvent | endEvent | linkEventThrow | linkEventCatch
#              | startsWith('event') | endsWith('Gateway')
#
# so a 48px gateway occupies 66 while a 64px task occupies 64 — the smallest
# shapes are not the smallest occupants, and a height-only table misses any lane
# whose lowest node is a gateway or an event.
#
# Keyed by BPMN local tag, because that is what crosses the seam. The designer's
# link and typed events all serialise to intermediateCatchEvent /
# intermediateThrowEvent / boundaryEvent (src:9118 TYPE_TAG, src:9403);
# collapsing them is sound HERE specifically because every event kind in
# NODE_DEFAULTS is 36 with labelBelow true. It would not be sound for a rule that
# needed the shape back.
#
# tests/test_t313_lane_capacity.py DERIVES this table from
# src/aef-workflow-designer.html rather than restating it, so the palette cannot
# outgrow it silently.
NODE_OCCUPANCY = {
    "startEvent": 54,
    "endEvent": 54,
    "intermediateCatchEvent": 54,
    "intermediateThrowEvent": 54,
    "boundaryEvent": 54,
    "exclusiveGateway": 66,
    "parallelGateway": 66,
    "serviceTask": 64,
    "userTask": 64,
    "scriptTask": 64,
    "subProcess": 64,
}

# src:6966 — the containment margin the Clean layout applies at BOTH edges. Used
# only to describe the tidy target in a repair hint; the rule itself gates on
# containment, NOT on the fixpoint. See _check_lane_capacity.
LANE_FIT_MARGIN = 12


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
        self._check_iw9_authority(lanes, nodes)

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

    # -- IW-9 authority (section 3, section 7) ------------------------------

    def _check_iw9_authority(self, lanes, nodes):
        """v1.1 IW-9 authority enforcement on the canonical YAML form.

        The counterpart of ``XmlValidator._check_iw9_authority``, closing the
        T-322 half of the T-320 parity census. Both rules read the same two
        module-scope tables and emit the same two ids, so a map that is
        governance-clean on one form is governance-clean on the other.

        O-3 (E-INCEPTION-NOT-SOVEREIGN, ERROR): a subProcess carrying
          ``aef.workflowType: inception`` MUST sit in a lane whose authority is
          ``sovereignty`` — the go/no-go boundary is human-owned.
        O-1 (W-TYPE-LANE-MISMATCH, WARN): a userTask/serviceTask/scriptTask
          whose type-implied performer disagrees with the lane authority
          collapse. The lane wins; the type is presentational.

        Absent lane authority is a VIOLATION of O-3, not a skip (PL-035, T-199):
        section 7 names the sovereignty lane the sole source of the go/no-go
        decision, so a map carrying no authority at all is precisely what that
        MUST rejects — it must not become the one map that passes. O-1 stays
        silent in that case, guarded on ``authority is not None``, because
        absent authority is not a disagreement: there is nothing to disagree
        with.
        """
        lane_authority = {
            lane["id"]: lane.get("authority")
            for lane in lanes
            if isinstance(lane, dict) and "id" in lane
        }
        for node in nodes:
            if not isinstance(node, dict):
                continue
            uid = node.get("uid")
            if uid is None:
                continue
            # An unresolvable lane reference reads as authority-absent, matching
            # the XML form's treatment of a node in no flowNodeRef. E-NODE-LANE
            # already reports the dangling reference itself.
            authority = lane_authority.get(node.get("lane"))
            ntype = node.get("type")
            aef = node.get("aef")
            if not isinstance(aef, dict):
                aef = {}

            # O-3: an inception's boundary MUST be sovereignty(human)-laned
            if ntype == "subProcess" and aef.get("workflowType") == "inception":
                if authority != "sovereignty":
                    self.err(
                        "E-INCEPTION-NOT-SOVEREIGN",
                        "node '%s'" % uid,
                        'inception (workflowType="inception") must be in a '
                        "sovereignty (human) lane; its lane authority is %s "
                        "(O-3, mapping-v1 §7)"
                        % ("absent" if authority is None else "'%s'" % authority),
                    )

            # O-1: task-type should agree with lane authority (lane wins)
            if ntype in TYPE_PERFORMER and authority is not None:
                owner = AUTHORITY_OWNER.get(authority)
                if owner is not None and owner != TYPE_PERFORMER[ntype]:
                    self.warn(
                        "W-TYPE-LANE-MISMATCH",
                        "node '%s'" % uid,
                        "%s implies performer '%s' but its lane authority '%s' "
                        "collapses to owner '%s'; the lane wins, task-type is "
                        "presentational (O-1, mapping-v1 §3)"
                        % (ntype, TYPE_PERFORMER[ntype], authority, owner),
                    )

            # T-331: a task node whose lane yields no derivable owner.
            #
            # Distinct from O-1, which asks whether two owners DISAGREE. This
            # asks whether an owner exists at all, and it is the case O-1
            # cannot reach: `owner is not None` skips rather than fails, so an
            # unmapped authority silently disabled the only check on the
            # governance question. Warn-not-refuse matches O-1's posture --
            # the diagram is underspecified, not malformed.
            #
            # Deliberately does NOT fire on AUTHORITY_NO_TASK: `external ->
            # no task` is a decided outcome, not a missing one, and warning on
            # a decision is how a warning gets trained away.
            if ntype in TYPE_PERFORMER and authority in AUTHORITY_NO_OWNER_DERIVABLE:
                self.warn(
                    "W-LANE-NO-OWNER",
                    "node '%s'" % uid,
                    "%s is a task but its lane authority '%s' has no compiled "
                    "outcome; mapping-v1 §3 makes the lane the sole "
                    "authority-of-record, so this task has no derivable owner "
                    "and a downstream compiler must invent one"
                    % (ntype, authority),
                )


class XmlValidator:
    """Validates the BPMN-XML export form (docs/designer/schema.md section 7)."""

    def __init__(self):
        self.findings = []

    def err(self, rule, location, message):
        self.findings.append(Finding(ERROR, rule, location, message))

    def warn(self, rule, location, message):
        self.findings.append(Finding(WARN, rule, location, message))

    def info(self, rule, location, message):
        self.findings.append(Finding(INFO, rule, location, message))

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
            # T-321: vocabulary gate. Until this existed, <bpmn:serviceTaks> --
            # a plain typo -- validated clean at rc=0, and the only witness was
            # an INFO skip-note from the lane-capacity rule, which noticed only
            # because T-313 built it to refuse to guess an occupancy it does not
            # know. An unrelated rule's honesty was standing in for this gate.
            if local not in XML_NODE_TYPES:
                self.err(
                    "E-XML-NODE-TYPE",
                    "node '%s'" % (child.get("id") or "?"),
                    "unknown flow-node element '%s'; the XML vocabulary is "
                    "%s (section 7.2)"
                    % (local, ", ".join(sorted(XML_NODE_TYPES))),
                )
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
        # Outgoing flows carrying no bpmn:conditionExpression, per source node.
        # Kept as flow ids rather than a bare count so the finding can name the
        # witnesses — a count alone tells an author there is a problem without
        # telling them which edges to look at.
        unconditioned_out = {}
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
                if flow.find("{%s}conditionExpression" % BPMN_NS) is None:
                    unconditioned_out.setdefault(src, []).append(fid)

        # -- at least one lane (section 3) ----------------------------------
        # T-330. Counterpart to the YAML form's E-LANES-EMPTY, and the ONE of
        # that task's three candidate holes that survived measurement: the
        # bridge carries this defect through unchanged, emitting a <laneSet>
        # with zero <lane> children. Its two siblings (E-LANE-FIELD,
        # E-NODE-FIELD) are NOT holes -- yaml-to-bpmn.py repairs both by
        # defaulting the missing carrier (height -> 120, x -> 0), so no defect
        # reaches this form and a rule here would report a conformant bridged
        # document as broken.
        #
        # Deliberately does not return: a map with no lanes still has flow
        # nodes, ids and gateways worth validating, and O-3 must still be
        # evaluated (T-199 -- a missing laneSet must not short-circuit it).
        lane_set = process.find("{%s}laneSet" % BPMN_NS)
        declared_lanes = (
            [] if lane_set is None
            else lane_set.findall("{%s}lane" % BPMN_NS)
        )
        if not declared_lanes:
            self.err(
                "E-XML-LANES-EMPTY",
                "<bpmn:laneSet>" if lane_set is not None else "<bpmn:process>",
                "no <bpmn:lane> declared; section 3 requires at least one lane",
            )

        # -- lane membership (section 7.3) ----------------------------------
        assigned = set()
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

        # -- exclusiveGateway branch ambiguity (section 6.5, WARN) ----------
        # Parity with the YAML path's W-GW-AMBIGUOUS (validate-workflow.py:326).
        # At most one outgoing edge may be unconditioned — that one is the
        # default branch. Two or more and the runtime has no defined choice.
        #
        # The designer speaks BPMN, so without this the editor would be shown
        # the weaker of the two rule sets (T-309 / T-317). Semantics are copied
        # from the YAML rule rather than re-derived: the boundary is exactly
        # one, so a well-formed gateway with a single default stays SILENT.
        #
        # WARN, not ERROR, for the T-312 reason: at ERROR this would hard-fail
        # promoted peer bytes we are forbidden to edit, and a defensible reading
        # of an unconditioned pair usually exists (the condition may live in the
        # branch label rather than in a conditionExpression).
        #
        # The bare token `gw_ambiguous` is carried in the message so a grep
        # joins both toolchains across the rule-id namespacing, as done for
        # lane_geometry in T-312.
        for gid in gateways:
            unconditioned = unconditioned_out.get(gid, [])
            if len(unconditioned) > 1:
                self.warn(
                    "W-XML-GW-AMBIGUOUS",
                    "exclusiveGateway '%s'" % gid,
                    "gw_ambiguous: exclusiveGateway has %d outgoing flows "
                    "without a conditionExpression (%s); at most one may be "
                    "the default"
                    % (len(unconditioned), ", ".join(sorted(unconditioned))),
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

        # Lane/geometry agreement (T-312) — the one class both toolchains were
        # blind to, because both are purely structural (rail 334/339).
        self._check_lane_geometry(process)

        # Lane capacity (T-313). MUST run after lane geometry: capacity's repair
        # hint depends on whether the ordering rule is clean, because heights can
        # only contain lanes that are already ordered (see _check_lane_capacity).
        self._check_lane_capacity(process)

    def _node_y(self, node_el):
        """The node's drawn y from <aef:position>, or None when unpositioned.

        ``y == 0`` is the designer's *sentinel* for "no position was encoded":
        src:9710-9713 defaults an absent/NaN position to y=0 and src:9805 then
        patches it to the lane centre. Reading it as a real coordinate would
        invent geometry the map never carried, so it counts as unpositioned
        here too — both sides must agree what "unpositioned" means.
        """
        pos = node_el.find(
            "{%s}extensionElements/{%s}position" % (BPMN_NS, AEF_NS)
        )
        if pos is None:
            return None
        raw = pos.get("y")
        if raw is None:
            return None
        try:
            y = float(raw)
        except (TypeError, ValueError):
            return None
        return None if y == 0 else y

    @staticmethod
    def _fmt_y(value):
        return str(int(value)) if float(value).is_integer() else str(value)

    def _flow_nodes(self, process):
        """Flow nodes of a process as ({id: element}, [id, ...]) in document order."""
        node_el = {}
        doc_order = []
        for child in list(process):
            local = self._local(child.tag)
            if local == "sequenceFlow" or local in XML_NON_FLOWNODE_TAGS:
                continue
            nid = child.get("id")
            if nid is None:
                continue
            node_el[nid] = child
            doc_order.append(nid)
        return node_el, doc_order

    def _lane_members(self, lane, node_el):
        """Resolvable flowNodeRef members of a lane, in declaration order."""
        members = []
        for ref_el in lane.findall("{%s}flowNodeRef" % BPMN_NS):
            ref = (ref_el.text or "").strip()
            if ref and ref in node_el:
                members.append(ref)
        return members

    def _check_lane_geometry(self, process):
        """Lane/geometry agreement (T-312), mirroring AEF `fw corpus lint::lane_geometry`.

        Predicate, settled jointly with AEF at rail 339 and adopted verbatim:

          For lanes in laneSet DECLARATION order, the y-ranges of nodes grouped
          by DECLARED lane must be strictly ordered and non-overlapping.
          Evaluate only when: >=2 lanes, >=2 lanes populated, and EVERY node
          positioned. Otherwise SKIP (do not pass) — an unevaluable map must
          not report clean.
          Report per violating ADJACENT lane pair, naming the extremal witness
          pair: the upper lane's lowest-drawn node and the lower lane's
          highest-drawn node. Equal y counts as a crossing (two nodes on one
          row cannot be in two bands).
          Distinguish repair shape by crossing counts: 100% of both sides =>
          wholesale inversion => laneSet reorder (zero-semantic). A subset =>
          placement or stale membership on the named nodes => authority call,
          not a layout call.

        The predicate is deliberately ORIGIN-FREE: it never reconstructs band
        boundaries. Do not "improve" it by walking cumulative lane heights from
        POOL_Y + POOL_HEADER the way the renderer does (laneTop/laneAtY) — that
        needs an origin the map does not store, and anchoring at the topmost
        node produced 7 phantom mismatches on AEF's draft-trigger-handling,
        which is clean under this rule (rail 339).

        Adjacent pairs are sufficient: the relation is transitive across
        populated lanes, since each populated group has min <= max.
        """
        lane_set = process.find("{%s}laneSet" % BPMN_NS)
        lanes = (
            lane_set.findall("{%s}lane" % BPMN_NS) if lane_set is not None else []
        )

        node_el, doc_order = self._flow_nodes(process)

        # group by DECLARED lane (flowNodeRef), in laneSet declaration order
        groups = [
            (lane.get("id") or "?", self._lane_members(lane, node_el))
            for lane in lanes
        ]
        populated = [g for g in groups if g[1]]

        # Out of scope rather than unevaluable: with fewer than two populated
        # lanes there is no ordering claim to disagree with. Silent by design —
        # a note on every single-lane map would be noise, not signal.
        if len(lanes) < 2 or len(populated) < 2:
            return

        ys = {nid: self._node_y(node_el[nid]) for nid in doc_order}
        missing = [nid for nid in doc_order if ys[nid] is None]
        if missing:
            # SKIP, not PASS. This map has an ordering claim but no geometry to
            # check it against; reporting it clean would be the false green.
            self.info(
                "I-XML-LANE-GEOMETRY-SKIP",
                "laneSet",
                "lane/geometry agreement not evaluated: %d of %d flow node(s) "
                "carry no <aef:position> y (e.g. %s). Geometry that does not "
                "exist cannot disagree with the declared lanes — this map is "
                "SKIPPED by lane_geometry, not passed by it"
                % (len(missing), len(doc_order), ", ".join(sorted(missing)[:3])),
            )
            return

        for (upper_id, upper), (lower_id, lower) in zip(populated, populated[1:]):
            # extremal witness pair; max/min keep the first extremum, so ties
            # resolve in laneSet declaration order
            up_lowest = max(upper, key=lambda n: ys[n])
            lo_highest = min(lower, key=lambda n: ys[n])
            # strictly ordered and non-overlapping; equal y counts as a crossing
            if ys[up_lowest] < ys[lo_highest]:
                continue

            cross_up = [n for n in upper if ys[n] >= ys[lo_highest]]
            cross_lo = [n for n in lower if ys[n] <= ys[up_lowest]]
            if len(cross_up) == len(upper) and len(cross_lo) == len(lower):
                repair = (
                    "every node on both sides crosses, so this is a wholesale "
                    "inversion: reorder the laneSet (zero-semantic repair)"
                )
            else:
                repair = (
                    "only a subset crosses, so this is placement or stale "
                    "membership on the named nodes: an authority call, not a "
                    "layout call"
                )
            self.warn(
                "W-XML-LANE-GEOMETRY",
                "lane '%s' -> lane '%s'" % (upper_id, lower_id),
                "declared lane order disagrees with geometry (lane_geometry): "
                "lane '%s' is declared above lane '%s', but its lowest-drawn "
                "node '%s' (y=%s) is at or below '%s' (y=%s), the highest-drawn "
                "node of the lower lane; %d/%d and %d/%d nodes cross — %s"
                % (
                    upper_id,
                    lower_id,
                    up_lowest,
                    self._fmt_y(ys[up_lowest]),
                    lo_highest,
                    self._fmt_y(ys[lo_highest]),
                    len(cross_up),
                    len(upper),
                    len(cross_lo),
                    len(lower),
                    repair,
                ),
            )

    def _check_lane_capacity(self, process):
        """Lane capacity (T-313), mirroring AEF `fw corpus lint::lane_overflow`.

        Ordering (``_check_lane_geometry``) compares lanes against EACH OTHER and
        is structurally blind to a lane that cannot contain its OWN members. This
        is that rule: a lane whose members' occupancy extent exceeds its declared
        height draws part of itself past the band edge.

        Gated on CONTAINMENT, strict: ``extent > height``. A box whose bottom edge
        lands exactly ON the band edge is contained and does not fire.

        This is DELIBERATELY not the Clean fixpoint
        ``height == extent + 2*LANE_FIT_MARGIN``. A lane that contains its content
        while missing the fixpoint is one Clean away from tidy, not broken, and
        (AEF, rail 341) "a lint that reports tidiness as breakage trains people to
        ignore it". Tidiness is the mapMessiness nudge's job (T-102), not this
        rule's. Our two toolchains therefore agree exactly, including on the lanes
        they both decline to report — the divergence is pinned by a test so a
        future "consistency fix" has to delete a named case to happen.

        Occupancy, not height, and the lowest node is found by botOf rather than
        by y: AEF's fixture has a gateway at y=199 reaching 265 and a task at
        y=200 reaching 264, so a largest-y sort names the wrong node, and their
        live session-lifecycle case has a gateway as its lowest member.

        Composition with the ordering rule, which is why this runs second: bands
        tile the axis contiguously in declaration order, so heights are the only
        free variable. A set of heights that contains every lane exists iff the
        lanes' member extents are already ordered and non-overlapping — i.e. iff
        lane_geometry is clean. So on an ordering-clean map this is repairable
        with zero node movement, and on an ordering-dirty one it is not
        repairable by heights at all.
        """
        lane_set = process.find("{%s}laneSet" % BPMN_NS)
        lanes = (
            lane_set.findall("{%s}lane" % BPMN_NS) if lane_set is not None else []
        )
        if not lanes:
            return
        node_el, _ = self._flow_nodes(process)

        # If the lanes are out of order, no set of heights can contain them; say
        # so in the repair rather than advising a height change that cannot work.
        ordering_dirty = any(
            f.rule == "W-XML-LANE-GEOMETRY" for f in self.findings
        )

        for lane in lanes:
            lane_id = lane.get("id") or "?"
            members = self._lane_members(lane, node_el)
            meta = lane.find(
                "{%s}extensionElements/{%s}laneMeta" % (BPMN_NS, AEF_NS)
            )
            raw_h = meta.get("height") if meta is not None else None
            try:
                height = float(raw_h)
            except (TypeError, ValueError):
                height = None

            # Out of scope, not unevaluable: a lane with no members or no declared
            # height makes NO containment claim. Silent by design — otherwise every
            # hand-authored heightless fixture gains a permanent unresolvable note.
            if not members or height is None:
                continue

            unknown = sorted(
                {
                    self._local(node_el[m].tag)
                    for m in members
                    if self._local(node_el[m].tag) not in NODE_OCCUPANCY
                }
            )
            if unknown:
                # SKIP rather than default to a guessed occupancy. Defaulting would
                # silently under- or over-report forever; the coverage test in
                # tests/test_t313_lane_capacity.py is what stops this from becoming
                # a permanent quiet skip as the palette grows.
                self.info(
                    "I-XML-LANE-CAPACITY-SKIP",
                    "lane '%s'" % lane_id,
                    "lane capacity not evaluated: no occupancy is known for node "
                    "type(s) %s, and guessing one would misreport the band by the "
                    "size of the guess — this lane is SKIPPED by lane_overflow, "
                    "not passed by it" % ", ".join(unknown),
                )
                continue

            ys = {m: self._node_y(node_el[m]) for m in members}
            missing = sorted(m for m in members if ys[m] is None)
            if missing:
                self.info(
                    "I-XML-LANE-CAPACITY-SKIP",
                    "lane '%s'" % lane_id,
                    "lane capacity not evaluated: %d of %d member(s) carry no "
                    "<aef:position> y (e.g. %s). A band cannot be shown to "
                    "overflow content that was never placed — this lane is "
                    "SKIPPED by lane_overflow, not passed by it"
                    % (len(missing), len(members), ", ".join(missing[:3])),
                )
                continue

            occ = {m: NODE_OCCUPANCY[self._local(node_el[m].tag)] for m in members}
            # the lowest-drawn node is the one with the greatest BOTTOM edge, which
            # is not necessarily the one with the greatest y
            lowest = max(members, key=lambda m: ys[m] + occ[m])
            bottom = ys[lowest] + occ[lowest]
            top = min(ys[m] for m in members)
            extent = bottom - top
            if extent <= height:
                continue

            tidy = extent + 2 * LANE_FIT_MARGIN
            if ordering_dirty:
                repair = (
                    "the lanes on this map are NOT in order (see "
                    "W-XML-LANE-GEOMETRY), and while that holds no set of lane "
                    "heights can contain them — resolve the ordering first, after "
                    "which this becomes a pure height change"
                )
            else:
                repair = (
                    "the lanes on this map are in order, so growing the declared "
                    "height to at least %s (%s for the Clean fixpoint) fixes this "
                    "with ZERO node movement — bands tile the axis, so heights are "
                    "the only free variable"
                    % (self._fmt_y(extent), self._fmt_y(tidy))
                )
            self.warn(
                "W-XML-LANE-CAPACITY",
                "lane '%s'" % lane_id,
                "lane cannot contain its own members (lane_overflow): declared "
                "height %s, member extent %s, spilling %s px past the band edge. "
                "Lowest-drawn node is '%s' (%s at y=%s, occupies %d, bottom edge "
                "%s) — chosen by bottom edge, not by y. %s"
                % (
                    self._fmt_y(height),
                    self._fmt_y(extent),
                    self._fmt_y(extent - height),
                    lowest,
                    self._local(node_el[lowest].tag),
                    self._fmt_y(ys[lowest]),
                    occ[lowest],
                    self._fmt_y(bottom),
                    repair,
                ),
            )

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
        # AUTHORITY_OWNER / TYPE_PERFORMER are module-scope (T-322) so this form
        # and the canonical YAML form cannot drift on the authority collapse.
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
            # T-329: the §5 vocabulary gate, on the form the designer authors.
            # Until this existed, authority="overlord" was carried faithfully
            # into <aef:laneMeta> and read by nothing here -- so the check lived
            # only on the form neither the designer nor AEF consumes.
            #
            # AUTHORITIES is the module-scope set the YAML form reads (T-322).
            # Deliberately NOT re-listed here: a second copy of the vocabulary
            # is how the one-form-only family reproduces itself one level down,
            # with the two forms drifting on the governance question itself.
            if authority is not None and authority not in AUTHORITIES:
                self.err(
                    "E-XML-AUTHORITY",
                    "lane '%s'" % (lane.get("id") or "?"),
                    "authority '%s' not in %s"
                    % (authority, sorted(AUTHORITIES)),
                )
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

            # T-331 -- counterpart of the YAML form's W-LANE-NO-OWNER, built in
            # the same task rather than left for a later parity census to find.
            # This is the form AEF's compiler consumes, and it is where the
            # consequence lands: their compiler falls to `owner = type_owner or
            # "agent"` on a lane that resolves to nothing, silently (their
            # OBS-120). An owner appears downstream that no table here granted.
            if local in TYPE_PERFORMER and authority in AUTHORITY_NO_OWNER_DERIVABLE:
                self.warn(
                    "W-LANE-NO-OWNER",
                    "node '%s'" % nid,
                    "%s is a task but its lane authority '%s' has no compiled "
                    "outcome; mapping-v1 §3 makes the lane the sole "
                    "authority-of-record, so this task has no derivable owner "
                    "and a downstream compiler must invent one"
                    % (local, authority),
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
    notes = sum(1 for f in findings if f.severity == INFO)
    if not findings:
        lines.append("VALID  %s -- no findings" % path)
    elif not errors and not warns:
        # notes only: still VALID, and still "no findings" in the blocking sense
        lines.append("VALID  %s -- no findings, %d note(s)" % (path, notes))
    else:
        lines.append(
            "%s  %s -- %d error(s), %d warning(s)%s"
            % (
                "INVALID" if errors else "WARN",
                path,
                errors,
                warns,
                ", %d note(s)" % notes if notes else "",
            )
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
