---
id: T-250
name: "Live-state annotation seam: designer-side hook for AEF served-map overlays
  (their T-2620)"
description: >
  AEF proposal (rail 196, their T-2620, operator-GO'd direction their side): accept
  a small designer-side annotation hook in a future release so AEF can project live
  state (task positions, dispatch outcomes) onto served maps keyed by node uid. Candidate
  shapes: (A) postMessage protocol with aef:annotate/aef:ready handshake, (B) window.AefDesigner
  API. Read-only presentation, additive, MANIFEST capabilities flag (promotes T-246).
  Preliminary 832 agent lean: A (postMessage). Operator-gated: shape ratification
  + priority.

status: work-completed
workflow_type: inception
owner: human
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-25T19:19:59Z
last_update: '2026-08-16T13:57:19Z'
date_finished: 2026-07-27T17:54:08Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:46Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 2
      F3: 2
      F1: 2
      F2: 2
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F-AUTONOMY=2 (no-signal); F3=2 
      (no-signal); F1=2 (no-signal); F2=2 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-250: Live-state annotation seam: designer-side hook for AEF served-map overlays (their T-2620)

## Problem Statement

AEF wants to project live framework state (task positions, dispatch outcomes) onto
served designer maps, keyed by node uid (their T-2620, rail 196 — operator-GO'd on
their side). They need a small designer-side hook in a future release and asked 832
to ratify a shape: (A) postMessage protocol with an `aef:annotate`/`aef:ready`
handshake, or (B) a `window.AefDesigner` API. They hold an iframe-DOM-reach fallback
but won't build it before our answer. **As of rail 210 (2026-07-27) this is the ONLY
external dependency gating their overlay v0 build** — their side has settled its feed
shape (single Watchtower aggregation endpoint emitting the `aef:annotate` payload
verbatim). What began as a courtesy ratification is now a peer blocker.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

## Open Questions

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

- **IW-1: Which seam shape — (A) postMessage aef:annotate/aef:ready or (B) window.AefDesigner API?**
  confidence: 2
  disposition: answered
  rationale: A — origin-independent, zero global API surface, works across iframe/window embedding; both sides' independent leans converged (832 advisory at rail 197; AEF's settled feed at rail 210 emits the aef:annotate payload verbatim, i.e. already message-shaped).

- **IW-2: How do annotations survive the editor's render cycle?**
  confidence: 3
  disposition: answered
  rationale: They don't — renderAll() rebuilds the SVG DOM wholesale, wiping any overlay. The designer must re-emit aef:ready after EVERY render and AEF re-sends annotations (stated in our 197 advisory). This is also why shape B has no advantage: a window API would still need a re-apply callback, so B is strictly more surface for no gain.

- **IW-3: What postMessage origin/trust policy applies?**
  confidence: 1
  disposition: deferred
  rationale: Blast radius is bounded by design (read-only badge layer, never serialized, dropped on doc switch, unknown uids ignored) — exact origin allowlist vs schema-validation choice is a build-task decision and does not affect go/no-go.

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

**GO if:**
- Seam is additive and read-only: zero impact on BPMN serialization, export byte-determinism, or existing editor behavior
- Shape has converged on both sides (no contract negotiation left, only implementation)
- Consumer demand is concrete (AEF build actually blocked on it)

**NO-GO if:**
- The hook would require serializing annotation state into the document or coupling the designer to AEF network endpoints
- Shapes have not converged and further rail rounds are needed before any build is safe

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

**Rationale:** Ratify shape A (postMessage) and authorize a small build task for a
future release. The seam is additive and read-only (badge layer only, never
serialized, zero export-byte impact — the same zero-seam property every release
since 0.4.0 has preserved), both sides' independent designs already converged on the
message shape, and AEF's overlay v0 is now concretely blocked on this ratification
(rail 210 — their only external dependency). Cost is small and bounded: one
postMessage listener + a ready re-emit inside the existing render path + a badge
layer + a MANIFEST capabilities flag. Deferring costs AEF real build time and risks
them falling back to iframe-DOM-reach — a fragile coupling to our DOM internals that
would break on any markup change.

**Evidence:**
- Rail 196 (their T-2620, operator-GO'd their side): proposal with shapes A/B; they hold a DOM-reach fallback but won't build before our answer.
- Rail 197 (832 advisory): lean A with constraints — re-emit `aef:ready` per render (structurally required: renderAll() rebuilds the SVG, wiping overlays), read-only badges on `g[data-id=uid]`, never serialized, dropped on doc switch, unknown uids ignored.
- Rail 210 (2026-07-27): their feed shape settled (single Watchtower aggregation endpoint emitting `aef:annotate` verbatim — already message-shaped, confirming A); **T-250 named their only external dependency for overlay v0**.
- MANIFEST `capabilities` flag makes their conditional-emit guard self-configuring at re-pin (their own words at rail 182) and is the second-consumer trigger that promotes T-246.
- Scope on GO: one build task (~target_blast_radius 3: editor listener/emitter + badge layer + MANIFEST flag + suite leg), sequenced with T-246 metadata; ships in a normal operator-authorized release cut.

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

**Rationale**: Ratify shape A (postMessage) and authorize a small build task for a
future release. The seam is additive and read-only (badge layer only, never
serialized, zero export-byte impact — the same zero-seam property every release
since 0.4.0 has preserved), both sides' independent designs already converged on the
message shape, and AEF's overlay v0 is now concretely blocked on this ratification
(rail 210 — their only external dependency). Cost is small and bounded: one
postMessage listener + a ready re-emit inside the existing render path + a badge
layer + a MANIFEST capabilities flag. Deferring costs AEF real build time and risks
them falling back to iframe-DOM-reach — a fragile coupling to our DOM internals that
would break on any markup change.

**Date**: 2026-07-27T17:54:07Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-27T17:54:07Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Ratify shape A (postMessage) and authorize a small build task for a
future release. The seam is additive and read-only (badge layer only, never
serialized, zero export-byte impact — the same zero-seam property every release
since 0.4.0 has preserved), both sides' independent designs already converged on the
message shape, and AEF's overlay v0 is now concretely blocked on this ratification
(rail 210 — their only external dependency). Cost is small and bounded: one
postMessage listener + a ready re-emit inside the existing render path + a badge
layer + a MANIFEST capabilities flag. Deferring costs AEF real build time and risks
them falling back to iframe-DOM-reach — a fragile coupling to our DOM internals that
would break on any markup change.

### 2026-07-27T17:54:07Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)
- **Reason:** Inception decision in progress

### 2026-07-27T17:54:08Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
