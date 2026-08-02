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

### 2026-08-01 — IW-1b RESOLVED (T-325): the axis is derivable from the frozen standard

IW-1b listed three options and called them unpriced: (i) detect dialect per document and suppress,
(ii) classify each rule universal vs dialect-relative, (iii) surface everything and let the author
filter. Option (iii) was already rejected on the 47-of-48 number. Option (ii) is now built.

**The discriminator, and the trap it had to avoid.** The obvious way to decide "is this rule
dialect-relative" is to measure how differently it fires across the two corpora. That is precisely
the T-323 mistake one level up: the T-320 census classified rules OUT-OF-SCOPE on a corpus zero and
was wrong, because absence from a corpus is not inexpressibility. **A corpus count is priority,
never classification.** A firing-rate table is especially seductive here because it looks so much
like evidence for exactly this question.

The classification is instead derived from `docs/standards/aef-bpmn-mapping-v1.md`:

- **PRESENTATIONAL** — every carrier the predicate reads is in §1's Presentational class. §1 is
  normative: *"A change to a presentational attribute alone MUST be a no-op for the task graph."*
  Such a rule cannot be reporting a task-graph defect, whatever else it usefully reports.
- **DIALECT-RELATIVE** — the predicate fires on the **absence** of a carrier the standard does not
  mandate. Absence is conformant, so firing separates authoring convention from correctness.
- **UNIVERSAL** — everything else: graph structure any conformant document must satisfy, or a
  carrier constrained only *when present*, or a MUST-emit carrier (whose absence is itself the
  violation — PL-035).

**Polarity is the hinge, and it is mechanical.** `W-GW-AMBIGUOUS` fires when the branch condition is
ABSENT; `W-PGW-CONDITION` reads the same carrier and fires when it is PRESENT on a parallel branch.
Same carrier, opposite polarity, opposite class — a map that never writes a condition can never trip
the second one.

**Result — 46 rules: 39 universal, 3 dialect-relative, 4 presentational.**

| class | rules |
|---|---|
| DIALECT-RELATIVE | `W-GW-AMBIGUOUS`, `W-XML-GW-AMBIGUOUS`, `W-IO-INPUT` |
| PRESENTATIONAL | `W-XML-LANE-GEOMETRY`, `W-XML-LANE-CAPACITY` + their two skip-notes |

`W-IO-INPUT` was not on anyone's list and is the same shape as the gateway pair: it demands an
upstream `io.outputs` entry matching by name, so a corpus that declares `io` only where it is
consumed lights up. Two independent instances, found by the discriminator rather than by the
symptom, is the argument that the discriminator is doing work.

**The gateway rule fires on documents that satisfy the frozen standard — that is a defect in the
rule, not a quirk of the peer.** mapping-v1 §5 defines an exclusiveGateway's branches as *"outgoing
edges = branches; edge label = condition"*; forward-compile §3.1 admits *"branch label /
`conditionExpression`"*. Both carriers are standard-admitted; ours demands one of them. The sharpest
evidence is in our own tree: `tests/fixtures/warn/W-XML-GW-AMBIGUOUS.xml` labels its branches
`name="code"`, `name="design"`, `name="environment"` — AEF's dialect exactly — and we ship it as the
fixture that demonstrates a warning.

**Enforcement.** `tests/test_rule_dialect_axis.py`, wired into the gating runner (bridge 63 → 64).
Rule enumeration is single-sourced from the T-320 parity guard's extractor, so the two axes can
never disagree about which rules exist. The classification is *computed* from a declared
`(carrier, polarity)` pair rather than written down per rule, and the carrier map is drift-guarded
bidirectionally against §1 — a rule whose class was simply asserted would be the unfalsifiable-PAIRED
trap again.

Polarity is made falsifiable **behaviourally**: for a REQUIRES rule, adding the carrier to the real
fixture must silence it; for CONSTRAINS, removing it must. The transform's direction is checked
against the declared polarity (counted on a comment-stripped copy — the fixture explains itself by
naming `conditionExpression` in prose, which is the G-009 class), so flipping a label fails rather
than quietly computing a different class. Teeth proven by four mutations on the real tree — dropped
declaration, mis-declared carrier, flipped polarity, carrier map moved off the standard — each RED,
tree restored byte-identical. Six negative controls run every pass, including "an unreadable frozen
standard must RAISE, not pass quiet".

**Firing-rate cross-check — priority evidence, and it is not the classification.** Naming the
subject of each number (G-013):

