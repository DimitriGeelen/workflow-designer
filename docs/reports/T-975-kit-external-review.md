# T-975 — External review of the vendor authoring kit

**Task:** T-975 · **Date:** 2026-10-01 · **Kit under review:** `docs/authoring-kit/AUTHORING.md`
plus the generated `CONFORMANCE.md`, `exemplar.bpmn` and the validator (T-974).

The operator delegated the guide's review: *"Don't ask me to review the guide, you think about it
and if you need more then get external guidance."* So: my own critique first, written before any
reviewer replied so the reviews can be compared against it rather than absorbed into it, then
three external agents doing the job the guide is for.

---

## 1. My own critique (written before any external reply)

Read cold, as the Evergreen agent: a generator, a source, this kit, nothing else.

**C1. A false statement about `/api/save`.** The guide says the save response carries the
verdict. That holds only on our reference server (T-973). AEF's blueprint, the one Evergreen
actually saves through, does not have it yet. A vendor reading the guide would see no
`validation` key and could conclude the map was fine. The guide must say: no `validation` key
means this server does not validate, so run the validator yourself.

**C2. The aef namespace URI is never stated.** A generator cannot emit `aef:laneMeta` without
`xmlns:aef="http://anchorpoint.framework/aef/extensions"`. It is only discoverable by opening the
exemplar.

**C3. No guidance on what a lane IS.** Evergreen laned by *system* and invented a
"(systeem niet bekend)" lane. The authority vocabulary (sovereignty / authority / initiative /
external / none) is AEF's human/agent/framework governance axis, and the guide never maps it
onto a business process: a human department is `sovereignty` (a human performs it), an
automated system step is `authority`, a party outside the organisation is `external`. Without
that mapping a generator either guesses or omits, and omission is what happened.

**C4. `aef:uid` stability is asserted, not explained.** "Stable" requires deriving the uid from
the source's own identity (a step's ontology IRI, a requirement id), never from a counter or a
random value. Otherwise every regeneration is a new map. That was Evergreen's #2/#3: they had to
match round trips by lane+step name.

**C5. No snippet for the "order unknown" pattern.** The guide says "add a textAnnotation" but
not how: `textAnnotation` plus `association` to the steps.

**C6. Layout is not mentioned.** The operator's original complaint about Evergreen was that the
layout was messy. The guide says presentational data never changes meaning, which is true, but
says nothing about what a generator should emit for geometry (nothing, and let the designer lay
it out? lane-banded `aef:position`?). I do not yet know the right answer; this is a question for
the reviewers and for the trial.

**C7. `kind="work-plan"` is listed in CONFORMANCE.md and never explained.**

**C8. When to split.** One map per process; an overview that names sub-processes should link
them rather than inline them. Not covered.

## 2. The external panel

Brief, identical for each reviewer: act as a vendor's generating agent; given a synthetic source
text (an order-fulfilment process deliberately containing a human decision, an automated system
step, an external party, an undocumented step order and an out-of-scope sub-process) and ONLY
the kit, produce `map.bpmn`, validate it with the kit's validator, then report what you had to
guess, what the guide got wrong, and anything you were tempted to invent.

| reviewer | vendor | status |
|---|---|---|
| Codex | OpenAI | _pending_ |
| opencode · glm-5.2 | Z.ai (coding plan) | _pending_ |
| Vibe | Mistral | rate-limited at first probe; retried |
| cursor-agent | Cursor | not signed in, needs an interactive login; not used |

## 3. Replies and dispositions

_(filled as replies arrive)_
