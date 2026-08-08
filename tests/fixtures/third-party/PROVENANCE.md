# Third-party-authored BPMN fixtures (T-356)

**These files were NOT written here, and that is the entire point.**

Before this directory existed, all 126 `.bpmn` files in the tree were produced by
this designer: **0 carried an `exporter=` signature and 0 carried `bpmndi:`.** Every
import-fidelity instrument we have was therefore measuring a population that could
not exhibit the defects it hunts — a capability zero wearing an occupancy zero's
clothes. See T-356, and T-340's severity rating, which was drawn from exactly that
census.

## Why these files are provably foreign

The test is a property no fixture we could write would honestly have — **the
exporting tool's own signature on `<definitions>`** — plus the absence of our
fingerprints. "Looks like bpmn.io output" is not evidence; a population built by
imagining what real input looks like is the same defect one level up.

| file | `exporter=` | `aef:position`/`aef:uid` | `bpmndi:` |
|---|---|---|---|
| `simple.bpmn` | `camunda modeler` 2.6.0 | 0 | 28 |
| `boundary-events.bpmn` | `Camunda Modeler` | 0 | 36 |
| `multiple-diagrams.bpmn` | `bpmn-js (https://demo.bpmn.io)` | 0 | 12 |
| `collaboration-message-flows.bpmn` | `camunda modeler` | 0 | 36 |
| `nested-subprocesses.bpmn` | `camunda modeler` | 0 | 48 |

## Why each one is here

Each fixture was chosen because it is a **real-world carrier of a population this
project has previously measured only synthetically**:

| file | population it makes real |
|---|---|
| `simple.bpmn` | DI present (T-340); also uses the `bpmn2:` namespace prefix where our corpus uses `bpmn:` — a prefix-sensitivity test nothing here has ever run |
| `boundary-events.bpmn` | boundary events + `attachedToRef` (T-339) |
| `multiple-diagrams.bpmn` | **multiple `BPMNDiagram` roots** — T-348's first-only read, from a real emitter rather than an injection |
| `collaboration-message-flows.bpmn` | **two pools + `messageFlow`** — T-348's "a two-pool collaboration opens and saves as ONE pool", which until now had no third-party witness |
| `nested-subprocesses.bpmn` | deep `subProcess` nesting; our importer flattens |

## Two fixtures deliberately NOT taken

`collaboration.bpmn` and `collaboration-vertical.bpmn` are the most direct
two-pool cases in the upstream suite and were the first two I wanted. **Both carry
no `exporter=` attribute**, so neither can prove it was tool-authored rather than
hand-written, and both were dropped. `collaboration-message-flows.bpmn` covers the
same population *and* carries a signature.

Recorded because the reasoning is the reusable part: the criterion has to be able
to reject a fixture you want, or it is not a criterion.

## Provenance

- **Source:** https://github.com/bpmn-io/bpmn-js — `test/fixtures/bpmn/`, ref `develop`
- **Retrieved:** 2026-08-03, verbatim via `curl`, unmodified (byte-for-byte as served)
- **Licence:** MIT — Copyright (c) 2014-present Camunda Services GmbH. Permission is
  granted to use, copy, modify, merge, publish and distribute, provided the
  copyright notice and permission notice are included. This file is that notice for
  the copies held here.

### Pinned digests

Re-fetch and compare before trusting any conclusion drawn from these files; an
upstream edit would silently change what the population means.

```
e9a1365895d516656ba0c96d19635d8741dc3fab2648edd3acc268509491dfcc  boundary-events.bpmn
aeaaaabac173064f40cc4683a3fb135157b98e2ee34058fd72dcdf9e03685068  collaboration-message-flows.bpmn
46aff94d202085d9025784fab1866eab8399bbfd3d470c7bd1d0fe3cb335bd31  multiple-diagrams.bpmn
b9227f15acfd06876d9a61488cb2984ba50eb281922ac1ae6b90873fb63c271f  nested-subprocesses.bpmn
48e0f2877bd5d1e947f424313cf6ad9822fcd852f6bb31ad6d7cda56f7c7546f  simple.bpmn
```

## What this directory does NOT yet establish

Adding fixtures is not the same as proving the population is **capable of failing**.
Until at least one of these is run through today's importer and shown to lose
content, this directory is an untested claim about coverage, and a green suite over
it would recreate the exact unreachable witnessing state T-356 exists to remove.

That measurement is T-356's second acceptance criterion. **If every fixture
round-trips clean, the correct conclusion is that the fixtures are unrepresentative
— not that the importer is sound.**

---

## Measured 2026-08-03: the population IS capable of failing

