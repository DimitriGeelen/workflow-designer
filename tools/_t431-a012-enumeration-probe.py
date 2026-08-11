#!/usr/bin/env python3
"""
_t431-a012-enumeration-probe.py — does the frozen mapping still cover AEF's enumeration?

T-431. Answers arc-anchor assumption A-012 without AEF's help.

A-012: "Every AEF `workflow_type` and `owner` is representable by (BPMN type + `aef:`
extension) with no new BPMN shape."

WHY THIS DID NOT NEED TO BE ASKED ON THE RAIL
---------------------------------------------
It was sent to AEF at DM 527 §1 alongside A-013 and A-014. Those two genuinely need them —
they are about what their model can RECEIVE and whether their record is RECONSTRUCTIBLE.
A-012 is not in that class: it is a claim about an ENUMERATION, and the enumeration is
vendored in this tree. Waiting for an answer we can measure is the same shape as waiting
for a ruling that was already given.

NEITHER SIDE IS RETYPED
-----------------------
Both enumerations are extracted at run time from the shipping files. A copy of AEF's list
pasted into this probe would test my transcription; a copy of the standard's list would
test my reading of a document I am forbidden to edit. This is the convention AEF took from
us at 529 §1, applied to the case that motivated it: a closed-world claim about somebody
else's list, written once, with nothing re-checking it across re-vendors.

WHAT IT REPORTS THAT A SET-DIFFERENCE WOULD NOT
-----------------------------------------------
Whether the enumeration is ENFORCED. A validator that exists and is called from nowhere is
indistinguishable, from its own output, from one that passes everything — the T-429 family.
So the probe counts call sites and reports the real distribution of values in `.tasks/`,
because a declared enumeration and a practised vocabulary are different objects and A-012
is only interesting about the second.

EXIT
  0  both enumerations covered, and covered by the same values
  1  a gap in either direction — read it
  2  cannot answer (an enumeration is not extractable) — never the same code as "no gap"
"""

import os
import re
import sys
from collections import Counter

