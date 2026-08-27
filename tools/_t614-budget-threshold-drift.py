#!/usr/bin/env python3
"""T-614 — does CLAUDE.md's budget ladder still say what budget-gate.sh computes?

THE INCIDENT. `budget-gate.sh` derives its thresholds as percentages of a configurable
`CONTEXT_WINDOW` (default 300000): warn 75%, urgent 85%, critical 95%. CLAUDE.md carried a
hard-coded 120K/150K/170K ladder with "60% / 75% / 85%" labels — a 200K-era calibration. At
154,476 tokens the gate wrote `"level": "ok"` (51%) and the agent, reading the prose,
declared the session urgent, refused the next task and generated a handover at half budget.

The agent even noticed the contradiction and resolved it in favour of the document.

WHAT THE GUARD ASSERTS. Two things, both derived from the script rather than restated:

  1. every percentage named in CLAUDE.md's budget RULE text is one the gate computes
  2. every absolute token figure named there equals a threshold the gate derives at the
     configured window — or is explicitly marked illustrative

WHY THE REGION AND NOT THE FILE (T-608's lesson). A token scan cannot tell a USE from a
MENTION. This file's own docstring names 120K, 150K and 170K; so does T-614's task
description; so would any future RCA narrative. A file-wide scan would flag the very
explanation of the bug it exists to prevent. So the scan is pointed only at the sections
that carry the RULE, and the vacuity guard below refuses to pass if those sections cannot be
found at all.

Exit 0 = doc and gate agree. 1 = drift. 2 = cannot measure (NOT a pass).
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GATE = REPO / ".agentic-framework" / "agents" / "context" / "budget-gate.sh"
DOC = REPO / "CLAUDE.md"

# The headings whose bullets are normative. Anything outside these is prose about the rule.
RULE_SECTIONS = ("### Work Proposal Rule", "### Automated Monitoring (Claude Code)",
                 # T-614: the third stale site lived here, outside the two obvious sections.
                 # Guarding only where the bug was found would leave the site that was
                 # ALSO wrong unguarded — the same partial-coverage shape as rail 607.
                 "### Commit Cadence and Check-In")


def gate_thresholds(text):
    """Read the percentages and default window out of the script that enforces them."""
    m = re.search(r'CONTEXT_WINDOW=\$\(fw_config_int\s+"CONTEXT_WINDOW"\s+(\d+)\)', text)
    if not m:
        return None, {}
    window = int(m.group(1))
    pcts = {}
    for name, pct in re.findall(r"TOKEN_(\w+)=\$\(\(CONTEXT_WINDOW \* (\d+) / 100\)\)", text):
        pcts[name.lower()] = int(pct)
    return window, pcts


def rule_text(doc):
    """Only the normative sections — see the docstring on USE vs MENTION."""
    out = []
    for head in RULE_SECTIONS:
        i = doc.find(head)
        if i == -1:
            continue
        j = doc.find("\n### ", i + len(head))
        k = doc.find("\n## ", i + len(head))
        end = min(x for x in (j, k, len(doc)) if x != -1)
        out.append(doc[i:end])
    return "\n".join(out)


def main():
    if not GATE.exists() or not DOC.exists():
        print("CANNOT MEASURE: budget-gate.sh or CLAUDE.md missing")
        return 2

    window, pcts = gate_thresholds(GATE.read_text())
    if not window or len(pcts) < 3:
        print("CANNOT MEASURE: could not read thresholds out of budget-gate.sh — its shape "
              "changed, and this guard would otherwise pass by finding nothing to compare")
        return 2

    doc = DOC.read_text()
    rules = rule_text(doc)
    if not rules.strip():
        print(f"CANNOT MEASURE: none of {RULE_SECTIONS} found in CLAUDE.md — a renamed "
              f"heading would make this guard pass vacuously")
        return 2

    derived = {n: window * p // 100 for n, p in pcts.items()}
    allowed_pct = set(pcts.values())
    allowed_abs = set(derived.values())

    problems = []

    # 1. percentages named in the rule text
    for pct in {int(x) for x in re.findall(r"(\d{2})\s*%", rules)}:
        if pct not in allowed_pct:
            problems.append(f"rule text names {pct}% — the gate computes only "
                            f"{sorted(allowed_pct)}")

    # 2. absolute token figures. "225K" and "225000" are the same claim.
    for raw in re.findall(r"\b(\d{2,3})K\b", rules):
        val = int(raw) * 1000
        if val not in allowed_abs and val != window:
            problems.append(f"rule text names {raw}K ({val}) — the gate derives "
                            f"{sorted(allowed_abs)} at CONTEXT_WINDOW={window}")
    for raw in re.findall(r"\b(\d{6})\b", rules):
        val = int(raw)
        if val not in allowed_abs and val != window:
            problems.append(f"rule text names {val} — the gate derives {sorted(allowed_abs)}")

    print("T-614 — CLAUDE.md budget ladder vs budget-gate.sh")
    print(f"  gate       CONTEXT_WINDOW={window}  " +
          "  ".join(f"{n}={p}% ({derived[n]})" for n, p in sorted(pcts.items())))
    print(f"  doc        {len(rules)} bytes of rule text across {len(RULE_SECTIONS)} sections")
    if problems:
        print("  DRIFT:")
        for p in sorted(set(problems)):
            print(f"      ! {p}")
        print()
        print("  A ladder written as absolute tokens goes stale when CONTEXT_WINDOW moves.")
        print("  Write the percentage as the rule; mark any absolute as illustrative.")
        return 1
    print("  OK — every percentage and token figure in the rule text is one the gate computes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
