#!/usr/bin/env python3
"""T-202 (arc: designer-authoring-surface, post-GO on T-201 write-out): src-served
guard that the designer's ``.bpmn`` EXPORT carries the write-out *content contract*
that AEF's ``fw bpmn promote`` → ``fw task create`` (T-2541) consumes.

The write-out seam resolved to **manifest-as-seam** (T-201 §3a): 832 owns the
content, AEF owns the gated write. AEF's promote derives each emitted task's
``owner`` from lane authority (IW-9 collapse map) and stamps ``aef_provenance``
(``uid`` + source ``.bpmn``). Both of those reads come from 832's export. So the
export must never hand promote an owner-bearing node it cannot **identify**
(no ``aef:uid``) or **lane** (no defined lane authority) — either is a gap that
would make owner-derivation or provenance stamping impossible downstream.

This guard proves 832's side of that contract, independent of AEF's promote
(which is why it is buildable now; the end-to-end compile→promote→task test waits
on T-2541). It asserts, against the live ``buildBpmnXml(state)`` export of the
seed workflow served from ``src/aef-workflow-designer.html``:

  1. UID PRESENT  — every owner-bearing node (serviceTask/userTask/scriptTask/
                    subProcess) carries a non-empty ``<aef:uid value="…"/>``.
  2. LANE DEFINED — every owner-bearing node is referenced by exactly one lane
                    whose ``<aef:laneMeta authority="…"/>`` is one of the five
                    defined authorities (sovereignty/authority/initiative/
                    external/none) — so IW-9 owner-derivation never resolves
                    against an absent/undefined lane.
  3. GATE HAS TEETH — the same audit, run over a mutated export with a uid
                    stripped (and again with a lane authority blanked), MUST
                    report violations. This proves (1)/(2) are real assertions,
                    not tautologies that pass on anything.
  4. CONSOLE      — no console errors except the whitelisted backend-absent
                    probes (/api/health, /favicon.ico).

Sibling of ``tests/test_designer_owner_derived.py`` (same src-served Playwright
harness). Distinct from ``tests/test_designer_render.py`` (the released-dist gate).

Run (exits 0 on pass, non-zero on failure):
    python3 tests/test_designer_export_contract.py
"""
import functools
import http.server
import socketserver
import sys
import threading
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT / "src"
SRC_FILE = "aef-workflow-designer.html"

CONSOLE_WHITELIST = ("/api/health", "/favicon.ico")

NS = {
    "bpmn": "http://www.omg.org/spec/BPMN/20100524/MODEL",
    "aef": "http://anchorpoint.framework/aef/extensions",
}
BPMN = NS["bpmn"]
AEF = NS["aef"]

# Node types whose emitted task gets a derived owner + provenance downstream.
OWNER_BEARING = ("serviceTask", "userTask", "scriptTask", "subProcess")
# The five lane authorities IW-9 collapses to owner. Anything else (incl. "" or
# a missing laneMeta) is an undefined lane and a contract gap.
AUTHORITIES = {"sovereignty", "authority", "initiative", "external", "none"}


def audit(xml_text):
    """Return a list of contract-violation strings for a .bpmn export. Empty ⇒ clean.

    Pure function of the XML string so it can be re-run over mutated copies to
    prove the assertions have teeth (AC-3).
    """
    violations = []
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError as exc:
        return [f"export is not well-formed XML: {exc}"]

    # lane id -> authority, and node displayId -> set(lane ids referencing it)
    lane_authority = {}
    node_to_lanes = {}
    for lane in root.iter(f"{{{BPMN}}}lane"):
        lane_id = lane.get("id") or "(unnamed-lane)"
        meta = lane.find(f".//{{{AEF}}}laneMeta")
        # A missing laneMeta or a missing/blank authority attr ⇒ authority None.
        lane_authority[lane_id] = meta.get("authority") if meta is not None else None
        for ref in lane.findall(f"{{{BPMN}}}flowNodeRef"):
            nid = (ref.text or "").strip()
            if nid:
                node_to_lanes.setdefault(nid, set()).add(lane_id)

    # every owner-bearing node element
    found_any = False
    for local in OWNER_BEARING:
        for node in root.iter(f"{{{BPMN}}}{local}"):
            found_any = True
            nid = node.get("id") or "(unnamed)"
            label = f"{local} '{node.get('name') or nid}'"

            # (1) uid present + non-empty
            uid_el = node.find(f".//{{{AEF}}}uid")
            uid = uid_el.get("value") if uid_el is not None else None
            if not (uid and uid.strip()):
                violations.append(f"{label}: missing/empty <aef:uid>")

            # (2) referenced by exactly one lane with a defined authority
            lanes = node_to_lanes.get(nid, set())
            if not lanes:
                violations.append(f"{label}: not referenced by any lane (owner can't be derived)")
            elif len(lanes) > 1:
                violations.append(f"{label}: referenced by multiple lanes {sorted(lanes)} (ambiguous owner)")
            else:
                (lane_id,) = tuple(lanes)
                auth = lane_authority.get(lane_id)
                if auth not in AUTHORITIES:
                    violations.append(
                        f"{label}: lane '{lane_id}' authority={auth!r} is not a defined "
                        f"authority {sorted(AUTHORITIES)}"
                    )

    if not found_any:
        violations.append("no owner-bearing nodes in export — seed workflow empty/broken?")
    return violations


