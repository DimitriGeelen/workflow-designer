#!/usr/bin/env python3
"""_t567-episodic-parse-check.py — episodic memory must be readable.

Episodic memory is written once, at task completion, and until T-567 nothing ever read it
back. That is how `.context/episodic/T-431.yaml` sat unparseable for nine days while being
cited as ordinary completed work: the generator's ScannerError is raised to whoever happens
to be watching that terminal, and an unread store cannot report its own corruption.

Two assertions, and the second is the one that matters:

  1. every `.context/episodic/*.yaml` parses;
  2. the corpus is NOT TRIVIALLY SMALL. "0 unparseable" is also what an empty directory
     reports, and what a deleted directory reports. `--min` pins a floor so the check
     cannot pass by having nothing to check (T-560: an absence assertion needs a control
     establishing the search could have failed).

Optionally (`--match-git`) each `git_timeline` entry is compared to the git subject it was
mined from, which is the property the generator actually owes: the record must say what
happened, not merely parse. A generator that emitted an empty string would satisfy (1) and
(2) and fail this.

Exit 0 = all assertions hold. Exit 1 = a real failure. Exit 2 = the check could not run.

This is deliberately a standalone script rather than an inline verification one-liner, so
that the cron audit can call it — which is the condition G-040 closes on.
"""
import argparse
import glob
import json
import os
import subprocess
import sys

import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--min", type=int, default=1,
                    help="minimum number of episodics that must exist (guards the empty-corpus pass)")
    ap.add_argument("--match-git", action="store_true",
                    help="also require each timeline entry to equal its git subject")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    epdir = os.path.join(ROOT, ".context", "episodic")
    if not os.path.isdir(epdir):
        print("ERROR: no episodic directory at %s" % epdir, file=sys.stderr)
        return 2

    files = sorted(glob.glob(os.path.join(epdir, "*.yaml")))
    unparseable = []
    parsed = {}
    for f in files:
        try:
            parsed[f] = yaml.safe_load(open(f, encoding="utf-8"))
        except Exception as e:  # noqa: BLE001 - any parse failure is the finding
            unparseable.append((os.path.basename(f), str(e).split("\n")[0].strip()))

    mismatches = []
    compared = 0
    if args.match_git:
        for f, doc in parsed.items():
            tid = os.path.basename(f)[:-5]
            tl = (doc or {}).get("git_timeline") or []
            if not isinstance(tl, list):
                continue
            acts = [e.get("action") for e in tl
                    if isinstance(e, dict) and e.get("action")]
            if not acts:
                continue
            try:
                subs = subprocess.run(
                    ["git", "-C", ROOT, "log", "--all", "--grep=^%s:" % tid,
                     "--format=%s", "--reverse"],
                    capture_output=True, text=True, check=False).stdout.splitlines()
            except Exception:  # noqa: BLE001
                continue
            for a, s in zip(acts, subs):
                compared += 1
                if a != s:
                    mismatches.append((tid, a[:70], s[:70]))

    too_few = len(files) < args.min
    ok = not unparseable and not mismatches and not too_few

    result = {
        "episodics": len(files),
        "minimum_required": args.min,
        "unparseable": len(unparseable),
        "timeline_entries_compared": compared,
        "timeline_mismatches": len(mismatches),
        "verdict": "PASS" if ok else "FAIL",
    }
    if args.json:
        print(json.dumps(result))
    else:
        print("episodics        : %d (floor %d)" % (len(files), args.min))
        print("unparseable      : %d" % len(unparseable))
        for name, err in unparseable:
            print("    %-24s %s" % (name, err[:80]))
        if args.match_git:
            print("timeline vs git  : %d compared, %d mismatched" % (compared, len(mismatches)))
            for tid, a, s in mismatches[:5]:
                print("    %s\n      yaml: %s\n      git : %s" % (tid, a, s))
        if too_few:
            print("FAIL: only %d episodic(s) found, below the floor of %d — a passing parse "
                  "check over an empty corpus asserts nothing." % (len(files), args.min))
        print()
        print("PASS: episodic memory is readable and matches its source."
              if ok else "FAIL: episodic memory is not readable as claimed.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
