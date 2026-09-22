# SQ-2 — three rulings, drafted to be chosen

The unchecked `[REVIEW]` AC on T-353 line 191:

> **may an agent edit `## Verification` blocks inside `.tasks/completed/`?**

Each option below is written to be pasted under that AC. **All three are drafted to the same
standard on purpose** — drafting only the recommended one, or writing the others thinly, is
steering a sovereignty decision by making one answer easier to give than the rest.

The agent's recommendation is in §4, deliberately *after* the drafts.

---

## Evidence, re-verified 2026-09-22 (the AC's own steps)

| AC step | citation | measured today |
|---|---|---|
| 1 | `_t353-repair-probe.sh` — "16/16" | **23/23.** The AC's number is stale: the probe cited an ephemeral scratchpad path, reported 12+1, and was repaired in T-787 (gaining 7 legs). |
| 2 | `_t353-convert.py` — 19/19, DIVERGENT 0 | **reproduces exactly: 19/19, DIVERGENT remaining 0** |
| 3 | `docs/reports/T-353-corpus-readiness.md` §3, §4 | present |

**Two populations, not one.** The AC's binary conflates them:

| | count | consequence if never fixed |
|---|---|---|
| T-353's patch set | **23** lines, all archived | none — archived blocks do not re-run |
| `_t560` uncontrolled legs in `completed/` | **110** of 127 | `_t560` stays RED permanently |

`127 − 17 = 110 > 78`. Fixing every leg an agent may currently touch still leaves the ratchet
above its baseline, so **no agent-permitted action closes `_t560`.**

**Disclosure:** 14 of the 127 were added by the agent during this session (T-789…T-798), all
now in `completed/`. Its claim to have "controlled" them was overstated — the control legs used
a *related* pattern, not the same string the instrument requires.

---

## Option A — YES, as the AC frames it

> **Ruling: YES.** An agent may edit `## Verification` blocks inside `.tasks/completed/`. The
> proven patch set is applied to the 23 archived lines. The P-011 errexit gate change becomes
> unblocked as a separate decision (G-008 upstream). Agents editing archived verification
> blocks is hereby a normal operation, not an exception.

**What follows:** the 23 lines are repaired. `_t560`'s 110 also become repairable. The ratchet
can return to 78.

**The cost, stated fairly:** this is the broadest of the three and the hardest to withdraw. It
licenses editing other owners' archived records generally, not only where an instrument demands
it — and the task's own analysis argues against doing so on tidiness grounds, because all 23 of
its lines are inert.

## Option B — NO, as the AC frames it

> **Ruling: NO.** Archived `## Verification` blocks are immutable under agent control. The
> task closes as a proven proposal; its patch set is not applied. The P-011 gate change stays
> parked. `_t560` is accepted as permanently red, and its baseline is NOT raised to conceal
> that.

**What follows:** nothing is touched. The task's own argument is honoured exactly — repairing
inert lines buys tidiness at the cost of editing other owners' records.

**The cost, stated fairly:** `_t560` stays red forever, and a permanently-red instrument decays
into noise people learn to ignore. If this is the answer, the honest follow-up is deciding
whether `_t560` should be *retired* rather than left red — a check nobody can ever turn green
is worse than no check.

## Option C — the narrow third ruling

The AC's own "If not" invites this: *"if the question is not the right one to be asking, say
so."*

> **Ruling: NARROW YES.** An agent may **append** a sibling control leg to a `## Verification`
> block inside `.tasks/completed/` **only** where a teeth instrument requires it to discharge
> an uncontrolled assertion, and only as an **addition** — no existing assertion may be altered
> or removed. Each such edit is logged as Tier 2. The 23-line patch set is NOT authorised by
> this and remains deferred per its own recommendation; the P-011 gate change stays parked.

**What follows:** `_t560`'s 110 become dischargeable, the ratchet can return to 78, and the
inert patch set stays unapplied — each population gets the answer its own evidence supports.

**The cost, stated fairly:** it is a narrower rule and therefore a more complicated one. "Only
where a teeth instrument requires it" needs judgement at each site, and a future agent may
stretch it. It also leaves the P-011 gate change parked indefinitely, which is a loose end
rather than a resolution.

---

## §4 — The agent's recommendation

**Option C**, because the two populations have different evidence and C is the only option that
answers each on its own merits. A is more permission than any measured need requires; B accepts
a permanently red instrument without deciding what to do about it.

**Against C, honestly:** it is the option the agent proposed, about a problem the agent
contributed 14 instances to, and "narrow" rules are the ones that widen quietly.

## How to record it

1. Paste the chosen ruling text under the AC at line 191 of
   `.tasks/active/T-353-prepare-the-corpus-for-the-p-011-errexit.md`
2. Tick the box — **`### Human` ACs are the operator's alone; the agent will not tick it**
3. Then: `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-353 --status work-completed`
