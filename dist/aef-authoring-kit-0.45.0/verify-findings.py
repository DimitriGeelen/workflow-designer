#!/usr/bin/env python3
"""verify-findings.py — check each review finding's map evidence against the map (T-1290).

A reviewer's finding about the map must cite where it saw the problem:

    "map_evidence": {"line": <1-based line in map.bpmn>, "quote": "<text verbatim on that line>"}

or `null` when the finding is about something ABSENT from the map. This script checks the citation mechanically:

    verified     the quote occurs on the cited line
    absence      map_evidence is null: a claim that something is missing (nothing to quote)
    unverified   no map_evidence key, the line does not exist, or the quote is not on that line

A finding that cites a line which does not say what it claims is the cheapest kind of reviewer error to catch, and
the costliest to chase by hand (832 release 0.26.0: a reviewer cited map.bpmn:119 for an attribute that sits on
line 98, on a different gateway).

  python3 verify-findings.py map.bpmn REVIEW.json            summary + one line per finding; exit 0
  python3 verify-findings.py map.bpmn REVIEW.json --write    also stores "verification" on each finding
  python3 verify-findings.py map.bpmn REVIEW.json --split OUT_UNVERIFIED.json
                                                             moves unverified findings to OUT, keeps the rest
  exit 2 when either file cannot be read or parsed (never a silent "all verified")
"""
import json
import sys


def label(finding, lines):
    if not isinstance(finding, dict) or "map_evidence" not in finding:
        return "unverified", "no map_evidence"
    ev = finding["map_evidence"]
    if ev is None:
        return "absence", "claims something is absent"
    if not isinstance(ev, dict):
        return "unverified", "map_evidence is not an object"
    line, quote = ev.get("line"), ev.get("quote")
    if not isinstance(line, int) or not isinstance(quote, str) or not quote.strip():
        return "unverified", "map_evidence needs an integer line and a non-empty quote"
    if line < 1 or line > len(lines):
        return "unverified", "line %s is outside the map (1-%d)" % (line, len(lines))
    if quote.strip() not in lines[line - 1]:
        return "unverified", "line %d does not contain the quote" % line
    return "verified", "line %d contains the quote" % line


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    map_path, review_path = argv[0], argv[1]
    try:
        with open(map_path, encoding="utf-8") as fh:
            lines = fh.read().split("\n")
        with open(review_path, encoding="utf-8") as fh:
            findings = json.load(fh)
        if not isinstance(findings, list):
            raise ValueError("REVIEW.json is not a JSON array")
    except (OSError, ValueError) as e:
        print("verify-findings: NOT CHECKED: %s" % e)
        return 2
    counts = {"verified": 0, "absence": 0, "unverified": 0}
    labelled = []
    for f in findings:
        status, why = label(f, lines)
        counts[status] += 1
        labelled.append((f, status))
        print("  %-10s %s (%s)" % (status, (f.get("element") if isinstance(f, dict) else "?"), why))
    print("verify-findings: %d verified, %d absence, %d unverified" % (counts["verified"], counts["absence"], counts["unverified"]))
    if "--write" in argv:
        for f, status in labelled:
            if isinstance(f, dict):
                f["verification"] = status
        with open(review_path, "w", encoding="utf-8") as fh:
            json.dump(findings, fh, indent=1)
    if "--split" in argv:
        out = argv[argv.index("--split") + 1]
        with open(out, "w", encoding="utf-8") as fh:
            json.dump([f for f, s in labelled if s == "unverified"], fh, indent=1)
        with open(review_path, "w", encoding="utf-8") as fh:
            json.dump([f for f, s in labelled if s != "unverified"], fh, indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
