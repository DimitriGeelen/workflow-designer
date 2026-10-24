#!/usr/bin/env python3
"""_t952 — a ratchet on the bridge suite's failure count, read from its run history.

WHY A RATCHET AND NOT A GATE. The suite is not green: the last completed run measured
122 passed, 32 failed. A scheduled caller that fails every single night trains the reader
to ignore it, which is the decay this project has already been burned by twice — the 1362
merged divergence count (T-945) and the 27-item GO-scope warning with one real item in it
(T-949). So: today's failure count is a recorded FLOOR. A rise fails loudly. A fall is
reported as "the floor can be lowered" and changes nothing on its own, because tightening
a floor should have a commit behind it.

WHY IT READS HISTORY RATHER THAN RUNNING THE SUITE. tests/run-bridge-tests.sh already
appends one row per run to tests/.run-history.tsv from an exit trap, so red and interrupted
runs are recorded too (T-813). Separating the runner from the reader means this stays
cheap enough to sit in an audit — which is the thing that was missing, since nothing in
audit.sh reads either the history or _t813-suite-age.py today.

THE ROW-SELECTION RULE IS LOAD-BEARING, and it is not "the last row".

    2026-09-30T10:42:45Z   73   16   143   321
    2026-09-30T10:45:06Z   64   12   143   118
    2026-09-30T13:57:30Z  122   32     1   999

The 143 rows are runs killed by SIGTERM — a timeout, in fact mine, earlier today. They
record real-looking counts from a partial sweep: 16 failures, then 12. A ratchet reading
the newest row would have seen 12 against a floor of 32 and cheerfully announced a
twenty-failure improvement. That is the same defect as reading a mid-sweep log, except
persisted to disk where it outlives the mistake. Only rc 0 (all passed) and rc 1 (ran,
had failures) describe a completed sweep; everything else is discarded, and discarded
LOUDLY so a run that never completes cannot pass as an improvement.

STALENESS IS A FAILURE HERE, unlike in _t813. That tool deliberately refuses to gate on
age because no threshold had been agreed. Now one has: the suite is scheduled nightly, so
two consecutive misses (48h) means the schedule is broken, and a ratchet that cannot see a
fresh run must not report the floor as held.

Exit: 0 floor held (or can be lowered) · 1 floor breached, or stale, or unmeasurable.
"""
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

PROJ = Path(os.environ.get("T952_PROJ", Path(__file__).resolve().parent.parent))
HISTORY = PROJ / "tests/.run-history.tsv"
BASELINE = PROJ / "tools/_t952-bridge-baseline.txt"

# T-1163: the suite is NOT scheduled — T-917 chose a cheap monitor over a 40-minute browser suite on a timer
# (.context/cron-registry.yaml, bridge-suite-age-daily). It runs by hand, so a week without a completed run is the
# signal; the old 48h limit assumed a nightly schedule that never existed and failed every quiet weekend.
STALE_AFTER = timedelta(days=7)

COMPLETED_RCS = (0, 1)


def read_baseline():
    if not BASELINE.is_file():
        return None, f"{BASELINE.relative_to(PROJ)} does not exist"
    for line in BASELINE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split("|", 1)]
        try:
            return int(parts[0]), (parts[1] if len(parts) > 1 else "(no reason recorded)")
        except ValueError:
            return None, f"first non-comment line is not an integer: {line[:60]!r}"
    return None, "no non-comment line found"


