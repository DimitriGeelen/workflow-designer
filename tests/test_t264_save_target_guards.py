#!/usr/bin/env python3
"""test_t264_save_target_guards — save-target guard set regression wrapper (T-264),
arc: designer-authoring-surface.

The real work is `tools/_t264-save-target-guards-cdp.mjs`, which drives the REAL
editor in an isolated headless chromium against a hermetic throwaway gallery
sidecar. It encodes the three guards built from the T-263 GO (the AEF rail-225
scratch-copy-overwrote-the-original incident) as standing PASS/FAIL legs:

  * G1 collision feedback: props-panel ID rename onto an existing library key
    renders a one-shot `.id-rename-notice` naming the id; state unchanged
    (renameActiveWorkflow still refuses — only the feedback is new).
  * G2 commit-on-blur/Enter: the ID field commits once on blur or Enter; input
    events alone do not commit, so trusted mid-typing keystrokes keep focus
    (pre-fix: first character committed, panel re-render dumped focus to <body>).
    Title stays live-commit — the deferral is ID-field-only.
  * G3 load-source mismatch confirm: saveToProject asks one confirm when the
    document came in via ?load (state: _loadSrcKey === activeKey) and the source
    stem differs from workflowMeta.id; decline aborts the POST. BITE leg proves
    the guard reads state, not string echo: same-stem and no-deep-link saves see
    no prompt.

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green (T-212 convention). Runs standalone and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_t264-save-target-guards-cdp.mjs")


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
        return "node not on PATH — save-target guard harness needs Node.js"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=240
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_save_target_guards():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "save-target guard suite failed (exit %d):\n%s" % (code, out[-1500:])


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
        print("OK: save-target guard legs green (T-264 — collision notice, "
              "commit-on-blur/Enter + focus, load-source mismatch confirm + BITE)")
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
