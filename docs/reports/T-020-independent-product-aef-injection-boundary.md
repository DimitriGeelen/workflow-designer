# T-020 — Independent-product AEF injection-point boundary (inception)

```yaml
status: exploring            # exploring | decided
type: inception
recommendation: GO           # agent advisory; Sovereign decides
decision: pending            # go | no-go | defer — Sovereign-reserved
authored: 2026-07-02
owner: human                 # foundational product-strategy decision
relates: [T-002, T-017, T-018, T-019]
```

> **This is an inception / exploration task.** No build artifacts are produced
> under T-020. The output is this research artifact + a Sovereign go/no-go.

## The one question

**Is the seam between the Workflow Designer as an *independent product* and AEF
clean enough to build against — and if so, where exactly are the injection
points?**

- **GO** → the boundary is clean; mature the product standalone, with
  AEF-aware injection stubs, then integrate to the framework later.
- **NO-GO / redirect** → the coupling to AEF is irreducible; integrate directly
  (the r3 Process-layer route) instead of maturing independently.

The *direction* (independent product first) is the Sovereign's stated intent
(2026-07-02). This inception validates the assumption that direction rests on
(clean seams exist) and produces the seam catalog + maturation outline as design
inputs. It does not re-open the direction.

## Strategy under evaluation

> "prepare an independent product, mature it with placeholders for injection
> points of AEF, then go to framework; reflect, incept if sensible, push back if
> desirable." — Sovereign, 2026-07-02

Restated: build the designer as a self-contained product with usable value on
its own, expose **defined seams** where AEF later plugs in, mature it against
real use, and only then bring it to the framework for integration.

### The framing fork (lead open question — IW-1)

"Independent" has two readings; they lead to very different products:

| Reading | What it means | Assessment |
|---|---|---|
| **A. Implementation/packaging independence + AEF-aware seams** *(recommended)* | No runtime dependency on `fw`/framework internals; runs standalone; but the *domain* stays AEF (swimlanes = authority model) and seams are anchored to AEF's known integration surface | Keeps the differentiation; preserves portability; integration is low-rework because seams match a known contract |
| **B. Domain-neutral BPMN tool** | A generic workflow editor with AEF as one optional plugin among many | Throws away the core differentiation (the authority-model swimlanes, the AEF-typed I/O); larger surface; weaker product. Not recommended |

**Recommendation: Reading A.** Push-back registered if the Sovereign intends B —
that is a materially larger and, in my read, weaker bet. **This is the single
most decision-shaping fork and needs Sovereign confirmation before Lock-1-style
build slices.**

## Why GO is credible (evidence)

1. **A working injection point already exists.** T-017/T-018 shipped
   `tools/validate-workflow.py` deliberately standalone — "not wired into the
   vendored `fw` CLI … the framework can later adopt it as `fw workflow
   validate`." The validator/judge seam is proven, not hypothetical.
2. **Hand-usability is established.** T-002 GO rested on the designer being
   usable before any AEF runtime exists — independence is already true of the
   core artifact (`src/aef-workflow-designer.html`).
3. **The integration surface is mapped.** The r3 Process-layer spec (stored at
   `docs/proposals/aef-workflow-process-layer-2026-07-02/`, evaluated in T-019)
   enumerates what AEF will want. Seams can be anchored to that contract instead
   of guessed — this is what keeps "independent" from becoming "divergent."

## Candidate AEF injection points (seam catalog — IW-2, to be validated)

Each is a place the *product* defines an interface/stub and AEF later supplies
the implementation. Anchored to the r3 spec sections.

| # | Seam | Product side (independent) | AEF side (later) | r3 anchor |
|---|---|---|---|---|
| S1 | **Validation / judge** | standalone `validate-workflow.py` (exists) | adopted as `fw workflow validate`; +v3 rules | §2.4 |
| S2 | **Canonical file + schema version** | YAML canonical, `schema_version` field | v3 schema, migration | §2.1 |
| S3 | **Executor / run hook** | *placeholder only* — no execution; a documented "run boundary" | `fw workflow run` (strict mode) | §0.3, §3.3 |
| S4 | **Governance status fields** | `status`/`ratified_by` present but inert (advisory) | ratify/deprecate lifecycle + gates | §2.1, §3.2 |
| S5 | **Component references** | optional `components:` refs, unresolved = advisory note | Component Fabric resolution + drift | §2.5 |
| S6 | **Human touchpoint routing** | `humanTouchpoint` metadata carried, not routed | Watchtower surface wiring | §2.1, §3.3 |
| S7 | **Interchange** | BPMN import/export (T-018 covers XML validation) | framework interchange fidelity | §2.3, Lock 2 |
| S8 | **Composition** | `callActivity`/link-event *schema* support, structural validation only | Workflow Fabric graph | §2.3, §2.6 |

