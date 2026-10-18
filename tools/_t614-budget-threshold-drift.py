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

SINCE AEF v1.8.11 (T-4226, 832 T-1204) the gate has no percentages: it reads its thresholds
from lib/budget_ladder.py, one ladder from the spawn reserve. The guard then asks that module
for the thresholds at the default window and at each window the rule text illustrates, and
treats any percentage in the rule text as drift. The percentage path stays for an older gate.

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


LADDER = REPO / ".agentic-framework" / "lib" / "budget_ladder.py"


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


def ladder_thresholds(window):
    """T-1204 (AEF v1.8.11, T-4226): the gate no longer computes percentages; it reads
    TOKEN_WARN/URGENT/CRITICAL from lib/budget_ladder.py. Ask that module, never re-derive it."""
    import subprocess
    p = subprocess.run([sys.executable, "-I", str(LADDER), str(window)],
                       capture_output=True, text=True)
    if p.returncode != 0:
        return {}
    kv = dict(ln.split("=", 1) for ln in p.stdout.splitlines() if "=" in ln)
    return {k[6:].lower(): int(v) for k, v in kv.items() if k.startswith("TOKEN_")}


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

    gate = GATE.read_text()
    window, pcts = gate_thresholds(gate)
    if not window:
        print("CANNOT MEASURE: could not read the default CONTEXT_WINDOW out of budget-gate.sh — "
              "its shape changed, and this guard would otherwise pass by finding nothing to compare")
        return 2

    doc = DOC.read_text()
    rules = rule_text(doc)
    if not rules.strip():
        print(f"CANNOT MEASURE: none of {RULE_SECTIONS} found in CLAUDE.md — a renamed "
              f"heading would make this guard pass vacuously")
        return 2

    if len(pcts) >= 3:          # the percentage gate (pre-v1.8.11)
        derived = {n: window * p // 100 for n, p in pcts.items()}
        allowed_pct = set(pcts.values())
        allowed_abs = set(derived.values())
        windows = {window}
    elif "budget_ladder" in gate and LADDER.exists():
        # The ladder gate: no percentages at all, so any `NN%` in the rule text is drift. The
        # absolutes may be illustrated at the default window and at any window the rule text
        # names as "at NNNK" (it shows 800K and 975K); each must be what the ladder derives there.
        # Only the two illustration forms count as naming a window: "the 800K default" and
        # "at 975K," / "at 975K:". A bare "at 650K" is a threshold, not a window.
        named = re.findall(r"\bthe (\d{3,4})K default\b|\b[Aa]t (\d{3,4})K[,:]", rules)
        windows = {window} | {int(a or b) * 1000 for a, b in named}
        derived = ladder_thresholds(window)
        if len(derived) < 3:
            print("CANNOT MEASURE: lib/budget_ladder.py did not yield TOKEN_WARN/URGENT/CRITICAL")
            return 2
        allowed_pct = set()
        allowed_abs = set()
        for w in windows:
            allowed_abs |= set(ladder_thresholds(w).values())
        pcts = {n: "ladder" for n in derived}
    else:
        print("CANNOT MEASURE: budget-gate.sh neither computes percentages nor reads "
              "lib/budget_ladder.py — its shape changed again")
        return 2

    problems = []

    # 1. percentages named in the rule text
    for pct in {int(x) for x in re.findall(r"(\d{2})\s*%", rules)}:
        if pct not in allowed_pct:
            problems.append(f"rule text names {pct}% — the gate computes only "
                            f"{sorted(allowed_pct)}")

    # 2. absolute token figures. "225K" and "225000" are the same claim.
    for raw in re.findall(r"\b(\d{2,3})K\b", rules):
        val = int(raw) * 1000
        if val not in allowed_abs and val not in windows:
            problems.append(f"rule text names {raw}K ({val}) — the gate derives "
                            f"{sorted(allowed_abs)} at CONTEXT_WINDOW in {sorted(windows)}")
    for raw in re.findall(r"\b(\d{6})\b", rules):
        val = int(raw)
        if val not in allowed_abs and val not in windows:
            problems.append(f"rule text names {val} — the gate derives {sorted(allowed_abs)}")

    print("T-614 — CLAUDE.md budget ladder vs budget-gate.sh")
    print(f"  gate       CONTEXT_WINDOW={window}  " +
          "  ".join(f"{n}={p}{'%' if p != 'ladder' else ''} ({derived[n]})" for n, p in sorted(pcts.items())))
    print(f"  windows    {sorted(windows)} (default + those the rule text illustrates)")
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
