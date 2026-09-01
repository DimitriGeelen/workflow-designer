#!/usr/bin/env python3
"""
T-534 teeth — does the D2 human-review-queue line name only tasks that meet the bar it states?

THE DEFECT. `audit.sh` accumulated `d2_details` in BOTH the >=720h (fail) and >=336h (warn)
branches, then the fail message printed the fail-tier COUNT against that shared list:

    D2: Human review queue — 2 task(s) waiting >30d: T-093(41d) T-178(36d) T-308(17d) T-310(17d) T-325(14d)

Count 2, list 5, three of them under the threshold the sentence states. PL-159 exactly: a bar
stated in a message string is not a bar the instrument holds.

WHY IT SURVIVED, and it is the reason this file drives all three tiers rather than one: the
defect is INVISIBLE unless both tiers are populated. With only fail-tier entries the shared
list happens to equal the fail list and every check agrees. A test built from a single aged
task would pass against the broken code — PL-206, a stimulus built so it cannot fail.

WHY IT DRIVES THE REAL audit.sh. The branch logic is four lines; re-implementing it here and
asserting against the copy would assert nothing about the subject. The seam is TASKS_DIR
(`lib/paths.sh:69`, `TASKS_DIR="${TASKS_DIR:-$PROJECT_ROOT/.tasks}"`), so a synthetic queue can
be handed to the real binary. A task enters the queue on `status: work-completed` +
`owner: human` + a parseable date (`active-task-scan.py:185`).

WHY --section discovery AND NOT --section oe-daily. D2 lives inside
`if should_run_section "discovery"` (audit.sh:3915), NOT under oe-daily. OBS-027 recorded that
`--section oe-daily` "never emits the D2 check" and inferred that a section behaves differently
alone than inside a full run; the real reason is that D2 was never an oe-daily check. Measured
under T-534: `--section oe-daily` and the same section inside a full run are byte-identical,
(65,27,0) both ways. Running the full audit here would cost 81s (216s against a synthetic
TASKS_DIR) to reach one line that `--section discovery` reaches in 7s.

T-667 (2026-09-01). T-656 gave D2 a second axis — signed-off vs awaiting-judgement — and this
file's parse was a transcription of the OLD sentence, anchored on `waiting >30d:`. T-656 made
that a semicolon. The parse then failed on every run and the file said so as an ABSTENTION,
which the sweep reads as needing no action; it became visible only when T-666 gave a dead
control its own exit code. Two repairs: the parse is now POSITIONAL (tier headers + token
regions, so intervening clauses may change freely), and the fragments it does depend on are
ASSERTED TO EXIST IN audit.sh before use, so the next rewording dies loudly naming what moved.

Legs:
  1  the D2 line is EMITTED and took the FAIL branch — the guard, because every leg below is a
     claim about the CONTENT of a line, and all of them are satisfied by silence if it is absent
  2  every task named under `>30d` actually has age >= 30d          <- THE DEFECT
  3  the >30d count equals the length of the >30d list — post-T-656 this is also what holds the
     audit to "names both kinds and keeps the total": the list is the union of the signed-off
     and awaiting-judgement groups, so counting both while naming one goes red, and so does
     naming both while counting one
  4  every task named under `>14d` has 14d <= age < 30d
  5  the >14d count equals the length of the >14d list
  6  the info-tier task (5d) is named in NEITHER list — guards against a "fix" that reconciles
     count with list by printing everything
  7  no task appears in both lists
  8  the parser DISCRIMINATES: replayed against the pre-fix line captured from the real binary,
     legs 2/3 go red and name the offending task. Without this, legs 2-7 green prove only that
     something was parsed, not that a violation would have been caught.

Exit 0 all legs pass, 1 a leg failed, 2 REFUSE (no D2 line, or the fixture did not reach the
FAIL branch — nothing was evaluated, and that is not a pass: PL-205), 4 DEAD CONTROL (a line
came back and THIS FILE could not parse it, or audit.sh no longer contains a fragment the
parse depends on — the instrument is broken, which is a different claim from declining to
look; T-666).
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta, timezone

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = os.path.join(REPO, ".agentic-framework/bin/fw")
AUDIT = os.path.join(REPO, ".agentic-framework/agents/audit/audit.sh")

# Tiers are the audit's own thresholds (audit.sh:3964,3967), restated as DAYS for the fixture.
# FAIL2/WARN2 are second members of the same tiers, added by T-667 so each tier carries one
# signed-off and one awaiting-judgement task.
FAIL_D, FAIL2_D, WARN_D, WARN2_D, INFO_D = 40, 35, 20, 18, 5

# (id, age_days, has_an_unticked_human_AC). The second field puts a task in a tier; the third
# decides which SIDE of that tier it lands on (audit.sh:4139 branches on `unticked -eq 0`).
QUEUE = (
    ("T-901", FAIL_D,  False),   # >30d, signed off        -> d2_fail_flip
    ("T-904", FAIL2_D, True),    # >30d, awaiting judgement-> d2_fail
    ("T-902", WARN_D,  False),   # >14d, signed off        -> d2_warn_flip
    ("T-905", WARN2_D, True),    # >14d, awaiting judgement-> d2_warn
    ("T-903", INFO_D,  False),   # below both tiers, must be named nowhere
)

# T-667. The literal fragments audit.sh composes the D2 FAIL line from. This file previously
# restated the format as one monolithic regex anchored on `waiting >30d:` — a colon that
# T-656 replaced with a semicolon when it split the queue into signed-off and
# awaiting-judgement groups. Nothing re-derived the claim, so the probe stopped parsing and
# said so only as an abstention, which reads as needing no action (until T-666 gave it rc 4).
#
# These are asserted to EXIST IN THE SUBJECT before being relied on. If the audit rewords D2
# again, this file dies loudly naming the fragment that moved, rather than silently failing
# to match. Same repair as the derived import list in T-665 and the derived pin in T-663:
# a hand-maintained claim about an artifact is re-derived, or it ages out in silence.
FORMAT_ANCHORS = (
    "task(s) waiting >30d",
    " awaiting judgement:",
    " signed off, awaiting only the status flip:",
    " waiting >14d",
    "(of which ",
    " signed off:",
)

# Captured from the real pre-fix binary on 2026-08-16 against the same 40/20/5 fixture, before
# the audit.sh change. Kept verbatim as a regression witness for leg 8. It proves the PARSER
# discriminates; it is not evidence about today's binary — legs 1-7 carry that.
PREFIX_WITNESS = ("[FAIL] D2: Human review queue — 1 task(s) waiting >30d: "
                  "T-901(40d) T-902(20d)")

# The two TIER HEADERS, each carrying that tier's own total. Everything between them is the
# >30d region and everything after the second is the >14d region — so the clauses BETWEEN the
# headers (`N awaiting judgement:`, `N signed off, awaiting only the status flip:`,
# `(of which N signed off: …)`) may be present, absent, or reordered without this file caring.
# It cares about two things only: the totals, and which region each task token falls in.
# That is the whole claim these legs make, and it is now expressed positionally instead of as
# a transcription of one particular sentence.
HDR30 = re.compile(r"D2: Human review queue — (\d+) task\(s\) waiting >30d")
HDR14 = re.compile(r";\s*(\d+) waiting >14d")
TOKEN = re.compile(r"(T-\d+)\((\d+)d\)")

failures = []
passes = 0


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — no leg was evaluated.")
    sys.exit(2)


def dead(msg):
    """T-666: rc 4 — these teeth are broken, as distinct from declining to look.

    refuse() is for a subject that is not there or has said nothing: nothing ran,
    nobody is at fault, and the sweep is right to file it as an abstention needing
    no action. This is the opposite case — the subject spoke and THIS FILE could not
    parse it, which means the anchor here has aged out of agreement with the audit.
    An abstention hides that; a dead control reports it.
    """
    print("TEETH BROKEN — %s" % msg)
    print("This is a DEAD CONTROL, not an abstention: the subject answered and the")
    print("expectation in this file is what failed to match it.")
    sys.exit(4)


def leg(name, ok, detail=""):
    global passes
    if ok:
        passes += 1
        print("  PASS  %s" % name)
    else:
        failures.append(name)
        print("  FAIL  %s%s" % (name, ("\n        " + detail) if detail else ""))


def build_queue(tmp):
    """A .tasks dir populating BOTH D2 axes: the age tier AND signed-off vs awaiting judgement.

    T-667: the original fixture wrote no `## Acceptance Criteria` section at all, so
    active-task-scan.py computed `unticked=0` for every task (:214-216) and all three landed
    in the signed-off group. Once T-656 split the message on that axis, the emitted line
    exercised only half the format the audit can produce — no `awaiting judgement:` clause was
    ever provoked, so no leg could observe one.

    That is this file's own PL-206 argument, one axis over. The docstring above already argues
    the age tiers must BOTH be populated or the count/list defect is invisible; the same holds
    for the signed-off split, and the fixture had silently stopped satisfying it.
    """
    active = os.path.join(tmp, ".tasks", "active")
    os.makedirs(active)
    os.makedirs(os.path.join(tmp, ".tasks", "completed"))
    os.makedirs(os.path.join(tmp, ".tasks", "templates"))
    now = datetime.now(timezone.utc)
    for tid, days, unticked in QUEUE:
        stamp = (now - timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ")
        # The scan strips HTML comments, then counts `- [ ]` inside `## Acceptance Criteria`
        # up to the next `## ` heading — so the trailing heading is load-bearing, not decor.
        box = "- [ ] a criterion nobody has ticked\n" if unticked else "- [x] ticked\n"
        with open(os.path.join(active, "%s-probe.md" % tid), "w") as fh:
            fh.write("---\nid: %s\nname: \"probe %dd\"\n"
                     "description: \"synthetic D2 queue probe (T-534 teeth)\"\n"
                     "status: work-completed\nworkflow_type: build\nowner: human\n"
                     "horizon: now\ncreated: %s\nlast_update: %s\ndate_finished: %s\n---\n"
                     "\n## Acceptance Criteria\n\n### Human\n%s\n## Verification\n"
                     % (tid, days, stamp, stamp, stamp, box))
    return os.path.join(tmp, ".tasks")


def d2_line(tasks_dir):
    env = dict(os.environ)
    env["TASKS_DIR"] = tasks_dir
    out = os.path.join(tempfile.gettempdir(), "t534-teeth-audit.yaml")
    p = subprocess.run([FW, "audit", "--section", "discovery", "--output", out],
                       cwd=REPO, env=env, capture_output=True, text=True,
                       timeout=600, check=False)
    for line in (p.stdout + p.stderr).splitlines():
        if "D2: Human review queue" in line:
            return line.strip()
    return None


def check_format_anchors():
    """Assert the fragments this file parses around still exist in audit.sh (T-667).

    Runs BEFORE the audit is invoked, because the useful message here is "the format
    moved, here is the fragment", not "a line I could not parse came back".
    """
    if not os.path.isfile(AUDIT):
        refuse("missing %s — the format cannot be derived, and asserting a regex against "
               "a subject that is not here would be a claim about nothing" % AUDIT)
    src = open(AUDIT, encoding="utf-8").read()
    i = src.find('d2_msg="D2: Human review queue')
    if i < 0:
        dead("audit.sh no longer composes a line starting `d2_msg=\"D2: Human review queue`. "
             "The D2 message was renamed or restructured, so every anchor below is a claim "
             "about a sentence that no longer exists.")
    block = src[i:i + 2500]
    missing = [a for a in FORMAT_ANCHORS if a not in block]
    if missing:
        dead("the D2 composition block in audit.sh no longer contains %d fragment(s) this "
             "file parses around: %s\n         This is the T-656 failure repeating: the "
             "audit's wording moved and the expectation here did not follow. Re-derive the "
             "parse from the block above rather than loosening it to match."
             % (len(missing), ", ".join(repr(m) for m in missing)))


def parse(line):
    """-> (fail_count, [(id, age)], warn_count, [(id, age)]) or None.

    Positional, not transcriptional: locate each tier header, take its own count, and
    attribute every `T-NNN(NNd)` token to the region it appears in. The >30d list is
    therefore the UNION of the awaiting-judgement and signed-off groups — which is exactly
    what the header counts (`$((d2_fail + d2_fail_flip))`, audit.sh:4183). T-656's commit
    message states the intent as "names both kinds and keeps the total"; leg 3 is what holds
    the audit to it, in either direction — counting both while listing one goes red, and so
    does listing both while counting one.
    """
    m30 = HDR30.search(line)
    if not m30:
        return None
    rest = line[m30.end():]
    m14 = HDR14.search(rest)
    if m14:
        fail_region, warn_region, wc = rest[:m14.start()], rest[m14.end():], int(m14.group(1))
    else:
        fail_region, warn_region, wc = rest, "", 0
    fl = [(t, int(a)) for t, a in TOKEN.findall(fail_region)]
    wl = [(t, int(a)) for t, a in TOKEN.findall(warn_region)]
    return int(m30.group(1)), fl, wc, wl


def check_line(line, label):
    """Run legs 2-5 against a parsed D2 line. Returns list of (leg_name, ok, detail)."""
    parsed = parse(line)
    if parsed is None:
        return None
    fc, fl, wc, wl = parsed
    bad30 = [(t, a) for t, a in fl if a < 30]
    bad14 = [(t, a) for t, a in wl if not (14 <= a < 30)]
    return [
        ("2 every task named under >30d actually has age >= 30d%s" % label,
         not bad30,
         "named under a '>30d' predicate but below it: %s. The sentence states a bar the "
         "instrument does not hold (PL-159); an operator reading this line sees a "
         "contradiction inside one clause." % bad30),
        ("3 the >30d count equals the length of the >30d list%s" % label,
         fc == len(fl) and fc > 0,
         "count=%d list=%d %s. A count and an enumeration that answer different questions "
         "make a FAIL line unusable as evidence for the thing it names." % (fc, len(fl), fl)),
        ("4 every task named under >14d has 14d <= age < 30d%s" % label,
         not bad14,
         "outside the >14d tier: %s" % bad14),
        ("5 the >14d count equals the length of the >14d list%s" % label,
         wc == len(wl),
         "count=%d list=%d %s" % (wc, len(wl), wl)),
    ]


if not os.path.isfile(FW):
    refuse("missing .agentic-framework/bin/fw — the subject is not here")

print("T-534 teeth — does the D2 line name only tasks that meet the bar it states?")
print("subject: .agentic-framework/agents/audit/audit.sh (D2 human review queue)")
print()

check_format_anchors()

tmp = tempfile.mkdtemp(prefix="t534-teeth-")
try:
    line = d2_line(build_queue(tmp))
    if line is None:
        refuse("the audit emitted no D2 line at all, so no claim below could be observed. "
               "Either the fixture did not populate the review queue (a task needs "
               "status=work-completed AND owner=human AND a parseable date_finished), or D2 "
               "moved out of --section discovery. Nothing was evaluated.")
    print("  line: %s" % line)
    print()

    parsed = parse(line)
    if parsed is None:
        dead("a D2 line was emitted but did not match the expected shape, so the legs "
               "below would be asserting against a failed parse rather than against the "
               "audit. Line was:\n         %s" % line)

    fc, fl, wc, wl = parsed
    leg("1 the D2 line is EMITTED and took the FAIL branch",
        "[FAIL]" in line and fc > 0,
        "line=%r. Every leg below is a claim about this line's CONTENT and is satisfied by "
        "silence if it is absent — so this guard runs first." % line)

    for name, ok, detail in check_line(line, ""):
        leg(name, ok, detail)

    named = [t for t, _ in fl] + [t for t, _ in wl]
    leg("6 the info-tier task (%dd) is named in NEITHER list" % INFO_D,
        "T-903" not in named,
        "T-903 is %dd old and below both thresholds; naming it would be a 'fix' that "
        "reconciles count with list by printing everything. named=%s" % (INFO_D, named))

    leg("7 no task appears in both lists",
        len(set(named)) == len(named),
        "duplicated across tiers: %s" % [t for t in set(named) if named.count(t) > 1])

    # ── leg 8: the parser must be shown to discriminate ────────────────────────────────────
    replay = check_line(PREFIX_WITNESS, "")
    if replay is None:
        leg("8 the parser discriminates — pre-fix witness is caught", False,
            "the stored pre-fix witness no longer parses, so this leg could not run and "
            "legs 2-5 above have no demonstrated red arm. Witness:\n        %s"
            % PREFIX_WITNESS)
    else:
        red = [n for n, ok, _ in replay if not ok]
        leg("8 the parser DISCRIMINATES — replaying the pre-fix line trips legs 2 and 3",
            len(red) >= 2 and any(n.startswith("2 ") for n in red)
            and any(n.startswith("3 ") for n in red),
            "replaying the captured pre-fix output tripped %r. Legs 2-7 passing on today's "
            "binary proves a violation would be CAUGHT only if this replay shows the legs "
            "can go red at all." % red)
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print()
total = passes + len(failures)
if failures:
    print("%d/%d legs passed — FAILED: %s" % (passes, total, ", ".join(failures)))
    sys.exit(1)
print("%d/%d legs passed" % (passes, total))
sys.exit(0)