| population | files | findings | of which dialect-relative |
|---|---|---|---|
| 832-authored (25 rendered BPMN + 25 YAML) | 50 | **0** | 0 |
| AEF bytes in `tests/fixtures/aef-bpmn` | 20 | 34 | 6 |
| AEF bytes in `build/aef-corpus-drop` | 24 | 1 | 0 |
| AEF live corpus (**their** measurement, rail 356) | — | 47 of 48 gateways | 47 |

Our own zero **discriminates nothing for this question** — it is consistent with the rules being
universal and with their being dialect-relative, so it is not evidence either way. The two AEF
populations we hold disagree with each other (34 findings vs 1), which is itself the point: both are
blends whose proportions are an artifact of which files happened to round-trip through our bridge.
The only clean foreign-dialect measurement is AEF's own, and it is not reproducible from here.

**A hole in the frozen standard, surfaced by the derivation.** §1 opens *"Every `aef:` datum is
exactly one of two classes"* — but `aef:laneMeta`'s attributes appear in neither list, though
`height` and `abbr` are both read by live rules. §3/O-3 does rule normatively on `authority`, so
that one is covered elsewhere. The two uncovered carriers are declared, printed every run and
count-asserted rather than absorbed into whichever class made the arithmetic work. **This is a
ratification question for the operator and the rail, not something to settle here** — the standard
is frozen and not editable under agent control.

**Consequence for the surfacing work.** IW-1b resolves to option (ii), and the answer to IW-3 falls
out of it rather than needing its own ruling:

- **UNIVERSAL** (39) — surface normally; advisory per the Authority Model, ERROR/WARN as graded.
- **DIALECT-RELATIVE** (3) — must not be surfaced as correctness on a foreign map. Either suppressed
  or re-labelled as a convention note. The honest fix for the gateway pair is upstream of the
  designer: the rule should accept the standard's other carrier.
- **PRESENTATIONAL** (4) — a separate channel from correctness, and a natural fit for the existing
  Clean-layout nudge, which is the house pattern for advisory layout feedback and is already proven
  not to annoy.

### 2026-08-02 — IW-2 priced (spike 2). The decision stays the operator's; the numbers were missing

Pricing, not deciding. Every number below is measured against the tree at `f03002b`; where something
is unmeasured this section says so rather than estimating it.

**The port surface is a quarter the size everyone has been quoting.** IW-2 and the Technical
Constraints both frame this as "the rules are Python" — 46 rules, 1636 lines. But the designer
authors the **BPMN form**, so only `XmlValidator` is in play:

| span | lines | rule ids |
|---|---|---|
| `Validator` (YAML form) | 614 | 28 |
| `XmlValidator` (BPMN form) | 681 | **20** |
| CLI entry / render / format detect | 341 | — |

**A-3 is now measured rather than assumed.** The whole 1636-line file contains exactly one `open()`,
at line 1601 inside `main()`. No `os`, no `subprocess`, no network, no filesystem reach from any rule
body — imports are `argparse`, `json`, `sys`, `xml.etree`, `yaml`. The rules are pure functions over
a parsed tree. The editor already builds an equivalent tree (`src/aef-workflow-designer.html:9596`,
`DOMParser.parseFromString`) in its own import path, so a port has both a target and a host.

**Route (c) "one shared rule spec" cannot express this rule set, and would decay into route (a).**
Counting constructs inside `XmlValidator`: 4 worklist/BFS traversal sites, 5 adjacency
constructions, 4 reachability set-arithmetic sites, and 41 geometry-arithmetic sites. The
reachability rules (`W-XML-UNREACHABLE`, `W-XML-DEADEND`) and the lane rules
(`W-XML-LANE-GEOMETRY`, `W-XML-LANE-CAPACITY`) are imperative algorithms over a graph, not
predicates over attributes. What *is* already declarative is T-325's `(carrier, polarity)`
classification — genuinely shareable, and it is the metadata layer, not the predicates. Sold as "one
spec" this route silently becomes *a spec for the easy rules plus a second implementation for the
rest*, which is route (a) carrying an extra artifact.

**Route (b) "sidecar HTTP" is mechanically cheap and serves the wrong population.** The sidecar
already exposes 7 routes and `POST /api/save` already receives BPMN text, so `/api/validate` is the
same shape — hours, not days. The cost is not effort, it is reach: since 0.3.0 every released
artifact is a **single self-contained HTML file with zero external references**
(`dist/aef-workflow-designer-0.3.0..0.7.1.html`), and that is the artifact AEF pins and opens from
the filesystem. So route (b) delivers validation to the population whose maps we have measured at
**0 findings** (832-authored, 50 files) and withholds it from the population measured at **34
findings** here and **47 of 48 gateways** in their own corpus. The feature would be absent exactly
where it fires.

