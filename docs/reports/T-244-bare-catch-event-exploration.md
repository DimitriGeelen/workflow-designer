# T-244 — Bare catch-event rendering: exploration

**Task:** T-244 (inception) · **Explored:** 2026-07-29 · **Status:** exploration complete, awaiting operator decision

## The one question

Should a bare `intermediateCatchEvent` — one carrying no `aef:link` and no `aef:eventDef` — render
as the link-catch ("← Handoff") UI with an empty, never-bindable target, or as a neutral untyped
glyph?

## What was verified in code (not assumed)

The filing note asserted this was a presentation-only defect. That is now **confirmed**, and the
confirmation materially changes the cost estimate.

**1. Root cause is a single fallback line.** `REVERSE_TYPE['intermediateCatchEvent'] =
'linkEventCatch'` (src/aef-workflow-designer.html:9347). Any `intermediateCatchEvent` that does not
match a recognised `aef:eventDef` kind decodes to `linkEventCatch`. There is no neutral landing type.

**2. The consequences are all presentational.** Such a node receives the "← Handoff" label
(src:7783), the link-catch glyph — circle with inward chevron (src:5662) — and the link property
schema `['workflowRef', 'name', 'targetWorkflow', 'linkId']` (src:1784). None can ever bind, because
the source document carries no `aef:link`. That is exactly the reading failure AEF's operator hit: a
healthy map looked like a broken connector.

**3. Round-trip is byte-clean today — the load-bearing finding.** `aefExtensionXml` emits
`<aef:link>` only under the guard `if (aef.workflowRef || aef.targetWorkflow || aef.linkId ||
aef.name)`, pushing only non-empty attributes; `linkEventCatch` exports as `intermediateCatchEvent`
(src:8985). A bare catch event therefore survives import → export **unchanged**. Nothing is
corrupted, nothing is silently injected.

The defect is *entirely* in what the reader sees. That rules out the expensive fix and makes the
cheap one viable.

## The two fix paths, correctly priced

**(a) New neutral node type.** Palette entry, `TYPE_TAG` mapping, `REVERSE_TYPE` entry, geometry
record, glyph, property schema, export path, validator rules — and, because it would export as
something new, **a dialect change AEF must ratify**. This is the shape the filing note implicitly
priced. It is not justified by a presentation bug.

**(b) Render neutrally when unbound.** Keep the type; branch glyph, label and property panel on
"does this node actually carry a binding?" Zero schema change, zero export change, zero dialect
change, nothing for AEF to ratify — the standing rail commitment becomes a courtesy FYI rather than
a ratification request.

Path (b) is roughly an order of magnitude cheaper and carries no cross-project surface.

## The wrinkle this exploration surfaced

Path (b) is not free of design tension, and the tension was invisible from the filing note.

**A palette-created handoff node is also unbound.** Dragging `linkEventCatch` from the palette
yields a node with no `workflowRef`/`targetWorkflow`/`linkId` — by state, indistinguishable from a
bare imported catch event. So a naive "unbound ⇒ render neutral" strips the handoff affordance from
a node the author just placed and intends to bind.

**And the distinction cannot survive a save.** Because export emits no empty `<aef:link>`, the
dialect has **no carrier for authorial intent**: "author placed a handoff, not yet bound" and "bare
imported catch event" serialize to an identical `<intermediateCatchEvent>`. No rendering cleverness
recovers a distinction the file does not record.

**Resolution that follows:** keep the intent in *session* state, not document state. While the node
is live in the editor (placed from the palette this session), show the handoff UI so binding stays
discoverable. After a reload, render neutral — which is honest, because at that point the document
genuinely says nothing about handoff intent. The alternative, a persisted "intended handoff" marker,
is a dialect change: path (a) in disguise.

## Open questions — dispositions

- **IW-1** (render neutral vs link-catch UI) — **answered**, confidence 3. Neutral, but conditioned
  on session state per IW-3. Evidence: src:9347 fallback, src:7783/5662/1784 consequences.
- **IW-2** (new node type vs rendering branch) — **answered**, confidence 3. Rendering branch
  suffices; no schema surface. Evidence: `aefExtensionXml` conditional link guard + src:8985 export
  mapping prove round-trip safety without a new type.
- **IW-3** (can authorial intent be distinguished, does it survive a save) — **answered**,
  confidence 3. Distinguishable in session, **not** across a save; the dialect has no carrier.
  Evidence: conditional `<aef:link>` emission means unbound handoff and bare catch event serialize
  identically.

## Assumptions tested

| Assumption | Status |
|---|---|
| Defect is presentation-only, no data corruption | **Validated** — export guard verified, round-trip byte-clean |
| A fix requires a new node type / dialect change | **Broken** — path (b) needs neither |
| Unbound state uniquely identifies a bare imported catch event | **Broken** — palette-created handoffs are also unbound, and the distinction dies at save |
| Zero live exposure in either corpus | **Validated at filing** (AEF typed their event upstream); re-check before building |

## Go/No-Go assessment against the task's own criteria

- *GO if root cause identified with a bounded fix path* — **met**: one fallback line, one rendering
  branch, no schema surface.
- *GO if fix is scoped, testable, and reversible* — **met**: testable by importing a bare catch event
  and asserting glyph/label/property panel; reversible by reverting one branch.
- *NO-GO if fundamental redesign or unbounded scope* — **not met** (path b is bounded).
- *NO-GO if cost exceeds benefit* — **the live question.** Cost is now known to be small. Benefit is
  zero live instances today; the value is preventing the next misread, which already cost a peer
  operator real confusion once.

## Recommendation

**GO**, scoped to path (b) — with the session-state resolution above, and explicitly **not** a new
node type.

Why this differs from the filing stub's DEFER: the stub deferred against an *unmeasured* cost. Now
measured, the fix is a rendering branch with no dialect surface and no round-trip risk, and it
removes a failure mode that has already misled one operator. Deferring a small, bounded, zero-risk
correctness fix because the triggering instance happened to be cleaned up upstream optimises for
inaction — the next bare catch event (hand-authored map, peer fixture, partially-typed import) walks
into the same misread.

If the decision is DEFER instead, the honest revisit trigger is a bare `intermediateCatchEvent`
appearing in any authored or imported map. The analysis is preserved either way, so a future GO
starts from a priced fix rather than from scratch.

**If GO:** implementation belongs in a separate build task (Inception Discipline step 5), scoped to
the rendering branch plus a regression test that imports a bare catch event and asserts the neutral
presentation, plus a courtesy note on the AEF rail.
