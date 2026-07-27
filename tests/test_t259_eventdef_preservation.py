#!/usr/bin/env python3
"""test_t259_eventdef_preservation — T-259 (T-257 GO) regression guard for the
eventDef preservation passthrough, arc: designer-authoring-surface.

The real work is `tools/_t259-eventdef-preservation-cdp.mjs`, which drives the REAL
editor runtime (parseBpmnXml → buildBpmnXml) in an isolated headless chromium
against the REAL peer field bytes (tests/fixtures/aef-bpmn/t257-eventdef-roundtrip/
draft-trigger-handling-v1.bpmn — AEF byte-check EXACT MATCH, rail 215). It asserts
the rail-201 field defect stays cured:

  * start/throw carriers keep their <aef:eventDef> across open→save (passthrough,
    NO node-type override — T-237 catch-only decision untouched);
  * the typed-CATCH override (T-204) still takes precedence on th_pickup;
  * emitted host tags are unmutated; a second save is also lossless;
  * BITE: with the eventDefs stripped, no passthrough appears and none is emitted.

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green. Runs standalone (`python3 tests/test_t259_eventdef_preservation.py`) and
under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_t259-eventdef-preservation-cdp.mjs")
FIXTURE = os.path.join(
    ROOT, "tests", "fixtures", "aef-bpmn", "t257-eventdef-roundtrip",
    "draft-trigger-handling-v1.bpmn",
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
        return "node not on PATH — t259 preservation harness needs Node.js"
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


def test_eventdef_preservation():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "t259 preservation harness failed (exit %d):\n%s" % (code, out[-1500:])


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
        print("OK: start/throw eventDefs survive open→save (passthrough), catch "
              "override precedence holds, and the guard bites")
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
