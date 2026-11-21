---
id: T-1461
name: "Should the designer draw phases across a map (bpmn:group with categoryValueRef
  as phase bands: dividers through all lanes, a named bracket per phase, an optional
  second row, an optional tint), as Greenfield's owner asks?"
description: >
  Inception: Should the designer draw phases across a map (bpmn:group with categoryValueRef
  as phase bands: dividers through all lanes, a named bracket per phase, an optional
  second row, an optional tint), as Greenfield's owner asks?

status: work-completed
workflow_type: inception
current_node: frw_end_task
owner: human
horizon: null
tags: []
components: []
related_tasks: []
waiting_on: agent
revisit_at: 2026-11-27
created: 2026-11-20T13:12:30Z
last_update: 2026-11-21T15:15:46Z
date_finished: 2026-11-21T15:15:46Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
#
# T-865 (operator-directed 2026-09-26): the two values below are PLACEHOLDERS, not an assessment. The BVP
# estimator ignores any value without `<field>_source: human` and estimates it from this task's own text, so a
# 0.5 nobody chose no longer ranks as "judged middling". They stay filled because AEF's T-2188 schema hook
# refuses an edit to an inception without them (T-1178; T-865 had deleted them before that hook arrived here).
#
# TO OVERRIDE. Set the value AND its source, and it becomes sticky — no automatic pass will ever change it again:
#
#   voi_score: 0.9
#   voi_score_source: human
#
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-11-21T12:01:08Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 1
      D2: 1
      D3: 1
      D4: 1
      F-RECALL: 1
      F2: 1
      F4: 1
      F3: 1
      F1: 1
    rationale: D1=1 (voi:no-leverage-signal (measured low, not unassessed)); 
      D2=1 (voi:no-leverage-signal (measured low, not unassessed)); D3=1 
      (voi:no-leverage-signal (measured low, not unassessed)); D4=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F-RECALL=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F2=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F4=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F3=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F1=1 
      (voi:no-leverage-signal (measured low, not unassessed))
    rubric_sha: e4a00f38e801
---

# T-1461: Should the designer draw phases across a map (bpmn:group with categoryValueRef as phase bands: dividers through all lanes, a named bracket per phase, an optional second row, an optional tint), as Greenfield's owner asks?

## Problem Statement

Greenfield's owner (msg d5819d5e, 2026-11-20) wants a horizontal map divided into phases along the x axis: divider
lines through all lanes, a named bracket per phase above the pool, an optional second row (their Salesforce phases
over the Tacton steps), an optional tint. Order and lanes must not change. Today the designer keeps `bpmn:group`
unchanged on save but draws nothing, so Greenfield draws phases themselves, outside the designer, from our DI.
Findings: `docs/reports/T-1461-phases.md`.

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

We believe that drawing phases from standard `bpmn:group` + `bpmn:category` (a phase being a range of steps, its
rectangle derived from them),
we will achieve a map a workshop can read by phase inside the designer, with no change to any map that has no phases.
We will know that we are successful when we see Greenfield's workshop map open with its 5 phases at the boundaries
they drew (x 560/1016/1604/2080, within one step), a second row drawn, and every corpus map and byte-identity golden
unchanged on save.

## Assumptions

- A1: no existing corpus map carries groups (checked: none; only the kitchen-sink fixture).
- A2: Greenfield's phases are contiguous ranges of steps along x (their subtitle "stap 4-6"; their boundaries sit
  between steps).

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

- **IW-1: Can phases be stored as standard BPMN (bpmn:group with categoryValueRef) so that other tools and AEF read the same file, rather than as an aef: extension?**
  confidence: 2
  disposition: answered
  rationale: yes — group + categoryValue per phase, one category per row; only a small aef marker in the category's extensionElements says "this row is phases" (report F2, F3)
- **IW-2: Does the designer already keep groups byte-stable on save (T-1327), so that drawing them is a rendering change and not a model change?**
  confidence: 3
  disposition: answered
  rationale: yes — captureProcessLevelKept keeps groups, their DI and named categories verbatim (src ~15890), pinned by the kitchen-sink golden; Greenfield's question 2 is already met (report F1)
- **IW-3: How does a person create, rename, move and delete a phase, and how are two rows (e.g. phase and sub-phase) told apart in the file?**
  confidence: 1
  disposition: deferred
  rationale: storage answered (a phase = a range of steps; a row = a category; report F4); the editing UI is slice 2, designed in its own build task after slice 1, with screenshots and review
- **IW-4: Does drawing phases change saved bytes or routing of any existing corpus map (T-423)?**
  confidence: 2
  disposition: answered
  rationale: no corpus map has a group (grep); bands sit above/behind the lanes and move no node; slice 1 writes kept groups unchanged (report F5)
- **IW-5: Does AEF (the main consumer) want or object to phases in the maps it stores?**
  confidence: 1
  disposition: deferred
  rationale: slice 1 changes no file AEF stores; AEF is asked with the exact XML before slice 2 writes new groups (report F6)

## Exploration Plan

