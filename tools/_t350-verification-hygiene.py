#!/usr/bin/env python3
"""_t350-verification-hygiene.py — assert T-350's own ## Verification block does not
commit the subject error G-015 records (T-350 AC8).

G-015 is about verification lines that assert a GLOBAL, always-moving property instead of
a property of the task that carries them. Two carriers are on record: 75 lines running
`diff src/aef-workflow-designer.html build/gallery/designer.html`, and 11 lines with a
hard-coded port. A task whose whole purpose is to remedy that gap must not ship either.

Finds the task file by ID in active/ or completed/ so the check survives the move that
`work-completed` performs. Exits non-zero naming the offending line.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TASK_ID = sys.argv[1] if len(sys.argv) > 1 else "T-350"

matches = sorted(
    glob.glob(os.path.join(ROOT, ".tasks", "active", TASK_ID + "-*.md"))
    + glob.glob(os.path.join(ROOT, ".tasks", "completed", TASK_ID + "-*.md"))
)
if not matches:
    sys.exit("HYGIENE: no task file found for %s in active/ or completed/ — "
             "this check would otherwise pass over nothing" % TASK_ID)
path = matches[0]

text = open(path, encoding="utf-8").read()
# Anchor on the HEADING, not the string. An AC that talks about "## Verification" puts the
# same characters in the body, and splitting on the raw string captured that prose instead
# of the block — the check then flagged a criterion for describing the rule it enforces.
m = re.search(r"^## Verification[ \t]*$", text, re.M)
if not m:
    sys.exit("HYGIENE: %s has no ## Verification heading — nothing to check, which is "
             "not the same as clean" % os.path.basename(path))

block = re.split(r"^## ", text[m.end():], maxsplit=1, flags=re.M)[0]
lines = [ln for ln in block.splitlines()
         if ln.strip() and not ln.strip().startswith("#")]
if not lines:
    sys.exit("HYGIENE: the ## Verification block of %s holds no executable lines — an "
             "empty block cannot fail, so a clean verdict here would be vacuous"
             % os.path.basename(path))

problems = []
for ln in lines:
    if re.search(r"\b(diff|cmp)\b.*build/gallery", ln) or \
       re.search(r"build/gallery.*\b(diff|cmp)\b", ln):
        problems.append("asserts the serve root matches src (the exact 75-line G-015 "
                        "carrier): %s" % ln.strip())
    # A port literal. Ports live in .context/working/watchtower.{port,url} or are
    # discovered free at runtime; a literal pins a host-level fact into a per-task gate.
    for m in re.finditer(r":(\d{2,5})\b", ln):
        problems.append("hard-codes port %s (the 11-line G-015 carrier): %s"
                        % (m.group(1), ln.strip()))

if problems:
    print("HYGIENE FAIL — %s ## Verification carries the defect the task remedies:"
          % os.path.basename(path), file=sys.stderr)
    for p in problems:
        print("  - " + p, file=sys.stderr)
    sys.exit(1)

print("hygiene ok: %s ## Verification (%d executable line(s)) has no serve-root diff and "
      "no hard-coded port" % (os.path.basename(path), len(lines)))
