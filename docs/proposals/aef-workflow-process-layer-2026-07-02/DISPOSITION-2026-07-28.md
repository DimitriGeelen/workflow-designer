# DISPOSITION — AEF Process-layer package (v1, 2026-07-02)

```yaml
disposed: 2026-07-28
author: product agent (832-Workflow-designer), task T-278
package: aef-workflow-process-layer-package-v1-2026-07-02
supersession: T-175 framing inception (2026-07-10, GO) → arc-001 designer-authoring-surface
coordination: AEF agent notified on the rail (thread T-278); AEF ran the same review its side
```

This note closes the bookkeeping the package left open: its Sovereign decision register
(SD-1..SD-15 incl. WF-A..E) was never disposed as a register. Eight days after ingestion
(T-019), the operator ran a fresh framing inception with this product agent — **T-175**
(IW-1..IW-8, operator dialogue 2026-07-10) — whose architecture **supersedes the package's
central design**: tasks are canonical (a diagram *proposes* governed work, never authors it);
the portable contract is the **BPMN(+`aef:`) ⇄ task-YAML mapping standard**
(`docs/standards/aef-bpmn-mapping-v1.md`, frozen v1.1) with this designer as blessed reference
implementation — not YAML-canonical workflow files under `workflows/` driven by an
`fw workflow` verb family. The package was not rejected; its P1/P2 intent was delivered
through the pivot, its P3/P4 enforcement half remains genuinely open (gap tasks below).

## Step 0 / Step 0.5 status

- **Step 0 discovery (Q1–Q10):** OBSOLETE under the pivot — it scoped a framework-repo
  implementation (`lib/workflow.sh`, `workflows/`, instance cage) that was never dispatched.
  Q10's autonomy-integrity principle (a guardrail the agent can edit is not a guardrail)
  remains live design input for T-279 if revived.
- **Step 0.5 paper exercise:** ANALOG DELIVERED, 24× over — every corpus process was
  hand-authored against the schema with a friction note
  (`docs/reports/T-021-inception-lifecycle-friction.md` … `T-067-*`), exactly the
  schema-pressure-test pattern §1.1 prescribed, including the prescribed first article
  (inception-lifecycle).

## SD register disposition

| ID | Decision | Disposition |
|----|----------|-------------|
| SD-1 | Core concepts #1/#2 = Governance + Value | **Superseded** — the "third foundational concept" framing was never ratified; the operative framing is T-175's authoring-surface program (arc-001) |
| SD-2 | Process: own layer vs cross-cutting | **Superseded** — resolved structurally by IW-7: a portable *standard* (mapping-v1), not a framework layer |
| SD-3 | Arc↔workflow relation / task follows workflow | **Superseded (inverted)** — IW-1: tasks canonical, diagram proposes; forward-compile spec §3 defines diagram→task-graph, not task→workflow binding |
| SD-4 | Normative vs descriptive | **Partial** — the mapping standard is normative (frozen Part I, conformance-fenced); individual process maps are descriptive dogfood; per-map ratified/proposed lifecycle → still-open under T-279 |
| SD-5 | Canonical file location `workflows/` | **Superseded** — corpus lives at `examples/aef-processes/*.workflow.yaml` (+ rendered BPMN); no `workflows/` dir exists by design |
| SD-6 | Ratified immutability | **Delivered (transmuted)** — version-bump + re-ratify realized on the *standard* (v1.0→v1.1, T-189/T-195 rulings) and on designer releases (G-007 immutability guard, T-198); per-workflow-file immutability → T-279 |
| SD-7 | BVP drivers for the arc | **Delivered** — arc-001 exists with BVP scoring fields; driver scoping is the live fw arc mechanism |
| SD-8 | Enforcement ladder advisory/guided/strict | **STILL OPEN → [T-279]** — nothing exists either side (verified absent in AEF v1.6.763 payload); advisory-by-convention is the de-facto state |
| SD-9 | callActivity node type | **STILL OPEN → [T-282]** — collapsed subProcess (T-081) covers containment, not sync call-with-return + ioMapping |
| SD-10 | Instance state home / caged advance | **STILL OPEN → [T-279]** — no binding, no instance files, no gated setter |
| SD-11 | humanTouchpoint block on userTask | **STILL OPEN → [T-279]** — not in the aef: schema (17-key node allowlist has no touchpoint fields); Watchtower routing unspecified |
| SD-12 | Application-practice scope / one app example | **STILL OPEN → [T-283]** — all 24 corpus maps are AEF-internal; tenant-neutrality (IW-6) has no second-tenant test article |
| SD-13 | Component Fabric linkage (aef.components) | **STILL OPEN (unscoped)** — no components refs in the schema; nearest kin is `source:` ground-truth headers on corpus maps. Fold into T-280 if revived (its reverse index was a registry/fabric feature) |
| SD-14 | Pseudocode lens | **STILL OPEN → [T-281]** — no audience lenses; designer has view controls, not filtered renderings; V2/V8 never formally tested |
| SD-15 | Workflow Fabric (incl. WF-A..E) | **STILL OPEN → [T-280]** — no process-dependency graph; AEF's conformance registry (their T-2654) covers only the conformance slice. WF-A..WF-E sub-decisions all moot until revival |

