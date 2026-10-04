---
id: T-1010
name: "AEF as a standing design partner: AEF owns its process maps and iterates them
  through our authoring kit (EWCR)"
description: >
  Inception: AEF as a standing design partner: AEF owns its process maps and iterates
  them through our authoring kit (EWCR)

status: work-completed
workflow_type: inception
current_node: frw_11_task
owner: human
horizon: null
tags: [arc:ewcr-governed-delivery]
components: [tests/run-bridge-tests.sh]
related_tasks: [T-1041]
created: 2026-10-03T15:22:16Z
last_update: 2026-10-04T16:17:55Z
date_finished: 2026-10-04T16:17:55Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-03T15:23:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 2
      F4: 2
      F3: 2
      F1: 2
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F2=2 (no-signal); F4=2 (no-signal); 
      F3=2 (no-signal); F1=2 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-1010: AEF as a standing design partner: AEF owns its process maps and iterates them through our authoring kit (EWCR)

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->
We render 24 process maps of AEF's own processes, and AEF consumes none of them (AEF 08-12 and 09-25). So today 832 draws AEF's processes FOR AEF: the wrong direction, with no owner to say a map is wrong. Meanwhile the Evergreen loop proved the mechanism that fixes this (kit, calibration, measured iterations, learning ledger, cross-vendor panel; 3 iterations, 17 findings, 10 confirmed lessons, kit 0.15.3). But Evergreen only tests conception → documented map. AEF is the only partner that can test the next step, documented map → executable contract (deterministic steps, I/O, agent fallback), which EWCR Arc-0 has lacked a concrete artefact for since 09-21.

## Hypothesis

<!-- Written by the agent (2026-10-04) from this task's own Problem Statement, Open Questions and Recommendation; hypothesis_source deliberately left unset: the operator sets `hypothesis_source: human` if they adopt this wording. -->

We believe that AEF taking ownership of its process maps and iterating them through our authoring kit's review loop, as Evergreen does,
we will achieve maps that AEF itself maintains and corrects, and a first map compiled toward an executable contract, giving EWCR Arc-0 its missing concrete artefact,
We will know that we are successful when we see AEF's round 0 measured by `tools/_t989-measure-evergreen.py` on maps in AEF's own repo, at least one review-loop iteration with its findings in docs/learning-ledger.yaml, and `fw bpmn compile` on AEF's task-gate map either producing a runnable artefact or naming exactly what is missing.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1010 -->

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

- **IW-1: Will AEF take ownership of its process maps (in its repo, under its governance), so the 24 we render become their round-0 corpus?**
  confidence: 2
  disposition: deferred
  rationale: Intent is shown: AEF filed its own inception T-3774, recommended GO ("we consume none of our own 24 maps, which is backwards", sidecar @316, 2026-10-03). Its formal answer follows its compile check of task-gate.bpmn. Deferred to the first round after a GO (docs/reports/T-1010-aef-design-partner.md:79-81)
- **IW-2: Can AEF's agent run our kit's review loop (`loop.sh --review-only`) on its maps the way Evergreen did, and is the cadence sustainable for both sides?**
  confidence: 2
  disposition: deferred
  rationale: "Can" is shown in shape. Our spike ran the loop on task-gate.bpmn (GLM-5.3): 11 findings (T-1010-spike-task-gate-review.r1.json). Cadence is NOT yet shown: codex hit its quota mid-run, and the sidecar channel needed fixes (G-082; the REPLIED receipt gap, AEF T-3804 in v1.8.1). Deferred to a measured round after a GO (report :59-77)
- **IW-3: Does `fw bpmn compile` on a map AEF owns (task-gate first) produce a runnable artefact, or name exactly what is missing?**
  confidence: 0
  disposition: deferred
  rationale: Unmeasured. AEF said it will run the compile check of task-gate.bpmn on its side before answering Q1-Q4 (@316). This is the first concrete deliverable of the round a GO starts
