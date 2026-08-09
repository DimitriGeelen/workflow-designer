# T-397 — Import repair semantics: four open rulings, read as one decision

**Status:** decision brief. Prepared for the operator. Nothing here is decided.
**Date:** 2026-08-08
**Blocked tasks covered:** T-340, T-341, T-347, T-358 (ACs 4–6)
**Precedent already ruled:** T-337 (completed 2026-08-03)

---

## Why this document exists

Four arc tasks are stopped on Human `[REVIEW]` rulings. Between them they hold the
largest cluster of now-horizon work in `designer-authoring-surface`. Each ruling lives
at the bottom of a 300–430 line task file, each carries its own option set (`a/b/c`,
`a/a′/b/c`, `1/2/3`), and several have been **corrected in place** — T-340's
recommendation changed from `(a′)` to `(b)`, T-347's severity was restated twice and
retracted once, T-340's step 3 is marked *superseded*.

The result is that the current recommendation for any one ruling is recoverable only by
reading the whole file and knowing which paragraphs are live. That is the actual
blocker. Not the difficulty of the questions — the unreadability of their current state.

This brief states each ruling once, in its current form, with what it costs and what it
unblocks.

---

## TL;DR

| # | Ruling | Question | Recommendation | Unblocks |
|---|---|---|---|---|
| **Q1a** | **T-347** | Content inside an element we accept — `documentation`, foreign `extensionElements` children, `property`, loop characteristics, unknown attributes | **(a) preserve and re-emit** | T-347 (4 ACs), the T-348 fold-in (7 more shapes) |
| **Q1b** | **T-340** | The whole `bpmndi` sub-tree | **(b) consume DI as layout**, scoped — *not* (a) | T-340 (3 ACs), first increment of T-357 |
| **Q2a** | **T-341** | Which lane silently acquires a flow node whose `flowNodeRef` will not resolve | **operator only — no agent recommendation** | T-341 (3 ACs) |
| **Q2b** | **T-358** | Whether the importer may invent lanes and a participant the input never had | follows from Q2a | T-358 ACs 4–6 |

**Q1 has a ratified precedent. Q2 has none, and should not acquire one from an agent.**

---

## The hypothesis I started with, and why it is false

I opened this expecting to find that four tasks were asking one question four times, and
that the consolidation was simply *"T-337 already ruled (a); extend it."*

That is wrong, and T-340's own analysis is what falsifies it. Recording it because the
wrong version is the intuitive one and someone will re-derive it:

> **(a) preserve-and-re-emit is correct for a foreign tag and for element content, and
> actively harmful for DI.**

The mechanism is specific. Preserving DI bytes leaves the *importer* blind to them, so a
foreign file still auto-layouts on load — `src:9742` takes position from `aef:position`
if present, **else lays out automatically**, and a foreign file has no `aef:position` by
construction. Export then writes the preserved original DI *alongside* freshly generated
`aef:position`. The document now carries **two contradictory geometries, immediately,
with no user action**. The variant `(a′)` — preserve structure, refresh coordinates from
`aef:position` — is self-consistent and destroys exactly the thing worth saving.

So the honest generalisation is not "always preserve". It is:

> ### The competing-carrier rule
>
> **Preserve-and-re-emit unconsumed content — unless we generate a competing carrier for
> the same fact. Where we do, preservation produces a self-contradictory document, and
> the correct answer is to consume.**

Checked against all three granularities:

| granularity | do we generate a competing carrier? | correct semantics |
|---|---|---|
| T-337 — foreign flow-node tag | no | **(a) preserve** ✔ *shipped* |
| T-347 — content inside an accepted element | no | **(a) preserve** ← recommended |
| T-340 — `bpmndi` geometry | **yes — `aef:position`** | **(b) consume** ← recommended |

DI is the only case in the tree where we generate a rival carrier. That is why it is the
only one that departs from the precedent, and the departure is principled rather than an
inconsistency to be tidied away.

---

## The two questions

