# T-466 — The arc is blocked on one ruling, not five

**For:** Dimitri (operator) · **Prepared:** 2026-08-12 · **Arc:** arc-001 `designer-authoring-surface`

I have told you three windows running that arc-001 is gated on five operator rulings —
**T-340, T-341, T-347, T-358, T-209**. I re-derived it instead of restating it. It is one:
**T-340**. The other four are genuinely open and genuinely need you, but nothing in the arc
waits on them.

This document is the correction, the evidence, and how the wrong number survived three
windows without anyone noticing — including me, twice, while writing the sentence.

---

## 1. What actually blocks the arc

Two active tasks carry `arc_id: designer-authoring-surface`. Derived, not recalled:

```
cd /opt/832-Workflow-designer && grep -l '^arc_id: designer-authoring-surface' .tasks/active/*.md
```

→ `T-423` (step 2, `captured/now`) and `T-424` (step 3, `captured/later`). **Denominator: 2.**

Of those two, exactly one names a blocking precondition, and it names exactly one task —
T-423's first Agent AC:

> **Ordering respected: this task does not start until T-340 is ruled and step 1 has landed.**

T-424 names no blocker at all; it is step 3 of the same decomposition and sits behind step 2
by construction, `horizon: later`.

Which rulings do the two arc tasks reference at all?

```
cd /opt/832-Workflow-designer && grep -oE 'T-(341|347|358|209|340|357)([^0-9]|$)' .tasks/active/T-423-*.md .tasks/active/T-424-*.md | grep -oE 'T-[0-9]+' | sort | uniq -c
```

| task | T-340 | T-357 | T-341 | T-347 | T-358 | T-209 |
|---|---|---|---|---|---|---|
| T-423 | 6 | 6 | — | — | — | — |
| T-424 | — | 4 | — | — | — | — |

**T-341, T-347, T-358 and T-209 do not appear in either arc task.** Not as blockers, not as
related tasks, not in prose.

### The near-miss that is worth more than the table

The first version of that command was unanchored — `grep -oE 'T-(341|347|358|209|340|357)'` —
and it reported **T-209 present in both arc tasks**. It was matching `T-209` inside **`T-2090`**,
a verification-block comment reference (the SIGPIPE hint) that has nothing to do with rulings.

Had I stopped there, I would have "confirmed" one fifth of the original claim with a false
positive and reported a partial correction that was itself wrong. The anchored form
(`([^0-9]|$)`) is what produced the table above. I am recording the near-miss rather than the
clean result alone, because the reason to trust the table is that the first attempt failed in a
way I caught — not that the second attempt looked tidy. This is G-037 axis-1's neighbour: an
unanchored pattern producing a confident wrong number.

---

## 2. How "five" survived three windows

The five rulings **do** appear together, repeatedly — in handover frontmatter:

```
tasks_touched: [..., T-209, T-341, T-340, T-358, T-347, ...]
```

That is a **co-occurrence** list: tasks I opened in one sitting. All five are open `[REVIEW]`
rulings, so a window spent triaging open rulings touches all five, and they land adjacent in the
record. Somewhere between that list and the next window's summary, *"the five rulings I looked at"*
became *"the five rulings that block the arc"* — and nothing in the handover format distinguishes
those two relations, because `tasks_touched` has no semantics beyond "seen".

Each subsequent window then inherited the **summary**, not the tasks. A summary is a claim with
its derivation stripped off; re-deriving costs two greps, and restating costs nothing, so the
restatement won three times running.

**The class:** a set assembled by *adjacency in a work log* was restated as a set defined by
*causation in the task graph*, and the record could not tell them apart. Same family as PL-145
(a ruling filed as prose is invisible to instruments) one level up — here the *dependency* was
filed as prose, so no instrument could contradict the drift.

**Why no gate caught it:** nothing derives arc blockage. `fw arc show` prints constituent tasks
with status and horizon; it does not read AC prose, so it cannot know T-423 is held. The claim
lived only in handover text, where the only reader is the next window's summary of it.

---

## 3. The arc view could not see the blocker either (fixed)

Before this task, `fw arc show designer-authoring-surface` listed:

```
T-423 [captured/now]   T-357 step 2: emit BPMN DI additively alongside aef:position
T-424 [captured/later] T-357 step 3: retire aef:position
```

`T-423 [captured/now]` is indistinguishable from *ready to pick up*. The task it waits on —
T-340, **step 1 of the very same three-step T-357 decomposition** — was not tagged into the arc,
while steps 2 and 3 both were. The one task the arc was waiting on was the one task the arc view
omitted.

### The obvious fix wrote the wrong field

