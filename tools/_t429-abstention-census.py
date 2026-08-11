#!/usr/bin/env python3
"""
_t429-abstention-census.py — can any of our suites report success having run nothing?

T-429.

THE QUESTION
------------
Not "do the suites pass" — they do. The question is whether a suite that ran ZERO legs is
distinguishable, from the outside, from one that ran forty and found nothing wrong. Our
suites end on `[ "$fail" -eq 0 ] || exit 1`. A suite whose legs never executed has
`fail=0`. It exits 0. It prints `pass=0 fail=0` and the caller — P-011, a task's
Verification block, a human reading a transcript — records a green.

Arrived as AEF's finding about AEF's code (DM 529 §4): a stalled-task guard that had never
evaluated a single row, coverage 11/1325, printing the same sentence a guard that cleared
300 tasks would print. Their generalisation is `a verdict must never print without its
denominator`. This is the reciprocal measurement on our side.

WHY THE CENSUS PRINTS ITS OWN DENOMINATOR
-----------------------------------------
A census of under-covering instruments that under-covers is not ironic, it is the same
bug. Two hand-written greps for "suites with a fail counter" were run while scoping this
task and returned DIFFERENT nine-file sets — neither was the union. So the rule here is
not a list of counter names: it is "a variable that is incremented by 1 somewhere in the
file and named like a tally". Every file examined is reported with its verdict, including
NO-COUNTER, and the header states examined-of-total. A file this program cannot read is
UNREADABLE, never silently skipped.

WHAT `GUARDED` MEANS
--------------------
The suite's own exit path asserts that legs ran: somewhere it compares a tally (or the sum
of tallies) against zero and takes a non-zero exit from it. Not "it has an if statement" —
the comparison has to reach an `exit` that is not 0, within a few lines, or a suite could
print a warning about having run nothing and still return green.

EXIT
----
  0  every counter-bearing suite is guarded
  1  at least one can abstain silently
  2  cannot answer (no tools dir, nothing examined) — never the same code as "all clean"
"""

import os
import re
import sys

