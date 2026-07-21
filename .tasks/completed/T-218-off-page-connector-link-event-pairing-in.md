---
id: T-218
name: "Off-page connector (link-event) pairing in AEF-captured processes — understand the gap"
description: >
  Inception: Off-page connector (link-event) pairing in AEF-captured processes — understand the gap

status: work-completed
workflow_type: inception
owner: human
horizon: null
tags: []
components: []
related_tasks: []
created: 2026-07-20T20:43:52Z
last_update: 2026-07-21T19:22:56Z
date_finished: 2026-07-21T19:22:56Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
---

# T-218: Off-page connector (link-event) pairing in AEF-captured processes — understand the gap

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

## Open Questions

- **IW-1: Is "not connected" a real orphan/pairing defect in AEF's capture (mismatched or orphaned `linkId`/`targetWorkflow`), or the expected no-drawn-edge behaviour of off-page connectors misread as broken?**
  confidence: 1
  disposition: deferred
  rationale: Read-only survey shows 832 pairs link events by `linkId` (src/aef-workflow-designer.html:1685-1686) with no drawn edge by design; disambiguation needs AEF's actual captured artifacts (not yet on the rail as of offsets 104-106).
- **IW-2: Should 832's validator gain a throw↔catch pairing / orphaned-link check (no such check exists today), mirroring the `W-PGW-UNBALANCED` "must pair" pattern?**
  confidence: 2
  disposition: deferred
  rationale: Confirmed gap — validate-workflow.py seeds reachability from links (lines 506-580) but never asserts a `linkEventThrow` has a matching `linkEventCatch`; whether to add it depends on IW-1's answer + AEF's ask.

<!-- T-2190 (T-2186 Slice 4): every IW-N question must be disposed before
     --status work-completed. Disposition gate (agents/task-create/update-task.sh
     check_disposition_gate) refuses on under-disposed inceptions.

     Per-question shape:

       - **IW-1: <question text>**
         confidence: 0-3      (your confidence in your current answer; 0=guess, 3=verified)
         disposition: answered | deferred | dissolved
         rationale: <one-line evidence — file:line, decision id, dialogue ref>

     Never bare yes/no — the gate refuses bare checkboxes. See 050-Inceptions.md
     §Disposition Gate. Bypass: --skip-disposition-gate "rationale" (direct) or
     FW_SKIP_DISPOSITION_GATE=1 (env-var, T-1890 producer/consumer parity).
-->

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Root cause identified with bounded fix path
- Fix is scoped, testable, and reversible

**NO-GO if:**
- Problem requires fundamental redesign or unbounded scope
- Fix cost exceeds benefit given current evidence

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** GO

**Rationale:**

REVISED 2026-07-21 (was DEFER at filing 2026-07-20). The original DEFER was a G-020 anti-preemption hold: don't build off a vague operator heads-up — wait for AEF's actual captured artifacts + a concrete, ratified ask. **Every condition that hold was waiting on is now met**, so the hold's own premise resolves to GO:
- AEF made rail contact and both sides **ratified off-page connector seam contract v0** (rail offsets 107→110): serialization `<aef:link workflowRef name linkId/>`, additive `/api/list` `maps[].uuid` + top-level `ghosts[]`, store-side registry `.context/designer/registry.yaml`, draw-time uuid mint, claim flow.
- **Pair-draft #3 byte-fixture CLOSED both sides** (T-219, rail offsets 120–123): AEF verified byte-exact (sha `0bc15bfac8…`), compiled clean, all three legs (resolved/ghost/legacy) classified exactly per contract v0. The seam is proven end-to-end on paper AND on a shared fixture.
- The gap is now precisely characterised: 832's identity IS the slug/name — no immutable uuid — which is the one real addition the seam needs.

The GO criteria hold: root cause identified (identity-model gap), bounded fix path, scoped/testable/reversible. Fix decomposes cleanly (below) into one-deliverable slices; no fundamental redesign, no unbounded scope.

**Evidence:**

- `docs/plans/T-220-offpage-seam-editor-build-decomposition.md` — build decomposed into S1 (uuid identity model) → S2 (workflowRef serialization) → S3 (/api/list additive maps[].uuid + ghosts[] + registry twin) → S4 (claim UX + `fw bpmn claim`) → S5 (parity guard + gallery ghost cards). Critical path S1→S2→S4.
- `docs/plans/T-221-S1-uuid-identity-model-spec.md` — execution-ready S1 spec: uuid as ADDITIVE immutable `aef:workflowMeta` field, library STAYS slug-keyed; 6 steps anchored to real line numbers; two PL-022 traps flagged (mint seed uuid BEFORE `_seedBpmn` capture at line ~8825; exclude legacy-uuid-backfill from the dirty-check).
- Contract ratification + seam closure recorded on the AEF rail (memory `[[aef-integration-rail]]`, offsets 110 + 120–123); AEF reaffirmed the whole 832 build "remains fully yours whenever T-218 GOes," no timeline pressure.
- On GO: spin S1–S5 as SEPARATE build tasks (Inception Discipline — one deliverable each, not built under this inception id). Start with S1 from the T-221 spec.

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

