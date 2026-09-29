#!/usr/bin/env python3
"""T-785 — does the census CREDIT the one leg this task repaired?

WHY THIS EXISTS RATHER THAN A LEG PINNING THE RATCHET. T-785's first draft of its own
`## Verification` pinned the global ratchet: "the census exits 0". That is a G-015 carrier —
"a line asserting a global, always-moving property ... that decays when anyone else edits the
tree" — and it decayed inside twenty minutes. Measured 2026-09-29: the census read
`baseline 74, current 74` (rc=0) at 10:01, and `74 / 75` (rc=1) at 10:09, because a CONCURRENT
session added an uncontrolled `test -z "$(git log --since=... -- <path>)"` leg to
`.tasks/active/T-826` at 10:08:43 while this task was being verified. Nothing about T-785's
repair changed between those two runs.

So the ratchet is the wrong thing for THIS task to gate on. It is a corpus-wide rise detector
owned by no single task, and coupling one task's close to it makes that close a function of
every other session's in-flight edits. What T-785 delivered is narrower and is what this probe
asserts: the specific leg that had risen above the baseline — T-859:296 — is now CREDITED, and
credited for the right reason.

NOT A WEAKENING, and the distinction matters because this task's scope forbids exactly that.
`_t560-absence-assertion-census.py` is unchanged by this file. `_t560-absence-baseline.txt` is
unchanged (still 74). No exclusion list grew. The ratchet still fails on a rise, and it is
failing right now on T-826's leg — correctly, and for someone else to answer. This probe adds
an assertion; it removes none.

Exit 0 = the leg is credited PATTERN. 1 = it is not. 2 = the probe could not measure
(the leg or the file moved) — an ABSTENTION, never to be read as a pass.
"""
import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CENSUS = os.path.join(ROOT, "tools", "_t560-absence-assertion-census.py")
TARGET = os.path.join(ROOT, ".tasks", "completed",
                      "T-859-t542-cost-axis-guard-raises-attributeerr.md")

if not os.path.exists(CENSUS) or not os.path.exists(TARGET):
    print("REFUSE: census or target task file missing — nothing measured.")
    sys.exit(2)

spec = importlib.util.spec_from_file_location("census", CENSUS)
c = importlib.util.module_from_spec(spec)
spec.loader.exec_module(c)

legs = c.verification_legs(TARGET)
hits = [(n, t) for n, t in legs if "grep -c Traceback" in t and "-eq 0" in t]
if len(hits) != 1:
    print("REFUSE: expected exactly 1 'grep -c Traceback ... -eq 0' leg in %s, found %d."
          % (os.path.relpath(TARGET, ROOT), len(hits)))
    print("        The leg was edited or removed. Re-derive rather than trust a green.")
    sys.exit(2)

lineno, text = hits[0]
siblings = [t for n, t in legs if n != lineno]

# 1. The leg IS an absence assertion — if it stopped being one, this probe is vacuous.
forms = c.classify(text)
# 2. Its pattern is readable at all. This is the T-785 change; without it, credit is impossible.
pats = c.patterns_in(text)
# 3. And it is credited, by a sibling that greps the same string.
level = c.control_level(text, siblings)

print("T-859:%d  %s" % (lineno, text.strip()))
print("  absence forms : %s" % (forms or "NONE — leg is no longer an absence assertion"))
print("  patterns read : %r" % (pats,))
print("  control level : %s" % level)

fail = []
if not forms:
    fail.append("the leg is no longer classified as an absence assertion, so crediting it "
                "proves nothing — this probe would be vacuous")
if "Traceback" not in pats:
    fail.append("the bare pattern 'Traceback' is not readable — GREP_PAT regressed to "
                "quoted-only and the leg is uncontrollable again")
if level != "PATTERN":
    fail.append("control level is %s, not PATTERN — the companion leg appended under PD-308 "
                "is gone or no longer greps the same string" % level)

if fail:
    print("\nT-785 CREDIT PROBE: FAIL")
    for f in fail:
        print("  - %s" % f)
    sys.exit(1)

print("\nT-785 CREDIT PROBE: PASS — the repaired leg is read, classified and PATTERN-credited.")
sys.exit(0)