ROOT = os.environ.get("T429_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(ROOT, "tools")

# A tally is a variable incremented by one. Named like a count of outcomes — deliberately
# broad, because the failure this file audits is exactly an enumeration that was too narrow.
TALLY_NAME = re.compile(r"^(pass|fail|ok|err|error|bad|good|red|green|skip|leg|test|check|assert|count|total|ran|n)[a-z_]*$", re.I)
INCREMENT = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\$\(\(\s*\1\s*\+\s*1\s*\)\)")


def tallies(src):
    """Variable names incremented by one anywhere in the file, filtered to tally-shaped names."""
    return sorted({m.group(1) for m in INCREMENT.finditer(src) if TALLY_NAME.match(m.group(1))})


def guarded(src, names):
    """True when the suite takes a NON-ZERO EXIT ON THE BRANCH WHERE A TALLY IS ZERO.

    THE BRANCH IS THE WHOLE POINT, AND THE FIRST DRAFT OF THIS FUNCTION GOT IT WRONG.
    It looked for `-eq 0` near `exit 1` and therefore called

        [ "$fail" -eq 0 ] || exit 1

    a guard. That is the ordinary VERDICT line every one of these suites already ends on:
    it exits when `fail` is NON-zero, and is silent in exactly the case under audit. The
    tokens matched; the meaning was the opposite. That is AEF's 529 §3 class — `does this
    string mention the thing, or is it the thing` — committed inside the instrument built
    to audit the family it belongs to. The fixture keeps that row forever.

    So the discriminator is operator AND connective together:
        tally -eq 0  followed by  && exit N   or  then ... exit N   -> guards
        tally -gt 0  followed by  || exit N                         -> guards
        tally -eq 0  followed by  || exit N                         -> the verdict line
    """
    if not names:
        return False
    alt = "|".join(re.escape(n) for n in names)
    tally = r"(?:\$\{?(?:%s)\}?|\$\(\([^)]*\b(?:%s)\b[^)]*\)\))" % (alt, alt)
    # zero-branch: "is empty" tested, then an exit taken when that is TRUE
    is_zero = re.compile(r"%s[^\n]*-(?:eq)\s+0\b|%s[^\n]*-(?:lt)\s+1\b" % (tally, tally))
    is_nonzero = re.compile(r"%s[^\n]*-(?:gt)\s+0\b|%s[^\n]*-(?:ge)\s+1\b" % (tally, tally))
    lines = src.splitlines()
    for i, line in enumerate(lines):
        zero, nonzero = bool(is_zero.search(line)), bool(is_nonzero.search(line))
        if not (zero or nonzero):
            continue

        # THE EXIT MUST BE CONTROLLED BY THIS TEST, NOT MERELY NEAR IT.
        # The previous version scanned a 4-line window, which credited the very next
        # statement — and in every suite here the next statement IS `|| exit 1`, the
        # verdict line. So a file that only PRINTED "nothing ran" and returned success
        # was classified as guarded, because a guard-shaped exit happened to follow it.
        # Same mention-vs-instance error as the draft before it, one scope out: near is
        # not the same as governed by. Caught by leg V4, which exists for this.
        inline_then = re.search(r";\s*then\b(.*)$", line)
        if re.search(r";\s*then\s*$", line):                    # block form, body follows
            body = []
            for follow in lines[i + 1:]:
                if re.match(r"^\s*(fi|else|elif)\b", follow):
                    break
                body.append(follow)
            controlled = "\n".join(body)
            fires_on_true, fires_on_false = True, False
        elif inline_then:                                       # `if ...; then ...; fi`
            controlled = inline_then.group(1)
            fires_on_true, fires_on_false = True, False
        else:                                                   # one-line form
            controlled = line.split("&&", 1)[-1] if "&&" in line else line.split("||", 1)[-1]
            fires_on_true = "&&" in line and "||" not in line
            fires_on_false = "||" in line
            if not (fires_on_true or fires_on_false):
                continue

        if not re.search(r"\bexit\s+[1-9]", controlled):
            continue
        if zero and fires_on_true:
            return True
        if nonzero and fires_on_false:
            return True
    return False


def main():
    if not os.path.isdir(TOOLS):
        print("UNKNOWN — no tools/ directory under %s. Nothing examined." % ROOT)
        return 2

    files = sorted(f for f in os.listdir(TOOLS) if f.endswith(".sh"))
    rows, unreadable = [], []
    for name in files:
        path = os.path.join(TOOLS, name)
        try:
            src = open(path, encoding="utf-8", errors="replace").read()
        except OSError as exc:
            unreadable.append((name, exc))
            continue
        names = tallies(src)
        if not names:
            rows.append((name, "NO-COUNTER", names))
        elif guarded(src, names):
            rows.append((name, "GUARDED", names))
        else:
            rows.append((name, "UNGUARDED", names))

    counter_rows = [r for r in rows if r[1] != "NO-COUNTER"]
    unguarded = [r for r in counter_rows if r[1] == "UNGUARDED"]

    print("=== T-429 abstention census: can a suite exit 0 having run no legs? ===")
    print()
    print("  examined      %d of %d file(s) in tools/" % (len(rows), len(files)))
    print("  unreadable    %d" % len(unreadable))
    print("  no counter    %d  (not suites in this sense — not a finding)" % (len(rows) - len(counter_rows)))
    print("  counter-bearing suites: %d" % len(counter_rows))
    print("    GUARDED     %d" % (len(counter_rows) - len(unguarded)))
    print("    UNGUARDED   %d" % len(unguarded))

    if not rows:
        print()
        print("UNKNOWN — tools/ holds no .sh files. A census of nothing is not a PASS.")
        return 2

    for name, exc in unreadable:
        print("  UNREADABLE %s: %s" % (name, exc))

    if unguarded:
        print()
        print("UNGUARDED — tallies exist, but no zero-comparison reaches a non-zero exit:")
        for name, _verdict, names in unguarded:
            print("  %-46s tallies: %s" % (name, ", ".join(names)))
        print()
        print("  Each of these returns 0 when every leg is skipped, and prints a line whose")
        print("  shape is identical to a full green run. The caller cannot tell the two apart,")
        print("  and neither can the suite's author reading a transcript six weeks later.")

    print()
    if unguarded:
        print("FINDINGS: %d suite(s) can report success having verified nothing." % len(unguarded))
        return 1
    print("PASS — every counter-bearing suite fails when its legs do not run.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
