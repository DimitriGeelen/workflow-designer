#!/usr/bin/env python3
"""test_t311_doc_comment_roundtrip — T-311 regression guard for the authored doc
block, arc: designer-authoring-surface.

The real work is `tools/_t311-doc-comment-roundtrip-cdp.mjs`, which drives the REAL
editor runtime in an isolated headless chromium against
tests/fixtures/aef-bpmn/doc-comment.bpmn.

Background: the leading comment child of <bpmn:definitions> carries the map's
authored rationale, and AEF's corpus_spec treats it as SEMANTIC (`fw corpus
explain` prints it). Our save path destroyed it. There was no COMMENT_NODE
handling anywhere in the designer, so the comment was never read at parse, and
buildBpmnXml re-synthesises the document from state — the first UI save dropped
the doc and every save after inherited the loss. The single comment we DID emit
was our own hardcoded DI trailer, as the LAST child. AEF's then-guardless
parse_map took the first comment as `doc`, so it adopted our boilerplate as the
rationale: 5 of their 11 maps, 2 of them already promoted. Their reader guard
shipped as T-2682 and the promoted maps were restored from git history as T-2683;
this is our half.

The harness asserts, in nine legs:

  * the doc block is captured at import and is byte-verbatim (1398 chars here,
    including internal newlines, hanging indentation, angle brackets and an
    ampersand that must NOT be escaped — comment data is not parsed content)
  * it is re-emitted LEADING, ahead of <bpmn:collaboration>, which is the position
    AEF's reader keys on
  * the round-trip is stable: export, re-import, export again, byte-identical
  * a map with no doc block gains none, and its export carries no leading comment
  * our own DI trailer is never adopted as rationale — including when a hand-edit
    HOISTS it into leading position, so the guard is prefix-based and not merely
    positional (this is the exact defect that poisoned AEF's corpus)
  * the doc survives an edit -> undo cycle, whose snapshots serialise through
    buildBpmnXml and restore through parseBpmnXml — a gap at either end would
    drop it silently
  * a doc containing sequences XML forbids inside a comment (`--`, trailing `-`)
    still exports to a parseable document rather than corrupting it

Note the fixture validates CLEAN under tools/validate-workflow.py. That is
deliberate: a doc comment is not a schema feature, so no structural rule has an
opinion about it. Together with T-310 this is the second finding in a row that
both toolchains' validators pass because both are structural — the guard has to
be a browser-level test.

Teeth (PL-061): the harness accepts an optional path to a different designer
build. Run it against the pre-fix source and it goes red on five real assertions
(not captured, not emitted, not leading, lost on re-import, lost on undo) rather
than erroring out:
    node tools/_t311-doc-comment-roundtrip-cdp.mjs /path/to/older-designer.html

Chromium/node absence is an ENVIRONMENT skip, surfaced LOUDLY — never a silent
green (T-212 convention). Runs standalone
(`python3 tests/test_t311_doc_comment_roundtrip.py`) and under pytest.
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(ROOT, "tools", "_t311-doc-comment-roundtrip-cdp.mjs")
FIXTURE = os.path.join(ROOT, "tests", "fixtures", "aef-bpmn", "doc-comment.bpmn")


def _chromium_present():
    cache = os.path.join(os.path.expanduser("~"), ".cache", "ms-playwright")
    if not os.path.isdir(cache):
        return False
    for d in os.listdir(cache):
        if d.startswith("chromium-") and os.path.exists(
            os.path.join(cache, d, "chrome-linux64", "chrome")
        ):
            return True
    return False


def _skip_reason():
    if not os.path.isfile(HARNESS):
        return None  # missing harness is a real failure, not a skip
    if shutil.which("node") is None:
        return "node not on PATH — t311 doc-comment harness needs Node.js"
    if not _chromium_present():
        return "no Playwright chromium build in ~/.cache/ms-playwright — harness needs a browser"
    return None


def run_harness():
    assert os.path.isfile(HARNESS), "harness missing: %s" % HARNESS
    assert os.path.isfile(FIXTURE), "fixture missing: %s" % FIXTURE
    proc = subprocess.run(
        ["node", HARNESS], cwd=ROOT, capture_output=True, text=True, timeout=240
    )
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def test_doc_comment_roundtrip():
    reason = _skip_reason()
    if reason:
        try:
            import pytest  # noqa: WPS433
            pytest.skip(reason)
        except ImportError:
            print("SKIP: %s" % reason)
            return
    code, out = run_harness()
    assert code == 0, "t311 doc-comment harness failed (exit %d):\n%s" % (
        code,
        out[-1500:],
    )


def main():
    reason = _skip_reason()
    if reason:
        print("SKIP: %s" % reason)
        return 0
    try:
        code, out = run_harness()
    except AssertionError as exc:
        sys.stderr.write("FAIL: %s\n" % exc)
        return 1
    sys.stdout.write(out if out.endswith("\n") else out + "\n")
    if code == 0:
        print(
            "OK: the authored doc block is captured verbatim, leads the exported "
            "document, survives re-import and undo, is never confused with our own "
            "DI trailer, and cannot corrupt the document"
        )
    else:
        sys.stderr.write("FAIL: harness exit %d (see verdict above)\n" % code)
    return code


if __name__ == "__main__":
    sys.exit(main())
