#!/usr/bin/env python3
"""
T-942: the ONE console-error whitelist for every guard that loads the designer headless.

Why this module exists
----------------------
Three guards load `dist/aef-workflow-designer-*.html` in chromium and assert a clean console:
`test_designer_render.py`, `test_designer_export_contract.py`, `test_designer_owner_derived.py`.
Each carried its own private copy of the same tuple.

T-884 shipped `GET /api/instances` on 2026-09-29 and updated none of them. The render-check copy
was corrected on 2026-09-30 (T-940) because it blocked the 0.14.0 release; the other two stayed
broken and were only found when a sweep ran the suite a day later. Three copies of one rule meant
one omission broke a SUBSET, and the subset that got fixed was the one with a deadline attached.
That is PL-214 — fix at the shared mechanism, not at the site where the defect surfaced.

Adding a route here now updates all three. A new optional probe cannot break two of three again.

What belongs here, and what does not
------------------------------------
ONLY errors produced by the browser's own network layer for a backend that is legitimately
absent when the build is served as a static file — the same condition as AEF's `:3001/designer`.
These entries are unavoidable BY CONSTRUCTION: the console line is emitted before any JS runs,
so no amount of `try`/`catch` in the designer can prevent it.

An entry is NOT justified because a test is failing. If a console error means the designer is
broken, the designer is broken — silencing it here converts a real signal into permanent silence
across all three guards at once, which is exactly the leverage that makes this module worth
being careful with. Every entry states its reason on its own line, so a bare addition has
nowhere to hide.
"""

# Each entry: the substring matched against "<message> @ <location>", and why it is unavoidable.
#
#   /api/health     the original backend liveness probe (T-178). No backend when static.
#   /favicon.ico    requested by the browser itself, never by the designer.
#   /api/instances  T-884's instance-overlay snapshot (added T-940 after this gate correctly
#                   blocked the 0.14.0 release). The designer's handling is CORRECT and was not
#                   changed: loadInstanceSnapshot() catches the failure and sets
#                   instanceView.available = false — "additive overlay: absence is a state, never
#                   a fault" — and selectInstance() refuses to report not-found without the
#                   endpoint rather than claiming it read the corpus. The console entry comes from
#                   the NETWORK layer before any JS runs, so it cannot be caught away; repairing
#                   src/ to silence it would be breaking correct code to satisfy a stale test.
#
# As of T-176 the web fonts are embedded (base64 woff2) — there is NO CDN font request in 0.3.0+,
# so a font/CDN error can no longer occur and is deliberately NOT whitelisted.
CONSOLE_WHITELIST = ("/api/health", "/favicon.ico", "/api/instances")


def unexpected(console_errors):
    """Filter a list of console-error strings down to the ones no entry explains.

    Kept here rather than repeated in each guard so the MATCHING rule is shared too, not just
    the tuple — three identical `any(w in e for w in ...)` comprehensions is the same duplication
    one level down.
    """
    return [e for e in console_errors if not any(w in e for w in CONSOLE_WHITELIST)]
