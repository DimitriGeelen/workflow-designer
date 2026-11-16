# T-592 Human AC#1 — evidence report

Reviewer: independent review worker (rung-3-termlink-single-reviewer)
Revision reviewed: 498b0cbb75cab0ab21543832da98dc2a8d903985
Criterion: "[REVIEW] Decide whether the vacuous-verification detector becomes a blocking gate"
Expected: one of (a)/(b)/(c) recorded, plus a yes/no on the CLAUDE.md paragraph edit.

## Verdict: escalate

The criterion asks for a decision, not a measurement. No such decision is recorded, and it
is the operator's to make (project direction: whether a new blocking gate lands on other
people's active tasks). I verified the inputs to the decision; I did not make it.

## What I ran

1. `python3 tools/check-vacuous-verification.py` — exit 0.
   Output today: `LIVE RISK 33` (32 `[quiet]`, 1 `[loud]`) across 15 distinct active tasks;
   `ADVISORY 527` in completed tasks.
   The criterion's step 1 says "24 legs across 15 active tasks"; the task body says
   "Live 24 / advisory 292". The task count still matches (15); the leg count does not
   (33 now, 24 at filing on 2026-08-26). The population has grown by 9 live legs while the
   decision has been open, which is the "If not" consequence the criterion predicts.
   One of the 33 is T-592's own demonstration leg (the poisoned control), which is flagged
   by design of its content, not a defect.
2. `python3 tools/check-vacuous-verification.py --self-test` — exit 0, three PASS lines:
   exactly the planted defect found (1 hit, poisoned.md); honest forms (bare, `&&` file
   form, `! grep -qE`) not flagged; anchors on the LAST `## Verification` block.

## Is a decision recorded anywhere?

- Task file `## Decisions` and `## Decision` sections: template comments only, empty.
- Human AC checkbox: unticked. `## Recommendation` holds the producer's recommendation of
  (b), which is advice to the operator, not the operator's choice.
- `.context/reviews/evidence/T-592/` did not exist before this run; no prior verdict rows
  seen for this AC.
- Other tasks mentioning T-592 (T-843, T-844, T-847, T-1063) concern a different detector
  (uncontrolled absence assertions) and T-592 being "never judged"; none records (a)/(b)/(c).
- The detector is referenced by no hook: no match for `check-vacuous-verification` in
  `.claude/settings.json` or `.agentic-framework/lib/*.sh`. It is still advisory, i.e. the
  de facto state is (b)-without-the-follow-up or (c), by default rather than by decision.

## Second half: the CLAUDE.md paragraph edit

- `grep -n "L-387\|T-352\|errexit\|vacuous" CLAUDE.md` returns nothing, and no CLAUDE.md in
  the tree contains `L-387`. The criterion's step 4 premise ("L-387 ... T-352 ... both are in
  the same file", meaning CLAUDE.md) does not hold at this revision.
- The two halves ARE joined in the Verification hints comment block as it appears in the
  T-592 task file itself: an "ERREXIT WARNING (T-352)" paragraph, and the L-387 hint now
  labelling the file form `PREFERRED: && not ;` and the capture form
  `SIGPIPE-safe, errexit-blind`. So the doc-joining the criterion asks a yes/no on appears
  already done, in the hints block rather than in CLAUDE.md. I did not locate the template
  source file it is stamped from, so I cannot say new tasks receive that text.
  No yes/no from the operator is recorded either way.

## Why escalate and not green/amber/red

- Not green: Expected is a recorded choice; none exists.
- Not amber/red: nothing is wrong with the work under review that an agent could fix; the
  missing thing is the operator's choice itself. A reviewer picking (a)/(b)/(c) would be
  making a project-direction call (a blocking gate that reddens 15 active tasks), which the
  task itself reserves to the operator.

## What the operator needs to do

Record one of (a)/(b)/(c) and a yes/no on the doc edit. Facts to decide on, as of this
revision: 33 live legs in 15 active tasks (not 24); detector self-test passes; detector not
wired to any gate; the hints-block wording already prefers the `&&` file form, and CLAUDE.md
itself carries no L-387/T-352 text to edit.
