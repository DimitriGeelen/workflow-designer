#!/usr/bin/env python3
"""T-535 teeth — the audit's trend detector must aggregate an issue whose NUMBERS move.

Drives the REAL audit binary (.agentic-framework/agents/audit/audit.sh, vendored) against a
controlled corpus of audit records supplied through the AUDITS_DIR seam. Nothing in the real
.context/audits is read or written: the sandbox holds the corpus AND receives the run's output.

WHAT IS UNDER TEST
    audit.sh's TREND ANALYSIS block keyed its counter on the verbatim rendered check string, so
    any check embedding its own measurement minted a fresh key every run and could never reach
    the count>=3 threshold. Measured on this project's real 9-audit window before the fix: the
    fabric edges warn was present in 9 of 9 audits, the drift warn in 8, the coverage warn in 7,
    and exactly ONE line was ever promoted — and only because its reading held still for three
    consecutive days. The detector fired on STASIS while labelled recurrence.

WHY THE OVER-MERGE LEG IS NOT DECORATION
    The obvious repair, s/[0-9]+/N/, collapses "CTL-028: ..." and "CTL-029: ..." — two DIFFERENT
    controls — into one key and manufactures a recurrence across unrelated checks. Leg 4 builds
    exactly that pair and fails if they merge. It is the leg most likely to go red under a
    well-meaning simplification of the normaliser.

DATES ARE COMPUTED FROM TODAY, NEVER PINNED (G-015)
    The trend reader applies a 14-day rolling window. A corpus with hardcoded dates passes today
    and silently reports "no repeated issues" — indistinguishable from health — once it ages out.
    Leg 0 REFUSES (rc 2) rather than pass if the run yields no trend section at all.

Exit codes:  0 = all legs green   1 = a leg is red   2 = REFUSE (could not establish the stimulus)
"""

import datetime
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = os.path.join(ROOT, ".agentic-framework", "bin", "fw")

# The corpus: 5 consecutive days ending yesterday. Each day carries the same four issues.
DAYS = 5

# An issue whose numbers move every single day. Under the pre-fix key it scores 1, forever.
MOVER = 'Fabric: {a}/{b} cards have no edges'
# Two DIFFERENT controls whose text differs only in digits — the over-merge trap.
CTL_A = "CTL-028: T-901 is in .tasks/completed/ but frontmatter status='started-work'"
CTL_B = "CTL-029: T-901 is in .tasks/completed/ but frontmatter status='started-work'"
# Present on only 2 of the 5 days — must stay BELOW the threshold, so green is a classification
# and not merely "the detector prints everything it sees".
RARE = 'Solitary drift: {a} orphan(s) detected'

# Replayed through this script's own parser (leg 5). This is what the PRE-FIX renderer emitted on
# the real tree — note the count leaking into the text from `cut -d' ' -f2-` on uniq -c's padded
# output, a second defect in the same block. If the parser cannot tell this from a fixed line, a
# green run proves nothing.
PRE_FIX_WITNESS = "  -      3 Fabric: 36/40 cards have no edges (3 times)"

LINE_RE = re.compile(r'^\s*-\s+(?P<text>.*?)\s+\((?P<count>\d+) times\)\s*$')


def refuse(msg):
    print("REFUSE: %s" % msg)
    sys.exit(2)


def parse_trend(stdout):
    """Return (present, [(text, count), ...]). `present` is False if no trend section rendered."""
    if "=== TREND ANALYSIS ===" not in stdout:
        return False, []
    body = stdout.split("=== TREND ANALYSIS ===", 1)[1]
    body = body.split("Audit history:", 1)[0]
    if "Repeated issues detected" not in body:
        return True, []
    out = []
    for line in body.splitlines():
        m = LINE_RE.match(line)
        if m:
            out.append((m.group("text"), int(m.group("count"))))
    return True, out


def write_corpus(sandbox):
    today = datetime.date.today()
    for i in range(1, DAYS + 1):
        day = today - datetime.timedelta(days=i)
        checks = [
            MOVER.format(a=30 + i, b=40 + i),
            CTL_A,
            CTL_B,
        ]
        if i <= 2:
            checks.append(RARE.format(a=i))
        lines = ["date: %s" % day.isoformat(), "checks:"]
        for c in checks:
            lines += ['  - level: WARN', '    check: "%s"' % c, '    mitigation: "n/a"']
        with open(os.path.join(sandbox, "%s.yaml" % day.isoformat()), "w", encoding="utf-8") as fh:
            fh.write("\n".join(lines) + "\n")


