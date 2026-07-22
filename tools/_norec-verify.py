#!/usr/bin/env python3
"""_norec-verify.py — T-236 review-queue handoff guard.

Exit 1 if any task with UNCHECKED Human ACs lacks a parseable `## Recommendation`
verdict (GO/NO-GO/DEFER) — the NO-REC state that silently stalls the operator's
approvals queue ("agent thinks it handed over, operator sees nothing actionable").
HTML comments are stripped first, mirroring the Watchtower queue's parser, so
template example checkboxes never count. Stdlib-only; P-011 reads the exit code.

Origin: operator found "no approvals lined up" while 8 handed-over tasks sat
NO-REC (T-228 + this sweep). Verdict-at-handoff is the invariant this checks.
"""
import glob
import re
import sys

bad = []
for p in sorted(glob.glob('.tasks/active/*.md') + glob.glob('.tasks/completed/*.md')):
    s = open(p, encoding='utf-8', errors='replace').read()
    s = re.sub(r'<!--.*?-->', '', s, flags=re.S)
    m = re.search(r'^### Human\s*$(.*?)(?=^## |\Z)', s, re.M | re.S)
    if not m or not re.search(r'^\s*- \[ \]', m.group(1), re.M):
        continue                                   # no live (uncommented) Human ACs pending
    r = re.search(r'^## Recommendation\s*$(.*?)(?=^#{2,} |\Z)', s, re.M | re.S)
    if r and re.search(r'\*\*Recommendation:\*\*\s*(GO|NO-GO|DEFER)', r.group(1)):
        continue                                   # verdict present
    bad.append(p)

for p in bad:
    print('NO-REC:', p)
print('%d task(s) with pending Human ACs lack a Recommendation verdict' % len(bad))
sys.exit(1 if bad else 0)
