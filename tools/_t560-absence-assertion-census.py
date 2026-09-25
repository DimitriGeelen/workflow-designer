#!/usr/bin/env python3
"""T-560 — census of P-011 Verification legs that assert ABSENCE without a control.

THE DEFECT. A Verification leg that asserts something is NOT there is satisfied by
silence. If its pattern is broken — mis-quoted, shell-expanded before `grep` sees it,
pointed at a path that does not exist — the leg finds nothing and goes green for the
wrong reason. The assertion and its own failure produce the identical observable, and
the P-011 gate cannot tell them apart. This is PL-219 landing inside the mechanism the
framework treats as proof rather than as self-assessment.

WHY THIS IS NOT A CENSUS OF MIS-QUOTED GREPS. Two legs were caught mis-quoted in a
single session (T-501 leg 2, a `\\[` that matches nothing as a BRE; T-301 leg 4, a
double-quoted `${...}` the shell emptied before grep ran). BOTH were caught, and both
for the same reason: they asserted PRESENCE, so a broken pattern produced a red leg.
The quoting was never the discriminator. Direction was. So this tool measures the
population where the same mistake is invisible, not the population where it is loud.

WHAT COUNTS AS CONTROLLED. An absence assertion is sound when something independent
establishes that the search COULD have succeeded. Three levels are distinguished
because they catch different mistakes and conflating them would overstate coverage:

  PATTERN   another leg in the same Verification block asserts the SAME pattern
            positively somewhere. A typo in the pattern breaks that leg too, loudly.
            This is the only control that catches a wrong PATTERN.
  EXISTENCE the same line proves its target exists (`test -f`, `test -s`, `test -d`,
            or a `git ls-files`/redirect into a file it then greps). Catches a wrong
            PATH. Does NOT catch a wrong pattern — stated explicitly because reading
            `test -f X && ! grep -q P X` as "controlled" is the exact overstatement
            this tool exists to avoid.
  NONE      nothing establishes reachability. A finding.

RATCHET, NOT GATE. There are ~100 such legs in the corpus and most predate the idea.
Failing on all of them would make the suite permanently red, which trains readers to
ignore it (OBS-293). So the tool compares the UNCONTROLLED count against a committed
baseline and fails only when it RISES. Lowering the baseline is a deliberate edit.

DENOMINATOR IS REPORTED. Legs examined, legs classified, legs the parser could not
read. A census that silently skips what it cannot parse reports a clean corpus by
omission — the failure mode this whole task is about, one level up.
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASELINE = os.path.join(ROOT, "tools", "_t560-absence-baseline.txt")

# T560_TASK_ROOT retargets the scan at a synthetic tree. It exists for the teeth and
# for nothing else: planting mutant task files into the live `.tasks/active/` — the
# T-558 approach — would put fabricated tasks in front of a 15-minute audit cron and
# every artifact that counts active tasks, for however long the run takes. The env
# door is the smaller risk, and it is closed from the other side: teeth leg 5 runs the
# census with NO override and asserts it still reports the real corpus, so a mutant
# tree cannot be mistaken for the live one and an override left set cannot go unseen.
_task_root = os.environ.get("T560_TASK_ROOT") or os.path.join(ROOT, ".tasks")
TASK_DIRS = [os.path.join(_task_root, d) for d in ("active", "completed")]

# ── Absence forms ────────────────────────────────────────────────────────────────
# Anchored at a command boundary (start, ;, &&, ||, open paren) so that the word
# "grep" appearing inside a quoted pattern does not read as an invocation.
CMD_START = r"(?:^|[;&|(]\s*|&&\s*|\|\|\s*)"

FORMS = [
    ("bang-grep",     re.compile(CMD_START + r"!\s*grep\b")),
    ("test-z",        re.compile(CMD_START + r"(?:test|\[)\s+-z\b")),
    ("count-eq-zero", re.compile(r"-eq\s+0\b|\b0\s+-eq\b")),
    ("grep-v-only",   re.compile(r"\bgrep\s+-\w*v\w*\b")),
    ("zero-literal",  re.compile(r"grep\s+-q\s+(['\"])\^0\$\1")),
]

# `grep -c` compared against a NON-zero count is a presence assertion, not absence.
# Without this the `-eq` form sweeps in every count leg in the corpus.
NONZERO_EQ = re.compile(r"-eq\s+([1-9]\d*)\b|\b([1-9]\d*)\s+-eq\b")

# A zero-comparison is only an ABSENCE ASSERTION when the zero comes from a SEARCH.
# Found by dogfooding: this task's own suite leg is `test "$failed" -eq 0`, where the
# count comes from parsing a line the suite printed. If that parse breaks, the variable
# is empty and `test "" -eq 0` errors — it fails LOUD, which is the whole distinction
# this tool draws. Counting it would have made the census flag its own task and, worse,
# would have inflated the corpus number with legs that carry no silent-failure risk.
#
# T-844 — WHAT THIS ACTUALLY CATCHES IS WIDER THAN ITS NAME, AND THE WIDER READING IS
# THE RIGHT ONE. The rule is better stated as: a zero means NO WORK HAPPENED rather
# than NO MATCH. An empty search, an empty glob, and a loop that never iterated are the
# same defect. Measured over 37 count-eq-zero legs: 32 compare a substitution containing
# a search, 5 compare a bare variable — and 4 of those 5 are LOOP ACCUMULATORS
# (`n=0; for f in …/*.bpmn; do n=$((n+1)); done; test "$n" -eq 0`), which pass having
# measured nothing when the glob matches nothing. Verified: zero iterations leaves n=0
# and the test passes. So flagging them is correct, and an earlier proposal to exclude
# variable-operand zeros (OBS-376) would have traded one false positive for four false
# negatives. That proposal is withdrawn and the classifier is deliberately UNCHANGED —
# the only genuine false positive was one leg whose `rc` is assigned in both branches of
# an if/else, and it was given a control instead.
#
# TWO LIMITS OF THE CONTROL MODEL, FOUND THE SAME WAY, BOTH BIASED TOWARD FLAGGING A
# CONTROLLED LEG (OBS-377 and T-844):
#   - `len(p) >= 3` in control_level() means a pattern of one or two characters can NEVER
#     earn PATTERN credit. `^_` is two. A perfectly good same-string companion leg is
#     silently not counted, and the author has no way to tell from the output why.
#   - EXIST_CTRL matches only -f, -s and -d, so `test -x` is not recognised even though
#     -x implies -f.
# Neither is fixed here (one bug, one task). Both matter more than they did, because the
# classifier now gates closes rather than printing a report: a control it cannot see
# blocks a close and pushes the author toward the weaker form it can.
SEARCH_SOURCED = re.compile(r"\bgrep\b|\bfind\b|\bgit\s+(?:diff|status|ls-files)\b|\bls\b")

# Existence controls on the same line.
EXIST_CTRL = re.compile(
    CMD_START + r"(?:test|\[)\s+-[fsd]\s|"          # test -f / -s / -d
    r"\bgit\s+ls-files\b|"                          # materialises a file list first
    r">\s*/tmp/\.[\w.-]+"                           # captures output to a file it greps
)

# Pattern extraction: first quoted string after a grep invocation.
GREP_PAT = re.compile(r"\bgrep\b(?:\s+-{1,2}[\w-]+)*\s+(['\"])(.*?)(?<!\\)\1")


def verification_legs(path):
    """(lineno, text) for each executable line in the file's ## Verification block."""
    legs, inblock = [], False
    with open(path, encoding="utf-8", errors="replace") as fh:
        for i, line in enumerate(fh, 1):
            if line.startswith("## "):
                inblock = line.strip() == "## Verification"
                continue
            if not inblock:
                continue
            s = line.strip()
            if not s or s.startswith("#") or s.startswith("<!--") or s.startswith("-->"):
                continue
            legs.append((i, s))
    return legs


