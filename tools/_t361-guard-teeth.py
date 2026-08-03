#!/usr/bin/env python3
"""
_t361-guard-teeth.py — prove tests/test_emitted_comment_claims.py can FAIL.

Each case breaks exactly one thing in a COPY of the tree and asserts the guard
goes red on the check that owns it. A guard read but never broken is a guard
whose teeth are a matter of opinion.

The case that matters most is the last one: the legacy ledger is an EXEMPTION,
and an exemption that cannot fail for existing wrongly is just a silence with a
filename. Pinning it to sha rather than path is what makes it falsifiable — so
that has to be demonstrated, not argued.

Run: python3 tools/_t361-guard-teeth.py
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GUARD = os.path.join(ROOT, "tests", "test_emitted_comment_claims.py")

FALSE_TAIL = "AEF generates it from node coordinates"


def build_tree(tmp):
    """Minimal tree the guard can walk: src + ledger + the exported witness."""
    os.makedirs(os.path.join(tmp, "src"))
    os.makedirs(os.path.join(tmp, "tests", "data"))
    os.makedirs(os.path.join(tmp, "tests", "fixtures", "exported"))
    shutil.copy(os.path.join(ROOT, "src", "aef-workflow-designer.html"),
                os.path.join(tmp, "src", "aef-workflow-designer.html"))
    shutil.copy(os.path.join(ROOT, "tests", "data", "t361-legacy-di-trailer.txt"),
                os.path.join(tmp, "tests", "data", "t361-legacy-di-trailer.txt"))
    wit = os.path.join(ROOT, "tests", "fixtures", "exported", "t361-trailer-witness.bpmn")
    if os.path.exists(wit):
        shutil.copy(wit, os.path.join(tmp, "tests", "fixtures", "exported",
                                      "t361-trailer-witness.bpmn"))
    return tmp


def run_guard(tmp):
    env = dict(os.environ)
    env["T361_ROOT"] = tmp
    env["T361_SRC"] = os.path.join(tmp, "src", "aef-workflow-designer.html")
    env["T361_LEDGER"] = os.path.join(tmp, "tests", "data", "t361-legacy-di-trailer.txt")
    p = subprocess.run([sys.executable, GUARD], capture_output=True, text=True, env=env)
    return p.returncode, p.stdout


def edit_src(tmp, fn):
    path = os.path.join(tmp, "src", "aef-workflow-designer.html")
    body = open(path, encoding="utf-8").read()
    open(path, "w", encoding="utf-8").write(fn(body))


CASES = []


def case(label, mutate, expect_marker):
    CASES.append((label, mutate, expect_marker))


# 1 — put the false attribution back
case("the false attribution is restored in DI_TRAILER",
     lambda tmp: edit_src(tmp, lambda b: b.replace(
         "const DI_TRAILER = `${DI_TRAILER_PREFIX}; node geometry travels as aef:position`;",
         "const DI_TRAILER = `${DI_TRAILER_PREFIX} in this demo; " + FALSE_TAIL + "`;")),
     "trailer attributes no action to a named external party")

# 2 — emitter goes back to a hardcoded duplicate (how this survived two months)
case("emitter duplicates the literal instead of deriving it",
     lambda tmp: edit_src(tmp, lambda b: b.replace(
         "lines.push(`  <!-- ${DI_TRAILER} -->`);",
         "lines.push(`  <!-- BPMN DI (visual layout) omitted; hand-written copy -->`);")),
     "emitter derives the trailer from DI_TRAILER rather than duplicating it")

# 3 — compatibility prefix broken (would orphan every prior document's reader)
case("trailer no longer starts with the compatibility prefix",
     lambda tmp: edit_src(tmp, lambda b: b.replace(
         "const DI_TRAILER = `${DI_TRAILER_PREFIX}; node geometry travels as aef:position`;",
         "const DI_TRAILER = `Layout omitted; node geometry travels as aef:position`;")),
     "trailer preserves the compatibility prefix")


# 4 — a NEW exported document carrying a wrong tail must not slip through
def _new_bad_doc(tmp):
    p = os.path.join(tmp, "tests", "fixtures", "exported", "sneaky.bpmn")
    open(p, "w", encoding="utf-8").write(
        "<bpmn:definitions>\n  <!-- BPMN DI (visual layout) omitted in this demo; "
        + FALSE_TAIL + " -->\n</bpmn:definitions>\n")


case("a newly exported document carries the false tail",
     _new_bad_doc,
     "every exported document carries the approved trailer or is a pinned legacy record")


# 5 — THE EXEMPTION ITSELF MUST BE ABLE TO FAIL.
# A path-keyed allowlist would let a re-export of a listed file stay wrong forever.
# Keying on sha means changed bytes drop out of the ledger and face the live rule.
def _tamper_ledger_member(tmp):
    ledger = os.path.join(tmp, "tests", "data", "t361-legacy-di-trailer.txt")
    rel = None
    for line in open(ledger, encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#"):
            rel = line.split(None, 1)[1]
            break
    if rel is None:
        raise RuntimeError("ledger has no members")
    dest = os.path.join(tmp, rel)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    # A re-export of a ledgered document: same path, different bytes, still wrong.
    open(dest, "w", encoding="utf-8").write(
        "<bpmn:definitions>\n  <!-- BPMN DI (visual layout) omitted in this demo; "
        + FALSE_TAIL + " -->\n  <!-- re-exported, bytes changed -->\n</bpmn:definitions>\n")


case("a LEDGERED document is re-exported with changed bytes and a wrong tail",
     _tamper_ledger_member,
     "every exported document carries the approved trailer or is a pinned legacy record")


def main():
    # Control: the unmutated tree must PASS. Without this, every red below could
    # be a red for some unrelated reason and the whole harness would prove nothing.
    with tempfile.TemporaryDirectory() as tmp:
        build_tree(tmp)
        code, out = run_guard(tmp)
    print(f"{'CONTROL':<10} exit={code}  (want 0)")
    fails = []
    if code != 0:
        fails.append(("CONTROL did not pass on an unmutated tree", out))

    for label, mutate, marker in CASES:
        with tempfile.TemporaryDirectory() as tmp:
            build_tree(tmp)
            mutate(tmp)
            code, out = run_guard(tmp)
        red_on_right_check = any(l.startswith("  FAIL") and marker in l
                                 for l in out.splitlines())
        ok = code != 0 and red_on_right_check
        print(f"{'RED' if code else 'green':<10} {'ok ' if ok else 'BAD'} {label}")
        if not ok:
            fails.append((label, out))

    print()
    if fails:
        print(f"TEETH FAILED — {len(fails)} case(s):")
        for label, out in fails:
            print(f"  {label}")
            for line in out.splitlines()[:8]:
                print(f"    {line}")
        return 1
    print(f"TEETH PASS — control green, {len(CASES)} mutations each red on their own check;")
    print("             the sha-pinned legacy exemption proven able to fail.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
