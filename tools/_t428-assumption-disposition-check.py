#!/usr/bin/env python3
"""
_t428-assumption-disposition-check.py — does every assumption still have somebody
whose job it is to answer it?

T-428.

THE QUESTION THIS ASKS
----------------------
Not "are there untested assumptions" — untested is the normal, healthy state of a
question that has just been asked. The question is whether the asking is still ATTACHED
to anything. An assumption whose owning task is closed is not an open question; it is an
abandoned one, and the register goes on presenting it in the same colour as a live one.

OBS-018 recorded the near-miss version: A-020 was answered NO on the rail, recorded in
T-357's Open Questions, and the register still read `untested` seven days later — long
enough that a build task got filed on the stale reading. That looked like a reconciliation
lag. Measured across the whole register it is not a lag: A-020 is the only assumption in
this project that was ever answered at all, and it was answered because a human asked on
the rail, not because anything checked.

WHAT `dangling` MEANS, AND WHY IT IS NOT `stale`
-----------------------------------------------
`dangling` = untested AND the linked_task is in completed/. It deliberately does NOT mean
"old". Age is not the defect — an assumption can sit untested for months while its task is
still being worked, and that is fine, someone owns it. The defect is the OWNER leaving.
Ranking by age would sort A-001 (July 2) to the top and A-016 (July 18) to the bottom while
telling you nothing about whether either is anybody's problem.

WHY `unevidenced` IS A SEPARATE VERDICT FROM `disposed`
-------------------------------------------------------
Because it is the shape this check will be used to launder if it is ever going to be.
`validated` with `evidence: []` is a status flip: the finding disappears and no record of
the answer is created. Splitting it out means the cheap way to clear a `dangling` row lands
in a different bucket that is still reported. At the time of writing the split costs
nothing — 4 of 4 disposed rows carry real evidence — which is exactly when to build it.

THE REMEDY IS NOT A COMMAND
---------------------------
Per OBS-017 (adopted from AEF rail 519 §2): a detector whose printed remedy clears the
finding without doing the work makes the miss permanent and green. `fw assumption validate
A-XXX` would do precisely that here. So this file prints no runnable remedy for `dangling`
— it names the two real dispositions (answer it with evidence, or re-link it to a task that
owns it) and leaves the doing to a human or a task. AC#3 greps this program's own output
for the laundering shape and fails if it ever appears.

EXIT
----
  0  no dangling, unevidenced or orphan rows
  1  findings — read them
  2  cannot answer (register unparseable, tasks dir missing) — never silent, and never
     the same exit code as "nothing found"
"""

import os
import sys

try:
    import yaml
except ImportError:
    print("UNKNOWN — pyyaml unavailable; this probe cannot answer.")
    sys.exit(2)

ROOT = os.environ.get("T428_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTER = os.path.join(ROOT, ".context", "project", "assumptions.yaml")
ACTIVE = os.path.join(ROOT, ".tasks", "active")
COMPLETED = os.path.join(ROOT, ".tasks", "completed")

DISPOSED_STATUSES = ("validated", "invalidated")


def task_location(task_id):
    """'active', 'completed', or None. Matches T-NNN- prefix, not substring: T-20 must
    not match T-201."""
    if not task_id:
        return None
    prefix = str(task_id).strip() + "-"
    for label, path in (("active", ACTIVE), ("completed", COMPLETED)):
        try:
            for name in os.listdir(path):
                if name.startswith(prefix) and name.endswith(".md"):
                    return label
        except OSError:
            return None
    return None


def classify(row):
    status = (row.get("status") or "").strip()
    where = task_location(row.get("linked_task"))
    if where is None:
        return "orphan"
    if status in DISPOSED_STATUSES:
        return "disposed" if row.get("evidence") else "unevidenced"
    return "dangling" if where == "completed" else "live"


def main():
    if not os.path.isdir(ACTIVE) or not os.path.isdir(COMPLETED):
        print("UNKNOWN — .tasks/active or .tasks/completed not found under %s." % ROOT)
        print("  Cannot tell an abandoned assumption from a live one without the task tree.")
        return 2
    try:
        with open(REGISTER, encoding="utf-8") as fh:
            data = yaml.safe_load(fh) or {}
    except (OSError, yaml.YAMLError) as exc:
        print("UNKNOWN — cannot parse %s: %s" % (REGISTER, exc))
        return 2

    rows = data.get("assumptions") or []
    if not rows:
        print("UNKNOWN — register parsed but carries no `assumptions:` list.")
        print("  An empty register and an unreadable one must not both look like PASS.")
        return 2

    buckets = {k: [] for k in ("dangling", "live", "disposed", "unevidenced", "orphan")}
    tbd = 0
    for row in rows:
        buckets[classify(row)].append(row)
        if (row.get("validation_method") or "").strip().upper() == "TBD":
            tbd += 1

    print("=== T-428 assumption disposition: does each one still have an owner? ===")
    print()
    print("  %-12s %s" % ("dangling", len(buckets["dangling"])))
    print("  %-12s %s" % ("live", len(buckets["live"])))
    print("  %-12s %s" % ("disposed", len(buckets["disposed"])))
    print("  %-12s %s" % ("unevidenced", len(buckets["unevidenced"])))
    print("  %-12s %s" % ("orphan", len(buckets["orphan"])))
    print()
    print("  validation_method still 'TBD': %d of %d" % (tbd, len(rows)))
    if tbd == len(rows) and rows:
        print("    Every row, including the disposed ones. The field is inert: it has never")
        print("    steered a single disposition. Reported, not failed on — it is a property")
        print("    of the register's design, and folding it into the counts would hide it.")

    if buckets["orphan"]:
        print()
        print("ORPHAN — linked_task resolves to no task file:")
        for row in buckets["orphan"]:
            print("  %-7s linked_task=%s" % (row.get("id"), row.get("linked_task")))

    if buckets["unevidenced"]:
        print()
        print("UNEVIDENCED — carries a disposition but no record of what produced it:")
        for row in buckets["unevidenced"]:
            print("  %-7s %s" % (row.get("id"), (row.get("status") or "?")))
        print("  A status without evidence is the flip, not the answer.")

    if buckets["dangling"]:
        print()
        print("DANGLING — still untested, and the task that would have answered it is closed:")
        by_task = {}
        for row in buckets["dangling"]:
            by_task.setdefault(str(row.get("linked_task")), []).append(row)
        for task_id in sorted(by_task):
            print("  %s (completed) owns %d:" % (task_id, len(by_task[task_id])))
            for row in by_task[task_id]:
                stmt = " ".join((row.get("statement") or "").split())
                print("    %-7s %s" % (row.get("id"), stmt[:96]))
        print()
        print("  There are two dispositions and neither of them is a status change:")
        print("    - answer it, and record what produced the answer in `evidence`; or")
        print("    - re-link it to a task that is actually going to carry it.")
        print("  Marking it disposed without evidence lands in UNEVIDENCED above, which is")
        print("  still a finding. There is no cheap exit from this list on purpose.")

    findings = len(buckets["dangling"]) + len(buckets["unevidenced"]) + len(buckets["orphan"])
    print()
    if findings == 0:
        print("PASS — every assumption is either disposed with evidence or owned by a live task.")
        return 0
    print("FINDINGS: %d assumption(s) with no owner and no answer." % findings)
    return 1


if __name__ == "__main__":
    sys.exit(main())