## Success-criteria scorecard (V1–V9)

| V | Criterion | Status |
|---|-----------|--------|
| V1 | Agent-generation ≥90% first-pass validate | **Not formally measured** — 24 corpus maps validate clean, but no fresh-agent pass-rate experiment was run |
| V2 | Human legibility from diagram | **Not formally tested** — extensive designer legibility work shipped (labels, halos, routing); no structured reader test |
| V3 | Round-trip identity | **DELIVERED** — G-002 closed (T-187/T-188 harness); byte-identical fixture guards the seam |
| V4 | Dogfood ≥5 processes | **DELIVERED 5×** — 24 validated processes incl. 6 of the 7 named catalog entries |
| V5 | Composition end-to-end | **Substantially delivered** — link events + off-page claims + subProcess + uuid workflowRef; callActivity leg → T-282 |
| V6 | Judge separation | **DELIVERED** — `tools/validate-workflow.py` (YAML+XML) + mapping-conformance test suite + AEF conformance registry (T-2654) |
| V7 | Guided-mode guardrail refusals | **NOT STARTED → [T-279]** |
| V8 | Business-view legibility | **NOT STARTED → [T-281]** |
| V9 | Drift detection on ratified refs | **Partial analog** — AEF audit iterates the conformance registry; ratified-workflow component-drift semantics → T-280 |

## Gap tasks (arc-001, filed 2026-07-28)

- **T-278** — this note.
- **T-279** — inception: P3 guided-mode guardrail (SD-8/10/11, Locks 3+6, V7): revive with AEF or retire.
- **T-280** — inception: Workflow Fabric (SD-15, +SD-13 fold-in): revive or retire.
- **T-281** — inception: audience render lenses (SD-14/§2.2, V2/V8).
- **T-282** — inception: callActivity (SD-9/§2.3).
- **T-283** — build: app-flavored second-tenant example (SD-12).

All four inceptions filed DEFER, owner human — decision placeholders, not scheduled work.
T-279/T-280 are predominantly AEF-side surface; their GO begins with a rail conversation.

## Addendum (2026-07-28 evening, rail 284) — register convergence with AEF

AEF ran the same review (their T-2662, report `docs/reports/T-2662-workflow-process-layer-package-review.md`
their side) and filed a mirror gap backlog in their arc-014. Cross-links:

- **T-283 is now DELIVERED** (same day): `examples/app-processes/customer-refund.workflow.yaml` + rendered
  BPMN, both zero-findings — SD-12 closes; the SD table's still-open row is superseded by this addendum.
- **T-279 (guided mode) ↔ their T-2668** (inception, DEFER their rec too) — same question both registers;
  ownership per the proposed split: theirs. Our T-279 stays as the 832 ratification touchpoint only.
- **T-280 (Workflow Fabric) ↔ their T-2670** (DEFER) — same; theirs.
- **T-281 (lenses) ↔ their T-2669** — **recommendations diverge**: ours DEFER, theirs NO-GO
  ("write-mostly corpus, no read-pull yet"). Operator sees both framings at decision time.
- **Their T-2663** (rec-GO): operator ratifies mirror+rails AS the Process layer — the SD-1 keystone
  decision, settling canonical-format authority per side (their single-stored-representation their side;
  our .workflow.yaml-canonical corpus this side; both coexist across the seam).
- **Their T-2664** (next): tier0-escalation map+rail as the P4 falsifiability experiment — arrives on the
  rail as a pair-draft round; our corpus already holds `tier0-escalation.workflow.yaml` (T-025 friction
  note) as the 832-side pairing article. T-2665/66/67 (more P4 maps) gate on its outcome.
- Their review also credits the pair with the package's Lock 2 (interchange) and Lock 5 (dogfood), and
  scores the conformance rails as EXCEEDING V9 (daily map-vs-code audit vs the package's component-ref
  drift reports only) — consistent with our scorecard, stronger on V9.
