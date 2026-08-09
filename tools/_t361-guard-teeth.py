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


def ledger_members(n):
    """First n (sha, relpath) entries of the real ledger, in file order."""
    out = []
    with open(os.path.join(ROOT, "tests", "data", "t361-legacy-di-trailer.txt"),
              encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            sha, rel = line.split(None, 1)
            out.append((sha, rel))
            if len(out) == n:
                break
    if len(out) < n:
        raise RuntimeError(f"ledger has fewer than {n} members")
    return out


def build_tree(tmp):
    """Minimal tree the guard can walk.

    Both identity generations must be represented (T-399): the FORWARD arm (the
    exported witness, carrying the standard `exporter` attribute) and the HISTORIC
    arm (documents whose path is in the legacy ledger). The guard's anti-vacuity
    checks assert each arm resolves something, so a tree carrying only one of them
    fails the CONTROL — as this harness demonstrated the first time it was run
    against the repair, which is the harness doing its job on the fix itself.

    TWO ledgered documents are materialised, not one, so that the case which
    tampers with the first still leaves the historic arm resolving.
    """
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
    for _sha, rel in ledger_members(2):
        srcp = os.path.join(ROOT, rel)
        if not os.path.exists(srcp):
            raise RuntimeError(f"ledgered document missing from the tree: {rel}")
        dest = os.path.join(tmp, rel)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copy(srcp, dest)
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


# 4 — a NEW exported document carrying a wrong tail must not slip through.
# T-399: it must carry the producer identity our emitter stamps, because that is now
# what puts it in scope. Writing it WITHOUT the attribute would be writing a document
# our designer could not have produced, and the guard correctly ignoring it would
# look like a hole while actually being the fix working.
def _new_bad_doc(tmp):
    p = os.path.join(tmp, "tests", "fixtures", "exported", "sneaky.bpmn")
    open(p, "w", encoding="utf-8").write(
        '<bpmn:definitions exporter="aef-workflow-designer">\n'
        "  <!-- BPMN DI (visual layout) omitted in this demo; "
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


# ── T-399: the identity mechanism itself ────────────────────────────────────
# Scope is now load-bearing. A repair that answers "is this ours?" with "no" for
# everything empties the offender list and turns the whole guard green, and the
# output is indistinguishable from a clean tree. These three break identity rather
# than the trailer, and each must still produce a red.

# 6 — the emitter stops deriving the marker (the T-361 duplicate-literal class,
#     now applied to the field that decides scope)
case("emitter hardcodes the exporter instead of deriving it",
     lambda tmp: edit_src(tmp, lambda b: b.replace(
         'lines.push(`                  exporter="${BPMN_EXPORTER}"`);',
         'lines.push(`                  exporter="aef-workflow-designer"`);')),
     "emitter derives the exporter attribute from BPMN_EXPORTER")


# 7 — THE ANTI-NARROWING CASE. If no document carries producer identity, the guard
#     must say so rather than report a clean tree.
def _strip_witness_identity(tmp):
    p = os.path.join(tmp, "tests", "fixtures", "exported", "t361-trailer-witness.bpmn")
    body = open(p, encoding="utf-8").read()
    open(p, "w", encoding="utf-8").write(
        body.replace('exporter="aef-workflow-designer"\n', ""))


case("no document carries producer identity (net narrowed to nothing)",
     _strip_witness_identity,
     "forward identity arm resolves at least one document")


# 8 — MUTATION TEETH on a GENUINE artifact, not a synthetic one. Case 4 writes a
#     hand-made document; this one takes the real exported witness — bytes that came
#     out of the real editor through a real browser — and gives it the stale trailer.
#     A repair that silenced the false positive by narrowing the net until nothing is
#     caught would leave this green, and would look identical in the suite output.
def _stale_trailer_on_genuine_export(tmp):
    p = os.path.join(tmp, "tests", "fixtures", "exported", "t361-trailer-witness.bpmn")
    body = open(p, encoding="utf-8").read()
    stale = "BPMN DI (visual layout) omitted in this demo; " + FALSE_TAIL
    out = body.replace(
        "BPMN DI (visual layout) omitted; node geometry travels as aef:position",
        stale)
    if out == body:
        raise RuntimeError("witness did not carry the current trailer — nothing mutated")
    open(p, "w", encoding="utf-8").write(out)


case("a GENUINE export of ours is given a stale trailer",
     _stale_trailer_on_genuine_export,
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

    # RECIPROCAL CONTROL (T-399). The bug was a FALSE POSITIVE: a peer's document,
    # authored to our own mapping standard, reported as an unaccounted export of
    # ours. Every case above proves the guard can still go red; this proves it stopped
    # going red about somebody else's file — the direction the repair was for.
    #
    # It is placed in the tree at a DIFFERENT path than the real one, so a pass here
    # cannot be a path skip in disguise: the only thing keeping it out of the offender
    # list is that it carries no producer identity of ours and no ledger entry.
    with tempfile.TemporaryDirectory() as tmp:
        build_tree(tmp)
        peer_src = os.path.join(ROOT, "tests", "fixtures", "third-party",
                                "aef-draft-inception-readiness-v2.bpmn")
        dest_dir = os.path.join(tmp, "vendored", "somewhere-else")
        os.makedirs(dest_dir)
        shutil.copy(peer_src, os.path.join(dest_dir, "peer-document.bpmn"))
        code_r, out_r = run_guard(tmp)
    named = "peer-document.bpmn" in out_r
    ok_r = code_r == 0 and not named
    print(f"{'RECIPROC':<10} {'ok ' if ok_r else 'BAD'} a peer document sharing our trailer prefix is NOT reported")
    if not ok_r:
        fails.append(("peer document was reported as one of ours"
                      + (" (named in output)" if named else ""), out_r))

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
    print("             the sha-pinned legacy exemption proven able to fail;")
    print("             a peer document sharing our trailer prefix proven NOT reported.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
