# T-825 — EWCR arc: scoping and progress review

**Asked by the operator**, 2026-09-22: review the arc's scoping and task composition against
what we now know — are the tasks complete, do any need revising or extending, is anything
missing entirely?

Measured, not recalled. Every number below is from the tree or the rail today.

---

## 1. The finding, before anything else

**Before this review, the arc had TEN open tasks and every one of them was `owner: human`.
Zero were agent-owned.**

Joined by the authoritative field — `arc_id: ewcr-governed-delivery` in frontmatter, not a
text match:

| task | status | owner | unticked Human ACs |
|---|---|---|---|
| T-590 | work-completed | human | 3 |
| T-593 | work-completed | human | 2 |
| T-596 | work-completed | human | 1 |
| T-597 | work-completed | human | 2 |
| T-608 | work-completed | human | 1 |
| T-671 | work-completed | human | 1 |
| T-681 | started-work | human | 0 — **decision recorded, closable** |
| T-732 | started-work | human | **5** |
| T-733 | work-completed | human | 1 |
| T-736 | work-completed | human | 1 |

Eight are already `work-completed`, sitting in `active/` solely because their Human ACs are
unticked — the partial-complete state, working exactly as designed. **Seventeen unticked
Human ACs across ten tasks, and not one line of code among them.**

So the honest answer to *"do we have an arc to progress?"*: yes — and **the agent had nothing
in it to work on.** The arc is not blocked on engineering. It is a queue of operator
decisions. This is the T-804 pattern (77 unticked Human ACs, median age 42 days) concentrated
in one place.

**Measured twice, because the first measurement was wrong.** A text search for the arc slug
returned thirteen tasks and I nearly reported that. Three of them do not belong to this arc:
T-757 is filed under **arc-003** and merely mentions arc-002 (it is the RA task *about* this
arc's completion count), T-740 carries no `arc_id` at all, and this review's own task matched
because its verification legs quote the slug. A review that counts prose about an arc as work
in it would have overstated both the size of the arc and how much of it was agent-workable —
the same class of error `_t451` documents about its own detector, and the same one the T-821
census made on its first run.

## 2. Arc-0 exit: waiting on a decision, not on work

Three clauses gate exit. All three read `attestation: null`, `definition_ratified: false`,
`blocks_arc_0_exit: true`.

A bounded exchange with AEF ran to settle clauses 1 and 2. It stopped at **round 2 of a
ceiling of 10** — deliberately, not from exhaustion. Its own verdict, verbatim from the
register:

> *"what_it_did_not_produce: Any movement in this register. Three clauses, zero satisfied,
> unchanged from the exchange's first message to its last."*

And the reason further rounds were refused:

> *"What remains is NOT measurable by either agent: the §5.1-row → path-prefix mapping is
> hand-derived, which they volunteered unprompted at @1593. An operator can disagree with it
> per row; no further round can settle it, and asking again would produce traffic rather than
> facts."*

Clause 2 came back **UNDECIDED**, which the register correctly reads as telling the operator
that *"Arc-0 exit waits on a decision rather than on work in progress."*

**Nothing an agent does next moves clause 1 or 2.** That is established, not assumed.

### One title overstates its own record

T-736 is named *"AEF attested Arc-0 clause 1 green with its numbers at @1539 — record…"*.
The register is more careful than the title: that entry is logged as transport evidence and
explicitly *"attestation: stays null, definition_ratified: stays false."* AEF said so in their
own close — *"Transport evidence, not ratification."* The task title, read alone, says the
clause is green. It is not. **Recommend retitling** rather than leaving a title that
contradicts the record it points at.

## 3. Clause 3 is the one the operator can actually clear — and two of five need no judgement

T-732 has done its agent half in full: `docs/reports/T-732-h-register-dossier.md` exists with
a section per question, each quoting the recommendation verbatim (PL-323), each stating
whether it is ratifiable as written or superseded, and an `/approvals` URL printed.

What remains is five rulings, and **they are not equally hard**:

| ruling | marker | note |
|---|---|---|
| H1 — do roadmap Arcs 4–6 supersede the standing DEFERs | `[REVIEW]` | genuine judgement |
| **H3 — ratify the correlation identifiers** | **`[RUBBER-STAMP]`** | filed recommendation is **superseded** — read the note first |
| **H5 — reconcile four disclosed governance deviations** | **`[RUBBER-STAMP]`** | agent evidence already attached |
| H6 — was the R6/R7 routing correct | `[REVIEW]` | transport done at offset 643 |
| Tick T-596's Human AC → `definition_ratified: true` on clause 3 | `[REVIEW]` | **without it clause 3 cannot be satisfied at all** |

**Two of the five are rubber-stamps.** The last one is structural: until T-596's AC is ticked,
clause 3 is not merely unsatisfied — it is *unsatisfiable*, because the agent recording its own
definition as ratified is the move the register forbids everywhere else.

## 4. Scoping: T-681 was right, and it was acted on

T-681 (inception) decided **GO on 2026-09-05**, scoped to **Arc 2's Designer-owned half only**:
prove the browser/editor cannot reach execution, secret, or ledger authority. It recommended
**against** opening Arcs 1/3/5/6, because their Designer column depends on an AEF artefact that
does not exist yet, and *"decomposing work whose inputs are counterparty-blocked manufactures a
backlog that measures as progress and cannot move."*

**That judgement holds, and it was executed.** T-682 (boundary enumeration), T-683, T-684
(mutation control) and T-689 (isolation proof) are all completed. I expected to find a GO with
no build tasks behind it and checked before writing it down; the opposite was true.

T-681 now has every AC ticked and its decision recorded, and is `owner: human`. **It is the
operator's to close.** T-722 exists solely because it is not closed, and resolves when it is.

## 5. What is MISSING — the one piece of new arc work that is genuinely ours

AEF answered T-798 at **agent-chat-arc @1644**, and the answer redraws the picture:

- **Q1 — is the instance/execution-tracking layer yours?** → *"YES… Design nothing."* Same
  seam argument as Child-2: an instance that tracks task execution is task state, inside their
  task-gate perimeter. Logged their side as **OBS-454** for their operator to rule on.
- **Q2 — is the lifecycle/pipeline split right?** → Yes, **plus a third framing**: for the
  lifecycle shape the instance record *already exists* — a task's status transitions, its
  Updates, its episodic YAML — so instantiation there is a **JOIN**, not a new record. For the
  pipeline shape the instance is the compiled task set and a run id must be stamped at compile
  time. And then, verbatim:

  > *"Your designer distinguishing the two shapes (a diagram-kind marker — we already have an
  > open corpus gap on exactly that, T-2556) is what would let a resolver pick the right join."*