**The drift argument is real, and it is ours — we already ran the experiment.** IW-2's comment worries
that "two implementations of one rule set is how they drift." We need not reason about it: this
repository *is* that experiment. `tests/test_rule_form_parity.py` reports **46 rules classified, 11
gaps** — rules present on one form and absent on the other. T-323 emptied `OUT_OF_SCOPE_PROBES`, so
**zero of those 11 are explained by inexpressibility**; each is a rule the other form could carry and
does not. Two implementations, same language, same file, same authors, one rule set: 11/46 diverged.

**But name that number's subject before using it.** The 11 measures **coverage** drift — *does a rule
exist on both forms*. It says nothing about **behavioural** drift — *do the two implementations agree
about when to fire*. Those are different defects and conflating them is the error class this arc
keeps paying for.

**And behavioural drift is not merely unmeasured — no instrument in the tree can see it.**
`extract_rules()` (`tests/test_rule_form_parity.py:255`) regex-extracts rule ids from each class's
source span; it never validates a document. T-323's PAIRED enforcement strengthened *id* pairing.
So `W-GW-AMBIGUOUS` and `W-XML-GW-AMBIGUOUS` could carry different predicates indefinitely and every
gate in this repository stays green. This is the arc's own lesson landing on our own guard: **teeth
prove a guard fires, never what it discriminates — and parity proves a rule exists, never that it
agrees.**

A clean-corpus comparison cannot close this: IW-5 measured 0 findings on both paths, and 0-vs-0
discriminates nothing (the same trap already recorded at "our own zero discriminates nothing"). The
populations that *do* fire (AEF bytes) exist only in BPMN form, so there is no paired population that
fires. Measuring agreement therefore needs constructed documents driven through `yaml-to-bpmn.py`,
which is a build task, not a paragraph.

**What this does to the three routes.** It does not pick one — that is the operator's call and it is
an architecture call. It changes what the choice is *between*:

- (a) **port to JS** — 681 lines / 20 rules, pure, with a host tree already parsed; reaches every
  usage mode including the peer's; adds a third implementation of a rule set whose second
  implementation has 11/46 coverage drift and whose behavioural agreement is currently unobservable.
- (b) **sidecar HTTP** — cheapest to build, one implementation, and structurally absent in the
  standalone artifact the peer actually uses.
- (c) **shared spec** — expressible for the T-325 classification layer, not for the traversal and
  geometry predicates; as a whole-rule-set answer it is route (a) with an extra artifact.

**The prerequisite that falls out, and it is independent of which route wins.** A cross-form
behavioural agreement harness — one document, both forms, compare findings — is (i) the only thing
that makes route (a) safe rather than merely cheap, (ii) unnecessary for route (b) *only* because
route (b) declines to serve the peer, and (iii) **valuable today regardless**, because it would test
the Python pair we already ship and hand to AEF. Filed separately rather than folded in here.

**Probe for an actual divergence — null, and the null is the interesting part.** Having claimed
behavioural drift is *unobservable*, the next question is whether it is *actual*. The paired gateway
rules read the same carrier by different tests:

| form | test | site |
|---|---|---|
| YAML `W-GW-AMBIGUOUS` | `not e.get("condition")` — **falsy** | `validate-workflow.py:417` |
| XML `W-XML-GW-AMBIGUOUS` | `flow.find(...conditionExpression) is None` — **existence** | `validate-workflow.py:949` |

An edge whose condition is *empty* is therefore unconditioned on the YAML form and conditioned on the
XML form — the same map, two verdicts. But before treating that as a finding, the question this arc
exists to ask: **can either emitter produce that document?** No. Both are truthiness-gated —
`if e.get("condition"):` (`yaml-to-bpmn.py:342`) and `if (e.condition)` (`aef-workflow-designer.html:9539`).
And the corpus agrees: **0 empty `conditionExpression` elements across the 100 files that carry one.**

So this is not "the implementations disagree" and it is not "the implementations agree" — it is
**latent divergence**: two predicates that differ, separated by a document no current emitter emits.
It is invisible to the parity guard (id-level), unexercised by the corpus (nothing produces the
separating input), and it goes live the moment either emitter starts writing an empty element. Note
the designer's *import* already normalises toward it — `condEl` present sets `edge.condition = ""`
(`:9856`), which the export then drops — so the two sides of the round trip already disagree about
whether that element exists.

