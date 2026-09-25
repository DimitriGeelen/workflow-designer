#!/usr/bin/env python3
"""T-848 — report on the realization ledger: what was predicted, what was observed.

WHY THIS EXISTS. Four value reviews recorded `.context/audits/bvp-realization.jsonl` as ABSENT
and treated that as neglect. It was not: NOTHING IN THE TREE READS OR WRITES IT. There was no
producer and no consumer, so it was never going to appear — "absent" described a thing nobody had
built, not a thing that had stopped working.

WHAT IS AND IS NOT IN SCOPE, because the distinction is the whole reason this is not vacuous:

  ARC-LEVEL realization — "did the shipped arc deliver the value its BVP predicted?" — is
  BLOCKED. All three arcs are in-progress and ZERO have ever closed, so that question has no
  candidate set. Building a check for it would produce an instrument that can only report
  nothing (the OBS-381 defect), so this tool deliberately does not attempt it.

  REVIEW-LEVEL realization — "did this finding's predicted effect actually happen?" — does NOT
  depend on an arc closing, and has a non-empty candidate set today. That is what the ledger
  holds.

IT REPORTS, IT DOES NOT GATE. Exit 0 even with failed predictions. Realization is evidence for
the operator's judgement about the value model, not a correctness property of any task, and a
gate here would be an agent grading the operator's predictions.

THREE-VALUED BY CONSTRUCTION. A prediction whose trigger has not fired is NOT_YET_DUE — never a
pass. The hit rate is reported over RESOLVED rows only. A rate over the total would let
untriggered rows inflate it, which is the same false green this session spent its length on.
"""
import json
import os
import sys

VALID = ("OBSERVED_TRUE", "OBSERVED_FALSE", "NOT_YET_DUE")
DEFAULT = ".context/audits/bvp-realization.jsonl"


def main(argv):
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    path = argv[1] if len(argv) > 1 else os.path.join(root, DEFAULT)

    if not os.path.isfile(path):
        print("REALIZATION LEDGER: absent at %s" % path)
        print("  Not a pass and not a failure — nothing has been recorded yet.")
        return 0

    rows, bad_rows = [], []
    with open(path, encoding="utf-8") as fh:
        for i, line in enumerate(fh, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            try:
                rows.append((i, json.loads(line)))
            except ValueError as exc:
                # Reported, never dropped. A ledger that silently skips what it cannot read
                # reports a clean set by omission.
                bad_rows.append((i, str(exc)))

    print("REALIZATION LEDGER — %s" % os.path.relpath(path, root))
    print("=" * 78)

    if not rows and not bad_rows:
        print("no rows: the ledger is empty. Nothing measured; this is not a clean run.")
        return 0

    counts = {k: 0 for k in VALID}
    unknown = []
    for lineno, r in rows:
        st = str(r.get("status", "")).upper()
        if st in counts:
            counts[st] += 1
        else:
            unknown.append((lineno, r.get("id", "?"), st or "(missing)"))

    for k in VALID:
        print("  %-16s: %d" % (k, counts[k]))
    resolved = counts["OBSERVED_TRUE"] + counts["OBSERVED_FALSE"]
    print("  %-16s: %d" % ("rows total", len(rows)))
    print()
    print("  NOT_YET_DUE is NOT a pass — those predictions are unsatisfied, not satisfied.")
    if resolved:
        print("  Hit rate over RESOLVED rows only: %d/%d (%.0f%%). Deliberately not over the"
              % (counts["OBSERVED_TRUE"], resolved,
                 100.0 * counts["OBSERVED_TRUE"] / resolved))
        print("  total, which untriggered rows would inflate.")
    else:
        print("  No resolved rows yet, so no hit rate can be computed.")

    if unknown:
        print()
        print("UNKNOWN STATUS (named, not bucketed):")
        for lineno, rid, st in unknown:
            print("  line %d  %s  unknown status %r" % (lineno, rid, st))
    if bad_rows:
        print()
        print("UNPARSEABLE ROWS (reported, not skipped silently):")
        for lineno, exc in bad_rows:
            print("  line %d: malformed — %s" % (lineno, exc))

    print()
    print("DETAIL")
    print("-" * 78)
    for _, r in rows:
        print("  [%s] %s  (%s)" % (r.get("status", "?"), r.get("id", "?"), r.get("source", "?")))
        print("      predicted: %s" % r.get("prediction", ""))
        if r.get("status", "").upper() == "NOT_YET_DUE":
            print("      trigger:   %s" % r.get("trigger", "(none recorded)"))
        elif r.get("observed"):
            print("      observed:  %s" % r.get("observed"))

    print()
    print("ARC-LEVEL REALIZATION IS NOT MEASURED HERE and that is deliberate: zero arcs have")
    print("closed, so 'did the shipped arc deliver?' has no candidate set. Checking it today")
    print("would be an instrument that can only ever report nothing.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
