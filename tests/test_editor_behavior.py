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


def _text(b):
    if b is None:
        return ""
    return b.decode("utf-8", "replace") if isinstance(b, bytes) else b


def _last_step(err):
    steps = [l for l in err.splitlines() if l.startswith("[ebv +")]
    return steps[-1] if steps else "(no step logged — the harness never started its first step)"


def run_harness():
    """(exit code, output). The harness logs `[ebv +ms] step` lines to stderr (T-1431); they are shown only when the
    run fails, and on a timeout the partial output is KEPT and the last step named. Before T-1431 a timeout raised
    TimeoutExpired, which discarded everything the harness had printed, so three hangs left no trace."""
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    limit = int(os.environ.get("EBV_TIMEOUT_S", "180"))   # override only to prove the timeout path
    # Own process group: on a timeout the WHOLE group (node, its Chrome, its sidecar) is killed, not node alone,
    # which left the hung run's Chrome and server behind to load the next leg.
    proc = subprocess.Popen(["node", HARNESS], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            text=True, start_new_session=True)
    try:
        out, err = proc.communicate(timeout=limit)
    except subprocess.TimeoutExpired:
        import signal
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        out, err = proc.communicate()
        tail = "\n".join((err or "").splitlines()[-40:])
        return 124, ("HANG: the harness was killed after %d s. Last step reached:\n  %s\n"
                     "Partial stdout:\n%s\nLast 40 stderr lines:\n%s\n" % (limit, _last_step(err or ""), out or "", tail))
    if proc.returncode == 0:
        return 0, out or ""
    err = err or ""
    return proc.returncode, (out or "") + "\nLast step: %s\nLast 40 stderr lines:\n%s\n" % (
        _last_step(err), "\n".join(err.splitlines()[-40:]))


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
