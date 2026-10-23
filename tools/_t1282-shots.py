#!/usr/bin/env python3
"""T-1282 evidence shots: the project browser opened by ?browse=1, on AEF's project corpus.

The designer is served by gallery-serve.py over a temp version store holding every version of
.agentic-framework/.context/designer/projects/* (what AEF stores), each map's latest version given a thumbnail
rendered by the designer's own captureThumbnail() (the PNG a save writes), so the cards show real tiles.
  browse-{w}.png        designer.html?browse=1 as it opens: the browser, every card (1024x768, 1440x900, 1920x1080);
  browse-hover-{w}.png  the same, the pointer on the aef-task-lifecycle card: the hover-zoom preview showing;
  button-{w}.png        the browser opened by the Open project button, for comparison (1440 only).
Usage: python3 tools/_t1282-shots.py [outdir]   (default docs/reports/T-1282-evidence). Exit 0 = shots taken; 3 = no
playwright. Asserts nothing: the reading is in the task's ## Visual Verification.
"""
import base64
import importlib.util
import json
import os
import shutil
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECTS = os.path.join(ROOT, ".agentic-framework", ".context", "designer", "projects")
SRC = os.environ.get("T1282_SRC") or os.path.join(ROOT, "src", "aef-workflow-designer.html")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "reports", "T-1282-evidence")
SIZES = {1024: 768, 1440: 900, 1920: 1080}
HOVER = "aef-task-lifecycle"

spec = importlib.util.spec_from_file_location("t962", os.path.join(ROOT, "tests", "test_t962_findings_on_map.py"))
t962 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t962)

JS_THUMB = """async (args) => {
  const xml = await (await fetch(`/api/version?id=${args.id}&v=${args.v}`)).text();
  adoptImportedXml(xml, { replace: true, userImport: true, projectId: args.id });
  renderAll();
  await new Promise(r => setTimeout(r, 150));
  return await captureThumbnail();
}"""
READY = "() => typeof _appReady !== 'undefined' && _appReady === true && _apiAvailable === true"
CARDS_IN = ("() => { const m = document.getElementById('project-modal'); if (!m) return false;"
            " const im = m.querySelectorAll('img'); return im.length > 0 && Array.prototype.every.call(im, i => i.complete); }")


def build_store(repo):
    latest = {}
    for id_ in sorted(os.listdir(PROJECTS)):
        meta_p = os.path.join(PROJECTS, id_, "meta.json")
        if not os.path.exists(meta_p):
            continue
        meta = json.load(open(meta_p, encoding="utf-8"))
        out = os.path.join(repo, ".editor-versions", id_)
        os.makedirs(out)
        index = [v for v in meta["versions"] if os.path.exists(os.path.join(PROJECTS, id_, "v%d.bpmn" % v["v"]))]
        for v in index:
            shutil.copy(os.path.join(PROJECTS, id_, "v%d.bpmn" % v["v"]), os.path.join(out, "v%d.bpmn" % v["v"]))
        json.dump([{"v": v["v"], "ts": v["ts"], "note": v.get("note", "")} for v in index],
                  open(os.path.join(out, "index.json"), "w"), indent=2)
        latest[id_] = max(v["v"] for v in index)
    return latest


def main():
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("no playwright")
        return 3
    os.makedirs(OUT, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix="t1282-")
    docroot = os.path.join(tmp, "docroot")
    repo = os.path.join(tmp, "repo")
    os.makedirs(os.path.join(docroot, "rendered"))
    os.makedirs(repo)
    shutil.copy(SRC, os.path.join(docroot, "designer.html"))
    latest = build_store(repo)
    t962.ROOT = repo   # start_server serves --repo t962.ROOT: point it at the temp store, not this repository
    proc, port = t962.start_server(docroot)
    base = "http://127.0.0.1:%d/designer.html" % port
    n = 0

    def shot(page, name):
        nonlocal n
        page.screenshot(path=os.path.join(OUT, name))
        n += 1
        print("ok   " + name)

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            # the thumbnails: one page, every map's latest version drawn by the designer, written into the temp store
            page = browser.new_page(viewport={"width": 1440, "height": 900})
            page.goto(base)
            page.wait_for_function(READY, timeout=int(os.environ.get("CDP_READY_MS", "20000")))
            for id_, v in latest.items():
                url = page.evaluate(JS_THUMB, {"id": id_, "v": v})
                if url:
                    open(os.path.join(repo, ".editor-versions", id_, "v%d.png" % v), "wb").write(base64.b64decode(url.split(",", 1)[1]))
            page.close()
            for w, h in SIZES.items():
                ctx = browser.new_context(viewport={"width": w, "height": h})   # fresh storage: no autosave restored
                page = ctx.new_page()
                page.goto(base + "?browse=1")
                page.wait_for_function(READY, timeout=int(os.environ.get("CDP_READY_MS", "20000")))
                page.wait_for_function(CARDS_IN, timeout=8000)
                page.wait_for_timeout(300)
                shot(page, "browse-%d.png" % w)
                page.hover('#project-modal button[title="Open %s"]' % HOVER)
                page.wait_for_timeout(500)
                shot(page, "browse-hover-%d.png" % w)
                ctx.close()
            ctx = browser.new_context(viewport={"width": 1440, "height": 900})
            page = ctx.new_page()
            page.goto(base)
            page.wait_for_function(READY, timeout=int(os.environ.get("CDP_READY_MS", "20000")))
            page.click("#btn-open-project")
            page.wait_for_function(CARDS_IN, timeout=8000)
            page.wait_for_timeout(300)
            shot(page, "button-1440.png")
            ctx.close()
            browser.close()
    finally:
        proc.terminate()
        proc.wait()
        shutil.rmtree(tmp, ignore_errors=True)
    print("%d shots -> %s" % (n, OUT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
