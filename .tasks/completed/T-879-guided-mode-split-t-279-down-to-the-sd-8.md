---
id: T-879
name: "Guided mode: split T-279 down to the SD-8 enforcement-ladder question and answer
  it"
description: >
  arc-005 S3/B7. The live half of the captured T-279. Question: which rung does this
  project target and what does guided mode refuse? Ladder is advisory (today, by convention)
  -> guided (target) -> strict (EXPLICITLY OUT — anything that actually drives execution
  is arc-002/EWCR). Deliverable is the decision plus the refusal contract; V7's three
  refusals are the acceptance shape. Depends on the instance-identity answer. On GO
  file the build tasks in the same session.

status: work-completed
workflow_type: inception
target_blast_radius: 3
voi_score: 0.5
owner: agent
horizon: null
arc_id: process-instances
tags: [arc:process-instances]
components: []
related_tasks: [T-882, T-883, T-279]
created: 2026-09-26T22:42:46Z
last_update: 2026-09-27T22:45:10Z
date_finished: 2026-09-27T22:45:10Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
#
# T-865 (operator-directed 2026-09-26): BOTH fields below are now ESTIMATED
# automatically from this task's own text. Do not pre-fill them.
#
# They used to ship with `target_blast_radius: 3` and `voi_score: 0.5` already
# filled in, and that default was doing real damage: int(round(0.5*5)) == 2, and
# an ABSENT voi_score also scored 2, so "nobody assessed this" and "someone
# judged it middling" were the same number. 42 of 45 inceptions ranked on a
# value no person had chosen, and because 2 is mid-range they sorted ahead of
# measured work. T-624 tried to fix it with a warning printed right here; 28
# days later the figure had not moved by one, because a comment is not a gate.
# Deleting the default IS the gate.
#
# TO OVERRIDE. Set the value AND its source, and it becomes sticky — no
# automatic pass will ever change it again:
#
#   voi_score: 0.9
#   voi_score_source: human
#
# Anything without `_source: human` is treated as the estimator's own and is
# freely recomputed. There is no third state, deliberately: an "unknown
# provenance" value is exactly the ambiguity this replaced.
#
# target_blast_radius — int 0..9. Anticipated component count of the build work
#   this inception would authorise on GO; substitutes for the absent
#   components: list in the F8 cost formula (040).
#   Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem
#   (M), 7=multi-arc (L), 9=framework-wide (XL).
# voi_score — float 0..1. Value of Information: expected value of RESOLVING
#   this question, independent of build cost. Higher when the answer affects
#   many tasks or unblocks a strategic decision.
bvp_scores_proposed:
  - ts: '2026-09-26T23:10:11Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 3
      D2: 3
      D3: 3
      D4: 3
      F-RECALL: 3
      F2: 3
      F4: 3
      F3: 3
      F1: 3
    rationale: D1=3 (voi:decision-with-alternatives~'go/no-go'); D2=3 
      (voi:decision-with-alternatives~'go/no-go'); D3=3 
      (voi:decision-with-alternatives~'go/no-go'); D4=3 
      (voi:decision-with-alternatives~'go/no-go'); F-RECALL=3 
      (voi:decision-with-alternatives~'go/no-go'); F2=3 
      (voi:decision-with-alternatives~'go/no-go'); F4=3 
      (voi:decision-with-alternatives~'go/no-go'); F3=3 
      (voi:decision-with-alternatives~'go/no-go'); F1=3 
      (voi:decision-with-alternatives~'go/no-go')
    rubric_sha: e4a00f38e801
---

# T-879: Guided mode: split T-279 down to the SD-8 enforcement-ladder question and answer it

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Hypothesis

<!-- REQUIRED before a GO decision (T-866, arc-004). Fill the three blanks below and
     delete this comment. Keep the three phrases — the gate looks for them.

     NOT EVERY INCEPTION HAS ONE, and that is fine. "Research how X works" produces
     understanding, not a delivered outcome, and forcing it into "we will achieve
     <outcome>" would manufacture a fake claim to satisfy a gate — which teaches
     authors to write fiction and is worse than no gate at all.

     If this is that kind of inception, set in the frontmatter:

         inception_kind: research

     and delete this section. The gate then passes. Declare it NOW, while framing the
     work — not later at the decision, when you know whether the hypothesis would have
     been inconvenient. The count of research inceptions is reported, so if the
     exemption quietly becomes the default that is visible rather than silent.

     This is the form the BVP scoring method expects. Every support score in this
     task's value-driver table is an ARGUMENT ABOUT THIS SENTENCE: "support 5 on
     Reliability" means something only once the sentence says what success looks
     like. Without it a score can rank but cannot be wrong, because there is no
     claim for it to be wrong about.

     THE THIRD CLAUSE IS THE ONE THAT BITES. It has to be checkable by someone who
     was not in the room and who reads this in three months. A number, a count, a
     threshold, a named state.

       no  — "...when the system is better"
       no  — "...when the team is more productive"
       yes — "...when 5 consecutive fire-suppression tests pass at every equipped site"
       yes — "...when fw audit reports 0 failures for 3 consecutive nightly runs"
       yes — "...when the importer no longer fabricates a lane for input that has none"

     Writing it is genuinely hard. You are not expected to start from blank: the
     estimator drafts one from this task's own text, and you correct it. Your
     correction is sticky — set `hypothesis_source: human` in the frontmatter and no
     automatic pass will ever overwrite it. -->

