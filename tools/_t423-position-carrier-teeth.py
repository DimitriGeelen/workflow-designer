#!/usr/bin/env python3
"""
_t423-position-carrier-teeth.py — proof that _t423-position-carrier-guard.py FIRES.

T-423. PL-070: a guard whose teeth never run is a guard nobody has checked, and a green
guard over a corpus that already satisfies it carries no information until something shows
it can go red.

HERMETIC BY CONSTRUCTION
------------------------
Every mutation happens on a COPY under mkdtemp and the guard is pointed at the copy with
T423_CORPUS. The real corpus is opened read-only and never written. This matters more than
usual here: _t350's header records an earlier mutation harness in this repo whose safety
stub silently failed to apply and deleted the repository. Building the population under
mkdtemp in the same breath as using it is the shape that cannot drift (it is also, per
T-508, the one count-pinning shape that is CORRECT — the population is constructed, not
observed).

THE LEGS, AND WHY EACH ONE EARNS ITS PLACE
------------------------------------------
  1  control          unmutated copy is green      — the harness itself is not the failure
  2  drop one         one position deleted → red   — AEF's exact shape: delete the rival
                                                     carrier, the test goes loud
  3  drop all in one  a whole map stripped → red   — a wholesale regression, not just a slip
  4  stray position   an extra position added in a NON-node's extensionElements → red,
                      while every node still carries its own. This is the leg that proves
                      L3 is a separate assertion and not a restatement of L2.
  5  empty corpus     no maps at all → REFUSAL (rc 2), not a pass. Without this leg the
                      guard could be satisfied by deleting the corpus, which is the
                      false-green family PL-151 keeps finding.
  6  benign edit      coordinates changed → still green. ANTI-OVERFIT: without it, a guard
                      that simply went red on any diff would pass legs 2-5 and be useless.

A green run here means the guard discriminates. It does not mean the corpus is correct —
that is leg 1 of the suite, and a different claim.
"""

import os
import re
import sys
import glob
import shutil
import tempfile
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GUARD = os.path.join(HERE, "_t423-position-carrier-guard.py")
REAL = os.path.join(ROOT, "examples", "aef-processes", "rendered")

POS = re.compile(r"[ \t]*<aef:position [^>]*/>\n")

passed = failed = 0


def run_guard(corpus):
    p = subprocess.run(
        [sys.executable, GUARD],
        capture_output=True, text=True, timeout=120,
        env=dict(os.environ, T423_CORPUS=corpus),
    )
    return p.returncode, (p.stdout + p.stderr)


def leg(name, corpus, want, needle=None):
    """want: 'green' (rc 0), 'red' (rc 1), or 'refuse' (rc 2)."""
    global passed, failed
    rc, out = run_guard(corpus)
    expect = {"green": 0, "red": 1, "refuse": 2}[want]
    ok = rc == expect and (needle is None or needle in out)
    if ok:
        passed += 1
        print(f"  PASS  {name}  (rc={rc}, wanted {want})")
    else:
        failed += 1
        print(f"  FAIL  {name}  (rc={rc}, wanted {want}={expect}"
              + (f", needle {needle!r} {'found' if needle and needle in out else 'MISSING'}" if needle else "")
              + ")")
        print("        " + out.strip().replace("\n", "\n        "))


def fresh(tmp, label):
    """A pristine copy of the corpus. Built, never observed."""
    dst = os.path.join(tmp, label)
    shutil.copytree(REAL, dst)
    return dst


def main():
    if not os.path.isdir(REAL):
        print(f"REFUSING: real corpus missing at {REAL}", file=sys.stderr)
        return 2
    if not os.path.exists(GUARD):
        print(f"REFUSING: guard missing at {GUARD}", file=sys.stderr)
        return 2

    print("_t423 position-carrier teeth — the guard must go red for the right reasons")

    with tempfile.TemporaryDirectory(prefix="t423-teeth-") as tmp:
        # ── 1. control ────────────────────────────────────────────────────────────────
        leg("control: unmutated copy is green", fresh(tmp, "control"), "green")

        # ── 2. drop ONE position ──────────────────────────────────────────────────────
        c2 = fresh(tmp, "drop-one")
        victim = sorted(glob.glob(os.path.join(c2, "*.bpmn")))[0]
        src = open(victim).read()
        m = POS.search(src)
        if not m:
            print("  FAIL  fixture: no aef:position to delete in the first map")
            return 1
        open(victim, "w").write(src[:m.start()] + src[m.end():])
        leg("one aef:position deleted -> red, naming the node",
            c2, "red", "do not carry exactly one aef:position")

        # ── 3. strip a whole map ──────────────────────────────────────────────────────
        c3 = fresh(tmp, "drop-all")
        victim = sorted(glob.glob(os.path.join(c3, "*.bpmn")))[0]
        # Read fully BEFORE opening for write: open(...,"w") truncates immediately, so the
        # nested-read spelling of this line silently feeds the guard an empty file and the
        # leg then "passes" for the wrong reason (it did, on the first run — the guard
        # refused with a parse error instead of the carrier failure it was meant to show).
        src = open(victim).read()
        open(victim, "w").write(POS.sub("", src))
        leg("every aef:position in one map deleted -> red", c3, "red")

        # ── 4. stray position, all nodes still intact ─────────────────────────────────
        # Injected into the PROCESS's own extensionElements: a real extensionElements
        # block, but not a flow node's. L2 must stay satisfied so the red can only be L3.
        c4 = fresh(tmp, "stray")
        victim = sorted(glob.glob(os.path.join(c4, "*.bpmn")))[0]
        src = open(victim).read()
        anchor = "<aef:workflowMeta "
        i = src.index(anchor)
        open(victim, "w").write(
            src[:i] + '<aef:position x="1.0" y="1.0"/>\n      ' + src[i:]
        )
        leg("an extra aef:position outside a flow node -> red on location, not on count",
            c4, "red", "live outside a flow node")

        # ── 5. a guard over nothing must refuse ───────────────────────────────────────
        c5 = os.path.join(tmp, "empty")
        os.makedirs(c5)
        leg("empty corpus -> REFUSAL, not a pass", c5, "refuse", "not green")

        # ── 6. anti-overfit: a benign edit must NOT trip it ───────────────────────────
        c6 = fresh(tmp, "benign")
        victim = sorted(glob.glob(os.path.join(c6, "*.bpmn")))[0]
        src = open(victim).read()   # read before truncating — see the note on leg 3
        open(victim, "w").write(POS.sub(lambda mm: mm.group(0).replace('y="', 'y="9'), src))
        leg("coordinates changed but every carrier present -> still green", c6, "green")

    print()
    if failed == 0 and passed == 0:
        print("REFUSING: no legs ran. An empty teeth run is not a pass.", file=sys.stderr)
        return 2
    print(f"TEETH {'PASS' if failed == 0 else 'FAIL'} — {passed} passed, {failed} failed "
          f"({passed + failed} legs ran)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
