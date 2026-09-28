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

# ── T-875 (arc-005 S1): the DOCUMENT level, which this suite could not reach ──────────────────
#
# Everything above is about NODE-level aef:meta keys. T-875's own finding, re-derived against the
# standard rather than inherited from T-213's claim: §1's two-class partition enumerates NODE-level
# attributes and §6's four conformance clauses never reach document-level metadata. THE STANDARD
# HAS NO DOCUMENT-LEVEL CLASS AT ALL. So `aef:workflowMeta/@kind` cannot be added to a frozen
# fence — there is no fence to add it to, and Part I is frozen and is not edited here.
#
# What IS assertable, and is asserted below:
#
#   (1) A TRIPWIRE ON THE STANDARD. Exactly one conformance fence exists today. If a
#       document-level fence ever appears, this test FAILS and says to wire it in — rather than
#       the fence sitting in the standard unenforced, which is the drift this whole suite exists
#       to prevent, one level up. It is a currently-true assertion, not a permanent red
#       (OBS-293): it fires exactly when the situation it describes changes.
#
#   (2) THE ENUM HAS ONE HOME. `kind` is a CLOSED set, and a closed set with two copies is the
#       T-322 defect — the two copies diverge and neither is wrong on its own terms. Asserted to
#       be defined exactly once across the tree.
#
#   (3) THE EDITOR BOTH READS AND WRITES IT. An attribute imported but not emitted is dropped on
#       the first save, which is worse than absent because it survives review and vanishes in use
#       — the editor's own comment at the read site says so. Import-only is therefore a failure,
#       not a partial pass.
VALIDATOR = "tools/validate-workflow.py"
RE_ANY_FENCE = re.compile(r"```conformance-([a-z0-9-]+)", re.M)
EXPECTED_FENCES = {"governance-meta-keys"}
RE_KIND_ENUM = re.compile(r"^WORKFLOW_KINDS\s*=\s*\{([^}]*)\}", re.M)
EXPECTED_KINDS = {"documentation", "work-plan"}
# Anchored on aefMetaEl, NOT on getAttribute('kind') alone. The editor calls getAttribute('kind')
# three times and TWO of them are on eventDefEl — a different element entirely. A check matching
# those would stay green with workflowMeta/@kind removed, which is precisely the false green this
# case exists to close.
RE_EDITOR_KIND_READ = re.compile(r"aefMetaEl\?\.getAttribute\('kind'\)")
RE_EDITOR_KIND_WRITE = re.compile(r"kind=\"\$\{escAttr\(wm\.kind\)\}\"")


def standard_fences(text):
    """Every ```conformance-<name> fence the standard declares."""
    return set(RE_ANY_FENCE.findall(text))


def kind_enum_definitions(validator_text):
    """The WORKFLOW_KINDS definitions found. A list, so a SECOND copy is visible."""
    out = []
    for body in RE_KIND_ENUM.findall(validator_text):
        out.append({v.strip().strip("\"'") for v in body.split(",") if v.strip()})
    return out


