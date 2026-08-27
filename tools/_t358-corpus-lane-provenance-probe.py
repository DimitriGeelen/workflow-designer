#!/usr/bin/env python3
"""
T-358 — does any corpus map RELY on the fabricated lane default?

T-358's defect: the importer initialises `state` into our own lane skeleton, so an
absent lane set and an empty one share a representation, and every one of five
third-party fixtures gains `lanes 0->3 / participants 0->1` on open->save. The
repair is to emit zero lanes for a lane-less input.

This probe answers the AC that guards the repair from reversing into the opposite
defect: *if any existing map relies on the fabricated default, that reliance is a
finding to file, not a reason to keep fabricating.*

The test is provenance, not count. For each of the 24 corpus maps, every lane in
the rendered BPMN must be declared by name in the source `.workflow.yaml`'s
`lanes:` array. A lane in the output that the input never declared is the
fabricated default showing up in our own corpus — which would mean the repair
would change our bytes and the corpus was leaning on the bug.

Exit 0 = no reliance; the repair is safe for the corpus.
Exit 1 = at least one map carries an undeclared lane — a finding.
Exit 2 = could not measure (missing corpus, unparseable source). Refusal, not a pass.

DELIBERATELY NOT A FINDING: lanes that are declared in source but hold zero
flowNodeRef. There are 7 of those, and they are an authoring choice — a lane
declared for structural completeness that no node happens to sit in. They are
reported for visibility and do not fail the probe, because an empty AUTHORED lane
and a FABRICATED lane are different things, and conflating them is the same
missing-versus-default collapse T-358 is about.

MEASUREMENT NOTE (2026-08-27). Two wrong readings were produced before this one,
both caught before they were reported, both the same shape:
  1. A regex looking for `lane:`/`role:` keys reported 67 "undeclared" lane names.
     The lane names are authored in a top-level `lanes:` array the regex never
     looked at. Searching for the shape I expected instead of the place the thing
     lives.
  2. A debug dump sliced lists to their first two entries (`v[:2]`), which made a
     3-lane source read as 2 and manufactured a discrepancy that did not exist.
     The truncation was mine, in the instrument, not in the data.
Both are the reason this file exists rather than a number in a task file.
"""

import glob
import os
import re
import sys

import yaml

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_GLOB = os.path.join(REPO, "examples", "aef-processes", "*.workflow.yaml")
RENDERED = os.path.join(REPO, "examples", "aef-processes", "rendered")

LANE_BLOCK = re.compile(
    r'<(?:\w+:)?lane\b[^>]*\bname="([^"]*)"[^>]*>(.*?)</(?:\w+:)?lane>', re.S
)
# Self-closing lanes carry no members by construction; matched separately so they
# are counted rather than silently skipped by the block regex above.
LANE_SELFCLOSE = re.compile(r'<(?:\w+:)?lane\b[^>]*\bname="([^"]*)"[^>]*/>')


def refuse(msg):
    print("  REFUSE  %s" % msg)
    print("\n  probe could not measure — this is not a pass")
    sys.exit(2)


def main():
    print("T-358 — does any corpus map rely on the fabricated lane default?\n")

    sources = sorted(glob.glob(SRC_GLOB))
    if not sources:
        refuse("no source workflows matched %s" % SRC_GLOB)
    if not os.path.isdir(RENDERED):
        refuse("rendered corpus directory missing: %s" % RENDERED)

    print("  %-26s %-6s %-6s %s" % ("map", "src", "bpmn", "undeclared lane(s)"))

    undeclared_total = 0
    affected = []
    empty_authored = []

    for s in sources:
        base = os.path.basename(s).replace(".workflow.yaml", "")
        bpmn = os.path.join(RENDERED, "%s.bpmn" % base)
        if not os.path.exists(bpmn):
            refuse("no rendered BPMN for %s" % base)
        try:
            doc = yaml.safe_load(open(s)) or {}
        except Exception as exc:
            refuse("%s does not parse: %s" % (os.path.basename(s), exc))

        src_names = [l.get("name") for l in (doc.get("lanes") or [])]
        if not src_names:
            refuse("%s declares no lanes: array — cannot establish provenance" % base)

        txt = open(bpmn, encoding="utf-8", errors="replace").read()
        blocks = LANE_BLOCK.findall(txt)
        bpmn_names = [n for n, _ in blocks] + LANE_SELFCLOSE.findall(txt)
        empty = {n for n, body in blocks if not re.search(r"flowNodeRef", body)}
        empty |= set(LANE_SELFCLOSE.findall(txt))

        undeclared = [n for n in bpmn_names if n not in src_names]
        if undeclared:
            affected.append(base)
            undeclared_total += len(undeclared)
        for n in sorted(empty):
            empty_authored.append((base, n, n in src_names))

        print("  %-26s %-6d %-6d %s" % (
            base, len(src_names), len(bpmn_names),
            ", ".join(undeclared) if undeclared else "-"))

    print()
    if empty_authored:
        undeclared_empty = [e for e in empty_authored if not e[2]]
        print("  note: %d lane(s) hold zero flowNodeRef; %d of those are declared in "
              "source" % (len(empty_authored), len(empty_authored) - len(undeclared_empty)))
        for base, name, declared in empty_authored:
            print("        %-26s %-38s %s" % (
                base, name, "authored" if declared else "UNDECLARED"))
        print()

    if affected:
        print("  FAIL  %d map(s) carry %d lane(s) the source never declared"
              % (len(affected), undeclared_total))
        for a in affected:
            print("          %s" % a)
        print("\n  The corpus DOES lean on the fabricated default. This is a finding:")
        print("  repairing the importer would change bytes for these maps.")
        return 1

    print("  PASS  every lane in all %d rendered maps is declared in its source yaml"
          % len(sources))
    print("  No corpus map relies on the fabricated default, so emitting zero lanes")
    print("  for a lane-less input cannot reverse into the opposite defect here.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