The four rulings are not four points on one axis. They are two axes.

### Q1 — LOSS. *What do we do with content we did not read?*

T-340, T-347 (and the seven root-level shapes T-348 folded in). Failure mode: a peer's
document arrives, opens, saves, and comes back smaller. Nothing is invented; things go
missing. **Fidelity question.**

Governed by a principle we already ratified at **T-225** — *diagram XML is never silently
migrated* — live at three sites in `src/aef-workflow-designer.html` (8201, 9773, 9869),
and by the **T-259** precedent where an unconsumed `<aef:eventDef>` was captured as inert
state so export could re-emit it. **T-337** applied both and shipped `(a)`.

### Q2 — FABRICATION. *What do we do about content we invented?*

T-341, T-358. Failure mode: a document arrives carrying *less* structure than we require,
and the importer **manufactures the difference** — three lanes and a participant that the
input never had (T-358), or a home for a flow node whose lane reference will not resolve
(T-341). Nothing goes missing; things appear.

**This is not a fidelity question and the Q1 precedent does not reach it.** A fabricated
lane is not a preservation failure — it is an assertion about *who is accountable for a
step*, made by the importer, silently. T-341 states this correctly and I am not going to
soften it: the three options differ in which authority acquires a step, which the
Authority Model reserves to the human. **No agent recommendation is offered on Q2a, and
none should be accepted.**

---

## Per-ruling briefs

### Q1a · T-347 — content inside an accepted element

**Measured.** Ten real third-party fixtures (Camunda Modeler 5.16 / 4.8, Zeebe Modeler,
Enterprise Composer, Bizagi). Every carrier loses all of it, **always to exactly zero,
never a reduction**:

    documentation                      2/2 carriers lose it
    foreign extensionElements children 6/6
    spec property                      2/2
    loop characteristics               2/2
    unknown foreign-ns attributes      3/3

**The trap worth your attention.** `caseagile-local-ns.bpmn` loses **one** thing under a
structural census and **451** under the content census. Node, flow and lane counts are
unchanged throughout — an element that survives with its body stripped keeps all three.
Every count-based instrument in this tree stayed green over documents being gutted, for
the entire time the defect existed. *"Our suites are green"* is not evidence here.

**Recommendation: (a) preserve and re-emit.** It matches T-337 at the granularity
directly above, matches T-259 at the granularity directly below, and is the only option
that also covers content nobody has thought of yet. No competing carrier exists, so the
competing-carrier exception does not apply.

**One row may not want the uniform answer.** The T-348 fold-in includes `second-process`:
a two-pool collaboration opened and saved returns as a one-pool document — an entire
pool's nodes gone — while every count on the *surviving* pool stays green. Option (c)
refuse is far more defensible for that row than for a `documentation` string. If Q1a is
ruled uniformly, `second-process` is the row most likely to make the uniform answer
wrong, and deserves an explicit sentence either way.

---

### Q1b · T-340 — the `bpmndi` sub-tree

**Recommendation: (b) consume DI as layout — scoped, not maximal.**

    on import   aef:position  →  else DI  →  else auto-layout
    on export   emit DI only when the input carried it

**Why this changes zero bytes, re-measured today.** The byte objection that once
disqualified (b) applies only to a maximal form that always emits regenerated DI. Scoped
as above, the precedence rule never fires on our corpus, because the two populations are
disjoint:

    tracked .bpmn files          142
      carry aef:position         123
      carry BPMN DI               10
      carry BOTH                   0     <- the load-bearing number
      carry NEITHER                9

**This is a re-measurement, not an inherited claim.** T-340 measured 126 files and
121 carrying `aef:position`; the third-party intake has since added sixteen files,
ten of which carry DI. A disjointness claim is exactly the kind a new intake can break.
It did not: `BOTH` is still 0. Zero bytes change for existing maps, `_t308` stays 24/24,
no fixture re-pin, no seam event.

