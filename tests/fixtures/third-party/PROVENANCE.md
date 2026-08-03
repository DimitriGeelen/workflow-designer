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
