# T-469 — What T-423 actually costs at the seam, measured before asking AEF to absorb it

**Purpose:** T-423 (arc-001 step 2, emit BPMN DI additively) is blocked behind T-340's ruling.
Its stated cost is *"all 24 corpus maps change bytes, so AEF's pinned `source_bpmn_sha` fixtures
need a COORDINATED re-pin — this is the first step in the arc that touches the seam."*

That sentence conflates two different corpora and, measured, **overstates the risk in the place
that matters most and understates a constraint nobody had named.** This document establishes the
blast radius from our side so the rail question asks AEF for a *process*, not for our measuring.

Nothing here emits, migrates, or re-pins anything. T-423 remains blocked.

---

## 1. There are two corpora, and only one of them is what T-423 changes

| corpus | files | named in a standard? | export-path output? |
|---|---|---|---|
| `examples/aef-processes/rendered/` | **24** | **no** — no standard names this path | **24 of 24** |
| `tests/fixtures/aef-bpmn/` | **20** | **yes — 3 normative references** | **7 of 20** |

> **These numbers were 18 and 6 in the first draft, and the correction is not cosmetic.** A
> shell glob `tests/fixtures/aef-bpmn/*.bpmn` does not descend, so it missed the subdirectory
> `t257-eventdef-roundtrip/` entirely — two files, one of which is export-path output and is the
> single most seam-relevant file in the set (§2a). Caught by a verification leg that compared
> the report's asserted count against git's own recursive pathspec; the two disagree, 18 vs 20,
> and the leg went red. **The glob's reach was the unchecked assumption, again** — third
> instance this session of a first-form measurement that was wrong in a way that reads as a
> result.

The "24 corpus maps" in T-423's description are the *rendered* ones. They are not named in
`aef-bpmn-mapping-v1.md` or `aef-bpmn-forward-compile-v1.md`. Changing them is a pin problem
only.

The fixture corpus is the one with standard exposure: `aef-bpmn-forward-compile-v1.md` names
`tests/fixtures/aef-bpmn/*.bpmn` as **"the reference corpus"**, and `aef-bpmn-mapping-v1.md:142`
names `inception-gonogo.bpmn` as a **Reference fixture** — inside **Part I, which is frozen and
must not be edited under agent control**.

---

## 2. The three artifacts that would have been expensive are all safe

| artifact | why it matters | export-path output? |
|---|---|---|
| `typed-events.bpmn` | sha-pinned by `tests/test_typed_event_fixture_contract.py`; delivered to AEF rail-inline (offsets 88/89) as the byte-identical cross-validation artifact | **no** |
| `boundary-events.bpmn` | same pin, same delivery | **no** |
| `inception-gonogo.bpmn` | named as a Reference fixture at `mapping-v1.md:142`, inside **frozen Part I** | **no** |

**None of the three is produced by the export path**, so T-423 does not touch them. The frozen
standard's named fixture is untouched, and neither pinned sha moves.

The 7 fixtures that *are* export-path output: `arc-lifecycle`, `dispatch-loop`,
`harvest-pipeline`, `investigate`, `resume-status`, `s4-exemplar`, and
`t257-eventdef-roundtrip/draft-trigger-handling-v2.bpmn`. These sit inside the forward-compile
standard's **wildcard** reference corpus, not a named-file clause. Six of them change bytes
**only if someone re-exports them** — a choice T-423 does not have to make.

### 2a. The seventh is different, and it is the one to raise with AEF

`t257-eventdef-roundtrip/` holds a **pair**: `draft-trigger-handling-v1.bpmn` and `-v2.bpmn`.
Measured, **v1 lacks the exporter trailer and v2 carries it** — so the pair is
*input → export result*: v1 is what goes in, v2 is what our exporter is expected to produce.

That makes v2 **the expected-output half of a pinned round-trip fixture.** T-423 changes what
the exporter emits, so v2 is not a file that changes *if we choose to regenerate it* — it is a
file whose correct contents are **defined** by exporter behaviour. Leave it and the round-trip
test asserts the old exporter; regenerate it and the pinned bytes move.

