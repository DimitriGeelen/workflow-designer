#!/usr/bin/env python3
"""test_t308_bare_catch_render — T-308 (T-244 GO, path b) regression guard for the
neutral presentation of a bare catch event, arc: designer-authoring-surface.

The real work is `tools/_t308-bare-catch-render-cdp.mjs`, which drives the REAL
editor runtime (parseBpmnXml → renderAll → renderProperties → buildBpmnXml) in an
isolated headless chromium against tests/fixtures/aef-bpmn/bare-catch-event.bpmn.

Background: a <bpmn:intermediateCatchEvent> carrying no <aef:link> and no
recognised <aef:eventDef> decodes to linkEventCatch via the REVERSE_TYPE fallback
— there is no neutral landing type — and then wears the "← Handoff" glyph plus a
link property schema whose target fields can never bind. AEF's operator read that
as a broken connector on a healthy map (T-244 exploration, GO on path b).

The harness asserts, in five layers:

  * MODEL   the bare node KEEPS type linkEventCatch (presentation-only fix — a
            type change would be path (a), a dialect change AEF must ratify)
            while isBareCatchEvent() singles it out; uuid-bound, legacy-slug and
            typed-catch nodes are not flagged (T-204/T-237 untouched);
  * RENDER  the bare node draws the neutral double ring, no chevron; a bound
            handoff still draws circle + chevron;
  * PANEL   the bare node shows the neutral 'intermediateEvent' badge and the
            "Make this a handoff" affordance and NOT the dead target picker/jump;
            a bound handoff's panel is unchanged. Read from #properties, never
            document.body — static modal/palette markup carries the same strings
            and would make these assertions vacuously true;
  * EXPORT  ZERO export surface: exactly 2 <aef:link> survive, the bare node's
            block emits none, a second save is byte-identical, and a
            palette-created (unbound) handoff also emits none — intent is never
            persisted, which is what keeps this off AEF's ratification path;
  * SESSION IW-3: a palette-created handoff keeps its handoff UI while live, and
            flips neutral once the session Set is cleared (reload proxy);
  * BITE    giving the bare node a targetWorkflow flips it back to the handoff
            presentation — proving the branch reads node state, not a constant.

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green (T-212 convention). Runs standalone
(`python3 tests/test_t308_bare_catch_render.py`) and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_t308-bare-catch-render-cdp.mjs")
FIXTURE = os.path.join(
    ROOT, "tests", "fixtures", "aef-bpmn", "bare-catch-event.bpmn"
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
        return "node not on PATH — t308 bare-catch harness needs Node.js"
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


def test_bare_catch_render():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "t308 bare-catch harness failed (exit %d):\n%s" % (
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
            "OK: bare catch event presents neutrally (glyph, panel), bound and "
            "typed catches are unaffected, export surface is zero, session intent "
            "dies with the session, and the guard bites"
        )
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