Desk research, 1 h: read the designer's group keep (T-1326/T-1327), the BPMN group/category model, the corpus and
fixtures for existing groups, and Greenfield's request. No prototype before a decision.

## Technical Constraints

Single-file designer (src/aef-workflow-designer.html). T-423: saved bytes must not depend on the screen. Byte-identity
goldens (T-358) must stay identical in slice 1. UI change: person-sees gate, screenshots at three widths, review.

## Scope Fence

IN: whether and how phases are stored and drawn; what changes for existing maps; the slice plan.
OUT: the editing UI's design (slice 2, its own task); drawing non-phase groups as plain boxes (a separate question);
vertical maps (the designer draws horizontal pools).

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
  **Why you:** direction — whether the designer takes on phases (a new kind of thing on the map, asked by Greenfield's owner) is the operator's call
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Phases fit standard BPMN (groups + categories), so maps stay valid `.bpmn` for other tools and AEF
- Drawing them changes nothing for maps without phases (saved bytes, routing, layout)
- A first slice (draw only) is small and testable on Greenfield's own map

**NO-GO if:**
- Phases need an aef-only model other tools cannot read
- Drawing them would move steps, change routing or change saved bytes of existing maps

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

**Recommendation:** GO (slice 1 only: draw phases from the file; editing is a later, separate decision)

**Rationale:**

Phases fit standard BPMN: a `bpmn:group` per phase pointing at a `bpmn:categoryValue`, one `bpmn:category` per row, so
a second row (Greenfield's Salesforce phases) is just a second category. The designer already keeps all of this
unchanged on save (T-1327), so Greenfield's fallback question is already answered yes. Slice 1 only draws: divider
lines through all lanes, a named bracket per phase above the pool, a second row, an optional tint. No map in the
corpus has a group, so nothing changes for any existing map, on screen or on save. Not every group is a phase (the
bpmn.io-style groups in our kitchen-sink fixture are boxes inside one lane), so a row is marked as phases by a small aef
marker in the category, or recognised by spanning the pool's full height. Editing phases (slice 2) writes new XML into
maps AEF stores, so it waits for slice 1 on screen, AEF's view, and its own go.

**Evidence:**

- `docs/reports/T-1461-phases.md` F1–F6
- `src/aef-workflow-designer.html` `captureProcessLevelKept` (groups, DI and categories kept verbatim)
- `grep -rlE '<(bpmn:)?group[ >]' --include=*.bpmn` finds only `tests/fixtures/third-party/kitchen-sink.bpmn`
- kitchen-sink groups: bounds inside one lane (190..1400 × 120–150 in a lane 1160 high), not phases

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

**Rationale**: Phases fit standard BPMN: a `bpmn:group` per phase pointing at a `bpmn:categoryValue`, one `bpmn:category` per row, so
a second row (Greenfield's Salesforce phases) is just a second category. The designer already keeps all of this
unchanged on save (T-1327), so Greenfield's fallback question is already answered yes. Slice 1 only draws: divider
lines through all lanes, a named bracket per phase above the pool, a second row, an optional tint. No map in the
corpus has a group, so nothing changes for any existing map, on screen or on save. Not every group is a phase (the
bpmn.io-style groups in our kitchen-sink fixture are boxes inside one lane), so a row is marked as phases by a small aef
marker in the category, or recognised by spanning the pool's full height. Editing phases (slice 2) writes new XML into
maps AEF stores, so it waits for slice 1 on screen, AEF's view, and its own go.

**Date**: 2026-11-21T15:15:45Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-11-21T12:01:07Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-11-21T15:15:45Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Phases fit standard BPMN: a `bpmn:group` per phase pointing at a `bpmn:categoryValue`, one `bpmn:category` per row, so
a second row (Greenfield's Salesforce phases) is just a second category. The designer already keeps all of this
unchanged on save (T-1327), so Greenfield's fallback question is already answered yes. Slice 1 only draws: divider
lines through all lanes, a named bracket per phase above the pool, a second row, an optional tint. No map in the
corpus has a group, so nothing changes for any existing map, on screen or on save. Not every group is a phase (the
bpmn.io-style groups in our kitchen-sink fixture are boxes inside one lane), so a row is marked as phases by a small aef
marker in the category, or recognised by spanning the pool's full height. Editing phases (slice 2) writes new XML into
maps AEF stores, so it waits for slice 1 on screen, AEF's view, and its own go.

### 2026-11-21T15:15:46Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0dff49a2
- **Timestamp:** 2026-11-21T15:15:47Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** 3

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-1
     - evidence: `IW-1 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  2. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-2
     - evidence: `IW-2 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  3. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-4
     - evidence: `IW-4 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-ab1f046c
- **Timestamp:** 2026-11-21T15:15:47Z
- **Overall:** CONFIRMED
- **Claims:** 4

| Claim | Type | Status |
|-------|------|--------|
| `docs/reports/T-1461-phases.md` | file | ✓ pass |
| `src/aef-workflow-designer.html` | file | ✓ pass |
| `tests/fixtures/third-party/kitchen-sink.bpmn` | file | ✓ pass |
| `T-1327` | task | ✓ pass |
