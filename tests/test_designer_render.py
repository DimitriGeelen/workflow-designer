#!/usr/bin/env python3
"""
T-179: Playwright render-check guarding test for the designer BUILD.

Complements ``tests/test_editor_bridge_meta_parity.py`` (STATIC parity check)
with a DYNAMIC render-check: serve the current ``dist/`` build via a local
static server (no backend — mirrors the AEF-served static condition at
``:3001/designer``), load it headless with python-playwright/chromium, and
assert render + feature-marker + clean console.

Why this exists (learning P-029, origin T-177/T-178):
``curl`` + sha256 proves the served *bytes* match the pinned manifest, but NOT
that the build actually *renders*, nor that the governance dropdowns appear. A
stale/wrong build, a JS exception, or a lost inspector field all pass a byte
check and fail here. This is the deployment-verification half a byte-check
cannot cover.

What it asserts against ``dist/aef-workflow-designer-<VERSION>.html``:
  1. RENDER          — page loads with no uncaught JS exception; palette
                       (Service/User/Script Task, Sub-process) + canvas nodes
                       present; <title> contains "Workflow Designer".
  2. FEATURE MARKER  — in-page ``FIELD_META.horizon`` truthy AND
                       ``AEF_FIELDS.serviceTask`` contains horizon/workflowType.
                       FAILS on any pre-T-177 build (stale-build guard). Owner is
                       retired from AEF_FIELDS as of IW-9/T-197 (derived, not a field).
  3. RENDERED DOM    — selecting a serviceTask node renders the two editable
                       governance <select>s (Horizon / Workflow type) with their
                       exact option sets. Owner is now a read-only derived readout
                       (IW-9/T-197), guarded by tests/test_designer_owner_derived.py.
  4. CONSOLE         — no console errors EXCEPT the whitelisted, documented
                       backend-absent probes (/api/health, /favicon.ico). The
                       source is NOT modified to suppress them.

Dev setup (one-time; already present in this environment):
    pip install playwright
    playwright install chromium

Run (exits 0 on pass, non-zero on failure):
    python3 tests/test_designer_render.py
"""
import functools
import http.server
import socketserver
import sys
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"

# Console errors we intentionally tolerate. The designer probes a backend that
# is absent when served as a static file (same condition as :3001/designer).
# Documented, non-fatal (T-178). Scoped to EXACTLY these two per spec. As of
# T-176 the web fonts are embedded (base64 woff2) — there is NO CDN font request
# in 0.3.0+, so a font/CDN error can no longer occur (nor is it whitelisted).
CONSOLE_WHITELIST = ("/api/health", "/favicon.ico")

# Expected governance dropdown option-sets (order-sensitive signatures).
# Matched by signature rather than by DOM position so the assertion is robust
# to inspector markup changes. Owner was an editable T-177 <select> but is
# RETIRED as of IW-9/T-197 — it is now a read-only readout derived from lane
# authority, so it is deliberately NOT asserted here (the derived readout is
# guarded separately by tests/test_designer_owner_derived.py).
SIG = {
    "horizon": ["", "now", "next", "later"],
    "workflowType": ["", "build", "test", "refactor", "decommission",
                     "specification", "design", "inception"],
}


class _QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):  # silence per-request stderr noise
        pass


def _resolve_build():
    version = (ROOT / "VERSION").read_text().strip()
    artifact = DIST / f"aef-workflow-designer-{version}.html"
    if not artifact.exists():
        raise SystemExit(
            f"FAIL: build artifact not found: {artifact}\n"
            f"      run scripts/release-designer.sh to produce it."
        )
    return version, artifact


def _serve(directory):
    handler = functools.partial(_QuietHandler, directory=str(directory))
    socketserver.ThreadingTCPServer.allow_reuse_address = True
    httpd = socketserver.ThreadingTCPServer(("127.0.0.1", 0), handler)
    httpd.daemon_threads = True
    port = httpd.server_address[1]
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd, port


