---
id: T-279
name: "Guided-mode procedural guardrail (package P3, Locks 3+6): revive or retire"
description: >
  Inception: decide whether the package's enforcement half (P3 guided mode + procedural
  guardrails, INSTRUCTIONS §0.3/§3.1.4/Locks 3+6) should be revived as a joint 832/AEF
  arc phase or formally retired. Evidence base: docs/proposals/aef-workflow-process-layer-2026-07-02/INSTRUCTIONS
  §0.3, §2.4 mode-gating rules, §3.2, Locks 3/6, V7.

status: captured
workflow_type: inception
owner: human
horizon: later
tags: [arc:designer-authoring-surface]
components: []
related_tasks: []
created: 2026-07-28T14:52:30Z
last_update: '2026-08-16T14:33:00Z'
date_finished:
revisit_at: 2026-09-15
revisit_evidence_needed: "Operator decision to raise the enforcement ladder with AEF, or a third instance of a prose process being re-interpreted and a fix not locking in"
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:26Z'
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
  - ts: '2026-08-16T14:33:00Z'
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
  - ts: '2026-08-16T13:57:12Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 6
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=6 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-279: Guided-mode procedural guardrail (package P3, Locks 3+6): revive or retire

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Hypothesis

<!-- DRAFTED by the estimator from this task's own text. Correct it, then set `hypothesis_source: human` in the frontmatter to make your wording permanent. Until then a later pass may redraft it. -->

We believe that guided-mode procedural guardrail (package P3, Locks 3+6): revive or retire,
we will achieve Inception: decide whether the package's enforcement half (P3 guided mode + procedural guardrails, INSTRUCTIONS §0.3/§3.1.4/Locks 3+6) should be revived as a joint 832/AEF arc phase or formally retired.
We will know that we are successful when we see [NEEDS YOU: name something a person could go and look at — a count, a threshold, a named check, or a state that would visibly change].

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
  1. Run: `fw task review T-279` (opens Watchtower with recommendation, assumptions, research artifacts)
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

**Rationale:** Package P3/P4 enforcement half (enforcement ladder advisory/guided/strict, fw workflow bind/advance, caged instance state, humanTouchpoint, workflow-scoped tier envelopes) was never built either side — verified absent in AEF v1.6.763 payload (no lib/workflow.sh, no workflow verb family) and never mentioned on the rail. Surface is mostly AEF-side; the P4 diagnosis (prose processes stochastically re-interpreted, fixes never lock in) remains unanswered. One question: raise with AEF and decide revive-vs-retire; DEFER until operator wants it raised.

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

## Reviewer Verdict (v1.5)

- **Scan ID:** R-66f1070b
- **Timestamp:** 2026-07-29T13:13:45Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-fbe9990a
- **Timestamp:** 2026-07-29T13:13:45Z
- **Overall:** UNVERIFIED
- **Claims:** 0
- No verifiable claims found in ## Recommendation

## 2026-09-27 — SPLIT PROPOSED (T-874, arc-005). Nothing here is ticked, closed or reassigned.

This task carries THREE Sovereign decisions — **SD-8** (advisory/guided/strict enforcement
ladder), **SD-10** (instance state home and caged advance) and **SD-11** (humanTouchpoint on
userTask). That violates this project's own sizing rule ("one inception = one question") and is
the most likely reason it has sat `captured` since 2026-07-28: there is no single go/no-go that
answers it.

arc-005 (`process-instances`) proposes the split:

| SD | goes to |
|----|---------|
| SD-10 instance identity / binding | **T-878** — new inception, the load-bearing unknown |
| SD-8 enforcement ladder | **T-879** — new inception, the live half of this task |
| SD-11 humanTouchpoint | deferred out of arc-005 **explicitly**, so it is deferred rather than forgotten |

**This is a proposal for the operator, not a completed re-parenting.** T-279 remains `captured`,
`owner: human`, tagged `arc:designer-authoring-surface`, with every criterion untouched. If the
split is ratified, T-279 is retired or rescoped to SD-11 alone; if it is not, T-878/T-879 are the
duplicates and should be withdrawn. Recorded here so the relationship is visible from this side
too, and not only from the new arc's scope document.

Scope: `docs/reports/arc-005-process-instances-scope.md` §3 S2/S3 and §5.
