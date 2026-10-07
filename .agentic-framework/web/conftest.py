"""Pytest configuration for web/ test suite.

T-1823 — `framework_repo` marker + auto-skip on consumer projects.

Some tests in this file assert framework-repo fixture data (G-001 in
/gaps, 001-Vision in /project, "Watchtower v" in the footer). They will
fail on consumer projects whose data shape is different. Rather than
remove them — they're load-bearing for framework-dev — we mark them and
let pytest skip on consumers.

Consumer mode is detected via the same heuristic `fw doctor` uses
(T-574): FRAMEWORK_ROOT != PROJECT_ROOT. Both env vars are exported by
the `fw` shim on every invocation; running pytest outside `fw test` (or
without those env vars set) is treated as framework-repo mode so local
hacking still exercises the full suite.
"""

import os

import pytest


def _is_consumer_mode() -> bool:
    """Return True when running on a consumer project (not the framework repo).

    Mirrors the FRAMEWORK_ROOT vs PROJECT_ROOT comparison in `bin/fw`
    (the doctor's `Check 9: Test infrastructure` block).
    """
    framework_root = os.environ.get("FRAMEWORK_ROOT")
    project_root = os.environ.get("PROJECT_ROOT")
    if not framework_root or not project_root:
        # No fw env → assume framework-repo mode (local hacking).
        return False
    return os.path.realpath(framework_root) != os.path.realpath(project_root)


def pytest_configure(config):
    """Register the `framework_repo` marker so pytest doesn't warn."""
    config.addinivalue_line(
        "markers",
        "framework_repo: test assumes framework-repo fixture data "
        "(skipped on consumer projects).",
    )


def pytest_collection_modifyitems(config, items):
    """Auto-skip `framework_repo`-marked tests on consumer projects."""
    if not _is_consumer_mode():
        return
    skip_marker = pytest.mark.skip(
        reason="framework_repo-only test — running on a consumer project "
        "(FRAMEWORK_ROOT != PROJECT_ROOT)."
    )
    for item in items:
        if "framework_repo" in item.keywords:
            item.add_marker(skip_marker)

# ---------------------------------------------------------------------------
# T-648: shared by test_app.py and test_costs.py. It lives here rather than in
# test_app.py because test_costs.py importing from a sibling test module would make
# one suite's collection depend on another's. Three call sites, one definition —
# the point of the exercise is not to write a third spelling of the same check.
# ---------------------------------------------------------------------------
def document_shell_constructs(payload):
    """Return the document-shell constructs a real HTML parser finds in `payload`.

    T-645: this used to be two substring assertions —

        assert "<!DOCTYPE" not in html
        assert "<html" not in html

    — which is a CHARACTER SCAN standing in for a STRUCTURAL property. HTML tag names
    are case-insensitive and Python's `in` is not, and a substring cannot tell whether
    it is sitting in a comment, a script body, or an attribute value. Measured, the
    scan was wrong in both directions at once:

        <HTML><BODY>x</BODY></HTML>        scan PASSED   parser: <html>, <body>
        <!doctype html><p>x</p>            scan PASSED   parser: <!DOCTYPE>
        <body><p>x</p></body>              scan PASSED   parser: <body>
        <Html lang="en"><p>x</p></Html>    scan PASSED   parser: <html>
        <!-- <html> --><p>hi</p>           scan FAILED   parser: (clean)
        <script>var s = "<html>";</script> scan FAILED   parser: (clean)

    Four ways to ship a whole document past the test, and two ways to be failed by text
    that is not markup at all. So: ask the parser. `html.parser` lowercases tag names
    for us and treats script/style bodies as CDATA and comments as comments, which is
    the entire difference between the two columns above.

    This does not take over T-646's job. A raw `<html>` in page prose genuinely IS a
    start tag to any parser, so it is still reported here — as "a document shell was
    found", which is the honest limit of what a fragment test can say about it.
    """
    import html.parser as _hp

    found = []

    class _ShellFinder(_hp.HTMLParser):
        def handle_starttag(self, tag, attrs):
            if tag in ("html", "head", "body"):
                found.append("<%s>" % tag)

        def handle_decl(self, decl):
            if decl.lower().startswith("doctype"):
                found.append("<!DOCTYPE>")

    parser = _ShellFinder(convert_charrefs=True)
    parser.feed(payload)
    parser.close()
    return found


@pytest.fixture
def document_shell(): 
    """The T-648 detector, as a fixture.

    A plain function defined in conftest.py is NOT importable from a test module by
    virtue of living here — pytest auto-loads conftest for fixtures and hooks, not for
    names. Exposing it as a fixture is what actually makes it shared, and it avoids
    `from conftest import ...`, which only works by accident of sys.path insertion.
    """
    return document_shell_constructs
