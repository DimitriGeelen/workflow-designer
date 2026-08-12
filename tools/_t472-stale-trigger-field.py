#!/usr/bin/env python3
"""T-472 — flag tasks whose frontmatter `description:` still advertises a PENDING trigger
that the task's own body records as FIRED.

Origin: T-443's description read "TRIGGER: AEF answers DM 548 section 5" while its
`## Context`, four lines below, opened "AEF HAS RULED: KEEP THE PATH (DM 549 §5)". The
description was read as current state 32 rails later and the already-answered question was
put back to the peer who had answered it.

The class is narrower than "summaries decay": a task's SUMMARY FIELD outlives the body's
corrections, because correcting the body is where the work feels finished. Frontmatter is a
cache with no invalidation, and it is what every listing, handover and `fw task` view
renders. The body is where the truth gets written; the field is where it gets read.

HEURISTIC, deliberately. It cannot know that "TRIGGER: X" and "X HAS RULED" refer to the
same X — it pairs a pending-shaped description with a resolved-shaped body and asks a human
to look. False positives are the expected cost; a missed contradiction is the one that
costs a rail message. Exit 0 always: this reports, it does not gate.

Usage:  python3 tools/_t472-stale-trigger-field.py [--quiet]
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ACTIVE = os.path.join(ROOT, ".tasks", "active")

# Description says something is still awaited.
PENDING = re.compile(
    r"\bTRIGGER:|\bPENDING\b|\bawait(?:s|ing)?\b|\bstill open\b|\bunanswered\b|"
    r"\bblocked (?:on|behind)\b|\bopen at DM\b|\bwaiting (?:on|for)\b",
    re.I,
)
# Body says it landed.
#
# TIGHTENED after the first run scored 0/4 on real contradictions. What the loose form
# caught instead, and why each had to go:
#   - `\bANSWERED\b` matched `disposition: answered | deferred | dissolved` — TEMPLATE
#     boilerplate inside an HTML comment, present in every task from the revisit template.
#     Fixed by stripping comments (strip_comments) rather than by dropping the word.
#   - `\bdecision (?:landed|recorded)\b` matched `**Expected:** Decision recorded, task
#     completed` — a Human AC's Expected clause, i.e. a statement about the FUTURE.
#     Dropped: it cannot distinguish "was recorded" from "should be recorded".
#   - bare `\bFIRED\b` matched "completing the note dialog fired the claim" — a UI claim
#     firing. Homonym. Now requires the trigger/ruling sense explicitly.
# The surviving patterns all assert, in the past tense, that a decision arrived.
RESOLVED = re.compile(
    r"\bHAS RULED\b|\bRULED:|\bthey ruled\b|\bsuperseded\b|"
    r"\btrigger (?:has )?fired\b|\bresolved at\b|"
    r"\b(?:was|were|been) answered\b|\bANSWERED (?:at|from|by)\b",
    re.I,
)
# Template scaffolding and instructions-to-the-reader are not assertions about this task.
HTML_COMMENT = re.compile(r"<!--.*?-->", re.S)
# Already carries a marker from this check — reported separately, not as a new finding.
MARKED = re.compile(r"STALE-FIELD MARKER", re.I)


def split_task(text):
    """Return (frontmatter_description, body). Frontmatter is the first --- ... --- block."""
    if not text.startswith("---"):
        return "", text
    end = text.find("\n---", 3)
    if end == -1:
        return "", text
    fm, body = text[3:end], text[end + 4 :]
    m = re.search(r"^description:\s*(.*?)(?=^\w[\w_]*:)", fm, re.M | re.S)
    return (m.group(1) if m else ""), body


def main():
    quiet = "--quiet" in sys.argv
    hits, marked = [], []
    for name in sorted(os.listdir(ACTIVE)):
        if not name.endswith(".md"):
            continue
        path = os.path.join(ACTIVE, name)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        desc, body = split_task(text)
        if not desc or not PENDING.search(desc):
            continue
        if not RESOLVED.search(HTML_COMMENT.sub("", body)):
            continue
        (marked if MARKED.search(desc) else hits).append(
            (name.split("-")[0] + "-" + name.split("-")[1], name)
        )

    if not quiet:
        print("T-472 stale-trigger-field scan — %d active task(s) scanned" % len(os.listdir(ACTIVE)))
        print()
        if hits:
            print("FLAGGED — description advertises a pending trigger, body records it as resolved:")
            for tid, name in hits:
                print("  %-10s %s" % (tid, name))
            print()
            print("These are candidates, not verdicts. Open each and compare the")
            print("`description:` field against `## Context`. If the body is right, mark the")
            print("field superseded rather than deleting it — the wrong version is evidence.")
        else:
            print("No unmarked contradictions found.")
        if marked:
            print()
            print("Already carrying a STALE-FIELD MARKER (not re-reported):")
            for tid, name in marked:
                print("  %-10s %s" % (tid, name))
    print()
    print("flagged=%d marked=%d" % (len(hits), len(marked)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
