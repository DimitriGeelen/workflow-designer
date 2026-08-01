#!/usr/bin/env python3
"""test_harness_emitter_fidelity.py — T-327.

A harness that synthesises BPMN must synthesise a document our EMITTERS could
actually produce. Otherwise it proves the consumer handles a shape that never
occurs and says nothing about the shape that does — AEF's rail-367 phrasing:
"worse than an absent guard, because an absent guard does not report."

That is not hypothetical. Three gallery harnesses built off-page nodes with
`<bpmn:linkEventThrow>` — our canonical YAML type name in the BPMN namespace,
which is not a BPMN element at any version and which NEITHER emitter can produce
(bridge TYPE_MAP and designer TYPE_TAG both rename it to intermediateThrowEvent).
All three passed, for the same structural reason AEF's Pass 5 passed on the
byte-pinned fixture that carried it (T-324): the ref-scan reads <aef:link> and
never inspects the host tag. A fourth harness used `<bpmn:task>` — legal BPMN,
but still not something either emitter emits.

WHERE THE PERMITTED SET COMES FROM, AND WHY IT MATTERS
------------------------------------------------------
Derived from the emitters, never hand-written:

  node elements  <- tools/validate-workflow.py XML_NODE_TYPES, itself guarded by
                    tests/test_xml_node_type_vocab.py as a DECLARED superset
                    computed from both emitters' type maps.
  scaffolding    <- the literal <bpmn:NAME tags the two emitters themselves write
                    (definitions, process, laneSet, sequenceFlow, ...), scanned
                    from their source.

A hand-written list would drift from the emitters silently. Concretely: after
T-324 no file in the corpus contains `linkEventThrow` anywhere, so a check built
from corpus content would now have nothing to say about it — while the emitters
still cannot produce it, and a harness author can still type it.

WHAT IS SCANNED, AND WHAT IS DELIBERATELY NOT
----------------------------------------------
Only NON-DOCSTRING string literals, via tokenize + ast. Comments are a separate
token type and never reach the scan; module/class/function docstrings are
identified through ast and excluded by position. This is load-bearing, not
tidiness: several files legitimately name <bpmn:linkEventThrow> in prose
explaining T-324, and a scan that reads its own explanation is satisfied by it
(G-009). The negative control below proves both directions.

TOLERANCES ARE COUNTED, NEVER SILENT
-------------------------------------
Some harnesses synthesise a non-emitter element ON PURPOSE, because the element
being un-producible IS the test. Those are declared with a reason, PRINTED every
run, and the count is asserted — so a new violation fails the build instead of
joining the exemption (T-312/T-314/T-317/T-321/T-324 pattern).
"""
import ast
import io
import os
import re
import sys
import tokenize

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")
EMITTERS = [
    os.path.join(ROOT, "tools", "yaml-to-bpmn.py"),
    os.path.join(ROOT, "src", "aef-workflow-designer.html"),
]
SCAN_DIRS = [os.path.join(ROOT, "tools"), os.path.join(ROOT, "tests")]

# Never scanned: the emitters define the vocabulary (scanning them would make the
# guard tautological), and this file names bogus tags in its own control strings.
SELF = os.path.abspath(__file__)
EXCLUDE = {os.path.abspath(p) for p in EMITTERS} | {SELF}

TAG_RE = re.compile(r"<bpmn:([A-Za-z][A-Za-z0-9]*)")

# Counted tolerances — {(basename, element): reason}. Each is a case where the
# element being NOT emitter-producible is the point of the test.
TOLERATED = {
    ("test_t313_lane_capacity.py", "transaction"):
        "deliberate unknown-node-type fixture: asserts lane-capacity SKIPS rather "
        "than guesses occupancy for a type it does not know. An emitter-producible "
        "tag would not exercise the skip path at all.",
    ("test_typed_event_fixture_contract.py", "timerEventDefinition"):
        "deliberate teeth: injects a NATIVE bpmn:timerEventDefinition to prove the "
        "IW-1 guard trips. T-204 fixed that typed events ride <aef:eventDef> and no "
        "native *EventDefinition is ever emitted — so un-producible is the property "
        "under test.",
}
EXPECTED_TOLERATED = 2


def _load_validator():
    import importlib.util
    spec = importlib.util.spec_from_file_location("_vw", VALIDATOR)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _docstring_positions(src):
    """(lineno, col) of every module/class/function docstring token."""
    pos = set()
    try:
        tree = ast.parse(src)
    except SyntaxError:
        return pos
    for node in ast.walk(tree):
        if not isinstance(node, (ast.Module, ast.ClassDef, ast.FunctionDef,
                                 ast.AsyncFunctionDef)):
            continue
        body = getattr(node, "body", None)
        if not body:
            continue
        first = body[0]
        if isinstance(first, ast.Expr) and isinstance(first.value, ast.Constant) \
                and isinstance(first.value.value, str):
            pos.add((first.value.lineno, first.value.col_offset))
    return pos


