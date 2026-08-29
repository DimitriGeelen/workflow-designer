#!/usr/bin/env python3
"""T-627 — find inceptions equipped to be revisited that were never actually ruled on.

THE STATE THIS FINDS

An inception with `revisit_at:` set and no `**Decision**:` line carries the *machinery*
of a DEFER without the DEFER. Two things follow, and neither is visible:

  * A reader seeing `revisit_at: 2026-10-01` reasonably concludes the deferral was ruled
    on. It was not. The date is the consequence of a decision that never happened.
  * The task is UNCLOSEABLE. `check_inception_decision` (update-task.sh) refuses
    --status work-completed without that line, so the task cannot reach a terminal state
    no matter how much work is done on it.

How ours got this way is recorded rather than guessed: commit 7ed9643b (T-575) applied
revisit dates to eight parked inceptions as a fix for real scan blindness. T-307's briefs
had offered those fields conditionally — "IF you ratify all nine as DEFER". The condition
was never met and the consequence was applied anyway.

WHY THE REGEX IS READ, NOT COPIED

The point of this check is to warn about a state the COMPLETION GATE will refuse. If it
used its own approximation of the gate's pattern the two could drift, and a drifted
detector is worse than none: it sends people to fix a state the gate does not object to,
or stays silent on one it does. So the pattern is extracted from update-task.sh itself.
If the gate's regex changes, this follows it or fails loudly — it never quietly disagrees.

WHAT THIS DOES NOT DO

It does not write a `**Decision**:` line. Recording a sovereignty ruling on the
operator's behalf is precisely the act this check exists to report the absence of, and
`fw inception decide` refuses to run under an agent session by design (T-679/T-1259).
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GATE = os.path.join(ROOT, ".agentic-framework", "agents", "task-create", "update-task.sh")

# The line in the gate we lift the pattern from. Anchored on `grep -qE '<pattern>'`.
GATE_LINE = re.compile(r"""grep -qE ['"](\^\\\*\\\*Decision[^'"]*)['"]""")


def gate_regex():
    """Return the decision pattern the completion gate actually enforces.

    Raises rather than falling back to a hard-coded default: a silent fallback is how a
    detector starts disagreeing with the gate it is supposed to mirror.
    """
    with open(GATE, encoding="utf-8") as fh:
        for line in fh:
            m = GATE_LINE.search(line)
            if m:
                # ERE from the shell -> Python. The classes used are POSIX bracket
                # expressions; translate the one that appears.
                pat = m.group(1).replace("[[:space:]]", r"\s")
                return pat
    raise SystemExit(
        "INTEGRITY: could not extract the decision regex from %s.\n"
        "The gate's shape changed. Fix this extractor rather than hard-coding a copy —\n"
        "a detector that guesses the gate's rule is worse than no detector." % GATE
    )


def main():
    pat = re.compile(gate_regex(), re.M)
    equipped_undecided = []
    decided = 0
    for path in sorted(glob.glob(os.path.join(ROOT, ".tasks", "*", "*.md"))):
        if os.sep + "templates" + os.sep in path:
            continue
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        if "workflow_type: inception" not in text:
            continue
        m = re.search(r"^revisit_at:\s*(\S+)", text, re.M)
        if not m:
            continue
        if pat.search(text):
            decided += 1
        else:
            equipped_undecided.append((os.path.basename(path), m.group(1)))

    print("T-627 — inceptions with a revisit date but no recorded decision")
    print("  gate regex in force: %s" % pat.pattern)
    print()
    print("  revisit_at set AND decision recorded ... %d" % decided)
    print("  revisit_at set, NO decision ............ %d" % len(equipped_undecided))
    print()
    for name, when in equipped_undecided:
        print("  UNRULED  revisit_at=%-12s %s" % (when, name))

    if equipped_undecided:
        print()
        print("  These carry the machinery of a DEFER without the DEFER. Each is also")
        print("  UNCLOSEABLE: the completion gate refuses work-completed without that line.")
        print("  Ruling on them is the operator's act — `fw task review T-XXX`, then the")
        print("  Watchtower /inception/ page. An agent must not write the line.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
