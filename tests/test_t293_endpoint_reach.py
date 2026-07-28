#!/usr/bin/env python3
"""test_t293_endpoint_reach — standing endpoint-reconnect reachability leg
(T-293, G-003 class), arc: designer-authoring-surface.

The real work is `tools/_t293-endpoint-reach-cdp.mjs`, which drives the REAL
editor in an isolated headless chromium with real CDP mouse input. It guards:

  * canvas layer order (#g-badges < #g-edges < #g-nodes < #g-badges-top <
    #g-handles < #g-preview) — T-286 badge layers + T-293 handles layer;
  * endpoint grab-halo reachability at frw_11_harvest (the field case): handle
    centres hit the handle, press+move starts an endpoint drag, never a node
    drag;
  * a full Input-driven reconnect drag actually rewires edge.target.

TEETH (proven at T-293 build): against the pre-fix editor, 3/4 handle centres
resolve to node-shape, 1/4 to a port-indicator dot, and the e2e reconnect
leaves edge.target unchanged — the exact field symptoms.

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green (T-212 convention). Runs standalone and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_t293-endpoint-reach-cdp.mjs")


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
        return "node not on PATH — endpoint-reach harness needs Node.js"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=180
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_t293_endpoint_reach():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "endpoint-reach suite failed (exit %d):\n%s" % (code, out[-1500:])


def main():
    reason = _skip_reason()
    if reason:
        print("SKIP (LOUD, environment): %s" % reason)
        return 0
    code, out = run_harness()
    sys.stdout.write(out)
    return code


if __name__ == "__main__":
    sys.exit(main())
