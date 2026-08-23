#!/usr/bin/env python3
"""_t423-additive-export-teeth.py — prove _t423-additive-export-guard.py can go RED.

The guard returned PASS on 24/24 pairs on its first run. That is equally consistent with
"the exporter is additive" and with "the comparison does not work", and the second reading
is not paranoid: this guard's whole body is one equality, and an equality between two things
derived by the same function is the easiest thing in the world to make trivially true.

These teeth copy the real source corpus and a real export into a temp tree, damage the
EXPORT, and require the guard to notice. The source side is never touched, because the
guard's claim is about what export does to a document.

WHAT EACH CASE IS FOR, since a list of thirteen mutations reads as thoroughness whether or
not it is:

  1-3   THE THREE EXERCISED INTENT EXTENSIONS, one case each. aef:anchors deleted,
        aef:routingHint deleted, aef:loopDetour's coordinate altered. These are the AC's
        actual subject. Three separate cases rather than one, because a guard can be blind
        to a whole element type while catching another — and the AC names them individually.

  4     REORDERING with nothing added or removed. The AC says "removed OR REORDERED" and a
        set comparison satisfies that sentence while ignoring half of it. This case is the
        only thing standing between the guard and that mistake; it is the reason the guard
        compares an ordered sequence.

  5     `targetNamespace` REMOVED from the root. The guard permits two named additions on the
        root, and the tempting simplification was "ignore root attributes". This case is what
        makes that simplification fail: targetNamespace is the attribute AEF's reader keys
        on, and the loose version would have shipped green while it vanished.

  6     AN UNEXPECTED ATTRIBUTE on the root — the other half of case 5. The allow-list must
        admit exactly two names, not "anything on the root".

  7-8   DI DAMAGED, and both must stay GREEN. Deleting a BPMNShape and adding a bogus DI
        element are NOT this guard's business — the carrier-agreement guard owns DI
        correctness. A harness where every mutation reddens has stopped testing scope.
        These two are what keep the guard from silently becoming a second, worse copy of a
        gate that already exists.

  9     POPULATION CHANGE: an export file removed. A guard that compares only the pairs it
        finds will happily report PASS on the survivors, which is coverage evaporating with
        no verdict change — the failure mode _t423-carrier-agreement-cdp.mjs was given a
        fatal for.

  10-12 ANTI-VACUITY: unparseable export, empty export dir, missing dir. Each must REFUSE
        (rc 2), never pass. An unreadable document is not an unchanged one.

  13    THE ALLOW-LIST CONTROL: adding `exporterVersion` must stay GREEN, because the guard
        names it as permitted. If this reddens, the allow-list is not doing its job and every
        real export would fail.

Exit 0 = control green and all cases landed on their own verdict.
     1 = a mutant survived, or the control was not green.
     2 = a prerequisite is missing, or a mutation was a no-op.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
GUARD = os.path.join(HERE, "_t423-additive-export-guard.py")
SRC_CORPUS = os.environ.get("T423_CORPUS", os.path.join(REPO, "examples", "aef-processes", "rendered"))
# The export side must be a REAL export. Produced by the cdp probe; this env var is how the
# suite hands it over, and how a developer re-runs the teeth without a browser.
EXPORT_DIR = os.environ.get("T423_EXPORT_DIR", "")

results = []


def run_guard(src, exp):
    p = subprocess.run(["python3", GUARD, src, exp], capture_output=True, text=True, timeout=300)
    return p.returncode, (p.stdout + p.stderr)


def case(name, mutate, expect_rc, expect_in=None):
    """A mutation that leaves the tree byte-identical is a NO-OP MUTANT: it reports "the
    mutant did not die", which is indistinguishable from a guard that never worked. Refused
    rather than run — the same detector that caught a silent no-op in the carrier teeth and
    in _t361's."""
    d = tempfile.mkdtemp(prefix="t423add-teeth-")
    try:
        s, e = os.path.join(d, "src"), os.path.join(d, "exp")
        shutil.copytree(SRC_CORPUS, s)
        shutil.copytree(EXPORT_DIR, e)
        before = _fingerprint(e)
        try:
            mutate(e)
        except Exception as ex:
            results.append((name, "ANCHOR GONE", str(ex)))
            return
        if _fingerprint(e) == before:
            results.append((name, "NO-OP", "mutation changed nothing — re-point this case"))
            return
        rc, log = run_guard(s, e)
        ok = rc == expect_rc and (expect_in is None or expect_in in log)
        detail = f"expected rc={expect_rc}" + (f" and {expect_in!r}" if expect_in else "") + f", got rc={rc}"
        if not ok:
            detail += "\n      " + log.strip().replace("\n", "\n      ")[:900]
        else:
            m = re.search(r"^\s*compared .*$", log, re.M)
            if m:
                detail += " — " + m.group(0).strip()
        results.append((name, "ok" if ok else "SURVIVED", detail))
    finally:
        shutil.rmtree(d, ignore_errors=True)


