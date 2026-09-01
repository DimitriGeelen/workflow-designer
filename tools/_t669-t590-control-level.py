#!/usr/bin/env python3
"""T-669 — assert that T-590's repaired absence leg is PATTERN-controlled.

WHY A FILE AND NOT A GREP. The natural verification here is "T-590 no longer appears in
the census output", and that is an absence assertion: it passes identically if T-590 was
repaired, if the census stopped printing, or if the output file was never written. This
task exists because that class of leg is satisfied by silence, so verifying it with one
would be self-refuting.

Instead the census's OWN classifier is called on the leg and the answer is required to
EQUAL "PATTERN". A wrong path, a renamed function, a leg that vanished, or a classifier
that stopped working all fail loudly and by name.

Exit 0 PATTERN as required, 1 the classification is wrong, 2 REFUSE (the subject could
not be established — nothing was evaluated).
"""

import importlib.util
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CENSUS = os.path.join(REPO, "tools", "_t560-absence-assertion-census.py")
TASK = os.path.join(REPO, ".tasks", "active",
                    "T-590-ewcr-arc-0-designer-contract-inventory-a.md")
NEEDLE = '! grep -qE "conditionExpression'


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — the classification was never evaluated.")
    sys.exit(2)


def main():
    for path in (CENSUS, TASK):
        if not os.path.isfile(path):
            refuse("%s not found" % os.path.relpath(path, REPO))

    spec = importlib.util.spec_from_file_location("_t560_census", CENSUS)
    census = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(census)
    for fn in ("verification_legs", "control_level"):
        if not hasattr(census, fn):
            refuse("the census no longer defines %s() — this file cannot classify "
                   "anything without guessing at a replacement" % fn)

    legs = census.verification_legs(TASK)
    if not legs:
        refuse("T-590 has no readable ## Verification block")

    targets = [t for _, t in legs if t.startswith(NEEDLE)]
    if len(targets) != 1:
        refuse("expected exactly 1 leg starting %r in T-590, found %d. The leg this "
               "task repaired has been edited or removed; re-verifying against a "
               "different leg would assert nothing about the repair."
               % (NEEDLE, len(targets)))

    leg = targets[0]
    siblings = [t for _, t in legs if t != leg]
    level = census.control_level(leg, siblings)
    if level != "PATTERN":
        print("FAIL: T-590's absence leg classifies as %s, expected PATTERN." % level)
        print("      The companion leg that greps the same alternation in")
        print("      cannot-represent-yet.md is missing, reworded, or no longer shares")
        print("      the absence leg's exact pattern string — which is what makes a")
        print("      mistyped alternation fail loudly instead of passing on empty.")
        return 1

    print("T-669: T-590's absence leg is PATTERN-controlled (companion leg asserts the "
          "same alternation where it IS present).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