ROOT = os.environ.get("T431_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENUMS = os.path.join(ROOT, ".agentic-framework", "lib", "enums.sh")
STANDARD = os.path.join(ROOT, "docs", "standards", "aef-bpmn-mapping-v1.md")
AEF_TREE = os.path.join(ROOT, ".agentic-framework")
TASKS = [os.path.join(ROOT, ".tasks", d) for d in ("active", "completed")]


def read(path):
    try:
        return open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return None


def aef_enum(src, name):
    """The shipped value of a VALID_* assignment, extracted from the file that ships it."""
    m = re.search(r'^\s*%s="([^"]*)"' % re.escape(name), src, re.M)
    return m.group(1).split() if m else None


def standard_enum(src, field):
    """Values a markdown table row lists for `field`, from the `Allowed values` column.

    The row is found by its task-YAML field name, not by line number: the standard is
    frozen and must not be edited, but it may be superseded, and a line-number anchor would
    silently read the wrong row rather than fail."""
    for line in src.splitlines():
        if not line.startswith("|"):
            continue
        # Split on UNESCAPED pipes only. The allowed-values cells are written
        # `build \| test \| refactor \| ...` — a plain split("|") tears them apart and
        # returns the FIRST value as if it were the whole enumeration. The first draft did
        # exactly that and reported six of AEF's seven workflow_types as unmapped: a
        # confident, specific, entirely wrong finding, produced by an extractor that
        # under-read in silence. Same direction of failure as everything else this week.
        cells = [c.strip() for c in re.split(r"(?<!\\)\|", line.strip().strip("|"))]
        if len(cells) < 3:
            continue
        # The field cell is not always a bare name: the owner row reads
        # "~~`owner`~~ *(derived — see §3)*" because v1.1 removed the node-level override.
        # Match the name inside the cell rather than the whole cell.
        if not re.search(r"`%s`" % re.escape(field), cells[1]):
            continue
        # The allowed-values cell is a `\|`-separated list whose items are sometimes
        # backticked (`human` \| `agent`) and sometimes bare (build \| test \| ...).
        # Splitting on the separator and stripping decoration handles both; a
        # backtick-only regex silently found nothing on the bare row and exited 2.
        vals = []
        for tok in re.split(r"\\\|", cells[2]):
            tok = tok.strip().strip("`").strip()
            if re.fullmatch(r"[a-z][a-z-]*", tok):
                vals.append(tok)
        return vals or None
    return None


def call_sites(symbol):
    """How many places in the vendored tree actually invoke this validator."""
    hits = 0
    for base, _dirs, files in os.walk(AEF_TREE):
        if "/.git" in base:
            continue
        for name in files:
            if not name.endswith((".sh", ".py")):
                continue
            src = read(os.path.join(base, name)) or ""
            for m in re.finditer(r"\b%s\b" % re.escape(symbol), src):
                line = src[src.rfind("\n", 0, m.start()) + 1:src.find("\n", m.start())]
                if re.match(r"\s*%s\s*\(\)" % re.escape(symbol), line):
                    continue          # the definition
                if line.lstrip().startswith("#"):
                    continue          # a comment about it
                hits += 1
    return hits


def practised(field):
    counts = Counter()
    for d in TASKS:
        try:
            names = os.listdir(d)
        except OSError:
            continue
        for name in names:
            if not name.endswith(".md"):
                continue
            src = read(os.path.join(d, name)) or ""
            m = re.search(r"^%s:\s*(\S+)" % re.escape(field), src, re.M)
            if m:
                counts[m.group(1).strip().strip('"')] += 1
    return counts


def main():
    enums_src, std_src = read(ENUMS), read(STANDARD)
    if enums_src is None:
        print("UNKNOWN — cannot read %s. A-012 is about AEF's enumeration; without the" % ENUMS)
        print("  file that ships it there is nothing to compare and this is not a pass.")
        return 2
    if std_src is None:
        print("UNKNOWN — cannot read %s." % STANDARD)
        return 2

    aef_types = aef_enum(enums_src, "VALID_TYPES")
    aef_owners = aef_enum(enums_src, "VALID_OWNERS")
    std_types = standard_enum(std_src, "workflow_type")
    std_owners = standard_enum(std_src, "owner")

    missing = [n for n, v in (("AEF workflow_type", aef_types), ("AEF owner", aef_owners),
                              ("standard workflow_type", std_types),
                              ("standard owner", std_owners)) if not v]
    if missing:
        print("UNKNOWN — could not extract: %s" % ", ".join(missing))
        print("  The shape of one of the two sources changed. A probe that cannot find an")
        print("  enumeration must not report that the enumerations agree.")
        return 2

    print("=== T-431 A-012: does the frozen mapping cover AEF's enumeration? ===")
    print("  both sides extracted at run time; neither retyped")
    print()

    findings = []
    for label, field, aef, std in (("workflow_type", "workflow_type", aef_types, std_types),
                                   ("owner", "owner", aef_owners, std_owners)):
        a, s = set(aef), set(std)
        print("  %s" % label)
        print("    AEF ships    (%d): %s" % (len(aef), " ".join(sorted(a))))
        print("    standard has (%d): %s" % (len(std), " ".join(sorted(s))))
        if a - s:
            print("    SHIPPED BUT UNMAPPED : %s" % " ".join(sorted(a - s)))
            findings.append("%s: AEF ships %s, the standard does not name it"
                            % (label, "/".join(sorted(a - s))))
        if s - a:
            print("    MAPPED BUT NOT SHIPPED: %s" % " ".join(sorted(s - a)))
            findings.append("%s: the standard maps to %s, AEF does not ship it"
                            % (label, "/".join(sorted(s - a))))
        if a == s:
            print("    exact match in both directions")
        counts = practised(field)
        print("    practised in .tasks/: %s"
              % ", ".join("%s=%d" % kv for kv in counts.most_common()) or "(none)")
        undeclared = set(counts) - a
        if undeclared:
            print("    IN USE, NOT DECLARED : %s"
                  % " ".join("%s(%d)" % (v, counts[v]) for v in sorted(undeclared)))
            findings.append("%s: %s in use in this tree, absent from AEF's own enumeration"
                            % (label, "/".join(sorted(undeclared))))
        print()

    sites = call_sites("is_valid_owner")
    print("  is_valid_owner() call sites in the vendored tree: %d" % sites)
    if sites == 0:
        print("    Declared and invoked nowhere. An enumeration enforced by nothing and one")
        print("    that accepts everything have identical output, which is why the value in")
        print("    use here was never rejected. Reported, not counted as an A-012 gap: it")
        print("    is AEF's to close and is going to them, not into their tree from here.")
    print()

    if not findings:
        print("PASS — A-012 holds on both fields: every value AEF ships is named by the")
        print("  standard and every value the standard names is shipped.")
        return 0
    print("FINDINGS — A-012 does not hold as written:")
    for f in findings:
        print("  - %s" % f)
    print()
    print("  Representability is NOT what fails here. A lane can carry any owner label, so")
    print("  no new BPMN shape is needed. What fails is the premise underneath A-012: that")
    print("  there is one fixed enumeration to map onto. Recorded as evidence, not as a")
    print("  status flip.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