- **IW-4: Can the gap from documented map to executable contract (per-step I/O, command binding, agent fallback) be expressed as kit findings and designer features, i.e. does the Evergreen mechanism transfer without a new one?**
  confidence: 2
  disposition: answered
  rationale: Yes in shape, per the spike. Its 11 findings resolve into expressible gaps: (1) the source of an executable map is the implementation, not prose (a kit review-mode gap, the analogue of Evergreen's K1); (2) a structural defect the validator misses (flow out of an END and into a START; proposed ledger lesson L28); (3) no source citations on elements (a renderer/designer feature). Report :66-77

## Exploration Plan

Research artifact: docs/reports/T-1010-aef-design-partner.md.
1. Ask AEF IW-1, IW-2 (cadence), IW-3 on the sidecar with the proposal (time-box: one exchange round).
2. Spike: task-gate.bpmn (tag designer-v0.15.3) through our kit's review-only loop on our side, to size what an AEF round 0 would report (time-box: 1 h). Read-only on AEF.
3. Draft the partnership contract: ownership, cadence, what is measured per iteration, what each side commits to (absorbs operator items 2 and 3).
4. Recommendation with evidence; the operator decides.

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
  1. Run: `fw task review T-1010` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- AEF agrees to own its maps in its repo, under its governance (IW-1), and to run the kit's review loop on them (IW-2)
- The first round is bounded: one map (task-gate) through calibrate → review → measure, plus one `fw bpmn compile` attempt (IW-3)

**NO-GO if:**
- AEF declines ownership, or can only take the maps as read-only drawings; then 832 keeps drawing them, which is the problem
- Getting to an executable contract needs a new mechanism rather than kit findings and designer features (IW-4 answered "no")

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

Provisional, pre-exploration. Evidence: (1) the Evergreen loop (kit, calibration, measured iterations, ledger, calibrated cross-vendor panel, release) has run 3 iterations and produced 17 findings, 10 confirmed lessons and kit 0.15.3; (2) AEF consumes ZERO of the 24 maps we render of its processes (AEF 08-12 and 09-25), so today we draw their processes for them, the wrong direction; (3) AEF adopted 6 of our 7 recent proposals within days, so the collaboration channel works; (4) EWCR Arc-0 has been stalled on rulings since 09-21 and lacks a concrete artefact: AEF compiling a map it owns would be one. Evergreen tests conception-to-documented-map; AEF is the only partner that can test map-to-executable-contract (deterministic steps, I/O, agent fallback).

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

**Rationale**: Provisional, pre-exploration. Evidence: (1) the Evergreen loop (kit, calibration, measured iterations, ledger, calibrated cross-vendor panel, release) has run 3 iterations and produced 17 findings, 10 confirmed lessons and kit 0.15.3; (2) AEF consumes ZERO of the 24 maps we render of its processes (AEF 08-12 and 09-25), so today we draw their processes for them, the wrong direction; (3) AEF adopted 6 of our 7 recent proposals within days, so the collaboration channel works; (4) EWCR Arc-0 has been stalled on rulings since 09-21 and lacks a concrete artefact: AEF compiling a map it owns would be one. Evergreen tests conception-to-documented-map; AEF is the only partner that can test map-to-executable-contract (deterministic steps, I/O, agent fallback).

**Date**: 2026-10-04T16:17:54Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-03T15:23:03Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-10-03T15:24:24Z — status-update [task-update-agent]
- **Change:** tags: +arc:ewcr-governed-delivery

### 2026-10-04T16:17:54Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Provisional, pre-exploration. Evidence: (1) the Evergreen loop (kit, calibration, measured iterations, ledger, calibrated cross-vendor panel, release) has run 3 iterations and produced 17 findings, 10 confirmed lessons and kit 0.15.3; (2) AEF consumes ZERO of the 24 maps we render of its processes (AEF 08-12 and 09-25), so today we draw their processes for them, the wrong direction; (3) AEF adopted 6 of our 7 recent proposals within days, so the collaboration channel works; (4) EWCR Arc-0 has been stalled on rulings since 09-21 and lacks a concrete artefact: AEF compiling a map it owns would be one. Evergreen tests conception-to-documented-map; AEF is the only partner that can test map-to-executable-contract (deterministic steps, I/O, agent fallback).

## Reviewer Verdict (v1.5)

- **Scan ID:** R-06b430ea
- **Timestamp:** 2026-10-04T16:17:56Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-4
     - evidence: `IW-4 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-9fd7606f
- **Timestamp:** 2026-10-04T16:17:56Z
- **Overall:** UNVERIFIED
- **Claims:** 0
- No verifiable claims found in ## Recommendation

### 2026-10-04T16:17:55Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
