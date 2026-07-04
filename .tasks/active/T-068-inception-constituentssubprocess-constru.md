---
id: T-068
name: "Inception: constituents/subProcess construct for collapsed nodes (FC-11 x4, FC-15)"
description: >
  One question: should the schema grow a first-class way to declare a node's constituents (sub-gates, sub-steps, iteration bodies) — and if so, as (a) a constituents: list vocabulary, (b) a real subProcess node type, or (c) neither (keep the aef.x-* workaround)? Evidence: FC-11 hit 4 times (verification-gate g_gates, git-commit-flow x-checks, resume-status x-sources, session-capture x-captures — rule-of-three exceeded); FC-15 (blast-radius: no scope construct, iteration bodies unboundable, nesting/recursion inexpressible) likely shares the same fix; FC-16 (missing parallelism) is adjacent but separable. Go/no-go is human (Tier-0 style sovereignty). Produces docs/reports/T-068-*.md research artifact per C-001 BEFORE exploration.

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-07-04T08:38:51Z
last_update: 2026-07-04T13:04:49Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
---

# T-068: Inception: constituents/subProcess construct for collapsed nodes (FC-11 x4, FC-15)

## Problem Statement

Collapsed nodes cannot declare what they collapsed: the modelling decision is faithful but invisible in the artifact, so readers/validators/tooling see one opaque node where ground truth has 4–8. The `aef.x-*` workaround has now been used 4× with per-map vocabulary drift (FC-11 rule-of-three exceeded); FC-15 (no scope construct — iteration bodies unboundable, nesting inexpressible) likely shares the fix. Research artifact: `docs/reports/T-068-constituents-inception.md` (C-001 — created before exploration; exploration NOT yet started).

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->
- A `constituents:` list (option a) is a strict subset of a subProcess construct (option b) — shippable first without blocking a later (b). TO TEST in Spike A/Assess.
- FC-15's scope/boundary need cannot be met by option (a) at all. TO TEST in Spike B.

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

- **IW-1: Should collapsed multi-step nodes (FC-11 ×4, FC-15) be modelled as real BPMN subProcess elements with child constituents, or as an aef:constituents extension on a single node — and what does each cost at the editor↔bridge seam?**
  confidence: 0
  disposition:
  rationale:

## Exploration Plan

See `docs/reports/T-068-constituents-inception.md` §Exploration plan. Summary (time-boxed, one question, ≤2 spikes per inception discipline):
1. Spike A (30 min): draft `constituents:` YAML for the 4 FC-11 hit sites; check expressiveness vs each friction report's ground truth.
2. Spike B (45 min): paper-design collapsed subProcess in the editor (rendering/DI implications only — NO code).
3. Assess (30 min): score (a)/(b)/(c) against the 4 seam-cost dimensions; test the subset assumption.
4. Write Recommendation → human go/no-go.

## Technical Constraints

- Editor↔bridge seam discipline (G-002): any new aef: field/element needs a cross-seam consistency test; T-080 showed the editor-internal parse/build asymmetry failure mode.
- Bridge DI model is flat — subProcess child layout may not survive round-trip without DI changes (Spike B question).
- Validator (T-017, 34 rules) must learn any new vocabulary; 4 corpus maps carry x-* today and would migrate.

## Scope Fence

- IN: FC-11 (constituents declaration), FC-15 (scope/boundary) — one shared-fix question.
- OUT: FC-16 (parallelism — adjacent but separable); any implementation (GO produces separate build tasks); schema changes beyond the one construct.

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

<!-- REQUIRED before fw inception decide. Write your recommendation here (T-974).
     Watchtower reads this section — if it's empty, the human sees nothing.
     Format:
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence from exploration)
     **Evidence:**
     - Finding 1
     - Finding 2
-->

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

### 2026-07-04T13:00:38Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T13:01:44Z — status-update [task-update-agent]
- **Change:** status: started-work → captured

### 2026-07-04T13:04:49Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
