#!/usr/bin/env python3
"""T-696 — measure the RECURRENCE, not the state.

T-624 measured 38 of 41 inceptions sitting at the template's planted `voi_score`
on 2026-08-29, diagnosed it correctly, and chose an in-template warning as its
prevention. Twelve days later the proportion was unchanged. The warning is
emphatic, correct, and physically adjacent to the field it governs.

    A COMMENT IS NOT A GATE.

The thing T-624 could not do -- because it needed time to pass -- is show that
the number did not move. Doing that by re-reading two prose reports is how the
observation decays into another prose claim. This records the figure with its
date into an append-only ledger, so the next check is a DIFF AGAINST A RECORDED
NUMBER.

What this is NOT: a gate. The prevention has not been chosen yet -- that is the
`[REVIEW]` Human AC on T-696, and it is the operator's ruling (A/B/C/D/no-repair).
Shipping a failing check here would be choosing the prevention by installing it,
which is T-624's error run in reverse: asserting a prevention before anyone picked
one. `--require-improvement` exists for whoever wires it up AFTER the ruling, and
is deliberately not referenced by this task's own Verification block.

Usage:
    python3 tools/_t696-voi-recurrence.py              # diff against last record
    python3 tools/_t696-voi-recurrence.py --record     # append a dated datapoint
    python3 tools/_t696-voi-recurrence.py --self-test  # throwaway root, no real ledger
"""

import argparse
import datetime
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROVENANCE = os.path.join(ROOT, "tools", "_t624-voi-provenance.py")
LEDGER = os.path.join(ROOT, ".context", "audits", "t696-voi-recurrence.jsonl")

FIELDS = ("voi_score", "target_blast_radius")


def measure():
    """Current figures, from T-624's tool -- one source of truth, not a re-implementation."""
    out = subprocess.run(
        [sys.executable, PROVENANCE, "--json"],
        capture_output=True, text=True, cwd=ROOT,
    )
    if out.returncode != 0:
        raise RuntimeError(f"provenance tool failed rc={out.returncode}: {out.stderr[:300]}")
    return json.loads(out.stdout)


def _ratio(entry):
    total = entry["total"]
    return (entry["template_default_count"] / total) if total else 0.0


def read_ledger(path):
    if not os.path.exists(path):
        return []
    rows = []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if line:
                rows.append(json.loads(line))
    return rows


def record(path, data, today=None):
    """Append one dated datapoint. Append-only: never rewrites prior lines."""
    today = today or datetime.date.today().isoformat()
    row = {"date": today, "fields": data}
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a") as fh:
        fh.write(json.dumps(row, sort_keys=True) + "\n")
    return row


def diff(path, data, require_improvement=False):
    """Report the delta since the last recorded datapoint. Returns an exit code."""
    rows = read_ledger(path)
    print("T-696 — voi_score / target_blast_radius recurrence")
    print("=" * 66)

    if not rows:
        print("\nNo prior datapoint in the ledger.")
        print(f"  ledger: {path}")
        for f in FIELDS:
            e = data[f]
            print(f"  {f:22s} {e['template_default_count']}/{e['total']} at template default "
                  f"({_ratio(e):.0%})")
        print("\nRun with --record to establish the baseline. Nothing to diff yet, and\n"
              "saying 'unchanged' with nothing to compare against would be the prose\n"
              "claim this tool exists to replace.")
        return 0

    prev = rows[-1]
    print(f"\n  last recorded: {prev['date']}   ({len(rows)} datapoint(s) in ledger)")
    print(f"  ledger: {path}\n")

    worsened = False
    for f in FIELDS:
        now, was = data[f], prev["fields"][f]
        d_count = now["template_default_count"] - was["template_default_count"]
        d_ratio = _ratio(now) - _ratio(was)
        arrow = "unchanged" if d_count == 0 else (f"{d_count:+d}")
        print(f"  {f:22s} {was['template_default_count']}/{was['total']} "
              f"({_ratio(was):.0%})  ->  {now['template_default_count']}/{now['total']} "
              f"({_ratio(now):.0%})   [{arrow}]")
        if d_ratio > 0.001:
            worsened = True

    try:
        d0 = datetime.date.fromisoformat(prev["date"])
        days = (datetime.date.today() - d0).days
        print(f"\n  elapsed since last datapoint: {days} day(s)")
    except ValueError:
        days = None

    if require_improvement:
        stalled = all(
            data[f]["template_default_count"] >= prev["fields"][f]["template_default_count"]
            for f in FIELDS
        )
        if stalled:
            print("\nFAIL (--require-improvement): the proportion has not fallen since the\n"
                  "last datapoint. Whatever prevention is in place has not refused anything.")
            return 1

    print("\nThis is an INSTRUMENT, not a gate. The prevention is T-696's open [REVIEW]\n"
          "ruling (A/B/C/D/no-repair). Wire --require-improvement in only after that is\n"
          "decided — installing a failing check now would BE the decision.")
    return 1 if (worsened and require_improvement) else 0


