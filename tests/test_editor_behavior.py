#!/usr/bin/env python3
"""test_editor_behavior — G-010 standing editor behavior suite wrapper (T-238),
arc: designer-authoring-surface.

The real work is `tools/_editor-behavior-verify-cdp.mjs`, which drives the REAL
editor in an isolated headless chromium against a hermetic throwaway gallery
sidecar (temp --repo + temp docroot — structurally incapable of touching the real
registry or versions store). It encodes the two field-found 0.3.1 blockers as
standing legs:

  * T-234 jump-autosave poisoning: ?load=X → jumpToWorkflow(Y) → autosave record
    carries src:null (not X's deep-link src); revisiting ?load=X renders X. Plus
    the legitimate same-map edit-restore branch the fix had to keep working.
  * T-237 classification contract: throw+eventDef keeps its throw tag on
    re-export (payload drops — recorded decision); catch+link+eventDef →
    linkEventCatch with the ref preserved; bare catch → linkEventCatch; typed
    catch → eventMessage with binding, eventDef re-emitted.

TEETH (proven at T-238 build): run against the pre-fix editor
(`git show 7390131^:src/aef-workflow-designer.html`) the suite fails BOTH legs
with the exact field symptoms — it is not vacuous.

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green (T-212 convention). Runs standalone and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_editor-behavior-verify-cdp.mjs")


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
        return "node not on PATH — editor-behavior harness needs Node.js"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=180
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_editor_behavior():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "editor-behavior suite failed (exit %d):\n%s" % (code, out[-1500:])


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
        print("OK: editor behavior legs green (T-234 jump-no-poison + edit-restore; "
              "T-237 classification contract)")
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
