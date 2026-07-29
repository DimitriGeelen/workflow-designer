#!/usr/bin/env python3
"""test_t310_lane_position_conflict — T-310 regression guard for the lane
membership vs position conflict, arc: designer-authoring-surface.

The real work is `tools/_t310-lane-position-conflict-cdp.mjs`, which drives the REAL
editor runtime in an isolated headless chromium against
tests/fixtures/aef-bpmn/lane-position-conflict.bpmn.

Background: a map can declare a node in lane A while its <aef:position> draws it
inside lane B's band. The designer used to import BOTH truths without reconciling
them, and the first drag then resolved the contradiction in favour of PIXELS via
laneAtY — silently rewriting lane membership, which in mapping-v1 is *who is
responsible for the step* (T-189, Lane=who). Reproduced from AEF's served
draft-knowledge-leveling bytes: 10 of 12 nodes inverted between v5 and v7 while
their positions barely moved, because their generator ordered the laneSet
agent-then-framework while placing the framework nodes at the top y-values.
laneAtY had a second edge: a y below every band returned getLanes()[0], so a node
dragged into the void under the pool was silently adopted by the top lane.

The harness asserts, in eight legs:

  * conflicts are reconciled in favour of the DECLARED lane (2 of the fixture's 4)
  * agreements are left byte-alone — no gratuitous geometry rewriting
  * every node's centre now falls inside the lane it claims
  * the move is REPORTED (dismissible notice, correct count and wording), because
    silently rewriting the operator's geometry is the same sin as silently
    rewriting their membership
  * laneAtY below every band returns null, not lane[0]
  * nothing about the reconciliation leaks into the exported document, and export
    membership still matches the declaration (resolved via aef:uid — displayIds
    are derived and regenerate on import, so they cannot be compared directly)
  * re-importing the export reconciles ZERO — the repair is idempotent

Note the fixture validates CLEAN under tools/validate-workflow.py. That is
deliberate: this defect class needs geometry, and both validator paths are
structural, so no rule can see it. The guard has to be a browser-level test.

Teeth (PL-061): the harness accepts an optional path to a different designer
build. Run it against the pre-fix source and it goes red on six real assertions,
including the exact AEF inversion and the orphan adoption:
    node tools/_t310-lane-position-conflict-cdp.mjs /path/to/older-designer.html

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green (T-212 convention). Runs standalone
(`python3 tests/test_t310_lane_position_conflict.py`) and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_t310-lane-position-conflict-cdp.mjs")
FIXTURE = os.path.join(
    ROOT, "tests", "fixtures", "aef-bpmn", "lane-position-conflict.bpmn"
)


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
        return "node not on PATH — t310 lane-conflict harness needs Node.js"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    assert os.path.isfile(FIXTURE), "fixture missing: %s" % FIXTURE
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=240
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_lane_position_conflict():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "t310 lane-conflict harness failed (exit %d):\n%s" % (
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
        print(
            "OK: declared lane wins over conflicting geometry, agreeing nodes are "
            "untouched, the move is reported, the void no longer adopts nodes into "
            "lane[0], nothing leaks into the export, and the repair is idempotent"
        )
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
