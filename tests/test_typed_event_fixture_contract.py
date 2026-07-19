#!/usr/bin/env python3
"""Typed-event fixture contract (T-212) — the 832-authored canonical typed-event
fixtures for the designer↔AEF typed-event cross-validation seam (rail offsets 88/89;
AEF ref T-2552 aef:eventDef detector), arc: designer-authoring-surface.

WHY a sha-pin contract beside test_typed_events.py: that harness drives the REAL editor
runtime (parseBpmnXml → buildBpmnXml) and asserts decode/encode CORRECTNESS — but it is
SKIPPED whenever node/chromium is absent (a browser-less CI has ZERO guard on these
fixtures), it covers only typed-events.bpmn, and it does NOT pin the bytes. These two
fixtures are the shared byte-identical artifact AEF cross-validates against (T-559 "pinned
sha" half of the producer contract); a silent edit to either would break AEF's
cross-validation with no local failure. This test pins the exact bytes AEF now holds and
asserts the aef:-extension typed-event SHAPE that makes each sha meaningful — in PURE
PYTHON (stdlib only), so it runs in EVERY environment, browser or not.

BOUNDARY REALITY (T-559 symmetric): this asserts the 832-side producer INPUT only —
byte-determinism + the aef:-extension typed-event shape (IW-1: the kind rides
<aef:eventDef>, NO native bpmn:*EventDefinition). It does NOT assert AEF's detector OUTPUT;
that lives in AEF's bats (T-2552). Complements — does not duplicate — test_typed_events.py.

Runnable standalone (`python3 tests/test_typed_event_fixture_contract.py`, exit 0 = pass)
and under pytest. Wired into tests/run-bridge-tests.sh.
"""
import hashlib
import os
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURES = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn")

BPMN = "http://www.omg.org/spec/BPMN/20100524/MODEL"
AEF = "http://anchorpoint.framework/aef/extensions"


def _q(ns, tag):
    return "{%s}%s" % (ns, tag)


# source_bpmn_sha reconcile keys — pinned; AEF cross-validates byte-exact against these
# (rail offsets 88/89). If a fixture is edited, re-pin HERE + notify AEF on the rail.
TYPED = "typed-events.bpmn"
TYPED_SHA = "5467071b3a3909629b224ed6357abb5fc8a57c12e18e402106307dd91d2ca5ff"
BOUNDARY = "boundary-events.bpmn"
BOUNDARY_SHA = "37eec1b0f10ad02aa5622e28e0e9977ae8bfa9308f59fd36d91048da6d106f1a"


def _read_bytes(name):
    with open(os.path.join(FIXTURES, name), "rb") as fh:
        return fh.read()


def _has_native_event_definition(root):
    """True if any element is a native bpmn:*EventDefinition — the IW-1 violation."""
    for el in root.iter():
        if el.tag.startswith("{%s}" % BPMN) and el.tag.endswith("EventDefinition"):
            return True
    return False


def check_typed_shape(text):
    """Shape invariants for typed-events.bpmn. Returns list of problems (empty == clean)."""
    problems = []
    try:
        root = ET.fromstring(text)
    except ET.ParseError as e:
        return ["typed: not well-formed XML: %s" % e]

    catches = list(root.iter(_q(BPMN, "intermediateCatchEvent")))
    if len(catches) != 3:
        problems.append("typed: expected 3 intermediateCatchEvent, found %d" % len(catches))

    kinds = []
    for ev in catches:
        defs = ev.findall("./%s/%s" % (_q(BPMN, "extensionElements"), _q(AEF, "eventDef")))
        if len(defs) != 1:
            problems.append(
                "typed: event %s has %d aef:eventDef (expected 1)"
                % (ev.get("id"), len(defs))
            )
            continue
        k = defs[0].get("kind")
        kinds.append(k)
        if not defs[0].get("binding"):
            problems.append("typed: event %s aef:eventDef missing binding" % ev.get("id"))
    if set(kinds) != {"error", "timer", "message"}:
        problems.append(
            "typed: eventDef kinds must be {error,timer,message}; got %s" % sorted(kinds)
        )

    if _has_native_event_definition(root):
        problems.append(
            "typed: native bpmn:*EventDefinition present — violates IW-1 "
            "(kind must ride aef:eventDef only)"
        )
    return problems


