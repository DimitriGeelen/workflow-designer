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
  for two months, inside bytes AEF pins by sha, and the deferral was never
  collected. That is a gap, not just a task.

Either answer changes the recommendation. **IW-1 is not closed by this spike; it is
re-aimed.** What the spike established is that the reason is *recorded* — which is
what I said I would not assume either way.

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
of adoption. Spike 3 is incomplete: `anchors` and `aef:waypoint` are not yet
classified as result-or-intent.

---

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
   change bytes → coordinated re-pin with AEF; the standard gains a carrier it
   does not name, which is additive rather than contradictory.
3. **Retire `aef:position`** — needs a T-225 scope ruling, a v1.1 standard
   revision, and an answer to the intent-expressiveness gap in spike 3.

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
