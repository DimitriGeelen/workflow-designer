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

Legs:
  1  the D2 line is EMITTED and took the FAIL branch — the guard, because every leg below is a
     claim about the CONTENT of a line, and all of them are satisfied by silence if it is absent
  2  every task named under `>30d` actually has age >= 30d          <- THE DEFECT
  3  the >30d count equals the length of the >30d list
  4  every task named under `>14d` has 14d <= age < 30d
  5  the >14d count equals the length of the >14d list
  6  the info-tier task (5d) is named in NEITHER list — guards against a "fix" that reconciles
     count with list by printing everything
  7  no task appears in both lists
  8  the parser DISCRIMINATES: replayed against the pre-fix line captured from the real binary,
     legs 2/3 go red and name the offending task. Without this, legs 2-7 green prove only that
     something was parsed, not that a violation would have been caught.

Exit 0 all legs pass, 1 a leg failed, 2 REFUSE (no D2 line, or the fixture did not reach the
FAIL branch — nothing was evaluated, and that is not a pass: PL-205).
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

# Tiers are the audit's own thresholds (audit.sh:3964,3967), restated as DAYS for the fixture.
FAIL_D, WARN_D, INFO_D = 40, 20, 5

# Captured from the real pre-fix binary on 2026-08-16 against the same 40/20/5 fixture, before
# the audit.sh change. Kept verbatim as a regression witness for leg 8. It proves the PARSER
# discriminates; it is not evidence about today's binary — legs 1-7 carry that.
PREFIX_WITNESS = ("[FAIL] D2: Human review queue — 1 task(s) waiting >30d: "
                  "T-901(40d) T-902(20d)")

D2_RE = re.compile(r"D2: Human review queue — (\d+) task\(s\) waiting >30d:([^;]*)"
                   r"(?:;\s*(\d+) waiting >14d:(.*))?$")
TOKEN = re.compile(r"(T-\d+)\((\d+)d\)")

failures = []
passes = 0


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — no leg was evaluated.")
    sys.exit(2)


def leg(name, ok, detail=""):
    global passes
    if ok:
        passes += 1
        print("  PASS  %s" % name)
    else:
        failures.append(name)
        print("  FAIL  %s%s" % (name, ("\n        " + detail) if detail else ""))


def build_queue(tmp):
    """A .tasks dir whose active/ holds one task in each D2 tier."""
    active = os.path.join(tmp, ".tasks", "active")
    os.makedirs(active)
    os.makedirs(os.path.join(tmp, ".tasks", "completed"))
    os.makedirs(os.path.join(tmp, ".tasks", "templates"))
    now = datetime.now(timezone.utc)
    for tid, days in (("T-901", FAIL_D), ("T-902", WARN_D), ("T-903", INFO_D)):
        stamp = (now - timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%SZ")
        with open(os.path.join(active, "%s-probe.md" % tid), "w") as fh:
            fh.write("---\nid: %s\nname: \"probe %dd\"\n"
                     "description: \"synthetic D2 queue probe (T-534 teeth)\"\n"
                     "status: work-completed\nworkflow_type: build\nowner: human\n"
                     "horizon: now\ncreated: %s\nlast_update: %s\ndate_finished: %s\n---\n"
                     % (tid, days, stamp, stamp, stamp))
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


def parse(line):
    """-> (fail_count, [(id, age)], warn_count, [(id, age)]) or None."""
    m = D2_RE.search(line)
    if not m:
        return None
    fc = int(m.group(1))
    fl = [(t, int(a)) for t, a in TOKEN.findall(m.group(2) or "")]
    wc = int(m.group(3)) if m.group(3) else 0
    wl = [(t, int(a)) for t, a in TOKEN.findall(m.group(4) or "")]
    return fc, fl, wc, wl


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
        refuse("a D2 line was emitted but did not match the expected shape, so the legs "
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
