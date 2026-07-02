# INGESTION-workflow-process-layer-2026-07-02.md

```yaml
status: proposed
authored: 2026-07-02
audience: framework agent (Claude Code) + Sovereign
package: aef-workflow-process-layer-package-v1-2026-07-02
binding_notes:
  - Research is not authorization. This package authorizes Step 0 (read-only
    discovery) and Step 0.5 (paper exercise) ONLY, upon Sovereign dispatch.
  - No implementation, no repo modification beyond the three deliverable
    notes named in §4, until Sovereign disposition of the decision register.
  - Producer-not-judge: nothing in this package is self-certifying.
```

## 1. What this package is

Design bundle for the AEF **Process layer** — proposed as the third
foundational core concept (Governance / Value / **Process**), pending
Sovereign confirmation (SD-1). It contains the full specification, design,
architecture, and phased build instructions for turning a proven prototype
into a governed AEF subsystem, plus the prototype itself as reference
implementation and evidence.

The Process layer serves four purposes (INSTRUCTIONS §0.1):
- **P1** design substrate — flows designed functionally/logically/technically
  in one governed artifact with per-audience lenses
- **P2** systematic documentation of business and application logic
- **P3** procedural guardrail — workflows enforce at the procedure level what
  verb gates enforce at the action level (contextual authority envelopes)
- **P4** crystallization medium for stochastic→deterministic migration —
  the lane model IS the determinism map; ratified versions are the ratchet
  against the prose-reinterpretation regressions observed in inception
  routing, exception handling, task creation, tier-0 escalation, and
  knowledge leveling

## 2. Package contents and reading order

| Order | File | What it is |
|---|---|---|
| 1 | `INGESTION-workflow-process-layer-2026-07-02.md` | this file — entry point |
| 2 | `INSTRUCTIONS-workflow-process-layer-2026-07-02.md` (r3) | THE specification: purposes, schema v3, validation rules, architecture, Workflow Fabric, lock plan, decision register. Authoritative for all forward work |
| 3 | `prototype/docs/README.md` | prototype orientation (bannered: describes v2 prototype) |
| 4 | `prototype/docs/schema.md` | prototype schema v2 reference (superseded by v3 spec upon Lock 1) |
| 5 | `prototype/docs/architecture.md` | prototype implementation rationale — the *why* behind two-identifier model, routing, interaction design |
| 6 | `prototype/docs/user-guide.md` | prototype editor usage |
| 7 | `prototype/aef-workflow-designer.html` | the working prototype (open in browser): 10-element intent, v2 schema, multi-workflow library, BPMN round-trip, link events |
| 8 | `prototype/tests/roundtrip.js` | evidence: automated round-trip test (14 nodes / 16 edges, uid + position preservation verified) |

## 3. Authoritative state at handover

- **Prototype**: working; XML round-trip verified programmatically; v2 schema.
- **Specification**: INSTRUCTIONS r3, `status: proposed`.
- **Decision register**: **SD-1 .. SD-15 (including WF-A..E) are ALL OPEN.**
  Every disposition in the register is a design-agent PROPOSAL, none
  Sovereign-ratified. Do not treat proposals as decisions.
- **What gates on what**: Step 0 and Step 0.5 gate on nothing. Lock 1 gates
  on the full register + both Step 0 deliverables. Locks 2–6 gate on their
  predecessors (one lock at a time).

## 4. What the framework agent does now (and only this)

Upon Sovereign dispatch:

1. **Step 0 — read-only discovery** (INSTRUCTIONS §1): answer Q1–Q10 against
   the live repo. Deliverable: `DISCOVERY-workflow-process-layer-<date>.md`.
   First line: `Discovery: workflow process layer. Q1–Q10 disposed. Blocking
   surprises: <none|list>.`
   Highest-consequence questions: **Q5** (Component Fabric ID stability —
   decides Workflow Fabric implementation shape, WF-A) and **Q10**
   (instance-state cage / P-03 autonomy-integrity constraint — a guardrail
   the agent can edit is not a guardrail).
2. **Step 0.5 — paper exercise** (INSTRUCTIONS §1.1): hand-author
   `inception-lifecycle.workflow.yaml` against the DRAFT v3 schema, grounded
   in Q1 findings (the chat strawman in §1.1 is a hypothesis to CORRECT, not
   confirm). Mark every node's determinism status. Deliverables: the draft
   workflow file + `NOTE-schema-friction-inception-<date>.md`.
3. **Stop.** Return deliverables for Sovereign review + register disposition.

Explicitly NOT authorized: schema implementation, `lib/workflow.sh`, any
`fw` verb, repo restructuring, doc migration, prototype modification.

## 5. Key insights carried from the design conversation (context, not law)

- YAML is canonical; BPMN XML is a derived interchange format; the HTML
  designer is a view surface, not the system. The prototype's XML-first shape
  was a sandbox convenience that inverted the architecture; the spec corrects
  it.
- Enforcement ladder: advisory → guided → strict. Advisory alone is
  discipline, not structure. Guided mode (framework-validated transitions,
  Lock 6) is this arc's structural-guardrail target; strict (`fw workflow
  run`) is a future arc.
- displayIds are computed, never stored; uid is the only identity. Edge
  references never break on rename/reorder/lane-move.
- Pseudocode is a one-way derived lens — never authored, never parsed back.
- Component refs on ratified workflows drift-report, never validation-error.
- Dogfood selection principle: the processes with the worst regression
  history first — Lock 5 is a falsifiable experiment for the foundational
  claim, not a demo.

## 6. First message back to the Sovereign on completion

`Step 0+0.5 complete. Q1–Q10 disposed (blocking: <none|list>). Inception draft authored; schema friction items: <n>. Awaiting register disposition SD-1..15.`
