#!/usr/bin/env python3
"""T-674: CTL-012 must ignore ACs inside HTML comments — and must still catch real ones.

This fences a FALSE-POSITIVE fix, which is the dangerous kind: the cheapest way to stop
a detector reporting something is to stop it reporting anything. So the arms are
deliberately asymmetric in importance —

  MUST NOT REPORT   a completed task whose only unticked `- [ ]` lines sit inside a
                    `<!-- ... -->` block. This is the bug: T-508 preserved its
                    superseded ACs in a comment, under the rationale that a rewritten
                    AC set hiding its own supersession is the laundering this project
                    keeps catching, and CTL-012 punished it for exactly that. Deleting
                    the block would have cleared the warn. The detector rewarded the
                    laundering it exists to catch.

  MUST REPORT       a completed task with a genuinely unticked LIVE AC. This arm is
                    load-bearing: a scanner gutted to return nothing passes the first
                    arm perfectly.

Plus the neighbouring behaviours that share the same loop and could be broken silently
by a change to it: Human-section ACs stay ignored, prose-DEFERRED markers stay skipped,
and the `missing-decide` classification still fires.

Every case is a throwaway .tasks/completed tree. Nothing here reads the real corpus.

Exit 0 all arms behaved, 1 any arm did not.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCANNER = os.path.join(REPO, ".agentic-framework", "agents", "audit",
                       "completed-task-scan.py")

FM = """---
id: %s
name: "fixture"
status: work-completed
workflow_type: %s
owner: claude-code
date_finished: 2026-09-04
---

# %s
"""


def task(tid, body, wtype="build"):
    return FM % (tid, wtype, tid) + body


# (label, body, must_report)
CASES = [
    ("commented-out superseded ACs (the T-508 shape)", """
## Acceptance Criteria

### Agent
- [x] The live criterion, ticked.

<!--
ORIGINAL ACs, kept because a rewritten AC set that hides its own supersession is
the laundering this project keeps catching.
- [ ] The two classes are separated mechanically
- [ ] A second superseded criterion
-->
""", False),

    ("genuinely unticked live AC — MUST still fire", """
## Acceptance Criteria

### Agent
- [x] One done.
- [ ] One genuinely outstanding.
""", True),

    # A comment that opens and closes on one line must not swallow the rest of it,
    # and must not leave the stripper stuck open for the remainder of the file.
    ("inline comment does not swallow the live AC after it", """
## Acceptance Criteria

### Agent
<!-- note --> - [ ] Live and outstanding, after an inline comment.
""", True),

    ("unticked AC only in the ### Human section", """
## Acceptance Criteria

### Agent
- [x] Agent side complete.

### Human
- [ ] [REVIEW] Someone must look at this.
""", False),

    ("prose-DEFERRED scope-cut marker", """
## Acceptance Criteria

### Agent
- [x] Done.
- [ ] **DEFERRED** to a follow-up task.
""", False),

    # A commented-out heading must not steer section state. Before T-674 the scanner
    # honoured `### Human` from inside a comment and went blind to everything after it.
    ("commented-out ### Human does not blind the scanner", """
## Acceptance Criteria

### Agent
<!-- ### Human -->
- [ ] Live, outstanding, and after a commented heading.
""", True),
]


def scan(tmp):
    r = subprocess.run(
        [sys.executable, SCANNER, os.path.join(tmp, ".tasks"),
         os.path.join(tmp, "episodic"), os.path.join(tmp, "reports")],
        capture_output=True, text=True)
    if r.returncode != 0:
        return None, r.stderr.strip()[:200]
    try:
        return json.loads(r.stdout), ""
    except Exception as exc:
        return None, "unparsable scanner output: %s" % exc


def build(tmp, tid, body, wtype="build"):
    d = os.path.join(tmp, ".tasks", "completed")
    os.makedirs(d, exist_ok=True)
    os.makedirs(os.path.join(tmp, "episodic"), exist_ok=True)
    os.makedirs(os.path.join(tmp, "reports"), exist_ok=True)
    with open(os.path.join(d, "%s-fixture.md" % tid), "w") as fh:
        fh.write(task(tid, body, wtype))


def main():
    print("T-674 CTL-012 comment-region fence\n")
    failures = []
    for i, (label, body, must_report) in enumerate(CASES):
        tid = "T-9%02d" % i
        tmp = tempfile.mkdtemp(prefix="t674-")
        try:
            build(tmp, tid, body)
            data, err = scan(tmp)
            if data is None:
                print("FAIL   %-56s scanner error: %s" % (label, err))
                failures.append(label)
                continue
            reported = any(u["id"] == tid for u in data.get("unchecked_ac", []))
            ok = reported == must_report
            print("%-6s %-56s want=%s got=%s" %
                  ("PASS" if ok else "FAIL", label,
                   "REPORT" if must_report else "silent",
                   "REPORT" if reported else "silent"))
            if not ok:
                failures.append(label)
        finally:
            shutil.rmtree(tmp, ignore_errors=True)

    # missing-decide shares the loop; a comment-stripping change could break it.
    tmp = tempfile.mkdtemp(prefix="t674-md-")
    try:
        build(tmp, "T-950", """
## Acceptance Criteria

### Agent
- [x] Explored.
<!-- @auto-tick-on-decide -->
@auto-tick-on-decide
- [ ] Decision recorded.

## Decision
""", wtype="inception")
        data, err = scan(tmp)
        cls = ""
        if data:
            for u in data.get("unchecked_ac", []):
                if u["id"] == "T-950":
                    cls = u.get("class", "")
        ok = cls == "missing-decide"
        print("%-6s %-56s want=missing-decide got=%s" %
              ("PASS" if ok else "FAIL", "missing-decide classification survives",
               cls or "not reported"))
        if not ok:
            failures.append("missing-decide classification")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    if failures:
        print("\nFENCE FAILED — %d arm(s): %s" % (len(failures), "; ".join(failures)))
        return 1
    print("\nFENCE PASSED — commented ACs are ignored, live ones are still caught,"
          "\nand the Human / DEFERRED / missing-decide behaviours are intact.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
