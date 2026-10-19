# T-402 Human AC#1 — "Decide local containment while upstream fixes it" (A / B / C)

Reviewer: judge-t-402-r3-b51042fff95d · revision cf2a6e1b40bb7db86ecc64ba7733ececed992911 · rung-3

## What I checked
1. Task file at the reviewed revision (`git show cf2a6e1b:.tasks/active/T-402-...md`).
   - The `## Findings` probe table is there: 5 of 9 misclassified at the time, with negative controls.
   - `## Decisions` and `## Decision` hold only the template. **No A/B/C letter is recorded anywhere**, and the Human AC box is unticked.
   - The agent recommends A, coupled to T-433. The UPDATE of 2026-10-05 (T-1045) says upstream's fix (AEF T-2919 `lib/cmd_classify.py` and T-2923) is now vendored, so "outcome A has happened".
2. I independently re-ran `python3 tools/_t402-gate-drive-probe.py`, which drives the real gate at critical in a scratch root. Result: **PASS, all 11 rows as recorded, exit 0.** All 5 earlier bypass shapes (compound, comment, string literal, fetch+exec) now classify as blocked. The negative controls stay blocked. Wrap-up and the heredoc-commit sentinels stay allowed.
3. `budget-gate.sh` now imports `cmd_classify` (lines 322 and 331). `git diff cf2a6e1b HEAD` shows no change to the file since the reviewed revision.

## Finding
- The facts support the agent's claim: the bypass is closed by upstream's code, and no local fork was ever carried. Choosing A would therefore cost nothing in practice.
- The criterion itself is not met: its Expected outcome is "one of A / B / C recorded as a decision on this task", and no decision is recorded.
- The criterion was put to the operator on purpose ("'A by choice' and 'A by nobody deciding' are the same observable"). It is a containment / risk-acceptance and fork-policy decision for an enforcement gate. That makes it a sovereignty / project-direction call, which a reviewer cannot make for the operator.

## Verdict: escalate
The operator needs to reply with a letter. Given the probe evidence above, A ("wait for upstream", now delivered) is a well-supported choice with no remaining exposure.
