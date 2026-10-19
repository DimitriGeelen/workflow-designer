# T-702 Human AC#1 — reviewer evidence (rev 4008ed51)

## What I checked
- `.tasks/active/T-702-...md` @4008ed51, lines 121-132 (AC text) and the Decisions section (agent recommends Option A).
- `docs/reports/T-702-urgent-named.md` @4008ed51 (the census the AC tells the operator to read).
- Review page http://192.168.10.107:3013/review/T-702: NOT opened (no browser used); I judged from the committed files.

## What I found
1. **The criterion is a choice for the operator.** It asks for a letter, A or B, and under B a dismiss/promote/hold ruling on each of three orphans. The task text itself says the orphans are "yours alone" and "each a decision only the operator can make". Whether a risk-register finding (RA-006) counts as closed by enumeration rather than drain is a call on project direction. One orphan (OBS-251, minting a project termlink key) is about credentials. Under the operator ruling, both of these need a human.
2. **The census does not match the criterion (stale input to the decision).**
   - AC#1 text (line 121) says: 36 named; 25 carried-by-completed-task, 7 active, 3 orphan (**OBS-249, OBS-251, OBS-256**), 1 dangling (OBS-309).
   - The committed report (generated 2026-09-28) says: 28 rows; **25 carried-by-active-task, 3 orphan = OBS-251, OBS-398, OBS-407**. It has no completed-task class, no dangling row, and neither OBS-249 nor OBS-256.
   - So the operator would be asked to rule B on OBS-249 and OBS-256, which the census no longer lists as orphans. Meanwhile OBS-398 (inception scoring outranks build work) and OBS-407 (verify-queue found 3/5 partial-complete tasks RED) are orphans that the AC never mentions.

## Verdict
escalate: the decision belongs to the operator. Before it goes to them, the agent should reconcile the AC/Decisions text with the regenerated census so that the human rules on the correct orphans.
