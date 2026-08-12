#!/usr/bin/env python3
"""T-484 — audit the bridge's coverage enumerations by BEHAVIOUR rather than by membership.

T-483 measured that appending seven non-scalar values to the round-trip harness's METAKEYS
would have satisfied every membership check while moving detection from 0/7 to 2/7, because
String() on a dict is the constant "[object Object]". The rule captured and published to AEF
at rail 599:

    A name in a coverage list is a CLAIM. Only a value that varies is EVIDENCE.

I published that generalisation to AEF having measured exactly one of my own lists. This
probe settles it for the bridge's enumerations, or falsifies it.

METHOD. For each key in each enumeration: set that key on a node's `aef` to value A, run the
bridge's emit(), set it to value B, run emit() again. If the two emissions are byte-identical
the key is INERT — it is named in a list that claims coverage and changes nothing. Every node
in the corpus workflow is tried, because a key may only be emitted for certain node types, and
"inert on the node I happened to pick" is not "inert".

The value shape is chosen per enumeration, because the whole T-483 finding was that a wrong
shape stringifies to a constant and reads as coverage:
    META_KEYS                 scalar strings
    STRUCTURED_LIST_KEYS      lists of strings
    STRUCTURED_DICT_KEYS      dicts
    STRUCTURED_ITEMLIST_KEYS  lists of dicts

CONTROLS (AC3, PL-095). Two, because a probe that cannot report inertness proves nothing
about its absence:
    positive  'tier' is known live and MUST be reported LIVE
    negative  a synthetic key in no enumeration MUST be reported INERT
If either control fails the probe refuses to publish a verdict and exits 2.

DENOMINATOR (PL-084). Counts are printed for every outcome including NOT-EXERCISABLE.
This is an AUDIT: nothing found here is fixed here (AC5).

Exit 0 = both controls held and the audit ran. Findings are reported, not gated — an inert
key is a result to file, not a reason to fail the probe.
"""
import contextlib
import copy
import importlib.util
import io
import json
import sys

WORKFLOW = "examples/aef-processes/arc-lifecycle.workflow.yaml"
BRIDGE = "tools/yaml-to-bpmn.py"

# Value pairs per enumeration shape. A and B must differ in a way that MUST reach the output
# if the key is emitted at all.
SHAPES = {
    "META_KEYS":                (["__T484_A__"], ["__T484_B__"], "scalar"),
    "STRUCTURED_LIST_KEYS":     ([["__T484_A__"]], [["__T484_B__"]], "list"),
    "STRUCTURED_DICT_KEYS":     ([{"value": "__T484_A__"}], [{"value": "__T484_B__"}], "dict"),
    "STRUCTURED_ITEMLIST_KEYS": ([[{"id": "__T484_A__", "name": "__T484_A__", "ref": "__T484_A__"}]],
                                 [[{"id": "__T484_B__", "name": "__T484_B__", "ref": "__T484_B__"}]], "itemlist"),
}


def load_bridge():
    spec = importlib.util.spec_from_file_location("y2b", BRIDGE)
    mod = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(mod)
    except SystemExit:
        pass
    return mod


def emit_with(mod, workflow, node_idx, key, value):
    """Emit the workflow with `key` forced to `value` on one node. Returns XML or None."""
    w = copy.deepcopy(workflow)
    nodes = w.get("nodes") or []
    if node_idx >= len(nodes):
        return None
    nodes[node_idx].setdefault("aef", {})[key] = value
    # The bridge writes its "unknown aef key dropped" warnings to STDOUT, not stderr, so an
    # unredirected run interleaves them with this probe's JSON and makes the report
    # unparseable. Captured rather than silenced: the text is part of the emission's
    # behaviour, and a warning that differs between A and B would itself be a live signal.
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            out = mod.emit(w)
    except Exception as e:                      # a key that crashes the bridge is a finding,
        return "EMIT-EXCEPTION: %s" % e         # not a silent skip
    return out + "\n__WARNINGS__\n" + buf.getvalue()


def classify(mod, workflow, key, val_a, val_b):
    """LIVE if ANY node's emission differs between val_a and val_b."""
    nodes = workflow.get("nodes") or []
    exceptions = 0
    for i in range(len(nodes)):
        a = emit_with(mod, workflow, i, key, val_a)
        b = emit_with(mod, workflow, i, key, val_b)
        if a is None or b is None:
            continue
        if isinstance(a, str) and a.startswith("EMIT-EXCEPTION"):
            exceptions += 1
            continue
        if a != b:
            return "LIVE", {"node_index": i, "exceptions": exceptions}
    return "INERT", {"nodes_tried": len(nodes), "exceptions": exceptions}


def main():
    import yaml
    mod = load_bridge()
    workflow = yaml.safe_load(open(WORKFLOW))
    nodes = workflow.get("nodes") or []
    if not nodes:
        print(json.dumps({"pass": False, "error": "corpus workflow has no nodes — verdict would be vacuous"}))
        return 1

    report = {
        "workflow": WORKFLOW,
        "nodes_in_workflow": len(nodes),
        "lists": {},
        "live": [],
        "inert": [],
        "not_exercisable": [],
        "controls": {},
    }

    # ---- controls first; a failed control voids the verdict ------------------------------
    pos_kind, _ = classify(mod, workflow, "tier", "__T484_A__", "__T484_B__")
    neg_kind, _ = classify(mod, workflow, "__t484_synthetic_key__", "__T484_A__", "__T484_B__")
    report["controls"] = {
        "positive_tier_expected_LIVE": pos_kind,
        "negative_synthetic_expected_INERT": neg_kind,
        "held": pos_kind == "LIVE" and neg_kind == "INERT",
    }
    if not report["controls"]["held"]:
        report["pass"] = False
        report["error"] = ("controls did not hold — the probe cannot distinguish live from inert, "
                           "so any clean verdict would be vacuous")
        print(json.dumps(report, indent=2))
        return 2

    # ---- the audit ----------------------------------------------------------------------
    for list_name, (a_vals, b_vals, shape) in SHAPES.items():
        keys = getattr(mod, list_name, None)
        if keys is None:
            report["not_exercisable"].append({"list": list_name, "reason": "not present in bridge module"})
            continue
        members = sorted(keys)
        report["lists"][list_name] = {"members": len(members), "shape": shape}
        for k in members:
            kind, detail = classify(mod, workflow, k, a_vals[0], b_vals[0])
            entry = {"key": k, "list": list_name, "shape": shape, **detail}
            (report["live"] if kind == "LIVE" else report["inert"]).append(entry)

    report["counts"] = {
        "lists_audited": len(report["lists"]),
        "members_audited": sum(v["members"] for v in report["lists"].values()),
        "LIVE": len(report["live"]),
        "INERT": len(report["inert"]),
        "NOT_EXERCISABLE": len(report["not_exercisable"]),
    }
    report["inert_keys"] = sorted(e["key"] for e in report["inert"])
    report["pass"] = True
    report["summary"] = ("%d lists / %d members audited by behaviour: %d LIVE, %d INERT%s"
                         % (report["counts"]["lists_audited"], report["counts"]["members_audited"],
                            report["counts"]["LIVE"], report["counts"]["INERT"],
                            (" -> " + ",".join(report["inert_keys"])) if report["inert_keys"] else ""))
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