def self_test():
    """Runs entirely in a throwaway root. Never touches the real ledger."""
    print("T-696 recurrence — self-test (throwaway ledger root)")
    print("=" * 66)
    failures = []

    tmp = tempfile.mkdtemp()
    led = os.path.join(tmp, "audits", "t696.jsonl")

    def mk(n, total=43):
        return {f: {"template_default": "0.5", "total": total,
                    "scored": total - n, "template_default_count": n, "absent": 0}
                for f in FIELDS}

    # 1. empty ledger is not an error, and does not claim "unchanged"
    rc = diff(led, mk(40))
    if rc != 0:
        failures.append("empty ledger should exit 0")
    if read_ledger(led):
        failures.append("diff must not write to the ledger")

    # 2. record appends, and appends WITHOUT rewriting
    record(led, mk(40), today="2026-08-29")
    record(led, mk(40), today="2026-09-10")
    rows = read_ledger(led)
    if len(rows) != 2:
        failures.append(f"expected 2 ledger rows, got {len(rows)}")
    if rows[0]["date"] != "2026-08-29":
        failures.append("append-only violated: first row changed")

    # 3. the real recurrence shape -- unchanged over time -- is reported, not hidden
    rc = diff(led, mk(40))
    if rc != 0:
        failures.append("unchanged should exit 0 without --require-improvement")

    # 4. --require-improvement DOES fail on a stall (the gate is real when wired)
    rc = diff(led, mk(40), require_improvement=True)
    if rc != 1:
        failures.append("--require-improvement must fail on a stalled figure")

    # 5. ... and passes when the figure actually falls
    rc = diff(led, mk(12), require_improvement=True)
    if rc != 0:
        failures.append("--require-improvement must pass when the figure falls")

    # 6. a WORSENING figure must not read as improvement
    rc = diff(led, mk(43), require_improvement=True)
    if rc != 1:
        failures.append("--require-improvement must fail when the figure worsens")

    print("\n" + "=" * 66)
    for f in failures:
        print(f"  FAIL: {f}")
    if failures:
        print(f"\nVERDICT: RED — {len(failures)} of 6 checks failed.")
        return 1
    print("\nVERDICT: GREEN — 6/6 checks passed, real ledger untouched.")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--record", action="store_true",
                    help="append a dated datapoint to the append-only ledger")
    ap.add_argument("--require-improvement", action="store_true",
                    help="exit non-zero if the proportion has not fallen since the last "
                         "datapoint. NOT wired into T-696's Verification: the prevention "
                         "has not been chosen yet, and installing a failing check would "
                         "be choosing it.")
    ap.add_argument("--ledger", default=LEDGER)
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    data = measure()
    if args.record:
        row = record(args.ledger, data)
        print(f"recorded {row['date']} -> {args.ledger}")
        for f in FIELDS:
            e = data[f]
            print(f"  {f:22s} {e['template_default_count']}/{e['total']} at template default")
        return 0
    return diff(args.ledger, data, require_improvement=args.require_improvement)


if __name__ == "__main__":
    sys.exit(main())
