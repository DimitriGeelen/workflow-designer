"""research_preserved — was an inception's thinking preserved, wherever it lives? (T-919)

THE RULING. Operator, 2026-09-16, on OBS-351: *"the task file counts."* C-001 says conversations are
ephemeral and files are permanent — and a task file IS a file, committed and durable. An inception
whose reasoning is recorded in its own task file satisfies C-001.

THE DEFECT THIS REPLACES. Both audit scanners decided "has research artifact" by LOCATION:

  completed-task-scan.py  a filename in docs/reports/ containing the task id, OR the literal string
                          "docs/reports/" anywhere in the body, OR an episodic reference
  active-task-scan.py     the filename test alone — narrower still

None asks whether the thinking was preserved. Measured on 2026-09-29, the completed scan flagged
T-250, T-587 and T-879, and every one held substantive exploratory prose in-task: T-250 a 738-char
Problem Statement and 1198-char Open Questions; T-587 680/569/515/413 across Problem Statement,
Exploration Plan, Technical Constraints and Scope Fence; T-879 a 513-char Hypothesis. The entire
output set was false positives under the ruling. OBS-351 recorded the rate as 50% on the four RA-00x
findings of 2026-09-16; on the live set it was 100%.

ONE ENCODING, ON PURPOSE. This lives in lib/ and is imported by both scanners rather than copied into
each. The delegation boundary in this same corpus is encoded twice — once in the path that enforces
and once in the path that reports — and the two were measured disagreeing on 2026-09-29 (G-052). A
second copy of "was the thinking preserved" would start the same drift on day one.
"""
from __future__ import annotations

import re

# RESEARCH-BEARING SECTIONS ONLY, and the exclusions are what make this discriminating. Every
# inception carries Acceptance Criteria, Verification, Updates, Recommendation, Decision and Go/No-Go
# by template, so counting those would make EVERY inception pass — retiring the check by accident,
# which is a worse outcome than the false positives it is fixing. What counts is the exploratory
# record: sections that exist only because someone thought on paper.
RESEARCH_SECTIONS = (
    "problem statement", "open questions", "exploration plan", "technical constraints",
    "hypothesis", "findings", "evidence", "dialogue log", "scope fence", "spikes",
    "prior art", "assumptions",
)

# The threshold carries the measurement it came from, not a round number chosen for looking right.
# The smallest genuine case observed when this was written is T-879's 513-character Hypothesis — its
# only research-bearing section. 400 admits it with ~20% margin. A section still holding its template
# measures under 50 once HTML comments and placeholder brackets are stripped, so the gap between
# "wrote something" and "left the template in place" is an order of magnitude, not a judgement call.
# Disagree with the number rather than guessing at one: it is here to be argued with.
RESEARCH_MIN_CHARS = 400

_SECTION_RE = re.compile(r"^## +(.+?)\s*$", re.M)
_COMMENT_RE = re.compile(r"<!--.*?-->", re.S)
_PLACEHOLDER_RE = re.compile(r"\[TODO\]|\[[A-Z][a-z]+(?: [a-z]+)*\]")


def research_chars(content: str) -> int:
    """Characters of substantive exploratory prose in the task file itself.

    HTML comments and placeholder brackets are stripped BEFORE measuring, so a task still holding its
    template scores near zero rather than passing on the template's own word count. That direction is
    the load-bearing one: a check that accepts the template accepts everything.
    """
    body = _COMMENT_RE.sub("", content or "")
    marks = list(_SECTION_RE.finditer(body))
    total = 0
    for i, m in enumerate(marks):
        name = m.group(1).strip().lower()
        if not any(name.startswith(s) for s in RESEARCH_SECTIONS):
            continue
        end = marks[i + 1].start() if i + 1 < len(marks) else len(body)
        total += len(_PLACEHOLDER_RE.sub("", body[m.end():end]).strip())
    return total


def research_preserved_in_task(content: str) -> bool:
    """True when the task file carries enough exploratory prose to satisfy C-001 on its own."""
    return research_chars(content) >= RESEARCH_MIN_CHARS
