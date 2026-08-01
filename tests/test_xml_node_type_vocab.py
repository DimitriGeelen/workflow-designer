#!/usr/bin/env python3
"""T-321 — the XML flow-node vocabulary is DERIVED, and stays agreed with both emitters.

`XML_NODE_TYPES` in tools/validate-workflow.py is not a hand-written list beside
`NODE_TYPES`. It is `{XML_TYPE_MAP.get(t, t) for t in NODE_TYPES} | XML_ONLY_NODE_TYPES`
— a translation of the canonical vocabulary plus one declared extension. Two
hand-maintained lists describing one modelling language drift, which is the T-322
defect one level up.

The translation table itself IS a hand-copy (the validator stays standalone and
does not import the bridge at load time), so this module is the drift guard that
makes it a declaration rather than a copy. It asserts the validator's map agrees
with BOTH emitters:

  - the bridge          tools/yaml-to-bpmn.py            TYPE_MAP
  - the designer        src/aef-workflow-designer.html   TYPE_TAG

Measured when written, over 96 authored BPMN: both emitters produce EXACTLY the
same 10 element names, and the corpus carried two elements neither can produce —
`boundaryEvent` (legal BPMN, the one declared extension) and `linkEventThrow`
(not a BPMN element at all; the YAML type name in the BPMN namespace).

T-324 UPDATE: the `linkEventThrow` instances are GONE from the corpus — all three
lived in the byte-pinned offpage-seam.bpmn and were repaired by coordinated re-pin
with AEF. `boundaryEvent` remains the one declared extension. Note this does NOT
weaken the gate: the vocabulary is still a DECLARED superset measured against both
emitters, not a list of what the corpus happens to contain today. A rule derived
from corpus content would now have nothing to say about linkEventThrow at all.

Runnable standalone (exit 0 = pass) and under pytest. Wired into
tests/run-bridge-tests.sh.
"""
import importlib.util
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load(rel, name):
    path = os.path.join(ROOT, rel)
    if not os.path.isfile(path):
        raise RuntimeError(
            "%s is missing -- this guard cannot evaluate the vocabulary "
            "agreement and must not pass quiet" % rel)
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _designer_type_tag():
    """TYPE_TAG from the designer source, scraped from the literal."""
    path = os.path.join(ROOT, "src", "aef-workflow-designer.html")
    if not os.path.isfile(path):
        raise RuntimeError("designer source missing at %s" % path)
    src = open(path, encoding="utf-8").read()
    block = re.search(r"const TYPE_TAG\s*=\s*\{(.*?)\n\}", src, re.S)
    if not block:
        raise RuntimeError(
            "could not locate `const TYPE_TAG = {...}` in the designer source. "
            "Renamed or restructured -- an empty map would make every "
            "agreement assertion below pass trivially.")
    pairs = dict(re.findall(r"(\w+)\s*:\s*'(\w+)'", block.group(1)))
    if not pairs:
        raise RuntimeError("TYPE_TAG located but parsed to zero entries")
    return pairs


def failures():
    fails = []
    v = _load("tools/validate-workflow.py", "_t321_validator")
    bridge = _load("tools/yaml-to-bpmn.py", "_t321_bridge")
    designer = _designer_type_tag()

    if not v.NODE_TYPES or not v.XML_NODE_TYPES:
        fails.append("NODE_TYPES or XML_NODE_TYPES is empty -- an empty "
                     "vocabulary admits every element, so the gate would pass "
                     "the very typo it exists to catch")
        return fails

    # (1) the validator's translation agrees with the bridge, over the keys that
    #     actually matter: the canonical node types.
    for t in sorted(v.NODE_TYPES):
        want = bridge.TYPE_MAP.get(t, t)
        got = v.XML_TYPE_MAP.get(t, t)
        if want != got:
            fails.append(
                "(1) node type %r: validator translates to %r, the bridge emits "
                "%r. The validator would reject bytes the bridge produces (or "
                "admit an element nothing can write)." % (t, got, want))

    # (2) ...and with the designer, which is the OTHER thing that writes these
    #     bytes. Agreement with one emitter is not agreement.
    for t in sorted(v.NODE_TYPES):
        if t not in designer:
            continue
        want = designer[t]
        got = v.XML_TYPE_MAP.get(t, t)
        if want != got:
            fails.append(
                "(2) node type %r: validator translates to %r, the designer "
                "emits %r" % (t, got, want))

    # (3) the derived set is exactly translation + declared extension. Guards
    #     against someone widening XML_NODE_TYPES directly instead of declaring
    #     the extension, which is how the two forms would start drifting again.
    derived = {v.XML_TYPE_MAP.get(t, t) for t in v.NODE_TYPES} | set(v.XML_ONLY_NODE_TYPES)
    if set(v.XML_NODE_TYPES) != derived:
        fails.append(
            "(3) XML_NODE_TYPES is not (translation | XML_ONLY_NODE_TYPES): "
            "extra=%s missing=%s -- widen XML_ONLY_NODE_TYPES with a reason "
            "instead of editing the derived set"
            % (sorted(set(v.XML_NODE_TYPES) - derived),
               sorted(derived - set(v.XML_NODE_TYPES))))

    # (4) every declared XML-only type must be a type no emitter can produce.
    #     If an emitter CAN produce it, it belongs in the translation, and
    #     listing it here hides a real vocabulary from NODE_TYPES.
    producible = {bridge.TYPE_MAP.get(t, t) for t in v.NODE_TYPES}
    producible |= set(designer.values())
    for t in sorted(v.XML_ONLY_NODE_TYPES):
        if t in producible:
            fails.append(
                "(4) %r is declared XML-only but an emitter can produce it -- "
                "it is part of the translation, not an extension" % t)

    return fails


def test_xml_node_type_vocab():
    fails = failures()
    assert not fails, "XML node-type vocabulary drift:\n" + "\n".join(fails)


def main():
    fails = failures()
    if fails:
        for f in fails:
            sys.stderr.write("FAIL: %s\n" % f)
        sys.stderr.write("\n%d vocabulary failure(s)\n" % len(fails))
        return 1
    v = _load("tools/validate-workflow.py", "_t321_summary")
    print("xml node-type vocabulary: OK -- validator agrees with bridge and "
          "designer; %d translated from NODE_TYPES + %d declared XML-only (%s)"
          % (len(v.XML_TRANSLATED_NODE_TYPES),
             len(v.XML_ONLY_NODE_TYPES),
             ", ".join(sorted(v.XML_ONLY_NODE_TYPES))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
