#!/usr/bin/env python3
"""test_t962_findings_on_map — validator findings reach the map (T-309 slice 3).

WHAT THIS GUARDS. T-961 gave the designer `validateCurrentWorkflow()`; T-962 shows its answer:
a marker on each offending node and a dock listing every finding. The operator's shape, in
their words — "a check that shows the errors and also makes it visibly in the flow so we can
remediate it".

THE PROPERTIES, each with a leg that can fail:

  1. THREE STATES ARE DISTINCT. `not yet checked`, `checked · no findings`, and `could not
     check` must never render as the same thing. T-961 made that true at the function boundary
     (no `findings` key at all when unavailable); it dies here if an unchecked map looks like a
     clean one, and then "looks clean" stops meaning anything.

  2. NOTHING IS DROPPED. The dock lists EVERY finding returned. Markers are a declared subset.
     A finding whose location does not resolve to a node must still appear as a row — losing it
     because it had nowhere to sit is the false green at this layer.

  3. IDS RESOLVE THE WAY THE VALIDATOR SPELLS THEM. The validator reads the EXPORTED document,
     so it reports `displayIdOf(n)`, not the internal `n.id`. The first implementation matched
     `n.id` and placed ZERO markers while the dock reported "3 findings, 0 on the map" — every
     row rendered perfectly and said "not on the map", a true statement about a wrong
     computation. No DOM assertion caught it; reading a screenshot did. Leg 5 is its guard.

  4. THE MARKER ALLOWLIST IS REAL. `W-XML-GW-AMBIGUOUS` fires on 47 of AEF's 48 live gateways
     and 0 of ours (T-325) — it reports which toolchain wrote the file. It is excluded from the
     canvas and NOT from the list. Leg 6 proves both halves, because an allowlist that also
     suppressed the row would be hiding findings rather than quieting them.

Chromium absence is an ENVIRONMENT skip surfaced LOUDLY, never a silent green (T-212).

Exit 0 iff every leg passes. Run: python3 tests/test_t962_findings_on_map.py
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
# T962_DESIGNER_SRC retargets the page under test. It exists for the TEETH and nothing else:
# pointed at a pre-change designer this file must REFUSE (rc=3) rather than pass. Same
# convention as T961_DESIGNER_SRC and T560_TASK_ROOT.
SRC = os.environ.get("T962_DESIGNER_SRC") or os.path.join(
    ROOT, "src", "aef-workflow-designer.html")
SERVER = os.path.join(ROOT, "tools", "gallery-serve.py")

results = []


def check(name, cond, detail=""):
    results.append((name, bool(cond)))
    print("%s %s%s" % ("PASS" if cond else "FAIL", name, (" — " + detail) if detail else ""))


def _chromium_present():
    cache = os.path.join(os.path.expanduser("~"), ".cache", "ms-playwright")
    return os.path.isdir(cache) and any(
        d.startswith("chromium") for d in os.listdir(cache))


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


JS_STATE = """() => ({
  line: document.getElementById('findings-state').textContent,
  stateAttr: document.getElementById('findings-state').getAttribute('data-state'),
  open: document.getElementById('findings-drawer').getAttribute('data-open'),
  rows: document.getElementById('findings-list').children.length,
  markers: document.querySelectorAll('[data-finding-badge]').length,
})"""

# One node pointed at a lane that does not exist: a real editor-side mistake (a lane deleted
# out from under a node) and the minimum difference from the clean document.
JS_DIRTY = """async () => {
  state.nodes[0].lane = 'lane-that-does-not-exist';
  renderAll();
  await runCheck();
  const res = await validateCurrentWorkflow();
  const marks = Array.from(document.querySelectorAll('[data-finding-badge]')).map(e => {
    const owner = e.closest('g[data-id]');
    const n = state.nodes.find(x => x.id === owner.getAttribute('data-id'));
    return { rule: e.getAttribute('data-finding-badge'), displayId: n ? displayIdOf(n) : null };
  });
  return {
    line: document.getElementById('findings-state').textContent,
    rows: document.getElementById('findings-list').children.length,
    markers: marks,
    totalFromApi: res.ok ? res.findings.length : -1,
    // The ids the VALIDATOR used, to compare against the ids the MARKERS resolved to.
    apiLocations: res.ok ? res.findings.map(f => (/'([^']+)'/.exec(f.location) || [])[1]) : [],
  };
}"""

# T-964 REGRESSION. Move a node clear of every lane band. The designer does NOT orphan it —
# `if (newLane) n.lane = newLane` keeps the last valid lane — so this is not
# E-XML-NODE-UNASSIGNED; it is W-XML-LANE-CAPACITY, the lane can no longer contain its own
# member. That rule is the picture-disagrees-with-the-file class this whole feature exists
# for, and the original ALLOWLIST silently omitted it: a row in the dock and no marker on the
# map, with nothing to say so. The leg demands the MARKER, not merely the finding.
JS_LANE_OVERFLOW = """async () => {
  const n = state.nodes[0];
  let bottom = POOL_Y + POOL_HEADER;
  for (const l of getLanes()) bottom += l.height;
  n.y = bottom + 400;
  const centerY = n.y + NODE_DEFAULTS[n.type].h / 2;
  const newLane = laneAtY(centerY);
  if (newLane) n.lane = newLane;          // exactly what the drag handler does
  renderAll();
  await runCheck();
  const marked = Array.from(document.querySelectorAll('[data-finding-badge]'))
    .map(e => e.getAttribute('data-finding-badge'));
  const rows = Array.from(document.querySelectorAll('.finding-row'))
    .map(r => r.getAttribute('data-rule'));
  return {
    laneKept: !!findLane(n.lane),
    laneAtYWasNull: newLane === null,
    rows, marked,
    capacityListed: rows.filter(r => r === 'W-XML-LANE-CAPACITY').length,
    capacityMarked: marked.filter(r => r === 'W-XML-LANE-CAPACITY').length,
    unanchoredRows: document.querySelectorAll('.finding-row[data-anchored="0"]').length,
  };
}"""

# Clear every condition on one exclusive gateway's outgoing edges. buildBpmnXml emits
# <bpmn:conditionExpression> only when e.condition is set, so this produces exactly the
# ambiguity W-XML-GW-AMBIGUOUS reports — the 47-of-48 rule.
JS_AMBIGUOUS = """async () => {
  const gw = state.nodes.find(n => n.type === 'exclusiveGateway');
  if (!gw) return { skipped: 'no exclusiveGateway in the seed map' };
  const outs = state.edges.filter(e => e.source === gw.id);
  if (outs.length < 2) return { skipped: 'gateway has fewer than 2 outgoing edges' };
  for (const e of outs) e.condition = '';
  renderAll();
  await runCheck();
  const rows = Array.from(document.querySelectorAll('.finding-row'))
    .map(r => r.getAttribute('data-rule'));
  const marked = Array.from(document.querySelectorAll('[data-finding-badge]'))
    .map(e => e.getAttribute('data-finding-badge'));
  return {
    ambiguousInList: rows.filter(r => r === 'W-XML-GW-AMBIGUOUS').length,
    ambiguousMarked: marked.filter(r => r === 'W-XML-GW-AMBIGUOUS').length,
    rows: rows.length,
  };
}"""

JS_UNAVAILABLE = """async () => {
  const was = _apiAvailable;
  _apiAvailable = false;
  await runCheck();
  const out = {
    line: document.getElementById('findings-state').textContent,
    stateAttr: document.getElementById('findings-state').getAttribute('data-state'),
    rows: document.getElementById('findings-list').children.length,
    markers: document.querySelectorAll('[data-finding-badge]').length,
  };
  _apiAvailable = was;
  return out;
}"""


def main():
    if not os.path.isfile(SRC):
        print("COULD-NOT-MEASURE: %s missing" % SRC, file=sys.stderr)
        return 3
    src_text = open(SRC, encoding="utf-8").read()
    for needle, what in (("findings-drawer", "the findings dock"),
                         ("FINDING_MARKER_EXCLUDED", "the marker denylist"),
                         ("data-finding-badge", "the node marker")):
        if needle not in src_text:
            print("COULD-NOT-MEASURE: %s is not in the designer (%s); this leg guards "
                  "something that does not exist" % (what, needle), file=sys.stderr)
            return 3
    try:
        from playwright.sync_api import sync_playwright
    except Exception as e:
        print("SKIP (ENVIRONMENT): playwright python not importable: %s" % e, file=sys.stderr)
        print("SKIP (ENVIRONMENT): this leg asserted NOTHING this run", file=sys.stderr)
        return 0
    if not _chromium_present():
        print("SKIP (ENVIRONMENT): no chromium under ~/.cache/ms-playwright", file=sys.stderr)
        print("SKIP (ENVIRONMENT): this leg asserted NOTHING this run", file=sys.stderr)
        return 0

    tmp = tempfile.mkdtemp(prefix="t962-")
    docroot = os.path.join(tmp, "docroot")
    os.makedirs(docroot, exist_ok=True)
    served = os.path.join(docroot, "designer.html")
    shutil.copy2(SRC, served)
    check("the served page is byte-identical to the designer under test",
          filecmp.cmp(SRC, served, shallow=False))

    proc, port = start_server(docroot)
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page(viewport={"width": 1600, "height": 1000})
            page.goto("http://127.0.0.1:%d/designer.html" % port)
            page.wait_for_function("() => typeof _apiAvailable !== 'undefined' && _apiAvailable === true",
                                   timeout=15000)

            # --- leg 2: before any check, the state is UNCHECKED, not clean ----------
            s0 = page.evaluate(JS_STATE)
            check("before any check: state is 'unchecked' and the dock is closed",
                  s0["stateAttr"] == "unchecked" and s0["open"] == "0"
                  and s0["markers"] == 0,
                  json.dumps(s0))

            # --- leg 3: a clean map says so IN WORDS, distinct from unchecked --------
            page.evaluate("async () => { await runCheck(); }")
            s1 = page.evaluate(JS_STATE)
            check("clean map: state becomes 'clean' with a distinct line, 0 markers",
                  s1["stateAttr"] == "clean" and s1["rows"] == 0 and s1["markers"] == 0
                  and s1["line"] != s0["line"],
                  json.dumps(s1))

            # --- leg 4/5: a real defect marks the node, by the EXPORTED id -----------
            d = page.evaluate(JS_DIRTY)
            check("one node in no lane: findings appear and at least one marker is drawn",
                  d["rows"] > 0 and len(d["markers"]) > 0,
                  "rows=%s markers=%s" % (d["rows"], len(d["markers"])))
            check("the dock lists EVERY finding the API returned (nothing dropped)",
                  d["rows"] == d["totalFromApi"],
                  "rows=%s api=%s" % (d["rows"], d["totalFromApi"]))
            # The regression guard. Each marker's node must carry the displayId the
            # validator named — matching on n.id placed zero markers and still looked fine.
            marked_display = sorted(m["displayId"] for m in d["markers"])
            check("each marker sits on the node whose EXPORTED id the validator named "
                  "(the displayIdOf regression)",
                  len(marked_display) > 0
                  and all(x in d["apiLocations"] for x in marked_display),
                  "marked=%s apiLocations=%s" % (marked_display, d["apiLocations"][:6]))

            # --- leg 6 (T-964): a node clear of every lane band is MARKED ------------
            # The regression this slice shipped without. The original allowlist omitted
            # W-XML-LANE-CAPACITY, so this produced a row and no marker, silently.
            page.reload()
            page.wait_for_function("() => typeof _apiAvailable !== 'undefined' && _apiAvailable === true",
                                   timeout=15000)
            lo = page.evaluate(JS_LANE_OVERFLOW)
            check("a node dragged clear of the lanes keeps its lane "
                  "(the designer refuses to orphan it)",
                  lo["laneKept"] is True and lo["laneAtYWasNull"] is True,
                  json.dumps({k: lo[k] for k in ("laneKept", "laneAtYWasNull")}))
            # CORRECTED FROM MY FIRST ATTEMPT, which demanded a MARKER here and failed.
            # W-XML-LANE-CAPACITY anchors to `lane '<id>'`, not to a node, so no node marker
            # is possible — the denylist inversion was necessary but could never be
            # sufficient for a lane-anchored rule. What must hold is that it is LISTED and
            # HONESTLY LABELLED as unanchored, rather than dropped for having nowhere to sit.
            # Lane markers are a separate gap (4 lane-anchored rules), filed, not faked here.
            check("lane-anchored findings are LISTED and flagged as not-on-the-map "
                  "(never dropped for having no node to sit on)",
                  lo["capacityListed"] > 0 and lo["capacityMarked"] == 0
                  and lo["unanchoredRows"] >= lo["capacityListed"],
                  "listed=%s marked=%s unanchored=%s rows=%s"
                  % (lo["capacityListed"], lo["capacityMarked"],
                     lo["unanchoredRows"], lo["rows"]))

            # --- leg 7: the denylist quiets the canvas WITHOUT hiding the row --------
            a = page.evaluate(JS_AMBIGUOUS)
            if a.get("skipped"):
                check("allowlist leg could run against the seed map", False, a["skipped"])
            else:
                check("W-XML-GW-AMBIGUOUS is LISTED (not hidden)",
                      a["ambiguousInList"] > 0, json.dumps(a))
                check("W-XML-GW-AMBIGUOUS draws NO marker (the 47-of-48 rule is off-canvas)",
                      a["ambiguousMarked"] == 0, json.dumps(a))

            # --- leg 7: unavailable is its own state, and clears the markers ---------
            u = page.evaluate(JS_UNAVAILABLE)
            check("validator unavailable: state is 'unavailable', 0 rows, 0 markers "
                  "(never rendered as a clean map)",
                  u["stateAttr"] == "unavailable" and u["rows"] == 0 and u["markers"] == 0,
                  json.dumps(u))

            browser.close()
    finally:
        if proc.poll() is None:
            proc.terminate()
            proc.wait(timeout=10)
        shutil.rmtree(tmp, ignore_errors=True)

    passed = sum(1 for _, ok in results if ok)
    failed = len(results) - passed
    print()
    print("findings on the map: %d passed, %d failed" % (passed, failed))
    if failed:
        print("findings on the map: FAILED")
        return 1
    print("OK: findings reach the map, the three states stay distinct, and the allowlist "
          "quiets the canvas without hiding a row")
    return 0


if __name__ == "__main__":
    sys.exit(main())
