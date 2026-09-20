#!/usr/bin/env python3
"""T-739 — a recorded DEFER is not a made decision.

Reproduces, from the LIVE tree, the defect where `fw review-queue`'s DECISIONS
section permanently drops any inception that has recorded a DEFER.

  fw:5748  DECISION_RE = re.compile(r"^\\*\\*Decision\\*\\*:\\s*(GO|NO-GO|DEFER)\\b", re.M)
  fw:5768  if workflow_type == "inception" and not DECISION_RE.search(text):

DEFER sits in the alternation and a MATCH is used as an EXCLUSION, so recording a
deferral removes the task from the surface whose entire job is to show pending
decisions. A DEFER is the explicit statement that the decision has NOT been made.

WHY THIS READS THE SHIPPED REGEX INSTEAD OF DECLARING ITS OWN (PL-159, T-445):
"a bar stated in a failure-message string is not a bar the instrument holds."
A probe carrying a private copy of DECISION_RE tests the copy, not the product,
and would keep passing after fw drifts underneath it. This extracts the pattern
from .agentic-framework/bin/fw at run time. If the line cannot be found, that is
itself a failure (exit 2) rather than a silent pass.

Exit codes:
  0 — no active inception is hidden from DECISIONS by a recorded DEFER
  1 — at least one is hidden (the defect is live)
  2 — probe could not read the shipped regex (inconclusive, never a silent pass)
"""
import ast
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FW = ROOT / ".agentic-framework" / "bin" / "fw"
ACTIVE = ROOT / ".tasks" / "active"

# The terminal verbs: a decision that is actually MADE. A DEFER is not one of them.
TERMINAL = {"GO", "NO-GO"}


def shipped_decision_re():
    """Extract and compile DECISION_RE from the shipped fw source."""
    if not FW.is_file():
        print(f"INCONCLUSIVE: fw not found at {FW}", file=sys.stderr)
        sys.exit(2)
    src = FW.read_text(errors="replace")
    m = re.search(r"^\s*DECISION_RE\s*=\s*re\.compile\(\s*(r?\"[^\"]*\")", src, re.M)
    if not m:
        print("INCONCLUSIVE: could not locate the DECISION_RE assignment in fw.",
              file=sys.stderr)
        print("The probe refuses to substitute its own copy (PL-159).", file=sys.stderr)
        sys.exit(2)
    pattern = ast.literal_eval(m.group(1))
    line_no = src[:m.start()].count("\n") + 1
    return re.compile(pattern, re.M), pattern, line_no


def workflow_type_of(text):
    fm = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not fm:
        return "", ""
    wf = re.search(r"^workflow_type:\s*(\S+)", fm.group(1), re.M)
    st = re.search(r"^status:\s*(\S+)", fm.group(1), re.M)
    return (wf.group(1).strip() if wf else ""), (st.group(1).strip() if st else "")


def would_pass_second_filter(text, status):
    """fw:5770-5776 — after the DECISION_RE gate, a row still needs a substantive
    ## Recommendation or status started-work. Replicated so the probe does not
    over-claim that removing the DEFER exclusion alone makes a task visible."""
    rec = re.search(r"^## Recommendation\s*$(.*?)(?=^#{2,} |\Z)", text, re.M | re.DOTALL)
    body = re.sub(r"<!--.*?-->", "", rec.group(1) if rec else "", flags=re.DOTALL).strip()
    return len(body) >= 20 or status == "started-work"


def main():
    decision_re, pattern, line_no = shipped_decision_re()
    print(f"Shipped DECISION_RE (fw:{line_no}): {pattern}")

    if not ACTIVE.is_dir():
        print(f"INCONCLUSIVE: no {ACTIVE}", file=sys.stderr)
        sys.exit(2)

    hidden, decided, pending = [], [], []
    for f in sorted(ACTIVE.glob("*.md")):
        text = f.read_text(errors="replace")
        wf, status = workflow_type_of(text)
        if wf != "inception":
            continue
        m = decision_re.search(text)
        if not m:
            pending.append(f.stem)
            continue
        verb = m.group(1).upper()
        if verb in TERMINAL:
            decided.append((f.stem, verb))
        else:
            hidden.append((f.stem, verb, would_pass_second_filter(text, status), status))

    print(f"Active inceptions scanned: {len(decided) + len(hidden) + len(pending)}")
    print(f"  excluded, decision MADE ({'/'.join(sorted(TERMINAL))}): {len(decided)}")
    print(f"  listed, no decision block yet:                {len(pending)}")
    print(f"  excluded by a NON-terminal decision verb:     {len(hidden)}")

    if not hidden:
        print("\nPASS — no active inception is hidden from DECISIONS by a recorded "
              "non-terminal decision.")
        return 0

    print("\nFAIL — these tasks recorded a decision that was never made, and the "
          "DECISIONS queue drops them:")
    for stem, verb, visible, status in hidden:
        note = "would appear once the exclusion is fixed" if visible else (
            "STILL hidden by the ## Recommendation/status filter at fw:5770")
        print(f"  {stem}")
        print(f"      recorded **Decision**: {verb}   status={status}   → {note}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
