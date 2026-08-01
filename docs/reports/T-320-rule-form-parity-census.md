# T-320 — Rule-form parity census

**Date:** 2026-07-31
**Task:** T-320 (build)
**Predecessor:** T-317 (`W-XML-GW-AMBIGUOUS`), which fixed one instance of this class
**Peer:** AEF is sweeping the same class on their side (rail 354); method posted at
rail 355 before results, deliberately, so neither side inherits the other's blind
spot in the method rather than in the code.

## The class

`tools/validate-workflow.py` carries two validators: `Validator` (canonical YAML
form) and `XmlValidator` (BPMN form). A rule that exists on one form and not the
other means files on the unguarded form can sit in `fixtures/valid/` asserting a
cleanliness **nothing ever evaluated**.

T-317 found this the expensive way: `investigate.bpmn` had silently dropped both
gateway conditions its YAML twin carries, and the only rule describing that defect
had no counterpart on the form the file was written in. Not "the check was
missing" — the check *could not exist* on that form, so the file's presence in
`valid/` was evidence of nothing while reading as evidence of correctness.

## Discriminator

Asymmetry is **not** the finding. The question is whether the other form carries the
**construct** the rule describes:

| | verdict |
|---|---|
| asymmetric + construct absent on the other form | correctly out of scope |
| asymmetric + construct **present** on the other form | **GAP** |

Decided by measuring the corpus, not by taste — same method that settled T-317's
labelled-branch question at 0 of 113.

**Live-violation count is priority, not classification.** A gap with zero current
violations is still a gap: nothing prevents the next map from violating, and the
absence of a rule is what makes the absence of violations unfalsifiable.

### Correction — I got this wrong first, in writing

At rail 355 I offered `W-XML-LANE-GEOMETRY` as the canonical example of *correctly
out of scope*, on the grounds that "YAML carries no coordinates." **That is false.**
The canonical YAML form carries `x`, `y` on every node and `height` on every lane
(`examples/aef-processes/inception-lifecycle.workflow.yaml:48`). What I actually
had was an older measurement — *0 violations today* — which I collapsed into *out of
scope*.