**(b) is also the only option under which the author opens their diagram and sees their
diagram.** (a) and (a′) both leave the importer blind and produce the contradiction
described above.

**Relationship to T-357.** Scoped (b) is a strict subset of "adopt BPMN DI as the
designer geometry and retire `aef:position`". Choosing it now is the first increment
either way and is not work thrown away if that inception says GO. **T-357 being open is
not a reason to defer this ruling.**

---

### Q2a · T-341 — which lane acquires an orphaned flow node

**No agent recommendation.** The options are in the task file and reproduced here only so
the shape is visible without opening it:

1. **Keep positional (`lanes[0]`).** Zero change. Accepts that laneSet *order* decides
   authority for orphans.
2. **Fixed lane by authority.** Orphans always land in a named lane regardless of order —
   e.g. the lowest-authority lane present, so an unresolvable reference can never
   *promote* a step. Needs a rule for maps where no such lane exists.
3. **Refuse to place.** No silent repair at all.

Orthogonal yes/no: **should the reassignment be announced?** `E-XML-LANEREF-DANGLING`
exists as an ERROR rule, but T-309 IW-3 measured the repair as happening *inside*
`parseBpmnXml`, so no surface can ever show it. Announcing composes with any of 1/2/3.

---

### Q2b · T-358 — fabricated lanes and participants

Diagnosis is complete: 3 of 6 ACs done — the fabrication is reproduced, its site named,
the two causes separated ("input had no lane set" vs "input had one we failed to read"),
and a negative control proves the probe can report *no* fabrication.

The remaining three ACs are all **repair**, and repair needs the fabrication policy. The
one constraint already established and worth carrying into the ruling: *"repair must not
silently reverse into the opposite defect"* — emitting zero lanes where the input had
none is a different document than the input, in the other direction.

**Follows from Q2a.** Ruling Q2a without noticing Q2b is how the two acquire inconsistent
policies.

---

## Dependency map

    Q1a  T-347  ──> T-347 ACs 1-4, T-348 fold-in (7 shapes)
    Q1b  T-340  ──> T-340 ACs 1-3  ──> T-357 (first increment; not blocked BY T-357)
    Q2a  T-341  ──> T-341 ACs 2-4
                └─> Q2b T-358 ACs 4-6

**Four rulings, three independent decisions** — Q2b follows from Q2a. Q1a and Q1b are
independent of each other and of Q2. Any one can be ruled without the others.

---

## Consistency constraints

1. **Q1a and Q1b may differ, and should.** If both are ruled `(a)`, DI produces
   contradictory geometry. If both are ruled `(b)`, we start typing content we have no
   fields for. The competing-carrier rule is what makes "different answers" principled
   rather than arbitrary — and it is worth recording *as a rule*, because the next
   granularity will arrive and someone will have to ask the question again.
2. **Q2a and Q2b must agree.** Both decide what the importer may invent.
3. **Q1 and Q2 need not agree about anything.** Different axes.

---

## What AEF's answer changes, and what it does not

Asked on the rail at **offset 484**: does AEF's importer have a precedent for unconsumed
content, and which way does it fall?

**The asymmetry that motivated asking.** If we take (a) and AEF takes (b), a document that
round-trips through *both* of us still loses the content — our preservation buys nothing
at the seam, and joint behaviour is (b) regardless of what we choose. Preservation is only
end-to-end if both ends do it.

**No ruling here is blocked on their reply.** Q1a's case stands on our own precedent and
our own measurements. Q1b's scoped (b) changes zero bytes and needs no coordination — the
narrower question genuinely owed to AEF is *"if you ever hand us a document carrying both
`aef:position` and DI, which wins?"*, and nothing produces that shape today (`BOTH = 0`,
re-measured above). Q2 is entirely ours. Their answer changes **what we record about the
seam**, not what we decide.

### The answer arrived, measured — rail 487 (their T-2882) — 2026-08-09

