---
id: T-1054
name: "Adopt AEF fw runme for 832 operator commands (instead of the project-root runme.sh)?"
description: >
  Inception: Adopt AEF fw runme for 832 operator commands (instead of the project-root
  runme.sh)?

status: work-completed
workflow_type: inception
current_node: frw_11_task
owner: human
horizon: null
tags: []
components: []
related_tasks: [T-1055]
inception_decisions:
  - id: runme-launcher-hybrid
    text: "Option 3: one reviewed launcher holds the operator safeguards; jobs are immutable, named, hash-bound to their dry-run"
    ships_in: T-1055
created: 2026-10-05T18:02:45Z
last_update: 2026-10-05T19:06:19Z
date_finished: 2026-10-05T19:06:19Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-05T18:03:31Z'
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
    rationale: D1=2 (voi:open-question~'assumption'); D2=2 
      (voi:open-question~'assumption'); D3=2 (voi:open-question~'assumption'); 
      D4=2 (voi:open-question~'assumption'); F-RECALL=2 
      (voi:open-question~'assumption'); F2=2 (voi:open-question~'assumption'); 
      F4=2 (voi:open-question~'assumption'); F3=2 
      (voi:open-question~'assumption'); F1=2 (voi:open-question~'assumption')
    rubric_sha: e4a00f38e801
---

# T-1054: Adopt AEF fw runme for 832 operator commands (instead of the project-root runme.sh)?

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Hypothesis

<!-- DRAFTED by the estimator from this task's own text. Correct it, then set `hypothesis_source: human` in the frontmatter to make your wording permanent. Until then a later pass may redraft it. -->

We believe that adopt AEF fw runme for 832 operator commands (instead of the project-root runme.sh)?,
we will achieve a recorded choice of ONE operator-command path for 832, tested against an external panel.
We will know that we are successful when we see the consult artifact (`fw external show t1054-runme-path`) with at least 3 non-Claude answers, every objection answered in docs/reports/T-1054-runme-path-brief.md, and the operator's go/no-go recorded.

## Assumptions
<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1054 -->

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

- **IW-1: Does keeping the project-root runme.sh (A) carry a failure mode that AEF's fw runme (B) avoids, strong enough to switch?**
  confidence: 2
  disposition: answered
  rationale: yes — consult t1054-runme-path 5/5: wrong-job risk (observed today, 142c4183 written by the duplicate copy), dry-run not hash-bound to the live script, safety logic re-implemented per job; docs/reports/T-1054-runme-path-brief.md §Findings
- **IW-2: Is asking AEF to read 832's events file in `fw runme pending` a reasonable request, or a divergence that will bite?**
  confidence: 2
  disposition: answered
  rationale: no — reverse coupling (4 of 5 panelists); propose the safeguards to fw runme upstream instead; brief §Findings #6

## Exploration Plan

1. External consult (`fw external scan t1054-runme-path`, brief: docs/reports/T-1054-runme-path-brief.md), strongest-objection prompt, non-Claude panel. Time-box: one run.
2. Record each objection and the answer in the brief; dispose IW-1/IW-2; hand the go/no-go to the operator.

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
  1. Run: `fw task review T-1054` (opens Watchtower with recommendation, assumptions, research artifacts)
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

**Recommendation:** GO (hybrid, changed from NO-GO by the external consult)

**Rationale:**

Keep the operator's safeguards (one constant command, y/N per step, dry-run, preflight) but stop
hand-writing them per job: one reviewed wrapper does them; each job is an immutable, named artifact
under `.context/runme/<name>/`; the wrapper names the job and its sha256 before asking, and refuses a
job whose hash differs from its dry-run. Propose the same safeguards to AEF's `fw runme` so 832 can
converge on the shared runner; withdraw the request that AEF read our events file.

**Evidence:**
- External consult t1054-runme-path (2026-10-05): 5/5 non-Claude models (gpt-4o, gemini-2.5-pro, grok-4.7, deepseek-chat, qwen-2.5-72b) against keeping A as is; findings table in docs/reports/T-1054-runme-path-brief.md
- Wrong-job risk observed today: the duplicate copy (T-1052) rewrote runme.sh (142c4183) while the operator had been told a different job was waiting

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

**Rationale**: Operator chose option 3 (2026-10-05) after an external consult (t1054-runme-path, 5/5 non-Claude, unanimous that the hand-written root runme.sh is wrong: wrong-job risk observed today, dry-run not bound to the live script, safety logic re-implemented per job). Hybrid: one reviewed launcher holds dry-run, y/N per step, preflight, logging and events; each job is an immutable named file under .context/runme/<name>/; the launcher shows job name + sha256 and refuses a job changed since its dry-run; operator command stays constant. Offered upstream to AEF fw runme. Scored 30 vs 16/23/24 (docs/reports/T-1054-runme-path-brief.md).

**Date**: 2026-10-05T19:06:18Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-05T18:03:31Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-10-05T19:06:18Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Operator chose option 3 (2026-10-05) after an external consult (t1054-runme-path, 5/5 non-Claude, unanimous that the hand-written root runme.sh is wrong: wrong-job risk observed today, dry-run not bound to the live script, safety logic re-implemented per job). Hybrid: one reviewed launcher holds dry-run, y/N per step, preflight, logging and events; each job is an immutable named file under .context/runme/<name>/; the launcher shows job name + sha256 and refuses a job changed since its dry-run; operator command stays constant. Offered upstream to AEF fw runme. Scored 30 vs 16/23/24 (docs/reports/T-1054-runme-path-brief.md).

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1aa03de7
- **Timestamp:** 2026-10-05T19:06:20Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-2
     - evidence: `IW-2 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-e9df8a92
- **Timestamp:** 2026-10-05T19:06:20Z
- **Overall:** CONFIRMED
- **Claims:** 1

| Claim | Type | Status |
|-------|------|--------|
| `T-1052` | task | ✓ pass |

### 2026-10-05T19:06:19Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
