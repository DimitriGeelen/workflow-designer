#!/usr/bin/env python3
"""T-1256 screenshots: aef-task-lifecycle's canvas, designer-v0.24.0 ("before") vs the working source ("after").

At 1920 and 1024: id captions on and off (lens All; 0.24.0 has no lenses), plus the Business lens after. The map is
opened through the ?load= deep link, the way a person opens it, so "after" at 1024 shows openingZoom()'s readable
view; "after-1024-*-scrolled-*" scroll that view to the middle and the right end (the rest is reached by scroll).
Element shots of the canvas area, the Clean-layout nudge dismissed with its ✕. Asserts only that every shot was taken; the reading of each shot, control by
control, is in T-1256's ## Visual Verification (UI review rule, 2026-10-14).
Usage: python3 tools/_t1256-shots.py [outdir]   (default docs/reports/T-1256-evidence)
Exit 0 = shots taken; 1 = a shot failed; 3 = could not measure.
"""
import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURE = os.path.join(ROOT, ".agentic-framework", ".context", "designer", "projects", "aef-task-lifecycle", "v3.bpmn")
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
BASE_TAG = "designer-v0.24.0"
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "reports", "T-1256-evidence")
WIDTHS = ((1920, 1080), (1024, 768))

spec = importlib.util.spec_from_file_location("t962", os.path.join(ROOT, "tests", "test_t962_findings_on_map.py"))
t962 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t962)

SET = """(a) => {
  if (a.lens && typeof setLens === 'function') setLens(a.lens);
  labelPrefs.showIds = a.ids; renderAll();
  return { zoom: typeof zoomFactor === 'undefined' ? null : zoomFactor, nodes: state.nodes.length };
}"""


def main():
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("no playwright")
        return 3
    os.makedirs(OUT, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="t1256-shots-")
    roots = {}
    for tag, html in (("before", subprocess.check_output(["git", "-C", ROOT, "show", BASE_TAG + ":src/aef-workflow-designer.html"])),
                      ("after", open(SRC, "rb").read())):
        d = os.path.join(tmp, tag)
        os.makedirs(os.path.join(d, "rendered"))
        open(os.path.join(d, "designer.html"), "wb").write(html)
        shutil.copy(FIXTURE, os.path.join(d, "rendered", "lifecycle.bpmn"))
        roots[tag] = d
    procs, fails = [], []
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            for tag, d in roots.items():
                proc, port = t962.start_server(d)
                procs.append(proc)
                cfgs = [("ids", None, True), ("noids", None, False)] + ([("business", "business", True)] if tag == "after" else [])
                for w, h in WIDTHS:
                    for name, lens, ids in cfgs:
                        page = browser.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
                        page.goto("http://127.0.0.1:%d/designer.html?load=rendered/lifecycle.bpmn" % port)
                        page.wait_for_function("() => typeof _appReady !== 'undefined' && _appReady === true && window._deepLinkSettled === 'adopted'",
                                               timeout=int(os.environ.get("CDP_READY_MS", "20000")))
                        if lens:
                            page.wait_for_function("() => !!_lensDef", timeout=int(os.environ.get("CDP_READY_MS", "20000")))
                        got = page.evaluate(SET, {"lens": lens, "ids": ids})
                        page.evaluate("() => { const x = document.getElementById('clean-nudge-dismiss'); if (x && x.offsetParent) x.click(); }")   # dismissed, as a person would
                        page.wait_for_timeout(300)
                        wrap = page.locator(".canvas-wrap")
                        f = os.path.join(OUT, "%s-%d-%s.png" % (tag, w, name))
                        wrap.screenshot(path=f)
                        if tag == "after" and got["zoom"] is not None:
                            for where, frac in (("mid", 0.5), ("end", 1.0)):
                                page.evaluate("(f) => { const w = document.querySelector('.canvas-wrap'); w.scrollLeft = (w.scrollWidth - w.clientWidth) * f; }", frac)
                                page.wait_for_timeout(200)
                                wrap.screenshot(path=os.path.join(OUT, "%s-%d-%s-scrolled-%s.png" % (tag, w, name, where)))
                        ok = got["nodes"] > 10
                        print("%s  %s %d %s: zoom=%s" % ("ok  " if ok else "FAIL", tag, w, name, got["zoom"]))
                        if not ok:
                            fails.append(f)
                        page.close()
            browser.close()
    finally:
        for proc in procs:
            proc.terminate()
        shutil.rmtree(tmp, ignore_errors=True)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