The documented command for this is `fw arc tag`, and it reports success:

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw arc tag designer-authoring-surface T-340
→ Tagged task T-340 with arc:designer-authoring-surface
```

It set `tags: [arc:designer-authoring-surface]` and left `arc_id:` commented out — the
**legacy** form. `fw arc`'s own help says the opposite: *"Source-of-truth is task-side `arc_id:`
(T-1849)"*, with the tag/`constituent_tasks` path marked as the T-1851 deprecation. Both sibling
arc tasks (T-423, T-424) carry `arc_id:` and empty `tags:`, so following the documented command
would have left the arc with its three members recorded two different ways, one of them the way
the framework says not to use.

`fw arc show` renders either, so **nothing would have gone red.** I only caught it because a
verification leg asserted the source-of-truth field by name rather than asserting that the arc
view looked right. An instrument that checks the rendered output would have passed this.

Fixed by writing the source-of-truth field directly (`arc_id: designer-authoring-surface`,
`tags: []`), matching the siblings. The `fw arc tag` defect is registered as **T-467** — one bug,
one task — and is in vendored framework code, so it is an upstream candidate under G-008.

`fw arc show` now renders the ordering:

```
T-340 [started-work/now]  Standard BPMN DI is silently discarded on import ...
T-423 [captured/now]      T-357 step 2 ...
T-424 [captured/later]    T-357 step 3 ...
```

This makes the blocker **visible**; it does not make it **derived**. A reader still has to know
that T-340 precedes T-423 — the arc view has no blocked-by relation to render. Naming that limit
rather than claiming the problem is closed: the tagging is mitigation, not prevention (G-019).

---

## 4. So what is actually being asked of you

**One ruling. T-340.** It is fully briefed in
[`docs/reports/T-397-import-repair-semantics-brief.md`](T-397-import-repair-semantics-brief.md)
§Q1b — options, evidence, the competing-carrier rule, provenance for every number. Nothing in
this document supersedes it, and this task deliberately did not touch it.

Three things about T-340 that make it a smaller ask than it has been made to look:

1. **The recommendation is already drafted:** option **(b) scoped** — read `aef:position`, then
   DI, then auto-layout; emit regenerated DI only when the input carried it.
2. **It changes zero bytes** for all 24 existing corpus maps (`BOTH = 0`, re-measured over 142
   files), so it needs **no AEF coordination and no fixture re-pin**. The re-pin cost belongs to
   T-423, downstream, not to this decision.
3. **AEF reached the same ruling independently** (rail 487, their T-2882) before reading ours —
   two derivations of PL-114 from different codebases.

**One caveat I am keeping in front of you rather than resolving.** Your T-357 GO rationale names
this increment by name — *"Read DI when `aef:position` is absent. = T-340 scoped (b)"*. That may
already be your ruling. I am not treating it as one: an inception decision approves a direction,
it does not tick another task's Human AC, and reading an implication as an authorisation is the
exact move the sovereignty gate exists to prevent. So the AC stays open until you record it.

**Where it must be recorded** (PL-145 — from T-209, one of the four now shown not to block the
arc): in the decision record, not in prose. A ruling written into a comment or a chat message is
invisible to every instrument that looks for rulings.

Canonical route:

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task review T-340
```

CLI fallback — a **draft** rationale, yours to edit; add `--i-am-human` if pasting inside an agent session:

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context add-decision "T-340 DI repair semantics: b-scoped" --task T-340 --rationale "aef:position then DI then auto-layout; emit DI only when input carried it; BOTH=0 so zero bytes change and no AEF re-pin"
```

---

## 5. Where the other four stand

Open, needing you, **not blocking the arc**. Ruling them changes import fidelity; it does not
release T-423.

| ruling | question | brief |
|---|---|---|
| T-347 | Q1a — content inside an accepted element | T-397 §Q1a |
| T-341 | Q2a — which lane acquires an orphaned flow node | T-397 §Q2a (**no recommendation offered, deliberately — it is a sovereignty call**) |
| T-358 | Q2b — fabricated lanes and participants | T-397 §Q2b (**must agree with T-341**) |
| T-209 | decline AEF's offset-78 producer-contract proposal? | **none — see below** |

**T-209 has no brief, and this task does not write one.** It was in scope while the "five
blockers" framing held; once T-209 is shown not to block the arc, folding a brief for it into
this task would be the umbrella-task antipattern (one task = one deliverable). It remains the
only one of the five with no consolidated evidence, and it is the AEF-seam ruling — a reasonable
next task, not a silent omission.

---

## 6. What I got wrong, stated plainly

- I reported five arc blockers in three consecutive windows. There is one.
- The error came from restating a summary instead of re-deriving from the task files. The
  derivation costs two greps.
- My first attempt at the correction was itself wrong (unanchored match, `T-209` inside `T-2090`)
  and would have produced a confidently wrong partial retraction.
- Consequence for you: the arc has looked like a five-decision wall for three windows when it was
  a one-decision gate — and that one decision may already be implied by a GO you have recorded.
