# T-357 — Adopt BPMN DI as the designer geometry? (inception research)

**Status:** exploration in progress. No decision recorded. No build artifact produced.
**Filed recommendation at inception time:** GO (on *exploring*, not on executing).

> **C-001 compliance note, stated rather than hidden:** this artifact was created
> *after* spikes 1–2 ran, not before. The protocol says the file comes first and is
> updated incrementally. The spikes were four greps and two file reads, so nothing
> was lost — but the sequencing was wrong and is recorded here rather than tidied
> away.

---

## Spike 1 — Why does `aef:position` exist? (IW-1)

**The answer is neither of the two possibilities I registered.** I registered
"a bridge constraint" or "DI judged too heavy for the yaml round trip", and
explicitly refused to assert "oversight". It is none of those three.

`src:9406-9407`, verbatim:

```js
const DI_TRAILER_PREFIX = 'BPMN DI (visual layout) omitted';
const DI_TRAILER = `${DI_TRAILER_PREFIX} in this demo; AEF generates it from node coordinates`;
```

and `src:9582` emits it into **every document the designer exports**:

```
<!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->
```

So `aef:position` was never intended as a *replacement* for DI. It was intended as
the **input to DI generation**, with generation **delegated to AEF**. The
disposition of IW-1 is therefore:

> **DI omission was a deliberate demo-stage deferral with a named downstream owner,
> not an oversight and not a constraint.**

Two properties of that sentence matter more than the sentence:

1. **"in this demo".** This is seed-stage scaffolding. It entered the canonical
   tree in `61242508` (T-012, 2026-06-05, "Promote designer artifact + docs into
   canonical `src/`") — `git log --follow` finds no earlier commit, because the
   artifact was promoted wholesale from `zzz-seed-design-files/`. The deferral has
   been in the shipped export path for two months and across **ten releases**
   (`dist/` 0.1.0 → 0.8.0 all carry the string).

2. **It is an unverified claim about a peer project, shipped inside our bytes.**
   Every `.bpmn` file we have ever exported asserts that AEF generates DI from our
   node coordinates. **I have never checked whether that is true**, and under the
   T-559 boundary I cannot check it from here — only AEF can answer it.

### The part that makes this more than trivia

The trailer has **already caused a cross-project incident**, and the incident did
not surface the problem above.

`src:9409-9421` — `readDocComment` explicitly refuses to treat the trailer as the
document's doc block, and the comment above it records why: hoisting our
boilerplate to the top and *"promoting that to rationale is the exact defect that
poisoned their corpus"*. AEF fixed their reader (their T-2682) and restored two
promoted maps from git history (T-2683); `src:9400-9405` is our half.

So this comment has been under **direct, two-party scrutiny**, with an incident
report on each side — and both investigations asked *where the comment appears*.
**Neither asked whether the sentence it contains is true.** The scrutiny landed on
the right artifact and answered a different question about it.

That is a distinct failure shape from the ones already catalogued on this arc, and
worth naming: **an artifact can be examined closely, by both parties, and come out
of the examination with its central claim still unexamined — because the incident
that drew attention to it was about a different property.** Attention is not
coverage, and an incident directs attention rather than distributing it.

**Open, and now the sharpest question on this task:** does AEF generate DI from
`aef:position`? Asked on the rail.

- If **yes** — the pipeline works as designed, the defect is narrower than T-340
  claims (our exports are DI-less only until AEF processes them), and the honest
  T-357 framing becomes "should the *designer* also do what AEF already does?"
- If **no** — the trailer has been shipping a false statement about the pipeline
  for two months, inside bytes ~~AEF pins by sha~~ **[T-475: not these bytes. AEF's six
  digest-guarded artifacts include two of ours — `typed-events`, `boundary-events` — and
  neither is export-path output, so the trailer does not ride in anything they pin. The
  false statement is still shipping; the aggravating clause was wrong.]**, and the deferral
  was never collected. That is a gap, not just a task.

Either answer changes the recommendation. **IW-1 is not closed by this spike; it is
re-aimed.** What the spike established is that the reason is *recorded* — which is
what I said I would not assume either way.

### IW-1 ANSWERED — and it was answered before this paragraph was last edited (T-478, 2026-08-13)

**The answer is NO. AEF does not generate DI from our node coordinates.** Two
independent lines, both already in the record:

1. **AEF said so, rail offset 497:** the sentence `AEF generates it from node
   coordinates` is *"a false sentence about my project [that] has been sitting in 17 of
   my documents as my content."*
2. **Their importer says so in its own words.** At offset 449 we measured that AEF's
   import path does not preserve our trailer — it **replaces** it:

       LOST : <!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->
       NEW  : <!-- BPMN DI (visual layout) omitted; node geometry travels as aef:position -->

   Their replacement describes **transport**, not generation. That is their code's own
   account of what happens to the geometry.

Registered: **A-020 (`AEF generates BPMN DI from our aef:position`) — `invalidated`.**
`src` was corrected by **T-361**: `DI_TRAILER` now reads *"node geometry travels as
aef:position"*, with a comment recording the old sentence was *"AT BEST aspirational for
two months."*

**So why did this paragraph still say "Open, the sharpest question on this task"?**
Because the answer went to the places where work feels finished — the code, and the
assumption register — and **the document that poses the question is in no fix's blast
radius.** Worse, at offset 523, *after* AEF's answer at 497, we posted to them that
*"A-020 [is] still open on your side — whether you generate DI from our coordinates."*
We re-asked a question that had been answered six offsets earlier.

That is a distinct mechanism from the stale-frontmatter class (PL-171): nothing decayed
here. **An answer arrived as a subordinate clause in a message about a different subject,
and was never filed against the question it answered.** A question's carrier is not
updated by fixing the thing the answer implies.

### The consequence T-361 did not reach: the generator was fixed, the generated was not

Measured 2026-08-13, whole populations, no sampling:

| population | carries the false sentence |
|---|---|
| `src/` | **0** — corrected by T-361 |
| `examples/aef-processes/rendered/*.bpmn` | **24 of 24** |
| `examples/app-processes/rendered/*.bpmn` | 0 of 1 (`customer-refund.bpmn`) |
| `dist/` releases | 11 of 13 |
| corpus documents carrying the *corrected* trailer | **0** |

**Those 24 are the arc's 24 corpus maps** — the same population T-101 rewrites and T-423
was costed against. Every one still asserts a false statement about a peer project, and
17 of them have been imported into AEF's corpus where the sentence now reads as *their*
content.

**A cheap correction may already be scheduled.** The emit site (`src:9710`) interpolates
`${DI_TRAILER}`, which is now the corrected constant — so **if T-101 re-exports the 24
maps through the designer's `buildBpmnXml`, all 24 are corrected as a side effect.** If
T-101 instead patches coordinates in place with a script, they are not. **That is a
mechanism choice worth making deliberately before T-101 runs, not discovering after** —
it is the difference between this defect closing for free and persisting through the one
operation that touches every affected file.

`dist/` releases are immutable historical artifacts and are out of scope for correction.

---

## Spike 2 — Who reads `aef:position`? (IW-2)

Tree-wide, outside `src/` and `dist/`, the substantive hits are:

| consumer | relationship |
|---|---|
| `tools/yaml-to-bpmn.py` | writes it (forward compile) |
| `docs/standards/aef-bpmn-mapping-v1.md` | **names it in the frozen two-party standard** |
| `examples/aef-processes/inception-review.workflow.yaml` | data |
| episodic/handover/task files | history, not consumers |

The standard is the finding. `docs/standards/aef-bpmn-mapping-v1.md:42-45`:

> **Presentational (diagram cosmetics):** `aef:position`, `aef:anchors`,
> `aef:endpoint`, `aef:waypoint`, `aef:routing`, `aef:routingHint`,
> `aef:forceStraight`, `aef:loopDetour` … The reverse compile MAY write these
> (layout) but **MUST treat them as derived, never authoritative**. A change to a
> presentational attribute alone MUST be a no-op for the task graph.

This cuts **both ways**, and both directions are load-bearing:

**For adoption.** The frozen standard already declares this geometry *derived and
never authoritative*, and mandates that changing it alone is a no-op for the task
graph. Swapping the carrier from `aef:position` to `bpmndi` is precisely such a
change. **The standard does not merely permit the swap — it pre-authorises the
class of change the swap belongs to.** A-3 ("no consumer treats it as a contract")
is therefore *ratified*, not merely expected. Stronger evidence than I anticipated.

**Against adoption, or at least against costing it as a code change.** The standard
**enumerates `aef:position` by name**. Adoption makes that enumeration stale, and
the standard is frozen: Part I must not be edited under agent control, and it is a
two-party artifact. So adoption's cost includes **a v1.1 standard revision
negotiated with AEF**, not just an editor change. My inception-time rationale
listed the seam cost as "re-pin `source_bpmn_sha` fixtures". That undercounted.

---

## Spike 3 — Can DI express what we persist? (IW-3) — PARTIAL, and the answer is *no*

The inception was framed as `aef:position` vs `bpmndi`. That framing is too small.
The standard's presentational list is **eight** elements, and all are live in `src`:

| symbol | occurrences in `src` |
|---|---|
| `routingHint` | 22 |
| `anchors` | 19 |
| `forceStraight` | 12 |
| `loopDetour` | 9 |
| `aef:waypoint` | 1 |

DI maps the *results* cleanly — `dc:Bounds` for shape geometry, `di:waypoint` for
edge geometry, label bounds for labels. It is genuinely richer than `aef:position`
for all of those.

**But `forceStraight`, `routingHint` and `loopDetour` are not geometry — they are
layout *intent*.** They are inputs to the routing engine that produced the
waypoints, not a record of where the edge ended up. DI has no vocabulary for
intent, by design: it is an interchange format for *computed* diagram state.

Consequence: **DI cannot be a drop-in replacement for the presentational family.**
The realistic shapes are (i) emit DI *and* retain the intent extensions alongside
it, or (ii) accept that re-opening a saved map re-derives routing from waypoints
and loses the author's stated intent on the next layout change.

This is the first finding that pushes toward NO-GO on the *maximal* form — and it
should be watched carefully, because **the last time I let a property of a maximal
variant settle a whole option, I was wrong** (T-340 option (b); RAIL-416). Recorded
here as bounding the *scope* of adoption, explicitly **not** as a disqualification
of adoption.

### Spike 3 completed 2026-08-12 (T-477) — both remaining elements are intent

`anchors` and `aef:waypoint` were left unclassified. Both are now classified, against a
criterion fixed **before** looking: an attribute is a *computed result* iff its value is
recoverable from the rendered geometry alone; it is *authored intent* iff it survives as
an input that changes what geometry gets recomputed on the next layout pass.

**`aef:anchors` (sourcePort/targetPort) — INTENT.** All 19 `anchors` sites enumerated.
Every write is a user gesture: endpoint drag onto a port (`:3737-3738`), properties-panel
select (`:5282/:5287`), drag-snap (`:6526/:6534/:6537`), reverse-edge port swap (`:5358`),
explicit reset to `auto` (`:3760-3761`), plus construction (`:8042-8043`) and file
read-back (`:10126-10127`). It is emitted **only when the port is not `auto`**
(`:9674-9682`) — i.e. only when the author actually pinned it. Not recoverable from
geometry: an edge meeting a node's left side looks identical whether the author pinned
`left` or the router chose it, and the two behave differently on the next pass because
the router branches on `auto` (`:3524`, `:3570`).

**`aef:waypoint` — INTENT, and the sharper of the two.** Author-placed bend points:
created by drag-insert (`:6447-6448`) and moved by drag (`:6441`). They **override** the
router — proven by `:7836-7844`, which temporarily clears `edge.waypoints` so the router
computes *"the natural polyline rather than honoring stale overrides"*, then restores
them. They are cleared wholesale whenever the geometry they were authored against stops
holding (`:3740`, `:3762`, `:5283-5345`, `:6528`, `:6539`, `:8104`, `:8122` — *"old
waypoints made sense for the old geometry"*).

There is **no router→waypoint path at all**: the only function that computes corners for
assignment to `edge.waypoints` (`currentRenderedMiddleCorners`, `:7828`) has **zero
callers**. Its doc comment (`:7821-7827`) describes assigning router output to
`edge.waypoints` — so reading the comment alone yields the *opposite* classification.
The caller census is what settled it. (Recorded because it is this arc's recurring shape:
a comment describing a mechanism that no longer has a caller.)

### The consequence, which is worse than "no DI equivalent"

Spike 3's original finding was that DI has no vocabulary for intent. For `aef:waypoint`
the problem is not absence but **false equivalence**: `di:waypoint` carries the same
`x`/`y` values, so a swap *looks* lossless. But `aef:waypoint` records **only the
author's middle overrides**, while `di:waypoint` records the **entire computed polyline**.
Round-tripping through DI would promote every router-computed corner into an author
override — silently freezing every edge's route, so the router stops adapting on the next
layout change.

**A missing carrier fails loudly; a false equivalent round-trips clean and changes the
meaning.** That is the more dangerous of the two, and it was invisible while the element
sat unclassified.

**Revised tally of the eight-element presentational family:** `routingHint`,
`forceStraight`, `loopDetour`, `anchors`, `waypoint` = **five are intent**; `aef:routing`
is their container; **`aef:position` is the only true computed result**. Spike 3 costed
depth 3 on three-of-eight. It is five-of-eight, plus one false equivalent.

**`aef:endpoint` is not presentational at all** — see §"Standard defect" below. It is
excluded from this tally.

---

## Standard defect found while completing spike 3 (T-477, 2026-08-12)

Classifying the family required reading the frozen standard's presentational list
element by element. It names **`aef:endpoint`** as "diagram cosmetics".

**`aef:endpoint` is not cosmetic. It is the executable command a task node runs.**

- `src:1867` — the properties-panel field: `{ label: 'Endpoint', hint: 'fw … | agent
  prompt | watchtower view', textarea: true }`
- `src:1790-1805` — offered on `serviceTask`, `userTask`, `scriptTask`, `subProcess`,
  alongside `tier`, `agentType`, `contextReads`, `artifactsWrites`
- `src:1958-2019` — seed data holds real commands, e.g.
  `endpoint: 'fw context build --task ${task_id} --depth 2'`
- `src:9286` — emitted as a standalone `<aef:endpoint>` element, immediately beside
  `aef:contextReads`, `aef:artifactsWrites`, `aef:decisionInput/Outputs`
- `tools/yaml-to-bpmn.py:56` — the bridge lists `endpoint` in **`META_KEYS`**, i.e. treats
  it as a governance meta-key

So **both** reference implementations treat it as semantic, and the standard's own §1
semantic class covers "the scalar governance meta-keys" — which the bridge's `META_KEYS`
defines, and which contains `endpoint`. The standard contradicts itself about this one
element **within a single section**.

**Why it is consequential, not pedantic.** §1 says presentational content is "derived,
never authoritative" and "a change to a presentational attribute alone MUST be a no-op
for the task graph." A conforming consumer is therefore **entitled to discard
`aef:endpoint`** — silently dropping the command from every service task in a map. That
is the opposite of a no-op.

**Probable cause — a name collision, not a judgment error.** The editor uses "endpoint"
for two unrelated things: the *edge-endpoint drag handle* (genuinely presentational —
`edgeDrag.kind === 'endpoint'`, `.edge-handle-endpoint`, 80+ sites) and the *node's
command field* (semantic — 1 site). Anyone enumerating presentational concerns would meet
the drag-handle sense dozens of times first. The list is right about the word and wrong
about the element.

**Not fixed here, deliberately.** `docs/standards/aef-bpmn-mapping-v1.md` Part I is frozen
and two-party; it must not be edited under agent control, and §"Versioning & change
control" requires a version bump plus a conformance-test update. Registered as an
observation and raised with AEF on the rail. **The correction is a v1.2 item for the
operator and AEF, not for this task.**

### Severity, measured (T-479, 2026-08-13): LATENT, not live — but unguarded

OBS-039 established an *entitlement* to discard. Whether anything *does* was measured by
executing the round trip in the real editor (`tools/_t479-endpoint-roundtrip-cdp.mjs`),
not by reading code:

    population : 30 documents carrying >=1 <aef:endpoint>   (examples/ + tests/fixtures/)
    endpoints  : 155 in  ->  155 out
    lossy      : 0
    control    : fired (one endpoint stripped from a real document was detected as lost)

**No commands are being lost today.** The editor's parse→build preserves every endpoint,
value included. So the v1.2 correction is a calm fix, not an incident.

**But nothing is watching it.** The strongest guard we have —
`_roundtrip-serialization-cdp.mjs`, the only true semantic fixed-point test — projects a
fixed `METAKEYS` list and **`endpoint` appears nowhere in that harness**. Presentational
content is excluded from the projection *by design*, following the standard's classes. So
**the misclassification has already propagated out of the standard and into our
verification: the one guard that would catch endpoint loss is configured not to look.**

That is the same shape AEF reported this round in their own guard — a defect encoded in a
passing test, which no scan finds because the suite defends it. Here it is milder: nothing
is broken, but a future regression that drops `aef:endpoint` would be **silent**. Filed as
its own item; adding `endpoint` to the projection is a fix and belongs to a fix task.

**Closed by T-480 (2026-08-13).** `endpoint` is now projected by the round-trip semantic
fixed point, in **both** `METAKEYS` definitions (the guard's and its preflight self-test's
— patching only one would have left the guard asserting a property its own teeth-proof
never exercised, the fix-one-of-N trap AEF reported at rail 588).

Falsified both ways by mutating an emitted `aef:endpoint` value:

    PRE-change    projEqual = True    <- drift invisible to the projection
    POST-change   projEqual = False   <- caught, drift localised at the endpoint value

**The counterfactual nearly reversed the conclusion.** Both runs *also* reported
`deterministic = False`, so the pre-change mutant **exited red** — which reads as "the old
harness caught it, the fix was unnecessary." It did not: the determinism flag broke because
the mutation edits `emit1a` after `emit1b` was computed, an artifact of the probe, not a
detection. **Judging on the exit code would have retired a real fix.** The verdict had to be
read off the specific signal the change was about.

**Census of what the round-trip fixed point still does not project** (so the follow-up is
scoped, not guessed): `contextReads`, `artifactsWrites`, `decisionInput`, `decisionOutputs`,
`io`, `link` — six structured semantic elements the editor parses and re-emits. They are
**not** unguarded overall: `test_editor_bridge_field_coverage.py` (T-059) guards the
editor↔**bridge** axis, and `test_editor_bridge_structured_parity.py` (T-063) covers a
different set (`emits`, `compensates`, `aggregation`, `multiInstance`, `timer`). What no
guard covers for these six is the **editor's own parse→build round trip**. Filed for a
follow-up; not folded in here (one bug = one task).

**Probe honesty note.** The first form of this measurement reported
`tests/fixtures/aef-bpmn/offpage-seam.bpmn` as **lossy**. It was not: that endpoint
contains `->`, which the fixture carries unescaped and the editor re-emits as `-&gt;`.
Semantically identical, textually different — the comparison was on raw serialized text,
so it was comparing *encodings*, not values. **That false positive was one step from being
reported to AEF as data loss in a fixture they pin.** Fixed by decoding entities before
comparison; the corrected probe is what produced the numbers above.

Scope note: this is outside T-477's stated scope (classify `anchors` and `waypoint`). It
is recorded rather than pursued, per "one bug = one task".

## Spike 4 — T-225 compatibility (IW-4)

**The principle splits the task in half, and it has never been exercised on the
half that matters here.**

The ratification is invoked at exactly **four** sites in `src`:

| site | what it protects | kind |
|---|---|---|
| `8201` | a resolved uuid is never written back into `aef.targetWorkflow` | semantic |
| `9301` | the legacy `targetWorkflow` slug alias rides along on re-export | semantic |
| `9681` | T-337's preserve-and-re-emit of foreign flow-node tags | semantic |
| `9777` | the legacy `targetWorkflow` leg is not rewritten to `workflowRef` | semantic |

**All four are semantic. Zero are presentational.** In every case the principle is
invoked to justify *conservation* — the author's bytes keep saying what they said
unless the author changes them.

### First finding: the task decomposes, and only one half is in scope

- **Adopt** (emit DI; read DI when `aef:position` is absent) **is not a migration.**
  It adds a representation. Nothing the author wrote is rewritten or dropped.
- **Retire** (stop writing `aef:position`) **is exactly a silent migration** — a
  file that carried `aef:position` and no DI comes back carrying DI and no
  `aef:position`, on a save the author made for unrelated reasons.

T-357's title contains both verbs and they are independently decidable. Only
*retire* meets T-225.

### Second finding: the principle's scope over presentational content is stated, not tested

Two ratifications point in opposite directions on the same act:

- **T-225 (local, `src`):** *diagram XML is never silently migrated* → retiring
  `aef:position` on save is prohibited.
- **The frozen two-party standard (`aef-bpmn-mapping-v1.md:42-45`):**
  presentational content is *"derived, never authoritative"* and a change to it
  alone *"MUST be a no-op for the task graph"* → retiring `aef:position` is not
  merely permitted but pre-authorised.

They only conflict if T-225 reaches presentational content. **It never has.** The
principle was established over four semantic cases and is *worded* — "diagram XML"
— in terms that cover presentational content too. Whether it intends to has never
had to be answered, because until now nothing proposed changing presentational
content.

That is a **declaration scoped by its fixture**: a rule verified on one population
and phrased over a wider one. It is the same shape this arc has now hit repeatedly,
except the carrier this time is a *ratified principle* rather than a measurement —
which is worse, because a principle is quoted rather than re-derived, and three of
its four invocation sites are load-bearing code comments justifying live behaviour.

**Disposition:** IW-4 is **answered for the adopt half** (no conflict) and
**escalated for the retire half**. The retire half needs an explicit ruling on
T-225's scope. That ruling is the operator's and it is worth having on its own
merits, independent of this inception — the ambiguity is live right now, not
created by T-357.

---

## Running effect after spike 4

The recommendation is unchanged at **GO on exploring**, but the shape has firmed
considerably. What began as one question is now three, in increasing cost order:

1. **Read DI when `aef:position` is absent** — this is T-340 scoped (b). Byte
   neutral, no standard revision, no T-225 question, no seam event. Fixes the
   user-facing defect (a foreign author's diagram survives being opened).
2. **Emit DI additively, keep writing `aef:position`** — no T-225 question, no
   intent-expressiveness problem (the extensions stay). Costs: 24 corpus maps
   change bytes → ~~coordinated re-pin with AEF~~ **[CORRECTED 2026-08-12, T-475: there is
   no re-pin. AEF pins none of the 24 and holds no copy of the rendered corpus — measured
   on their side, rail 584 Q1/Q3. The surviving cost is one-party: our own `_t308`
   baseline goes 24/24 drifted.]**; the standard gains a carrier it
   does not name, which is additive rather than contradictory.
3. **Retire `aef:position`** — needs a T-225 scope ruling, a v1.1 standard
   revision, and an answer to the intent-expressiveness gap in spike 3.
   **[T-477, 2026-08-12 — the gap is bigger than costed here, and depth 3 alone is
   affected.]** Spike 3 costed this on three intent elements of eight; completing the
   classification makes it **five of eight**, and adds a failure mode that is not a gap
   at all: `di:waypoint` is a *false equivalent* for `aef:waypoint` — same values,
   different status — so a swap round-trips clean while silently freezing every edge's
   route. Depth 3 gets **more** expensive and less safe. **Depths 1 and 2 are untouched:
   both retain `aef:position` and the whole extension family alongside any DI, so no
   intent is lost at either. T-340's scoped (b) is unaffected — it reads DI, writes
   nothing, and moves no bytes.**

**Each is a strict subset of the next**, so none of the work is thrown away
whichever depth the operator picks. That is the useful result of this inception,
and it did not exist when the task was filed.

---

## Running effect on the recommendation

Still **GO on exploring**. Two changes to the *rationale*, both material:

1. The cost is higher than filed — it includes a **v1.1 revision of a frozen
   two-party standard**, not just fixture re-pinning.
2. The scope is larger than filed — the question is the **eight-element
   presentational family**, not `aef:position` alone, and part of that family has
   no DI equivalent.

Unchanged: **T-340's scoped option (b) is not blocked by any of this.** It is
byte-neutral, needs no standard revision, needs no AEF coordination, and remains a
strict subset of adoption.