def check_boundary_shape(text):
    """Shape invariants for boundary-events.bpmn. Returns list of problems."""
    problems = []
    try:
        root = ET.fromstring(text)
    except ET.ParseError as e:
        return ["boundary: not well-formed XML: %s" % e]

    bnds = list(root.iter(_q(BPMN, "boundaryEvent")))
    if len(bnds) != 2:
        problems.append("boundary: expected 2 boundaryEvent, found %d" % len(bnds))

    cancels = []
    for ev in bnds:
        if not ev.get("attachedToRef"):
            problems.append("boundary: %s missing attachedToRef" % ev.get("id"))
        ca = ev.get("cancelActivity")
        cancels.append(ca)
        ext = ev.find(_q(BPMN, "extensionElements"))
        if ext is None or ext.find(_q(AEF, "eventDef")) is None:
            problems.append("boundary: %s missing aef:eventDef" % ev.get("id"))
        if ext is None or ext.find(_q(AEF, "boundaryPos")) is None:
            problems.append("boundary: %s missing aef:boundaryPos" % ev.get("id"))
    # one interrupting (true) and one non-interrupting (false) — the two variants
    # AEF's detector must both catch.
    if set(cancels) != {"true", "false"}:
        problems.append(
            "boundary: cancelActivity must be {true,false} (one interrupting, one "
            "non-interrupting); got %s" % sorted(str(c) for c in cancels)
        )

    if _has_native_event_definition(root):
        problems.append(
            "boundary: native bpmn:*EventDefinition present — violates IW-1 "
            "(kind must ride aef:eventDef only)"
        )
    return problems


def failures():
    fails = []

    for name, pinned, checker in (
        (TYPED, TYPED_SHA, check_typed_shape),
        (BOUNDARY, BOUNDARY_SHA, check_boundary_shape),
    ):
        raw = _read_bytes(name)
        text = raw.decode("utf-8")

        # (1) byte-determinism — sha256 over exact bytes == pin, recompute-stable
        h1 = hashlib.sha256(raw).hexdigest()
        h2 = hashlib.sha256(_read_bytes(name)).hexdigest()
        if h1 != pinned:
            fails.append(
                "(1) %s sha256 %s != pinned %s — source_bpmn_sha changed (fixture "
                "edited? re-pin in this test + notify AEF on the rail)" % (name, h1, pinned)
            )
        if h1 != h2:
            fails.append("(1) %s sha256 not recompute-stable: %s vs %s" % (name, h1, h2))

        # (2) shape — the aef:-extension typed-event invariants that make the sha mean
        #     something (a re-pin can't silently drop the contract semantics)
        shape = checker(text)
        if shape:
            fails.append("(2) %s shape violations: %s" % (name, shape))

    # (3a) teeth — stripping a typed eventDef must be caught by the shape check, proving
    #      the invariant is not vacuous (mirrors the "kinds set" assertion).
    typed_text = _read_bytes(TYPED).decode("utf-8")
    broken_typed = typed_text.replace(
        '<aef:eventDef kind="timer" binding="0 9 * * *"/>', "", 1
    )
    if broken_typed == typed_text:
        fails.append("(3a) mutation no-op: typed timer eventDef marker not found")
    elif not check_typed_shape(broken_typed):
        fails.append("(3a) stripped typed eventDef NOT detected by shape check — no teeth")

    # (3b) teeth — injecting a native bpmn:timerEventDefinition must trip the IW-1 guard.
    boundary_text = _read_bytes(BOUNDARY).decode("utf-8")
    injected = boundary_text.replace(
        '<aef:eventDef kind="timer" binding="0 0 * * *"/>',
        '<aef:eventDef kind="timer" binding="0 0 * * *"/>'
        '<bpmn:timerEventDefinition/>',
        1,
    )
    if injected == boundary_text:
        fails.append("(3b) mutation no-op: boundary timer eventDef marker not found")
    elif not check_boundary_shape(injected):
        fails.append(
            "(3b) injected native bpmn:*EventDefinition NOT detected by shape check — "
            "IW-1 guard has no teeth"
        )

    return fails


def test_typed_event_fixture_contract():
    fails = failures()
    assert not fails, "typed-event fixture contract failures:\n" + "\n".join(fails)


def main():
    fails = failures()
    if fails:
        for f in fails:
            sys.stderr.write("FAIL: %s\n" % f)
        sys.stderr.write("\n%d contract failure(s)\n" % len(fails))
        return 1
    print(
        "OK: typed-event fixture contract — %s (sha %s), %s (sha %s)"
        % (TYPED, TYPED_SHA[:12], BOUNDARY, BOUNDARY_SHA[:12])
    )
    print(
        "  byte-determinism + aef:eventDef shape (3 intermediate kinds; 2 boundary "
        "interrupting/non-interrupting) + no-native-EventDefinition (IW-1) + teeth verified"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
