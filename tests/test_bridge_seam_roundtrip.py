#!/usr/bin/env python3
"""test_bridge_seam_roundtrip — suite integration for the G-002 half-2 cross-seam harness
(T-188, arc: designer-authoring-surface).

The real work is done by `tools/_bridge-seam-roundtrip-cdp.mjs`, which runs the actual Python
bridge (yaml-to-bpmn.py) on every examples/aef-processes/*.workflow.yaml, imports each emission
into the real editor runtime in isolated headless chromium, and asserts NO governance signal
(aef:uid / editor-known aef:meta) is silently dropped on the bridge->editor path — the JS<->Python
drift class that motivated G-002 (T-042 namespace, T-053 decisionOutputs). Its self-test mangles
the aef namespace URI (reproducing T-042) to prove the drop-detector bites.

This wrapper runs that harness as a subprocess so the cross-seam guard joins the Python test path.
Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent green. Runs
standalone (`python3 tests/test_bridge_seam_roundtrip.py`) and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_bridge-seam-roundtrip-cdp.mjs")
YAML_DIR = os.path.join(ROOT, "examples", "aef-processes")


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
        return "node not on PATH — cross-seam harness needs Node.js"
    if shutil.which("python3") is None:
        return "python3 not on PATH — harness runs the bridge as a subprocess"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    assert os.path.isdir(YAML_DIR) and any(
        f.endswith(".workflow.yaml") for f in os.listdir(YAML_DIR)
    ), "workflow corpus missing/empty (PL-022): %s" % YAML_DIR
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=300
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_bridge_seam_no_silent_drop():
    """Every bridge emission imports into the editor with no dropped aef governance signal."""
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "cross-seam harness failed (exit %d):\n%s" % (code, out[-1800:])


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
        print("OK: bridge emissions survive editor import with no silent drop across all workflows")
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
