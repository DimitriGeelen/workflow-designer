---
id: T-498
name: "scope the onboarding-experience arc iteration: which arcs, whose project, what
  iteration"
description: >
  Inception: scope the onboarding-experience arc iteration: which arcs, whose project,
  what iteration

status: captured
workflow_type: inception
owner: human
horizon: later
tags: []
components: []
related_tasks: []
created: 2026-08-14T11:31:38Z
last_update: 2026-08-23T10:24:12Z
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:30Z'
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
  - ts: '2026-08-16T14:33:04Z'
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
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-498: scope the onboarding-experience arc iteration: which arcs, whose project, what iteration

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

## Open Questions

- **IW-1: Does this project have onboarding arcs at all, or is the operator's "4 arcs
  for onboarding" recollection pointing at the AEF project?**
  confidence: 3
  disposition: answered
  rationale: AEF-side. `ls .context/arcs/` here returns exactly one file —
    designer-authoring-surface.yaml (arc-001, in-progress), matching today's audit
    line "All 1 in-progress arc(s)". The FOUR arcs are AEF's, named in their rail
    message at offset 621 §2 as the four that read zero-population under their
    stale-arc membership bug: horizon-axis-hardening (5 tasks),
    onboarding-shape-detection (3), onboarding-curriculum (4),
    ladder-trigger-producer (1). Two of the four are literally "onboarding-*", which
    is the likely source of the recollection. 18 files here mention "onboarding" but
    they are our own T-001..T-015 bootstrap tasks, not an arc.

- **IW-2: If the arcs are AEF-side, what may I legitimately do about them from here?**
  confidence: 3
  disposition: answered
  rationale: Not much, and deliberately. T-559 forbids invoking AEF's tooling; the
    832<->AEF seam is contract+fixture based. `fw arc` commands against their tree are
    out. What IS sanctioned: reporting over the DM rail, and reading their SERVED HTTP
    resources. So iterating those arcs is work for a session in THEIR project, not a
    thing this session can do on their behalf.

- **IW-3: "Iterate to improve the onboarding experience" — whose onboarding?**
  A new human operator adopting the framework, a new agent session picking up context,
  or a new consumer project adopting the designer. These have disjoint deliverables and
  the phrase does not distinguish them.
  confidence: 3
  disposition: dissolved
  rationale: The question had no subject. Operator withdrew the premise ("oh i was
    confused") once IW-1 showed this project has one arc and the four onboarding-ish
    arcs are AEF's. Dissolved rather than deferred: there is nothing to come back to
    here, and a deferred question would sit in the register implying latent work.

## Dialogue Log (C-001)

### 2026-08-14 — the four arcs

- **Operator:** "we have 4 arc i believe which we wanted to iterate to improve the
  onboarding experience"
- **Checked before answering:** `.context/arcs/` holds exactly one file
  (designer-authoring-surface.yaml), consistent with today's audit "All 1 in-progress
  arc(s)". The four arcs exist — in AEF's tree, named at rail offset 621 §2 as the four
  that read zero-population under their stale-arc membership bug, two of them
  `onboarding-*`.
- **Outcome:** premise withdrawn. No work scoped, nothing built.
- **Worth keeping:** the recollection was accurate about the NUMBER and the THEME and
  wrong only about the PROJECT. Content arriving over the rail is indistinguishable, in
  memory, from local state — the message that carried those four arc names was read here
  an hour earlier. That is a cross-project context-bleed shape, not a slip.

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
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
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

**Recommendation:** DEFER

**Rationale:**

Cannot recommend before enumerating. Today's audit reports exactly ONE in-progress arc here (designer-authoring-surface, arc-001, 22 tasks). The arcs named 'onboarding-shape-detection' (3 tasks) and 'onboarding-curriculum' (4 tasks) appear in AEF's rail message at offset 621 as AEF-SIDE arcs surfaced by their stale-arc audit, not ours. The operator's recollection of four onboarding arcs may therefore point at the AEF project, which T-559 forbids me to touch with their tooling. DEFER until the arc set here is enumerated and the premise confirmed with the operator.

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

<!-- Filled at completion via: fw inception decide T-XXX go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-08-14T11:31:49Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-08-23T10:24:12Z — status-update [task-update-agent]
- **Change:** horizon: now → later
- **Change:** status: started-work → captured (auto-sync)
