#!/usr/bin/env python3
"""T-486 — are there closed inception GO decisions with nothing carrying the work?

Mirror of AEF's T-2925 (rail 601 §1): an inception closed with a GO whose build slices were
never created, so the fix stayed unbuilt while the record read "done" and the archived task
took the gap with it.

TWO THINGS THIS PROBE REFUSES TO DO, both learned the hard way in this same task:

1. It does not classify a GO as carried because SOME task references it. That is a reference
   count — a membership audit one level deeper — which is precisely the critique I sent AEF
   at 599/602. A referencing task can be another inception, a handover, or prose. Carried
   means an IMPLEMENTATION-typed successor exists.

2. It does not read the decision from a frontmatter field. The first P-011 leg written for
   this task did, found `inception_decision:` on ZERO tasks because decisions are recorded in
   the `## Decision` section, and therefore exited 0 over an empty population — a green leg
   testing nothing. The denominator is printed and asserted for exactly that reason (PL-084).

Exit 0 = population non-empty AND no orphaned GO. Exit 1 = orphans found. Exit 2 = the
population is empty, which is a broken probe rather than a clean tree.
"""
import glob
import json
import re
import sys

IMPL = {"build", "test", "refactor", "decommission"}


def decision_of(text):
    """GO / NO-GO / DEFER / ABSENT, from frontmatter if present else the ## Decision body."""
    m = re.search(r"^inception_decision:\s*(\S+)", text, re.M)
    if m:
        return m.group(1).strip().upper()
    sec = re.search(r"##\s*Decision\b(.*?)(?=\n##\s|\Z)", text, re.S)
    if not sec:
        return "ABSENT"
    body = sec.group(1)
    if re.search(r"\bNO[- ]GO\b", body, re.I):
        return "NO-GO"
    if re.search(r"\bDEFER\b", body, re.I):
        return "DEFER"
    if re.search(r"\bGO\b", body):
        return "GO"
    return "ABSENT"


def main():
    texts, types = {}, {}
    for f in sorted(glob.glob(".tasks/completed/*.md")) + sorted(glob.glob(".tasks/active/*.md")):
        m = re.match(r".*/(T-\d+)-", f)
        if not m:
            continue
        t = open(f, encoding="utf-8", errors="replace").read()
        texts[m.group(1)] = t
        wt = re.search(r"^workflow_type:\s*(\S+)", t, re.M)
        types[m.group(1)] = wt.group(1) if wt else "?"

    counts, gos = {}, []
    for tid, t in texts.items():
        if not re.search(r"^workflow_type:\s*inception", t, re.M):
            continue
        d = decision_of(t)
        counts[d] = counts.get(d, 0) + 1
        if d == "GO":
            gos.append(tid)

    carried, orphaned, referenced_only = [], [], []
    for g in sorted(gos):
        refs = [o for o, tx in texts.items() if o != g and g in tx]
        impl = [o for o in refs if types.get(o) in IMPL]
        if impl:
            carried.append(g)
        elif refs:
            referenced_only.append({"inception": g, "refs": [(o, types.get(o)) for o in refs]})
            orphaned.append(g)
        else:
            orphaned.append(g)

    out = {
        "inceptions_total": sum(counts.values()),
        "decisions": counts,
        "GO_population": len(gos),
        "carried_by_implementation": len(carried),
        "orphaned": orphaned,
        "referenced_but_no_implementation": referenced_only,
    }
    # PL-084: a zero over an empty population is not a clean result, it is no result.
    if not gos:
        out["pass"] = False
        out["error"] = ("GO population is ZERO — the decision parser found no GO at all. "
                        "That is a broken probe, not a clean tree; a verdict here would be vacuous.")
        print(json.dumps(out, indent=2))
        return 2
    out["pass"] = not orphaned
    out["summary"] = "%d completed inceptions, %d GO, %d carried by an implementation successor, %d orphaned" % (
        out["inceptions_total"], len(gos), len(carried), len(orphaned))
    print(json.dumps(out, indent=2))
    return 0 if not orphaned else 1


if __name__ == "__main__":
    sys.exit(main())