`node tools/_t356-third-party-fidelity-cdp.mjs` → **5 of 5 lose content**; positive
control (a designer-produced corpus map) clean. Full table and analysis in
`docs/reports/T-356-third-party-fidelity.md`. The "what this directory does NOT yet
establish" caveat above is now discharged.

## STANDING WARNING — these files are INPUTS ONLY

**`exporter=` is dropped by the round trip in all five.** The attribute that proves
these files are foreign does not survive the operation being measured. Round-trip
one of these fixtures and save it back over itself and it becomes indistinguishable
from a designer-produced map — the population silently reverts to the incapable
state T-356 exists to escape, and the census that would detect it
(`grep -c 'exporter='`) would still be counting the originals.

Never replace a fixture with its own round-trip output. The pinned digests above are
what catches it if someone does.

---

# Second intake, 2026-08-03 (T-347) — five more, for a DIFFERENT question

**The five above could not answer T-347.** Censused against its shapes they returned
all zeros: `documentation` 0, foreign `extensionElements` children 0, `property` 0,
loop characteristics 0. They were selected for "does a third-party document survive
structurally?" and are fit for that. **Capability is per-QUESTION, not per-population**
— T-356 succeeding cast a halo over neighbouring questions, produced *by* the fix, and
the halo had to be measured away rather than argued away.

Drawn from a survey of **467 `.bpmn` files** across `bpmn-io/bpmn-js`,
`bpmn-io/bpmn-moddle` and `camunda/camunda-bpmn-js`; 288 carried an `exporter=`
signature.

| file | signature | shapes it makes real |
|---|---|---|
| `kitchen-sink.bpmn` | `exporter="Camunda Modeler" 5.16.0-dev` | spec `property`, 4 `multiInstance` + 3 `standardLoopCharacteristics`, `zeebe:calledElement` — three shapes in one real export |
| `i18n-documentation.bpmn` | `exporter="Camunda Modeler" 4.8.0-rc.0` | `<bpmn:documentation>`, `modeler:` attributes |
| `zeebe-service-task.bpmn` | `exporter="Zeebe Modeler" 0.11.0` | deep `zeebe:` extension tree — `ioMapping`, `taskDefinition`, `taskHeaders`, `input`, `header` |
| `caseagile-local-ns.bpmn` | `exporter="Enterprise Composer" 1.0.11.0` | 45 `caseagile:property` children, `multiInstanceLoopCharacteristics`, **namespace declared on an inner element, not the root** |
| `bizagi-nested-ns.bpmn` | `xmlns:bizagi="http://www.bizagi.com/bpmn20"` + `<bizagi:BizagiExtensions>` | 8 `<documentation>`, nested vendor extension tree |

**Vendor spread is deliberately wider than the first intake**, which was entirely
Camunda Modeler and bpmn-js. Signavio, Enterprise Composer, Zeebe Modeler and Bizagi
are four vocabularies this project had never seen.

## The criterion was CLARIFIED, and the clarification was checked against the decision it could have overturned

The first intake's rule was worded *"the exporting tool's own signature on
`<definitions>`"*, and `exporter=` was the instance used. `bizagi-nested-ns.bpmn`
carries no `exporter=` — but it declares **the vendor's own namespace URI** and
carries vendor element vocabulary. That is the same class of evidence: a declared,
machine-written claim of origin no fixture we could write would honestly have.

**Loosening a criterion because it is blocking the result you want is the failure this
directory exists to prevent**, so the clarification was tested against the two files
T-356 rejected. `collaboration.bpmn` and `collaboration-vertical.bpmn` have **no
`exporter=`, no vendor namespace, and no vendor elements**. They remain rejected. The
clarification overturns no past decision.

## Rejected this intake — the criterion still bites

| file | carried | why rejected |
|---|---|---|
| `vendor/yaoqiang-event-definitions.bpmn` | `documentation` ×14, `property` ×7 | **ID prefixes only** (`Yaoqiang-ID_…`). No exporter, no vendor namespace. A naming convention is *resemblance*, and resemblance is what this criterion rules out. It was the single richest `documentation` carrier found and was dropped anyway. |
| `documentation.bpmn`, `documentation-extension-elements.bpmn` | `documentation` ×2 | Hand-written bpmn-moddle test fixtures. No provenance of any kind — exactly the population the criterion exists to exclude. |
| `extension/camunda/inputOutput-*.part.bpmn` | `camunda:` children | Fragments, not whole documents. Do not parse standalone. |

**Consequence, stated because it bounds a conclusion:** the rejected files are the
richest `documentation` carriers available (14 and 8 vs a maximum of 8 admitted, and
only 1 in the exporter-signed population). The criterion cost real coverage here. It
was still applied.

