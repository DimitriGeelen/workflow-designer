#!/usr/bin/env python3
"""_t573-one-vocabulary-teeth.py — the "exactly one structured-list vocabulary" check has teeth.

T-573 hoisted the emits/compensates wrapper-item-attribute triple out of buildBpmnXml and
the import reader into one module-scope `STRUCT_LIST_KEYS`, because the properties panel
needed to read it and a THIRD copy is the T-322 defect. That turned
tests/test_editor_bridge_structured_parity.py's old check ("the editor's two copies each
agree with the bridge") into a stronger one ("the editor holds exactly one copy").

A count assertion is worthless unless it can go wrong. This drives the parity guard's own
extraction against MUTATED copies of the editor and requires it to fail on each:

  leg 1  the real tree            -> copies == 1, check() clean
  leg 2  a second `structList = {`-> copies == 2, and check() SAYS SO
  leg 3  the inline import array back -> copies == 2, and check() says so
  leg 4  STRUCT_LIST_KEYS renamed -> copies == 0 (blind), and check() says so — because
         "the guard cannot find its subject" must not read the same as "all is well"
  leg 5  a key dropped from the constant -> the bridge-parity arm fails, proving leg 1's
         green is about agreement and not merely about the count

Mutations are applied to a TEMP COPY; the tree is never written to. Exit 0 all legs pass.
"""
import importlib.util
import os
import re
import shutil
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GUARD = os.path.join(ROOT, "tests", "test_editor_bridge_structured_parity.py")
EDITOR = os.path.join(ROOT, "src", "aef-workflow-designer.html")


def load_guard(editor_path):
    """Fresh module instance with EDITOR repointed — never the real file for a mutant."""
    spec = importlib.util.spec_from_file_location("_parity_probe", GUARD)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.EDITOR = editor_path
    return mod


def with_mutation(fn):
    """Copy the editor, apply fn(text)->text, return the temp path."""
    d = tempfile.mkdtemp(prefix="t573-vocab-")
    p = os.path.join(d, "designer.html")
    text = open(EDITOR, encoding="utf-8").read()
    open(p, "w", encoding="utf-8").write(fn(text))
    return p, d


def main():
    npass = nfail = 0
    def report(ok, name, detail):
        nonlocal npass, nfail
        npass, nfail = (npass + 1, nfail) if ok else (npass, nfail + 1)
        print("  %s %-28s %s" % ("ok  " if ok else "FAIL", name, detail))

    print("=== T-573: the one-vocabulary check, against mutants ===")

    # leg 1 — the real tree
    g = load_guard(EDITOR)
    keys, copies, _ = g.editor_structured()
    fails = g.check()
    report(copies == 1 and not fails and keys == {"emits", "compensates"},
           "real-tree-clean",
           "copies=%d keys=%s check()=%s" % (copies, sorted(keys), fails or "clean"))

    # leg 2 — a second export-style copy
    p, d = with_mutation(lambda t: t + "\n<script>const structList = { emits: ['emits','emit','value'] };</script>\n")
    try:
        g = load_guard(p); _, copies, _ = g.editor_structured(); fails = g.check()
        hit = any("cop(ies)" in f for f in fails)
        report(copies == 2 and hit, "second-export-copy-caught",
               "copies=%d, guard %s" % (copies, "names it" if hit else "SAID NOTHING"))
    finally:
        shutil.rmtree(d, ignore_errors=True)

    # leg 3 — the inline import array put back
    p, d = with_mutation(lambda t: t + "\n<script>for (const [key, item, attr] of [['emits','emit','value']]) {}</script>\n")
    try:
        g = load_guard(p); _, copies, _ = g.editor_structured(); fails = g.check()
        hit = any("cop(ies)" in f for f in fails)
        report(copies == 2 and hit, "second-import-copy-caught",
               "copies=%d, guard %s" % (copies, "names it" if hit else "SAID NOTHING"))
    finally:
        shutil.rmtree(d, ignore_errors=True)

    # leg 4 — the constant renamed away. The guard must report BLINDNESS, not health.
    p, d = with_mutation(lambda t: t.replace("const STRUCT_LIST_KEYS = {", "const STRUCT_LIST_RENAMED = {", 1))
    try:
        g = load_guard(p); keys, copies, _ = g.editor_structured(); fails = g.check()
        hit = any("cop(ies)" in f for f in fails)
        report(copies == 0 and hit and not keys, "rename-reads-as-blind-not-clean",
               "copies=%d keys=%s, guard %s" % (copies, sorted(keys), "names it" if hit else "SAID NOTHING"))
    finally:
        shutil.rmtree(d, ignore_errors=True)

    # leg 5 — a key dropped. Proves leg 1 is about AGREEMENT with the bridge, not the count.
    p, d = with_mutation(lambda t: re.sub(r"\n  compensates: \['compensates', 'compensate', 'ref'\],", "", t, count=1))
    try:
        g = load_guard(p); keys, copies, _ = g.editor_structured(); fails = g.check()
        hit = any("STRUCT_LIST_KEYS" in f and "bridge" in f for f in fails)
        report(copies == 1 and hit and keys == {"emits"}, "dropped-key-caught",
               "copies=%d keys=%s, guard %s" % (copies, sorted(keys), "names the disagreement" if hit else "SAID NOTHING"))
    finally:
        shutil.rmtree(d, ignore_errors=True)

    print("\nPASS=%d FAIL=%d" % (npass, nfail))
    return 0 if nfail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
