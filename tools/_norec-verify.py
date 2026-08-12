#!/usr/bin/env python3
"""_norec-verify.py — T-236 review-queue handoff guard.

Exit 1 if any task with UNCHECKED Human ACs lacks a parseable `## Recommendation`
verdict (GO/NO-GO/DEFER) — the NO-REC state that silently stalls the operator's
approvals queue ("agent thinks it handed over, operator sees nothing actionable").
HTML comments are stripped first, mirroring the Watchtower queue's parser, so
template example checkboxes never count. Stdlib-only.

Origin: the operator found "no approvals lined up" while 8 handed-over tasks sat
NO-REC (T-228 + the T-236 sweep). Verdict-at-handoff is the invariant this checks.

EXIT CODES (T-450)
  0  every handed-over task carries a verdict — a green about a NAMED corpus
  1  at least one task with pending Human ACs has no verdict
  2  the corpus could not be enumerated. Nothing was examined; NOT a pass.

ABSTAIN IS A VERDICT (T-454)
The vocabulary was GO/NO-GO/DEFER, and that set has no token for the case where the
agent has *deliberately decided not to recommend*. T-341 is one: the consolidated brief
rules it "operator only — no agent recommendation", because which lane authority falls
to when a reference fails is a question about where power lands, and an agent proposing
an answer is the agent proposing its own authority. Under the old vocabulary such a task
could satisfy this guard only by MANUFACTURING a recommendation. That is a gate paying
for its own green, and it was caught live: T-454 re-tokenised T-341's superseded
proposal to `GO` purely to clear this check, then reverted it.

So ABSTAIN parses. But it is reported on its OWN line, never folded into the verdict
count, because the obvious failure mode of adding an escape token is that it becomes the
cheap way to empty a queue. An abstention wave and a well-served queue must not print the
same number — the same reason (2) below is named rather than silently passed. Three
populations, three counts (PL-084, PL-160).

Why 2 has to exist. Until T-450 this tool printed

    0 task(s) with pending Human ACs lack a Recommendation verdict

and exited 0 from three different worlds, character-identically:

  1. the corpus is unreadable or empty (`.tasks/` missing, or holding no `*.md`),
  2. the corpus is fine and nobody has handed anything over (queue genuinely empty),
  3. the corpus is fine, N tasks are handed over, and all of them carry a verdict.

Only (3) is the green this guard was built to certify. (1) is G-034: a verdict
computed from a tally of FAILURES alone reports "clean" when it means "empty". The
tool that exists *because* a silent zero once told the operator there was nothing to
approve was emitting one of its own, in the same voice, for a year.

2 rather than 1 is the T-430 abstention discipline — 1 means "I looked and it is
bad", 0 means "I looked and it is fine", and a run that examined nothing is neither.
Collapsing it into 0 is the defect above; collapsing it into 1 would send someone
hunting a queue defect that is not there.

(2) is not refused — an empty approvals queue is a legitimate, healthy state. But it
is NAMED, because "nothing to approve" is the precise sentence that misled the
operator, and this guard must not be able to say it without also saying how many
task files it read to get there.

The corpus size is deliberately not written down here. It derives from TASK_DIRS,
which is CLAUDE.md's task file structure; a restated denominator rots the day the
corpus grows (PL-158, T-444).
"""
import glob
import os
import re
import sys

# The AUTHORITY this guard is measured against — CLAUDE.md §Task System's file
# structure, not a convenience pair of globs. Both are required: a tree missing
# either is not a task corpus, and saying so is a different statement from
# reporting zero findings over it.
TASK_DIRS = ('.tasks/active', '.tasks/completed')


def refuse(msg):
    """Stop without a verdict. Exit 2, never 0, never 1."""
    sys.stderr.write('REFUSING: ' + msg + '\nNothing was examined; this is not a pass.\n')
    raise SystemExit(2)


def corpus():
    """Every task file the queue is drawn from, or a refusal naming what was missing."""
    absent = [d for d in TASK_DIRS if not os.path.isdir(d)]
    if absent:
        refuse('task director%s missing: %s. An approvals queue cannot be read out of a '
               'tree that is not a task corpus.'
               % ('y' if len(absent) == 1 else 'ies', ', '.join(absent)))
    files = sorted(f for d in TASK_DIRS for f in glob.glob(os.path.join(d, '*.md')))
    if not files:
        refuse('no *.md task files under %s, so there is no queue to report on. '
               '"0 lack a verdict" over an empty corpus is exactly the sentence this '
               'guard exists to stop the operator from reading.' % ' or '.join(TASK_DIRS))
    return files


files = corpus()
pending, bad, abstained = [], [], []
for p in files:
    s = open(p, encoding='utf-8', errors='replace').read()
    s = re.sub(r'<!--.*?-->', '', s, flags=re.S)
    m = re.search(r'^### Human\s*$(.*?)(?=^## |\Z)', s, re.M | re.S)
    if not m or not re.search(r'^\s*- \[ \]', m.group(1), re.M):
        continue                                   # no live (uncommented) Human ACs pending
    pending.append(p)                              # handed over — the subject population
    r = re.search(r'^## Recommendation\s*$(.*?)(?=^#{2,} |\Z)', s, re.M | re.S)
    v = re.search(r'\*\*Recommendation:\*\*\s*(GO|NO-GO|DEFER|ABSTAIN)', r.group(1)) if r else None
    if v:
        if v.group(1) == 'ABSTAIN':
            abstained.append(p)                    # a verdict, but counted apart — see docstring
        continue
    bad.append(p)

for p in bad:
    print('NO-REC:', p)

# THREE counts, not one. The old last line was a tally of failures alone, so an empty
# queue and a clean one printed the same string — and that is the distinction the
# operator actually needs, because it is the one they got wrong (T-228). Printing the
# denominator alongside the finding is what makes "clean" and "empty" different
# sentences (PL-084); the same fix T-447 applied to bake-clean-layout's scope line.
for p in abstained:
    print('ABSTAIN:', p)

print('examined %d task file(s) under %s  ·  %d with pending Human ACs  ·  %d agent '
      'ABSTAIN (declined to recommend, explicitly)  ·  %d without a Recommendation verdict'
      % (len(files), ' + '.join(TASK_DIRS), len(pending), len(abstained), len(bad)))
if abstained and not bad:
    print('Queue is clear of SILENT gaps, but %d task(s) carry an explicit abstention: the '
          'agent declined\nto recommend and the ruling is entirely yours. That is a smaller '
          'handover than a verdict,\nnot a completed one.' % len(abstained))
if not pending:
    print('Queue is EMPTY, not merely clean: no task in that corpus has a pending Human AC.')
sys.exit(1 if bad else 0)