This is also the fixture with live seam history: `draft-trigger-handling` is the one AEF's
pinned 0.4.0 exercises, and a previous change there was resolved by *their* release re-pin
rather than an edit on our side. So it is the concrete case where "who regenerates, and when"
has already needed an answer once.

---

## 3. How this was measured, and the limit of the method (PL-033/PL-034)

The proxy for "is this export-path output" is the trailer `src:9582` emits into **every**
exported `.bpmn`:

```
cd /opt/832-Workflow-designer && grep -l 'BPMN DI (visual layout) omitted' tests/fixtures/aef-bpmn/*.bpmn
```

The inference is **asymmetric, and the safety conclusions rest on the sound direction**:

- **lacks the trailer ⇒ not export-path output.** Sound: the exporter emits it unconditionally.
  This is what carries §2 — all three high-cost artifacts lack it.
- **has the trailer ⇒ probably export-path output.** Weaker: a hand-authored file could have had
  it pasted in. This carries only the *at-risk* set of 6, where the weak direction can only
  **over**-estimate risk.

So the method is conservative exactly where being wrong would be expensive, and loose only where
being wrong costs an unnecessary check. Stated because PL-034 is explicit that a guard checking
our own corpus is internal self-consistency and cannot detect a broken promise at the seam:
**everything above is our half.** What AEF pins, where, and what goes red on their side when 24
rendered maps change is **not observable from here** and is not claimed.

---

## 4. What is actually owed to AEF — a process question, not a ruling question

The ruling on T-340 is the operator's and is not AEF's to influence; asking them to weigh in on
it would route a sovereignty decision through the peer. The question that *is* theirs, and is
answerable **now, before the ruling**, is what a re-pin costs them and how much lead time it
needs. Four things, all measurable on their side:

1. **Which of our artifacts do you pin by `source_bpmn_sha`** — the 24 rendered maps, the 18
   fixtures, or a subset? We know we deliver both; we do not know what you pin.
2. **Do you hold the 6 export-authored fixtures as static bytes, or regenerate them from our
   exporter?** If static, T-423 costs you nothing there. If regenerated, those 6 are the ones
   inside your forward-compile reference corpus.
3. **What does a re-pin cost you** — a fixture refresh, a code change, a release re-pin? And
   what lead time do you need between "832 says the bytes are about to move" and "your side is
   green again"?
4. **Is there a shape you would prefer for the announcement** — a rail post with the new shas
   inline, a manifest, or a version bump? Getting this wrong is the difference between a
   coordinated change and a broken peer.

**Why ask now.** If the ruling lands and *then* we start this exchange, the arc's first
seam-touching step is blocked on a round trip that could have happened while it was already
blocked on something else. This is the only part of T-423 that can be de-risked without
pre-empting the operator's decision.

---

## 5. Correction 2026-08-12 (T-471) — the premise of §4 was arc-scoped

Everything above is scoped to T-423 because T-423 is the arc step. Measured across **all**
active work, T-423 is not the trigger most likely to fire first — it is the only one that
**cannot** fire, being blocked on T-340.

- **T-101** (`started-work`, `horizon: now`, owner human, unblocked) runs `cleanLayout()`
  over the same 24 rendered maps and mirrors to `build/gallery/rendered/`. Same bytes,
  no gate.
- **T-443** changes the fixture corpus **path identity** (rename as a v1.2 standard delta)
  and is already queued behind AEF's answer at **DM 548 §5** — so the rail carries two
  unlinked threads about the same files.

So §4's four questions are right and their attribution was wrong: AEF was asked to cost a
change gated behind an unschedulable ruling, while the change that can land tomorrow went
unmentioned. Corrected on the rail as a correction, not an addendum.

**And the pin in this task's own Verification covered 42 of 47 paths.** Leg 2 used
`…/*.bpmn` globs — the very construct §1's callout identifies as having hidden
`t257-eventdef-roundtrip/`. The prose was fixed; the leg was not. The five paths outside it
include both halves of the round-trip pair §2a calls the most seam-relevant artifact here,
and `PROVENANCE.md`. Recursive form: `882ce395ad5d00b6` over 47 paths, pinned by T-471.

Full inventory: `docs/reports/T-471-seam-repin-trigger-inventory.md`.
