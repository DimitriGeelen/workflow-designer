#!/usr/bin/env python3
"""test_editor_bridge_structured_parity — the editor and the bridge handle the
SAME set of structured aef keys, on both the import and export sides (T-063).

Fifth sibling in the editor↔bridge seam-guard family (namespace: T-044; shape:
T-053; coverage: T-059; meta-parity: T-060; structured: this).

T-063 gave the five structured-valued aef keys — emits, compensates (list) and
aggregation, multiInstance, timer (dict) — dedicated child elements instead of
the scalar <aef:meta> channel that silently dropped them. Unlike scalar
META_KEYS (guarded by the meta-parity test) these need matching read+write logic
on BOTH sides; a key added to one side and forgotten on the other reopens the
G-002 JS↔Python drift the whole family exists to prevent.

Invariant (static, code-coupled by design — breaks loudly on a one-sided edit):
  bridge STRUCTURED_LIST_KEYS  == editor export list-keys == editor import list-keys
  bridge STRUCTURED_DICT_KEYS  == editor dict-keys (each `for (const key of [...])`)

Pure stdlib. Exit 0 = parity holds. Exit 1 = drift. Exit 2 = self-test failed.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRIDGE = os.path.join(ROOT, "tools", "yaml-to-bpmn.py")
EDITOR = os.path.join(ROOT, "src", "aef-workflow-designer.html")


def bridge_structured():
    """(list_keys, dict_keys) the bridge emits as dedicated structured elements."""
    text = open(BRIDGE, encoding="utf-8").read()
    m = re.search(r"STRUCTURED_LIST_KEYS\s*=\s*\{(.*?)\}", text, re.S)
    list_keys = set(re.findall(r'"([A-Za-z]+)"\s*:', m.group(1))) if m else set()
    m = re.search(r"STRUCTURED_DICT_KEYS\s*=\s*\((.*?)\)", text, re.S)
    dict_keys = set(re.findall(r'"([A-Za-z]+)"', m.group(1))) if m else set()
    return list_keys, dict_keys


def editor_structured():
    """(export_list, import_list, [dict_sets]) parsed from the editor's T-063 blocks."""
    text = open(EDITOR, encoding="utf-8").read()
    # export: const structList = { emits: ['emit','value'], compensates: [...] };
    m = re.search(r"structList\s*=\s*\{(.*?)\}", text, re.S)
    export_list = set(re.findall(r"(\w+):\s*\[", m.group(1))) if m else set()
    # import: for (const [key, item, attr] of [['emits','emit','value'], ...]) {
    m = re.search(r"for \(const \[key, item, attr\] of \[(.*?)\]\s*\)\s*\{", text, re.S)
    import_list = set(re.findall(r"\['([A-Za-z]+)'", m.group(1))) if m else set()
    # dict-valued: every `for (const key of ['aggregation', ...])` (export + import)
    dict_sets = [set(re.findall(r"'([A-Za-z]+)'", body))
                 for body in re.findall(r"for \(const key of \[([^\]]+)\]\)", text)]
    return export_list, import_list, dict_sets


def check():
    fails = []
    b_list, b_dict = bridge_structured()
    e_export, e_import, e_dicts = editor_structured()
    if not b_list or not b_dict:
        return ["could not extract bridge STRUCTURED_LIST_KEYS/STRUCTURED_DICT_KEYS — scan pattern wrong?"]
    if e_export != b_list:
        fails.append("editor EXPORT list-keys %s != bridge STRUCTURED_LIST_KEYS %s" % (sorted(e_export), sorted(b_list)))
    if e_import != b_list:
        fails.append("editor IMPORT list-keys %s != bridge STRUCTURED_LIST_KEYS %s" % (sorted(e_import), sorted(b_list)))
    if not e_dicts:
        fails.append("no `for (const key of [...])` dict-loops found in editor — import/export drifted?")
    for i, ds in enumerate(e_dicts):
        if ds != b_dict:
            fails.append("editor dict-loop #%d %s != bridge STRUCTURED_DICT_KEYS %s" % (i + 1, sorted(ds), sorted(b_dict)))
    return fails


def _selftest():
    b_list, b_dict = bridge_structured()
    assert b_list == {"emits", "compensates"}, "bridge list-keys drifted: %s" % sorted(b_list)
    assert b_dict == {"aggregation", "multiInstance", "timer"}, "bridge dict-keys drifted: %s" % sorted(b_dict)
    e_export, e_import, e_dicts = editor_structured()
    assert e_export and e_import and e_dicts, "editor extraction returned empty — patterns wrong?"


def main():
    try:
        _selftest()
    except AssertionError as exc:
        sys.stderr.write("SELFTEST FAIL: %s\n" % exc)
        return 2
    fails = check()
    if fails:
        sys.stderr.write("EDITOR↔BRIDGE STRUCTURED-KEY PARITY VIOLATED (T-063):\n")
        for f in fails:
            sys.stderr.write("  - %s\n" % f)
        return 1
    print("OK: editor and bridge agree on structured aef keys "
          "(list: emits/compensates; dict: aggregation/multiInstance/timer)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
