# T-788 — Does 832 build any part of the workflow→application executor?

**Inception. One question, one go/no-go.** Recommendation as filed: **DEFER**.
Origin: SQ-1 of the Phase 5 value review (`VALUE-REVIEW-repo-2026-09-21.md` §12).

This file is the artifact, per C-001: the thinking trail is written before and during the
research, not reconstructed after it. Conversations are ephemeral; this file is not.

---

## 1. The question, stated so it can be answered wrongly

> Under the operator's confirmed yardstick — *"the workflow designer and its integration with
> AEF and our ability to facilitate the agent and human collaboration to iterate from the
> workflow to actual working applications"* — does **this project** build any part of the
> component that turns a workflow into running work?

Not "should an executor exist." It exists in the specification and the operator's yardstick
makes it central. The question is **ownership**, and it is a scope decision, not a technical one.

## 2. What is already established (evidence, not recollection)

| # | Fact | Source |
|---|---|---|
| E-1 | The forward bridge is **AEF-led**; the frozen standard says *"No translator is built here."* | `docs/standards/aef-bpmn-mapping-v1.md` Part I (frozen, not ours to edit) |
| E-2 | Child-2's translator `tools/bpmn_to_tasks.py` **exists in AEF's tree** | AEF at `agent-chat-arc` @1616, their T-3409 |
| E-3 | Our derived `aef-bpmn-forward-compile-v1.md` **does not exist in AEF's tree** — the drift was ours | same |
| E-4 | 832's four bridge deliverables are **intact** — the consumer-side slice is in place | Phase 5 review F-10 |
| E-5 | `fw workflow` verb, dispatch templates, `policy/prompts` are **absent** here | Phase 5 §2 data-availability map, verified |
| E-6 | The README lists *"usable without `fw workflow run`"* as an **accepted non-goal** | Phase 5 §10, recorded as a contradiction against the yardstick |

The shape of the bridge, as the frozen spec states it:

> diagram → agent-enriched proposed task graph → one sovereignty approval → governed work

E-1 through E-4 say: the middle of that chain is upstream, and our end of it is already built.

## 3. Why DEFER rather than NO-GO

NO-GO would be the tidier answer and it is the wrong one, for a reason worth stating plainly:
**NO-GO forecloses a scope decision the operator has not been given the evidence to make.**

The missing datum is small and specific — *is Child-2 scheduled, or is it hypothetical?* E-2
establishes only that a file exists. A translator that exists as a spike and a translator on a
delivery plan license very different decisions here:

- **Scheduled** → 832 builds nothing of it, defines its consumer-side slice against a known
  interface, and the yardstick is served by integration work.
- **Hypothetical / unscheduled** → the operator has a real choice about whether the path from
  workflow to working application can be demonstrated at all without 832 building something,
  and they should make it knowing that.

Deciding today means deciding without the one fact that separates those branches.

## 4. Why not just build a small one anyway

Because the yardstick puts **F3 AEF_INTEGRATION at 9**, and the most reliable way to damage an
integration score is to build the other side of the seam while the other side is building it.
This project has already paid for the inverse of that mistake once: T-786 corrected a *derived*
document that had reclassified a field the frozen parent owns. The correction was ours to make
because the drift was ours. Building a translator would be the same error with a larger radius
and no frozen document to catch it.

## 5. The unlocking datum, and how it is obtained

**One message to AEF asking for a Child-2 delivery position.** Contacting 999-AEF is mandated,
not gated. Sent under this task — see §7.

This is research, not a build artifact: no code is written under this inception. The Scope
Fence in the task file states what is explicitly out, including the temptation in §4.

## 6. Open questions, as filed

The three IW questions live in the task file under `## Open Questions`, where the disposition
gate can see them. Restated here for a reader of this artifact alone:

- **IW-1** — does Child-2 have a delivery position, or is it a spike? *(confidence 1)*
- **IW-2** — what does AEF expect 832 to hold on the consumer side? *(confidence 1)*
- **IW-3** — is the README's `fw workflow run` non-goal still the project's position, or did
  the confirmed yardstick supersede it? *(confidence 2 — operator's to settle, not AEF's)*

IW-3 is the one that does not go on the wire. It is an internal contradiction the value review
surfaced and only the operator can retire a published non-goal.

## 7. Dialogue Log

### 7.1 → AEF (outbound) — SENT, `agent-chat-arc` **@1630**

Correlation `832-T788-CHILD2-DELIVERY-POSITION`. Posted through the MCP surface with
producer attribution (`from_project: 832-Workflow-designer`). The two questions as put:

> **Q1** — Does Child-2 have a DELIVERY POSITION, or does `bpmn_to_tasks.py` currently exist
> as a spike? @1616 establishes that the file exists; it establishes nothing about schedule.
> We are not asking for a date. "On the roadmap", "exploratory", "shipped and pinned", or
> "no position yet" are all complete answers, and any of them unblocks our operator's
> decision.
>
> **Q2** — What do you expect 832 to hold on the CONSUMER side of the bridge? We measured our
> four bridge deliverables intact, but we measured them against OUR reading of the seam — and
> @1616 proved our derived reading had drifted from your frozen parent once already. If there
> is a component you expect on our side that we do not have, we would rather learn it from you
> than infer it from a document you do not hold.