def classify(text):
    """Return the list of absence-form names this leg matches (possibly empty)."""
    matched = []
    for name, rx in FORMS:
        if not rx.search(text):
            continue
        if name == "count-eq-zero":
            if NONZERO_EQ.search(text):
                continue          # e.g. `test 3 -eq "$(grep -c …)"` — a presence assertion
            if not SEARCH_SOURCED.search(text):
                continue          # the zero is a parsed number, not an empty search result
        if name == "grep-v-only" and ("grep -q" in text or "grep -c" in text):
            # `... | grep -v X | grep -q .` asserts PRESENCE of the residue.
            continue
        matched.append(name)
    return matched


def patterns_in(text):
    return [m.group(2) for m in GREP_PAT.finditer(text)]


def control_level(text, sibling_texts):
    """PATTERN > EXISTENCE > NONE. Strongest applicable control wins.

    A sibling counts as a PATTERN control only when the SAME STRING IS ITSELF THE
    SIBLING'S GREP PATTERN. An earlier draft accepted any sibling whose text merely
    CONTAINED the pattern, and it over-credited immediately and in the direction that
    hides findings: T-301:283 (`test -f X && ! grep -q "workflowMeta" X`) was called
    PATTERN-controlled because a neighbouring census leg happened to mention
    `workflowMeta` inside a Python snippet. Mention is not invocation — the same
    distinction this corpus keeps relearning — and a control that is satisfied by a
    coincidence of substrings is worth less than no control at all, because it is
    recorded as coverage.
    """
    pats = [p for p in patterns_in(text) if len(p) >= 3]
    for sib in sibling_texts:
        if classify(sib):
            continue              # the sibling is itself an absence leg — not a control
        sib_pats = patterns_in(sib)
        for p in pats:
            if p in sib_pats:
                return "PATTERN"
    if EXIST_CTRL.search(text):
        return "EXISTENCE"
    return "NONE"


def _is_unparseable_absence(text):
    """An absence-shaped leg whose PATTERN the parser cannot extract.

    Same condition main() already uses for its `unparsed` denominator line, factored out
    so the close gate and the census cannot disagree about which legs are unreadable.
    These legs are NOT EVALUATED: reporting them as controlled would claim coverage the
    parser does not have, and reporting them as uncontrolled would block a close for a
    reason unrelated to the defect (T-3105's distinction, T-843).
    """
    return bool(classify(text)) and "grep" in text \
        and not patterns_in(text) and "test -z" not in text