def main():
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        raise SystemExit(
            "FAIL: python-playwright not installed.\n"
            "      dev setup: pip install playwright && playwright install chromium"
        )

    version, artifact = _resolve_build()
    httpd, port = _serve(DIST)
    url = f"http://127.0.0.1:{port}/{artifact.name}"

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
            except Exception as exc:  # missing/incompatible browser
                raise SystemExit(
                    f"FAIL: could not launch chromium ({exc}).\n"
                    f"      dev setup: playwright install chromium"
                )
            page = browser.new_page()
            page.on("console", _on_console)
            page.on("pageerror", lambda e: failures.append(f"uncaught JS exception: {e}"))

            page.goto(url, wait_until="load")
            page.wait_for_selector("svg g.node", timeout=10_000)

            # (1) RENDER --------------------------------------------------------
            title = page.title()
            if "Workflow Designer" not in title:
                failures.append(f"title missing 'Workflow Designer': {title!r}")
            palette = page.evaluate(
                """() => Array.from(document.querySelectorAll('*'))
                    .filter(e => e.children.length === 0 &&
                        /^(Service Task|User Task|Script Task|Sub-process)$/.test((e.textContent||'').trim()))
                    .map(e => e.textContent.trim())"""
            )
            for needed in ("Service Task", "User Task", "Script Task", "Sub-process"):
                if needed not in palette:
                    failures.append(f"palette missing '{needed}'")
            node_count = page.evaluate("() => document.querySelectorAll('svg g.node').length")
            if node_count < 1:
                failures.append(f"no canvas nodes rendered (svg g.node = {node_count})")

            # (2) FEATURE MARKER (stale-build guard) ---------------------------
            marker = page.evaluate(
                """() => ({
                    horizon: (typeof FIELD_META !== 'undefined') && !!FIELD_META.horizon,
                    fields: (typeof AEF_FIELDS !== 'undefined') ? AEF_FIELDS.serviceTask : null
                })"""
            )
            if not marker["horizon"]:
                failures.append("FIELD_META.horizon missing/falsey — stale (pre-T-177) build?")
            fields = marker["fields"] or []
            for f in ("horizon", "workflowType"):
                if f not in fields:
                    failures.append(
                        f"AEF_FIELDS.serviceTask missing '{f}' — stale build? (got {fields})"
                    )

            # (3) RENDERED DOM: select a serviceTask node, assert 3 dropdowns ---
            # Dispatches the real selection event sequence the canvas listens
            # for, then matches inspector <select>s by exact option-set.
            selected = page.evaluate(
                """(sigs) => {
                    const node = Array.from(document.querySelectorAll('svg g.node'))
                        .find(n => /Decompose/.test(n.textContent || ''));
                    if (!node) return { ok: false, reason: 'seed serviceTask (Decompose) not found' };
                    const r = node.getBoundingClientRect();
                    const opts = { bubbles: true, cancelable: true,
                                   clientX: r.x + r.width / 2, clientY: r.y + r.height / 2, view: window };
                    for (const t of ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'])
                        node.dispatchEvent(new (t.startsWith('pointer') ? PointerEvent : MouseEvent)(t, opts));
                    const all = Array.from(document.querySelectorAll('select'))
                        .map(s => Array.from(s.options).map(o => o.value));
                    const has = sig => all.some(x => x.length === sig.length && x.every((v, i) => v === sig[i]));
                    return { ok: true, has: {
                        horizon: has(sigs.horizon),
                        workflowType: has(sigs.workflowType),
                    }};
                }""",
                SIG,
            )
            if not selected.get("ok"):
                failures.append("rendered-DOM: " + selected.get("reason", "node selection failed"))
            else:
                for k in ("horizon", "workflowType"):
                    if not selected["has"][k]:
                        failures.append(
                            f"rendered-DOM: inspector '{k}' dropdown not rendered "
                            f"after selecting a serviceTask node"
                        )

            # (4) CONSOLE -------------------------------------------------------
            unexpected = [e for e in console_errors
                          if not any(w in e for w in CONSOLE_WHITELIST)]
            if unexpected:
                failures.append("unexpected console errors: " + "; ".join(unexpected))

            browser.close()
    finally:
        httpd.shutdown()

    if failures:
        print(f"FAIL: designer render-check ({version}) — {len(failures)} issue(s):",
              file=sys.stderr)
        for f in failures:
            print("  - " + f, file=sys.stderr)
        sys.exit(1)

    print(f"PASS: designer render-check ({version}) — render, T-177 markers, "
          f"inspector dropdowns, and console all OK "
          f"(whitelisted probes: {', '.join(CONSOLE_WHITELIST)})")


if __name__ == "__main__":
    main()
