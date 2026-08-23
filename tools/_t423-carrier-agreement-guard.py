#!/usr/bin/env python3
"""_t423-carrier-agreement-guard.py — the two geometry carriers must AGREE, not merely
both exist.

WHY THIS IS A SECOND GUARD AND NOT AN EXTRA LEG ON THE FIRST ONE.
`tools/_t423-position-carrier-guard.py` asserts that `aef:position` is PRESENT on every
flow node. It landed 2026-08-15 and it was the whole of what could be built then, because
until the DI emitter existed `aef:position` had nothing to disagree with. The emitter
landed at 389133c8. From that commit onward every exported document carries two
independent statements of where a node is — `aef:position` and `dc:Bounds` — and the
presence guard stays GREEN while those two drift apart. That is the exact failure its own
docstring claims to cover, so the gap is named here rather than left implied.

THE PROVENANCE OF THIS GUARD'S SHAPE, which is AEF's and not ours (rail 11876). They
reported their index canary was a false green TWICE: once because the control was sized so
it could never trip, and once because — while genuinely broken — it still ranked first,
since on a small index "is the canary the top hit?" is satisfied by having NO RIVAL. They
had to plant a decoy that wins when the canary is broken before the assertion meant
anything. Their question, transferred verbatim: *"has anyone watched it go red, against a
real artefact, with a real competitor?"*

Applied here, the decoy is not hypothetical and it is not exotic. The two carriers are
joined by a NODE ID: `aef:position` lives inside the flow node's own extensionElements, and
`dc:Bounds` hangs off a `bpmndi:BPMNShape` that points at that node via `@bpmnElement`. The
obvious implementation — walk the pairs that match, compare their coordinates — reports
"no disagreements" when the join produces NO PAIRS AT ALL. Change the id scheme on one side
and the check goes green on a document where the two carriers have stopped referring to the
same nodes entirely. Zero pairs is the strongest possible disagreement and the naive
implementation reads it as the strongest possible agreement.

So COVERAGE is asserted before agreement is, and the pair count is a first-class output.
Three separate things must hold, and each is reported by name so a pass cannot be read off
a number that never moved:

  1. COVERAGE   — every node carrying `aef:position` has a `BPMNShape` naming it, and every
                  `BPMNShape` naming a flow node finds that node carrying `aef:position`.
                  One-sided coverage is not coverage: a shape for a node with no position is
                  DI knowing a geometry `aef:position` does not, which is precisely the
                  asymmetry step 3 (T-424) has to reason about.
  2. AGREEMENT  — |bounds.x - pos.x| <= TOL and |bounds.y - pos.y| <= TOL, per node.
  3. NON-VACUITY — at least one document in the run carried BOTH carriers. A run over
                  documents that have no DI at all is a REFUSAL (exit 2), never a pass.
                  Without this leg, deleting the emitter turns this guard green, and
                  "the emitter is gone" would report identically to "the emitter agrees".

TOLERANCE, STATED RATHER THAN ASSUMED. Both carriers are written by the same exporter from
the same model field, each through `.toFixed(1)` — `aef:position` at src:9555, `dc:Bounds`
in the DI block. So they agree EXACTLY today, and the honest tolerance is the precision at
which they are both printed: half of the last emitted digit.

    TOL = 0.05

Not 0.0: a zero-width window makes the verdict hostage to float parsing rather than to the
values, and a guard that can fail for a reason unrelated to its subject is a guard that
gets disabled. Not larger: at 0.1 a genuine one-decimal drift — the smallest drift the
format can express — would pass, and the smallest expressible drift is the one a refactor
actually produces. The window is wide enough to absorb representation and too narrow to
absorb any difference the emitters can write down.

WHAT `dc:Bounds` MEANS HERE, checked rather than assumed: `centerOf()` at src:3848 is
`n.x + w/2`, so the model's x/y IS the top-left corner, which is what BPMN DI's Bounds
means. The two carriers are therefore the same quantity in the same frame, and comparing
them directly is not an approximation. Had the model been centre-origin this guard would
have to compare `bounds.x + w/2` and would have found the emitter wrong on its first run.

WHAT THIS GUARD DELIBERATELY DOES NOT CHECK. Edge waypoints. `di:waypoint` has no rival
carrier — `aef:waypoint` exists on exactly one node in the corpus and expresses INTENT, not
a computed route (Spike 3). There is nothing for waypoints to agree WITH, so asserting
anything about them here would be a check with one input, which is the shape this whole
guard exists to argue against. The teeth include a benign waypoint edit as an anti-overfit
control: a guard that reddened on any diff would pass every other leg in this file.

NO POPULATION PIN. Today's corpus is 24 maps and 306 nodes and neither number appears in
executable code here. Every assertion is per-document and per-node, or an emptiness
assertion, so this file does not falsify itself the first time a map is added (G-015).

Usage:  _t423-carrier-agreement-guard.py PATH [PATH...]     (file or directory of .bpmn)
Exit 0 = both carriers present and agreeing everywhere.
     1 = a disagreement or a coverage hole (the offending nodes are named).
     2 = refusal: nothing to compare, unreadable input, or no paths given.
"""

