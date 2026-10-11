---
id: T-1118
name: "Unknown content kinds become designer fields only on operator approval, with
  per-project and per-workflow field visibility (R2 of the T-347 ruling)"
description: >
  Inception: Unknown content kinds become designer fields only on operator approval,
  with per-project and per-workflow field visibility (R2 of the T-347 ruling)

status: work-completed
workflow_type: inception
current_node: frw_11_task
owner: human
horizon: null
tags: []
components: [src/aef-workflow-designer.html, tests/run-bridge-tests.sh, tools/_t338-input-fidelity-cdp.mjs, tools/_t598-source-marker.py, tools/_t603-multiprocess-import.mjs]
related_tasks: [T-1124, T-1125, T-1126]
inception_decisions:
  - id: hide-empty-fields
    text: "B1: the properties panel folds empty fields behind '+ N empty fields'; a field with a value is never hidden; Settings 'Show all fields'"
    ships_in: T-1124
  - id: field-profile
    text: "B2: a field profile per project and per workflow decides which fields show (designer default < project < workflow)"
    ships_in: T-1125
  - id: suggest-and-approve
    text: "B3: 'Suggest as a field' on unknown keys; a field appears only after the operator approves it via a runme job"
    ships_in: T-1126
created: 2026-10-10T12:37:38Z
last_update: 2026-10-11T12:56:03Z
date_finished: 2026-10-11T12:56:03Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-11T07:33:01Z'
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

# T-1118: Unknown content kinds become designer fields only on operator approval, with per-project and per-workflow field visibility (R2 of the T-347 ruling)

## Problem Statement

The properties panel shows one fixed field list per element type (`AEF_FIELDS`), filled or not: a service task offers
13 fields and the 42 in `examples/` fill a median of 2. Fields the designer lacks are only listed read-only
("Other extensions", T-566). The operator wants (T-347 ruling, 2026-10-10): new fields only on his approval, visibility
chosen per project and per workflow, and empty fields out of the way. Research: `docs/reports/T-1118-fields-on-approval-and-visibility.md`.

## Hypothesis

<!-- DRAFTED by the estimator from this task's own text. Correct it, then set `hypothesis_source: human` in the frontmatter to make your wording permanent. Until then a later pass may redraft it. -->

We believe that hiding empty fields by default, a field profile per project and per workflow, and new fields only on operator approval,
we will achieve a properties panel that shows what a map actually carries, with every new field one the operator chose.
We will know that we are successful when we see, on the 42 service tasks in examples/, at most 4 field rows shown by default (today 13), 0 filled fields hidden in a CDP census of the corpus, and every field outside the designer default backed by an approval record in the project profile.

## Assumptions
<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1118 -->

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

- **IW-1: How does the designer notice a new kind of content, and how does it phrase the suggestion to make it a field?**
  confidence: 2
  disposition: answered
  rationale: Extend T-566 'Other extensions' (src:6988-7024) with 'Suggest as a field' plus a per-map evidence count; a suggestion is a record, never a field (report §IW-1)
- **IW-2: How does the operator approve a suggested field (the "tier 0, with operator" path), and where is the approval recorded?**
  confidence: 2
  disposition: answered
  rationale: Suggestions queued per project; the operator approves via a runme job that writes the project field profile with approved_by/date; git history is the record (report §IW-2)
- **IW-3: Where does field visibility live — per project, per workflow, per element type — and which wins when they differ?**
  confidence: 2
  disposition: answered
  rationale: Designer default < project profile < workflow setting stored in the map; hard rule: a field with a value is never hidden (report §IW-3)
- **IW-4: Show only what is used: can the properties panel hide empty / unused fields by default (less clutter) without hiding anything that carries a value, and how does a user reveal a hidden field to fill it?**
  confidence: 3
  disposition: answered
  rationale: Measured median 2 of 13 service-task fields filled (42 in examples/); collapse empties behind '+ N empty fields', expandable in place; Settings 'show all fields' restores today's panel (report §IW-4)
- **IW-5: Which kinds come first — Greenfield's pools and message flows (T-1096)?**
  confidence: 2
  disposition: answered
  rationale: Pools and message flows are elements, kept and drawn since 0.17.0 (T-1119/T-1120), not this mechanism; first field candidates are T-566's unknown aef: keys, then element-interior content once T-347 R1 keeps it (report §IW-5)

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
  **Why you:** direction — which content kinds the designer turns into fields, and what each project / workflow shows, is product direction the operator ruled on himself (T-347, 2026-10-10); and `fw inception decide` is the operator's
  **Steps:**
  1. Run: `fw task review T-1118` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Each of the three parts (hide empty, field profile, suggest + approve) is a bounded build task, testable with CDP legs
- Defaults reproduce today's panel, so every part is reversible
- No filled field can become invisible (value-never-hidden rule holds)

**NO-GO if:**
- Visibility settings cannot be shared per project without a new server or account model
- The approval path would let a field appear without the operator

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

All five questions answered from the code and a corpus measurement. Three bounded builds, in order: B1 hide empty fields (removes the measured pollution, no new files); B2 a field profile per project plus a per-workflow setting in the map (most specific wins, a filled field is never hidden); B3 'Suggest as a field' on unknown keys, approved by an operator runme job that writes the profile. Each is testable and reversible; defaults reproduce today's panel.

**Evidence:**

- `src/aef-workflow-designer.html:2174` AEF_FIELDS is one fixed list per element type; `:6814-6928` draws every one, filled or not
- Corpus count, 42 service tasks in examples/: median 2 of 13 fields filled (report, "What the designer does today")
- `:6988-7024` T-566 'Other extensions' already detects keys with no field (305 of 714 values at T-566)
- Settings today live only in localStorage (`:2843-2943`), per browser, not per project; tools/gallery-serve.py serves maps per project id

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

**Rationale**: Operator R1 2026-10-11: GO on all three builds in order — B1 hide empty fields (median 2 of 13 service-task fields filled), B2 project + workflow field profile (most specific wins, a filled field is never hidden), B3 suggest-as-field approved by the operator via runme. Each bounded, testable, reversible; defaults reproduce today's panel. Findings: docs/reports/T-1118-fields-on-approval-and-visibility.md

**Date**: 2026-10-11T12:56:02Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-11T07:33:01Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-10-11T12:56:02Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Operator R1 2026-10-11: GO on all three builds in order — B1 hide empty fields (median 2 of 13 service-task fields filled), B2 project + workflow field profile (most specific wins, a filled field is never hidden), B3 suggest-as-field approved by the operator via runme. Each bounded, testable, reversible; defaults reproduce today's panel. Findings: docs/reports/T-1118-fields-on-approval-and-visibility.md

## Reviewer Verdict (v1.5)

- **Scan ID:** R-763fa422
- **Timestamp:** 2026-10-11T12:56:58Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 3

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-2
     - evidence: `IW-2 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  2. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-3
     - evidence: `IW-3 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  3. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-4
     - evidence: `IW-4 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-2b63e2fc
- **Timestamp:** 2026-10-11T12:56:58Z
- **Overall:** CONFIRMED
- **Claims:** 2

| Claim | Type | Status |
|-------|------|--------|
| `src/aef-workflow-designer.html:2174` | file_line | ✓ pass |
| `T-566` | task | ✓ pass |

### 2026-10-11T12:56:03Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
