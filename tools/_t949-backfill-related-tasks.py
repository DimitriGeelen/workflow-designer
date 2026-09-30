#!/usr/bin/env python3
"""T-949 — backfill related_tasks: on the GO-recorded inceptions whose approved work
was delivered but never linked back.

WHY A TOOL AND NOT 22 HAND EDITS. The mapping below is the reviewable artifact: each
parent is paired with the children that cite it, and each pairing is justified in
docs/reports/T-949-go-scope-triage.md by a verbatim line from the child task. A tool
makes the mapping inspectable and the operation re-runnable; 22 hand edits make it
neither.

WHAT IT REFUSES TO DO:
  - It only ever replaces `related_tasks: []`. A parent that already carries entries is
    left alone and reported, because overwriting a hand-curated list is not backfill.
  - It writes nothing for a parent whose children do not all exist on disk.
  - It touches only the 22 SHIPPED-UNLINKED parents. The PARTIAL, UNDONE and
    SUPERSEDED-UPSTREAM findings KEEP their audit finding — for those the check is right,
    and silencing them would be the actual defect.

--dry-run prints the diff it would make and changes nothing. Run that first.
"""
import re
import sys
from pathlib import Path

PROJ = Path(__file__).resolve().parent.parent

# parent -> children that cite it. Evidence per row: docs/reports/T-949-go-scope-triage.md
# Children are the tasks that DELIVERED the GO's scope, not every task that mentions it.
MAPPING = {
    "T-788": ["T-789", "T-794", "T-798", "T-799", "T-800", "T-802", "T-803"],
    "T-685": ["T-835"],
    "T-681": ["T-682", "T-683", "T-684", "T-689", "T-738", "T-780", "T-825"],
    "T-617": ["T-618", "T-619"],
    # T-950 CORRECTION. This read `[]` with the comment "PARTIAL — slice T-264 filed and
    # never started". T-264 was BUILT on 2026-07-27 (8-leg CDP harness green, re-verified
    # rc=0 on 2026-09-30) and merely left at status: captured. The triage trusted the
    # status field over the task body — the same field-vs-reality defect it was written
    # to document.
    "T-263": ["T-264"],
    "T-257": ["T-259", "T-261"],
    "T-250": ["T-258", "T-260"],
    "T-249": ["T-251"],
    "T-247": ["T-248", "T-254"],
    "T-244": ["T-308"],
    "T-218": ["T-219", "T-220", "T-221", "T-224", "T-225", "T-226", "T-227", "T-228"],
    "T-213": ["T-875", "T-877", "T-911"],
    "T-201": ["T-202"],
    "T-190": ["T-192", "T-203", "T-204"],
    "T-173": ["T-174", "T-175"],
    "T-142": ["T-143", "T-144"],
    "T-112": ["T-113", "T-114"],
    "T-103": [],   # PARTIAL — T-105 open 72 days. Deliberately empty.
    "T-092": ["T-093", "T-094", "T-095", "T-097", "T-098", "T-106", "T-107"],
    "T-068": ["T-081"],
    "T-038": ["T-039", "T-040", "T-041"],
    "T-020": ["T-021", "T-022", "T-023", "T-024", "T-025", "T-026", "T-027",
              "T-031", "T-032", "T-033"],
    "T-015": ["T-091"],
    "T-007": [],   # SUPERSEDED-UPSTREAM — framework behaviour. Deliberately empty.
    "T-006": [],   # SUPERSEDED-UPSTREAM — framework behaviour. Deliberately empty.
    "T-002": ["T-012", "T-017", "T-018"],
    "T-301": [],   # UNDONE — nothing was filed. Deliberately empty; the finding stands.
}

EMPTY = "related_tasks: []"


def find_task(tid):
    for sub in ("completed", "active"):
        hits = sorted((PROJ / ".tasks" / sub).glob(f"{tid}-*.md"))
        if hits:
            return hits[0]
    return None


def main():
    # --verify turns this one-shot migration into a standing regression guard: once the
    # backfill has landed, a run must find NOTHING left to do. If it finds work again, a
    # related_tasks: list was wiped — by a re-vendor, a bad edit, or a template reset —
    # and the audit finding is about to climb back toward 27 with nobody watching.
    # This is why the tool is not an orphan instrument (T-316/PL-363): it has a caller.
    verify = "--verify" in sys.argv
    dry = "--dry-run" in sys.argv or verify
    changed = skipped = refused = populated = 0

    for parent, children in sorted(MAPPING.items()):
        if not children:
            print(f"  SKIP     {parent}  deliberately empty (PARTIAL/UNDONE/UPSTREAM — finding stands)")
            skipped += 1
            continue

        pf = find_task(parent)
        if pf is None:
            print(f"  REFUSE   {parent}  parent task file not found")
            refused += 1
            continue

        missing = [c for c in children if find_task(c) is None]
        if missing:
            print(f"  REFUSE   {parent}  children not on disk: {' '.join(missing)}")
            refused += 1
            continue

        text = pf.read_text()
        if EMPTY not in text:
            # Already populated. In --verify this is the invariant HOLDING, so it must not
            # be counted as a refusal — the first cut did exactly that and turned a healthy
            # tree into rc=1 with "refused: 22" under a line saying PASS.
            cur = re.search(r"^related_tasks:.*$", text, re.M)
            verb = "INTACT  " if verify else "LEAVE   "
            print(f"  {verb} {parent}  already populated: "
                  f"{cur.group(0) if cur else 'no related_tasks: line'}")
            populated += 1
            continue

        new_line = "related_tasks: [" + ", ".join(children) + "]"
        if dry:
            print(f"  WOULD    {parent}  ->  {new_line}")
        else:
            pf.write_text(text.replace(EMPTY, new_line, 1))
            print(f"  BACKFILL {parent}  ->  {new_line}")
        changed += 1

    print()
    print(f"{'would change' if dry else 'changed'}: {changed}   already populated: "
          f"{populated}   deliberately skipped: {skipped}   refused: {refused}")

    if verify:
        # Guard the DENOMINATOR: if the mapping ever empties out, "nothing to do" would
        # read as healthy while asserting nothing at all (T-3105).
        expected = sum(1 for v in MAPPING.values() if v)
        if expected == 0:
            print("FAIL: the mapping declares no backfillable parents — this check would "
                  "pass vacuously, asserting nothing")
            return 1
        if refused:
            print(f"FAIL: {refused} parent(s) could not be checked (missing file, or a "
                  f"declared child absent from the tree). The mapping and the tree "
                  f"disagree; the invariant is unmeasured, which is not the same as held.")
            return 1
        if changed:
            print(f"FAIL: {changed} of {expected} parent(s) have an empty related_tasks: "
                  f"again. The backfill landed once, so something reverted it — and the "
                  f"GO-scope audit finding is climbing back toward 27 with nobody watching.")
            return 1
        if populated != expected:
            print(f"FAIL: expected {expected} populated parent(s), counted {populated}. "
                  f"The arithmetic does not close, so this is not a pass.")
            return 1
        print(f"PASS: all {expected} backfilled parent(s) still carry their back-link")
        return 0

    # Outside --verify a refusal is a real failure: mapping and tree disagree.
    return 1 if refused else 0


if __name__ == "__main__":
    sys.exit(main())
