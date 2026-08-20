#!/usr/bin/env python3
"""_t566-note-field-teeth.py — does the T-566 probe actually discriminate?

A probe that passes on the fixed source proves nothing on its own: "all legs green" is
also what a probe that asserts nothing produces. So each mutant below is a fix someone
would plausibly ship, and each must redden EXACTLY the legs it breaks and no others. A
mutant that reddens more than its own legs is not discriminating and is reported as a
failure, not quietly accepted.

  A — `note` removed from AEF_FIELDS (the shipping code before this task).
      Must redden the three NOTE legs and leave the two DISCLOSURE legs green — because
      once `note` is unlisted it becomes an unlisted key, which is precisely what the
      disclosure branch exists to catch. `multiline-roundtrip` must also stay green: it
      is an assertion about escAttr, not about the panel.

  B — the disclosure branch deleted, `note` left correct.
      Must redden ONLY the two disclosure legs. This is the "just fix note" patch — the
      one that satisfies both reporters and leaves the shape that produced them intact.

  C — the disclosure rendered with editable controls instead of read-only readouts.
      Must redden ONLY `disclosure-readonly`. The keys are still all shown, so this is
      the mutant that a test asking only "is everything visible?" would wave through,
      while it puts an edit box on `owner` and `gatewayKind` (T-197: a lie).

A CONTROL RUN ON UNMUTATED SOURCE COMES FIRST. "every mutant died" is equally satisfied
by a harness that fails on everything (T-560), and this probe drives a real browser, so
an environment fault is a live possibility rather than a theoretical one.

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
PROBE = os.path.join(ROOT, "tools", "_t566-note-field-cdp.mjs")
LEGS = ("note-field", "note-reads", "note-writes", "disclosure", "disclosure-readonly",
        "multiline-roundtrip")


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
        raise SystemExit("mutant %s: anchor occurs %d times, need exactly 1" % (label, n))
    open(path, "w", encoding="utf-8").write(s.replace(old, new))


def mutate_A(path):
    """Strip 'note' from every AEF_FIELDS list — the state of the file before this task."""
    s = open(path, encoding="utf-8").read()
    i = s.index("const AEF_FIELDS = {")
    j = s.index("\n};", i)
    block = s[i:j]
    stripped = block.replace(", 'note']", "]").replace("['note']", "[]")
    if stripped == block:
        raise SystemExit("mutant A: no 'note' entries found in AEF_FIELDS")
    open(path, "w", encoding="utf-8").write(s[:i] + stripped + s[j:])


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

    scratch = tempfile.mkdtemp(prefix="t566-teeth-")
    try:
        rc, out = run_probe(SRC)
        ctl = verdicts(out)
        if rc != 0 or reddened(ctl):
            report(False, "control: unmutated source passes all six legs",
                   "rc=%d failing=%s" % (rc, reddened(ctl) or "none"))
            print("\n%d passed, %d failed" % (npass, nfail))
            return 1
        report(True, "control: unmutated source passes all six legs", ", ".join(LEGS))

        # ── A ──
        a = os.path.join(scratch, "A.html")
        shutil.copyfile(SRC, a)
        mutate_A(a)
        red = reddened(verdicts(run_probe(a)[1]))
        want = ["note-field", "note-reads", "note-writes"]
        report(red == want, "mutant A killed ('note' unlisted, as shipped)",
               "reddened %s (want %s — disclosure legs MUST stay green)" % (red, want))

        # ── B ──
        b = os.path.join(scratch, "B.html")
        shutil.copyfile(SRC, b)
        patch(b, "  if (hiddenKeys.length) {", "  if (false && hiddenKeys.length) {", "B")
        red = reddened(verdicts(run_probe(b)[1]))
        want = ["disclosure", "disclosure-readonly"]
        report(red == want, "mutant B killed (disclosure removed, note left correct)",
               "reddened %s (want %s)" % (red, want))

        # ── C ──
        c = os.path.join(scratch, "C.html")
        shutil.copyfile(SRC, c)
        patch(c,
              "      const val = document.createElement('div');\n"
              "      val.className = 'field-input';",
              "      const val = document.createElement('input');\n"
              "      val.className = 'field-input';",
              "C")
        patch(c, "      val.textContent = String(n.aef[k]);",
                 "      val.value = String(n.aef[k]);", "C2")
        red = reddened(verdicts(run_probe(c)[1]))
        want = ["disclosure-readonly"]
        report(red == want, "mutant C killed (disclosure made editable)",
               "reddened %s (want %s — every key is still shown, which is the trap)" % (red, want))

        print("\n%d passed, %d failed" % (npass, nfail))
        if nfail == 0:
            print("%d/%d teeth legs passed" % (npass, npass))
        return 0 if nfail == 0 else 1
    finally:
        shutil.rmtree(scratch, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
