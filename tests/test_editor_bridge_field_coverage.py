#!/usr/bin/env python3
"""test_editor_bridge_field_coverage — no editor-readable aef field is dropped by
the bridge (T-059).

Third sibling in the editor↔bridge seam-guard family (namespace: T-044; shape:
T-053; coverage: this). It closes the blind spot those two missed: the bridge
can silently *omit an entire field* that the editor reads, and because the bridge
suite only checks that emitted BPMN *validates*, the dropped data goes unnoticed.

The T-059 bug: `tools/yaml-to-bpmn.py` had no emit for `contextReads`,
`artifactsWrites`, node `io`, or `link`, so canonical YAML rendered to BPMN and
opened in the editor lost those fields (artifactsWrites alone in 7 of 16 maps).

Invariant (data-driven, self-maintaining — no hand-kept field list):
  For every corpus `*.workflow.yaml`, and every node field that
    (a) is present in that YAML (an `aef:` key, or the top-level `io` key), AND
    (b) the editor reads as a node-level extension via `byAef(el, 'FIELD')`,
  the bridge's emitted BPMN MUST retain it — either as a dedicated
  `<aef:FIELD …>` element, or (for a bridge META_KEYS scalar) as an attribute on
  `<aef:meta …>`. A field the editor reads but that never appears in any YAML
  (e.g. editor-only visual hints: anchors/routing/routingHint/loopDetour) is out
  of scope: there is no data to drop.

Pure stdlib except PyYAML (already a bridge dependency). Runs the real bridge.
Exit 0 = no field dropped. Exit 1 = a field was dropped. Exit 2 = self-test failed.
"""
import glob
import os
import re
import subprocess
import sys

import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRIDGE = os.path.join(ROOT, "tools", "yaml-to-bpmn.py")
EDITOR = os.path.join(ROOT, "src", "aef-workflow-designer.html")
CORPUS = os.path.join(ROOT, "examples", "aef-processes")


def editor_node_reads():
    """Field local-names the editor reads at node level via byAef(el, 'X')."""
    text = open(EDITOR, encoding="utf-8").read()
    return set(re.findall(r"byAef\(el,\s*'([A-Za-z]+)'\)", text))


def bridge_meta_keys():
    """The META_KEYS tuple the bridge emits as <aef:meta> attributes."""
    text = open(BRIDGE, encoding="utf-8").read()
    m = re.search(r"META_KEYS\s*=\s*\((.*?)\)", text, re.S)
    if not m:
        return set()
    return set(re.findall(r"['\"]([A-Za-z]+)['\"]", m.group(1)))


def node_fields(node):
    """aef keys present on a node, plus 'io' if the node carries a top-level io block."""
    fields = set()
    aef = node.get("aef") or {}
    if isinstance(aef, dict):
        fields |= set(aef.keys())
    io = node.get("io") or {}
    if isinstance(io, dict) and (io.get("inputs") or io.get("outputs")):
        fields.add("io")
    return fields


def field_survives(field, bpmn, meta_keys):
    """Is `field` retained in the emitted BPMN text?"""
    if re.search(r"<aef:%s[\s/>]" % re.escape(field), bpmn):
        return True  # dedicated element
    if field in meta_keys and re.search(r"<aef:meta\b[^>]*\b%s=" % re.escape(field), bpmn):
        return True  # META_KEYS attribute on <aef:meta>
    return False


def render(path):
    """Run the real bridge; return emitted BPMN text (raises on failure)."""
    return subprocess.run(
        [sys.executable, BRIDGE, path, "--out", "/dev/stdout"],
        capture_output=True, text=True, check=True,
    ).stdout


def check_corpus(reads, meta_keys):
    """Return list of (map, node_uid, field) findings for dropped fields."""
    findings = []
    for path in sorted(glob.glob(os.path.join(CORPUS, "*.workflow.yaml"))):
        base = os.path.basename(path)[: -len(".workflow.yaml")]
        wf = yaml.safe_load(open(path, encoding="utf-8"))
        bpmn = render(path)
        for node in wf.get("nodes", []) or []:
            if not isinstance(node, dict):
                continue
            for field in node_fields(node) & reads:
                if not field_survives(field, bpmn, meta_keys):
                    findings.append((base, node.get("uid", "?"), field))
    return findings


def _selftest():
    """Prove the survival check flags a dropped element field and accepts a meta attr."""
    meta_keys = {"endpoint"}
    good_elem = '<aef:contextReads paths="x"/>'
    good_meta = '<aef:meta endpoint="fw x"/>'
    assert field_survives("contextReads", good_elem, meta_keys)
    assert field_survives("endpoint", good_meta, meta_keys)
    assert not field_survives("contextReads", "<aef:meta tier=\"1\"/>", meta_keys), \
        "self-test: a dropped field was not detected"
    assert not field_survives("io", "<aef:uid value=\"n\"/>", meta_keys)


def main():
    try:
        _selftest()
    except AssertionError as exc:
        sys.stderr.write("SELFTEST FAIL: %s\n" % exc)
        return 2

    reads = editor_node_reads()
    meta_keys = bridge_meta_keys()
    if not reads or not meta_keys:
        sys.stderr.write("error: could not extract editor reads / bridge META_KEYS — scan patterns wrong?\n")
        return 2

    findings = check_corpus(reads, meta_keys)
    if findings:
        sys.stderr.write("BRIDGE DROPS editor-readable field(s) present in the corpus YAML:\n")
        for base, uid, field in findings:
            sys.stderr.write("  - %s / node %s: aef field '%s' not retained in emitted BPMN\n"
                             % (base, uid, field))
        return 1

    print("OK: every editor-readable aef field present in the corpus survives the bridge "
          "(%d read-fields, %d META_KEYS checked)" % (len(reads), len(meta_keys)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