They declined my offered fallback (*"we're (b) by omission, not by decision"*) and measured
instead: harness `tests/unit/test_importer_fidelity.py`, report `docs/reports/T-2882-importer-fidelity.md`.

**My question had the wrong shape.** They have *two* importers, and only one is a round-trip:
`bpmn_to_tasks.py` is a **projection** (BPMN → task skeletons on stdout, never writes a
`.bpmn`), `corpus_spec.py` is the **round-trip**. For the projection the (a)/(b)/(c) question
barely applies — everything it drops is still in the untouched source file, which remains the
store of record. That is a *projection loss, not a data loss*. **We must not import that
distinction by analogy: it does not exist in the same form on our side**, because our importer
feeds an editor whose export is the next store of record.

Round-trip results, by position (fixture: **our** `session-handover.bpmn` from T-214, which
round-trips canonically identical — so it doubles as proof they can read what we author):

| their outcome | positions |
|---|---|
| **preserved (a)** | unrecognised `aef:*` child of `extensionElements`; foreign-ns child of `extensionElements`; non-extension child of `sequenceFlow` |
| **refused (c)** | unsupported `process` child **with an id** → hard `SystemExit` |
| **dropped (b), silently** | foreign-ns attribute on a node; **loose text inside a node** ← our T-347 shape; `<bpmn:documentation>` on a **node**; unsupported `process` child **without** an id; foreign sub-tree off `<definitions>`; trailing comment; **`bpmndi` geometry** ← our T-340 position |

**Q1b / T-340 — convergence, not agreement.** They emit `aef:position` on every node and no
BPMNDI at all, and concluded that preserving input DI hands the export two carriers for one
geometry with no user action to reconcile them. Same position, same ruling, same reasoning,
*arrived at before reading ours*. That is worth strictly more than agreement would be: two
independent derivations of PL-114 from different codebases. **Adopt their test shape.** Ours
argues the rule in prose; theirs pins `test_di_drop_has_a_competing_carrier`, which asserts the
carrier **exists** — delete `aef:position` and it goes red. The day our DI drop becomes pure
loss, we get a red test instead of a silence. Our recommendation is unchanged; our *instrument*
should change.

**Q1a / T-347 — 484's question resolves, but it does not settle the ruling.** They drop loose
node text silently too. So the behaviour is a property of **the seam**, not a defect peculiar
to us — our ruling is not a defect confession. Stated plainly, because it is tempting to
over-read: *"both sides do it" is a description, not a justification.* It removes the argument
that we are uniquely lossy; it adds nothing to the case that (a) is correct. The
recommendation for T-347 still rests on our own precedent (T-337) and the absence of a
competing carrier — exactly where it rested before their reply.

**Q2 / T-341 + T-358 — this is where the measurement costs us.** Their classification, with a
test (`test_fabricated_fields_are_enumerated`) that fails on any emitted key belonging to none
of the three classes:

| class | keys |
|---|---|
| sourced | `id` (`aef:uid`), `name` (`@name`) |
| derived | `owner` ← from the node's **lane** (their IW-7 authority-of-record) |
| fabricated | `workflow_type`, `tier`, `horizon`, `status`, `related_tasks` |

> **"We do not invent lanes or participants the input never had."**

They fabricate *scheduling and lifecycle* fields and **derive** the accountability field from a
structure the author actually authored. Our importer **fabricates the structure itself** — 3
lanes and 1 participant on every third-party document, on open (T-358).

On the sovereignty axis **we are the outlier and they are not.** This belongs in front of the
operator as an asymmetry, not as a fidelity nit: a fabricated lane asserts *who is accountable
for a step*, so we are inventing accountability where they are reading it off authored
structure. Note also that their derivation is *visible where it is weakest* — a `serviceTask`
in a human lane resolves lane-wins **with a WARN**, and an `authority`-lane node falls back to
`agent` under our own ratified wording (*the executor is still the agent; what is lost is
provenance*, rail 95). Ours announces nothing.

**Two findings they reported, unfixed, with analogues we have NOT checked:**

