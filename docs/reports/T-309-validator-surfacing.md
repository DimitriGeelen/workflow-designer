# T-309 — Surfacing validator findings in the designer: exploration

**Task:** T-309 (inception) · **Opened:** 2026-07-29 · **Status:** frame filled, exploration not yet run

Written per C-001: the artifact is created before the research and grown as findings arrive. What is
below the line is what has actually been established; everything else is still a question.

## The one question

The workflow validator's rules already exist and are already trusted. Should they reach the person
authoring a map in the designer — and if so, where, how, and with what authority?

## What is already established (before any exploration)

These were verified while filing the task, not assumed:

1. **The rules exist on both serialization paths.** `tools/validate-workflow.py` has two validator
   classes — `Validator` (YAML, from line 101) and `XmlValidator` (BPMN, from line 644). Rules
   observed: `E-GW-OUTGOING` (exclusiveGateway needs ≥2 outgoing, ERROR), `W-GW-AMBIGUOUS` (>1
   unconditioned outgoing edge), `W-PGW-CONDITION` (condition on a parallel fork — "did you mean an
   exclusiveGateway?"), `W-PGW-NOOP`, `W-PGW-UNBALANCED`, `W-UNREACHABLE`, `W-DEADEND`, plus
   constituents and required-I/O checks. The validator suite is green at **34 passed, 0 failed**, and
   its test names confirm the XML mirrors carry the same rule ids (`W-XML-PGW-CONDITION`,
   `W-XML-UNREACHABLE`, …).

   *Correction worth recording:* an initial reading of this — from seeing `healing-loop.bpmn`
   validate clean while its YAML source also validated clean — suggested the BPMN path lacked the
   semantic rules entirely. That was wrong. Running the validator suite showed the XML mirrors are
   present and tested; `healing-loop` is simply clean, because its only gateway has two properly
   conditioned outgoing edges. The gap is reach, not coverage.

2. **The editor has no validation surface.** A grep of `src/aef-workflow-designer.html` for
   `validate` returns only unrelated hits (a zoom-mechanism comment, waypoint invalidation, a routing
   bounding-box helper). Nothing calls the validator; nothing displays a finding.

3. **"Nodes need at least one connection" is already covered.** An orphan node trips both
   `W-UNREACHABLE` (not forward-reachable from any startEvent) and `W-DEADEND` (no endEvent reachable
   backward). `linkEventCatch` is seeded as an additional forward entry point and `linkEventThrow` as
   a backward terminus, so off-page connectors do not false-positive.

4. **The triggering example is NOT caught by any current rule.** `fw_3_failure` — an
   `exclusiveGateway` labelled "failure type?" with six outgoing branches (external, dependency,
   unknown, design, environment, code) all targeting the single node `fw_4_lookup`. Exclusive is the
   semantically correct gateway here: a failure has one type, and a parallel gateway would activate
   all six branches at once. The smell is the immediate reconvergence — six branches that differ in
   nothing downstream are a data field, not a decision. No rule covers "XOR whose outgoing flows all
   share one target".

5. **The map is not ours.** `fw_3_failure` does not appear anywhere in this repo. Neither do
   `aef-task-lifecycle`, `aef-tier0-escalation` or `draft-knowledge-leveling`; our corpus carries the
   unprefixed `task-lifecycle` and `tier0-escalation`. These are AEF-authored maps reaching us
   through the gallery, so any rule that fires here fires on peer content — a rail conversation under
   the T-559 contract+fixture seam, not a purely local feature.

## Open questions

Filed on the task as IW-1..IW-5 (where findings surface / how the rules reach the browser / advisory
vs blocking / whether the missing rule is part of the deliverable / what the corpus baseline is).
Dispositions and evidence land here as the exploration runs.

**IW-5 is sequenced first deliberately.** If ordinary corpus maps already light up with warnings, the
feature is dead on arrival however well it is built, and every other question becomes moot. Measure
before designing.

---

## Findings

### IW-5 — corpus baseline (spike 1, run 2026-07-29)

**Question:** if the validator's findings were surfaced in the designer today, how much would light up?
If ordinary maps are noisy, the feature is dead on arrival.

**Answer: nothing lights up. 112 maps, zero findings, both paths.**

| Population | n | Findings | Note |
|---|---|---|---|
| `examples/aef-processes/rendered/*.bpmn` (XML path) | 24 | 0 | the shipped corpus |
| `examples/**/*.workflow.yaml` (YAML path) | 25 | 0 | canonical sources incl. app-processes |
| `.editor-versions/*/v*.bpmn` (XML path) | 63 | 0 | intermediate editor saves |

**The green is real, not a broken harness.** Control injection into `healing-loop.bpmn`
(PL-061 — a check that cannot go red is not evidence):

- drop one `<bpmn:sequenceFlow>` → exit 1, `W-XML-DEADEND` + `W-XML-UNREACHABLE` ✓
- drop one `<bpmn:flowNodeRef>` → exit 1, `W-XML-NODE-UNASSIGNED` ✓

**Caveat that limits how far this result travels.** All three populations are *committed or
saved* states — clean by selection bias, because they were tidied before they were written.
The population a designer-side validator actually runs against is mid-authoring: half-drawn
gateways, nodes dropped but not yet wired. The 63 editor-version snapshots are the closest
proxy we have and they are clean too, but they are still *saves*, not keystrokes. **The
zero-noise result is necessary, not sufficient.** It rules out alarm fatigue on finished work;
it does not establish the finding rate on work in progress.

### IW-5b — the two paths are NOT mirrors (correcting the correction)

The pre-exploration note above says "the XML mirrors carry the same rule ids". Measured, that
is **wrong** — and this time by counting rather than inferring. Of the rule ids emitted by the
two classes, only **7** are shared. Discounting the ids that are shape-checks with no
cross-format meaning (`E-NOT-MAPPING`, `E-TOPLEVEL-MISSING`, `E-*-FIELD` vs `E-PARSE`/
`E-STRUCTURE`) and naming-only differences (`E-EDGE-DANGLING` ↔ `E-FLOW-DANGLING`), three
**semantic** asymmetries remain:

| Rule | YAML | XML | Consequence |
|---|---|---|---|
| `W-GW-AMBIGUOUS` — XOR with >1 unconditioned outgoing | ✓ | **✗** | the designer's dialect cannot detect it |
| `W-XML-NODE-UNASSIGNED` — flow node in no lane | ✗ | ✓ | |
| `W-TYPE-LANE-MISMATCH` — task type vs lane authority | ✗ | ✓ | |

Empirically confirmed for the first row: stripping *every* `conditionExpression` from a corpus
map fires **nothing** on the XML path (exit 0), where the YAML path has `W-GW-AMBIGUOUS` for
exactly that shape.

**This reshapes the inception.** The designer speaks BPMN, so surfacing "the validator" in the
editor surfaces the XML rule set — which is missing precisely the ambiguous-gateway class that
prompted the operator's original gateway question. Rule *parity* is therefore not a nice-to-have
adjacent to the surfacing work; it is a prerequisite for the surfacing work to answer the
question that motivated it.

### IW-5c — a live operator mishap already has a rule (unsurfaced)

Operator screenshot (2026-07-29, map `pen_inbound_classifier`, ~53 nodes / 5 lanes) shows ~14
nodes rendered **below every lane band**, plus long trunk edges running the full canvas width
back up to them. The map is not reachable from here — absent from our corpus, from our gallery
(`/api/list`, 6 maps) and from AEF's (11 maps) — so this is read off the screenshot, not validated.

Two candidate causes, and they differ in whether tooling can already see the defect:

- **(a) nodes in no lane's `flowNodeRef`.** Already detected: `W-XML-NODE-UNASSIGNED`, verified
  by injection above. The editor renders them silently.
- **(b) nodes assigned to a lane but positioned outside its y-band** (lane height not grown to
  fit content). **No rule covers this** — it is geometry, not graph structure, and the validator
  is a structural checker by design.

Discriminating test needs the map bytes. If (a), this is the strongest single argument for the
feature on the table: a rule that already exists, already passing its tests, would have named
the operator's actual defect at authoring time. If (b), it is out of the validator's scope
entirely and belongs to the layout track.

### 2026-07-31 — IW-1b: findings are DIALECT-RELATIVE, and this changes the feature's shape

Arrived from outside the inception, via the peer rail (AEF 356) while T-320 was running. It is
the most consequential finding on this page and it was not on the question list.

`W-XML-GW-AMBIGUOUS` (T-317) does not measure gateway correctness. It measures **which
toolchain wrote the file.** Same predicate, three populations, subject named:

| corpus | gateways ≥2 outgoing | firing | flows carrying `conditionExpression` |
|---|---|---|---|
| 832-authored (`examples/*/rendered`, 25 maps) | 53 | **0** | 117 / 327 |
| AEF bytes as they sit in our fixture tree (21 maps) | 18 | 7 | 24 / 198 |
| AEF live corpus (their measurement, rail 356) | 48 | **47** | **0 / 381** |

Rows 1 and 3 are the two clean dialects, maximally separated. We express branch semantics in
`conditionExpression`; they express it entirely in `name=` ("yes — status: issues", "blocked —
unchecked AC"). Neither is wrong. Row 2 is **neither dialect** — it is a blend, because some of
those AEF files have round-tripped through our bridge or designer, which emit
`conditionExpression` on export. Any measurement taken over the fixture tree describes a
mixture whose proportions are an artifact of which files happened to pass through our toolchain.

**Consequence for this inception, and it is not small.** The premise of T-309 is that an author
opens a map and sees what is wrong with it. An author who opens an *AEF* map in our designer
today would be shown **47 warnings on a map that is correct by the conventions it was written
under**, with no way to know that. For the cross-toolchain case this feature exists to serve,
that is worse than shipping nothing: it trains the author to dismiss the panel, and by AEF's
L-527 a rule that gets tuned out is weaker than no rule, because its silence stops meaning
anything.

So IW-1 ("where do findings surface") splits:

- **IW-1a** — surface: panel / inline / gutter. Unchanged, still unpriced.
- **IW-1b (NEW)** — findings must carry a notion of which dialect they are evaluating, or the
  surfacing must. Options not yet priced: (i) detect dialect per document and suppress
  dialect-relative rules on foreign maps; (ii) classify each rule as universal vs
  dialect-relative in the validator (the T-320 `PARITY` table is the obvious place, it already
  classifies every rule and is enforced every run); (iii) surface everything and let the author
  filter — rejected on the 47-of-48 number, that IS the do-nothing option.

**This is a prerequisite, not a refinement.** IW-3 asked "advisory or blocking". The answer for
a dialect-relative rule is neither until IW-1b is settled: a rule that fires on 98% of one
peer's corpus cannot be blocking, and as advisory it is noise. Pricing IW-2 (delivery route)
before IW-1b would be pricing the wrong thing.

**Method note worth keeping.** This did not come from a spike. It came from posting a method to
a peer *before* running it and being told the measurement backing it had scanned one side of a
two-sided dialect. The rail has now produced this twice in two days in both directions; neither
side has found its own instance.

## Recommendation

*(empty — no recommendation until the spikes above have run. Filing-time advisory was GO on the
problem being worth solving; that is not a substitute for a priced recommendation. IW-1b now
sits ahead of IW-2 in the ordering.)*
