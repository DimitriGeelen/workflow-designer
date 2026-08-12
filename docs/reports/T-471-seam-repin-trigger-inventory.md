# T-471 — The seam re-pin has three triggers, and rail 581 named the blocked one

**Correction to my own rail post.** At offset 581 I asked AEF what a coordinated re-pin
costs them and how much lead time it needs, attributing the trigger to **T-423** (arc-001
step 2, emit BPMN DI). T-423 is blocked behind T-340's ruling and cannot move a byte until
the operator rules.

Measured across *all* active work rather than just the arc, **T-423 is not the trigger most
likely to fire first.** It is the only one that cannot.

---

## 1. The inventory

Every active task naming either corpus, classified by reading it rather than by the fact
that it names a path:

| task | corpus | change kind | can it fire now? | owner |
|---|---|---|---|---|
| **T-101** | 24 rendered maps | **moves bytes** — `cleanLayout()` over all 24, then mirror to `build/gallery/rendered/` | **YES** — `started-work`, `horizon: now`, nothing blocking | human |
| **T-423** | 24 rendered maps | moves bytes — additive DI emission | no — blocked on T-340 | arc |
| **T-443** | `tests/fixtures/aef-bpmn/` | **path identity** — rename as a v1.2 standard delta | no — blocked on AEF's own ruling, DM 548 §5 | human |

Ruled out, and each for a reason that had to be checked rather than assumed:

| task | why it is not a trigger |
|---|---|
| **T-041** | Named the rendered corpus and is `started-work`/`now`, so it read like a trigger. It is not: `examples/aef-processes/rendered/inception-review.bpmn` **already exists** and its Agent AC is checked. The byte-writing half is done; what remains is the operator's fidelity verdict. |
| **T-155** | Mentions the path as a browse source. A backlog `inception` for an Open-project browser redesign — reads the corpus, does not author it. |
| **T-308, T-310, T-449** | `work-completed` (partial-complete, awaiting Human ACs). Whatever they moved has moved. Not pending. |

---

## 2. Why this matters more than the count

**The unblocked trigger and the announced trigger are different tasks.** AEF is currently
being asked to cost a change that is gated behind an operator ruling nobody can schedule,
while the change that can land tomorrow — T-101 re-laying-out all 24 rendered maps —
was not mentioned to them at all.

If T-101 runs first, the 24 rendered maps move bytes *before* the protocol my own rail post
asked for exists. The lead-time question at 581 §3 was the right question pointed at the
wrong task.

**T-443 is a different kind of event and should not be folded in.** T-101 and T-423 move
bytes under a stable path; T-443 changes the path *itself* — a path named normatively in a
**frozen** two-party standard (`mapping-v1.md:142` inside Part I; `forward-compile-v1.md:21`
with a section titled after it). A consumer pinning `source_bpmn_sha` survives a byte change
with a re-pin. A consumer resolving the path does not survive a rename at all. **Byte-diffing
cannot see this class**, which is why it is listed separately rather than as a third row of
the same table.

**T-443 is already queued behind an AEF question, and I did not connect them.** Its trigger
is *"AEF answers DM 548 §5"*. So the rail now carries two unlinked threads about the same
corpus: 548 §5 (may we rename the fixture path?) and 581 (what does a re-pin cost you?).
Same files, same peer, asked as if unrelated.

---

## 3. The pin I wrote in T-469 covered 42 of 47 paths

T-469 pinned the corpora with

```
git ls-files -s examples/aef-processes/rendered/*.bpmn tests/fixtures/aef-bpmn/*.bpmn
```

→ 42 files, `3443f813ab1ea6b5`. The recursive form over the same two directories:

→ **47 files**, `882ce395ad5d00b6`. The five outside the pin:

```
examples/aef-processes/rendered/README.md
tests/fixtures/aef-bpmn/PROVENANCE.md
tests/fixtures/aef-bpmn/t257-eventdef-roundtrip/draft-trigger-handling-v1.bpmn
tests/fixtures/aef-bpmn/t257-eventdef-roundtrip/draft-trigger-handling-v2.bpmn
tests/fixtures/aef-bpmn/t257-eventdef-roundtrip/README.md
```

**T-469's headline finding was that a shell glob does not descend and had hidden
`t257-eventdef-roundtrip/` — and the guard written in that same task used the glob.** The
prose was corrected; the leg was not. A finding does not propagate into the instruments of
the task that found it unless someone carries it there, and the natural stopping point is
the moment the sentence reads correctly.

Worse in this instance than the count suggests: the two unpinned `.bpmn` files are the
round-trip pair T-469 identified as *the single most seam-relevant artifact in the
analysis*, and `PROVENANCE.md` is the file that establishes 832-authorship and the
normative-path claim T-443 turns on. The pin protected the routine files and left the
load-bearing ones out.

T-471 pins the recursive form.

---

## 4. What is corrected on the rail

The 581 post stands as to its four questions — they are still the right questions. What
changes is the premise attached to them:

1. The trigger to cost is **T-101**, not T-423. T-101 is unblocked and human-owned.
2. T-423 remains blocked and may never fire in its current shape.
3. **T-443 is the same conversation as DM 548 §5**, not a separate one, and it is a
   path-identity change rather than a byte change.

Stated as a correction rather than an addendum, because "here is more information" would
leave AEF's existing cost estimate attached to the wrong task.

**Not claimed:** what AEF actually pins is still their answer to give (581 §1). This
document corrects our half of the premise; it does not presume theirs.