The pattern throughout: **carry the metadata, validate the structure, stop at
the execution/resolution boundary.** The product is a complete *authoring +
validation* tool; AEF supplies *execution + resolution*. That boundary is the
injection line.

## Maturation-slice hypothesis (independent product → framework-ready)

Not a commitment — a strawman roadmap to pressure-test in the inception:

- **M1** — validator to v3-schema parity for the structural rules (build on
  T-017/T-018): startEvent/endEvent rules, cross-file uid uniqueness,
  callActivity acyclicity, humanTouchpoint↔edge coverage. *(standalone)*
- **M2** — canonical YAML round-trip + schema-version handling; BPMN bridge
  fidelity (round-trip test like the bundled `roundtrip.js`). *(standalone)*
- **M3** — define + document the seam interfaces (S1–S8) as an explicit
  "AEF integration contract" doc — the placeholder spec AEF will implement.
- **M4** — product usability hardening (library/open-save, lens rendering as
  read-only views) — value that stands without AEF.
- **M5** — *only then* the framework hand-off: the integration contract (M3)
  becomes the pickup to the framework agent.

## Assumptions to validate

- **A-1**: A clean authoring/validation ↔ execution/resolution boundary exists
  (the injection line above holds without leaks). *Falsifiable by finding a seam
  that cannot be stubbed without an AEF runtime.*
- **A-2**: Anchoring seams to the r3 spec keeps integration low-rework (the spec
  is a stable-enough contract). *Risk: SD-1..15 are all OPEN; the contract may
  shift.*
- **A-3**: Reading A (AEF-aware independence) is the intended meaning of
  "independent." *Sovereign-confirmable only.*

## Go/No-Go criteria

**GO if:** the seam catalog holds (every AEF touch reduces to a stub-able
interface at the authoring/execution boundary) **and** the Sovereign confirms
Reading A.

**NO-GO / redirect if:** one or more seams cannot be stubbed without embedding
AEF runtime (coupling is irreducible) **or** the Sovereign intends Reading B /
direct framework integration.

## Recommendation

**GO** on Reading A, with the seam catalog above as the design skeleton. Rework
risk is managed by anchoring to the r3 contract; the biggest open variable is
the Sovereign's intent on the framing fork (A vs B) and the fact that SD-1..15
remain OPEN (the anchor contract is a proposal, not ratified).

## Dialogue Log

### 2026-07-02 — strategy set + inception opened
- **Sovereign:** having evaluated the r3 Process-layer package (T-019), do NOT
  go straight to framework. Prepare an independent product, mature it with AEF
  injection-point placeholders, then go to framework. "reflect, incept if
  sensible, push back if desirable."
- **Agent reflection:** affirmed the strategy as Directive-4 (Portability) and
  Directive-1 (Antifragility) aligned, and noted we already started it (the
  standalone validator). Push-back: (1) anchor seams to the r3 contract so
  "independent" != "divergent"; (2) name the A-vs-B framing fork and recommend A
  (implementation independence + AEF-aware seams, not domain-neutrality).
- **Outcome:** filed this inception (T-020), recommendation GO, decision
  reserved for the Sovereign. Framework-integration pickup remains on hold —
  now *deliberately* deferred behind product maturation, consistent with the
  earlier "hold."

## Open questions for the Sovereign

1. **IW-1 Framing fork:** confirm Reading A (recommended) vs Reading B.
2. **IW-2 Seam catalog:** is S1–S8 the right injection set, or are there seams
   I've missed / over-reached on?
3. **IW-3 Anchor depth:** given SD-1..15 are OPEN, how much should we anchor to
   the r3 contract now vs treat it as provisional?
```
