#!/usr/bin/env python3
"""T-1149 — check the 2026-10-13 observation triage is complete and every answer is backed.

Reads the triage report's per-item table (docs/reports/T-1149-observation-triage.md) and
.context/inbox.yaml, and fails when:
  - the table lists fewer than 100 observations (the triage was of 138; a truncated table is caught),
  - a listed observation is still pending in the inbox,
  - its inbox status disagrees with the answer in the table,
  - a resolved one's carrier does not resolve (task file under .tasks/, or a tracked path),
  - a promoted one's task does not exist, or is not the task named in the table.
A promoted observation is recorded with `fw note resolve --carrier <new task>`, not `fw note promote`:
promote names the task with the observation's full text; the new task gets a real name instead.
Prints one line per failure and a summary; exit 0 only when there are none.
"""
import glob
import re
import subprocess
import sys

import yaml

REPORT = "docs/reports/T-1149-observation-triage.md"
ROW = re.compile(r"^\| (OBS-\d+) \| (resolve|dismiss|promote) \| ([^|]*) \|")
STATUS = {"resolve": "resolved", "dismiss": "dismissed", "promote": "resolved"}


def carrier_exists(c):
    c = c.strip().strip("`")
    if re.fullmatch(r"T-\d+", c):
        return bool(glob.glob(".tasks/*/%s-*.md" % c))
    return subprocess.run(["git", "ls-files", "--error-unmatch", c],
                          capture_output=True).returncode == 0


def main():
    rows = [m.groups() for m in map(ROW.match, open(REPORT, encoding="utf-8")) if m]
    inbox = {o["id"]: o for o in yaml.safe_load(open(".context/inbox.yaml"))["observations"]}
    bad = []
    if len(rows) < 100:
        bad.append("report lists only %d observations" % len(rows))
    for oid, answer, target in rows:
        o = inbox.get(oid)
        if o is None:
            bad.append("%s: not in the inbox" % oid)
            continue
        if o.get("status") != STATUS[answer]:
            bad.append("%s: inbox status %r, report says %s" % (oid, o.get("status"), answer))
        carrier = str(o.get("resolved_carrier") or "")
        if answer != "dismiss" and not carrier_exists(carrier):
            bad.append("%s: carrier %r does not resolve" % (oid, carrier))
        if answer == "promote" and carrier != target.strip().strip("`"):
            bad.append("%s: carrier %r is not the new task %r" % (oid, carrier, target.strip()))
    for b in bad:
        print("FAIL", b)
    print("%d observations checked, %d failures" % (len(rows), len(bad)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
