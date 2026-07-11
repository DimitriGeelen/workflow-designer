#!/usr/bin/env python3
"""test_forward_fixtures — guard the reference BPMN(+aef:) fixture set (T-183, arc:
designer-authoring-surface child-2, forward-bridge 832 support).

`tests/fixtures/aef-bpmn/*.bpmn` are authentic editor-emitted BPMN diagrams that serve as
the reference input corpus for the AEF-led forward bridge (child-2). The forward-compile
spec (`docs/standards/aef-bpmn-forward-compile-v1.md`) documents the expected proposed
task-graph for each. This test guards the fixtures so they cannot silently drift out of v1
conformance (`docs/standards/aef-bpmn-mapping-v1.md`):

  1. every fixture parses as XML;
  2. every flow node AND every sequence flow carries a non-empty `aef:uid` (v1 §5 — the
     round-trip identity hinge; forward compile keys modify-vs-create on it);
  3. every `aef:meta` attribute key is within the bridge `META_KEYS` whitelist
     (typo / unknown-key guard — reuses `bridge_meta_keys` from the parity test);
  4. the governance contract is demonstrably exercised across the set — node scalars
     `tier` + `agentType` appear as `aef:meta`, and `owner` is exercised via lanes
     (`aef:laneMeta`). `horizon`/`workflowType` are authored-optional and legitimately
     absent from these process fixtures (see the spec).

An empty / missing fixtures directory is a FAILURE, not a vacuous pass (PL-022).

Parsers for the bridge whitelist are imported from `test_editor_bridge_meta_parity` so the
fixture guard, the editor↔bridge parity test, and the standard↔implementation conformance
test all share one extraction of the META_KEYS vocabulary.

Pure stdlib. Exit 0 = conformant. Exit 1 = drift. Exit 2 = self-test/extraction failure.
"""
import os
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Single source of truth for the bridge META_KEYS whitelist extraction.
from test_editor_bridge_meta_parity import (  # noqa: E402
    bridge_meta_keys,
    _read,
    BRIDGE,
)

BPMN = "http://www.omg.org/spec/BPMN/20100524/MODEL"
AEF = "http://anchorpoint.framework/aef/extensions"
FIXTURES_DIR = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn")

# BPMN flow-node local names that carry an aef:uid. Events are process-boundary markers
# (no task in v1 §3) but the editor still emits a uid on them, so they are held to the
# same identity requirement.
FLOW_NODE_TAGS = {
    "task", "userTask", "serviceTask", "scriptTask", "manualTask", "sendTask",
    "receiveTask", "businessRuleTask", "callActivity", "subProcess",
    "exclusiveGateway", "parallelGateway", "inclusiveGateway", "eventBasedGateway",
    "complexGateway",
    "startEvent", "endEvent", "intermediateThrowEvent", "intermediateCatchEvent",
    "boundaryEvent",
}

# Frozen v1 governance scalars that these process fixtures carry at node level (v1 §2).
NODE_GOV_SCALARS = ("tier", "agentType")


def _local(tag):
    """Strip an ElementTree `{namespace}local` tag down to `local`."""
    return tag.rsplit("}", 1)[-1]


def _own_uid(el):
    """The element's OWN aef:uid value, or None.

    Looks only at direct children and a direct <bpmn:extensionElements> child — never
    recurses — so a subProcess does not borrow a nested child node's uid.
    """
    direct = el.find("{%s}uid" % AEF)
    if direct is not None and (direct.get("value") or "").strip():
        return direct.get("value").strip()
    ext = el.find("{%s}extensionElements" % BPMN)
    if ext is not None:
        u = ext.find("{%s}uid" % AEF)
        if u is not None and (u.get("value") or "").strip():
            return u.get("value").strip()
    return None


def audit_fixture(path):
    """Return (errors, meta_keys_used, has_lane) for one fixture."""
    errors = []
    meta_keys = set()
    has_lane = False
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as exc:
        return (["does not parse as XML: %s" % exc], meta_keys, has_lane)

    for el in root.iter():
        local = _local(el.tag)
        if el.tag == "{%s}meta" % AEF:
            meta_keys.update(el.attrib.keys())
        if el.tag == "{%s}laneMeta" % AEF or local == "lane":
            has_lane = True
        if local in FLOW_NODE_TAGS:
            if _own_uid(el) is None:
                errors.append("%s id=%r has no aef:uid" % (local, el.get("id")))
        if local == "sequenceFlow":
            if _own_uid(el) is None:
                errors.append("sequenceFlow id=%r has no aef:uid" % el.get("id"))
    return (errors, meta_keys, has_lane)