import sys
import os
import glob
import xml.etree.ElementTree as ET

NS_BPMN = "http://www.omg.org/spec/BPMN/20100524/MODEL"
NS_BPMNDI = "http://www.omg.org/spec/BPMN/20100524/DI"
NS_DC = "http://www.omg.org/spec/DD/20100524/DC"
NS_AEF = "http://anchorpoint.framework/aef/extensions"

# See the tolerance passage in the module docstring. Half of the last digit that
# `.toFixed(1)` can emit: wide enough for representation, narrower than any drift the
# two emitters are capable of writing.
TOL = 0.05


def _split(tag):
    """('{uri}local') -> (uri, local). Prefix-agnostic on purpose: a third-party document
    may bind these namespaces to any prefix it likes, and matching on the prefix would make
    this guard silently blind to exactly the documents it is least sure about."""
    if tag.startswith("{"):
        uri, _, local = tag[1:].partition("}")
        return uri, local
    return "", tag


def _positions(root):
    """node id -> (x, y) for every flow node carrying aef:position.

    The owner is the nearest ancestor with an @id, which is how the position is bound to a
    node in our own exports (it sits in the node's own bpmn:extensionElements). A position
    with no id-bearing ancestor is a STRAY and is reported rather than skipped — the
    presence guard already covers strays, but a stray dropped silently here would shrink
    the population this guard measures and make its coverage leg easier to satisfy."""
    out, strays = {}, []
    parent = {c: p for p in root.iter() for c in p}
    for el in root.iter():
        uri, local = _split(el.tag)
        if uri != NS_AEF or local != "position":
            continue
        owner = parent.get(el)
        while owner is not None and owner.get("id") is None:
            owner = parent.get(owner)
        if owner is None:
            strays.append(el)
            continue
        try:
            out[owner.get("id")] = (float(el.get("x")), float(el.get("y")))
        except (TypeError, ValueError):
            strays.append(el)
    return out, strays


def _bounds(root):
    """bpmnElement id -> (x, y) from every bpmndi:BPMNShape carrying dc:Bounds."""
    out = {}
    for el in root.iter():
        uri, local = _split(el.tag)
        if uri != NS_BPMNDI or local != "BPMNShape":
            continue
        ref = el.get("bpmnElement")
        if not ref:
            continue
        for kid in el:
            kuri, klocal = _split(kid.tag)
            if kuri == NS_DC and klocal == "Bounds":
                try:
                    out[ref] = (float(kid.get("x")), float(kid.get("y")))
                except (TypeError, ValueError):
                    pass
                break
    return out


# The BPMN flow nodes — the closed set of things that can carry a position in this editor.
# An ALLOW-LIST and not a deny-list, and the difference is the whole point: a deny-list of
# containers ("not a lane, not a participant, not a process") silently admits every element
# type nobody thought of, so the first time DI carries a shape for something new this guard
# reports a coverage hole that is really a vocabulary gap. Getting the allow-list wrong makes
# the guard MISS a node; getting a deny-list wrong makes it INVENT a violation, and a guard
# that cries wolf is disabled long before one that is quietly narrow.
FLOW_NODES = {
    "startEvent", "endEvent", "intermediateCatchEvent", "intermediateThrowEvent",
    "boundaryEvent", "task", "userTask", "serviceTask", "scriptTask", "manualTask",
    "businessRuleTask", "sendTask", "receiveTask", "callActivity", "subProcess",
    "transaction", "adHocSubProcess", "exclusiveGateway", "parallelGateway",
    "inclusiveGateway", "eventBasedGateway", "complexGateway",
}


def _flow_node_ids(root):
    """Ids of FLOW NODES only — not every id in the BPMN namespace.

    The distinction decides what a shape-with-no-position means. Pointing at a flow node,
    it is a real coverage hole: DI knows a geometry `aef:position` does not, which is the
    asymmetry T-424 has to reason about. Pointing at a lane, a participant or the process
    itself, it is nothing of the kind — BPMN DI legitimately carries container shapes and
    our exporter simply does not emit them yet. An earlier draft collected every
    BPMN-namespace id, which would have turned the first pool or lane shape anyone adds
    into a fleet of false violations against a guard that had just been declared correct."""
    ids = set()
    for el in root.iter():
        uri, local = _split(el.tag)
        if uri == NS_BPMN and local in FLOW_NODES and el.get("id"):
            ids.add(el.get("id"))
    return ids


