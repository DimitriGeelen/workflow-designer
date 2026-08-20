#!/usr/bin/env python3
"""_t570-meta-carriage-teeth.py — does the T-570 probe actually discriminate?

A probe that passes on the fixed source proves nothing on its own: "all legs green" is also
what a probe that asserts nothing produces. Each mutant below is a fix someone would plausibly
ship, and each must redden EXACTLY the legs it breaks and no others. A mutant that reddens
more than its own legs is not discriminating and is reported as a failure, not accepted.

  A — carriage removed; export reverts to the shipping metaKeys.filter one-liner.
      Reddens the four legs that depend on an unlisted key reaching the file. Note that
      `reproduce-drop` must stay GREEN: it asserts the PRE-fix rule loses those keys, which is
      exactly what mutant A restores. A control arm that reddened here would be measuring the
      shipped code rather than the defect.

  D — the NARROW fix: `determinism` and `sideEffect` added to metaKeys, carriage removed.
      This is the tempting patch — it repairs every key the corpus census actually found, and
      it is why the fixture carries `provenance`, which the census does not. D must redden
      carriage and the scalar `emits`, and must LEAVE `carried-escaping` green, because the
      hard-value key is one of the two it whitelisted. That asymmetry with A is the whole
      point: repairing the sample and repairing the mechanism are different, and the teeth
      have to be able to tell them apart.

  B — the shape guard dropped: carriage no longer excludes object/array values.
      Must redden ONLY `structured-untouched`. An ARRAY emits gets stringified into an
      attribute alongside its own structured element — two carriers for one value, which any
      test asking only "did the key survive?" waves through.

  C — `endpoint` removed from the skip set.
      Must redden ONLY `no-double-emit`. The value still round-trips (the element wins on
      re-import), so this is the mutant that a correctness-only test cannot see.

A CONTROL RUN ON UNMUTATED SOURCE COMES FIRST. "every mutant died" is equally satisfied by a
harness that fails on everything (T-560), and this probe drives a real browser, so an
environment fault is a live possibility rather than a theoretical one.

Mutants live in a tmpdir copy. Nothing here writes to the tree.
Exit 0 = control green and each mutant kills exactly its own legs.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
PROBE = os.path.join(ROOT, "tools", "_t570-meta-carriage-cdp.mjs")
LEGS = ("reproduce-drop", "carriage-roundtrip", "carried-escaping", "no-acquisition",
        "no-double-emit", "structured-untouched", "scalar-emits-survives",
        "deterministic-order")

NEW_METAATTRS = ("  const metaAttrs = [...metaKeys.filter(k => aefKeys.includes(k)), ...carriedKeys]\n"
                 "    .map(k => `${k}=\"${escAttr(aef[k])}\"`).join(' ');")
OLD_METAATTRS = ("  const metaAttrs = metaKeys.filter(k => aefKeys.includes(k))"
                 ".map(k => `${k}=\"${escAttr(aef[k])}\"`).join(' ');")
METAKEYS_TAIL = "    'horizon', 'workflowType', 'owner'];"
CARRIED_LINE = ("  const carriedKeys = aefKeys.filter(k => !scalarHandled.has(k) "
                "&& typeof aef[k] !== 'object').sort();")
ENDPOINT_LINE = "    'endpoint', 'contextReads', 'artifactsWrites', 'decisionInput', 'decisionOutputs',"


def run_probe(src_path):
    r = subprocess.run(["node", PROBE, "--src", src_path],
                       capture_output=True, text=True, timeout=600, cwd=ROOT)
    return r.returncode, r.stdout + r.stderr


def verdicts(out):
    v = {}
    for line in out.splitlines():
        m = re.match(r"^(PASS|FAIL)\s+(\S+)\s+—", line)
        if m:
            v[m.group(2)] = m.group(1)
    return {leg: v.get(leg, "MISSING") for leg in LEGS}


def reddened(v):
    return sorted([k for k, s in v.items() if s != "PASS"])


def patch(path, old, new, label):
    s = open(path, encoding="utf-8").read()
    n = s.count(old)
    if n != 1:
        raise SystemExit("mutant %s: anchor occurs %d times, need exactly 1:\n  %r" % (label, n, old[:80]))
    open(path, "w", encoding="utf-8").write(s.replace(old, new))


def main():
    npass = nfail = 0

    def report(ok, name, detail):
        nonlocal npass, nfail
        if ok:
            npass += 1
        else:
            nfail += 1
        print("%s  %s — %s" % ("PASS" if ok else "FAIL", name, detail))

    for p in (SRC, PROBE):
        if not os.path.exists(p):
            print("CANNOT RUN: missing %s" % p)
            return 2

    scratch = tempfile.mkdtemp(prefix="t570-teeth-")
    try:
        rc, out = run_probe(SRC)
        ctl = verdicts(out)
        if rc != 0 or reddened(ctl):
            report(False, "control: unmutated source passes all eight legs",
                   "rc=%d failing=%s" % (rc, reddened(ctl) or "none"))
            print("\n%d passed, %d failed" % (npass, nfail))
            return 1
        report(True, "control: unmutated source passes all eight legs", ", ".join(LEGS))

        # ── A: carriage removed entirely (the shipping code before this task) ──
        a = os.path.join(scratch, "A.html")
        shutil.copyfile(SRC, a)
        patch(a, NEW_METAATTRS, OLD_METAATTRS, "A")
        red = reddened(verdicts(run_probe(a)[1]))
        want = ["carriage-roundtrip", "carried-escaping", "deterministic-order",
                "scalar-emits-survives"]
        report(red == want, "mutant A killed (carriage removed, as shipped)",
               "reddened %s (want %s — reproduce-drop MUST stay green)" % (red, want))

        # ── D: the narrow fix — widen metaKeys by the keys the census found ──
        d = os.path.join(scratch, "D.html")
        shutil.copyfile(SRC, d)
        patch(d, METAKEYS_TAIL,
              "    'horizon', 'workflowType', 'owner', 'determinism', 'sideEffect'];", "D")
        patch(d, NEW_METAATTRS, OLD_METAATTRS, "D2")
        red = reddened(verdicts(run_probe(d)[1]))
        want = ["carriage-roundtrip", "deterministic-order", "scalar-emits-survives"]
        report(red == want, "mutant D killed (metaKeys widened by the census, no carriage)",
               "reddened %s (want %s — carried-escaping stays GREEN, which is what "
               "separates D from A)" % (red, want))

        # ── B: the shape guard dropped ──
        b = os.path.join(scratch, "B.html")
        shutil.copyfile(SRC, b)
        patch(b, CARRIED_LINE,
              "  const carriedKeys = aefKeys.filter(k => !scalarHandled.has(k)).sort();", "B")
        red = reddened(verdicts(run_probe(b)[1]))
        want = ["structured-untouched"]
        report(red == want, "mutant B killed (arrays flattened into the meta bag)",
               "reddened %s (want %s)" % (red, want))

        # ── C: endpoint removed from the skip set ──
        c = os.path.join(scratch, "C.html")
        shutil.copyfile(SRC, c)
        patch(c, ENDPOINT_LINE,
              "    'contextReads', 'artifactsWrites', 'decisionInput', 'decisionOutputs',", "C")
        red = reddened(verdicts(run_probe(c)[1]))
        want = ["no-double-emit"]
        report(red == want, "mutant C killed (endpoint emitted twice)",
               "reddened %s (want %s — the value still round-trips, which is the trap)" % (red, want))

        print("\n%d passed, %d failed" % (npass, nfail))
        if nfail == 0:
            print("%d/%d teeth legs passed" % (npass, npass))
        return 0 if nfail == 0 else 1
    finally:
        shutil.rmtree(scratch, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
