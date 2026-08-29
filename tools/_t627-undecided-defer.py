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


FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.S)
WF_INCEPTION = re.compile(r"^workflow_type:\s*inception\s*$", re.M)


def is_inception(text):
    """True only if the FRONTMATTER declares it, not if the body mentions it.

    T-637: this was `"workflow_type: inception" in text` — a substring test over the
    whole file. It was harmless only because the caller skipped anything without a
    revisit date; widening the scan exposed it immediately, with two false positives out
    of four new rows. One is a TABLE CELL documenting the node-type mapping
    (`| inception-node -> \\`workflow_type: inception\\` |`) and the other is a SENTENCE
    about how the scoring exception routes inception tasks. Both are prose ABOUT the
    field, in files whose actual workflow_type is `test` and `build`.

    That is the same defect this project has now found five times in two days, in five
    different places: a character-level scan standing in for structure, so a document
    that MENTIONS a thing is treated as one. The remedy is the same each time — read the
    structure that carries meaning (here the YAML frontmatter block, anchored at the
    start of file) rather than the characters that spell it.
    """
    m = FRONTMATTER.match(text)
    if not m:
        return False
    return bool(WF_INCEPTION.search(m.group(1)))


def main():
    pat = re.compile(gate_regex(), re.M)
    equipped_undecided = []
    unscheduled_undecided = []
    decided = 0
    for path in sorted(glob.glob(os.path.join(ROOT, ".tasks", "*", "*.md"))):
        if os.sep + "templates" + os.sep in path:
            continue
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        if not is_inception(text):
            continue
        m = re.search(r"^revisit_at:\s*(\S+)", text, re.M)
        if not m:
            # T-637: this used to `continue`, and that made the check's denominator
            # "inceptions carrying a revisit date" while its NAME and its closing advice
            # are about inceptions that were never ruled on. Two live tasks sat in the
            # difference — undecided, active, and invisible to every scan, which is why
            # neither had ever reached a handover in the months they have existed.
            #
            # They are the WORSE half of the population, not a footnote to it. An
            # inception with `revisit_at` at least has a date on which something will
            # eventually fire. One with neither a decision nor a date has no mechanism
            # that will ever raise it again: it is closed off from the completion gate
            # (which refuses without the line) and from the revisit scan (which needs the
            # date), and it will be found only by someone reading the task list by hand.
            #
            # Same class as the /tmp census the day before: A SCAN'S DENOMINATOR IS A
            # CLAIM, and this one was narrower than the sentence it printed.
            if os.sep + "active" + os.sep in path and not pat.search(text):
                unscheduled_undecided.append(os.path.basename(path))
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
    print("  active, NO decision AND no revisit ..... %d" % len(unscheduled_undecided))
    print()
    for name, when in equipped_undecided:
        print("  UNRULED  revisit_at=%-12s %s" % (when, name))
    for name in unscheduled_undecided:
        print("  UNRULED  no revisit date  %s" % name)

    if equipped_undecided:
        print()
        print("  The first group carries the machinery of a DEFER without the DEFER. Each")
        print("  is also UNCLOSEABLE: the completion gate refuses work-completed without")
        print("  that line.")
    if unscheduled_undecided:
        print()
        print("  The second group is worse and was invisible until T-637: no decision AND")
        print("  no revisit date, so nothing will ever raise them — not the completion")
        print("  gate, not the revisit scan. They surface here or not at all.")
    if equipped_undecided or unscheduled_undecided:
        print()
        print("  Ruling on any of these is the operator's act — `fw task review T-XXX`,")
        print("  then the Watchtower /inception/ page. An agent must not write the line.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
