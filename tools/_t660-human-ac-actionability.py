#!/usr/bin/env python3
"""T-660 — is the operator's queue ACTIONABLE, not merely present?

WHY THIS EXISTS. P-010 gates on Agent ACs. P-011 runs Verification. The `### Human` section
is explicitly non-blocking — so the one class of criterion a *person* must act on is the
only one with no instrument at all. 010-termlink put it exactly right at rail @891:
gate-green and operator-actionable are separate properties, and only the first is measured.

Measured here on 2026-08-31: 13 of 51 live-queue tasks carried a Human AC that could not be
acted on as written. Nine of them were unruled inceptions whose first step read
`Run: fw task review T-XXX` — the literal placeholder, because create-task.sh substituted
the id into the frontmatter and the H1 and nowhere else. That root cause is fixed; this
reports the residue and the next regression.

WHAT IT DOES NOT DO. It never ticks, edits, or judges whether a criterion has been MET.
"Can this be acted on" and "has this been satisfied" are different questions, and answering
the second would be the agent grading the operator's work.

Exit 0 = every unticked Human AC in the live queue is actionable. Exit 1 = at least one is
not. Exit 3 = could not measure.
"""

import os
import re
import sys

# Non-greedy, and NOT a line-range delete. The task template keeps worked [REVIEW] and
# [REVIEWER] examples — with real `- [ ]` boxes AND full Steps/Expected/If-not — inside the
# ### Human section's HTML comment. Count those and every task looks perfectly actionable,
# which is the precise error this instrument exists to avoid. `sed '/<!--/,/-->/d'` is not
# equivalent: the range pairs each opener with the next closer anywhere in the file (T-655).
COMMENT = re.compile(r"<!--.*?-->", re.S)

# Placeholders that make a step impossible to execute without reconstructing intent.
# `<your ...>` is deliberately NOT here: "--rationale '<your reason>'" is a genuine
# fill-in-your-own-words prompt, not an unresolved template token.
PLACEHOLDER = re.compile(r"T-XXX|TBD|FIXME|\[Link to design|\[First criterion\]")


def audit_task(path):
    """Return (task_id, owner, [reasons]) — reasons empty means actionable."""
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            raw = fh.read()
    except OSError:
        return None

    fm = raw.split("---")[1] if raw.startswith("---") else ""

    def field(key):
        m = re.search(r"^%s:\s*(.*)$" % key, fm, re.M)
        return m.group(1).strip().strip('"') if m else ""

    task_id = field("id")
    owner = field("owner")
    if not task_id:
        return None

    body = COMMENT.sub("", raw)
    m = re.search(r"### Human(.*?)(?=\n## |\Z)", body, re.S)
    if not m:
        return None
    human = m.group(1)

    # Only unticked criteria matter. A ticked one has already been acted on, so its
    # legibility is a historical question, not a queue problem.
    if not re.search(r"^\s*-\s*\[ \]", human, re.M):
        return None

    # PREFIX matches, not exact strings. The first version of this checker required the
    # literal `**Steps:**` / `**Expected:**` / `**If not:**` and flagged T-426 and T-579,
    # both of which are among the best-written ACs in the queue: T-426 heads its block
    # `**Steps — option A (recommended), ...:**` and T-579 closes with `**If it is still
    # red after that:**`, which is a more useful fallback than the generic wording. That
    # was a chosen-set assertion — it could only find the spellings I had thought of, and
    # it would have had me rewrite good prose to satisfy a matcher. An instrument for
    # actionability must not become an instrument for house style.
    reasons = []
    if not re.search(r"\*\*Steps\b", human):
        reasons.append("no Steps: block")
    if not re.search(r"\*\*Expected\b", human):
        reasons.append("no Expected: clause")
    if not re.search(r"\*\*If\b", human):
        reasons.append("no If-not: fallback")
    for tok in sorted(set(PLACEHOLDER.findall(human))):
        reasons.append("unresolved placeholder %r" % tok)
    return (task_id, owner, reasons)


def main():
    root = os.environ.get("PROJECT_ROOT") or os.getcwd()
    active = os.path.join(root, ".tasks", "active")
    if not os.path.isdir(active):
        sys.stderr.write("COULD-NOT-MEASURE: %s not found\n" % active)
        return 3

    rows = []
    for name in sorted(os.listdir(active)):
        if not name.endswith(".md"):
            continue
        r = audit_task(os.path.join(active, name))
        if r:
            rows.append(r)

    # The live queue is what the operator is actually waiting on. Reporting a defect rate
    # over tasks nobody is waiting on would overstate the problem.
    live = [r for r in rows if r[1] == "human"]
    bad = [r for r in live if r[2]]

    print("Human ACs awaiting action : %d task(s) (%d in the live queue, owner: human)"
          % (len(rows), len(live)))
    if not bad:
        print("OK — every unticked Human AC in the live queue carries Steps, Expected,")
        print("     If-not, and no unresolved placeholder.")
        return 0

    print("")
    for task_id, _owner, reasons in bad:
        print("  NOT ACTIONABLE  %s" % task_id)
        for reason in reasons:
            print("                  - %s" % reason)
    print("")
    print("FAIL — %d of %d live-queue task(s) ask the operator for something they cannot"
          % (len(bad), len(live)))
    print("       execute as written. An AC that must be decoded before it can be run is")
    print("       a deferred sitting, not a pending decision.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
