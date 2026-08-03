# T-347 — what happens to content INSIDE an element the importer accepts

**Run:** `node tools/_t347-accepted-element-content-cdp.mjs`, 2026-08-03.
**Positive control** (`arc-lifecycle`, designer-produced, input-derived): **no shape lost.**

**Result: every one of T-347's five shapes is LOST on 100% of the files that carry
it.** Until today this task's verdicts were synthetic — measured by splicing a probe
into a document we wrote. They now have named third-party witnesses.

| shape | carriers losing it | witnesses |
|---|---|---|
| `documentation` | **2 / 2** | `bizagi-nested-ns`, `i18n-documentation` |
| foreign `extensionElements` children | **6 / 6** | all six carriers |
| spec `property` | **2 / 2** | `caseagile-local-ns`, `kitchen-sink` |
| loop characteristics | **2 / 2** | `caseagile-local-ns`, `kitchen-sink` |
| unknown (foreign-namespaced) attributes | **3 / 3** | `i18n-documentation`, `kitchen-sink`, `zeebe-service-task` |

Every loss is to **exactly zero**, never a reduction.

## Why this needed its own instrument, demonstrated rather than argued

`caseagile-local-ns.bpmn` is the case that settles it. Run through `_t356` — which
censuses *structure*: nodes, flows, lanes, participants, DI — it loses **one** thing,
the `exporter` attribute. On that instrument it is the cleanest file in the set and
reads as very nearly lossless.

Run through `_t347` the same file loses **451 pieces of content**: 405 foreign
elements, 45 `property` elements, 1 `multiInstanceLoopCharacteristics`.

**A structural census returns a near-clean verdict on a document that is being
gutted.** Neither number is wrong; they answer different questions, and T-347's
question had no instrument. This is why "T-356 proved the corpus can exhibit
real-world import defects" was true of one question and false of four others —
capability is per-QUESTION, not per-population.

## The instrument defect that would have published a false negative

The first cut of this census summed every non-spec-prefixed element into one
`extChildren` number and compared input to output. It reported:

```
kitchen-sink   extChildren  kept 1->162
```

`kitchen-sink` contains exactly **one** foreign element, a `<zeebe:calledElement>`.
It cannot honestly come back with 162. What happened: the importer deleted the
`zeebe:` element and our exporter wrote 162 `<aef:position>` elements — one per node
— which my counter also scored as "foreign", pushing the output total far above the
input so the comparison called a deletion **kept**.

**A total cannot distinguish PRESERVATION from SUBSTITUTION**, and content we emit
ourselves can never repay a debt in someone else's vocabulary. Fixed by tallying per
prefix and comparing only over the prefixes the *input* actually had. The fix moved
`extChildren` from **2/6 to 6/6** — four rows that read as survival were substitution.

Worth recording for its direction: the bug failed toward the **reassuring** answer. A
wrong `LOST` sends you to debug working code and gets caught; a wrong `kept` gets
published. Instruments do not fail symmetrically, and the cheap ones to catch are the
ones that fail the expensive way.

## Three-state reporting, and why `n/a` is never folded in

Each shape reports `kept` / `LOST` / `n-a`, and each shape's denominator is **the
number of files that actually carry it**, not the number of files run.

A two-state instrument would score a fixture containing no `<documentation>` as
"documentation fine", and eight such fixtures would read as strong evidence for a
claim nothing measured. Of the ten fixtures, **eight cannot answer the
`documentation` question at all**. The two that can, both lose it. `2/2` and `2/10`
are very different sentences and only one of them is true.

## The severity claim this run corrects — and the one it does not rescue

Last session I retracted T-347's assertion that *"any file arriving from a
third-party modeller carries both [documentation and a foreign extension child]"* as
measured false — 0 of the T-356 five carried either. That retraction stands and this
run does not reverse it: of ten third-party fixtures, only **2** carry
`documentation` and **6** carry a foreign extension child.

What changes is the *other* half. The shapes are **rare but universally fatal**: when
present, they are destroyed every single time, with no partial survival anywhere in
the table. Severity is therefore **low incidence, total loss**, which is a different
risk profile from either "latent" (the pre-T-356 rating, drawn from a population that
could not exhibit it) or "any file carries it" (the overcorrection I retracted).

## Occurrence, and the limit on what that number means

From the 467-file survey the fixtures were drawn from:

| shape | files carrying it | of 467 |
|---|---|---|
| `documentation` | 10 | 2.1% |
| `LoopCharacteristics` | 19 | 4.1% |
| spec `property` | 22 | 4.7% |
| …of which `__targetRef_placeholder` only | 19 | — |

Genuine author-meaningful `bpmn:property` appears in **3 of 467** files; the rest is
bpmn-js's internal `__targetRef_placeholder`.

**This is not a wild-occurrence rate and must not be quoted as one.** The surveyed
population is *tooling test fixtures*, which are minimal by construction — written to
exercise one feature, not to model a business. Presence here is strong evidence a
real tool emits the shape; the *rate* says little about production models, where
`documentation` is exactly the thing a human author types. The honest sentence is
"non-zero occupancy in the wild, still unquantified" — the same wording the retracted
severity claim was replaced with, and for the same reason.

## Not claimed

- **No expectation pin flipped.** `_t338`'s `EXPECTED_*` sets are untouched; this
  instrument gates nothing. T-347 is now *capable of failing* and does fail; the
  repair is a separate matter.
- **Nothing repaired.** No source file was edited.
- **Four fixtures still cannot answer four of five questions.** `simple`,
  `boundary-events`, `nested-subprocesses`, `collaboration-message-flows` — the
  T-356 five minus `multiple-diagrams` — are `n/a` across the board here. They were
  selected for a different question and remain fit for it.
