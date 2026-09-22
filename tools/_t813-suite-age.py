#!/usr/bin/env python3
"""_t813-suite-age.py — how old is the gating suite's current failure state?

T-813, value review finding F-03.

THE QUESTION THIS ANSWERS, which nothing in this repo could answer before: the bridge suite
reports "131 passed, 7 failed". Are those seven failures seven hours old or seven weeks old?
F-03: "no test-run artefact exists anywhere in the tree, so the age of the 7 failures is
unknowable — UNMEASURED, not zero." Seven fresh failures and seven ancient ones are entirely
different findings and nothing could tell them apart. The same absence is why F-09's golden
drift has no knowable age.

tests/run-bridge-tests.sh now appends one record per run (exit-trapped, so red and
interrupted runs are recorded too). This reads them.

THE DISTINCTION THIS TOOL EXISTS TO PRESERVE: **no history is not zero failures.** An empty
or missing file means nobody has run the suite since recording began — which is precisely the
F-03 condition, not a clean bill of health. It exits 3 (could-not-measure) rather than 0.
That mirrors the release-lag probe's own convention, for the same reason: an unmeasured leg
reported as ok is how absence starts carrying a decision.

NOT A GATE. It reports; it does not fail a build on age. What threshold makes a stale suite
unacceptable is a judgement nobody has recorded, and inventing one inside a reader would be
the "fitted the gate to the tree" mistake the release-lag thresholds comment warns about.

Exit: 0 history read and reported | 3 no history to read
"""

import os
import sys
from datetime import datetime, timezone

REPO = os.environ.get(
    "T813_REPO_ROOT",
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
)
HISTORY = os.path.join(REPO, "tests", ".run-history.tsv")


def parse(path):
    rows = []
    with open(path) as fh:
        for n, line in enumerate(fh, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 6:
                # A malformed row is reported, not skipped: silently dropping rows makes
                # the history shorter and healthier-looking than it is.
                print(f"  WARNING: {os.path.basename(path)}:{n} malformed, ignored: "
                      f"{line[:60]!r}", file=sys.stderr)
                continue
            ts, npass, nfail, rc, dur, sha = parts[:6]
            try:
                when = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                rows.append({"when": when, "pass": int(npass), "fail": int(nfail),
                             "rc": int(rc), "dur": int(dur), "sha": sha})
            except ValueError:
                print(f"  WARNING: {os.path.basename(path)}:{n} unparseable, ignored",
                      file=sys.stderr)
    return rows


def main():
    if not os.path.exists(HISTORY) or os.path.getsize(HISTORY) == 0:
        print("=== T-813 gating-suite run history (F-03) ===")
        print()
        print("  NO HISTORY. The suite has not been run since recording began.")
        print()
        print("  This is NOT 'zero failures' — it is the F-03 condition itself: a 742s suite")
        print("  that nothing schedules, whose failure age is unmeasured. Run it once to")
        print("  start the record:")
        print("     cd %s && bash tests/run-bridge-tests.sh" % REPO)
        return 3

    rows = parse(HISTORY)
    if not rows:
        print("history file exists but holds no usable records — see warnings above",
              file=sys.stderr)
        return 3

    rows.sort(key=lambda r: r["when"])
    latest = rows[-1]
    now = datetime.now(timezone.utc)

    print("=== T-813 gating-suite run history (F-03) ===")
    print(f"records: {len(rows)}   first: {rows[0]['when']:%Y-%m-%d}   "
          f"latest: {latest['when']:%Y-%m-%d %H:%M}Z")
    print()
    age_days = (now - latest["when"]).days
    print(f"  latest run: {latest['pass']} passed, {latest['fail']} failed, "
          f"exit {latest['rc']}, {latest['dur']}s, at {latest['sha']}")
    print(f"  that run is {age_days}d old")
    print()

    if latest["fail"] == 0:
        print("  current state: GREEN as of the latest recorded run.")
        return 0

    # How long has it been failing? Walk back to the last run that was green.
    first_red = latest
    for r in reversed(rows):
        if r["fail"] == 0:
            break
        first_red = r

    red_days = (now - first_red["when"]).days
    if first_red is rows[0]:
        print(f"  current state: RED, and it has been red for every one of the "
              f"{len(rows)} recorded run(s).")
        print(f"  Earliest recorded failure: {first_red['when']:%Y-%m-%d} "
              f"({red_days}d ago) — but the history begins there, so this is a LOWER BOUND.")
        print("  The failures may predate recording; nothing can say by how much.")
    else:
        print(f"  current state: RED since {first_red['when']:%Y-%m-%d %H:%M}Z "
              f"({red_days}d ago), at {first_red['sha']}")
        print("  That is a measured age, bounded by a green run before it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