def _selftest():
    good = (
        '<bpmn:process xmlns:bpmn="%s" xmlns:aef="%s">'
        '<bpmn:serviceTask id="t1"><bpmn:extensionElements>'
        '<aef:uid value="n_1"/><aef:meta tier="1" agentType="primary"/>'
        '</bpmn:extensionElements></bpmn:serviceTask>'
        '<bpmn:sequenceFlow id="f1"><bpmn:extensionElements>'
        '<aef:uid value="e_1"/></bpmn:extensionElements></bpmn:sequenceFlow>'
        '<bpmn:laneSet><bpmn:lane id="L"><bpmn:extensionElements>'
        '<aef:laneMeta abbr="agt"/></bpmn:extensionElements></bpmn:lane></bpmn:laneSet>'
        "</bpmn:process>" % (BPMN, AEF)
    )
    import tempfile
    with tempfile.NamedTemporaryFile("w", suffix=".bpmn", delete=False) as fh:
        fh.write(good)
        p = fh.name
    try:
        errs, keys, lane = audit_fixture(p)
        assert errs == [], "selftest: clean fixture flagged: %r" % errs
        assert keys == {"tier", "agentType"}, "selftest: meta keys wrong: %r" % keys
        assert lane is True, "selftest: lane not detected"
    finally:
        os.unlink(p)

    # A node missing its uid must be flagged.
    bad = (
        '<bpmn:process xmlns:bpmn="%s" xmlns:aef="%s">'
        '<bpmn:serviceTask id="t2"/></bpmn:process>' % (BPMN, AEF)
    )
    with tempfile.NamedTemporaryFile("w", suffix=".bpmn", delete=False) as fh:
        fh.write(bad)
        p = fh.name
    try:
        errs, _, _ = audit_fixture(p)
        assert any("no aef:uid" in e for e in errs), "selftest: missing uid not flagged: %r" % errs
    finally:
        os.unlink(p)


def main():
    try:
        _selftest()
    except AssertionError as exc:
        sys.stderr.write("SELFTEST FAIL: %s\n" % exc)
        return 2

    if not os.path.isdir(FIXTURES_DIR):
        sys.stderr.write("error: fixtures dir %s does not exist — the reference corpus is the "
                         "subject of this test; its absence is a FAILURE, not a skip.\n" % FIXTURES_DIR)
        return 1
    fixtures = sorted(f for f in os.listdir(FIXTURES_DIR) if f.endswith(".bpmn"))
    if not fixtures:
        sys.stderr.write("error: no *.bpmn fixtures in %s (empty corpus is a FAILURE).\n" % FIXTURES_DIR)
        return 1

    whitelist = bridge_meta_keys(_read(BRIDGE))
    if not whitelist:
        sys.stderr.write("error: could not extract bridge META_KEYS from %s.\n" % BRIDGE)
        return 2
    whitelist = set(whitelist)

    all_errors = []
    all_meta_keys = set()
    any_lane = False
    for name in fixtures:
        errs, keys, lane = audit_fixture(os.path.join(FIXTURES_DIR, name))
        all_meta_keys.update(keys)
        any_lane = any_lane or lane
        for e in errs:
            all_errors.append("%s: %s" % (name, e))

    # 3. every aef:meta key is a recognised bridge whitelist key.
    unknown = sorted(k for k in all_meta_keys if k not in whitelist)
    for k in unknown:
        all_errors.append("aef:meta key %r is not in the bridge META_KEYS whitelist (%s)" % (k, BRIDGE))

    # 4. governance contract exercised: tier + agentType at node level, owner via lanes.
    for scalar in NODE_GOV_SCALARS:
        if scalar not in all_meta_keys:
            all_errors.append("frozen governance scalar %r is never exercised across the fixture set" % scalar)
    if not any_lane:
        all_errors.append("no lanes (aef:laneMeta) in any fixture — owner mapping (v1 §3) is not exercised")

    if all_errors:
        sys.stderr.write("FORWARD-FIXTURE CONFORMANCE FAILED:\n")
        for e in all_errors:
            sys.stderr.write("  - %s\n" % e)
        return 1

    print("OK: %d fixture(s) [%s] conformant — every flow node + sequence flow has aef:uid; "
          "all %d aef:meta key(s) within bridge whitelist; governance exercised (tier, agentType, owner-via-lanes)"
          % (len(fixtures), ", ".join(fixtures), len(all_meta_keys)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
