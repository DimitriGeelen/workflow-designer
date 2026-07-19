#!/usr/bin/env python3
"""test_typed_events — T-204 Slice 1 correctness guard for typed intermediate
events (error / timer / message), arc: designer-authoring-surface.

The real work is `tools/_typed-events-cdp.mjs`, which drives the REAL editor
runtime (parseBpmnXml → buildBpmnXml) in an isolated headless chromium and asserts
CORRECTNESS — distinct from the fixed-point round-trip guard
(test_roundtrip_serialization.py), which only proves self-consistency and so
cannot catch a consistently-wrong mapping. This harness asserts:

  * parseBpmnXml(tests/fixtures/aef-bpmn/typed-events.bpmn) decodes the three
    neutral <bpmn:intermediateCatchEvent> tags to node.type eventError/eventTimer/
    eventMessage via their <aef:eventDef kind=…>, restoring the kind-specific
    binding field (errorStatus / timerSpec / busTopic);
  * buildBpmnXml re-emits the three <aef:eventDef kind=… binding=…/> markers;
  * BITE: with <aef:eventDef> stripped, the SAME tag decodes to linkEventCatch —
    proving the typing is driven by the extension, not the tag (IW-1 collision
    disambiguation is real).

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green. Runs standalone (`python3 tests/test_typed_events.py`) and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_typed-events-cdp.mjs")
FIXTURE = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn", "typed-events.bpmn")


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
        return "node not on PATH — typed-events harness needs Node.js"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    assert os.path.isfile(FIXTURE), "fixture missing: %s" % FIXTURE
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=180
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_typed_events_correctness():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "typed-events harness failed (exit %d):\n%s" % (code, out[-1500:])


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
        print("OK: typed events decode/encode correctly (error/timer/message) and the "
              "extension-driven typing bites")
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
