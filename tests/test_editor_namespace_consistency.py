#!/usr/bin/env python3
"""test_editor_namespace_consistency — pin the aef: extension namespace (T-044).

Prevention for the T-042 class: the editor's XML *import* path
(`parseBpmnXml` in src/aef-workflow-designer.html) used a different `aef:`
namespace URI than the bridge, validator, corpus, and schema. `byAef`
(getElementsByTagNameNS) then matched zero extension elements and silently
dropped every aef:uid / aef:position, so imported diagrams auto-laid-out.
Nothing caught it because only the emitter (Python) side was ever tested.

This test scans every place the aef: extension namespace is declared —
editor import constant + export xmlns, the bridge, the validator, every
generated/golden .bpmn, and the docs — and asserts they ALL resolve to the
single canonical URI. Any drift on import OR export fails the test.

Pure stdlib (no jsdom/browser): the failure mode is a namespace-constant
mismatch, which is a textual property; a full DOM round-trip of parseBpmnXml
is a future extension if a JS test harness is ever adopted.

Exit 0 = consistent. Exit 1 = drift found. Exit 2 = self-test failed.
"""
import glob
import os
import re
import sys

CANONICAL = "http://anchorpoint.framework/aef/extensions"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Regexes that capture an aef: EXTENSION namespace declaration specifically.
# (Deliberately NOT matching `targetNamespace="…/workflows"` — a different,
#  unused namespace that byAef never resolves.)
RE_XMLNS_AEF = re.compile(r'xmlns:aef\s*=\s*["\']([^"\']+)["\']')
RE_CONST_AEF = re.compile(r'\bAEF_NS\s*=\s*["\']([^"\']+)["\']')


def _read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as fh:
        return fh.read()


def _find(text, *regexes):
    hits = []
    for rx in regexes:
        hits.extend(rx.findall(text))
    return hits


def extract_all():
    """Return list of (source_label, namespace) for every aef: NS declaration."""
    found = []

    def scan(path, *regexes):
        if not os.path.exists(os.path.join(ROOT, path)):
            return
        for ns in _find(_read(path), *regexes):
            found.append((path, ns))

    # Editor: import constant + export xmlns declarations.
    scan("src/aef-workflow-designer.html", RE_CONST_AEF, RE_XMLNS_AEF)
    # Tooling.
    scan("tools/validate-workflow.py", RE_CONST_AEF)
    scan("tools/yaml-to-bpmn.py", RE_CONST_AEF)
    # Spec + archival bundle.
    scan("docs/designer/schema.md", RE_XMLNS_AEF)
    scan("docs/designer/aef-workflow-designer-complete.md", RE_CONST_AEF, RE_XMLNS_AEF)
    # Every generated + golden BPMN.
    for pat in ("examples/aef-processes/rendered/*.bpmn", "tests/fixtures/valid/*.bpmn"):
        for p in sorted(glob.glob(os.path.join(ROOT, pat))):
            rel = os.path.relpath(p, ROOT)
            scan(rel, RE_XMLNS_AEF)

    return found


def check(found):
    """Return list of drift findings (label, ns) where ns != CANONICAL."""
    return [(label, ns) for (label, ns) in found if ns != CANONICAL]


def _selftest():
    """Prove the drift detector actually flags a wrong namespace."""
    sample = [("good", CANONICAL), ("bad", "https://aef.anchorpoint.dev/extensions")]
    drift = check(sample)
    assert drift == [("bad", "https://aef.anchorpoint.dev/extensions")], \
        "self-test failed: drift detector did not flag a mutated namespace"


def main():
    try:
        _selftest()
    except AssertionError as exc:
        sys.stderr.write("SELFTEST FAIL: %s\n" % exc)
        return 2

    found = extract_all()
    if not found:
        sys.stderr.write("error: no aef: namespace declarations found — scan paths wrong?\n")
        return 2

    drift = check(found)
    if drift:
        sys.stderr.write("NAMESPACE DRIFT — expected %s:\n" % CANONICAL)
        for label, ns in drift:
            sys.stderr.write("  - %s uses %s\n" % (label, ns))
        return 1

    print("OK: %d aef: namespace declaration(s) across %d source(s) all canonical"
          % (len(found), len(set(l for l, _ in found))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