def _fingerprint(d):
    out = []
    for f in sorted(os.listdir(d)):
        p = os.path.join(d, f)
        out.append((f, os.path.getsize(p), open(p, "rb").read()))
    return out


def _files(d):
    return sorted(f for f in os.listdir(d) if f.endswith(".bpmn"))


def _edit_first_containing(d, needle, fn):
    """Apply `fn` to the first export document containing `needle`."""
    for f in _files(d):
        p = os.path.join(d, f)
        t = open(p, encoding="utf-8").read()
        if needle in t:
            out = fn(t)
            if out != t:
                open(p, "w", encoding="utf-8").write(out)
                return f
    raise RuntimeError(f"no export document contains {needle!r} — re-point this case")


def drop_anchors(d):
    _edit_first_containing(d, "<aef:anchors", lambda t: re.sub(r"\s*<aef:anchors[^>]*/>", "", t, count=1))


def drop_routinghint(d):
    _edit_first_containing(d, "<aef:routingHint", lambda t: re.sub(r"\s*<aef:routingHint[^>]*/>", "", t, count=1))


def alter_loopdetour(d):
    _edit_first_containing(d, "<aef:loopDetour",
                           lambda t: re.sub(r'(<aef:loopDetour y=")([\d.]+)(")',
                                            lambda m: m.group(1) + "1.5" + m.group(3), t, count=1))


def reorder_two_siblings(d):
    """Swap two consecutive <bpmn:sequenceFlow> BLOCKS: nothing added, nothing removed.

    The first draft of this case matched a self-closing `<bpmn:sequenceFlow .../>` and found
    none — exports give the element `<bpmn:extensionElements>` children, so every one of the
    13 is a block with a closing tag. It reported ANCHOR GONE rather than passing, which is
    the whole point of distinguishing the two: a case that cannot find what it means to
    damage must say so, because "the guard did not complain" is what a no-op mutant and a
    broken guard both look like.
    """
    BLOCK = r"[ \t]*<bpmn:sequenceFlow\b.*?</bpmn:sequenceFlow>\n"

    def fn(t):
        m = list(re.finditer(BLOCK, t, flags=re.S))
        if len(m) < 2:
            return t
        for i in range(len(m) - 1):
            a, b = m[i], m[i + 1]
            gap = t[a.end():b.start()]
            if gap.strip() == "":          # consecutive siblings, blank lines allowed
                return t[:a.start()] + b.group(0) + gap + a.group(0) + t[b.end():]
        return t

    _edit_first_containing(d, "<bpmn:sequenceFlow", fn)


def drop_target_namespace(d):
    _edit_first_containing(d, "targetNamespace=",
                           lambda t: re.sub(r'\s*targetNamespace="[^"]*"', "", t, count=1))


