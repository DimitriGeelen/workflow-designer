#!/usr/bin/env python3
"""check-lane-bands — assert node coordinates render legibly (T-042).

The validator (tools/validate-workflow.py) and the bridge round-trip suite check
*structure* — unique ids, refs resolve, lane assignment, gateway fan-out. None of
them check *geometry*: whether a node's y-box actually falls inside the lane band
it is assigned to, or whether two nodes in the same lane overlap. A workflow can
therefore validate clean (exit 0) yet render as an illegible, overlapping mess —
which is exactly what happened to inception-review (T-041 fidelity pilot).

This tool closes that gap. It reconstructs the lane bands the editor
(src/aef-workflow-designer.html) computes — cumulative lane `height` stacked from
POOL_Y + POOL_HEADER = 62 — and asserts, for every node:

  1. the node's vertical box [y, y+h] lies within its assigned lane's band
     (a small OVERFLOW_TOLERANCE allows events to kiss a band edge), and
  2. no two nodes sharing a lane overlap in 2-D (boxes must not intersect,
     modulo a small MIN_GAP breathing space).

Exit 0 = clean. Exit 1 = geometry findings (printed). Exit 2 = usage/parse error.

These node dimensions mirror NODE_DEFAULTS in the editor; keep them in sync.
"""
import argparse
import sys

import yaml

# Geometry constants — mirror src/aef-workflow-designer.html.
POOL_Y = 30
POOL_HEADER = 32
BAND_TOP0 = POOL_Y + POOL_HEADER  # 62 — first lane band starts here

# node type → (w, h), mirroring NODE_DEFAULTS.
NODE_SIZE = {
    "startEvent": (36, 36),
    "endEvent": (36, 36),
    "serviceTask": (110, 64),
    "userTask": (110, 64),
    "scriptTask": (110, 64),
    "exclusiveGateway": (48, 48),
    "parallelGateway": (48, 48),
    "linkEventThrow": (36, 36),
    "linkEventCatch": (36, 36),
}
DEFAULT_SIZE = (110, 64)

# Events may kiss a band edge (their glyph is small and visually centred), so a
# few px of overflow past the band boundary is not a real defect.
OVERFLOW_TOLERANCE = 8
# Minimum clear space required between two same-lane node boxes.
MIN_GAP = 0


def size_for(node_type):
    return NODE_SIZE.get(node_type, DEFAULT_SIZE)


def bands(lanes):
    """Return {lane_id: (top, bottom)} stacked by height from BAND_TOP0."""
    out = {}
    top = BAND_TOP0
    for lane in lanes:
        if not isinstance(lane, dict):
            continue
        h = int(lane.get("height", 130))
        lid = lane.get("id", "")
        out[lid] = (top, top + h)
        top += h
    return out


def boxes_overlap(a, b):
    """True if rectangles a,b (x, y, w, h) intersect (with MIN_GAP margin)."""
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    sep_x = ax + aw + MIN_GAP <= bx or bx + bw + MIN_GAP <= ax
    sep_y = ay + ah + MIN_GAP <= by or by + bh + MIN_GAP <= ay
    return not (sep_x or sep_y)


def check(workflow):
    findings = []
    lanes = workflow.get("lanes", []) or []
    nodes = workflow.get("nodes", []) or []
    band = bands(lanes)

    placed = []  # (uid, lane, box)
    for n in nodes:
        if not isinstance(n, dict):
            continue
        uid = n.get("uid", "?")
        lane = n.get("lane")
        w, h = size_for(n.get("type", "serviceTask"))
        try:
            x = float(n.get("x", 0))
            y = float(n.get("y", 0))
        except (TypeError, ValueError):
            findings.append("%s: non-numeric x/y" % uid)
            continue
        box = (x, y, w, h)

        if lane not in band:
            findings.append("%s: lane '%s' has no band (unknown lane)" % (uid, lane))
        else:
            top, bottom = band[lane]
            if y < top - OVERFLOW_TOLERANCE:
                findings.append(
                    "%s: y=%g box-top above lane '%s' band top %g (straddles band above)"
                    % (uid, y, lane, top))
            if y + h > bottom + OVERFLOW_TOLERANCE:
                findings.append(
                    "%s: y+h=%g box-bottom below lane '%s' band bottom %g (straddles band below)"
                    % (uid, y + h, lane, bottom))

        for (ouid, olane, obox) in placed:
            if olane == lane and boxes_overlap(box, obox):
                findings.append("%s overlaps %s in lane '%s'" % (uid, ouid, lane))
        placed.append((uid, lane, box))

    return findings


def main(argv=None):
    ap = argparse.ArgumentParser(description="Check workflow node geometry (lane bands + overlap).")
    ap.add_argument("input", help="path to a *.workflow.yaml file")
    args = ap.parse_args(argv)

    try:
        with open(args.input) as fh:
            workflow = yaml.safe_load(fh)
    except (OSError, yaml.YAMLError) as exc:
        sys.stderr.write("error: cannot read/parse %s: %s\n" % (args.input, exc))
        return 2
    if not isinstance(workflow, dict):
        sys.stderr.write("error: %s is not a workflow mapping\n" % args.input)
        return 2

    findings = check(workflow)
    if findings:
        sys.stderr.write("LAYOUT findings in %s:\n" % args.input)
        for f in findings:
            sys.stderr.write("  - %s\n" % f)
        return 1
    print("OK: %s — all nodes within lane bands, no overlaps" % args.input)
    return 0


if __name__ == "__main__":
    sys.exit(main())