def main():
    if not os.path.isfile(FW):
        refuse("fw not found at %s" % FW)

    sandbox = tempfile.mkdtemp(prefix="t535-trend-")
    try:
        write_corpus(sandbox)
        env = dict(os.environ, AUDITS_DIR=sandbox)
        proc = subprocess.run([FW, "audit", "--section", "structure"],
                              cwd=ROOT, env=env, capture_output=True, text=True, timeout=600)
        stdout = proc.stdout + proc.stderr
    finally:
        shutil.rmtree(sandbox, ignore_errors=True)

    present, issues = parse_trend(stdout)

    # Leg 0 — REFUSE, not pass, when the stimulus could not be established. A reader that breaks
    # renders as "no repeated issues", which reads exactly like health.
    if not present:
        refuse("audit produced no TREND ANALYSIS section — stimulus not established")
    if not issues:
        refuse("trend section rendered but reported nothing; the %d-day corpus should promote "
               "at least the mover" % DAYS)

    by_text = dict(issues)
    failures = []

    # Leg 1 — the issue whose numbers move every day aggregates to the full corpus depth.
    movers = [(t, c) for t, c in issues if "cards have no edges" in t]
    if len(movers) != 1:
        failures.append("leg1: expected exactly 1 aggregated 'cards have no edges' entry, got %r"
                        % (movers,))
    elif movers[0][1] != DAYS:
        failures.append("leg1: mover aggregated to %d, expected %d — a check embedding its own "
                        "measurement is still minting a key per run" % (movers[0][1], DAYS))

    # Leg 2 — the rendered text is a CONCRETE reading, not the normalised key.
    if movers and re.search(r'\bN\b', movers[0][0]):
        failures.append("leg2: rendered line shows the normalised key %r instead of a real "
                        "reading" % movers[0][0])

    # Leg 3 — the count is not also leaking into the text (the pre-fix `cut -d' ' -f2-` defect).
    for text, _ in issues:
        if re.match(r'^\d+\s', text):
            failures.append("leg3: count leaked into rendered text: %r" % text)

    # Leg 4 — THE OVER-MERGE GUARD. CTL-028 and CTL-029 differ only in digits and must not fuse.
    ctl = [(t, c) for t, c in issues if "started-work" in t]
    if len(ctl) != 2:
        failures.append("leg4: expected CTL-028 and CTL-029 to stay distinct (2 entries), got %d: "
                        "%r — the normaliser is folding identifier tokens" % (len(ctl), ctl))
    else:
        if not any("CTL-028" in t for t, _ in ctl) or not any("CTL-029" in t for t, _ in ctl):
            failures.append("leg4: both control ids must survive normalisation, got %r" % (ctl,))
        for t, c in ctl:
            if c != DAYS:
                failures.append("leg4: %r counted %d, expected %d (a merge would show %d)"
                                % (t, c, DAYS, 2 * DAYS))

    # Leg 5 — anti-vacuity: the threshold still discriminates. RARE appears on 2 of 5 days.
    if any("Solitary drift" in t for t, _ in issues):
        failures.append("leg5: an issue present on 2 of %d days was promoted; the count>=3 "
                        "threshold is not being applied" % DAYS)

    # Leg 6 — the parser can tell a pre-fix render from a fixed one. Without this, every leg above
    # could be passing on a parser that matches nothing.
    m = LINE_RE.match(PRE_FIX_WITNESS)
    if not m:
        failures.append("leg6: parser does not match the stored pre-fix witness at all")
    else:
        if not re.match(r'^\d+\s', m.group("text")):
            failures.append("leg6: parser did not detect the count leak in the pre-fix witness "
                            "%r — leg3 is therefore untested" % m.group("text"))
        if int(m.group("count")) != 3:
            failures.append("leg6: parser misread the pre-fix witness count")

    print("T-535 trend-key teeth — corpus %d days, %d issue(s) promoted" % (DAYS, len(issues)))
    for t, c in issues:
        print("    %2d x  %s" % (c, t))
    legs = 7
    if failures:
        print("\n%d/%d legs FAILED:" % (len(failures), legs))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("\n%d/%d legs green" % (legs, legs))
    return 0


if __name__ == "__main__":
    sys.exit(main())
