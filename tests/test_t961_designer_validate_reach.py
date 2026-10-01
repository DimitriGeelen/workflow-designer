#!/usr/bin/env python3
"""test_t961_designer_validate_reach — the designer can REACH the validator (T-309 slice 2).

WHAT THIS GUARDS. ~24 XmlValidator rules are trusted and green, and until T-955 none of them
reached the person drawing the map, which is where the mistake is actually made (T-309). T-955
built the route; this leg guards the editor's side of it: `validateCurrentWorkflow()` serialises
the live map, posts it, and returns a parsed result.

WHY A REAL BROWSER AND A REAL SERVER. The function under test calls `buildBpmnXml(state)` and
`fetch('/api/validate')`. Unit-calling a copy of it would prove a copy works. So this drives the
REAL editor in headless chromium, served over real HTTP by the real `tools/gallery-serve.py`,
from a docroot holding a byte-identical copy of `src/aef-workflow-designer.html`.

  The byte-identical copy is not incidental. `build/gallery/designer.html` is a COPY refreshed by
  `tools/serve-gallery.sh`, and in this tree it ALREADY differs from src/ — so a test pointed at
  the ordinary serve root can pass against code that is not the code under test. The copy is
  asserted with filecmp before the server starts.

THE SHAPE IS THE PROPERTY. `validateCurrentWorkflow()` returns a tagged union:

    { ok: true,  findings: [...], errors: n, warnings: n }
    { ok: false, reason: '<readable>' }

An empty `findings` must mean THE VALIDATOR RAN AND FOUND NOTHING, and must never also mean the
validator could not run. Those two render identically if you return `[]` for both, and "looks
clean" then becomes indistinguishable from "never looked". So every clean leg here is paired
with a leg that cannot look, and the unavailable legs assert `findings` is ABSENT — not empty.

Chromium absence is an ENVIRONMENT skip surfaced LOUDLY, never a silent green (T-212).

Exit 0 iff every leg passes. Run: python3 tests/test_t961_designer_validate_reach.py
"""
import filecmp
import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# T961_DESIGNER_SRC retargets the page under test. It exists for the TEETH and for nothing
# else: pointed at a pre-change copy of the designer, this file must REFUSE (rc=3) rather
# than pass, which is the only way to show the legs below are load-bearing. Same convention
# as T560_TASK_ROOT in tools/_t560-absence-assertion-census.py.
SRC = os.environ.get("T961_DESIGNER_SRC") or os.path.join(
    ROOT, "src", "aef-workflow-designer.html")
SERVER = os.path.join(ROOT, "tools", "gallery-serve.py")

results = []


def check(name, cond, detail=""):
    results.append((name, bool(cond)))
    print("%s %s%s" % ("PASS" if cond else "FAIL", name, (" — " + detail) if detail else ""))


def _chromium_present():
    cache = os.path.join(os.path.expanduser("~"), ".cache", "ms-playwright")
    if not os.path.isdir(cache):
        return False
    for d in os.listdir(cache):
        if d.startswith("chromium") and os.path.isdir(os.path.join(cache, d)):
            return True
    return False


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


