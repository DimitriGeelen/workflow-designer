#!/usr/bin/env python3
"""test_t125_lane_compaction — vertical lane-compaction regression wrapper (T-125),
arc: designer-authoring-surface.

The real work is `tools/_t125-lane-compaction-cdp.mjs`, which drives the REAL
editor in isolated headless chromium over the full rendered corpus (24 maps) and
asserts the compaction rule extracted from the T-122 operator correction pairs:

  * vertical-only — compactLanesFit() never touches node.x (pairs 1-3: the human
    correction was almost entirely vertical)
  * exact fixpoint — cleanLayout() converges (moved==0) within 8 iterations; the
    tidy<->compact grid feedback (laneRowYs derives its snap grid FROM lane
    height) 2-cycled 16/24 maps under a naive extent fit during build
  * containment — post-Clean every node rect sits inside its lane band (the
    baseline corpus had genuine overflows, e.g. audit-process framework lane)
  * no new overlaps, messiness never increases, one undoTidy() restores geometry
    exactly (compaction rides Clean's composite undo)
  * pair-map ceilings — task-lifecycle/promotion-pipeline/arc-lifecycle total
    heights stay under generous regression ceilings (they were 620/620/533
    before the rule; 392/376/420 at build)

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green (T-212 convention). Runs standalone and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_t125-lane-compaction-cdp.mjs")


def _chromium_present():
    cache = os.path.join(os.path.expanduser("~"), ".cache", "ms-playwright")
    if not os.path.isdir(cache):
        return False
    for d in os.listdir(cache):
        if d.startswith("chromium-") and os.path.exists(
            os.path.join(cache, d, "chrome-linux64", "chrome")
        ):
            return True
    return False


def _skip_reason():
    if not os.path.isfile(HARNESS):
        return None  # missing harness is a real failure, not a skip
    if shutil.which("node") is None:
        return "node not on PATH — lane-compaction harness needs Node.js"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=240
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_lane_compaction():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "lane-compaction suite failed (exit %d):\n%s" % (code, out[-1500:])


def main():
    reason = _skip_reason()
    if reason:
        print("SKIP: %s" % reason)
        return 0
    try:
        code, out = run_harness()
    except AssertionError as exc:
        sys.stderr.write("FAIL: %s\n" % exc)
        return 1
    sys.stdout.write(out if out.endswith("\n") else out + "\n")
    if code == 0:
        print("OK: lane-compaction legs green (T-125 — vertical-only, fixpoint, "
              "containment, overlaps, messiness, undo, pair-map ceilings; 24 maps)")
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
