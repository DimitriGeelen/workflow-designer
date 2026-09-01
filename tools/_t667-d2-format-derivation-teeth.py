#!/usr/bin/env python3
"""T-667 teeth — prove _t534's anti-aging guard actually fires, and fires as a DEAD CONTROL.

WHY THIS FILE EXISTS. T-667 repaired _t534 by deriving its expectation from audit.sh instead
of transcribing it: `check_format_anchors()` asserts that the fragments the parse depends on
still exist in the audit's D2 composition block, and calls dead() (rc 4) when one has moved.

That guard is itself a hand-written claim, and this session's whole finding is that a guard
nobody drives red goes dead in silence — T-665's control was broken for six days, T-666 gave
that state a name, and _t534 was the first thing the name caught. A repair whose own new
mechanism is unproven would be the same bet placed again, one level up.

So: mutate a COPY of audit.sh the way T-656 actually did, point _t534's guard at the copy, and
require it to die rc 4 naming the fragment that moved. The real audit.sh is never touched.

Three arms, because the repair could fail in three different directions:

  A  a reworded audit.sh  -> rc 4, naming the moved fragment. If this returns normally the
     guard does not guard, and _t534 is back to aging out silently.
  B  an unparseable D2 line -> parse() returns None (which _t534 routes to dead(), rc 4).
     Guards the opposite risk from A: the positional parse was made permissive on purpose so
     intervening clauses can change freely, and a parse permissive enough to swallow anything
     detects nothing.
  C  no D2 line at all -> still refuse(), rc 2. This is the arm that matters most. T-666's
     entire finding was that an honest abstention and a dead control are opposite events that
     shared one exit code; if a later repair collapses them back together, the bug returns
     wearing the fix as a disguise.

Exit 0 all arms green, 1 an arm failed, 2 REFUSE (stimulus not established — nothing evaluated).
"""

import contextlib
import io
import os
import re
import shutil
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROBE = os.path.join(REPO, "tools", "_t534-d2-queue-tier-teeth.py")
AUDIT = os.path.join(REPO, ".agentic-framework/agents/audit/audit.sh")

# The rewording used for arm A. Deliberately the SAME KIND of change T-656 made — a clause
# reworded, not deleted — because a deleted clause is the easy case and was never the bug.
REWORD = ("signed off, awaiting only the status flip:",
          "signed off, pending only the status change:")


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — no arm was evaluated.")
    sys.exit(2)


def load_defs(audit_path):
    """_t534's top-level definitions, with AUDIT redirected at a copy.

    The driver code below `if not os.path.isfile(FW):` invokes the real audit against a
    synthetic queue and costs ~7s; this file needs only the pure functions, so the source is
    cut at the driver rather than executed through it.
    """
    src = open(PROBE, encoding="utf-8").read()
    marker = "if not os.path.isfile(FW):"
    if marker not in src:
        refuse("could not find the driver boundary %r in %s — the file was restructured and "
               "this teeth file cannot isolate its definitions without guessing." % (marker, PROBE))
    ns = {"__name__": "_t534_defs", "__file__": PROBE}
    exec(compile(src.split(marker, 1)[0], PROBE, "exec"), ns)
    for required in ("check_format_anchors", "parse", "refuse", "dead"):
        if required not in ns:
            refuse("_t534 no longer defines %s() — the contract this file tests is gone, and "
                   "asserting against a function that does not exist would be a green built "
                   "on absence." % required)
    ns["AUDIT"] = audit_path
    return ns


