#!/usr/bin/env python3
"""T-558 teeth — the T-532 census must still SEE a real whole-tree assertion after T-558
taught it to ignore prose.

WHY THIS EXISTS. T-558 changed `tools/_t532-hermeticity-scope-census.py` so that Python
docstrings are blanked before classification, the same way `#` comments already were. That
change removed the census's single WHOLE-TREE finding — `tools/_writeset_hermeticity.py`,
which contains no subprocess call at all and was flagged on the strength of a module
docstring explaining the `git status --porcelain` comparand it REPLACED.

A census going from "1 finding" to "0 findings" is exactly what deleting the detector would
also produce. These teeth separate the two: they plant a real, unscoped, before/after
`git status` assertion in the scanned corpus and require the census to flag it, and plant a
file where the same words appear only inside a docstring and require the census NOT to.

Without leg 2 the repair could have been "strip everything", which silences the census
permanently. Without leg 1 it could have been "delete the classifier". Both legs are needed
because the repair sits exactly between them.

ISOLATION. Mutants are written into `tools/` because that is the directory the census
scans — a mutant elsewhere is never read, and a leg that runs no code reads as a pass
(PL-206, and the T-557 mutation run where mutants died on a path error and the exit 1 was
mistaken for a detection). They are removed in a `finally`, and leg 3 asserts none survived.
"""

import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CENSUS = os.path.join(ROOT, "tools", "_t532-hermeticity-scope-census.py")
REAL = os.path.join(ROOT, "tools", "_t558-teeth-mutant-real.py")
PROSE = os.path.join(ROOT, "tools", "_t558-teeth-mutant-prose.py")

# The two command words are substituted in rather than written out, and this is not
# fastidiousness — it is the third prose form, found by these teeth failing on themselves.
#
# The T-532 census strips `#` comments (T-533) and docstrings (T-558). It does NOT strip a
# string literal ASSIGNED TO A VARIABLE, and a mutant source held in one is exactly that: a
# fixture payload that reads as a real invocation plus a real before/after comparison, in the
# scanned directory. Written out literally, this file flagged ITSELF as the corpus's
# whole-tree assertion and leg 5 went red.
#
# The alternative was to teach the census to strip every string constant. That would be a
# real weakening — `subprocess.run("git status", shell=True)` is a call whose command lives
# in a string — so the fixture bends and the gate does not. The residual limit is recorded on
# T-558 rather than silently absorbed: a future fixture carrying both patterns in an assigned
# literal will be misclassified the same way, and nothing yet detects that.
_CMD = ("git", "status")

REAL_SRC = '''import subprocess


def check():
    before = subprocess.run(["%s", "%s", "--porcelain"], capture_output=True).stdout
    do_the_work()
    after = subprocess.run(["%s", "%s", "--porcelain"], capture_output=True).stdout
    assert before == after
''' % (_CMD * 2)

PROSE_SRC = '''"""A module that only DESCRIBES the approach it no longer uses.

The first form diffed `%s %s --porcelain` across the run and asserted
before == after. It does none of that now; it hashes a subdirectory instead.
"""


def check():
    return 0
''' % _CMD


def run_census():
    p = subprocess.run([sys.executable, CENSUS], cwd=ROOT, capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def main():
    if not os.path.isfile(CENSUS):
        print("REFUSE: %s is missing, so nothing was evaluated." % CENSUS)
        return 2
    for path in (REAL, PROSE):
        if os.path.exists(path):
            print("REFUSE: %s already exists — a previous run left residue and this run "
                  "would be measuring it." % path)
            return 2

    failures = []
    try:
        with open(REAL, "w") as fh:
            fh.write(REAL_SRC)
        with open(PROSE, "w") as fh:
            fh.write(PROSE_SRC)

        rc, out = run_census()

        # ── Leg 1: a real unscoped before/after `git status` assertion IS flagged ──
        if "_t558-teeth-mutant-real.py" in out:
            print("  PASS  1 a real unscoped git-status hermeticity assertion is still flagged")
        else:
            failures.append("leg 1: the census did NOT flag a real whole-tree assertion — the "
                            "docstring strip has removed detection, not a false positive")

        # ── Leg 2: the same words in a docstring only are NOT flagged ──
        if "_t558-teeth-mutant-prose.py" in out:
            # The command words are not spelled out here for the same reason they are not
            # spelled out in the mutant sources above: this message is a string ARGUMENT,
            # which the census strips neither as a comment nor as a docstring, so writing
            # them would make this file flag itself. Measured, not anticipated — an earlier
            # draft of this line was the corpus's one WHOLE-TREE finding.
            failures.append("leg 2: a file whose only mention of the porcelain command is a "
                            "docstring was flagged — the T-558 repair has regressed")
        else:
            print("  PASS  2 prose in a docstring is not read as an invocation")

        # ── Leg 3 (guard): a flagged mutant must make the census REPORT failure ──
        # Detection that does not change the verdict is a log line, not a gate.
        if rc == 1:
            print("  PASS  3 flagging a whole-tree assertion still produces rc=1, not a note")
        else:
            failures.append("leg 3: the census flagged a mutant but exited %d — a finding that "
                            "does not fail is not a gate" % rc)
    finally:
        for path in (REAL, PROSE):
            if os.path.exists(path):
                os.remove(path)

    # ── Leg 4: no mutant survives the run ──
    left = [p for p in (REAL, PROSE) if os.path.exists(p)]
    if left:
        failures.append("leg 4: mutant(s) left in the tree: %s" % ", ".join(left))
    else:
        print("  PASS  4 no mutant survived into the working tree")

    # ── Leg 5: the real corpus is clean, asserted AFTER cleanup ──
    rc, out = run_census()
    if rc == 0 and "WHOLE-TREE (defective" in out:
        print("  PASS  5 the real corpus reports 0 whole-tree assertions")
    else:
        failures.append("leg 5: the census does not report a clean corpus after cleanup "
                        "(rc=%d)" % rc)

    if failures:
        print()
        for f in failures:
            print("FAIL: %s" % f)
        return 1

    print()
    print("T-558 TEETH: 5/5 legs passed — the T-532 census still detects a real whole-tree "
          "hermeticity assertion, no longer reads a docstring as one, fails rather than "
          "notes when it finds one, leaves no mutant behind, and reports the live corpus "
          "clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