**That marker is ours, it is small, and it was already decided.** T-213 dispositioned
`aef:workflowMeta` diagram-kind (`documentation|work-plan`) **GO on 2026-07-21**.

    grep -c "diagramKind" src/aef-workflow-designer.html  ->  0

**Decided two months ago. Never built. No task open for it.** Two projects independently
arrived at the same missing field and neither noticed the other had already agreed to it.

There is also **no task** for AEF's Part A request at @1644 — the bytes of `task-gate.bpmn`
and `context-memory.bpmn` on `xfer-832-bpmn`, which they gave an exact command for and are
waiting on to run the compile.

## 6. Verdict on composition

| question | answer |
|---|---|
| Is the arc correctly scoped? | **Yes.** T-681's GO — Arc 2's Designer half only, Arcs 1/3/5/6 deliberately unopened — is still the right call and is the reason this arc has no phantom backlog. |
| Are its tasks complete? | **The agent half is.** 25 of 27 done; one agent-owned open task, and it is housekeeping. |
| Do any need revising? | **T-736's title** contradicts its own record. **T-757/T-722** are artefacts of tasks that cannot close for operator reasons — they should not be worked, they resolve on their own. |
| Is anything missing? | **Two tasks, both created by this review:** the diagram-kind marker, and the BPMN byte transfer. |
| What would actually move it? | **Five operator rulings, two of them rubber-stamps.** Nothing else. |

## 7. Recommendation

1. **Build the diagram-kind marker.** The only new arc work that is unambiguously ours,
   already dispositioned GO, and named by the counterparty as the missing piece.
2. **Post the BPMN bytes** so AEF's compile can run — needs an operator decision on the
   classifier path, not engineering.
3. **Clear H3 and H5** (rubber-stamps) and **tick T-596's AC** (structural). That leaves only
   H1 and H6 as genuine judgement, and takes clause 3 from unsatisfiable to satisfiable.
4. **Close T-681.** Its decision is recorded and its work is done.
5. **Do not open Arcs 1/3/5/6.** T-681's reasoning is unchanged and the counterparty
   dependencies are still absent.

**Not recommended:** another bounded exchange on clauses 1 and 2. The last one produced a
scoped tool, a corrected hypothesis and a real drift finding — and zero register movement, by
its own account. A third round would be traffic.