- **OBS-205 — node/edge asymmetry.** `<bpmn:documentation>` on an **edge** round-trips; the
  byte-identical element on a **task** is destroyed silently. Same content, opposite outcome,
  decided by which side of the graph it landed on.
- **OBS-206 — the refusal is gated on having an id.** Their hard error fires from a branch
  requiring `el.get("id")`. Same tag, same content, same position: *with* an id, a loud
  `SystemExit`; *without*, it vanishes. `textAnnotation` and `association` are routinely
  authored without ids — **the hole is exactly the shape of the elements most likely to fall
  into it.**

OBS-206's concealment mechanism is the one to carry across: **the guard's *success* is what hid
it.** Every time it fired, it fired loudly and correctly, and that track record is evidence
about which elements people give ids to — not about the guard's reach. Same shape as PL-115
(fixing a gate does not replay what it blocked) and as our own DI finding: a control reads as
comprehensive precisely because the cases escaping it are the silent ones.

We have plausible analogues of both. **We have not looked.** Recorded here as unchecked, not as
clean.

**Method note worth stealing.** My 484 line — *"an element that survives with its body stripped
keeps its node, flow and lane counts"* — changed their harness, not just their answer. Their
instruments were structural and would have reported clean for the same reason ours did. Every
probe now carries a unique sentinel and asks **where that string ended up**, never how many
elements survived. They added two controls we should copy: a **positive** control (a mutation in
a position the importer demonstrably reads *must* move the output — otherwise every
"dropped-silently" reading is equally consistent with a harness that never invoked the importer
at all; they had exactly that masquerade as a working fix in T-2881) and a **null** control (an
unused `xmlns` declaration must *not* move the output, or the foreign-namespace probes are
measuring the declaration rather than the payload). They also split our (b) into
`dropped-silently` vs `dropped-with-notice` — every one of theirs came back silent.

**What they did not measure**, in their words: one fixture per importer; probes are
per-position, not per-map; the designer save path was *inspected, not probed* (it writes client
bytes verbatim); `bpmn_promote.py` not probed; probes insert one level deep, so a deeply nested
foreign sub-tree inside a preserved `ext_raw` child is preserved by construction but not
separately probed.

---

## Recording a ruling

Any single ruling, copy-pasteable:

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context add-decision "T-347 repair semantics: a" --task T-347 --rationale "preserve-and-re-emit; no competing carrier; matches T-337/T-259"
```

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context add-decision "T-340 DI repair semantics: b-scoped" --task T-340 --rationale "aef:position then DI then auto-layout; emit DI only when input carried it; BOTH=0 so zero bytes change"
```

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context add-decision "T-341 orphan-lane policy: <1|2|3>, announce <yes|no>" --task T-341 --rationale "<why>"
```

---

## Provenance of every number in this brief

| claim | how obtained |
|---|---|
| 142 / 123 / 10 / **0** / 9 population split | measured this session over `git ls-files '*.bpmn'` |
| T-225 principle live at 3 sites | `grep "never silently migrated" src/` — 8201, 9773, 9869 |
| `foreignTag` carrier live | `src:9527-9529`, `9981-9989` |
| T-347 per-shape carrier counts | `docs/reports/T-347-accepted-element-content.md` (10 fixtures) |
| 1-vs-451 structural/content divergence | T-347 report, `caseagile-local-ns.bpmn` |
| T-358 diagnosis 3/6 complete | AC state in the task file |
| T-337 ruled (a) and shipped | `.tasks/completed/T-337-*.md` → `## Decisions` |
| AEF round-trip table (preserved/refused/dropped) | rail 487, their T-2882 — **their** measurement, reported not reproduced |
| AEF sourced/derived/fabricated split | rail 487; pinned their side by `test_fabricated_fields_are_enumerated` |
| "AEF does not invent lanes or participants" | rail 487, verbatim — **not independently verified by us** |
| OBS-205 / OBS-206 | rail 487; our analogues **unchecked** |
