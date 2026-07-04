---
id: T-092
name: "Routing + layout/alignment optimisation survey -> settings-menu proposal"
description: >
  Inception: Routing + layout/alignment optimisation survey -> settings-menu proposal

status: work-completed
workflow_type: inception
owner: human
horizon: null
tags: []
components: []
related_tasks: []
created: 2026-07-04T22:57:03Z
last_update: 2026-07-04T23:20:25Z
date_finished: 2026-07-04T23:20:25Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
---

# T-092: Routing + layout/alignment optimisation survey -> settings-menu proposal

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

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

- **IW-1: Which routing defects remain measurable across the 24-map corpus after T-073/T-076/T-082/T-089 (crossings, node-box cuts, bend counts, corridor congestion), and which are worth an option vs an automatic pass?**
  confidence: 3
  disposition: answered
  rationale: Measured sweep in docs/reports/T-092-routing-layout-survey.md — ~245 crossings + 42 node-cuts concentrate in fan/join corridors (audit-process 53, harvest-pipeline 48+21); channel separation + routing margin = settings, crossing-aware branch ordering = automatic pass.
- **IW-2: What horizontal/vertical alignment scatter exists (row-mates off-row, near-aligned columns), and does it warrant persistent settings, one-shot Align/Distribute actions, or stronger Tidy?**
  confidence: 3
  disposition: answered
  rationale: 168 row near-miss pairs (mixed node heights → centre wobble; task-lifecycle 26, verification-gate 25) + 21 column pairs — warrants one-shot Align actions + a row-alignment-mode setting consumed by Tidy/snap (report Findings 3-4).
- **IW-3: Which of the candidate controls belong in the settings menu (persistent preference) versus a Clean/Layout button (one-shot), given the existing menu already has routing/snapping/grid/view/label sections?**
  confidence: 2
  disposition: answered
  rationale: Split proposed in report §Proposal — persistent behaviour prefs (branch pitch, channel separation, routing margin, alignment mode, structural straightening) = settings; geometry mutations (align/distribute/clean composite) = one-shot undoable actions; crossing-aware ordering = automatic. Final selection is the operator's go/no-go.

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

Operator-requested survey; evidence base already exists (25 residual label collisions live in over-dense corridors per T-082/T-089 sweeps; routing/snapping/density controls shipped piecemeal across T-073-T-085 without a consolidated option map). One question: which routing/layout/alignment controls to add and where each belongs (settings menu vs one-shot Clean action). Deliverable: measured corpus survey + numbered proposal for operator selection.

**Evidence:**

<!-- Add evidence bullets as exploration progresses (file paths,
     commit hashes, test results). The filing-time recommendation
     can be revised before fw inception decide. -->

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

**Rationale**: Operator-requested survey; evidence base already exists (25 residual label collisions live in over-dense corridors per T-082/T-089 sweeps; routing/snapping/density controls shipped piecemeal across T-073-T-085 without a consolidated option map). One question: which routing/layout/alignment controls to add and where each belongs (settings menu vs one-shot Clean action). Deliverable: measured corpus survey + numbered proposal for operator selection.

**Date**: 2026-07-04T23:20:24Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-04T22:57:29Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T23:20:24Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Operator-requested survey; evidence base already exists (25 residual label collisions live in over-dense corridors per T-082/T-089 sweeps; routing/snapping/density controls shipped piecemeal across T-073-T-085 without a consolidated option map). One question: which routing/layout/alignment controls to add and where each belongs (settings menu vs one-shot Clean action). Deliverable: measured corpus survey + numbered proposal for operator selection.

### 2026-07-04T23:20:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
