#!/usr/bin/env python3
"""bake-clean-layout — bake the editor's Clean layout into the corpus (T-101).

The rendered corpus (examples/aef-processes/rendered/*.bpmn) is machine-generated
by tools/yaml-to-bpmn.py, which copies each node's x/y and each lane's height
straight from the *.workflow.yaml source. Nobody hand-placed those nodes, so the
editor's Tidy/Clean standard finds most of them untidy (T-100 messiness). This
tool bakes Clean in ONCE so the shipped corpus is already tidy.

Design (why this shape):
  * Geometry lives in the yaml (`x:`/`y:` per node, `height:` per lane); the .bpmn
    is a pure projection of it (aef:position / aef:laneMeta). So we bake the tidied
    geometry back into the YAML SOURCE, then re-render. This makes the generator
    naturally emit tidy output — a naive `yaml-to-bpmn.py` regen can no longer
    silently un-tidy the corpus (T-101 AC #3, "generator emits tidy output").
  * Clean = cleanLayout(), which lives ONLY in the editor JS. We reuse it verbatim
    by running the real editor headless (tools/_clean-layout-cdp.mjs) — we never
    reimplement Tidy in Python (PL-005: editor/bridge drift on shared logic).
  * The YAML patch is line-surgical: only the specific `y:`/`x:`/`height:` numbers
    that Clean changed are rewritten; every other byte (comments, key order,
    quoting, flow-style io) is left exactly as-is, so the diff is the geometry
    delta and nothing else.

Re-run after Clean logic changes:  tools/bake-clean-layout.py
Check the corpus is a Clean fixpoint (idempotent, no writes):  --check

Usage:
  tools/bake-clean-layout.py [--check] [map ...]
    (no map args → all 24 rendered maps)
"""
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORPUS = os.path.join(ROOT, "examples", "aef-processes")
RENDERED = os.path.join(CORPUS, "rendered")
GALLERY = os.path.join(ROOT, "build", "gallery", "rendered")
DRIVER = os.path.join(ROOT, "tools", "_clean-layout-cdp.mjs")
GEN = os.path.join(ROOT, "tools", "yaml-to-bpmn.py")
MESSINESS_MAX = 3  # T-100 CLEAN_NUDGE_MIN — a clean map scores < 3


def fmtnum(v):
    v = round(float(v), 3)
    return str(int(v)) if v == int(v) else ("%g" % v)


def run_driver(maps):
    """Run the headless editor over the given maps; return {map: result}."""
    cmd = ["node", DRIVER] + maps
    proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        raise SystemExit("clean-layout driver failed (exit %d)" % proc.returncode)
    return json.loads(proc.stdout)


def patch_yaml(path, node_geom, lane_h):
    """Line-surgically rewrite only changed x/y (nodes) and height (lanes).

    node_geom: {uid: {'x': float, 'y': float}}   lane_h: {lane_id: float}
    Returns number of lines rewritten.
    """
    with open(path) as fh:
        lines = fh.read().split("\n")
    section = None
    cur_uid = None
    cur_lane = None
    changed = 0
    for i, line in enumerate(lines):
        top = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):", line)
        if top:
            key = top.group(1)
            section = key if key in ("lanes", "nodes") else "other"
            cur_uid = cur_lane = None
            continue
        if section == "nodes":
            m = re.match(r"^  - uid:\s*(\S+)", line)
            if m:
                cur_uid = m.group(1)
                continue
            if cur_uid and cur_uid in node_geom:
                m = re.match(r"^(    )(x|y):\s*(-?[0-9.]+)\s*$", line)
                if m:
                    newv = node_geom[cur_uid].get(m.group(2))
                    if newv is not None and fmtnum(newv) != m.group(3):
                        lines[i] = "    %s: %s" % (m.group(2), fmtnum(newv))
                        changed += 1
        elif section == "lanes":
            m = re.match(r"^  - id:\s*(\S+)", line)
            if m:
                cur_lane = m.group(1)
                continue
            if cur_lane and cur_lane in lane_h:
                m = re.match(r"^(    )height:\s*(-?[0-9.]+)\s*$", line)
                if m and fmtnum(lane_h[cur_lane]) != m.group(2):
                    lines[i] = "    height: %s" % fmtnum(lane_h[cur_lane])
                    changed += 1
    with open(path, "w") as fh:
        fh.write("\n".join(lines))
    return changed


def render(base):
    """Re-render one map's yaml → rendered/<base>.bpmn, then mirror to gallery."""
    src = os.path.join(CORPUS, base + ".workflow.yaml")
    out = os.path.join(RENDERED, base + ".bpmn")
    subprocess.run(["python3", GEN, src, "--out", out], cwd=ROOT, check=True)
    shutil.copyfile(out, os.path.join(GALLERY, base + ".bpmn"))


def all_maps():
    return sorted(b[:-len(".bpmn")] for b in os.listdir(RENDERED) if b.endswith(".bpmn"))


def main(argv):
    check = "--check" in argv
    names = [a for a in argv if not a.startswith("--")]
    maps = names or all_maps()

    results = run_driver(maps)

    # Report table.
    bad = 0
    print("%-28s %6s %6s %8s %8s" % ("map", "moved", "iters", "messy→", "→messy"))
    for base in maps:
        r = results.get(base, {})
        if not r.get("ok"):
            print("  %-26s  ERROR: %s" % (base, r.get("error", "no result")))
            bad += 1
            continue
        warn = "  ⚠ not converged" if r.get("lastMoved", 0) != 0 else ""
        print("  %-26s %5d %6s %8s %8s%s" % (
            base, r["moved"], r.get("iters", "?"),
            r["messinessBefore"], r["messinessAfter"], warn))

    if check:
        # Fixpoint check: an already-baked corpus moves nothing and is not messy.
        fail = 0
        for base in maps:
            r = results.get(base, {})
            if not r.get("ok"):
                fail += 1
                continue
            if r["moved"] != 0 or r["messinessBefore"] >= MESSINESS_MAX:
                print("  NOT A FIXPOINT: %s (moved=%s messinessBefore=%s)"
                      % (base, r["moved"], r["messinessBefore"]))
                fail += 1
        print("\n--check: %d/%d maps are a Clean fixpoint"
              % (len(maps) - fail, len(maps)))
        return 1 if fail else 0

    if bad:
        raise SystemExit("driver returned errors for %d map(s); aborting bake" % bad)

    # Bake: patch yaml, re-render, mirror.
    total_lines = 0
    for base in maps:
        r = results[base]
        node_geom = {n["id"]: {"x": n["x"], "y": n["y"]} for n in r["nodes"]}
        lane_h = {l["id"]: l["height"] for l in r["lanes"]}
        n = patch_yaml(os.path.join(CORPUS, base + ".workflow.yaml"), node_geom, lane_h)
        render(base)
        total_lines += n
        print("  baked %-24s (%d geometry lines rewritten)" % (base, n))
    print("\nBaked Clean into %d maps; %d geometry lines rewritten; gallery mirror synced."
          % (len(maps), total_lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