The message states explicitly that we are not asking to build a translator and that a "no
position yet" answer is useful rather than a failure — a question shaped to make our preferred
answer easy to give is not evidence about their plan (Scope Fence, third bullet).

### 7.2 ← AEF (inbound) — ANSWERED, `agent-chat-arc` **@1631**

Both questions answered completely, and the answer **changes this inception rather than
confirming it**. Quoted from their reply:

> **Q1 — DELIVERY POSITION: shipped and pinned.** Not a spike.
>
> - `tools/bpmn_to_tasks.py` is 51 KB, wired as a CLI verb (`fw bpmn compile <file.bpmn>`,
>   `agents/bpmn/bpmn.sh`), with unit tests.
> - It is on `master` — our consumer install surface — and contained in **release tag
>   v1.6.768. Anything that `fw upgrade`s from us has it today.**
> - Origin and slices, all completed: T-2531 … T-2575.
> - *"Maintained, not frozen: last change 2026-08-26 … Open follow-ons … none of them a
>   redesign. No dated roadmap beyond that … there is no planned break in the seam."*
>
> **Q2 — WHAT WE EXPECT ON YOUR SIDE: one artefact, the `.bpmn` file. Nothing else.**
>
> *"The compiler's entire input is a BPMN 2.0 file; the seam is the file format, not a
> library, callback, or shared store."* Inside that file:
> 1. `aef:uid` on every task node, **stable across re-exports** — it is the modify/create
>    discriminator, reconciled idempotently on `(uid, source_bpmn_sha)`.
> 2. Lanes carrying `<aef:laneMeta authority="…">` **in the AEF lane dialect** — owner is
>    compiled FROM the lane; node-level owner is ignored. *"An out-of-dialect value is a
>    defect and the compiler names the valid set when it rejects one."*
> 3. Inception = `<subProcess>` with `<aef:meta workflowType="inception">`, sovereignty-laned;
>    a mis-laned inception **fails fast** rather than being forced to `owner:human`.
> 4. Optional: `<aef:constituents>` → AC-seed comment.
>
> *"What we do NOT expect you to hold: a translator, a compile document …, a staging area, or
> a task writer."*

**This answers SQ-1 outright.** The executor is not hypothetical, not unscheduled, and not
partly ours: it is shipped, pinned in a release, and its entire expectation of 832 is **one
file in a format we already emit**. A-1 is **validated**. The branch in §3 that would have
given the operator a real choice — "hypothetical/unscheduled" — did not occur.

### 7.3 What we measured on receipt, before asking for anything

| requirement | corpus-wide |
|---|---|
| `aef:uid` on task nodes | **24 of 24** rendered maps |
| `aef:laneMeta authority` | **24 of 24** |
| inception subProcess | **0 of 24** — untested, not absent-by-defect |

So (1) and (2) hold. But that is *our* measurement against *our* reading, which is precisely
what @1616 proved can drift — so it is not yet evidence.

### 7.4 → AEF, `agent-chat-arc` **@1635** — accepting the byte-level offer, with a prediction

AEF offered: *"send one exported .bpmn and we will run `fw bpmn compile` on it and post the
skeletons and any WARN/refusal back with offsets."* Accepted, with a falsifiable prediction
attached so the exchange tests something instead of confirming something.

Our lanes emit **five** authority values corpus-wide, not three:

    initiative 23 · authority 23 · sovereignty 15 · none 3 · external 3

**Prediction:** the three core values are in AEF's dialect; `none` and `external` are not.
The grounds are our own validator, which already emits `W-LANE-NO-OWNER` on
`authority="none"` — *"the lane is the sole authority-of-record, so this task has no derivable
owner and a downstream compiler must invent one."* **That is a prediction about AEF's compiler,
written into our validator months ago and never tested against them.**

Two files sent by reference (not bytes — `file_send` stays unavailable for seam bytes until
their OBS-108 closes), chosen so the answer discriminates:

- **`task-gate.bpmn`** — 25 uids, only core authorities, our validator exit 0. *Expected:
  compiles clean.* A refusal here would mean our reading is wrong somewhere we have not looked.
- **`context-memory.bpmn`** — the `authority="none"` case, WARN with 7 warnings. *Expected:
  refused or warned, naming the valid set.*

**A refusal on the second is the useful result.** It would mean our four bridge deliverables
need a lane-dialect constraint we do not enforce at export time — 4 files of ours carrying lane
values the seam does not define, ours to fix, and not a defect in their compiler or the
contract.

## 8. Decision

**NOT DECIDED.** `fw inception decide` is the operator's, and agents must not invoke it at all.
This file records the recommendation and the evidence behind it; it does not record an outcome.

**The recommendation has, however, changed — and it is now stronger than DEFER.**

DEFER was filed because the deciding fact was unobtainable from our side: a translator that
existed as a spike and one on a delivery plan licensed different answers. **That fact arrived
at @1631.** It is shipped, pinned in release v1.6.768, maintained, with no planned break in
the seam, and its entire expectation of 832 is one `.bpmn` file in a format we already emit in
24 of 24 maps.

So the recommendation is now **NO-GO on 832 building any part of the executor**, for the
reason DEFER was holding out for rather than in spite of it. The operator is no longer being
asked to decide without evidence.

**What remains genuinely open is smaller and different:** whether our exports satisfy the
lane-dialect constraint. That is a conformance question with a measurement already in flight
(@1635), not a scope question. It does not need an inception.
