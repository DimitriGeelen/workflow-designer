# T-971 — Evergreen corpus: what our product let them produce, and which of it we must not straighten

**Task:** T-971 · **Date:** 2026-10-01 · **Corpus:** `aef-greenfield-test` (Nooteboom landscape
ontology), 26 maps + 104 saved versions, designer **v0.13.0**, AEF 1.7.441.
**Their maps are not committed** — analysed in place under a gitignored path. The owner approved
*sending* them; that is not approval to archive a real company's process landscape in our history.

---

## 0. The brief changed when we read the maps

We were asked to straighten these maps out and send them back improved. **Most of them must not
be straightened**, and finding out why is worth more than the cleanup would have been.

`bo-production`, read rather than measured:

```
COMPONENT 1 (5)   Start → Contstruction → Assembly → Painting → End
COMPONENT 2 (2)   Intracompany transport ↔ Warehouse transfer     ← floating
COMPONENT 3 (1)   Quality Control                                  ← floating
                  textAnnotation: "Volgorde tussen deze stappen is
                                   niet vastgelegd in de bron"
```

*"The order between these steps is not recorded in the source."*

The disconnection is **an honest representation of missing knowledge.** Their ontology states the
order for three steps and not for the other three. Connecting them would fabricate process
knowledge — the same prohibition as the rule that started this work: *an owner cannot be derived
and must not be invented.* **An order cannot be derived either.**

---

## 1. The measurement

| | ours | theirs |
|---|---|---|
| maps | 25 | 26 |
| maps with findings | 1 | **13 of 13 rendered** (before the `<task>` fix) |
| findings | 8 | **110 → 16** after the fix |

The `<task>` fix (T-970) removed 94 of 110 findings: we had been rejecting the base task element
of the standard we claim to implement, against our own §3 *lane-wins, warn-not-refuse* clause.
**86% of what we first "found" in their work was our defect.**

What remains, identical in both the as-is and the Soll (target-state) sets:

```
6  W-XML-DEADEND        5  W-XML-UNREACHABLE        5  W-XML-DISCONNECTED
```

**10 of 26 maps carry orphan components — the same 5 maps in each set.** 24 orphan components,
8 of them annotated. Per-map counts are *identical* between as-is and Soll, while the files
genuinely differ (4 changed fragments each). So **the defects are generator-systematic, not
design-specific**: fixing `ontology-bpmn.py` fixes all 26 at once, and the five fragmented maps
are not five modelling problems to untangle by hand.

---

## 2. The taxonomy — three classes, and only one is ours to repair

### Class A — declared uncertainty (8 maps). **Do not touch.**
`bo-parts-sales`, `bo-service-sales`, `bo-production`, `sales-new-vehicle`, ×2 for Soll.
Orphan components carrying the "order not recorded in the source" annotation.

This is the corpus being **more honest than the notation allows**. Our `W-XML-DISCONNECTED`
flags it as a defect, which means **we penalise them for not inventing an order**.

> **Could the designer have prevented it?** No — and it should not try. What the designer lacks
> is a way to *express* it. This is their finding #6 and it is the highest-value item in the
> whole corpus.

### Class B — overview maps where flow semantics do not apply (2 maps).
`bo-business-overview` (×2): 47 nodes, 44 in one component with **zero start events**, plus three
single-node orphans — *Account Management*, *Post Production Changes*, *Recalls* — all in a lane
named **"Overzicht"** (Overview). No annotation.

A landscape overview is not a process. Three capability boxes floating in an overview lane is
arguably correct for that document type, and flagging it as "two or more independent processes
sharing one pool" is a **category error**.

> **Could the designer have prevented it?** It could have *known*: `workflowMeta.kind`
> (`documentation` | `work-plan`) exists precisely to say "this is not an executable process".
> **None of their 26 maps carries any `aef:workflowMeta` at all**, so `kind` is absent and every
> map is judged as if it were an executable process. T-956 catalogued `kind` as one of four dials
> "turned and connected to nothing". This corpus is what that costs.

### Class C — genuinely generator-invented structure.
Their finding #1: *"our generator placed a start event before every step without a predecessor
and an end event after every step without a successor. 10 of 26 maps had up to three start and
three end events — a parallel process the source never stated."*

> **Could the designer have prevented it?** **Yes, and now it does.** `W-XML-DISCONNECTED`
> (T-967) exists because our own operator spotted the identical shape by eye on one of *our*
> maps, hours before their corpus arrived. Independently reported, same defect class, neither
> caught by any tool.

---

## 3. A second rule that can be silenced by removing its input

`W-XML-UNREACHABLE` only runs when the document **has** start events — it seeds from them. Three
of their maps have **zero**, so the reachability check is skipped entirely and reports nothing.

That is the same shape as the defect `W-XML-DISCONNECTED` was built for: *the check goes quiet on
a document that is more wrong, not less.* Delete every start event and the unreachability rule
stops having an opinion. Two instances of one pattern, found in one corpus.

---

## 4. What we owe them, in priority order

1. **A way to say "order not known".** Their prose annotation is unreadable by any machine,
   including ours. Until this exists, honest authors are punished by our validator. *(Their #6.)*
2. **`kind`-aware rule applicability.** An overview map should not be judged as an executable
   process. The field exists; nothing reads it. *(Their #1, Class B.)*
3. **Stable ids across save.** Identity is derived from the file's process id rather than the id
   they posted, so round trips must be matched on lane+step name. *(Their #2 and #3 — and this
   lands directly in the `workflowMeta[@id]` derivation we were working in this week.)*
4. **Save-if-changed.** They built their own dedup against `GET /api/version`. *(Their #4.)*
5. **A first-class unassigned owner.** They invented a lane `(systeem niet bekend)`; every task in
   these maps sits in it. A real "unassigned" concept, flagged rather than faked. *(Their #5.)*

**Free, and theirs:** `Contstruction` is misspelled in their ontology and propagates to every map
that uses it.

---

## 5. What we will send back, and what we will not

**Not** a set of rewritten maps. For Class A that would fabricate knowledge; for Class B it would
impose process semantics on an overview.

**Yes**: this taxonomy, the `<task>` fix (already shipped and already reported to them), the
statement that their generator is the single point of repair for all 26, and the typo.

**The one repair we can legitimately offer** is Class C — removing generator-invented start/end
wrappers where the ontology states no order — and even that belongs in *their* generator, not in
our edit of their files.

---

## 6. Dialogue log

- **Operator, 2026-10-01:** *"Have we read them all? … Have we straightened them out? … What the
  fuck where are we?"* — Correct challenge. I had *measured* all 26 and read none. Reading one
  map inverted the deliverable.
- **Evergreen, @1:** answers to all five questions, unfiltered corpus, owner's approval.
- **Us, @9:** the `<task>` finding, including two instrument errors of ours so they know what to
  discount.
- **Open:** whether they want the corpus deleted after analysis; items 1–5 above.
