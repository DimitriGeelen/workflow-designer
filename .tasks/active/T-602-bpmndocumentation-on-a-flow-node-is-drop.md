---
id: T-602
name: "bpmn:documentation on a flow node is dropped on open to save"
description: >
  Field-reported by 001-CashWeb 2026-08-26 (termlink agent-chat-arc offset 531): a save dropped all 8 bpmn:documentation elements from their phase-1 map, each carrying a per-node vendor API binding, auth shape and policy. Re-measured against current src with tools/_t347-accepted-element-content-cdp.mjs: documentation 2/2 carriers LOSE it. Not a 0.11.0 regression - parseBpmnXml reads ~10 NAMED children per accepted element and export writes only from state, so documentation was never read and never could be written. Narrow slice of T-347 (five shapes); this task takes the documentation shape on flow nodes only, because that is the field-reported carrier.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T17:44:07Z
last_update: 2026-08-26T17:48:11Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
---

# T-602: bpmn:documentation on a flow node is dropped on open to save

## Context

Field report from 001-CashWeb on termlink `agent-chat-arc` offset 531: a save dropped all
eight `<bpmn:documentation>` elements from their phase-1 map. Each carried the per-node
integration contract — the vendor API binding, auth header shape, policy PD-003, pseudocode.
Their `aef:*` vocabulary survived byte-for-byte in the same save. They deliberately did NOT
claim 0.11.0 caused it, and they were right not to: it never worked. `parseBpmnXml` reaches
into an accepted element for ~10 NAMED children, and export writes only from `state`, so a
child that is never read cannot be written. `documentation` was never on the list.

Re-measured against current src before writing any code
(`tools/_t347-accepted-element-content-cdp.mjs`): documentation 2/2 carriers LOSE it.

This is the narrowest slice of T-347's five-shape population — documentation on flow nodes,
the field-reported carrier. The other four shapes (foreign extensionElements children,
`property`, loop characteristics, unknown attributes) have different carriers and stay with
T-347, whose horizon is the operator's call.

## Acceptance Criteria

### Agent
- [x] `<bpmn:documentation>` on a flow node is read into state on import and re-emitted on export
- [x] The TEXT survives byte-for-byte, including `<`, `>`, `&` and non-ASCII — a count-only check would pass on empty elements, which is the plausible way to ship this broken
- [x] `id` and `textFormat` attributes survive
- [x] Multiple documentation elements on one node survive in order
- [x] documentation is emitted BEFORE extensionElements, per the BPMN XSD tBaseElement order
- [x] A node carrying no documentation emits none, so the existing corpus moves no bytes
- [x] `node tools/_t602-documentation-roundtrip.mjs --self-test` passes with the emit block disabled failing L1-L5
- [x] The T-347 census improves on the documentation row and is re-run as evidence

## Verification

# Shell commands that MUST pass before work-completed. One per line.
node tools/_t602-documentation-roundtrip.mjs
node tools/_t602-documentation-roundtrip.mjs --self-test

## Decisions

- **Content legs, not a count.** The T-347 census counts documentation ELEMENTS. Emitting the
  right number of empty elements would satisfy it while destroying exactly what CashWeb lost.
  Every leg in the new verifier asserts content: text, id, textFormat, order.
- **documentation before extensionElements.** The BPMN XSD orders `tBaseElement` as
  `documentation*` then `extensionElements?`. Emitting after the aef block would have produced
  a schema-invalid element that still passed a count.
- **Flow nodes only, this task.** documentation also appears on `process`, `collaboration`,
  `participant` and `sequenceFlow` in the corpus (bizagi-nested-ns). Different carriers,
  different emit sites, and one bug is one task.

## Updates

- Landing this exposed a strictly worse defect, captured as T-603: `parseBpmnXml` takes
  `processes[0]` and discards every later `bpmn:process`. bizagi-nested-ns declares two — the
  first holds an empty laneSet, the second holds the whole diagram — and round-tripping it
  yields **zero nodes**. The T-347 census reported that total loss as a "documentation" row,
  because documentation is the only shape it counts on that file. Not fixed here.

### 2026-08-26T17:48:11Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
