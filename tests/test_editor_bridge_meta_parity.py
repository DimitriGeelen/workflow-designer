#!/usr/bin/env python3
"""test_editor_bridge_meta_parity — pin the `<aef:meta>` attribute whitelist
across the JS↔Python seam (T-060).

Third sibling of the seam guards:
  - test_editor_namespace_consistency (T-044) — the aef: namespace *URI*.
  - test_editor_extension_shape_consistency (T-053) — per-field element-vs-attribute *shape*.
  - test_editor_bridge_field_coverage (T-059) — dedicated-element field *coverage*.
This one guards the fourth channel those three miss: scalar keys carried as
attributes of the single `<aef:meta>` element.

The T-060 bug: the editor writes a fixed set of scalar keys into `<aef:meta>`
(its `metaKeys` array) and reads them back generically (it absorbs *every*
attribute of `<aef:meta>`). The bridge emits `<aef:meta>` from its own separate
`META_KEYS` whitelist. Because the editor read side is generic, no editor test
could notice that the bridge's whitelist was missing `agentType`/`triggeredBy`/
`emits` — a YAML carrying those keys simply lost them on YAML→bridge→BPMN, with
no failing test anywhere. T-059's coverage test was blind to this channel: it
only follows fields the editor reads via `byAef(el,'X')`, never the generic
attribute absorption.

Invariant enforced here:
  Every key the editor's `metaKeys` writer emits into `<aef:meta>` MUST also be
  in the bridge's `META_KEYS` tuple — otherwise the bridge drops it. (⊆, not ==:
  the bridge legitimately emits more keys than the editor authors, e.g.
  determinism/endpoint/sideEffect; those flow bridge→editor via the generic
  absorption, so the reverse direction is not a data-loss risk.)

Pure stdlib: both whitelists are literal lists in their source files.
Exit 0 = editor metaKeys ⊆ bridge META_KEYS. Exit 1 = a key the editor writes is
dropped by the bridge. Exit 2 = self-test / extraction failure.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRIDGE = "tools/yaml-to-bpmn.py"
EDITOR = "src/aef-workflow-designer.html"

# Editor: `const metaKeys = ['tier', 'agentType', ...];` (single JS array literal).
RE_EDITOR_METAKEYS = re.compile(r"const\s+metaKeys\s*=\s*\[([^\]]*)\]")
# Bridge: `META_KEYS = ( "determinism", ... )` (possibly multi-line tuple; may
# contain `# ...` comments between the parens).
RE_BRIDGE_METAKEYS = re.compile(r"META_KEYS\s*=\s*\((.*?)\)", re.DOTALL)
# String literals inside either block: '...' or "...".
RE_STR = re.compile(r"""['"]([^'"]+)['"]""")


def _read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as fh:
        return fh.read()


def _strip_line_comments(text):
    """Drop `# ...` comment tails so commented example keys aren't picked up."""
    return "\n".join(line.split("#", 1)[0] for line in text.splitlines())


def editor_meta_keys(text):
    m = RE_EDITOR_METAKEYS.search(text)
    if not m:
        return None
    return [s for s in RE_STR.findall(m.group(1))]


def bridge_meta_keys(text):
    # Strip `# ...` comments BEFORE matching the tuple: a comment inside the
    # tuple may contain a `)` (e.g. a file path in parens), which would truncate
    # the non-greedy `META_KEYS = (...)` match and hide the trailing keys.
    m = RE_BRIDGE_METAKEYS.search(_strip_line_comments(text))
    if not m:
        return None
    return [s for s in RE_STR.findall(m.group(1))]


def check(editor_keys, bridge_keys):
    """Return the keys the editor writes but the bridge drops (empty = parity)."""
    return [k for k in editor_keys if k not in set(bridge_keys)]


def _selftest():
    """Prove the detector flags a bridge whitelist missing an editor key —
    i.e. it would have caught the T-060 bug (pre-fix bridge lacked `emits`)."""
    editor = "const metaKeys = ['tier', 'agentType', 'emits'];"
    ekeys = editor_meta_keys(editor)
    assert ekeys == ["tier", "agentType", "emits"], "self-test: editor extraction wrong: %r" % ekeys

    bridge_ok = 'META_KEYS = ("tier", "agentType",\n    "emits")  # complete'
    bridge_bad = 'META_KEYS = ("tier", "agentType")  # missing emits (the T-060 bug)'
    assert bridge_meta_keys(bridge_ok) == ["tier", "agentType", "emits"], "self-test: bridge extraction wrong"
    assert check(ekeys, bridge_meta_keys(bridge_ok)) == [], "self-test: parity wrongly flagged"
    dropped = check(ekeys, bridge_meta_keys(bridge_bad))
    assert dropped == ["emits"], "self-test: dropped key NOT flagged: %r" % dropped

    # Commented example keys in the bridge tuple must not count as covered.
    bridge_comment = 'META_KEYS = ("tier",  # "emits" would go here\n    "agentType")'
    assert check(ekeys, bridge_meta_keys(bridge_comment)) == ["emits"], \
        "self-test: commented key wrongly counted as present"


def main():
    try:
        _selftest()
    except AssertionError as exc:
        sys.stderr.write("SELFTEST FAIL: %s\n" % exc)
        return 2

    editor_keys = editor_meta_keys(_read(EDITOR))
    bridge_keys = bridge_meta_keys(_read(BRIDGE))
    if not editor_keys:
        sys.stderr.write("error: could not find `const metaKeys = [...]` in %s\n" % EDITOR)
        return 2
    if not bridge_keys:
        sys.stderr.write("error: could not find `META_KEYS = (...)` in %s\n" % BRIDGE)
        return 2

    dropped = check(editor_keys, bridge_keys)
    if dropped:
        sys.stderr.write(
            "aef:meta PARITY BREAK — editor writes these keys into <aef:meta> but the "
            "bridge META_KEYS drops them (YAML→bridge→BPMN loses them):\n")
        for k in dropped:
            sys.stderr.write("  - %s\n" % k)
        sys.stderr.write("Fix: add the key(s) to META_KEYS in %s\n" % BRIDGE)
        return 1

    print("OK: all %d editor metaKeys [%s] present in bridge META_KEYS (%d keys)"
          % (len(editor_keys), ", ".join(editor_keys), len(bridge_keys)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
