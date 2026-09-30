#!/usr/bin/env python3
"""T-949 — the GO-scope triage must stay complete as the audit finding changes.

WHAT THIS GUARDS, AND WHY NOT THE OBVIOUS THING. The obvious check is "the triage
document covers all 27". That anchor rots the moment the backfill lands (the finding
is now 5) and rots again on every future change — T-3326, mutable-corpus anchors.

So the invariant is FORWARD-LOOKING instead: every inception the audit flags RIGHT NOW
must carry a verdict in the triage document. A newly-abandoned GO therefore cannot
appear in the audit without failing this check, which is the whole point — the triage
becomes a living document rather than a snapshot of one afternoon.

Three legs:
  1. COVERAGE  — every currently-flagged id has a verdict.
  2. VOCABULARY— every verdict is one of the four declared values.
  3. EVIDENCE  — every verdict cites an artifact (another task id, a docs/ path, or a
                 commit hash). A verdict resting only on the inception's title is not
                 admissible; that was the standard this triage set for itself.

Exit 0 all legs pass · 1 a leg failed · 3 could not measure.
"""
import os
import re
import sys
from pathlib import Path

PROJ = Path(__file__).resolve().parent.parent
# Overridable so the teeth prober can drive this against fixtures. A checker that can
# only be pointed at the real tree can be observed passing and never proven to fail.
AUDIT_REPORT = Path(os.environ.get(
    "T949_AUDIT_REPORT", PROJ / ".context/audits/go-scope-unpropagated/LATEST.md"))
TRIAGE = Path(os.environ.get(
    "T949_TRIAGE", PROJ / "docs/reports/T-949-go-scope-triage.md"))

VERDICTS = ("SHIPPED-UNLINKED", "PARTIAL", "UNDONE", "SUPERSEDED-UPSTREAM")
# another task id, a docs path, or a commit-ish hash
EVIDENCE = re.compile(r"T-\d{3}\b|docs/[\w./-]+|\b[0-9a-f]{8}\b")


def die_unmeasurable(msg):
    sys.stderr.write(f"COULD-NOT-MEASURE: {msg}\n")
    sys.exit(3)


def flagged_ids(path):
    """Population read from the audit's own report — never hand-typed (PL-181)."""
    if not path.exists():
        die_unmeasurable(f"{path} not found; the audit has not produced the report")
    ids = re.findall(r"^- (T-\d+) —", path.read_text(), re.M)
    return ids


def verdict_sections(text):
    """id -> (verdict, evidence_block).

    A verdict attaches to the row or bullet whose SUBJECT is the id — a table row
    whose FIRST cell is the id, or a bullet opening `- **T-XXX**`. Every other task
    id on that row is evidence, not a second verdict.

    The first cut of this function assigned a verdict to every id appearing anywhere
    under a verdict heading. That read 67 verdicts out of a 27-row document, because
    it classified the delivering CHILDREN alongside their parents, and it scoped
    evidence to a single line so multi-line bullets looked unevidenced. Both were
    caught by running the check against this document (T-949).
    """
    out = {}
    current = None
    subject = None          # id whose block we are accumulating
    lines = text.splitlines()

    for line in lines:
        # ANY heading closes the current section. Only a recognised verdict opens one.
        # The first cut reset `current` only on a `## ` heading, so a `###` heading that
        # was not a declared verdict fell through and its rows silently INHERITED the
        # previous verdict — renaming `### UNDONE` to `### PROBABLY-FINE` reclassified
        # T-301 as PARTIAL and the checker passed. Caught by the teeth prober's
        # vocabulary leg, which is the only reason this is not still true.
        if re.match(r"^#{2,}\s+", line):
            m = re.match(r"^###\s+([A-Z][A-Z-]*)", line)
            current = m.group(1) if (m and m.group(1) in VERDICTS) else None
            subject = None
            continue
        if not current:
            continue

        # a table row whose first cell is the id, or a bullet naming it in bold
        row = re.match(r"^\|\s*\**(T-\d{3})\**\s*\|", line)
        bul = re.match(r"^[-*]\s+\**(T-\d{3})\**", line)
        hit = row or bul
        if hit:
            subject = hit.group(1)
            out.setdefault(subject, [current, line])
        elif subject and line.strip() and not line.startswith("|"):
            # continuation of the current bullet — its evidence may live here
            out[subject][1] += " " + line.strip()
        elif not line.strip():
            subject = None

    return {k: (v[0], v[1]) for k, v in out.items()}


def main():
    if not TRIAGE.exists():
        die_unmeasurable(f"{TRIAGE} not found")

    triage_text = TRIAGE.read_text()
    assigned = verdict_sections(triage_text)
    live = flagged_ids(AUDIT_REPORT)

    if not live:
        # An empty finding list is a legitimate state (everything triaged and linked),
        # but it must not read as a pass for the coverage leg without saying so.
        print("audit currently flags 0 inception(s) — coverage leg has an empty "
              "denominator and asserts nothing (T-3105)")
    print(f"audit flags {len(live)} inception(s); triage document assigns "
          f"{len(assigned)} verdict(s)")
    print()

    failures = []

    # --- leg 1: coverage --------------------------------------------------
    uncovered = [i for i in live if i not in assigned]
    if uncovered:
        failures.append(
            "COVERAGE: the audit flags these and the triage has no verdict for them: "
            + " ".join(uncovered)
            + "\n    A newly-flagged inception needs triage, not a passing check.")
    else:
        print(f"  PASS  coverage — all {len(live)} flagged inception(s) carry a verdict")

    # --- leg 2: vocabulary ------------------------------------------------
    bad_vocab = {i: v for i, (v, _) in assigned.items() if v not in VERDICTS}
    if bad_vocab:
        failures.append(f"VOCABULARY: undeclared verdict value(s): {bad_vocab}")
    else:
        print(f"  PASS  vocabulary — {len(assigned)} verdict(s), all within "
              f"{'/'.join(VERDICTS)}")

    # --- leg 3: evidence --------------------------------------------------
    naked = []
    for tid in live:
        if tid not in assigned:
            continue
        _verdict, line = assigned[tid]
        # strip the id itself before looking for corroborating evidence, so a row
        # cannot cite itself
        rest = line.replace(tid, "")
        if not EVIDENCE.search(rest):
            naked.append(tid)
    if naked:
        failures.append(
            "EVIDENCE: verdict(s) citing no artifact (no other task id, no docs/ path, "
            "no commit): " + " ".join(naked))
    else:
        print("  PASS  evidence — every flagged inception's verdict cites an artifact")

    print()
    if failures:
        for f in failures:
            print(f"FAIL: {f}")
        return 1
    print("=== all legs pass ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
