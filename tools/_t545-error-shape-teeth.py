#!/usr/bin/env python3
"""T-545 teeth — a 403 must be written for the client that asked for it.

The operator clicked Approve on /approvals and the toast read:

    Session expired — Workflow designer (function(){var t=localStorage.getItem(…

That is not a garbled message, it is a whole HTML document being scraped. The
403 handler rendered the full T-2309 "Session expired" PAGE (66456 bytes) to an
`hx-post`, and `web/static/htmx-toast.js` extracts its message with

    .replace(/<[^>]*>/g, '').trim().substring(0, 100)

which is a TAG stripper, not a text extractor: it removes `<title>`/`<script>`
tags and keeps the text inside them. So the page title and the theme bootstrap's
JavaScript source became the error message.

Two properties are pinned here, because fixing only one leaves the defect:

  A. the SHAPE — an htmx/API caller gets a fragment, not a document;
  B. the CONSEQUENCE — what the shipped toast expression actually produces from
     that body contains no script source. (A) without (B) is an assertion about
     byte counts; (B) is the thing the operator saw.

Leg 5 exists because the first draft of the fix was WRONG in a way that looked
right: it exempted `HX-Boosted` requests to protect T-2309's full-page recovery
UI. Five routes post plain `<form method="post">` under `hx-boost`, so they are
boosted POSTs and kept the defect. Leg 6 re-checks the fact that settled it —
htmx never swaps a 4xx — because the whole design rests on it and a library
upgrade could silently retire it.

The trigger for the generic-403 leg is synthetic (a route registered by this
probe that aborts 403); the HANDLER under test is the real one.

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import os
import re
import sys
from pathlib import Path

ROOT = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FW = ROOT / ".agentic-framework"
TOAST_JS = FW / "web" / "static" / "htmx-toast.js"
HTMX_JS = FW / "web" / "static" / "htmx.min.js"

# What the pre-fix handler returned to the operator's Approve button, measured
# on the running instance before the change. Named so the improvement below is
# a comparison against a real prior observation, not a bare threshold.
PRE_FIX_BYTES = 66456
FRAGMENT_CEILING = 2048


def refuse(msg):
    print("REFUSE: %s" % msg)
    sys.exit(2)


def toast_extract(body: str) -> str:
    """Apply htmx-toast.js's OWN extraction expression, read from the shipped
    file rather than re-typed here. A re-typed copy would keep passing after
    someone changed the real one."""
    src = TOAST_JS.read_text(encoding="utf-8")
    m = re.search(r"\.replace\(/(.+?)/g,\s*''\)", src)
    if not m:
        refuse("could not find the tag-stripping expression in %s — this probe "
               "asserts what that expression PRODUCES, so it must read the real "
               "one; a hardcoded copy would pass after the real one changed"
               % TOAST_JS.name)
    limit = re.search(r"\.substring\(0,\s*(\d+)\)", src)
    if not limit:
        refuse("could not find the substring() cap in %s" % TOAST_JS.name)
    return re.sub(m.group(1), "", body).strip()[: int(limit.group(1))]


def main():
    for p in (TOAST_JS, HTMX_JS):
        if not p.is_file():
            refuse("%s not found — nothing to measure" % p)

    sys.path.insert(0, str(FW))
    os.environ["PROJECT_ROOT"] = str(ROOT)
    try:
        from flask import abort
        from web.app import create_app
    except Exception as exc:                                # noqa: BLE001
        refuse("could not import the app under test: %s" % exc)

    app = create_app()
    app.config["TESTING"] = True

    # Synthetic trigger, real handler: a generic (non-CSRF) 403 so leg 4 can
    # check that T-2309's distinction survives on the compact branch too.
    app.add_url_rule(
        "/api/_t545_generic", "_t545_generic",
        lambda: abort(403, description="not your proposal"), methods=["POST"],
    )

    c = app.test_client()
    failures = []

    # The operator's exact path: hx-post to /api/*, no CSRF token.
    api = c.post("/api/bvp/driver/approve?id=P-nope")
    if api.status_code != 403:
        refuse("the /api/ approve route returned %d, not 403 — the stimulus "
               "this probe depends on is gone, which is not a pass"
               % api.status_code)
    api_body = api.get_data(as_text=True)

    # ── Leg 1 — SHAPE: a fragment, not a document.
    if len(api_body) > FRAGMENT_CEILING:
        failures.append(
            "leg1: 403 on an /api/* path returned %d bytes (pre-fix was %d, "
            "ceiling %d). The handler is rendering a full page to a client "
            "that splices fragments."
            % (len(api_body), PRE_FIX_BYTES, FRAGMENT_CEILING))
    if "<html" in api_body.lower() or "<!doctype" in api_body.lower():
        failures.append(
            "leg1b: the /api/* 403 body is a whole HTML document — it carries "
            "<html>/<!doctype>, which no fragment target can absorb.")

    # ── Leg 2 — CONSEQUENCE: what the operator actually reads.
    #    This is the leg that owns the reported symptom.
    toast = toast_extract(api_body)
    leak = [t for t in ("localStorage", "function()", "var t=", "querySelector")
            if t in toast]
    if leak:
        failures.append(
            "leg2: htmx-toast.js's own extraction of this body yields "
            "JavaScript source (%s). This is verbatim the operator's report: "
            "the tag stripper removes <script> tags and keeps what is inside "
            "them. Toast would read: %r" % (", ".join(leak), toast[:90]))
    if not toast.strip():
        failures.append(
            "leg2b: the toast would be EMPTY — the caller is told a save "
            "failed with no reason, which is a different failure, not a fix.")

    # ── Leg 3 — the T-2309 recovery page is NOT traded away. A genuine
    #    navigation (no HX-Request) is the only thing that renders a 403 as a
    #    document, so it must still get the page with its Reload control.
    nav = c.post("/inception/T-000/decide")
    nav_body = nav.get_data(as_text=True)
    if "Reload page" not in nav_body:
        failures.append(
            "leg3: a non-htmx navigation no longer receives T-2309's "
            "Session-expired page with its Reload button (%d bytes). The API "
            "fix must not cost the recovery UI." % len(nav_body))

    # ── Leg 4 — the CSRF/generic distinction survives on the compact branch.
    #    The trigger has to PASS CSRF first — csrf_protect() is a before_request
    #    on every POST, so an unauthenticated call to the synthetic route aborts
    #    with the CSRF description and never reaches it. That is what this leg
    #    caught on its first run: the leg was red because the STIMULUS was
    #    wrong, not the handler. Seed a session token and present it.
    with c.session_transaction() as s:
        s["_csrf_token"] = "t545-probe-token"
    gen = c.post("/api/_t545_generic",
                 headers={"X-CSRF-Token": "t545-probe-token"})
    k_csrf, k_gen = api.headers.get("HX-Error-Kind"), gen.headers.get("HX-Error-Kind")
    if gen.status_code != 403:
        refuse("the synthetic generic-403 route returned %d — leg 4 has no "
               "non-CSRF 403 to compare against and would be vacuous"
               % gen.status_code)
    #    Match the EXACT description csrf_protect() aborts with, not a bare
    #    "CSRF" substring: every rendered page carries a csrf-token meta tag, so
    #    the loose form made this refuse — i.e. ABSTAIN — under the very mutant
    #    that reverts the fix, when it owes a red leg instead. A control that
    #    declines to answer when the defect returns is not a control.
    if "CSRF token missing or invalid" in gen.get_data(as_text=True):
        refuse("the synthetic generic-403 still went through the CSRF branch — "
               "leg 4 would be comparing a CSRF failure with itself")
    if not k_csrf or not k_gen:
        failures.append(
            "leg4: the compact 403 carries no HX-Error-Kind header (csrf=%r "
            "generic=%r) — a machine client cannot tell a stale token from a "
            "real permission denial without parsing prose." % (k_csrf, k_gen))
    elif k_csrf == k_gen:
        failures.append(
            "leg4: a CSRF failure and a genuine permission denial both report "
            "HX-Error-Kind=%r. T-2309 introduced that distinction precisely "
            "because the two need different responses." % k_csrf)

    # ── Leg 5 — the exemption the first draft got wrong. Five routes post a
    #    plain <form> under hx-boost; they must not fall back to the document.
    boosted = c.post("/inception/T-000/decide",
                     headers={"HX-Request": "true", "HX-Boosted": "true"})
    if len(boosted.get_data(as_text=True)) > FRAGMENT_CEILING:
        failures.append(
            "leg5: a BOOSTED form post still receives the full document (%d "
            "bytes). hx-boost turns plain <form method=post> into an htmx "
            "request, and htmx does not swap 4xx — so this body reaches only "
            "the toast and reproduces the original symptom on the five routes "
            "that post that way." % len(boosted.get_data(as_text=True)))

    # ── Leg 6 — the fact the whole design rests on, re-read from the shipped
    #    library. If a future htmx starts swapping 4xx, the fragment becomes
    #    the thing spliced into the page and this needs rethinking, not a
    #    quietly-still-green suite.
    htmx_src = HTMX_JS.read_text(encoding="utf-8")
    m = re.search(r'\{code:"\[45\]\.\.",swap:(true|false)', htmx_src)
    if not m:
        refuse("could not read htmx's default responseHandling for 4xx — the "
               "fix assumes htmx never swaps a 4xx and this probe cannot "
               "confirm that assumption still holds")
    if m.group(1) != "false":
        failures.append(
            "leg6: htmx now swaps 4xx responses (swap:%s). The compact body "
            "this task introduced would be spliced into the page rather than "
            "scraped by the toast — the fix needs re-deciding, not adjusting."
            % m.group(1))

    print("T-545 error-shape teeth")
    print("    /api/* 403 body    : %d bytes   (pre-fix: %d)"
          % (len(api_body), PRE_FIX_BYTES))
    print("    navigation 403     : %d bytes   (T-2309 page retained)"
          % len(nav_body))
    print("    HX-Error-Kind      : csrf=%s  generic=%s" % (k_csrf, k_gen))
    print("    htmx 4xx swap      : %s" % m.group(1))
    print("    toast would read   : %r" % toast[:88])

    if failures:
        print("\n%d finding(s):" % len(failures))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("\nall legs green")
    return 0


if __name__ == "__main__":
    sys.exit(main())