Those are different claims and I merged them, which is precisely the error AEF made
at rail 354 in the other direction ("not in the latest tag" collapsed into "not
published"). Two independent instances of the same move, one week apart, in
opposite directions. It is worth naming as its own failure shape: **a measurement
that supports a weaker claim, silently promoted to a stronger one.** The measurement
was honest both times; the promotion was not measured at all.

Under the corrected discriminator, lane geometry is a GAP with 0 live violations —
not out of scope.

## Census

Rule ids extracted mechanically from the emit sites of both classes: **26 YAML
rules, 19 XML rules.** Eleven pair cleanly (dangling edge, gw-outgoing, uid-dup,
deadend, unreachable, the three parallel-gateway rules, structure, node-lane,
gw-ambiguous as of T-317).

Residue, measured over 25 canonical YAML maps and 96 authored BPMN files
(`.editor-versions/` history excluded — that is version churn, not authored content):

| rule family | direction | construct carried on other form | verdict | live |
|---|---|---|---|---|
| `E-CONST-DUP` / `E-CONST-SHAPE` / `W-CONST-FIELD` | YAML→XML | `aef:constituents`, **23/96** bpmn | **GAP** | not probed |
| `E-SCOPEOF-SELF` / `E-SCOPEOF-DANGLING` / `W-SCOPEOF-TYPE` | YAML→XML | `aef:scopeOf`, **0/96 authored — but in the shared vocabulary** | ~~out of scope~~ **GAP** (overturned, see below) | 0 |
| `W-IO-INPUT` | YAML→XML | declared io, **17/96** bpmn | **GAP** | not probed |
| `E-ABBR-DUP` | YAML→XML | lane `abbr`, **96/96** bpmn | **GAP** | 0 |
| `E-NODE-TYPE` | YAML→XML | typed flow elements, **96/96** | **GAP** | see below |
| `W-TYPE-LANE-MISMATCH` | XML→YAML | authority + task-type, **24/24** yaml | ~~GAP~~ **CLOSED T-322** | 0 |
| `E-INCEPTION-NOT-SOVEREIGN` | XML→YAML | ~~`workflowType=inception`, 2/24 yaml~~ **0/26 authored — in the canonical vocabulary** (corrected, see below) | ~~GAP~~ **CLOSED T-322** | 0 |
| `W-XML-LANE-GEOMETRY` | XML→YAML | node `y`, **24/24** yaml | **GAP** | 0 |
| `W-XML-LANE-CAPACITY` | XML→YAML | lane `height` + `y`, **24/24** yaml | **GAP** | 0 |

> ### 2026-08-01 — the headline above was wrong, and so was the discriminator (T-322/T-323)
>
> Corrected count: **nine gap families, and ZERO are correctly out of scope.**
>
> **The discriminator.** This census said: measure whether the *other form carries
> the construct*, and that got operationalised as **a corpus count** — does any
> authored file contain it today. But this same document insists a corpus count is
> **priority, never classification**: *"a gap with zero violations is still a gap;
> the missing rule is exactly what makes the missing violations unfalsifiable."*
> I applied that to the GAP rows and not to the OUT-OF-SCOPE rows. The discipline
> was itself one-form-only — applied to one half of its own table.
>
> **`scopeOf` overturned, decisively.** `aef:scopeOf` is in the shared canonical
> vocabulary (`tools/yaml-to-bpmn.py` `META_KEYS`; designer `metaKeys`,
> `src/aef-workflow-designer.html:9283`) and the bridge emits it as
> `<aef:meta scopeOf="…">`. Same map, both forms — a `subProcess` whose `scopeOf`
> points at itself:
>
> | form | verdict |
> |---|---|
> | YAML | `ERROR [E-SCOPEOF-SELF]` rc=2 |
> | BPMN, bridged from those bytes (`scopeOf="n_capture"` present) | `VALID — no findings` rc=0 |
>
> So the one family this census called correctly out of scope is a **GAP**. The
> corrected rule: **out-of-scope means the other form CANNOT EXPRESS the
> construct**, decided by the schema / shared key vocabulary — not by whether
> anyone has authored one yet. The probes in `tests/test_rule_form_parity.py`
> therefore interrogate the wrong object: they walk the corpus, so a
> classification flips only *after* someone authors a violating file, which is
> precisely too late. **T-323** repairs the discriminator and the probes.
>
> **Second, smaller error, in the row that motivated the task AEF ranked highest.**
> The `E-INCEPTION-NOT-SOVEREIGN` row read *"`workflowType=inception`, 2/24 yaml"*.
> Measured: **zero of 26** `.workflow.yaml` carry `workflowType` at all. The two
> carriers are `tests/fixtures/aef-bpmn/{inception-gonogo,two-lane-joint}.bpmn` —
> XML files, i.e. the rule's **own** form. I counted carriers on the wrong side of
> the comparison the column exists to make. The GAP classification survives
> (`workflowType` is in the canonical vocabulary) but for a different reason and
> off a different number.
>
> Both errors are the same family as the lane-geometry slip corrected above:
> [[measurement-promoted-past-its-scope]]. Posted to AEF at rail 359 before they
> ran their own one-form-only sweep, so they would not inherit the discriminator.

The gap runs in **both** directions, which I did not expect. `W-TYPE-LANE-MISMATCH`
and `E-INCEPTION-NOT-SOVEREIGN` — the IW-9 authority rules, the ones that decide
whether an inception is sovereign — exist on the XML form and have **no counterpart
on the canonical YAML form at all.** That is the governance-bearing half.

**Closed by T-322 (2026-08-01).** Both rules now emit from `Validator` as well,
off module-scope `AUTHORITY_OWNER` / `TYPE_PERFORMER` tables the two classes share
so the authority collapse itself cannot drift. Fixtures cover both forms — the same
map, bridged, yields the same rule id and the same exit code on each. The guard
gained a `PAIRED (same id, both forms)` classification that is *enforced*: deleting
either half now fails it. Before that it did not — the deletion mutation ran green,
because the surviving XML half kept the id alive and the stale-entry check only
fires when no validator emits it at all. A parity claim nothing enforces is the
same false green this census exists to remove.

## `E-NODE-TYPE`: the gap, and why the naive fix is wrong

**The gap, proven by mutation on a real fixture.** Renaming one element in
`tests/fixtures/valid/investigate.bpmn` from `<bpmn:serviceTask>` to
`<bpmn:serviceTaks>` — a plain typo — yields:

```
INFO  [I-XML-LANE-CAPACITY-SKIP] lane 'agent': lane capacity not evaluated: no
      occupancy is known for node type(s) serviceTaks, ...
VALID  ...bogus.bpmn -- no findings, 1 note(s)
rc=0
```

`VALID`, exit 0. There is no node-type vocabulary gate on the XML form.

The only witness is an **INFO note from the lane-capacity rule** — a rule about band
heights, on an unrelated subject, which noticed only because T-313 built it to
refuse to guess an occupancy it does not know. The unevaluable-must-be-visible
discipline leaked a signal that a vocabulary rule should have raised. Worth keeping
as an argument for that discipline: it produced a detector for a defect class nobody
was designing for.

**Why porting `NODE_TYPES` verbatim would be wrong.** The two forms' vocabularies
genuinely differ. The XML form accepts three flow-element types the YAML vocabulary
cannot express at all:

| element | occurrences | files |
|---|---|---|
| `intermediateCatchEvent` | 10 | 5 |
| `intermediateThrowEvent` | 7 | 3 |
| `boundaryEvent` | 2 | 1 |

All deliberate — `bare-catch-event.bpmn` (T-308), the T-257 eventdef round-trip
pair, `boundary-events.bpmn`, `s4-exemplar.bpmn`. A parity fix that copied
`NODE_TYPES` across would hard-fail eight of our own fixtures, several of which
exist precisely to exercise these types. The XML vocabulary must be a **declared
superset**, not a copy.

This is the case that justifies the whole "measure before porting" posture: the
rule is genuinely missing, *and* the obvious way to add it is wrong, and only the
measurement distinguishes those.

Secondary observation, not chased here: a BPMN carrying a `boundaryEvent` has **no
expressible canonical YAML twin.** Whether that round-trip hole is known and
intended is a separate question from this census.

## What this leaves behind

The classification table is not a document that goes stale — it is enforced by
`tests/test_rule_form_parity.py`, wired into the gating runner:

1. Rule ids are extracted from the emit sites, never hand-listed, so the census
   cannot drift from the code.
2. Every rule must carry a classification. A rule added to either form without a
   parity decision fails the build, naming it.
3. **`OUT_OF_SCOPE` entries are re-measured every run.** `scopeOf` is out of scope
   because 0 of 96 files carry it; the day one does, the classification is no longer
   true and the guard goes red. A classification that was true when written and is
   false now must not keep passing.
4. `GAP` entries print a NOTE every run and their count is asserted — a counted
   tolerance, in a place that still executes. (T-317's tolerance counter had been
   sitting in a *completed* task's Verification block, where it had silently stopped
   running; the half that made it a tolerance rather than a suppression list was
   gone. AEF is checking their own tolerances for the same shape.)
5. Unevaluable is red: if either validator class cannot be located, or yields zero
   rules, the guard raises rather than passing quiet.
