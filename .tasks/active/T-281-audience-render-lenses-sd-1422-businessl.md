---
id: T-281
name: "Audience render lenses (SD-14/§2.2): business/logical/technical/pseudocode
  views"
description: >
  Inception: decide whether to build audience-filtered lens rendering in the designer
  (functional/logical/technical + derived pseudocode) per package §2.2/SD-14, including
  deterministic byte-stable pseudocode output. Evidence: docs/proposals/aef-workflow-process-layer-2026-07-02/INSTRUCTIONS
  §2.2, SD-14.

status: started-work
workflow_type: inception
current_node: frw_1_start
owner: human
horizon: now
tags: [arc:designer-authoring-surface]
components: []
related_tasks: []
created: 2026-07-28T14:52:46Z
last_update: 2026-10-20T19:47:27Z
date_finished:
revisit_at: 2027-01-15
revisit_evidence_needed: "A non-technical reader who needs to read a map and cannot"
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

# T-281: Audience render lenses (SD-14/§2.2): business/logical/technical/pseudocode views

## Revived 2026-10-19 (operator, H1 reversed) — AEF input on their T-2669

AEF (msg 705e7d58, conversation `832-roadmap-arcs-4-6`): **T-2669 is not an objection to lenses.** Its finding
(AEF `docs/reports/T-2669-audience-lenses-supersession-review.md`, 2026-09-19): the business/logical/technical
lenses belong to arc-019 §10 / roadmap Arc 4, rendered from the ratified procedure, not to AEF's corpus-map package
(arc-014). Building them in the designer under Arc 4 is where it pointed. A designer-only render view with no
compiler impact is fully consistent with it. Their record reads GO while its rationale describes dissolution; AEF
says to treat the rationale as the position. Caveats to carry into this inception:
- **One reader, not a second:** wrap or replace the `fw corpus explain` / ask-recall seam (AEF T-2622); do not
  duplicate it.
- **The pseudocode lens (SD-14) was retired** on its own evidence. It stays out unless this inception adds it with
  a named consumer.
- **The first real read consumer is the operator,** through the onboarding curriculum's routes. That is a ready
  acceptance fixture for the Business lens.

## Problem Statement

One process map is read by three kinds of reader: a business reader (what happens, who decides), a logical reader
(the flow and its rules) and a technical reader (ids, bindings, authority, findings). The designer shows every
reader everything at once: technical badges, ids and Extensions fields bury the flow for the business reader. The
first real reader is the operator, through the onboarding curriculum's routes (AEF, msg 705e7d58). Full research:
`docs/reports/T-281-audience-lenses.md`.

## Hypothesis

We believe that a named, switchable lens in the designer (business / logical / technical / all), defined once in a
lens-definition file that AEF owns and the explain reader can share (AEF T-4402),
we will achieve one map that each reader can follow at their level, instead of a map plus a separately written
summary.
We will know that we are successful when we see 0 technical badges and 0 fields outside the business set visible
in the business lens on `aef-task-lifecycle` (measured by a test), 0 bytes changed in the saved BPMN when switching
lenses (export before == export after), 0 fields shown that the project's field profile hides, and the operator,
having opened that map in the designer in the business lens, confirm they can follow it.

## Open Questions

- **IW-1: Is a lens a per-reader view, a document, or both?**
  confidence: 2
  disposition: answered
  rationale: both from one definition (report §Design options, option C): the designer switch first (slice 1),
  the explain reader on the same file later (AEF T-4402 / T-2622 seam).
- **IW-2: How does a lens relate to the field profile?**
  confidence: 2
  disposition: answered
  rationale: the profile is project policy (what may be shown), the lens a per-reader selection inside it, never
  showing a field the profile hides (report §Open questions; asserted by the success clause).
- **IW-3: Which maps are the acceptance fixture, and where does the operator read them?**
  confidence: 3
  disposition: answered
  rationale: `aef-task-lifecycle` then `aef-session-lifecycle` (AEF); the operator reads them IN THE DESIGNER
  (operator, 2026-10-20, chat).
- **IW-4: Who owns the lens-definition file?**
  confidence: 3
  disposition: answered
  rationale: AEF, next to tools/corpus_spec.py, read by the designer from the vendored framework (AEF msg
  77dcf341, their T-4402).

## Scope Fence

IN: slice 1, the lens definition's shape and the business lens in the designer (toolbar switch; panel, details
view and canvas decoration follow the lens). Later build tasks: logical and technical lenses; `fw corpus explain
--lens` on the same definition (AEF). OUT: the pseudocode lens (SD-14, retired; no named consumer); any change to
the saved BPMN or to the compiler.

## Assumptions
<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

## Exploration Plan

Done as desk research (no spike needed for the decision): inventory of what the designer already has, AEF's
position and ownership, design options and slices, all in `docs/reports/T-281-audience-lenses.md`.

## Technical Constraints

The designer is one self-contained HTML file; the lens definition comes from the vendored framework (AEF-owned
file), so the designer must read it the way it reads the field profile (`/api/field-profile`), and work without it
(all fields, as today).

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
  1. Run: `fw task review T-281` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- A named first reader exists (met: the operator, via the onboarding curriculum; AEF msg 705e7d58)
- The lens is a render-only view: no change to saved BPMN or to the compiler (met by design; asserted by a test)
- One definition serves the designer and the explain reader, so there is no second reader (met: AEF owns it, T-4402)

**NO-GO if:**
- The lens would need its own copy of the field list or a second explain reader
- The pseudocode lens is required without a named consumer

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

**Recommendation:** GO (slice 1: lens definition shape + business lens in the designer)

**Rationale:** The earlier DEFER (2026-08) waited for "a real business-stakeholder consumer". Since 2026-10-19 one
exists: the operator, through the onboarding curriculum's routes (AEF msg 705e7d58), with fixtures named by AEF
and read in the designer (operator, 2026-10-20). AEF's T-2669 places the lenses in the designer as a render-only
view, and AEF owns the shared lens definition (T-4402), so the GO criteria are met. The operator ruled GO on
2026-10-20 (chat). Logical and technical lenses and the explain-reader integration follow as their own build
tasks; the pseudocode lens stays out.

**Evidence:**
- `docs/reports/T-281-audience-lenses.md` (existing pieces: field profile T-1125/T-1128, hide-empty T-1124,
  details view T-1127; design options A/B/C; slices)
- AEF msgs 705e7d58 (T-2669 position, three conditions) and 77dcf341 (AEF owns the definition, T-4402)

*(Earlier recommendation, 2026-08: DEFER until a real business-stakeholder consumer exists. Superseded above.)*

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

- **Scan ID:** R-0e1a5c27
- **Timestamp:** 2026-07-29T13:13:45Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-3448782b
- **Timestamp:** 2026-07-29T13:13:45Z
- **Overall:** UNVERIFIED
- **Claims:** 0
- No verifiable claims found in ## Recommendation

### 2026-10-19T10:09:52Z — status-update [task-update-agent]
- **Change:** horizon: later → next

### 2026-10-20T19:32:05Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
