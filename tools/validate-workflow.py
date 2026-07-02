#!/usr/bin/env python3
"""Schema validator for AEF Workflow Designer files (YAML canonical form).

Validates the workflow file format produced by the AEF Workflow Designer against
the contract in docs/designer/schema.md (see especially section 7.3 "Validation"
and the required-field tables in sections 3, 4.1, 5, 6.1).

This is a STRUCTURAL validator only. It does not execute workflows -- the
`fw workflow run` runtime executor is explicitly out of scope (T-002 scope fence).
It operates on the YAML canonical form, which is the AEF-canonical,
source-controlled, hand-authorable representation and the producer<->executor
contract. In the YAML form, edges reference node `uid`s (not displayIds).

Exit codes (AEF audit convention):
    0  valid          -- no findings
    1  warnings only  -- convention issues, still usable
    2  invalid        -- one or more hard-rule errors (or a load failure)

Usage:
    python3 tools/validate-workflow.py <file.yaml> [--json] [--quiet]

Standalone by design (not wired into the vendored `fw` CLI) to respect the
product/framework boundary and Directive 4 (Portability); the framework may
later adopt it as `fw workflow validate`.
"""

import argparse
import json
import sys

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


def exit_code(findings):
    if any(f.severity == ERROR for f in findings):
        return 2
    if any(f.severity == WARN for f in findings):
        return 1
    return 0


def load_workflow(path, validator):
    try:
        with open(path, "r") as fh:
            return yaml.safe_load(fh)
    except FileNotFoundError:
        validator.err("E-LOAD", path, "file not found")
    except yaml.YAMLError as exc:
        validator.err("E-YAML-PARSE", path, "YAML parse error: %s" % exc)
    return None


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
        description="Validate an AEF Workflow Designer YAML file against the schema."
    )
    parser.add_argument("file", help="path to the workflow YAML file")
    parser.add_argument(
        "--json", action="store_true", help="emit findings as JSON"
    )
    parser.add_argument(
        "--quiet", action="store_true", help="suppress the human-readable report"
    )
    args = parser.parse_args(argv)

    validator = Validator()
    doc = load_workflow(args.file, validator)
    if not any(f.rule in ("E-LOAD", "E-YAML-PARSE") for f in validator.findings):
        validator.validate(doc)

    code = exit_code(validator.findings)

    if args.json:
        print(
            json.dumps(
                {
                    "file": args.file,
                    "exit_code": code,
                    "findings": [f.as_dict() for f in validator.findings],
                },
                indent=2,
            )
        )
    elif not args.quiet:
        print(render_text(args.file, validator.findings))

    return code


if __name__ == "__main__":
    sys.exit(main())
