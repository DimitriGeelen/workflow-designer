---
id: T-020
name: "Independent-product AEF injection-point boundary"
description: >
  Inception: Independent-product AEF injection-point boundary

status: work-completed
workflow_type: inception
owner: human
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-02T20:44:48Z
last_update: '2026-08-16T12:33:31Z'
date_finished: 2026-07-02T21:25:02Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:31Z'
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
---

# T-020: Independent-product AEF injection-point boundary

## Problem Statement

The Sovereign has chosen to mature the Workflow Designer as an **independent
product** with placeholder injection points for AEF, then integrate to the
framework later — rather than take the r3 Process-layer proposal (T-019)
straight to framework. This inception validates the assumption that choice rests
on: **that a clean seam between an independent product and AEF actually exists,
and where.** Output: a seam catalog + maturation outline + Sovereign go/no-go.
Full framing, evidence, seam catalog (S1–S8), and maturation slices (M1–M5):
`docs/reports/T-020-independent-product-aef-injection-boundary.md`.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->
- A-1: A clean authoring/validation ↔ execution/resolution boundary exists (seams stub-able without an AEF runtime).
- A-2: Anchoring seams to the r3 spec keeps integration low-rework (contract stable enough despite SD-1..15 OPEN).
- A-3: "Independent" means implementation/packaging independence + AEF-aware seams (Reading A), not domain-neutrality (Reading B).

## Open Questions

- **IW-1: Framing fork — does "independent" mean Reading A (implementation/packaging independence + AEF-aware seams) or Reading B (domain-neutral BPMN tool)?**
  confidence: 2
  disposition: deferred
  rationale: Recommend A (keeps swimlane authority-model differentiation); Sovereign-reserved — see research artifact §framing fork.
- **IW-2: Does the seam catalog (S1–S8) hold — can every AEF touch reduce to a stub-able interface at the authoring/execution boundary?**
  confidence: 2
  disposition: deferred
  rationale: S1 (validator) already proven standalone in T-017/T-018; S3–S8 to be pressure-tested in exploration.
- **IW-3: Given SD-1..15 are all OPEN, how far should seams anchor to the r3 contract now vs treat it as provisional?**
  confidence: 1
  disposition: deferred
  rationale: r3 is a proposal, not ratified (T-019 evaluation); anchoring depth is a Sovereign risk call.


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

GO: the independent-with-injection-points architecture is viable and the seam is already partly proven. Evidence: (1) T-017/T-018 shipped the validator deliberately standalone ("not wired into fw; the framework can later adopt it") — a working AEF injection point that already exists; (2) T-002 GO established the designer is hand-usable before any AEF runtime; (3) the just-evaluated r3 Process-layer spec is a detailed map of AEFs future integration surface, so seams can be anchored to a known contract rather than guessed. Risk to manage, not a blocker: keep "independent" meaning implementation/packaging independence + AEF-aware seams, NOT domain-neutrality (the swimlane authority model is the products differentiation). The falsifiable question the inception closes: is the boundary clean enough to build against, and where exactly are the seams. Foundational product-strategy decision — go/no-go reserved for the Sovereign.

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

**Rationale**: GO: the independent-with-injection-points architecture is viable and the seam is already partly proven. Evidence: (1) T-017/T-018 shipped the validator deliberately standalone ("not wired into fw; the framework can later adopt it") — a working AEF injection point that already exists; (2) T-002 GO established the designer is hand-usable before any AEF runtime; (3) the just-evaluated r3 Process-layer spec is a detailed map of AEFs future integration surface, so seams can be anchored to a known contract rather than guessed. Risk to manage, not a blocker: keep "independent" meaning implementation/packaging independence + AEF-aware seams, NOT domain-neutrality (the swimlane authority model is the products differentiation). The falsifiable question the inception closes: is the boundary clean enough to build against, and where exactly are the seams. Foundational product-strategy decision — go/no-go reserved for the Sovereign.

**Date**: 2026-07-02T21:25:02Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-02T20:45:50Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-02T21:25:02Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** GO: the independent-with-injection-points architecture is viable and the seam is already partly proven. Evidence: (1) T-017/T-018 shipped the validator deliberately standalone ("not wired into fw; the framework can later adopt it") — a working AEF injection point that already exists; (2) T-002 GO established the designer is hand-usable before any AEF runtime; (3) the just-evaluated r3 Process-layer spec is a detailed map of AEFs future integration surface, so seams can be anchored to a known contract rather than guessed. Risk to manage, not a blocker: keep "independent" meaning implementation/packaging independence + AEF-aware seams, NOT domain-neutrality (the swimlane authority model is the products differentiation). The falsifiable question the inception closes: is the boundary clean enough to build against, and where exactly are the seams. Foundational product-strategy decision — go/no-go reserved for the Sovereign.

### 2026-07-02T21:25:02Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