Recording the null honestly matters more than the candidate did. A corpus zero here means *this
divergence is not currently exercised*; it does not mean the implementations agree. That is the same
inference the T-320 census got wrong in the other direction, and the reason `OUT_OF_SCOPE_PROBES` is
now empty.

### 2026-08-02 — IW-1a priced (spike 3): **can a finding be pointed at?**

IW-1a has been sitting as a taste question — gutter markers, an on-demand panel, or a save-time
gate — and taste is the wrong instrument, because two of those three options require every finding
to name a thing that **exists on the canvas at a position**. That is a property of the emitter and
the renderer, not of anyone's preference, so it is measurable before the argument starts.

**Method.** Two populations, deliberately separated.

- **(A) Capability** — every `self.err/warn/info` call site read out of `tools/validate-workflow.py`
  by `ast`, classified by *what its `location` string names*. Read from source, because a shape no
  document happens to trigger is still a shape the designer would have to render. The classification
  table is total and explicit: an unlisted rule id is a hard error, never a silent default (T-333).
- **(B) Occupancy** — every finding actually emitted over 25 corpus BPMN + 22 BPMN fixtures, with
  the id inside each `location` **resolved against the document it came from**.

Scope is `XmlValidator` alone — **23 distinct rule ids** — because IW-2 already fixed the port
surface there; the 34 `Validator` (YAML) call sites are not in the form the designer holds.

**The `location` field is prose, not a reference.** `"node 'wrk_2_context'"`, `"lane '%s' -> lane
'%s'"`, `"<bpmn:laneSet>"`. Any surface that points at something has to parse it back out. That is
not fatal, but it is a cost that belongs to every option except the panel, and it is invisible until
you look.

| anchor class | rules | what the canvas can do with it |
|---|---|---|
| **NODE** | 12 | id → element carrying `<aef:position>` — a marker can sit on it |
| **LANE** | 3 | id → band — a marker can sit on its header |
| **LANE-PAIR** | 1 | `W-XML-LANE-GEOMETRY` names **two** lanes; which one carries the marker is undecided |
| **DOC** | 3 | no id interpolated at all — nothing on the canvas to point at |
| **VALUE** | 2 | a *duplicated* id: resolves to ≥2 elements, so "the" anchor does not exist |
| **REFERENT** | 1 | names the id the rule asserts **does not resolve** |
| **DROPPED** | 1 | resolves in the document and is still not on the canvas |

**15 of 23 are gutter-able; 8 are not.** But the split by severity is the result that actually
decides IW-1a:

| severity | gutter-able | not | share a gutter would hide |
|---|---|---|---|
| ERROR | 4 | 6 | **60%** |
| WARN | 10 | 1 | 9% |
| INFO | 1 | 1 | 50% |

**A gutter would show the author the advice and hide the errors.** The six ERROR rules with nowhere
to land are `E-XML-STRUCTURE`, `E-XML-LANES-EMPTY`, `E-XML-ID-DUP`, `E-XML-UID-DUP`,
`E-XML-LANEREF-DANGLING`, `E-XML-FLOW-DANGLING` — the structural ones, which is to say the ones you
would most want to block a save on. This is not a coincidence: a finding is anchorable when the
document is well-formed enough to have the element the finding is about, and the ERROR rules are
precisely the ones that fire when it is not.

**Two mechanisms produce an unanchorable finding, and they are different.**

- `E-XML-LANEREF-DANGLING` (REFERENT): the id genuinely does not resolve — 5 witnesses in
  `bare-catch-event.bpmn`. The canvas can only show the *referrer* (the lane), and the location
  string never names it.
- `E-XML-FLOW-DANGLING` (DROPPED): the id **does** resolve — the `sequenceFlow` element is right
  there in the XML — and the edge is still not on the canvas, because `renderEdges`
  (`src/aef-workflow-designer.html:3501-3504`) does `const src = findNode(e.source); … if (!src ||
  !tgt) continue;`, and `findNode` (`src:2499`) matches on `uid`, which a dangling `targetRef` never
  becomes. **Resolving against the document scores this one gutter-able, and that is wrong — the
  document is not the canvas.** The renderer's own defensive skip is what removes the carrier.

**Two rules degrade to a placeholder.** `E-XML-NODE-TYPE` and `E-XML-AUTHORITY` build their location
as `"… '%s'" % (el.get('id') or '?')`. The element that lacks the identifier the canvas addresses it
by is exactly the malformed element the author most needs pointed at, and it is the one the location
cannot name. (The YAML side is worse — 22 of 34 sites use a `loc` that starts life as
`"nodes[%d]" % i`, an index into the source array, and is upgraded to `node '<uid>'` *only if the
node has a uid*.)