def main():
    if not os.path.isfile(PROBE):
        refuse("%s not found — nothing to drive" % PROBE)
    if not os.path.isfile(AUDIT):
        refuse("%s not found — no subject to mutate" % AUDIT)

    fails = []
    probe_src = open(PROBE, encoding="utf-8").read()
    audit_src = open(AUDIT, encoding="utf-8").read()

    # ── Arm A — a reworded audit.sh must kill the probe, loudly and by name ──────────────
    if REWORD[0] not in audit_src:
        refuse("the fragment %r is not in audit.sh, so the rewording that reproduces T-656 "
               "cannot be staged. Either D2 moved again (in which case _t534 should already "
               "be red) or this file's stimulus has aged out — the very failure it tests for."
               % REWORD[0])
    tmp = tempfile.mkdtemp(prefix="t667-teeth-")
    try:
        mutated = os.path.join(tmp, "audit.sh")
        open(mutated, "w", encoding="utf-8").write(audit_src.replace(*REWORD))
        ns = load_defs(mutated)
        # The guard prints its diagnosis to stdout on the way out. Captured rather than let
        # through, because "TEETH BROKEN" in this file's transcript is the EXPECTED result of
        # arm A and reads as a failure to anyone scanning the sweep log.
        buf = io.StringIO()
        code = None
        try:
            with contextlib.redirect_stdout(buf):
                ns["check_format_anchors"]()
        except SystemExit as e:
            code = e.code
        said = buf.getvalue()
        if code is None:
            fails.append(
                "arm A: audit.sh was reworded and check_format_anchors() returned normally. "
                "The guard does not guard, so _t534's expectation can drift out of agreement "
                "with the audit exactly as it did under T-656 — silently.")
        elif code != 4:
            fails.append(
                "arm A: a reworded audit.sh exited %r, expected 4 (DEAD CONTROL). A format "
                "drift reported as anything else is the original defect: rc 2 reads as an "
                "honest abstention needing no action, and rc 1 claims a regression in the "
                "queue itself, which this run measured nothing about." % code)
        elif REWORD[0].strip() not in said:
            fails.append(
                "arm A: the guard died rc 4 but its message never names %r — the fragment "
                "that actually moved. A death that does not say what moved leaves the reader "
                "diffing two files to find out, which is the search problem moved rather "
                "than solved (T-666 leg 7, same argument)." % REWORD[0].strip())
        else:
            print("  arm A: reworded audit.sh -> rc 4, message names the moved fragment")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    # ── Arm B — the permissive parse must still refuse garbage ───────────────────────────
    ns = load_defs(AUDIT)
    junk = "[FAIL] D2: Human review queue — the queue is fine actually"
    if ns["parse"](junk) is not None:
        fails.append(
            "arm B: %r parsed anyway. The positional parse is permissive by design so that "
            "clauses BETWEEN the tier headers may change freely — but a parse that accepts a "
            "line with no tier header at all cannot tell 'the format moved' from 'the format "
            "is fine', and the derivation guard is then the only thing standing." % junk)

    # ── Arm C — the abstention arm must survive the repair ───────────────────────────────
    if 'refuse("the audit emitted no D2 line at all' not in probe_src:
        fails.append(
            "arm C: _t534's no-D2-line branch no longer calls refuse(). An honest abstention "
            "has been converted into something else. T-666 separated these two states at some "
            "cost; merging them back is the defect returning with the fix as its disguise.")
    if not re.search(r"def refuse\([^)]*\):(?:.|\n)*?sys\.exit\(2\)", probe_src):
        fails.append("arm C: _t534's refuse() no longer exits 2, so an abstention is no longer "
                     "distinguishable from a dead control by exit code.")
    if not re.search(r"def dead\([^)]*\):(?:.|\n)*?sys\.exit\(4\)", probe_src):
        fails.append("arm C: _t534's dead() no longer exits 4, so a broken instrument is no "
                     "longer distinguishable from an abstention by exit code.")

    if fails:
        print("T-667 TEETH: %d finding(s)" % len(fails))
        for f in fails:
            print("  - %s" % f)
        return 1
    print("T-667 TEETH: 3 arms green — a reworded audit.sh kills _t534 with rc 4 naming the "
          "moved fragment, a line with no tier header does not parse, and the no-D2-line "
          "abstention is still rc 2 while a broken parse is still rc 4.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