## Considered and deliberately not taken

- `bpmn-moddle/test/fixtures/bpmn/complex.bpmn` — a genuine **Signavio Process Editor
  6.2.1** export with 916 `signavio:` children and 4 loop characteristics. The most
  real-world document found. **Not taken on size**: 260 KB, ~7× the largest fixture
  here. Recorded rather than silently skipped — if the `extensionElements` repair ever
  needs a heavy real-world case, this is it.
- `extension/camunda/inputOutput.bpmn` — `exporter="camunda modeler" 2.5.0`, and
  interesting for declaring `xmlns:camunda="http://activiti.org/bpmn"`, the *activiti*
  URI under the `camunda` prefix. Coverage of nested extension trees is already
  carried by `zeebe-service-task` and `caseagile-local-ns` with live vendors.

### Pinned digests (second intake)

```
cf2e096a73984a690959b55614722f3195de31aa9d3e867a31302cbf2dfb9f85  bizagi-nested-ns.bpmn
fb9bbc8b7e2a32b95cca4bfa671dc26237cd4d45dbd471a881edee2c7e3acf34  caseagile-local-ns.bpmn
db93b7ed701c578bc59385f1c10bc152e410711529266950bcf4ec14c26dbb6a  i18n-documentation.bpmn
63c8a9d73ec6d20762d910922fffb268157f75af7b196822aef1eb791801206c  kitchen-sink.bpmn
e2b75352e08bdcbf234bab30653c13bf6973de56499061c672d9e25c5bdab5b7  zeebe-service-task.bpmn
```

Sources — `bpmn-io/bpmn-js` @`develop` `test/fixtures/bpmn/`; `bpmn-io/bpmn-moddle`
@`main` `test/fixtures/bpmn/` and `.../vendor/`; `camunda/camunda-bpmn-js` @`main`
`test/camunda-cloud/`. Retrieved verbatim via `curl`, unmodified. MIT, as above.

## Measured 2026-08-03: all ten lose content, and the STANDING WARNING now covers all ten

`_t347-accepted-element-content-cdp.mjs` — **every T-347 shape is LOST on 100% of the
files carrying it**, always to exactly zero. See
`docs/reports/T-347-accepted-element-content.md`.

`_t356-third-party-fidelity-cdp.mjs` — **10/10 lossy**, control clean. `exporter=` is
dropped on all five new fixtures too, **measured, not assumed by analogy**. The
inputs-only warning above therefore applies to this intake without exception.

`bizagi-nested-ns.bpmn` is the severest single row found so far: **`nodes 3→0`,
`flows 2→0`** — a document whose namespace is declared on an inner element rather
than the root loses its entire task graph.


## `aef-draft-inception-readiness-v2.bpmn` — foreign, but NOT by this directory's test (T-372)

**This file fails the "provably foreign" test every other fixture here passes, and it
is still foreign.** It carries 52 `aef:position`/`aef:uid` hits and no `exporter=`
attribute — by the table at the top of this file, that reads as *ours*. It is not.
AEF authored it, and they use the `aef:` namespace legitimately because they are the
project that defines it. The fingerprint test above assumes our namespace implies our
authorship; for the one peer who shares the namespace, that assumption is false.

So its provenance rests on different evidence, weaker in kind and stated plainly:
AEF published the bytes on the integration rail with a byte count and a digest, and
the file here matches both.

| property | value |
|---|---|
| origin | AEF (`999-Agentic-Engineering-Framework`), rail offset 445 |
| their name for it | `draft-inception-readiness` v2 |
| bytes | 18472 |
| sha256 | `fe3a520ddd51523e3cdd55da0aea428368a07b05e481246c837c6330d9c4a846` |
| retrieved | 2026-08-08, verbatim, unmodified |

The digest is asserted by `tools/_t372-aef-cycle-roundtrip.mjs` before it measures
anything, so a silent edit here fails the probe rather than quietly changing what the
round-trip result was about.

**Population it makes real:** a **cross-lane cycle** — an `exclusiveGateway` with three
outbound edges, two of them return edges, one re-entering a *collapsed* `subProcess`
in a different lane, spanning all three lanes. Nothing else in the corpus carries a
cycle that crosses lane boundaries, and `nested-subprocesses.bpmn` covers nesting but
not re-entry.

**Measured 2026-08-08 (T-372): 7/7 claims survive the round-trip**, each proven to go
red under a targeted mutation. The one comment in the file is lost — but it is a
*trailer* (after `</bpmn:process>`), which T-311 refuses by design, and our emitter
writes its own in that slot. A count-based check reads `1 in, 1 out` and calls that
preservation; it is substitution.
