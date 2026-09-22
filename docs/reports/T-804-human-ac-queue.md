# T-804 — "I don't want to tick ACs, why should I?"

**Short answer: for most of this queue, you shouldn't — and the reason is not the one I
expected.**

---

## 1. My hypothesis was wrong

I went in expecting to find that most of the 77 unchecked Human ACs were **misfiled** —
machine-checkable things dressed up as human work. The framework even has a marker for
exactly that case (`[REVIEWER]`, T-1811/T-1878: *"if your Expected clause is grep-able … that
AC should be an Agent AC with the reviewer command in `## Verification` instead"*).

Measured:

| marker | count |
|---|---|
| `[REVIEW]` — genuine human judgement | **71** |
| `[RUBBER-STAMP]` — mechanical, no judgement | **6** |
| `[REVIEWER]` — should have been an Agent AC | **0** |

**Zero.** And reading them, the `[REVIEW]`s are what they say they are: *"Rule H1 — do roadmap
Arcs 4–6 supersede the standing DEFERs"*, *"Rule on the rail substrate"*, *"Rule the 22
findings item by item."* These are governance rulings. A machine cannot make them.

So the queue is not misfiled. That disposes of the comfortable answer.

## 2. What is actually wrong: volume and age

| | |
|---|---|
| unchecked Human ACs | **77** |
| tasks holding them | **62** |
| **median age** | **42 days** |
| aged 31–90 days | **32 tasks** |
| oldest | 73 days (T-189) |

**A median of 42 days is the finding.** Nothing has rotted past 90 days, so this is not
abandonment — but nothing leaves quickly either. The queue is not being drained; it is being
maintained at a level.

**And agents generate these faster than any human issues them.** Every session that surfaces a
governance question adds one. This session alone put three in front of you. Seventy-seven
pending decisions is not a verification queue — it is a decision backlog that cannot be
cleared by working harder at it, because the inflow is the problem.

**That is our failure, not the operator's.** The correct reading of a 42-day median is not
"the human is slow"; it is "the agents are asking too much."

## 3. One pathological shape worth naming

T-732 carries: *"**[REVIEW]** Tick T-596's Human AC to set `definition_ratified: true`."*

**An acceptance criterion whose content is ticking another acceptance criterion.** That is
queue recursion, and it is pure overhead — it adds a step without adding a judgement.

## 4. The specific one I asked you for

T-353's AC is a genuine `[REVIEW]`: *may an agent edit `## Verification` blocks inside
`.tasks/completed/`?* That is a governance ruling about agent permissions. It is legitimately
yours and no machine can make it.

**But you already made it.** You said "c", it is recorded as **PD-308**, and it has already
been exercised and constrained (T-802 applied it; T-803 was refused by it). **The decision is
done and is load-bearing.** The tick would be a second, ceremonial confirmation of a decision
that is already in force.

So the honest position: **the ruling was the valuable act; the tick is bookkeeping.** If the
bookkeeping is not worth your time, the cost of skipping it is small and specific — T-353 stays
`started-work` and keeps appearing in the queue. Nothing else breaks. PD-308 stands either way.

## 5. What would actually help — with costs

**A. Stop adding to it.** Agents should surface a ruling only when something is *blocked* on
it, not whenever a question is interesting. Three went to you today; arguably one was blocked
(SQ-2) and one did not exist at all (IW-3, my misquotation).
*Cost:* judgement calls get made by the agent that would otherwise have been escalated. That is
the trade, and it is the one the operator is implicitly asking for.

**B. Batch by decision, not by task.** 77 ACs across 62 tasks are not 77 decisions — T-732
alone holds five. A view organised by *question* rather than by *task* would be shorter than
the count suggests.
*Cost:* building it, and it does not reduce the inflow.

**C. Let a recorded decision close its task.** PD-308 exists; T-353 remains open anyway. If a
decision record could satisfy the AC that asked for it, the ceremonial tick disappears.
*Cost:* this is framework behaviour — AEF's to change, not ours — and it weakens the guarantee
that a human saw the specific words in the AC.

**Recommendation: A, starting now, and it costs nothing to begin.** B and C are real
improvements but both require building something, and neither addresses why the queue keeps
growing.

## 6. What I am not doing

Not ticking anything. Not converting `[REVIEW]`s to Agent ACs — measured, there are none to
convert, and doing it anyway would be manufacturing the tidy answer I came looking for.
