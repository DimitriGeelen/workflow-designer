# T-592 Human AC#1 — evidence report

Reviewer: independent review worker (rung-3-termlink-single-reviewer), dispatch judge-t-592-r3-eab0f46fb117
Revision reviewed: c11c41b427032052a2ee4a1b4e6d4084833f3f1f
Criterion: "[REVIEW] Decide whether the vacuous-verification detector becomes a blocking gate"
Expected: one of (a)/(b)/(c) recorded, plus a yes/no on the CLAUDE.md paragraph edit.

## Verdict: green

Both halves of Expected are recorded in the task file at this revision, and every checkable
fact in the record holds.

## What I checked

1. The record. `git show c11c41b42 -- .tasks/active/T-592-*.md` adds, under the criterion,
   "Operator ruling, 2026-11-18 (in session, answering the escalation above): "b" — fix
   forward, then gate" and "Doc edit: yes, and already done upstream". It answers the previous
   reviewer's escalation (V-20261116-1e31a5c8), which is quoted directly above it. So one of
   (a)/(b)/(c) is recorded (b) and the doc-edit yes/no is recorded (yes, no further edit).
2. The follow-up the ruling names exists: `.tasks/active/T-1434-fix-the-live-vacuous-verification-legs-t.md`,
   status captured, created 2026-11-18T11:17:28Z, name "Fix the live vacuous verification
   legs, then make check-vacuous-verification a blocking gate (T-592 ruling b)". Added in the
   same commit.
3. Population. `python3 tools/check-vacuous-verification.py` prints `LIVE RISK 27` and
   `ADVISORY 530`. The 27 legs are in 11 task files: T-308 (4), T-310 (5), T-588, T-592,
   T-647, T-826, T-858 (1 each), T-866 (2), T-884 (7), T-1249 (2), T-1256 (2). One of the 11 is
   T-592's own demonstration leg, so "27 legs in 10 active tasks" is right for the tasks that
   need fixing and one short if T-592 itself is counted.
4. Self-test. `python3 tools/check-vacuous-verification.py --self-test` exits 0 with three
   PASS lines (planted defect found, honest forms not flagged, anchors on the last
   Verification block).
5. Doc-edit claim. `.tasks/templates/default.md` lines 148-167: line 150 "THE DEFAULT —
   redirect to a file, then grep the file", lines 151-153 give the `&&` file form and say it
   keeps the producing command's exit code; lines 160-167 say "Do NOT write
   `echo "$out" | grep -q PAT`" and cite T-4921 and 832 T-1340. The claim is accurate.
   `CLAUDE.md` contains no L-387 or T-352 text (grep count 0), so there is no paragraph left
   there to edit; the guidance lives in the template that stamps new tasks.
6. State matches ruling (b): `check-vacuous-verification` appears in no hook
   (`.claude/settings.json` count 0, none under `.git/hooks` or `.agentic-framework/agents`).
   The detector is still advisory, as (b) says it should be until T-1434 is done.

## Limits and notes

- I cannot independently confirm what the operator said in session. The ruling text was
  committed under the operator's git identity with an agent co-author; there is no separate
  operator-signed record of it. The criterion asks for the choice to be recorded, and it is.
  If the operator did not rule "b", this row is wrong and they should say so.
- The criterion's step 1 says "24 legs across 15 active tasks"; that count is from
  2026-08-26. The ruling records the current count, so Expected is unaffected.
- The brief said the evidence is images. No image is named in the criterion and none is in
  `.context/reviews/evidence/T-592/`; the evidence is the task file, the detector and the
  template, which I read and ran.
- Gating is not done. It is T-1434's work, not this criterion's.
