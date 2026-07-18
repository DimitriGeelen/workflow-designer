#!/usr/bin/env python3
"""T-197 (IW-9 v1.1): src-served render guard — the node-level `owner` override
is RETIRED from the editor authoring surface and shown read-only, derived from
the node's lane authority.

Sibling of ``tests/test_designer_render.py``, which guards the *released dist*
build (resolves VERSION → dist/…-<version>.html) and is a release gate. That
test legitimately still asserts owner renders for the released 0.2.0 bytes,
which shipped before IW-9 graduated; its owner-expectations flip atomically
with the release that rebuilds dist (a VERSION bump). This guard instead points
at ``src/aef-workflow-designer.html`` so the retire is verifiable NOW, decoupled
from any release.

What it asserts against ``src/aef-workflow-designer.html`` (served headless):
  1. FIELD RETIRED   — in-page ``AEF_FIELDS.serviceTask`` (and userTask/
                       scriptTask/subProcess) do NOT contain ``owner``.
  2. NO EDITABLE SELECT — selecting a serviceTask node renders NO ``<select>``
                       whose option-set is the owner signature ["","human",
                       "agent"] (distinct from Lane / decisionOwner / agentType).
  3. DERIVED READOUT — the inspector shows a read-only Owner readout whose value
                       matches the lane→owner collapse (sovereignty→human,
                       initiative/authority→agent) for the selected node's lane.
  4. CONSOLE         — no console errors except the whitelisted backend-absent
                       probes (/api/health, /favicon.ico).

Run (exits 0 on pass, non-zero on failure):
    python3 tests/test_designer_owner_derived.py
"""
import functools
import http.server
import socketserver
import sys
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT / "src"
SRC_FILE = "aef-workflow-designer.html"

CONSOLE_WHITELIST = ("/api/health", "/favicon.ico")

# The retired owner field's option signature (order-sensitive). If any <select>
# in the inspector still carries this exact set, the editable dropdown survived.
OWNER_SIG = ["", "human", "agent"]

# Node types that lost the owner field (must be absent from AEF_FIELDS).
OWNER_BEARING = ("serviceTask", "userTask", "scriptTask", "subProcess")


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

            # (1) FIELD RETIRED ------------------------------------------------
            fields = page.evaluate(
                """(types) => {
                    if (typeof AEF_FIELDS === 'undefined') return null;
                    const out = {};
                    for (const t of types) out[t] = AEF_FIELDS[t] || [];
                    return out;
                }""",
                list(OWNER_BEARING),
            )
            if fields is None:
                failures.append("AEF_FIELDS undefined — stale/broken build?")
            else:
                for t in OWNER_BEARING:
                    if "owner" in fields.get(t, []):
                        failures.append(f"AEF_FIELDS.{t} still contains 'owner' (not retired)")

            # (2)+(3) select a serviceTask node; check no owner <select>, derived readout
            result = page.evaluate(
                """(ownerSig) => {
                    const node = Array.from(document.querySelectorAll('svg g.node'))
                        .find(n => /Decompose/.test(n.textContent || ''));
                    if (!node) return { ok: false, reason: 'seed serviceTask (Decompose) not found' };
                    const r = node.getBoundingClientRect();
                    const opts = { bubbles: true, cancelable: true,
                                   clientX: r.x + r.width / 2, clientY: r.y + r.height / 2, view: window };
                    for (const t of ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'])
                        node.dispatchEvent(new (t.startsWith('pointer') ? PointerEvent : MouseEvent)(t, opts));
                    const selects = Array.from(document.querySelectorAll('select'))
                        .map(s => Array.from(s.options).map(o => o.value));
                    const eq = (a, b) => a.length === b.length && a.every((v, i) => v === b[i]);
                    const ownerSelectSurvives = selects.some(x => eq(x, ownerSig));
                    // Derived readout: a .field whose label text starts with "Owner"
                    // and which is NOT a <select> (read-only div value).
                    let readoutText = null, readoutHasSelect = null;
                    for (const fld of document.querySelectorAll('.field')) {
                        const lbl = fld.querySelector('.field-label');
                        if (lbl && (lbl.textContent || '').trim().startsWith('Owner')) {
                            const val = fld.querySelector('.field-input');
                            readoutText = val ? (val.textContent || '').trim() : '';
                            readoutHasSelect = !!fld.querySelector('select');
                            break;
                        }
                    }
                    return { ok: true, ownerSelectSurvives, readoutText, readoutHasSelect };
                }""",
                OWNER_SIG,
            )
            if not result.get("ok"):
                failures.append("selection: " + result.get("reason", "node selection failed"))
            else:
                if result["ownerSelectSurvives"]:
                    failures.append("an editable owner <select> [\"\",\"human\",\"agent\"] still renders")
                if result["readoutText"] is None:
                    failures.append("no read-only Owner readout found in inspector")
                else:
                    # seed 'Decompose' lives in the agent lane (initiative) → 'agent'
                    if result["readoutHasSelect"]:
                        failures.append("Owner readout is still a <select>, not read-only")
                    if result["readoutText"] != "agent":
                        failures.append(
                            f"derived Owner readout = {result['readoutText']!r}, expected 'agent' "
                            f"(Decompose is in the initiative/agent lane)"
                        )

            # (4) CONSOLE ------------------------------------------------------
            unexpected = [e for e in console_errors
                          if not any(w in e for w in CONSOLE_WHITELIST)]
            if unexpected:
                failures.append("unexpected console errors: " + "; ".join(unexpected))

            browser.close()
    finally:
        httpd.shutdown()

    if failures:
        print(f"FAIL: designer owner-derived guard — {len(failures)} issue(s):", file=sys.stderr)
        for f in failures:
            print("  - " + f, file=sys.stderr)
        sys.exit(1)

    print("PASS: designer owner-derived guard — owner retired from AEF_FIELDS, "
          "no editable owner dropdown, read-only derived readout present, console OK")


if __name__ == "__main__":
    main()
