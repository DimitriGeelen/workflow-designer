#!/usr/bin/env python3
"""test_t258_annotation_seam — T-258 (T-250 GO) guard for the annotation seam v0
(shape A postMessage), arc: designer-authoring-surface.

The real work is `tools/_t258-annotation-seam-cdp.mjs`, which embeds the REAL
editor in an iframe host page (the AEF Watchtower topology) in an isolated
headless chromium and asserts the ratified loop end-to-end:

  * aef:ready (version 1, workflow id, uid list) on initial load and after every
    re-render / document switch;
  * aef:annotate renders read-only badges for known uids, ignores unknown uids
    and malformed entries, and rejects non-parent-source messages (spoof probe);
  * display-only invariants: BPMN emit clean, thumbnail clone strip works,
    re-render wipes badges (re-handshake contract);
  * BITE: zero badges before any annotate.

Also produces .playwright-mcp/t258-annotation-badges.png for the visual read.

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green. Runs standalone (`python3 tests/test_t258_annotation_seam.py`) and under
pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_t258-annotation-seam-cdp.mjs")


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
        return "node not on PATH — t258 annotation-seam harness needs Node.js"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=240
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_annotation_seam():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "t258 annotation-seam harness failed (exit %d):\n%s" % (code, out[-1500:])


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
        print("OK: annotation seam v0 loop green — ready handshake, badge intake, "
              "display-only invariants, spoof rejection, wipe + doc-switch contracts")
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