**How much of this is verified, and how much is my reading.** The corpus cannot answer this question
at all: 25 documents, **7 findings, 1 rule**, 24/25 clean. A percentage computed over it would be a
corpus zero wearing a measurement's clothes. Adding the 22 BPMN fixtures gets 34 findings across 9
rules. So:

- **9 rows confirmed** by resolving real findings against real documents — 9 agree, **0 disagree**.
- **3 more rows witnessed** by scratch probes built for this spike (a dangling `targetRef`, a
  duplicated `bpmn:id`, an emptied `laneSet`), confirming `DROPPED`, `VALUE` and `DOC` respectively.
- **11 rows rest on reading the location expression alone.** They are declared, not measured. The
  headline 15/23 is a source-derived count; treat the 11 as the part that could move.

**Correction, same session — that "11 unverified" was itself a measurement scoped by an accident,
and it is the finding above happening to me one level up.** My denominator was *BPMN files on disk*.
`tests/test_harness_cross_form_agreement.py` drives every YAML fixture through
`tools/yaml-to-bpmn.py` and validates the result with `run_xml` — **BPMN documents that exist only in
memory, produced on every gating run**. Re-resolving the anchor table against those bridged
documents: 29 fixtures bridged, **19 XmlValidator rules witnessed, 19 agree, 0 disagree, 10 of them
rows I had just called unverified.**

**The table is 22 of 23 verified, not 12.** The one that remains is `E-XML-STRUCTURE` (root element
is not `<bpmn:definitions>`) — and it is unmeasured for a structural reason, not a missing fixture:
no emitter in the tree produces a document with the wrong root, so it is the same *unreachable
witnessing state* as `E-LOAD` in T-333. A missing witness and an impossible one look identical until
you ask which.

The error direction was over-pessimistic, which is the safe way to be wrong — but the mechanism was
identical to `E-XML-FLOW-DANGLING`: I queried the artifact that happened to be lying around rather
than the one the property lives in. **I posted the finding to the rail and then committed it in the
same instrument.** One row is also weaker than the tally suggests: the acceptance predicate for
`VALUE` only checks that the duplicated id resolves to *something*, not that it resolves to **≥2**
elements, which is the property that makes the class distinct. Counted as verified; read as
partially verified.

**The nag budget (A-2), such as it is.** Over the fixtures: 13/22 clean, mean 3.8 findings on a
dirty document, max 10. But findings cascade — the single duplicated-id probe produced four
findings (`E-XML-ID-DUP`, two `E-XML-FLOW-DANGLING`, one `E-XML-LANEREF-DANGLING`) from one
malformation. A live surface would show four problems where the author made one mistake, and the
three derived ones are all in the unanchorable classes.

**Consequence for IW-1a.** The options are not interchangeable and the measurement ranks them:

1. **A panel can carry all 23 rules.** It is the only option with no anchorability precondition, and
   the only one that can show a finding about an element the canvas has dropped.
2. **A gutter/inline surface can carry 15 of 23 — and it inverts severity**, showing 91% of the
   warnings and 40% of the errors. Shipping it alone would be a surface whose coverage is worst
   exactly where the stakes are highest.
3. **A save-time gate covers exactly what the gutter cannot**: the six structural ERRORs are the
   findings with no canvas anchor, and a gate needs none. This makes IW-1a and IW-3 **complements
   rather than alternatives** — the earlier note that "the class decides the channel" now has a
   second axis, anchorability, that points the same way.

What this does **not** decide: whether the panel is live or on-demand (A-2 is still untested), and
whether the gate blocks or advises — that is the Authority Model question, and it is the operator's.
Nothing here has been built; the spike is measurement only.

## Recommendation

*(still empty as a whole-feature recommendation. **IW-1a is now priced, not decided**: a panel is the
only option that can carry the whole rule set, a gutter inverts severity coverage, and a save-time
gate is the complement of the gutter rather than a rival to it — the choice among them is a product
call reserved to the operator. IW-2 is **priced but undecided**: the routes carry measured costs and
the choice between them is an architecture call, also the operator's. IW-3 no longer needs a separate
ruling — the class decides the channel, and anchorability now points the same way. IW-4 is closed:
T-319 DECLINED on measurement, so the rule set needs no addition before the surface work.)*
