#!/usr/bin/env python3
"""T-1278 evidence shots: the codex sweep items, on aef-task-lifecycle, opened as tools/_t1241-lens-shots.py opens it.

Reachability (items 1-3, 5), device scale 1, the side panel open on `tl_create`:
  reach-{lens}-{w}-{left,mid,right}.png   the canvas scrolled to its left end, middle and right end (1024, 1440, 1920);
  palette-end-{lens}-{w}.png              the left palette scrolled to its end, LANES in view (1024, 1440, 1920).
Crops at device scale 2 (one per fixed item and width):
  open-text-2x-{lens}-{w}.png             the canvas at the opening zoom, top-left 640x360 (items 6-7);
  name-field-2x-{lens}-{w}.png            the side panel's BPMN section with the Name box (item 4);
  palette-2x-{lens}-{w}.png               the left palette top and its typed events (item 10), business and logical;
  helper-2x-{lens}-{w}.png                the details view's field labels and helper text (item 11).
Usage: python3 tools/_t1278-shots.py [outdir]   (default docs/reports/T-1278-evidence). Exit 0 = shots taken; 3 = no
playwright. Asserts nothing: the reading is in the task's ## Visual Verification.
"""
import importlib.util
import os
import shutil
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURE = os.path.join(ROOT, ".agentic-framework", ".context", "designer", "projects", "aef-task-lifecycle", "v3.bpmn")
SRC = os.environ.get("T1278_SRC") or os.path.join(ROOT, "src", "aef-workflow-designer.html")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "reports", "T-1278-evidence")
SIZES = {1024: 768, 1440: 900, 1920: 1080}
PICK = "tl_create"

spec = importlib.util.spec_from_file_location("t962", os.path.join(ROOT, "tests", "test_t962_findings_on_map.py"))
t962 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t962)

JS_LOAD = """(args) => {
  adoptImportedXml(args.xml, { userImport: true });
  renderAll();
  if (typeof openingZoom === 'function') openingZoom();
  setLens(args.lens);
  const n = state.nodes.find(x => x.uid === args.uid);
  selection = { kind: 'node', id: n.id };
  renderProperties();
  return document.getElementById('lens-select').value;
}"""


def rect(page, sel):
    return page.evaluate("(s) => { const r = document.querySelector(s).getBoundingClientRect(); return [r.left, r.top, r.width, r.height]; }", sel)


def clip(x, y, w, h):
    return {"x": max(0, x), "y": max(0, y), "width": w, "height": h}


def main():
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("no playwright")
        return 3
    os.makedirs(OUT, exist_ok=True)
    xml = open(FIXTURE, encoding="utf-8").read()
    tmp = tempfile.mkdtemp(prefix="t1278-")
    docroot = os.path.join(tmp, "docroot")
    os.makedirs(docroot)
    shutil.copy(SRC, os.path.join(docroot, "designer.html"))
    proc, port = t962.start_server(docroot)
    n = 0

    def open_page(browser, w, scale, lens):
        page = browser.new_page(viewport={"width": w, "height": SIZES[w]}, device_scale_factor=scale)
        page.goto("http://127.0.0.1:%d/designer.html" % port)
        page.wait_for_function("() => typeof _appReady !== 'undefined' && _appReady === true && !!_lensDef",
                               timeout=int(os.environ.get("CDP_READY_MS", "20000")))
        page.evaluate(JS_LOAD, {"xml": xml, "lens": lens, "uid": PICK})
        page.wait_for_timeout(400)
        return page

    def shot(page, name, **kw):
        nonlocal n
        page.screenshot(path=os.path.join(OUT, name), **kw)
        n += 1
        print("ok   " + name)

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            for lens in ("business", "all"):
                for w in (1024, 1440, 1920):   # 1920 too: at the 9 px opening (zoom 1.00) the map is wider than the canvas
                    page = open_page(browser, w, 1, lens)
                    for pos, frac in (("left", 0), ("mid", 0.5), ("right", 1)):
                        page.evaluate("(f) => { canvasWrap.scrollLeft = (canvasWrap.scrollWidth - canvasWrap.clientWidth) * f; syncOverlayPin(); }", frac)
                        page.wait_for_timeout(200)
                        shot(page, "reach-%s-%d-%s.png" % (lens, w, pos))
                    page.close()
            for w in (1024, 1440, 1920):
                page = open_page(browser, w, 1, "business")
                page.evaluate("() => { const p = document.querySelector('.palette'); p.scrollTop = p.scrollHeight; }")
                page.wait_for_timeout(200)
                shot(page, "palette-end-business-%d.png" % w)
                page.close()
            for w in (1024, 1440, 1920):
                for lens in ("business", "logical", "technical", "all"):
                    page = open_page(browser, w, 2, lens)
                    x, y, cw, ch = rect(page, ".canvas-wrap")
                    shot(page, "open-text-2x-%s-%d.png" % (lens, w), clip=clip(x, y, min(640, cw), min(360, ch)))
                    if lens in ("business", "all"):
                        px, py, pw, ph = rect(page, "#properties")
                        shot(page, "name-field-2x-%s-%d.png" % (lens, w), clip=clip(px, py, pw, min(300, ph)))
                    if lens in ("business", "logical"):
                        ax, ay, aw, ah = rect(page, ".palette")
                        shot(page, "palette-2x-%s-%d.png" % (lens, w), clip=clip(ax, ay, aw, min(560, ah)))
                        page.evaluate("() => { const p = document.querySelector('.palette'); p.scrollTop = p.scrollHeight; }")
                        page.wait_for_timeout(150)
                        shot(page, "palette-end-2x-%s-%d.png" % (lens, w), clip=clip(ax, ay + ah - min(420, ah), aw, min(420, ah)))
                    if lens == "all":
                        page.evaluate("(uid) => openDetails(state.nodes.find(x => x.uid === uid).id)", PICK)
                        page.wait_for_timeout(300)
                        bx, by, bw, bh = rect(page, "#details-body")
                        shot(page, "helper-2x-%s-%d.png" % (lens, w), clip=clip(bx, by, min(bw, 720), min(bh, 420)))
                    page.close()
            browser.close()
    finally:
        proc.terminate()
        shutil.rmtree(tmp, ignore_errors=True)
    print("%d shots in %s" % (n, OUT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