def start_server(docroot):
    port = free_port()
    proc = subprocess.Popen(
        [sys.executable, SERVER, str(port), "--repo", ROOT,
         "--docroot", docroot, "--bind", "127.0.0.1"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(100):
        try:
            urllib.request.urlopen("http://127.0.0.1:%d/api/health" % port, timeout=0.5)
            return proc, port
        except Exception:
            time.sleep(0.05)
    proc.terminate()
    raise RuntimeError("gallery-serve did not come up")


# Mutate ONE field on ONE node: point it at a lane that does not exist. A real editor-side
# mistake (a lane deleted out from under a node), and the minimum possible difference from the
# clean document, so a finding cannot be blamed on anything else. Restored in a finally so the
# clean re-measurement afterwards is meaningful.
JS_DIRTY = """
async () => {
  const node = state.nodes[0];
  const original = node.lane;
  node.lane = 'lane-that-does-not-exist';
  let dirty;
  try { dirty = await validateCurrentWorkflow(); }
  finally { node.lane = original; }
  const clean = await validateCurrentWorkflow();
  return {
    dirty_ok: dirty.ok,
    dirty_rules: dirty.findings ? [...new Set(dirty.findings.map(f => f.rule))] : null,
    dirty_errors: dirty.errors,
    first_keys: (dirty.findings && dirty.findings[0]) ? Object.keys(dirty.findings[0]).sort() : null,
    clean_ok: clean.ok,
    clean_count: clean.findings ? clean.findings.length : null,
    lane_restored: state.nodes[0].lane === original,
  };
}
"""

# _apiAvailable false is how the standalone file:// build presents: no server at all.
JS_OFFLINE = """
async () => {
  const was = _apiAvailable;
  _apiAvailable = false;
  const r = await validateCurrentWorkflow();
  _apiAvailable = was;
  return {
    ok: r.ok,
    reason: r.reason || null,
    has_findings_key: Object.prototype.hasOwnProperty.call(r, 'findings'),
  };
}
"""

# The server is gone but _apiAvailable is still true — the realistic mid-session failure.
# Also asserts the fault reached _faults, because an editor failure with no record is one of
# this suite's own standing complaints.
JS_UNREACHABLE = """
async () => {
  const r = await validateCurrentWorkflow();
  const rows = (typeof _faults !== 'undefined' && Array.isArray(_faults)) ? _faults : null;
  return {
    api_available_still_true: _apiAvailable === true,
    ok: r.ok,
    reason: r.reason || null,
    has_findings_key: Object.prototype.hasOwnProperty.call(r, 'findings'),
    fault_recorded: rows ? rows.some(f => f.code === 'validate') : false,
  };
}
"""


def main():
    if not os.path.isfile(SRC):
        print("COULD-NOT-MEASURE: %s missing" % SRC, file=sys.stderr)
        return 3
    if not os.path.isfile(SERVER):
        print("COULD-NOT-MEASURE: %s missing" % SERVER, file=sys.stderr)
        return 3
    if "validateCurrentWorkflow" not in open(SRC, encoding="utf-8").read():
        print("COULD-NOT-MEASURE: validateCurrentWorkflow() is not in the designer; this leg "
              "guards a function that does not exist", file=sys.stderr)
        return 3
    try:
        from playwright.sync_api import sync_playwright
    except Exception as e:
        print("SKIP (ENVIRONMENT): playwright python is not importable: %s" % e, file=sys.stderr)
        print("SKIP (ENVIRONMENT): this leg asserted NOTHING this run", file=sys.stderr)
        return 0
    if not _chromium_present():
        print("SKIP (ENVIRONMENT): no chromium under ~/.cache/ms-playwright", file=sys.stderr)
        print("SKIP (ENVIRONMENT): this leg asserted NOTHING this run", file=sys.stderr)
        return 0

    tmp = tempfile.mkdtemp(prefix="t961-")
    docroot = os.path.join(tmp, "docroot")
    os.makedirs(docroot, exist_ok=True)
    served = os.path.join(docroot, "designer.html")
    shutil.copy2(SRC, served)

    # The code under test, not a stale copy of it.
    check("the served page is byte-identical to src/aef-workflow-designer.html",
          filecmp.cmp(SRC, served, shallow=False),
          "docroot=%s" % docroot)

    proc, port = start_server(docroot)
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page()
            page.goto("http://127.0.0.1:%d/designer.html" % port)
            # detectSaveApi() probes /api/health on load and flips _apiAvailable.
            page.wait_for_function("() => typeof _apiAvailable !== 'undefined' && _apiAvailable === true",
                                   timeout=15000)

            # --- leg 1: the seed map is clean, and that zero is a MEASUREMENT ------------
            clean = page.evaluate("""async () => {
              const r = await validateCurrentWorkflow();
              return { ok: r.ok, count: r.findings ? r.findings.length : null,
                       errors: r.errors, warnings: r.warnings,
                       is_array: Array.isArray(r.findings) };
            }""")
            check("clean seed map -> ok:true, zero findings, counts present",
                  clean["ok"] is True and clean["count"] == 0 and clean["is_array"] is True
                  and clean["errors"] == 0 and clean["warnings"] == 0,
                  json.dumps(clean))

            # --- leg 2: one bad lane ref -> a NAMED rule, then clean again ---------------
            d = page.evaluate(JS_DIRTY)
            check("one node pointed at a missing lane -> E-XML-NODE-UNASSIGNED",
                  d["dirty_ok"] is True and d["dirty_rules"] == ["E-XML-NODE-UNASSIGNED"]
                  and d["dirty_errors"] == 1,
                  json.dumps({k: d[k] for k in ("dirty_ok", "dirty_rules", "dirty_errors")}))
            check("a finding carries rule + severity + message + location",
                  d["first_keys"] == ["location", "message", "rule", "severity"],
                  str(d["first_keys"]))
            check("restoring the lane returns the map to zero findings "
                  "(so leg 1's zero is a measurement, not blindness)",
                  d["clean_ok"] is True and d["clean_count"] == 0 and d["lane_restored"] is True,
                  json.dumps({k: d[k] for k in ("clean_ok", "clean_count", "lane_restored")}))

            # --- leg 3: no server at all (the file:// build) ------------------------------
            off = page.evaluate(JS_OFFLINE)
            check("no API available -> ok:false and NO findings key (not an empty list)",
                  off["ok"] is False and off["has_findings_key"] is False
                  and bool(off["reason"]),
                  json.dumps(off))

            # --- leg 4: THE TEETH. Server killed mid-session ------------------------------
            # Without this leg the file would pass against a function that cannot tell a
            # reachable validator from an unreachable one.
            proc.terminate()
            proc.wait(timeout=10)
            unreach = page.evaluate(JS_UNREACHABLE)
            check("server gone while _apiAvailable is still true -> ok:false, no findings key",
                  unreach["ok"] is False and unreach["has_findings_key"] is False
                  and unreach["api_available_still_true"] is True,
                  json.dumps({k: unreach[k] for k in
                              ("ok", "has_findings_key", "api_available_still_true")}))
            check("the unreachable failure is RECORDED via aefRecordFault, not swallowed",
                  unreach["fault_recorded"] is True,
                  "reason=%s" % (unreach["reason"] or "")[:70])

            browser.close()
    finally:
        if proc.poll() is None:
            proc.terminate()
            proc.wait(timeout=10)
        shutil.rmtree(tmp, ignore_errors=True)

    passed = sum(1 for _, ok in results if ok)
    failed = len(results) - passed
    print()
    print("designer validate reach: %d passed, %d failed" % (passed, failed))
    if failed:
        print("designer validate reach: FAILED")
        return 1
    print("OK: the designer reaches the one validator, and cannot-look is distinguishable "
          "from found-nothing")
    return 0


if __name__ == "__main__":
    sys.exit(main())
