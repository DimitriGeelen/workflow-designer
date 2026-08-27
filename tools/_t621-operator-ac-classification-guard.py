#!/usr/bin/env python3
"""T-621 — an Agent AC that names the operator as decider is a deadlock, not a criterion.

WHY THIS EXISTS. /approvals surfaces `### Human` ACs and inception decisions. A criterion
whose own text says the outcome is the operator's ("Operator decision recorded", "Operator
approves or rejects...") but which is filed under `### Agent` is invisible to the person who
must act on it. Meanwhile P-010 refuses completion while it is unchecked, and the agent must
not check it because it is not the agent's to verify. The only exit is a bypass — which is how
a governance gate quietly becomes a formality.

T-537 and T-540 sat in exactly that state and appeared on no operator surface. This guard is
the prevention half; reclassifying those two was the mitigation half (G-019: mitigation is not
prevention).

Exit 0 = clean. 1 = at least one mis-filed criterion. 2 = cannot measure (NOT a pass).
"""
import re
import sys
from pathlib import Path

ACTIVE = Path(__file__).resolve().parent.parent / ".tasks" / "active"

# The operator must be the ACTOR on a deciding verb. Deliberately narrow: an incidental
# mention ("the operator will see the banner") is context, not a decision, and firing on it
# would train people to ignore this guard.
OPERATOR_DECIDES = re.compile(
    r"(operator\s+(decision|approves|rejects|rules|ratifies|decides|authorises|authorizes|must\s+decide)"
    r"|blocked\s+on\s+the\s+operator"
    r"|the\s+operator'?s?\s+(call|ruling|decision)\s+to\s+make"
    r"|requires?\s+(an?\s+)?operator\s+(decision|ruling|approval))",
    re.I,
)

SELF_TEST = [
    ("**Operator decision recorded.** termlink is shared tooling", True),
    ("**Operator approves or rejects the three proposals**", True),
    ("Blocked on the operator — this task claims no fix", True),
    ("The operator will see the banner on /approvals", False),
    ("Endpoint returns 200 and the operator dashboard renders", False),
    ("Guard exits 2 when the register is absent", False),
]

# End-to-end: the same operator phrase must be REPORTED when unchecked and IGNORED when
# ticked. Asserting the matcher alone would miss a regression in criteria() itself.
SECTION_TEST = """### Agent
- [x] No widening of the push gate under agent initiative — scope is an operator decision
- [ ] **Operator approves or rejects the three proposals**, and rules on the drivers
- [ ] Endpoint returns 200 and the operator dashboard renders

### Human
"""


def agent_block(text):
    m = re.search(r"^### Agent\b(.*?)(?=^### |^## )", text, re.S | re.M)
    return m.group(1) if m else None


def criteria(block):
    """Only UNCHECKED criteria. A ticked Agent AC was, by definition, verifiable by the agent
    — it may *describe* an operator decision as a constraint ("no key claims an operator
    decision") without being one. The deadlock this guard exists for is specifically an
    UNCHECKED criterion the agent must not tick and the operator is never shown."""
    out, cur = [], None
    for line in block.splitlines():
        if re.match(r"\s*- \[[ x]\]", line):
            if cur:
                out.append(cur)
            cur = line if re.match(r"\s*- \[ \]", line) else None
            continue
        if False:
            pass
        elif cur is not None and line.strip() and line.startswith((" ", "\t")):
            cur += " " + line.strip()
        elif cur is not None and not line.strip():
            out.append(cur)
            cur = None
    if cur:
        out.append(cur)
    return out


def self_test():
    """A detector nobody has tried to fool is a detector nobody should trust."""
    bad = [(s, exp) for s, exp in SELF_TEST if bool(OPERATOR_DECIDES.search(s)) != exp]
    print("SELF-TEST — the matcher must fire on decisions and stay silent on mentions")
    for s, exp in SELF_TEST:
        got = bool(OPERATOR_DECIDES.search(s))
        print(f"  [{'ok  ' if got == exp else 'FAIL'}] expected={exp!s:<5} got={got!s:<5} {s[:56]}")
    hits = [c for c in criteria(agent_block(SECTION_TEST)) if OPERATOR_DECIDES.search(c)]
    ok_e2e = len(hits) == 1 and "Operator approves" in hits[0]
    print(f"  [{'ok  ' if ok_e2e else 'FAIL'}] end-to-end: ticked operator-mention ignored, "
          f"unticked one reported (got {len(hits)})")
    return not bad and ok_e2e


def main():
    if not self_test():
        print("\nCANNOT MEASURE: the matcher failed its own self-test")
        return 2
    if not ACTIVE.is_dir():
        print("CANNOT MEASURE: .tasks/active/ not found — a moved tree would otherwise make "
              "this guard pass by finding nothing to check")
        return 2
    files = sorted(ACTIVE.glob("*.md"))
    if not files:
        print("CANNOT MEASURE: no task files under .tasks/active/")
        return 2

    findings, scanned = [], 0
    for f in files:
        block = agent_block(f.read_text(errors="replace"))
        if block is None:
            continue
        scanned += 1
        for c in criteria(block):
            m = OPERATOR_DECIDES.search(c)
            if m:
                findings.append((f.name, m.group(0), re.sub(r"\s+", " ", c)[:150]))

    if scanned == 0:
        print(f"\nCANNOT MEASURE: {len(files)} task file(s) but none carries a '### Agent' "
              f"section — the AC split may have been renamed, and this guard would otherwise "
              f"pass vacuously")
        return 2

    print(f"\nLIVE — {scanned} task(s) with an ### Agent section")
    if findings:
        print(f"\n  {len(findings)} operator-decision criterion(s) mis-filed under ### Agent:\n")
        for name, phrase, txt in findings:
            print(f"    {name}")
            print(f"      matched: {phrase!r}")
            print(f"      {txt}\n")
        print("  Such an AC is a deadlock: /approvals never shows it, P-010 blocks completion")
        print("  while it is unchecked, and the agent must not check it. The only exit is a")
        print("  bypass. Move it to '### Human' with Steps/Expected/If-not.")
        return 1
    print("\n  OK — no Agent AC names the operator as the deciding party")
    return 0


if __name__ == "__main__":
    sys.exit(main())
