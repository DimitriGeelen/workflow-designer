#!/usr/bin/env python3
"""
_t423-position-carrier-guard.py — aef:position is the geometry carrier, and it must stay
one carrier per node until something deliberately replaces it.

T-423 (arc-001, anchor T-175). Adopts AEF's instrument, not just their answer: they pin
`test_di_drop_has_a_competing_carrier`, a guard that asserts the RIVAL carrier still
exists, so that deleting it is loud instead of silent. This is our equivalent.

WHAT IT IS FOR
--------------
Step 3 of T-357 introduces BPMN DI (`bpmndi:BPMNShape`/`dc:Bounds`) as a second place a
node's geometry can live. From that moment the corpus has TWO carriers for one fact. The
failure this guards is not "DI is wrong" — it is DI landing while `aef:position` quietly
stops being emitted for some nodes, leaving the corpus with two geometries that disagree
and no signal that it happened. Delete `aef:position` and this goes red, by name, on the
node that lost it.

WHY IT IS WIRED BEFORE THE EMITTER EXISTS
-----------------------------------------
A guard added at the same time as the change it guards proves nothing: it was written
against the new behaviour. Landing it now records the CURRENT invariant while it is still
true, so the day the emitter moves it, the red comes from the corpus and not from an
author's memory of what used to hold.

THE SHAPE, AND WHY IT IS NOT THE OBVIOUS ONE
--------------------------------------------
The obvious assertion is `nodes == 306 and positions == 306`. That is exactly the defect
this project catalogued 17 live instances of two days ago (G-015 / PL-200): a line pinning
a GLOBAL, ALWAYS-MOVING property — the size of a growing corpus — instead of a property of
the thing under test. It falsifies itself the first time a map is added, and the fix a
future reader reaches for is to bump 306, which teaches them that guards are paperwork.

So nothing here is pinned to a count. Every assertion is EMPTINESS-shaped (zero
violations) or `-ge`-shaped (at least one), both of which survive corpus growth:

  L1  anti-vacuity   at least one map, and at least one flow node in every map
  L2  the carrier    every flow node carries EXACTLY ONE aef:position          (zero misses)
  L3  its location   no aef:position anywhere except a flow node's own
                     bpmn:extensionElements                                    (zero strays)

L1 exists because L2 and L3 are both satisfied by an empty corpus. "No maps found" must be
a REFUSAL, never a pass — a guard that goes green when its subject is missing is the
false-green this repo keeps finding (PL-151, and _t509's own "a sweep over nothing is not
a pass").

The counts it prints are OBSERVATIONS, not assertions. Do not copy them into a
## Verification block — that is how a population-pinned line is born.

USAGE
  python3 tools/_t423-position-carrier-guard.py           # rc 0 green, 1 red, 2 refusal
  T423_CORPUS=/some/dir python3 tools/_t423-position-carrier-guard.py   # teeth use this
"""

import os
import sys
import glob
import xml.etree.ElementTree as ET

BPMN = "http://www.omg.org/spec/BPMN/20100524/MODEL"
AEF = "http://anchorpoint.framework/aef/extensions"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORPUS = os.environ.get("T423_CORPUS") or os.path.join(
    ROOT, "examples", "aef-processes", "rendered"
)

# BPMN's flow node substitution group, spelled out. Deliberately a closed list and not
# "anything with an id": a lane, a sequence flow and a data object are not nodes and must
# not be required to carry geometry.
FLOW_NODES = {
    "startEvent", "endEvent", "intermediateCatchEvent", "intermediateThrowEvent",
    "boundaryEvent", "task", "userTask", "serviceTask", "scriptTask", "manualTask",
    "businessRuleTask", "sendTask", "receiveTask", "subProcess", "transaction",
    "adHocSubProcess", "callActivity", "exclusiveGateway", "parallelGateway",
    "inclusiveGateway", "complexGateway", "eventBasedGateway",
}

POSITION = f"{{{AEF}}}position"
EXTENSION = f"{{{BPMN}}}extensionElements"


def local(tag):
    return tag.rsplit("}", 1)[-1] if isinstance(tag, str) and "}" in tag else tag


def is_flow_node(el):
    return isinstance(el.tag, str) and el.tag.startswith(f"{{{BPMN}}}") and local(el.tag) in FLOW_NODES


def main():
    maps = sorted(glob.glob(os.path.join(CORPUS, "*.bpmn")))

    # ── L1a: a sweep over nothing is not a pass ────────────────────────────────────────
    if not maps:
        print(f"REFUSING: no *.bpmn under {CORPUS}. A guard with no subject is not green.",
              file=sys.stderr)
        return 2

    missing = []   # (map, tag, id, count) — flow nodes not carrying exactly one position
    strays = []    # (map, where) — positions living somewhere they should not
    empty = []     # maps with no flow nodes at all
    nodes = positions = 0

    for path in maps:
        name = os.path.basename(path)
        try:
            tree = ET.parse(path)
        except ET.ParseError as exc:
            print(f"REFUSING: {name} does not parse: {exc}", file=sys.stderr)
            return 2
        root = tree.getroot()
        parent = {c: p for p in root.iter() for c in p}

        here = 0
        for el in root.iter():
            if not is_flow_node(el):
                continue
            here += 1
            nodes += 1
            own = el.find(EXTENSION)
            found = own.findall(POSITION) if own is not None else []
            positions += len(found)
            if len(found) != 1:
                missing.append((name, local(el.tag), el.get("id"), len(found)))

        # ── L1b: a map with no nodes satisfies L2 vacuously ───────────────────────────
        if here == 0:
            empty.append(name)

        # ── L3: every position must sit in a flow node's OWN extensionElements ────────
        for pos in root.iter(POSITION):
            holder = parent.get(pos)
            owner = parent.get(holder) if holder is not None else None
            if holder is None or holder.tag != EXTENSION or owner is None or not is_flow_node(owner):
                where = local(owner.tag) if owner is not None else "<detached>"
                strays.append((name, f"under {where}"))

    # Observations. NOT assertions — see the docstring.
    print(f"observed (not asserted): maps={len(maps)} nodes={nodes} aef:position={positions}")

    rc = 0
    if empty:
        print(f"REFUSING: {len(empty)} map(s) contain no flow nodes, so 'every node carries "
              f"a position' is vacuously true for them: {', '.join(empty)}", file=sys.stderr)
        rc = 2
    if missing:
        print(f"FAIL: {len(missing)} flow node(s) do not carry exactly one aef:position — "
              f"the geometry carrier has been dropped or duplicated:", file=sys.stderr)
        for name, tag, nid, n in missing[:20]:
            print(f"  {name}: <bpmn:{tag} id=\"{nid}\"> has {n}", file=sys.stderr)
        if len(missing) > 20:
            print(f"  … and {len(missing) - 20} more", file=sys.stderr)
        rc = rc or 1
    if strays:
        print(f"FAIL: {len(strays)} aef:position element(s) live outside a flow node's own "
              f"bpmn:extensionElements — geometry in a second place is the thing this "
              f"guard exists to make loud:", file=sys.stderr)
        for name, where in strays[:20]:
            print(f"  {name}: {where}", file=sys.stderr)
        rc = rc or 1

    if rc == 0:
        print("GUARD PASS — every flow node carries exactly one aef:position, and no "
              "position lives anywhere else.")
    return rc


if __name__ == "__main__":
    sys.exit(main())