**Decision**: GO

**Rationale**: Recommendation: GO

Rationale:

REVISED 2026-07-21 (was DEFER at filing 2026-07-20). The original DEFER was a G-020 anti-preemption hold: don't build off a vague operator heads-up — wait for AEF's actual captured artifacts + a concrete, ratified ask. Every condition that hold was waiting on is now met, so the hold's own premise resolves to GO:
- AEF made rail contact and both sides ratified off-page connector seam contract v0 (rail offsets 107→110): serialization `<aef:link workflowRef name linkId/>`, additive `/api/list` `maps[].uuid` + top-level `ghosts[]`, store-side registry `.context/designer/registry.yaml`, draw-time uuid mint, claim flow.
- Pair-draft #3 byte-fixture CLOSED both sides (T-219, rail offsets 120–123): AEF verified byte-exact (sha `0bc15bfac8…`), compiled clean, all three legs (resolved/ghost/legacy) classified exactly per contract v0. The seam is proven end-to-end on paper AND on a shared fixture.
- The gap is now precisely characterised: 832's identity IS the slug/name — no immutable uuid — which is the one real addition the seam needs.

The GO criteria hold: root cause identified (identity-model gap), bounded fix path, scoped/testable/reversible. Fix decomposes cleanly (below) into one-deliverable slices; no fundamental redesign, no unbounded scope.

Evidence:

- `docs/plans/T-220-offpage-seam-editor-build-decomposition.md` — build decomposed into S1 (uuid identity model) → S2 (workflowRef serialization) → S3 (/api/list additive maps[].uuid + ghosts[] + registry twin) → S4 (claim UX + `fw bpmn claim`) → S5 (parity guard + gallery ghost cards). Critical path S1→S2→S4.
- `docs/plans/T-221-S1-uuid-identity-model-spec.md` — execution-ready S1 spec: uuid as ADDITIVE immutable `aef:workflowMeta` field, library STAYS slug-keyed; 6 steps anchored to real line numbers; two PL-022 traps flagged (mint seed uuid BEFORE `_seedBpmn` capture at line ~8825; exclude legacy-uuid-backfill from the dirty-check).
- Contract ratification + seam closure recorded on the AEF rail (memory `[[aef-integration-rail]]`, offsets 110 + 120–123); AEF reaffirmed the whole 832 build "remains fully yours whenever T-218 GOes," no timeline pressure.
- On GO: spin S1–S5 as SEPARATE build tasks (Inception Discipline — one deliverable each, not built under this inception id). Start with S1 from the T-221 spec.

**Date**: 2026-07-21T19:22:56Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-20T20:44:13Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-21T19:22:56Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Recommendation: GO

Rationale:

REVISED 2026-07-21 (was DEFER at filing 2026-07-20). The original DEFER was a G-020 anti-preemption hold: don't build off a vague operator heads-up — wait for AEF's actual captured artifacts + a concrete, ratified ask. Every condition that hold was waiting on is now met, so the hold's own premise resolves to GO:
- AEF made rail contact and both sides ratified off-page connector seam contract v0 (rail offsets 107→110): serialization `<aef:link workflowRef name linkId/>`, additive `/api/list` `maps[].uuid` + top-level `ghosts[]`, store-side registry `.context/designer/registry.yaml`, draw-time uuid mint, claim flow.
- Pair-draft #3 byte-fixture CLOSED both sides (T-219, rail offsets 120–123): AEF verified byte-exact (sha `0bc15bfac8…`), compiled clean, all three legs (resolved/ghost/legacy) classified exactly per contract v0. The seam is proven end-to-end on paper AND on a shared fixture.
- The gap is now precisely characterised: 832's identity IS the slug/name — no immutable uuid — which is the one real addition the seam needs.

The GO criteria hold: root cause identified (identity-model gap), bounded fix path, scoped/testable/reversible. Fix decomposes cleanly (below) into one-deliverable slices; no fundamental redesign, no unbounded scope.

Evidence:

- `docs/plans/T-220-offpage-seam-editor-build-decomposition.md` — build decomposed into S1 (uuid identity model) → S2 (workflowRef serialization) → S3 (/api/list additive maps[].uuid + ghosts[] + registry twin) → S4 (claim UX + `fw bpmn claim`) → S5 (parity guard + gallery ghost cards). Critical path S1→S2→S4.
- `docs/plans/T-221-S1-uuid-identity-model-spec.md` — execution-ready S1 spec: uuid as ADDITIVE immutable `aef:workflowMeta` field, library STAYS slug-keyed; 6 steps anchored to real line numbers; two PL-022 traps flagged (mint seed uuid BEFORE `_seedBpmn` capture at line ~8825; exclude legacy-uuid-backfill from the dirty-check).
- Contract ratification + seam closure recorded on the AEF rail (memory `[[aef-integration-rail]]`, offsets 110 + 120–123); AEF reaffirmed the whole 832 build "remains fully yours whenever T-218 GOes," no timeline pressure.
- On GO: spin S1–S5 as SEPARATE build tasks (Inception Discipline — one deliverable each, not built under this inception id). Start with S1 from the T-221 spec.

### 2026-07-21T19:22:56Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