# ── mutators for the teeth check (AC-3) ──────────────────────────────────────
def _strip_first_uid(xml_text):
    """Remove the first owner-bearing node's <aef:uid …/> line."""
    root = ET.fromstring(xml_text)
    for local in OWNER_BEARING:
        for node in root.iter(f"{{{BPMN}}}{local}"):
            ext = node.find(f"{{{BPMN}}}extensionElements")
            uid_el = ext.find(f"{{{AEF}}}uid") if ext is not None else None
            if uid_el is not None:
                ext.remove(uid_el)
                return ET.tostring(root, encoding="unicode")
    return None  # nothing to strip


def _blank_first_lane_authority(xml_text):
    """Blank the authority of the first lane that references an owner-bearing node."""
    root = ET.fromstring(xml_text)
    owner_ids = {
        n.get("id")
        for local in OWNER_BEARING
        for n in root.iter(f"{{{BPMN}}}{local}")
    }
    for lane in root.iter(f"{{{BPMN}}}lane"):
        refs = {(r.text or "").strip() for r in lane.findall(f"{{{BPMN}}}flowNodeRef")}
        if refs & owner_ids:
            meta = lane.find(f".//{{{AEF}}}laneMeta")
            if meta is not None:
                meta.set("authority", "")  # undefined authority
                return ET.tostring(root, encoding="unicode")
    return None


class _QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def _serve(directory):
    handler = functools.partial(_QuietHandler, directory=str(directory))
    socketserver.ThreadingTCPServer.allow_reuse_address = True
    httpd = socketserver.ThreadingTCPServer(("127.0.0.1", 0), handler)
    httpd.daemon_threads = True
    port = httpd.server_address[1]
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd, port


def main():
    if not (SRC_DIR / SRC_FILE).exists():
        raise SystemExit(f"FAIL: source not found: {SRC_DIR / SRC_FILE}")

    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        raise SystemExit(
            "FAIL: python-playwright not installed.\n"
            "      dev setup: pip install playwright && playwright install chromium"
        )

    httpd, port = _serve(SRC_DIR)
    url = f"http://127.0.0.1:{port}/{SRC_FILE}"

    failures = []
    console_errors = []

    def _on_console(msg):
        if msg.type == "error":
            loc = msg.location.get("url", "") if msg.location else ""
            console_errors.append(f"{msg.text} @ {loc}")

    try:
        with sync_playwright() as p:
            try:
                browser = p.chromium.launch(headless=True)
            except Exception as exc:
                raise SystemExit(
                    f"FAIL: could not launch chromium ({exc}).\n"
                    f"      dev setup: playwright install chromium"
                )
            page = browser.new_page()
            page.on("console", _on_console)
            page.on("pageerror", lambda e: failures.append(f"uncaught JS exception: {e}"))

            page.goto(url, wait_until="load")
            page.wait_for_selector("svg g.node", timeout=10_000)

            # Live export of the seed workflow via the in-page serializer.
            xml_text = page.evaluate(
                "() => (typeof buildBpmnXml === 'function' && state) "
                "? buildBpmnXml(state) : null"
            )
            browser.close()
    finally:
        httpd.shutdown()

    if not xml_text:
        print("FAIL: could not obtain buildBpmnXml(state) export from the page", file=sys.stderr)
        sys.exit(1)

    # (1)+(2) the real export must be clean
    export_violations = audit(xml_text)
    for v in export_violations:
        failures.append("export contract: " + v)

    # (3) gate-has-teeth: mutated exports MUST produce violations
    stripped = _strip_first_uid(xml_text)
    if stripped is None:
        failures.append("teeth: no uid to strip — cannot prove uid assertion has teeth")
    elif not any("aef:uid" in v for v in audit(stripped)):
        failures.append("teeth: stripping a uid did NOT trip the guard (uid check is a tautology)")

    blanked = _blank_first_lane_authority(xml_text)
    if blanked is None:
        failures.append("teeth: no owner-bearing lane to blank — cannot prove authority assertion has teeth")
    elif not any("authority" in v for v in audit(blanked)):
        failures.append("teeth: blanking a lane authority did NOT trip the guard (authority check is a tautology)")

    # (4) console
    unexpected = [e for e in console_errors if not any(w in e for w in CONSOLE_WHITELIST)]
    if unexpected:
        failures.append("unexpected console errors: " + "; ".join(unexpected))

    if failures:
        print(f"FAIL: designer export-contract guard — {len(failures)} issue(s):", file=sys.stderr)
        for f in failures:
            print("  - " + f, file=sys.stderr)
        sys.exit(1)

    n_owner = sum(xml_text.count(f"<bpmn:{t} ") for t in OWNER_BEARING)
    print(f"PASS: designer export-contract guard — {n_owner} owner-bearing node(s) each carry "
          "a non-empty aef:uid and a defined lane authority; uid/authority checks proven to have "
          "teeth; console OK")


if __name__ == "__main__":
    main()
