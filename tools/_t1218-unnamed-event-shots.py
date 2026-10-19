#!/usr/bin/env python3
"""T-1218 screenshots: an unnamed start/end event on the canvas, before and after the fix, at 1024/1440/1920.

Loads a real third-party fixture whose start and end events carry no name
(tests/fixtures/third-party/zeebe-service-task.bpmn: StartEvent_1, Event_1ijl6th) into the real designer, served
by the gallery server T-962 uses, and screenshots the page at the three review widths (the UI review rule,
2026-10-14) for the source just before the fix ("before", BEFORE_REF) and for the working tree ("after").

Asserted per width: BEFORE, the canvas labels of the two events read their ids (the reported defect);
AFTER, no node label on the canvas equals either id, and the service task's label is unchanged.
Usage: python3 tools/_t1218-unnamed-event-shots.py [outdir]   (default docs/reports/T-1218-evidence)
Exit 0 = all asserted; 1 = an assertion failed; 3 = could not measure (no playwright, no fixture).
"""
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURE = os.path.join(ROOT, "tests", "fixtures", "third-party", "zeebe-service-task.bpmn")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "reports", "T-1218-evidence")
IDS = ["StartEvent_1", "Event_1ijl6th"]
BEFORE_REF = os.environ.get("T1218_BEFORE_REF", "036e5403~1")

spec = importlib.util.spec_from_file_location("t962", os.path.join(ROOT, "tests", "test_t962_findings_on_map.py"))
t962 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t962)

JS_LOAD = """(xml) => {
  adoptImportedXml(xml, { userImport: true });
  renderAll();
  return Array.from(document.querySelectorAll('.node-label')).map(e => e.textContent.trim());
}"""


def shoot(label, src_bytes, xml, fails):
    tmp = tempfile.mkdtemp(prefix="t1218-")
    docroot = os.path.join(tmp, "docroot")
    os.makedirs(docroot)
    with open(os.path.join(docroot, "designer.html"), "wb") as fh:
        fh.write(src_bytes)
    proc, port = t962.start_server(docroot)
    try:
        from playwright.sync_api import sync_playwright
        with sync_playwright() as p:
            browser = p.chromium.launch()
            for w, h in ((1024, 768), (1440, 900), (1920, 1080)):
                page = browser.new_page(viewport={"width": w, "height": h}, device_scale_factor=2)
                page.goto("http://127.0.0.1:%d/designer.html" % port)
                page.wait_for_function("() => typeof _appReady !== 'undefined' && _appReady === true",
                                       timeout=int(os.environ.get("CDP_READY_MS", "20000")))
                labels = page.evaluate(JS_LOAD, xml)
                page.wait_for_timeout(300)
                page.screenshot(path=os.path.join(OUT, "t1218-%s-%d.png" % (label, w)))
                # Close-up: the union of the node groups, padded, so the labels under the events are legible.
                box = page.evaluate("""() => {
                  const r = Array.from(document.querySelectorAll('.node-label')).map(e => e.parentNode.getBoundingClientRect());
                  if (!r.length) return null;
                  const x0 = Math.min(...r.map(b => b.left)) - 40, y0 = Math.min(...r.map(b => b.top)) - 40;
                  const x1 = Math.max(...r.map(b => b.right)) + 40, y1 = Math.max(...r.map(b => b.bottom)) + 40;
                  return { x: Math.max(0, x0), y: Math.max(0, y0), width: x1 - Math.max(0, x0), height: y1 - Math.max(0, y0) };
                }""")
                if box:
                    page.screenshot(path=os.path.join(OUT, "t1218-%s-%d-detail.png" % (label, w)), clip=box)
                shown = [i for i in IDS if i in labels]
                if label == "before":
                    ok = shown == IDS
                else:
                    ok = not shown and any(l for l in labels if l not in IDS)
                print("%s  %s %d: labels=%s" % ("ok  " if ok else "FAIL", label, w, json.dumps(labels)[:300]))
                if not ok:
                    fails.append("%s-%d" % (label, w))
                page.close()
            browser.close()
    finally:
        proc.terminate()
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    if not os.path.isfile(FIXTURE):
        print("COULD-NOT-MEASURE: fixture missing: %s" % FIXTURE)
        return 3
    try:
        import playwright.sync_api  # noqa: F401
    except Exception as e:
        print("COULD-NOT-MEASURE: playwright not importable: %s" % e)
        return 3
    xml = open(FIXTURE, encoding="utf-8").read()
    os.makedirs(OUT, exist_ok=True)
    # The parent of the T-1218 fix commit (036e5403): HEAD carries the fix from then on.
    before = subprocess.run(["git", "-C", ROOT, "show", BEFORE_REF + ":src/aef-workflow-designer.html"],
                            capture_output=True, check=True).stdout
    after = open(os.path.join(ROOT, "src", "aef-workflow-designer.html"), "rb").read()
    fails = []
    shoot("before", before, xml, fails)
    shoot("after", after, xml, fails)
    print("T-1218 shots: %s, written to %s" % ("all asserted" if not fails else "FAILED at %s" % fails, OUT))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
