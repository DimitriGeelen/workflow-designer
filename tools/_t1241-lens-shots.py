#!/usr/bin/env python3
"""T-1241 screenshots: each lens (business / logical / technical / all) on aef-task-lifecycle at 1024/1440/1920.

Two states per lens and width: "panel" (a service task selected: canvas decoration + side panel) and "details"
(the element details view open on the same task). Served by the gallery server T-962 uses (real repo, so the real
interim lens file is read). Asserts only that every shot was taken and the lens select shows the lens; the
reading of each shot, control by control, is in the task's ## Visual Verification (UI review rule, 2026-10-14).
Usage: python3 tools/_t1241-lens-shots.py [outdir]   (default docs/reports/T-1241-evidence)
Exit 0 = shots taken; 3 = could not measure.
"""
import importlib.util
import os
import shutil
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURE = os.path.join(ROOT, ".agentic-framework", ".context", "designer", "projects", "aef-task-lifecycle", "v3.bpmn")
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "reports", "T-1241-evidence")
LENSES = ["business", "logical", "technical", "all"]
WIDTHS = ((1024, 768), (1440, 900), (1920, 1080))
PICK = "tl_create"   # service task "create task - fw work-on": carries meta (state, note), the richest panel

spec = importlib.util.spec_from_file_location("t962", os.path.join(ROOT, "tests", "test_t962_findings_on_map.py"))
t962 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t962)

JS_LOAD = """(args) => {
  adoptImportedXml(args.xml, { userImport: true });
  renderAll();
  setLens(args.lens);
  const n = state.nodes.find(x => x.uid === args.uid);
  selection = { kind: 'node', id: n.id };
  renderProperties();
  return document.getElementById('lens-select').value;
}"""


def main():
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("no playwright")
        return 3
    os.makedirs(OUT, exist_ok=True)
    xml = open(FIXTURE, encoding="utf-8").read()
    tmp = tempfile.mkdtemp(prefix="t1241-")
    docroot = os.path.join(tmp, "docroot")
    os.makedirs(docroot)
    shutil.copy(SRC, os.path.join(docroot, "designer.html"))
    proc, port = t962.start_server(docroot)
    fails = []
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            for lens in LENSES:
                for w, h in WIDTHS:
                    page = browser.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
                    page.goto("http://127.0.0.1:%d/designer.html" % port)
                    page.wait_for_function("() => typeof _appReady !== 'undefined' && _appReady === true && !!_lensDef",
                                           timeout=int(os.environ.get("CDP_READY_MS", "20000")))
                    got = page.evaluate(JS_LOAD, {"xml": xml, "lens": lens, "uid": PICK})
                    page.wait_for_timeout(400)
                    page.screenshot(path=os.path.join(OUT, "t1241-%s-%d-panel.png" % (lens, w)))
                    page.evaluate("(uid) => openDetails(state.nodes.find(x => x.uid === uid).id)", PICK)
                    page.wait_for_timeout(300)
                    page.screenshot(path=os.path.join(OUT, "t1241-%s-%d-details.png" % (lens, w)))
                    ok = got == lens
                    print("%s  %s %d: lens-select=%s" % ("ok  " if ok else "FAIL", lens, w, got))
                    if not ok:
                        fails.append("%s-%d" % (lens, w))
                    page.close()
            browser.close()
    finally:
        proc.terminate()
        shutil.rmtree(tmp, ignore_errors=True)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
