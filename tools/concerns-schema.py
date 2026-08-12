#!/usr/bin/env python3
"""concerns-schema.py — refuse a register entry whose field name nothing reads (T-400).

THE DEFECT THIS EXISTS FOR (G-027). A gap was written with `closure_condition:` — a
plausible, readable, obviously-meant-well field name. Nothing reads it. The renderer
and the audit both read `decision_trigger:`. So the entry contained a perfectly good
closure condition and the audit reported it as having none. The WARN text said "no
closure condition", which describes the entry as MISSING the thing it visibly
CONTAINS, and therefore pointed the next reader at rewriting prose that was already
there. A silent-acceptance defect whose only detector actively misdirects.

WHY A NAME-ALLOWLIST AND NOT A "DID YOU MEAN" HEURISTIC. The audit grew a partial
detector that flags an alternate key only when its name contains "trigger".
`closure_condition` does not contain "trigger", so the very entry that motivated the
check would still have been reported as missing. Near-synonyms do not reliably share
a substring with the field they shadow — that is what makes them near-synonyms. The
only thing that separates "a field the code reads" from "a field that looks like one"
is an explicit list of the former.

TWO DIRECTIONS, because the register can be wrong in both:

  PRESENT-BUT-UNREAD   a field in the register that no code reads. Harmless as prose;
                       load-bearing-looking prose is exactly how G-027 happened. New
                       ones are refused; the ones already here are listed as prose.
  READ-BUT-ABSENT      a field the code reads that no entry carries. The machinery is
                       inert and nobody is told. Reported, never fatal — an optional
                       feature legitimately has no users yet.

Usage:
  concerns-schema.py             check (exit 1 on an unknown field name)
  concerns-schema.py --census    print the full field census, exit 0

Exit 0 = every field name is accounted for. 1 = an unaccounted name. 2 = harness error.
"""
import argparse
import collections
import os
import sys

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML unavailable", file=sys.stderr)
    sys.exit(2)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTER = os.path.join(ROOT, ".context", "project", "concerns.yaml")

# Fields some code actually reads, each with the reader that reads it. The reader is
# recorded so a future author can CHECK the claim rather than trust this list; a list of
# bare names would rot into the same unverifiable prose it exists to prevent.
READ_BY = {
    "id":                    "bin/fw (fw gaps renderer); lib/gaps.py",
    "status":                "bin/fw; audit.sh (watching filter); handover.sh; context/lib/init.sh",
    "title":                 "bin/fw; audit.sh; handover.sh; lib/gaps.py",
    "severity":              "handover.sh; reviewer/static_scan.py",
    "type":                  "audit.sh (gap-vs-concern split)",
    "decision_trigger":      "bin/fw (THE rendered closure condition); audit.sh closure check",
    "closure_check_command": "lib/gaps.py (one-click closure gauge)",
    "last_reviewed":         "lib/gaps.py:408 (staleness reference)",
    "created":               "lib/gaps.py:408 (staleness reference, fallback)",
}

# Fields carried deliberately as prose for human readers. Nothing reads them and nothing
# is meant to. Listing them is the point: it is the difference between "we know this is
# prose" and "we assumed something read it".
PROSE = {
    "origin_task":       "which task discovered it",
    "detected":          "date first seen (NOTE: gaps.py reads `created`, not this)",
    "registered":        "date entered in the register (same note as `detected`)",
    "related":           "free-form related ids",
    "related_tasks":     "near-synonym of `related`; neither is read",
    "description":       "long-form statement",
    "detail":            "near-synonym of `description`; neither is read",
    "context":           "the mechanism, in prose — how the gap works and why it is invisible "
                         "(T-463: carried by G-029 onward, red since 2026-08-09)",
    "evidence":          "measurements supporting the entry",
    "closure_evidence":  "measurements supporting closure",
    "resolution":        "what closed it",
    "resolved":          "date closed",
    "prevention_partial": "notes that mitigation exists but prevention does not",
    "progress":          "interim notes",
}

# Dated evidence keys (`evidence_YYYY_MM_DD_T###`) are a deliberate append-only
# convention: a later measurement must not overwrite an earlier one.
import re
DATED_EVIDENCE = re.compile(r"^evidence_\d{4}_\d{2}_\d{2}(_[A-Za-z0-9]+)?$")