def add_unexpected_root_attr(d):
    _edit_first_containing(d, "<bpmn:definitions",
                           lambda t: t.replace("<bpmn:definitions", '<bpmn:definitions sneaked="1"', 1))


def drop_a_bpmnshape(d):
    _edit_first_containing(d, "<bpmndi:BPMNShape",
                           lambda t: re.sub(r"\s*<bpmndi:BPMNShape.*?</bpmndi:BPMNShape>", "", t,
                                            count=1, flags=re.S))


def add_bogus_di(d):
    _edit_first_containing(d, "</bpmndi:BPMNPlane>",
                           lambda t: t.replace("</bpmndi:BPMNPlane>",
                                               '  <bpmndi:BPMNShape id="bogus"/>\n</bpmndi:BPMNPlane>', 1))


def remove_one_export(d):
    os.remove(os.path.join(d, _files(d)[0]))


def corrupt_one_export(d):
    p = os.path.join(d, _files(d)[0])
    open(p, "a", encoding="utf-8").write("<unclosed>")


def empty_the_export(d):
    for f in _files(d):
        os.remove(os.path.join(d, f))


def add_exporter_version(d):
    _edit_first_containing(d, "<bpmn:definitions",
                           lambda t: t.replace("<bpmn:definitions", '<bpmn:definitions exporterVersion="9.9"', 1))


def main():
    if not EXPORT_DIR or not os.path.isdir(EXPORT_DIR):
        print("REFUSE — T423_EXPORT_DIR must point at a directory of REAL exports.\n"
              "        These teeth damage an export and require the guard to notice; running\n"
              "        them against a hand-written stand-in would test the stand-in.")
        return 2
    for p in (GUARD, SRC_CORPUS):
        if not os.path.exists(p):
            print("REFUSE — missing: " + p.replace(REPO + "/", ""))
            return 2

    rc, log = run_guard(SRC_CORPUS, EXPORT_DIR)
    if rc != 0:
        print(f"FAIL — CONTROL is not green (rc={rc}) on the undamaged export:\n{log}")
        return 1
    m = re.search(r"^\s*compared .*$", log, re.M)
    print(f"  control: undamaged export -> PASS  ({m.group(0).strip() if m else ''})")

    case("an aef:anchors element is deleted from an export", drop_anchors, 1, "diverges")
    case("an aef:routingHint element is deleted from an export", drop_routinghint, 1, "diverges")
    case("an aef:loopDetour coordinate is altered", alter_loopdetour, 1, "diverges")
    case("two sibling sequenceFlows are SWAPPED — nothing added or removed", reorder_two_siblings, 1, "diverges")
    case("targetNamespace is removed from the root", drop_target_namespace, 1, "diverges")
    case("an unexpected attribute appears on the root", add_unexpected_root_attr, 1, "diverges")
    case("a bpmndi:BPMNShape is deleted — NOT this guard's subject, MUST STAY GREEN", drop_a_bpmnshape, 0)
    case("a bogus DI element is added — MUST STAY GREEN", add_bogus_di, 0)
    case("one export document disappears", remove_one_export, 1, "did not export")
    case("one export document becomes unparseable — must REFUSE, not pass", corrupt_one_export, 2, "not an unchanged one")
    case("the export directory is emptied — must REFUSE", empty_the_export, 2, "Nothing was compared")
    case("exporterVersion is added — allow-list control, MUST STAY GREEN", add_exporter_version, 0)

    bad = [r for r in results if r[1] != "ok"]
    for name, verdict, detail in results:
        print(f"  [{'PASS' if verdict == 'ok' else verdict}] {name}\n      {detail}")
    if bad:
        print(f"\nTEETH FAIL — {len(bad)} of {len(results)} case(s) did not behave as required")
        return 1
    print(f"\nTEETH PASS — control green, {len(results)} cases each landing on their own verdict")
    return 0


if __name__ == "__main__":
    sys.exit(main())