def block_mode(argv):
    """T-843 — classify ONE verification block read from stdin, for the close gate.

    Exists so `find_uncontrolled_absence_legs` can shell to THIS classifier rather than
    re-implement it in bash (L-533: run this expression, not a re-typed copy). A bash
    re-implementation would drift, and then the corpus number and the close decision would
    mean different things.

    --uncontrolled  print legs the census would count (control level NONE)
    --unparseable   print absence legs whose pattern cannot be extracted (NOT EVALUATED)

    Exit 0 always: this is a reporter, not a verdict. The caller decides what to do with
    the lines, exactly as it does with find_port_literals.
    """
    want = "uncontrolled"
    if "--unparseable" in argv:
        want = "unparseable"

    texts = []
    for raw in sys.stdin.read().splitlines():
        s = raw.strip()
        if not s or s.startswith("#") or s.startswith("<!--") or s.startswith("-->"):
            continue
        texts.append(s)

    for text in texts:
        if not classify(text):
            continue
        unreadable = _is_unparseable_absence(text)
        if want == "unparseable":
            if unreadable:
                print(text)
            continue
        # An unreadable leg is neither controlled nor uncontrolled — it is unmeasured,
        # and it must not appear here or the gate fails a close over a parser limit.
        if unreadable:
            continue
        siblings = [t for t in texts if t != text]
        if control_level(text, siblings) == "NONE":
            print(text)
    return 0


def main():
    if "--block" in sys.argv:
        return block_mode(sys.argv)

    files = 0
    legs_seen = 0
    absence = []
    unparsed = 0

    for d in TASK_DIRS:
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            if not name.endswith(".md"):
                continue
            path = os.path.join(d, name)
            legs = verification_legs(path)
            if not legs:
                continue
            files += 1
            texts = [t for _, t in legs]
            for lineno, text in legs:
                legs_seen += 1
                forms = classify(text)
                if not forms:
                    continue
                if _is_unparseable_absence(text):
                    # An absence-shaped leg whose pattern the parser cannot extract.
                    # Counted and reported, never silently dropped. Predicate factored to
                    # _is_unparseable_absence so T-843's close gate classifies "unreadable"
                    # by the same rule this denominator line counts (L-533).
                    unparsed += 1
                siblings = [t for t in texts if t != text]
                absence.append((
                    os.path.relpath(path, ROOT), lineno,
                    ",".join(forms), control_level(text, siblings), text,
                ))

    uncontrolled = [a for a in absence if a[3] == "NONE"]
    existence = [a for a in absence if a[3] == "EXISTENCE"]
    pattern = [a for a in absence if a[3] == "PATTERN"]

    print("T-560 ABSENCE-ASSERTION CENSUS")
    print("=" * 78)
    print("DENOMINATOR   files with a ## Verification block : %d" % files)
    print("              executable legs examined           : %d" % legs_seen)
    print("              absence-asserting legs             : %d" % len(absence))
    print("              absence legs whose pattern the parser could not extract: %d"
          % unparsed)
    print()
    print("CONTROL       PATTERN   (a sibling leg proves the pattern matches) : %d"
          % len(pattern))
    print("              EXISTENCE (target proven to exist; pattern UNchecked): %d"
          % len(existence))
    print("              NONE      (nothing proves the search could succeed)  : %d"
          % len(uncontrolled))
    print()

    if uncontrolled:
        print("UNCONTROLLED ABSENCE ASSERTIONS")
        print("-" * 78)
        for relpath, lineno, forms, _, text in uncontrolled:
            print("%s:%d  [%s]" % (relpath, lineno, forms))
            print("    %s" % (text if len(text) <= 160 else text[:157] + "..."))
        print()

    count = len(uncontrolled)
    if not os.path.isfile(BASELINE):
        print("NO BASELINE at %s — write it with the current count to arm the ratchet."
              % os.path.relpath(BASELINE, ROOT))
        print("CURRENT UNCONTROLLED COUNT: %d" % count)
        return 2

    with open(BASELINE, encoding="utf-8") as fh:
        recorded = None
        for line in fh:
            line = line.strip()
            if line and not line.startswith("#"):
                recorded = int(line)
                break
    if recorded is None:
        print("BASELINE at %s holds no number." % BASELINE)
        return 2

    print("RATCHET       baseline %d, current %d" % (recorded, count))
    if count > recorded:
        print()
        print("FAIL: uncontrolled absence assertions ROSE from %d to %d." % (recorded, count))
        print("      A new Verification leg asserts something is absent and nothing")
        print("      establishes the search could have found it. Add a companion leg")
        print("      that greps the same pattern where it IS present, or assert the")
        print("      positive fact directly.")
        return 1
    if count < recorded:
        print()
        print("NOTE: count FELL from %d to %d. Lower the baseline in the same commit —"
              % (recorded, count))
        print("      leaving it high re-admits exactly that many silent legs.")
    print()
    print("PASS: no increase in uncontrolled absence assertions.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
