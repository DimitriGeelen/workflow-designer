#!/usr/bin/env python3
"""T-612 — is the operator's T-589 review actually reachable, and is it the RIGHT build?

The deliverable of T-612 is not a file on disk. It is a URL the operator can open and act
on. So this verifier fetches, and it fails when the server is down — that is correct, not a
fragility: if nothing is serving, the operator has nothing to review.

WHY IDENTITY AND NOT HTTP 200 (PL-198). The failure this guards is specific and silent.
`dist/aef-workflow-designer-0.11.0.html` and `src/aef-workflow-designer.html` both serve,
both render a designer, both return 200. Only one has the fields under review. An operator
handed the pinned release would select a node, find no "Fabric component" row, and correctly
conclude the feature does not work — closing a `[REVIEW]` criterion against a build that
never contained the change. So the check is a byte comparison against `src/` AND a proof of
difference from the released artifact. Either one alone is satisfiable by the wrong page.

WHY THE MAP IS PARSED AND NOT COUNTED BY FILENAME. `fabricRef` and `links` are offered on
four task-like node types only; T-589's `gateway-not-offered` leg is a passing leg. A map of
pure gateways and events would serve, load, and offer the operator nothing to click. The
served bytes are parsed for the four types.

Exit 0 = the operator can do the review. 1 = they cannot. 2 = cannot measure (NOT a pass).
"""
import hashlib
import re
import sys
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PORT_FILE = Path("/tmp/claude-0/-opt-832-Workflow-designer/"
                 "500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/t611.port")
HOST = "192.168.10.107"
MAP = "harvest-pipeline.bpmn"
TASK_LIKE = ("serviceTask", "scriptTask", "subProcess", "userTask")


def fetch(url):
    with urllib.request.urlopen(url, timeout=15) as r:
        return r.read(), r.status


def main():
    if not PORT_FILE.exists():
        print(f"CANNOT MEASURE: no port file at {PORT_FILE} — the review server was never "
              f"started, or its record is gone")
        return 2
    port = PORT_FILE.read_text().strip().split("=")[-1]

    src = REPO / "src" / "aef-workflow-designer.html"
    released = REPO / "dist" / "aef-workflow-designer-0.11.0.html"
    if not src.exists():
        print("CANNOT MEASURE: src/aef-workflow-designer.html missing")
        return 2

    base = f"http://{HOST}:{port}"
    try:
        page, code = fetch(f"{base}/designer.html")
        raw_map, map_code = fetch(f"{base}/{MAP}")
    except Exception as exc:
        print(f"FAIL: {base} unreachable — {exc}")
        print("  The operator has no page to review. This is the deliverable, not a flake.")
        return 1

    src_bytes = src.read_bytes()
    is_src = page == src_bytes
    # Prove it is NOT the pinned release. If dist/ is absent we cannot make that claim and
    # must say so rather than let the leg pass on a missing file.
    if not released.exists():
        print("CANNOT MEASURE: dist/aef-workflow-designer-0.11.0.html absent — cannot prove "
              "the served page is not the pinned release, and that is the whole risk")
        return 2
    is_release = page == released.read_bytes()

    text = raw_map.decode("utf-8", "replace")
    counts = {k: len(re.findall(r"<bpmn2?:?" + k + r"\b", text)) for k in TASK_LIKE}
    tasklike = sum(counts.values())

    sha = lambda b: hashlib.sha256(b).hexdigest()[:12]
    print("T-612 — operator review reachability")
    print(f"  url          {base}/designer.html   (HTTP {code}, {len(page)} bytes, sha {sha(page)})")
    print(f"  map          {base}/{MAP}   (HTTP {map_code}, {len(raw_map)} bytes)")
    print(f"  identity     == src/ : {is_src}   == dist/0.11.0 : {is_release}")
    print(f"  task-like    {counts}  total={tasklike}")

    ok = is_src and not is_release and tasklike > 0
    if not ok:
        print()
        if not is_src:
            print("  FAIL: the served page is not the src build under review.")
        if is_release:
            print("  FAIL: the served page IS the pinned 0.11.0 release — it does not contain")
            print("        the fields the operator is being asked to review. They would find")
            print("        no 'Fabric component' row and correctly conclude it does not work.")
        if tasklike == 0:
            print(f"  FAIL: {MAP} carries no task-like node, so no node in it offers the")
            print("        fields. The operator would have nothing to click.")
    else:
        print("  OK — the operator can open the page, load the map, and select a node that "
              "offers both fields.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