We believe that if the framework holds instance state and advances it only through a validated transition,
we will achieve a guided mode in which an illegitimate step is refused at the moment it is attempted instead of being discovered afterwards.
We will know that we are successful when we see all 3 of the V7 cases — an out-of-order advance, a skipped human gateway, and an unmet input contract — each refused with a non-zero exit code and each leaving a line in the audit log that names which rule refused it.

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

**Rationale:** GO on the SD-8 half, and the split is part of the recommendation. T-279 as filed carries THREE Sovereign decisions — SD-8 (advisory/guided/strict ladder), SD-10 (instance state and caged advance) and SD-11 (humanTouchpoint on userTask) — which violates this project's own 'one inception = one question' sizing rule and has left it captured and unstarted since 2026-07-28. Splitting is what makes it answerable: SD-10 goes to the instance-identity inception, SD-11 defers out of arc-005 explicitly rather than by neglect, and what remains here is one question with a clean go/no-go. The evidence that the ladder is the right target is that advisory-by-convention is the measured de-facto state (DISPOSITION-2026-07-28 verified SD-8 absent on both sides in AEF v1.6.763) and success criterion V7 — an out-of-order advance, a skipped human gateway, and an unmet input contract each refused and audited — is still NOT STARTED. Sequenced after the instance-identity inception: a ladder that advances something cannot be specified before what it advances exists.

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

Rationale: GO on the SD-8 half, and the split is part of the recommendation. T-279 as filed carries THREE Sovereign decisions — SD-8 (advisory/guided/strict ladder), SD-10 (instance state and caged advance) and SD-11 (humanTouchpoint on userTask) — which violates this project's own 'one inception = one question' sizing rule and has left it captured and unstarted since 2026-07-28. Splitting is what makes it answerable: SD-10 goes to the instance-identity inception, SD-11 defers out of arc-005 explicitly rather than by neglect, and what remains here is one question with a clean go/no-go. The evidence that the ladder is the right target is that advisory-by-convention is the measured de-facto state (DISPOSITION-2026-07-28 verified SD-8 absent on both sides in AEF v1.6.763) and success criterion V7 — an out-of-order advance, a skipped human gateway, and an unmet input contract each refused and audited — is still NOT STARTED. Sequenced after the instance-identity inception: a ladder that advances something cannot be specified before what it advances exists.

**Date**: 2026-09-27T22:45:08Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-09-27T22:45:08Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Recommendation: GO

Rationale: GO on the SD-8 half, and the split is part of the recommendation. T-279 as filed carries THREE Sovereign decisions — SD-8 (advisory/guided/strict ladder), SD-10 (instance state and caged advance) and SD-11 (humanTouchpoint on userTask) — which violates this project's own 'one inception = one question' sizing rule and has left it captured and unstarted since 2026-07-28. Splitting is what makes it answerable: SD-10 goes to the instance-identity inception, SD-11 defers out of arc-005 explicitly rather than by neglect, and what remains here is one question with a clean go/no-go. The evidence that the ladder is the right target is that advisory-by-convention is the measured de-facto state (DISPOSITION-2026-07-28 verified SD-8 absent on both sides in AEF v1.6.763) and success criterion V7 — an out-of-order advance, a skipped human gateway, and an unmet input contract each refused and audited — is still NOT STARTED. Sequenced after the instance-identity inception: a ladder that advances something cannot be specified before what it advances exists.

### 2026-09-27T22:45:09Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Reason:** Inception decision in progress

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9891a974
- **Timestamp:** 2026-09-27T22:45:10Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-850908c8
- **Timestamp:** 2026-09-27T22:45:10Z
- **Overall:** CONFIRMED
- **Claims:** 1

| Claim | Type | Status |
|-------|------|--------|
| `T-279` | task | ✓ pass |

### 2026-09-27T22:45:10Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