def check_document_kind(standard_text, validator_text, editor_text):
    """Return a list of problem strings; empty means conformant."""
    problems = []

    fences = standard_fences(standard_text)
    unexpected = sorted(fences - EXPECTED_FENCES)
    if unexpected:
        problems.append(
            "the standard declares conformance fence(s) this suite does not enforce: %s — a fence "
            "in the standard that no test reads is exactly the standard/implementation drift this "
            "suite exists to prevent. Wire it in here rather than leaving it unenforced."
            % ", ".join(unexpected))
    missing_fences = sorted(EXPECTED_FENCES - fences)
    if missing_fences:
        problems.append(
            "expected conformance fence(s) absent from the standard: %s" % ", ".join(missing_fences))

    defs = kind_enum_definitions(validator_text)
    if not defs:
        problems.append(
            "no WORKFLOW_KINDS definition found in %s — the closed enum for "
            "aef:workflowMeta/@kind is the subject of this check; its absence is a FAILURE, not a "
            "skip" % VALIDATOR)
    elif len(defs) > 1:
        problems.append(
            "WORKFLOW_KINDS is defined %d times in %s — a closed set with two copies is the T-322 "
            "defect: the copies diverge and neither is wrong on its own terms"
            % (len(defs), VALIDATOR))
    elif defs[0] != EXPECTED_KINDS:
        problems.append(
            "WORKFLOW_KINDS is %s, expected %s — T-213's ratified enum is closed; changing it is a "
            "contract change, not an edit" % (sorted(defs[0]), sorted(EXPECTED_KINDS)))

    if not RE_EDITOR_KIND_READ.search(editor_text):
        problems.append(
            "the editor does not read aef:workflowMeta/@kind off aefMetaEl (%s)" % EDITOR)
    if not RE_EDITOR_KIND_WRITE.search(editor_text):
        problems.append(
            "the editor does not WRITE aef:workflowMeta/@kind (%s) — an attribute imported but not "
            "emitted is dropped on the first save, which is worse than absent because it survives "
            "review and vanishes in use" % EDITOR)

    return problems


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

    # ── T-875 document-level controls ─────────────────────────────────────────────────────────
    # Each check gets BOTH legs: a conformant input that must produce no problem, and a broken
    # input that must produce one. A check exercised only on good input cannot be shown to fail,
    # and a check that cannot fail is not a check (PL-328).
    good_std = "```conformance-governance-meta-keys\nhorizon\n```"
    good_val = 'WORKFLOW_KINDS = {"documentation", "work-plan"}\n'
    good_ed = ("kind: aefMetaEl?.getAttribute('kind') || null,\n"
               'wmAttrs.push(`kind="${escAttr(wm.kind)}"`);\n')
    assert check_document_kind(good_std, good_val, good_ed) == [], \
        "selftest: conformant document-level input flagged: %r" % check_document_kind(good_std, good_val, good_ed)

    # An unenforced new fence in the standard must be caught.
    p = check_document_kind(good_std + "\n```conformance-document-meta-attributes\nkind\n```",
                            good_val, good_ed)
    assert any("does not enforce" in x for x in p), "selftest: new fence not flagged: %r" % p
    # The expected fence going missing must be caught.
    p = check_document_kind("no fences at all", good_val, good_ed)
    assert any("absent from the standard" in x for x in p), "selftest: missing fence not flagged: %r" % p
    # A SECOND copy of the closed enum must be caught (T-322).
    p = check_document_kind(good_std, good_val + good_val, good_ed)
    assert any("defined 2 times" in x for x in p), "selftest: duplicate enum not flagged: %r" % p
    # The enum having no definition at all must be caught.
    p = check_document_kind(good_std, "nothing here", good_ed)
    assert any("no WORKFLOW_KINDS definition" in x for x in p), "selftest: absent enum not flagged: %r" % p
    # A widened enum must be caught — the set is closed.
    p = check_document_kind(good_std, 'WORKFLOW_KINDS = {"documentation", "work-plan", "sketch"}\n',
                            good_ed)
    assert any("expected" in x and "sketch" in x for x in p), "selftest: widened enum not flagged: %r" % p
    # IMPORT-ONLY must be caught: reads kind, never writes it.
    p = check_document_kind(good_std, good_val, "kind: aefMetaEl?.getAttribute('kind') || null,\n")
    assert any("does not WRITE" in x for x in p), "selftest: import-only not flagged: %r" % p
    # And the eventDefEl decoy must NOT satisfy the read leg — this is the false green the
    # aefMetaEl anchor exists to prevent, so it is asserted rather than assumed.
    p = check_document_kind(good_std, good_val,
                            "const kind = eventDefEl.getAttribute('kind') || '';\n"
                            'wmAttrs.push(`kind="${escAttr(wm.kind)}"`);\n')
    assert any("does not read" in x for x in p), "selftest: eventDefEl decoy satisfied the read leg: %r" % p


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

    # T-875: the document level. Reported separately from the node-level result because the two
    # rest on different guarantees — the node level on a frozen fence in the standard, the
    # document level on the standard having no such fence and the implementations agreeing
    # directly. Collapsing them into one OK line would let a reader believe the standard covers
    # `kind`, which it does not.
    doc_problems = check_document_kind(
        _read(STANDARD), _read(VALIDATOR), _read(EDITOR))
    if doc_problems:
        sys.stderr.write("DOCUMENT-LEVEL CONFORMANCE (T-875, aef:workflowMeta/@kind):\n")
        for p in doc_problems:
            sys.stderr.write("  - %s\n" % p)
        return 1

    print("OK: all %d frozen governance meta-keys [%s] present in both editor metaKeys and bridge META_KEYS"
          % (len(frozen), ", ".join(frozen)))
    print("OK: document-level aef:workflowMeta/@kind — closed enum %s defined once in %s, "
          "read AND written by the editor. NOTE: the standard has NO document-level conformance "
          "class (T-875 finding); this is enforced implementation-to-implementation, and a new "
          "conformance fence in the standard will fail this check until it is wired in."
          % (sorted(EXPECTED_KINDS), VALIDATOR))
    return 0


if __name__ == "__main__":
    sys.exit(main())
