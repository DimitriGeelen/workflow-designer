#!/usr/bin/env python3
"""test_t315_lane_grow_on_import — T-315 regression guard: an under-declared lane
band is GROWN on import rather than the operator's nodes being moved into a band
that was too small for them. Arc: designer-authoring-surface.

The real work is `tools/_t315-lane-grow-on-import-cdp.mjs`, which drives the REAL
editor runtime in an isolated headless chromium against two fixtures.

Background. T-313 detects the class in bytes (`W-XML-LANE-CAPACITY`): a lane whose
declared members' occupancy extent exceeds its declared height. This guards what the
EDITOR does about it. T-310's import reconcile tests each node's centre against the
band it lands in and moves it to the declared lane's centre — the right answer when
the map contradicts itself about *who*, the wrong answer when the map never
disagreed about ownership and simply under-declared a number. There, moving the
nodes repairs the symptom by destroying an authored layout; growing the band
preserves every position and changes no semantics at all.

The two cases separate on T-313's composition result, not on a heuristic: bands tile
the axis contiguously, so heights are the only free variable, and a containing set
of heights exists EXACTLY WHEN the lanes are ordering-clean (T-312's lane_geometry).
Hence the pairing this harness asserts:

  lane-capacity-large-spill.bpmn   ORDERING-CLEAN. Agent lane declares 260 while its
      members span 567. Band grows to the Clean fixpoint (591), ZERO nodes move,
      every authored y survives, and the grown height reaches the exported document
      (it is a real edit, not a render-time fudge that reverts on save).

  lane-position-conflict.bpmn      ORDERING-DIRTY (two-node swap). No set of heights
      can repair it, so the grow pass stands down and T-310's behaviour is
      byte-identical: 2 nodes reconciled, both lanes still 160, and the notice reads
      exactly the T-310 sentence with no grow clause.

That second fixture is what the operator is asked to load for T-310's still-open
`[REVIEW]` ACs — including the one asking whether "declared membership wins" is the
right default. So "unchanged" there is a governance requirement, not a nicety, and
it is a sharp test rather than a vacuous one: that lane WOULD grow (agent extent 254
vs declared 160) if the ordering gate were dropped or inverted.

Teeth (PL-061): the harness accepts a path to a different designer build. Against
the pre-T-315 source it fails on TEN real assertions, and shows the defect directly
— 3 of the 4 nodes yanked, y 300 -> 160, 600 -> 174, 700 -> 404:
    node tools/_t315-lane-grow-on-import-cdp.mjs /path/to/older-designer.html

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green (T-212 convention). Runs standalone
(`python3 tests/test_t315_lane_grow_on_import.py`) and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_t315-lane-grow-on-import-cdp.mjs")
FIXTURES = [
    os.path.join(ROOT, "tests", "fixtures", "aef-bpmn", "lane-capacity-large-spill.bpmn"),
    os.path.join(ROOT, "tests", "fixtures", "aef-bpmn", "lane-position-conflict.bpmn"),
]


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
        return "node not on PATH — t315 lane-grow harness needs Node.js"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    for f in FIXTURES:
        assert os.path.isfile(f), "fixture missing: %s" % f
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=240
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_lane_grow_on_import():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "t315 lane-grow harness failed (exit %d):\n%s" % (
        code,
        out[-1500:],
    )


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
        print("OK: T-315 — under-declared band grown (591), zero nodes moved, grown "
              "height round-trips; ordering-dirty map untouched (T-310 review fixture "
              "byte-identical)")
        return 0
    sys.stderr.write("FAIL: t315 lane-grow harness exit %d\n" % code)
    return 1


if __name__ == "__main__":
    sys.exit(main())
