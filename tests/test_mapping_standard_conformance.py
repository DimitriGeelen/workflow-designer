#!/usr/bin/env python3
"""test_mapping_standard_conformance — guard the mapping STANDARD against the
implementation (T-182, arc: designer-authoring-surface child-1).

`docs/standards/aef-bpmn-mapping-v1.md` freezes a list of governance meta-keys
(§2) that a v1-conformant editor MUST emit and the bridge MUST round-trip. This
test parses that frozen list from the standard and asserts every key is actually
present in BOTH the reference editor's `metaKeys` and the bridge's `META_KEYS` —
so the *document* and the *code* cannot silently drift.

Relationship to the T-060 parity test:
  test_editor_bridge_meta_parity.py  guards  editor metaKeys ⊆ bridge META_KEYS.
  THIS test                          guards  standard(frozen) ⊆ editor metaKeys
                                             AND standard(frozen) ⊆ bridge META_KEYS.
Together: the standard, the editor, and the bridge stay in lockstep on the
governance vocabulary. Parsers are IMPORTED from the parity test so the three
share one extraction implementation.

Frozen list is read from a fenced block in the standard:
    ```conformance-governance-meta-keys
    horizon
    workflowType
    ...
    ```
Guards against a vacuous pass (PL-022): a missing/empty fence is a FAILURE, not a
silent skip.

Pure stdlib. Exit 0 = conformant. Exit 1 = drift (a frozen key missing from an
implementation, or the fence missing/empty). Exit 2 = self-test/extraction failure.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Reuse the parity test's extraction — single source of truth for parsing.
from test_editor_bridge_meta_parity import (  # noqa: E402
    editor_meta_keys,
    bridge_meta_keys,
    _read,
    EDITOR,
    BRIDGE,
)

STANDARD = "docs/standards/aef-bpmn-mapping-v1.md"

# The frozen governance-meta-key fenced block.
RE_FENCE = re.compile(
    r"```conformance-governance-meta-keys\s*\n(.*?)```",
    re.DOTALL,
)


def frozen_meta_keys(text):
    """Extract the frozen governance-meta-key list from the standard, or None."""
    m = RE_FENCE.search(text)
    if not m:
        return None
    keys = [ln.strip() for ln in m.group(1).splitlines()]
    return [k for k in keys if k and not k.startswith("#")]


def check(frozen, editor_keys, bridge_keys):
    """Return (missing_from_editor, missing_from_bridge)."""
    eset, bset = set(editor_keys), set(bridge_keys)
    return (
        [k for k in frozen if k not in eset],
        [k for k in frozen if k not in bset],
    )


def _selftest():
    doc_ok = "text\n```conformance-governance-meta-keys\nhorizon\nowner\n```\nmore"
    assert frozen_meta_keys(doc_ok) == ["horizon", "owner"], "selftest: fence parse wrong"
    # Missing fence → None (must be treated as failure by main, not empty-pass).
    assert frozen_meta_keys("no fence here") is None, "selftest: missing fence not None"
    # Empty fence → [] (also a failure).
    assert frozen_meta_keys("```conformance-governance-meta-keys\n```") == [], "selftest: empty fence"
    me, mb = check(["horizon", "owner", "ghost"], ["horizon", "owner"], ["horizon", "owner"])
    assert me == ["ghost"] and mb == ["ghost"], "selftest: drift not flagged: %r %r" % (me, mb)
    me, mb = check(["horizon"], ["horizon"], ["horizon"])
    assert me == [] and mb == [], "selftest: conformant wrongly flagged"


def main():
    try:
        _selftest()
    except AssertionError as exc:
        sys.stderr.write("SELFTEST FAIL: %s\n" % exc)
        return 2

    frozen = frozen_meta_keys(_read(STANDARD))
    if frozen is None:
        sys.stderr.write(
            "error: no ```conformance-governance-meta-keys fence in %s — the standard's "
            "frozen list is the subject of this test; its absence is a FAILURE, not a skip.\n" % STANDARD)
        return 1
    if not frozen:
        sys.stderr.write("error: frozen governance-meta-key fence in %s is EMPTY.\n" % STANDARD)
        return 1

    editor_keys = editor_meta_keys(_read(EDITOR))
    bridge_keys = bridge_meta_keys(_read(BRIDGE))
    if not editor_keys or not bridge_keys:
        sys.stderr.write("error: could not extract editor metaKeys or bridge META_KEYS.\n")
        return 2

    missing_editor, missing_bridge = check(frozen, editor_keys, bridge_keys)
    if missing_editor or missing_bridge:
        sys.stderr.write(
            "STANDARD↔IMPLEMENTATION DRIFT — frozen governance meta-key(s) in %s not honored:\n" % STANDARD)
        for k in missing_editor:
            sys.stderr.write("  - %s: not emitted by editor metaKeys (%s)\n" % (k, EDITOR))
        for k in missing_bridge:
            sys.stderr.write("  - %s: not in bridge META_KEYS (%s)\n" % (k, BRIDGE))
        sys.stderr.write("Fix: align the standard's frozen list with the implementation, "
                         "or bump the standard version if the contract changed.\n")
        return 1

    print("OK: all %d frozen governance meta-keys [%s] present in both editor metaKeys and bridge META_KEYS"
          % (len(frozen), ", ".join(frozen)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
