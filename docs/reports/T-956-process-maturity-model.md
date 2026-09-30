# T-956 — Process maturity: strictness is earned, deviation is evidence, the hatch never closes

**Task:** T-956 · **Date:** 2026-09-30 · **Source:** operator dialogue, this session
**Status:** design record. No code. Names one thing already written down that this contradicts.

---

## Why this file exists

The operator stated a model for how process strictness should evolve. It arrived as dialogue
while settling a narrower question (should validator findings block a save — T-309 IW-3),
and it is broader than that question: it governs the whole class/instance layer (arc-005)
and the execution runtime (arc-002), not just the authoring surface.

Per C-001 the thinking trail is the artifact — conversations are ephemeral. This records the
model, the carriers that already exist for it, and the one place the codebase currently says
the opposite.

## The model, in the operator's terms

> *"When you're still drafting a process, a workflow — and here we've got the class and we've
> got the instance — the instance can be run and the boundaries are less strict. Of course we
> manage risk, but it can be less strict because you don't know exactly what the boundaries
> need to be and how the process should look. We're still discovering that. So that's why you
> don't want to make it too strict, otherwise you're not getting through and you want to move
> forward. So you need to have the ability to navigate around blockades or things that are not
> so effective. And then learn from that and also adjust. And then at some point when you
> repeat it several times and you say this is a settled process, then you lock it and say this
> is the execution that needs to take place. And that's why you cannot just… by default. There
> should always be an exception hatch."*

Decomposed into claims that can each be built or refused:

| # | claim |
|---|---|
| **M1** | Strictness is a property of a workflow's **maturity**, not a global setting. |
| **M2** | An **instance may run against an immature class.** You do not have to finish modelling before you can execute. |
| **M3** | Early strictness is **harmful**, not merely premature: it stops you getting through, and the boundaries are not yet knowable. |
| **M4** | **Navigating around a blockade is a first-class act**, not a violation — including around steps that turn out not to be effective. |
| **M5** | Those deviations are **learning inputs that adjust the class.** |
| **M6** | Lock is **earned by repetition** — "when you repeat it several times and say this is a settled process". |
| **M7** | **The hatch never closes.** Even a locked process keeps an exception path. Friction yes; refusal-with-no-appeal no. |
| **M8** | More than two rungs. `documentation | work-plan` is too coarse for this. |

And separately, on the authoring question that started it:

> *"I always want to override, or have to override option. Yes, it can give me friction. Can
> it really ask me… or ask me not to do it lightly. But I want to be the final authority."*

**Ruled: advisory plus friction, never a hard block.** Recorded so the T-309 UI slice
inherits it rather than re-asking.

---

## This is the project's own conclusion, reached twice independently

**T-325** got to M1 from the opposite direction, with a measurement:

> *"`W-XML-GW-AMBIGUOUS` fires on **47 of AEF's 48 live gateways and on 0 of ours.** It is not
> measuring gateway correctness; it is measuring which toolchain wrote the file. A rule like
> that cannot be surfaced to an author as-is: it would show 47 warnings on a map that is
> correct by the conventions it was written under, and by AEF's L-527 a rule that gets tuned
> out is weaker than no rule, because its silence stops meaning anything. So before findings
> can reach the designer, **each rule needs to say which kind of claim it is making.**"*

**And the Antifragility directive is M5 verbatim**: *"System strengthens under stress;
failures are learning events."* M4/M5 are that directive applied to the process layer, where
it currently is not.

---

## Carriers that already exist — four dials, none wired to maturity

| carrier | what it is | state |
|---|---|---|
| `workflowMeta.kind` = `documentation` \| `work-plan` | a declared maturity level, in the seam schema | **validated only.** `validate-workflow.py:338-346` checks the value is legal. No rule's applicability depends on it. |
| `workflowMeta.tier_default` | a per-workflow enforcement tier | carried through round-trip by six tools. **Enforcing nothing.** |
| `tests/test_rule_dialect_axis.py` | T-325's per-rule claim classification (universal vs dialect-relative) | **exists**, unconsumed by the validator |
| `tools/instance-node.py` → `cmd_refusals`, `cmd_refused` | the record of every refused advance | **exists and is populated** |
| `examples/aef-processes/template-binding.yaml` | the class↔instance join, derived from `workflow_type` | shipped (T-880) |