def check(path):
    """-> (violations, pairs_compared, has_di). Raises on unreadable input: a document this
    guard cannot parse must not be counted as a document with nothing wrong in it.

    `has_di` IS THE DISTINCTION THE FIRST VERSION OF THIS FILE DID NOT MAKE, and its teeth
    caught it on the first run. A document with no `BPMNShape` at all and a document whose
    shapes have stopped referring to its nodes both produce ZERO PAIRS, and the first draft
    refused on both — which meant renaming every `@bpmnElement`, the total collapse of the
    join between the carriers, reported as "nothing to compare" instead of as the complete
    coverage failure it is. Same number, opposite meanings:

      no DI in the document at all   -> nothing to compare (a source map, or a deleted
                                        emitter). Only the RUN can judge that, because one
                                        DI-less document among many is itself the finding.
      DI present, join broken        -> everything to compare and none of it lines up. That
                                        is the loudest possible disagreement.

    So the per-document verdict reports which of the two it saw, and main() decides."""
    root = ET.parse(path).getroot()
    pos, strays = _positions(root)
    bnd = _bounds(root)
    ids = _flow_node_ids(root)
    name = os.path.basename(path)
    v = []
    has_di = bool(bnd)

    if not has_di:
        # Coverage is not assessed against a carrier that is not there. Reporting 306
        # "node has no shape" violations for a pre-export source map would bury a real
        # finding under an artefact of what the document IS.
        return v, 0, False

    for el in strays:
        v.append(f"{name}: aef:position with no id-bearing owner (x={el.get('x')} y={el.get('y')})")

    # Coverage, both directions, BEFORE any coordinate is compared. This is the leg that
    # makes an id-scheme drift report as the disagreement it is instead of as an empty
    # comparison set.
    for nid in sorted(set(pos) - set(bnd)):
        v.append(f"{name}: node {nid} carries aef:position but NO bpmndi:BPMNShape names it")
    for nid in sorted((set(bnd) - set(pos)) & ids):
        v.append(f"{name}: BPMNShape names flow node {nid}, which carries NO aef:position")

    pairs = 0
    for nid in sorted(set(pos) & set(bnd)):
        px, py = pos[nid]
        bx, by = bnd[nid]
        pairs += 1
        if abs(bx - px) > TOL or abs(by - py) > TOL:
            v.append(
                f"{name}: node {nid} carriers DISAGREE — "
                f"aef:position=({px:.1f},{py:.1f}) dc:Bounds=({bx:.1f},{by:.1f}) "
                f"delta=({bx - px:+.2f},{by - py:+.2f}) tolerance={TOL}"
            )
    return v, pairs, True


def main(argv):
    paths = []
    for a in argv:
        if os.path.isdir(a):
            paths += sorted(glob.glob(os.path.join(a, "*.bpmn")))
        else:
            paths.append(a)
    if not paths:
        print("REFUSE — no .bpmn documents given; a guard with no input is not a guard that passed")
        return 2

    violations, pairs, with_di, without_di, unreadable = [], 0, [], [], []
    for p in paths:
        try:
            v, n, has_di = check(p)
        except Exception as e:  # parse failure, missing file, anything
            unreadable.append(f"{os.path.basename(p)}: {e}")
            continue
        violations += v
        pairs += n
        (with_di if has_di else without_di).append(os.path.basename(p))

    if unreadable:
        print(f"REFUSE — {len(unreadable)} document(s) could not be read:")
        for u in unreadable:
            print("  " + u)
        return 2

    # The non-vacuity leg, and the ORDER of these three branches is the whole of what the
    # teeth corrected. Everything this guard asserts is satisfied by a corpus in which no
    # document carries DI — no pairs to disagree, no shapes to be uncovered, zero
    # violations, green. That is the absence-satisfied-by-silence shape T-560 pins, and
    # here it would report "the carriers agree" about a designer whose emitter had been
    # deleted. But refusing on `pairs == 0` ALONE is the mirror mistake: it also swallows
    # the case where DI is present and its join to the model has completely broken, which
    # is a finding and not an absence. Vacuity is judged on whether the rival carrier is
    # THERE, never on whether the comparison happened to produce rows.
    if not with_di:
        print(f"REFUSE — {len(paths)} document(s) read, NONE carries any bpmndi:BPMNShape. "
              f"There is no rival carrier here, so nothing was compared and nothing agreed.")
        return 2

    # A mixed run is itself the finding: after 389133c8 every export carries DI, so a
    # document that does not is either not an export or evidence of an emitter that has
    # stopped firing for some inputs. Named, not averaged away.
    for n in without_di:
        violations.append(f"{n}: carries aef:position but NO DI at all, in a run where "
                          f"{len(with_di)} other document(s) do")

    print(f"  documents: {len(paths)}   carrying both carriers: {len(with_di)}   "
          f"node pairs compared: {pairs}   tolerance: {TOL}")
    if violations:
        print(f"\nFAIL — {len(violations)} carrier disagreement(s)/coverage hole(s):")
        for x in violations[:40]:
            print("  " + x)
        if len(violations) > 40:
            print(f"  … and {len(violations) - 40} more")
        return 1
    print("PASS — aef:position and dc:Bounds cover the same nodes and agree on every one")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
