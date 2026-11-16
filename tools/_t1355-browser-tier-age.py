#!/usr/bin/env python3
"""_t1355-browser-tier-age.py — when did the browser tier last run, and has the framework moved since?

T-1355. Pushes run only the core tier (T-1288) and so do the upgrade jobs; the browser tier runs when someone runs it.
Two browser legs went red with the be.31 upgrade and T-1262/T-1271 (2026-10-27/28) and nobody saw it for days
(T-1351, T-1352). _t813-suite-age.py reports full runs only, to syslog. This prints the one line the session-start
alerts show every session.

Reads tests/.run-history.tsv (one row per suite run, appended by tests/run-bridge-tests.sh): ts, passed, failed,
exit, seconds, sha[, tier, flaky, quarantined]. A row with tier `browser` counts, and so does a full run (no tier
column, or `all`), which includes the browser legs.

  OK      last run green, within MAX_AGE_DAYS, and no commit to .agentic-framework/ after it
  RED     last run had failures (named first: a red run is red whatever its age)
  STALE   green, but the vendored framework has a commit after it, or it is older than MAX_AGE_DAYS

Exit: 0 OK | 1 RED or STALE | 3 no browser run recorded (NOT CHECKED — no history is not a green run)
Env (tests): T1355_HISTORY, T1355_REPO (git repo to ask for the framework's last commit), T1355_NOW (ISO time).
"""
import os
import subprocess
import sys
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HISTORY = os.environ.get("T1355_HISTORY", os.path.join(ROOT, "tests", ".run-history.tsv"))
REPO = os.environ.get("T1355_REPO", ROOT)
MAX_AGE_DAYS = 7
FRAMEWORK = ".agentic-framework"


def ts(s):
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def last_browser_run():
    last = None
    with open(HISTORY) as fh:
        for line in fh:
            p = line.rstrip("\n").split("\t")
            if len(p) < 6:
                continue
            tier = p[6] if len(p) > 6 else "all"
            if tier not in ("browser", "all"):
                continue
            try:
                row = {"at": ts(p[0]), "passed": int(p[1]), "failed": int(p[2]), "sha": p[5][:9], "tier": tier}
            except ValueError:
                continue
            if last is None or row["at"] >= last["at"]:
                last = row
    return last


# T-1423 (G-094): inputs the browser harnesses read, besides their own code. A commit to any of them after the last
# browser run makes that run stale. The corpus was missing: T-876 changed only examples/aef-processes/ and turned a
# browser harness red, unseen for a day.
WATCHED = ((FRAMEWORK, "the vendored framework"), ("examples/aef-processes", "the corpus (examples/aef-processes)"))


def changed_at(path):
    r = subprocess.run(["git", "-C", REPO, "log", "-1", "--format=%cI", "--", path],
                       capture_output=True, text=True, timeout=30)
    out = r.stdout.strip()
    return ts(out) if r.returncode == 0 and out else None


def main():
    try:
        run = last_browser_run()
    except OSError as e:
        print("NOT CHECKED — no run history (%s)" % e)
        return 3
    if run is None:
        print("NOT CHECKED — no browser-tier run recorded; run: bash tests/run-bridge-tests.sh --tier browser")
        return 3
    now = ts(os.environ["T1355_NOW"]) if os.environ.get("T1355_NOW") else datetime.now(timezone.utc)
    days = (now - run["at"]).total_seconds() / 86400
    what = "%s run %.1fd ago at %s (%d passed, %d failed)" % (run["tier"], days, run["sha"], run["passed"], run["failed"])
    if run["failed"]:
        print("RED: last %s — run: bash tests/run-bridge-tests.sh --tier browser" % what)
        return 1
    moved = [(label, at) for path, label in WATCHED for at in [changed_at(path)] if at is not None and at > run["at"]]
    if moved:
        print("STALE: last %s; %s changed since — run: bash tests/run-bridge-tests.sh --tier browser"
              % (what, " and ".join("%s (%s)" % (label, at.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%MZ"))
                                    for label, at in moved)))
        return 1
    if days > MAX_AGE_DAYS:
        print("STALE: last %s, older than %d days — run: bash tests/run-bridge-tests.sh --tier browser" % (what, MAX_AGE_DAYS))
        return 1
    print("OK: last %s" % what)
    return 0


if __name__ == "__main__":
    sys.exit(main())
