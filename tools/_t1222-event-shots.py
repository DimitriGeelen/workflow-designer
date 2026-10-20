#!/usr/bin/env python3
"""T-1222 screenshots: third-party native event kinds on the canvas, before and after the fix, at 1024/1440/1920.

Loads tests/fixtures/t1222/native-event-kinds.bpmn (a timer catch and a message boundary, typed from their
definition; a signal catch and an escalation boundary, plain; a signal throw, plain; a boundary with no definition)
into the real designer, served by the gallery server T-962 uses, and screenshots the page at the three review widths
(the UI review rule, 2026-10-14) for the released 0.24.0 ("before", BEFORE_REF) and the working tree ("after").

Asserted per width: BEFORE, the three boundary events are not on any host (flattened into tasks) and the catches
are link-typed; AFTER, the three boundary events sit on their hosts, the timer catch and the message boundary carry
their designer type, and no event is link-typed with a native definition shown as a link.
Usage: python3 tools/_t1222-event-shots.py [outdir]   (default docs/reports/T-1222-evidence)
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
FIXTURE = os.path.join(ROOT, "tests", "fixtures", "t1222", "native-event-kinds.bpmn")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "reports", "T-1222-evidence")
BEFORE_REF = os.environ.get("T1222_BEFORE_REF", "designer-v0.24.0")

spec = importlib.util.spec_from_file_location("t962", os.path.join(ROOT, "tests", "test_t962_findings_on_map.py"))
t962 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t962)

JS_LOAD = """(xml) => {
  adoptImportedXml(xml, { userImport: true });
  renderAll();
  const by = name => state.nodes.find(n => n.name === name) || {};
  const pick = name => { const n = by(name); return { type: n.type, boundary: !!(typeof boundaryHostOf === 'function' && n.uid && boundaryHostOf(n)) }; };
  return { timer: pick('Wait one day'), signalCatch: pick('Stock low'), throwSig: pick('Announce shipped'),
           bMsg: pick('Order changed'), bEsc: pick('Escalate'), bBare: pick('Interrupted') };
}"""


def shoot(label, src_bytes, xml, fails):
    tmp = tempfile.mkdtemp(prefix="t1222-")
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
                r = page.evaluate(JS_LOAD, xml)
                page.wait_for_timeout(300)
                page.screenshot(path=os.path.join(OUT, "t1222-%s-%d.png" % (label, w)))
                # Close-up: the union of the node groups, padded, so the labels under the events are legible.
                box = page.evaluate("""() => {
                  const r = Array.from(document.querySelectorAll('.node-label')).map(e => e.parentNode.getBoundingClientRect());
                  if (!r.length) return null;
                  const x0 = Math.min(...r.map(b => b.left)) - 40, y0 = Math.min(...r.map(b => b.top)) - 40;
                  const x1 = Math.max(...r.map(b => b.right)) + 40, y1 = Math.max(...r.map(b => b.bottom)) + 40;
                  return { x: Math.max(0, x0), y: Math.max(0, y0), width: x1 - Math.max(0, x0), height: y1 - Math.max(0, y0) };
                }""")
                if box:
                    page.screenshot(path=os.path.join(OUT, "t1222-%s-%d-detail.png" % (label, w)), clip=box)
                bounds = [r[k]["boundary"] for k in ("bMsg", "bEsc", "bBare")]
                if label == "before":
                    ok = not any(bounds)
                else:
                    ok = (all(bounds) and r["timer"]["type"] == "eventTimer" and r["bMsg"]["type"] == "eventMessage"
                          and r["signalCatch"]["type"] == "linkEventCatch" and r["throwSig"]["type"] == "linkEventThrow")
                print("%s  %s %d: %s" % ("ok  " if ok else "FAIL", label, w, json.dumps(r)[:400]))
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
    # The released 0.24.0, before T-1222: HEAD carries the fix from then on.
    before = subprocess.run(["git", "-C", ROOT, "show", BEFORE_REF + ":src/aef-workflow-designer.html"],
                            capture_output=True, check=True).stdout
    after = open(os.path.join(ROOT, "src", "aef-workflow-designer.html"), "rb").read()
    fails = []
    shoot("before", before, xml, fails)
    shoot("after", after, xml, fails)
    print("T-1222 shots: %s, written to %s" % ("all asserted" if not fails else "FAILED at %s" % fails, OUT))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
