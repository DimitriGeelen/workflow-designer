#!/usr/bin/env python3
"""test_roundtrip_serialization — suite integration for the G-002 round-trip serialization
harness (T-187, arc: designer-authoring-surface).

The real work is done by `tools/_roundtrip-serialization-cdp.mjs`, which drives the actual editor
runtime (parseBpmnXml -> buildBpmnXml) in an isolated headless chromium and asserts the aef:
serialization seam is a semantic fixed point across every tests/fixtures/aef-bpmn/*.bpmn. This
wrapper runs that harness as a subprocess so the round-trip guard participates in the normal
Python test path alongside the seven static seam guards.

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY (explicit reason) — never a silent
green. When the toolchain is present (as in CI/dev here), the harness runs for real and its exit
code is the verdict: 0 = every fixture round-trips, 1 = a fixture drifted, 2 = the harness
self-test found the guard vacuous.

Runs standalone (`python3 tests/test_roundtrip_serialization.py`) and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_roundtrip-serialization-cdp.mjs")
FIXTURES = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn")


def _chromium_present():
    """True if a Playwright chromium build is on disk (matches the harness's findChrome)."""
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
        return "node not on PATH — round-trip harness needs Node.js"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    """Run the harness. Returns (exit_code, output). Raises AssertionError on hard misconfig."""
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    assert os.path.isdir(FIXTURES) and any(
        f.endswith(".bpmn") for f in os.listdir(FIXTURES)
    ), "fixture corpus missing/empty (PL-022): %s" % FIXTURES
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=180
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_roundtrip_serialization_fixed_point():
    """Every aef-bpmn fixture round-trips through the real editor as a semantic fixed point."""
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "round-trip harness failed (exit %d):\n%s" % (code, out[-1500:])


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
        print("OK: round-trip serialization is a semantic fixed point across all aef-bpmn fixtures")
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
