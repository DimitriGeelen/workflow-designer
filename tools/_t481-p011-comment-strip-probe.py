#!/usr/bin/env python3
"""T-481 — reproduce, byte-exact, how the P-011 gate rewrites an executable command.

update-task.sh:978-983 strips HTML comment SPANS from the ## Verification block before
running it:

    text = re.sub(r'<!--.*?-->', '', text, flags=re.DOTALL)

The strip is span-based over raw block text, with no command-boundary and no quote
awareness. So a LIVE command that carries '<!--' and '-->' as literal data — a grep for an
HTML comment, say — has its middle deleted and is executed in the rewritten form.

This probe is the evidence for OBS-043, and the falsifier for the T-478 learning that
blamed backticks. Backticks are NOT the mechanism: our gate is a single `eval "$cmd"`
(update-task.sh:1101), and under a single eval single quotes protect backticks (measured
by AEF at rail 593 §2). Removing the backticks "fixed" my leg only because it also removed
the '<!--'.

Exit 0 iff the reproduction matches what the gate actually printed.
"""
import re
import sys

# The leg exactly as it was stored in T-478's ## Verification block.
ORIGINAL = (
    "/usr/bin/grep -q 'lines.push(`  <!-- ${DI_TRAILER} -->`)' "
    "src/aef-workflow-designer.html"
)
# What the gate printed back when the leg went red.
GATE_REPORTED = "/usr/bin/grep -q 'lines.push(`  `)' src/aef-workflow-designer.html"


def gate_strip(text):
    """The exact transformation at update-task.sh:978-983."""
    return re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)


def main():
    got = gate_strip(ORIGINAL).strip()
    ok = got == GATE_REPORTED
    print("original      : %s" % ORIGINAL)
    print("after strip   : %s" % got)
    print("gate reported : %s" % GATE_REPORTED)
    print("byte-exact    : %s" % ok)

    # The backtick counter-claim, stated as data: backticks survive the strip untouched.
    # If they were the mechanism, they would be gone here.
    print("backticks in stripped output: %d (unchanged from %d) -> backticks are NOT the mechanism"
          % (got.count("`"), ORIGINAL.count("`")))

    # Positive control: a leg with no comment span must pass through byte-identical,
    # otherwise this probe proves nothing about what the strip targets.
    safe = "/usr/bin/grep -q 'DI_TRAILER} -->' src/aef-workflow-designer.html"
    ctl = gate_strip(safe) == safe
    print("control (no '<!--' -> untouched): %s" % ctl)

    # And the dangerous direction, which is the reason this is a defect and not a nuisance:
    # a strip that leaves a still-matchable pattern passes while checking something else.
    danger = "/usr/bin/grep -q 'foo<!--x-->bar' f.txt"
    print("silent-rewrite example: %s  ->  %s" % (danger, gate_strip(danger)))

    if not (ok and ctl):
        sys.stderr.write("FAIL: reproduction or control did not hold\n")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
