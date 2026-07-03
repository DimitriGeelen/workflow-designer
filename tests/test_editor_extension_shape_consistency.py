#!/usr/bin/env python3
"""test_editor_extension_shape_consistency — pin aef: field *shape* across the
JS↔Python seam (T-053).

Sibling to test_editor_namespace_consistency (T-044). That test pinned the aef:
namespace *URI* across editor and bridge. This one pins the per-field
*serialization shape*: whether a field lives in element text
(`<aef:F>value</aef:F>`) or in an attribute (`<aef:F attr="value"/>`).

The T-053 bug: the bridge emitted `decisionOutputs` as element text (like
`decisionInput`), but the editor read it via `getAttribute('values')`. Each side
was internally consistent, so neither side's own tests failed — the mismatch
lived only in the cross-artifact seam, and a bridge-generated BPMN opened in the
editor silently dropped its decision outputs.

Invariant enforced here (self-maintaining — no hand-kept table):
  For every field the bridge emits as a DEDICATED child element
  `<aef:FIELD>%s</aef:FIELD>`, the editor's parseBpmnXml MUST recover it via
  `.textContent` (element shape). Reading such a field only via `.getAttribute`
  is the data-loss bug and fails the test.

Pure stdlib (no jsdom/browser): shape is a textual property of both sources.
Exit 0 = shapes consistent. Exit 1 = a shape mismatch. Exit 2 = self-test failed.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRIDGE = "tools/yaml-to-bpmn.py"
EDITOR = "src/aef-workflow-designer.html"

# Bridge lines that emit a dedicated element-text field: `<aef:FIELD>%s</aef:FIELD>`.
RE_BRIDGE_ELEMENT_FIELD = re.compile(r"<aef:(\w+)>%s</aef:\1>")


def _read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as fh:
        return fh.read()


def bridge_element_fields(text):
    """Fields the bridge emits as `<aef:FIELD>text</aef:FIELD>` (element shape)."""
    return sorted(set(RE_BRIDGE_ELEMENT_FIELD.findall(text)))


def editor_read_expr(text, field):
    """Return the RHS expression the editor assigns to `aef.<field>` in parseBpmnXml,
    or None if the editor does not read that field."""
    m = re.search(r"aef\.%s\s*=\s*([^;\n]+)" % re.escape(field), text)
    return m.group(1).strip() if m else None


def check(bridge_text, editor_text):
    """Return list of (field, reason) findings. Empty list = consistent."""
    findings = []
    for field in bridge_element_fields(bridge_text):
        expr = editor_read_expr(editor_text, field)
        if expr is None:
            # Bridge emits it but the editor never reads it — a different (import
            # coverage) gap; out of scope for this shape check, so skip quietly.
            continue
        if ".textContent" not in expr:
            findings.append((
                field,
                "bridge emits <aef:%s> as element text but editor reads it via "
                "`%s` (no .textContent) — round-tripped value is lost" % (field, expr),
            ))
    return findings


def _selftest():
    """Prove the detector flags an attribute-only read of an element-text field —
    i.e. it would have caught the T-053 bug."""
    bridge = "out.append('<aef:decisionOutputs>%s</aef:decisionOutputs>')"
    good = "if (decOutEl) aef.decisionOutputs = (decOutEl.textContent || '').trim();"
    bad = "if (decOutEl) aef.decisionOutputs = decOutEl.getAttribute('values') || '';"
    assert check(bridge, good) == [], "self-test: element-text read wrongly flagged"
    flagged = check(bridge, bad)
    assert len(flagged) == 1 and flagged[0][0] == "decisionOutputs", \
        "self-test: attribute-only read of an element field was NOT flagged"


def main():
    try:
        _selftest()
    except AssertionError as exc:
        sys.stderr.write("SELFTEST FAIL: %s\n" % exc)
        return 2

    bridge_text = _read(BRIDGE)
    editor_text = _read(EDITOR)

    fields = bridge_element_fields(bridge_text)
    if not fields:
        sys.stderr.write("error: no `<aef:FIELD>%s</aef:FIELD>` emissions found in "
                         "%s — scan pattern wrong?\n" % BRIDGE)
        return 2

    findings = check(bridge_text, editor_text)
    if findings:
        sys.stderr.write("aef: FIELD SHAPE MISMATCH (bridge element text vs editor read):\n")
        for field, reason in findings:
            sys.stderr.write("  - %s: %s\n" % (field, reason))
        return 1

    print("OK: %d bridge element-text field(s) [%s] all read via .textContent in editor"
          % (len(fields), ", ".join(fields)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