**A map can already declare what it is, what tier it is held to, and which rules make which
claims — and nothing reads any of it to decide how strict to be.** The four dials are turned
and connected to nothing. That is the gap, and it is smaller than building the model from
scratch.

---

## The contradiction, named

**arc-005's headline mechanic currently says the opposite of M4.**

> *"An operator opens task-lifecycle in the designer, sees it marked as a template rather than
> an actionable work-plan, creates an instance of it bound to a real task number, and watches
> that instance advance node by node as the task moves — **with an out-of-order advance refused
> and written to the audit log**."*

Refused **and** logged. Under M2/M4 that is right only for a *mature* class. For one still
being discovered it is exactly the early strictness M3 warns about: the instance cannot
proceed, so the operator either stops or works outside the system — and the second outcome
destroys the very evidence M5 wants.

**The reframe:** an out-of-order advance against an immature class should be **permitted,
recorded, and surfaced as a candidate class amendment.** Against a locked class it becomes a
refusal *pending authorisation* — which the operator can grant, because that is what M7
means. Same record; the maturity of the class decides whether it reads as a deviation to
learn from or an exception to authorise.

**This is not a small edit.** arc-005's headline is a demo-evidence claim; changing what it
promises is an arc-level decision and belongs to the operator.

---

## The part that is unusually tractable: lock is measurable

M6 says lock is earned by repetition, and **the repetition is already countable**:

- `instance-node.py cmd_instances` — instances of a template
- `GET /api/instances?template=<id>` — the same, over HTTP (T-884)
- `cmd_refusals` — deviations recorded per instance

So a maturity ladder need not be a manual flag an agent nags about. It can be **evidence-driven**:
a class is a *candidate* for the next rung when it has accumulated N completed instances
whose refusal count is falling, and the promotion is still the operator's to make. That is
the same shape as `fw promote` for learnings, and the same shape as the T-952 ratchet:
a floor that tightens on evidence and never on its own.

It also gives arc-004's hypothesis discipline something real to measure: *"we believe that
locking this process will achieve X; we will know when we see Y"* — with Y already
instrumented.

---

## Open questions for the operator

1. **How many rungs, and what are they?** M8 says more than two. A plausible ladder is
   `draft → piloted → settled → locked`, but the names should be the operator's, and each
   rung needs a *rule applicability* meaning or it is decoration.
2. **Does `kind` become the maturity field, or does maturity sit beside it?** `kind`
   distinguishes *what a map is for* (documentation vs work-plan); maturity is *how far
   discovery has got*. Those may be two axes, not one. Conflating them would be the cheap
   answer and probably the wrong one — a locked documentation map is a coherent thing.
   **Note:** `kind` is a ratified seam field AEF also consumes, so widening it is a two-party
   change; a new field beside it may be cheaper precisely because it is ours alone.
3. **Does arc-005's "refused and written to the audit log" change?** Under this model, yes,
   for immature classes. That is an arc-level promise and the operator's call.
4. **What friction does the hatch carry?** Tier 2 already defines the pattern — *"human
   situational authorization, single-use, mandatory logging"* — and PD-298 is precedent that
   *a check may carry a recorded exemption*. The hatch probably is Tier 2, not a new
   mechanism. Worth confirming rather than assuming.

## What this record deliberately does not do

No code, no schema change, no arc edit. The model is the operator's and three of the four
questions above are theirs to settle. Filing the model without the answers is the point:
it stops the reasoning evaporating into a transcript, and it names the contradiction with
arc-005 so the next person to read that headline finds this beside it.