def entries(doc):
    out = []
    for key in ("concerns", "gaps"):
        v = (doc or {}).get(key)
        if isinstance(v, list):
            out.extend(e for e in v if isinstance(e, dict))
    return out


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--census", action="store_true")
    ap.add_argument("--register", default=REGISTER)
    args = ap.parse_args()

    if not os.path.exists(args.register):
        print("ERROR: no register at %s" % args.register, file=sys.stderr)
        return 2
    try:
        doc = yaml.safe_load(open(args.register, encoding="utf-8"))
    except yaml.YAMLError as e:
        print("ERROR: register does not parse: %s" % e, file=sys.stderr)
        return 2

    es = entries(doc)
    # ANTI-VACUITY (PL-084): a clean verdict over zero entries is a bug, not a pass.
    if not es:
        print("VACUOUS: the register holds no entries, so 'every field accounted for' "
              "would be a statement about nothing.", file=sys.stderr)
        return 2

    counts = collections.Counter()
    for e in es:
        counts.update(e.keys())

    unknown = []
    for field, n in sorted(counts.items()):
        if field in READ_BY or field in PROSE or DATED_EVIDENCE.match(field):
            continue
        unknown.append((field, n))

    absent = [f for f in sorted(READ_BY) if counts.get(f, 0) == 0]

    if args.census:
        print("register: %s" % os.path.relpath(args.register, ROOT))
        print("entries : %d\n" % len(es))
        print("READ BY CODE (load-bearing)")
        for f in sorted(READ_BY):
            print("  %-22s %3d/%d  %s" % (f, counts.get(f, 0), len(es), READ_BY[f]))
        print("\nPROSE (read by nothing, by design)")
        for f in sorted(PROSE):
            print("  %-22s %3d/%d  %s" % (f, counts.get(f, 0), len(es), PROSE[f]))
        dated = sorted(f for f in counts if DATED_EVIDENCE.match(f))
        if dated:
            print("\nDATED EVIDENCE (append-only convention)")
            for f in dated:
                print("  %-22s %3d/%d" % (f, counts[f], len(es)))
        if absent:
            print("\nREAD-BUT-ABSENT — code reads these; no entry carries one, so the")
            print("machinery behind them is inert and nothing says so:")
            for f in absent:
                print("  %-22s        %s" % (f, READ_BY[f]))
        return 0

    if absent:
        print("NOTE — %d field(s) are read by code but carried by no entry. Not a failure "
              "(an optional feature may have no users yet), but the machinery is inert:"
              % len(absent))
        for f in absent:
            print("  - %-22s %s" % (f, READ_BY[f]))
        print()

    if unknown:
        print("SCHEMA FAIL — %d field name(s) nothing accounts for:" % len(unknown),
              file=sys.stderr)
        for f, n in unknown:
            print("  - %-24s (in %d entry/entries)" % (f, n), file=sys.stderr)
        print("\nThis is the G-027 shape: a plausible, readable field name that no code "
              "reads. The entry looks complete and the tooling behaves as if it is empty.",
              file=sys.stderr)
        print("Fix by one of:", file=sys.stderr)
        print("  - rename it to the field the code actually reads (listed inline below, "
              "not behind another command — G-027's whole cost was a message that sent "
              "the reader somewhere else), or", file=sys.stderr)
        print("  - if it is genuinely human-only prose, add it to PROSE in this file with "
              "a one-line note saying what it is for.", file=sys.stderr)
        print("\nFields the code reads:", file=sys.stderr)
        for f in sorted(READ_BY):
            print("  %-24s %s" % (f, READ_BY[f]), file=sys.stderr)
        print("\nIf you meant 'when is this gap allowed to close', the field is "
              "`decision_trigger` — it is the one the renderer and the audit both read.",
              file=sys.stderr)
        return 1

    print("schema ok: %d entries, %d distinct field name(s), all accounted for "
          "(%d read by code, %d prose)."
          % (len(es), len(counts),
             sum(1 for f in counts if f in READ_BY),
             sum(1 for f in counts if f in PROSE or DATED_EVIDENCE.match(f))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
