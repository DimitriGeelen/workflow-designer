#!/usr/bin/env python3
"""T-1212 — the exclusive-gateway arity finding shows as a WARNING in the designer's Check, at three widths.

The validator change (E-GW-OUTGOING -> W-GW-OUTGOING, E-XML-GW-OUTGOING -> W-XML-GW-OUTGOING) is visible: the
designer's Check counts findings by severity and the dock lists them. This loads the warn fixture
(tests/fixtures/warn/W-XML-GW-OUTGOING.xml: a 1-in/1-out exclusive gateway) into the real designer, served by the
same gallery server T-962 uses (so /api/validate is the real validator), presses Check, asserts the dock lists
W-XML-GW-OUTGOING and no ERROR, and screenshots the page at 1024, 1440 and 1920 (the UI review rule, 2026-10-14).

  python3 tools/_t1212-gw-warning-shots.py [OUT_DIR]     default OUT_DIR: docs/reports/T-1212-evidence
Exit 0 = asserted and shot; 1 = an assertion failed; 3 = could not measure.
"""
import importlib.util
import json
import os
import shutil
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURE = os.path.join(ROOT, "tests", "fixtures", "warn", "W-XML-GW-OUTGOING.xml")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "docs", "reports", "T-1212-evidence")

spec = importlib.util.spec_from_file_location("t962", os.path.join(ROOT, "tests", "test_t962_findings_on_map.py"))
t962 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t962)

JS_LOAD_CHECK = """async (xml) => {
  adoptImportedXml(xml, { userImport: true });
  renderAll();
  await runCheck();
  const res = await validateCurrentWorkflow();
  const drawer = document.getElementById('findings-drawer');
  if (drawer) drawer.setAttribute('data-open', '1');
  return {
    ok: res.ok,
    rules: res.ok ? res.findings.map(f => f.rule) : [],
    severities: res.ok ? res.findings.map(f => f.rule + ':' + f.severity) : [],
    line: document.getElementById('findings-state').textContent,
    stateAttr: document.getElementById('findings-state').getAttribute('data-state'),
    rows: Array.from(document.getElementById('findings-list').children).map(e => e.textContent.trim().slice(0, 120)),
  };
}"""


def main():
    if not os.path.isfile(FIXTURE):
        print("COULD-NOT-MEASURE: fixture missing: %s" % FIXTURE)
        return 3
    try:
        from playwright.sync_api import sync_playwright
    except Exception as e:
        print("COULD-NOT-MEASURE: playwright not importable: %s" % e)
        return 3
    xml = open(FIXTURE, encoding="utf-8").read()
    tmp = tempfile.mkdtemp(prefix="t1212-")
    docroot = os.path.join(tmp, "docroot")
    os.makedirs(docroot)
    shutil.copy2(t962.SRC, os.path.join(docroot, "designer.html"))
    os.makedirs(OUT, exist_ok=True)
    proc, port = t962.start_server(docroot)
    fails = []
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            for w, h in ((1024, 768), (1440, 900), (1920, 1080)):
                page = browser.new_page(viewport={"width": w, "height": h})
                page.goto("http://127.0.0.1:%d/designer.html" % port)
                page.wait_for_function("() => typeof _apiAvailable !== 'undefined' && _apiAvailable === true",
                                       timeout=int(os.environ.get("CDP_READY_MS", "20000")))
                r = page.evaluate(JS_LOAD_CHECK, xml)
                page.wait_for_timeout(300)
                page.screenshot(path=os.path.join(OUT, "t1212-check-%d.png" % w))
                ok = (r["ok"] and "W-XML-GW-OUTGOING" in r["rules"]
                      and "E-XML-GW-OUTGOING" not in r["rules"]
                      and not any(s.endswith(":ERROR") for s in r["severities"]))
                print("%s  %d: %s" % ("ok  " if ok else "FAIL", w, json.dumps(r)[:600]))
                if not ok:
                    fails.append(w)
                page.close()
            browser.close()
    finally:
        proc.terminate()
        shutil.rmtree(tmp, ignore_errors=True)
    print("T-1212 shots: %s, written to %s" % ("all asserted" if not fails else "FAILED at %s" % fails, OUT))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