def code_strings(path):
    """Concatenated text of NON-DOCSTRING string literals. Comments never appear:
    tokenize emits them as COMMENT, which is not collected."""
    with open(path, encoding="utf-8", errors="replace") as fh:
        src = fh.read()
    docs = _docstring_positions(src)
    out = []
    try:
        for tok in tokenize.generate_tokens(io.StringIO(src).readline):
            if tok.type == tokenize.STRING and tok.start not in docs:
                out.append(tok.string)
    except (tokenize.TokenError, IndentationError, SyntaxError):
        # Never fail open on an unparseable file — an unreadable scan target must
        # be loud, not silently contribute zero tags.
        raise RuntimeError("could not tokenize %s — the scan would silently skip "
                           "it and report clean" % path)
    return "\n".join(out)


def _emitter_scaffolding():
    """Literal <bpmn:NAME tags the emitters themselves write."""
    names = set()
    for p in EMITTERS:
        with open(p, encoding="utf-8", errors="replace") as fh:
            src = fh.read()
        if p.endswith(".html"):
            src = re.sub(r"//.*$", "", src, flags=re.M)
            src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
        else:
            src = "\n".join(re.sub(r"#.*$", "", l) for l in src.splitlines())
        names |= set(TAG_RE.findall(src))
    return names


def scan_targets():
    out = []
    for d in SCAN_DIRS:
        for dp, dn, fn in os.walk(d):
            if "fixtures" in dp or "__pycache__" in dp:
                continue
            for f in sorted(fn):
                if not f.endswith(".py"):
                    continue
                p = os.path.abspath(os.path.join(dp, f))
                if p not in EXCLUDE:
                    out.append(p)
    return sorted(out)


def failures():
    fails = []
    v = _load_validator()

    node_types = set(v.XML_NODE_TYPES)
    scaffolding = _emitter_scaffolding()
    permitted = node_types | scaffolding

    if not node_types:
        fails.append("(0) XML_NODE_TYPES is empty — an empty permitted set would "
                     "flag everything; an empty scaffolding set would flag the "
                     "document skeleton. Either reads as a broken guard, not a "
                     "clean tree.")
    if not scaffolding:
        fails.append("(0) no <bpmn: literals found in either emitter — the "
                     "scaffolding derivation is broken. A guard whose permitted "
                     "set collapses to node types alone would flag <bpmn:process "
                     "in every harness and be switched off.")

    targets = scan_targets()
    if not targets:
        fails.append("(0) scan surface is EMPTY — zero .py files under tools/ and "
                     "tests/. A scan pointed at nothing reports clean and is "
                     "indistinguishable from a clean tree (AEF rail-367: a "
                     "capability gap reported against a directory that never "
                     "existed).")

    seen_tolerated = {}
    violations = []
    for path in targets:
        base = os.path.basename(path)
        for name in sorted(set(TAG_RE.findall(code_strings(path)))):
            if name in permitted:
                continue
            key = (base, name)
            if key in TOLERATED:
                seen_tolerated[key] = seen_tolerated.get(key, 0) + 1
                continue
            violations.append((base, name))

    for base, name in violations:
        fails.append(
            "(1) %s synthesises <bpmn:%s>, which NEITHER emitter can produce. "
            "A harness asserting against a document shape we cannot emit proves "
            "the consumer handles bytes that never occur. Either use the tag the "
            "emitter produces, or — if un-producibility IS the property under "
            "test — declare it in TOLERATED with a reason."
            % (base, name))

    # Tolerances print every run and their count is asserted (never silent).
    for (base, name), reason in sorted(TOLERATED.items()):
        if (base, name) not in seen_tolerated:
            fails.append(
                "(2) declared tolerance (%s, %s) no longer fires — the harness was "
                "changed or removed. A tolerance outliving its reason is how an "
                "exemption list stops describing the tree." % (base, name))
        else:
            print("  NOTE (tolerated, T-327): %s synthesises <bpmn:%s> on purpose "
                  "— %s" % (base, name, reason))

    if len(TOLERATED) != EXPECTED_TOLERATED:
        fails.append("(2) TOLERATED holds %d entries, expected %d — a tolerance "
                     "was added or removed without moving the assertion."
                     % (len(TOLERATED), EXPECTED_TOLERATED))

    print("  harness emitter fidelity: %d files scanned, %d permitted element "
          "names (%d node types from XML_NODE_TYPES + %d scaffolding literals "
          "read off both emitters), %d tolerated, %d violations."
          % (len(targets), len(permitted), len(node_types), len(scaffolding),
             len(seen_tolerated), len(violations)))
    return fails


def test_harness_emitter_fidelity():
    fails = failures()
    assert not fails, "\n".join(fails)


def main():
    fails = failures()
    if fails:
        print("\nFAIL (%d):" % len(fails))
        for f in fails:
            print("  - %s" % f)
        return 1
    print("OK: every synthesised <bpmn:*> element is one an emitter can produce")
    return 0


if __name__ == "__main__":
    sys.exit(main())