def read_history():
    """-> (completed_rows, discarded_rows, error)"""
    if not HISTORY.is_file():
        return [], [], f"{HISTORY.relative_to(PROJ)} does not exist — the suite has " \
                       f"never run since recording began. That is not zero failures."
    completed, discarded = [], []
    for n, line in enumerate(HISTORY.read_text().splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 5:
            discarded.append((n, line[:60], "malformed"))
            continue
        try:
            when = datetime.fromisoformat(parts[0].replace("Z", "+00:00"))
            row = {"when": when, "pass": int(parts[1]), "fail": int(parts[2]),
                   "rc": int(parts[3]), "dur": int(parts[4]), "line": n}
        except ValueError:
            discarded.append((n, line[:60], "unparseable"))
            continue
        # T-1288: a 7th column names the tier. Only an `all` row (or a pre-T-1288 row, which has none) is a
        # whole sweep; a core/browser/sweep row counts a subset and must not read as the suite's failure count.
        if len(parts) >= 7 and parts[6] != "all":
            continue
        if row["rc"] in COMPLETED_RCS:
            completed.append(row)
        else:
            discarded.append((n, line[:60], f"rc={row['rc']} — run did not complete"))
    completed.sort(key=lambda r: r["when"])
    return completed, discarded, None


def main():
    print("=== T-952: bridge-suite failure ratchet ===")
    print()

    floor, why = read_baseline()
    completed, discarded, err = read_history()

    if err:
        print(f"FAIL: cannot measure — {err}")
        return 1
    if floor is None:
        print(f"FAIL: cannot measure — no usable baseline ({why})")
        print(f"      Record one as a single integer, optionally '<n> | <reason>', in "
              f"{BASELINE.relative_to(PROJ)}.")
        return 1

    if discarded:
        # Reported, never silently dropped: these are the rows that would have lied.
        print(f"discarded {len(discarded)} history row(s) that do not describe a "
              f"completed sweep:")
        for n, snippet, reason in discarded[-5:]:
            print(f"  line {n}: {reason}")
        if len(discarded) > 5:
            print(f"  ... and {len(discarded) - 5} more")
        print()

    if not completed:
        print("FAIL: cannot measure — the history contains no COMPLETED run.")
        print("      Rows exist, but every one was killed or malformed. A partial sweep's")
        print("      counts are not a result, and must not be read as an improvement.")
        return 1

    latest = completed[-1]
    age = datetime.now(timezone.utc) - latest["when"]
    print(f"baseline floor : {floor} failure(s)   ({why})")
    print(f"latest complete: {latest['fail']} failure(s), {latest['pass']} passed, "
          f"rc={latest['rc']}, {latest['dur']}s")
    print(f"               : {latest['when'].isoformat()}  "
          f"({age.days}d {age.seconds // 3600}h old)")
    print(f"completed runs : {len(completed)} of {len(completed) + len(discarded)} rows")
    print()

    rc = 0

    if age > STALE_AFTER:
        print(f"FAIL: the newest completed run is {age.days}d {age.seconds // 3600}h old, "
              f"past the {STALE_AFTER.days}-day limit.")
        print("      The suite runs by hand (it is deliberately not scheduled, T-917), so nobody has")
        print("      run it for a week: run tests/run-bridge-tests.sh. A floor cannot be 'held' by a")
        print("      measurement nobody took.")
        rc = 1

    # T-1163 (OBS-459): the failure count moves run to run at the same commit (one flaky leg: 33 then 34), so a
    # single run above the floor is not yet a regression. A rise is CONFIRMED when the two newest completed runs are
    # both above the floor; one run above it is reported loudly as UNCONFIRMED and the next run settles it.
    previous = completed[-2] if len(completed) > 1 else None
    if latest["fail"] > floor and previous is not None and previous["fail"] > floor:
        print(f"FAIL: failures ROSE — {latest['fail']} against a floor of {floor} "
              f"(+{latest['fail'] - floor}), confirmed by the run before it ({previous['fail']}).")
        print("      Something that used to pass now fails. Fix it, or move the floor")
        print("      deliberately with a reason, which is a commit and not an edit.")
        rc = 1
    elif latest["fail"] > floor:
        print(f"WARN: UNCONFIRMED RISE — {latest['fail']} against a floor of {floor} "
              f"(+{latest['fail'] - floor}) in the newest run only "
              f"({'the run before held at %d' % previous['fail'] if previous else 'no earlier completed run'}).")
        print("      One flaky leg moves this count (OBS-459). Run the suite again: a second run above")
        print("      the floor confirms the rise and fails this ratchet; a run at or under it clears it.")
    elif latest["fail"] < floor:
        print(f"OK — and the floor CAN BE LOWERED: {latest['fail']} < {floor} "
              f"({floor - latest['fail']} fewer).")
        print(f"      Nothing is changed automatically. Tightening is a decision: set "
              f"{BASELINE.relative_to(PROJ)} to {latest['fail']} with a reason.")
    else:
        print(f"OK — floor held at exactly {floor}.")

    return rc


if __name__ == "__main__":
    sys.exit(main())
