---
id: T-1035
name: "Census: 13 hook-fix teeth (T-628..T-662) fail or cannot measure on 1.7.740
  — adopted upstream, lost silently, or obsolete?"
description: >
  Found by T-1013: never wired, so T-1020's census could not see them. Same class
  as T-1020. Decide per fix before the v1.8.0 upgrade.

status: started-work
workflow_type: inception
current_node: frw_3_start
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-10-04T14:04:47Z
last_update: 2026-10-04T14:13:55Z
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
  - ts: '2026-10-04T14:12:52Z'
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

# T-1035: Census: 13 hook-fix teeth (T-628..T-662) fail or cannot measure on 1.7.740 — adopted upstream, lost silently, or obsolete?

## Problem Statement

T-1013 ran 13 never-wired teeth for 832's framework-hook fixes (T-628, 629, 631-634, 636-639, 650, 654, 662) on the 1.7.740 vendor. 9 fail and 4 cannot build their pre-fix mutant, because the code they target is gone. That is the T-1020 signature: local fixes erased by the re-vendor. T-1020's census nevertheless missed them. Before the v1.8.0 upgrade we must know, per fix, whether the behaviour is still delivered (adopted upstream in another form), lost, or obsolete; otherwise the next re-vendor repeats the loss. Research artifact: docs/reports/T-1035-hook-fix-census.md.

## Hypothesis

<!-- Written by the agent (2026-10-04), not the operator: hypothesis_source deliberately left unset. -->

We believe that most of these 13 teeth fail because 832's hook fixes were erased by the 1.7.740 re-vendor, and not because the protected behaviour is gone; for some, AEF delivers the same protection in another form,
we will achieve a per-fix verdict (adopted / lost / obsolete), each backed by evidence on today's tree, so that what is lost can be restored and declared before the v1.8.0 upgrade,
We will know that we are successful when we see docs/reports/T-1035-hook-fix-census.md give each of the 13 tools exactly one verdict with a behavioural check run on today's tree, plus the reason T-1020's census missed them.

## Assumptions
<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1035 -->

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

- **IW-1: For each of the 13, is the protected behaviour still delivered on 1.7.740 (adopted upstream in another form), lost, or obsolete?**
  confidence: 0
  disposition:
  rationale:
- **IW-2: Why did T-1020's census (every commit touching .agentic-framework/) not flag these fixes?**
  confidence: 0
  disposition:
  rationale:
- **IW-3: For the 4 that cannot measure (_t632, _t638, _t639, _t654): is the tooth stale (superseded by a newer probe, e.g. _t639 by _t1005) or is its subject gone?**
  confidence: 1
  disposition:
  rationale: _t1005's header says it "Replaces _t639, whose mutation targets a function name 1.7.740 does not have"

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->
- **Spike A (mechanical, 30 min).** Per tool:
  - find the fix commit(s) that touched .agentic-framework/;
  - measure how many of its added lines survive in HEAD;
  - record its T-1020 census row and register status.

  Answers IW-2.
- **Spike B (behavioural, 90 min).** Per tool:
  - read what it asserts, then test that BEHAVIOUR on today's tree, independent of the tooth's mutation mechanics;
  - verdict: ADOPTED (the behaviour holds by another route), LOST (the behaviour is broken), or OBSOLETE (the subject no longer exists or is superseded).

  Answers IW-1 and IW-3.
- Each spike's output goes to the report before the next starts. Restores happen in separate build tasks after a GO, never under this inception.

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
  1. Run: `fw task review T-1035` (opens Watchtower with recommendation, assumptions, research artifacts)
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

**Rationale:** T-1013 ran 13 never-wired teeth for 832's hook fixes (T-628..T-662) on 1.7.740: 9 fail (e.g. _t628 5/11, _t650 10/16, _t662 4/9) and 4 cannot build their pre-fix mutant because the code they target is gone. That is the T-1020 signature (local fixes erased by the re-vendor), invisible to T-1020 because nothing ran these teeth. A per-fix census (adopted upstream in another form / lost / obsolete) is bounded (13 items, reports exist) and must precede the v1.8.0 upgrade, or that re-vendor repeats the loss.

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

<!-- Filled at completion via: fw inception decide T-1035 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-04T14:12:51Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
